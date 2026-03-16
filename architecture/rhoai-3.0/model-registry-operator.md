# Component: Model Registry Operator

## Metadata
- **Repository**: https://github.com/red-hat-data-services/model-registry-operator.git
- **Version**: eb4d8e5
- **Branch**: rhoai-3.0
- **Distribution**: RHOAI
- **Languages**: Go 1.25
- **Deployment Type**: Kubernetes Operator

## Purpose
**Short**: Kubernetes operator for deploying and managing Model Registry instances in OpenShift AI and Open Data Hub.

**Detailed**: The Model Registry Operator is a Kubernetes operator that automates the deployment and lifecycle management of Model Registry instances. It provides a declarative API through Custom Resource Definitions (CRDs) to manage model metadata storage systems backed by PostgreSQL or MySQL databases. The operator deploys both REST and gRPC endpoints for model registry services, handles authentication through kube-rbac-proxy or OAuth proxy, manages database connections with TLS support, and integrates with OpenShift Routes and Istio service mesh for external access. It supports auto-provisioning of PostgreSQL databases, OpenShift-specific features like service serving certificates, and comprehensive RBAC configuration for multi-tenant model registry deployments.

The operator is based on Google ML Metadata (v1.14.0) and the Kubeflow Model Registry project, providing enterprise-grade features including database schema migrations, webhook-based validation, network policies, and integration with OpenShift AI/Open Data Hub platform components.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| Controller Manager | Deployment | Main operator controller that reconciles ModelRegistry CRs and manages lifecycle |
| ModelRegistry REST Server | Deployment | REST API server for model registry operations (deployed per CR) |
| ModelRegistry gRPC Server | Container | gRPC API server for ML Metadata operations (sidecar in REST deployment) |
| kube-rbac-proxy | Container | Authentication proxy providing bearer token auth and TLS termination |
| PostgreSQL/MySQL Database | External/Deployment | Backend database for model metadata storage |
| Webhook Server | Service | Validates and mutates ModelRegistry CR changes |

## APIs Exposed

### Custom Resource Definitions (CRDs)

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| modelregistry.opendatahub.io | v1alpha1 | ModelRegistry | Namespaced | (Deprecated) Defines model registry instance configuration |
| modelregistry.opendatahub.io | v1beta1 | ModelRegistry | Namespaced | Defines model registry instance configuration with REST/gRPC endpoints, database config, auth settings |

### HTTP Endpoints

#### Operator Metrics and Health

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /metrics | GET | 8443/TCP | HTTPS | TLS 1.2+ | Bearer Token | Prometheus metrics endpoint |
| /healthz | GET | 8081/TCP | HTTP | None | None | Controller liveness probe |
| /readyz | GET | 8081/TCP | HTTP | None | None | Controller readiness probe |

