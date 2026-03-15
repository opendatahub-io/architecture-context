# Component: ODH Notebook Controller

## Metadata
- **Repository**: https://github.com/red-hat-data-services/kubeflow.git
- **Version**: v1.27.0-rhods-237-g4e7a7145
- **Branch**: rhoai-2.6
- **Distribution**: RHOAI
- **Languages**: Go 1.19
- **Deployment Type**: Kubernetes Controller/Operator
- **Component Path**: components/odh-notebook-controller

## Purpose
**Short**: Extends Kubeflow Notebook controller with OpenShift-specific ingress (Routes) and OAuth authentication capabilities.

**Detailed**: The ODH (Open Data Hub) Notebook Controller is a Kubernetes operator that watches Kubeflow Notebook custom resources and extends their functionality with OpenShift-specific features. It automatically creates OpenShift Routes for notebook ingress with TLS termination, enabling external access to Jupyter notebooks. When the `notebooks.opendatahub.io/inject-oauth` annotation is set, the controller injects an OAuth proxy sidecar container that provides authentication and authorization through OpenShift's built-in OAuth server. Authorization is delegated to Kubernetes RBAC through SubjectAccessReview, ensuring users can only access notebooks they have permission to view.

The controller also manages network policies to control pod-to-pod communication, integrates with OpenShift's cluster-wide proxy configuration, and provisions TLS certificates via OpenShift's service-ca operator. It works in conjunction with the upstream Kubeflow Notebook Controller, which handles the creation of StatefulSets for the actual notebook pods.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| OpenshiftNotebookReconciler | Controller | Main reconciliation loop for Notebook CRs - creates Routes, Services, Secrets, ConfigMaps, NetworkPolicies |
| NotebookWebhook | Mutating Webhook | Injects OAuth proxy sidecar, reconciliation lock annotation, and cluster-wide proxy config into Notebook pods |
| Webhook Server | HTTPS Server | Serves mutating webhook on port 8443 with TLS certificates from service-ca |
| Metrics Server | HTTP Server | Exposes Prometheus metrics on port 8080 |
| Health Probes | HTTP Server | Provides /healthz and /readyz endpoints on port 8081 |

## APIs Exposed

### Custom Resource Definitions (CRDs)

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| kubeflow.org | v1 | Notebook | Namespaced | Defines Jupyter notebook instances with pod templates (CRD owned by upstream Kubeflow, watched by this controller) |

### HTTP Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /mutate-notebook-v1 | POST | 8443/TCP | HTTPS | TLS 1.2+ | Kubernetes API Server (client cert) | Mutating webhook for Notebook CRs |
| /metrics | GET | 8080/TCP | HTTP | None | None | Prometheus metrics for controller |
| /healthz | GET | 8081/TCP | HTTP | None | None | Liveness probe endpoint |
| /readyz | GET | 8081/TCP | HTTP | None | None | Readiness probe endpoint |

### gRPC Services

| Service | Port | Protocol | Encryption | Auth | Purpose |
|---------|------|----------|------------|------|---------|
| N/A | N/A | N/A | N/A | N/A | No gRPC services exposed |

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| Kubeflow Notebook Controller | v0.0.0-20220728153354-fc09bd1eefb8 | Yes | Upstream controller that creates StatefulSets for notebooks |
| OpenShift Route API | route.openshift.io/v1 | Yes | Creates ingress routes for notebook access |
| OpenShift OAuth Proxy | ose-oauth-proxy:latest | Yes | Sidecar container for authentication/authorization |
| OpenShift Config API | config.openshift.io/v1 | No | Optional cluster-wide proxy configuration |
| OpenShift Service CA | N/A | Yes | Provisions TLS certificates for services |
| controller-runtime | v0.11.0 | Yes | Kubernetes controller framework |
| Kubernetes | v1.24.2+ | Yes | Core Kubernetes API |

