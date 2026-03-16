# Component: ODH Notebook Controller

## Metadata
- **Repository**: https://github.com/red-hat-data-services/kubeflow
- **Version**: v1.27.0-rhods-319-gdfd14280
- **Branch**: rhoai-2.8
- **Distribution**: RHOAI
- **Languages**: Go 1.19
- **Deployment Type**: Kubernetes Operator (Kubebuilder-based)
- **Component Path**: components/odh-notebook-controller
- **Manifests Location**: components/odh-notebook-controller/config

## Purpose
**Short**: Extends Kubeflow Notebook Controller with OpenShift-specific features including ingress integration and OAuth-based authentication/authorization.

**Detailed**:
The ODH Notebook Controller is a Kubernetes operator that watches Kubeflow Notebook custom resources and extends the base Kubeflow notebook controller functionality with OpenShift-specific capabilities. It automatically creates OpenShift Routes for external access to notebooks with TLS termination, and optionally injects an OAuth proxy sidecar container when the `notebooks.opendatahub.io/inject-oauth` annotation is set to true. This OAuth proxy provides authentication via OpenShift's identity provider and authorization through Kubernetes RBAC, requiring users to have GET permissions on the notebook resource to access it. The controller also manages network policies to control traffic flow, creates service accounts with OAuth redirect references, and manages TLS certificates and secrets required for secure notebook access.

The controller is built using Kubebuilder and operates as a standard Kubernetes controller with a mutating webhook that intercepts Notebook CR create/update operations to inject the OAuth sidecar and related configuration before the notebook pod is created.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| OpenshiftNotebookReconciler | Controller | Main reconciliation loop for Notebook CRs; manages Routes, Services, Secrets, ConfigMaps, and NetworkPolicies |
| NotebookWebhook | Mutating Webhook | Intercepts Notebook CR create/update operations to inject OAuth proxy sidecar and reconciliation lock annotation |
| OAuth Proxy Sidecar | Container | Provides OpenShift OAuth authentication and RBAC-based authorization for notebook access |
| Manager Deployment | Deployment | Runs the controller manager pod with metrics, health probes, and webhook server |
| Webhook Service | Service | Exposes webhook endpoint for Kubernetes API server to call |
| Metrics Service | Service | Exposes Prometheus metrics endpoint |

## APIs Exposed

### Custom Resource Definitions (CRDs)

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| kubeflow.org | v1 | Notebook | Namespaced | Watched CRD (defined by upstream Kubeflow); represents a Jupyter notebook instance with pod template spec |

**Note**: This controller does not define CRDs but watches the Notebook CRD from the Kubeflow notebook-controller project.

### Mutating Webhooks

| Webhook Name | Path | Operations | Resources | Purpose |
|--------------|------|------------|-----------|---------|
| notebooks.opendatahub.io | /mutate-notebook-v1 | CREATE, UPDATE | notebooks.kubeflow.org/v1 | Injects OAuth proxy sidecar container, volumes, and reconciliation lock annotation when `notebooks.opendatahub.io/inject-oauth` annotation is true |

### HTTP Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /metrics | GET | 8080/TCP | HTTP | None | None | Prometheus metrics endpoint for controller monitoring |
| /healthz | GET | 8081/TCP | HTTP | None | None | Liveness probe endpoint |
| /readyz | GET | 8081/TCP | HTTP | None | None | Readiness probe endpoint |
| /mutate-notebook-v1 | POST | 8443/TCP | HTTPS | TLS 1.2+ | Kubernetes API server client cert | Mutating webhook admission endpoint |

