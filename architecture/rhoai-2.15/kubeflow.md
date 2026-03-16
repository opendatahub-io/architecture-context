# Component: ODH Notebook Controller

## Metadata
- **Repository**: https://github.com/red-hat-data-services/kubeflow.git
- **Version**: v1.27.0-rhods-688-ge7061d29
- **Branch**: rhoai-2.15
- **Distribution**: RHOAI
- **Languages**: Go (Golang 1.21)
- **Deployment Type**: Kubernetes Controller/Operator
- **Framework**: Kubebuilder
- **Component Path**: components/odh-notebook-controller
- **Manifests Path**: components/odh-notebook-controller/config

## Purpose
**Short**: Extends Kubeflow Notebook Controller with OpenShift-native ingress and OAuth authentication capabilities.

**Detailed**: The ODH Notebook Controller is a Kubernetes controller that extends the functionality of the upstream Kubeflow Notebook Controller specifically for OpenShift and Red Hat OpenShift AI (RHOAI) environments. It watches Kubeflow Notebook custom resources and automatically creates OpenShift-specific resources to enable secure external access to notebooks. The controller integrates with OpenShift's ingress controller by creating TLS-enabled Routes and optionally injects an OAuth proxy sidecar container to provide authentication and authorization using OpenShift's built-in OAuth server. This enables users to access their Jupyter notebooks through OpenShift authentication while maintaining RBAC-based authorization controls.

The controller also manages network policies to control traffic flow, handles CA certificate bundle mounting for notebooks to trust custom certificates, and provides integration with OpenShift Service Mesh when configured. By automating the creation of routes, services, secrets, and network policies, the ODH Notebook Controller simplifies the deployment and management of secure, multi-tenant notebook environments in OpenShift.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| OpenshiftNotebookReconciler | Controller | Main reconciliation loop that watches Notebook CRDs and creates OpenShift resources |
| NotebookWebhook | Mutating Admission Webhook | Intercepts Notebook CREATE/UPDATE requests to inject OAuth proxy sidecar and mount CA bundles |
| Route Reconciler | Reconciliation Function | Creates and manages OpenShift Routes for notebook ingress (both OAuth and non-OAuth variants) |
| OAuth Reconciler | Reconciliation Function | Creates ServiceAccount, Service, Secret, and Route for OAuth proxy integration |
| Network Policy Reconciler | Reconciliation Function | Creates NetworkPolicies to control ingress traffic to notebook pods |
| CA Bundle Manager | Reconciliation Function | Manages trusted CA certificate ConfigMaps for notebooks |

## APIs Exposed

### Custom Resource Definitions (CRDs)

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| kubeflow.org | v1 | Notebook | Namespaced | Watches (not owned) - Kubeflow Notebook resource for managing Jupyter notebook instances |

**Note**: This controller watches the Notebook CRD but does not define it. The CRD is owned by the upstream Kubeflow Notebook Controller.

### HTTP Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /metrics | GET | 8080/TCP | HTTP | None | None | Prometheus metrics endpoint for controller monitoring |
| /healthz | GET | 8081/TCP | HTTP | None | None | Liveness probe endpoint |
| /readyz | GET | 8081/TCP | HTTP | None | None | Readiness probe endpoint |
| /mutate-notebook-v1 | POST | 8443/TCP | HTTPS | TLS 1.2+ | mTLS | Mutating webhook for Notebook resources |
| /oauth/healthz | GET | 8443/TCP | HTTPS | TLS 1.2+ | None | OAuth proxy health check (injected into notebooks) |

### gRPC Services

No gRPC services are exposed by this component.

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| Kubernetes | 1.29.0 | Yes | Kubernetes API and controller runtime |
| OpenShift API | 3.9.0+ | Yes | Route and Config resources |
| OAuth Proxy | registry.redhat.io/openshift4/ose-oauth-proxy@sha256:4bef31eb993feb6f1096b51b4876c65a6fb1f4401fee97fa4f4542b6b7c9bc46 | Optional | Injected as sidecar for authentication (when enabled via annotation) |
| controller-runtime | v0.17.0 | Yes | Kubernetes controller framework |

### Internal ODH Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| Kubeflow Notebook Controller | CRD Watch | Depends on Notebook CRD definition and watches Notebook resources |
| OpenShift OAuth Server | OAuth Integration | OAuth proxy delegates authentication to OpenShift OAuth |
| OpenShift Ingress Controller | Route Creation | Creates Routes that are processed by OpenShift ingress |
| OpenShift Certificate Manager | Certificate Provisioning | Automatically provisions TLS certificates via service annotations |
| ODH Dashboard | User Interaction | Users create notebooks via dashboard which creates Notebook CRs |

## Network Architecture

### Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| odh-notebook-controller-service | ClusterIP | 8080/TCP | 8080 | HTTP | None | None | Internal |
| odh-notebook-controller-webhook-service | ClusterIP | 443/TCP | 8443 | HTTPS | TLS 1.2+ | mTLS | Internal |
| {notebook-name}-tls | ClusterIP | 443/TCP | 8443 | HTTPS | TLS 1.2+ | OAuth | Internal (Created per notebook with OAuth) |

### Ingress

| Name | Type | Hosts | Port | Protocol | Encryption | TLS Mode | Exposure |
|------|------|-------|------|----------|------------|----------|----------|
| {notebook-name} (non-OAuth) | OpenShift Route | Auto-assigned | 443/TCP | HTTPS | TLS 1.2+ | Edge | External |
| {notebook-name} (OAuth) | OpenShift Route | Auto-assigned | 443/TCP | HTTPS | TLS 1.2+ | Reencrypt | External |

**Notes**:
- Routes are created automatically per Notebook resource
- Hostnames are auto-assigned by OpenShift ingress controller
- Edge termination for non-OAuth notebooks (TLS terminates at router, HTTP to pod)
- Reencrypt termination for OAuth notebooks (TLS terminates at router, re-encrypted to OAuth proxy in pod)

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| Kubernetes API Server | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token | Controller operations (watch, create, update resources) |
| OpenShift OAuth Server | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token | OAuth proxy authentication delegation |
| OpenShift ImageStream API | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token | Resolve notebook container images from internal registry |

## Security

### RBAC - Cluster Roles

| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|
| manager-role | kubeflow.org | notebooks | get, list, watch, patch |
| manager-role | kubeflow.org | notebooks/status | get |
| manager-role | kubeflow.org | notebooks/finalizers | update |
| manager-role | route.openshift.io | routes | get, list, watch, create, update, patch |
| manager-role | "" (core) | services, serviceaccounts, secrets, configmaps | get, list, watch, create, update, patch |
| manager-role | config.openshift.io | proxies | get, list, watch |
| manager-role | networking.k8s.io | networkpolicies | get, list, watch, create, update, patch |
| leader-election-role | "" (core) | configmaps | get, list, watch, create, update, patch |
| leader-election-role | coordination.k8s.io | leases | get, list, watch, create, update, patch |
| leader-election-role | "" (core) | events | create, patch |
| notebooks-edit | kubeflow.org | notebooks, notebooks/status | get, list, watch, create, delete, deletecollection, patch, update |
| notebooks-view | kubeflow.org | notebooks, notebooks/status | get, list, watch |

### RBAC - Role Bindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| manager-rolebinding | Cluster-wide | manager-role (ClusterRole) | odh-notebook-controller-manager |
| leader-election-rolebinding | Controller namespace | leader-election-role (Role) | odh-notebook-controller-manager |

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| odh-notebook-controller-webhook-cert | kubernetes.io/tls | TLS certificate for mutating webhook server | OpenShift service-ca-operator (via annotation) | Yes |
| {notebook-name}-tls | kubernetes.io/tls | TLS certificate for OAuth proxy service | OpenShift service-ca-operator (via annotation) | Yes |
| {notebook-name}-oauth-config | Opaque | OAuth proxy cookie secret (random generated) | ODH Notebook Controller | No |

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| /mutate-notebook-v1 | POST | mTLS (Kubernetes API Server to Webhook) | Kubernetes API Server | ValidatingWebhookConfiguration with service CA bundle |
| /metrics | GET | None | Controller | Internal only (ClusterIP service) |
| /healthz, /readyz | GET | None | Controller | Internal only (ClusterIP service) |
| Notebook via Route (OAuth enabled) | ALL | Bearer Token (OAuth) + OpenShift SAR | OAuth Proxy Sidecar | OpenShift SubjectAccessReview: {verb: get, resource: notebooks, resourceAPIGroup: kubeflow.org, resourceName: {notebook-name}} |
| Notebook via Route (OAuth disabled) | ALL | None (TLS only) | None | Direct access to notebook container |

## Data Flows

### Flow 1: Notebook Creation with OAuth Injection

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User/Dashboard | Kubernetes API Server | 443/TCP | HTTPS | TLS 1.3 | Bearer Token (User credentials) |
| 2 | Kubernetes API Server | ODH Notebook Controller Webhook | 8443/TCP | HTTPS | TLS 1.2+ | mTLS (Service CA) |
| 3 | Webhook | Kubernetes API Server (ImageStream) | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 4 | Webhook Response | Kubernetes API Server | 8443/TCP | HTTPS | TLS 1.2+ | mTLS (Service CA) |
| 5 | Controller (Watch Event) | Kubernetes API Server | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 6 | Controller | Kubernetes API Server (Create Resources) | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |

### Flow 2: User Accessing OAuth-Protected Notebook

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User Browser | OpenShift Router (Route) | 443/TCP | HTTPS | TLS 1.3 | None (initial request) |
| 2 | OpenShift Router | OAuth Proxy Container | 8443/TCP | HTTPS | TLS 1.2+ | None (forwarded request) |
| 3 | OAuth Proxy | OpenShift OAuth Server | 443/TCP | HTTPS | TLS 1.2+ | OAuth Flow |
| 4 | OAuth Proxy | Kubernetes API Server (SAR) | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 5 | OAuth Proxy (authorized) | Notebook Container | 8888/TCP | HTTP | None | None (localhost) |

### Flow 3: Certificate Bundle Management

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Controller (Watch ConfigMap) | Kubernetes API Server | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 2 | Controller | Kubernetes API Server (Create workbench-trusted-ca-bundle) | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 3 | Controller | Kubernetes API Server (Patch Notebook) | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |

### Flow 4: Network Policy Enforcement

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Controller Namespace Pods | Notebook Pod | 8888/TCP | HTTP | None | NetworkPolicy (namespace selector) |
| 2 | OpenShift Router | Notebook Pod (OAuth) | 8443/TCP | HTTPS | TLS 1.2+ | NetworkPolicy (allow all) |

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| Kubernetes API Server | REST API | 443/TCP | HTTPS | TLS 1.2+ | Watch Notebook CRDs, create/update resources |
| OpenShift OAuth Server | OAuth 2.0 | 443/TCP | HTTPS | TLS 1.2+ | Delegate authentication for OAuth-protected notebooks |
| OpenShift Service CA | Certificate Request | 443/TCP | HTTPS | TLS 1.2+ | Automatic TLS certificate provisioning via service annotations |
| OpenShift Ingress Controller | Route Management | 443/TCP | HTTPS | TLS 1.2+ | Process Route resources to expose notebooks externally |
| Kubeflow Notebook Controller | CRD Watch | N/A | N/A | N/A | Watches same Notebook CRD, creates StatefulSet/Service |
| OpenShift ImageStream API | Dynamic Client | 443/TCP | HTTPS | TLS 1.2+ | Resolve container images from internal registry or external registries |

## Deployment Architecture

### Container Image

- **Build Method**: Konflux (RHOAI production builds)
- **Base Image**: registry.access.redhat.com/ubi8/go-toolset (builder), registry.access.redhat.com/ubi8/ubi-minimal (runtime)
- **Security Context**: Non-root user (UID 1001), no privilege escalation
- **Image Pull Policy**: Always

### Resource Limits

| Resource | Request | Limit |
|----------|---------|-------|
| CPU | 500m | 500m |
| Memory | 256Mi | 4Gi |

### High Availability

- **Replicas**: 1 (leader election enabled)
- **Leader Election**: Yes (via coordination.k8s.io/v1 Lease)
- **Rolling Update Strategy**: maxSurge=0, maxUnavailable=100%

## Configuration

### Annotations (Notebook CRD)

| Annotation | Values | Purpose |
|------------|--------|---------|
| notebooks.opendatahub.io/inject-oauth | "true"/"false" | Enable OAuth proxy sidecar injection |
| opendatahub.io/service-mesh | "true"/"false" | Enable Service Mesh integration (mutually exclusive with OAuth) |
| notebooks.opendatahub.io/oauth-logout-url | URL string | Custom logout URL for OAuth proxy |
| notebooks.opendatahub.io/last-image-selection | "imagestream:tag" | Select notebook image from ImageStream |
| kubeflow-notebook-idle-stop | "odh-notebook-controller-lock" | Reconciliation lock to prevent race conditions |

### ConfigMaps Watched

| ConfigMap Name | Namespace | Purpose |
|----------------|-----------|---------|
| odh-trusted-ca-bundle | User namespace | User-provided and cluster CA certificates |
| kube-root-ca.crt | User namespace | Cluster self-signed CA certificate |
| workbench-trusted-ca-bundle | User namespace | Merged CA bundle created by controller |

## Network Policies Created

### Policy 1: Notebook Controller Access

| Field | Value |
|-------|-------|
| Name | {notebook-name}-ctrl-np |
| Pod Selector | notebook-name={notebook-name} |
| Policy Type | Ingress |
| Ingress Port | 8888/TCP |
| Ingress From | Namespace: controller namespace (redhat-ods-applications) |

### Policy 2: OAuth Proxy Access

| Field | Value |
|-------|-------|
| Name | {notebook-name}-oauth-np |
| Pod Selector | notebook-name={notebook-name} |
| Policy Type | Ingress |
| Ingress Port | 8443/TCP |
| Ingress From | All (no restrictions for external access via Route) |

## Webhook Configuration

### Mutating Webhook

