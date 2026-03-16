# Component: ODH Notebook Controller

## Metadata
- **Repository**: https://github.com/red-hat-data-services/kubeflow
- **Component Path**: components/odh-notebook-controller
- **Version**: v1.27.0-rhods-873-g72911b74 (rhoai-2.17 branch)
- **Distribution**: RHOAI
- **Languages**: Go (1.21)
- **Deployment Type**: Kubernetes Operator (Controller + Mutating Webhook)

## Purpose
**Short**: Extends Kubeflow Notebook controller with OpenShift-specific capabilities including OAuth proxy injection, route management, and network policy enforcement.

**Detailed**:
The ODH Notebook Controller is a Kubernetes operator that watches Kubeflow Notebook custom resources and extends their functionality with OpenShift-specific integrations. It automatically creates TLS-enabled Routes for notebook ingress exposure, injects OAuth proxy sidecars for authentication and authorization when requested via annotations, and manages network policies to control traffic flow. The controller ensures notebooks are properly integrated with OpenShift's security model by delegating authentication to OpenShift OAuth and authorization to Kubernetes RBAC through SubjectAccessReview checks.

The controller implements a mutating admission webhook that modifies notebook pod specifications during creation and update operations, injecting OAuth proxy containers, mounting TLS certificates, and configuring service accounts. It also manages the complete lifecycle of supporting resources including Services, ServiceAccounts, Secrets, ConfigMaps, NetworkPolicies, Roles, and RoleBindings that are required for OAuth proxy operation and pipeline integration.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| OpenshiftNotebookReconciler | Controller | Reconciles Notebook resources and manages OpenShift-specific resources (Routes, Services, NetworkPolicies, RBAC) |
| NotebookWebhook | Mutating Admission Webhook | Intercepts Notebook CREATE/UPDATE operations to inject OAuth proxy sidecar and modify pod spec |
| Metrics Server | HTTP Service | Exposes Prometheus metrics on port 8080 for monitoring controller operations |
| Health/Readiness Probes | HTTP Endpoints | Provides /healthz and /readyz endpoints on port 8081 for Kubernetes liveness/readiness checks |
| Webhook Server | HTTPS Service | Serves mutating webhook on port 8443 with TLS encryption for API server callbacks |

## APIs Exposed

### Custom Resource Definitions (CRDs)

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| kubeflow.org | v1 | Notebook | Namespaced | Defines Jupyter notebook instances with container specs, OAuth injection settings, and service mesh configuration |

**Note**: The CRD is owned by the Kubeflow notebook-controller component. ODH Notebook Controller watches this CRD but does not define it.

### HTTP Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /mutate-notebook-v1 | POST | 8443/TCP | HTTPS | TLS 1.2+ | mTLS (API server client cert) | Mutating webhook for Notebook resources - injects OAuth proxy sidecar |
| /metrics | GET | 8080/TCP | HTTP | None | None | Prometheus metrics endpoint for controller operations monitoring |
| /healthz | GET | 8081/TCP | HTTP | None | None | Liveness probe endpoint - indicates controller process health |
| /readyz | GET | 8081/TCP | HTTP | None | None | Readiness probe endpoint - indicates controller is ready to serve requests |

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| Kubeflow Notebook Controller | v0.0.0-20220728153354-fc09bd1eefb8 | Yes | Defines Notebook CRD and primary reconciliation logic for notebook StatefulSets |
| OpenShift Route API | route.openshift.io/v1 | Yes | Provides Route resources for external ingress to notebooks |
| OpenShift OAuth Proxy | registry.redhat.io/openshift4/ose-oauth-proxy:v4.14 | Yes | Sidecar container for authentication/authorization when notebooks.opendatahub.io/inject-oauth=true |
| OpenShift Config API | config.openshift.io/v1 | Yes | Accesses cluster-wide proxy configuration for notebook environments |
| OpenShift Service CA | service.beta.openshift.io/serving-cert | Yes | Automatic TLS certificate provisioning for webhook and OAuth services |
| Kubernetes API | v1.29.0 | Yes | Core Kubernetes resources (Services, Secrets, ServiceAccounts, ConfigMaps) |
| Kubernetes Networking API | networking.k8s.io/v1 | Yes | NetworkPolicy resources for pod-level network segmentation |
| Kubernetes RBAC API | rbac.authorization.k8s.io/v1 | Yes | Roles and RoleBindings for notebook service account permissions |
| controller-runtime | v0.17.0 | Yes | Kubernetes controller framework for reconciliation loops and webhooks |

