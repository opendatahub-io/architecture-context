# Component: ODH Dashboard

## Metadata
- **Repository**: https://github.com/red-hat-data-services/odh-dashboard.git
- **Version**: v1.21.0-18-rhods-4956-gb8dfd1a2d
- **Branch**: rhoai-3.2
- **Distribution**: RHOAI (also supports ODH)
- **Languages**: TypeScript, Node.js (v22+), React
- **Deployment Type**: Web Application (Frontend + Backend)
- **Build System**: Konflux (RHOAI), Webpack (Frontend), npm workspaces

## Purpose
**Short**: Web-based user interface for Red Hat OpenShift AI and Open Data Hub platform.

**Detailed**: The ODH Dashboard is the primary web console for Red Hat OpenShift AI (RHOAI) and Open Data Hub (ODH). It provides a unified interface for data scientists and ML engineers to manage their data science workflows, including Jupyter notebooks, model serving, data connections, model registries, and distributed workloads. The dashboard integrates with various ODH/RHOAI components such as KServe, Kubeflow Notebooks, Model Registry, and monitoring systems. It features a modular architecture with support for dynamic plugins through module federation, allowing teams to extend functionality independently. The dashboard handles user authentication via OAuth, provides role-based access control, and offers quickstart tutorials to help users get started with the platform.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| Frontend | React Web Application | User interface built with PatternFly components, handles rendering and user interactions |
| Backend | Node.js/Fastify REST API | Provides REST API endpoints, proxies Kubernetes API calls, handles authentication |
| kube-rbac-proxy | Authentication Sidecar | Enforces OAuth authentication, provides TLS termination, injects user/group headers |
| Module Federation | Plugin System | Enables dynamic loading of UI plugins (GenAI, Model Registry, MaaS) at runtime |
| ODH Applications | Custom Resources | Defines available applications and services in the dashboard catalog |
| ODH Documents | Custom Resources | Manages documentation links and learning resources |
| ODH QuickStarts | Custom Resources | Interactive tutorials guiding users through workflows |
| ODH Dashboard Config | Custom Resource | Dashboard feature flags and configuration settings |

## APIs Exposed

### Custom Resource Definitions (CRDs)

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| dashboard.opendatahub.io | v1 | OdhApplication | Namespaced | Defines applications available in the dashboard catalog (e.g., Jupyter, Starburst, NVIDIA tools) |
| opendatahub.io | v1alpha | OdhDashboardConfig | Namespaced | Configuration for dashboard features, notebook sizes, model serving settings, feature flags |
| dashboard.opendatahub.io | v1 | OdhDocument | Namespaced | Documentation links and resources shown in the dashboard |
| console.openshift.io | v1 | OdhQuickStart | Namespaced | Interactive quickstart tutorials for guided workflows |

