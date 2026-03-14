# Component: ODH Notebook Controller

## Metadata
- **Repository**: https://github.com/red-hat-data-services/kubeflow.git
- **Version**: v1.27.0-rhods-1417-gc0b85e2f
- **Branch**: rhoai-3.3
- **Distribution**: RHOAI
- **Languages**: Go 1.25.3
- **Deployment Type**: Kubernetes Operator (Controller)
- **Build System**: Konflux (Dockerfile.konflux)

## Purpose
**Short**: Kubernetes operator that extends Kubeflow Notebook functionality with OpenShift integration, Gateway API routing, and RBAC-based authentication.

**Detailed**: The ODH Notebook Controller watches Kubeflow Notebook custom resources and enriches them with OpenShift-specific capabilities. It automatically creates HTTPRoute resources for Gateway API integration, enabling external access to notebook instances through the data-science-gateway. When notebooks are annotated with `notebooks.opendatahub.io/inject-auth: "true"`, the controller injects kube-rbac-proxy sidecars via a mutating webhook to provide Kubernetes RBAC-based authentication and authorization. The controller also manages network policies, service accounts, roles, and TLS certificates to ensure secure notebook access. It integrates with Data Science Pipelines to automatically provision secrets and RBAC for pipeline access from notebooks.

The controller uses Kubebuilder framework and implements a reconciliation loop that creates and maintains supporting resources for each Notebook CR including HTTPRoutes, ReferenceGrants, NetworkPolicies, Services, ConfigMaps, Secrets, and RBAC objects. It ensures notebooks are properly exposed through the Gateway API with appropriate authentication and network isolation.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| OpenshiftNotebookReconciler | Controller | Main reconciliation loop for Notebook CRs |
| NotebookWebhook | Mutating Webhook | Injects kube-rbac-proxy sidecar into notebook pods |
| HTTPRoute Manager | Resource Controller | Creates Gateway API HTTPRoutes for notebook access |
| ReferenceGrant Manager | Resource Controller | Creates ReferenceGrants for cross-namespace routing |
| NetworkPolicy Manager | Resource Controller | Creates NetworkPolicies for traffic isolation |
| RBAC Manager | Resource Controller | Creates ServiceAccounts, Roles, and RoleBindings |
| kube-rbac-proxy Config Generator | Config Manager | Generates kube-rbac-proxy sidecar configuration |
| DSPA Integration | Resource Controller | Provisions Data Science Pipeline secrets and RBAC |

## APIs Exposed

### Custom Resource Definitions (CRDs)

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| kubeflow.org | v1 | Notebook | Namespaced | Defines Jupyter notebook instances (watched, not owned by controller) |
| gateway.networking.k8s.io | v1 | HTTPRoute | Namespaced | Routes external traffic to notebook services (created by controller) |
| gateway.networking.k8s.io | v1beta1 | ReferenceGrant | Namespaced | Permits cross-namespace service references (created by controller) |
| gateway.networking.k8s.io | v1 | Gateway | Namespaced | Gateway configuration (referenced, not created) |
| datasciencepipelinesapplications.opendatahub.io | v1 | DataSciencePipelinesApplication | Namespaced | Pipeline configuration (watched for integration) |
| image.openshift.io | v1 | ImageStream | Namespaced | Container image metadata (watched) |

### HTTP Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /metrics | GET | 8080/TCP | HTTP | None | None | Prometheus metrics endpoint |
| /healthz | GET | 8081/TCP | HTTP | None | None | Liveness probe endpoint |
| /readyz | GET | 8081/TCP | HTTP | None | None | Readiness probe endpoint |
| /mutate-notebook-v1 | POST | 8443/TCP | HTTPS | TLS 1.2+ | mTLS | Mutating webhook for Notebook CRs |

### Webhook Admission Controllers

| Name | Type | Resources | Operations | Path |
|------|------|-----------|------------|------|
| notebooks.opendatahub.io | MutatingWebhook | notebooks.kubeflow.org/v1 | CREATE, UPDATE | /mutate-notebook-v1 |

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| Kubeflow Notebook Controller | v1 | Yes | Creates Notebook StatefulSets and base Services |
| Gateway API | v1.2.1 | Yes | Provides HTTPRoute and Gateway CRDs for routing |
| OpenShift Service CA Operator | 4.19+ | Yes | Provisions TLS certificates for webhooks and services |
| kube-rbac-proxy | Latest | Yes | Sidecar proxy for RBAC-based authentication |
| Kubernetes | 1.33+ | Yes | Core Kubernetes APIs |
| OpenShift | 4.19+ | Yes | OpenShift-specific APIs (Route, ImageStream, OAuthClient) |
| controller-runtime | v0.21.0 | Yes | Controller framework and client libraries |

