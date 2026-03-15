# Component: ODH Notebook Controller

## Metadata
- **Repository**: https://github.com/red-hat-data-services/kubeflow.git
- **Version**: v1.27.0-rhods-244-g31e7ced9
- **Branch**: rhoai-2.7
- **Distribution**: RHOAI
- **Languages**: Go 1.19
- **Deployment Type**: Kubernetes Operator (Controller + Webhook)

## Purpose
**Short**: Extends Kubeflow Notebook Controller with OpenShift-specific ingress and authentication capabilities.

**Detailed**:

The ODH (Open Data Hub) Notebook Controller is a Kubernetes operator that watches Kubeflow Notebook custom resources and extends the base Kubeflow notebook controller with OpenShift-native features. It automatically creates OpenShift Routes for external access with TLS edge termination, and optionally injects an OAuth proxy sidecar container to provide enterprise-grade authentication and authorization using OpenShift's built-in OAuth server.

When a Notebook resource is created, the controller reconciles the following OpenShift-specific resources: TLS Routes for ingress, ServiceAccounts with OAuth redirect annotations, Secrets for cookie authentication, ConfigMaps for proxy configuration, and NetworkPolicies for traffic control. The optional OAuth proxy integration (enabled via annotation) provides single sign-on authentication through OpenShift, with authorization delegated to Kubernetes RBAC via Subject Access Review (SAR) checks.

The controller uses a mutating webhook to inject the OAuth proxy sidecar and reconciliation lock annotations during notebook creation, ensuring proper initialization order and preventing race conditions with service account token mounting.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| OpenshiftNotebookReconciler | Controller | Reconciles Notebook CRs to create OpenShift Routes, ServiceAccounts, Secrets, ConfigMaps, and NetworkPolicies |
| NotebookWebhook | Mutating Webhook | Injects OAuth proxy sidecar container and reconciliation lock annotation into Notebook pods |
| Manager | Deployment | Hosts the controller and webhook server with health/metrics endpoints |
| OAuth Proxy Sidecar | Container | Provides OpenShift OAuth authentication for notebook access (when enabled via annotation) |

## APIs Exposed

### Custom Resource Definitions (CRDs)

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| kubeflow.org | v1 | Notebook | Namespaced | External CRD (watched) - Defines Jupyter notebook deployments with OAuth integration |

**Note**: This controller watches the Notebook CRD but does not define it. The CRD is provided by the upstream Kubeflow Notebook Controller.

### HTTP Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /metrics | GET | 8080/TCP | HTTP | None | None | Prometheus metrics scraping |
| /healthz | GET | 8081/TCP | HTTP | None | None | Liveness probe endpoint |
| /readyz | GET | 8081/TCP | HTTP | None | None | Readiness probe endpoint |
| /mutate-notebook-v1 | POST | 8443/TCP | HTTPS | TLS 1.2+ | Kubernetes API | Mutating webhook for Notebook CR admission |
| /oauth/healthz | GET | 8443/TCP | HTTPS | TLS 1.2+ | None | OAuth proxy health check (in injected sidecar) |

### gRPC Services

None.

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| Kubeflow Notebook Controller | v1 | Yes | Provides Notebook CRD and base reconciliation logic |
| OpenShift Route API | route.openshift.io/v1 | Yes | Enables external ingress via OpenShift router |
| OpenShift Config API | config.openshift.io/v1 | No | Reads cluster-wide proxy configuration |
| OpenShift OAuth Proxy | registry.redhat.io/openshift4/ose-oauth-proxy | Yes | Provides OAuth authentication sidecar |
| Kubernetes Networking API | networking.k8s.io/v1 | Yes | Creates NetworkPolicy resources for traffic control |

### Internal ODH Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| Kubeflow Notebook Controller | CRD Watching | Watches Notebook CRs created by the base controller |
| OpenShift Service CA Operator | Certificate Annotation | Automatic TLS certificate provisioning for webhook service |

## Network Architecture

### Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| service | ClusterIP | 8080/TCP | 8080 | HTTP | None | None | Internal (metrics) |
| webhook-service | ClusterIP | 443/TCP | 8443 | HTTPS | TLS 1.2+ | Kubernetes API mTLS | Internal (API server) |

**Note**: The webhook service uses the annotation `service.beta.openshift.io/serving-cert-secret-name: odh-notebook-controller-webhook-cert` to automatically provision TLS certificates via OpenShift Service CA Operator.

### Ingress

| Name | Type | Hosts | Port | Protocol | Encryption | TLS Mode | Exposure |
|------|------|-------|------|----------|------------|----------|----------|
| {notebook-name} Route | OpenShift Route | Auto-assigned | 443/TCP | HTTPS | TLS 1.2+ | Edge | External |

