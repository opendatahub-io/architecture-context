# Component: ODH Dashboard

## Metadata
- **Repository**: https://github.com/red-hat-data-services/odh-dashboard.git
- **Version**: 1.21.0-18-rhods-5081-gba65f51d1
- **Branch**: rhoai-3.3
- **Distribution**: Both ODH and RHOAI (with variants: addon, onprem, modular-architecture)
- **Languages**: TypeScript, JavaScript, Node.js 22
- **Deployment Type**: Web Application (Frontend + Backend Service)
- **Build System**: Konflux (Dockerfile.konflux variants for different deployments)

## Purpose
**Short**: Web-based user interface for managing Open Data Hub and Red Hat OpenShift AI components, projects, and workloads.

**Detailed**:
The ODH Dashboard is the primary web interface for Open Data Hub and Red Hat OpenShift AI. It provides a unified user experience for data scientists and administrators to interact with the platform's various components including Jupyter notebooks, model serving (KServe), data science pipelines, model registry, distributed workloads, and GenAI capabilities. The dashboard manages user authentication via OpenShift OAuth, orchestrates Kubernetes resources through its backend API, and offers a modular architecture that supports federated micro-frontends for specialized features like Model Registry, GenAI, and Model-as-a-Service (MaaS). It serves as the control plane UI, enabling users to create and manage data science projects, deploy models, configure storage, manage connections, and monitor workloads.

The dashboard supports feature flags through OdhDashboardConfig CRD for enabling/disabling capabilities, manages quickstart tutorials for onboarding, and provides integration points with external components through custom resource definitions and REST APIs. In RHOAI deployments, it supports both managed (addon) and self-managed (onprem) configurations with appropriate branding and support links.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| Frontend | React 18 + TypeScript SPA | User interface built with PatternFly 6, supports module federation for micro-frontends |
| Backend | Node.js/Fastify API Server | REST API proxy to Kubernetes, authentication handling, WebSocket support for streaming |
| kube-rbac-proxy | Sidecar Proxy | OAuth authentication enforcement, TLS termination, request authorization |
| model-registry-ui | Federated Micro-frontend | Model registry management interface (modular architecture only) |
| gen-ai-ui | Federated Micro-frontend | Generative AI features interface (modular architecture only) |
| maas-ui | Federated Micro-frontend | Model-as-a-Service interface (modular architecture only) |

## APIs Exposed

### Custom Resource Definitions (CRDs)

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| dashboard.opendatahub.io | v1 | OdhApplication | Namespaced | Defines ODH applications that appear in the dashboard with metadata, enablement configuration, and documentation links |
| opendatahub.io | v1alpha | OdhDashboardConfig | Namespaced | Configuration for dashboard feature flags and capabilities (unmanaged resource - changes persist after operator updates) |
| dashboard.opendatahub.io | v1 | OdhDocument | Namespaced | Documentation resources displayed in dashboard including tutorials, how-tos, and quickstarts |
| console.openshift.io | v1 | OdhQuickStart | Namespaced | Interactive guided tutorials for dashboard workflows with step-by-step instructions |