### Internal ODH Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| Data Science Pipelines (DSPA) | RBAC (Optional) | Creates RoleBinding to ds-pipeline-user-access-dspa Role if it exists in notebook namespace for Elyra pipeline execution |
| Kubeflow Notebook Controller | CRD Watch | Primary controller that creates/manages Notebook StatefulSets; ODH controller extends with OpenShift features |

## Network Architecture

### Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| odh-notebook-controller-metrics (manager service) | ClusterIP | 8080/TCP | 8080 (metrics) | HTTP | None | None | Internal (Prometheus scraping) |
| odh-notebook-controller-webhook-service | ClusterIP | 443/TCP | 8443 (webhook) | HTTPS | TLS 1.2+ (service.beta.openshift.io/serving-cert-secret-name) | mTLS (API server client cert) | Internal (Kubernetes API server only) |
| {notebook-name}-tls | ClusterIP | 443/TCP | 8443 (oauth-proxy) | HTTPS | TLS 1.2+ (service.beta.openshift.io/serving-cert-secret-name) | Bearer Token (OAuth) | Internal (via Route) |

**Note**: Per-notebook services are created dynamically by the controller for each Notebook resource when OAuth injection is enabled.

### Ingress

| Name | Type | Hosts | Port | Protocol | Encryption | TLS Mode | Exposure |
|------|------|-------|------|----------|------------|----------|----------|
| {notebook-name} | OpenShift Route (Edge TLS) | Auto-assigned by cluster ingress | 443/TCP | HTTPS | TLS 1.2+ | Edge Termination | External (via OpenShift Router) |

**Route Details**:
- **Termination**: Edge (TLS terminates at router, backend is HTTP or HTTPS)
- **Insecure Traffic**: Redirect to HTTPS
- **Target Service**: {notebook-name} (created by Kubeflow notebook controller) or {notebook-name}-tls (OAuth service)
- **Created For**: All Notebook resources to provide external access via OpenShift ingress controller

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| Kubernetes API Server | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token (in-cluster) | Controller operations: watch/create/update resources |
| OpenShift OAuth Server | 443/TCP | HTTPS | TLS 1.2+ | OAuth Token | OAuth proxy authentication flow when notebooks.opendatahub.io/inject-oauth=true |
| Cluster Proxy (if configured) | 443/TCP | HTTPS | TLS 1.2+ | Varies | Propagate cluster-wide proxy settings to notebook environments via HTTP_PROXY/HTTPS_PROXY env vars |

## Security

### RBAC - Cluster Roles

| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|
| odh-notebook-controller-manager-role | kubeflow.org | notebooks, notebooks/status, notebooks/finalizers | get, list, watch, patch, update |
| odh-notebook-controller-manager-role | route.openshift.io | routes | get, list, watch, create, update, patch |
| odh-notebook-controller-manager-role | "" (core) | services, serviceaccounts, secrets, configmaps | get, list, watch, create, update, patch |
| odh-notebook-controller-manager-role | config.openshift.io | proxies | get, list, watch |
| odh-notebook-controller-manager-role | networking.k8s.io | networkpolicies | get, list, watch, create, update, patch |
| odh-notebook-controller-manager-role | rbac.authorization.k8s.io | roles, rolebindings | get, list, watch, create, update, patch, delete |
| notebooks-admin | kubeflow.org | notebooks, notebooks/status | Aggregated from notebooks-edit |
| notebooks-edit | kubeflow.org | notebooks, notebooks/status | get, list, watch, create, delete, deletecollection, patch, update |
| notebooks-view | kubeflow.org | notebooks, notebooks/status | get, list, watch |

