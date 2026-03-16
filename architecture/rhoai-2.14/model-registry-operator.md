# Component: Model Registry Operator

## Metadata
- **Repository**: https://github.com/red-hat-data-services/model-registry-operator
- **Version**: v-2160 (commit 002ecbb)
- **Branch**: rhoai-2.14
- **Distribution**: RHOAI
- **Languages**: Go 1.21
- **Deployment Type**: Kubernetes Operator

## Purpose
**Short**: Kubernetes operator that deploys and manages Model Registry service instances for registering and tracking ML models.

**Detailed**: The Model Registry Operator is a Kubernetes controller that reconciles `ModelRegistry` custom resources to create and manage Model Registry service deployments. It provides a unified API for deploying model registry instances with REST and gRPC endpoints, backed by PostgreSQL or MySQL databases. The operator supports both plain Kubernetes deployments and advanced service mesh configurations using Istio with Authorino-based authentication and authorization. It manages the complete lifecycle of model registry instances including database connections, service exposure, RBAC permissions, and optional Istio Gateway creation for external access. The operator integrates with OpenShift Service Mesh and can automatically create Routes for external access in OpenShift clusters.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| Operator Controller | Go Application | Reconciles ModelRegistry CRs and manages model registry deployments |
| Model Registry Deployment | Multi-container Pod | Runs REST and gRPC containers serving the Model Registry API |
| REST Container | HTTP Service | Provides REST API on port 8080 for model registry operations |
| gRPC Container | gRPC Service | Provides ML Metadata gRPC API on port 9090 for metadata operations |
| Service | Kubernetes Service | ClusterIP service exposing both REST and gRPC ports |
| Istio Gateway | Istio Gateway | Optional external gateway for REST and gRPC traffic |
| VirtualService | Istio VirtualService | Routes traffic from Gateway to model registry service |
| DestinationRule | Istio DestinationRule | Configures mTLS for service-to-service communication |
| AuthConfig | Authorino CR | Defines authentication and authorization rules |
| AuthorizationPolicy | Istio Security | Delegates authorization to Authorino external provider |

## APIs Exposed

### Custom Resource Definitions (CRDs)

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| modelregistry.opendatahub.io | v1alpha1 | ModelRegistry | Namespaced | Defines desired state for a Model Registry instance including database config, REST/gRPC settings, and Istio integration |

