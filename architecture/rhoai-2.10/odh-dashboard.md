# Component: ODH Dashboard

## Metadata
- **Repository**: https://github.com/red-hat-data-services/odh-dashboard.git
- **Version**: v1.21.0-18-rhods-1883-g20da6d655
- **Branch**: rhoai-2.10
- **Distribution**: RHOAI (also supports ODH)
- **Languages**: TypeScript, JavaScript (Node.js 18+), React
- **Deployment Type**: Web Application (Frontend + Backend Service)

## Purpose
**Short**: Web-based user interface and API gateway for Open Data Hub and Red Hat OpenShift AI platform management.

**Detailed**:

The ODH Dashboard is the primary user interface for the Open Data Hub and Red Hat OpenShift AI platforms. It provides a centralized web portal that enables data scientists and administrators to discover and access installed components, manage data science projects and workbenches, configure model serving deployments, and access component documentation.

The dashboard consists of a React-based frontend built with PatternFly UI components and a Node.js/Fastify backend that acts as an API gateway, proxying requests to the Kubernetes API server while enforcing authentication and authorization. It integrates deeply with OpenShift's OAuth infrastructure to provide seamless single sign-on, and exposes custom resources (CRDs) to allow operators and users to configure dashboard behavior, register applications, and define accelerator profiles for GPU/specialized hardware.

The component serves as the primary entry point for end users, offering guided quickstarts, project/namespace management, Jupyter notebook lifecycle management, model serving configuration, and monitoring capabilities through integration with Prometheus and other ODH platform components.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| Frontend | React/TypeScript SPA | User interface built with PatternFly, served as static assets |
| Backend | Node.js/Fastify API Server | REST API gateway, Kubernetes API proxy, static file server |
| OAuth Proxy | OpenShift OAuth Proxy | Authentication and authorization enforcement |
| CRD Controllers | Kubernetes Custom Resources | Dashboard configuration, application catalog, accelerator profiles |

## APIs Exposed

### Custom Resource Definitions (CRDs)

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| dashboard.opendatahub.io | v1 | AcceleratorProfile | Namespaced | Defines GPU/accelerator device configurations (tolerations, identifiers) for workload scheduling |
| dashboard.opendatahub.io | v1 | OdhApplication | Namespaced | Catalog entries for applications displayed in dashboard (Jupyter, model serving, etc.) |
| opendatahub.io | v1alpha | OdhDashboardConfig | Namespaced | Dashboard feature flags and configuration (enable/disable UI sections) |
| dashboard.opendatahub.io | v1 | OdhDocument | Namespaced | Documentation links and resources displayed in dashboard |
| console.openshift.io | v1 | OdhQuickStart | Namespaced | Interactive guided tutorials for dashboard features |