### RBAC - Role Bindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| odh-notebook-controller-manager-rolebinding | Controller namespace | odh-notebook-controller-manager-role (ClusterRole) | odh-notebook-controller-manager |
| odh-notebook-controller-leader-election-rolebinding | Controller namespace | odh-notebook-controller-leader-election-role (Role) | odh-notebook-controller-manager |
| elyra-pipelines-{notebook-name} | Notebook namespace | ds-pipeline-user-access-dspa (Role) | {notebook-name} |

**Note**: Per-notebook RoleBindings are created dynamically for pipeline access if DSPA Role exists.

### RBAC - Roles (Namespace-scoped)

| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|
| odh-notebook-controller-leader-election-role | "" (core) | configmaps | get, list, watch, create, update, patch, delete |
| odh-notebook-controller-leader-election-role | coordination.k8s.io | leases | get, list, watch, create, update, patch, delete |
| odh-notebook-controller-leader-election-role | "" (core) | events | create, patch |

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| odh-notebook-controller-webhook-cert | kubernetes.io/tls | TLS certificate for mutating webhook server | OpenShift Service CA Operator (via annotation) | Yes (Service CA) |
| {notebook-name}-tls | kubernetes.io/tls | TLS certificate for OAuth proxy service | OpenShift Service CA Operator (via annotation) | Yes (Service CA) |
| {notebook-name}-oauth-config | Opaque | OAuth proxy cookie secret (base64-encoded random value) | ODH Notebook Controller | No |

**Note**: Per-notebook secrets are created dynamically for each Notebook with OAuth injection enabled.

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| /mutate-notebook-v1 | POST | mTLS (Kubernetes API server client certificate) | Kubernetes API Server | Only API server can call webhook |
| /metrics | GET | None | N/A | Internal cluster access only (ClusterIP service) |
| /healthz, /readyz | GET | None | N/A | Internal cluster access only (listening on localhost or cluster IP) |
| Notebook (via OAuth proxy) | ALL | OpenShift OAuth + SubjectAccessReview | OAuth Proxy Sidecar | User must have GET permission on Notebook resource (--openshift-sar flag) |
| Notebook (via Route, no OAuth) | ALL | None | N/A | Public access if no OAuth annotation |

**OAuth Proxy Authorization Details**:
```json
--openshift-sar={
  "verb": "get",
  "resource": "notebooks",
  "resourceAPIGroup": "kubeflow.org",
  "resourceName": "{notebook-name}",
  "namespace": "{notebook-namespace}"
}
```
Users can only access notebooks if they can execute: `oc get notebook {notebook-name} -n {namespace}`

### Network Policies

| Policy Name | Selector | Ingress Rules | Egress Rules | Purpose |
|-------------|----------|---------------|--------------|---------|
| {notebook-name}-ctrl-np | notebook-name={notebook-name} | Allow TCP/8888 from controller namespace (kubernetes.io/metadata.name label) | Not specified (default allow) | Restrict notebook port access to controller namespace only |
| {notebook-name}-oauth-np | notebook-name={notebook-name} | Allow TCP/8443 from anywhere | Not specified (default allow) | Allow OAuth proxy port access (created when OAuth injection enabled and service mesh disabled) |

**Note**: NetworkPolicies are created per-notebook. The ctrl-np allows notebook port access only from the controller's namespace, while oauth-np allows broader access to the OAuth proxy port.

## Data Flows

### Flow 1: OAuth Proxy Injection (Notebook Creation with Authentication)

