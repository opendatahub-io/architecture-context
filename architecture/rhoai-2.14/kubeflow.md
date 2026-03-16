# Component: ODH Notebook Controller

## Metadata
- **Repository**: https://github.com/red-hat-data-services/kubeflow.git
- **Version**: v1.27.0-rhods-663-g6d3539f5
- **Branch**: rhoai-2.14
- **Distribution**: RHOAI
- **Languages**: Go 1.21
- **Deployment Type**: Kubernetes Controller (Kubebuilder-based)

## Purpose
**Short**: Extends Kubeflow Notebook Controller with OpenShift-specific features including Route-based ingress, OAuth proxy authentication, and network policy management.

**Detailed**: The ODH Notebook Controller is a Kubernetes controller that watches Kubeflow Notebook custom resources and enhances them with OpenShift-native capabilities. It automatically creates OpenShift Routes for notebook ingress with TLS termination, optionally injecting an OAuth proxy sidecar for authentication and authorization via OpenShift RBAC. The controller reconciles all supporting resources including service accounts, services, secrets, and network policies required for secure notebook access.

When the `notebooks.opendatahub.io/inject-oauth` annotation is set to `true`, the controller's mutating webhook injects an OAuth proxy sidecar that enforces authentication through OpenShift OAuth and authorization through SubjectAccessReview (SAR), allowing only users with appropriate notebook permissions to access the notebook. The controller also supports Service Mesh integration and creates NetworkPolicies to restrict traffic to notebook pods.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| OpenshiftNotebookReconciler | Controller | Watches Notebook CRs and reconciles OpenShift Routes, Services, ServiceAccounts, Secrets, and NetworkPolicies |
| NotebookWebhook | Mutating Admission Webhook | Injects OAuth proxy sidecar container and volumes into Notebook pods when annotation is present |
| Manager Deployment | Pod | Runs the controller manager with webhook server and reconciliation loops |

## APIs Exposed

### Custom Resource Definitions (CRDs)

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| kubeflow.org | v1 | Notebook | Namespaced | Watched (not owned) - Kubeflow notebook resource extended with OpenShift capabilities |

### HTTP Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /metrics | GET | 8080/TCP | HTTP | None | None | Prometheus metrics for controller |
| /healthz | GET | 8081/TCP | HTTP | None | None | Liveness probe endpoint |
| /readyz | GET | 8081/TCP | HTTP | None | None | Readiness probe endpoint |
| /mutate-notebook-v1 | POST | 8443/TCP | HTTPS | TLS 1.2+ | Kubernetes API mTLS | Mutating webhook for Notebook resources |

### gRPC Services

| Service | Port | Protocol | Encryption | Auth | Purpose |
|---------|------|----------|------------|------|---------|
| N/A | N/A | N/A | N/A | N/A | No gRPC services |

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| Kubeflow Notebook Controller | v1.27.0+ | Yes | Creates and manages underlying StatefulSets and Services for notebooks |
| OpenShift Route API | route.openshift.io/v1 | Yes | Route CRD for ingress traffic routing |
| OpenShift OAuth Proxy | 4.14 (digest sha256:4bef31eb993feb6) | Yes (if OAuth enabled) | Sidecar container providing OAuth authentication |
| OpenShift Service CA Operator | OpenShift 4.x | Yes (if OAuth enabled) | Generates TLS certificates for services via annotations |
| OpenShift OAuth Server | OpenShift 4.x | Yes (if OAuth enabled) | Handles user authentication for OAuth proxy |

### Internal ODH Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| Kubeflow Notebook Controller | CRD Watching | Watches Notebook CRs created by Notebook Controller |
| ODH Dashboard | HTTP/Routes | Dashboard links users to notebook Routes created by this controller |
| Service Mesh (Optional) | Istio Integration | Optional service mesh integration via annotation `opendatahub.io/service-mesh` |

## Network Architecture

### Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| odh-notebook-controller-manager-service | ClusterIP | 8080/TCP | metrics | HTTP | None | None | Internal (metrics) |
| odh-notebook-controller-webhook-service | ClusterIP | 443/TCP | 8443/TCP | HTTPS | TLS 1.2+ | Kubernetes API | Internal (webhook) |
| {notebook-name}-tls | ClusterIP | 443/TCP | oauth-proxy | HTTPS | TLS 1.2+ (service-ca) | OAuth/mTLS | Internal (OAuth notebooks) |
| {notebook-name} | ClusterIP | 80/TCP | http-{name} | HTTP | None | None | Internal (non-OAuth notebooks) |

### Ingress

