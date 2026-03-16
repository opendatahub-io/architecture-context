# Component: ODH Notebook Controller

## Metadata
- **Repository**: https://github.com/red-hat-data-services/kubeflow.git
- **Version**: v1.27.0-rhods-327-gc9976e28
- **Branch**: rhoai-2.12
- **Distribution**: RHOAI
- **Languages**: Go 1.21
- **Deployment Type**: Kubernetes Operator/Controller
- **Deployment Method**: Kustomize manifests in `components/odh-notebook-controller/config`

## Purpose
**Short**: Extends Kubeflow Notebooks with OpenShift-specific capabilities including OAuth authentication, route-based ingress, and network isolation.

**Detailed**: The ODH Notebook Controller watches Kubeflow Notebook custom resources and extends their functionality for OpenShift environments. It automatically creates OpenShift Routes for external access, optionally injects OAuth proxy sidecars for authentication and authorization through OpenShift RBAC, manages network policies for pod-level network isolation, and handles certificate trust bundles for secure communications. When the `notebooks.opendatahub.io/inject-oauth` annotation is set to true, the controller uses a mutating webhook to inject an OAuth proxy sidecar and creates all required supporting resources (ServiceAccount, Service, Secret, Route) to enable secure authenticated access to notebook workloads. The controller also reconciles ImageStream references to container images and manages CA certificate bundles for workbenches.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| OpenshiftNotebookReconciler | Controller | Reconciles Notebook CRs, creates Routes, Services, Secrets, ConfigMaps, and NetworkPolicies |
| NotebookWebhook | MutatingWebhook | Injects OAuth proxy sidecar, reconciliation locks, and CA bundles into Notebook pods |
| Manager | Deployment | Hosts the controller and webhook server |
| OAuth Proxy | Sidecar Container | Provides authentication and authorization for notebook access |

## APIs Exposed

### Custom Resource Definitions (CRDs)

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| kubeflow.org | v1 | Notebook | Namespaced | Defines Jupyter notebook workloads (watched, not owned by this controller) |

**Note**: This controller watches the `notebooks.kubeflow.org` CRD but does not own it. The CRD is managed by the upstream Kubeflow Notebook Controller.

### HTTP Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /metrics | GET | 8080/TCP | HTTP | None | None | Prometheus metrics |
| /healthz | GET | 8081/TCP | HTTP | None | None | Liveness probe |
| /readyz | GET | 8081/TCP | HTTP | None | None | Readiness probe |
| /mutate-notebook-v1 | POST | 8443/TCP | HTTPS | TLS 1.2+ | mTLS | Mutating webhook for Notebook resources |
| /oauth/healthz | GET | 8443/TCP | HTTPS | TLS 1.2+ | None | OAuth proxy health check (on notebook pods) |

### gRPC Services

None - this controller uses HTTP/HTTPS only.

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| Kubernetes | 1.29.0 | Yes | Container orchestration platform |
| OpenShift Route API | v1 | Yes | Ingress/external access to notebooks |
| OpenShift Config API | v1 | Yes | Cluster proxy configuration |
| OpenShift OAuth Proxy | latest | Yes | Authentication sidecar for notebooks |
| cert-manager / service-serving-cert | N/A | Yes | TLS certificate provisioning via annotation |

### Internal ODH Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| Kubeflow Notebook Controller | CRD (watches same resource) | Creates the StatefulSet for notebook pods; this controller extends functionality |
| ODH Operator | ConfigMap | Provides `odh-trusted-ca-bundle` ConfigMap for custom CA certificates |
| ImageStreams (OpenShift) | API | Resolves notebook container images from internal registry |

## Network Architecture

### Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| odh-notebook-controller-service | ClusterIP | 8080/TCP | 8080 | HTTP | None | None | Internal (metrics) |
| odh-notebook-controller-webhook-service | ClusterIP | 443/TCP | 8443 | HTTPS | TLS 1.2+ | mTLS | Internal (webhook) |
| {notebook-name}-tls | ClusterIP | 443/TCP | 8443 | HTTPS | TLS 1.2+ | mTLS | Internal (OAuth notebooks) |

### Ingress

| Name | Type | Hosts | Port | Protocol | Encryption | TLS Mode | Exposure |
|------|------|-------|------|----------|------------|----------|----------|
| {notebook-name} | OpenShift Route | auto-assigned | 443/TCP | HTTPS | TLS 1.2+ | Edge (non-OAuth) or Reencrypt (OAuth) | External |

**Notes**:
- Routes are created automatically for each Notebook
- Non-OAuth notebooks use Edge termination (TLS terminates at router)
- OAuth-enabled notebooks use Reencrypt termination (TLS from router to OAuth proxy)
- InsecureEdgeTerminationPolicy is set to Redirect (HTTP → HTTPS)

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token | Watch Notebook CRs, manage resources |
| OpenShift API Server | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token | Manage Routes, ImageStreams |
| Container Registries | 443/TCP | HTTPS | TLS 1.2+ | Pull Secrets | Pull OAuth proxy and notebook images |