### Internal ODH Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| Data Science Gateway | Gateway API (HTTPRoute) | Routes external traffic to notebooks |
| Data Science Pipelines Operator | CRD Watch (DSPA) | Provisions pipeline secrets and RBAC for notebooks |
| ODH Dashboard | Notebook CRD | Dashboard creates Notebook CRs that this controller enhances |
| Trusted CA Bundle | ConfigMap Mount | Provides CA certificates for secure connections |

## Network Architecture

### Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| odh-notebook-controller-service | ClusterIP | 8080/TCP | 8080 | HTTP | None | None | Internal (metrics) |
| odh-notebook-controller-webhook-service | ClusterIP | 443/TCP | 8443 | HTTPS | TLS 1.2+ | mTLS (client cert from K8s API) | Internal (webhook) |
| {notebook-name}-kube-rbac-proxy | ClusterIP | 8443/TCP | 8443 | HTTPS | TLS 1.2+ | mTLS (service-ca cert) | Internal (notebook auth proxy) |
| {notebook-name} | ClusterIP | 80/TCP | 8888 | HTTP | None | None | Internal (created by notebook-controller) |

### Ingress

| Name | Type | Hosts | Port | Protocol | Encryption | TLS Mode | Exposure |
|------|------|-------|------|----------|------------|----------|----------|
| nb-{namespace}-{notebook-name} | HTTPRoute | data-science-gateway hostname | 443/TCP | HTTPS | TLS 1.2+ | Edge (terminated at Gateway) | External |

### HTTPRoute Configuration

| HTTPRoute Name | Parent Gateway | Backend Service | Path | Namespace Model |
|----------------|----------------|-----------------|------|-----------------|
| nb-{user-namespace}-{notebook-name} | data-science-gateway (openshift-ingress) | {notebook-name}-kube-rbac-proxy or {notebook-name} | /notebook/{namespace}/{name} | Cross-namespace (HTTPRoute in controller namespace, Service in user namespace) |

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| Kubernetes API Server | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token | Controller operations, SubjectAccessReviews |
| Data Science Pipelines API | 8888/TCP | HTTPS | TLS 1.2+ | Bearer Token | Pipeline integration (optional) |
| Image Registry | 443/TCP | HTTPS | TLS 1.2+ | Pull Secrets | Container image pulls |
| OpenShift Proxy | 443/TCP | HTTPS | TLS 1.2+ | None | Cluster-wide proxy configuration (optional) |

## Security

### RBAC - Cluster Roles

| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|
| odh-notebook-controller-manager-role | kubeflow.org | notebooks, notebooks/status, notebooks/finalizers | get, list, watch, patch, update |
| odh-notebook-controller-manager-role | gateway.networking.k8s.io | httproutes, referencegrants | get, list, watch, create, update, patch, delete |
| odh-notebook-controller-manager-role | gateway.networking.k8s.io | gateways | get, list, watch |
| odh-notebook-controller-manager-role | "" (core) | services, serviceaccounts, secrets, configmaps | get, list, watch, create, update, patch |
| odh-notebook-controller-manager-role | networking.k8s.io | networkpolicies, networkpolicies/finalizers | get, list, watch, create, update, patch |
| odh-notebook-controller-manager-role | rbac.authorization.k8s.io | roles, rolebindings, clusterrolebindings | get, list, watch, create, update, patch, delete |
| odh-notebook-controller-manager-role | authentication.k8s.io | tokenreviews | create |
| odh-notebook-controller-manager-role | authorization.k8s.io | subjectaccessreviews | create |
| odh-notebook-controller-manager-role | oauth.openshift.io | oauthclients | get, list, watch, update, patch, delete |
| odh-notebook-controller-manager-role | datasciencepipelinesapplications.opendatahub.io | datasciencepipelinesapplications, datasciencepipelinesapplications/api | get, list, watch, create, update, patch, delete |
| odh-notebook-controller-manager-role | image.openshift.io | imagestreams | get, list, watch |
| odh-notebook-controller-manager-role | config.openshift.io | proxies | get, list, watch |
| odh-notebook-controller-manager-role | route.openshift.io | routes | get, list, watch |
| notebooks-admin | kubeflow.org | notebooks, notebooks/status | all (aggregates to admin role) |
| notebooks-edit | kubeflow.org | notebooks, notebooks/status | get, list, watch, create, delete, deletecollection, patch, update |
| notebooks-view | kubeflow.org | notebooks, notebooks/status | get, list, watch |

