# Component: ODH Dashboard

## Metadata
- **Repository**: https://github.com/red-hat-data-services/odh-dashboard
- **Version**: v1.21.0-18-rhods-2466
- **Distribution**: Both ODH and RHOAI
- **Languages**: TypeScript, JavaScript, Node.js
- **Deployment Type**: Web Application (Frontend + Backend Service)

## Purpose
**Short**: Web-based dashboard providing unified UI for managing Open Data Hub and Red Hat OpenShift AI components, data science projects, and ML workloads.

**Detailed**: The ODH Dashboard is the primary user interface for Open Data Hub and Red Hat OpenShift AI platforms. It provides a comprehensive web-based console for data scientists and administrators to manage the full lifecycle of data science workflows. The dashboard enables users to create and manage data science projects, launch Jupyter notebooks with custom configurations, deploy and monitor ML models through KServe and ModelMesh, configure accelerator profiles for GPU workloads, manage data connections, and access integrated partner applications. It serves as a centralized control plane that abstracts the complexity of underlying Kubernetes resources and provides guided workflows, quickstarts, and documentation to help users be productive quickly.

The dashboard architecture consists of a React-based frontend using PatternFly components for consistent OpenShift UX, and a Fastify Node.js backend that communicates with the Kubernetes API server to manage custom resources and orchestrate platform components. Authentication is handled via OpenShift OAuth proxy, providing seamless SSO integration with the cluster identity provider.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| Frontend | React SPA | User interface built with PatternFly components, served as static files |
| Backend | Node.js/Fastify API | REST API server for Kubernetes operations and business logic |
| OAuth Proxy | Security Sidecar | OpenShift OAuth authentication and authorization proxy |
| Static Assets | Static Files | Images, CSS, JavaScript bundles served to browser |

## APIs Exposed

### Custom Resource Definitions (CRDs)

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| opendatahub.io | v1alpha | OdhDashboardConfig | Namespaced | Dashboard configuration including feature flags, group permissions, notebook/model server sizes |
| dashboard.opendatahub.io | v1 | OdhApplication | Namespaced | Application catalog entries for integrated tools and partner solutions |
| dashboard.opendatahub.io | v1 | OdhDocument | Namespaced | Documentation resources and how-to guides displayed in dashboard |
| console.openshift.io | v1 | OdhQuickStart | Namespaced | Interactive guided tours and tutorials for dashboard features |
| dashboard.opendatahub.io | v1, v1alpha | AcceleratorProfile | Namespaced | GPU/accelerator configurations with tolerations for workload scheduling |

