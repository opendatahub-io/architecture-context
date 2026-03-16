# Component: Model Registry Operator

## Metadata
- **Repository**: https://github.com/red-hat-data-services/model-registry-operator.git
- **Version**: a169b40 (rhoai-2.17 branch)
- **Distribution**: RHOAI
- **Languages**: Go
- **Deployment Type**: Kubernetes Operator

## Purpose
**Short**: Kubernetes operator that manages the lifecycle of Model Registry service instances and their associated resources.

**Detailed**: The Model Registry Operator is a Kubernetes controller that reconciles ModelRegistry custom resources to deploy and manage Model Registry services. The operator automates the deployment of the Model Registry API, which provides both REST and gRPC endpoints for storing and retrieving ML model metadata using ML Metadata (MLMD) as the backend storage layer. It supports PostgreSQL and MySQL databases, optional Istio service mesh integration for security and traffic management, and Authorino-based authentication and authorization. The operator creates and manages all necessary Kubernetes resources including deployments, services, service accounts, RBAC policies, and optionally Istio resources (gateways, virtual services, destination rules, authorization policies) to provide secure, production-ready model registry instances.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| Operator Manager | Go Application | Reconciles ModelRegistry CRs and manages lifecycle of registry instances |
| Model Registry gRPC Server | Container (mlmd-grpc-server) | Provides gRPC API for ML Metadata operations on port 9090 |
| Model Registry REST Proxy | Container (model-registry) | Provides REST API proxy to gRPC backend on port 8080 |
| Kube-RBAC Proxy | Sidecar Container | Provides secure metrics endpoint with RBAC enforcement |
| Database Backend | External PostgreSQL/MySQL | Stores ML metadata; required external dependency |

## APIs Exposed

### Custom Resource Definitions (CRDs)

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| modelregistry.opendatahub.io | v1alpha1 | ModelRegistry | Namespaced | Defines a Model Registry instance with database config, service ports, Istio settings, and TLS options |

### HTTP Endpoints

#### Operator Metrics

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /metrics | GET | 8443/TCP | HTTPS | TLS 1.2+ | Bearer Token (ServiceAccount) | Prometheus metrics for operator controller |
| /healthz | GET | 8081/TCP | HTTP | None | None | Operator liveness probe |
| /readyz | GET | 8081/TCP | HTTP | None | None | Operator readiness probe |