| Field | Value |
|-------|-------|
| Name | notebooks.opendatahub.io |
| Path | /mutate-notebook-v1 |
| Service | odh-notebook-controller-webhook-service |
| Port | 443 |
| CA Bundle | Injected by cert-manager |
| Failure Policy | Fail |
| Side Effects | None |
| API Groups | kubeflow.org |
| Resources | notebooks |
| Operations | CREATE, UPDATE |
| Admission Review Versions | v1 |

## Recent Changes

| Commit | Date | Changes |
|--------|------|---------|
| e7061d29 | 2024 | - Merge pull request #128 from opendatahub-io/v1.9-branch |
| e5b3eebb | 2024 | - Merge pull request #425 from opendatahub-io/temp-11400062366 |
| 9747c598 | 2024 | - Update odh and notebook-controller with image 1.9-c5d8c55 |
| 648689f8 | 2024 | - [RHOAIENG-11895] fix(odh-nbc): put a newline between certs in case input is missing a newline (#411) |
| ac7b4851 | 2024 | - Merge pull request #124 from red-hat-data-services/add-config |
| b33d7a2c | 2024 | - Merge pull request #125 from opendatahub-io/v1.9-branch |
| 7f21e130 | 2024 | - Merge pull request #422 from opendatahub-io/main |
| 16bc9fac | 2024 | - Merge pull request #420 from jiridanek/jd_sync_v1.9-branch_from_main |
| c3d9c8b3 | 2024 | - Merge pull request #419 from jiridanek/jd_revert_oauth_proxy_update |

## Key Features

### 1. OpenShift Route Integration
- Automatically creates TLS-enabled OpenShift Routes for notebook access
- Edge termination for non-OAuth notebooks
- Reencrypt termination for OAuth-protected notebooks
- Automatic hostname assignment via OpenShift ingress controller

### 2. OAuth Proxy Injection
- Mutating webhook injects OAuth proxy sidecar when annotation is set
- Creates required ServiceAccount, Service, Secret, and Route
- Integrates with OpenShift OAuth server for authentication
- Uses OpenShift SubjectAccessReview (SAR) for authorization
- Custom logout URL support

### 3. Network Policy Management
- Automatically creates NetworkPolicies for notebook pods
- Restricts notebook container access to controller namespace
- Allows external access to OAuth proxy port
- Service Mesh integration option (mutually exclusive with OAuth)

### 4. CA Certificate Bundle Management
- Watches odh-trusted-ca-bundle ConfigMap for user-provided certificates
- Merges with cluster self-signed certificates from kube-root-ca.crt
- Creates workbench-trusted-ca-bundle ConfigMap per namespace
- Automatically mounts certificates and sets environment variables (PIP_CERT, REQUESTS_CA_BUNDLE, SSL_CERT_FILE, PIPELINES_SSL_SA_CERTS, GIT_SSL_CAINFO)
- Handles certificate rotation and cleanup

### 5. ImageStream Integration
- Resolves notebook images from OpenShift ImageStreams
- Supports both internal registry and external registries
- Uses last-image-selection annotation to select specific images
- Automatically updates JUPYTER_IMAGE environment variable

### 6. Reconciliation Lock
- Prevents race conditions during notebook creation
- Temporarily stops notebook pod startup until resources are ready
- Ensures ServiceAccount image pull secrets are mounted before pod starts
- Automatic cleanup after reconciliation completes

## Troubleshooting

### Common Issues

1. **Webhook Certificate Issues**: Webhook service must have annotation `service.beta.openshift.io/serving-cert-secret-name` for automatic certificate provisioning
2. **OAuth Access Denied**: User must have `get` permission on the specific Notebook resource (verified via OpenShift SAR)
3. **ImageStream Resolution**: Searches in `opendatahub` and `redhat-ods-applications` namespaces for ImageStreams
4. **CA Bundle Not Mounted**: Requires `odh-trusted-ca-bundle` ConfigMap to exist in notebook namespace; controller creates `workbench-trusted-ca-bundle`
5. **Network Policy Blocking**: Controller namespace defaults to reading from `/var/run/secrets/kubernetes.io/serviceaccount/namespace`, falls back to `redhat-ods-applications`

## Security Considerations

1. **TLS Everywhere**: All external communication uses TLS 1.2+
2. **No Root Containers**: Controller and OAuth proxy run as non-root (UID 1001)
3. **RBAC Enforcement**: Uses OpenShift SubjectAccessReview for fine-grained authorization
4. **Secret Rotation**: TLS certificates auto-rotate via service-ca-operator
5. **Network Segmentation**: NetworkPolicies restrict traffic to notebook pods
6. **OAuth Cookie Security**: 24-hour cookie expiration, secure random cookie secret generation
7. **Service Mesh Ready**: Supports Service Mesh integration for mTLS between services
