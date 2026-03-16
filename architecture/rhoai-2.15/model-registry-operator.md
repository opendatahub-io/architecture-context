# Component: Model Registry Operator

## Metadata
- **Repository**: https://github.com/red-hat-data-services/model-registry-operator.git
- **Version**: dc70e33 (rhoai-2.15 branch)
- **Distribution**: RHOAI
- **Languages**: Go 1.21
- **Deployment Type**: Kubernetes Operator

## Purpose
**Short**: Manages the lifecycle of Model Registry service instances in Kubernetes/OpenShift clusters.

**Detailed**: The Model Registry Operator is a Kubernetes controller that reconciles ModelRegistry custom resources to deploy and manage Model Registry API services. The operator creates deployments with both REST and gRPC endpoints that provide access to ML model metadata stored in PostgreSQL or MySQL databases. It supports integration with Istio service mesh for mTLS communication, Authorino for token-based authentication/authorization, and OpenShift Routes or Istio Gateways for external access. The operator manages the complete lifecycle including RBAC setup, TLS certificate configuration, database connections with optional SSL, and service mesh policy enforcement.

The Model Registry service itself is a metadata store for machine learning models, providing versioning, artifact tracking, and model lineage capabilities through both RESTful HTTP and gRPC APIs backed by ML Metadata (MLMD) protocol buffers.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| model-registry-operator controller-manager | Deployment | Main operator pod that reconciles ModelRegistry CRs and manages child resources |
| ModelRegistry CRD | Custom Resource | Declarative API for defining Model Registry service instances |
| model-registry deployment (managed) | Deployment | Application pod created by operator containing gRPC and REST containers |
| model-registry service (managed) | Service | ClusterIP service exposing gRPC (9090) and REST (8080) endpoints |
| Istio Gateway (optional, managed) | Gateway | Ingress gateway for external REST and gRPC access via service mesh |
| Authorino AuthConfig (optional, managed) | AuthConfig | Authentication/authorization policy for Kubernetes token validation |
| Webhook Server | Service | Admission webhooks for validating and defaulting ModelRegistry resources |

## APIs Exposed

### Custom Resource Definitions (CRDs)

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| modelregistry.opendatahub.io | v1alpha1 | ModelRegistry | Namespaced | Defines desired state of a Model Registry service instance including database config, ports, Istio settings, and TLS |

### HTTP Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /api/model_registry/v1alpha3/* | GET, POST, PUT, DELETE, PATCH | 8080/TCP | HTTP | None (internal), TLS 1.2+ (via Istio) | Bearer Token (when Istio enabled) | REST API for model registry operations - CRUD on registered models, model versions, artifacts |
| /healthz | GET | 8081/TCP | HTTP | None | None | Operator controller liveness probe |
| /readyz | GET | 8081/TCP | HTTP | None | None | Operator controller readiness probe |
| /metrics | GET | 8443/TCP | HTTPS | TLS 1.2+ | mTLS | Operator Prometheus metrics endpoint with controller-runtime metrics |

### gRPC Services

| Service | Port | Protocol | Encryption | Auth | Purpose |
|---------|------|----------|------------|------|---------|
| ml_metadata.MetadataStoreService | 9090/TCP | gRPC | None (internal), mTLS (via Istio) | Bearer Token (when Istio enabled) | ML Metadata gRPC API for storing and retrieving ML model metadata, artifacts, executions, and contexts |

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| PostgreSQL | 11+ | Yes (or MySQL) | Primary metadata storage backend for ML Metadata protocol buffers |
| MySQL | 5.7+ / 8.0+ | Yes (or PostgreSQL) | Alternative metadata storage backend for ML Metadata |
| Istio / OpenShift Service Mesh | 1.20+ | No | Service mesh for mTLS, traffic management, and policy enforcement |
| Authorino | 0.17+ | No | External authorization for Kubernetes token validation when Istio enabled |
| cert-manager | Any | No | Optional TLS certificate management for gateway endpoints |

### Internal ODH/RHOAI Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| opendatahub-operator | CR Management | Installs and configures model-registry-operator as a managed component |
| Istio (ODH/RHOAI) | Service Mesh | Provides mTLS, AuthorizationPolicies, and external gateway routing |
| Authorino (ODH/RHOAI) | Authentication | Kubernetes token review and RBAC-based authorization for model registry services |

## Network Architecture

### Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| controller-manager-metrics-service | ClusterIP | 8443/TCP | 8443 | HTTPS | TLS 1.2+ | mTLS client certs | Internal (metrics scraping) |
| webhook-service | ClusterIP | 443/TCP | 9443 | HTTPS | TLS 1.2+ | mTLS (K8s API server) | Internal (admission webhooks) |
| {registry-name} | ClusterIP | 8080/TCP | 8080 | HTTP | None (plaintext) | None (internal) / Bearer Token (via Istio) | Internal (within namespace) |
| {registry-name} | ClusterIP | 9090/TCP | 9090 | gRPC | None (plaintext) | None (internal) / Bearer Token (via Istio) | Internal (within namespace) |

### Ingress

| Name | Type | Hosts | Port | Protocol | Encryption | TLS Mode | Exposure |
|------|------|-------|------|----------|------------|----------|----------|
| {registry-name} (Istio Gateway) | Istio Gateway | {registry-name}-rest.{domain} | 80/TCP or 443/TCP | HTTP or HTTPS | None or TLS 1.2+ | SIMPLE / MUTUAL / ISTIO_MUTUAL | External (via Istio ingress gateway) |
| {registry-name} (Istio Gateway) | Istio Gateway | {registry-name}-grpc.{domain} | 80/TCP or 443/TCP | GRPC or HTTPS | None or TLS 1.2+ | SIMPLE / MUTUAL / ISTIO_MUTUAL | External (via Istio ingress gateway) |
| {registry-name}-http (OpenShift Route) | OpenShift Route | auto-generated | 80/TCP | HTTP | None | N/A | External (when spec.rest.serviceRoute=enabled) |
| {namespace}-{registry-name}-rest (OpenShift Route, Istio) | OpenShift Route | auto-generated | 443/TCP | HTTPS | TLS 1.2+ | passthrough | External (auto-created in istio-system when gateway enabled) |
| {namespace}-{registry-name}-grpc (OpenShift Route, Istio) | OpenShift Route | auto-generated | 443/TCP | HTTPS | TLS 1.2+ | passthrough | External (auto-created in istio-system when gateway enabled) |

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| PostgreSQL database host | 5432/TCP (default) | PostgreSQL | None or TLS 1.2+ (configurable sslmode) | Username/password, optional mTLS client cert | ML Metadata storage - retrieve and persist model metadata, artifacts, lineage |
| MySQL database host | 3306/TCP (default) | MySQL | None or TLS 1.2+ (optional SSL) | Username/password, optional SSL client cert | Alternative ML Metadata storage backend |
| Kubernetes API server | 443/TCP | HTTPS | TLS 1.2+ | Service account token | Read cluster config (OpenShift ingress domain), manage child resources |

## Security

### RBAC - Cluster Roles

| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|
| manager-role | modelregistry.opendatahub.io | modelregistries | create, delete, get, list, patch, update, watch |
| manager-role | modelregistry.opendatahub.io | modelregistries/status | get, patch, update |
| manager-role | modelregistry.opendatahub.io | modelregistries/finalizers | update |
| manager-role | apps | deployments | create, delete, get, list, patch, update, watch |
| manager-role | "" (core) | services, serviceaccounts | create, delete, get, list, patch, update, watch |
| manager-role | "" (core) | pods | get, list, watch |
| manager-role | "" (core) | events | create, patch |
| manager-role | rbac.authorization.k8s.io | roles, rolebindings | create, delete, get, list, patch, update, watch |
| manager-role | networking.istio.io | gateways, virtualservices, destinationrules | create, delete, get, list, patch, update, watch |
| manager-role | security.istio.io | authorizationpolicies | create, delete, get, list, patch, update, watch |
| manager-role | authorino.kuadrant.io | authconfigs | create, delete, get, list, patch, update, watch |
| manager-role | route.openshift.io | routes, routes/custom-host | create, delete, get, list, patch, update, watch |
| manager-role | user.openshift.io | groups | create, delete, get, list, patch, update, watch |
| manager-role | config.openshift.io | ingresses | get, list, watch |
| leader-election-role | "" (core) | configmaps | get, list, watch, create, update, patch, delete |
| leader-election-role | coordination.k8s.io | leases | get, list, watch, create, update, patch, delete |
| leader-election-role | "" (core) | events | create, patch |
| auth-proxy-role | authentication.k8s.io | tokenreviews | create |
| auth-proxy-role | authorization.k8s.io | subjectaccessreviews | create |
| modelregistry-editor-role | modelregistry.opendatahub.io | modelregistries | create, delete, get, list, patch, update, watch |
| modelregistry-viewer-role | modelregistry.opendatahub.io | modelregistries | get, list, watch |
| registry-user-{registry-name} (created per MR) | "" (core) | services | get |