### HTTP Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /api/model_registry/v1alpha3/* | GET, POST, PUT, DELETE | 8080/TCP | HTTP | None (internal) | None (internal) | Model Registry REST API endpoints |
| /api/model_registry/v1alpha3/* | GET, POST, PUT, DELETE | 80/TCP or 443/TCP | HTTP or HTTPS | TLS 1.2+ (if gateway TLS enabled) | Bearer Token (Kubernetes SA token) | External REST API via Istio Gateway |
| /healthz | GET | 8081/TCP | HTTP | None | None | Operator controller health check |
| /readyz | GET | 8081/TCP | HTTP | None | None | Operator controller readiness check |
| /metrics | GET | 8443/TCP | HTTPS | TLS 1.2+ | OpenShift serving cert | Operator controller Prometheus metrics |

### gRPC Services

| Service | Port | Protocol | Encryption | Auth | Purpose |
|---------|------|----------|------------|------|---------|
| ML Metadata Store | 9090/TCP | gRPC | None (internal) | None (internal) | ML Metadata gRPC API for model lineage and versioning |
| ML Metadata Store | 80/TCP or 443/TCP | gRPC or gRPC/TLS | TLS 1.2+ (if gateway TLS enabled) | Bearer Token (Kubernetes SA token) | External gRPC API via Istio Gateway |

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| PostgreSQL | 9.6+ or compatible | Yes (one of) | Persistent storage for ML metadata |
| MySQL | 5.7+ or compatible | Yes (one of) | Alternative persistent storage for ML metadata |
| Istio | 1.20+ | No | Service mesh for mTLS, traffic management, and security |
| Authorino | 0.17+ | No | External authorization provider for API authentication |
| OpenShift Service Mesh | 2.x | No | OpenShift-specific Istio distribution |
| cert-manager | Any | No | Certificate management for TLS (recommended for production) |

### Internal ODH/RHOAI Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| ODH Operator | Configuration | Operator can be deployed as ODH component with configmap-based auth configuration |
| Authorino | AuthConfig CR | Creates authentication configs for model registry instances when Istio is enabled |
| Service Mesh Control Plane | ServiceMeshMember | Integrates with OpenShift Service Mesh for namespace inclusion |

## Network Architecture

### Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| modelregistry-sample | ClusterIP | 8080/TCP | 8080 | HTTP | None | None | Internal |
| modelregistry-sample | ClusterIP | 9090/TCP | 9090 | gRPC | None | None | Internal |
| model-registry-operator-controller-manager | ClusterIP | 8443/TCP | 8443 | HTTPS | TLS 1.2+ | OpenShift serving cert | Internal (metrics) |

### Ingress

| Name | Type | Hosts | Port | Protocol | Encryption | TLS Mode | Exposure |
|------|------|-------|------|----------|------------|----------|----------|
| modelregistry-sample-rest | Istio Gateway | {name}-rest.{domain} | 80/TCP or 443/TCP | HTTP or HTTPS | TLS 1.2+ (optional) | SIMPLE, MUTUAL, or ISTIO_MUTUAL | External (optional) |
| modelregistry-sample-grpc | Istio Gateway | {name}-grpc.{domain} | 80/TCP or 443/TCP | GRPC or gRPC/TLS | TLS 1.2+ (optional) | SIMPLE, MUTUAL, or ISTIO_MUTUAL | External (optional) |
| modelregistry-sample-http | OpenShift Route | route-{namespace}.{cluster-domain} | 80/TCP | HTTP | None | N/A | External (OpenShift, optional) |
| {namespace}-modelregistry-sample-rest | OpenShift Route | auto-generated | 443/TCP | HTTPS | TLS passthrough or edge | N/A | External (OpenShift + Istio Gateway) |
| {namespace}-modelregistry-sample-grpc | OpenShift Route | auto-generated | 443/TCP | HTTPS | TLS passthrough or edge | N/A | External (OpenShift + Istio Gateway) |

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| PostgreSQL Database | 5432/TCP | PostgreSQL | TLS 1.2+ (configurable) | Username/Password | Model metadata persistence |
| MySQL Database | 3306/TCP | MySQL | TLS 1.2+ (configurable) | Username/Password | Model metadata persistence (alternative) |

## Security

### RBAC - Cluster Roles

| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|
| manager-role | modelregistry.opendatahub.io | modelregistries, modelregistries/status, modelregistries/finalizers | create, delete, get, list, patch, update, watch |
| manager-role | apps | deployments | create, delete, get, list, patch, update, watch |
| manager-role | "" | services, serviceaccounts | create, delete, get, list, patch, update, watch |
| manager-role | "" | pods | get, list, watch |
| manager-role | "" | events | create, patch |
| manager-role | rbac.authorization.k8s.io | roles, rolebindings | create, delete, get, list, patch, update, watch |
| manager-role | networking.istio.io | gateways, virtualservices, destinationrules | create, delete, get, list, patch, update, watch |
| manager-role | security.istio.io | authorizationpolicies | create, delete, get, list, patch, update, watch |
| manager-role | authorino.kuadrant.io | authconfigs | create, delete, get, list, patch, update, watch |
| manager-role | route.openshift.io | routes, routes/custom-host | create, delete, get, list, patch, update, watch |
| manager-role | user.openshift.io | groups | create, delete, get, list, patch, update, watch |
| manager-role | config.openshift.io | ingresses | get, list, watch |
| leader-election-role | "" | configmaps | get, list, watch, create, update, patch, delete |
| leader-election-role | coordination.k8s.io | leases | get, list, watch, create, update, patch, delete |
| modelregistry-editor-role | modelregistry.opendatahub.io | modelregistries | create, delete, get, list, patch, update, watch |
| modelregistry-viewer-role | modelregistry.opendatahub.io | modelregistries | get, list, watch |

### RBAC - Role Bindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| manager-role-binding | model-registry-operator-system | manager-role (ClusterRole) | controller-manager |
| leader-election-role-binding | model-registry-operator-system | leader-election-role | controller-manager |
| registry-user-{registry-name} | model-registry namespace | registry-user-{registry-name} | Users/SAs authorized to access registry |

### RBAC - Per-Instance Roles

| Role Name | API Group | Resources | Verbs | Purpose |
|-----------|-----------|-----------|-------|---------|
| registry-user-{registry-name} | "" | services/{registry-name} | get | Grants permission to access specific model registry instance (used by Authorino) |

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| {registry-name}-db | Opaque | Database password for model registry | User | No |
| modelregistry-sample-rest-credential | kubernetes.io/tls | TLS certificates for REST Gateway endpoint | cert-manager or manual | Depends on provisioner |
| modelregistry-sample-grpc-credential | kubernetes.io/tls | TLS certificates for gRPC Gateway endpoint | cert-manager or manual | Depends on provisioner |
| model-registry-db-credential | Opaque | Database CA certificate and optional client certificates | cert-manager or manual | Depends on provisioner |
| controller-manager-sa-token | kubernetes.io/service-account-token | Service account token for operator | Kubernetes | Yes |

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| REST API (external) | GET, POST, PUT, DELETE | Bearer Token (Kubernetes SA token) | Authorino (via Istio AuthorizationPolicy CUSTOM action) | Kubernetes TokenReview + SubjectAccessReview (user must have GET permission on service resource) |
| gRPC API (external) | All gRPC methods | Bearer Token (Kubernetes SA token) | Authorino (via Istio AuthorizationPolicy CUSTOM action) | Kubernetes TokenReview + SubjectAccessReview (user must have GET permission on service resource) |
| REST API (internal) | GET, POST, PUT, DELETE | None | None | Open within cluster (protected by Istio mTLS when enabled) |
| gRPC API (internal) | All gRPC methods | None | None | Open within cluster (protected by Istio mTLS when enabled) |
| Operator Metrics | GET | OpenShift Serving Cert | kube-rbac-proxy sidecar | Kubernetes RBAC via TokenReview |

### Istio Security Configuration

| Resource Type | Name Pattern | Configuration | Purpose |
|--------------|--------------|---------------|---------|
| DestinationRule | {registry-name} | trafficPolicy.tls.mode: ISTIO_MUTUAL (default) | Enforces mTLS for traffic to model registry pods |
| AuthorizationPolicy | {registry-name}-authorino | action: CUSTOM, provider: {auth-provider} | Delegates all requests to Authorino for authentication |
| AuthConfig | {registry-name} | KubernetesTokenReview + SubjectAccessReview | Validates K8s tokens and checks user has GET permission on service |

### User Groups (OpenShift Only)

| Group Name | Type | Purpose |
|------------|------|---------|
| {registry-name}-users | user.openshift.io/v1 Group | Simplifies granting access to model registry (operator creates RoleBinding to this group) |

## Data Flows

### Flow 1: External REST API Access (with Istio Gateway and Authorino)

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | External Client | Istio Ingress Gateway | 443/TCP | HTTPS | TLS 1.2+ | Bearer Token in Authorization header |
| 2 | Istio Ingress Gateway | Istio AuthorizationPolicy | N/A | N/A | N/A | Policy evaluation (delegates to Authorino) |
| 3 | Istio Proxy | Authorino Service | 50051/TCP | gRPC | mTLS | Envoy filter passes request metadata |
| 4 | Authorino | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | Service account token |
| 5 | Authorino | Istio Proxy | N/A | N/A | N/A | Returns allow/deny decision |
| 6 | Istio Ingress Gateway | Model Registry Service (VirtualService) | 8080/TCP | HTTP | mTLS (if ISTIO_MUTUAL) | Validated token |
| 7 | Model Registry REST Container | gRPC Container (localhost) | 9090/TCP | gRPC | None (localhost) | None |
| 8 | gRPC Container | Database | 5432/TCP or 3306/TCP | PostgreSQL/MySQL | TLS (if configured) | Username/Password |

### Flow 2: Internal Service Access (without Istio)

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Client Pod | Model Registry Service | 8080/TCP or 9090/TCP | HTTP or gRPC | None | None |
| 2 | Model Registry Container | gRPC Container (same pod) | 9090/TCP | gRPC | None (localhost) | None |
| 3 | gRPC Container | Database | 5432/TCP or 3306/TCP | PostgreSQL/MySQL | TLS (if configured) | Username/Password |

### Flow 3: Operator Reconciliation

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Operator Controller | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | Service account token |
| 2 | Operator Controller | Istio API (if enabled) | 6443/TCP | HTTPS | TLS 1.2+ | Service account token |
| 3 | Operator Controller | Authorino API (if enabled) | 6443/TCP | HTTPS | TLS 1.2+ | Service account token |
| 4 | Operator Controller | OpenShift API (if OpenShift) | 6443/TCP | HTTPS | TLS 1.2+ | Service account token |

### Flow 4: OpenShift Route Access (without Istio)

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | External Client | OpenShift Router | 443/TCP | HTTPS | TLS 1.2+ (edge termination) | None |
| 2 | OpenShift Router | Model Registry Service | 8080/TCP | HTTP | None | None |
| 3 | Model Registry REST Container | gRPC Container (localhost) | 9090/TCP | gRPC | None | None |
| 4 | gRPC Container | Database | 5432/TCP or 3306/TCP | PostgreSQL/MySQL | TLS (if configured) | Username/Password |

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| Kubernetes API Server | REST API | 6443/TCP | HTTPS | TLS 1.2+ | CR management, resource creation, RBAC checks |
| PostgreSQL Database | SQL Protocol | 5432/TCP | PostgreSQL | TLS (configurable) | Persistent storage for ML metadata |
| MySQL Database | SQL Protocol | 3306/TCP | MySQL | TLS (configurable) | Alternative persistent storage for ML metadata |
| Istio Control Plane | xDS API | 15012/TCP | gRPC | mTLS | Service mesh configuration and certificate management |
| Authorino | gRPC API | 50051/TCP | gRPC | mTLS | External authorization for API requests |
| Prometheus | HTTP API | 8443/TCP | HTTPS | TLS 1.2+ | Metrics collection from operator |
| OpenShift Ingress | OpenShift API | 6443/TCP | HTTPS | TLS 1.2+ | Query cluster ingress domain for auto-configuration |

## Container Images

| Component | Default Image | Purpose |
|-----------|---------------|---------|
| Operator | quay.io/opendatahub/model-registry-operator:latest | Model Registry operator controller |
| REST Service | quay.io/opendatahub/model-registry:latest | Model Registry REST API server |
| gRPC Service | quay.io/opendatahub/mlmd-grpc-server:latest | ML Metadata gRPC server |

## Environment Variables (Operator)

| Variable | Default | Purpose |
|----------|---------|---------|
| GRPC_IMAGE | quay.io/opendatahub/mlmd-grpc-server:latest | Override gRPC container image |
| REST_IMAGE | quay.io/opendatahub/model-registry:latest | Override REST container image |
| ENABLE_WEBHOOKS | false | Enable admission webhooks for validation |
| CREATE_AUTH_RESOURCES | true | Create Authorino and RBAC resources |
| DEFAULT_DOMAIN | "" | Default domain for Istio Gateway hosts |
| DEFAULT_CERT | "" | Default TLS certificate secret name |
| DEFAULT_AUTH_PROVIDER | "" | Default Authorino provider name |
| DEFAULT_AUTH_CONFIG_LABELS | "" | Default labels for AuthConfig resources |

## Deployment Configurations

### Operator Deployment

| Setting | Value | Purpose |
|---------|-------|---------|
| Replicas | 1 | Single operator instance with leader election |
| CPU Request | 10m | Minimal CPU for operator controller |
| Memory Request | 64Mi | Minimal memory for operator controller |
| CPU Limit | 500m | Maximum CPU for operator controller |
| Memory Limit | 128Mi | Maximum memory for operator controller |
| Security Context | runAsNonRoot: true, no privilege escalation | Restricted security posture |

### Model Registry Deployment

| Setting | Value | Purpose |
|---------|-------|---------|
| Replicas | 1 | Single instance (no HA support currently) |
| Containers | 2 (REST + gRPC) | Separate containers for REST and gRPC APIs |
| Istio Injection | Controlled by spec.istio | Conditional sidecar injection |
| Security Context | Inherited from namespace | Follows namespace pod security standards |

## Recent Changes

| Commit | Date | Changes |
|--------|------|---------|
| 002ecbb | Recent | - Add govulncheck<br>- Fix protobuf dependency<br>- Fixes RHOAIENG-13878 |
| 5fee736 | Recent | - Remove static AUTH_PROVIDER in istio.env to allow operator to set it at runtime<br>- Fixes #139 |
| b8f3211 | Recent | - Replace rbac proxy container with controller metrics server authentication<br>- Fixes RHOAIENG-13837 |
| a5e4b92 | Recent | - Refactor defaulting and validating webhooks<br>- Fixes RHOAIENG-13113 |
| 637ed69 | Recent | - Cleanup optional properties<br>- Fixes RHOAIENG-12838 |
| ab472e6 | Recent | - Set authorino config properties in ODH overlay from ODH operator configmap auth-refs<br>- Fixes RHOAIENG-5076 |
| 77cc222 | Recent | - Switch from go build to make build in Dockerfile |
| 033afb2 | Recent | - Add missing DB labels in DB secrets<br>- Fixes RHOAIENG-12126 |
| e0b7589 | Recent | - Add unexpected reconcile errors to false Available status in MR CR<br>- Fixes RHOAIENG-10027 |
| c4f88ba | Recent | - Add annotations for external service host and port in MR service<br>- Fixes RHOAIENG-11092 |
| e8d902b | Recent | - Add labels to DB sample resources<br>- Fixes RHOAIENG-11363 |
| 13dfaf5 | Recent | - Add support for mutating and validating webhooks<br>- Fixes RHOAIENG-906 |
| 6459fb9 | Recent | - Ensure functions use inherited context |
| 8c1505c | Recent | - Add OpenShift serving certs to metrics endpoint<br>- Fixes RHOAIENG-1828 |
| 245d5f0 | Recent | - Add env variable DEFAULT_CERT to specify default cert secret name<br>- Fixes RHOAIENG-10035 |

## Notes

- **No HA Support**: Model Registry deployments currently run with 1 replica; high availability is not supported
- **Database Required**: Every ModelRegistry instance requires an external PostgreSQL or MySQL database
- **Istio Optional**: The operator supports both plain Kubernetes deployments and Istio-enabled deployments
- **OpenShift Integration**: Automatic Route creation and domain detection in OpenShift clusters
- **Authorization Model**: When Istio is enabled, uses Kubernetes RBAC model where users need GET permission on the service resource
- **Certificate Management**: Production deployments should use cert-manager or similar for TLS certificate lifecycle
- **Metrics**: Operator exposes Prometheus metrics on port 8443 with OpenShift serving certificates
- **Webhooks**: Admission webhooks are disabled by default but can be enabled via ENABLE_WEBHOOKS environment variable
- **Sample Configurations**: Repository includes multiple kustomize samples for different deployment scenarios (MySQL/PostgreSQL, with/without Istio, with/without TLS)
