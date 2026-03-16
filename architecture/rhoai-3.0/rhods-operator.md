# Component: RHODS Operator (OpenDataHub Operator)

## Metadata
- **Repository**: https://github.com/red-hat-data-services/rhods-operator.git
- **Version**: v1.6.0-3582-g331819fa5
- **Branch**: rhoai-3.0
- **Distribution**: RHOAI (also used for ODH)
- **Languages**: Go 1.24
- **Deployment Type**: Kubernetes Operator (controller-runtime based)
- **Build System**: Konflux (production builds)
- **Container Base**: UBI9 Minimal

## Purpose
**Short**: Platform operator that manages the complete lifecycle of Red Hat OpenShift AI and Open Data Hub data science components and infrastructure services.

**Detailed**:

The RHODS Operator (opendatahub-operator) is the central control plane for Red Hat OpenShift AI (RHOAI) and Open Data Hub (ODH) platforms. It orchestrates the deployment, configuration, and lifecycle management of data science workloads and supporting infrastructure across OpenShift clusters.

The operator manages two primary resource types: **DataScienceCluster** (DSC) which defines enabled components, and **DSCInitialization** (DSCI) which configures platform-wide settings like monitoring, trusted CA bundles, and namespaces. Component controllers deploy individual data science applications (dashboards, notebooks, pipelines, model serving) while service controllers manage shared infrastructure (gateway, authentication, monitoring).

**Critical RHOAI 3.x Architecture**: This operator deploys Gateway API-based ingress infrastructure as the primary platform ingress mechanism. The gateway controller creates GatewayClass, Gateway, EnvoyFilter, and kube-auth-proxy resources in the `openshift-ingress` namespace. Component controllers create HTTPRoute CRs that reference the platform gateway (`data-science-gateway`) and inject kube-rbac-proxy sidecars for authentication - replacing the legacy Route + oauth-proxy pattern from RHOAI 2.x.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| RHODS Operator Manager | Go Binary (controller-runtime) | Main operator process managing reconciliation loops for all CRDs |
| DataScienceCluster Controller | Reconciler | Manages DSC CR to orchestrate component enablement/removal |
| DSCInitialization Controller | Reconciler | Manages DSCI CR for platform initialization, monitoring, and CA bundles |
| Gateway Service Controller | Reconciler | Deploys Gateway API infrastructure (GatewayClass, Gateway, EnvoyFilter, kube-auth-proxy) |
| Auth Service Controller | Reconciler | Manages authentication service configuration |
| Monitoring Service Controller | Reconciler | Deploys Prometheus, Alertmanager, ServiceMonitors for platform observability |
| Cert ConfigMap Generator Controller | Reconciler | Generates certificate ConfigMaps from secrets |
| Dashboard Component Controller | Reconciler | Deploys ODH/RHOAI Dashboard UI |
| Workbenches Component Controller | Reconciler | Manages Jupyter notebook controllers and workbench infrastructure |
| DataSciencePipelines Component Controller | Reconciler | Deploys Kubeflow Pipelines (Argo Workflows, API server, persistence) |
| KServe Component Controller | Reconciler | Manages KServe model serving platform (raw deployment mode) |
| Kueue Component Controller | Reconciler | Deploys Kueue job queueing system |
| Ray Component Controller | Reconciler | Manages Ray distributed computing framework |
| TrustyAI Component Controller | Reconciler | Deploys TrustyAI explainability and fairness service |
| ModelRegistry Component Controller | Reconciler | Manages model registry service for ML model metadata |
| TrainingOperator Component Controller | Reconciler | Deploys Kubeflow Training Operator for distributed training |
| FeastOperator Component Controller | Reconciler | Manages Feast feature store operator |
| LlamaStackOperator Component Controller | Reconciler | Deploys LlamaStack operator for LLM workloads |
| ModelController Component Controller | Reconciler | Manages model controller for serving orchestration |
| Webhooks | Validating/Mutating Webhooks | Enforce admission policies for DSC, DSCI, and component CRs |

## APIs Exposed