| Step | Source | Destination | Port | Protocol | Encryption | Auth | Description |
|------|--------|-------------|------|----------|------------|------|-------------|
| 1 | User/System | Kubernetes API Server | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token | Create Notebook resource with annotation notebooks.opendatahub.io/inject-oauth=true |
| 2 | Kubernetes API Server | ODH Notebook Controller Webhook | 8443/TCP | HTTPS | TLS 1.2+ (mTLS) | API Server Client Cert | Send AdmissionReview request to /mutate-notebook-v1 |
| 3 | ODH Notebook Controller Webhook | Kubernetes API Server | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token | Return modified Notebook spec with OAuth proxy sidecar container injected |
| 4 | ODH Notebook Controller | Kubernetes API Server | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token | Create ServiceAccount with OAuth redirect annotation |
| 5 | ODH Notebook Controller | Kubernetes API Server | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token | Create Service ({notebook-name}-tls) with serving-cert annotation |
| 6 | Service CA Operator | Kubernetes API Server | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token | Create Secret ({notebook-name}-tls) with TLS certificate |
| 7 | ODH Notebook Controller | Kubernetes API Server | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token | Create Secret ({notebook-name}-oauth-config) with random cookie secret |
| 8 | ODH Notebook Controller | Kubernetes API Server | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token | Create Route for external access to OAuth service |
| 9 | ODH Notebook Controller | Kubernetes API Server | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token | Create NetworkPolicies ({notebook-name}-ctrl-np, {notebook-name}-oauth-np) |
| 10 | ODH Notebook Controller | Kubernetes API Server | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token | Create RoleBinding (elyra-pipelines-{notebook-name}) if DSPA Role exists |
| 11 | Kubeflow Notebook Controller | Kubernetes API Server | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token | Create StatefulSet with injected OAuth proxy sidecar |

### Flow 2: User Access to Notebook via OAuth (Runtime)

| Step | Source | Destination | Port | Protocol | Encryption | Auth | Description |
|------|--------|-------------|------|----------|------------|------|-------------|
| 1 | User Browser | OpenShift Router | 443/TCP | HTTPS | TLS 1.2+ (Edge) | None | HTTPS request to notebook Route URL |
| 2 | OpenShift Router | OAuth Proxy Sidecar | 8443/TCP | HTTPS | TLS 1.2+ | None | Forward to {notebook-name}-tls Service |
| 3 | OAuth Proxy Sidecar | OpenShift OAuth Server | 443/TCP | HTTPS | TLS 1.2+ | None | Redirect to OAuth login if no valid session |
| 4 | User Browser | OpenShift OAuth Server | 443/TCP | HTTPS | TLS 1.2+ | User Credentials | User authenticates with OpenShift credentials |
| 5 | OpenShift OAuth Server | OAuth Proxy Sidecar | 443/TCP | HTTPS | TLS 1.2+ | OAuth Token | Return OAuth token to proxy |
| 6 | OAuth Proxy Sidecar | Kubernetes API Server | 443/TCP | HTTPS | TLS 1.2+ | OAuth Token | Perform SubjectAccessReview check (can user GET notebook?) |
| 7 | Kubernetes API Server | OAuth Proxy Sidecar | 443/TCP | HTTPS | TLS 1.2+ | N/A | Return SAR result (allowed/denied) |
| 8 | OAuth Proxy Sidecar | Jupyter Notebook Container | 8888/TCP | HTTP | None | None | Proxy request to notebook if authorized |
| 9 | Jupyter Notebook Container | OAuth Proxy Sidecar | 8888/TCP | HTTP | None | None | Return response |
| 10 | OAuth Proxy Sidecar | User Browser | 8443/TCP→443/TCP | HTTPS | TLS 1.2+ (Edge) | Session Cookie | Return response through Route |

### Flow 3: Notebook Without OAuth (Direct Access)

| Step | Source | Destination | Port | Protocol | Encryption | Auth | Description |
|------|--------|-------------|------|----------|------------|------|-------------|
| 1 | User/System | Kubernetes API Server | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token | Create Notebook resource (no OAuth annotation or inject-oauth=false) |
| 2 | ODH Notebook Controller | Kubernetes API Server | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token | Create Route pointing to notebook Service (created by Kubeflow controller) |
| 3 | ODH Notebook Controller | Kubernetes API Server | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token | Create NetworkPolicy ({notebook-name}-ctrl-np) for notebook port |
| 4 | User Browser | OpenShift Router | 443/TCP | HTTPS | TLS 1.2+ (Edge) | None | Access notebook via Route (no authentication required) |
| 5 | OpenShift Router | Jupyter Notebook Container | 8888/TCP | HTTP | None | None | Forward to notebook Service |
| 6 | Jupyter Notebook Container | OpenShift Router | 8888/TCP | HTTP | None | None | Return response |
| 7 | OpenShift Router | User Browser | 443/TCP | HTTPS | TLS 1.2+ (Edge) | None | Return response |