### RBAC - Namespace Roles

| Role Name | API Group | Resources | Verbs | Namespace |
|-----------|-----------|-----------|-------|-----------|
| odh-notebook-controller-leader-election-role | "" (core) | configmaps | get, list, watch, create, update, patch, delete | Controller namespace |
| odh-notebook-controller-leader-election-role | coordination.k8s.io | leases | get, list, watch, create, update, patch, delete | Controller namespace |
| odh-notebook-controller-leader-election-role | "" (core) | events | create, patch | Controller namespace |

### RBAC - Role Bindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| odh-notebook-controller-manager-rolebinding | Cluster-wide | odh-notebook-controller-manager-role (ClusterRole) | manager (controller namespace) |
| odh-notebook-controller-leader-election-rolebinding | Controller namespace | odh-notebook-controller-leader-election-role (Role) | manager (controller namespace) |
| {notebook-name}-sa-rb | User namespace | {dspa-name}-dspa (Role) | {notebook-name} (user namespace) |

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| odh-notebook-controller-webhook-cert | kubernetes.io/tls | Webhook server TLS certificate | service-ca-operator | Yes (30 days) |
| {notebook-name}-tls-proxy-serving-cert | kubernetes.io/tls | kube-rbac-proxy TLS certificate | service-ca-operator | Yes (30 days) |
| {notebook-name}-{dspa-name}-token | Opaque | Data Science Pipeline API token | odh-notebook-controller | No |

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| /mutate-notebook-v1 | POST | mTLS client certificate | Kubernetes API Server | API server validates webhook certificate from service-ca |
| /notebook/{ns}/{name} (with auth) | ALL | Bearer Token (OAuth) + RBAC | kube-rbac-proxy sidecar | SubjectAccessReview: user must have "get" permission on Notebook CR |
| /notebook/{ns}/{name} (no auth) | ALL | None | None | Direct access to notebook service |
| /metrics | GET | None | None | Internal cluster access only |
| /healthz, /readyz | GET | None | None | Internal cluster access only |

### kube-rbac-proxy Authorization

When `notebooks.opendatahub.io/inject-auth: "true"` annotation is set:

| Component | Authorization Method | Required Permission |
|-----------|---------------------|---------------------|
| kube-rbac-proxy sidecar | SubjectAccessReview | User must have "get" verb on Notebook CR in notebook namespace |

Example authorization configuration:
```yaml
authorization:
  resourceAttributes:
    verb: get
    resource: notebooks
    apiGroup: kubeflow.org
    name: {notebook-name}
    namespace: {notebook-namespace}
```

### Network Policies

| Policy Name | Pod Selector | Ingress From | Ingress Ports | Purpose |
|-------------|--------------|--------------|---------------|---------|
| {notebook-name}-ctrl-np | notebook-name={notebook-name} | namespace=controller-namespace | 8888/TCP | Allow traffic from controller namespace to notebook container |
| {notebook-name}-kube-rbac-proxy-np | notebook-name={notebook-name} | namespace=controller-namespace | 8443/TCP, 8444/TCP | Allow traffic from controller namespace to kube-rbac-proxy |

## Data Flows

### Flow 1: User Access to Notebook (with Authentication)

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User Browser | Gateway (openshift-ingress) | 443/TCP | HTTPS | TLS 1.2+ | OpenShift OAuth |
| 2 | Gateway | kube-rbac-proxy sidecar | 8443/TCP | HTTPS | TLS 1.2+ (service-ca) | Bearer Token passthrough |
| 3 | kube-rbac-proxy | Kubernetes API Server | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 4 | kube-rbac-proxy | Jupyter Notebook container | 8888/TCP | HTTP | None | None (localhost) |

### Flow 2: User Access to Notebook (without Authentication)

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User Browser | Gateway (openshift-ingress) | 443/TCP | HTTPS | TLS 1.2+ | OpenShift OAuth |
| 2 | Gateway | Notebook Service | 80/TCP | HTTP | None | None |
| 3 | Notebook Service | Jupyter Notebook container | 8888/TCP | HTTP | None | None |