### Custom Resource Definitions (CRDs)

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| datasciencecluster.opendatahub.io | v1, v2 | DataScienceCluster | Cluster | Defines which data science components are enabled and their configuration |
| dscinitialization.opendatahub.io | v1, v2 | DSCInitialization | Cluster | Platform initialization: monitoring, CA bundles, namespaces, feature flags |
| services.platform.opendatahub.io | v1alpha1 | GatewayConfig | Cluster | Configures platform ingress gateway (certificate, OIDC, domain, cookies) |
| services.platform.opendatahub.io | v1alpha1 | Auth | Cluster | Configures authentication service settings |
| services.platform.opendatahub.io | v1alpha1 | Monitoring | Cluster | Configures monitoring stack (Prometheus, Alertmanager, storage) |
| components.platform.opendatahub.io | v1alpha1 | Dashboard | Cluster | Dashboard component configuration and status |
| components.platform.opendatahub.io | v1alpha1 | Workbenches | Cluster | Workbenches (notebooks) component configuration |
| components.platform.opendatahub.io | v1alpha1 | DataSciencePipelines | Cluster | AI/ML pipelines component configuration |
| components.platform.opendatahub.io | v1alpha1 | Kserve | Cluster | KServe model serving configuration |
| components.platform.opendatahub.io | v1alpha1 | Kueue | Cluster | Kueue job queueing configuration |
| components.platform.opendatahub.io | v1alpha1 | Ray | Cluster | Ray distributed computing configuration |
| components.platform.opendatahub.io | v1alpha1 | TrustyAI | Cluster | TrustyAI explainability configuration |
| components.platform.opendatahub.io | v1alpha1 | ModelRegistry | Cluster | Model registry configuration |
| components.platform.opendatahub.io | v1alpha1 | TrainingOperator | Cluster | Training operator configuration |
| components.platform.opendatahub.io | v1alpha1 | FeastOperator | Cluster | Feast feature store configuration |
| components.platform.opendatahub.io | v1alpha1 | LlamaStackOperator | Cluster | LlamaStack operator configuration |
| components.platform.opendatahub.io | v1alpha1 | ModelController | Cluster | Model controller configuration |
| features.opendatahub.io | v1 | FeatureTracker | Cluster | Tracks enabled features and dependencies |
| infrastructure.opendatahub.io | v1, v1alpha1 | HardwareProfile | Cluster | Defines hardware profiles for workloads |

### HTTP Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /healthz | GET | 8081/TCP | HTTP | None | None | Operator liveness probe |
| /readyz | GET | 8081/TCP | HTTP | None | None | Operator readiness probe |
| /metrics | GET | 8080/TCP | HTTP | None | None | Operator Prometheus metrics |
| /validate-* | POST | 9443/TCP | HTTPS | TLS 1.2+ | Webhook cert | Validating webhook endpoints |
| /mutate-* | POST | 9443/TCP | HTTPS | TLS 1.2+ | Webhook cert | Mutating webhook endpoints |

### Gateway API Resources (Deployed by Gateway Controller)

**CRITICAL RHOAI 3.x Ingress Architecture**: The gateway controller dynamically creates these resources - they are NOT in static manifests but are deployed at runtime through controller reconcile logic.

| Resource Type | Name | Namespace | Purpose |
|---------------|------|-----------|---------|
| GatewayClass | data-science-gateway-class | N/A (cluster-scoped) | Defines gateway class using OpenShift Gateway Controller |
| Gateway | data-science-gateway | openshift-ingress | Platform ingress gateway for all RHOAI components (HTTPS/443) |
| EnvoyFilter | authn-filter | openshift-ingress | Istio/Service Mesh integration for authentication with ext_authz |
| DestinationRule | kube-auth-proxy-tls | openshift-ingress | Configures mTLS for kube-auth-proxy service traffic |
| Deployment | kube-auth-proxy | openshift-ingress | OAuth2 proxy deployment for authentication (kube-rbac-proxy pattern) |
| Service | kube-auth-proxy | openshift-ingress | Service exposing kube-auth-proxy on 4180/TCP (HTTP) and 8443/TCP (HTTPS) |
| Secret | kube-auth-proxy-creds | openshift-ingress | OAuth2 proxy credentials (client secret, cookie secret) |
| Secret | kube-auth-proxy-tls | openshift-ingress | TLS certificate for kube-auth-proxy service |
| HTTPRoute | oauth-callback-route | openshift-ingress | OAuth callback route for authentication flow |
| OAuthClient | odh | N/A (cluster-scoped) | OpenShift OAuth client (IntegratedOAuth mode only, not OIDC/ROSA) |

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| Kubernetes | 1.25+ | Yes | Container orchestration platform |
| OpenShift | 4.12+ | Yes | Enterprise Kubernetes distribution with Routes, OAuth, security |
| Gateway API CRDs | v1 | Yes | Gateway, GatewayClass, HTTPRoute resources for ingress |
| Prometheus Operator | v0.68+ | No | ServiceMonitor, PrometheusRule CRDs for monitoring |
| Istio / OpenShift Service Mesh | 2.4+ | No | EnvoyFilter, DestinationRule for service mesh integration |
| cert-manager | v1.11+ | No | Optional certificate management for custom certs |
| OpenShift Ingress Operator | N/A | Yes | Manages default ingress controller and certificates |

