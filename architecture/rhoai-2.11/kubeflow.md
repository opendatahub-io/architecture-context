# Component: ODH Notebook Controller

## Metadata
- **Repository**: https://github.com/red-hat-data-services/kubeflow.git
- **Version**: 1.27.0-rhods-318-g750bf133
- **Branch**: rhoai-2.11
- **Distribution**: RHOAI
- **Languages**: Go (Golang 1.21)
- **Deployment Type**: Kubernetes Operator (Kubebuilder-based)
- **Component Path**: components/odh-notebook-controller
- **Manifests Location**: components/odh-notebook-controller/config

## Purpose
**Short**: Extends Kubeflow Notebook Controller with OpenShift-specific ingress and authentication capabilities.

**Detailed**: The ODH (Open Data Hub) Notebook Controller is a Kubernetes operator that watches Kubeflow Notebook custom resources and extends their functionality with OpenShift-native features. It automatically creates OpenShift Routes for notebook ingress with TLS termination, and optionally injects an OAuth proxy sidecar container to provide authentication and authorization using OpenShift's identity management system. The controller manages the complete lifecycle of network policies, services, routes, secrets, and service accounts required to securely expose Jupyter notebooks and similar interactive development environments in OpenShift clusters. When the `notebooks.opendatahub.io/inject-oauth` annotation is set to true, the controller delegates authorization to OpenShift RBAC, ensuring users can only access notebooks they have explicit permissions to view. This component is critical for RHOAI (Red Hat OpenShift AI) deployments, providing enterprise-grade security and multi-tenancy for data science workbenches.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| OpenshiftNotebookReconciler | Controller | Main reconciliation loop that watches Notebook CRDs and manages OpenShift resources |
| NotebookWebhook | Mutating Webhook | Intercepts Notebook CREATE/UPDATE operations to inject OAuth proxy sidecar and reconciliation lock |
| OAuth Proxy Manager | Reconciler | Creates and manages OAuth proxy sidecar containers, services, routes, secrets, and service accounts |
| Route Manager | Reconciler | Creates and manages OpenShift Routes for notebook ingress with TLS termination |
| Network Policy Manager | Reconciler | Creates and manages NetworkPolicies to control traffic to notebook pods |
| Certificate Manager | Reconciler | Manages TLS certificates and trusted CA bundles for notebooks |

## APIs Exposed

### Custom Resource Definitions (CRDs)

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| kubeflow.org | v1 | Notebook | Namespaced | Defines Jupyter notebook workbenches (watched, not owned by this controller) |

**Note**: This controller watches the `Notebook` CRD defined by the upstream Kubeflow notebook-controller. It does not define its own CRDs but extends functionality through annotations:
- `notebooks.opendatahub.io/inject-oauth`: Enable OAuth proxy injection (boolean)
- `notebooks.opendatahub.io/oauth-logout-url`: Custom logout URL for OAuth proxy
- `kubeflow-notebook-idle-*`: Reconciliation lock annotations for culling coordination

### HTTP Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /metrics | GET | 8080/TCP | HTTP | None | None | Prometheus metrics endpoint for controller monitoring |
| /healthz | GET | 8081/TCP | HTTP | None | None | Liveness probe endpoint |
| /readyz | GET | 8081/TCP | HTTP | None | None | Readiness probe endpoint |
| /mutate-notebook-v1 | POST | 8443/TCP | HTTPS | TLS 1.2+ | mTLS | Mutating webhook for Notebook resources |

### Webhook Services

| Webhook Name | Type | Operations | Resources | Failure Policy | Side Effects |
|--------------|------|------------|-----------|----------------|--------------|
| notebooks.opendatahub.io | MutatingWebhookConfiguration | CREATE, UPDATE | notebooks.kubeflow.org/v1 | Fail | None |

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| Kubeflow Notebook Controller | v1.x | Yes | Provides base Notebook CRD and StatefulSet management |
| OpenShift Route API | route.openshift.io/v1 | Yes | Creates ingress routes for notebook access |
| OpenShift OAuth Proxy | registry.redhat.io/openshift4/ose-oauth-proxy@sha256:4bef31eb... | Conditional | Provides authentication/authorization when OAuth injection enabled |
| OpenShift Service CA Operator | N/A | Yes | Provisions TLS certificates via service.beta.openshift.io/serving-cert-secret-name annotation |
| OpenShift Config API | config.openshift.io/v1 | No | Reads cluster proxy configuration if present |