## Security

### RBAC - Cluster Roles

| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|
| manager-role | kubeflow.org | notebooks, notebooks/status, notebooks/finalizers | get, list, watch, patch, update |
| manager-role | route.openshift.io | routes | get, list, watch, create, update, patch |
| manager-role | "" (core) | services, serviceaccounts, secrets, configmaps | get, list, watch, create, update, patch |
| manager-role | config.openshift.io | proxies | get, list, watch |
| manager-role | networking.k8s.io | networkpolicies | get, list, watch, create, update, patch |
| notebooks-edit | kubeflow.org | notebooks, notebooks/status | get, list, watch, create, delete, deletecollection, patch, update |
| notebooks-view | kubeflow.org | notebooks, notebooks/status | get, list, watch |
| leader-election-role (namespaced) | "" (core) | configmaps | get, list, watch, create, update, patch, delete |
| leader-election-role (namespaced) | coordination.k8s.io | leases | get, list, watch, create, update, patch, delete |
| leader-election-role (namespaced) | "" (core) | events | create, patch |

### RBAC - Role Bindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| manager-rolebinding | N/A (cluster) | manager-role (ClusterRole) | odh-notebook-controller-manager |
| leader-election-rolebinding | controller namespace | leader-election-role (Role) | odh-notebook-controller-manager |

**Note**: User roles (notebooks-edit, notebooks-view, notebooks-admin) aggregate to standard Kubernetes roles (edit, view, admin).

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| odh-notebook-controller-webhook-cert | kubernetes.io/tls | Webhook server TLS certificate | service.beta.openshift.io/serving-cert-secret-name annotation | Yes (OpenShift service CA) |
| {notebook-name}-oauth-config | Opaque | OAuth proxy cookie secret (random base64) | ODH Notebook Controller | No |
| {notebook-name}-tls | kubernetes.io/tls | OAuth proxy TLS certificate | service.beta.openshift.io/serving-cert-secret-name annotation | Yes (OpenShift service CA) |

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| /mutate-notebook-v1 | POST | mTLS (Kubernetes API Server) | Kubernetes API Server | MutatingWebhookConfiguration |
| /metrics | GET | None | N/A | Internal only (ClusterIP) |
| Notebook (OAuth) | ALL | OpenShift OAuth + Bearer Token | OAuth Proxy Sidecar | OpenShift SAR: get notebooks.kubeflow.org/{name} |
| Notebook (non-OAuth) | ALL | None | N/A | Public access via Route |

**OAuth Authorization Details**:
- OAuth proxy uses `--openshift-sar` flag with SubjectAccessReview
- Required permission: `GET` on `notebooks.kubeflow.org` resource with the notebook's name
- Example: User must be able to run `oc get notebook {notebook-name} -n {namespace}`
- Enforced through OpenShift RBAC (notebooks-view, notebooks-edit, or custom roles)

## Data Flows

### Flow 1: Notebook Creation (OAuth Enabled)

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User/Client | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | User credentials |
| 2 | Kubernetes API | ODH Notebook Controller Webhook | 8443/TCP | HTTPS | TLS 1.2+ (mTLS) | K8s API client cert |
| 3 | Webhook | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 4 | Controller (watch event) | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 5 | Controller | Kubernetes API (create ServiceAccount) | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 6 | Controller | Kubernetes API (create Service) | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 7 | Controller | Kubernetes API (create Secret) | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 8 | Controller | Kubernetes API (create Route) | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 9 | Controller | Kubernetes API (create NetworkPolicies) | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |

### Flow 2: Notebook Access (OAuth Enabled)

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User Browser | OpenShift Router | 443/TCP | HTTPS | TLS 1.3 | None |
| 2 | OpenShift Router | OAuth Proxy (notebook pod) | 8443/TCP | HTTPS | TLS 1.2+ | Route passthrough |
| 3 | OAuth Proxy | OpenShift OAuth Server | 443/TCP | HTTPS | TLS 1.2+ | OAuth flow |
| 4 | OAuth Proxy | Kubernetes API (SAR check) | 6443/TCP | HTTPS | TLS 1.2+ | User token |
| 5 | OAuth Proxy | Notebook Container | 8888/TCP | HTTP | None | Localhost |

### Flow 3: Notebook Access (Non-OAuth)

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User Browser | OpenShift Router | 443/TCP | HTTPS | TLS 1.3 | None |
| 2 | OpenShift Router | Notebook Service | 8888/TCP | HTTP | None | None |
| 3 | Notebook Service | Notebook Container | 8888/TCP | HTTP | None | None |