### Internal ODH Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| Kubeflow Notebook Controller | CRD Watch | Watches Notebook CRs created by upstream controller |
| ODH Dashboard | Route Consumer | Dashboard links to notebook Routes created by this controller |
| OpenShift Ingress | Route Processing | OpenShift router processes Routes and assigns hosts |
| Service CA Operator | Certificate Provisioning | Provisions TLS certs via service.beta.openshift.io/serving-cert-secret-name annotation |

## Network Architecture

### Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| {notebook-name}-tls | ClusterIP | 443/TCP | 8443 (oauth-proxy) | HTTPS | TLS 1.2+ | mTLS (service-ca cert) | Internal |
| odh-notebook-controller-webhook-service | ClusterIP | 443/TCP | 8443 (webhook) | HTTPS | TLS 1.2+ | Client cert (Kubernetes API server) | Internal |
| odh-notebook-controller-service | ClusterIP | 8080/TCP | 8080 (metrics) | HTTP | None | None | Internal |

### Ingress

| Name | Type | Hosts | Port | Protocol | Encryption | TLS Mode | Exposure |
|------|------|-------|------|----------|------------|----------|----------|
| {notebook-name} (no OAuth) | OpenShift Route | Auto-assigned by router | 443/TCP | HTTPS | TLS (edge termination) | Edge | External |
| {notebook-name} (with OAuth) | OpenShift Route | Auto-assigned by router | 443/TCP | HTTPS | TLS (re-encrypt) | Re-encrypt | External |

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | Service Account Token | Watch Notebook CRs, create/update resources |
| OpenShift OAuth Server | 443/TCP | HTTPS | TLS 1.2+ | Service Account Token | OAuth proxy authentication (from injected sidecar) |
| Cluster-wide Proxy (if configured) | Varies | HTTP/HTTPS | Varies | Varies | Proxy egress traffic from notebooks |

## Security

### RBAC - Cluster Roles

| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|
| manager-role | kubeflow.org | notebooks, notebooks/status, notebooks/finalizers | get, list, watch, patch, update |
| manager-role | route.openshift.io | routes | get, list, watch, create, update, patch |
| manager-role | "" (core) | services, serviceaccounts, secrets, configmaps | get, list, watch, create, update, patch |
| manager-role | config.openshift.io | proxies | get, list, watch |
| manager-role | networking.k8s.io | networkpolicies | get, list, watch, create, update, patch |
| leader-election-role | "" (core) | configmaps, events | get, list, watch, create, update, patch, delete |
| leader-election-role | coordination.k8s.io | leases | get, list, watch, create, update, patch, delete |
| notebooks-edit | kubeflow.org | notebooks, notebooks/status | get, list, watch, create, delete, deletecollection, patch, update |
| notebooks-view | kubeflow.org | notebooks, notebooks/status | get, list, watch |

### RBAC - Role Bindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| manager-rolebinding | Cluster-wide | manager-role (ClusterRole) | manager (in controller namespace) |
| leader-election-rolebinding | Controller namespace | leader-election-role (Role) | manager |

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| {notebook-name}-oauth-config | Opaque | Stores OAuth proxy cookie secret (random base64) | ODH Notebook Controller | No |
| {notebook-name}-tls | kubernetes.io/tls | TLS certificate for OAuth service | OpenShift Service CA | Yes (90 days) |
| odh-notebook-controller-webhook-cert | kubernetes.io/tls | TLS certificate for webhook server | OpenShift Service CA | Yes (90 days) |
| trusted-ca | N/A (ConfigMap) | Cluster-wide trusted CA bundle | OpenShift Network Operator | Yes (automatic) |

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| /mutate-notebook-v1 | POST | mTLS (Kubernetes API server client cert) | Webhook Server | Kubernetes RBAC |
| /{notebook-path} (with OAuth) | GET, POST | OpenShift OAuth + SubjectAccessReview | OAuth Proxy Sidecar | User must have GET permission on notebook CR |
| /{notebook-path} (no OAuth) | GET, POST | None | N/A | Publicly accessible via Route |
| /metrics | GET | None | N/A | Internal only (ClusterIP) |