### Internal ODH Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| Kubeflow Notebook Controller | CRD Watch | Watches Notebook CRDs created/managed by upstream controller |
| ODH Dashboard | Route Consumer | Dashboard links to routes created by this controller |
| ODH Trusted CA Bundle | ConfigMap | Provides custom CA certificates for notebook trust stores |

## Network Architecture

### Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| odh-notebook-controller-metrics-service | ClusterIP | 8080/TCP | 8080 | HTTP | None | None | Internal |
| odh-notebook-controller-webhook-service | ClusterIP | 443/TCP | 8443 | HTTPS | TLS 1.2+ | mTLS | Internal |
| {notebook-name}-tls | ClusterIP | 443/TCP | 8443 | HTTPS | TLS 1.2+ | OpenShift OAuth | Internal |
| {notebook-name} | ClusterIP | 80/TCP | 8888 | HTTP | None | None | Internal (non-OAuth mode) |

**Note**: Services with `{notebook-name}` are dynamically created per Notebook instance.

### Ingress

| Name | Type | Hosts | Port | Protocol | Encryption | TLS Mode | Exposure |
|------|------|-------|------|----------|------------|----------|----------|
| {notebook-name} (non-OAuth) | OpenShift Route | cluster-assigned | 443/TCP | HTTPS | TLS 1.2+ | Edge | External |
| {notebook-name} (OAuth) | OpenShift Route | cluster-assigned | 443/TCP | HTTPS | TLS 1.2+ | Reencrypt | External |

**TLS Termination Modes**:
- **Edge**: Route terminates TLS, forwards HTTP to notebook service (non-OAuth notebooks)
- **Reencrypt**: Route terminates TLS, re-encrypts to OAuth proxy service (OAuth-enabled notebooks)

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| Kubernetes API Server | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token | Watch Notebook CRDs, manage resources |
| OpenShift OAuth Server | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token | OAuth proxy authentication (when enabled) |

## Security

### RBAC - Cluster Roles

| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|
| manager-role | kubeflow.org | notebooks | get, list, watch, patch |
| manager-role | kubeflow.org | notebooks/status | get |
| manager-role | kubeflow.org | notebooks/finalizers | update |
| manager-role | route.openshift.io | routes | get, list, watch, create, update, patch |
| manager-role | "" (core) | services, serviceaccounts, secrets, configmaps | get, list, watch, create, update, patch |
| manager-role | networking.k8s.io | networkpolicies | get, list, watch, create, update, patch |
| manager-role | config.openshift.io | proxies | get, list, watch |
| notebooks-edit | kubeflow.org | notebooks, notebooks/status | get, list, watch, create, delete, deletecollection, patch, update |
| notebooks-view | kubeflow.org | notebooks, notebooks/status | get, list, watch |

### RBAC - Role Bindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| manager-rolebinding | cluster-scoped | ClusterRole/manager-role | manager (controller namespace) |
| leader-election-rolebinding | controller namespace | Role/leader-election-role | manager |

### RBAC - Leader Election Role

| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|
| leader-election-role | "" (core) | configmaps | get, list, watch, create, update, patch, delete |
| leader-election-role | coordination.k8s.io | leases | get, list, watch, create, update, patch, delete |
| leader-election-role | "" (core) | events | create, patch |

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| odh-notebook-controller-webhook-cert | kubernetes.io/tls | Webhook server TLS certificate | OpenShift Service CA | Yes (30d) |
| {notebook-name}-tls | kubernetes.io/tls | OAuth proxy service TLS certificate | OpenShift Service CA | Yes (30d) |
| {notebook-name}-oauth-config | Opaque | OAuth proxy cookie secret (base64-encoded random 32 bytes) | ODH Notebook Controller | No |

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| /mutate-notebook-v1 | POST | mTLS (Kubernetes API server client cert) | Kubernetes API Server | ValidatingWebhookConfiguration |
| {notebook-name} route (OAuth) | ALL | OpenShift OAuth (browser redirect) | OAuth Proxy Sidecar | OpenShift SAR: `get notebooks.kubeflow.org/{notebook-name}` |
| {notebook-name} route (non-OAuth) | ALL | None | N/A | Unauthenticated access |

**OAuth Authorization Flow**:
1. User accesses notebook route via browser
2. OAuth proxy intercepts request, redirects to OpenShift OAuth server
3. User authenticates with OpenShift credentials
4. OAuth server performs SubjectAccessReview (SAR): checks if user can `GET` the specific Notebook resource
5. If authorized, OAuth proxy issues session cookie and proxies to notebook container on localhost:8888
6. Session cookie expires after 24 hours