### Flow 4: Webhook Admission

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Kubernetes API | Webhook Service | 443/TCP | HTTPS | TLS 1.2+ (mTLS) | K8s API client cert |
| 2 | Webhook Service | Controller Pod | 8443/TCP | HTTPS | TLS 1.2+ | Service routing |
| 3 | Webhook | ImageStream API (optional) | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| Kubernetes API Server | REST API | 6443/TCP | HTTPS | TLS 1.2+ | Watch Notebooks, create/update resources |
| Kubeflow Notebook Controller | CRD (shared) | N/A | N/A | N/A | Creates StatefulSets; ODH controller extends functionality |
| OpenShift Router | Route | 443/TCP | HTTPS | TLS 1.3 | External ingress to notebooks |
| OpenShift OAuth Server | OAuth 2.0 | 443/TCP | HTTPS | TLS 1.2+ | User authentication for notebooks |
| OpenShift Service CA | Certificate Annotation | N/A | N/A | N/A | Auto-provision TLS certificates for services |
| OpenShift ImageStream API | REST API | 6443/TCP | HTTPS | TLS 1.2+ | Resolve container image references |
| Prometheus | Metrics scraping | 8080/TCP | HTTP | None | Controller metrics collection |

## Network Policies

The controller creates two NetworkPolicies per notebook:

### Policy 1: Notebook Controller Access

| Field | Value |
|-------|-------|
| Name | {notebook-name}-ctrl-np |
| Pod Selector | notebook-name={notebook-name} |
| Policy Type | Ingress |
| Ingress From | Namespace with label `kubernetes.io/metadata.name={controller-namespace}` |
| Ingress Port | 8888/TCP |
| Purpose | Allow controller namespace to access notebook application port |

### Policy 2: OAuth Proxy Access

| Field | Value |
|-------|-------|
| Name | {notebook-name}-oauth-np |
| Pod Selector | notebook-name={notebook-name} |
| Policy Type | Ingress |
| Ingress From | All (empty array) |
| Ingress Port | 8443/TCP |
| Purpose | Allow external access to OAuth proxy port |

## ConfigMaps

| ConfigMap Name | Namespace | Purpose | Managed By |
|----------------|-----------|---------|------------|
| odh-trusted-ca-bundle | Notebook namespace | Contains custom CA certificates (ca-bundle.crt, odh-ca-bundle.crt) | ODH Operator |
| kube-root-ca.crt | Notebook namespace | Contains cluster self-signed CA (ca.crt) | Kubernetes |
| workbench-trusted-ca-bundle | Notebook namespace | Merged CA bundle for notebook consumption | ODH Notebook Controller |

**Certificate Injection**:
- Controller watches `odh-trusted-ca-bundle` and `kube-root-ca.crt`
- Merges valid PEM certificates into `workbench-trusted-ca-bundle`
- Webhook mounts ConfigMap to notebooks at `/etc/pki/tls/custom-certs/ca-bundle.crt`
- Sets environment variables: `PIP_CERT`, `REQUESTS_CA_BUNDLE`, `SSL_CERT_FILE`, `PIPELINES_SSL_SA_CERTS`, `GIT_SSL_CAINFO`

## Deployment Configuration

### Container Image
- Built from: `components/odh-notebook-controller/Dockerfile`
- Base image: `registry.access.redhat.com/ubi8/go-toolset:1.21` (builder)
- Runtime image: `registry.access.redhat.com/ubi8/ubi-minimal:latest`
- Runs as: non-root user `rhods` (UID 1001)

### Resource Limits

| Container | CPU Request | Memory Request | CPU Limit | Memory Limit |
|-----------|-------------|----------------|-----------|--------------|
| manager | 500m | 256Mi | 500m | 4Gi |
| oauth-proxy (notebook sidecar) | 100m | 64Mi | 100m | 64Mi |

### Environment Variables

| Variable | Source | Purpose |
|----------|--------|---------|
| --metrics-bind-address | Flag | Metrics server address (default: :8080) |
| --health-probe-bind-address | Flag | Health probe address (default: :8081) |
| --webhook-port | Flag | Webhook server port (default: 8443) |
| --oauth-proxy-image | Flag | OAuth proxy image to inject (default: registry.redhat.io/openshift4/ose-oauth-proxy@sha256:4bef31...) |
| --leader-elect | Flag | Enable leader election (default: false) |

## Annotations