**Notes**:
- Routes are created per-notebook with TLS edge termination
- Host is automatically assigned by OpenShift ingress controller
- InsecureEdgeTerminationPolicy: Redirect (HTTP -> HTTPS)
- Routes target the notebook Service on port `http-{notebook-name}`

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token | Controller operations (watch, create, update resources) |
| OpenShift OAuth Server | 443/TCP | HTTPS | TLS 1.2+ | mTLS | OAuth proxy authentication (when enabled) |

## Security

### RBAC - Cluster Roles

| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|
| manager-role | kubeflow.org | notebooks, notebooks/status, notebooks/finalizers | get, list, watch, patch, update |
| manager-role | route.openshift.io | routes | get, list, watch, create, update, patch |
| manager-role | "" (core) | services, serviceaccounts, secrets, configmaps | get, list, watch, create, update, patch |
| manager-role | networking.k8s.io | networkpolicies | get, list, watch, create, update, patch |
| manager-role | config.openshift.io | proxies | get, list, watch |
| leader-election-role | "" (core) | configmaps, events | get, list, watch, create, update, patch, delete |
| leader-election-role | coordination.k8s.io | leases | get, list, watch, create, update, patch, delete |
| notebooks-admin | kubeflow.org | notebooks, notebooks/status | Aggregated from notebooks-edit |
| notebooks-edit | kubeflow.org | notebooks, notebooks/status | get, list, watch, create, delete, deletecollection, patch, update |
| notebooks-view | kubeflow.org | notebooks, notebooks/status | get, list, watch |

### RBAC - Role Bindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| manager-rolebinding | Cluster-wide | manager-role (ClusterRole) | manager (in controller namespace) |
| leader-election-rolebinding | Controller namespace | leader-election-role (Role) | controller-manager (in controller namespace) |

**Note**: User-facing roles (notebooks-admin, notebooks-edit, notebooks-view) aggregate to standard Kubernetes roles (admin, edit, view) via RBAC aggregation labels.

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| odh-notebook-controller-webhook-cert | kubernetes.io/tls | Webhook server TLS certificate | OpenShift Service CA | Yes |
| {notebook-name}-oauth-config | Opaque | OAuth proxy cookie secret (base64 random) | ODH Notebook Controller | No |
| {notebook-name}-tls | kubernetes.io/tls | OAuth proxy TLS certificates | OpenShift Service CA | Yes |

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| /mutate-notebook-v1 | POST | Kubernetes API mTLS | Kubernetes API Server | API server validates webhook certificates |
| Notebook (via OAuth) | GET, POST | OpenShift OAuth + Bearer Token | OAuth Proxy Sidecar | Subject Access Review (SAR): `GET notebooks/{name}` permission |
| Notebook (direct) | GET, POST | None | N/A | No authentication when OAuth not enabled |

**OAuth Authorization Details**:
- OAuth proxy uses `--openshift-sar` flag to delegate authorization to Kubernetes RBAC
- Users must have `get` permission on the specific notebook resource in the namespace
- Authorization check: `{"verb":"get","resource":"notebooks","resourceAPIGroup":"kubeflow.org","resourceName":"{notebook-name}","namespace":"{namespace}"}`

## Data Flows

### Flow 1: Notebook Creation with OAuth

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Kubernetes API | ODH Notebook Controller Webhook | 8443/TCP | HTTPS | TLS 1.2+ | API mTLS |
| 2 | ODH Notebook Controller | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 3 | ODH Notebook Controller | Notebook ServiceAccount | N/A | N/A | N/A | Owner Reference |
| 4 | ODH Notebook Controller | OAuth ConfigMap/Secret | N/A | N/A | N/A | Owner Reference |
| 5 | ODH Notebook Controller | NetworkPolicy | N/A | N/A | N/A | Owner Reference |
| 6 | ODH Notebook Controller | OpenShift Route | N/A | N/A | N/A | Owner Reference |

### Flow 2: User Access to Notebook (OAuth Enabled)

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User Browser | OpenShift Router | 443/TCP | HTTPS | TLS 1.2+ | None |
| 2 | OpenShift Router | OAuth Proxy (Notebook Pod) | 8443/TCP | HTTPS | TLS 1.2+ | Route Host |
| 3 | OAuth Proxy | OpenShift OAuth Server | 443/TCP | HTTPS | TLS 1.2+ | mTLS |
| 4 | OAuth Proxy | Kubernetes API (SAR) | 6443/TCP | HTTPS | TLS 1.2+ | User Token |
| 5 | OAuth Proxy | Notebook Container (localhost) | 8888/TCP | HTTP | None | Localhost |