### HTTP Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /api/config | GET, PATCH | 8080/TCP | HTTP | None | ServiceAccount | Retrieve and update dashboard configuration |
| /api/status | GET | 8080/TCP | HTTP | None | ServiceAccount | Component status and enablement |
| /api/components | GET | 8080/TCP | HTTP | None | ServiceAccount | Installed component information |
| /api/dashboardConfig | GET | 8080/TCP | HTTP | None | ServiceAccount | Dashboard-specific configuration |
| /api/dsc | GET | 8080/TCP | HTTP | None | ServiceAccount | DataScienceCluster CR status |
| /api/dsci | GET | 8080/TCP | HTTP | None | ServiceAccount | DSCInitialization CR status |
| /api/namespaces | GET, POST, PATCH, DELETE | 8080/TCP | HTTP | None | ServiceAccount | Data science project/namespace management |
| /api/notebooks | GET | 8080/TCP | HTTP | None | ServiceAccount | Jupyter notebook resource management |
| /api/nb-events/:namespace/:notebookName | GET | 8080/TCP | HTTP | None | ServiceAccount | Notebook pod events and logs |
| /api/templates | GET, POST, PATCH, DELETE | 8080/TCP | HTTP | None | ServiceAccount | Notebook image templates |
| /api/accelerator-profiles | GET | 8080/TCP | HTTP | None | ServiceAccount | GPU/accelerator profile management |
| /api/accelerators | GET | 8080/TCP | HTTP | None | ServiceAccount | Available accelerator devices |
| /api/modelRegistries | GET, POST, PATCH, DELETE | 8080/TCP | HTTP | None | ServiceAccount | Model registry instances |
| /api/modelRegistryRoleBindings | GET, POST, DELETE | 8080/TCP | HTTP | None | ServiceAccount | Model registry RBAC bindings |
| /api/servingRuntimes | POST | 8080/TCP | HTTP | None | ServiceAccount | KServe serving runtime management |
| /api/service/:namespace/:name | GET | 8080/TCP | HTTP | None | ServiceAccount | Kubernetes service details |
| /api/builds/:namespace/:buildId | GET | 8080/TCP | HTTP | None | ServiceAccount | Build status for custom images |
| /api/images/:namespace/:imageId | GET | 8080/TCP | HTTP | None | ServiceAccount | ImageStream details |
| /api/connection-types | GET, POST, PUT, PATCH, DELETE | 8080/TCP | HTTP | None | ServiceAccount | Data connection type management |
| /api/storage-class | PUT | 8080/TCP | HTTP | None | ServiceAccount | StorageClass metadata updates |
| /api/groups-config | GET, PUT | 8080/TCP | HTTP | None | ServiceAccount | Admin and allowed group configuration |
| /api/quickstarts | GET | 8080/TCP | HTTP | None | ServiceAccount | Quickstart tutorials |
| /api/docs | GET | 8080/TCP | HTTP | None | ServiceAccount | Documentation resources |
| /api/validate-isv | GET | 8080/TCP | HTTP | None | ServiceAccount | ISV partner application validation |
| /api/prometheus | GET | 8080/TCP | HTTP | None | ServiceAccount | Prometheus metrics queries |
| /api/health | GET | 8080/TCP | HTTP | None | None | Liveness/readiness health check |
| / | GET | 8443/TCP | HTTPS | TLS 1.2+ | OAuth (Bearer Token) | Proxied dashboard UI (via oauth-proxy) |
| /api/* | All | 8443/TCP | HTTPS | TLS 1.2+ | OAuth (Bearer Token) | Proxied backend API (via oauth-proxy) |
| /metrics | GET | 8443/TCP | HTTPS | TLS 1.2+ | None | Prometheus metrics endpoint (auth skipped) |
| /oauth/healthz | GET | 8443/TCP | HTTPS | TLS 1.2+ | None | OAuth proxy health check |

### gRPC Services

| Service | Port | Protocol | Encryption | Auth | Purpose |
|---------|------|----------|------------|------|---------|
| N/A | N/A | N/A | N/A | N/A | No gRPC services exposed |

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| Node.js | >=18.0.0 | Yes | JavaScript runtime for backend |
| React | ^18.2.0 | Yes | Frontend UI framework |
| Fastify | ^4.28.1 | Yes | Backend HTTP server framework |
| PatternFly React | ^5.4.0 | Yes | UI component library |
| @kubernetes/client-node | ^0.12.2 | Yes | Kubernetes API client library |
| @openshift/dynamic-plugin-sdk | ^4.0.0 | Yes | OpenShift console plugin integration |
| OAuth Proxy | latest | Yes | OpenShift authentication proxy container |

### Internal ODH Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| DataScienceCluster Operator | CRD API (datasciencecluster.opendatahub.io) | Monitor DSC status and component enablement |
| DSCInitialization Operator | CRD API (dscinitialization.opendatahub.io) | Platform initialization configuration |
| KServe | CRD API (serving.kserve.io) | Deploy and manage inference services |
| Kubeflow Notebooks | CRD API (kubeflow.org) | Create and manage Jupyter notebook pods |
| Model Registry Operator | CRD API (modelregistry.opendatahub.io) | Model registry lifecycle management |
| Prometheus | HTTP API | Query component metrics and health |
| OpenShift Console | ConsoleLink CR (console.openshift.io) | Add dashboard link to OpenShift console |
| OpenShift OAuth Server | OAuth API | User authentication and authorization |
| OpenShift Image Registry | ImageStream API (image.openshift.io) | Notebook image management |
| OpenShift Builds | Build API (build.openshift.io) | Custom notebook image builds |

## Network Architecture

### Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| odh-dashboard | ClusterIP | 8443/TCP | 8443 | HTTPS | TLS 1.2+ | OAuth | Internal |

### Ingress

| Name | Type | Hosts | Port | Protocol | Encryption | TLS Mode | Exposure |
|------|------|-------|------|----------|------------|----------|----------|
| odh-dashboard | OpenShift Route | Cluster-specific | 443/TCP | HTTPS | TLS 1.2+ | Reencrypt | External |

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| kubernetes.default.svc | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token | Kubernetes API operations |
| prometheus-k8s.openshift-monitoring.svc | 9091/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token | Metrics queries |
| Model Registry Services | 443/TCP | HTTPS | TLS 1.2+ | Bearer Token | Model registry API access |
| KServe InferenceServices | 443/TCP | HTTPS | TLS 1.2+ | Bearer Token | Inference service status |
| Partner ISV Services | 443/TCP | HTTPS | TLS 1.2+ | Varies | ISV application validation |

## Security

### RBAC - Cluster Roles

| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|
| odh-dashboard | "" | nodes | get, list |
| odh-dashboard | "" | configmaps, persistentvolumeclaims, secrets | create, delete, get, list, patch, update, watch |
| odh-dashboard | "" | pods, serviceaccounts, services | get, list, watch |
| odh-dashboard | "" | namespaces | get, list, watch, create, update, patch, delete |
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
| odh-dashboard | rbac.authorization.k8s.io | rolebindings, clusterrolebindings, roles | get, list, watch, create, update, patch, delete |
| odh-dashboard | kubeflow.org | notebooks | get, list, watch, create, update, patch, delete |
| odh-dashboard | datasciencecluster.opendatahub.io | datascienceclusters | list, watch, get |
| odh-dashboard | dscinitialization.opendatahub.io | dscinitializations | list, watch, get |
| odh-dashboard | serving.kserve.io | inferenceservices | get, list, watch |
| odh-dashboard | modelregistry.opendatahub.io | modelregistries | get, list, watch, create, update, patch, delete |

### RBAC - Namespace Roles

| Role Name | Namespace | API Group | Resources | Verbs |
|-----------|-----------|-----------|-----------|-------|
| odh-dashboard | Dashboard NS | dashboard.opendatahub.io | acceleratorprofiles | create, get, list, update, patch, delete |
| odh-dashboard | Dashboard NS | route.openshift.io | routes | get, list, watch |
| odh-dashboard | Dashboard NS | kfdef.apps.kubeflow.org | kfdefs | get, list, watch |
| odh-dashboard | Dashboard NS | batch | cronjobs, jobs, jobs/status | create, delete, get, list, patch, update, watch |
| odh-dashboard | Dashboard NS | image.openshift.io | imagestreams | create, get, list, update, patch, delete |
| odh-dashboard | Dashboard NS | build.openshift.io | builds, buildconfigs, buildconfigs/instantiate | get, list, watch, create, patch, delete |
| odh-dashboard | Dashboard NS | apps | deployments | patch, update |
| odh-dashboard | Dashboard NS | apps.openshift.io | deploymentconfigs, deploymentconfigs/instantiate | get, list, watch, create, update, patch, delete |
| odh-dashboard | Dashboard NS | opendatahub.io | odhdashboardconfigs | get, list, watch, create, update, patch, delete |
| odh-dashboard | Dashboard NS | kubeflow.org | notebooks | get, list, watch, create, update, patch, delete |
| odh-dashboard | Dashboard NS | dashboard.opendatahub.io | odhapplications, odhdocuments | get, list |
| odh-dashboard | Dashboard NS | console.openshift.io | odhquickstarts | get, list |
| odh-dashboard | Dashboard NS | template.openshift.io | templates | * |
| odh-dashboard | Dashboard NS | serving.kserve.io | servingruntimes | * |

### RBAC - Role Bindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| odh-dashboard | Dashboard NS | odh-dashboard (Role) | odh-dashboard |
| odh-dashboard | Cluster | odh-dashboard (ClusterRole) | odh-dashboard (Dashboard NS) |
| odh-dashboard-monitoring | Cluster | cluster-monitoring-view | odh-dashboard (Dashboard NS) |
| system:auth-delegator | Cluster | system:auth-delegator | odh-dashboard (Dashboard NS) |
| odh-dashboard-image-puller | Cluster | system:image-puller | odh-dashboard (Dashboard NS) |

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| dashboard-proxy-tls | kubernetes.io/tls | TLS certificate for service serving cert | service.alpha.openshift.io/serving-cert-secret-name | Yes |
| dashboard-oauth-config-generated | Opaque | OAuth cookie secret | Dashboard deployment | No |
| dashboard-oauth-client-generated | Opaque | OAuth client secret | Dashboard deployment | No |

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| / (All UI/API) | All | OpenShift OAuth (Bearer Token) | oauth-proxy sidecar | Projects list permission required |
| /api/* | All | OpenShift OAuth (Bearer Token) | oauth-proxy sidecar | Delegated to K8s RBAC via openshift-delegate-urls |
| /metrics | GET | None (skipped) | oauth-proxy sidecar | skip-auth-regex=^/metrics |
| /api/health | GET | None | Backend | No authentication required |
| Internal port 8080 | All | ServiceAccount Token | Backend | Uses in-cluster K8s client |

## Data Flows

### Flow 1: User Login and Dashboard Access

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User Browser | odh-dashboard Route | 443/TCP | HTTPS | TLS 1.2+ | None |
| 2 | HAProxy Router | oauth-proxy | 8443/TCP | HTTPS | TLS 1.2+ (service cert) | None |
| 3 | oauth-proxy | OpenShift OAuth Server | 443/TCP | HTTPS | TLS 1.2+ | OAuth flow |
| 4 | oauth-proxy | odh-dashboard backend | 8080/TCP | HTTP | None | Bearer Token (proxied) |
| 5 | User Browser | odh-dashboard frontend | 443/TCP | HTTPS | TLS 1.2+ | Bearer Token (cookie) |

### Flow 2: API Request to Kubernetes

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User Browser | oauth-proxy | 8443/TCP | HTTPS | TLS 1.2+ | Bearer Token (cookie) |
| 2 | oauth-proxy | odh-dashboard backend | 8080/TCP | HTTP | None | Bearer Token (header) |
| 3 | odh-dashboard backend | kubernetes.default.svc | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 4 | kubernetes.default.svc | odh-dashboard backend | 443/TCP | HTTPS | TLS 1.2+ | Response |
| 5 | odh-dashboard backend | oauth-proxy | 8080/TCP | HTTP | None | JSON Response |
| 6 | oauth-proxy | User Browser | 8443/TCP | HTTPS | TLS 1.2+ | JSON Response |

### Flow 3: Metrics Collection

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Prometheus | odh-dashboard Route | 443/TCP | HTTPS | TLS 1.2+ | None (skip-auth-regex) |
| 2 | HAProxy Router | oauth-proxy | 8443/TCP | HTTPS | TLS 1.2+ | None |
| 3 | oauth-proxy | odh-dashboard backend | 8080/TCP | HTTP | None | None (skipped) |
| 4 | odh-dashboard backend | Prometheus client | N/A | N/A | N/A | Metrics scraped |

### Flow 4: Notebook Creation

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User Browser | oauth-proxy | 8443/TCP | HTTPS | TLS 1.2+ | Bearer Token |
| 2 | oauth-proxy | odh-dashboard backend | 8080/TCP | HTTP | None | Bearer Token |
| 3 | odh-dashboard backend | kubernetes.default.svc | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 4 | kubernetes.default.svc | Kubeflow Notebooks Operator | N/A | N/A | N/A | Notebook CR created |
| 5 | odh-dashboard backend | User Browser | 8443/TCP | HTTPS | TLS 1.2+ | Success response |

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| Kubernetes API Server | REST API | 443/TCP | HTTPS | TLS 1.2+ | All resource operations (CRDs, namespaces, pods, etc.) |
| OpenShift OAuth Server | OAuth 2.0 | 443/TCP | HTTPS | TLS 1.2+ | User authentication and token validation |
| Prometheus | REST API | 9091/TCP | HTTPS | TLS 1.2+ | Query component metrics and status |
| OpenShift Console | ConsoleLink CR | N/A | N/A | N/A | Add dashboard link to console menu |
| KServe Operator | Kubernetes Watch API | 443/TCP | HTTPS | TLS 1.2+ | Monitor InferenceService status |
| Kubeflow Notebooks Operator | Kubernetes Watch API | 443/TCP | HTTPS | TLS 1.2+ | Monitor Notebook CR status |
| Model Registry Operator | Kubernetes CRUD API | 443/TCP | HTTPS | TLS 1.2+ | Manage ModelRegistry CRs |
| DSC/DSCI Operators | Kubernetes Watch API | 443/TCP | HTTPS | TLS 1.2+ | Platform component status monitoring |
| OpenShift Image Registry | ImageStream API | 443/TCP | HTTPS | TLS 1.2+ | Notebook image catalog management |
| OpenShift Build Service | Build API | 443/TCP | HTTPS | TLS 1.2+ | Custom image build orchestration |

## Container Images

### Production Image (Konflux)

| Build File | Base Image | Ports | Purpose |
|-----------|------------|-------|---------|
| Dockerfile.konflux | registry.access.redhat.com/ubi8/nodejs-18 | 8080/TCP | Multi-stage build for RHOAI production deployment |

**Build Stages:**
1. **Builder**: Installs dependencies, builds frontend and backend
2. **Runtime**: Copies compiled assets, runs production server

**Environment Variables:**
- `ODH_LOGO`: Product logo path (rhoai-logo.svg for RHOAI)
- `ODH_PRODUCT_NAME`: Product name (Red Hat OpenShift AI)
- `ODH_FAVICON`: Favicon file
- `DOC_LINK`: Documentation URL
- `SUPPORT_LINK`: Support case creation URL
- `COMMUNITY_LINK`: Community link (empty for RHOAI)

## Configuration

### Dashboard Configuration (OdhDashboardConfig CR)

**Key Configuration Options:**
- **Feature Flags**: Enable/disable dashboard sections (projects, model serving, pipelines, distributed workloads, etc.)
- **Group Permissions**: Admin groups and allowed user groups
- **Notebook Sizes**: Predefined CPU/memory resource configurations
- **Model Server Sizes**: Resource templates for serving runtimes
- **Notebook Controller**: Namespace, PVC size, storage class settings
- **Template Management**: Order and disable/enable notebook templates

### Deployment Configuration

**Replica Management:**
- 2 replicas with pod anti-affinity across availability zones
- Resource requests: 500m CPU, 1Gi memory per container
- Resource limits: 1000m CPU, 2Gi memory per container

**Health Checks:**
- Liveness probe: TCP socket on port 8080 (dashboard), HTTPS on 8443 (oauth-proxy)
- Readiness probe: HTTP GET /api/health on port 8080 (dashboard), /oauth/healthz on 8443 (oauth-proxy)

**Volume Mounts:**
- CA certificate bundles: odh-trusted-ca-bundle, odh-ca-bundle
- OAuth secrets: dashboard-oauth-config-generated, dashboard-oauth-client-generated
- TLS certificates: dashboard-proxy-tls

## Recent Changes

| Commit | Date | Changes |
|--------|------|---------|
| 4774c0d88 | 2024-10-21 | - Merge v2.28.0 fixes |
| 21aba0254 | 2024-10-21 | - Upversion Dashboard to v2.28.0 |
| 6b6dc43af | 2024-10-18 | - Update project list view to show active notebooks<br>- Improved UX for notebook status visibility |
| 3b5a56b51 | 2024-10-18 | - Update memory units display |
| 448ed592a | 2024-10-18 | - Rename trusty flag to disableTrustyBiasMetrics |
| 2305d0ae2 | 2024-10-18 | - Make label cursor hoverable in UI |
| 0cb198c18 | 2024-10-18 | - Fix missing tooltip for disabled kebab in Manage permissions page |
| 5a2fd848c | 2024-10-18 | - Update endpoint details button text |
| e385f43a7 | 2024-10-17 | - Support editing connections with unmatched connection types |
| 488d37d90 | 2024-10-18 | - Update properties section in model details and version details |
| 856e79ea1 | 2024-10-17 | - Display internal addresses even when models are external |
| a89722e53 | 2024-10-17 | - Disable archive for model registry/version if deployments exist |

## Deployment Variants

### ODH Deployment
- **Kustomize Base**: `manifests/odh`
- **Features**: Community branding, all features enabled by default
- **Applications**: Jupyter, community integrations

### RHOAI Addon Deployment
- **Kustomize Base**: `manifests/rhoai/addon`
- **Features**: RHOAI branding, managed cloud features
- **Applications**: Jupyter, NVIDIA, RHOAM, Starburst Galaxy
- **Additional**: Anaconda CE, Intel AI Analytics Toolkit, OpenVINO, Elastic, NVIDIA NIM, Pachyderm, Watson.x

### RHOAI On-Premise Deployment
- **Kustomize Base**: `manifests/rhoai/onprem`
- **Features**: RHOAI branding, self-managed features
- **Applications**: Jupyter, Starburst Enterprise
- **Additional**: Same as addon plus on-premise specific ISV integrations

## Notes

- The dashboard serves as the primary management interface for the entire Open Data Hub/RHOAI platform
- All user-facing operations are authenticated through OpenShift OAuth, with fine-grained authorization via Kubernetes RBAC
- The backend uses the Kubernetes service account to perform operations on behalf of users, validated against user permissions
- Network security relies on OpenShift Route TLS termination and oauth-proxy for authentication
- Custom resources defined by the dashboard are consumed by other operators (DSC, DSCI) to configure platform behavior
- The dashboard dynamically adapts its UI based on installed components detected through the Kubernetes API
- ISV partner applications are validated and integrated through the OdhApplication CR catalog
- Metrics are exposed in Prometheus format on /metrics endpoint for monitoring integration