## Data Flows

### Flow 1: Notebook Access with OAuth

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User Browser | OpenShift Router | 443/TCP | HTTPS | TLS 1.2+ (edge) | None (redirects to OAuth) |
| 2 | OpenShift Router | {notebook-name}-tls Service | 443/TCP | HTTPS | TLS 1.2+ (re-encrypt) | None |
| 3 | Service | OAuth Proxy Container | 8443/TCP | HTTPS | TLS 1.2+ (service-ca cert) | None |
| 4 | OAuth Proxy | OpenShift OAuth Server | 443/TCP | HTTPS | TLS 1.2+ | Service Account Token |
| 5 | OAuth Proxy | Kubernetes API Server (SAR) | 6443/TCP | HTTPS | TLS 1.2+ | User Token |
| 6 | OAuth Proxy | Notebook Container | 8888/TCP | HTTP | None | None (localhost) |

### Flow 2: Notebook CR Reconciliation

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Kubernetes API Server | ODH Notebook Controller | N/A | Watch (HTTP/2) | TLS 1.2+ | Service Account Token |
| 2 | ODH Notebook Controller | Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | Service Account Token |

### Flow 3: Webhook Injection

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Kubernetes API Server | Webhook Service | 443/TCP | HTTPS | TLS 1.2+ (service-ca cert) | mTLS (API server client cert) |
| 2 | Webhook Server | Kubernetes API Server (read Proxy CR) | 6443/TCP | HTTPS | TLS 1.2+ | Service Account Token |

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| Kubeflow Notebook Controller | Kubernetes Watch | N/A | HTTP/2 (Watch API) | TLS 1.2+ | Watch Notebook CRs for changes |
| OpenShift Router | HTTP Route | 443/TCP | HTTPS | TLS (edge/re-encrypt) | Expose notebooks externally |
| OpenShift OAuth Server | OAuth 2.0 | 443/TCP | HTTPS | TLS 1.2+ | Authenticate users accessing notebooks |
| Kubernetes API Server (SAR) | SubjectAccessReview | 6443/TCP | HTTPS | TLS 1.2+ | Authorize user access to notebooks |
| Service CA Operator | Certificate Provisioning | N/A | N/A | N/A | Automatic TLS certificate provisioning |
| OpenShift Network Operator | ConfigMap Injection | N/A | N/A | N/A | Inject trusted CA bundle |

## Network Policies

The controller creates two NetworkPolicy resources per notebook:

### {notebook-name}-ctrl-np
- **Purpose**: Allow controller namespace to access notebook container port
- **Selector**: Pods with label `notebook-name: {notebook-name}`
- **Ingress**: Allow TCP/8888 from namespace with label `kubernetes.io/metadata.name: {controller-namespace}` (defaults to redhat-ods-applications)
- **Policy Type**: Ingress

### {notebook-name}-oauth-np
- **Purpose**: Allow all traffic to OAuth proxy port
- **Selector**: Pods with label `notebook-name: {notebook-name}`
- **Ingress**: Allow TCP/8443 from all sources
- **Policy Type**: Ingress

## Deployment Architecture

### Controller Deployment

| Parameter | Value |
|-----------|-------|
| Replicas | 1 |
| Strategy | RollingUpdate (maxSurge: 0, maxUnavailable: 100%) |
| Service Account | manager |
| Security Context | runAsNonRoot: true, allowPrivilegeEscalation: false |
| CPU Request | 500m |
| CPU Limit | 500m |
| Memory Request | 256Mi |
| Memory Limit | 4Gi |
| Liveness Probe | HTTP GET /healthz:8081 (delay: 15s, period: 20s) |
| Readiness Probe | HTTP GET /readyz:8081 (delay: 5s, period: 10s) |

### Container Images

