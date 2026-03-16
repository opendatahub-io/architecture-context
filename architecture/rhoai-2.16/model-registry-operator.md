# Component: Model Registry Operator

## Metadata
- **Repository**: https://github.com/red-hat-data-services/model-registry-operator.git
- **Version**: v-2160-131-gc6013df
- **Branch**: rhoai-2.16
- **Distribution**: RHOAI
- **Languages**: Go
- **Deployment Type**: Kubernetes Operator

## Purpose
**Short**: Kubernetes operator that deploys and manages Model Registry service instances for ML model metadata tracking and versioning.

**Detailed**: The Model Registry Operator is a Kubernetes controller that automates the deployment and lifecycle management of Model Registry services in OpenShift AI (RHOAI) clusters. It reconciles `ModelRegistry` custom resources to create fully configured model registry deployments that provide both REST and gRPC APIs for managing ML model metadata. The operator supports multiple deployment modes including plain Kubernetes services, Istio service mesh integration with mTLS security, and Authorino-based authentication/authorization. It can work with PostgreSQL or MySQL backends and automatically configures necessary networking, RBAC, and security resources. The operator is designed to integrate seamlessly with the OpenShift AI platform, supporting OpenShift Routes, Istio Gateways, and external authentication providers.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| Controller Manager | Operator Pod | Reconciles ModelRegistry CRs and manages lifecycle of registry deployments |
| Model Registry REST API | Deployed Service | HTTP/HTTPS REST API for model metadata operations (port 8080) |
| Model Registry gRPC API | Deployed Service | gRPC API for model metadata operations (port 9090) |
| Webhook Server | Operator Component | Validates and mutates ModelRegistry CRs on CREATE/UPDATE |
| Metrics Service | Operator Component | Prometheus metrics endpoint for operator monitoring (port 8443) |
| Health Endpoints | Operator Component | Liveness and readiness probes (port 8081) |

## APIs Exposed

### Custom Resource Definitions (CRDs)

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| modelregistry.opendatahub.io | v1alpha1 | ModelRegistry | Namespaced | Defines a model registry instance with database config, service ports, and optional Istio/gateway settings |

### HTTP Endpoints

#### Operator Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /metrics | GET | 8443/TCP | HTTPS | TLS 1.2+ | Bearer Token | Prometheus metrics for operator monitoring |
| /healthz | GET | 8081/TCP | HTTP | None | None | Liveness probe for operator pod |
| /readyz | GET | 8081/TCP | HTTP | None | None | Readiness probe for operator pod |
| /mutate-modelregistry-opendatahub-io-v1alpha1-modelregistry | POST | 9443/TCP | HTTPS | TLS 1.2+ | K8s API Server | Mutating webhook for ModelRegistry CR validation |
| /validate-modelregistry-opendatahub-io-v1alpha1-modelregistry | POST | 9443/TCP | HTTPS | TLS 1.2+ | K8s API Server | Validating webhook for ModelRegistry CR validation |

