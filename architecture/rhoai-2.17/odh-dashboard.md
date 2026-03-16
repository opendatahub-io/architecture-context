# Component: ODH Dashboard

## Metadata
- **Repository**: https://github.com/red-hat-data-services/odh-dashboard.git
- **Version**: v1.21.0-18-rhods-2865-gfcf2476db
- **Branch**: rhoai-2.17
- **Distribution**: RHOAI (primary), ODH
- **Languages**: TypeScript, JavaScript, React
- **Deployment Type**: Web Application Service

## Purpose
**Short**: Web-based user interface for managing and interacting with Open Data Hub and Red Hat OpenShift AI platform components.

**Detailed**: The ODH Dashboard is the primary user interface for the Open Data Hub and Red Hat OpenShift AI platforms. It provides a unified web console for data scientists and administrators to manage machine learning workloads, including Jupyter notebooks, model serving, data science projects, pipelines, and distributed workloads. The dashboard integrates with various ODH/RHOAI components through Kubernetes APIs and custom resources, offering features like accelerator profile management, model registry integration, serving runtime configuration, and cluster resource monitoring. Built as a React-based frontend with a Node.js/Fastify backend, it serves as both a standalone application and an OpenShift Console dynamic plugin, secured through OAuth proxy for authentication and authorization.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| odh-dashboard (backend) | Node.js/Fastify Service | REST API server providing backend services for dashboard operations |
| odh-dashboard (frontend) | React/TypeScript SPA | Web UI for user interactions with ODH/RHOAI platform |
| oauth-proxy | Sidecar Proxy | OpenShift OAuth authentication and HTTPS termination |
| ConsoleLink | OpenShift Integration | Application menu integration in OpenShift Console |

## APIs Exposed

### Custom Resource Definitions (CRDs)

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| dashboard.opendatahub.io | v1 | OdhApplication | Namespaced | Defines available applications in the dashboard catalog |
| dashboard.opendatahub.io | v1 | OdhDocument | Namespaced | Documentation and tutorial resources for dashboard |
| opendatahub.io | v1alpha | OdhDashboardConfig | Namespaced | Configuration settings for dashboard features and behavior |
| console.openshift.io | v1 | OdhQuickStart | Namespaced | Interactive quick-start tutorials for users |
| dashboard.opendatahub.io | v1, v1alpha (deprecated) | AcceleratorProfile | Namespaced | GPU and accelerator device profiles for workloads |
| dashboard.opendatahub.io | v1alpha1 | HardwareProfile | Namespaced | Hardware configuration profiles for workloads |

