# Component: Kubeflow Notebook Controllers

## Metadata
- **Repository**: https://github.com/opendatahub-io/kubeflow
- **Version**: v1.7.0-15-519
- **Distribution**: Both ODH and RHOAI
- **Languages**: Go 1.25.7
- **Deployment Type**: Kubernetes Operators (Controller-Runtime based)

## Purpose
**Short**: Manages the lifecycle of Jupyter notebook instances in Kubernetes for machine learning workloads.

**Detailed**: This repository contains two complementary Kubernetes operators that manage Jupyter notebook environments for data science and machine learning workflows. The `notebook-controller` is the upstream Kubeflow component that provides core notebook lifecycle management including creation, deletion, and culling of idle notebooks. The `odh-notebook-controller` extends this functionality with OpenShift and OpenDataHub-specific features including OAuth integration, network policies, OpenShift Routes, Data Science Pipelines integration, and Gateway API support. Together, these controllers enable users to create and manage secure, multi-tenant notebook environments with integrated access to data science tools and services.

Both controllers reconcile the `Notebook` CRD (Custom Resource Definition) which represents a Jupyter notebook instance. When a Notebook resource is created, the controllers provision a StatefulSet with the notebook server container, configure networking (Services, Routes, VirtualServices, or HTTPRoutes), set up authentication (OAuth or service mesh), establish RBAC permissions, and optionally inject configuration for integrated services like Data Science Pipelines and Feast. The culling controller monitors notebook activity and automatically stops idle notebooks to conserve resources.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| notebook-controller | Kubernetes Operator | Core notebook lifecycle management and culling |
| odh-notebook-controller | Kubernetes Operator | ODH/RHOAI-specific extensions for notebooks (OAuth, Routes, networking, integrations) |
| notebook-controller-culler | Controller Module | Monitors and stops idle notebook instances based on configurable thresholds |
| notebook-webhook | Admission Webhook | Validates and mutates Notebook CRs during creation/update |

## APIs Exposed

### Custom Resource Definitions (CRDs)

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| kubeflow.org | v1 | Notebook | Namespaced | Primary API for notebook instances (storage version) |
| kubeflow.org | v1beta1 | Notebook | Namespaced | Beta API version with webhook support and conversion |
| kubeflow.org | v1alpha1 | Notebook | Namespaced | Alpha API version with conversion support |

### HTTP Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /healthz | GET | 8081/TCP | HTTP | None | None | Liveness probe for controller health |
| /readyz | GET | 8081/TCP | HTTP | None | None | Readiness probe for controller availability |
| /metrics | GET | 8080/TCP | HTTP | None | None | Prometheus metrics endpoint (odh-notebook-controller) |
| /validate | POST | 8443/TCP | HTTPS | TLS 1.2+ | mTLS | Validating webhook for Notebook resources |
| /mutate | POST | 8443/TCP | HTTPS | TLS 1.2+ | mTLS | Mutating webhook for Notebook resources |

### gRPC Services

No gRPC services exposed.

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| Kubernetes | 0.33.7+ | Yes | Container orchestration platform (OpenShift 4.19+ compatible) |
| controller-runtime | 0.21.0 | Yes | Kubernetes controller framework |
| Istio | N/A | No | Optional service mesh for VirtualService-based networking |
| cert-manager | N/A | No | Certificate provisioning for webhooks (or OpenShift service-ca) |
| OpenShift Service CA | N/A | No | Alternative certificate provisioning on OpenShift |

### Internal ODH Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| Data Science Pipelines Operator | CRD (DataSciencePipelinesApplication) | Retrieves pipeline API endpoints and injects runtime configuration/secrets into notebooks |
| OpenShift OAuth | API (OAuth Clients) | Creates OAuth clients for notebook authentication on OpenShift |
| OpenShift Routes | CRD (Route) | Exposes notebooks externally on OpenShift clusters |
| Gateway API | CRD (Gateway, HTTPRoute, ReferenceGrant) | Alternative ingress mechanism using Kubernetes Gateway API |
| OpenShift ImageStreams | CRD (ImageStream) | References container images for notebook runtimes |
| Feast | ConfigMap | Injects Feast feature store configuration into notebooks |

