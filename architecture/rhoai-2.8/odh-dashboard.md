# Component: ODH Dashboard

## Metadata
- **Repository**: https://github.com/red-hat-data-services/odh-dashboard.git
- **Version**: v1.21.0-18-rhods-1329-g8d4570f4d
- **Branch**: rhoai-2.8
- **Distribution**: RHOAI
- **Languages**: TypeScript, JavaScript (Node.js 18)
- **Deployment Type**: Full-stack Web Application (Frontend + Backend Service)

## Purpose
**Short**: Web-based management dashboard for Red Hat OpenShift AI platform components and data science workflows.

**Detailed**: The ODH Dashboard serves as the primary user interface for Red Hat OpenShift AI (RHOAI), providing a unified web console for managing data science workloads, Jupyter notebooks, model serving, and platform components. It integrates with OpenShift's authentication system via OAuth proxy and provides a modern React-based frontend backed by a Node.js/Fastify API server. The dashboard allows administrators to configure platform settings, manage accelerator profiles, control feature enablement, and provides users with access to documentation, quickstarts, and application catalogs. It acts as a central hub for interacting with various ODH/RHOAI components including KServe, notebooks, pipelines, and distributed workloads.

The dashboard is built as a containerized application using Konflux build pipelines, deployed with high availability (2 replicas with pod anti-affinity), and secured with OpenShift OAuth delegation for authentication. It exposes both HTTP REST APIs and WebSocket connections for real-time updates, and integrates with Prometheus for metrics collection.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| odh-dashboard | Container (Frontend) | React 18 single-page application providing UI for RHOAI platform |
| odh-dashboard | Container (Backend) | Node.js/Fastify API server providing REST endpoints and K8s integration |
| oauth-proxy | Sidecar Container | OpenShift OAuth authentication proxy for securing dashboard access |
| Frontend Build | Webpack Bundle | Static assets compiled from TypeScript/React source |
| Backend Build | TypeScript Compiled | Node.js application built from TypeScript sources |

## APIs Exposed

### Custom Resource Definitions (CRDs)

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| dashboard.opendatahub.io | v1, v1alpha | AcceleratorProfile | Namespaced | Defines accelerator hardware profiles (GPUs, etc.) with tolerations and identifiers |
| dashboard.opendatahub.io | v1 | OdhApplication | Namespaced | Application catalog entries shown in dashboard with enablement state and links |
| opendatahub.io | v1alpha | OdhDashboardConfig | Namespaced | Central configuration for dashboard features, groups, notebook/model sizes |
| dashboard.opendatahub.io | v1 | OdhDocument | Namespaced | Documentation resources displayed in dashboard with URLs and metadata |
| console.openshift.io | v1 | OdhQuickStart | Namespaced | Guided tutorial workflows integrated into dashboard UI |