### HTTP Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /api/health | GET | 8080/TCP | HTTP | None | None | Backend health check endpoint |
| /api/* | GET/POST/PUT/PATCH/DELETE | 8080/TCP | HTTP | None | Internal | Backend API endpoints (40+ routes) |
| /metrics | GET | 8080/TCP | HTTP | None | Bypass | Prometheus metrics endpoint |
| / | GET | 8080/TCP | HTTP | None | Internal | Static frontend assets |
| /oauth/healthz | GET | 8443/TCP | HTTPS | TLS 1.2+ | None | OAuth proxy health check |
| /* | ALL | 8443/TCP | HTTPS | TLS 1.2+ | OpenShift OAuth | All external traffic via oauth-proxy |
| /api/accelerator-profiles | GET/POST/PUT/DELETE | 8080/TCP | HTTP | None | Internal | Manage accelerator profiles |
| /api/accelerators | GET | 8080/TCP | HTTP | None | Internal | Query available accelerators |
| /api/builds | GET/POST | 8080/TCP | HTTP | None | Internal | Manage notebook image builds |
| /api/cluster-settings | GET | 8080/TCP | HTTP | None | Internal | Retrieve cluster configuration |
| /api/components | GET | 8080/TCP | HTTP | None | Internal | List installed ODH components |
| /api/config | GET | 8080/TCP | HTTP | None | Internal | Dashboard configuration |
| /api/connection-types | GET | 8080/TCP | HTTP | None | Internal | Data connection type definitions |
| /api/console-links | GET | 8080/TCP | HTTP | None | Internal | OpenShift console integration |
| /api/dashboardConfig | GET | 8080/TCP | HTTP | None | Internal | Dashboard feature flags |
| /api/docs | GET | 8080/TCP | HTTP | None | Internal | Documentation resources |
| /api/dsc | GET | 8080/TCP | HTTP | None | Internal | DataScienceCluster status |
| /api/dsci | GET | 8080/TCP | HTTP | None | Internal | DSCInitialization status |
| /api/groups-config | GET | 8080/TCP | HTTP | None | Internal | User group configuration |
| /api/images | GET | 8080/TCP | HTTP | None | Internal | Notebook image streams |
| /api/k8s | Proxy | 8080/TCP | HTTP | None | Internal | Kubernetes API proxy |
| /api/modelRegistries | GET/POST/PUT/DELETE | 8080/TCP | HTTP | None | Internal | Model registry management |
| /api/namespaces | GET/POST | 8080/TCP | HTTP | None | Internal | Data science project management |
| /api/notebooks | GET/POST/PUT/DELETE | 8080/TCP | HTTP | None | Internal | Jupyter notebook workbench management |
| /api/nb-events | WebSocket | 8080/TCP | WS | None | Internal | Notebook event streaming |
| /api/prometheus | Proxy | 8080/TCP | HTTP | None | Internal | Thanos/Prometheus metrics proxy |
| /api/quickstarts | GET | 8080/TCP | HTTP | None | Internal | Interactive tutorial content |
| /api/rolebindings | GET/POST/DELETE | 8080/TCP | HTTP | None | Internal | Project role binding management |
| /api/segment-key | GET | 8080/TCP | HTTP | None | Internal | Analytics tracking configuration |
| /api/service | GET | 8080/TCP | HTTP | None | Internal | Kubernetes service queries |
| /api/servingRuntimes | GET/POST/PUT/DELETE | 8080/TCP | HTTP | None | Internal | Model serving runtime templates |
| /api/status | GET | 8080/TCP | HTTP | None | Internal | Component status information |
| /api/storage-class | GET | 8080/TCP | HTTP | None | Internal | Storage class management |
| /api/templates | GET | 8080/TCP | HTTP | None | Internal | OpenShift template management |
| /api/validate-isv | POST | 8080/TCP | HTTP | None | Internal | ISV partner validation |

### gRPC Services

None - Dashboard does not expose gRPC services.

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| Node.js | >=18.0.0 | Yes | JavaScript runtime for backend and frontend build |
| Fastify | ^4.28.1 | Yes | Web framework for backend API server |
| React | ^18.2.0 | Yes | Frontend UI framework |
| PatternFly | ^6.0.0 | Yes | Red Hat's design system and UI components |
| @kubernetes/client-node | ^0.12.2 | Yes | Kubernetes API client library |
| oauth-proxy | latest | Yes | OpenShift OAuth authentication sidecar |

### Internal ODH Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| opendatahub-operator | CRD/API | Manages DataScienceCluster and DSCInitialization resources |
| kubeflow/notebooks | CRD/API | Creates and manages Jupyter notebook workbenches |
| kserve | CRD/API | Queries InferenceService resources for model serving |
| model-registry | CRD/API | Manages ModelRegistry resources and API integration |
| odh-model-controller | CRD/API | Serving runtime and model deployment management |
| nvidia-gpu-operator | API | Queries GPU availability for accelerator profiles |
| openshift-monitoring | API | Queries Thanos/Prometheus for metrics (port 9092) |
| NIM Operator | CRD/API | Manages NVIDIA NIM account resources |

## Network Architecture

### Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| odh-dashboard | ClusterIP | 8443/TCP | 8443 | HTTPS | TLS 1.2+ | OpenShift OAuth | Internal |

### Ingress

| Name | Type | Hosts | Port | Protocol | Encryption | TLS Mode | Exposure |
|------|------|-------|------|----------|------------|----------|----------|
| odh-dashboard | OpenShift Route | cluster-specific | 443/TCP | HTTPS | TLS 1.2+ | reencrypt | External |

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| kubernetes.default.svc | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token | Kubernetes API access for resource management |
| thanos-querier.openshift-monitoring.svc | 9092/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token | Metrics queries for dashboard analytics |
| model-registry services | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token | Model registry API interactions |
| imagestreams (internal registry) | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token | Notebook image metadata and builds |

## Security

### RBAC - Cluster Roles

| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|
| odh-dashboard | storage.k8s.io | storageclasses | update, patch |
| odh-dashboard | "" | nodes | get, list |
| odh-dashboard | machine.openshift.io, autoscaling.openshift.io | machineautoscalers, machinesets | get, list |
| odh-dashboard | "", config.openshift.io | clusterversions | get, watch, list |
| odh-dashboard | operators.coreos.com | clusterserviceversions, subscriptions | get, list, watch |
| odh-dashboard | "", image.openshift.io | imagestreams/layers | get |
| odh-dashboard | "" | configmaps, persistentvolumeclaims, secrets | create, delete, get, list, patch, update, watch |
| odh-dashboard | route.openshift.io | routes | get, list, watch |
| odh-dashboard | console.openshift.io | consolelinks | get, list, watch |
| odh-dashboard | operator.openshift.io | consoles | get, list, watch |
| odh-dashboard | "", integreatly.org | rhmis | get, watch, list |
| odh-dashboard | user.openshift.io | groups, users | get, list, watch |
| odh-dashboard | "" | pods, serviceaccounts, services | get, list, watch |
| odh-dashboard | "" | namespaces | patch |
| odh-dashboard | rbac.authorization.k8s.io | rolebindings, clusterrolebindings, roles | get, list, watch, create, update, patch, delete |
| odh-dashboard | "", events.k8s.io | events | get, list, watch |
| odh-dashboard | kubeflow.org | notebooks | get, list, watch, create, update, patch, delete |
| odh-dashboard | datasciencecluster.opendatahub.io | datascienceclusters | list, watch, get |
| odh-dashboard | dscinitialization.opendatahub.io | dscinitializations | list, watch, get |
| odh-dashboard | serving.kserve.io | inferenceservices | get, list, watch |
| odh-dashboard | modelregistry.opendatahub.io | modelregistries | get, list, watch, create, update, patch, delete |
| odh-dashboard | nim.opendatahub.io | accounts | get, list, watch, create, update, patch, delete |
| odh-dashboard | "" | endpoints | get |
| odh-dashboard | services.platform.opendatahub.io | auths | get |

### RBAC - Namespace Roles

| Role Name | API Group | Resources | Verbs | Scope |
|-----------|-----------|-----------|-------|-------|
| odh-dashboard | dashboard.opendatahub.io | acceleratorprofiles | create, get, list, update, patch, delete | Namespace |
| odh-dashboard | route.openshift.io | routes | get, list, watch | Namespace |
| odh-dashboard | kfdef.apps.kubeflow.org | kfdefs | get, list, watch | Namespace |
| odh-dashboard | batch | cronjobs, jobs, jobs/status | create, delete, get, list, patch, update, watch | Namespace |
| odh-dashboard | image.openshift.io | imagestreams | create, get, list, update, patch, delete | Namespace |
| odh-dashboard | build.openshift.io | builds, buildconfigs, buildconfigs/instantiate | get, list, watch, create, patch, delete | Namespace |
| odh-dashboard | apps | deployments | patch, update | Namespace |
| odh-dashboard | apps.openshift.io | deploymentconfigs, deploymentconfigs/instantiate | get, list, watch, create, update, patch, delete | Namespace |
| odh-dashboard | opendatahub.io | odhdashboardconfigs | get, list, watch, create, update, patch, delete | Namespace |
| odh-dashboard | kubeflow.org | notebooks | get, list, watch, create, update, patch, delete | Namespace |
| odh-dashboard | dashboard.opendatahub.io | odhapplications, odhdocuments | get, list | Namespace |
| odh-dashboard | console.openshift.io | odhquickstarts | get, list | Namespace |
| odh-dashboard | template.openshift.io | templates | * | Namespace |
| odh-dashboard | serving.kserve.io | servingruntimes | * | Namespace |

### RBAC - Role Bindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| odh-dashboard | deployment namespace | odh-dashboard (ClusterRole) | odh-dashboard |
| odh-dashboard | deployment namespace | odh-dashboard (Role) | odh-dashboard |
| odh-dashboard-auth-delegator | kube-system | system:auth-delegator | odh-dashboard |
| odh-dashboard-cluster-monitoring-view | deployment namespace | cluster-monitoring-view | odh-dashboard |
| odh-dashboard-model-serving | deployment namespace | odh-dashboard-model-serving | odh-dashboard |
| odh-dashboard-image-puller | deployment namespace | system:image-puller | odh-dashboard |

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| dashboard-proxy-tls | kubernetes.io/tls | TLS certificate for oauth-proxy HTTPS | service.alpha.openshift.io/serving-cert | Yes |
| dashboard-oauth-config-generated | Opaque | OAuth proxy cookie secret | Operator/Manual | No |
| dashboard-oauth-client-generated | Opaque | OAuth client secret for OpenShift | Operator/Manual | No |

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| /* (external) | ALL | OpenShift OAuth (Bearer Token) | oauth-proxy sidecar | User must list projects |
| /api/* (internal) | ALL | x-forwarded-access-token header | Backend validates token | ServiceAccount permissions |
| /metrics | GET | None (bypassed) | oauth-proxy skip-auth-regex | Public within cluster |
| /oauth/healthz | GET | None | oauth-proxy | Public within cluster |
| /api/health | GET | None | Backend | Public within pod network |

## Data Flows

### Flow 1: User Dashboard Access

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User Browser | odh-dashboard Route | 443/TCP | HTTPS | TLS 1.2+ | None |
| 2 | Route | odh-dashboard Service | 8443/TCP | HTTPS | TLS 1.2+ (reencrypt) | None |
| 3 | Service | oauth-proxy (Pod) | 8443/TCP | HTTPS | TLS 1.2+ | OpenShift OAuth redirect |
| 4 | oauth-proxy | OpenShift OAuth Server | 443/TCP | HTTPS | TLS 1.2+ | OAuth flow |
| 5 | oauth-proxy | odh-dashboard backend | 8080/TCP | HTTP | None (localhost) | Bearer Token (header) |
| 6 | Backend | Kubernetes API | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |

### Flow 2: Notebook Creation

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User (UI) | odh-dashboard backend | 8080/TCP | HTTP | None (via oauth-proxy) | Bearer Token |
| 2 | Backend | Kubernetes API (notebooks CRD) | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 3 | Backend | Kubernetes API (PVC) | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 4 | Backend | Kubernetes API (ConfigMap) | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 5 | Backend | User Browser (response) | 8080/TCP | HTTP | None (via oauth-proxy) | Bearer Token |

### Flow 3: Metrics Query

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User (UI) | odh-dashboard backend | 8080/TCP | HTTP | None (via oauth-proxy) | Bearer Token |
| 2 | Backend | thanos-querier.openshift-monitoring | 9092/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 3 | thanos-querier | Prometheus | 9091/TCP | HTTPS | TLS 1.2+ | Internal auth |
| 4 | Backend | User Browser (response) | 8080/TCP | HTTP | None (via oauth-proxy) | Bearer Token |

### Flow 4: Model Registry Integration

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User (UI) | odh-dashboard backend | 8080/TCP | HTTP | None (via oauth-proxy) | Bearer Token |
| 2 | Backend | Kubernetes API (ModelRegistry CRD) | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 3 | Backend | Model Registry Service | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 4 | Backend | User Browser (response) | 8080/TCP | HTTP | None (via oauth-proxy) | Bearer Token |

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| Kubernetes API Server | REST API | 443/TCP | HTTPS | TLS 1.2+ | Resource CRUD operations and watches |
| OpenShift OAuth Server | OAuth 2.0 | 443/TCP | HTTPS | TLS 1.2+ | User authentication and authorization |
| Thanos Querier | REST API (Prometheus) | 9092/TCP | HTTPS | TLS 1.2+ | Metrics queries for performance monitoring |
| Model Registry Service | REST API | 443/TCP | HTTPS | TLS 1.2+ | Model versioning and metadata management |
| OpenShift Image Registry | REST API | 443/TCP | HTTPS | TLS 1.2+ | Notebook image metadata and builds |
| Kubeflow Notebook Controller | Kubernetes Watch | 443/TCP | HTTPS | TLS 1.2+ | Notebook lifecycle management |
| KServe Controller | Kubernetes Watch | 443/TCP | HTTPS | TLS 1.2+ | Model serving deployment status |
| OpenShift Console | ConsoleLink CRD | N/A | N/A | N/A | Application menu integration |

## Recent Changes

| Commit | Date | Changes |
|--------|------|---------|
| fcf2476db | Recent | - Merge pull request for Konflux SA migration |
| da32e9ba4 | Recent | - Konflux build pipeline service account migration<br>- Signed-off by konflux automation |
| cc76ed322 | Recent | - Update Konflux references |
| da8fcd857 | Recent | - chore(deps): update konflux references |
| a4c849ece | Recent | - chore(deps): update konflux references to b9cb1e1 |
| f0ad17765 | Recent | - chore(deps): update konflux references to b9cb1e1 |
| 047398bf1 | Recent | - chore(deps): update konflux references to 944e769 |
| 4cdbc8492 | Recent | - chore(deps): update konflux references |
| 3e34f99f3 | Recent | - chore(deps): update konflux references |
| dbd05ab39 | Recent | - chore(deps): update konflux references to 8b6f22f |
| 5b6ef8b03 | Recent | - chore(deps): update konflux references |
| 82577861a | Recent | - chore(deps): update konflux references to 5bc6129 |
| 2bebad3b7 | Recent | - chore(deps): update UBI8 nodejs-18 docker digest |
| bc5957c8b | Recent | - chore(deps): update konflux references to b78123a |
| 59b48e1e3 | Recent | - chore(deps): update konflux references |
| bea9bda1c | Recent | - chore(deps): update konflux references to 5a78c42 |
| c72c1c5f8 | Recent | - chore(deps): update konflux references |
| 2ab5fa5c1 | Recent | - chore(deps): update konflux references |
| 39cbe3099 | Recent | - chore(deps): update konflux references to e603b3d |
| 5f81c81df | Recent | - Merge pull request from v2.30.0-fixes |

## Build and Deployment

### Container Build

The dashboard is built using **Dockerfile.konflux** (Konflux CI/CD pipeline):
- **Base Image**: registry.access.redhat.com/ubi8/nodejs-18
- **Build Process**: Multi-stage build (builder + runtime)
- **Builder Stage**:
  - Installs all dependencies via `npm ci --omit=optional`
  - Sets RHOAI branding (logo, product name, documentation links)
  - Builds frontend static assets via `npm run build`
  - Compiles backend TypeScript to JavaScript
- **Runtime Stage**:
  - Copies compiled backend and frontend artifacts
  - Installs production dependencies only (`npm ci --omit=dev --omit=optional`)
  - Runs as non-root user (UID 1001)
  - Exposes port 8080
  - Starts backend server via `npm run start`

### Deployment Architecture

- **Replicas**: 2 (high availability)
- **Pod Anti-Affinity**: Preferred across availability zones
- **Resource Requests**: 500m CPU, 1Gi memory (per container)
- **Resource Limits**: 1000m CPU, 2Gi memory (per container)
- **Liveness Probe**: TCP socket check on port 8080 (backend), HTTPS /oauth/healthz on 8443 (oauth-proxy)
- **Readiness Probe**: HTTP GET /api/health on port 8080 (backend), HTTPS /oauth/healthz on 8443 (oauth-proxy)
- **Volume Mounts**:
  - `/etc/pki/tls/certs/odh-trusted-ca-bundle.crt` (ConfigMap: odh-trusted-ca-bundle)
  - `/etc/pki/tls/certs/odh-ca-bundle.crt` (ConfigMap: odh-trusted-ca-bundle)
  - `/etc/tls/private` (Secret: dashboard-proxy-tls, oauth-proxy only)
  - `/etc/oauth/config` (Secret: dashboard-oauth-config-generated, oauth-proxy only)
  - `/etc/oauth/client` (Secret: dashboard-oauth-client-generated, oauth-proxy only)

### Kustomize Structure

- **Base**: `manifests/core-bases/base/` - Core deployment resources
- **Common**: `manifests/common/` - CRDs, applications, connection types
- **Overlays**:
  - `manifests/odh/` - Open Data Hub deployment configuration
  - `manifests/rhoai/addon/` - RHOAI Managed (cloud) configuration
  - `manifests/rhoai/onprem/` - RHOAI Self-Managed configuration

## Configuration

### Environment Variables (Backend)

- `PORT` / `BACKEND_PORT`: Backend listen port (default: 8080)
- `IP`: Bind address (default: 0.0.0.0)
- `LOG_LEVEL` / `FASTIFY_LOG_LEVEL`: Logging verbosity (default: info)
- `APP_ENV`: Application environment (development/production)
- `DEV_IMPERSONATE_USER`: Development user impersonation (dev only)
- `OC_PROJECT`: Development namespace (dev only)

### Environment Variables (Frontend Build)

- `ODH_LOGO`: Dashboard logo path (RHOAI: ../images/rhoai-logo.svg)
- `ODH_LOGO_DARK`: Dark theme logo path (RHOAI: ../images/rhoai-logo-dark-theme.svg)
- `ODH_PRODUCT_NAME`: Product display name (RHOAI: "Red Hat OpenShift AI")
- `ODH_FAVICON`: Favicon filename (RHOAI: rhoai-favicon.svg)
- `DOC_LINK`: Documentation URL (RHOAI: Red Hat docs)
- `SUPPORT_LINK`: Support URL (RHOAI: Red Hat support portal)
- `COMMUNITY_LINK`: Community URL (empty for RHOAI)

### Feature Flags (OdhDashboardConfig)

- `enablement`: Enable/disable dashboard
- `disableInfo`: Hide info sections
- `disableSupport`: Hide support links
- `disableClusterManager`: Disable cluster management features
- `disableTracking`: Disable analytics tracking
- `disableBYONImageStream`: Disable bring-your-own-notebook images
- `disableISVBadges`: Hide ISV partner badges
- `disableUserManagement`: Disable user management UI
- `disableHome`: Hide home page
- `disableProjects`: Disable data science projects
- `disableModelServing`: Disable model serving features
- `disableProjectSharing`: Disable project sharing
- `disableCustomServingRuntimes`: Disable custom serving runtime creation
- `disablePipelines`: Disable pipeline features
- `disableTrustyBiasMetrics`: Disable TrustyAI bias metrics
- `disablePerformanceMetrics`: Disable performance metrics
- `disableKServe`: Disable KServe integration
- `disableKServeAuth`: Disable KServe authentication
- `disableKServeMetrics`: Disable KServe metrics
- `disableModelMesh`: Disable ModelMesh serving
- `disableAcceleratorProfiles`: Disable accelerator profiles
- `disableHardwareProfiles`: Disable hardware profiles
- `disableDistributedWorkloads`: Disable distributed workloads (Ray, CodeFlare)
- `disableModelRegistry`: Disable model registry integration
- `disableModelRegistrySecureDB`: Disable secure model registry database
- `disableServingRuntimeParams`: Disable serving runtime parameters
- `disableStorageClasses`: Disable storage class management
- `disableNIMModelServing`: Disable NVIDIA NIM model serving

## Monitoring and Observability

### Metrics

- **Endpoint**: `/metrics` (bypasses authentication)
- **Format**: Prometheus text format
- **Library**: prom-client (v14.0.1)
- **Scraping**: Automatic via ServiceMonitor (if configured)

### Logging

- **Backend**: Pino structured JSON logging
- **Log Level**: Configurable via LOG_LEVEL env var (default: info)
- **Redacted Fields**: Authorization headers, tokens
- **Development**: Pretty-printed colored output via pino-pretty
- **Production**: JSON format for log aggregation
- **Admin Activity Log**: File-based logging at `/usr/src/app/logs/adminActivity.log`

### Health Checks

- **Readiness**: `GET /api/health` (HTTP 200 if backend healthy)
- **Liveness**: TCP socket check on port 8080 (backend), HTTPS GET /oauth/healthz (oauth-proxy)
- **Startup Delay**: 30 seconds initial delay for both probes
- **Probe Period**: 30 seconds (backend), 5 seconds (oauth-proxy)
- **Timeout**: 15 seconds (backend), 1 second (oauth-proxy)
- **Failure Threshold**: 3 consecutive failures

## Notes

- The dashboard serves as both a standalone web application and can integrate into the OpenShift Console via the ConsoleLink resource
- OAuth proxy provides secure authentication via OpenShift OAuth server, delegating project list authorization
- Backend uses service account token to interact with Kubernetes/OpenShift APIs on behalf of authenticated users
- WebSocket support enables real-time notebook event streaming for improved user experience
- The component manages its own CRDs (OdhApplication, OdhDocument, etc.) and watches external CRDs (Notebooks, InferenceServices)
- RBAC permissions are extensive, covering cluster-wide and namespace-scoped resources for full platform management
- Recent commits focus on Konflux CI/CD pipeline updates, indicating active RHOAI build automation
- No NetworkPolicy or service mesh (Istio) policies are defined in manifests; security relies on OpenShift RBAC and OAuth
- The dashboard acts as a central integration point for all RHOAI/ODH components, providing unified user experience