## Network Architecture

### Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| notebook-controller-service | ClusterIP | 443/TCP | 443 | HTTPS | TLS 1.2+ | mTLS | Internal |
| odh-notebook-controller-webhook-service | ClusterIP | 443/TCP | webhook (8443) | HTTPS | TLS 1.2+ | mTLS | Internal |
| odh-notebook-controller-metrics-service | ClusterIP | 8080/TCP | metrics (8080) | HTTP | None | None | Internal |
| {notebook-name} | ClusterIP | 80/TCP | notebook-port | HTTP | None | OAuth/Istio | Internal |

### Ingress

| Name | Type | Hosts | Port | Protocol | Encryption | TLS Mode | Exposure |
|------|------|-------|------|----------|------------|----------|----------|
| {notebook-name}-route | OpenShift Route | {notebook-name}-{namespace}.{domain} | 443/TCP | HTTPS | TLS 1.2+ | edge/reencrypt | External |
| {notebook-name}-httproute | Gateway HTTPRoute | {notebook-name}.{domain} | 443/TCP | HTTPS | TLS 1.2+ | SIMPLE | External |
| {notebook-name}-vs | Istio VirtualService | {istio-host} | 80/TCP | HTTP | None | N/A | External (via Istio Gateway) |

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | Service Account Token | Controller watches and reconciles Kubernetes resources |
| Data Science Pipelines API | 8888/TCP | HTTP | None | Internal | Retrieves pipeline runtime configuration |
| Container Registries | 443/TCP | HTTPS | TLS 1.2+ | Pull Secrets | Pulls notebook container images |
| External HTTP(S) | 80/TCP, 443/TCP | HTTP/HTTPS | TLS 1.2+ (HTTPS) | Configurable | Cluster proxy configuration for notebook egress (optional) |

## Security

### RBAC - Cluster Roles

| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|
| notebook-controller-role | kubeflow.org | notebooks, notebooks/finalizers, notebooks/status | * |
| notebook-controller-role | "" | services, pods, events | *, get, list, watch, delete, create, patch |
| notebook-controller-role | apps | statefulsets | * |
| notebook-controller-role | networking.istio.io | virtualservices | * |
| odh-notebook-controller-manager-role | kubeflow.org | notebooks, notebooks/finalizers, notebooks/status | get, list, watch, patch, update |
| odh-notebook-controller-manager-role | "" | configmaps, secrets, serviceaccounts, services | create, get, list, patch, update, watch |
| odh-notebook-controller-manager-role | authentication.k8s.io | tokenreviews | create |
| odh-notebook-controller-manager-role | authorization.k8s.io | subjectaccessreviews | create |
| odh-notebook-controller-manager-role | datasciencepipelinesapplications.opendatahub.io | datasciencepipelinesapplications, datasciencepipelinesapplications/api | get, list, watch, create, delete, patch, update |
| odh-notebook-controller-manager-role | gateway.networking.k8s.io | gateways | get, list, watch |
| odh-notebook-controller-manager-role | gateway.networking.k8s.io | httproutes, referencegrants | create, delete, get, list, patch, update, watch |
| odh-notebook-controller-manager-role | image.openshift.io | imagestreams | get, list, watch |
| odh-notebook-controller-manager-role | networking.k8s.io | networkpolicies, networkpolicies/finalizers | create, get, list, patch, update, watch |
| odh-notebook-controller-manager-role | oauth.openshift.io | oauthclients | delete, get, list, patch, update, watch |
| odh-notebook-controller-manager-role | rbac.authorization.k8s.io | clusterrolebindings, rolebindings, roles | create, delete, get, list, patch, update, watch |
| odh-notebook-controller-manager-role | route.openshift.io | routes | get, list, watch |
| odh-notebook-controller-manager-role | config.openshift.io | proxies | get, list, watch |
| notebook-controller-leader-election-role | "" | configmaps | get, list, watch, create, update, patch |
| notebook-controller-leader-election-role | coordination.k8s.io | leases | get, create, update |