#### Model Registry REST API (per instance)

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /api/model_registry/v1alpha3/* | GET/POST/PUT/DELETE | 8080/TCP | HTTP | None | None | Model registry REST API (internal) |
| /api/model_registry/v1alpha3/* | GET/POST/PUT/DELETE | 8443/TCP | HTTPS | TLS 1.2+ | Bearer Token (kube-rbac-proxy) | Model registry REST API (via proxy) |
| /readyz/isDirty | GET | 8080/TCP | HTTP | None | None | REST server liveness/startup probe |
| /readyz/health | GET | 8080/TCP | HTTP | None | None | REST server readiness probe |

#### Webhook Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /mutate-modelregistry-opendatahub-io-modelregistry | POST | 9443/TCP | HTTPS | TLS 1.2+ | K8s API Server | Mutating webhook for ModelRegistry CR |
| /validate-modelregistry-opendatahub-io-modelregistry | POST | 9443/TCP | HTTPS | TLS 1.2+ | K8s API Server | Validating webhook for ModelRegistry CR |

### gRPC Services

| Service | Port | Protocol | Encryption | Auth | Purpose |
|---------|------|----------|------------|------|---------|
| ml_metadata.MetadataStoreService | 9090/TCP | gRPC | None | Internal | ML Metadata gRPC API for model artifact management |

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| PostgreSQL | 16 (RHEL9) | Yes (or MySQL) | Model metadata persistence backend |
| MySQL | 8.x | Yes (or PostgreSQL) | Alternative model metadata persistence backend |
| OpenShift Service CA Operator | N/A | No | Auto-generates TLS certificates for services (OpenShift only) |
| cert-manager | N/A | No | Alternative certificate management for non-OpenShift clusters |
| Istio Service Mesh | 1.20+ | No | Service mesh integration for advanced networking and security |

### Internal ODH/RHOAI Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| opendatahub-operator | Platform Component | Manages operator deployment, provides service-mesh-refs ConfigMap for Istio configuration |
| Istio Ingress Gateway | Istio Gateway | Provides external ingress when Istio integration is enabled |

## Network Architecture

### Services

#### Operator Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| controller-manager-metrics-service | ClusterIP | 8443/TCP | https | HTTPS | TLS 1.2+ | Bearer Token | Internal |
| webhook-service | ClusterIP | 9443/TCP | 9443 | HTTPS | TLS 1.2+ | K8s API | Internal |

#### Model Registry Instance Services (per ModelRegistry CR)

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| {registry-name} | ClusterIP | 8080/TCP | 8080 | HTTP | None | None | Internal (no proxy) |
| {registry-name} | ClusterIP | 8443/TCP | 8443 | HTTPS | TLS 1.2+ | Bearer Token | Internal (with kube-rbac-proxy) |

#### Database Services (auto-provisioned)

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| {registry-name}-db | ClusterIP | 5432/TCP | 5432 | PostgreSQL | TLS (optional) | Password | Internal |

### Ingress

| Name | Type | Hosts | Port | Protocol | Encryption | TLS Mode | Exposure |
|------|------|-------|------|----------|------------|----------|----------|
| {registry-name}-https | OpenShift Route | {registry-name}-https-{namespace}.apps.{domain} | 443/TCP | HTTPS | TLS 1.2+ | Edge | External (when serviceRoute=enabled) |
| {registry-name}-http | OpenShift Route | {registry-name}-http-{namespace}.apps.{domain} | 80/TCP | HTTP | None | N/A | External (when serviceRoute=enabled, no auth) |
| Istio Gateway | Istio Gateway | Custom domains | 443/TCP | HTTPS | TLS 1.2+ | SIMPLE/MUTUAL | External (when Istio integration enabled) |

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| PostgreSQL Database | 5432/TCP | PostgreSQL | TLS (optional) | Password/Client Cert | Model metadata persistence |
| MySQL Database | 3306/TCP | MySQL | TLS (optional) | Password/Client Cert | Model metadata persistence |
| Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token | CR reconciliation, resource management |

## Security

### RBAC - Cluster Roles

| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|
| manager-role | "" | configmaps, persistentvolumeclaims, secrets, serviceaccounts, services | create, delete, get, list, patch, update, watch |
| manager-role | "" | endpoints, pods, pods/log | get, list, watch |
| manager-role | "" | events | create, patch |
| manager-role | apps | deployments | create, delete, get, list, patch, update, watch |
| manager-role | modelregistry.opendatahub.io | modelregistries | create, delete, get, list, patch, update, watch |
| manager-role | modelregistry.opendatahub.io | modelregistries/finalizers | update |
| manager-role | modelregistry.opendatahub.io | modelregistries/status | get, patch, update |
| manager-role | route.openshift.io | routes, routes/custom-host | create, delete, get, list, patch, update, watch |
| manager-role | user.openshift.io | groups | create, delete, get, list, patch, update, watch |
| manager-role | networking.k8s.io | networkpolicies | create, delete, get, list, patch, update, watch |
| manager-role | rbac.authorization.k8s.io | clusterrolebindings, rolebindings, roles | create, delete, get, list, patch, update, watch |
| manager-role | authentication.k8s.io | tokenreviews | create |
| manager-role | authorization.k8s.io | subjectaccessreviews | create |
| manager-role | config.openshift.io | ingresses | get, list, watch |
| manager-role | migration.k8s.io | storageversionmigrations | create, delete, get, list, patch, update, watch |
| modelregistry-editor-role | modelregistry.opendatahub.io | modelregistries | create, delete, get, list, patch, update, watch |
| modelregistry-editor-role | modelregistry.opendatahub.io | modelregistries/status | get |
| modelregistry-viewer-role | modelregistry.opendatahub.io | modelregistries | get, list, watch |
| modelregistry-viewer-role | modelregistry.opendatahub.io | modelregistries/status | get |
| metrics-reader | "" (non-resource) | /metrics | get |
| leader-election-role | "" | configmaps | get, list, watch, create, update, patch, delete |
| leader-election-role | coordination.k8s.io | leases | get, list, watch, create, update, patch, delete |
| leader-election-role | "" | events | create, patch |

### RBAC - Role Bindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| leader-election-rolebinding | opendatahub | leader-election-role | controller-manager |
| manager-rolebinding | N/A (Cluster) | manager-role | controller-manager |
| proxy-rolebinding | opendatahub | proxy-role | controller-manager |
| registry-user-{registry-name} | {registry-namespace} | registry-user-{registry-name} | Per-registry access control |

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| {registry-name}-kube-rbac-proxy | kubernetes.io/tls | kube-rbac-proxy TLS certificate/key | OpenShift Service CA | Yes (OpenShift) |
| model-registry-db | Opaque | Database connection password | User/Operator | No |
| model-registry-db-credential | Opaque | Database TLS CA certificates (optional) | User/cert-manager | No |
| {registry-name}-postgres-ssl-cert | Opaque | PostgreSQL client certificate (optional) | User | No |
| {registry-name}-postgres-ssl-key | Opaque | PostgreSQL client private key (optional) | User | No |
| {registry-name}-mysql-ssl-cert | Opaque | MySQL client certificate (optional) | User | No |
| {registry-name}-mysql-ssl-key | Opaque | MySQL client private key (optional) | User | No |
| webhook-server-cert | kubernetes.io/tls | Webhook server TLS certificate | cert-manager/OpenShift | Yes |

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| /api/model_registry/v1alpha3/* (via proxy) | GET, POST, PUT, DELETE | Bearer Token (K8s RBAC) | kube-rbac-proxy | SubjectAccessReview to service GET permission |
| /api/model_registry/v1alpha3/* (direct) | GET, POST, PUT, DELETE | None | None | Internal cluster access only |
| /metrics | GET | Bearer Token (K8s RBAC) | kube-rbac-proxy | TokenReview + SubjectAccessReview |
| Webhook endpoints | POST | TLS Client Auth | K8s API Server | Webhook certificates validated by K8s |
| ModelRegistry CR operations | CREATE, UPDATE, DELETE | Bearer Token (K8s RBAC) | K8s API Server | modelregistry-editor-role or admin |

### Network Policies

| Policy Name | Namespace | Pod Selector | Ingress From | Ports | Purpose |
|-------------|-----------|--------------|--------------|-------|---------|
| {registry-name}-https-route | {registry-namespace} | app={registry-name}, component=model-registry | namespaceSelector: network.openshift.io/policy-group=ingress | 8443/TCP (kube-rbac-proxy) | Allow ingress from OpenShift Router to registry service |

## Data Flows

### Flow 1: Model Registry Query (Authenticated)

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | External Client | OpenShift Router | 443/TCP | HTTPS | TLS 1.2+ | None (Router) |
| 2 | OpenShift Router | {registry-name} Service | 8443/TCP | HTTPS | TLS 1.2+ (re-encrypted) | None (internal) |
| 3 | {registry-name} Service | kube-rbac-proxy Container | 8443/TCP | HTTPS | TLS 1.2+ | Bearer Token (validated) |
| 4 | kube-rbac-proxy | REST Container | 8080/TCP | HTTP | None | None (localhost) |
| 5 | REST Container | PostgreSQL/MySQL | 5432/3306/TCP | PostgreSQL/MySQL | TLS (optional) | Password/Client Cert |

### Flow 2: Model Registry gRPC Call (Internal)

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Internal Client Pod | {registry-name} Service | 9090/TCP | gRPC | None | None |
| 2 | {registry-name} Service | gRPC Container | 9090/TCP | gRPC | None | None (internal) |
| 3 | gRPC Container | PostgreSQL/MySQL | 5432/3306/TCP | PostgreSQL/MySQL | TLS (optional) | Password/Client Cert |

### Flow 3: Operator Reconciliation

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Controller Manager | Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 2 | Kubernetes API Server | Controller Manager | N/A | Watch Stream | TLS 1.2+ | ServiceAccount Token |
| 3 | Controller Manager | Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token (create/update resources) |

### Flow 4: Webhook Validation

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Kubernetes API Server | webhook-service | 9443/TCP | HTTPS | TLS 1.2+ | TLS Client Cert |
| 2 | webhook-service | Controller Manager | N/A | In-process | N/A | N/A |
| 3 | Controller Manager | Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | Response |

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| Kubernetes API Server | REST API | 6443/TCP | HTTPS | TLS 1.2+ | CR reconciliation, resource management, RBAC |
| PostgreSQL Database | PostgreSQL Protocol | 5432/TCP | PostgreSQL | TLS (optional) | Model metadata persistence |
| MySQL Database | MySQL Protocol | 3306/TCP | MySQL | TLS (optional) | Alternative metadata persistence |
| OpenShift Router | HTTP/HTTPS Proxy | 80,443/TCP | HTTP/HTTPS | TLS 1.2+ (443) | External ingress for model registry services |
| Istio Service Mesh | Service Mesh | N/A | N/A | mTLS | Optional service mesh integration |
| Prometheus | Metrics Scraping | 8443/TCP | HTTPS | TLS 1.2+ | Operator metrics collection |
| OpenShift Service CA | Certificate Authority | N/A | N/A | N/A | Auto-provision TLS certificates |
| opendatahub-operator | Platform Integration | N/A | N/A | N/A | ConfigMap-based configuration (service-mesh-refs) |

## Deployment Architecture

### Operator Deployment

- **Namespace**: `opendatahub` (ODH) or `redhat-ods-applications` (RHOAI)
- **Replicas**: 1 (leader election enabled)
- **Image**: Built via Konflux from Dockerfile.konflux (FIPS-enabled)
- **Base Images**:
  - Builder: `registry.access.redhat.com/ubi9/go-toolset:1.24`
  - Runtime: `registry.access.redhat.com/ubi9/ubi-minimal`
- **Security Context**:
  - runAsNonRoot: true
  - User: 65532:65532
  - Drop all capabilities
  - strictFIPS mode enabled

### Model Registry Instance Deployment (per CR)

- **Namespace**: User-specified (typically `{odh|rhoai}-model-registries`)
- **Replicas**: 1
- **Containers**:
  - **rest-container**: Model registry REST API server
  - **kube-rbac-proxy** (optional): Authentication proxy
- **Images**:
  - REST: `quay.io/opendatahub/model-registry:latest`
  - gRPC: `quay.io/opendatahub/mlmd-grpc-server:latest`
  - kube-rbac-proxy: `quay.io/openshift/origin-kube-rbac-proxy:latest`
- **Security Context**:
  - runAsNonRoot: true
  - Drop all capabilities
  - Restricted-v2 SCC (OpenShift)

### Storage

- **Database**: External PostgreSQL/MySQL or auto-provisioned PostgreSQL
- **Auto-provisioned DB**: PVC-backed PostgreSQL with configurable size
- **No operator state persistence**: Stateless controller

## Configuration

### Environment Variables (Operator)

| Variable | Default | Purpose |
|----------|---------|---------|
| GRPC_IMAGE | quay.io/opendatahub/mlmd-grpc-server:latest | gRPC server image |
| REST_IMAGE | quay.io/opendatahub/model-registry:latest | REST server image |
| OAUTH_PROXY_IMAGE | quay.io/openshift/origin-oauth-proxy:latest | OAuth proxy image (legacy) |
| KUBE_RBAC_PROXY_IMAGE | quay.io/openshift/origin-kube-rbac-proxy:latest | kube-rbac-proxy image |
| ENABLE_WEBHOOKS | false | Enable admission webhooks |
| CREATE_AUTH_RESOURCES | true | Create RBAC resources for registry access |
| REGISTRIES_NAMESPACE | "" | Target namespace for model registries |
| DEFAULT_DOMAIN | "" | Default domain for routes |
| DEFAULT_CONTROL_PLANE | "" | Istio control plane name (from service-mesh-refs) |
| DEFAULT_ISTIO_INGRESS | ingressgateway | Istio ingress gateway name (from service-mesh-refs) |

### ModelRegistry CR Configuration

Key configuration options:
- **rest.port**: REST API port (default: 8080)
- **rest.serviceRoute**: Enable OpenShift Route (disabled/enabled)
- **grpc.port**: gRPC API port (default: 9090)
- **postgres**: PostgreSQL database configuration
- **mysql**: MySQL database configuration
- **kubeRBACProxy**: kube-rbac-proxy configuration for authentication
- Database TLS configuration (sslMode, certificates, keys, CA)
- Resource requests/limits
- Custom images

## Recent Changes

| Version | Date | Changes |
|---------|------|---------|
| eb4d8e5 | 2026-03-09 | - Bump Go to 1.25.7 |
| 7be5aa2 | 2026-02-05 | - Update UBI9 minimal base image to 759f5f4 |
| 5d41f23 | 2026-02-04 | - Update UBI9 minimal base image to ecd4751 |
| f34d683 | 2026-01-26 | - Update UBI9 minimal base image to bb08f23 |
| 8817a4d | 2026-01-19 | - Update UBI9 minimal base image to 90bd85d |

## Known Limitations and Considerations

1. **Database Requirement**: Either PostgreSQL or MySQL must be configured; SQLite is not supported in production
2. **Single Replica**: Model registry deployments run with 1 replica (not HA by default)
3. **OpenShift Integration**: Full feature set (auto TLS, Routes) requires OpenShift; Kubernetes requires manual cert management
4. **gRPC Port**: gRPC endpoint is not exposed externally by default (internal use only)
5. **Webhook Requirement**: Webhooks disabled by default in standalone mode but enabled in ODH/RHOAI integration
6. **Database Schema Migration**: Supports schema upgrades/downgrades but requires careful planning
7. **OAuth Proxy Migration**: Legacy OAuth proxy configurations are automatically migrated to kube-rbac-proxy
8. **v1alpha1 Deprecation**: v1alpha1 API version is deprecated; use v1beta1 for new deployments

## Monitoring and Observability

- **Metrics**: Prometheus metrics exposed on `/metrics` endpoint (port 8443)
- **Health Checks**: `/healthz` and `/readyz` endpoints for operator health
- **Logging**: Structured logging via controller-runtime
- **Events**: Kubernetes events generated for CR lifecycle changes
- **Status Conditions**: CR status includes conditions for Available, IstioAvailable, GatewayAvailable, OAuthProxyAvailable, Degraded

## Disaster Recovery

- **State**: All state stored in ModelRegistry CRs and database; operator is stateless
- **Database Backup**: Database contains all model metadata; backup required for DR
- **CR Backup**: Export ModelRegistry CRs for disaster recovery
- **Restoration**: Restore database and apply ModelRegistry CRs to recreate services