### Internal ODH Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| ODH Dashboard | Deploys manifest | Web UI for data science platform |
| ODH Notebook Controller | Deploys manifest | Manages Jupyter notebook lifecycle, creates HTTPRoutes + kube-rbac-proxy sidecars |
| Kubeflow Pipelines | Deploys manifest | ML pipeline orchestration |
| KServe | Deploys manifest | Model serving inference platform |
| Kuberay Operator | Deploys manifest | Ray cluster management |
| Kueue | Deploys manifest | Job queue and resource quota management |
| TrustyAI Service | Deploys manifest | Model explainability and bias detection |
| Model Registry | Deploys manifest | ML model metadata and versioning |
| Training Operator | Deploys manifest | Distributed training jobs (PyTorch, TensorFlow) |
| Feast Operator | Deploys manifest | Feature store for ML |

## Network Architecture

### Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| rhods-operator-webhook-service | ClusterIP | 443/TCP | 9443 | HTTPS | TLS 1.2+ | Webhook cert | Internal |
| kube-auth-proxy | ClusterIP | 4180/TCP | 4180 | HTTP | None | OAuth2 | Internal (openshift-ingress ns) |
| kube-auth-proxy | ClusterIP | 8443/TCP | 8443 | HTTPS | TLS 1.3 | OAuth2 | Internal (openshift-ingress ns) |
| kube-auth-proxy | ClusterIP | 9000/TCP | 9000 | HTTP | None | None | Internal (metrics only) |
| prometheus | ClusterIP | 9090/TCP | 9090 | HTTPS | TLS 1.3 | mTLS | Internal (monitoring ns) |
| alertmanager | ClusterIP | 9093/TCP | 9093 | HTTPS | TLS 1.3 | mTLS | Internal (monitoring ns) |
| blackbox-exporter | ClusterIP | 9115/TCP | 9115 | HTTP | None | None | Internal (monitoring ns) |

### Ingress

**CRITICAL**: This section documents controller-managed ingress infrastructure deployed dynamically at runtime by the gateway controller.

| Name | Type | Hosts | Port | Protocol | Encryption | TLS Mode | Exposure |
|------|------|-------|------|----------|------------|----------|----------|
| data-science-gateway | Gateway (Gateway API v1) | *.apps.<cluster-domain> | 443/TCP | HTTPS | TLS 1.3 | SIMPLE (server-side TLS) | External |
| oauth-callback-route | HTTPRoute (Gateway API v1) | <gateway-domain> | 443/TCP | HTTPS | TLS 1.3 | Via parent Gateway | External (OAuth callback only) |

**Authentication Flow (RHOAI 3.x)**:
1. External request → Gateway (443/TCP) → EnvoyFilter ext_authz check
2. EnvoyFilter → kube-auth-proxy service (8443/TCP HTTPS)
3. kube-auth-proxy validates OAuth/OIDC session cookie
4. If valid: EnvoyFilter allows request through to backend HTTPRoute
5. If invalid: Redirect to OAuth/OIDC provider login
6. After login: Callback to oauth-callback-route → kube-auth-proxy sets session cookie