### Flow 3: Network Policy Enforcement

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Controller Namespace Pods | Notebook Pod | 8888/TCP | TCP | Varies | NetworkPolicy Allow |
| 2 | Any Source | Notebook Pod (OAuth Port) | 8443/TCP | TCP | TLS 1.2+ | NetworkPolicy Allow |

**Note**: Two NetworkPolicies are created:
- `{notebook-name}-ctrl-np`: Allows ingress to port 8888 from controller namespace only
- `{notebook-name}-oauth-np`: Allows ingress to port 8443 from any source (for external access)

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| Kubeflow Notebook Controller | CRD Watch | 6443/TCP | HTTPS | TLS 1.2+ | Watches Notebook CRs created by upstream controller |
| OpenShift Ingress Controller | Route Management | N/A | N/A | N/A | Automatically provisions external URLs for Routes |
| OpenShift Service CA | Certificate Injection | N/A | N/A | N/A | Provisions TLS certificates via service annotation |
| OpenShift OAuth Server | OAuth Flow | 443/TCP | HTTPS | TLS 1.2+ | Authenticates users accessing notebooks |
| Kubernetes API Server | Subject Access Review | 6443/TCP | HTTPS | TLS 1.2+ | Authorizes user access to notebooks |

## Recent Changes

| Version | Date | Changes |
|---------|------|---------|
| v1.27.0-rhods-244 | 2026-03 | - Merge pull request #39 from opendatahub-io/stable<br>- Bump controller-runtime version<br>- Adjust go mod download for Go 1.19 |
| v1.27.0-rhods-242 | 2026-02 | - Set notebook container env var SSL_CERT_FILE to point to optional proxy CA trust bundle<br>- Point default patch image to stable tag |
| v1.27.0-rhods-234 | 2026-01 | - Fix: patch images of notebook-controller in components<br>- Upgrade Golang version and indirect dependencies (net, grpc) for CVE fixes |
| v1.27.0 | 2025-12 | - Update manifests to commit 9f0db5d<br>- Adjust manifests based on RHODS odh-manifests |

## Deployment Configuration

**Kustomize Base**: `components/odh-notebook-controller/config`

**Key Deployment Parameters**:
- Replicas: 1
- Rolling Update Strategy: maxUnavailable=100%, maxSurge=0
- Security Context: runAsNonRoot=true, allowPrivilegeEscalation=false
- Resource Requests: CPU=500m, Memory=256Mi
- Resource Limits: CPU=500m, Memory=4Gi
- Webhook Port: 8443 (configurable via `--webhook-port` flag)
- OAuth Proxy Image: registry.redhat.io/openshift4/ose-oauth-proxy@sha256:4bef31eb... (configurable via `--oauth-proxy-image` flag)

**Leader Election**: Disabled by default, can be enabled via `--leader-elect` flag

**Annotations**:
- `notebooks.opendatahub.io/inject-oauth`: Set to "true" on Notebook CR to enable OAuth proxy injection
- `notebooks.opendatahub.io/oauth-logout-url`: Custom logout URL for OAuth proxy
- `kubeflow.org/last-applied-configuration`: Reconciliation lock annotation value

## Container Image

**Base Image**: gcr.io/distroless/base:debug
**Build Context**: `${KUBEFLOW_REPO}/components`
**Dockerfile**: `components/odh-notebook-controller/Dockerfile`
**Build Args**: GOLANG_VERSION=1.19
**Architecture Support**: amd64, arm64

## Known Limitations

1. **Single Replica**: Currently deployed with 1 replica; leader election is disabled by default
2. **Reconciliation Lock**: Uses culler stop annotation as a lock mechanism, which may conflict with actual culling operations
3. **Namespace Discovery**: Controller namespace is read from service account token file, no explicit configuration
4. **OAuth Proxy Image**: Hardcoded in deployment args, requires manifest change to update
5. **Certificate Management**: Depends on OpenShift Service CA Operator for automatic certificate provisioning

## Security Considerations

- **Webhook TLS**: Certificates automatically provisioned by OpenShift Service CA with rotation support
- **OAuth Proxy Security**: Uses TLS 1.2+ with HTTPS-only listeners, 24-hour cookie expiration
- **Service Account Isolation**: Each notebook gets its own ServiceAccount with OAuth redirect annotations
- **Network Segmentation**: NetworkPolicies restrict notebook port access to controller namespace only
- **Authorization**: Uses Kubernetes RBAC via Subject Access Review for fine-grained access control
- **Secret Management**: Cookie secrets generated with cryptographically secure random bytes (base64-encoded 32 bytes)
