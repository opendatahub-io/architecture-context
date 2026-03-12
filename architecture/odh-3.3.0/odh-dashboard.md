# Component: ODH Dashboard

## Metadata
- **Repository**: https://github.com/opendatahub-io/odh-dashboard
- **Version**: v3.4.0EA1
- **Distribution**: ODH and RHOAI
- **Languages**: TypeScript, React, Node.js
- **Deployment Type**: Web Application (Frontend + Backend API)

## Purpose
**Short**: Web-based dashboard UI for managing and interacting with Open Data Hub and Red Hat OpenShift AI components.

**Detailed**: The ODH Dashboard provides a unified web interface for data scientists and administrators to interact with Open Data Hub (ODH) and Red Hat OpenShift AI (RHOAI) platforms. It enables users to manage workbenches (Jupyter notebooks), model serving deployments, data science projects, distributed workloads, model registries, and various AI/ML tools. The dashboard consists of a React-based frontend using PatternFly components and a Node.js/Fastify backend that interfaces with Kubernetes APIs. It supports a modular plugin architecture allowing feature packages to extend functionality (Gen AI, Model Registry, MLflow, AutoML, AutoRAG, etc.), and provides OAuth-based authentication through OpenShift's identity provider via kube-rbac-proxy.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| Frontend | React/TypeScript SPA | Web UI using PatternFly v6, Material UI (Kubeflow mode), Webpack Module Federation |
| Backend | Node.js/Fastify API | REST API server providing Kubernetes resource management and proxy services |
| kube-rbac-proxy | Authentication Proxy | OAuth authentication, request authorization, TLS termination |
| Feature Packages | Plugin Modules | Modular extensions (gen-ai, model-registry, mlflow, automl, autorag, kserve, etc.) |

## APIs Exposed

### Custom Resource Definitions (CRDs)

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| dashboard.opendatahub.io | v1 | OdhApplication | Namespaced | Defines ODH applications displayed in dashboard catalog |
| opendatahub.io | v1alpha | OdhDashboardConfig | Namespaced | Dashboard feature flag configuration and enablement settings |
| dashboard.opendatahub.io | v1 | OdhDocument | Namespaced | Documentation and getting started guides |
| console.openshift.io | v1 | OdhQuickStart | Namespaced | Interactive quickstart tutorials for ODH components |

### HTTP Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| / | GET | 8443/TCP | HTTPS | TLS 1.2+ | OAuth (kube-rbac-proxy) | Dashboard UI entry point |
| /api/health | GET | 8080/TCP | HTTP | None | None | Backend health check (internal) |
| /api/config | GET, PATCH | 8080/TCP | HTTP | None | Bearer Token | Dashboard configuration management |
| /api/dashboardConfig | GET, PATCH | 8080/TCP | HTTP | None | Bearer Token | OdhDashboardConfig CR management |
| /api/components | GET | 8080/TCP | HTTP | None | Bearer Token | List ODH component applications |
| /api/namespaces | GET | 8080/TCP | HTTP | None | Bearer Token | List accessible Kubernetes namespaces |
| /api/notebooks | GET, POST, DELETE, PATCH | 8080/TCP | HTTP | None | Bearer Token | Kubeflow Notebook CR management |
| /api/modelRegistries | GET, POST, PATCH, DELETE | 8080/TCP | HTTP | None | Bearer Token | ModelRegistry CR management |
| /api/connection-types | GET, POST, PUT, PATCH, DELETE | 8080/TCP | HTTP | None | Bearer Token | Connection type management for data connections |
| /api/builds | GET | 8080/TCP | HTTP | None | Bearer Token | OpenShift Build and ImageStream information |
| /api/cluster-settings | GET, PUT | 8080/TCP | HTTP | None | Bearer Token | Cluster-wide settings (storage classes, GPU profiles) |
| /api/quickstarts | GET | 8080/TCP | HTTP | None | Bearer Token | List available quickstart tutorials |
| /api/docs | GET | 8080/TCP | HTTP | None | Bearer Token | List documentation resources |
| /api/prometheus | Proxy | 8080/TCP | HTTP | None | Bearer Token | Proxy to Prometheus metrics endpoints |
| /api/k8s | Proxy | 8080/TCP | HTTP | None | Bearer Token | Generic Kubernetes API proxy |
| /api/integrations/nim | GET, POST, DELETE | 8080/TCP | HTTP | None | Bearer Token | NVIDIA NIM integration management |
| /api/featurestores | GET | 8080/TCP | HTTP | None | Bearer Token | Feast FeatureStore CR listing |
| /api/service | GET, POST, PATCH | 8080/TCP | HTTP | None | Bearer Token | Kubernetes Service management |
| /api/rolebindings | GET, POST, PATCH, DELETE | 8080/TCP | HTTP | None | Bearer Token | RoleBinding management for project access |

### gRPC Services