### HTTP Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /api/health | GET | 8080/TCP | HTTP | None | None | Health check endpoint for readiness/liveness probes |
| /api/accelerator-profiles | GET, POST, PUT, DELETE | 8080/TCP | HTTP | None | OAuth | Manage accelerator profiles (GPU configs) |
| /api/accelerators | GET | 8080/TCP | HTTP | None | OAuth | List available accelerators in cluster |
| /api/builds | GET | 8080/TCP | HTTP | None | OAuth | Retrieve OpenShift build information |
| /api/cluster-settings | GET, PUT | 8080/TCP | HTTP | None | OAuth | Cluster-level configuration settings |
| /api/components | GET | 8080/TCP | HTTP | None | OAuth | List ODH/RHOAI platform components |
| /api/config | GET, PATCH | 8080/TCP | HTTP | None | OAuth | Dashboard configuration management |
| /api/console-links | GET | 8080/TCP | HTTP | None | OAuth | OpenShift console link integration |
| /api/dashboardConfig | GET, PATCH | 8080/TCP | HTTP | None | OAuth | OdhDashboardConfig CR management |
| /api/docs | GET | 8080/TCP | HTTP | None | OAuth | Documentation resources list |
| /api/dsc | GET | 8080/TCP | HTTP | None | OAuth | DataScienceCluster status |
| /api/groups-config | GET, PUT | 8080/TCP | HTTP | None | OAuth | Admin and allowed groups configuration |
| /api/images | GET, POST, PUT, DELETE | 8080/TCP | HTTP | None | OAuth | Container image stream management |
| /api/namespaces | GET | 8080/TCP | HTTP | None | OAuth | List/manage data science project namespaces |
| /api/nb-events | GET | 8080/TCP | HTTP | None | OAuth | Jupyter notebook pod events |
| /api/notebooks | GET, POST, PUT, DELETE | 8080/TCP | HTTP | None | OAuth | Kubeflow notebook CR management |
| /api/prometheus | GET | 8080/TCP | HTTP | None | OAuth | Proxy to Prometheus/Thanos metrics |
| /api/quickstarts | GET | 8080/TCP | HTTP | None | OAuth | QuickStart tutorial resources |
| /api/rolebindings | GET, POST, PATCH, DELETE | 8080/TCP | HTTP | None | OAuth | RBAC rolebinding management |
| /api/route | GET | 8080/TCP | HTTP | None | OAuth | OpenShift route information |
| /api/service | GET | 8080/TCP | HTTP | None | OAuth | Kubernetes service queries |
| /api/servingRuntimes | GET, POST, PUT, DELETE | 8080/TCP | HTTP | None | OAuth | KServe serving runtime templates |
| /api/templates | GET | 8080/TCP | HTTP | None | OAuth | OpenShift template management |
| /api/k8s/* | GET, POST, PUT, PATCH, DELETE | 8080/TCP | HTTP | None | OAuth | Generic Kubernetes API proxy |
| /oauth/* | GET | 8443/TCP | HTTPS | TLS 1.2+ | OAuth | OAuth proxy endpoints (health, callback) |
| /* | GET | 8080/TCP | HTTP | None | OAuth | Frontend static asset serving (fallback to index.html) |

### WebSocket Services

| Service | Port | Protocol | Encryption | Auth | Purpose |
|---------|------|----------|------------|------|---------|
| /wss/* | 8080/TCP | WebSocket | None | OAuth | Real-time event streaming (notebook events, logs) |

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| Node.js | 18.0.0+ | Yes | Runtime for backend server |
| React | 18.2.0 | Yes | Frontend UI framework |
| Fastify | 4.16.0 | Yes | Backend web server framework |
| @kubernetes/client-node | 0.12.2 | Yes | Kubernetes API client library |
| PatternFly | 5.1.0+ | Yes | UI component library (Red Hat design system) |
| Webpack | 5.76.0+ | Yes | Frontend build tooling |
| Axios | 1.6.4+ | Yes | HTTP client for API calls |
| Redux | 4.2.0 | Yes | Frontend state management |
| Pino | 8.11.0 | Yes | Structured logging library |
| prom-client | 14.0.1 | Yes | Prometheus metrics collection |
| js-yaml | 4.0.0 | Yes | YAML parsing for K8s resources |

### Internal ODH/RHOAI Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| KServe | CRD (serving.kserve.io) | Manage serving runtimes and inference services |
| Kubeflow Notebooks | CRD (kubeflow.org/notebooks) | Create and manage Jupyter notebook instances |
| DataScienceCluster | CRD (datasciencecluster.opendatahub.io) | Monitor platform installation status |
| OpenShift OAuth | OAuth Delegation | User authentication and authorization |
| OpenShift Console | ConsoleLink CRD | Integrate dashboard link into OpenShift console |
| Prometheus/Thanos | HTTP API | Query metrics for notebooks and model servers |
| OpenShift Builds | API (build.openshift.io) | Trigger and monitor notebook image builds |
| OpenShift ImageStreams | API (image.openshift.io) | Manage custom notebook images |
| OpenShift Routes | API (route.openshift.io) | Discover service endpoints |

## Network Architecture

### Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| odh-dashboard | ClusterIP | 8443/TCP | 8443 | HTTPS | TLS (Service Serving Cert) | OAuth Proxy | Internal |

### Ingress

| Name | Type | Hosts | Port | Protocol | Encryption | TLS Mode | Exposure |
|------|------|-------|------|----------|------------|----------|----------|
| odh-dashboard | OpenShift Route | Auto-generated | 8443/TCP | HTTPS | TLS 1.2+ | Reencrypt | External |

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| Kubernetes API Server | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token | CRUD operations on K8s resources |
| Prometheus/Thanos | 9091/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token | Query notebook/model metrics |
| OpenShift OAuth Server | 443/TCP | HTTPS | TLS 1.2+ | OAuth Client Secret | User authentication delegation |
| OpenShift Image Registry | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token | Query imagestream layer metadata |

## Security

### RBAC - Cluster Roles

| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|
| odh-dashboard | "" | nodes | get, list |
| odh-dashboard | "" | configmaps, persistentvolumeclaims, secrets | create, delete, get, list, patch, update, watch |
| odh-dashboard | "" | pods, serviceaccounts, services | get, list, watch |
| odh-dashboard | "" | namespaces | get, list, watch, create, update, patch, delete |
| odh-dashboard | "", events.k8s.io | events | get, list, watch |
| odh-dashboard | rbac.authorization.k8s.io | rolebindings, clusterrolebindings, roles | get, list, watch, create, update, patch, delete |
| odh-dashboard | machine.openshift.io | machineautoscalers, machinesets | get, list |
| odh-dashboard | autoscaling.openshift.io | machineautoscalers | get, list |
| odh-dashboard | "", config.openshift.io | clusterversions | get, watch, list |
| odh-dashboard | operators.coreos.com | clusterserviceversions, subscriptions | get, list, watch |
| odh-dashboard | "", image.openshift.io | imagestreams/layers | get |
| odh-dashboard | route.openshift.io | routes | get, list, watch |
| odh-dashboard | console.openshift.io | consolelinks | get, list, watch |
| odh-dashboard | operator.openshift.io | consoles | get, list, watch |
| odh-dashboard | "", integreatly.org | rhmis | get, watch, list |
| odh-dashboard | user.openshift.io | groups, users | get, list, watch |
| odh-dashboard | kubeflow.org | notebooks | get, list, watch, create, update, patch, delete |
| odh-dashboard | datasciencecluster.opendatahub.io | datascienceclusters | list, watch, get |

### RBAC - Namespace Roles

| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|
| odh-dashboard | dashboard.opendatahub.io | acceleratorprofiles | create, get, list, update, patch, delete |
| odh-dashboard | dashboard.opendatahub.io | odhapplications, odhdocuments | get, list |
| odh-dashboard | console.openshift.io | odhquickstarts | get, list |
| odh-dashboard | route.openshift.io | routes | get, list, watch |
| odh-dashboard | kfdef.apps.kubeflow.org | kfdefs | get, list, watch |
| odh-dashboard | batch | cronjobs, jobs, jobs/status | create, delete, get, list, patch, update, watch |
| odh-dashboard | image.openshift.io | imagestreams | create, get, list, update, patch, delete |
| odh-dashboard | build.openshift.io | builds, buildconfigs, buildconfigs/instantiate | get, list, watch, create, patch, delete |
| odh-dashboard | apps | deployments | patch, update |
| odh-dashboard | apps.openshift.io | deploymentconfigs, deploymentconfigs/instantiate | get, list, watch, create, update, patch, delete |
| odh-dashboard | opendatahub.io | odhdashboardconfigs | get, list, watch, create, update, patch, delete |
| odh-dashboard | kubeflow.org | notebooks | get, list, watch, create, update, patch, delete |
| odh-dashboard | template.openshift.io | templates | * (all verbs) |
| odh-dashboard | serving.kserve.io | servingruntimes | * (all verbs) |

### RBAC - Role Bindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| odh-dashboard | opendatahub/redhat-ods-applications | odh-dashboard (Role) | odh-dashboard |
| odh-dashboard | Cluster | odh-dashboard (ClusterRole) | odh-dashboard |
| odh-dashboard-auth-delegator | Cluster | system:auth-delegator (ClusterRole) | odh-dashboard |
| odh-dashboard-cluster-monitoring | Cluster | cluster-monitoring-view (ClusterRole) | odh-dashboard |
| odh-dashboard-model-serving | opendatahub/redhat-ods-applications | odh-dashboard-model-serving (Role) | odh-dashboard |

### Additional RBAC

| Binding Name | Namespace | Role | Service Account | Purpose |
|--------------|-----------|------|-----------------|---------|
| odh-dashboard-image-puller | Cluster | system:image-puller (ClusterRole) | odh-dashboard | Pull images from registry |
| odh-dashboard-fetch-builds-and-images | opendatahub/redhat-ods-applications | odh-dashboard-fetch-builds-and-images (Role) | odh-dashboard | Access OpenShift builds/images |
| odh-dashboard-fetch-accelerators | opendatahub/redhat-ods-applications | odh-dashboard-fetch-accelerators (Role) | odh-dashboard | Read accelerator node information |

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| dashboard-proxy-tls | kubernetes.io/tls | OAuth proxy TLS certificate | service.alpha.openshift.io/serving-cert-secret-name | Yes |
| dashboard-oauth-config-generated | Opaque | OAuth cookie secret | Manual/Operator | No |
| dashboard-oauth-client-generated | Opaque | OAuth client secret for OpenShift | Manual/Operator | No |

### ConfigMaps

| ConfigMap Name | Purpose | Managed By |
|----------------|---------|------------|
| odh-trusted-ca-bundle | Trusted CA certificates for external services | Platform/Operator |
| odh-trusted-ca-bundle (odh-ca-bundle.crt key) | ODH-specific CA bundle | Platform/Operator |

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| /api/* | All | Bearer Token (OAuth) | OAuth Proxy | OpenShift user authenticated, delegated verb check on odh-dashboard service |
| /oauth/* | GET | OAuth Code Flow | OAuth Proxy | OpenShift OAuth server |
| /metrics | GET | None (skipped) | OAuth Proxy | Skip auth via --skip-auth-regex |
| /api/health | GET | None | Application | Unsecured for health checks |
| /* (Frontend) | GET | Bearer Token (OAuth) | OAuth Proxy | Authenticated users only |

### Pod Security

| Setting | Value | Purpose |
|---------|-------|---------|
| runAsNonRoot | Implicit (user: default) | Container runs as non-root user (UID 1001 in UBI) |
| securityContext | Not explicitly set | Inherits namespace/cluster defaults |
| Service Account | odh-dashboard | Dedicated SA with scoped RBAC permissions |

## Data Flows

### Flow 1: User Authentication & Dashboard Access

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User Browser | OpenShift Router | 443/TCP | HTTPS | TLS 1.2+ | None |
| 2 | OpenShift Router | odh-dashboard Service | 8443/TCP | HTTPS | TLS (reencrypt) | None |
| 3 | odh-dashboard Service | oauth-proxy Container | 8443/TCP | HTTPS | TLS | None |
| 4 | oauth-proxy | OpenShift OAuth Server | 443/TCP | HTTPS | TLS 1.2+ | OAuth Client Secret |
| 5 | oauth-proxy | odh-dashboard Container | 8080/TCP | HTTP | None | Bearer Token (passed from OAuth) |
| 6 | odh-dashboard Container | User Browser | 8080→8443/TCP | HTTP→HTTPS | TLS (via proxy) | Bearer Token |

### Flow 2: Dashboard API to Kubernetes Resources

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User Browser | oauth-proxy | 8443/TCP | HTTPS | TLS | Bearer Token |
| 2 | oauth-proxy | odh-dashboard Container | 8080/TCP | HTTP | None | Bearer Token |
| 3 | odh-dashboard Container | Kubernetes API Server | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 4 | Kubernetes API Server | odh-dashboard Container | 443/TCP | HTTPS | TLS 1.2+ | Response |
| 5 | odh-dashboard Container | User Browser | 8080→8443/TCP | HTTP→HTTPS | TLS (via proxy) | Bearer Token |

### Flow 3: Prometheus Metrics Query

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User Browser | odh-dashboard API | 8443/TCP | HTTPS | TLS | Bearer Token |
| 2 | odh-dashboard Container | Prometheus/Thanos Service | 9091/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 3 | Prometheus Service | odh-dashboard Container | 9091/TCP | HTTPS | TLS 1.2+ | Metrics Data |
| 4 | odh-dashboard Container | User Browser | 8080→8443/TCP | HTTP→HTTPS | TLS (via proxy) | Metrics Response |

### Flow 4: Notebook Creation

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User Browser | odh-dashboard API (/api/notebooks) | 8443/TCP | HTTPS | TLS | Bearer Token |
| 2 | odh-dashboard Container | Kubernetes API (Notebook CRD) | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 3 | odh-dashboard Container | Kubernetes API (ConfigMaps, Secrets) | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 4 | odh-dashboard Container | User Browser | 8080→8443/TCP | HTTP→HTTPS | TLS (via proxy) | Notebook CR Response |

### Flow 5: WebSocket Event Stream

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User Browser | oauth-proxy (WebSocket Upgrade) | 8443/TCP | WSS (WebSocket Secure) | TLS | Bearer Token |
| 2 | oauth-proxy | odh-dashboard Container | 8080/TCP | WS (WebSocket) | None | Bearer Token |
| 3 | odh-dashboard Container | Kubernetes API (Watch) | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 4 | Kubernetes API | odh-dashboard Container (Stream) | 443/TCP | HTTPS | TLS 1.2+ | Event Stream |
| 5 | odh-dashboard Container | User Browser (Stream) | 8080→8443/TCP | WS→WSS | TLS (via proxy) | Event Stream |

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| Kubernetes API Server | REST API | 443/TCP | HTTPS | TLS 1.2+ | CRUD on all K8s resources, watch events |
| OpenShift OAuth | OAuth 2.0 | 443/TCP | HTTPS | TLS 1.2+ | User authentication and token validation |
| Prometheus/Thanos | HTTP API | 9091/TCP | HTTPS | TLS 1.2+ | Query notebook/model serving metrics |
| OpenShift Console | ConsoleLink CRD | N/A | N/A | N/A | Display dashboard link in OpenShift UI |
| KServe Operator | CRD Watch | N/A | K8s API | TLS 1.2+ | Monitor/manage serving runtimes |
| Kubeflow Notebook Controller | CRD Create/Update | N/A | K8s API | TLS 1.2+ | Create/manage notebook pods |
| OpenShift Build System | REST API | 443/TCP | HTTPS | TLS 1.2+ | Trigger notebook image builds |
| OpenShift Image Registry | REST API | 443/TCP | HTTPS | TLS 1.2+ | Query imagestream layers |
| DataScienceCluster Operator | CRD Watch | N/A | K8s API | TLS 1.2+ | Monitor platform component status |

## Deployment Architecture

### Container Images

| Image | Base | Build System | Purpose |
|-------|------|--------------|---------|
| odh-dashboard | registry.access.redhat.com/ubi8/nodejs-18 | Konflux | Multi-stage build: compile frontend/backend, runtime serves both |
| oauth-proxy | registry.redhat.io/openshift4/ose-oauth-proxy | Red Hat | OpenShift OAuth authentication sidecar |

### Pod Configuration

| Setting | Value | Purpose |
|---------|-------|---------|
| Replicas | 2 | High availability |
| Anti-affinity | Preferred (zone topology) | Spread pods across availability zones |
| Resource Requests | 500m CPU, 1Gi memory (per container) | Guaranteed resources |
| Resource Limits | 1000m CPU, 2Gi memory (per container) | Resource caps |
| Liveness Probe (odh-dashboard) | TCP :8080, 30s initial, 30s period | Detect container failures |
| Readiness Probe (odh-dashboard) | HTTP GET /api/health :8080, 30s initial, 30s period | Traffic routing control |
| Liveness Probe (oauth-proxy) | HTTPS GET /oauth/healthz :8443, 30s initial, 5s period | Detect OAuth proxy failures |
| Readiness Probe (oauth-proxy) | HTTPS GET /oauth/healthz :8443, 5s initial, 5s period | OAuth proxy readiness |

### Volume Mounts

| Volume | Type | Mount Path | Purpose |
|--------|------|------------|---------|
| proxy-tls | Secret | /etc/tls/private | OAuth proxy TLS certificate and key |
| oauth-config | Secret | /etc/oauth/config | OAuth cookie secret |
| oauth-client | Secret | /etc/oauth/client | OAuth client secret |
| odh-trusted-ca-cert | ConfigMap | /etc/pki/tls/certs/odh-trusted-ca-bundle.crt, /etc/ssl/certs/odh-trusted-ca-bundle.crt | Platform CA certificates |
| odh-ca-cert | ConfigMap | /etc/pki/tls/certs/odh-ca-bundle.crt, /etc/ssl/certs/odh-ca-bundle.crt | ODH-specific CA bundle |

### Build Process (Konflux)

| Stage | Action | Output |
|-------|--------|--------|
| Builder | npm ci --omit=optional | Install all dependencies |
| Builder | npm run build | Compile TypeScript backend, webpack bundle frontend |
| Runtime | Copy frontend/public, backend/dist | Production artifacts only |
| Runtime | npm ci --omit=dev --omit=optional (backend) | Install production dependencies only |
| Runtime | CMD npm run start (in backend/) | Start Fastify server on port 8080 |

## Configuration

### Environment Variables

| Variable | Default | Source | Purpose |
|----------|---------|--------|---------|
| ODH_LOGO | ../images/rhoai-logo.svg | Dockerfile.konflux | RHOAI branding |
| ODH_PRODUCT_NAME | Red Hat OpenShift AI | Dockerfile.konflux | Product name display |
| ODH_FAVICON | rhoai-favicon.svg | Dockerfile.konflux | Browser favicon |
| DOC_LINK | https://access.redhat.com/documentation/en-us/red_hat_openshift_data_science | Dockerfile.konflux | Documentation link |
| SUPPORT_LINK | https://access.redhat.com/support/cases/#/case/new/open-case | Dockerfile.konflux | Support case link |
| COMMUNITY_LINK | (empty) | Dockerfile.konflux | Community link (disabled for RHOAI) |
| NODE_ENV | production | Runtime | Node.js environment mode |
| NAMESPACE | (fieldRef: metadata.namespace) | Pod Spec | Current namespace for OAuth delegation |

### Runtime Configuration

| Setting | Source | Purpose |
|---------|--------|---------|
| Port | 8080 (default) | server.ts | Backend HTTP listener port |
| IP | 0.0.0.0 (default) | server.ts | Backend bind address |
| CA Certificates | Multiple file paths | server.ts | Trusted CAs for outbound HTTPS connections |
| OAuth Client ID | dashboard-oauth-client | deployment.yaml | OpenShift OAuth client identifier |
| OAuth Scope | user:full | deployment.yaml | OAuth permissions requested |
| OAuth Cookie Expiry | 23h0m0s | deployment.yaml | Session cookie lifetime |

## Recent Changes

| Commit | Date | Changes |
|--------|------|---------|
| 8d4570f4d | 2025-09-01 | - Update Konflux references (#929) |
| bc865f146 | Recent | - Update Konflux references (#928) |
| 68b062e37 | Recent | - Update Konflux references (#926) |
| 827d64dfe | Recent | - Update Konflux references (#924) |
| 0962e04f6 | Recent | - Update Konflux references (#923) |
| 66785f2ac | Recent | - Update Konflux references (#922) |
| e02aa34b2 | Recent | - Update Konflux references (#921) |
| 82087919e | Recent | - Update Konflux references (#920) |
| eabfd2c01 | Recent | - Update Konflux references (#919) |
| 792dfa44b | Recent | - Update Konflux references (#918) |
| 2ab5243ab | Recent | - Update Konflux references (#917) |
| 4ab33b84e | Recent | - Update Konflux references (#916) |
| 0d424f71f | Recent | - chore(deps): update konflux references (#860) |
| 2dfddc412 | Recent | - Update Konflux references (#812) |
| 1ffdaeb3a | Recent | - chore(deps): update nodejs-18 digest to 77d47e5 |
| c9b5b5754 | Recent | - chore(deps): update nodejs-18 digest to 77d47e5 (#797) |
| bb6d55af2 | Recent | - chore(deps): update nodejs-18 digest to ee81ae0 (#777) |
| a4575ec54 | Recent | - chore(deps): update nodejs-18 digest to 5f2b224 (#769) |
| d79e6ce7b | Recent | - chore(deps): update konflux references (#765) |
| b45f57795 | Recent | - chore(deps): update nodejs-18 digest to 89deea4 (#752) |

## Notes

- **Manifests Location**: `manifests/` directory contains Kustomize-based deployment configuration with base and overlay structure
- **Primary Manifest Path**: `manifests/base/` for core deployment resources
- **CRD Definitions**: `manifests/crd/` contains 5 custom resource definitions owned by the dashboard
- **Model Serving Templates**: `manifests/modelserving/` contains out-of-the-box serving runtime templates (Caikit, OVMS, TGIS)
- **Console Integration**: `manifests/consolelink/` integrates dashboard into OpenShift console navigation
- **Application Catalog**: `manifests/apps/` contains sample OdhApplication and OdhDocument CRs for Jupyter
- **OAuth Proxy Configuration**: Uses upstream delegation to OpenShift OAuth server, no local user database
- **Health Checks**: `/api/health` endpoint is unsecured for probe access; `/oauth/healthz` for OAuth proxy health
- **Metrics**: Prometheus metrics exposed on `/metrics` endpoint (auth skipped via OAuth proxy regex)
- **WebSocket Support**: Backend supports WebSocket connections for real-time event streaming (notebook events, logs)
- **CA Certificate Loading**: Backend loads multiple CA bundles at startup for outbound HTTPS trust
- **Build System**: RHOAI builds use Dockerfile.konflux exclusively; regular Dockerfile may be outdated
- **Frontend Technology**: React 18 with PatternFly 5 components, Redux for state, Webpack 5 for bundling
- **Backend Technology**: Fastify 4 web framework, Kubernetes client-node for K8s API access, Pino for logging
- **Static Asset Serving**: Backend serves compiled frontend from `/usr/src/app/frontend/public`, fallback to `index.html` for SPA routing
- **Development Mode**: Supports local development with hot reload (frontend webpack-dev-server, backend nodemon)
- **Testing**: Comprehensive test suite including Jest unit tests, Cypress E2E tests, and Playwright tests
- **Accessibility**: Uses PatternFly's accessible components, Cypress axe testing for a11y validation
- **High Availability**: 2-replica deployment with pod anti-affinity across availability zones
- **Resource Management**: Defined CPU/memory requests and limits for predictable scheduling and resource usage