| Name | Type | Hosts | Port | Protocol | Encryption | TLS Mode | Exposure |
|------|------|-------|------|----------|------------|----------|----------|
| {notebook-name} Route | OpenShift Route | Auto-assigned by cluster | 443/TCP | HTTPS | TLS 1.2+ | Edge (non-OAuth) | External |
| {notebook-name} Route (OAuth) | OpenShift Route | Auto-assigned by cluster | 443/TCP | HTTPS | TLS 1.2+ | Reencrypt | External |

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| Kubernetes API Server | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token | Controller operations (CRUD on resources) |
| OpenShift OAuth Server | 443/TCP | HTTPS | TLS 1.2+ | OAuth tokens | OAuth proxy authentication (when enabled) |
| OpenShift API Server (SAR) | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token | SubjectAccessReview for authorization (OAuth notebooks) |

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
| notebooks-edit | kubeflow.org | notebooks, notebooks/status | get, list, watch, create, delete, deletecollection, patch, update |
| notebooks-view | kubeflow.org | notebooks, notebooks/status | get, list, watch |
| notebooks-admin | N/A | N/A | Aggregates notebooks-edit |

### RBAC - Role Bindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| manager-rolebinding | Cluster-scoped | ClusterRole: manager-role | odh-notebook-controller:manager |
| leader-election-rolebinding | odh-notebook-controller | Role: leader-election-role | odh-notebook-controller:manager |

### RBAC - Roles (Namespace-scoped)

| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|
| leader-election-role | "" (core) | configmaps | get, list, watch, create, update, patch, delete |
| leader-election-role | coordination.k8s.io | leases | get, list, watch, create, update, patch, delete |
| leader-election-role | "" (core) | events | create, patch |

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| odh-notebook-controller-webhook-cert | kubernetes.io/tls | TLS certificate for webhook server | OpenShift Service CA | Yes |
| {notebook-name}-oauth-config | Opaque | OAuth proxy cookie secret (base64 encoded random) | ODH Notebook Controller | No |
| {notebook-name}-tls | kubernetes.io/tls | TLS certificate for OAuth service | OpenShift Service CA | Yes |

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| /mutate-notebook-v1 | POST | Kubernetes API mTLS | Kubernetes API Server | MutatingWebhookConfiguration with clientConfig |
| {notebook-url} (OAuth) | GET, POST | OpenShift OAuth + SAR | OAuth Proxy Sidecar | SAR: verb=get, resource=notebooks, resourceAPIGroup=kubeflow.org |
| {notebook-url} (non-OAuth) | GET, POST | None | None | Public access via Route |
| /metrics | GET | None | None | Internal ClusterIP service only |
| /healthz, /readyz | GET | None | None | Internal probes only |

## Data Flows

### Flow 1: User Accesses OAuth-Enabled Notebook

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User Browser | OpenShift Router | 443/TCP | HTTPS | TLS 1.2+ (Router cert) | None |
| 2 | OpenShift Router | {notebook}-tls Service | 443/TCP | HTTPS | TLS 1.2+ (Reencrypt) | None |
| 3 | Service | OAuth Proxy Container | 8443/TCP | HTTPS | TLS 1.2+ (Service CA cert) | None |
| 4 | OAuth Proxy | OpenShift OAuth Server | 443/TCP | HTTPS | TLS 1.2+ | OAuth flow |
| 5 | OAuth Proxy | Kubernetes API (SAR) | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 6 | OAuth Proxy | Notebook Container | 8888/TCP | HTTP | None | None (localhost) |

### Flow 2: Controller Reconciles Notebook

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Notebook CRD | Controller Watch | N/A | N/A | N/A | N/A (internal watch) |
| 2 | Controller | Kubernetes API | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 3 | Controller | Create/Update Route | API | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 4 | Controller | Create Service/Secret/SA | API | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 5 | Controller | Create NetworkPolicy | API | HTTPS | TLS 1.2+ | ServiceAccount Token |

### Flow 3: Notebook Creation with OAuth Injection

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User/Dashboard | Kubernetes API | 443/TCP | HTTPS | TLS 1.2+ | Bearer Token |
| 2 | Kubernetes API | NotebookWebhook | 8443/TCP | HTTPS | TLS 1.2+ | Kubernetes API mTLS |
| 3 | NotebookWebhook | Returns Mutated Spec | 8443/TCP | HTTPS | TLS 1.2+ | Kubernetes API mTLS |
| 4 | Kubernetes API | Kubeflow Controller | N/A | N/A | N/A | Creates StatefulSet |
| 5 | ODH Controller Watch | Reconciles Resources | N/A | N/A | N/A | Creates Route/Service/etc |