#### Model Registry Service Endpoints (Deployed by Operator)

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /api/model_registry/v1alpha3/registered_models | GET, POST | 8080/TCP | HTTP | None (non-Istio) | None (non-Istio) | REST API for model metadata operations |
| /api/model_registry/v1alpha3/* | ALL | 8080/TCP | HTTP/HTTPS | TLS 1.3 (Istio) | Bearer Token (Istio) | Full REST API for model registry |

### gRPC Services

| Service | Port | Protocol | Encryption | Auth | Purpose |
|---------|------|----------|------------|------|---------|
| ML Metadata gRPC | 9090/TCP | gRPC | mTLS (Istio mode) | mTLS client certs (Istio) | gRPC API for ML metadata service backend |

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| PostgreSQL | 9.6+ | Yes (or MySQL) | Backend database for ML metadata storage |
| MySQL | 5.7+ | Yes (or PostgreSQL) | Alternative backend database for ML metadata storage |
| Istio Service Mesh | 1.20+ | No | Optional service mesh for mTLS, traffic management, and gateway exposure |
| Authorino | 0.17+ | No | Optional authorization service for Istio-based deployments |
| cert-manager | Any | No | Optional certificate management for TLS in production |

### Internal ODH Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| OpenShift Service Mesh | Istio Resources | Uses service mesh control plane for mTLS and gateway routing |
| ODH Dashboard | Potential UI Integration | May integrate with dashboard for model registry management |
| Model Registry Images | Container Images | Deploys quay.io/opendatahub/model-registry:latest (REST) and quay.io/opendatahub/mlmd-grpc-server:latest (gRPC) |

## Network Architecture

### Services

#### Operator Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| controller-manager-metrics-service | ClusterIP | 8443/TCP | https | HTTPS | TLS 1.2+ | Bearer Token | Internal |
| webhook-service | ClusterIP | 443/TCP | 9443 | HTTPS | TLS 1.2+ | K8s API Server | Internal |

#### Model Registry Services (Created by Operator)

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| <registry-name> | ClusterIP | 8080/TCP | 8080 | HTTP/HTTPS | TLS 1.3 (Istio mTLS) | Bearer Token (Istio) | Internal/External via Route/Gateway |
| <registry-name>-grpc | ClusterIP | 9090/TCP | 9090 | gRPC | mTLS (Istio mode) | mTLS certs (Istio) | Internal/External via Gateway |

### Ingress

#### OpenShift Routes (Non-Istio Mode)

| Name | Type | Hosts | Port | Protocol | Encryption | TLS Mode | Exposure |
|------|------|-------|------|----------|------------|----------|----------|
| <registry-name>-http | Route | Auto-generated | 8080/TCP | HTTP/HTTPS | Edge TLS | SIMPLE | External |

#### Istio Gateway Routes (Istio Mode with Gateway)

| Name | Type | Hosts | Port | Protocol | Encryption | TLS Mode | Exposure |
|------|------|-------|------|----------|------------|----------|----------|
| <namespace>-<registry-name>-rest | Route | <registry-name>-rest.<domain> | 443/TCP | HTTPS | TLS 1.3 | SIMPLE/MUTUAL | External |
| <namespace>-<registry-name>-grpc | Route | <registry-name>-grpc.<domain> | 443/TCP | HTTPS | TLS 1.3 | SIMPLE/MUTUAL | External |

#### Istio Gateway Configuration

| Gateway Name | Hosts | Port | Protocol | TLS Mode | Purpose |
|--------------|-------|------|----------|----------|---------|
| <registry-name> | <registry-name>-rest.<domain> | 443/TCP | HTTPS | SIMPLE/MUTUAL/ISTIO_MUTUAL | Exposes REST API externally |
| <registry-name> | <registry-name>-grpc.<domain> | 443/TCP | HTTP2 (gRPC) | SIMPLE/MUTUAL/ISTIO_MUTUAL | Exposes gRPC API externally |

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| PostgreSQL Database | 5432/TCP | PostgreSQL | TLS 1.2+ (optional) | Password/Client Cert | Model metadata persistence |
| MySQL Database | 3306/TCP | MySQL | TLS 1.2+ (optional) | Password/Client Cert | Alternative model metadata persistence |
| Istio Control Plane | 15012/TCP | gRPC | mTLS | Service Account Token | Service mesh configuration and cert distribution |
| Authorino | 50051/TCP | gRPC | mTLS | Service Account Token | External authorization decisions |

## Security

### RBAC - Cluster Roles

#### Operator ClusterRole

| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|
| manager-role | modelregistry.opendatahub.io | modelregistries, modelregistries/status, modelregistries/finalizers | get, list, watch, create, update, patch, delete |
| manager-role | "" | services, serviceaccounts, events, endpoints, pods, pods/log | get, list, watch, create, update, patch, delete |
| manager-role | apps | deployments | get, list, watch, create, update, patch, delete |
| manager-role | rbac.authorization.k8s.io | roles, rolebindings | get, list, watch, create, update, patch, delete |
| manager-role | route.openshift.io | routes, routes/custom-host | get, list, watch, create, update, patch, delete |
| manager-role | user.openshift.io | groups | get, list, watch, create, update, patch, delete |
| manager-role | networking.istio.io | gateways, virtualservices, destinationrules | get, list, watch, create, update, patch, delete |
| manager-role | security.istio.io | authorizationpolicies | get, list, watch, create, update, patch, delete |
| manager-role | authorino.kuadrant.io | authconfigs | get, list, watch, create, update, patch, delete |
| manager-role | config.openshift.io | ingresses | get, list, watch |

#### Model Registry User Roles (Created per Registry)

| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|
| registry-user-<registry-name> | "" | services/<registry-name> | get | Purpose: Authorizes users to access model registry service when using Istio auth |

### RBAC - Role Bindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| manager-role | opendatahub | manager-role | controller-manager |
| leader-election-rolebinding | opendatahub | leader-election-role | controller-manager |
| auth-proxy-role-binding | opendatahub | auth-proxy-role | controller-manager |

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| <db-secret> | Opaque | Database password for model registry connection | User/Admin | No |
| <registry-name>-rest-credential | kubernetes.io/tls | TLS certificate for REST gateway endpoint | cert-manager/Admin | Yes (cert-manager) |
| <registry-name>-grpc-credential | kubernetes.io/tls | TLS certificate for gRPC gateway endpoint | cert-manager/Admin | Yes (cert-manager) |
| model-registry-db-credential | Opaque | Database CA certificate for SSL/TLS connection | Admin | No |
| webhook-server-cert | kubernetes.io/tls | TLS certificate for webhook server | cert-manager/service.beta.openshift.io | Yes |
| controller-manager-metrics-cert | kubernetes.io/tls | TLS certificate for metrics endpoint | service.beta.openshift.io | Yes |

### Authentication & Authorization

#### Operator Authentication

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| /metrics | GET | Bearer Token (ServiceAccount) | kube-rbac-proxy | Requires auth-proxy-client ClusterRole |
| /mutate-*, /validate-* | POST | K8s API Server mTLS | API Server | API server validates webhook cert |

#### Model Registry Service Authentication (Istio Mode)

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| /api/model_registry/v1alpha3/* | ALL | Bearer Token (JWT) | Authorino via Istio EnvoyFilter | Validates K8s/OIDC token, checks RBAC via K8s SubjectAccessReview |
| gRPC endpoints | ALL | Bearer Token (JWT) | Authorino via Istio EnvoyFilter | Same as REST API |
| Service-to-Service | ALL | mTLS (Istio) | Istio sidecar | ISTIO_MUTUAL mode validates service identity |

#### Authorization Policies (Istio Mode)

| Policy Name | Target | Action | Rules |
|-------------|--------|--------|-------|
| <registry-name>-authorino | Model Registry Service | CUSTOM | Delegates auth to Authorino external provider |

## Data Flows

### Flow 1: User Creates Model Registry CR

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User/Client | K8s API Server | 6443/TCP | HTTPS | TLS 1.3 | Bearer Token/Client Cert |
| 2 | K8s API Server | Webhook Service | 9443/TCP | HTTPS | TLS 1.2+ | K8s API Server mTLS |
| 3 | Webhook Service | K8s API Server | Response | HTTPS | TLS 1.2+ | K8s API Server mTLS |
| 4 | K8s API Server | Controller Manager | Watch | HTTPS | TLS 1.3 | ServiceAccount Token |
| 5 | Controller Manager | K8s API Server | 6443/TCP | HTTPS | TLS 1.3 | ServiceAccount Token |

### Flow 2: Controller Deploys Model Registry (Non-Istio)

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Controller Manager | K8s API Server | 6443/TCP | HTTPS | TLS 1.3 | ServiceAccount Token |
| 2 | K8s API Server | Kubelet | 10250/TCP | HTTPS | TLS 1.2+ | Client Cert |
| 3 | Model Registry Pod | PostgreSQL/MySQL | 5432/3306 TCP | PostgreSQL/MySQL | TLS 1.2+ (optional) | Password/Client Cert |

### Flow 3: User Accesses Model Registry (Istio + Gateway Mode)

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | External Client | OpenShift Route | 443/TCP | HTTPS | TLS 1.3 | None (TLS termination) |
| 2 | Route | Istio Ingress Gateway | 443/TCP | HTTPS | TLS 1.3 | TLS client cert (MUTUAL) or server cert (SIMPLE) |
| 3 | Istio Gateway | Envoy Sidecar (Registry Pod) | 8080/TCP | HTTP | mTLS | Istio workload identity |
| 4 | Envoy Sidecar | Authorino | 50051/TCP | gRPC | mTLS | Service mesh identity |
| 5 | Authorino | K8s API Server | 6443/TCP | HTTPS | TLS 1.3 | ServiceAccount Token (SubjectAccessReview) |
| 6 | Envoy Sidecar | Model Registry Container | 8080/TCP | HTTP | plaintext (localhost) | None (auth already validated) |
| 7 | Model Registry Container | PostgreSQL/MySQL | 5432/3306 TCP | PostgreSQL/MySQL | TLS 1.2+ (optional) | Password/Client Cert |

### Flow 4: Operator Metrics Collection

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Prometheus | kube-rbac-proxy | 8443/TCP | HTTPS | TLS 1.2+ (OpenShift serving cert) | Bearer Token |
| 2 | kube-rbac-proxy | Controller Manager | 8080/TCP | HTTP | plaintext (localhost) | None (proxied) |

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| PostgreSQL/MySQL | Database Connection | 5432/3306 TCP | PostgreSQL/MySQL | TLS 1.2+ (optional) | Persistent storage for model metadata |
| Istio Control Plane | Service Mesh | 15012/TCP | gRPC | mTLS | Certificate distribution, mesh config, telemetry |
| Authorino | External Auth | 50051/TCP | gRPC | mTLS | JWT validation and K8s RBAC authorization |
| Kubernetes API Server | Controller Reconciliation | 6443/TCP | HTTPS | TLS 1.3 | Watch/manage ModelRegistry CRs and child resources |
| Prometheus | Metrics Scraping | 8443/TCP | HTTPS | TLS 1.2+ | Operator health and performance monitoring |
| OpenShift Ingress | External Access | 443/TCP | HTTPS | Edge TLS | External route for model registry services |

## Deployment Manifests

### Kustomize Structure

The operator uses Kustomize for deployment configuration with the following structure:

- **Base**: `config/default/` - Standard operator deployment with RBAC, webhooks, manager
- **ODH Overlay**: `config/overlays/odh/` - OpenShift AI specific configuration
  - Namespace: `opendatahub`
  - Webhooks enabled with cert injection
  - OpenShift serving certs for metrics and webhooks
  - Component labels for ODH integration

### Container Images

| Image | Purpose | Build |
|-------|---------|-------|
| odh-model-registry-operator | Operator controller manager | Built via Dockerfile.konflux with Go 1.25, UBI8 base |
| quay.io/opendatahub/model-registry:latest | Model Registry REST API | Deployed by operator (configurable) |
| quay.io/opendatahub/mlmd-grpc-server:latest | ML Metadata gRPC server | Deployed by operator (configurable) |

## Recent Changes

| Commit | Date | Changes |
|--------|------|---------|
| c6013df | 2026-03 | chore(deps): update registry.access.redhat.com/ubi8/go-toolset:1.25 docker digest |
| 4e104bd | 2026-03 | chore(deps): update registry.access.redhat.com/ubi8/go-toolset:1.25 docker digest |
| 64e2783 | 2026-03 | chore(deps): update registry.access.redhat.com/ubi8/ubi-minimal docker digest |
| 1e38d40 | 2026-02 | chore(deps): update registry.access.redhat.com/ubi8/go-toolset:1.25 docker digest |
| 232e464 | 2026-02 | chore(deps): update registry.access.redhat.com/ubi8/go-toolset:1.25 docker digest |
| a772f18 | 2026-02 | chore(deps): update registry.access.redhat.com/ubi8/ubi-minimal docker digest |
| 13ca4a2 | 2026-01 | sync pipelineruns with konflux-central |
| cd2735f | 2026-01 | Add PipelineRun configuration for Model Registry Operator pull requests |
| 6b4833c | 2025-12 | bump go-toolset to 1.25.5 |

## Configuration Options

### ModelRegistry CR Specification

Key configuration fields in the ModelRegistry CR:

- **rest.port**: REST API port (default: 8080)
- **rest.serviceRoute**: Enable/disable OpenShift Route (enabled/disabled)
- **rest.image**: Override REST API image
- **grpc.port**: gRPC API port (default: 9090)
- **grpc.image**: Override gRPC API image
- **postgres**: PostgreSQL connection settings (host, port, database, username, passwordSecret, sslMode, SSL certificates)
- **mysql**: MySQL connection settings (host, port, database, username, passwordSecret, SSL certificates)
- **istio.authProvider**: Authorino provider name for external auth
- **istio.authConfigLabels**: Labels for Authorino AuthConfig resources
- **istio.tlsMode**: DestinationRule TLS mode (DISABLE/SIMPLE/MUTUAL/ISTIO_MUTUAL)
- **istio.gateway.domain**: Domain for gateway endpoints
- **istio.gateway.rest.tls.mode**: REST gateway TLS mode (SIMPLE/MUTUAL/ISTIO_MUTUAL)
- **istio.gateway.grpc.tls.mode**: gRPC gateway TLS mode (SIMPLE/MUTUAL/ISTIO_MUTUAL)
- **istio.gateway.rest.gatewayRoute**: Enable/disable OpenShift Route for REST gateway
- **istio.gateway.grpc.gatewayRoute**: Enable/disable OpenShift Route for gRPC gateway

### Operator Environment Variables

| Variable | Default | Purpose |
|----------|---------|---------|
| GRPC_IMAGE | quay.io/opendatahub/mlmd-grpc-server:latest | Default gRPC server image |
| REST_IMAGE | quay.io/opendatahub/model-registry:latest | Default REST API image |
| ENABLE_WEBHOOKS | false | Enable/disable admission webhooks |
| CREATE_AUTH_RESOURCES | true | Create Authorino and AuthorizationPolicy resources |
| DEFAULT_DOMAIN | "" | Default domain for gateway endpoints (auto-detected in OpenShift) |
| DEFAULT_CERT | "" | Default TLS certificate for gateways |
| DEFAULT_AUTH_PROVIDER | "" | Default Authorino provider name |
| DEFAULT_AUTH_CONFIG_LABELS | "" | Default labels for AuthConfig resources |

## Observability

### Metrics

The operator exposes Prometheus metrics on port 8443:
- Controller runtime metrics (reconciliation latency, queue depth, etc.)
- Custom resource status metrics
- Go runtime metrics (memory, goroutines, etc.)

### Health Checks

- **Liveness**: `http://localhost:8081/healthz`
- **Readiness**: `http://localhost:8081/readyz`

### Logging

The operator uses structured logging (logr) for:
- Reconciliation events
- Resource creation/updates
- Error conditions
- Status updates

## Known Limitations

1. **Database Migration**: Database schema upgrades require manual configuration via `enable_database_upgrade` flag
2. **Multi-Tenancy**: Each ModelRegistry CR creates a separate deployment; no built-in multi-tenancy within a single registry
3. **HA Mode**: No built-in high availability; relies on single replica deployment with persistent database
4. **Database Backends**: Only PostgreSQL and MySQL supported; no support for other databases
5. **Istio Dependency**: Gateway and external auth features require Istio/Service Mesh pre-installed
6. **Certificate Management**: TLS certificates for gateways must be manually provisioned or managed by external cert-manager

## Production Considerations

1. **Database**: Use external managed database (PostgreSQL/MySQL) with backups and HA
2. **TLS Certificates**: Integrate with cert-manager for automatic certificate rotation
3. **Resource Limits**: Configure appropriate CPU/memory limits for model registry pods based on workload
4. **Monitoring**: Enable ServiceMonitor and configure alerts for model registry availability
5. **Access Control**: Use Istio + Authorino for production authentication/authorization
6. **Network Policies**: Apply network policies to restrict database and service mesh traffic
7. **Backup/DR**: Implement database backup strategy and disaster recovery procedures