| Annotation | Target | Values | Purpose |
|------------|--------|--------|---------|
| notebooks.opendatahub.io/inject-oauth | Notebook | "true" / "false" | Enable OAuth proxy injection |
| notebooks.opendatahub.io/oauth-logout-url | Notebook | URL | Custom logout URL for OAuth proxy |
| notebooks.opendatahub.io/last-image-selection | Notebook | imagestream:tag | ImageStream reference for container image |
| kubeflow.org/last-applied-stop-annotation | Notebook | odh-notebook-controller-lock | Reconciliation lock (prevents premature pod start) |
| service.beta.openshift.io/serving-cert-secret-name | Service | secret-name | Trigger OpenShift service CA cert provisioning |
| serviceaccounts.openshift.io/oauth-redirectreference.first | ServiceAccount | JSON | OAuth redirect configuration |

## Recent Changes

| Commit | Date | Changes |
|--------|------|---------|
| c9976e28 | 2026-03 | Merge pull request #92 from harshad16/sync-stable |
| 1236dce6 | 2026-03 | Merge branch 'stable' of https://github.com/opendatahub-io/kubeflow into sync-stable |
| 8ddd516f | 2026-03 | Merge pull request #370 from atheo89/cherrypick-to-stable |
| ab40abf6 | 2026-03 | Merge pull request #368 from openshift-cherrypick-robot/cherry-pick-363-to-stable |
| b8f58cc1 | 2026-02 | Update kustomization to use params env and yml on notebook-controller and odh-notebook-controller (#364) |
| 3321e726 | 2026-02 | update the contributing guide |
| 27202f26 | 2026-02 | Update OWNERS file with adding more approvers |
| a03ec636 | 2026-02 | Merge pull request #90 from opendatahub-io/stable |
| ee922b9c | 2026-01 | chore: add `.snyk` config file to ignore directories that we don't build ODH from |
| 750bf133 | 2025-12 | Merge pull request #68 from opendatahub-io/stable |

## Special Features

### ImageStream Resolution
The webhook resolves ImageStream references to actual container image digests:
- Checks annotation `notebooks.opendatahub.io/last-image-selection` for imagestream:tag format
- Queries OpenShift ImageStream API in `opendatahub` and `redhat-ods-applications` namespaces
- Extracts `status.tags[].items[].dockerImageReference` from matching ImageStream
- Updates notebook container image to use digest reference
- Falls back to internal registry if detected: `image-registry.openshift-image-registry.svc:5000`

### Reconciliation Lock
The webhook injects a reconciliation lock annotation on notebook creation:
- Annotation: `kubeflow.org/last-applied-stop-annotation: odh-notebook-controller-lock`
- Prevents Kubeflow controller from starting the notebook pod prematurely
- Allows ODH controller to complete setup (ServiceAccount with pull secrets)
- Controller removes lock after verifying ServiceAccount has ImagePullSecrets mounted
- Uses exponential backoff: 3 steps, 1s initial, 5.0x factor

### Leader Election
Controller supports leader election for high availability:
- Uses `coordination.k8s.io/v1` Lease resource
- Lease name: `odh-notebook-controller`
- Configured via `--leader-elect` flag (default: false)
- Ensures only one active controller instance

## Known Limitations

1. **No CRD Ownership**: This controller does not own the Notebook CRD; it's managed by Kubeflow Notebook Controller
2. **OpenShift Specific**: Requires OpenShift APIs (Route, OAuth, Service CA) - not portable to vanilla Kubernetes
3. **Namespace Assumptions**: Falls back to `redhat-ods-applications` namespace for controller namespace detection
4. **ImageStream Namespaces**: Only searches `opendatahub` and `redhat-ods-applications` namespaces for ImageStreams
5. **No Egress NetworkPolicy**: Only ingress policies are created; egress is unrestricted

## Observability

### Metrics
- Exposed on port 8080 at `/metrics`
- Standard controller-runtime metrics (reconciliation, queue depth, etc.)
- Prometheus format

### Health Checks
- Liveness: `/healthz` on port 8081
- Readiness: `/readyz` on port 8081
- Initial delay: 15s (liveness), 5s (readiness)
- Period: 20s (liveness), 10s (readiness)

### Logging
- Structured logging via zap logger
- Log levels: info, debug (via `--debug-log` flag)
- Time format: RFC3339
- Context: includes notebook name and namespace

## Testing

### Unit Tests
- Framework: Kubernetes envtest
- Command: `make test`
- Coverage: Controller reconciliation logic, webhook mutations, network policies

### E2E Tests
- Framework: Ginkgo/Gomega
- Command: `make e2e-test -e K8S_NAMESPACE=<namespace>`
- Tests: Notebook creation, update, deletion, OAuth injection
- Flags: `--skip-deletion` to skip deletion tests

### Test Suites
1. `notebook_creation_test.go` - Notebook creation scenarios
2. `notebook_update_test.go` - Notebook update scenarios
3. `notebook_deletion_test.go` - Notebook deletion and cleanup
4. `notebook_controller_test.go` - Controller reconciliation logic