### RBAC - Role Bindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| manager-rolebinding | system (operator ns) | manager-role (ClusterRole) | controller-manager |
| leader-election-rolebinding | system (operator ns) | leader-election-role | controller-manager |
| auth-proxy-rolebinding | system (operator ns) | auth-proxy-role (ClusterRole) | controller-manager |
| {registry-name}-rolebinding | {registry-namespace} | registry-user-{registry-name} | {registry-name} (created per ModelRegistry) |

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| webhook-server-cert | kubernetes.io/tls | Webhook server TLS certificate for admission webhooks | cert-manager or controller-runtime | No (manual) |
| {db-password-secret} | Opaque | Database password for PostgreSQL/MySQL connection | User/external | No |
| {ssl-cert-secret} | Opaque | Client SSL certificate for database mTLS (keys: tls.crt, tls.key, ca.crt) | User/cert-manager | No |
| {gateway-credential-name} | kubernetes.io/tls | TLS certificate for Istio Gateway REST/gRPC endpoints | User/cert-manager | No |
| service-ca-cert (metrics) | Opaque | CA certificate for metrics endpoint mTLS | service-ca-operator (OpenShift) | Yes |

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| /api/model_registry/v1alpha3/* (with Istio) | ALL | Bearer Token (JWT) | Authorino (Istio ext-authz) | Kubernetes TokenReview + SubjectAccessReview (check GET permission on service/{registry-name}) |
| /api/model_registry/v1alpha3/* (without Istio) | ALL | None | N/A | Cluster network policies only |
| gRPC service (with Istio) | ALL | Bearer Token (JWT) in metadata | Authorino (Istio ext-authz) | Kubernetes TokenReview + SubjectAccessReview (check GET permission on service/{registry-name}) |
| /metrics (operator) | GET | mTLS client certificate | controller-runtime authn/authz | Service account token review + RBAC check (system:serviceaccounts must have metrics access) |
| Admission webhooks | ALL | mTLS (K8s API server) | Kubernetes API server | API server validates operator webhook service certificate |

### Service Mesh Policies

| Policy Name | Type | Target | Settings |
|-------------|------|--------|----------|
| {registry-name} AuthorizationPolicy | Istio AuthorizationPolicy | {registry-name} service | Enforces Authorino external authorization (action: CUSTOM, provider: {authProvider}) |
| {registry-name} DestinationRule | Istio DestinationRule | {registry-name} service | TLS mode: ISTIO_MUTUAL (default) - mTLS between pods in mesh |
| {registry-name} VirtualService | Istio VirtualService | {registry-name} service | Routes REST (port 8080) and gRPC (port 9090) traffic from gateway to service |

## Data Flows

### Flow 1: External Client → Model Registry REST API (with Istio)

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | External Client | OpenShift Router / Load Balancer | 443/TCP | HTTPS | TLS 1.2+ | None |
| 2 | OpenShift Router | Istio Ingress Gateway | 443/TCP | HTTPS | TLS 1.2+ | None |
| 3 | Istio Ingress Gateway | Authorino | 50051/TCP | gRPC | mTLS (ISTIO_MUTUAL) | Bearer Token (forwarded) |
| 4 | Authorino | Kubernetes API (TokenReview) | 443/TCP | HTTPS | TLS 1.2+ | Service account token |
| 5 | Authorino | Kubernetes API (SubjectAccessReview) | 443/TCP | HTTPS | TLS 1.2+ | Service account token |
| 6 | Istio Ingress Gateway (authz approved) | Model Registry Service (rest-container) | 8080/TCP | HTTP | mTLS (ISTIO_MUTUAL via Envoy sidecars) | mTLS |
| 7 | rest-container | grpc-container (localhost) | 9090/TCP | gRPC | None (same pod) | None |
| 8 | grpc-container | Database (PostgreSQL/MySQL) | 5432/TCP or 3306/TCP | PostgreSQL/MySQL | TLS (if sslmode configured) | Username/password + optional client cert |

### Flow 2: Model Registry REST API → Database (without Istio)

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Client (internal) | Model Registry Service | 8080/TCP | HTTP | None | None |
| 2 | rest-container | grpc-container (localhost) | 9090/TCP | gRPC | None (same pod) | None |
| 3 | grpc-container | Database (PostgreSQL/MySQL) | 5432/TCP or 3306/TCP | PostgreSQL/MySQL | TLS (if sslmode configured) | Username/password + optional client cert |

### Flow 3: Operator Reconciliation Loop

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | controller-manager | Kubernetes API (watch ModelRegistry CRs) | 443/TCP | HTTPS | TLS 1.2+ | Service account token |
| 2 | controller-manager | Kubernetes API (create/update Deployment, Service, etc.) | 443/TCP | HTTPS | TLS 1.2+ | Service account token |
| 3 | controller-manager (Istio enabled) | Kubernetes API (create Istio Gateway/VirtualService/DestinationRule) | 443/TCP | HTTPS | TLS 1.2+ | Service account token |
| 4 | controller-manager (Istio enabled) | Kubernetes API (create Authorino AuthConfig) | 443/TCP | HTTPS | TLS 1.2+ | Service account token |

### Flow 4: Admission Webhook Validation

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Kubernetes API Server | webhook-service | 443/TCP | HTTPS | TLS 1.2+ | mTLS (API server client cert) |
| 2 | webhook-service (controller-manager) | Response to API Server | 443/TCP | HTTPS | TLS 1.2+ | mTLS |

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| PostgreSQL Database | TCP Connection | 5432/TCP | PostgreSQL wire protocol | TLS (optional, via sslmode) | Store and retrieve ML model metadata, artifacts, executions, and lineage in MLMD format |
| MySQL Database | TCP Connection | 3306/TCP | MySQL wire protocol | TLS (optional, via SSL config) | Alternative backend for ML model metadata storage |
| Istio Ingress Gateway | Istio Gateway/VirtualService | 80/TCP, 443/TCP | HTTP, HTTPS | TLS 1.2+ | Route external traffic to model registry services via service mesh |
| Authorino | AuthConfig CRD | 50051/TCP | gRPC (ext-authz) | mTLS | Validate Kubernetes bearer tokens and enforce RBAC policies for model registry access |
| Kubernetes API Server | REST API | 443/TCP | HTTPS | TLS 1.2+ | Reconcile CRs, manage child resources, TokenReview, SubjectAccessReview |
| Prometheus | Metrics scraping | 8443/TCP | HTTPS | TLS 1.2+ | Collect operator controller-runtime metrics |
| ODH/RHOAI Dashboard | Service annotations | N/A | N/A | N/A | Read routing.opendatahub.io/external-address-* annotations for external endpoint URLs |

## Deployment Architecture

### Operator Deployment

| Component | Image | Replicas | Resources (Requests) | Resources (Limits) |
|-----------|-------|----------|----------------------|-------------------|
| controller-manager | odh-model-registry-operator (Konflux built) | 1 | CPU: 10m, Memory: 64Mi | CPU: 500m, Memory: 128Mi |

### ModelRegistry Deployment (Created by Operator)

| Component | Image | Replicas | Resources | Purpose |
|-----------|-------|----------|-----------|---------|
| grpc-container | quay.io/opendatahub/mlmd-grpc-server:latest | 1 | Configurable via CR | ML Metadata gRPC server exposing port 9090 |
| rest-container | quay.io/opendatahub/model-registry:latest | 1 | Configurable via CR | REST proxy to gRPC server exposing port 8080 |

## Recent Changes

| Commit | Date | Changes |
|--------|------|---------|
| dc70e33 | 2024 | - Merge branch 'opendatahub-io:main' into main |
| e0ead0b | 2024 | - Add support for ConfigMap CA certificates (RHOAIENG-14601) |
| 588dd2a | 2024 | - Refactor validating webhook to check for unique registry names (RHOAIENG-13171) |
| 9ef6284 | 2024 | - Add Konflux 2.16 support |
| 2e4f859 | 2024 | - Add renovate.json config for dependency management |
| 8174667 | 2024 | - Review Dockerfile for building odh-model-registry-operator in Konflux |
| df261bc | 2024 | - Create Dockerfile.konflux for Konflux-based builds |
| a0afa2a | 2024 | - Add user instructions for installing Model Registry |
| 002ecbb | 2024 | - Fix govulncheck and protobuf dependency (RHOAIENG-13878) |
| 5fee736 | 2024 | - Remove static AUTH_PROVIDER in istio.env to allow operator to set it at runtime |
| b8f3211 | 2024 | - Replace rbac proxy container with controller metrics server authentication and authorization (RHOAIENG-13837) |
| a5e4b92 | 2024 | - Refactor defaulting and validating webhooks (RHOAIENG-13113) |
| 637ed69 | 2024 | - Cleanup optional properties (RHOAIENG-12838) |
| ab472e6 | 2024 | - Set authorino config properties in odh overlay from odh operator configmap auth-refs (RHOAIENG-5076) |
| 77cc222 | 2024 | - Switch from go build to make build in Dockerfile |
| 033afb2 | 2024 | - Add missing DB labels in DB secrets (RHOAIENG-12126) |
| e0b7589 | 2024 | - Add unexpected reconcile errors to false Available status in MR CR (RHOAIENG-10027) |
| c4f88ba | 2024 | - Add annotations for external service host and port in MR service (RHOAIENG-11092) |

## Configuration Options

### Environment Variables (Operator)

| Variable | Default | Purpose |
|----------|---------|---------|
| GRPC_IMAGE | quay.io/opendatahub/mlmd-grpc-server:latest | Default gRPC container image for ModelRegistry deployments |
| REST_IMAGE | quay.io/opendatahub/model-registry:latest | Default REST container image for ModelRegistry deployments |
| ENABLE_WEBHOOKS | false | Enable admission webhooks for validation/defaulting |
| CREATE_AUTH_RESOURCES | true | Create Authorino AuthConfig and Istio AuthorizationPolicy resources |
| DEFAULT_DOMAIN | "" | Default domain for Istio Gateway hosts (auto-detected from OpenShift cluster if empty) |
| DEFAULT_CERT | "" | Default TLS certificate secret name for Gateway endpoints |
| DEFAULT_AUTH_PROVIDER | "" | Default Authorino external authorization provider name (e.g., opendatahub-auth-provider) |
| DEFAULT_AUTH_CONFIG_LABELS | "" | Default labels for Authorino AuthConfig selector |

### ModelRegistry CR Spec Highlights

| Field | Type | Default | Purpose |
|-------|------|---------|---------|
| spec.rest.port | int32 | 8080 | REST API listen port |
| spec.grpc.port | int32 | 9090 | gRPC API listen port |
| spec.postgres | object | nil | PostgreSQL connection configuration (host, port, username, database, sslMode, etc.) |
| spec.mysql | object | nil | MySQL connection configuration (host, port, username, database, SSL settings, etc.) |
| spec.istio.authProvider | string | "" | Authorino provider name for authentication |
| spec.istio.tlsMode | string | ISTIO_MUTUAL | DestinationRule TLS mode (DISABLE, SIMPLE, MUTUAL, ISTIO_MUTUAL) |
| spec.istio.gateway | object | nil | Istio Gateway configuration (domain, istioIngress, REST/gRPC server settings, TLS credentials) |
| spec.rest.serviceRoute | string | disabled | Create OpenShift Route for REST service (enabled/disabled) |

## Notes

- **Database Requirement**: One of PostgreSQL or MySQL **must** be configured. The operator does not provision databases; they must be provided externally.
- **Istio Integration**: When `spec.istio` is configured, the operator enables Istio sidecar injection, creates service mesh policies, and optionally configures Istio Gateway for external access.
- **Authentication**: Without Istio, the Model Registry services are unauthenticated. With Istio + Authorino, Kubernetes bearer tokens are validated and users/service accounts must have GET permission on the service resource.
- **TLS Options**: Database connections support optional TLS (PostgreSQL sslmode, MySQL SSL). Istio Gateway supports SIMPLE (server-side TLS), MUTUAL (mTLS with client certs), and ISTIO_MUTUAL (automatic Istio-generated certs).
- **Multi-tenancy**: Each ModelRegistry CR creates an isolated namespace-scoped deployment with its own service account, RBAC role, and optional OpenShift user group.
- **Webhooks**: Validating webhooks enforce unique registry names within a namespace and validate configuration. Defaulting webhooks set default values for optional fields.
- **OpenShift Routes**: The operator can automatically create OpenShift Routes for both direct service access (spec.rest.serviceRoute) and Istio Gateway endpoints (in istio-system namespace).
