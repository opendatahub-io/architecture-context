# Component: ODH Dashboard

## Metadata
- **Repository**: https://github.com/red-hat-data-services/odh-dashboard.git
- **Version**: v1.21.0-18-rhods-1994-gee5b1a290
- **Branch**: rhoai-2.11
- **Distribution**: RHOAI
- **Languages**: TypeScript, Node.js, React
- **Deployment Type**: Web Application (Frontend + Backend Service)

## Purpose
**Short**: Web-based dashboard UI for Red Hat OpenShift AI platform providing centralized management and access to data science tools.

**Detailed**: The ODH Dashboard is the primary web interface for the Red Hat OpenShift AI (RHOAI) platform, providing users with a unified console to discover, launch, and manage data science applications, workbenches, model serving deployments, and ML pipelines. The dashboard serves as the entry point for data scientists and ML engineers, offering capabilities for notebook management, model deployment, pipeline orchestration, accelerator profile configuration, and user/group management. It integrates with various ODH components including KServe, ModelMesh, Kubeflow Notebooks, and Data Science Pipelines, providing a PatternFly-based UI that is accessible through OpenShift's application menu via ConsoleLink integration. The dashboard also manages configuration through custom resources (OdhDashboardConfig) and presents application catalogs, documentation, quick starts, and learning resources to guide users through data science workflows.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| Frontend | React/TypeScript SPA | User interface built with PatternFly components, provides dashboard UI for data science workflows |
| Backend | Fastify (Node.js) API | REST API server that proxies Kubernetes API calls and serves frontend static assets |
| OAuth Proxy | OpenShift OAuth Proxy | Handles OpenShift authentication and authorization for dashboard access |

## APIs Exposed

### Custom Resource Definitions (CRDs)

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| dashboard.opendatahub.io | v1 | OdhApplication | Namespaced | Defines applications available in the dashboard catalog with metadata, links, and enablement status |
| dashboard.opendatahub.io | v1 | OdhDocument | Namespaced | Defines documentation resources, tutorials, and guides displayed in the learning center |
| opendatahub.io | v1alpha | OdhDashboardConfig | Namespaced | Configures dashboard behavior including feature flags, group permissions, and notebook/model server sizes |
| dashboard.opendatahub.io | v1, v1alpha | AcceleratorProfile | Namespaced | Defines GPU/accelerator profiles with resource identifiers and tolerations for workload scheduling |
| console.openshift.io | v1 | OdhQuickStart | Namespaced | Provides guided quick start tutorials for dashboard features and workflows |