### Flow 3: Webhook Mutation

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Kubernetes API Server | odh-notebook-controller webhook | 443/TCP | HTTPS | TLS 1.2+ | mTLS (client cert validation) |
| 2 | Webhook Handler | Kubernetes API Server | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |

### Flow 4: Controller Reconciliation

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Notebook Controller | Kubernetes API Server | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 2 | Notebook Controller | Kubernetes API Server (create/update resources) | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |

### Flow 5: Data Science Pipeline Integration

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Notebook Controller | Kubernetes API Server (watch DSPA) | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 2 | Notebook Controller | DSPA API | 8888/TCP | HTTPS | TLS 1.2+ | Token from Secret |
| 3 | Notebook Controller | Kubernetes API Server (create Secret) | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| Kubernetes API Server | REST API | 443/TCP | HTTPS | TLS 1.2+ | All controller operations, watches, creates, updates |
| Gateway API (data-science-gateway) | CRD (HTTPRoute) | N/A | N/A | N/A | External routing configuration for notebooks |
| Kubeflow Notebook Controller | CRD Watch | N/A | N/A | N/A | Watches Notebook CRs created by notebook-controller |
| Data Science Pipelines Operator | CRD Watch | N/A | N/A | N/A | Watches DSPA CRs for pipeline integration |
| OpenShift Service CA Operator | Certificate Provisioning | N/A | N/A | N/A | TLS certificate generation via annotation |
| kube-rbac-proxy | Sidecar Injection | 8443/TCP | HTTPS | mTLS | Injected via webhook for authentication |
| OpenShift OAuth | Token Validation | 443/TCP | HTTPS | TLS 1.2+ | User authentication for notebook access |

## Configuration

### Environment Variables

| Variable | Default | Purpose |
|----------|---------|---------|
| K8S_NAMESPACE | /var/run/secrets/.../namespace | Controller deployment namespace |
| NOTEBOOK_GATEWAY_NAME | data-science-gateway | Gateway name for HTTPRoute parent reference |
| NOTEBOOK_GATEWAY_NAMESPACE | openshift-ingress | Gateway namespace for HTTPRoute parent reference |
| SET_PIPELINE_RBAC | true | Enable RBAC creation for pipeline access |
| SET_PIPELINE_SECRET | true | Enable secret creation for pipeline access |
| INJECT_CLUSTER_PROXY_ENV | (from ConfigMap) | Inject cluster-wide proxy environment variables |

### Command-Line Flags

| Flag | Default | Purpose |
|------|---------|---------|
| --metrics-bind-address | :8080 | Metrics server listen address |
| --health-probe-bind-address | :8081 | Health probe server listen address |
| --webhook-port | 8443 | Webhook server listen port |
| --webhook-cert-dir | /tmp/k8s-webhook-server/serving-certs | TLS certificate directory |
| --kube-rbac-proxy-image | (required) | kube-rbac-proxy container image |
| --leader-elect | false | Enable leader election |
| --debug-log | false | Enable debug logging |

### Annotations

| Annotation | Values | Purpose |
|------------|--------|---------|
| notebooks.opendatahub.io/inject-auth | "true", "false" | Enable kube-rbac-proxy sidecar injection |
| notebooks.opendatahub.io/auth-sidecar-cpu-request | CPU quantity | kube-rbac-proxy CPU request (default: 100m) |
| notebooks.opendatahub.io/auth-sidecar-memory-request | Memory quantity | kube-rbac-proxy memory request (default: 64Mi) |
| notebooks.opendatahub.io/auth-sidecar-cpu-limit | CPU quantity | kube-rbac-proxy CPU limit (default: 100m) |
| notebooks.opendatahub.io/auth-sidecar-memory-limit | Memory quantity | kube-rbac-proxy memory limit (default: 64Mi) |
| kubeflow.org/last-activity | RFC3339 timestamp | Reconciliation lock (value: odh-notebook-controller-lock) |

## Deployment

### Container Images

| Image | Purpose | Build |
|-------|---------|-------|
| rhoai/odh-notebook-controller-rhel9 | Controller manager | Built via Konflux with FIPS-compliant Go 1.25 |
| kube-rbac-proxy | Authentication proxy sidecar | Injected into notebook pods (image specified via flag) |

### Resource Requirements

| Component | CPU Request | Memory Request | CPU Limit | Memory Limit |
|-----------|-------------|----------------|-----------|--------------|
| odh-notebook-controller manager | 500m | 256Mi | 500m | 4Gi |
| kube-rbac-proxy sidecar (default) | 100m | 64Mi | 100m | 64Mi |