### HTTP Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /api/health | GET | 8080/TCP | HTTP | None | None | Backend health check endpoint for readiness probe |
| /api/config | GET, PATCH | 8080/TCP | HTTP | None | Service Account Token | Dashboard configuration management |
| /api/dashboardConfig | GET, PATCH | 8080/TCP | HTTP | None | Service Account Token | OdhDashboardConfig CRD operations |
| /api/cluster-settings | GET, PUT | 8080/TCP | HTTP | None | Service Account Token | Cluster-wide settings (PVC size, culling, etc.) |
| /api/status | GET | 8080/TCP | HTTP | None | Service Account Token | Component and operator status |
| /api/dsc | GET | 8080/TCP | HTTP | None | Service Account Token | DataScienceCluster status |
| /api/dsci | GET | 8080/TCP | HTTP | None | Service Account Token | DSCInitialization status |
| /api/namespaces | GET | 8080/TCP | HTTP | None | Service Account Token | List available namespaces |
| /api/notebooks | GET, POST, PATCH | 8080/TCP | HTTP | None | Service Account Token | Jupyter notebook management |
| /api/components | GET | 8080/TCP | HTTP | None | Service Account Token | ODH component list and status |
| /api/docs | GET | 8080/TCP | HTTP | None | Service Account Token | OdhDocument resources |
| /api/quickstarts | GET | 8080/TCP | HTTP | None | Service Account Token | OdhQuickStart resources |
| /api/builds | GET | 8080/TCP | HTTP | None | Service Account Token | Build and BuildConfig status |
| /api/connection-types | GET, POST, PUT, PATCH, DELETE | 8080/TCP | HTTP | None | Service Account Token | Connection type management |
| /api/templates | GET, POST, PATCH, DELETE | 8080/TCP | HTTP | None | Service Account Token | OpenShift template management |
| /api/servingRuntimes | POST | 8080/TCP | HTTP | None | Service Account Token | Model serving runtime creation |
| /api/modelRegistries | GET, POST, PATCH, DELETE | 8080/TCP | HTTP | None | Service Account Token | Model registry management |
| /api/modelRegistryRoleBindings | GET, POST, DELETE | 8080/TCP | HTTP | None | Service Account Token | Model registry RBAC management |
| /api/rolebindings | GET, POST | 8080/TCP | HTTP | None | Service Account Token | Project role binding management |
| /api/prometheus | POST | 8080/TCP | HTTP | None | Service Account Token | Prometheus query proxy |
| /api/featurestores | GET, POST, PATCH, DELETE | 8080/TCP | HTTP | None | Service Account Token | Feature store (Feast) management |
| /api/nim-serving | GET | 8080/TCP | HTTP | None | Service Account Token | NVIDIA NIM model serving |
| /api/integrations/nim | GET, POST, PATCH, DELETE | 8080/TCP | HTTP | None | Service Account Token | NIM account integration |
| /api/k8s/* | GET | 8080/TCP | HTTP | None | Service Account Token | Generic Kubernetes resource proxy |
| /api/validate-isv | GET | 8080/TCP | HTTP | None | Service Account Token | ISV badge validation |
| /api/segment-key | GET | 8080/TCP | HTTP | None | Service Account Token | Analytics segment key |
| / | GET | 8443/TCP | HTTPS | TLS 1.2+ | OAuth Bearer Token | Dashboard web UI (proxied through kube-rbac-proxy) |
| /healthz | GET | 8444/TCP | HTTPS | TLS 1.2+ | None | kube-rbac-proxy health endpoint |
| /_mf/* | GET | 8080/TCP | HTTP | None | Service Account Token | Module federation remote entry points |
| /model-registry/* | * | 8043/TCP | HTTPS | TLS 1.2+ | OAuth Bearer Token (x-forwarded-access-token) | Model registry UI (modular architecture) |
| /gen-ai/* | * | 8143/TCP | HTTPS | TLS 1.2+ | OAuth Bearer Token (x-forwarded-access-token) | GenAI UI (modular architecture) |
| /maas/* | * | 8243/TCP | HTTPS | TLS 1.2+ | OAuth Bearer Token (x-forwarded-access-token) | MaaS UI (modular architecture) |

### WebSocket Endpoints

| Path | Port | Protocol | Encryption | Auth | Purpose |
|------|------|----------|------------|------|---------|
| /wss/k8s/* | 8080/TCP | WebSocket (ws://) | None | Service Account Token | Kubernetes API watch streams for real-time resource updates |

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| Node.js | >=22.0.0 | Yes | Runtime environment for frontend build and backend service |
| Kubernetes | 1.25+ | Yes | Container orchestration platform |
| OpenShift | 4.12+ | Yes | OAuth authentication, Routes, ConsoleLinks |
| kube-rbac-proxy | Latest | Yes | Authentication/authorization sidecar proxy |
| React | ^18.2.0 | Yes | Frontend UI framework |
| PatternFly | ^6.4.0 | Yes | UI component library |
| Fastify | ^4.28.1 | Yes | Backend web framework |
| @kubernetes/client-node | ^0.12.2 | Yes | Kubernetes API client library |

### Internal ODH Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| odh-operator / rhods-operator | CRD Watch (DataScienceCluster, DSCInitialization) | Monitor operator status and component enablement |
| kubeflow/notebooks | CRD Management (Notebook) | Create and manage Jupyter notebook instances |
| kserve | CRD Watch (InferenceService, ServingRuntime) | Model serving management and monitoring |
| odh-model-controller | CRD Management (ModelRegistry) | Model registry instance management |
| data-science-pipelines-operator | API Integration | Pipeline management (if enabled) |
| feast-operator | CRD Watch (FeatureStore) | Feature store management |
| ray-operator | CRD Watch | Distributed workload management |
| nvidia-nim | CRD Management (Account) | NVIDIA NIM integration for model serving |
| Prometheus | HTTP API | Metrics queries for performance monitoring |

## Network Architecture

### Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| odh-dashboard | ClusterIP | 8443/TCP | 8443 | HTTPS | TLS (service-serving-cert) | OAuth via kube-rbac-proxy | Internal |
| odh-dashboard (backend) | - | 8080/TCP | 8080 | HTTP | None (internal only) | None (proxied by kube-rbac-proxy) | Internal (not exposed) |
| odh-dashboard (proxy-health) | - | 8444/TCP | 8444 | HTTPS | TLS | None | Internal (health check only) |
| odh-dashboard (model-registry-ui) | - | 8043/TCP | 8043 | HTTPS | TLS (service-serving-cert) | OAuth via token forwarding | Internal (modular arch) |
| odh-dashboard (gen-ai-ui) | - | 8143/TCP | 8143 | HTTPS | TLS (service-serving-cert) | OAuth via token forwarding | Internal (modular arch) |
| odh-dashboard (maas-ui) | - | 8243/TCP | 8243 | HTTPS | TLS (service-serving-cert) | OAuth via token forwarding | Internal (modular arch) |

### Ingress

| Name | Type | Hosts | Port | Protocol | Encryption | TLS Mode | Exposure |
|------|------|-------|------|----------|------------|----------|----------|
| odh-dashboard | OpenShift Route | Cluster-assigned | 8443/TCP | HTTPS | TLS 1.2+ | Reencrypt (edge + backend TLS) | External |
| odh-dashboard | HTTPRoute (Gateway API) | Cluster-assigned via Gateway | 8443/TCP | HTTPS | TLS 1.2+ | TLS termination at Gateway | External |

**Route Configuration**:
- TLS termination: reencrypt (TLS at both edge and backend)
- Insecure traffic: Redirect to HTTPS
- HSTS header: max-age=31536000;includeSubDomains;preload
- Backend service: odh-dashboard:8443

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| kubernetes.default.svc | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token | Kubernetes API server for resource management |
| prometheus-k8s.openshift-monitoring.svc | 9091/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token | Metrics queries for performance monitoring |
| External OAuth Provider | 443/TCP | HTTPS | TLS 1.2+ | OAuth flow | User authentication (OpenShift OAuth) |
| External Image Registries | 443/TCP | HTTPS | TLS 1.2+ | Image pull secrets | Container image pulls for notebook and serving images |
| Model Registry Service | Varies | HTTP/HTTPS | TLS if available | ServiceAccount Token | Model registry backend API |
| S3-compatible Storage | 443/TCP | HTTPS | TLS 1.2+ | AWS credentials | Object storage for models and data |

## Security

### RBAC - Cluster Roles

| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|
| odh-dashboard | "" (core) | nodes | get, list |
| odh-dashboard | "" (core) | configmaps, persistentvolumeclaims, secrets | create, delete, get, list, patch, update, watch |
| odh-dashboard | "" (core) | pods, serviceaccounts, services | get, list, watch |
| odh-dashboard | "" (core) | namespaces | patch |
| odh-dashboard | "" (core) | endpoints | get |
| odh-dashboard | storage.k8s.io | storageclasses | update, patch |
| odh-dashboard | machine.openshift.io, autoscaling.openshift.io | machineautoscalers, machinesets | get, list |
| odh-dashboard | config.openshift.io | clusterversions, ingresses | get, watch, list |
| odh-dashboard | operators.coreos.com | clusterserviceversions, subscriptions | get, list, watch |
| odh-dashboard | image.openshift.io | imagestreams/layers | get |
| odh-dashboard | route.openshift.io | routes | get, list, watch |
| odh-dashboard | console.openshift.io | consolelinks | get, list, watch |
| odh-dashboard | operator.openshift.io | consoles | get, list, watch |
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
| aggregate-hardware-profiles-permissions | infrastructure.opendatahub.io | hardwareprofiles | get, list, watch |

### RBAC - Role Bindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| odh-dashboard | Dashboard namespace | odh-dashboard (Role) | odh-dashboard |
| odh-dashboard | Dashboard namespace | odh-dashboard (ClusterRole) | odh-dashboard |
| odh-dashboard-auth-delegator | kube-system | system:auth-delegator (ClusterRole) | odh-dashboard |
| cluster-monitoring-view | Dashboard namespace | cluster-monitoring-view (ClusterRole) | odh-dashboard |
| odh-dashboard-image-puller | Dashboard namespace | system:image-puller (ClusterRole) | odh-dashboard |
| servingruntimes-config-updater | Dashboard namespace | servingruntimes-config-updater (Role) | odh-dashboard |

### RBAC - Namespace Roles

| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|
| odh-dashboard | dashboard.opendatahub.io | acceleratorprofiles | create, get, list, update, patch, delete |
| odh-dashboard | route.openshift.io | routes | get, list, watch |
| odh-dashboard | batch | cronjobs | get, update, delete |
| odh-dashboard | image.openshift.io | imagestreams | create, get, list, update, patch, delete |
| odh-dashboard | build.openshift.io | builds, buildconfigs | list |
| odh-dashboard | apps | deployments | patch, update |
| odh-dashboard | apps.openshift.io | deploymentconfigs, deploymentconfigs/instantiate | get, list, watch, create, update, patch, delete |
| odh-dashboard | opendatahub.io | odhdashboardconfigs | get, list, watch, create, update, patch, delete |
| odh-dashboard | kubeflow.org | notebooks | get, list, watch, create, update, patch, delete |
| odh-dashboard | dashboard.opendatahub.io | odhapplications, odhdocuments | get, list |
| odh-dashboard | console.openshift.io | odhquickstarts | get, list |
| odh-dashboard | template.openshift.io | templates | * (all verbs) |
| odh-dashboard | serving.kserve.io | servingruntimes | * (all verbs) |
| odh-dashboard | nim.opendatahub.io | accounts | get, list, watch, create, update, patch, delete |
| servingruntimes-config-updater | template.openshift.io | templates | get, list |
| servingruntimes-config-updater | opendatahub.io | odhdashboardconfigs | get, list |

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| dashboard-proxy-tls | kubernetes.io/tls | TLS certificates for kube-rbac-proxy and service | service.beta.openshift.io/serving-cert-secret-name annotation | Yes (OpenShift service CA) |

### ConfigMaps

| ConfigMap Name | Purpose | Managed By |
|----------------|---------|------------|
| odh-trusted-ca-bundle | Custom CA certificates for trusting external services | Cluster administrator |
| kube-rbac-proxy-config | kube-rbac-proxy authorization configuration | Dashboard manifests (fully managed) |
| federation-config | Module federation remote entry configuration (modular arch) | Dashboard manifests (fully managed) |

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| /* (Dashboard UI) | GET, POST, PUT, DELETE | OAuth Bearer Token (OpenShift) | kube-rbac-proxy | SubjectAccessReview delegation to Kubernetes RBAC |
| /api/* (Backend APIs) | GET, POST, PUT, DELETE, PATCH | ServiceAccount Token (impersonation) | Backend validation | Kubernetes RBAC via impersonation headers |
| /wss/k8s/* (WebSocket) | WebSocket Upgrade | ServiceAccount Token | Backend validation | Kubernetes RBAC via impersonation |
| /healthz (Proxy health) | GET | None | None | Public endpoint for probe |
| /api/health (Backend health) | GET | None | None | Public endpoint for probe |
| /model-registry/* | * | OAuth Bearer Token via x-forwarded-access-token | model-registry-ui container | Token forwarding to backend |
| /gen-ai/* | * | OAuth Bearer Token via x-forwarded-access-token | gen-ai-ui container | Token forwarding to backend |
| /maas/* | * | OAuth Bearer Token via x-forwarded-access-token | maas-ui container | Token forwarding to backend |

### Network Policies

| Policy Name | Pod Selector | Policy Type | Allowed Sources | Allowed Ports |
|-------------|--------------|-------------|-----------------|---------------|
| odh-dashboard-allow-ports | deployment=odh-dashboard | Ingress | All (empty from clause) | 8443/TCP, 8043/TCP, 8143/TCP, 8243/TCP |

**Note**: The network policy allows ingress from all sources to the specified ports. Additional network restrictions may be enforced at the cluster level via OpenShift SDN or other CNI plugins.

## Data Flows

### Flow 1: User Authentication and Dashboard Access

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User Browser | OpenShift Router | 443/TCP | HTTPS | TLS 1.2+ | None (initial request) |
| 2 | OpenShift Router | odh-dashboard Service | 8443/TCP | HTTPS | TLS (reencrypt) | None (routing) |
| 3 | kube-rbac-proxy | OpenShift OAuth Server | 443/TCP | HTTPS | TLS 1.2+ | OAuth redirect |
| 4 | User Browser | OpenShift OAuth Server | 443/TCP | HTTPS | TLS 1.2+ | User credentials |
| 5 | OpenShift OAuth Server | User Browser | 443/TCP | HTTPS | TLS 1.2+ | OAuth token (redirect) |
| 6 | User Browser | odh-dashboard (kube-rbac-proxy) | 8443/TCP | HTTPS | TLS 1.2+ | Bearer Token (OAuth) |
| 7 | kube-rbac-proxy | Kubernetes API Server | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token (TokenReview) |
| 8 | kube-rbac-proxy | Backend (odh-dashboard) | 8080/TCP | HTTP | None (localhost) | Impersonation headers |
| 9 | Backend | User Browser | 8080/TCP → 8443/TCP | HTTP → HTTPS | TLS 1.2+ (at proxy) | Bearer Token |

### Flow 2: Notebook Creation

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User Browser (Dashboard UI) | odh-dashboard Service | 8443/TCP | HTTPS | TLS 1.2+ | Bearer Token (OAuth) |
| 2 | kube-rbac-proxy | Backend | 8080/TCP | HTTP | None (localhost) | Impersonation headers (X-Auth-Request-User) |
| 3 | Backend | Kubernetes API Server | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token + Impersonation |
| 4 | Backend | Kubernetes API Server (POST Notebook) | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token + Impersonation |
| 5 | Backend | User Browser | 8080/TCP → 8443/TCP | HTTP → HTTPS | TLS 1.2+ | Bearer Token |

### Flow 3: WebSocket Resource Watch

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User Browser (Dashboard UI) | odh-dashboard Service | 8443/TCP | WebSocket (wss://) | TLS 1.2+ | Bearer Token (OAuth) |
| 2 | kube-rbac-proxy | Backend /wss/k8s/* | 8080/TCP | WebSocket (ws://) | None (localhost) | Impersonation headers |
| 3 | Backend | Kubernetes API Server (watch) | 443/TCP | WebSocket (wss://) | TLS 1.2+ | ServiceAccount Token + Impersonation |
| 4 | Kubernetes API Server | Backend | 443/TCP | WebSocket (wss://) | TLS 1.2+ | Resource updates (streaming) |
| 5 | Backend | User Browser | 8080/TCP → 8443/TCP | WebSocket (wss://) | TLS 1.2+ | Resource updates (streaming) |

### Flow 4: Model Registry UI Access (Modular Architecture)

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User Browser | odh-dashboard Service | 8443/TCP | HTTPS | TLS 1.2+ | Bearer Token (OAuth) |
| 2 | Backend (module federation proxy) | model-registry-ui container | 8043/TCP | HTTPS | TLS (internal) | x-forwarded-access-token header |
| 3 | model-registry-ui | Model Registry Backend | Varies | HTTP/HTTPS | TLS if available | User token from header |
| 4 | model-registry-ui | User Browser | 8043/TCP → 8443/TCP | HTTPS | TLS 1.2+ | Bearer Token |

### Flow 5: Prometheus Metrics Query

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User Browser (Dashboard UI) | odh-dashboard Service | 8443/TCP | HTTPS | TLS 1.2+ | Bearer Token (OAuth) |
| 2 | Backend /api/prometheus | Prometheus Service | 9091/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 3 | Prometheus | Backend | 9091/TCP | HTTPS | TLS 1.2+ | Query results |
| 4 | Backend | User Browser | 8080/TCP → 8443/TCP | HTTP → HTTPS | TLS 1.2+ | Query results (JSON) |

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| Kubernetes API Server | REST API | 443/TCP | HTTPS | TLS 1.2+ | Resource CRUD operations, authentication, authorization |
| Kubernetes API Server | WebSocket | 443/TCP | WSS | TLS 1.2+ | Real-time resource watch streams |
| OpenShift OAuth Server | OAuth 2.0 | 443/TCP | HTTPS | TLS 1.2+ | User authentication and token issuance |
| Prometheus | REST API | 9091/TCP | HTTPS | TLS 1.2+ | Metrics queries for performance dashboards |
| Model Registry Backend | REST API | Varies | HTTP/HTTPS | TLS if available | Model metadata and artifact management |
| KServe Controller | CRD Watch | 443/TCP | HTTPS | TLS 1.2+ | InferenceService and ServingRuntime monitoring |
| Kubeflow Notebook Controller | CRD Management | 443/TCP | HTTPS | TLS 1.2+ | Notebook lifecycle management |
| ODH/RHODS Operator | CRD Watch | 443/TCP | HTTPS | TLS 1.2+ | Component status and configuration |
| Feast Operator | CRD Watch | 443/TCP | HTTPS | TLS 1.2+ | Feature store monitoring |
| External S3 Storage | S3 API | 443/TCP | HTTPS | TLS 1.2+ | Object storage for models and data |

## Deployment Configurations

### Standard Deployment (ODH/RHOAI)

**Containers**:
1. **odh-dashboard**: Main application container (frontend + backend)
2. **kube-rbac-proxy**: Authentication/authorization sidecar

**Resources**:
- odh-dashboard: 500m-1000m CPU, 1-2Gi memory
- kube-rbac-proxy: 500m-1000m CPU, 1-2Gi memory

**Replicas**: 2 (with pod anti-affinity across zones)

### Modular Architecture Deployment

**Additional Containers** (alongside standard):
3. **model-registry-ui**: Model registry micro-frontend (port 8043)
4. **gen-ai-ui**: GenAI features micro-frontend (port 8143)
5. **maas-ui**: Model-as-a-Service micro-frontend (port 8243)

**Resources** (per additional container):
- 500m CPU, 1Gi memory

**Module Federation**: Configured via `federation-config` ConfigMap with remote entry points and proxy paths.

## Recent Changes

| Commit | Date | Changes |
|--------|------|---------|
| ba65f51d1 | 2026-03 | chore(deps): update registry.access.redhat.com/ubi9/nodejs-22 docker digest to 172cdb4 |
| 4a232fc5e | 2026-03 | chore(deps): update registry.access.redhat.com/ubi9-minimal docker digest to 69f5c98 |
| 45be8dc3e | 2026-03 | chore(deps): update registry.access.redhat.com/ubi9/nodejs-22 docker digest to 110352e |
| e5db517d6 | 2026-02 | chore(deps): update registry.access.redhat.com/ubi9/nodejs-22 docker digest to 9019f9e |
| 7c64599bb | 2026-02 | sync pipelineruns with konflux-central - 9fd8f6f |
| a51bb4aa2 | 2026-02 | chore(deps): update registry.access.redhat.com/ubi9/nodejs-22 docker digest to c22b81d |
| 6a8ef270e | 2026-02 | chore(deps): update registry.access.redhat.com/ubi9/nodejs-22 docker digest to 04e9f30 |
| fe48004bc | 2026-02 | sync pipelineruns with konflux-central - 23bd5cc |

**Note**: Recent commits primarily focus on base image updates (UBI9/Node.js 22) and Konflux pipeline synchronization for secure build processes.

## Build and Release

### Container Images

**Main Image**: Built via `Dockerfile.konflux`
- Base: registry.access.redhat.com/ubi9/nodejs-22
- Multi-stage build: builder (npm ci + build) → runtime (production artifacts only)
- Branding: RHOAI logo and links configured at build time
- Runs as user 1001:0 (non-root)

**Modular Architecture Variants**:
- `Dockerfile.konflux.genai`: GenAI micro-frontend
- `Dockerfile.konflux.maas`: MaaS micro-frontend
- `Dockerfile.konflux.modelregistry`: Model Registry micro-frontend
- `Dockerfile.konflux.sealights`: Testing/coverage variant

### Build Process

1. **Install dependencies**: `npm ci --ignore-scripts`
2. **Build frontend**: webpack production build with module federation support
3. **Build backend**: TypeScript compilation to JavaScript
4. **Prune dev dependencies**: `npm prune --omit=dev`
5. **Copy artifacts**: Frontend public/ + backend dist/ to runtime image
6. **Set branding**: Environment variables for RHOAI product name and links

### Release Pipeline

- **CI/CD**: Konflux (Tekton pipelines in `.tekton/`)
- **Variants**:
  - `odh-dashboard-pull-request.yaml`: PR validation
  - `odh-dashboard-v3-3-push.yaml`: RHOAI 3.3 branch builds
  - Modular architecture pipelines for micro-frontends
- **Validation**: Automated kustomize validation, unit tests, Cypress e2e tests
- **Security**: Image scanning, vulnerability checks, SBOM generation

## Observability

### Health Endpoints

- **Backend**: `/api/health` (HTTP 8080) - Readiness probe
- **Proxy**: `/healthz` (HTTPS 8444) - Liveness and readiness probes

### Probes

**Backend Container**:
- Liveness: TCP socket on 8080, 30s initial delay, 30s period
- Readiness: HTTP GET /api/health on 8080, 30s initial delay, 30s period

**kube-rbac-proxy Container**:
- Liveness: HTTPS GET /healthz on 8444, 30s initial delay, 5s period
- Readiness: HTTPS GET /healthz on 8444, 5s initial delay, 5s period

**Modular Architecture Containers**:
- Liveness: HTTPS GET /healthcheck on respective ports, 30s initial delay
- Readiness: HTTPS GET /healthcheck on respective ports, 15s initial delay

### Logging

- **Format**: JSON (pino logger for backend)
- **Location**: `/usr/src/app/logs/` (backend), stdout/stderr
- **Admin Activity**: Special log file for admin actions (`adminActivity.log`)

### Metrics

- Backend exposes Prometheus metrics via `prom-client`
- Queries Prometheus for user-facing performance metrics
- Monitored by OpenShift cluster monitoring (via `cluster-monitoring-view` role)

## Security Considerations

### Threat Model

1. **Authentication Bypass**: Mitigated by kube-rbac-proxy OAuth enforcement and ServiceAccount token validation
2. **Privilege Escalation**: Mitigated by least-privilege RBAC policies and user impersonation
3. **MITM Attacks**: Mitigated by TLS everywhere (reencrypt route, service-serving-cert)
4. **CSRF**: Mitigated by OAuth token requirements and SameSite cookie policies
5. **XSS**: Frontend uses DOMPurify for sanitization, Content Security Policy headers

### Compliance

- **TLS**: Minimum TLS 1.2, prefers TLS 1.3
- **HSTS**: Enforced via route annotation (max-age=31536000;includeSubDomains;preload)
- **Non-root**: All containers run as non-root users (UID 1001)
- **Capabilities**: DROP ALL in modular architecture containers
- **Privilege Escalation**: Disabled in securityContext for modular containers

### Secrets Management

- **TLS Certificates**: Auto-provisioned and rotated by OpenShift service-ca-operator
- **OAuth Tokens**: Short-lived, managed by OpenShift OAuth server
- **ServiceAccount Tokens**: Kubernetes-managed, automatically rotated
- **User-provided Secrets**: Stored as Kubernetes Secrets, encrypted at rest

## Known Limitations

1. **OdhDashboardConfig**: Unmanaged resource - changes persist across operator upgrades, requires upgrade script for critical updates
2. **WebSocket Scaling**: Long-lived WebSocket connections may cause pod distribution challenges with HPA
3. **Module Federation**: Only supported in modular architecture deployment variant
4. **Browser Support**: Modern browsers only (ES2020+), no IE11 support
5. **OAuth Dependency**: Requires OpenShift OAuth server, not compatible with vanilla Kubernetes
6. **Single Namespace**: Dashboard deployment is single-namespace, though it manages resources cluster-wide

## Future Enhancements

Based on recent development activity:
- Continued migration to modular architecture for all specialized features
- Enhanced security scanning and SBOM integration (sealights variant)
- Improved Konflux integration for reproducible builds
- Gateway API adoption (HTTPRoute already present)
- Hardware profiles management (replacing accelerator profiles)
- Enhanced model catalog and registry features