## Data Flows

### Flow 1: Notebook Creation (Non-OAuth Mode)

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User/Dashboard | Kubernetes API | 443/TCP | HTTPS | TLS 1.2+ | Bearer Token |
| 2 | Kubernetes API | ODH Notebook Controller Webhook | 8443/TCP | HTTPS | mTLS | Client Cert |
| 3 | Webhook | Kubernetes API (patch response) | N/A | N/A | N/A | N/A |
| 4 | ODH Notebook Controller | Kubernetes API (watch) | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 5 | ODH Notebook Controller | Kubernetes API (create Route) | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 6 | ODH Notebook Controller | Kubernetes API (create NetworkPolicy) | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 7 | User Browser | OpenShift Router (Route) | 443/TCP | HTTPS | TLS 1.2+ | None |
| 8 | OpenShift Router | Notebook Service | 8888/TCP | HTTP | None | None |

### Flow 2: Notebook Creation (OAuth Mode)

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User/Dashboard | Kubernetes API | 443/TCP | HTTPS | TLS 1.2+ | Bearer Token |
| 2 | Kubernetes API | ODH Notebook Controller Webhook | 8443/TCP | HTTPS | mTLS | Client Cert |
| 3 | Webhook | Notebook Pod Spec (mutate) | N/A | N/A | N/A | Inject OAuth Sidecar |
| 4 | ODH Notebook Controller | Kubernetes API (create ServiceAccount) | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 5 | ODH Notebook Controller | Kubernetes API (create OAuth Secret) | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 6 | ODH Notebook Controller | Kubernetes API (create OAuth Service) | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 7 | ODH Notebook Controller | Kubernetes API (create OAuth Route) | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 8 | ODH Notebook Controller | Kubernetes API (create NetworkPolicies) | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |

### Flow 3: Notebook Access (OAuth Mode)

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User Browser | OpenShift Router (Route) | 443/TCP | HTTPS | TLS 1.2+ | None |
| 2 | OpenShift Router | OAuth Proxy Sidecar | 8443/TCP | HTTPS | TLS 1.2+ | None |
| 3 | OAuth Proxy | OpenShift OAuth Server | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 4 | User Browser | OpenShift OAuth Server | 443/TCP | HTTPS | TLS 1.2+ | User Credentials |
| 5 | OpenShift OAuth Server | Kubernetes API (SAR check) | 443/TCP | HTTPS | TLS 1.2+ | User Token |
| 6 | OAuth Proxy | Notebook Container (localhost) | 8888/TCP | HTTP | None | None |

### Flow 4: Webhook Mutation

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Kubernetes API | Webhook Service | 443/TCP | HTTPS | TLS 1.2+ | mTLS |
| 2 | Webhook Handler | Notebook Spec (in-memory) | N/A | N/A | N/A | Inject OAuth sidecar |
| 3 | Webhook Handler | Kubernetes API (response) | N/A | N/A | N/A | Admission response |

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| Kubeflow Notebook Controller | Kubernetes API (watch) | 443/TCP | HTTPS | TLS 1.2+ | Watch Notebook CRD events, coordinate reconciliation |
| OpenShift Ingress Controller | Route API | N/A | N/A | N/A | Expose notebooks via cluster ingress |
| OpenShift OAuth Server | OAuth/OIDC | 443/TCP | HTTPS | TLS 1.2+ | Authenticate users and perform authorization checks |
| OpenShift Service CA Operator | Annotation-based | N/A | N/A | N/A | Provision TLS certificates for services |
| Prometheus | Metrics scrape | 8080/TCP | HTTP | None | Collect controller metrics |
| ODH Dashboard | Route consumer | N/A | N/A | N/A | Display notebook URLs to users |

## Network Policies

### Notebook Controller Network Policy (per notebook)

| Direction | Source/Destination | Port | Protocol | Purpose |
|-----------|-------------------|------|----------|---------|
| Ingress | Pods in controller namespace | 8888/TCP | TCP | Allow notebook controller to probe notebook pod |
| Ingress | All (implicit) | 8443/TCP | TCP | Allow OAuth proxy traffic from OpenShift router |

### OAuth Network Policy (per notebook with OAuth enabled)

