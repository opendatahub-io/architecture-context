# Component: ODH Dashboard

## Metadata
- **Repository**: https://github.com/red-hat-data-services/odh-dashboard
- **Version**: v1.21.0-18-rhods-4281-g475248a55
- **Distribution**: Both ODH and RHOAI
- **Languages**: TypeScript, JavaScript (Node.js 20, React 18)
- **Deployment Type**: Web Application (Frontend + Backend Service)

## Purpose
**Short**: Web-based user interface for managing Open Data Hub and Red Hat OpenShift AI platform components, projects, and resources.

**Detailed**: The ODH Dashboard serves as the primary web interface for users interacting with the Open Data Hub and Red Hat OpenShift AI platforms. It provides a unified interface for managing data science workloads including Jupyter notebooks, model serving, pipelines, distributed workloads, and model registries. The dashboard integrates with the underlying Kubernetes/OpenShift cluster via API calls to manage custom resources, projects, and configurations. It features a modular plugin architecture that allows different components (model serving, feature store, LM eval, etc.) to be dynamically loaded. The dashboard also handles user authentication through OpenShift OAuth, provides feature flag management via OdhDashboardConfig CRDs, and exposes quickstart tutorials and documentation through custom resource definitions.

The application is built as a modern single-page application (SPA) using React 18 and PatternFly 6 components for the frontend, with a Node.js Fastify backend that acts as an API proxy to the Kubernetes API server. It supports both upstream Open Data Hub and downstream Red Hat OpenShift AI distributions with configuration-driven branding and feature toggles.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| Frontend (React) | Single Page Application | Web UI built with React 18, Redux, PatternFly 6, providing user interface for dashboard functionality |
| Backend (Fastify) | Node.js API Server | Fastify-based REST API server that proxies requests to Kubernetes API and provides business logic |
| OAuth Proxy | Sidecar Container | OpenShift OAuth proxy providing authentication and TLS termination for external access |
| Module Federation | Dynamic Plugin System | Webpack Module Federation for dynamic loading of feature plugins (gen-ai, model-registry, etc.) |
| Kubernetes Client | API Integration | @kubernetes/client-node for interacting with Kubernetes/OpenShift APIs |
| WebSocket Server | Real-time Communication | WebSocket support for live updates and streaming data |

## APIs Exposed

### Custom Resource Definitions (CRDs)

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| dashboard.opendatahub.io | v1 | OdhApplication | Namespaced | Defines applications/tiles shown in dashboard (Jupyter, model serving, etc.) |
| opendatahub.io | v1alpha | OdhDashboardConfig | Namespaced | Configuration for dashboard feature flags and settings |
| dashboard.opendatahub.io | v1 | OdhDocument | Namespaced | Documentation links and resources displayed in dashboard |
| console.openshift.io | v1 | OdhQuickStart | Namespaced | Interactive quickstart tutorials for dashboard features |
| dashboard.opendatahub.io | v1, v1alpha | AcceleratorProfile | Namespaced | GPU/accelerator profiles for workloads (deprecated, use HardwareProfile) |
| infrastructure.opendatahub.io | v1 | HardwareProfile | Namespaced | Hardware resource profiles for notebooks and model servers |