None - Dashboard uses HTTP/REST exclusively.

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| Node.js | >=22.0.0 | Yes | Runtime for backend server |
| Kubernetes | 1.24+ | Yes | Container orchestration platform |
| OpenShift | 4.12+ | Yes (RHOAI) | Platform for OAuth, Routes, Builds, ImageStreams |
| kube-rbac-proxy | latest | Yes | OAuth authentication and authorization |
| Prometheus | 2.x | No | Metrics collection (optional observability) |

### Internal ODH Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| odh-operator / rhoai-operator | CRD Watch | Reads DataScienceCluster, DSCInitialization for platform status |
| Kubeflow Notebooks | CRD Management | Creates/manages Notebook CRs for workbenches |
| KServe | CRD Watch | Lists InferenceService CRs for model serving |
| Model Registry | CRD Management | Creates/manages ModelRegistry CRs |
| TrustyAI | CRD Watch | Lists GuardrailsOrchestrator CRs for AI guardrails |
| Feast | CRD Watch | Lists FeatureStore CRs for feature stores |
| LlamaStack | CRD Watch | Lists LlamaStackDistribution CRs for LLM deployments |
| cert-manager | Certificate Usage | Consumes TLS certificates for service-to-service communication (optional) |

## Network Architecture

### Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| odh-dashboard | ClusterIP | 8443/TCP | 8443 | HTTPS | TLS (service-serving-cert) | OAuth (kube-rbac-proxy) | Internal |

### Ingress

| Name | Type | Hosts | Port | Protocol | Encryption | TLS Mode | Exposure |
|------|------|-------|------|----------|------------|----------|----------|
| odh-dashboard | OpenShift Route | (dynamic) | 443/TCP | HTTPS | TLS 1.2+ | Reencrypt | External |
| odh-dashboard | HTTPRoute (Gateway API) | (gateway-controlled) | 443/TCP | HTTPS | TLS 1.2+ | Gateway TLS | External |

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token | CR management, resource listing |
| Prometheus Service | 9091/TCP | HTTP | None | Bearer Token | Metrics queries (optional) |
| ModelRegistry Services | 8080/TCP | HTTP | None | Bearer Token | Model registry API proxy |
| OpenShift OAuth Server | 443/TCP | HTTPS | TLS 1.2+ | OAuth Token | User authentication validation |
| ImageStream Layers API | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token | Container image metadata |

## Security

### RBAC - Cluster Roles

| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|
| odh-dashboard | "" | configmaps, persistentvolumeclaims, secrets | create, delete, get, list, patch, update, watch |
| odh-dashboard | "" | nodes | get, list |
| odh-dashboard | "" | pods, serviceaccounts, services | get, list, watch |
| odh-dashboard | "" | namespaces | patch |
| odh-dashboard | "" | endpoints | get |
| odh-dashboard | "", events.k8s.io | events | get, list, watch |
| odh-dashboard | rbac.authorization.k8s.io | rolebindings, clusterrolebindings, roles | list, get, create, patch, delete |
| odh-dashboard | storage.k8s.io | storageclasses | update, patch |
| odh-dashboard | machine.openshift.io, autoscaling.openshift.io | machineautoscalers, machinesets | get, list |
| odh-dashboard | "", config.openshift.io | clusterversions, ingresses | get, watch, list |
| odh-dashboard | operators.coreos.com | clusterserviceversions, subscriptions | get, list, watch |
| odh-dashboard | "", image.openshift.io | imagestreams/layers | get |
| odh-dashboard | route.openshift.io | routes | get, list, watch |
| odh-dashboard | console.openshift.io | consolelinks | get, list, watch |
| odh-dashboard | operator.openshift.io | consoles | get, list, watch |
| odh-dashboard | user.openshift.io | groups, users | get, list, watch |
| odh-dashboard | kubeflow.org | notebooks | get, list, watch, create, update, patch, delete |
| odh-dashboard | datasciencecluster.opendatahub.io | datascienceclusters | list, watch, get |
| odh-dashboard | dscinitialization.opendatahub.io | dscinitializations | list, watch, get |
| odh-dashboard | serving.kserve.io | inferenceservices | get, list, watch |
| odh-dashboard | modelregistry.opendatahub.io | modelregistries | get, list, watch, create, update, patch, delete |
| odh-dashboard | services.platform.opendatahub.io | auths | get |
| odh-dashboard | llamastack.io | llamastackdistributions | get, list, watch |
| odh-dashboard | trustyai.opendatahub.io | guardrailsorchestrators | get, list, watch |
| odh-dashboard | feast.dev | featurestores | get, list, watch |
| odh-dashboard | authentication.k8s.io | tokenreviews | create |
| odh-dashboard | authorization.k8s.io | subjectaccessreviews | create |