| Direction | Source/Destination | Port | Protocol | Purpose |
|-----------|-------------------|------|----------|---------|
| Ingress | Pods in controller namespace | 8443/TCP | TCP | Allow traffic to OAuth proxy from router |

**Note**: Network policies are created with the notebook name as the pod selector (`notebook-name: {notebook-name}`)

## Deployment Architecture

### Container Image Build

- **Base Image**: registry.access.redhat.com/ubi8/go-toolset:1.21 (builder)
- **Runtime Image**: registry.access.redhat.com/ubi8/ubi-minimal:latest
- **Build Method**: Multi-stage Dockerfile
- **Binary**: `/manager` (compiled Go binary)
- **User**: UID 1001 (non-root)
- **Security Context**: `runAsNonRoot: true`, `allowPrivilegeEscalation: false`

### Controller Deployment

- **Replicas**: 1
- **Strategy**: RollingUpdate (maxSurge: 0, maxUnavailable: 100%)
- **Service Account**: manager
- **Leader Election**: Supported (optional, disabled by default)
- **Resource Requests**: CPU 500m, Memory 256Mi
- **Resource Limits**: CPU 500m, Memory 4Gi

### Command Line Flags

| Flag | Default | Purpose |
|------|---------|---------|
| --metrics-bind-address | :8080 | Prometheus metrics endpoint |
| --health-probe-bind-address | :8081 | Health/readiness probe endpoint |
| --webhook-port | 8443 | Webhook server HTTPS port |
| --oauth-proxy-image | registry.redhat.io/openshift4/ose-oauth-proxy@sha256:4bef31eb... | OAuth proxy sidecar image |
| --leader-elect | false | Enable leader election |
| --debug-log | false | Enable debug logging |

## Recent Changes

**Note**: Repository shows version `1.27.0-rhods-318-g750bf133` on branch `rhoai-2.11`. Recent commit history was not available in the output, indicating a stable release state.

| Version | Date | Changes |
|---------|------|---------|
| 1.27.0-rhods-318 | 2025-Q4 | RHOAI 2.11 release version |

## Configuration Files

### Kustomize Structure

```
components/odh-notebook-controller/config/
├── base/              # Base kustomization with param substitution
├── crd/external/      # External CRDs (Notebook, Route)
├── default/           # Default kustomization with webhook
├── development/       # Dev overlay with ktunnel for local testing
├── manager/           # Controller deployment, service, params
├── rbac/              # RBAC roles, bindings, service account
├── samples/           # Example Notebook resources
└── webhook/           # Webhook service and configuration
```

### Key Manifests

- **Deployment**: `config/manager/manager.yaml`
- **RBAC**: `config/rbac/role.yaml`, `config/rbac/role_binding.yaml`
- **Webhook**: `config/webhook/manifests.yaml`
- **Services**: `config/manager/service.yaml`, `config/webhook/service.yaml`
- **CRDs**: `config/crd/external/kubeflow.org_notebooks.yaml` (watched, not owned)

## Troubleshooting

### Common Issues

1. **Webhook Certificate Issues**: Webhook service requires `service.beta.openshift.io/serving-cert-secret-name` annotation to provision certificates via Service CA operator
2. **OAuth Proxy Failures**: Check that notebook ServiceAccount has OAuth redirect annotation and TLS secret exists
3. **Route Not Created**: Verify controller has permissions to create routes in target namespace
4. **Network Policy Blocking Access**: Ensure source namespace label matches `kubernetes.io/metadata.name` selector

### Debugging

- **Controller Logs**: `oc logs -n <namespace> deployment/odh-notebook-controller-manager`
- **Webhook Logs**: Same as controller (webhook runs in same pod)
- **Metrics**: `curl http://<controller-pod>:8080/metrics`
- **Health Checks**: `curl http://<controller-pod>:8081/healthz`

## Additional Notes

- **Coordination with Kubeflow**: This controller uses a "reconciliation lock" annotation to prevent race conditions with the upstream Kubeflow notebook controller when mounting image pull secrets
- **Certificate Trust**: Controller manages a `workbench-trusted-ca-bundle` ConfigMap that combines ODH custom CA bundles with cluster self-signed certificates for notebook trust stores
- **OpenShift-Specific**: This controller is tightly coupled to OpenShift APIs (Routes, OAuth, Service CA) and will not function on vanilla Kubernetes
- **Multi-Tenancy**: OAuth integration enforces namespace-scoped RBAC, preventing users from accessing notebooks they don't have permissions for