### RBAC - Role Bindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| notebook-controller-role-binding | {deployment-namespace} | notebook-controller-role | notebook-controller-service-account |
| odh-notebook-controller-manager-rolebinding | {deployment-namespace} | odh-notebook-controller-manager-role | odh-notebook-controller-manager |
| notebook-controller-leader-election-rolebinding | {deployment-namespace} | notebook-controller-leader-election-role | notebook-controller-service-account |

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| odh-notebook-controller-webhook-cert | kubernetes.io/tls | TLS certificate for admission webhook server | OpenShift Service CA / cert-manager | Yes (OpenShift) / No (cert-manager) |
| {notebook-name}-oauth-config | Opaque | OAuth client secret for notebook authentication | odh-notebook-controller | No |
| ds-pipeline-{dspa-name}-config | Opaque | Data Science Pipeline API credentials injected into notebooks | odh-notebook-controller | No |

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| /validate, /mutate | POST | mTLS client certificates | Kubernetes API Server | ValidatingWebhookConfiguration / MutatingWebhookConfiguration |
| /healthz, /readyz | GET | None | Container liveness/readiness | Public endpoints |
| /metrics | GET | None (internal) | Network Policy | Restricted to Prometheus scraper |
| Notebook HTTP endpoint | * | OAuth Proxy / Istio AuthorizationPolicy | OAuth Proxy sidecar / Istio | User must authenticate via OAuth or mTLS |

## Data Flows

### Flow 1: Notebook Creation and Provisioning

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User / Kubeflow Dashboard | Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | Bearer Token (User credentials) |
| 2 | Kubernetes API Server | odh-notebook-controller webhook | 8443/TCP | HTTPS | TLS 1.2+ | mTLS (API Server client cert) |
| 3 | odh-notebook-controller | Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | Service Account Token |
| 4 | odh-notebook-controller | Data Science Pipelines API | 8888/TCP | HTTP | None | Internal |
| 5 | odh-notebook-controller | Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | Service Account Token |

### Flow 2: Idle Notebook Culling

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | notebook-controller-culler | Notebook Pod /metrics | {notebook-port}/TCP | HTTP | None | None (internal) |
| 2 | notebook-controller-culler | Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | Service Account Token |

### Flow 3: User Access to Notebook

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User Browser | OpenShift Router / Istio Gateway | 443/TCP | HTTPS | TLS 1.2+ | None (public endpoint) |
| 2 | OpenShift Router / Istio Gateway | OAuth Proxy / Notebook Service | 80/TCP | HTTP | None | OAuth Token / mTLS |
| 3 | OAuth Proxy | OAuth Server | 443/TCP | HTTPS | TLS 1.2+ | OAuth Protocol |
| 4 | OAuth Proxy | Notebook Container | {notebook-port}/TCP | HTTP | None | Authorized session |

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| Kubernetes API Server | REST API | 6443/TCP | HTTPS | TLS 1.2+ | Watch and reconcile CRDs, manage Kubernetes resources |
| Data Science Pipelines | REST API | 8888/TCP | HTTP | None | Inject pipeline runtime configuration and secrets into notebooks |
| OpenShift OAuth | REST API | 443/TCP | HTTPS | TLS 1.2+ | Create and manage OAuth clients for notebook authentication |
| Istio Pilot | xDS API | 15010/TCP | gRPC | mTLS | Discover VirtualService configurations for notebook ingress |
| Prometheus | HTTP (scrape) | 8080/TCP | HTTP | None | Collect controller and notebook metrics |
| OpenShift Service CA | Certificate API | N/A | N/A | N/A | Provision webhook TLS certificates via annotations |

