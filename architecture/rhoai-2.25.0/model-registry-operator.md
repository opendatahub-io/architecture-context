# Component: Model Registry Operator

## Metadata
- **Repository**: https://github.com/red-hat-data-services/model-registry-operator.git
- **Version**: 0b48221 (rhoai-2.25 branch)
- **Distribution**: RHOAI, ODH
- **Languages**: Go 1.24.0+
- **Deployment Type**: Kubernetes Operator

## Purpose
**Short**: Manages lifecycle of Model Registry instances for machine learning model metadata storage and retrieval.

**Detailed**: The Model Registry Operator is a Kubernetes operator that deploys and manages Model Registry instances in OpenShift AI and Open Data Hub environments. It reconciles ModelRegistry custom resources to create deployments of the Model Registry service, which provides REST API access to ML Metadata (MLMD) stored in PostgreSQL or MySQL databases. The operator handles database connectivity configuration, optional OAuth proxy authentication for secure external access, OpenShift Route creation, and RBAC setup. It supports both simple internal-only deployments and production-ready secured deployments with TLS encryption and OpenShift OAuth authentication via proxy sidecars.

The operator creates all necessary Kubernetes resources including deployments, services, service accounts, roles, role bindings, network policies, and OpenShift routes. It manages two API versions (v1alpha1 deprecated, v1beta1 current) with automatic conversion webhooks. The operator enables data scientists and ML engineers to deploy isolated model registry instances per namespace for tracking machine learning model metadata, versions, artifacts, and lineage information.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| controller-manager | Deployment | Main operator pod that reconciles ModelRegistry CRs and manages registry lifecycle |
| ModelRegistry CR | Custom Resource | Declarative specification of model registry instance configuration |
| model-registry deployment | Deployment | User-facing model registry service with REST API and optional OAuth proxy sidecar |
| model-registry service | Service | ClusterIP service exposing REST API (8080) or HTTPS via OAuth proxy (8443) |
| webhook-service | Service | Admission webhook service for CR validation and mutation |
| controller-manager-metrics-service | Service | Prometheus metrics endpoint for operator monitoring |

## APIs Exposed

### Custom Resource Definitions (CRDs)

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| modelregistry.opendatahub.io | v1alpha1 | ModelRegistry | Namespaced | Legacy API for model registry instances (deprecated, supports Istio auth) |
| modelregistry.opendatahub.io | v1beta1 | ModelRegistry | Namespaced | Current API for model registry instances (storage version, OAuth only) |

### HTTP Endpoints

#### Operator Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /healthz | GET | 8081/TCP | HTTP | None | None | Operator liveness probe |
| /readyz | GET | 8081/TCP | HTTP | None | None | Operator readiness probe |
| /metrics | GET | 8443/TCP | HTTPS | TLS | Bearer Token | Operator Prometheus metrics |
| /mutate-modelregistry-opendatahub-io-modelregistry | POST | 443/TCP | HTTPS | TLS | Webhook CA | Mutating webhook for ModelRegistry CR |
| /validate-modelregistry-opendatahub-io-modelregistry | POST | 443/TCP | HTTPS | TLS | Webhook CA | Validating webhook for ModelRegistry CR |

