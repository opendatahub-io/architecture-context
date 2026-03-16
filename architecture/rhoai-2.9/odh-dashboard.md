# Component: ODH Dashboard

## Metadata
- **Repository**: https://github.com/red-hat-data-services/odh-dashboard.git
- **Version**: v1.21.0-18-rhods-1636-gbcf27bf51
- **Distribution**: RHOAI
- **Languages**: TypeScript, JavaScript, React
- **Deployment Type**: Web Application (Frontend + Backend Service)

## Purpose
**Short**: Web-based dashboard UI for managing and interacting with Red Hat OpenShift AI platform components.

**Detailed**: The ODH Dashboard is the primary user interface for Red Hat OpenShift AI (RHOAI) and Open Data Hub (ODH) platforms. It provides a unified web interface that displays installed and available components, manages data science projects and workbenches, configures model serving deployments, monitors pipelines and distributed workloads, and provides access to documentation and quick-start guides. The dashboard acts as the central control plane for data scientists and administrators to interact with the platform's various services including Jupyter notebooks, model serving runtimes (KServe, ModelMesh), data science pipelines, and accelerator profiles for GPU/hardware acceleration.

The dashboard consists of a React-based frontend serving static assets and a Node.js/Fastify backend that proxies requests to the Kubernetes API and other platform services. Authentication is handled via OpenShift OAuth proxy, enforcing token-based access control.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| Frontend | React/TypeScript SPA | User interface built with PatternFly components for managing RHOAI/ODH platform |
| Backend | Fastify/Node.js API Server | REST API server that interfaces with Kubernetes API and platform services |
| OAuth Proxy | OpenShift OAuth Proxy Sidecar | Authenticates users via OpenShift OAuth and enforces RBAC policies |

## APIs Exposed

### Custom Resource Definitions (CRDs)

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| opendatahub.io | v1alpha | OdhDashboardConfig | Namespaced | Configuration for dashboard behavior, feature flags, group permissions, and resource sizing |
| dashboard.opendatahub.io | v1 | OdhApplication | Namespaced | Defines applications available in the dashboard catalog with metadata and enablement logic |
| dashboard.opendatahub.io | v1 | OdhDocument | Namespaced | Documentation resources linked to applications (tutorials, how-tos, references) |
| console.openshift.io | v1 | OdhQuickStart | Namespaced | Interactive guided workflows for common tasks in the dashboard |
| dashboard.opendatahub.io | v1, v1alpha | AcceleratorProfile | Namespaced | Hardware accelerator configurations (GPUs, TPUs) with tolerations and resource identifiers |