## Recent Changes

| Version | Date | Changes |
|---------|------|---------|
| v1.7.0-15-519 | 2025-03 | - Bump docker/login-action from 3 to 4<br>- Update go.opentelemetry.io/otel/sdk dependency<br>- Sync security config files<br>- Update Go version to latest patch (1.25.7)<br>- Fix linter issues in odh-nbc component<br>- Improve error handling in waitForStatefulSet<br>- Reduce resource requirements for test notebooks<br>- Better diagnostics and PR feedback addressed |
| v1.7.0-15 | 2025-02 | - Fix e2e test flakiness from culling leaving notebooks stopped<br>- Add fallback for Public API endpoint retrieval<br>- Assure proper pipelines runtime config/secret presence<br>- Assure proper runtime images configmap presence<br>- Fix notebook culler failing to stop idle notebooks<br>- Update golangci-lint tool to latest version |

## Controller Reconciliation Modules

### notebook-controller (Upstream Kubeflow)

| Module | Purpose |
|--------|---------|
| notebook_controller.go | Main reconciler: provisions StatefulSet, Service, and optionally VirtualService for Notebook resources |
| culling_controller.go | Monitors notebook activity metrics and stops idle notebooks based on CULL_IDLE_TIME and IDLENESS_CHECK_PERIOD |

### odh-notebook-controller (ODH/RHOAI Extensions)

| Module | Purpose |
|--------|---------|
| notebook_controller.go | Main ODH reconciler: orchestrates all ODH-specific reconciliation modules |
| notebook_webhook.go | Admission webhook: validates and mutates Notebook CRs (e.g., injects defaults, enforces policies) |
| notebook_oauth.go | Creates and manages OpenShift OAuth clients for notebook authentication |
| notebook_route.go | Provisions OpenShift Routes for external notebook access |
| notebook_network.go | Creates NetworkPolicies to control notebook ingress/egress traffic |
| notebook_rbac.go | Configures RBAC Roles and RoleBindings for notebook service accounts |
| notebook_kube_rbac_auth.go | Injects kube-rbac-proxy sidecar for API authentication (alternative to OAuth) |
| notebook_dspa_secret.go | Retrieves Data Science Pipelines API credentials and injects them as notebook environment variables |
| notebook_feast_config.go | Injects Feast feature store configuration into notebook environment |
| notebook_runtime.go | Manages notebook runtime configuration (image, resources, tolerations, affinity) |
| notebook_referencegrant.go | Creates Gateway API ReferenceGrants to allow cross-namespace HTTPRoute references |

## Configuration

### Environment Variables (notebook-controller)

| Variable | Source | Default | Purpose |
|----------|--------|---------|---------|
| USE_ISTIO | ConfigMap: config | false | Enable Istio VirtualService creation for notebook ingress |
| ISTIO_GATEWAY | ConfigMap: config | kubeflow/kubeflow-gateway | Istio Gateway to attach VirtualServices to |
| ISTIO_HOST | ConfigMap: config | * | Hostname pattern for Istio VirtualServices |
| ENABLE_CULLING | ConfigMap: notebook-controller-culler-config | false | Enable automatic culling of idle notebooks |
| CULL_IDLE_TIME | ConfigMap: notebook-controller-culler-config | 1440 (24h) | Minutes of inactivity before notebook is stopped |
| IDLENESS_CHECK_PERIOD | ConfigMap: notebook-controller-culler-config | 1 | Minutes between idleness checks |

### Environment Variables (odh-notebook-controller)