### HTTP Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /api/health | GET | 8080/TCP | HTTP | None | None | Backend health check endpoint |
| /api/config | GET | 8080/TCP | HTTP | None | ServiceAccount | Retrieve dashboard configuration |
| /api/dashboardConfig | GET, PATCH | 8080/TCP | HTTP | None | ServiceAccount | Manage OdhDashboardConfig resources |
| /api/k8s/* | GET, POST, PUT, PATCH, DELETE | 8080/TCP | HTTP | None | ServiceAccount | Proxy to Kubernetes API server |
| /api/notebooks | GET, POST, DELETE | 8080/TCP | HTTP | None | ServiceAccount | Manage Jupyter notebook resources |
| /api/modelRegistries | GET, POST, PATCH, DELETE | 8080/TCP | HTTP | None | ServiceAccount | Manage model registry instances |
| /api/servingRuntimes | GET, POST, PATCH, DELETE | 8080/TCP | HTTP | None | ServiceAccount | Manage serving runtime configurations |
| /api/components | GET | 8080/TCP | HTTP | None | ServiceAccount | List installed platform components |
| /api/quickstarts | GET | 8080/TCP | HTTP | None | ServiceAccount | Retrieve quickstart tutorials |
| /api/docs | GET | 8080/TCP | HTTP | None | ServiceAccount | Retrieve documentation resources |
| /api/prometheus/* | GET | 8080/TCP | HTTP | None | ServiceAccount | Proxy to Prometheus metrics |
| /api/accelerators | GET | 8080/TCP | HTTP | None | ServiceAccount | List available accelerator profiles |
| /api/builds | GET | 8080/TCP | HTTP | None | ServiceAccount | Retrieve build and image information |
| /api/dsc | GET | 8080/TCP | HTTP | None | ServiceAccount | Get DataScienceCluster status |
| /api/dsci | GET | 8080/TCP | HTTP | None | ServiceAccount | Get DSCInitialization status |
| /api/namespaces | GET | 8080/TCP | HTTP | None | ServiceAccount | List accessible namespaces/projects |
| /api/rolebindings | GET, POST, PATCH, DELETE | 8080/TCP | HTTP | None | ServiceAccount | Manage role bindings for project access |
| /api/segment-key | GET | 8080/TCP | HTTP | None | ServiceAccount | Retrieve analytics tracking key |
| /api/connection-types | GET | 8080/TCP | HTTP | None | ServiceAccount | List available connection types |
| /api/llama-stack | GET | 8080/TCP | HTTP | None | ServiceAccount | Interact with LlamaStack distributions |
| /api/nim-serving | GET | 8080/TCP | HTTP | None | ServiceAccount | Manage NVIDIA NIM model serving |
| /* | GET | 8080/TCP | HTTP | None | None | Serve frontend static assets |
| /oauth/* | ALL | 8443/TCP | HTTPS | TLS 1.2+ | OpenShift OAuth | OAuth authentication endpoints |
| /* | ALL | 8443/TCP | HTTPS | TLS 1.2+ | OpenShift OAuth | Authenticated access to dashboard (proxied to backend) |
| /metrics | GET | 8443/TCP | HTTPS | TLS 1.2+ | None | Prometheus metrics endpoint (auth bypass) |

### gRPC Services

| Service | Port | Protocol | Encryption | Auth | Purpose |
|---------|------|----------|------------|------|---------|
| N/A | N/A | N/A | N/A | N/A | No gRPC services exposed |

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| Node.js | 20.x | Yes | Runtime for backend server |
| React | 18.2.0 | Yes | Frontend UI framework |
| PatternFly | 6.3.1 | Yes | UI component library |
| Fastify | 4.28.1 | Yes | Backend web framework |
| @kubernetes/client-node | 0.12.2 | Yes | Kubernetes API client |
| Webpack | 5.96.1 | Yes | Frontend build tooling |
| Redux | 4.2.0 | Yes | State management |
| React Router | 7.6.2 | Yes | Frontend routing |
| OpenShift OAuth Proxy | latest | Yes | Authentication and TLS termination |
| Prometheus | N/A | No | Metrics collection (optional integration) |

### Internal ODH Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| opendatahub-operator | CRD/API | Reads DataScienceCluster and DSCInitialization resources |
| kubeflow/notebooks | CRD/API | Creates and manages Jupyter Notebook custom resources |
| kserve | CRD/API | Reads InferenceService resources for model serving status |
| model-registry-operator | CRD/API | Creates and manages ModelRegistry custom resources |
| odh-model-controller | CRD/API | Interacts with serving runtimes and model deployments |
| workbenches | API | Manages workbench notebook instances |
| data-science-pipelines | API | Integrates with pipeline runs and experiments |
| trustyai-service | API | Displays bias and trustworthiness metrics |
| kueue | CRD/API | Manages distributed workload queue configurations |
| codeflare-operator | CRD/API | Manages distributed training workloads |
| OpenShift API Server | REST API | Authentication, project management, user/group info |
| OpenShift Console | Integration | Registers console links for navigation |
| service-mesh (Istio) | Networking | Traffic routing and mTLS (when available) |

## Network Architecture

### Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| odh-dashboard | ClusterIP | 8443/TCP | 8443 | HTTPS | TLS 1.2+ | OpenShift OAuth | Internal |

### Ingress

| Name | Type | Hosts | Port | Protocol | Encryption | TLS Mode | Exposure |
|------|------|-------|------|----------|------------|----------|----------|
| odh-dashboard | OpenShift Route | cluster-dependent | 443/TCP | HTTPS | TLS 1.2+ | edge | External |

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token | Manage Kubernetes resources |
| Prometheus/Thanos | 9092/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token | Query metrics data |
| Model Registry Services | 443/TCP or 8080/TCP | HTTPS/HTTP | TLS 1.2+ (optional) | ServiceAccount Token | Query model registry APIs |
| OpenShift OAuth Server | 6443/TCP | HTTPS | TLS 1.2+ | OAuth Token | Validate user authentication |
| External Documentation | 443/TCP | HTTPS | TLS 1.2+ | None | Fetch documentation content |

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
| odh-dashboard | rbac.authorization.k8s.io | rolebindings, clusterrolebindings, roles | list, get, create, patch, delete |
| odh-dashboard | "", events.k8s.io | events | get, list, watch |
| odh-dashboard | kubeflow.org | notebooks | get, list, watch, create, update, patch, delete |
| odh-dashboard | datasciencecluster.opendatahub.io | datascienceclusters | list, watch, get |
| odh-dashboard | dscinitialization.opendatahub.io | dscinitializations | list, watch, get |
| odh-dashboard | serving.kserve.io | inferenceservices | get, list, watch |
| odh-dashboard | modelregistry.opendatahub.io | modelregistries | get, list, watch, create, update, patch, delete |
| odh-dashboard | "" | endpoints | get |
| odh-dashboard | services.platform.opendatahub.io | auths | get |
| odh-dashboard | llamastack.io | llamastackdistributions | get, list, watch |
| aggregate-hardware-profiles-permissions | infrastructure.opendatahub.io | hardwareprofiles | get, list, watch |
| aggregate-accelerator-profiles-permissions | dashboard.opendatahub.io | acceleratorprofiles | get, list, watch |

### RBAC - Role Bindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| odh-dashboard | opendatahub/redhat-ods-applications | odh-dashboard (ClusterRole) | odh-dashboard |
| odh-dashboard-image-puller | various | system:image-puller (ClusterRole) | odh-dashboard |
| odh-dashboard-auth-delegator | kube-system | system:auth-delegator (ClusterRole) | odh-dashboard |
| odh-dashboard-monitoring | opendatahub/redhat-ods-applications | cluster-monitoring-view (ClusterRole) | odh-dashboard |

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| dashboard-proxy-tls | kubernetes.io/tls | TLS certificate for OAuth proxy HTTPS | service.alpha.openshift.io/serving-cert-secret-name annotation | Yes |
| dashboard-oauth-config-generated | Opaque | OAuth cookie secret for session management | secret-generator.opendatahub.io | No |
| dashboard-oauth-client-generated | Opaque | OAuth client secret for authentication | secret-generator.opendatahub.io | No |
| odh-dashboard SA token | kubernetes.io/service-account-token | ServiceAccount token for API authentication | Kubernetes | Yes |

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| /* (external) | ALL | OpenShift OAuth (Bearer Token) | OAuth Proxy Sidecar | User must have project list permission |
| /metrics | GET | None (auth bypass) | OAuth Proxy Sidecar | Publicly accessible for monitoring |
| /api/* (internal) | ALL | ServiceAccount Token | Kubernetes API Server | RBAC enforced by ClusterRole |
| Backend to K8s API | ALL | ServiceAccount Token (mounted) | Kubernetes API Server | odh-dashboard ClusterRole permissions |

## Data Flows

### Flow 1: User Dashboard Access

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User Browser | OpenShift Router | 443/TCP | HTTPS | TLS 1.2+ | None |
| 2 | OpenShift Router | OAuth Proxy (Dashboard Pod) | 8443/TCP | HTTPS | TLS 1.2+ | None |
| 3 | OAuth Proxy | OpenShift OAuth Server | 6443/TCP | HTTPS | TLS 1.2+ | OAuth Flow |
| 4 | OAuth Proxy | Backend (Dashboard Pod) | 8080/TCP | HTTP | None | Bearer Token (header) |
| 5 | User Browser | Backend (via proxy) | 8080/TCP | HTTP (proxied HTTPS) | TLS 1.2+ (end-to-end) | OAuth Token |

### Flow 2: Dashboard API to Kubernetes

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Frontend (User Browser) | Backend (Dashboard Pod) | 8080/TCP | HTTP (via OAuth proxy) | TLS 1.2+ (external) | Bearer Token |
| 2 | Backend (Dashboard Pod) | Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 3 | Backend (Dashboard Pod) | User Browser | 8080/TCP | HTTP (via OAuth proxy) | TLS 1.2+ (external) | None (response) |

### Flow 3: Metrics Collection

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Prometheus/Thanos | OAuth Proxy (Dashboard Pod) | 8443/TCP | HTTPS | TLS 1.2+ | None (skip-auth-regex) |
| 2 | Dashboard Backend | Prometheus/Thanos RBAC Proxy | 9092/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |

### Flow 4: WebSocket Communication

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Frontend (User Browser) | Backend (Dashboard Pod) | 8080/TCP | WebSocket (via OAuth proxy) | TLS 1.2+ (upgraded) | Bearer Token |
| 2 | Backend (Dashboard Pod) | Kubernetes API Server | 6443/TCP | WebSocket/HTTPS | TLS 1.2+ | ServiceAccount Token |

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| Kubernetes API Server | REST API | 6443/TCP | HTTPS | TLS 1.2+ | Manage all Kubernetes resources |
| OpenShift OAuth Server | OAuth 2.0 | 6443/TCP | HTTPS | TLS 1.2+ | User authentication and authorization |
| Prometheus/Thanos | HTTP/REST | 9092/TCP | HTTPS | TLS 1.2+ | Query metrics for model serving and workloads |
| Kubeflow Notebooks | CRD Management | 6443/TCP | HTTPS | TLS 1.2+ | Create and manage notebook instances |
| KServe | CRD Read | 6443/TCP | HTTPS | TLS 1.2+ | Display inference service status |
| Model Registry | HTTP/gRPC | 8080/TCP or 9090/TCP | HTTP/gRPC | varies | Query model metadata and artifacts |
| OpenShift Console | Console Link | N/A | N/A | N/A | Register navigation links |
| DataScienceCluster Operator | CRD Read | 6443/TCP | HTTPS | TLS 1.2+ | Read platform configuration |
| LlamaStack | CRD Read | 6443/TCP | HTTPS | TLS 1.2+ | Manage LLM inference distributions |
| Segment Analytics | HTTP/REST | 443/TCP | HTTPS | TLS 1.2+ | Optional usage analytics |

## Recent Changes

| Commit | Date | Changes |
|--------|------|---------|
| 475248a55 | 2026-03 | - Merge upstream stable-2.x into rhoai-2.25 branch |
| 2f2d92d32 | 2026-03 | - Update UBI9 Go toolset Docker digest |
| 1718167b2 | 2026-03 | - Fix pod status type error in 2.25-next |
| 4256116a2 | 2026-03 | - Update UBI9 Node.js 20 Docker digest to f374423 |
| 2153939ae | 2026-03 | - Sync pipeline runs with konflux-central |
| 928b68dd8 | 2026-03 | - Go version bump refactoring |
| c366172c3 | 2026-03 | - Simplify prefetch-input configuration in Tekton pipelines |
| 79a7c4319 | 2026-03 | - Add rhoai-version parameter (2.25.0) to Tekton pipeline configurations |

## Deployment Architecture

### Container Images

The dashboard is built using Konflux pipelines with the following Dockerfiles:

- **Dockerfile.konflux**: Primary production image for RHOAI (uses UBI9 Node.js 20 base)
  - Multi-stage build: builder stage compiles TypeScript, runtime stage runs production server
  - Sets RHOAI-specific branding (logo, product name, documentation links)
  - Runs backend server on port 8080 as user 1001

- **Dockerfile.konflux.modelregistry**: Variant with model registry plugin pre-built
- **Dockerfile**: Upstream ODH build (legacy, prefer Konflux builds)

### Deployment Variants

The manifests support three deployment modes via Kustomize:

1. **ODH (Open Data Hub)**: `manifests/odh/`
   - Upstream community deployment
   - Namespace: `opendatahub`
   - Full feature set enabled by default

2. **RHOAI Addon (Managed)**: `manifests/rhoai/addon/`
   - Red Hat managed cloud service
   - Restricted feature set
   - Controlled by addon operator

3. **RHOAI On-Premise (Self-Managed)**: `manifests/rhoai/onprem/`
   - Customer-managed RHOAI installation
   - Namespace: `redhat-ods-applications`
   - Full RHOAI feature set

### Resource Management

- **Replicas**: 2 (with pod anti-affinity for zone distribution)
- **CPU Requests**: 500m (backend), 500m (oauth-proxy)
- **CPU Limits**: 1000m (backend), 1000m (oauth-proxy)
- **Memory Requests**: 1Gi (backend), 1Gi (oauth-proxy)
- **Memory Limits**: 2Gi (backend), 2Gi (oauth-proxy)

### High Availability

- Pod anti-affinity rules distribute replicas across availability zones
- Readiness probes on `/api/health` ensure traffic only to healthy pods
- Liveness probes on TCP socket (port 8080) detect crashed processes
- OAuth proxy has separate health checks on `/oauth/healthz`

### Configuration Injection

The operator injects runtime configuration through:
- **params.env**: Environment-specific parameters (image refs, namespaces)
- **OdhDashboardConfig CR**: Feature flags and dashboard behavior
- **ConfigMaps**: Trusted CA bundles, federation module configs
- **Secrets**: OAuth credentials, TLS certificates

### Module Federation

Dynamic plugin architecture allows features to be:
- Loaded at runtime from separate bundles
- Enabled/disabled via feature flags
- Built independently (gen-ai, model-registry, feature-store, lm-eval, etc.)
- Configured via federation-configmap.yaml

## Monitoring and Observability

### Metrics

- **Endpoint**: `/metrics` (exposed via OAuth proxy without authentication)
- **Format**: Prometheus text format
- **Collection**: Prometheus scrapes metrics endpoint
- **Metrics Library**: prom-client (Node.js)

### Logging

- **Framework**: Pino logger with structured JSON output
- **Log Level**: Configurable via LOG_LEVEL environment variable
- **Development Mode**: Pretty-printed colored output
- **Production Mode**: JSON structured logs
- **Redaction**: Automatically redacts Authorization headers from logs
- **Admin Activity**: Separate admin activity log in `/usr/src/app/logs/adminActivity.log`

### Health Checks

- **Liveness**: TCP socket check on port 8080 (backend) and HTTPS on 8443 (oauth-proxy)
- **Readiness**: HTTP GET `/api/health` on port 8080
- **Initial Delay**: 30 seconds (backend), 5 seconds (oauth-proxy readiness)
- **Timeout**: 15 seconds (backend), 1 second (oauth-proxy)
- **Period**: 30 seconds (backend), 5 seconds (oauth-proxy)

## Security Considerations

### Network Policies

Network policies are defined in `manifests/modular-architecture/networkpolicy.yaml` and `manifests/rhoai/shared/base/networkpolicy.yaml` to control pod-to-pod communication.

### TLS/Certificate Management

- **OAuth Proxy TLS**: Automatically provisioned via `service.alpha.openshift.io/serving-cert-secret-name` annotation
- **CA Bundles**: Multiple CA bundle sources mounted for egress HTTPS calls:
  - `/etc/pki/ca-trust/extracted/pem/tls-ca-bundle.pem` (system CA bundle)
  - `/var/run/secrets/kubernetes.io/serviceaccount/ca.crt` (Kubernetes CA)
  - `/var/run/secrets/kubernetes.io/serviceaccount/service-ca.crt` (service CA)
  - `/etc/pki/tls/certs/odh-ca-bundle.crt` (ODH platform CA)
  - `/etc/pki/tls/certs/odh-trusted-ca-bundle.crt` (ODH trusted CA)

### Secret Management

- Secrets are managed via secret-generator.opendatahub.io annotations
- OAuth secrets auto-generated with cryptographically secure randomness
- ServiceAccount tokens auto-rotated by Kubernetes
- No hardcoded credentials in code or manifests

### Resource Lifecycle

- **Fully Managed Resources**: Most manifests (deployment, service, RBAC) are reconciled by operator
- **Unmanaged Resources**: OdhDashboardConfig (once created, customer-owned)
- **Partially Managed Resources**: Deployment replicas and resource limits can be modified by users

## Plugin Architecture

The dashboard supports a modular plugin system using Webpack Module Federation:

### Available Plugins

| Plugin | Package | Purpose |
|--------|---------|---------|
| Gen AI | packages/gen-ai | Generative AI model management and inference |
| Model Registry | packages/model-registry | Model versioning and metadata management |
| Feature Store | packages/feature-store | Feature engineering and storage |
| LM Eval | packages/lm-eval | Language model evaluation and benchmarking |
| KServe | packages/kserve | KServe model serving integration |
| Model Serving | packages/model-serving | Model deployment and serving runtimes |
| Model Training | packages/model-training | Training job management |

### Plugin Loading

- Plugins are loaded dynamically via `@module-federation/runtime`
- Configuration defined in federation-configmap
- Feature flags in OdhDashboardConfig control plugin availability
- Plugins can be enabled/disabled without redeploying dashboard

## API Structure

The backend exposes 35+ API route groups organized by functionality:

- **Resource Management**: k8s, namespaces, notebooks, servingRuntimes
- **Configuration**: config, dashboardConfig, cluster-settings
- **Platform Integration**: dsc, dsci, components, operator-subscription-status
- **Model Operations**: modelRegistries, modelRegistryCertificates, nim-serving
- **Documentation**: docs, quickstarts
- **Access Control**: rolebindings, dev-impersonate
- **Hardware**: accelerators (profiles)
- **Observability**: prometheus, health, status
- **Connectivity**: connection-types, route, service
- **Build & Deploy**: builds, envs
- **External Integrations**: console-links, integrations, llama-stack
- **Analytics**: segment-key, validate-isv

Each API route group typically provides CRUD operations for its respective resource type, with consistent error handling and logging via Fastify plugins.
