# Component: ODH Dashboard

## Metadata
- **Repository**: https://github.com/red-hat-data-services/odh-dashboard.git
- **Version**: v1.21.0-18-rhods-2182-ge30b77c5d
- **Branch**: rhoai-2.12
- **Distribution**: RHOAI
- **Languages**: TypeScript (Frontend), TypeScript (Backend Node.js)
- **Deployment Type**: Web Application

## Purpose
**Short**: Central web-based UI for managing and interacting with Open Data Hub and Red Hat OpenShift AI platform components.

**Detailed**: The ODH Dashboard is the primary user interface for the Open Data Hub and Red Hat OpenShift AI platforms. It provides a unified web console for data scientists and administrators to manage projects, workbenches, model serving, data science pipelines, model registries, and other AI/ML components. The dashboard integrates with OpenShift OAuth for authentication and provides a user-friendly interface built with PatternFly React components. It acts as a central hub that proxies requests to various backend services including Kubeflow Pipelines, Model Registry, TrustyAI, and ML Metadata, while also managing custom resources like notebooks, serving runtimes, and accelerator profiles. The dashboard enables teams to collaborate on data science projects with features like project sharing, user management, quickstarts, and integrated documentation.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| Frontend | React/PatternFly Web UI | User interface for managing ODH/RHOAI platform |
| Backend | Node.js Fastify Server | REST API server providing k8s access and service proxying |
| OAuth Proxy | OpenShift OAuth Proxy | Authentication and authorization layer |
| ConsoleLink | OpenShift Console Integration | Link to dashboard from OpenShift Console |

## APIs Exposed

### Custom Resource Definitions (CRDs)

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| opendatahub.io | v1alpha | OdhDashboardConfig | Namespaced | Dashboard configuration including feature flags, group access, notebook sizes |
| dashboard.opendatahub.io | v1 | OdhApplication | Namespaced | Catalog of available applications and integrations |
| dashboard.opendatahub.io | v1 | OdhDocument | Namespaced | Documentation and tutorial resources |
| console.openshift.io | v1 | OdhQuickStart | Cluster | Quick start guides for onboarding users |
| dashboard.opendatahub.io | v1 | AcceleratorProfile | Namespaced | GPU and accelerator device configurations |