| Variable | Source | Default | Purpose |
|----------|--------|---------|---------|
| SET_PIPELINE_RBAC | Hard-coded | true | Automatically configure RBAC for pipeline access |
| SET_PIPELINE_SECRET | Hard-coded | true | Inject pipeline API credentials into notebooks |
| INJECT_CLUSTER_PROXY_ENV | ConfigMap: notebook-controller-setting-config | false | Inject cluster-wide HTTP(S) proxy environment variables into notebooks |

## Deployment Characteristics

| Characteristic | notebook-controller | odh-notebook-controller |
|----------------|---------------------|-------------------------|
| Replicas | 1 | 1 |
| Deployment Strategy | RollingUpdate (maxUnavailable: 100%, maxSurge: 0) | RollingUpdate (maxUnavailable: 100%, maxSurge: 0) |
| Security Context | Default | runAsNonRoot: true, allowPrivilegeEscalation: false |
| Resource Requests | Not specified | CPU: 500m, Memory: 256Mi |
| Resource Limits | Not specified | CPU: 500m, Memory: 4Gi |
| Health Checks | Liveness: /healthz:8081, Readiness: /readyz:8081 | Liveness: /healthz:8081, Readiness: /readyz:8081 |
| Leader Election | Yes (via ConfigMap or Lease) | Yes (via ConfigMap or Lease) |

## Testing

| Test Type | Location | Coverage |
|-----------|----------|----------|
| Unit Tests | components/*/controllers/*_test.go | Controller reconciliation logic, webhook validation/mutation, RBAC, networking |
| Integration Tests | components/*/controllers/suite_test.go | End-to-end reconciliation with fake Kubernetes API |
| BDD Tests | components/notebook-controller/controllers/notebook_controller_bdd_test.go | Behavior-driven scenarios for notebook lifecycle |
| OpenTelemetry Tests | components/odh-notebook-controller/controllers/opentelemetry_test.go | Instrumentation and tracing validation |

## Known Limitations

1. **Single Replica**: Both controllers run as single replicas with leader election, limiting high availability.
2. **Webhook Downtime**: During controller upgrades, webhook endpoints are unavailable, blocking Notebook CR mutations.
3. **Culling Limitations**: Culling relies on notebook /metrics endpoint; notebooks without metrics cannot be culled based on activity.
4. **OpenShift Dependency**: odh-notebook-controller has hard dependencies on OpenShift APIs (Routes, OAuth, Service CA) limiting portability.
5. **No Multi-Cluster**: Controllers only manage notebooks within their local Kubernetes cluster.

## Troubleshooting

### Common Issues

| Issue | Symptom | Resolution |
|-------|---------|------------|
| Webhook failure blocking CR creation | Notebook CRs rejected with "connection refused" | Check webhook Service/Deployment health, verify certificate validity |
| Notebooks not culled | Idle notebooks remain running | Verify ENABLE_CULLING=true, check notebook metrics endpoint accessibility |
| OAuth login fails | 403 Forbidden on notebook URL | Verify OAuth client creation, check RBAC permissions for OAuth API |
| Pipeline secret not injected | Notebook env missing DS_PIPELINE_* | Ensure DSPA exists in namespace, verify odh-notebook-controller RBAC for DSPA API |
| Route not created | Notebook inaccessible externally | Check OpenShift Route API availability, verify controller RBAC for routes |

### Debug Commands

```bash
# Check controller logs
kubectl logs -n {namespace} deployment/notebook-controller
kubectl logs -n {namespace} deployment/odh-notebook-controller-manager

# Verify webhook configuration
kubectl get validatingwebhookconfigurations
kubectl get mutatingwebhookconfigurations

# Check Notebook status
kubectl get notebooks -A
kubectl describe notebook {notebook-name} -n {namespace}

# Verify RBAC
kubectl auth can-i create notebooks --as=system:serviceaccount:{namespace}:{service-account}

# Test webhook endpoint
kubectl run -it --rm curl --image=curlimages/curl --restart=Never -- \
  curl -k https://odh-notebook-controller-webhook-service.{namespace}.svc:443/validate
```