### RBAC - Role Bindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| odh-dashboard | (dynamic) | ClusterRole/odh-dashboard | odh-dashboard |
| odh-dashboard-auth-delegator | kube-system | ClusterRole/system:auth-delegator | odh-dashboard |
| odh-dashboard-cluster-monitoring-view | openshift-monitoring | ClusterRole/cluster-monitoring-view | odh-dashboard |

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| dashboard-proxy-tls | kubernetes.io/tls | TLS certificate for kube-rbac-proxy | service.beta.openshift.io/serving-cert-secret-name annotation | Yes |

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| /* (all dashboard routes) | GET, POST, PATCH, DELETE | OAuth Bearer Token (OpenShift) | kube-rbac-proxy | OpenShift user/group-based access |
| /api/health | GET | None (unsecured) | Backend | Public health check |
| /* (backend API) | GET, POST, PATCH, DELETE | Bearer Token (propagated from kube-rbac-proxy) | Backend + Kubernetes API | X-Auth-Request-User, X-Auth-Request-Groups headers validated |

### Network Policies

| Policy Name | Selectors | Ingress Rules | Egress Rules |
|-------------|-----------|---------------|--------------|
| odh-dashboard-allow-ports | deployment=odh-dashboard | Allow 8443/TCP, 8043/TCP, 8143/TCP, 8243/TCP, 8343/TCP, 8543/TCP, 8643/TCP from OpenShift ingress and same namespace | (not restricted) |

## Data Flows

### Flow 1: User Authentication and Dashboard Access

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User Browser | OpenShift Router | 443/TCP | HTTPS | TLS 1.2+ | None (redirects to OAuth) |
| 2 | OpenShift Router | OpenShift OAuth Server | 443/TCP | HTTPS | TLS 1.2+ | OAuth challenge |
| 3 | OpenShift OAuth Server | User Browser | 443/TCP | HTTPS | TLS 1.2+ | OAuth token (cookie) |
| 4 | User Browser | odh-dashboard Service | 443/TCP -> 8443/TCP | HTTPS | TLS 1.2+ | Bearer Token (cookie) |
| 5 | kube-rbac-proxy | odh-dashboard Backend | 8080/TCP | HTTP | None (localhost) | X-Auth-Request-User header |
| 6 | odh-dashboard Backend | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |

### Flow 2: Notebook Creation

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User Browser | odh-dashboard Service | 443/TCP -> 8443/TCP | HTTPS | TLS 1.2+ | Bearer Token |
| 2 | kube-rbac-proxy | odh-dashboard Backend | 8080/TCP | HTTP | None | X-Auth-Request-User header |
| 3 | odh-dashboard Backend | Kubernetes API (Notebook CR) | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 4 | odh-dashboard Backend | Kubernetes API (PVC, RoleBinding) | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |

### Flow 3: Model Registry Management

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User Browser | odh-dashboard Service | 443/TCP -> 8443/TCP | HTTPS | TLS 1.2+ | Bearer Token |
| 2 | kube-rbac-proxy | odh-dashboard Backend | 8080/TCP | HTTP | None | X-Auth-Request-User header |
| 3 | odh-dashboard Backend | Kubernetes API (ModelRegistry CR) | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 4 | odh-dashboard Backend | Model Registry Service API | 8080/TCP | HTTP | None | Bearer Token (proxied) |

### Flow 4: Metrics Query (Prometheus)

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User Browser | odh-dashboard Service | 443/TCP -> 8443/TCP | HTTPS | TLS 1.2+ | Bearer Token |
| 2 | kube-rbac-proxy | odh-dashboard Backend | 8080/TCP | HTTP | None | X-Auth-Request-User header |
| 3 | odh-dashboard Backend | Prometheus Service (via ServiceAccount token) | 9091/TCP | HTTP | None | Bearer Token |

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| Kubernetes API Server | REST API | 6443/TCP | HTTPS | TLS 1.2+ | CRUD operations on CRs, ConfigMaps, Secrets, Namespaces |
| OpenShift OAuth Server | OAuth 2.0 | 443/TCP | HTTPS | TLS 1.2+ | User authentication and authorization |
| Prometheus | REST API (Proxy) | 9091/TCP | HTTP | None | Model serving metrics queries |
| Model Registry Service | REST API (Proxy) | 8080/TCP | HTTP | None | Model metadata management |
| Kubeflow Notebook Controller | CRD Watch | 6443/TCP | HTTPS | TLS 1.2+ | Notebook lifecycle management |
| KServe Controller | CRD Watch | 6443/TCP | HTTPS | TLS 1.2+ | InferenceService status monitoring |

## Recent Changes

| Version | Date | Changes |
|---------|------|---------|
| v3.4.0EA1 | 2025-01 | - Add automl module to modular architecture manifests<br>- Restructure AI Hub nav with Models and MCP servers subsections<br>- Update secrets API to respect odh dashboard annotations<br>- External models registration UI<br>- Add RayJob details drawer layout<br>- Type Filter for Ray and Train jobs<br>- Handle network errors in notebook controller<br>- Remove tech preview label on new permissions tab<br>- Sync from kubeflow/model-registry<br>- Balance test load across test sets<br>- Fix cluster storage workbenches reset by background polling |
| v3.3.x | 2024-12 | - Quarantine unreliable tests and reintroduce fixed tests<br>- Migrate LSD models endpoint to secret-based credentials<br>- Add test contracts for BFF validation<br>- Fix aiAssetExternalModels to aiAssetCustomEndpoints feature flag<br>- Bump Go version to 1.25.7 in Dockerfiles<br>- Sync security config files |