**Component Ingress Pattern (NEW in RHOAI 3.x)**:
- Component controllers (e.g., odh-notebook-controller) create HTTPRoute CRs per workload
- HTTPRoutes reference parent Gateway: `data-science-gateway` in `openshift-ingress` namespace
- Component controllers inject kube-rbac-proxy sidecars (8443/TCP) for per-workload authentication
- Pattern: External request → Gateway → EnvoyFilter authz → HTTPRoute → kube-rbac-proxy sidecar → application container

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| quay.io | 443/TCP | HTTPS | TLS 1.2+ | Registry pull secret | Pull component container images |
| registry.redhat.io | 443/TCP | HTTPS | TLS 1.2+ | Red Hat pull secret | Pull RHOAI certified images |
| OpenShift API Server | 6443/TCP | HTTPS | TLS 1.2+ | Service account token | Kubernetes API operations |
| Prometheus Federation | 9091/TCP | HTTPS | TLS 1.3 | Bearer token | Federate metrics to cluster monitoring |
| OIDC Provider (if configured) | 443/TCP | HTTPS | TLS 1.2+ | Client credentials | OIDC authentication (ROSA/OIDC mode) |
| OpenShift OAuth Server | 443/TCP | HTTPS | TLS 1.2+ | OAuth client | OAuth authentication (IntegratedOAuth mode) |
| Component Git Repositories | 443/TCP | HTTPS | TLS 1.2+ | None (public) | Fetch component manifests during build |

## Security

### RBAC - Cluster Roles

**Note**: The operator requires extensive cluster-level permissions to manage components across namespaces. Key permissions include:

| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|
| rhods-operator-role | "" | configmaps, secrets, serviceaccounts, services, namespaces | create, delete, get, list, patch, update, watch |
| rhods-operator-role | "" | pods, pods/exec, pods/log, persistentvolumes, persistentvolumeclaims | * (all) |
| rhods-operator-role | apps | deployments, replicasets, statefulsets | * (all) |
| rhods-operator-role | rbac.authorization.k8s.io | roles, rolebindings, clusterroles, clusterrolebindings | create, delete, get, list, patch, update, watch |
| rhods-operator-role | route.openshift.io | routes | create, delete, get, list, patch, update, watch |
| rhods-operator-role | gateway.networking.k8s.io | gateways, gatewayclasses, httproutes | create, delete, get, list, patch, update, watch |
| rhods-operator-role | networking.istio.io | envoyfilters, destinationrules, virtualservices | create, delete, get, list, patch, update, watch |
| rhods-operator-role | oauth.openshift.io | oauthclients | create, delete, get, list, patch, update, watch |
| rhods-operator-role | config.openshift.io | ingresses, authentications, clusterversions | get, list, watch |
| rhods-operator-role | operator.openshift.io | ingresscontrollers | get, list, watch |
| rhods-operator-role | apiextensions.k8s.io | customresourcedefinitions | create, delete, get, list, patch, update, watch |
| rhods-operator-role | admissionregistration.k8s.io | validatingwebhookconfigurations, mutatingwebhookconfigurations | create, delete, get, list, patch, update, watch |
| rhods-operator-role | monitoring.coreos.com | servicemonitors, prometheusrules, podmonitors | create, delete, get, list, patch, update, watch |
| rhods-operator-role | datasciencecluster.opendatahub.io | datascienceclusters, datascienceclusters/status | * (all) |
| rhods-operator-role | dscinitialization.opendatahub.io | dscinitializations, dscinitializations/status | * (all) |
| rhods-operator-role | components.platform.opendatahub.io | dashboards, workbenches, kserves, datasciencepipelines, etc. | * (all) |
| rhods-operator-role | services.platform.opendatahub.io | gatewayconfigs, auths, monitorings | * (all) |
| rhods-operator-role | operators.coreos.com | subscriptions, clusterserviceversions, catalogsources | get, list, watch, patch |

### RBAC - Role Bindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| rhods-operator-rolebinding | Cluster-wide | rhods-operator-role (ClusterRole) | redhat-ods-operator-controller-manager |

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| rhods-operator-webhook-cert | kubernetes.io/tls | Webhook server TLS certificate | OpenShift cert injection | No |
| kube-auth-proxy-creds | Opaque | OAuth2 proxy credentials (clientSecret, cookieSecret, clientID) | Gateway controller | No |
| kube-auth-proxy-tls | kubernetes.io/tls | TLS certificate for kube-auth-proxy service | Gateway controller (from OpenShift ingress) | Yes (follows ingress cert rotation) |
| default-gateway-tls | kubernetes.io/tls | Gateway TLS certificate (references OpenShift default ingress cert) | Gateway controller | Yes (follows ingress cert rotation) |
| <component>-secret-* | Opaque | Component-specific secrets (DB passwords, API keys) | Component controllers | No |

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| Gateway (*.apps.<domain>) | ALL | OAuth2 / OIDC | EnvoyFilter ext_authz → kube-auth-proxy | Valid session cookie or redirect to login |
| kube-auth-proxy (8443/TCP) | ALL | Bearer Token (OAuth/OIDC) | OAuth2-proxy | Valid access token and session |
| Kubernetes API (operator) | ALL | Service Account Token | Kubernetes API Server | ClusterRole rhods-operator-role RBAC |
| Webhook endpoints | POST | TLS Client Cert | Kubernetes API Server | Webhook certificate validation |
| Component HTTPRoutes | ALL | kube-rbac-proxy sidecar | kube-rbac-proxy (per-workload) | Kubernetes RBAC (SubjectAccessReview) |