#### Model Registry REST API

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /api/model_registry/v1alpha3/* | GET, POST, PUT, PATCH, DELETE | 8080/TCP | HTTP | None (internal) | Bearer Token (Authorino, if Istio enabled) | REST API for model registry operations |

### gRPC Services

| Service | Port | Protocol | Encryption | Auth | Purpose |
|---------|------|----------|------------|------|---------|
| ML Metadata gRPC API | 9090/TCP | gRPC | None (internal), mTLS (with Istio) | Bearer Token (Authorino, if Istio enabled) | gRPC API for ML Metadata operations |

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| PostgreSQL | 5432 (default port) | Yes (or MySQL) | Database backend for ML Metadata storage |
| MySQL | 3306 (default port) | Yes (or PostgreSQL) | Alternative database backend for ML Metadata storage |
| Istio | N/A | No | Service mesh for mTLS, traffic management, and gateway ingress |
| Authorino | N/A | No (requires Istio) | Authentication and authorization enforcement via Kubernetes RBAC |
| Prometheus Operator | N/A | No | Metrics collection via ServiceMonitor |
| OpenShift | N/A | No | Automatic Route creation for gateways and services |

### Internal ODH Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| None | N/A | Model Registry Operator is standalone; consumed by other components for model metadata storage |

## Network Architecture

### Services

#### Operator Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| controller-manager-metrics-service | ClusterIP | 8443/TCP | 8443 | HTTPS | TLS 1.2+ | Bearer Token | Internal |

#### Model Registry Services (per instance)

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| {registry-name} | ClusterIP | 8080/TCP | 8080 | HTTP | None (mTLS with Istio sidecar) | Bearer Token (with Istio/Authorino) | Internal |
| {registry-name} | ClusterIP | 9090/TCP | 9090 | gRPC | None (mTLS with Istio sidecar) | Bearer Token (with Istio/Authorino) | Internal |

### Ingress

#### Istio Gateway (when enabled)

| Name | Type | Hosts | Port | Protocol | Encryption | TLS Mode | Exposure |
|------|------|-------|------|----------|------------|----------|----------|
| {registry-name} | Istio Gateway | {registry-name}-rest.{domain} | 443/TCP (configurable) | HTTPS | TLS 1.2+ | SIMPLE, MUTUAL, or ISTIO_MUTUAL | External |
| {registry-name} | Istio Gateway | {registry-name}-grpc.{domain} | 443/TCP (configurable) | HTTPS | TLS 1.2+ | SIMPLE, MUTUAL, or ISTIO_MUTUAL | External |

#### OpenShift Routes (when enabled on OpenShift)

| Name | Type | Hosts | Port | Protocol | Encryption | TLS Mode | Exposure |
|------|------|-------|------|----------|------------|----------|----------|
| {namespace}-{registry-name}-rest | OpenShift Route | Auto-generated | 443/TCP | HTTPS | TLS 1.2+ | Edge Termination | External |
| {namespace}-{registry-name}-grpc | OpenShift Route | Auto-generated | 443/TCP | HTTPS | TLS 1.2+ | Edge Termination | External |
| {registry-name}-http | OpenShift Route | Auto-generated | 80/TCP | HTTP | None | None | External (non-Istio, when serviceRoute=enabled) |

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| PostgreSQL Database | 5432/TCP (configurable) | PostgreSQL Wire Protocol | TLS (configurable, sslmode) | Username/Password | ML Metadata storage backend |
| MySQL Database | 3306/TCP (configurable) | MySQL Wire Protocol | TLS (configurable, SSL certs) | Username/Password | ML Metadata storage backend |

## Security

### RBAC - Cluster Roles

| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|
| manager-role | apps | deployments | create, delete, get, list, patch, update, watch |
| manager-role | "" | services, serviceaccounts | create, delete, get, list, patch, update, watch |
| manager-role | "" | endpoints, pods, pods/log | get, list, watch |
| manager-role | "" | events | create, patch |
| manager-role | modelregistry.opendatahub.io | modelregistries | create, delete, get, list, patch, update, watch |
| manager-role | modelregistry.opendatahub.io | modelregistries/status | get, patch, update |
| manager-role | modelregistry.opendatahub.io | modelregistries/finalizers | update |
| manager-role | networking.istio.io | gateways, virtualservices, destinationrules | create, delete, get, list, patch, update, watch |
| manager-role | security.istio.io | authorizationpolicies | create, delete, get, list, patch, update, watch |
| manager-role | authorino.kuadrant.io | authconfigs | create, delete, get, list, patch, update, watch |
| manager-role | rbac.authorization.k8s.io | roles, rolebindings | create, delete, get, list, patch, update, watch |
| manager-role | route.openshift.io | routes, routes/custom-host | create, delete, get, list, patch, update, watch |
| manager-role | user.openshift.io | groups | create, delete, get, list, patch, update, watch |
| manager-role | config.openshift.io | ingresses | get, list, watch |
| auth-proxy-client-clusterrole | authentication.k8s.io | tokenreviews | create |
| auth-proxy-client-clusterrole | authorization.k8s.io | subjectaccessreviews | create |

### RBAC - Role Bindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| manager-rolebinding | model-registry-operator-system | manager-role (ClusterRole) | controller-manager |
| leader-election-rolebinding | model-registry-operator-system | leader-election-role (Role) | controller-manager |
| auth-proxy-rolebinding | model-registry-operator-system | auth-proxy-role (Role) | controller-manager |
| registry-user-{registry-name}-binding | {registry-namespace} | registry-user-{registry-name} (Role) | Per-instance binding to users/groups |

### RBAC - Roles (Per Model Registry Instance)

| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|
| leader-election-role | "" | configmaps | get, list, watch, create, update, patch, delete |
| leader-election-role | coordination.k8s.io | leases | get, list, watch, create, update, patch, delete |
| leader-election-role | "" | events | create, patch |
| auth-proxy-role | "" | configmaps | get, list, watch |
| registry-user-{registry-name} | "" | services | get |

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| {database}-password-secret | Opaque | Database password for PostgreSQL/MySQL connection | User/External | No |
| {database}-ssl-cert | Opaque | Client SSL certificate for database connection | User/External/cert-manager | No |
| {database}-ssl-key | Opaque | Client SSL private key for database connection | User/External/cert-manager | No |
| {database}-ssl-rootcert | Opaque | Database CA certificate(s) | User/External/cert-manager | No |
| {registry-name}-rest-credential | kubernetes.io/tls | TLS certificate for REST gateway endpoint | User/cert-manager | No |
| {registry-name}-grpc-credential | kubernetes.io/tls | TLS certificate for gRPC gateway endpoint | User/cert-manager | No |

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| /metrics | GET | Bearer Token (ServiceAccount) | kube-rbac-proxy | Kubernetes RBAC via SubjectAccessReview |
| Model Registry REST API (with Istio) | GET, POST, PUT, PATCH, DELETE | Bearer Token (Kubernetes user/SA) | Authorino via Istio AuthorizationPolicy | Kubernetes RBAC - user must have GET permission on service/{registry-name} in namespace |
| Model Registry gRPC API (with Istio) | All | Bearer Token (Kubernetes user/SA) | Authorino via Istio AuthorizationPolicy | Kubernetes RBAC - user must have GET permission on service/{registry-name} in namespace |
| Model Registry APIs (without Istio) | All | None | None | Unprotected cluster-internal access |

### Service Mesh Security (Istio)

| Resource | Type | Configuration |
|----------|------|---------------|
| DestinationRule | networking.istio.io/v1beta1 | TLS mode: ISTIO_MUTUAL (default) - automatic mTLS between services in mesh |
| Gateway TLS | networking.istio.io/v1beta1 | Modes: SIMPLE (server TLS), MUTUAL (client certs), ISTIO_MUTUAL (auto mTLS), OPTIONAL_MUTUAL |
| AuthorizationPolicy | security.istio.io/v1beta1 | CUSTOM action - delegates to Authorino external authorization provider |
| AuthConfig | authorino.kuadrant.io/v1beta2 | Kubernetes TokenReview authentication + SubjectAccessReview authorization |

## Data Flows

### Flow 1: Model Registry REST API Call (with Istio Gateway)

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | External Client | Istio Ingress Gateway | 443/TCP | HTTPS | TLS 1.2+ (Gateway cert) | Bearer Token in Authorization header |
| 2 | Istio Ingress Gateway | VirtualService | N/A | N/A | N/A | N/A |
| 3 | VirtualService | AuthorizationPolicy (Authorino) | N/A | N/A | N/A | Token validation via Kubernetes TokenReview |
| 4 | Authorino | Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount token |
| 5 | Authorino | AuthConfig RBAC Check | N/A | N/A | N/A | SubjectAccessReview for service GET permission |
| 6 | VirtualService (after authz) | Model Registry Service | 8080/TCP | HTTP | mTLS (ISTIO_MUTUAL) | Validated identity in headers |
| 7 | Model Registry REST Container | Model Registry gRPC Container (localhost) | 9090/TCP | gRPC | None (localhost) | None (same pod) |
| 8 | Model Registry gRPC Container | PostgreSQL/MySQL Database | 5432/3306 TCP | PostgreSQL/MySQL Protocol | TLS (if configured) | Username/Password |

### Flow 2: Model Registry gRPC API Call (with Istio Gateway)

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | External gRPC Client | Istio Ingress Gateway | 443/TCP | HTTPS (HTTP/2) | TLS 1.2+ (Gateway cert) | Bearer Token in metadata |
| 2 | Istio Ingress Gateway | VirtualService | N/A | N/A | N/A | N/A |
| 3 | VirtualService | AuthorizationPolicy (Authorino) | N/A | N/A | N/A | Token validation via Kubernetes TokenReview |
| 4 | Authorino | Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount token |
| 5 | Authorino | AuthConfig RBAC Check | N/A | N/A | N/A | SubjectAccessReview for service GET permission |
| 6 | VirtualService (after authz) | Model Registry Service | 9090/TCP | gRPC | mTLS (ISTIO_MUTUAL) | Validated identity in headers |
| 7 | Model Registry gRPC Container | PostgreSQL/MySQL Database | 5432/3306 TCP | PostgreSQL/MySQL Protocol | TLS (if configured) | Username/Password |

### Flow 3: Operator Reconciliation

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Operator Manager | Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount token |
| 2 | Operator Manager | Create/Update Deployment | N/A | N/A | N/A | ClusterRole permissions |
| 3 | Operator Manager | Create/Update Service | N/A | N/A | N/A | ClusterRole permissions |
| 4 | Operator Manager (if Istio enabled) | Create/Update Istio Resources | N/A | N/A | N/A | ClusterRole permissions |
| 5 | Operator Manager (if Istio enabled) | Create/Update Authorino AuthConfig | N/A | N/A | N/A | ClusterRole permissions |
| 6 | Operator Manager | Update ModelRegistry Status | N/A | N/A | N/A | ClusterRole permissions |

### Flow 4: Metrics Collection

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Prometheus | controller-manager-metrics-service | 8443/TCP | HTTPS | TLS 1.2+ | Bearer Token (ServiceAccount) |
| 2 | kube-rbac-proxy | Kubernetes API Server (TokenReview) | 6443/TCP | HTTPS | TLS 1.2+ | Bearer Token validation |
| 3 | kube-rbac-proxy | Kubernetes API Server (SubjectAccessReview) | 6443/TCP | HTTPS | TLS 1.2+ | RBAC authorization check |
| 4 | kube-rbac-proxy | Operator Manager /metrics | 8080/TCP | HTTP | None (localhost) | Authorized request |

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| Kubernetes API Server | REST API | 6443/TCP | HTTPS | TLS 1.2+ | CRD reconciliation, resource management, RBAC checks |
| PostgreSQL Database | PostgreSQL Wire Protocol | 5432/TCP | PostgreSQL | TLS (sslmode configurable) | ML Metadata persistence |
| MySQL Database | MySQL Wire Protocol | 3306/TCP | MySQL | TLS (SSL certs configurable) | ML Metadata persistence |
| Istio Ingress Gateway | Istio Gateway API | N/A | N/A | N/A | External traffic routing to model registry services |
| Authorino | External Authorization API | N/A | gRPC | mTLS | Authentication and authorization enforcement |
| Prometheus | Metrics Scraping | 8443/TCP | HTTPS | TLS 1.2+ | Operator metrics collection |
| OpenShift Router | Route API | N/A | N/A | N/A | Automatic external route creation for gateways and services |

## Deployment Architecture

### Operator Deployment

- **Namespace**: `model-registry-operator-system` (or `opendatahub` when installed as ODH component)
- **Replicas**: 1 (with leader election)
- **Containers**:
  - `manager`: Operator controller (Go binary `/manager`)
  - `kube-rbac-proxy`: Metrics endpoint security proxy
- **Images**:
  - Operator: Built from Dockerfile.konflux using `registry.access.redhat.com/ubi8/go-toolset:1.21` and `registry.access.redhat.com/ubi8/ubi-minimal`
  - Default gRPC image: `quay.io/opendatahub/mlmd-grpc-server:latest`
  - Default REST image: `quay.io/opendatahub/model-registry:latest`

### Model Registry Deployment (per instance)

- **Namespace**: User-specified namespace (where ModelRegistry CR is created)
- **Replicas**: 1
- **Containers**:
  - `grpc-container`: ML Metadata gRPC server
  - `rest-container`: Model Registry REST API proxy
- **Volumes**:
  - Database SSL certificates (if configured)
  - ConfigMaps for CA certificates (if configured)
- **Istio Sidecar**: Injected when `spec.istio` is configured
- **Probes**:
  - Liveness: TCP socket probe on container ports
  - Readiness: TCP socket probe on container ports

## Configuration

### Operator Environment Variables

| Variable | Default | Purpose |
|----------|---------|---------|
| GRPC_IMAGE | quay.io/opendatahub/mlmd-grpc-server:latest | Default image for gRPC server container |
| REST_IMAGE | quay.io/opendatahub/model-registry:latest | Default image for REST proxy container |
| ENABLE_WEBHOOKS | false | Enable admission webhooks for validation |
| CREATE_AUTH_RESOURCES | true | Create Authorino AuthConfig resources |
| DEFAULT_DOMAIN | "" | Default domain for Istio Gateway hosts (auto-detected on OpenShift) |
| DEFAULT_CERT | "" | Default TLS certificate secret name for Gateway |
| DEFAULT_AUTH_PROVIDER | "" | Default Authorino provider name |
| DEFAULT_AUTH_CONFIG_LABELS | "" | Default labels for AuthConfig selector |

### ModelRegistry CR Configuration Options

| Field | Required | Default | Purpose |
|-------|----------|---------|---------|
| spec.rest.port | No | 8080 | REST API listen port |
| spec.rest.image | No | Operator env GRPC_IMAGE | Override REST container image |
| spec.rest.serviceRoute | No | disabled | Enable OpenShift Route creation |
| spec.grpc.port | No | 9090 | gRPC API listen port |
| spec.grpc.image | No | Operator env REST_IMAGE | Override gRPC container image |
| spec.postgres | Yes (or mysql) | N/A | PostgreSQL database configuration |
| spec.mysql | Yes (or postgres) | N/A | MySQL database configuration |
| spec.istio | No | N/A | Istio service mesh configuration |
| spec.istio.tlsMode | No | ISTIO_MUTUAL | DestinationRule TLS mode |
| spec.istio.authProvider | No | Operator env | Authorino provider name |
| spec.istio.gateway | No | N/A | Istio Gateway configuration |

## Recent Changes

| Commit | Date | Changes |
|--------|------|---------|
| a169b40 | 2025-03-05 | chore(deps): update konflux references (#177) |
| 3a5f98e | 2025-03-03 | chore(deps): update konflux references (#171) |
| 2d9ddac | 2025-03-03 | chore(deps): update konflux references (#170) |
| 29e43d4 | 2025-03-02 | chore(deps): update konflux references to b9cb1e1 (#166) |
| dac2c08 | 2025-02-28 | chore(deps): update konflux references to 944e769 (#160) |
| a26e682 | 2025-02-27 | chore(deps): update konflux references to 6673cbd (#155) |
| c310187 | 2025-02-27 | chore(deps): update konflux references (#153) |
| 502095d | 2025-02-27 | chore(deps): update konflux references to 8b6f22f (#149) |
| 54b27a9 | 2025-02-26 | chore(deps): update konflux references (#145) |
| b652cba | 2025-02-25 | chore(deps): update registry.access.redhat.com/ubi8/ubi-minimal docker digest to c38cc77 (#141) |
| 86f33f0 | 2025-02-24 | chore(deps): update konflux references to 5bc6129 (#135) |
| bc38d15 | 2025-02-16 | chore(deps): update konflux references to b78123a (#129) |
| b3ba470 | 2025-02-12 | chore(deps): update konflux references |
| fb6ea57 | 2025-02-12 | chore(deps): update konflux references to 5a78c42 |
| 9feb165 | 2025-02-11 | chore(deps): update konflux references to aab5f0f |
| 892a8b6 | 2025-02-11 | chore(deps): update konflux references to dc47cb5 |
| 5bad7be | 2025-02-11 | chore(deps): update konflux references |
| 6548b4d | 2025-02-09 | chore(deps): update konflux references to e603b3d |
| 93d9524 | 2025-02-06 | chore(deps): update konflux references |
| 0d755a7 | 2025-01-31 | chore(deps): update konflux references to 593714c |

## Notes

- **Database Requirement**: ModelRegistry requires either PostgreSQL or MySQL; the operator does not provision databases
- **Istio Integration**: When Istio is enabled, the operator creates comprehensive service mesh resources including mTLS, gateways, and authorization policies
- **Authentication**: With Istio+Authorino, authentication uses Kubernetes bearer tokens validated via TokenReview API
- **Authorization**: RBAC is enforced through Kubernetes SubjectAccessReview - users/serviceaccounts must have GET permission on the model registry service
- **User Management**: Operator creates a Group `{registry-name}-users` (on OpenShift) and Role `registry-user-{registry-name}` to simplify access management
- **TLS Configuration**: Supports multiple TLS modes for both database connections and Istio gateways (SIMPLE, MUTUAL, ISTIO_MUTUAL)
- **Multi-Database Support**: Can connect to PostgreSQL or MySQL with extensive SSL/TLS configuration options
- **Built with Konflux**: RHOAI builds use Dockerfile.konflux for Konflux CI/CD pipeline integration
- **Leader Election**: Operator uses leader election to support high availability deployments
- **Finalizers**: Operator uses finalizers to clean up resources (Groups, Roles) when ModelRegistry CR is deleted