### OAuth Proxy Endpoints (Injected Sidecar)

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /oauth/healthz | GET | 8443/TCP | HTTPS | TLS (service-serving cert) | None | OAuth proxy health check |
| /* | ALL | 8443/TCP | HTTPS | TLS (service-serving cert) | OpenShift OAuth + RBAC | Proxies requests to notebook after authentication/authorization |

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| Kubeflow Notebook Controller | v0.0.0-20220728153354 | Yes | Manages base Notebook CR lifecycle; creates StatefulSet for notebook pods |
| OpenShift Route API | route.openshift.io/v1 | Yes | Creates Routes for external ingress to notebooks |
| OpenShift Config API | config.openshift.io/v1 | Yes | Reads cluster-wide proxy configuration |
| OpenShift OAuth Proxy | registry.redhat.io/openshift4/ose-oauth-proxy | Yes (when OAuth enabled) | Sidecar container providing authentication/authorization |
| OpenShift Service CA Operator | N/A | Yes | Provisions TLS certificates for webhook service via service.beta.openshift.io/serving-cert-secret-name annotation |
| Kubernetes API | v1.22+ | Yes | Core API for managing resources |

### Internal ODH/RHOAI Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| Kubeflow Notebook Controller | Watches same CRD | Base controller creates StatefulSet; ODH controller adds OpenShift integrations |
| ODH Dashboard | Uses Notebook CRs | Creates Notebook resources that trigger this controller |
| ODH Operator | Deploys controller | Manages deployment and configuration of this controller |

## Network Architecture

### Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| odh-notebook-controller-service | ClusterIP | 8080/TCP | 8080 | HTTP | None | None | Internal (metrics) |
| odh-notebook-controller-webhook-service | ClusterIP | 443/TCP | 8443 | HTTPS | TLS 1.2+ (service-serving cert) | Kubernetes API server client cert | Internal (webhook) |
| {notebook-name} (OAuth) | ClusterIP | 443/TCP | 8443 | HTTPS | TLS 1.2+ (service-serving cert) | OAuth + RBAC | Internal (created per notebook when OAuth enabled) |
| {notebook-name} (base) | ClusterIP | 80/TCP | 8888 | HTTP | None | None | Internal (created by Kubeflow notebook controller) |

### Ingress

| Name | Type | Hosts | Port | Protocol | Encryption | TLS Mode | Exposure |
|------|------|-------|------|----------|------------|----------|----------|
| {notebook-name} | OpenShift Route | Auto-assigned by cluster | 443/TCP | HTTPS | TLS 1.2+ | Edge Termination | External |

**Route Configuration:**
- TLS Termination: Edge
- Insecure Traffic: Redirected to HTTPS
- Target Service: {notebook-name} (OAuth service when OAuth enabled, base service otherwise)
- Target Port: oauth-proxy (8443) when OAuth enabled, http-{notebook-name} (8888) otherwise

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | Service Account Token | Controller operations, RBAC checks |
| OpenShift OAuth Server | 6443/TCP | HTTPS | TLS 1.2+ | OAuth token exchange | OAuth proxy authentication flow |
| Container Registries (quay.io, registry.redhat.io) | 443/TCP | HTTPS | TLS 1.2+ | Pull secrets | Pull notebook and OAuth proxy images |

### Network Policies

| Policy Name | Scope | Ingress Rules | Purpose |
|-------------|-------|---------------|---------|
| {notebook-name}-ctrl-np | Notebook pods | Allow TCP/8888 from controller namespace | Allow Kubeflow controller to access notebook for health checks |
| {notebook-name}-oauth-np | Notebook pods | Allow TCP/8443 from all | Allow external traffic to OAuth proxy port |

## Security

### RBAC - Cluster Roles

| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|
| odh-notebook-controller-manager-role | "" | configmaps, secrets, serviceaccounts, services | create, get, list, patch, update, watch |
| odh-notebook-controller-manager-role | config.openshift.io | proxies | get, list, watch |
| odh-notebook-controller-manager-role | kubeflow.org | notebooks | get, list, patch, watch |
| odh-notebook-controller-manager-role | kubeflow.org | notebooks/finalizers | update |
| odh-notebook-controller-manager-role | kubeflow.org | notebooks/status | get |
| odh-notebook-controller-manager-role | networking.k8s.io | networkpolicies | create, get, list, patch, update, watch |
| odh-notebook-controller-manager-role | route.openshift.io | routes | create, get, list, patch, update, watch |
| notebooks-admin | kubeflow.org | notebooks, notebooks/status | Aggregated from notebooks-edit | User-facing role for notebook administrators |
| notebooks-edit | kubeflow.org | notebooks, notebooks/status | get, list, watch, create, delete, deletecollection, patch, update | User-facing role for notebook editors (aggregates to edit) |
| notebooks-view | kubeflow.org | notebooks, notebooks/status | get, list, watch | User-facing role for notebook viewers (aggregates to view) |
| odh-notebook-controller-leader-election-role | "" | configmaps | get, list, watch, create, update, patch, delete |
| odh-notebook-controller-leader-election-role | coordination.k8s.io | leases | get, list, watch, create, update, patch, delete |
| odh-notebook-controller-leader-election-role | "" | events | create, patch |

### RBAC - Role Bindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| odh-notebook-controller-manager-rolebinding | Cluster-wide | manager-role (ClusterRole) | odh-notebook-controller-manager (system namespace) |
| odh-notebook-controller-leader-election-rolebinding | system namespace | leader-election-role (Role) | odh-notebook-controller-manager (system namespace) |

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| odh-notebook-controller-webhook-cert | kubernetes.io/tls | TLS certificate for webhook server | OpenShift service-ca operator | Yes |
| {notebook-name}-oauth-config | Opaque | Contains cookie secret for OAuth proxy session encryption | ODH Notebook Controller | No |
| {notebook-name}-tls | kubernetes.io/tls | TLS certificate for OAuth proxy (when OAuth enabled) | OpenShift service-ca operator | Yes |

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| /mutate-notebook-v1 | POST | Kubernetes API server mTLS client cert | Kubernetes API server | Only API server can call webhook |
| /metrics | GET | None | None | Internal cluster access only via ClusterIP |
| /healthz, /readyz | GET | None | None | Used by kubelet for pod health checks |
| Notebook (via Route, OAuth enabled) | ALL | OpenShift OAuth + OpenShift SAR check | OAuth Proxy | User must authenticate with OpenShift and have GET permission on notebook CR |
| Notebook (via Route, OAuth disabled) | ALL | None | None | Unauthenticated access (application-level auth recommended) |

**OAuth SAR Check Details**:
```json
{
  "verb": "get",
  "resource": "notebooks",
  "resourceAPIGroup": "kubeflow.org",
  "resourceName": "{notebook-name}",
  "namespace": "{notebook-namespace}"
}
```

### ConfigMaps

| ConfigMap Name | Purpose | Created By | Contents |
|----------------|---------|------------|----------|
| {notebook-name}-trusted-ca-bundle | Provides trusted CA certificates to notebook pods | ODH Notebook Controller | Aggregates certificates from odh-trusted-ca-bundle and kube-root-ca.crt |

## Data Flows

### Flow 1: Notebook Creation with OAuth

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User/Dashboard | Kubernetes API | 6443/TCP | HTTPS | TLS 1.3 | Bearer Token |
| 2 | Kubernetes API | Webhook Service | 443/TCP | HTTPS | TLS 1.2+ | mTLS |
| 3 | NotebookWebhook | Kubernetes API | 6443/TCP | HTTPS | TLS 1.3 | Service Account Token |
| 4 | OpenshiftNotebookReconciler | Kubernetes API | 6443/TCP | HTTPS | TLS 1.3 | Service Account Token |
| 5 | Kubeflow Notebook Controller | Kubernetes API | 6443/TCP | HTTPS | TLS 1.3 | Service Account Token |

**Step Details:**
1. User creates Notebook CR via Dashboard/CLI
2. Kubernetes API calls mutating webhook with AdmissionReview containing Notebook CR
3. Webhook injects OAuth sidecar and returns mutated CR to API server
4. ODH controller reconciles: creates ServiceAccount, Secret, Service, Route, NetworkPolicies, ConfigMap
5. Kubeflow controller creates StatefulSet with injected OAuth sidecar

### Flow 2: Notebook Access (OAuth Enabled)

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User Browser | OpenShift Router | 443/TCP | HTTPS | TLS 1.3 | None |
| 2 | OpenShift Router | OAuth Proxy Sidecar | 8443/TCP | HTTPS | TLS 1.2+ | None |
| 3 | OAuth Proxy | OpenShift OAuth Server | 6443/TCP | HTTPS | TLS 1.3 | OAuth flow |
| 4 | OAuth Proxy | Kubernetes API (SAR) | 6443/TCP | HTTPS | TLS 1.3 | User token |
| 5 | OAuth Proxy | Notebook Container | 8888/TCP | HTTP | None | None |
| 6 | Notebook Container | OAuth Proxy | 8888/TCP | HTTP | None | None |
| 7 | OAuth Proxy | OpenShift Router | 8443/TCP | HTTPS | TLS 1.2+ | None |
| 8 | OpenShift Router | User Browser | 443/TCP | HTTPS | TLS 1.3 | None |

**Step Details:**
1. User navigates to notebook Route URL
2. Router terminates TLS and forwards to OAuth proxy service
3. OAuth proxy redirects unauthenticated users to OpenShift OAuth login
4. After authentication, proxy performs SubjectAccessReview to verify user has GET permission on notebook
5. Authorized requests are proxied to Jupyter notebook on port 8888
6-8. Response flows back through OAuth proxy and router to user

### Flow 3: Controller Reconciliation

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | OpenshiftNotebookReconciler | Kubernetes API (watch) | 6443/TCP | HTTPS | TLS 1.3 | Service Account Token |
| 2 | Kubernetes API | OpenshiftNotebookReconciler | 6443/TCP | HTTPS | TLS 1.3 | Service Account Token |
| 3 | OpenshiftNotebookReconciler | Kubernetes API | 6443/TCP | HTTPS | TLS 1.3 | Service Account Token |
| 4 | OpenshiftNotebookReconciler | Kubernetes API | 6443/TCP | HTTPS | TLS 1.3 | Service Account Token |

**Step Details:**
1. Controller establishes watch on Notebook CRs
2. Notebook event (create/update/delete) triggers reconciliation
3. Controller creates/updates Route, Service, Secret, NetworkPolicy, ConfigMap, ServiceAccount
4. Controller patches Notebook CR to remove reconciliation lock annotation

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| Kubernetes API Server | REST API | 6443/TCP | HTTPS | TLS 1.3 | Watch Notebook CRs, create/update resources |
| OpenShift Route API | REST API | 6443/TCP | HTTPS | TLS 1.3 | Create/manage Routes for notebook ingress |
| OpenShift OAuth Server | OAuth 2.0 | 6443/TCP | HTTPS | TLS 1.3 | Authenticate users accessing notebooks |
| Kubeflow Notebook Controller | Shared CRD watch | 6443/TCP | HTTPS | TLS 1.3 | Complementary controllers on same Notebook CR |
| Prometheus | Metrics scrape | 8080/TCP | HTTP | None | Scrape /metrics endpoint for monitoring |
| OpenShift Service CA | Certificate injection | N/A | N/A | N/A | Auto-provision TLS certs via annotations |

## Recent Changes

| Version | Date | Changes |
|---------|------|---------|
| v1.27.0-rhods-319 | 2025-09-01 | - Update Konflux build references<br>- Update UBI8 base image digest to 43dde01 |
| v1.27.0-rhods-318 | 2025-09-01 | - Update Konflux build references |
| v1.27.0-rhods-317 | 2025-08-26 | - Update UBI8 minimal base image digest |
| v1.27.0-rhods-316 | 2025-08-20 | - Update UBI8 minimal base image digest to 89f2c97 |
| v1.27.0-rhods-315 | 2025-08-14 | - Update UBI8 minimal base image digest to 395dec1 |
| v1.27.0-rhods-314 | 2025-08-01 | - Update Konflux references |
| v1.27.0-rhods-313 | 2025-07-31 | - Update UBI8 minimal base image digest to af9b4a2 |
| v1.27.0-rhods-312 | 2025-07-29 | - Update UBI8 minimal base image digest to 7957d61 |
| v1.27.0-rhods-311 | 2025-07-28 | - Update UBI8 minimal base image digest to 8075621 |
| v1.27.0-rhods-310 | 2025-07-15 | - Update UBI8 minimal base image digest to 5b195cf |

**Recent Activity Summary**: The repository has been primarily focused on dependency updates, particularly updating base container images (UBI8) and Konflux build system references. This indicates active maintenance and security patching of the container infrastructure. No major feature changes or bug fixes are evident in the recent commit history, suggesting a stable maintenance phase.
