# Component: ODH Dashboard

## Metadata
- **Repository**: https://github.com/red-hat-data-services/odh-dashboard.git
- **Version**: v-2160-125-g7d5dd8425
- **Branch**: rhoai-2.16
- **Distribution**: RHOAI
- **Languages**: TypeScript, JavaScript, Node.js
- **Deployment Type**: Web Application (Frontend + Backend)

## Purpose
**Short**: Web-based user interface for managing and interacting with Red Hat OpenShift AI platform components including data science projects, notebooks, model serving, and pipelines.

**Detailed**: The ODH Dashboard is the primary web interface for Red Hat OpenShift AI (RHOAI) and Open Data Hub (ODH) platforms. It provides a unified user experience for data scientists and administrators to manage data science workloads. The dashboard enables users to create and manage data science projects, launch Jupyter notebooks, deploy machine learning models, configure model serving runtimes, manage accelerator profiles, access documentation and quick-start guides, and configure platform-wide settings. It integrates with multiple ODH/RHOAI components including KServe, ModelMesh, Kubeflow Notebooks, and Data Science Pipelines, providing a centralized control plane for the entire platform. The dashboard is built as a full-stack application with a React frontend and Node.js/Fastify backend, deployed with an OAuth proxy for OpenShift authentication.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| Frontend | React/TypeScript SPA | User interface for dashboard features |
| Backend | Fastify (Node.js) REST API | API server handling K8s operations and business logic |
| OAuth Proxy | Sidecar container | OpenShift OAuth authentication and authorization |

## APIs Exposed

### Custom Resource Definitions (CRDs)

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| opendatahub.io | v1alpha | OdhDashboardConfig | Namespaced | Dashboard configuration including feature flags, UI settings, notebook/model server sizes, and admin groups |
| dashboard.opendatahub.io | v1 | OdhApplication | Namespaced | Application catalog entries for ODH components displayed in dashboard |
| dashboard.opendatahub.io | v1 | OdhDocument | Namespaced | Documentation links and resources displayed in dashboard |
| dashboard.opendatahub.io | v1 | AcceleratorProfile | Namespaced | GPU/accelerator profiles defining resource identifiers and tolerations for workloads |
| console.openshift.io | v1 | OdhQuickStart | Namespaced | Interactive quick-start tutorials guiding users through workflows |