**RHOAI 3.x Authentication Architecture**:
- **IntegratedOAuth mode** (OpenShift): OAuthClient → OpenShift OAuth server → kube-auth-proxy validates session
- **OIDC mode** (ROSA/external IdP): OIDC provider (Keycloak/etc.) → kube-auth-proxy validates OIDC tokens
- **Per-component auth**: kube-rbac-proxy sidecars injected by component controllers enforce Kubernetes RBAC before proxying to app containers

## Data Flows

### Flow 1: Component Enablement (DataScienceCluster Creation)

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User / GitOps | Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | kubectl / ServiceAccount token |
| 2 | Kubernetes API Server | RHODS Operator Webhook | 9443/TCP | HTTPS | TLS 1.2+ | Webhook cert validation |
| 3 | RHODS Operator Webhook | Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount token |
| 4 | DataScienceCluster Controller | Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount token |
| 5 | Component Controllers | Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount token |
| 6 | Component Controllers | Container Registries (quay.io) | 443/TCP | HTTPS | TLS 1.2+ | Pull secret |

### Flow 2: Gateway Deployment (Platform Ingress Setup)

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | RHODS Operator (startup) | Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount token |
| 2 | Gateway Controller | Kubernetes API Server (create GatewayClass) | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount token |
| 3 | Gateway Controller | Kubernetes API Server (create Gateway) | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount token |
| 4 | Gateway Controller | OpenShift Ingress Controller | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount token |
| 5 | Gateway Controller | Kubernetes API Server (create EnvoyFilter) | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount token |
| 6 | Gateway Controller | Kubernetes API Server (create kube-auth-proxy Deployment) | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount token |
| 7 | Gateway Controller | Kubernetes API Server (create OAuthClient) | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount token |

### Flow 3: External User Request (RHOAI 3.x with Authentication)

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | External User | OpenShift Router | 443/TCP | HTTPS | TLS 1.3 | None |
| 2 | OpenShift Router | Gateway (data-science-gateway) | 443/TCP | HTTPS | TLS 1.3 | None |
| 3 | Gateway (EnvoyFilter ext_authz) | kube-auth-proxy Service | 8443/TCP | HTTPS | TLS 1.3 | None (internal authz check) |
| 4 | kube-auth-proxy | OpenShift OAuth / OIDC Provider | 443/TCP | HTTPS | TLS 1.2+ | OAuth client credentials / OIDC |
| 5 | OpenShift OAuth / OIDC Provider | kube-auth-proxy | 443/TCP | HTTPS | TLS 1.2+ | OAuth code / OIDC tokens |
| 6 | EnvoyFilter (authz approved) | Backend Service (via HTTPRoute) | varies | HTTP/HTTPS | varies | Forwarded OAuth/OIDC headers |
| 7 | Backend Service | kube-rbac-proxy sidecar | 8443/TCP | HTTPS | TLS 1.3 | Kubernetes Bearer token |
| 8 | kube-rbac-proxy sidecar | Application Container | 8080/TCP | HTTP | None | None (localhost) |

