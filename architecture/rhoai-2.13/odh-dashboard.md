# Component: ODH Dashboard

## Metadata
- **Repository**: https://github.com/red-hat-data-services/odh-dashboard.git
- **Version**: v1.21.0-18-rhods-2273-ga7d3413d9
- **Branch**: rhoai-2.13
- **Distribution**: RHOAI
- **Languages**: TypeScript, JavaScript, Node.js 18+, React
- **Deployment Type**: Web Application (Backend API + Frontend UI)

## Purpose
**Short**: Web-based user interface and management console for Red Hat OpenShift AI (RHOAI) and Open Data Hub (ODH) platform components.

**Detailed**: The ODH Dashboard serves as the primary user interface for the Red Hat OpenShift AI platform, providing a centralized location for users to interact with and manage data science workloads. It enables users to launch and manage Jupyter notebooks, configure data science projects, deploy ML models, manage accelerator profiles for GPU workloads, configure model serving runtimes, and access documentation and quickstart guides. The dashboard aggregates functionality from multiple platform components (KServe, Kubeflow, pipelines, model registry) into a cohesive web experience. It handles user authentication via OpenShift OAuth, manages RBAC permissions, and provides both administrative configuration capabilities and end-user workflow interfaces. The dashboard is deployed as a containerized service with a Node.js/Fastify backend API and React/PatternFly frontend, secured behind an OAuth proxy for authentication.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| Backend API Server | Fastify/Node.js | REST API server providing Kubernetes API proxy, configuration management, and business logic |
| Frontend Web UI | React/PatternFly | Single-page application providing user interface for data science workflows |
| OAuth Proxy | OpenShift OAuth Proxy | Authentication and authorization gateway for securing dashboard access |
| Static File Server | Fastify Static | Serves compiled frontend assets from backend container |

## APIs Exposed

### Custom Resource Definitions (CRDs)

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| dashboard.opendatahub.io | v1 | OdhApplication | Namespaced | Defines applications available in the dashboard catalog (Jupyter, VS Code, etc.) |
| opendatahub.io | v1alpha | OdhDashboardConfig | Namespaced | Configures dashboard features, enablement flags, notebook sizes, model server sizes |
| dashboard.opendatahub.io | v1 | OdhDocument | Namespaced | Documentation resources displayed in the dashboard (tutorials, how-to guides) |
| console.openshift.io | v1 | OdhQuickStart | Namespaced | Interactive quickstart tutorials guiding users through workflows |
| dashboard.opendatahub.io | v1, v1alpha | AcceleratorProfile | Namespaced | GPU/accelerator device profiles with tolerations for workload scheduling |