### HTTP Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| / | GET | 8443/TCP | HTTPS | TLS 1.2+ | OAuth Bearer Token | Serve dashboard frontend |
| /api/* | GET/POST/PATCH/DELETE | 8443/TCP | HTTPS | TLS 1.2+ | OAuth Bearer Token | REST API for Kubernetes resources |
| /api/health | GET | 8080/TCP | HTTP | None | None | Backend health check endpoint |
| /api/k8s/* | GET/POST/PATCH/DELETE | 8443/TCP | HTTPS | TLS 1.2+ | OAuth Bearer Token | Proxy to Kubernetes API server |
| /api/namespaces/* | GET/POST/PATCH/DELETE | 8443/TCP | HTTPS | TLS 1.2+ | OAuth Bearer Token | Namespace management and project operations |
| /api/notebooks/* | GET/POST/DELETE | 8443/TCP | HTTPS | TLS 1.2+ | OAuth Bearer Token | Jupyter notebook management |
| /api/servingRuntimes/* | GET/POST/PATCH/DELETE | 8443/TCP | HTTPS | TLS 1.2+ | OAuth Bearer Token | Model serving runtime management |
| /api/prometheus/* | GET | 8443/TCP | HTTPS | TLS 1.2+ | OAuth Bearer Token | Metrics queries to Prometheus/Thanos |
| /api/modelRegistries/* | GET/POST/PATCH/DELETE | 8443/TCP | HTTPS | TLS 1.2+ | OAuth Bearer Token | Model registry management |
| /api/config | GET | 8443/TCP | HTTPS | TLS 1.2+ | OAuth Bearer Token | Dashboard configuration and feature flags |
| /api/dashboardConfig | GET/PATCH | 8443/TCP | HTTPS | TLS 1.2+ | OAuth Bearer Token | ODH Dashboard configuration CR operations |
| /api/quickstarts | GET | 8443/TCP | HTTPS | TLS 1.2+ | OAuth Bearer Token | List available quickstart tutorials |
| /api/docs | GET | 8443/TCP | HTTPS | TLS 1.2+ | OAuth Bearer Token | List documentation resources |
| /api/components | GET | 8443/TCP | HTTPS | TLS 1.2+ | OAuth Bearer Token | List enabled ODH components |
| /api/builds/* | GET | 8443/TCP | HTTPS | TLS 1.2+ | OAuth Bearer Token | OpenShift Build and BuildConfig operations |
| /api/templates/* | GET/POST | 8443/TCP | HTTPS | TLS 1.2+ | OAuth Bearer Token | OpenShift Template operations |
| /api/status | GET | 8443/TCP | HTTPS | TLS 1.2+ | OAuth Bearer Token | Overall system status information |
| /api/validate-isv | POST | 8443/TCP | HTTPS | TLS 1.2+ | OAuth Bearer Token | Validate ISV credentials |
| /healthz | GET | 8444/TCP | HTTPS | TLS 1.2+ | None | kube-rbac-proxy health check |

### WebSocket Endpoints

| Path | Port | Protocol | Encryption | Auth | Purpose |
|------|------|----------|------------|------|---------|
| /wss/* | 8443/TCP | WSS | TLS 1.2+ | OAuth Bearer Token | WebSocket connections for real-time updates |

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| Node.js | 22.0.0+ | Yes | Runtime for backend and build process |
| Kubernetes | 1.25+ | Yes | Underlying orchestration platform |
| OpenShift | 4.12+ | Yes | OAuth, Routes, ImageStreams, Templates |
| kube-rbac-proxy | latest | Yes | OAuth authentication and authorization |
| React | 18.2.0 | Yes | Frontend framework |
| PatternFly | 6.4.0 | Yes | UI component library |
| Fastify | 4.28.1 | Yes | Backend web framework |
| @kubernetes/client-node | 0.12.2 | Yes | Kubernetes API client library |

### Internal ODH Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| ODH Operator | CRD Watch | Reads DataScienceCluster and DSCInitialization CRs for cluster status |
| KServe | API/CRD | Manages InferenceServices for model serving |
| Kubeflow Notebooks | CRD | Creates and manages Notebook CRs for Jupyter workbenches |
| Model Registry | HTTP API | Proxies requests to model registry service for ML model tracking |
| Prometheus/Thanos | HTTP API | Queries metrics for dashboards and monitoring (port 9092/TCP) |
| OpenShift OAuth | OAuth Flow | User authentication and authorization |
| Service Mesh (Istio) | Network | Optional service mesh integration for secure communications |
| Feature Store (Feast) | CRD | Manages FeatureStore CRs for feature engineering |
| LlamaStack | CRD | Manages LlamaStackDistribution CRs for GenAI workloads |
| NIM Serving | CRD | NVIDIA NIM account and model serving management |

## Network Architecture

### Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| odh-dashboard | ClusterIP | 8443/TCP | 8443 | HTTPS | TLS 1.2+ | OAuth via kube-rbac-proxy | Internal |

### Ingress

| Name | Type | Hosts | Port | Protocol | Encryption | TLS Mode | Exposure |
|------|------|-------|------|----------|------------|----------|----------|
| odh-dashboard | OpenShift Route | Cluster-specific | 8443/TCP | HTTPS | TLS 1.2+ | Reencrypt | External |
| odh-dashboard | HTTPRoute (Gateway API) | Cluster-specific | 8443/TCP | HTTPS | TLS 1.2+ | Passthrough | External |

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token | API operations for all Kubernetes resources |
| Thanos Querier | 9092/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token | Prometheus metrics queries |
| Model Registry Service | 8080/TCP | HTTP/HTTPS | Context-dependent | Bearer Token | Model registry operations |
| Feast Registry Service | 8080/TCP | HTTP/HTTPS | Context-dependent | Bearer Token | Feature store operations |
| OpenShift OAuth Server | 6443/TCP | HTTPS | TLS 1.2+ | OAuth Token | Token validation and user info |
| OpenShift Image Registry | 5000/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token | Image metadata and layer inspection |

### Network Policies

| Name | Type | Selector | Ingress Rules | Egress Rules |
|------|------|----------|---------------|--------------|
| odh-dashboard-allow-ports | NetworkPolicy | deployment: odh-dashboard | Allow all sources to ports 8443, 8043, 8143/TCP | Not restricted |

## Security

### RBAC - Cluster Roles

| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|
| odh-dashboard | "" | nodes | get, list |
| odh-dashboard | "" | configmaps, persistentvolumeclaims, secrets | create, delete, get, list, patch, update, watch |
| odh-dashboard | "" | pods, serviceaccounts, services | get, list, watch |
| odh-dashboard | "" | namespaces | patch |
| odh-dashboard | storage.k8s.io | storageclasses | update, patch |
| odh-dashboard | machine.openshift.io | machineautoscalers, machinesets | get, list |
| odh-dashboard | autoscaling.openshift.io | machineautoscalers | get, list |
| odh-dashboard | config.openshift.io | clusterversions, ingresses | get, watch, list |
| odh-dashboard | operators.coreos.com | clusterserviceversions, subscriptions | get, list, watch |
| odh-dashboard | image.openshift.io | imagestreams/layers | get |
| odh-dashboard | route.openshift.io | routes | get, list, watch |
| odh-dashboard | console.openshift.io | consolelinks | get, list, watch |
| odh-dashboard | operator.openshift.io | consoles | get, list, watch |
| odh-dashboard | integreatly.org | rhmis | get, watch, list |
| odh-dashboard | user.openshift.io | groups, users | get, list, watch |
| odh-dashboard | rbac.authorization.k8s.io | rolebindings, clusterrolebindings, roles | list, get, create, patch, delete |
| odh-dashboard | events.k8s.io | events | get, list, watch |
| odh-dashboard | kubeflow.org | notebooks | get, list, watch, create, update, patch, delete |
| odh-dashboard | datasciencecluster.opendatahub.io | datascienceclusters | list, watch, get |
| odh-dashboard | dscinitialization.opendatahub.io | dscinitializations | list, watch, get |
| odh-dashboard | serving.kserve.io | inferenceservices | get, list, watch |
| odh-dashboard | modelregistry.opendatahub.io | modelregistries | get, list, watch, create, update, patch, delete |
| odh-dashboard | services.platform.opendatahub.io | auths | get |
| odh-dashboard | llamastack.io | llamastackdistributions | get, list, watch |
| odh-dashboard | feast.dev | featurestores | get, list, watch |
| odh-dashboard | authentication.k8s.io | tokenreviews | create |
| odh-dashboard | authorization.k8s.io | subjectaccessreviews | create |

### RBAC - Namespaced Roles

| Role Name | Namespace | API Group | Resources | Verbs |
|-----------|-----------|-----------|-----------|-------|
| odh-dashboard | Dashboard namespace | dashboard.opendatahub.io | acceleratorprofiles | create, get, list, update, patch, delete |
| odh-dashboard | Dashboard namespace | route.openshift.io | routes | get, list, watch |
| odh-dashboard | Dashboard namespace | batch | cronjobs | get, update, delete |
| odh-dashboard | Dashboard namespace | image.openshift.io | imagestreams | create, get, list, update, patch, delete |
| odh-dashboard | Dashboard namespace | build.openshift.io | builds, buildconfigs | list |
| odh-dashboard | Dashboard namespace | apps | deployments | patch, update |
| odh-dashboard | Dashboard namespace | apps.openshift.io | deploymentconfigs, deploymentconfigs/instantiate | get, list, watch, create, update, patch, delete |
| odh-dashboard | Dashboard namespace | opendatahub.io | odhdashboardconfigs | get, list, watch, create, update, patch, delete |
| odh-dashboard | Dashboard namespace | kubeflow.org | notebooks | get, list, watch, create, update, patch, delete |
| odh-dashboard | Dashboard namespace | dashboard.opendatahub.io | odhapplications, odhdocuments | get, list |
| odh-dashboard | Dashboard namespace | console.openshift.io | odhquickstarts | get, list |
| odh-dashboard | Dashboard namespace | template.openshift.io | templates | * (all verbs) |
| odh-dashboard | Dashboard namespace | serving.kserve.io | servingruntimes | * (all verbs) |
| odh-dashboard | Dashboard namespace | nim.opendatahub.io | accounts | get, list, watch, create, update, patch, delete |

### RBAC - Role Bindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| odh-dashboard | Dashboard namespace | odh-dashboard (Role) | odh-dashboard |
| odh-dashboard | Cluster-wide | odh-dashboard (ClusterRole) | odh-dashboard |
| odh-dashboard-auth-delegator | Cluster-wide | system:auth-delegator (ClusterRole) | odh-dashboard |
| odh-dashboard-image-puller | Cluster-wide | system:image-puller (ClusterRole) | odh-dashboard |
| cluster-monitoring-view | Dashboard namespace | cluster-monitoring-view (ClusterRole) | odh-dashboard |

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| dashboard-proxy-tls | kubernetes.io/tls | TLS certificate for kube-rbac-proxy | service.beta.openshift.io/serving-cert-secret-name annotation | Yes (OpenShift) |
| odh-trusted-ca-bundle | Opaque | Trusted CA certificates bundle | OpenShift cluster | Yes |

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| /* (all paths) | ALL | OAuth Bearer Token (OpenShift) | kube-rbac-proxy sidecar | User must have access to dashboard Route |
| /api/* | GET/POST/PATCH/DELETE | OAuth Bearer Token + RBAC | kube-rbac-proxy + Backend | User/group headers injected by proxy, backend enforces resource-level RBAC |
| /api/health | GET | None | Backend only | Public health check |
| /healthz | GET | None | kube-rbac-proxy | Public health check for proxy |

## Data Flows

### Flow 1: User Login and Dashboard Access

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User Browser | OpenShift OAuth Server | 443/TCP | HTTPS | TLS 1.2+ | OpenShift Credentials |
| 2 | OpenShift OAuth Server | User Browser | 443/TCP | HTTPS | TLS 1.2+ | OAuth Token (Cookie) |
| 3 | User Browser | ODH Dashboard Route | 443/TCP | HTTPS | TLS 1.2+ | OAuth Token |
| 4 | Route | kube-rbac-proxy (8443) | 8443/TCP | HTTPS | TLS 1.2+ (reencrypt) | OAuth Token |
| 5 | kube-rbac-proxy | Backend (8080) | 8080/TCP | HTTP | None | X-Auth-Request-User/Groups headers |
| 6 | Backend | Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 7 | Backend | User Browser (via proxy/route) | 8080→8443→443/TCP | HTTP→HTTPS | TLS 1.2+ | OAuth Token |

### Flow 2: Create Jupyter Notebook

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User Browser | Dashboard Backend | 443→8443/TCP | HTTPS | TLS 1.2+ | OAuth Bearer Token |
| 2 | kube-rbac-proxy | Backend API /api/notebooks | 8080/TCP | HTTP | None | User/Group Headers |
| 3 | Backend | Kubernetes API (Notebook CR) | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 4 | Backend | Kubernetes API (PVC, ConfigMap, Secret) | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 5 | Backend | Kubernetes API (RoleBinding) | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 6 | Backend | User Browser (response) | 8080→8443→443/TCP | HTTP→HTTPS | TLS 1.2+ | OAuth Token |

### Flow 3: Query Prometheus Metrics

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User Browser | Dashboard Backend /api/prometheus | 443→8443/TCP | HTTPS | TLS 1.2+ | OAuth Bearer Token |
| 2 | kube-rbac-proxy | Backend API | 8080/TCP | HTTP | None | User/Group Headers |
| 3 | Backend | Thanos Querier Service | 9092/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 4 | Thanos Querier | Backend | 9092/TCP | HTTPS | TLS 1.2+ | Response Data |
| 5 | Backend | User Browser (metrics data) | 8080→8443→443/TCP | HTTP→HTTPS | TLS 1.2+ | OAuth Token |

### Flow 4: Model Registry Operations

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User Browser | Dashboard Backend /api/modelRegistries | 443→8443/TCP | HTTPS | TLS 1.2+ | OAuth Bearer Token |
| 2 | kube-rbac-proxy | Backend API | 8080/TCP | HTTP | None | User/Group Headers |
| 3 | Backend | Kubernetes API (ModelRegistry CR) | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 4 | Backend | Model Registry Service | 8080/TCP | HTTP/HTTPS | Context-dependent | Bearer Token |
| 5 | Backend | User Browser (registry data) | 8080→8443→443/TCP | HTTP→HTTPS | TLS 1.2+ | OAuth Token |

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| Kubernetes API Server | REST API | 6443/TCP | HTTPS | TLS 1.2+ | All resource CRUD operations |
| OpenShift OAuth | OAuth 2.0 | 6443/TCP | HTTPS | TLS 1.2+ | User authentication and token validation |
| Thanos Querier | HTTP API | 9092/TCP | HTTPS | TLS 1.2+ | Metrics queries for monitoring dashboards |
| Model Registry | HTTP API | 8080/TCP | HTTP/HTTPS | Context-dependent | ML model metadata and versioning |
| Feast Registry | HTTP API | 8080/TCP | HTTP/HTTPS | Context-dependent | Feature store metadata |
| KServe Controller | Kubernetes CRD Watch | 6443/TCP | HTTPS | TLS 1.2+ | InferenceService management |
| Kubeflow Notebooks Controller | Kubernetes CRD Watch | 6443/TCP | HTTPS | TLS 1.2+ | Notebook CR management |
| ODH Operator | Kubernetes CRD Watch | 6443/TCP | HTTPS | TLS 1.2+ | Cluster configuration and status |
| OpenShift Build Service | REST API | 6443/TCP | HTTPS | TLS 1.2+ | Trigger and monitor notebook image builds |
| OpenShift Image Registry | REST API | 6443/TCP | HTTPS | TLS 1.2+ | Image metadata and vulnerability scanning |

## Deployment Architecture

### Container Images

| Image | Base | Purpose | Build Method |
|-------|------|---------|--------------|
| odh-dashboard | registry.access.redhat.com/ubi9/nodejs-22 | Main dashboard application | Konflux (Dockerfile.konflux) |
| odh-dashboard-genai | registry.access.redhat.com/ubi9/nodejs-22 | GenAI module federation plugin | Konflux (Dockerfile.konflux.genai) |
| odh-dashboard-modelregistry | registry.access.redhat.com/ubi9/nodejs-22 | Model Registry module federation plugin | Konflux (Dockerfile.konflux.modelregistry) |
| kube-rbac-proxy | gcr.io/kubebuilder/kube-rbac-proxy | OAuth authentication sidecar | Upstream |

### Deployment Configuration

| Parameter | Value | Purpose |
|-----------|-------|---------|
| Replicas | 2 | High availability with pod anti-affinity |
| CPU Request | 500m | Minimum CPU allocation per container |
| CPU Limit | 1000m | Maximum CPU allocation per container |
| Memory Request | 1Gi | Minimum memory allocation per container |
| Memory Limit | 2Gi | Maximum memory allocation per container |
| Liveness Probe | TCP socket :8080 (dashboard), HTTPS :8444 (proxy) | Restart unhealthy containers |
| Readiness Probe | HTTP /api/health :8080 (dashboard), HTTPS :8444 (proxy) | Traffic routing to healthy pods |
| Anti-Affinity | Preferred zone spreading | Distribute pods across availability zones |

## Module Federation Architecture

The dashboard uses Webpack Module Federation to load dynamic plugins at runtime:

| Plugin | Package | Purpose | Port |
|--------|---------|---------|------|
| Core Dashboard | frontend | Main application shell and routing | 8080 |
| GenAI Plugin | packages/gen-ai | GenAI studio and LLM serving UI | Federated |
| Model Registry Plugin | packages/model-registry | Model registry UI components | Federated |
| MaaS Plugin | packages/maas | Model-as-a-Service UI | Federated |
| KServe Plugin | packages/kserve | KServe-specific serving UI | Federated |
| Model Serving Plugin | packages/model-serving | General model serving UI | Federated |

## Feature Flags

Dashboard features can be enabled/disabled via the OdhDashboardConfig CR:

| Feature Flag | Default | Purpose |
|--------------|---------|---------|
| disableProjects | false | Enable/disable project management |
| disableModelServing | false | Enable/disable model serving features |
| disableKServe | false | Enable/disable KServe integration |
| disableModelRegistry | false | Enable/disable model registry integration |
| disableDistributedWorkloads | false | Enable/disable distributed workload features |
| disablePipelines | false | Enable/disable pipeline features |
| disableNIMModelServing | false | Enable/disable NVIDIA NIM serving |
| genAiStudio | false | Enable/disable GenAI studio features |
| modelAsService | false | Enable/disable Model-as-a-Service |
| trainingJobs | false | Enable/disable training jobs UI |

## Recent Changes

| Commit | Date | Changes |
|--------|------|---------|
| b8dfd1a2d | Recent | chore(deps): update registry.access.redhat.com/ubi9/nodejs-22 docker digest to b7c468c |
| bbf20bbb6 | Recent | chore(deps): update registry.access.redhat.com/ubi9/nodejs-22 docker digest to be02478 |
| a6bd87114 | Recent | chore(deps): update registry.access.redhat.com/ubi9-minimal docker digest to 759f5f4 |
| ec6c98202 | Recent | chore(deps): update registry.access.redhat.com/ubi9-minimal docker digest to ecd4751 |
| c3e33cd61 | Recent | chore(deps): update registry.access.redhat.com/ubi9/nodejs-22 docker digest to db36adb |

**Note**: Recent commits primarily focus on dependency updates and security patches for base container images (UBI9/Node.js 22).

## Observability

### Logging

| Component | Log Destination | Format | Level |
|-----------|----------------|--------|-------|
| Backend | stdout | JSON (Pino) | Configurable via LOG_LEVEL env var |
| Frontend | Browser console | Plain text | Development only |

### Metrics

| Endpoint | Port | Protocol | Metrics Format |
|----------|------|----------|----------------|
| (Internal) | 8080/TCP | HTTP | Prometheus (prom-client) |

### Health Checks

| Endpoint | Port | Type | Checks |
|----------|------|------|--------|
| /api/health | 8080/TCP | Readiness/Liveness | Backend service availability |
| /healthz | 8444/TCP | Readiness/Liveness | kube-rbac-proxy health |

## Configuration

### Environment Variables

| Variable | Default | Purpose |
|----------|---------|---------|
| PORT / BACKEND_PORT | 8080 | Backend server listening port |
| IP | 0.0.0.0 | Backend server listening address |
| LOG_LEVEL | info | Backend logging level |
| NODE_ENV | production | Node.js environment mode |
| DEV_MODE | false | Enable development features |
| THANOS_NAMESPACE | openshift-monitoring | Namespace where Thanos is deployed |
| THANOS_INSTANCE_NAME | thanos-querier | Thanos querier service name |
| THANOS_RBAC_PORT | 9092 | Thanos querier RBAC port |
| ODH_LOGO | ../images/rhoai-logo.svg | Dashboard logo (light theme) |
| ODH_LOGO_DARK | ../images/rhoai-logo-dark-theme.svg | Dashboard logo (dark theme) |
| ODH_PRODUCT_NAME | Red Hat OpenShift AI | Product name displayed in UI |
| ODH_FAVICON | rhoai-favicon.svg | Browser favicon |
| DOC_LINK | https://docs.redhat.com/en/documentation/red_hat_openshift_ai/ | Product documentation link |
| SUPPORT_LINK | https://access.redhat.com/support/cases/#/case/new/open-case?caseCreate=true | Support link |

### ConfigMaps

| ConfigMap | Purpose |
|-----------|---------|
| kube-rbac-proxy-config | kube-rbac-proxy configuration file |
| odh-trusted-ca-bundle | Trusted CA certificates for external services |
| federation-configmap | Module federation plugin configuration (modular architecture) |

## Known Limitations

1. **RBAC Scope**: Dashboard service account has broad cluster-level permissions for resource management
2. **OAuth Dependency**: Requires OpenShift OAuth server; not compatible with standalone Kubernetes
3. **Single Namespace Config**: OdhDashboardConfig CR must be in the same namespace as dashboard deployment
4. **No Multi-Tenancy**: Users see all projects they have access to; no built-in tenant isolation
5. **Module Federation**: Plugin loading requires network access to federated module endpoints
6. **Browser Compatibility**: Requires modern browser with ES2020+ support
7. **Image Registry**: OpenShift-specific ImageStream operations not available on vanilla Kubernetes

## Security Considerations

1. **OAuth Integration**: All user requests are authenticated via OpenShift OAuth before reaching backend
2. **RBAC Enforcement**: Backend validates user permissions before Kubernetes API operations
3. **TLS Encryption**: All external traffic uses TLS 1.2+; internal traffic between proxy and backend is unencrypted (localhost)
4. **Service Account**: Runs with dedicated service account with minimal required permissions
5. **Secret Management**: TLS certificates auto-rotated by OpenShift; no manual secret management required
6. **Network Policies**: Restricts ingress to specific ports; egress unrestricted for Kubernetes API access
7. **Content Security**: Frontend uses DOMPurify for XSS protection in user-generated content
8. **Dependency Scanning**: Automated Renovate updates for npm dependencies