### HTTP Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /api/accelerator-profiles | GET, POST, PUT, DELETE | 8080/TCP | HTTP | None (internal) | OAuth Token | Manage accelerator profile configurations |
| /api/accelerators | GET | 8080/TCP | HTTP | None (internal) | OAuth Token | List available hardware accelerators in cluster |
| /api/builds | GET | 8080/TCP | HTTP | None (internal) | OAuth Token | Retrieve notebook and imagestream build information |
| /api/cluster-settings | GET, PUT | 8080/TCP | HTTP | None (internal) | OAuth Token | Manage cluster-wide settings including notebook culling |
| /api/components | GET | 8080/TCP | HTTP | None (internal) | OAuth Token | List installed ODH/RHOAI components and status |
| /api/config | GET, PATCH | 8080/TCP | HTTP | None (internal) | OAuth Token | Get and update dashboard configuration |
| /api/console-links | GET | 8080/TCP | HTTP | None (internal) | OAuth Token | Retrieve OpenShift console links |
| /api/dashboardConfig | GET, PATCH | 8080/TCP | HTTP | None (internal) | OAuth Token | Access and modify OdhDashboardConfig custom resources |
| /api/docs | GET | 8080/TCP | HTTP | None (internal) | OAuth Token | Retrieve documentation resources |
| /api/dsc | GET | 8080/TCP | HTTP | None (internal) | OAuth Token | Get DataScienceCluster status and configuration |
| /api/dsci | GET | 8080/TCP | HTTP | None (internal) | OAuth Token | Get DSCInitialization status and configuration |
| /api/groups-config | GET | 8080/TCP | HTTP | None (internal) | OAuth Token | Retrieve group-based access control configuration |
| /api/health | GET | 8080/TCP | HTTP | None (internal) | None | Health check endpoint for readiness/liveness probes |
| /api/images | GET | 8080/TCP | HTTP | None (internal) | OAuth Token | List available notebook images and imagestreams |
| /api/k8s | Various | 8080/TCP | HTTP | None (internal) | OAuth Token | Generic Kubernetes API proxy for various resources |
| /api/namespaces | GET, POST, DELETE | 8080/TCP | HTTP | None (internal) | OAuth Token | Manage data science project namespaces |
| /api/nb-events | GET | 8080/TCP | HTTP | None (internal) | OAuth Token | Retrieve notebook-related Kubernetes events |
| /api/notebooks | GET, POST, PUT, DELETE | 8080/TCP | HTTP | None (internal) | OAuth Token | Manage Kubeflow Notebook custom resources |
| /api/prometheus | POST | 8080/TCP | HTTP | None (internal) | OAuth Token | Query Prometheus/Thanos for metrics data |
| /api/quickstarts | GET | 8080/TCP | HTTP | None (internal) | OAuth Token | List available quick-start tutorials |
| /api/rolebindings | GET, POST, DELETE | 8080/TCP | HTTP | None (internal) | OAuth Token | Manage project role bindings for user access |
| /api/segment-key | GET | 8080/TCP | HTTP | None (internal) | OAuth Token | Retrieve analytics segment key (if tracking enabled) |
| /api/service | GET | 8080/TCP | HTTP | None (internal) | OAuth Token | Get Kubernetes service information |
| /api/servingRuntimes | GET, POST, PUT, DELETE | 8080/TCP | HTTP | None (internal) | OAuth Token | Manage KServe serving runtime configurations |
| /api/status | GET | 8080/TCP | HTTP | None (internal) | OAuth Token | Get overall platform status information |
| /api/templates | GET, POST, DELETE | 8080/TCP | HTTP | None (internal) | OAuth Token | Manage OpenShift templates for deployments |
| /api/validate-isv | POST | 8080/TCP | HTTP | None (internal) | OAuth Token | Validate ISV (Independent Software Vendor) configurations |
| / (frontend) | GET | 8080/TCP | HTTP | None (internal) | OAuth Token | Serve React frontend static assets |
| /* (external) | ALL | 8443/TCP | HTTPS | TLS 1.2+ | OpenShift OAuth | OAuth proxy external endpoint with token validation |
| /oauth/healthz | GET | 8443/TCP | HTTPS | TLS 1.2+ | None | OAuth proxy health check |
| /metrics | GET | 8443/TCP | HTTPS | TLS 1.2+ | None | Prometheus metrics endpoint (auth skipped) |

### gRPC Services

None - Dashboard uses REST APIs exclusively.

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| Node.js | >=18.0.0 | Yes | Runtime environment for backend and build tooling |
| Fastify | ^4.16.0 | Yes | Web framework for backend API server |
| React | ^18.2.0 | Yes | Frontend UI framework |
| PatternFly | ^5.2.1 | Yes | Enterprise UI component library |
| @kubernetes/client-node | ^0.12.2 | Yes | Kubernetes API client for backend |
| OpenShift OAuth Proxy | latest | Yes | Authentication and authorization proxy |

### Internal ODH/RHOAI Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| KServe | CRD (serving.kserve.io) | Manage model serving runtimes and inference services |
| Kubeflow Notebooks | CRD (kubeflow.org) | Create and manage Jupyter notebook workbenches |
| Data Science Cluster | CRD (datasciencecluster.opendatahub.io) | Query platform installation and component status |
| DSC Initialization | CRD (dscinitialization.opendatahub.io) | Query platform initialization state |
| Prometheus/Thanos | HTTP API | Query metrics for workload monitoring and resource usage |
| OpenShift Console | CRD (console.openshift.io) | Create console links and integrate with cluster console |
| Model Registry | API (planned) | Integration with model registry service (feature-flagged) |
| Data Science Pipelines | API | Monitor and manage ML pipeline executions |

## Network Architecture

### Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| odh-dashboard | ClusterIP | 8443/TCP | 8443 | HTTPS | TLS 1.2+ (service cert) | OpenShift OAuth | Internal |

### Ingress

| Name | Type | Hosts | Port | Protocol | Encryption | TLS Mode | Exposure |
|------|------|-------|------|----------|------------|----------|----------|
| odh-dashboard | OpenShift Route | cluster-specific | 443/TCP | HTTPS | TLS 1.2+ | Reencrypt | External |

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | Service Account Token | Manage cluster resources via Kubernetes API |
| Thanos Querier (openshift-monitoring) | 9092/TCP | HTTPS | TLS 1.2+ | RBAC Token | Query cluster metrics from Prometheus/Thanos |
| KServe Inference Services | 443/TCP | HTTPS | TLS 1.2+ | Bearer Token | Validate and test model serving endpoints |
| OpenShift Image Registry | 443/TCP | HTTPS | TLS 1.2+ | Service Account Token | Pull notebook image metadata and layers |
| Data Science Pipelines API | 8443/TCP | HTTPS | TLS 1.2+ | Bearer Token | Retrieve pipeline execution data and logs |

## Security

### RBAC - Cluster Roles

| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|
| odh-dashboard | "" (core) | nodes | get, list |
| odh-dashboard | "" (core) | configmaps, persistentvolumeclaims, secrets | create, delete, get, list, patch, update, watch |
| odh-dashboard | "" (core) | pods, serviceaccounts, services | get, list, watch |
| odh-dashboard | "" (core) | namespaces | get, list, watch, create, update, patch, delete |
| odh-dashboard | "" (core), events.k8s.io | events | get, list, watch |
| odh-dashboard | config.openshift.io | clusterversions | get, watch, list |
| odh-dashboard | operators.coreos.com | clusterserviceversions, subscriptions | get, list, watch |
| odh-dashboard | image.openshift.io | imagestreams/layers | get |
| odh-dashboard | route.openshift.io | routes | get, list, watch |
| odh-dashboard | console.openshift.io | consolelinks | get, list, watch |
| odh-dashboard | operator.openshift.io | consoles | get, list, watch |
| odh-dashboard | integreatly.org | rhmis | get, watch, list |
| odh-dashboard | user.openshift.io | groups, users | get, list, watch |
| odh-dashboard | rbac.authorization.k8s.io | rolebindings, clusterrolebindings, roles | get, list, watch, create, update, patch, delete |
| odh-dashboard | machine.openshift.io, autoscaling.openshift.io | machineautoscalers, machinesets | get, list |
| odh-dashboard | kubeflow.org | notebooks | get, list, watch, create, update, patch, delete |
| odh-dashboard | datasciencecluster.opendatahub.io | datascienceclusters | list, watch, get |
| odh-dashboard | dscinitialization.opendatahub.io | dscinitializations | list, watch, get |

### RBAC - Role Bindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| odh-dashboard | dashboard namespace | odh-dashboard (Role) | odh-dashboard |
| odh-dashboard | dashboard namespace | odh-dashboard (ClusterRole) | odh-dashboard |
| odh-dashboard-auth-delegator | kube-system | system:auth-delegator | odh-dashboard |
| odh-dashboard-cluster-monitoring | openshift-monitoring | cluster-monitoring-view | odh-dashboard |
| image-puller | dashboard namespace | system:image-puller | odh-dashboard |

### RBAC - Namespaced Roles

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
| odh-dashboard | template.openshift.io | templates | * (all verbs) |
| odh-dashboard | serving.kserve.io | servingruntimes | * (all verbs) |
| servingruntimes-config-updater | template.openshift.io | templates | get, list |
| servingruntimes-config-updater | opendatahub.io | odhdashboardconfigs | get, list |

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| dashboard-proxy-tls | kubernetes.io/tls | TLS certificate for OAuth proxy HTTPS endpoint | OpenShift service-ca-operator | Yes |
| dashboard-oauth-config-generated | Opaque | Cookie secret for OAuth proxy session management | Kustomize/Operator | No |
| dashboard-oauth-client-generated | Opaque | OAuth client secret for authentication with OpenShift | Kustomize/Operator | No |

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| /api/* | ALL | Bearer Token (forwarded from OAuth proxy) | OAuth Proxy + Backend | OpenShift RBAC - user must have 'get' access to 'odh-dashboard' service in dashboard namespace |
| /oauth/healthz | GET | None | N/A | Public health endpoint |
| /metrics | GET | None (auth skipped) | OAuth Proxy skip-regex | Public metrics endpoint for Prometheus scraping |
| /* (all other paths) | ALL | OpenShift OAuth | OAuth Proxy | Valid OpenShift user session with service access |

### Service Mesh / Network Policies

No Istio service mesh integration or NetworkPolicies defined - Dashboard relies on OpenShift route and OAuth proxy for ingress security.

## Data Flows

### Flow 1: User Authentication and Dashboard Access

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User Browser | OpenShift Route (HAProxy) | 443/TCP | HTTPS | TLS 1.2+ | None |
| 2 | HAProxy | odh-dashboard Service | 8443/TCP | HTTPS | TLS 1.2+ (reencrypt) | None |
| 3 | Service | OAuth Proxy Container | 8443/TCP | HTTPS | TLS 1.2+ (service cert) | None |
| 4 | OAuth Proxy | OpenShift OAuth Server | 443/TCP | HTTPS | TLS 1.2+ | OAuth client credentials |
| 5 | OAuth Proxy (after auth) | Dashboard Backend | 8080/TCP | HTTP | None (localhost) | Bearer Token (x-forwarded-access-token) |
| 6 | Dashboard Backend | Frontend Static Files | N/A | Filesystem | None | None |

### Flow 2: Backend API to Kubernetes API

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Dashboard Backend | Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | Service Account Token (odh-dashboard) |
| 2 | Kubernetes API | etcd | 2379/TCP | HTTP | mTLS | Client cert |

### Flow 3: Metrics Query to Prometheus/Thanos

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User Request | Dashboard Backend (/api/prometheus) | 8080/TCP | HTTP | None (internal) | Bearer Token |
| 2 | Dashboard Backend | Thanos Querier (openshift-monitoring) | 9092/TCP | HTTPS | TLS 1.2+ | User Bearer Token (forwarded) |
| 3 | Thanos Querier | Prometheus/Thanos Store | 10901/TCP | gRPC | TLS 1.2+ | mTLS |

### Flow 4: Notebook Management

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User Request | Dashboard Backend (/api/notebooks) | 8080/TCP | HTTP | None (internal) | Bearer Token |
| 2 | Dashboard Backend | Kubernetes API (kubeflow.org/notebooks) | 6443/TCP | HTTPS | TLS 1.2+ | Service Account Token |
| 3 | Kubeflow Notebook Controller | Kubernetes API (StatefulSet creation) | 6443/TCP | HTTPS | TLS 1.2+ | Controller SA Token |

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| Kubernetes API Server | REST API | 6443/TCP | HTTPS | TLS 1.2+ | Manage all Kubernetes resources (CRDs, namespaces, RBAC, etc.) |
| OpenShift OAuth Server | OAuth 2.0 | 443/TCP | HTTPS | TLS 1.2+ | Authenticate users and validate access tokens |
| Thanos Querier | HTTP API | 9092/TCP | HTTPS | TLS 1.2+ | Query cluster and workload metrics for dashboards |
| OpenShift Image Registry | Docker Registry API | 443/TCP | HTTPS | TLS 1.2+ | Retrieve notebook image metadata and verify imagestreams |
| Kubeflow Notebook Controller | CRD Watch | N/A | Kubernetes API | TLS 1.2+ | Monitor and manage notebook lifecycle via custom resources |
| KServe Controller | CRD Watch | N/A | Kubernetes API | TLS 1.2+ | Manage serving runtimes and inference service configurations |
| Data Science Pipelines API | REST API | 8443/TCP | HTTPS | TLS 1.2+ | Retrieve pipeline runs, logs, and execution graphs |
| OpenShift Console | ConsoleLink CRD | N/A | Kubernetes API | TLS 1.2+ | Create navigation links in OpenShift web console |

## Recent Changes

| Version | Date | Changes |
|---------|------|---------|
| bcf27bf51 | 2024-05-13 | - Merge v2.22.0 fixes |
| ee15dada7 | 2024-05-10 | - Fix Jupyter tile environment variable handling<br>- Merge smarter Jupyter values from notebooks |
| b757ed60a | 2024-05-10 | - Add permissions to dashboard serviceaccount for DSCInitialization<br>- Added extra tests for DSCI fetch |
| bd9bc9547 | 2024-05-10 | - Read pipeline run node details from MLMD context<br>- Update MLMD service proxy configuration port to 8443 |
| 742286f64 | 2024-05-10 | - [RHOAIENG-6519] Distributed Workloads: Support workloads owned by RayCluster or Job when querying CPU/memory usage |
| fd5542a4d | 2024-05-10 | - Jupyter tile: merge cert info from old notebook to avoid certificate loss on updates |
| ae17703dc | 2024-05-10 | - Refactor pipelines context and add useSafePipelines hook for better error handling |

## Deployment Architecture

### Container Images

| Image | Base | Build Tool | Registry | Purpose |
|-------|------|------------|----------|---------|
| odh-dashboard | registry.access.redhat.com/ubi8/nodejs-18:latest | Docker multi-stage | Quay.io | Combined frontend (static assets) + backend (Node.js server) |
| oauth-proxy | OpenShift OAuth Proxy | N/A | registry.redhat.io | Authentication and authorization sidecar |

### Resource Requirements

| Container | CPU Request | CPU Limit | Memory Request | Memory Limit |
|-----------|-------------|-----------|----------------|--------------|
| odh-dashboard | 500m | 1000m | 1Gi | 2Gi |
| oauth-proxy | 500m | 1000m | 1Gi | 2Gi |

### High Availability

| Configuration | Value | Purpose |
|---------------|-------|---------|
| Replicas | 2 | High availability and load distribution |
| Pod Anti-Affinity | Preferred (zone-based) | Distribute pods across availability zones |
| Liveness Probe | TCP 8080 (30s initial, 30s period) | Detect and restart unhealthy containers |
| Readiness Probe | HTTP /api/health (30s initial, 30s period) | Route traffic only to healthy pods |

### Volume Mounts

| Volume | Type | Mount Path | Purpose |
|--------|------|------------|---------|
| proxy-tls | Secret | /etc/tls/private | OAuth proxy TLS certificate and key |
| oauth-config | Secret | /etc/oauth/config | OAuth proxy cookie secret |
| oauth-client | Secret | /etc/oauth/client | OAuth client secret |
| odh-trusted-ca-cert | ConfigMap | /etc/pki/tls/certs, /etc/ssl/certs | Trusted CA bundle for external HTTPS connections |
| odh-ca-cert | ConfigMap | /etc/pki/tls/certs, /etc/ssl/certs | ODH platform CA bundle |

## Configuration

### Environment Variables

| Variable | Default | Purpose |
|----------|---------|---------|
| PORT / BACKEND_PORT | 8080 | Backend HTTP server port |
| IP | 0.0.0.0 | Bind address for backend server |
| FASTIFY_LOG_LEVEL / LOG_LEVEL | info | Logging verbosity (info, debug, error) |
| APP_ENV | production | Application environment (development, production) |
| NODE_ENV | production | Node.js environment for optimizations |

### Feature Flags (via OdhDashboardConfig)

| Feature | Config Field | Default | Purpose |
|---------|--------------|---------|---------|
| Dashboard UI | enablement | true | Enable/disable entire dashboard |
| Info Section | disableInfo | false | Show/hide info/documentation section |
| Support Links | disableSupport | false | Show/hide support contact information |
| User Management | disableUserManagement | false | Enable/disable user and group management |
| Data Science Projects | disableProjects | false | Enable/disable project (namespace) management |
| Model Serving | disableModelServing | false | Enable/disable model serving features |
| KServe | disableKServe | false | Enable/disable KServe-based serving |
| ModelMesh | disableModelMesh | false | Enable/disable ModelMesh-based serving |
| Pipelines | disablePipelines | false | Enable/disable Data Science Pipelines integration |
| Distributed Workloads | disableDistributedWorkloads | false | Enable/disable distributed training workloads |
| Accelerator Profiles | disableAcceleratorProfiles | false | Enable/disable GPU/accelerator management |
| Model Registry | disableModelRegistry | true | Enable/disable model registry integration (preview) |
| Bias Metrics | disableBiasMetrics | false | Enable/disable bias/fairness metrics |
| Performance Metrics | disablePerformanceMetrics | false | Enable/disable model performance monitoring |

## Observability

### Metrics

| Metric Type | Endpoint | Format | Purpose |
|-------------|----------|--------|---------|
| Application Metrics | /metrics | Prometheus | Backend health, request rates, and custom dashboard metrics |

### Logging

| Component | Format | Destination | Level |
|-----------|--------|-------------|-------|
| Backend | JSON (pino) | stdout | Configurable (info default) |
| Frontend | Browser console | Browser | Development only |
| OAuth Proxy | Text | stdout | Info |

### Health Checks

| Endpoint | Type | Check | Success Criteria |
|----------|------|-------|------------------|
| /api/health | Readiness | HTTP GET | 200 OK response |
| 8080/tcp | Liveness | TCP socket | Port accepts connection |
| /oauth/healthz | OAuth Readiness | HTTP GET (HTTPS) | 200 OK response |

## Known Limitations

1. **No Network Policies**: Dashboard does not define NetworkPolicies - relies on OpenShift SDN/OVN default behavior
2. **Single Namespace Scope**: Dashboard deployment assumes single namespace installation (typically `redhat-ods-applications` or `opendatahub`)
3. **OAuth Dependency**: Requires OpenShift OAuth server - not compatible with vanilla Kubernetes
4. **No Horizontal Pod Autoscaling**: Fixed replica count (2) without HPA configuration
5. **Limited Offline Support**: Frontend requires backend API for all operations - no offline functionality

## Security Considerations

1. **OAuth Token Forwarding**: User access tokens are forwarded to backend via `x-forwarded-access-token` header - backend uses this for K8s API calls
2. **Service Account Permissions**: Dashboard service account has broad cluster-level read permissions and namespace-level write permissions
3. **Secret Management**: OAuth secrets are not auto-rotated - manual rotation required for cookie_secret and client_secret
4. **TLS Termination**: Route performs TLS termination and re-encryption - dashboard service must present valid TLS cert
5. **RBAC Delegation**: Dashboard performs OpenShift RBAC delegation check - validates user has 'get' permission on dashboard service before allowing access