### Flow 4: Notebook Access via NetworkPolicy (Controller Namespace to Notebook)

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Controller Namespace Pod | Notebook Pod | 8888/TCP | HTTP | None | None |
| 2 | NetworkPolicy Ingress | Allows from ns with label | 8888/TCP | TCP | N/A | kubernetes.io/metadata.name={controller-ns} |

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| Kubernetes API Server | REST API (client-go) | 443/TCP | HTTPS | TLS 1.2+ | CRUD operations on Kubernetes resources |
| OpenShift Route API | REST API (client-go) | 443/TCP | HTTPS | TLS 1.2+ | Create/update Routes for notebook ingress |
| OpenShift Service CA | Annotation-based | N/A | N/A | N/A | Auto-provision TLS certs via service annotation |
| OpenShift OAuth Server | OAuth 2.0 | 443/TCP | HTTPS | TLS 1.2+ | User authentication for notebooks |
| Kubeflow Notebook Controller | CRD Watch | N/A | N/A | N/A | Watches Notebook CRs created by Kubeflow controller |
| Prometheus | HTTP Scrape | 8080/TCP | HTTP | None | Scrapes /metrics endpoint for monitoring |

## Annotations and Configuration

### Notebook Annotations

| Annotation | Type | Default | Purpose |
|------------|------|---------|---------|
| notebooks.opendatahub.io/inject-oauth | boolean | false | Enable OAuth proxy sidecar injection |
| opendatahub.io/service-mesh | boolean | false | Enable Service Mesh integration (mutually exclusive with OAuth) |
| notebooks.opendatahub.io/oauth-logout-url | string | N/A | Custom logout URL for OAuth proxy |
| notebooks.kubeflow.org/stop-annotation | string | N/A | Used for reconciliation locking during controller sync |

### Service Annotations

| Annotation | Resource Type | Purpose |
|------------|---------------|---------|
| service.beta.openshift.io/serving-cert-secret-name | Service | Triggers Service CA to create TLS certificate secret |
| serviceaccounts.openshift.io/oauth-redirectreference.first | ServiceAccount | OAuth redirect reference for Route integration |

## Recent Changes

| Version | Date | Changes |
|---------|------|---------|
| v1.27.0-rhods-663 | 2024-11 | - Merge pull request #121: Fix GHA workflow<br>- Revert RHOAIENG-10827: oauth-proxy image update<br>- RHOAIENG-13494: Service mesh integration updates |
| v1.27.0-rhods-650 | 2024-10 | - RHOAIENG-9824: Improve integration tests for odh-notebook-controller<br>- Sync with v1.9-branch from opendatahub-io<br>- Run `make generate` to update YAML manifests |
| v1.27.0-rhods-640 | 2024-09 | - Update odh and notebook-controller images<br>- Comment out owners from Service Mesh section |

## Deployment Architecture

### Container Image Build

- **Base Image**: registry.access.redhat.com/ubi8/go-toolset:1.21 (builder)
- **Runtime Image**: registry.access.redhat.com/ubi8/ubi-minimal:latest
- **Build Context**: `components/` directory (includes both notebook-controller and odh-notebook-controller)
- **Binary**: `/manager`
- **User**: UID 1001 (non-root user `rhods`)

### Resource Requests/Limits

| Resource | Request | Limit |
|----------|---------|-------|
| CPU | 500m | 500m |
| Memory | 256Mi | 4Gi |

### Deployment Configuration

- **Replicas**: 1
- **Strategy**: RollingUpdate (maxSurge: 0, maxUnavailable: 100%)
- **Service Account**: manager
- **Security Context**: runAsNonRoot: true, allowPrivilegeEscalation: false
- **Termination Grace Period**: 10 seconds

## Network Policies Created by Controller

### Notebook Controller Network Policy

| Policy Name | Pod Selector | Ingress From | Ports | Purpose |
|-------------|--------------|--------------|-------|---------|
| {notebook-name}-ctrl-np | notebook-name={name} | Namespace: {controller-namespace} | 8888/TCP | Allow controller namespace to access notebook port |

### OAuth Network Policy (when OAuth enabled and Service Mesh disabled)

| Policy Name | Pod Selector | Ingress From | Ports | Purpose |
|-------------|--------------|--------------|-------|---------|
| {notebook-name}-oauth-np | notebook-name={name} | Any | 8443/TCP | Allow ingress to OAuth proxy port |

## Health and Monitoring

### Liveness Probe

- **Endpoint**: /healthz
- **Port**: 8081
- **Protocol**: HTTP
- **Initial Delay**: 15 seconds
- **Period**: 20 seconds