### Flow 4: Monitoring and Metrics

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Prometheus (RHOAI monitoring) | RHODS Operator | 8080/TCP | HTTP | None | None |
| 2 | Prometheus (RHOAI monitoring) | Component ServiceMonitors | varies | HTTP/HTTPS | varies | Bearer token / mTLS |
| 3 | Prometheus (RHOAI monitoring) | OpenShift Cluster Monitoring (federation) | 9091/TCP | HTTPS | TLS 1.3 | Bearer token |
| 4 | Alertmanager | OpenShift Alertmanager / External receivers | 443/TCP | HTTPS | TLS 1.2+ | Webhook secrets |

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| OpenShift Ingress Controller | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | Gateway provisioning and TLS certificate injection |
| OpenShift OAuth Server | OAuth 2.0 | 443/TCP | HTTPS | TLS 1.2+ | User authentication for IntegratedOAuth mode |
| External OIDC Provider (Keycloak/etc.) | OIDC | 443/TCP | HTTPS | TLS 1.2+ | User authentication for OIDC mode (ROSA) |
| OpenShift Service Mesh / Istio | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | EnvoyFilter and DestinationRule management for service mesh |
| Prometheus Operator | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | ServiceMonitor and PrometheusRule CR creation |
| OpenShift Cluster Monitoring | Prometheus Federation | 9091/TCP | HTTPS | TLS 1.3 | Metrics federation to cluster monitoring stack |
| OLM (Operator Lifecycle Manager) | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | Operator installation and updates |
| Component Operators (KServe, Kuberay, etc.) | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | Deploy and manage via Subscriptions and component-specific CRDs |
| Container Registries (quay.io, registry.redhat.io) | HTTPS | 443/TCP | HTTPS | TLS 1.2+ | Pull component container images |

## Recent Changes

| Version | Date | Changes |
|---------|------|---------|
| v1.6.0-3582-g331819fa5 | 2026-03-14 | - Updating operator repo with latest images and manifests<br>- Updated odh-must-gather-v3-0 to a7820c1<br>- Updated odh-kuberay-operator-controller-v3-0 to 35bd47d |
| v1.6.0-3579-g9241b8a24 | 2026-03-13 | - Updated odh-dashboard-v3-0 to ae158eb<br>- Component dependency updates via Konflux |
| v1.6.0-3576-gc52b1743f | 2026-03-12 | - Updated odh-kuberay-operator-controller-v3-0 to 3de22b9<br>- Continuous integration updates |
| v1.6.0-3574-ge213ab318 | 2026-03-11 | - Updated odh-dashboard-v3-0 to ced0bc6, 8c190ca, 19f6955<br>- Multiple dashboard updates merged |
| v1.6.0 (base) | 2025-Q4 | - **RHOAI 3.0 GA Release**<br>- Gateway API ingress architecture (replaces OpenShift Routes for new workloads)<br>- kube-auth-proxy authentication (replaces oauth-proxy)<br>- HTTPRoute + kube-rbac-proxy sidecar pattern for component ingress<br>- EnvoyFilter ext_authz integration for Service Mesh<br>- Support for OIDC authentication (ROSA compatibility)<br>- GatewayConfig, Auth, Monitoring service CRDs introduced<br>- Component CRDs migrated to components.platform.opendatahub.io/v1alpha1<br>- DSCInitialization v2 API with immutable applicationsNamespace<br>- Enhanced monitoring with Prometheus federation |

## Notes

**RHOAI 3.x vs 2.x Architectural Changes**:
- **Ingress**: Gateway API (HTTPRoute) replaces OpenShift Routes for new components
- **Authentication**: kube-auth-proxy + EnvoyFilter ext_authz replaces oauth-proxy sidecars
- **Authorization**: kube-rbac-proxy sidecars for per-workload RBAC enforcement
- **OIDC Support**: Native OIDC provider support for ROSA and external identity providers
- **Service Mesh**: EnvoyFilter for centralized authentication at Gateway layer

**Deployment Architecture**:
- Single operator deployment (3 replicas for HA) manages entire RHOAI platform
- Components are deployed via kustomize manifests bundled in operator image (`/opt/manifests`)
- Konflux build system prefetches component manifests during operator image build
- Gateway infrastructure deployed in `openshift-ingress` namespace
- Component workloads deployed in `redhat-ods-applications` namespace (configurable via DSCI)
- Monitoring stack deployed in `redhat-ods-monitoring` namespace

**Security Posture**:
- Operator runs as non-root user (UID 1001) in restricted SCC
- All operator communications use TLS 1.2+ encryption
- Service mesh integration provides mTLS between services (optional)
- OAuth/OIDC session cookies are httpOnly, secure, and time-limited
- Webhook certificates auto-rotated by OpenShift cert injection
- Gateway TLS follows OpenShift default ingress certificate lifecycle

**Observability**:
- Operator exposes Prometheus metrics on port 8080/TCP
- All components monitored via ServiceMonitor CRs
- Metrics federated to OpenShift cluster monitoring
- PrometheusRules define platform and component-specific alerts
- Blackbox exporter provides endpoint availability monitoring