### HTTP Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /api/* | GET, POST, PUT, DELETE, PATCH | 8080/TCP | HTTP | None | None | Backend REST API for k8s resources and configurations |
| /api/health | GET | 8080/TCP | HTTP | None | None | Health check endpoint |
| /oauth/* | GET | 8443/TCP | HTTPS | TLS 1.2+ | OpenShift OAuth | OAuth authentication flow |
| /metrics | GET | 8443/TCP | HTTPS | TLS 1.2+ | None | Prometheus metrics (auth bypassed) |
| /api/accelerator-profiles | GET, POST, PUT, DELETE | 8080/TCP | HTTP | None | Bearer Token | Manage accelerator profiles |
| /api/accelerators | GET | 8080/TCP | HTTP | None | Bearer Token | List available accelerators |
| /api/builds | GET | 8080/TCP | HTTP | None | Bearer Token | List builds and build configs |
| /api/cluster-settings | GET, PUT | 8080/TCP | HTTP | None | Bearer Token | Cluster configuration settings |
| /api/components | GET | 8080/TCP | HTTP | None | Bearer Token | List installed ODH components |
| /api/config | GET, PATCH | 8080/TCP | HTTP | None | Bearer Token | Dashboard configuration |
| /api/console-links | GET | 8080/TCP | HTTP | None | Bearer Token | Console link resources |
| /api/dashboardConfig | GET | 8080/TCP | HTTP | None | Bearer Token | Dashboard feature flags and config |
| /api/docs | GET | 8080/TCP | HTTP | None | Bearer Token | Documentation resources |
| /api/dsc | GET | 8080/TCP | HTTP | None | Bearer Token | Data Science Cluster status |
| /api/dsci | GET | 8080/TCP | HTTP | None | Bearer Token | DSC Initialization status |
| /api/groups-config | GET | 8080/TCP | HTTP | None | Bearer Token | User group configurations |
| /api/images | GET | 8080/TCP | HTTP | None | Bearer Token | Notebook and workbench images |
| /api/k8s/* | GET, POST, PUT, DELETE, PATCH | 8080/TCP | HTTP | None | Bearer Token | Kubernetes resource passthrough |
| /api/modelRegistries | GET, POST, PUT, DELETE | 8080/TCP | HTTP | None | Bearer Token | Model registry management |
| /api/namespaces | GET, POST | 8080/TCP | HTTP | None | Bearer Token | Namespace/project management |
| /api/nb-events/:namespace/:notebookName | GET | 8080/TCP | HTTP | None | Bearer Token | Notebook pod events |
| /api/notebooks | GET, POST, PUT, DELETE | 8080/TCP | HTTP | None | Bearer Token | Notebook management |
| /api/quickstarts | GET | 8080/TCP | HTTP | None | Bearer Token | Quick start guides |
| /api/rolebindings | GET, POST | 8080/TCP | HTTP | None | Bearer Token | Role binding management |
| /api/segment-key | GET | 8080/TCP | HTTP | None | Bearer Token | Analytics segment key |
| /api/service/mlmd/:namespace/:name/* | ALL | 8080/TCP | HTTP | None | Bearer Token | Proxy to ML Metadata service |
| /api/service/modelregistry/:namespace/:name/* | ALL | 8080/TCP | HTTP | None | Bearer Token | Proxy to Model Registry service |
| /api/service/pipelines/:namespace/:name/* | ALL | 8080/TCP | HTTP | None | Bearer Token | Proxy to Kubeflow Pipelines service |
| /api/service/trustyai/:namespace/:name/* | ALL | 8080/TCP | HTTP | None | Bearer Token | Proxy to TrustyAI service |
| /api/servingRuntimes | POST | 8080/TCP | HTTP | None | Bearer Token | Serving runtime management |
| /api/status | GET | 8080/TCP | HTTP | None | Bearer Token | Platform status information |
| /api/storage | GET | 8080/TCP | HTTP | None | Bearer Token | Storage and PVC management |
| /api/templates | GET, POST, PATCH, DELETE | 8080/TCP | HTTP | None | Bearer Token | Template management |
| /api/validate-isv | GET | 8080/TCP | HTTP | None | Bearer Token | ISV application validation |
| /wss/k8s/* | WebSocket | 8080/TCP | WS | None | Bearer Token | WebSocket connections for k8s watches |
| /* | GET | 8080/TCP | HTTP | None | None | Serve frontend static files |

### gRPC Services

| Service | Port | Protocol | Encryption | Auth | Purpose |
|---------|------|----------|------------|------|---------|
| N/A | N/A | N/A | N/A | N/A | No direct gRPC services (proxied via HTTP) |

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| Node.js | >=18.0.0 | Yes | JavaScript runtime for backend |
| Fastify | ^4.16.0 | Yes | Web framework for backend API |
| React | ^18.x | Yes | Frontend UI framework |
| PatternFly | ^5.3.x | Yes | UI component library |
| @kubernetes/client-node | ^0.12.2 | Yes | Kubernetes API client |
| OAuth Proxy | Latest | Yes | OpenShift OAuth authentication |
| Prometheus | Any | No | Metrics collection |
| OpenShift Console | 4.x | No | Console integration via ConsoleLink |

### Internal ODH Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| Kubeflow Notebooks | CRD (kubeflow.org/notebooks) | Manage Jupyter notebook workbenches |
| Data Science Pipelines | HTTP Proxy | Access pipeline server APIs |
| Model Registry | HTTP Proxy | Access model registry APIs |
| ML Metadata (MLMD) | HTTP Proxy | Access ML metadata service |
| TrustyAI | HTTP Proxy | Access model fairness and bias metrics |
| KServe | CRD (serving.kserve.io/servingruntimes) | Manage model serving runtimes |
| Model Mesh | CRD | Alternative model serving platform |
| Data Science Cluster Operator | CRD (datasciencecluster.opendatahub.io, dscinitialization.opendatahub.io) | Platform configuration and status |
| Model Registry Operator | CRD (modelregistry.opendatahub.io) | Model registry lifecycle |
| OpenShift Builds | API (build.openshift.io) | Custom notebook image builds |
| OpenShift ImageStreams | API (image.openshift.io) | Notebook image management |
| Red Hat Integration (RHOAM) | API (integreatly.org/rhmis) | 3scale API management integration |

## Network Architecture

### Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| odh-dashboard | ClusterIP | 8443/TCP | 8443 | HTTPS | TLS 1.2+ (service-ca) | OAuth Proxy | Internal |

### Ingress

| Name | Type | Hosts | Port | Protocol | Encryption | TLS Mode | Exposure |
|------|------|-------|------|----------|------------|----------|----------|
| odh-dashboard | OpenShift Route | Auto-generated | 8443/TCP | HTTPS | TLS 1.2+ | reencrypt | External |

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token | Resource management |
| Data Science Pipelines Service | 8888/TCP (or 8443/TCP) | HTTPS | TLS 1.2+ | Bearer Token | Pipeline operations |
| Model Registry Service | 8080/TCP (or 8443/TCP) | HTTPS | TLS 1.2+ | Bearer Token | Model registry operations |
| MLMD Service | 8080/TCP | HTTPS | TLS 1.2+ | Bearer Token | ML metadata operations |
| TrustyAI Service | 8080/TCP | HTTPS | TLS 1.2+ | Bearer Token | Bias metrics operations |
| OpenShift OAuth | 6443/TCP | HTTPS | TLS 1.2+ | OAuth Client Secret | User authentication |
| Prometheus | 9091/TCP | HTTPS | TLS 1.2+ | Bearer Token | Metrics queries |

## Security

### RBAC - Cluster Roles

| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|
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
| odh-dashboard | "" | namespaces | get, list, watch, create, update, patch, delete |
| odh-dashboard | rbac.authorization.k8s.io | rolebindings, clusterrolebindings, roles | get, list, watch, create, update, patch, delete |
| odh-dashboard | "", events.k8s.io | events | get, list, watch |
| odh-dashboard | kubeflow.org | notebooks | get, list, watch, create, update, patch, delete |
| odh-dashboard | datasciencecluster.opendatahub.io | datascienceclusters | list, watch, get |
| odh-dashboard | dscinitialization.opendatahub.io | dscinitializations | list, watch, get |
| odh-dashboard | modelregistry.opendatahub.io | modelregistries | get, list, watch, create, update, patch, delete |
| odh-dashboard-auth-delegator | authorization.k8s.io | subjectaccessreviews | create |
| odh-dashboard-image-puller | "" | secrets | get |

### RBAC - Role Bindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| odh-dashboard | ClusterRoleBinding | ClusterRole/odh-dashboard | odh-dashboard (operator namespace) |
| odh-dashboard-auth-delegator | ClusterRoleBinding | ClusterRole/system:auth-delegator | odh-dashboard (operator namespace) |
| odh-dashboard-image-puller | ClusterRoleBinding | ClusterRole/system:image-puller | odh-dashboard (operator namespace) |
| odh-dashboard | RoleBinding (operator namespace) | Role/odh-dashboard | odh-dashboard (operator namespace) |
| odh-dashboard-cluster-monitoring-view | RoleBinding (openshift-monitoring) | ClusterRole/cluster-monitoring-view | odh-dashboard (operator namespace) |

### RBAC - Namespace Roles

| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|
| odh-dashboard | dashboard.opendatahub.io | acceleratorprofiles | create, get, list, update, patch, delete |
| odh-dashboard | route.openshift.io | routes | get, list, watch |
| odh-dashboard | kfdef.apps.kubeflow.org | kfdefs | get, list, watch |
| odh-dashboard | batch | cronjobs, jobs, jobs/status | create, delete, get, list, patch, update, watch |
| odh-dashboard | image.openshift.io | imagestreams | create, get, list, update, patch, delete |
| odh-dashboard | build.openshift.io | builds, buildconfigs, buildconfigs/instantiate | get, list, watch, create, patch, delete |
| odh-dashboard | apps | deployments | patch, update |
| odh-dashboard | apps.openshift.io | deploymentconfigs, deploymentconfigs/instantiate | get, list, watch, create, update, patch, delete |
| odh-dashboard | opendatahub.io | odhdashboardconfigs | get, list, watch, create, update, patch, delete |
| odh-dashboard | kubeflow.org | notebooks | get, list, watch, create, update, patch, delete |
| odh-dashboard | dashboard.opendatahub.io | odhapplications, odhdocuments | get, list |
| odh-dashboard | console.openshift.io | odhquickstarts | get, list |
| odh-dashboard | template.openshift.io | templates | * |
| odh-dashboard | serving.kserve.io | servingruntimes | * |
| odh-dashboard-model-serving-role | serving.kserve.io | inferenceservices | create, delete, deletecollection, get, list, patch, update, watch |
| odh-dashboard-model-serving-role | serving.kserve.io | servingruntimes | get, list, watch |
| odh-dashboard-model-serving-role | serving.kserve.io | clusterservingruntimes | get, list, watch |
| odh-dashboard-fetch-accelerators | dashboard.opendatahub.io | acceleratorprofiles | get, list, watch |
| odh-dashboard-fetch-builds-images | image.openshift.io | imagestreams | get, list, watch |
| odh-dashboard-fetch-builds-images | build.openshift.io | buildconfigs, builds | get, list, watch |

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| dashboard-proxy-tls | kubernetes.io/tls | TLS certificate for OAuth proxy | service.alpha.openshift.io/serving-cert | Yes |
| dashboard-oauth-config-generated | Opaque | OAuth cookie secret | secret-generator.opendatahub.io | No |
| dashboard-oauth-client-generated | Opaque | OAuth client secret | secret-generator.opendatahub.io | No |
| odh-trusted-ca-bundle | ConfigMap | Trusted CA certificates | Platform | No |

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| /* (dashboard UI) | ALL | OpenShift OAuth (Bearer Token) | OAuth Proxy (8443) | OpenShift RBAC - user must have projects list permission |
| /api/* | ALL | Bearer Token (ServiceAccount or User) | Backend (8080) | Validated via K8s API TokenReview |
| /metrics | GET | None (auth skipped) | OAuth Proxy (8443) | Public endpoint |
| /oauth/healthz | GET | None | OAuth Proxy (8443) | Public health check |
| /api/health | GET | None | Backend (8080) | Public health check |

## Data Flows

### Flow 1: User Access Dashboard

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User Browser | OpenShift Router | 443/TCP | HTTPS | TLS 1.2+ | None |
| 2 | OpenShift Router | odh-dashboard Service | 8443/TCP | HTTPS | TLS 1.2+ (reencrypt) | None |
| 3 | OAuth Proxy | OpenShift OAuth | 6443/TCP | HTTPS | TLS 1.2+ | OAuth Client Secret |
| 4 | OAuth Proxy (authenticated) | Backend | 8080/TCP | HTTP | None (localhost) | Bearer Token (passed through) |

### Flow 2: Dashboard to Kubernetes API

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Backend Container | Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |

### Flow 3: Dashboard to Data Science Pipelines

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User Browser | odh-dashboard Service | 8443/TCP | HTTPS | TLS 1.2+ | Bearer Token (User) |
| 2 | Backend (proxy) | ds-pipeline-{name} Service | 8443/TCP | HTTPS | TLS 1.2+ | Bearer Token (User passthrough) |

### Flow 4: Dashboard to Model Registry

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User Browser | odh-dashboard Service | 8443/TCP | HTTPS | TLS 1.2+ | Bearer Token (User) |
| 2 | Backend (proxy) | model-registry-{name} Service | 8080/TCP | HTTP/HTTPS | Varies | Bearer Token (User passthrough) |

### Flow 5: Dashboard to TrustyAI Service

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User Browser | odh-dashboard Service | 8443/TCP | HTTPS | TLS 1.2+ | Bearer Token (User) |
| 2 | Backend (proxy) | trustyai-service-{name} Service | 8080/TCP | HTTP/HTTPS | Varies | Bearer Token (User passthrough) |

### Flow 6: Dashboard to Prometheus

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Backend | thanos-querier Service | 9091/TCP | HTTPS | TLS 1.2+ | Bearer Token (ServiceAccount) |

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| Kubernetes API | REST API | 6443/TCP | HTTPS | TLS 1.2+ | Resource CRUD operations |
| Data Science Pipelines | HTTP Proxy | 8443/TCP | HTTPS | TLS 1.2+ | Pipeline management and execution |
| Model Registry | HTTP Proxy | 8080/TCP | HTTP/HTTPS | Varies | Model versioning and metadata |
| ML Metadata (MLMD) | HTTP Proxy | 8080/TCP | HTTP/HTTPS | Varies | Pipeline metadata and artifacts |
| TrustyAI | HTTP Proxy | 8080/TCP | HTTP/HTTPS | Varies | Model fairness and bias metrics |
| Kubeflow Notebooks | CRD Management | 6443/TCP | HTTPS | TLS 1.2+ | Workbench lifecycle |
| KServe | CRD Management | 6443/TCP | HTTPS | TLS 1.2+ | Model serving runtime management |
| OpenShift Builds | REST API | 6443/TCP | HTTPS | TLS 1.2+ | Custom notebook image builds |
| OpenShift Console | ConsoleLink | N/A | N/A | N/A | Dashboard link in console menu |
| OpenShift OAuth | OAuth 2.0 | 6443/TCP | HTTPS | TLS 1.2+ | User authentication |
| Prometheus/Thanos | REST API | 9091/TCP | HTTPS | TLS 1.2+ | Metrics queries for dashboard |

## Recent Changes

| Commit | Date | Changes |
|--------|------|---------|
| e30b77c5d | 2024-12 | - Merge pull request #346 from opendatahub-io/v2.25.0-fixes |
| 998b2b5ef | 2024-12 | - Upversion Dashboard (#3037) (#3043) |
| d0de08df6 | 2024-12 | - Add definition of ready and done (#3031) |
| 8d1fa7305 | 2024-12 | - Enable KServeMetrics by default (RHOAIENG-8575) (#3032) |
| e78c6e95e | 2024-12 | - Infrastructure proxy call for artifacts API (#3017) |
| 979f9bab1 | 2024-12 | - [RHOAIENG-7943] Navigate to pipeline details on import (#3026) |
| e011af324 | 2024-12 | - Document commands for cypress e2e tests (#3030) |
| d47fa7a4b | 2024-12 | - Remove the DS project list toggle (#3018) |
| 82345b01b | 2024-12 | - Restart the pod after updating configMap in workbench (#3002) |
| 7332e85fb | 2024-12 | - Merge pull request #3008 from jpuzz0/RHOAIENG-4702 |
| 980dd127b | 2024-12 | - [RHOAIENG-4702] Improve unique naming for runs and versions in pipelines |
| b89b4160e | 2024-12 | - Handle deleted container size in workbenches (#2944) |
| f1784f5ff | 2024-12 | - Show correct state text on pipeline run node side drawer (#3029) |
| 1be20fa3e | 2024-12 | - Set experiment as Default on create run/schedule page (#2996) |
| c6336ff09 | 2024-12 | - Display pipeline run volume name correctly (#3027) |
| d1324f638 | 2024-12 | - Delete conflict dspa secret when creating pipeline server (#3011) |
| b909563f5 | 2024-12 | - Added ability to intercept mlmd requests (#3023) |
| 957169bb4 | 2024-12 | - feat(mr): add display name and description for mr selector (#3019) |
| 9f5e4d89e | 2024-12 | - Fix LogViewerSearch styling issue and improve functionality (#2997) |
| 7d5ba022c | 2024-12 | - feat(MR): register model page skeleton (#3015) |

## Deployment Architecture

### Container Images

| Container | Base Image | Port | Purpose |
|-----------|------------|------|---------|
| odh-dashboard | registry.access.redhat.com/ubi8/nodejs-18 | 8080/TCP | Main dashboard application |
| oauth-proxy | OpenShift OAuth Proxy | 8443/TCP | Authentication proxy |

### Resource Requirements

| Container | CPU Request | CPU Limit | Memory Request | Memory Limit |
|-----------|-------------|-----------|----------------|--------------|
| odh-dashboard | 500m | 1000m | 1Gi | 2Gi |
| oauth-proxy | 500m | 1000m | 1Gi | 2Gi |

### High Availability

| Feature | Configuration | Purpose |
|---------|---------------|---------|
| Replicas | 2 | Ensure availability during updates |
| Pod Anti-Affinity | Preferred (zone-based) | Distribute pods across availability zones |
| Readiness Probe | HTTP /api/health | Only route traffic to healthy pods |
| Liveness Probe | TCP 8080 | Restart unhealthy pods |

### Volume Mounts

| Volume Name | Type | Mount Path | Purpose |
|-------------|------|------------|---------|
| proxy-tls | Secret | /etc/tls/private | OAuth proxy TLS certificate |
| oauth-config | Secret | /etc/oauth/config | OAuth cookie secret |
| oauth-client | Secret | /etc/oauth/client | OAuth client credentials |
| odh-trusted-ca-cert | ConfigMap | /etc/pki/tls/certs, /etc/ssl/certs | Trusted CA certificates |
| odh-ca-cert | ConfigMap | /etc/pki/tls/certs, /etc/ssl/certs | ODH platform CA certificate |

## Feature Flags (OdhDashboardConfig)

The dashboard supports extensive feature flag configuration via the `OdhDashboardConfig` CRD:

| Feature Flag | Purpose |
|--------------|---------|
| disableInfo | Hide info/about sections |
| disableSupport | Hide support links |
| disableClusterManager | Disable cluster management features |
| disableTracking | Disable analytics tracking |
| disableBYONImageStream | Disable bring-your-own-notebook images |
| disableISVBadges | Hide ISV partner badges |
| disableUserManagement | Disable user/group management |
| disableHome | Hide home page |
| disableProjects | Disable data science projects |
| disableModelServing | Disable model serving features |
| disableProjectSharing | Disable project collaboration |
| disableCustomServingRuntimes | Disable custom serving runtime creation |
| disablePipelines | Disable pipeline features |
| disableBiasMetrics | Disable TrustyAI bias metrics |
| disablePerformanceMetrics | Disable model performance monitoring |
| disableKServe | Disable KServe model serving |
| disableKServeAuth | Disable KServe authentication |
| disableKServeMetrics | Disable KServe metrics |
| disableModelMesh | Disable ModelMesh serving |
| disableAcceleratorProfiles | Disable GPU/accelerator management |
| disablePipelineExperiments | Disable pipeline experiments |
| disableS3Endpoint | Hide S3 endpoint configuration |
| disableDistributedWorkloads | Disable distributed training features |
| disableModelRegistry | Disable model registry features |

## Notes

- The dashboard is the primary entry point for users accessing the RHOAI/ODH platform
- All user requests are authenticated through OpenShift OAuth proxy before reaching the backend
- The backend acts as a secure proxy to various internal services, passing through user credentials
- Custom resources (CRDs) enable declarative configuration of dashboard content (apps, docs, quickstarts)
- The dashboard integrates deeply with OpenShift features (OAuth, Routes, ConsoleLinks, ImageStreams, Builds)
- WebSocket support enables real-time updates for Kubernetes resource watches
- The deployment uses anti-affinity rules to spread replicas across zones for high availability
- TLS certificates are auto-provisioned using OpenShift's service-ca annotation
- OAuth secrets are generated using the secret-generator annotations
- The dashboard supports both ODH (upstream) and RHOAI (product) distributions with different feature sets and integrations