| Component | Image | Pull Policy |
|-----------|-------|-------------|
| Controller | Built from Dockerfile (multi-stage, distroless base) | Always |
| OAuth Proxy (injected) | registry.redhat.io/openshift4/ose-oauth-proxy@sha256:4bef31eb... | Always |

## Annotations Used

| Annotation | Target | Purpose |
|------------|--------|---------|
| notebooks.opendatahub.io/inject-oauth | Notebook CR | Triggers OAuth proxy injection |
| notebooks.opendatahub.io/oauth-logout-url | Notebook CR | Custom logout URL for OAuth proxy |
| kubeflow.org/last-activity | Notebook CR | Used by culling (set to "odh-notebook-controller-lock" during initial reconciliation) |
| service.beta.openshift.io/serving-cert-secret-name | Service | Triggers automatic TLS cert provisioning by service-ca |
| serviceaccounts.openshift.io/oauth-redirectreference.first | ServiceAccount | OAuth redirect configuration for Routes |
| config.openshift.io/inject-trusted-cabundle | ConfigMap | Triggers trusted CA bundle injection |

## Configuration

### Command-line Flags

| Flag | Default | Purpose |
|------|---------|---------|
| --metrics-bind-address | :8080 | Metrics server listen address |
| --health-probe-bind-address | :8081 | Health probe server listen address |
| --webhook-port | 8443 | Webhook server listen port |
| --oauth-proxy-image | registry.redhat.io/openshift4/ose-oauth-proxy:latest | OAuth proxy sidecar image |
| --leader-elect | false | Enable leader election |
| --debug-log | false | Enable debug logging |

### Environment Variables

| Variable | Source | Purpose |
|----------|--------|---------|
| NAMESPACE | Pod metadata (fieldRef) | Injected into OAuth proxy for SAR namespace |

## Recent Changes

| Version | Date | Changes |
|---------|------|---------|
| v1.27.0-rhods-237 | 2024-03-14 | RHOAI 2.6 release branch - OpenShift integration for Kubeflow notebooks with OAuth proxy, Routes, and NetworkPolicies |

## Operational Considerations

### High Availability
- Single replica deployment (no leader election by default)
- StatefulSets created by upstream Kubeflow controller handle notebook pod lifecycle
- Controller failure does not affect running notebooks, only prevents new notebooks from getting Routes/OAuth

### Monitoring
- Prometheus metrics on port 8080 (standard controller-runtime metrics)
- Liveness probe ensures pod restart on failure
- Readiness probe prevents traffic during startup

### Troubleshooting

**Common Issues:**

1. **Notebook not accessible**: Check Route status, NetworkPolicy rules, and OAuth service creation
2. **OAuth login fails**: Verify ServiceAccount annotations, TLS certificate provisioning, and SAR permissions
3. **Webhook failures**: Check webhook certificate validity and MutatingWebhookConfiguration
4. **Reconciliation stuck**: Check for "odh-notebook-controller-lock" annotation - should be removed after first reconciliation

**Debug Commands:**
```bash
# Check controller logs
oc logs -n redhat-ods-applications deployment/odh-notebook-controller-manager

# Verify notebook Route
oc get route {notebook-name} -n {namespace} -o yaml

# Check OAuth service and secret
oc get service,secret -l notebook-name={notebook-name} -n {namespace}

# Verify NetworkPolicies
oc get networkpolicy -n {namespace}

# Check webhook configuration
oc get mutatingwebhookconfiguration odh-notebook-controller-mutating-webhook-configuration
```

### Performance
- Lightweight controller with minimal resource usage (256Mi memory request)
- Webhook latency typically <100ms for Notebook CR mutations
- No database or persistent storage requirements

### Security Best Practices
- OAuth proxy enforces authentication for sensitive notebooks
- SubjectAccessReview ensures RBAC authorization
- TLS encryption for all external traffic
- NetworkPolicies restrict pod-to-pod communication
- Service-ca automatic certificate rotation (90 days)
- Non-root container execution