### Readiness Probe

- **Endpoint**: /readyz
- **Port**: 8081
- **Protocol**: HTTP
- **Initial Delay**: 5 seconds
- **Period**: 10 seconds

### Metrics

- **Endpoint**: /metrics
- **Port**: 8080
- **Protocol**: HTTP
- **Format**: Prometheus

## OAuth Proxy Configuration (Injected Sidecar)

### Container Specification

| Property | Value |
|----------|-------|
| Image | registry.redhat.io/openshift4/ose-oauth-proxy@sha256:4bef31eb993feb6 |
| Port | 8443/TCP (oauth-proxy) |
| CPU Request/Limit | 100m |
| Memory Request/Limit | 64Mi |

### OAuth Proxy Arguments

| Argument | Value | Purpose |
|----------|-------|---------|
| --provider | openshift | Use OpenShift OAuth provider |
| --https-address | :8443 | Listen on port 8443 for HTTPS |
| --http-address | (empty) | Disable HTTP listener |
| --openshift-service-account | {notebook-name} | Use notebook-specific ServiceAccount |
| --cookie-secret-file | /etc/oauth/config/cookie_secret | Path to cookie encryption secret |
| --cookie-expire | 24h0m0s | Cookie expiration time |
| --tls-cert | /etc/tls/private/tls.crt | TLS certificate path |
| --tls-key | /etc/tls/private/tls.key | TLS key path |
| --upstream | http://localhost:8888 | Proxy to notebook container |
| --upstream-ca | /var/run/secrets/kubernetes.io/serviceaccount/ca.crt | CA for upstream verification |
| --email-domain | * | Allow all email domains |
| --skip-provider-button | (flag) | Skip OAuth provider selection |
| --openshift-sar | JSON with verb=get, resource=notebooks, resourceName={name}, namespace=$(NAMESPACE) | SubjectAccessReview for authorization |

### Volume Mounts (OAuth Proxy)

| Volume | Mount Path | Purpose |
|--------|------------|---------|
| oauth-config | /etc/oauth/config | OAuth cookie secret |
| tls-certificates | /etc/tls/private | Service CA TLS certificate and key |

## Error Handling and Edge Cases

### Mutually Exclusive Features

The webhook denies Notebook creation if both annotations are set:
- `notebooks.opendatahub.io/inject-oauth=true`
- `opendatahub.io/service-mesh=true`

**Error Message**: "Cannot have both opendatahub.io/service-mesh and notebooks.opendatahub.io/inject-oauth set to true. Pick one."

### Reconciliation Lock

The webhook injects a culling stop annotation (`notebooks.kubeflow.org/stop-annotation=odh-notebook-controller-lock`) to prevent the notebook pod from starting before all OAuth resources are created. The controller removes this annotation after first reconciliation completes successfully.

### Route Reconciliation

Routes are reconciled using retry logic with exponential backoff to handle conflicts when the OpenShift ingress controller updates the resource version (e.g., when setting the `.spec.host` field).

## Observability

### Logging

- **Format**: Structured JSON (zap logger)
- **Time Format**: RFC3339
- **Debug Mode**: Controlled by `--debug-log` flag
- **Log Levels**: Info, Error, Debug

### Key Log Events

| Event | Log Level | Context |
|-------|-----------|---------|
| Creating Route | Info | notebook={name}, namespace={ns} |
| Creating OAuth Service | Info | notebook={name}, namespace={ns} |
| Creating OAuth Secret | Info | notebook={name}, namespace={ns} |
| Reconciling Route | Info | Route spec manually modified |
| Reconciling Network Policy | Info | Policy spec manually modified |
| Webhook Admission | Info | Operation, resource name |
| RBAC Errors | Error | Unable to create/update resources |

## Controller Configuration Flags

| Flag | Default | Purpose |
|------|---------|---------|
| --metrics-bind-address | :8080 | Metrics server bind address |
| --health-probe-bind-address | :8081 | Health probe server bind address |
| --webhook-port | 8443 | Webhook server port |
| --oauth-proxy-image | registry.redhat.io/openshift4/ose-oauth-proxy@sha256:4bef31eb993feb6 | OAuth proxy sidecar image |
| --leader-elect | false | Enable leader election |
| --debug-log | false | Enable debug logging |

## Leader Election

When `--leader-elect` is enabled:
- **Leader Election ID**: odh-notebook-controller
- **Lock Type**: ConfigMap or Lease (coordination.k8s.io/v1)
- **Namespace**: Controller deployment namespace
- **Service Account**: manager

Only one replica actively reconciles resources; others wait as standby replicas.