### HTTP Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /api/health | GET | 8080/TCP | HTTP | None | None | Health check endpoint for liveness/readiness probes |
| /api/accelerator-profiles | GET, POST, PATCH, DELETE | 8080/TCP | HTTP | None | Internal | Manage accelerator profile configurations |
| /api/accelerators | GET | 8080/TCP | HTTP | None | Internal | List available accelerators in the cluster |
| /api/builds | GET | 8080/TCP | HTTP | None | Internal | Query OpenShift BuildConfigs and Builds |
| /api/cluster-settings | GET | 8080/TCP | HTTP | None | Internal | Retrieve cluster configuration and settings |
| /api/components | GET | 8080/TCP | HTTP | None | Internal | List installed ODH/RHOAI components |
| /api/config | GET | 8080/TCP | HTTP | None | Internal | Retrieve dashboard configuration |
| /api/dashboardConfig | GET, PATCH | 8080/TCP | HTTP | None | Internal | Manage OdhDashboardConfig resources |
| /api/docs | GET | 8080/TCP | HTTP | None | Internal | Retrieve OdhDocument resources for learning center |
| /api/dsc | GET | 8080/TCP | HTTP | None | Internal | Query DataScienceCluster status |
| /api/dsci | GET | 8080/TCP | HTTP | None | Internal | Query DSCInitialization status |
| /api/groups-config | GET | 8080/TCP | HTTP | None | Internal | Retrieve admin and allowed user groups |
| /api/images | GET, POST, PATCH, DELETE | 8080/TCP | HTTP | None | Internal | Manage custom notebook ImageStreams |
| /api/k8s | GET, POST, PATCH, DELETE | 8080/TCP | HTTP | None | Internal | Generic Kubernetes API proxy |
| /api/modelRegistries | GET, POST, PATCH, DELETE | 8080/TCP | HTTP | None | Internal | Manage model registry configurations |
| /api/namespaces | GET, POST, PATCH, DELETE | 8080/TCP | HTTP | None | Internal | Manage project/namespace resources |
| /api/notebooks | GET, POST, PATCH, DELETE | 8080/TCP | HTTP | None | Internal | Manage Kubeflow Notebook resources |
| /api/prometheus | GET | 8080/TCP | HTTP | None | Internal | Proxy queries to Thanos/Prometheus for metrics |
| /api/quickstarts | GET | 8080/TCP | HTTP | None | Internal | Retrieve OdhQuickStart resources |
| /api/service | GET | 8080/TCP | HTTP | None | Internal | Query Kubernetes Service resources |
| /api/servingRuntimes | GET, POST, PATCH, DELETE | 8080/TCP | HTTP | None | Internal | Manage KServe ServingRuntime resources |
| /api/status | GET | 8080/TCP | HTTP | None | Internal | Retrieve component enablement status |
| /api/storage | GET, POST, PATCH, DELETE | 8080/TCP | HTTP | None | Internal | Manage PersistentVolumeClaim resources |
| /api/templates | GET | 8080/TCP | HTTP | None | Internal | Query OpenShift Template resources |
| /oauth/healthz | GET | 8443/TCP | HTTPS | TLS 1.2+ | None | OAuth proxy health check |
| /* | GET | 8443/TCP | HTTPS | TLS 1.2+ | OpenShift OAuth | Serve dashboard UI and authenticated API access |

### gRPC Services

| Service | Port | Protocol | Encryption | Auth | Purpose |
|---------|------|----------|------------|------|---------|
| N/A | N/A | N/A | N/A | N/A | No gRPC services exposed |

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| Node.js | >=18.0.0 | Yes | Runtime for backend server |
| Kubernetes API | 1.25+ | Yes | Core platform for resource management |
| OpenShift API | 4.12+ | Yes | Routes, OAuth, ImageStreams, BuildConfigs |
| OpenShift OAuth Proxy | latest | Yes | Authentication and authorization |

### Internal ODH Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| opendatahub-operator | CRD/API | Reads DataScienceCluster and DSCInitialization status |
| kubeflow-notebooks | CRD/API | Creates and manages Notebook resources |
| kserve | CRD/API | Manages ServingRuntime resources for model serving |
| modelmesh-serving | CRD/API | Manages ModelMesh-based model deployments |
| data-science-pipelines | API | Integrates with pipeline backend for ML workflows |
| model-registry | CRD/API | Manages ModelRegistry resources for model versioning |
| Thanos/Prometheus | HTTP/API | Queries metrics for performance monitoring |

## Network Architecture

### Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| odh-dashboard | ClusterIP | 8443/TCP | 8443 | HTTPS | TLS 1.2+ | mTLS (service CA) | Internal |

### Ingress

| Name | Type | Hosts | Port | Protocol | Encryption | TLS Mode | Exposure |
|------|------|-------|------|----------|------------|----------|----------|
| odh-dashboard | OpenShift Route | cluster-generated | 443/TCP | HTTPS | TLS 1.2+ | Reencrypt | External |

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| kubernetes.default.svc | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount token | Kubernetes API calls for resource management |
| thanos-querier.openshift-monitoring.svc | 9092/TCP | HTTPS | TLS 1.2+ | ServiceAccount token | Query metrics from Thanos/Prometheus |
| S3-compatible storage | 443/TCP | HTTPS | TLS 1.2+ | AWS credentials | Pipeline artifact storage (optional) |
| Model Registry services | 443/TCP | HTTPS | TLS 1.2+ | Bearer token | Model registry API calls |

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
| odh-dashboard-view | rbac.authorization.k8s.io | subjectaccessreviews, tokenreviews | create |
| odh-dashboard-cluster-monitoring | "" | namespaces | get |
| odh-dashboard-image-puller | "", image.openshift.io | imagestreamimages, imagestreams, imagestreamtags | get |

### RBAC - Role Bindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| odh-dashboard | dashboard namespace | odh-dashboard (Role) | odh-dashboard |
| odh-dashboard | cluster-wide | odh-dashboard (ClusterRole) | odh-dashboard |
| odh-dashboard-auth-delegator | kube-system | system:auth-delegator | odh-dashboard |
| odh-dashboard-cluster-monitoring | openshift-monitoring | cluster-monitoring-view | odh-dashboard |
| odh-dashboard-image-puller | openshift | odh-dashboard-image-puller | odh-dashboard |
| odh-dashboard-model-serving | dashboard namespace | odh-dashboard-model-serving | odh-dashboard |

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| dashboard-proxy-tls | kubernetes.io/tls | TLS certificate for OAuth proxy HTTPS endpoint | OpenShift service CA | Yes |
| dashboard-oauth-config-generated | Opaque | OAuth cookie secret for session management | secret-generator operator | No |
| dashboard-oauth-client-generated | Opaque | OAuth client credentials for OpenShift authentication | secret-generator operator | No |

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| /api/* | GET, POST, PATCH, DELETE | Bearer Token (OpenShift OAuth JWT) | OAuth Proxy | Requires `projects:list` permission via OpenShift RBAC |
| /oauth/healthz | GET | None | OAuth Proxy | Public endpoint |
| /api/health | GET | None | Backend (skip-auth-regex) | Public endpoint bypasses OAuth |
| /metrics | GET | None | Backend (skip-auth-regex) | Public endpoint for Prometheus scraping |

## Data Flows

### Flow 1: User Dashboard Access

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User Browser | OpenShift Router | 443/TCP | HTTPS | TLS 1.2+ | None |
| 2 | OpenShift Router | odh-dashboard Service | 8443/TCP | HTTPS | TLS 1.2+ (reencrypt) | Service CA cert |
| 3 | OAuth Proxy | OpenShift OAuth Server | 443/TCP | HTTPS | TLS 1.2+ | OAuth client credentials |
| 4 | OAuth Proxy | Backend (localhost) | 8080/TCP | HTTP | None | Bearer token (forwarded) |
| 5 | Backend | Kubernetes API | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount token |

### Flow 2: API Resource Management

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Frontend (Browser) | Backend API (/api/*) | 8443/TCP | HTTPS | TLS 1.2+ | Bearer token (OAuth JWT) |
| 2 | Backend | Kubernetes API | 443/TCP | HTTPS | TLS 1.2+ | User token (impersonation) |
| 3 | Kubernetes API | etcd | 2379/TCP | gRPC | mTLS | Client cert |

### Flow 3: Metrics Collection

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Frontend | Backend (/api/prometheus) | 8443/TCP | HTTPS | TLS 1.2+ | Bearer token |
| 2 | Backend | Thanos Querier (openshift-monitoring) | 9092/TCP | HTTPS | TLS 1.2+ | ServiceAccount token |
| 3 | Thanos Querier | Prometheus | 9091/TCP | HTTP | None | Internal |

### Flow 4: Notebook Creation

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Frontend | Backend (/api/notebooks) | 8443/TCP | HTTPS | TLS 1.2+ | Bearer token |
| 2 | Backend | Kubernetes API (Notebook CRD) | 443/TCP | HTTPS | TLS 1.2+ | User token |
| 3 | Notebook Controller | Kubernetes API (StatefulSet) | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount token |

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| Kubernetes API Server | REST API | 443/TCP | HTTPS | TLS 1.2+ | Resource CRUD operations for all ODH/K8s resources |
| OpenShift OAuth Server | OAuth 2.0 | 443/TCP | HTTPS | TLS 1.2+ | User authentication and token issuance |
| Thanos Querier | HTTP/REST | 9092/TCP | HTTPS | TLS 1.2+ | Metrics queries for model serving and pipeline performance |
| Data Science Pipelines API | HTTP/REST | 8443/TCP | HTTPS | TLS 1.2+ | Pipeline run management and artifact retrieval |
| Model Registry API | HTTP/REST | 8080/TCP | HTTPS | TLS 1.2+ | Model version and metadata management |
| S3-compatible Storage | HTTP/REST | 443/TCP | HTTPS | TLS 1.2+ | Pipeline artifacts and model storage |

## Recent Changes

| Version | Date | Changes |
|---------|------|---------|
| v1.21.0-18-rhods-1994 | 2024-06-28 | - Merge fixes for v2.24.0<br>- Fixed broken link to Fraud Detection tutorial<br>- Cleanup S3 endpoint host in pipeline server configuration |
| v2.24.0 | 2024-06-19 | - Upversion to v2.24.0<br>- Refactored useMetricColumnNames to handle empty experimentId<br>- Removed artifact preview feature |

## Build and Deployment

### Container Images

| Image | Base | Port | Purpose |
|-------|------|------|---------|
| odh-dashboard | registry.access.redhat.com/ubi8/nodejs-18:latest | 8080/TCP | Combined frontend and backend application |
| oauth-proxy | registry.redhat.io/openshift4/ose-oauth-proxy | 8443/TCP | OpenShift OAuth authentication proxy |

### Deployment Configuration

- **Replicas**: 2 (high availability)
- **Pod Anti-Affinity**: Preferred across availability zones
- **Resource Requests**: 500m CPU, 1Gi memory (per container)
- **Resource Limits**: 1000m CPU, 2Gi memory (per container)
- **Liveness Probe**: TCP socket check on port 8080 (dashboard), HTTPS /oauth/healthz on 8443 (oauth-proxy)
- **Readiness Probe**: HTTP GET /api/health on port 8080 (dashboard), HTTPS /oauth/healthz on 8443 (oauth-proxy)

### Volume Mounts

| Volume | Type | Mount Path | Purpose |
|--------|------|------------|---------|
| proxy-tls | Secret | /etc/tls/private | TLS certificate for OAuth proxy |
| oauth-config | Secret | /etc/oauth/config | OAuth cookie secret |
| oauth-client | Secret | /etc/oauth/client | OAuth client credentials |
| odh-trusted-ca-cert | ConfigMap | /etc/pki/tls/certs/, /etc/ssl/certs/ | Trusted CA certificates for API calls |
| odh-ca-cert | ConfigMap | /etc/pki/tls/certs/, /etc/ssl/certs/ | ODH platform CA certificates |

## Feature Flags

The dashboard supports extensive feature flag configuration via OdhDashboardConfig CRD:

- **disableInfo**: Hide info/about sections
- **disableSupport**: Hide support resources
- **disableClusterManager**: Disable cluster settings management
- **disableTracking**: Disable analytics tracking
- **disableBYONImageStream**: Disable custom notebook images
- **disableISVBadges**: Hide ISV partner badges
- **disableUserManagement**: Disable user/group management UI
- **disableHome**: Hide home page
- **disableProjects**: Disable projects/namespaces feature
- **disableModelServing**: Disable model serving features (KServe/ModelMesh)
- **disableProjectSharing**: Disable project sharing with groups
- **disableCustomServingRuntimes**: Disable custom serving runtime creation
- **disablePipelines**: Disable Data Science Pipelines integration
- **disableBiasMetrics**: Disable TrustyAI bias metrics
- **disablePerformanceMetrics**: Disable model performance metrics
- **disableKServe**: Disable KServe model serving
- **disableKServeAuth**: Disable KServe authorization features
- **disableKServeMetrics**: Disable KServe metrics collection
- **disableModelMesh**: Disable ModelMesh serving
- **disableAcceleratorProfiles**: Disable accelerator profile management
- **disablePipelineExperiments**: Disable ML experiment tracking
- **disableS3Endpoint**: Disable S3 endpoint configuration
- **disableDistributedWorkloads**: Disable distributed workloads (Kueue/CodeFlare)
- **disableModelRegistry**: Disable model registry integration

## Console Integration

The dashboard integrates with OpenShift Console via ConsoleLink resource:
- **Location**: ApplicationMenu
- **Section**: Configurable (default: "Open Data Hub" or "Red Hat OpenShift AI")
- **Link Target**: Dashboard route URL
- **Icon**: Base64-encoded ODH/RHOAI logo