### Deployment Strategy

| Parameter | Value |
|-----------|-------|
| Replicas | 1 |
| Strategy | RollingUpdate |
| MaxSurge | 0 |
| MaxUnavailable | 100% |
| Termination Grace Period | 10s |
| Security Context | runAsNonRoot: true, allowPrivilegeEscalation: false |
| Service Account | odh-notebook-controller-manager |

## Recent Changes

| Commit | Date | Changes |
|--------|------|---------|
| c0b85e2f | 2026-03-12 | chore(deps): update registry.access.redhat.com/ubi9/go-toolset:1.25 docker digest to 3cdf0d1 |
| 4b0820a6 | 2026-03-11 | chore(deps): update registry.access.redhat.com/ubi9/ubi-minimal docker digest to 69f5c98 |
| 3d800f70 | 2026-03-10 | chore(deps): update registry.access.redhat.com/ubi9/go-toolset:1.25 docker digest to 6da1160 |
| 6d0e8ac1 | 2026-03-09 | chore(deps): update registry.access.redhat.com/ubi9/go-toolset:1.25 docker digest to 71101fd |
| 8f1e99f6 | 2026-03-05 | chore(deps): update registry.access.redhat.com/ubi9/go-toolset:1.25 docker digest to e421039 |
| 40220ee0 | 2026-03-04 | sync pipelineruns with konflux-central - 9fd8f6f |
| 3c455faa | 2026-03-02 | chore(deps): update registry.access.redhat.com/ubi9/go-toolset:1.25 docker digest to b3b98e0 |
| c8a78fbd | 2026-03-02 | chore(deps): update registry.access.redhat.com/ubi9/go-toolset:1.25 docker digest to 3efce46 |
| 72c632ba | 2026-02-19 | Merge pull request #1057 from red-hat-data-services/moulalis-patch-3 |
| f593fbff | 2026-02-19 | Update odh-notebook-controller-v3-3-push.yaml |
| 8da200e3 | 2026-02-18 | chore(deps): update registry.access.redhat.com/ubi9/go-toolset:1.25 docker digest to 799cc02 |
| 834f9c07 | 2026-02-17 | chore(deps): update registry.access.redhat.com/ubi9/ubi-minimal docker digest to c7d4414 |
| b3dd9f21 | 2026-02-17 | chore(deps): update registry.access.redhat.com/ubi9/go-toolset:1.25 docker digest to 4c0a6ea |
| 03684d45 | 2026-02-11 | chore(deps): update registry.access.redhat.com/ubi9/go-toolset:1.25 docker digest to 82b82ec |
| 98f52fc9 | 2026-02-09 | chore(deps): update registry.access.redhat.com/ubi9/go-toolset:1.25 docker digest to 6983c6e |

## Notes

### Migration from RHOAI 2.x to 3.x

The controller includes backward compatibility code for migrating from RHOAI 2.x:
- **OAuthClient cleanup**: RHOAI 2.x created OAuthClient CRs for each notebook. These are no longer used in RHOAI 3.x (replaced by OpenShift OAuth integration). The controller includes finalizer logic to clean up legacy OAuthClient resources during notebook deletion.
- **Gateway API migration**: RHOAI 3.x uses Gateway API (HTTPRoute) instead of OpenShift Routes for notebook exposure. The controller creates HTTPRoutes in the central controller namespace with cross-namespace references to user notebook services.

### Cross-Namespace Architecture

The controller implements a cross-namespace architecture for security isolation:
- **HTTPRoute placement**: HTTPRoutes are created in the controller's namespace (e.g., `redhat-ods-applications`) rather than user namespaces
- **ReferenceGrants**: Created to permit HTTPRoutes to reference Services in user namespaces
- **NetworkPolicies**: Ensure only traffic from the controller namespace can reach notebook pods
- **Naming convention**: HTTPRoutes use `nb-{user-namespace}-{notebook-name}` naming to avoid conflicts

### FIPS Compliance

The controller is built with FIPS-compliant Go 1.25 using strict FIPS runtime mode:
```bash
CGO_ENABLED=1 GOEXPERIMENT=strictfipsruntime go build -tags strictfipsruntime
```

This ensures all cryptographic operations use FIPS 140-2 validated modules.

### Test Infrastructure

- **Unit tests**: Kubernetes envtest framework with Ginkgo/Gomega
- **E2E tests**: Full integration tests with notebook-controller and gateway
- **Debug features**: Kubeconfig export and audit log capture for test debugging