### HTTP Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /api/health | GET | 8080/TCP | HTTP | None | None | Backend health check endpoint |
| /api/* | GET, POST, PUT, PATCH, DELETE | 8080/TCP | HTTP | None | Internal | Backend REST API (not directly exposed) |
| / | GET | 8443/TCP | HTTPS | TLS 1.2+ | OAuth Bearer Token | Frontend application served via OAuth proxy |
| /api/* | GET, POST, PUT, PATCH, DELETE | 8443/TCP | HTTPS | TLS 1.2+ | OAuth Bearer Token | Backend API proxied through OAuth proxy |
| /oauth/healthz | GET | 8443/TCP | HTTPS | TLS 1.2+ | None | OAuth proxy health check |
| /metrics | GET | 8443/TCP | HTTPS | TLS 1.2+ | None | Prometheus metrics (auth bypassed) |

### gRPC Services

| Service | Port | Protocol | Encryption | Auth | Purpose |
|---------|------|----------|------------|------|---------|
| N/A | N/A | N/A | N/A | N/A | No gRPC services exposed |

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| Node.js | >=20.0.0 | Yes | Runtime for frontend and backend |
| OpenShift OAuth Server | cluster | Yes | User authentication and authorization |
| OpenShift Certificate Service | cluster | Yes | TLS certificate generation for service |
| Prometheus/Thanos | cluster | No | Metrics collection and storage |

### Internal ODH Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| Kubeflow Notebooks | CRD (kubeflow.org/notebooks) | Manage Jupyter notebook workspaces |
| KServe | CRD (serving.kserve.io/inferenceservices, servingruntimes) | Model serving management |
| ModelMesh | CRD (serving.kserve.io) | Alternative model serving backend |
| Data Science Pipelines | CRD | Pipeline management and execution |
| Model Registry | CRD (modelregistry.opendatahub.io/modelregistries) | Model versioning and registry |
| ODH Operator | CRD (datasciencecluster.opendatahub.io, dscinitialization.opendatahub.io) | Platform configuration and status |
| Distributed Workloads | CRD | Distributed training workload management |
| NIM Serving | CRD (nim.opendatahub.io/accounts) | NVIDIA NIM model serving |

## Network Architecture

### Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| odh-dashboard | ClusterIP | 8443/TCP | 8443 | HTTPS | TLS | OAuth Bearer Token | Internal |

### Ingress

| Name | Type | Hosts | Port | Protocol | Encryption | TLS Mode | Exposure |
|------|------|-------|------|----------|------------|----------|----------|
| odh-dashboard | OpenShift Route | [cluster-specific] | 443/TCP | HTTPS | TLS 1.2+ | reencrypt | External |

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token | CRD and resource management |
| Thanos Querier (openshift-monitoring) | 9092/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token | Query metrics for model serving and notebooks |
| ImageStream Layers API | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token | Access notebook and runtime image metadata |

## Security

### RBAC - Cluster Roles

| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|
| odh-dashboard | storage.k8s.io | storageclasses | update, patch |
| odh-dashboard | "" | nodes | get, list |
| odh-dashboard | machine.openshift.io, autoscaling.openshift.io | machineautoscalers, machinesets | get, list |
| odh-dashboard | "", config.openshift.io | clusterversions | get, watch, list |
| odh-dashboard | operators.coreos.com | clusterserviceversions, subscriptions | get, list, watch |
| odh-dashboard | "", image.openshift.io | imagestreams/layers | get |
| odh-dashboard | "" | configmaps, persistentvolumeclaims, secrets | create, delete, get, list, patch, update, watch |
| odh-dashboard | route.openshift.io | routes | get, list, watch |
| odh-dashboard | console.openshift.io | consolelinks | get, list, watch |
| odh-dashboard | operator.openshift.io | consoles | get, list, watch |
| odh-dashboard | "", integreatly.org | rhmis | get, watch, list |
| odh-dashboard | user.openshift.io | groups, users | get, list, watch |
| odh-dashboard | "" | pods, serviceaccounts, services | get, list, watch |
| odh-dashboard | "" | namespaces | get, list, watch, create, update, patch, delete |
| odh-dashboard | rbac.authorization.k8s.io | rolebindings, clusterrolebindings, roles | get, list, watch, create, update, patch, delete |
| odh-dashboard | "", events.k8s.io | events | get, list, watch |
| odh-dashboard | kubeflow.org | notebooks | get, list, watch, create, update, patch, delete |
| odh-dashboard | datasciencecluster.opendatahub.io | datascienceclusters | list, watch, get |
| odh-dashboard | dscinitialization.opendatahub.io | dscinitializations | list, watch, get |
| odh-dashboard | serving.kserve.io | inferenceservices | get, list, watch |
| odh-dashboard | modelregistry.opendatahub.io | modelregistries | get, list, watch, create, update, patch, delete |
| odh-dashboard | nim.opendatahub.io | accounts | get, list, watch, create, update, patch, delete |

### RBAC - Namespaced Roles

| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|
| odh-dashboard | dashboard.opendatahub.io | acceleratorprofiles | create, get, list, update, patch, delete |
| odh-dashboard | route.openshift.io | routes | get, list, watch |
| odh-dashboard | kfdef.apps.kubeflow.org | kfdefs | get, list, watch |
| odh-dashboard | batch | cronjobs, jobs, jobs/status | create, delete, get, list, patch, update, watch |
| odh-dashboard | image.openshift.io | imagestreams | create, get, list, update, patch, delete |
| odh-dashboard | build.openshift.io | builds, buildconfigs, buildconfigs/instantiate | get, list, watch, create, patch, delete |
| odh-dashboard | apps | deployments | patch, update |
| odh-dashboard | apps.openshift.io | deploymentconfigs, deploymentconfigs/instantiate | get, list, watch, create, update, patch, delete |
| odh-dashboard | opendatahub.io | odhdashboardconfigs | get, list, watch, create, update, patch, delete |
| odh-dashboard | kubeflow.org | notebooks | get, list, watch, create, update, patch, delete |
| odh-dashboard | dashboard.opendatahub.io | odhapplications, odhdocuments | get, list |
| odh-dashboard | console.openshift.io | odhquickstarts | get, list |
| odh-dashboard | template.openshift.io | templates | * |
| odh-dashboard | serving.kserve.io | servingruntimes | * |

### RBAC - Role Bindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| odh-dashboard | [dashboard-namespace] | odh-dashboard (ClusterRole) | odh-dashboard |
| odh-dashboard | [dashboard-namespace] | odh-dashboard (Role) | odh-dashboard |

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| dashboard-proxy-tls | kubernetes.io/tls | TLS certificate for OAuth proxy HTTPS endpoint | service.alpha.openshift.io/serving-cert-secret-name annotation | Yes |
| dashboard-oauth-config-generated | Opaque | OAuth proxy cookie secret configuration | Manual/Operator | No |
| dashboard-oauth-client-generated | Opaque | OAuth client credentials for OpenShift authentication | Manual/Operator | No |

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| / (all except /metrics) | GET, POST, PUT, PATCH, DELETE | OAuth Bearer Token (JWT) | OAuth Proxy | OpenShift RBAC: projects:list verb required |
| /metrics | GET | None | OAuth Proxy | Skip auth regex bypass |
| Kubernetes API | GET, LIST, WATCH, CREATE, UPDATE, PATCH, DELETE | ServiceAccount Token | Kubernetes API Server | ClusterRole/Role permissions |

## Data Flows

### Flow 1: User Authentication and Dashboard Access

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User Browser | OpenShift Route (odh-dashboard) | 443/TCP | HTTPS | TLS 1.2+ | None (redirect to OAuth) |
| 2 | OpenShift Route | OAuth Proxy Container | 8443/TCP | HTTPS | TLS (service cert) | None |
| 3 | OAuth Proxy | OpenShift OAuth Server | 443/TCP | HTTPS | TLS 1.2+ | OAuth client credentials |
| 4 | OAuth Proxy | Backend Container | 8080/TCP | HTTP | None (localhost) | Bearer Token (forwarded) |

### Flow 2: Kubernetes API Interaction

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Backend Container | Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 2 | Kubernetes API Server | Etcd | 2379/TCP | HTTPS | mTLS | Client Cert |

### Flow 3: Metrics Query

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Backend Container | Thanos Querier (openshift-monitoring) | 9092/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |

### Flow 4: Notebook Creation

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User Browser | OAuth Proxy (via Route) | 443/TCP | HTTPS | TLS 1.2+ | OAuth Bearer Token |
| 2 | Backend Container | Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 3 | Backend Container | ImageStream API (OpenShift) | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| Kubernetes API Server | REST API | 6443/TCP | HTTPS | TLS 1.2+ | Manage CRDs, namespaces, notebooks, model serving resources |
| OpenShift OAuth Server | OAuth 2.0 | 443/TCP | HTTPS | TLS 1.2+ | User authentication and token generation |
| Thanos Querier | REST API | 9092/TCP | HTTPS | TLS 1.2+ | Query metrics for model serving and notebook performance |
| OpenShift Image API | REST API | 6443/TCP | HTTPS | TLS 1.2+ | Retrieve notebook image metadata and layers |
| OpenShift Build API | REST API | 6443/TCP | HTTPS | TLS 1.2+ | Manage custom notebook image builds |
| Prometheus | REST API (via Thanos) | 9092/TCP | HTTPS | TLS 1.2+ | Expose dashboard and component metrics |

## Recent Changes

| Version | Date | Changes |
|---------|------|---------|
| v-2160-125 | 2026-03 | - Update UBI8 Node.js 20 base image digest<br>- Sync Konflux pipeline runs<br>- Dependency updates for tar, qs, lodash, node-forge security fixes<br>- Upgrade to Node.js 20 runtime |
| v-2160-100 | 2025-12 | - RHOAI 2.16 feature development<br>- Connection types support<br>- Storage classes management features<br>- NIM model serving integration |
| v2.29.0 | 2025-11 | - Bug fixes and stability improvements<br>- Enhanced Dockerfile for Konflux builds<br>- Security dependency updates |

## Deployment Architecture

### Container Images

| Image | Base | Build System | Purpose |
|-------|------|--------------|---------|
| odh-dashboard | registry.access.redhat.com/ubi8/nodejs-20 | Konflux | Combined frontend and backend container |

### Pod Configuration

| Pod | Replicas | Anti-Affinity | Resource Requests | Resource Limits |
|-----|----------|---------------|-------------------|-----------------|
| odh-dashboard | 2 | Preferred (zone-level) | 1 CPU (total), 2Gi RAM (total) | 2 CPU (total), 4Gi RAM (total) |

### Container Resource Allocation

| Container | CPU Request | CPU Limit | Memory Request | Memory Limit |
|-----------|-------------|-----------|----------------|--------------|
| odh-dashboard | 500m | 1000m | 1Gi | 2Gi |
| oauth-proxy | 500m | 1000m | 1Gi | 2Gi |

### Volume Mounts

| Volume | Source | Mount Path | Purpose |
|--------|--------|------------|---------|
| proxy-tls | Secret (dashboard-proxy-tls) | /etc/tls/private | OAuth proxy TLS certificate |
| oauth-config | Secret (dashboard-oauth-config-generated) | /etc/oauth/config | OAuth proxy cookie secret |
| oauth-client | Secret (dashboard-oauth-client-generated) | /etc/oauth/client | OAuth client credentials |
| odh-trusted-ca-cert | ConfigMap (odh-trusted-ca-bundle) | /etc/pki/tls/certs/, /etc/ssl/certs/ | Trusted CA bundle for ODH services |
| odh-ca-cert | ConfigMap (odh-trusted-ca-bundle) | /etc/pki/tls/certs/, /etc/ssl/certs/ | ODH platform CA bundle |

## API Routes Summary

The backend exposes RESTful APIs for managing ODH/RHOAI resources:

| Route Group | Purpose | Authentication |
|-------------|---------|----------------|
| /api/accelerator-profiles | Manage GPU/accelerator profiles | OAuth Bearer Token |
| /api/accelerators | Query available accelerators | OAuth Bearer Token |
| /api/builds | Manage custom notebook image builds | OAuth Bearer Token |
| /api/cluster-settings | Retrieve cluster configuration | OAuth Bearer Token |
| /api/components | List installed ODH components | OAuth Bearer Token |
| /api/config | Dashboard configuration management | OAuth Bearer Token |
| /api/connection-types | Manage data connection types | OAuth Bearer Token |
| /api/console-links | Manage OpenShift console links | OAuth Bearer Token |
| /api/dashboardConfig | CRUD operations on OdhDashboardConfig CRs | OAuth Bearer Token |
| /api/docs | Access documentation resources | OAuth Bearer Token |
| /api/dsc | Query DataScienceCluster status | OAuth Bearer Token |
| /api/dsci | Query DSCInitialization status | OAuth Bearer Token |
| /api/groups-config | Manage admin and user groups | OAuth Bearer Token |
| /api/health | Health check endpoint | None |
| /api/images | List notebook images | OAuth Bearer Token |
| /api/k8s | Generic Kubernetes resource proxy | OAuth Bearer Token |
| /api/modelRegistries | Manage model registry instances | OAuth Bearer Token |
| /api/modelRegistryRoleBindings | Manage model registry RBAC | OAuth Bearer Token |
| /api/namespaces | Manage data science projects (namespaces) | OAuth Bearer Token |
| /api/nb-events | Query notebook pod events | OAuth Bearer Token |
| /api/notebooks | Manage Jupyter notebooks | OAuth Bearer Token |
| /api/prometheus | Query metrics via Thanos | OAuth Bearer Token |
| /api/quickstarts | Access quick-start tutorials | OAuth Bearer Token |
| /api/rolebindings | Manage project role bindings | OAuth Bearer Token |
| /api/service | Query service endpoints | OAuth Bearer Token |
| /api/servingRuntimes | Manage KServe serving runtimes | OAuth Bearer Token |
| /api/status | Component status checks | OAuth Bearer Token |
| /api/storage-class | Manage storage classes | OAuth Bearer Token |
| /api/templates | Manage OpenShift templates | OAuth Bearer Token |
| /api/validate-isv | Validate ISV integrations | OAuth Bearer Token |
| /api/nim-serving | Manage NVIDIA NIM serving | OAuth Bearer Token |

## Key Features

1. **Project Management**: Create and manage data science projects (Kubernetes namespaces) with proper RBAC
2. **Notebook Launcher**: Launch and manage Jupyter notebooks with custom images, sizes, and accelerators
3. **Model Serving**: Deploy and manage ML models using KServe or ModelMesh serving runtimes
4. **Application Catalog**: Browse and enable ODH/RHOAI components from integrated catalog
5. **Accelerator Profiles**: Configure GPU and accelerator profiles for workloads
6. **Custom Image Builds**: Build custom notebook images using OpenShift Build API
7. **Model Registry**: Integrate with model registry for versioning and deployment
8. **Metrics Integration**: Display performance metrics via Prometheus/Thanos integration
9. **Quick Starts**: Interactive tutorials for platform features
10. **User Management**: Admin group configuration and user access control
11. **Connection Types**: Manage data connection templates (S3, URI, etc.)
12. **Distributed Workloads**: Support for distributed training jobs
13. **Storage Management**: Configure storage classes for notebooks and model storage

## Security Considerations

1. **Authentication**: All user requests authenticated via OpenShift OAuth
2. **Authorization**: Kubernetes RBAC enforced for all K8s API operations
3. **Network Security**: External access only via encrypted HTTPS route with TLS reencrypt
4. **Secret Management**: Sensitive data stored in Kubernetes Secrets
5. **Service Account**: Dedicated service account with least-privilege RBAC
6. **Token Forwarding**: User OAuth tokens forwarded to backend for user-scoped operations
7. **TLS Certificates**: Automatic certificate rotation via OpenShift service certificate service
8. **Content Security**: OAuth proxy prevents direct access to backend HTTP port
9. **Audit Logging**: Admin activity logged for compliance
10. **Namespace Isolation**: Multi-tenant support via namespace-scoped resources