#### Model Registry Service Endpoints (per instance)

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /api/model_registry/v1alpha3/* | GET,POST,PUT,PATCH,DELETE | 8080/TCP | HTTP | None | None | Model Registry REST API (non-OAuth mode) |
| /api/model_registry/v1alpha3/* | GET,POST,PUT,PATCH,DELETE | 8443/TCP | HTTPS | TLS 1.2+ | Bearer Token (OAuth) | Model Registry REST API (OAuth mode) |
| /readyz/isDirty | GET | 8080/TCP | HTTP | None | None | Service liveness probe |
| /readyz/health | GET | 8080/TCP | HTTP | None | None | Service readiness probe |
| /oauth/healthz | GET | 8443/TCP | HTTPS | TLS 1.2+ | None | OAuth proxy health check |
| /metrics | GET | 8443/TCP | HTTPS | TLS 1.2+ | None | OAuth proxy metrics (skip-auth) |

### gRPC Services

| Service | Port | Protocol | Encryption | Auth | Purpose |
|---------|------|----------|------------|------|---------|
| N/A | N/A | N/A | N/A | N/A | gRPC support was removed; v1alpha1 had gRPC spec but v1beta1 does not |

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| PostgreSQL | 9.6+ | Yes (or MySQL) | Backend database for ML Metadata storage |
| MySQL | 5.7+ | Yes (or PostgreSQL) | Alternative backend database for ML Metadata storage |
| OpenShift Service CA | 4.x | No | Automatic TLS certificate generation for OAuth proxy |
| OpenShift OAuth Server | 4.x | No | Authentication provider for OAuth proxy mode |
| OpenShift Ingress Router | 4.x | No | External route exposure for model registry services |

### Internal ODH/RHOAI Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| opendatahub-operator / rhods-operator | CRD Watch | Operator watches components.platform.opendatahub.io/modelregistries for platform integration |
| odh-model-registry (service) | Deployment | REST API service image deployed per ModelRegistry CR instance |
| Prometheus | ServiceMonitor | Operator exposes metrics for monitoring and alerting |

## Network Architecture

### Services

#### Operator Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| controller-manager-metrics-service | ClusterIP | 8443/TCP | https | HTTPS | TLS | Bearer Token | Internal |
| webhook-service | ClusterIP | 443/TCP | 9443 | HTTPS | TLS | Webhook CA | Internal |

#### Model Registry Instance Services (per CR)

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| {name} | ClusterIP | 8080/TCP | 8080 | HTTP | None | None | Internal (non-OAuth mode) |
| {name} | ClusterIP | 8443/TCP | 8443 | HTTPS | TLS 1.2+ | OAuth | Internal (OAuth mode) |

### Ingress

| Name | Type | Hosts | Port | Protocol | Encryption | TLS Mode | Exposure |
|------|------|-------|------|----------|------------|----------|----------|
| {name}-http | OpenShift Route | {name}-{namespace}.{cluster-domain} | 80/TCP | HTTP | None | None | External (if spec.rest.serviceRoute=enabled, non-OAuth) |
| {name}-https | OpenShift Route | {name}.{domain} | 443/TCP | HTTPS | TLS 1.2+ | Edge Termination | External (if spec.oauthProxy.serviceRoute=enabled, OAuth) |

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| PostgreSQL Database | 5432/TCP | PostgreSQL | TLS (configurable) | Username/Password | ML Metadata persistence |
| MySQL Database | 3306/TCP | MySQL | TLS (configurable) | Username/Password | ML Metadata persistence (alternative) |
| Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token | Operator reconciliation and API operations |
| OpenShift OAuth Server | 443/TCP | HTTPS | TLS 1.2+ | Service Account | OAuth token validation (OAuth mode) |

## Security

### RBAC - Cluster Roles

| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|
| manager-role | "" | configmaps, secrets | create, get, list, watch |
| manager-role | "" | services, serviceaccounts | create, delete, get, list, patch, update, watch |
| manager-role | "" | endpoints, pods, pods/log | get, list, watch |
| manager-role | "" | events | create, patch |
| manager-role | apps | deployments | create, delete, get, list, patch, update, watch |
| manager-role | modelregistry.opendatahub.io | modelregistries | create, delete, get, list, patch, update, watch |
| manager-role | modelregistry.opendatahub.io | modelregistries/status | get, patch, update |
| manager-role | modelregistry.opendatahub.io | modelregistries/finalizers | update |
| manager-role | route.openshift.io | routes, routes/custom-host | create, delete, get, list, patch, update, watch |
| manager-role | rbac.authorization.k8s.io | roles, rolebindings, clusterrolebindings | create, delete, get, list, patch, update, watch |
| manager-role | user.openshift.io | groups | create, delete, get, list, patch, update, watch |
| manager-role | networking.k8s.io | networkpolicies | create, delete, get, list, patch, update, watch |
| manager-role | authentication.k8s.io | tokenreviews | create |
| manager-role | authorization.k8s.io | subjectaccessreviews | create |
| manager-role | config.openshift.io | ingresses | get, list, watch |
| manager-role | components.platform.opendatahub.io | modelregistries | get, list, watch |
| manager-role | migration.k8s.io | storageversionmigrations | create, delete, get, list, patch, update, watch |
| manager-role | apiextensions.k8s.io | customresourcedefinitions | get, list, watch |
| proxy-role | authentication.k8s.io | tokenreviews | create |
| proxy-role | authorization.k8s.io | subjectaccessreviews | create |
| leader-election-role | "" | configmaps | get, list, watch, create, update, patch, delete |
| leader-election-role | coordination.k8s.io | leases | get, list, watch, create, update, patch, delete |
| leader-election-role | "" | events | create, patch |

### RBAC - Role Bindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| manager-rolebinding | system | manager-role (ClusterRole) | controller-manager |
| proxy-rolebinding | system | proxy-role (ClusterRole) | controller-manager |
| leader-election-rolebinding | system | leader-election-role (Role) | controller-manager |
| registry-user-{name}-binding | {namespace} | registry-user-{name} (Role) | Created dynamically per registry |

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| {name}-oauth-proxy | kubernetes.io/tls | OAuth proxy TLS certificate | OpenShift Service CA / User | Yes (Service CA) / No (User) |
| {name}-oauth-cookie-secret | Opaque | OAuth proxy session cookie encryption | Operator | No |
| {db-secret-name} | Opaque | Database password reference | User | No |
| {ssl-cert-secret} | Opaque | Database client SSL certificates | User | No |
| webhook-server-cert | kubernetes.io/tls | Webhook server TLS certificate | cert-manager / Service CA | Yes |

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| /api/model_registry/v1alpha3/* | ALL | Bearer Token (OpenShift OAuth) | OAuth Proxy Sidecar | User must have GET permission on service/{name} in namespace |
| /api/model_registry/v1alpha3/* | ALL | None | N/A | Internal cluster access only (non-OAuth mode) |
| /metrics (operator) | GET | Bearer Token (ServiceAccount) | kube-rbac-proxy | Requires tokenreviews/subjectaccessreviews permission |
| /mutate-*, /validate-* | POST | Webhook Client Certificate | API Server | API server validates webhook CA bundle |

### Network Policies

| Policy Name | Namespace | Pod Selector | Ingress From | Ingress Ports |
|-------------|-----------|--------------|--------------|---------------|
| {name}-https-route | {namespace} | app={name}, component=model-registry | namespaceSelector: network.openshift.io/policy-group=ingress | {oauth-proxy-port}/TCP |

## Data Flows

### Flow 1: External User Access to Model Registry (OAuth Mode)

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | External User | OpenShift Router | 443/TCP | HTTPS | TLS 1.2+ | None |
| 2 | OpenShift Router | model-registry Service ({name}) | 8443/TCP | HTTPS | TLS 1.2+ | Edge Termination |
| 3 | model-registry Service | OAuth Proxy Container | 8443/TCP | HTTPS | TLS 1.2+ | Bearer Token (OAuth) |
| 4 | OAuth Proxy | OpenShift OAuth Server | 443/TCP | HTTPS | TLS 1.2+ | Service Account Token |
| 5 | OAuth Proxy | REST Container | 8080/TCP | HTTP | None | None (localhost) |
| 6 | REST Container | PostgreSQL/MySQL | 5432/TCP or 3306/TCP | PostgreSQL/MySQL | TLS (optional) | Username/Password |

### Flow 2: Internal Cluster Access to Model Registry (Non-OAuth Mode)

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Internal Pod | model-registry Service ({name}) | 8080/TCP | HTTP | None | None |
| 2 | model-registry Service | REST Container | 8080/TCP | HTTP | None | None |
| 3 | REST Container | PostgreSQL/MySQL | 5432/TCP or 3306/TCP | PostgreSQL/MySQL | TLS (optional) | Username/Password |

### Flow 3: Operator Reconciliation

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | controller-manager | Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 2 | controller-manager | OpenShift API Server | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 3 | Kubernetes API Server | webhook-service | 443/TCP | HTTPS | TLS | Webhook Client Certificate |

### Flow 4: Metrics Collection

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Prometheus | controller-manager-metrics-service | 8443/TCP | HTTPS | TLS | Bearer Token (ServiceAccount) |

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| PostgreSQL Database | SQL Client | 5432/TCP | PostgreSQL | TLS (optional) | ML Metadata persistence backend |
| MySQL Database | SQL Client | 3306/TCP | MySQL | TLS (optional) | Alternative ML Metadata persistence backend |
| Kubernetes API Server | REST Client | 6443/TCP | HTTPS | TLS 1.2+ | CR reconciliation and resource management |
| OpenShift OAuth Server | OAuth Client | 443/TCP | HTTPS | TLS 1.2+ | User authentication for OAuth proxy mode |
| Prometheus | Metrics Scrape | 8443/TCP | HTTPS | TLS | Operator health and performance monitoring |
| OpenShift Service CA | Certificate Consumer | N/A | N/A | N/A | Automatic TLS certificate provisioning |
| opendatahub-operator | Platform Component | N/A | N/A | N/A | Platform-level registry management via components.platform.opendatahub.io CRD |

## Container Images

| Image | Purpose | Base Image | Build Method |
|-------|---------|------------|--------------|
| odh-model-registry-operator | Kubernetes operator binary | registry.access.redhat.com/ubi9/ubi-minimal | Konflux (Dockerfile.konflux) |
| quay.io/opendatahub/model-registry:latest | Model Registry REST API service | N/A | External (upstream project) |
| quay.io/openshift/origin-oauth-proxy:latest | OpenShift OAuth authentication proxy | N/A | External (OpenShift project) |

## Deployment Architecture

### Operator Deployment

- **Namespace**: Configured during installation (e.g., `redhat-ods-applications` for RHOAI)
- **Replicas**: 1
- **Service Account**: controller-manager
- **Security Context**: runAsNonRoot: true, seccompProfile: RuntimeDefault
- **Resource Limits**: 512Mi memory
- **Resource Requests**: 100m CPU, 256Mi memory
- **Health Checks**:
  - Liveness: /healthz on port 8081
  - Readiness: /readyz on port 8081

### Model Registry Instance Deployment (per CR)

- **Namespace**: Same as ModelRegistry CR
- **Replicas**: 1
- **Service Account**: {name} (created by operator)
- **Security Context**: runAsNonRoot: true, seccompProfile: RuntimeDefault, restricted-v2 SCC
- **Containers**:
  - rest-container: Model Registry REST API
  - oauth-proxy (optional): OpenShift OAuth proxy sidecar
- **Resource Limits**: Configurable via spec.rest.resources
- **Health Checks**:
  - REST: /readyz/isDirty (liveness), /readyz/health (readiness)
  - OAuth Proxy: /oauth/healthz (liveness, readiness)

## Recent Changes

| Commit | Date | Changes |
|--------|------|---------|
| 0b48221 | 2026-03-11 | - Sync pipelineruns with konflux-central - 19bdad4 |
| 6680c2f | 2026-03-11 | - Update base image to ubi9/ubi-minimal:69f5c98 |
| 349da78 | 2026-03-06 | - Merge upstream stable-2.x branch into rhoai-2.25 |
| 09ada35 | 2026-03-06 | - Update to Go 1.25.7 toolchain |
| 99849bb | 2026-02-26 | - Sync pipelineruns with konflux-central - e68c3cf |
| 970148d | 2026-02-18 | - Update base image to ubi9/ubi-minimal:c7d4414 |
| 59717f2 | 2026-02-17 | - Sync pipelineruns with konflux-central - 07ea5e7 |
| 4900965 | 2026-02-05 | - Update base image to ubi9/ubi-minimal:759f5f4 |
| f26d98a | 2026-02-04 | - Update base image to ubi9/ubi-minimal:ecd4751 |
| 26a2548 | 2026-02-02 | - Sync pipelineruns with konflux-central - 2ebf2ad |
| 414dd37 | 2026-01-26 | - Update base image to ubi9/ubi-minimal:bb08f23 |
| 44b9ecb | 2026-01-23 | - Sync pipelineruns with konflux-central - 64394fa |
| 0862c75 | 2026-01-19 | - Update base image to ubi9/ubi-minimal:90bd85d |
| 388e65d | 2026-01-19 | - Update base image to ubi9/ubi-minimal:90bd85d (duplicate) |
| 0e6ffe8 | 2026-01-19 | - Sync pipelineruns with konflux-central - 8ea3217 |

## Configuration Options

### ModelRegistry CR Spec (v1beta1)

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| spec.rest.port | int32 | 8080 | REST API port |
| spec.rest.serviceRoute | enum | disabled | Create OpenShift Route (enabled/disabled) |
| spec.rest.resources | ResourceRequirements | None | CPU/memory resource limits |
| spec.rest.image | string | quay.io/opendatahub/model-registry:latest | Override REST container image |
| spec.grpc.port | int32 | 9090 | gRPC port (deprecated, not used in v1beta1) |
| spec.postgres.host | string | Required | PostgreSQL server hostname |
| spec.postgres.port | int32 | 5432 | PostgreSQL server port |
| spec.postgres.database | string | Required | PostgreSQL database name |
| spec.postgres.username | string | Required | PostgreSQL username |
| spec.postgres.passwordSecret | SecretKeyValue | None | Secret reference for password |
| spec.postgres.sslMode | enum | disable | SSL mode (disable/allow/prefer/require/verify-ca/verify-full) |
| spec.mysql.host | string | Required | MySQL server hostname |
| spec.mysql.port | int32 | 3306 | MySQL server port |
| spec.mysql.database | string | Required | MySQL database name |
| spec.mysql.username | string | Required | MySQL username |
| spec.mysql.passwordSecret | SecretKeyValue | None | Secret reference for password |
| spec.oauthProxy.port | int32 | 8443 | OAuth proxy HTTPS port |
| spec.oauthProxy.serviceRoute | enum | enabled | Create OpenShift Route (enabled/disabled) |
| spec.oauthProxy.domain | string | Auto-detected | Custom domain for Route |
| spec.oauthProxy.routePort | int32 | 443 | Route external port |
| spec.oauthProxy.tlsCertificateSecret | SecretKeyValue | None | Custom TLS certificate (optional) |
| spec.oauthProxy.tlsKeySecret | SecretKeyValue | None | Custom TLS key (optional) |
| spec.oauthProxy.image | string | quay.io/openshift/origin-oauth-proxy:latest | Override OAuth proxy image |

## Migration Notes

### v1alpha1 to v1beta1

- **Removed**: Istio/Authorino authentication support (spec.istio field)
- **Removed**: Gateway configuration (spec.gateway field)
- **Removed**: gRPC server support (no longer deployed separately)
- **Changed**: OAuth proxy is now the only supported authentication method
- **Changed**: Conversion webhook handles automatic migration of existing v1alpha1 CRs
- **Deprecated**: v1alpha1 API will be removed in a future release

## Known Limitations

1. **Single Replica**: Model registry deployments run with 1 replica (no HA support)
2. **Database Backend**: User must provision and manage PostgreSQL or MySQL database separately
3. **OAuth Only**: OpenShift OAuth proxy is the only authentication mechanism in v1beta1
4. **No Built-in Backup**: Database backup/restore must be handled externally
5. **OpenShift Specific**: OAuth mode and Routes are OpenShift-specific features
6. **No Multi-Tenancy**: Each ModelRegistry CR creates an independent deployment (no shared multi-tenant mode)

## Troubleshooting

### Common Issues

1. **ModelRegistry CR stuck in Degraded state**
   - Check database connectivity from model-registry pod
   - Verify database credentials in referenced secrets
   - Review operator logs: `kubectl logs -n {operator-namespace} deployment/controller-manager`

2. **OAuth authentication failing**
   - Verify user has GET permission on service/{name} in registry namespace
   - Check OAuth proxy logs: `kubectl logs -n {namespace} deployment/{name} -c oauth-proxy`
   - Ensure OpenShift OAuth server is accessible from pod network

3. **Route not created**
   - Verify spec.rest.serviceRoute or spec.oauthProxy.serviceRoute is set to "enabled"
   - Check operator has permission to create routes.route.openshift.io resources
   - Review operator logs for route creation errors

4. **Database SSL/TLS connection errors**
   - Verify SSL certificates are correctly mounted in deployment
   - Check database server SSL configuration
   - Review spec.postgres.sslMode or spec.mysql SSL settings

## References

- **Upstream Project**: https://github.com/opendatahub-io/model-registry
- **API Documentation**: https://github.com/opendatahub-io/model-registry-operator/tree/main/api
- **Operator Pattern**: https://kubernetes.io/docs/concepts/extend-kubernetes/operator/
- **OpenShift OAuth Proxy**: https://github.com/openshift/oauth-proxy
- **ML Metadata**: https://github.com/google/ml-metadata