### Flow 4: Controller Reconciliation Loop

| Step | Source | Destination | Port | Protocol | Encryption | Auth | Description |
|------|--------|-------------|------|----------|------------|------|-------------|
| 1 | Kubernetes API Server | ODH Notebook Controller | 443/TCP | HTTPS | TLS 1.2+ | N/A | Watch event for Notebook resource (create/update/delete) |
| 2 | ODH Notebook Controller | Kubernetes API Server | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token | Get Notebook resource details |
| 3 | ODH Notebook Controller | Kubernetes API Server | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token | Check if Route exists (GET) |
| 4 | ODH Notebook Controller | Kubernetes API Server | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token | Create/Update Route if needed |
| 5 | ODH Notebook Controller | Kubernetes API Server | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token | Check OAuth injection annotation |
| 6 | ODH Notebook Controller | Kubernetes API Server | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token | Create/Update OAuth resources if inject-oauth=true (ServiceAccount, Service, Secrets, NetworkPolicies, RoleBindings) |
| 7 | ODH Notebook Controller | Kubernetes API Server | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token | Update Notebook status/finalizers if needed |
| 8 | ODH Notebook Controller | Prometheus | Scrape 8080/TCP | HTTP | None | None | Expose metrics for monitoring |

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| Kubernetes API Server | gRPC/REST API Watch | 443/TCP | HTTPS | TLS 1.2+ | Watch Notebook resources, manage Routes, Services, Secrets, RBAC |
| Kubeflow Notebook Controller | CRD Co-management | N/A | N/A | N/A | Primary controller creates StatefulSet; ODH controller extends with OpenShift features via webhook mutation and resource creation |
| OpenShift Router/Ingress | Route API | N/A | N/A | N/A | Exposes notebooks externally via automatically created Routes with TLS edge termination |
| OpenShift OAuth Server | OAuth 2.0 | 443/TCP | HTTPS | TLS 1.2+ | User authentication for notebooks when inject-oauth=true annotation present |
| OpenShift Service CA Operator | Certificate Provisioning | N/A | N/A | N/A | Automatic TLS certificate generation for webhook and OAuth services via service annotations |
| Data Science Pipelines (DSPA) | RBAC Integration | N/A | N/A | N/A | Optional RoleBinding creation if ds-pipeline-user-access-dspa Role exists for Elyra pipeline execution from notebooks |
| Service Mesh (Istio) | Service Mesh Integration | Varies | mTLS | mTLS | When opendatahub.io/service-mesh=true annotation present, skips OAuth NetworkPolicy creation |
| Prometheus | Metrics Scraping | 8080/TCP | HTTP | None | Controller exposes Prometheus metrics for operational monitoring |

## Recent Changes