### HTTP Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /api/health | GET | 8080/TCP | HTTP | None | None | Health check endpoint for readiness/liveness probes |
| /api/accelerator-profiles | GET, POST, PUT, DELETE | 8080/TCP | HTTP | None | Internal | Manage GPU/accelerator profiles for notebooks and models |
| /api/accelerators | GET | 8080/TCP | HTTP | None | Internal | Query available accelerator resources in cluster |
| /api/builds | GET, POST, DELETE | 8080/TCP | HTTP | None | Internal | Manage OpenShift BuildConfigs for custom notebook images |
| /api/cluster-settings | GET | 8080/TCP | HTTP | None | Internal | Retrieve cluster-level configuration and settings |
| /api/components | GET | 8080/TCP | HTTP | None | Internal | List installed ODH/RHOAI components and their status |
| /api/config | GET | 8080/TCP | HTTP | None | Internal | Dashboard configuration and feature flags |
| /api/connection-types | GET, POST, PUT, DELETE | 8080/TCP | HTTP | None | Internal | Manage data connection type definitions |
| /api/console-links | GET | 8080/TCP | HTTP | None | Internal | Retrieve OpenShift console links |
| /api/dashboardConfig | GET, PUT | 8080/TCP | HTTP | None | Internal | Admin configuration for dashboard behavior |
| /api/docs | GET | 8080/TCP | HTTP | None | Internal | Retrieve OdhDocument resources for documentation |
| /api/dsc | GET | 8080/TCP | HTTP | None | Internal | Query DataScienceCluster CR status |
| /api/dsci | GET | 8080/TCP | HTTP | None | Internal | Query DSCInitialization CR status |
| /api/images | GET, POST | 8080/TCP | HTTP | None | Internal | Manage ImageStreams for notebook images |
| /api/k8s | GET, POST, PUT, DELETE | 8080/TCP | HTTP | None | Internal | Generic Kubernetes API proxy for various resources |
| /api/modelRegistries | GET, POST, PUT, DELETE | 8080/TCP | HTTP | None | Internal | Manage model registry instances |
| /api/namespaces | GET, POST, PUT, DELETE | 8080/TCP | HTTP | None | Internal | Project/namespace management for data science projects |
| /api/nb-events | GET | 8080/TCP | HTTP | None | Internal | Retrieve notebook-related Kubernetes events |
| /api/notebooks | GET, POST, PUT, DELETE | 8080/TCP | HTTP | None | Internal | Manage Kubeflow Notebook CRs |
| /api/prometheus | GET | 8080/TCP | HTTP | None | Internal | Proxy for Prometheus metrics queries |
| /api/quickstarts | GET | 8080/TCP | HTTP | None | Internal | Retrieve OdhQuickStart resources |
| /api/rolebindings | GET, POST, DELETE | 8080/TCP | HTTP | None | Internal | Manage project RBAC permissions |
| /api/segment-key | GET | 8080/TCP | HTTP | None | Internal | Analytics tracking configuration |
| /api/service | GET | 8080/TCP | HTTP | None | Internal | Query Kubernetes Service resources |
| /api/servingRuntimes | GET, POST, PUT, DELETE | 8080/TCP | HTTP | None | Internal | Manage KServe ServingRuntime templates |
| /api/status | GET | 8080/TCP | HTTP | None | Internal | Component and operator status |
| /api/templates | GET | 8080/TCP | HTTP | None | Internal | OpenShift Template management |
| /api/validate-isv | POST | 8080/TCP | HTTP | None | Internal | Validate ISV partner configurations |
| / | GET | 8443/TCP | HTTPS | TLS 1.2+ | OAuth Bearer Token | Frontend application and static assets via OAuth proxy |
| /oauth/* | GET, POST | 8443/TCP | HTTPS | TLS 1.2+ | OpenShift OAuth | OAuth authentication endpoints |
| /metrics | GET | 8443/TCP | HTTPS | TLS 1.2+ | None | Prometheus metrics (bypasses auth) |

### gRPC Services

None - Dashboard uses HTTP/REST APIs exclusively.

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| Node.js | 18.0.0+ | Yes | Runtime for backend and build tooling |
| React | 18.2.0 | Yes | Frontend framework |
| PatternFly | 5.3.x | Yes | UI component library (Red Hat design system) |
| Fastify | 4.16.0 | Yes | Backend web framework |
| Kubernetes Client | 0.12.2 | Yes | Kubernetes API interactions |
| OAuth Proxy | registry.access.redhat.com/openshift4/ose-oauth-proxy | Yes | Authentication gateway |

### Internal ODH Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| ODH Operator | CRD Watch | Monitors DataScienceCluster and DSCInitialization CRs for platform status |
| Kubeflow Notebooks | CRD CRUD | Creates and manages Notebook CRs for user workspaces |
| KServe | CRD Read/Watch | Retrieves ServingRuntime templates for model serving |
| Model Registry Operator | CRD CRUD | Manages ModelRegistry instances |
| OpenShift Image Registry | API Calls | Manages ImageStreams for custom notebook images |
| OpenShift Build Service | API Calls | Creates BuildConfigs and Builds for notebook image customization |
| Prometheus | HTTP API | Queries metrics for model serving and pipeline performance |

## Network Architecture

### Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| odh-dashboard | ClusterIP | 8443/TCP | 8443 | HTTPS | TLS (Service Serving Cert) | mTLS (service cert) | Internal |

### Ingress

| Name | Type | Hosts | Port | Protocol | Encryption | TLS Mode | Exposure |
|------|------|-------|------|----------|------------|----------|----------|
| odh-dashboard | OpenShift Route | cluster-specific | 443/TCP | HTTPS | TLS 1.2+ | Re-encrypt | External |

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token | CRUD operations on Kubernetes resources |
| Prometheus Service | 9091/TCP | HTTP | None | ServiceAccount Token | Query metrics for model performance dashboards |
| OpenShift OAuth Server | 443/TCP | HTTPS | TLS 1.2+ | OAuth Client Secret | User authentication and token validation |
| Image Registry | 5000/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token | ImageStream layer inspection |

## Security

### RBAC - Cluster Roles

| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|
| odh-dashboard | "" (core) | nodes | get, list |
| odh-dashboard | machine.openshift.io, autoscaling.openshift.io | machineautoscalers, machinesets | get, list |
| odh-dashboard | config.openshift.io | clusterversions | get, watch, list |
| odh-dashboard | operators.coreos.com | clusterserviceversions, subscriptions | get, list, watch |
| odh-dashboard | image.openshift.io | imagestreams/layers | get |
| odh-dashboard | "" (core) | configmaps, persistentvolumeclaims, secrets | create, delete, get, list, patch, update, watch |
| odh-dashboard | route.openshift.io | routes | get, list, watch |
| odh-dashboard | console.openshift.io | consolelinks | get, list, watch |
| odh-dashboard | operator.openshift.io | consoles | get, list, watch |
| odh-dashboard | integreatly.org | rhmis | get, watch, list |
| odh-dashboard | user.openshift.io | groups, users | get, list, watch |
| odh-dashboard | "" (core) | pods, serviceaccounts, services | get, list, watch |
| odh-dashboard | "" (core) | namespaces | get, list, watch, create, update, patch, delete |
| odh-dashboard | rbac.authorization.k8s.io | rolebindings, clusterrolebindings, roles | get, list, watch, create, update, patch, delete |
| odh-dashboard | events.k8s.io | events | get, list, watch |
| odh-dashboard | kubeflow.org | notebooks | get, list, watch, create, update, patch, delete |
| odh-dashboard | datasciencecluster.opendatahub.io | datascienceclusters | list, watch, get |
| odh-dashboard | dscinitialization.opendatahub.io | dscinitializations | list, watch, get |
| odh-dashboard | modelregistry.opendatahub.io | modelregistries | get, list, watch, create, update, patch, delete |

### RBAC - Namespaced Roles

| Role Name | Namespace | API Group | Resources | Verbs |
|-----------|-----------|-----------|-----------|-------|
| odh-dashboard | dashboard namespace | dashboard.opendatahub.io | acceleratorprofiles | create, get, list, update, patch, delete |
| odh-dashboard | dashboard namespace | route.openshift.io | routes | get, list, watch |
| odh-dashboard | dashboard namespace | kfdef.apps.kubeflow.org | kfdefs | get, list, watch |
| odh-dashboard | dashboard namespace | batch | cronjobs, jobs, jobs/status | create, delete, get, list, patch, update, watch |
| odh-dashboard | dashboard namespace | image.openshift.io | imagestreams | create, get, list, update, patch, delete |
| odh-dashboard | dashboard namespace | build.openshift.io | builds, buildconfigs, buildconfigs/instantiate | get, list, watch, create, patch, delete |
| odh-dashboard | dashboard namespace | apps | deployments | patch, update |
| odh-dashboard | dashboard namespace | apps.openshift.io | deploymentconfigs, deploymentconfigs/instantiate | get, list, watch, create, update, patch, delete |
| odh-dashboard | dashboard namespace | opendatahub.io | odhdashboardconfigs | get, list, watch, create, update, patch, delete |
| odh-dashboard | dashboard namespace | kubeflow.org | notebooks | get, list, watch, create, update, patch, delete |
| odh-dashboard | dashboard namespace | dashboard.opendatahub.io | odhapplications, odhdocuments | get, list |
| odh-dashboard | dashboard namespace | console.openshift.io | odhquickstarts | get, list |
| odh-dashboard | dashboard namespace | template.openshift.io | templates | * (all) |
| odh-dashboard | dashboard namespace | serving.kserve.io | servingruntimes | * (all) |

### RBAC - Role Bindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| odh-dashboard | dashboard namespace | odh-dashboard (ClusterRole) | odh-dashboard |
| odh-dashboard | dashboard namespace | odh-dashboard (Role) | odh-dashboard |
| odh-dashboard-auth-delegator | kube-system | system:auth-delegator (ClusterRole) | odh-dashboard |
| odh-dashboard-cluster-monitoring-view | openshift-monitoring | cluster-monitoring-view (ClusterRole) | odh-dashboard |
| odh-dashboard-image-puller | dashboard namespace | system:image-puller (ClusterRole) | odh-dashboard |

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| dashboard-proxy-tls | kubernetes.io/tls | TLS certificate for OAuth proxy HTTPS endpoint | service.alpha.openshift.io/serving-cert-secret-name annotation | Yes (OpenShift Service CA) |
| dashboard-oauth-config-generated | Opaque | OAuth proxy cookie secret for session management | Dashboard deployment | No |
| dashboard-oauth-client-generated | Opaque | OAuth client secret for OpenShift authentication | Dashboard deployment | No |
| odh-trusted-ca-bundle | ConfigMap | Cluster-wide trusted CA certificates | OpenShift CA operator | Yes |

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| / (all frontend routes) | GET, POST | Bearer Token (OpenShift OAuth JWT) | OAuth Proxy (port 8443) | OpenShift SAR: user can list projects |
| /api/* (all backend APIs) | GET, POST, PUT, DELETE | Bearer Token (forwarded from OAuth proxy) | Backend (Kubernetes client with user token) | Per-resource RBAC via user impersonation |
| /metrics | GET | None (bypass auth) | OAuth Proxy | Public metrics endpoint |
| /oauth/healthz | GET | None | OAuth Proxy | Health check bypass |

## Data Flows

### Flow 1: User Authentication and Frontend Access

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User Browser | OpenShift Route (odh-dashboard) | 443/TCP | HTTPS | TLS 1.2+ | None (initial) |
| 2 | Route | OAuth Proxy (sidecar) | 8443/TCP | HTTPS | TLS (service cert) | None (redirect to OAuth) |
| 3 | OAuth Proxy | OpenShift OAuth Server | 443/TCP | HTTPS | TLS 1.2+ | OAuth Client Secret |
| 4 | OpenShift OAuth | User Browser | 443/TCP | HTTPS | TLS 1.2+ | User credentials |
| 5 | User Browser (with token) | OAuth Proxy | 8443/TCP | HTTPS | TLS (service cert) | Bearer Token (cookie) |
| 6 | OAuth Proxy | Backend API (localhost) | 8080/TCP | HTTP | None | Bearer Token (header) |
| 7 | Backend API | Frontend Static Files | local | local | None | None |

### Flow 2: API Request to Kubernetes

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Frontend JS (browser) | OAuth Proxy | 8443/TCP | HTTPS | TLS (service cert) | Bearer Token (cookie) |
| 2 | OAuth Proxy | Backend API (localhost) | 8080/TCP | HTTP | None | Bearer Token (header) |
| 3 | Backend API | Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | User Bearer Token (impersonation) |
| 4 | Kubernetes API | Backend API | 6443/TCP | HTTPS | TLS 1.2+ | Response |
| 5 | Backend API | OAuth Proxy | 8080/TCP | HTTP | None | Response |
| 6 | OAuth Proxy | Frontend JS | 8443/TCP | HTTPS | TLS (service cert) | Response |

### Flow 3: Notebook Creation

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User (Frontend) | Backend API (via OAuth proxy) | 8443/TCP | HTTPS | TLS (service cert) | Bearer Token |
| 2 | Backend API | Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | User Bearer Token |
| 3 | Backend API | Kubernetes API (create Namespace if needed) | 6443/TCP | HTTPS | TLS 1.2+ | User Bearer Token |
| 4 | Backend API | Kubernetes API (create Notebook CR) | 6443/TCP | HTTPS | TLS 1.2+ | User Bearer Token |
| 5 | Backend API | Kubernetes API (create RBAC) | 6443/TCP | HTTPS | TLS 1.2+ | User Bearer Token |
| 6 | Backend API | Frontend (response) | 8080/TCP | HTTP | None | Response |

### Flow 4: Metrics Query

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Frontend JS | Backend API (/api/prometheus) | 8443/TCP | HTTPS | TLS (service cert) | Bearer Token |
| 2 | Backend API | Prometheus Service | 9091/TCP | HTTP | None | ServiceAccount Token |
| 3 | Prometheus | Backend API | 9091/TCP | HTTP | None | Response (metrics data) |
| 4 | Backend API | Frontend JS | 8443/TCP | HTTPS | TLS (service cert) | Response (JSON) |

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| Kubernetes API Server | REST API | 6443/TCP | HTTPS | TLS 1.2+ | CRUD operations on all Kubernetes resources |
| OpenShift OAuth Server | OAuth 2.0 | 443/TCP | HTTPS | TLS 1.2+ | User authentication and authorization |
| Prometheus | REST API (PromQL) | 9091/TCP | HTTP | None | Query model serving and pipeline metrics |
| Kubeflow Notebook Controller | CRD Watch | 6443/TCP | HTTPS | TLS 1.2+ | Notebook lifecycle managed by controller (watches Notebook CRs) |
| KServe Controller | CRD Read | 6443/TCP | HTTPS | TLS 1.2+ | Retrieve serving runtime templates |
| ODH Operator | CRD Watch | 6443/TCP | HTTPS | TLS 1.2+ | Monitor platform configuration (DataScienceCluster, DSCInitialization) |
| Model Registry Operator | CRD CRUD | 6443/TCP | HTTPS | TLS 1.2+ | Manage model registry instances |
| OpenShift Console | ConsoleLink CRD | 6443/TCP | HTTPS | TLS 1.2+ | Register dashboard link in OpenShift web console navigation |

## Recent Changes

| Commit | Date | Changes |
|--------|------|---------|
| a7d3413d9 | 2025-05-08 | - Merge Konflux service account migration for odh-dashboard-v2-13 |
| 7e8e5db84 | 2025-04-25 | - Konflux build pipeline service account migration |
| 2d70162a4 | 2025-03-12 | - Update Konflux references for build pipeline |
| b7e12bd9c | 2025-03-12 | - Update Konflux references |
| 5f9a5b9fb | 2025-03-11 | - Update Konflux references to d00d159 |
| ed611b546 | 2025-03-11 | - Update Konflux references |
| 1e76e10bf | 2025-03-11 | - Update Konflux references |
| be25aecaa | 2025-03-10 | - Update Konflux references to 493a872 |
| 6570e98b3 | 2025-03-10 | - Update Konflux references to 493a872 |
| 7b081d96a | 2025-03-06 | - Update registry.access.redhat.com/ubi8/nodejs-18 Docker digest to 72a3c0e |
| 86f877d2b | 2025-03-05 | - Update Konflux references |
| 51ad6bb0d | 2025-03-03 | - Update Konflux references (dependency updates) |
| 8c2b46a2b | 2025-03-02 | - Update Konflux references to b9cb1e1 |
| 8e360f97d | 2025-02-28 | - Update Konflux references to 944e769 |
| 46622067e | 2025-02-27 | - Update Konflux references |
| e113e834e | 2025-02-27 | - Update Konflux references to 8b6f22f |
| b6ca6d8c2 | 2025-02-26 | - Update Konflux references |
| d11a1ae81 | 2025-02-24 | - Update Konflux references to 5bc6129 |
| b8a0dc7e6 | 2025-02-18 | - Update registry.access.redhat.com/ubi8/nodejs-18 docker digest to 0a4adb2 |
| 4362b6958 | 2025-02-16 | - Update Konflux references to b78123a |

## Deployment Configuration

### Container Images

**Primary**: Built via Konflux CI/CD using `Dockerfile.konflux`
- Base image: `registry.access.redhat.com/ubi8/nodejs-18`
- Multi-stage build: builder stage compiles TypeScript and Webpack bundles, runtime stage serves application
- Environment variables set for RHOAI branding (logo, product name, documentation links)

### Resource Requirements

| Container | CPU Request | CPU Limit | Memory Request | Memory Limit |
|-----------|-------------|-----------|----------------|--------------|
| odh-dashboard | 500m | 1000m | 1Gi | 2Gi |
| oauth-proxy | 500m | 1000m | 1Gi | 2Gi |

### High Availability

- **Replicas**: 2 (default)
- **Anti-affinity**: Preferred pod anti-affinity across availability zones (topology.kubernetes.io/zone)
- **Probes**:
  - Liveness (odh-dashboard): TCP socket on 8080, 30s initial delay
  - Readiness (odh-dashboard): HTTP GET /api/health on 8080, 30s initial delay
  - Liveness (oauth-proxy): HTTP GET /oauth/healthz on 8443, 30s initial delay
  - Readiness (oauth-proxy): HTTP GET /oauth/healthz on 8443, 5s initial delay

### Volumes and Mounts

| Volume | Type | Mount Path | Purpose |
|--------|------|------------|---------|
| proxy-tls | Secret | /etc/tls/private | TLS certificate/key for OAuth proxy HTTPS |
| oauth-config | Secret | /etc/oauth/config | OAuth proxy cookie secret |
| oauth-client | Secret | /etc/oauth/client | OAuth client secret for OpenShift |
| odh-trusted-ca-cert | ConfigMap | /etc/pki/tls/certs/, /etc/ssl/certs/ | Cluster trusted CA bundle |
| odh-ca-cert | ConfigMap | /etc/pki/tls/certs/, /etc/ssl/certs/ | ODH-specific CA bundle |

## Known Limitations and Considerations

1. **Backend is stateless**: No persistent storage; all state managed via Kubernetes API resources
2. **OAuth dependency**: Requires OpenShift OAuth server; not portable to vanilla Kubernetes without modification
3. **Single namespace deployment**: Dashboard typically deployed in a dedicated namespace (e.g., `redhat-ods-applications`)
4. **User impersonation**: Backend uses user bearer tokens to impersonate users for Kubernetes API calls, ensuring RBAC is respected
5. **No service mesh integration**: Currently does not integrate with Istio/Service Mesh for mTLS or advanced traffic management
6. **Metrics endpoint exposed**: /metrics endpoint bypasses authentication for Prometheus scraping
7. **Internal HTTP**: Backend container uses HTTP (not HTTPS) since it's only accessible via localhost from OAuth proxy sidecar