### HTTP Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| / | GET | 8443/TCP | HTTPS | TLS 1.2+ | OAuth | Frontend static assets (React app) |
| /api/health | GET | 8080/TCP | HTTP | None | None | Backend health check endpoint |
| /api/config | GET, PATCH | 8080/TCP | HTTP | None | Bearer Token | Dashboard runtime configuration |
| /api/dashboardConfig | GET, PATCH | 8080/TCP | HTTP | None | Bearer Token | OdhDashboardConfig CRUD operations |
| /api/accelerator-profiles | POST, PUT, DELETE | 8080/TCP | HTTP | None | Bearer Token | AcceleratorProfile management |
| /api/accelerators | GET | 8080/TCP | HTTP | None | Bearer Token | List available accelerator devices |
| /api/builds | GET | 8080/TCP | HTTP | None | Bearer Token | OpenShift Build/BuildConfig operations |
| /api/cluster-settings | GET, PUT | 8080/TCP | HTTP | None | Bearer Token | Cluster-wide settings (PVC sizes, culling) |
| /api/components | GET | 8080/TCP | HTTP | None | Bearer Token | List installed/available ODH components |
| /api/console-links | GET | 8080/TCP | HTTP | None | Bearer Token | OpenShift ConsoleLink resources |
| /api/docs | GET | 8080/TCP | HTTP | None | Bearer Token | OdhDocument resources |
| /api/dsc | GET | 8080/TCP | HTTP | None | Bearer Token | DataScienceCluster status |
| /api/dsci | GET | 8080/TCP | HTTP | None | Bearer Token | DSCInitialization status |
| /api/envs | GET | 8080/TCP | HTTP | None | Bearer Token | Environment variables for notebooks |
| /api/groups-config | GET, PUT | 8080/TCP | HTTP | None | Bearer Token | User group configuration |
| /api/images | GET, POST, PUT, DELETE | 8080/TCP | HTTP | None | Bearer Token | ImageStream management (notebook images) |
| /api/k8s/* | ALL | 8080/TCP | HTTP | None | Bearer Token | Kubernetes API pass-through proxy |
| /api/modelRegistries | POST, GET, PATCH, DELETE | 8080/TCP | HTTP | None | Bearer Token | ModelRegistry CR management |
| /api/namespaces | GET, POST, PATCH, DELETE | 8080/TCP | HTTP | None | Bearer Token | Namespace/project management |
| /api/nb-events/:namespace/:notebookName | GET | 8080/TCP | HTTP | None | Bearer Token | Notebook event stream |
| /api/notebooks | GET, POST, PATCH, DELETE | 8080/TCP | HTTP | None | Bearer Token | Kubeflow Notebook CR management |
| /api/prometheus/* | POST | 8080/TCP | HTTP | None | Bearer Token | Prometheus metrics query proxy |
| /api/quickstarts | GET | 8080/TCP | HTTP | None | Bearer Token | OdhQuickStart resources |
| /api/rolebindings | POST, DELETE | 8080/TCP | HTTP | None | Bearer Token | RoleBinding management for projects |
| /api/route | GET | 8080/TCP | HTTP | None | Bearer Token | OpenShift Route information |
| /api/servingRuntimes | POST | 8080/TCP | HTTP | None | Bearer Token | KServe ServingRuntime operations |
| /api/status | GET | 8080/TCP | HTTP | None | Bearer Token | Component installation status |
| /api/templates | GET, POST, PATCH, DELETE | 8080/TCP | HTTP | None | Bearer Token | OpenShift Template operations |
| /api/validate-isv | GET | 8080/TCP | HTTP | None | Bearer Token | ISV (Independent Software Vendor) validation |
| /oauth/healthz | GET | 8443/TCP | HTTPS | TLS 1.2+ | None | OAuth proxy health check |
| /metrics | GET | 8443/TCP | HTTPS | TLS 1.2+ | None | Prometheus metrics (no auth required) |

### WebSocket Endpoints

| Path | Port | Protocol | Encryption | Auth | Purpose |
|------|------|----------|------------|------|---------|
| /wss/k8s/* | 8080/TCP | WebSocket | None | Bearer Token | Kubernetes API watch/stream proxy |

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| OpenShift OAuth Server | 4.x | Yes | User authentication and authorization |
| Kubernetes API Server | 1.24+ | Yes | Cluster resource management |
| Node.js Runtime | 18+ | Yes | Backend application runtime |
| OpenShift Route/Ingress | 4.x | Yes | External HTTPS access to dashboard |
| Prometheus | 2.x | No | Metrics collection and querying |

### Internal ODH Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| DataScienceCluster | CRD Read | Determine installed ODH components and configuration |
| DSCInitialization | CRD Read | Check platform initialization status |
| Kubeflow Notebooks | CRD CRUD | Create and manage Jupyter notebook instances |
| KServe ServingRuntimes | CRD CRUD | Configure model serving runtimes |
| ModelRegistry | CRD CRUD | Manage model registry instances |
| Model Registry Service | HTTP API | Query registered models and metadata |
| Data Science Pipelines | HTTP API | Pipeline execution and monitoring |
| TrustyAI Service | HTTP API | Model bias/explainability metrics |

## Network Architecture

### Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| odh-dashboard | ClusterIP | 8443/TCP | 8443 | HTTPS | TLS 1.2+ | OAuth | Internal |

### Ingress

| Name | Type | Hosts | Port | Protocol | Encryption | TLS Mode | Exposure |
|------|------|-------|------|----------|------------|----------|----------|
| odh-dashboard | OpenShift Route | Dynamic (cluster domain) | 443/TCP | HTTPS | TLS 1.2+ | Reencrypt | External |

**Route Configuration:**
- Insecure traffic: Redirect to HTTPS
- TLS termination: Reencrypt (edge TLS + backend TLS)
- HSTS header: max-age=31536000;includeSubDomains;preload

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| kubernetes.default.svc | 443/TCP | HTTPS | TLS 1.2+ | Service Account Token | Kubernetes API operations |
| Prometheus Service | 9091/TCP | HTTP | None | Bearer Token | Metrics queries |
| Model Registry Service | Variable | HTTP/HTTPS | Variable | Bearer Token | Model metadata queries |
| Pipeline Service | Variable | HTTP/HTTPS | Variable | Bearer Token | Pipeline operations |
| TrustyAI Service | Variable | HTTP/HTTPS | Variable | Bearer Token | Bias metrics |

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

### RBAC - Roles (Namespaced)

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
| fetch-accelerators-role | dashboard.opendatahub.io | acceleratorprofiles | get, list, watch |
| servingruntimes-config-updater | template.openshift.io | templates | get, list |
| servingruntimes-config-updater | opendatahub.io | odhdashboardconfigs | get, list |

### RBAC - Role Bindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| odh-dashboard | Deployment namespace | odh-dashboard (Role) | odh-dashboard |
| odh-dashboard | Deployment namespace | odh-dashboard (ClusterRole) | odh-dashboard |
| odh-dashboard-auth-delegator | cluster-wide | system:auth-delegator (ClusterRole) | odh-dashboard |
| odh-dashboard-monitoring | cluster-wide | cluster-monitoring-view (ClusterRole) | odh-dashboard |
| accelerators | Deployment namespace | fetch-accelerators-role (Role) | system:authenticated (Group) |
| model-serving-role-binding | Deployment namespace | servingruntimes-config-updater (Role) | odh-dashboard |
| image-puller | cluster-wide | system:image-puller (ClusterRole) | odh-dashboard |

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| dashboard-proxy-tls | kubernetes.io/tls | OAuth proxy TLS certificate | service.alpha.openshift.io annotation | Yes |
| dashboard-oauth-config-generated | Opaque | OAuth proxy cookie secret | Operator/Manual | No |
| dashboard-oauth-client-generated | Opaque | OAuth client secret | Operator/Manual | No |
| dashboard-oauth-client | Opaque | OAuth client registration | OAuthClient CR | No |

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| /* (all paths) | ALL | OpenShift OAuth (cookie + token) | OAuth Proxy (port 8443) | User must have project list permission |
| /api/* | ALL | Bearer Token (JWT) | OAuth Proxy → Backend | Token passed from OAuth proxy, validated against Kubernetes API |
| /metrics | GET | None (unauthenticated) | OAuth Proxy | Explicitly excluded from auth (--skip-auth-regex) |
| /oauth/healthz | GET | None (unauthenticated) | OAuth Proxy | Health check endpoint |

**OAuth Delegation:**
- OAuth proxy validates: `{"resource": "projects", "verb": "list"}`
- User must have permission to list projects to access dashboard

## Data Flows

### Flow 1: User Authentication and Dashboard Access

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User Browser | OpenShift Route | 443/TCP | HTTPS | TLS 1.2+ | None |
| 2 | OpenShift Route | odh-dashboard Service | 8443/TCP | HTTPS | TLS 1.2+ (reencrypt) | None |
| 3 | Service | OAuth Proxy Container | 8443/TCP | HTTPS | TLS 1.2+ | None |
| 4 | OAuth Proxy | OpenShift OAuth Server | 443/TCP | HTTPS | TLS 1.2+ | Client Secret |
| 5 | OAuth Proxy | Backend Container | 8080/TCP | HTTP | None | Bearer Token (header injection) |
| 6 | Backend | User Browser | 8080→8443→443/TCP | HTTP→HTTPS | TLS 1.2+ (chain) | Session Cookie |

### Flow 2: Kubernetes API Operations

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User Browser | Backend (via OAuth proxy) | 8080/TCP | HTTP | None (internal) | Bearer Token |
| 2 | Backend | Kubernetes API Server | 443/TCP | HTTPS | TLS 1.2+ | Service Account Token |
| 3 | Kubernetes API | Backend | 443/TCP | HTTPS | TLS 1.2+ | N/A |
| 4 | Backend | User Browser (via OAuth proxy) | 8080→8443/TCP | HTTP→HTTPS | TLS 1.2+ | Bearer Token |

### Flow 3: Prometheus Metrics Query

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User Browser | Backend API (/api/prometheus/*) | 8080/TCP | HTTP | None (internal) | Bearer Token |
| 2 | Backend | Prometheus Service | 9091/TCP | HTTP | None | Bearer Token (user) |
| 3 | Prometheus | Backend | 9091/TCP | HTTP | None | N/A |
| 4 | Backend | User Browser | 8080/TCP | HTTP | None (internal) | Bearer Token |

### Flow 4: WebSocket Kubernetes Watch

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User Browser | Backend (/wss/k8s/*) | 8080/TCP | WebSocket | None (internal) | Bearer Token |
| 2 | Backend | Kubernetes API Server (watch) | 443/TCP | WebSocket/HTTPS | TLS 1.2+ | Service Account Token |
| 3 | Kubernetes API | Backend | 443/TCP | WebSocket/HTTPS | TLS 1.2+ | N/A |
| 4 | Backend | User Browser | 8080/TCP | WebSocket | None (internal) | Bearer Token |

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| Kubernetes API Server | REST API | 443/TCP | HTTPS | TLS 1.2+ | Resource CRUD operations, authentication delegation |
| OpenShift OAuth Server | OAuth 2.0 | 443/TCP | HTTPS | TLS 1.2+ | User authentication, token issuance |
| Prometheus | HTTP API | 9091/TCP | HTTP | None | Model serving metrics, workload metrics |
| Model Registry Service | HTTP API | Variable | HTTP/HTTPS | Variable | Model metadata queries |
| Data Science Pipelines API | HTTP API | Variable | HTTP/HTTPS | Variable | Pipeline creation, execution, monitoring |
| TrustyAI Service | HTTP API | Variable | HTTP/HTTPS | Variable | Bias metrics, model explainability |
| Kubeflow Notebook Controller | CRD Watch | N/A | N/A | N/A | Notebook lifecycle management |
| KServe Controller | CRD Watch | N/A | N/A | N/A | Model serving runtime management |

## Deployment Architecture

### Container Images

| Container | Base Image | Build Type | Purpose |
|-----------|------------|------------|---------|
| odh-dashboard | registry.access.redhat.com/ubi8/nodejs-18 | Multi-stage | Frontend (static) + Backend (Node.js) |
| oauth-proxy | registry.redhat.io/openshift4/ose-oauth-proxy | Pre-built | Authentication proxy |

### Pod Configuration

**Replicas:** 2 (with pod anti-affinity for zone distribution)

**Containers:**
1. **odh-dashboard**
   - Port: 8080/TCP
   - Resources: 500m-1000m CPU, 1Gi-2Gi memory
   - Probes: Liveness (TCP 8080), Readiness (HTTP /api/health)
   - Volume Mounts: CA certificates (odh-trusted-ca-bundle, odh-ca-bundle)

2. **oauth-proxy**
   - Port: 8443/TCP (HTTPS)
   - Resources: 500m-1000m CPU, 1Gi-2Gi memory
   - Probes: Liveness (HTTPS /oauth/healthz), Readiness (HTTPS /oauth/healthz)
   - Volume Mounts: TLS certificate, OAuth secrets, CA certificates

**Volumes:**
- dashboard-proxy-tls (Secret): TLS certificate for OAuth proxy
- dashboard-oauth-config-generated (Secret): Cookie secret
- dashboard-oauth-client-generated (Secret): OAuth client credentials
- odh-trusted-ca-bundle (ConfigMap, optional): Custom CA certificates
- odh-ca-bundle (ConfigMap, optional): ODH CA bundle

### Configuration

**Environment Variables (Backend):**
- PORT / BACKEND_PORT: 8080 (default)
- IP: 0.0.0.0 (default)
- NODE_ENV: production / development
- LOG_LEVEL: Configurable logging level
- METADATA_ENVOY_SERVICE_PORT: Model registry service port
- DS_PIPELINE_DSPA_SERVICE_PORT: Pipeline service port
- TRUSTYAI_TAIS_SERVICE_PORT: TrustyAI service port

**OAuth Proxy Arguments:**
- --https-address=:8443
- --provider=openshift
- --upstream=http://localhost:8080
- --client-id=dashboard-oauth-client
- --scope=user:full
- --cookie-expire=23h0m0s
- --pass-access-token
- --openshift-delegate-urls={"/": {"resource": "projects", "verb": "list"}}
- --skip-auth-regex=^/metrics

## Custom Resource Examples

### AcceleratorProfile Example
```yaml
apiVersion: dashboard.opendatahub.io/v1
kind: AcceleratorProfile
metadata:
  name: nvidia-gpu
spec:
  displayName: "NVIDIA GPU"
  enabled: true
  identifier: "nvidia.com/gpu"
  description: "NVIDIA GPU accelerator"
  tolerations:
    - key: "nvidia.com/gpu"
      operator: "Exists"
      effect: "NoSchedule"
```

### OdhDashboardConfig Example
```yaml
apiVersion: opendatahub.io/v1alpha
kind: OdhDashboardConfig
metadata:
  name: odh-dashboard-config
spec:
  dashboardConfig:
    enablement: true
    disableInfo: false
    disableSupport: false
    disableClusterManager: false
    disableTracking: true
    disableBYONImageStream: false
    disableISVBadges: false
    disableUserManagement: false
    disableHome: false
    disableProjects: false
    disableModelServing: false
    disableProjectSharing: false
    disableCustomServingRuntimes: false
    disablePipelines: false
    disableKServe: false
```

## Monitoring and Observability

### Metrics Exposed

| Metric Endpoint | Port | Format | Purpose |
|-----------------|------|--------|---------|
| /metrics | 8443/TCP | Prometheus | Application metrics (via prom-client library) |

**ServiceMonitor:**
The dashboard can be monitored by Prometheus through the `/metrics` endpoint (unauthenticated for scraping).

### Health Checks

| Endpoint | Type | Port | Success Criteria |
|----------|------|------|------------------|
| /api/health | HTTP GET | 8080/TCP | HTTP 200 response |
| /oauth/healthz | HTTP GET | 8443/TCP | HTTP 200 response |

### Logging

- **Format:** JSON (production), Pretty (development)
- **Library:** Pino
- **Redaction:** Authorization headers automatically redacted
- **Level:** Configurable via LOG_LEVEL environment variable
- **Output:** stdout/stderr

## Deployment Variants

### Overlays

| Overlay | Purpose | Key Changes |
|---------|---------|-------------|
| base | Standard ODH deployment | Default labels (app: odh-dashboard) |
| rhoai | RHOAI-specific deployment | Labels changed to rhods-dashboard, additional anaconda-ce validator cron |
| dev | Development deployment | CRDs + base resources + apps |
| odhdashboardconfig | Base + default OdhDashboardConfig | Includes default configuration CR |
| incubation | Feature preview deployment | Modified deployment settings |
| performance | Performance-tuned deployment | Adjusted resource limits/requests |
| consolelink | Console link only | OpenShift console integration |
| apps/* | Application catalog variants | Different sets of OdhApplication CRs (ODH vs RHOAI) |

## Known Limitations

1. **Authentication:** Requires OpenShift OAuth server; not compatible with vanilla Kubernetes
2. **Single Sign-On:** Cookie-based sessions expire after 23 hours
3. **API Gateway:** Backend acts as proxy but does not implement full API gateway features (rate limiting, circuit breaking)
4. **High Availability:** Requires shared session state for true HA; currently uses client-side cookies
5. **TLS:** Internal communication between OAuth proxy and backend is unencrypted (localhost only)

## Recent Changes

**Note:** No recent commits found in the last 3 months for branch rhoai-2.10 (likely a stable release branch).

This is a stable release branch for RHOAI 2.10. Active development occurs on the main/development branches.

## Build Process

### Multi-stage Dockerfile

1. **Builder Stage:**
   - Base: ubi8/nodejs-18
   - Install dependencies: `npm ci --omit=optional`
   - Build frontend and backend: `npm run build`
   - Output: Compiled frontend (static files) + transpiled backend (JavaScript)

2. **Runtime Stage:**
   - Base: ubi8/nodejs-18
   - Copy built artifacts: frontend/public, backend/dist, backend/package*.json
   - Install production dependencies: `npm ci --omit=dev --omit=optional`
   - Create logs directory with proper permissions
   - CMD: `npm run start` (executes backend/dist/server.js)

### Image Labels
- io.opendatahub.component="odh-dashboard"
- io.k8s.display-name="odh-dashboard"
- name="open-data-hub/odh-dashboard-ubi8"

## Security Considerations

### Trust Boundaries

1. **External → Route:** Public internet to OpenShift ingress (TLS encrypted)
2. **Route → OAuth Proxy:** Internal cluster network (TLS reencrypt)
3. **OAuth Proxy → Backend:** Pod-local (localhost, unencrypted HTTP)
4. **Backend → Kubernetes API:** Internal cluster network (TLS encrypted, service account token)

### Security Best Practices Implemented

- ✅ TLS encryption for external access
- ✅ OAuth authentication enforcement
- ✅ Authorization delegation to Kubernetes RBAC
- ✅ Service account token rotation
- ✅ Automatic TLS certificate generation (service serving certs)
- ✅ HSTS headers enforced
- ✅ Insecure traffic redirected to HTTPS
- ✅ Authorization header redaction in logs
- ✅ Principle of least privilege (granular RBAC)
- ✅ Non-root container execution
- ✅ Read-only root filesystem (where possible)

### Security Considerations

- ⚠️ Backend-to-OAuth-proxy communication is unencrypted (mitigated by localhost-only binding)
- ⚠️ OAuth client secret rotation requires manual intervention
- ⚠️ Cookie secret rotation requires pod restart
- ⚠️ Broad RBAC permissions required for full functionality (namespace creation, RBAC management)

## Configuration Management

### ConfigMaps

| Name | Purpose | Managed By |
|------|---------|------------|
| odh-trusted-ca-bundle | Custom CA certificates | Administrator |
| odh-dashboard-image-parameters | Image references for deployment | Kustomize configMapGenerator |

### Secrets Management

All secrets should be managed through:
1. OpenShift service serving cert controller (TLS certs)
2. OAuthClient CR (client registration)
3. Manual/operator creation (OAuth secrets)

**Rotation Policy:**
- TLS certificates: Auto-rotated by OpenShift (30 days before expiry)
- OAuth tokens: Rotated per session (23h expiry)
- OAuth secrets: Manual rotation required

## Testing

### Frontend Testing
- **Framework:** Jest, Cypress
- **Coverage:** Unit tests, integration tests, E2E tests
- **Location:** frontend/src/__tests__/

### Backend Testing
- **Framework:** Jest
- **Coverage:** Unit tests, API integration tests
- **Location:** backend/src/__tests__/

### Test Commands
- `npm run test` - Run all tests
- `npm run test:frontend:coverage` - Frontend with coverage
- `npm run test:cypress-ci` - E2E tests (mock mode)

## Development

### Local Development

```bash
# Install dependencies
npm install

# Start development mode (concurrent frontend + backend)
npm run dev

# Frontend: http://localhost:3000 (webpack-dev-server)
# Backend: http://localhost:8080 (nodemon with hot reload)
```

### Environment Variables

Development mode requires:
- `NODE_TLS_REJECT_UNAUTHORIZED=0` - Accept self-signed certs
- `NODE_ENV=development` - Enable dev features
- Kubernetes config in `~/.kube/config` - For API access

### Building

```bash
# Build both frontend and backend
npm run build

# Or individually
npm run build:frontend
npm run build:backend
```

## Future Enhancements

Potential improvements based on architecture analysis:

1. **Encryption:** Add TLS for OAuth proxy → Backend communication
2. **Caching:** Implement Redis for distributed session storage (true HA)
3. **API Gateway:** Add rate limiting, request validation, circuit breaking
4. **Observability:** Enhanced tracing with OpenTelemetry
5. **Security:** Implement automatic OAuth secret rotation
6. **Performance:** Server-side caching of frequently accessed resources
7. **Multi-tenancy:** Enhanced isolation between user projects/namespaces