| Version/Commit | Date | Changes |
|----------------|------|---------|
| 60251675 | 2025-02-25 | - Update registry.access.redhat.com/ubi8/ubi-minimal docker digest to c38cc77 |
| bf818e00 | 2025-02-10 | - Add repo ids to cpe mapping |
| a8ac2847 | 2025-02-10 | - Add repo ids to cpe mapping |
| 74009b78 | 2025-01-29 | - Update registry.access.redhat.com/ubi8/ubi-minimal docker digest to d16d444 |
| a37a5f2f | 2025-01-15 | - Update odh and notebook-controller with image 1.9-84946ca |
| df023d25 | 2025-01-14 | - Bump golang.org/x/net dependency for security |
| d4a5d8e8 | 2025-01-09 | - Update registry.access.redhat.com/ubi8/ubi-minimal docker digest to cf095e5 |
| aaf8d50b | 2024-12-19 | - Update odh and notebook-controller with image 1.9-58ee8e2 |
| 7c198800 | 2024-12-18 | - Update odh and notebook-controller with image 1.9-521f441 |
| 0ed59041 | 2024-12-10 | - Integration of Codecov coverage reporting for odh-notebook-controller tests |
| b4615772 | 2024-12-04 | - Manual sync to bring rhds into alignment with odh v1.9 |
| 3131949e | 2024-11-28 | - Update odh and notebook-controller with image 1.9-cae23d6 |
| dbc530e8 | 2024-11-28 | - Update v1.9-branch image tags |
| fc5ffd48 | 2024-11-27 | - Fix failing E2E tests (RHOAIENG-15141) |
| bb2dd26f | 2024-11-27 | - Search for imagestreams only in controller namespace (RHOAIENG-8390) |
| f1be2a4b | 2024-11-25 | - Set main tag to `main` to avoid digest updater updates (RHOAIENG-15748) |
| 92949272 | 2024-11-25 | - Update bash scripts for E2E tests to propagate failures |
| 30afc157 | 2024-11-21 | - Output struct diffs in gomega failure messages for better test debugging (RHOAIENG-15772) |
| b4646e7d | 2024-11-20 | - Write auditlogs from envtest tests to disk upon request (RHOAIENG-15772) |
| ed444be1 | 2024-11-19 | - Write envtest kubeconfig to disk upon request for debugging (RHOAIENG-15772) |

## Additional Notes

### Deployment Configuration
- **Namespace**: Typically deployed in the same namespace as the Kubeflow notebook controller (e.g., `redhat-ods-applications` or `opendatahub`)
- **Replicas**: 1 (leader election enabled for HA readiness)
- **Update Strategy**: RollingUpdate with maxSurge=0, maxUnavailable=100% (full replacement)
- **Security Context**: Runs as non-root (UID 1001), no privilege escalation allowed
- **Resource Limits**: CPU 500m, Memory 4Gi
- **Resource Requests**: CPU 500m, Memory 256Mi

### Build Configuration
- **Build Tool**: Go 1.21.9 with Kubebuilder framework
- **Container Base**: UBI8 minimal image
- **Build Mode**: CGO_ENABLED=1 with strictfipsruntime tags for FIPS compliance
- **Container Registry**: Built via Konflux CI/CD pipeline
- **Image Location**: registry.redhat.io/rhoai/odh-kf-notebook-controller-rhel8

### Key Annotations
- `notebooks.opendatahub.io/inject-oauth`: "true" | "false" - Controls OAuth proxy sidecar injection
- `opendatahub.io/service-mesh`: "true" | "false" - Indicates notebook is part of service mesh (disables OAuth NetworkPolicy creation)
- `notebooks.opendatahub.io/oauth-logout-url`: URL for custom logout redirect
- `kubeflow-resource-stopped`: "odh-notebook-controller-lock" - Prevents reconciliation during image pull secret mounting

### Controller Behavior
- **Watch Scope**: Cluster-wide watch on Notebook resources
- **Reconciliation Trigger**: Notebook CREATE, UPDATE, DELETE events
- **Owner References**: All created resources have ownerReference to parent Notebook for garbage collection
- **Finalizers**: Updates Notebook finalizers to ensure clean deletion
- **Conflict Handling**: Retries with exponential backoff on resource conflicts
- **Service Mesh Detection**: Skips OAuth NetworkPolicy creation when service mesh annotation is present

### OAuth Proxy Configuration
- **Image**: registry.redhat.io/openshift4/ose-oauth-proxy@sha256:4f8d66597feeb32bb18699326029f9a71a5aca4a57679d636b876377c2e95695 (v4.14, configurable via --oauth-proxy-image flag)
- **Port**: 8443 (HTTPS with TLS certificate from Service CA)
- **Cookie Secret**: Random 16-byte seed, base64-encoded twice
- **Authorization**: --openshift-sar flag with SubjectAccessReview for Notebook GET permission
- **TLS Certificate**: Automatically provisioned by OpenShift Service CA Operator
- **Session Storage**: Cookie-based (encrypted with cookie secret)
