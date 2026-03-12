# Platform: Open Data Hub 3.3.0

## Metadata
- **Distribution**: ODH (Open Data Hub)
- **Version**: 3.3.0
- **Base Platform**: OpenShift Container Platform 4.19+ / Kubernetes 1.25+
- **Components Analyzed**: 5
- **Generated**: 2026-03-12

## Platform Overview

Open Data Hub 3.3.0 is an open-source machine learning platform built on Kubernetes/OpenShift that provides an integrated suite of tools for the complete ML lifecycle. The platform delivers capabilities for data science workspaces (Jupyter notebooks), experiment tracking and model versioning (MLflow), feature engineering and serving (Feast), model deployment and serving, and platform management through a unified web dashboard. All components are orchestrated by a central operator that manages deployment, configuration, and lifecycle of the integrated services.

The platform implements a multi-tenant architecture where users interact with components through OpenShift OAuth-authenticated interfaces, with workloads isolated by Kubernetes namespaces. Core services like the ODH Operator provision and manage component-specific operators and services, while the Dashboard provides a unified control plane for users to create workbenches, deploy models, and manage ML resources. Feature stores and experiment tracking systems integrate seamlessly with notebook environments to enable end-to-end ML workflows from feature engineering to model deployment.

## Component Inventory

| Component | Type | Version | Purpose |
|-----------|------|---------|---------|
| OpenDataHub Operator | Operator | 3.3.0 | Central control plane managing deployment and lifecycle of all platform components |
| ODH Dashboard | Web Application | v3.4.0EA1 | Unified web interface for managing workbenches, models, projects, and ML resources |
| Kubeflow Notebook Controllers | Operator | v1.7.0-15-519 | Manages lifecycle of Jupyter notebook instances with ODH/RHOAI-specific extensions |
| MLflow | Service | 3.10.1 | ML lifecycle platform for experiment tracking, model versioning, and LLM observability |
| Feast | Operator + Services | 0.61.0 | Feature store for consistent feature management across training and serving |

## Component Relationships

### Dependency Graph

```
OpenDataHub Operator (Central Control Plane)
├─→ ODH Dashboard (deploys manifests)
├─→ Kubeflow Notebook Controllers (deploys manifests)
├─→ MLflow Operator (deploys operator)
├─→ Feast Operator (deploys operator)
├─→ KServe (deploys operator - not analyzed in this set)
├─→ Data Science Pipelines (deploys operator - not analyzed in this set)
└─→ Platform Services (Auth, Gateway, Monitoring)

ODH Dashboard
├─→ Kubernetes API Server (REST API for CR management)
├─→ Kubeflow Notebook Controllers (creates/manages Notebook CRs)
├─→ OpenShift OAuth (user authentication)
├─→ Prometheus (metrics queries)
└─→ Model Registry Service (API proxy)

Kubeflow Notebook Controllers
├─→ Kubernetes API Server (CR reconciliation)
├─→ Data Science Pipelines API (injects pipeline config)
├─→ OpenShift OAuth (creates OAuth clients)
├─→ OpenShift Routes (external notebook access)
├─→ Feast (injects feature store config into notebooks)
└─→ Istio (optional VirtualService creation)

MLflow
├─→ PostgreSQL (metadata storage)
├─→ S3-compatible storage (artifact storage)
├─→ Kubernetes API (namespace watch, RBAC enforcement)
└─→ Istio Gateway (external HTTPS exposure)

Feast
├─→ PostgreSQL/Redis (online/offline stores)
├─→ S3/GCS/BigQuery (registry and offline storage)
├─→ Istio (optional mTLS and authorization)
├─→ OpenShift Route (external UI/API access)
└─→ Prometheus (metrics scraping)
```

### Central Components

**Core Platform Services:**
1. **OpenDataHub Operator** - Most critical component; manages all other components
2. **Kubernetes API Server** - All components depend on it for resource management
3. **ODH Dashboard** - Primary user interface; integrates with all user-facing components

**Integration Hubs:**
1. **Kubeflow Notebook Controllers** - Integrates with Pipelines, Feast, OAuth, and Routes
2. **MLflow** - Central tracking and registry for experiments and models
3. **Feast** - Feature serving integration point for training and inference

### Integration Patterns

**Common Patterns:**
1. **CRD-based Management**: All operators use Custom Resources for declarative configuration (Notebook, FeatureStore, DataScienceCluster, etc.)
2. **Kubernetes RBAC Integration**: MLflow, Dashboard, and Notebook Controllers enforce permissions via SubjectAccessReview
3. **OAuth Authentication**: Dashboard and Notebook Controllers integrate with OpenShift OAuth for user authentication
4. **Service Mesh Optional**: Feast and Notebooks support optional Istio integration for mTLS and advanced routing
5. **Operator Pattern**: Central ODH Operator deploys component-specific operators (Feast Operator, MLflow Operator) which manage component lifecycles
6. **ConfigMap/Secret Injection**: Notebook Controller injects Feast and Pipeline configurations into workbench environments

## Platform Network Architecture

### Namespaces

| Namespace | Purpose | Components |
|-----------|---------|------------|
| opendatahub-operator-system | Operator deployment | OpenDataHub Operator, Controller Manager, Webhooks |
| opendatahub | Platform services | ODH Dashboard, shared platform resources |
| redhat-ods-applications | Application services | Notebook Controller, component operators |
| feast-operator-system | Feast operator | Feast Operator controller |
| {user-namespaces} | User workspaces | User notebooks, feature stores, MLflow workspaces |

**Note**: Exact namespace topology depends on deployment configuration. Multi-tenant deployments create per-user or per-team namespaces.

### External Ingress Points

| Component | Ingress Type | Hosts | Port | Protocol | Encryption | Purpose |
|-----------|--------------|-------|------|----------|------------|---------|
| ODH Dashboard | OpenShift Route | (dynamic) | 443/TCP | HTTPS | TLS 1.2+ (reencrypt) | Platform management UI |
| ODH Dashboard | HTTPRoute (Gateway API) | (gateway-controlled) | 443/TCP | HTTPS | TLS 1.2+ | Platform management UI (alternative) |
| Kubeflow Notebooks | OpenShift Route | {notebook}-{namespace}.{domain} | 443/TCP | HTTPS | TLS 1.2+ (edge/reencrypt) | Jupyter notebook access |
| Kubeflow Notebooks | Gateway HTTPRoute | {notebook}.{domain} | 443/TCP | HTTPS | TLS 1.2+ | Jupyter notebook access (alternative) |
| Kubeflow Notebooks | Istio VirtualService | {istio-host} | 80/TCP | HTTP | None | Jupyter notebook access (via Istio Gateway) |
| MLflow | Istio Gateway | mlflow.apps.* | 443/TCP | HTTPS | TLS 1.2+ | Experiment tracking and model registry UI/API |
| Feast UI | OpenShift Route | {name}-feast-ui-route | 443/TCP | HTTPS | TLS 1.2+ (edge) | Feature store web interface |
| Feast Online API | Kubernetes Ingress | Configurable | 443/TCP | HTTPS | TLS 1.2+ | Online feature serving (optional external) |

### External Egress Dependencies

| Component | Destination | Port | Protocol | Encryption | Purpose |
|-----------|-------------|------|----------|------------|---------|
| MLflow | PostgreSQL database | 5432/TCP | PostgreSQL | TLS 1.2+ (optional) | Metadata storage |
| MLflow | S3 endpoint | 443/TCP | HTTPS | TLS 1.2+ | Artifact storage |
| Feast | PostgreSQL/Redis | 5432/6379/TCP | PostgreSQL/Redis | TLS 1.2+ / TLS (optional) | Online/offline store backend |
| Feast | AWS S3 | 443/TCP | HTTPS | TLS 1.2+ | Registry file backend |
| Feast | GCS | 443/TCP | HTTPS | TLS 1.2+ | Registry file backend |
| Feast | BigQuery | 443/TCP | HTTPS | TLS 1.2+ | Offline store backend |
| Feast | Snowflake | 443/TCP | HTTPS | TLS 1.2+ | Online/offline store backend |
| Notebook Pods | Container Registries | 443/TCP | HTTPS | TLS 1.2+ | Notebook image pulls |
| Notebook Pods | External HTTP(S) | 80/443/TCP | HTTP/HTTPS | TLS 1.2+ (HTTPS) | User-initiated external requests |
| All Operators | Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | Resource management and reconciliation |
| ODH Operator | Quay.io / Registry | 443/TCP | HTTPS | TLS 1.2+ | Component image pulls |

### Internal Service Mesh

| Setting | Value | Components Using |
|---------|-------|------------------|
| mTLS Mode | PERMISSIVE / STRICT (optional) | Feast, Kubeflow Notebooks (when Istio enabled) |
| Peer Authentication | Optional configuration | Feast services, Notebook services |
| AuthorizationPolicy | Optional per-component | Feast feature server, Notebook endpoints |

**Note**: Service mesh integration is optional. When enabled, Istio provides mTLS for service-to-service communication and advanced traffic management.

## Platform Security

### RBAC Summary

**Operator-Level Permissions:**

| Component | ClusterRole | API Groups | Resources | Verbs |
|-----------|-------------|------------|-----------|-------|
| OpenDataHub Operator | controller-manager | datasciencecluster.opendatahub.io | datascienceclusters | get, list, watch, create, update, patch, delete |
| OpenDataHub Operator | controller-manager | dscinitialization.opendatahub.io | dscinitializations | get, list, watch, create, update, patch, delete |
| OpenDataHub Operator | controller-manager | components.platform.opendatahub.io | * (all component CRDs) | get, list, watch, create, update, patch, delete |
| OpenDataHub Operator | controller-manager | "", apps, rbac | namespaces, deployments, roles, rolebindings, secrets, configmaps | get, list, watch, create, update, patch, delete |
| Kubeflow Notebooks | notebook-controller-role | kubeflow.org | notebooks, notebooks/finalizers, notebooks/status | * |
| Kubeflow Notebooks | odh-notebook-controller-manager-role | datasciencepipelinesapplications.opendatahub.io | datasciencepipelinesapplications | get, list, watch, create, delete, patch, update |
| Kubeflow Notebooks | odh-notebook-controller-manager-role | oauth.openshift.io | oauthclients | delete, get, list, patch, update, watch |
| Feast Operator | manager-role | feast.dev | featurestores, featurestores/status, featurestores/finalizers | get, list, watch, create, update, patch, delete |
| Feast Operator | manager-role | apps, batch | deployments, cronjobs | get, list, watch, create, update, delete |
| MLflow | mlflow-k8s-workspace-provider | "" (core) | namespaces | list, watch |
| MLflow | mlflow-k8s-workspace-provider | mlflow.kubeflow.org | mlflowconfigs | list, watch |
| MLflow | mlflow-k8s-workspace-provider | authorization.k8s.io | subjectaccessreviews | create |
| ODH Dashboard | odh-dashboard | kubeflow.org | notebooks | get, list, watch, create, update, patch, delete |
| ODH Dashboard | odh-dashboard | modelregistry.opendatahub.io | modelregistries | get, list, watch, create, update, patch, delete |
| ODH Dashboard | odh-dashboard | feast.dev | featurestores | get, list, watch |

**User-Level Permissions (MLflow custom API):**

MLflow enforces RBAC on virtual API resources in the `mlflow.kubeflow.org` group:

| Resource | Verbs | Purpose |
|----------|-------|---------|
| experiments | get, list, create, update, delete | Experiment management |
| datasets | get, list, create, update, delete | Evaluation dataset management |
| registeredmodels | get, list, create, update, delete | Model registry and prompt management |
| assistants | get, create, update | AI assistant operations |

### Secrets Inventory

| Component | Secret Name | Type | Purpose |
|-----------|-------------|------|---------|
| OpenDataHub Operator | opendatahub-operator-controller-webhook-cert | kubernetes.io/tls | Webhook server TLS certificate |
| ODH Dashboard | dashboard-proxy-tls | kubernetes.io/tls | kube-rbac-proxy TLS certificate |
| Kubeflow Notebooks | odh-notebook-controller-webhook-cert | kubernetes.io/tls | Admission webhook TLS certificate |
| Kubeflow Notebooks | {notebook-name}-oauth-config | Opaque | OAuth client secret for notebook auth |
| Kubeflow Notebooks | ds-pipeline-{dspa-name}-config | Opaque | Pipeline API credentials injected into notebooks |
| MLflow | mlflow-artifact-connection | Opaque | S3 credentials (per-namespace override) |
| MLflow | mlflow-db-credentials | Opaque | PostgreSQL connection credentials |
| MLflow | mlflow-flask-secret-key | Opaque | Flask session signing key |
| Feast | {name}-feast-tls | kubernetes.io/tls | TLS certificates for HTTPS endpoints |
| Feast | {name}-feast-secret | Opaque | Database credentials and API keys |
| Feast | {name}-feast-registry-secret | Opaque | Registry backend credentials (S3, GCS) |
| Feast | {name}-feast-oidc-secret | Opaque | OIDC client credentials for UI auth |
| Feast | feast-operator-webhook-server-cert | kubernetes.io/tls | Webhook server certificate (future use) |

### Authentication Mechanisms

| Pattern | Components Using | Enforcement Point |
|---------|------------------|-------------------|
| OpenShift OAuth | ODH Dashboard, Kubeflow Notebooks | kube-rbac-proxy, OAuth Proxy sidecar |
| Bearer Tokens (K8s SA JWT) | MLflow, ODH Dashboard backend | kubernetes-auth middleware, RBAC proxy |
| mTLS Client Certificates | Feast (optional), Notebooks (optional) | Istio PeerAuthentication |
| OIDC (OpenID Connect) | Feast UI (optional) | FastAPI OAuth2 |
| Service Account Tokens | All operators | Kubernetes API Server |
| Kubernetes RBAC (SubjectAccessReview) | MLflow, ODH Dashboard | Custom middleware validating permissions |

## Platform APIs

### Custom Resource Definitions

**Platform Management:**

| Component | API Group | Kind | Scope | Purpose |
|-----------|-----------|------|-------|---------|
| OpenDataHub Operator | datasciencecluster.opendatahub.io | DataScienceCluster | Cluster | Declarative configuration of all data science components |
| OpenDataHub Operator | dscinitialization.opendatahub.io | DSCInitialization | Cluster | Platform initialization and global configuration |
| OpenDataHub Operator | components.platform.opendatahub.io | Dashboard, Workbenches, ModelRegistry, etc. | Cluster | Individual component configuration CRDs |
| OpenDataHub Operator | infrastructure.opendatahub.io | HardwareProfile | Cluster | Hardware resource profiles |
| ODH Dashboard | dashboard.opendatahub.io | OdhApplication | Namespaced | Applications in dashboard catalog |
| ODH Dashboard | opendatahub.io | OdhDashboardConfig | Namespaced | Dashboard feature flags and settings |
| ODH Dashboard | dashboard.opendatahub.io | OdhDocument | Namespaced | Documentation resources |
| ODH Dashboard | console.openshift.io | OdhQuickStart | Namespaced | Interactive tutorials |

**Workbench Management:**

| Component | API Group | Kind | Scope | Purpose |
|-----------|-----------|------|-------|---------|
| Kubeflow Notebooks | kubeflow.org | Notebook | Namespaced | Jupyter notebook instance (v1 storage, v1beta1/v1alpha1 conversion) |

**Feature Store:**

| Component | API Group | Kind | Scope | Purpose |
|-----------|-----------|------|-------|---------|
| Feast | feast.dev | FeatureStore | Namespaced | Feature store deployment with online/offline stores, registry, UI |

**Experiment Tracking:**

| Component | API Group | Kind | Scope | Purpose |
|-----------|-----------|------|-------|---------|
| MLflow | mlflow.kubeflow.org | MLflowConfig | Namespaced | Per-namespace artifact storage overrides |

### Public HTTP Endpoints

**Dashboard:**

| Component | Path | Method | Port | Protocol | Auth | Purpose |
|-----------|------|--------|------|----------|------|---------|
| ODH Dashboard | / | GET | 8443/TCP | HTTPS | OAuth | Dashboard UI entry point |
| ODH Dashboard | /api/config | GET, PATCH | 8080/TCP | HTTP | Bearer Token | Dashboard configuration |
| ODH Dashboard | /api/notebooks | GET, POST, DELETE, PATCH | 8080/TCP | HTTP | Bearer Token | Notebook CR management |
| ODH Dashboard | /api/modelRegistries | GET, POST, PATCH, DELETE | 8080/TCP | HTTP | Bearer Token | Model registry management |
| ODH Dashboard | /api/featurestores | GET | 8080/TCP | HTTP | Bearer Token | Feast feature store listing |

**MLflow:**

| Component | Path | Method | Port | Protocol | Auth | Purpose |
|-----------|------|--------|------|----------|------|---------|
| MLflow | /api/2.0/mlflow/experiments/* | GET, POST, DELETE | 5000/TCP | HTTP | Bearer Token | Experiment CRUD operations |
| MLflow | /api/2.0/mlflow/runs/* | GET, POST, DELETE | 5000/TCP | HTTP | Bearer Token | Run tracking and metrics logging |
| MLflow | /api/2.0/mlflow/model-versions/* | GET, POST, PATCH, DELETE | 5000/TCP | HTTP | Bearer Token | Model registry version management |
| MLflow | /api/3.0/mlflow/traces/* | GET, POST | 5000/TCP | HTTP | Bearer Token | LLM trace ingestion and retrieval |
| MLflow | / | GET | 5000/TCP | HTTP | None | React frontend UI |

**Feast:**

| Component | Path | Method | Port | Protocol | Auth | Purpose |
|-----------|------|--------|------|----------|------|---------|
| Feast | /get-online-features | POST | 80/TCP | HTTP | Optional Bearer/mTLS | Online feature retrieval |
| Feast | /push | POST | 80/TCP | HTTP | Optional Bearer/mTLS | Feature push to stores |
| Feast | /materialize | POST | 80/TCP | HTTP | Optional Bearer/mTLS | Feature materialization trigger |
| Feast | /ui | GET | 80/TCP | HTTP | Optional OIDC | Feature store web UI |
| Feast | /registry/* | GET/POST | 6572/TCP | HTTP | Optional Bearer | Registry REST API |
| Feast | /metrics | GET | 8000/TCP | HTTP | None | Prometheus metrics |

**Notebooks:**

| Component | Path | Method | Port | Protocol | Auth | Purpose |
|-----------|------|--------|------|----------|------|---------|
| Notebook Controller | /healthz | GET | 8081/TCP | HTTP | None | Controller health check |
| Notebook Controller | /readyz | GET | 8081/TCP | HTTP | None | Controller readiness |
| Notebook Controller | /metrics | GET | 8080/TCP | HTTP | None | Prometheus metrics |
| Notebook Instances | /* | * | {notebook-port}/TCP | HTTP | OAuth/Istio | Jupyter UI and APIs |

### gRPC Services

| Component | Service | Port | Protocol | Encryption | Auth | Purpose |
|-----------|---------|------|----------|------------|------|---------|
| Feast | ServingService | 6566/TCP | gRPC | None (optional mTLS) | Optional mTLS | Online features via gRPC |
| Feast | RegistryServer | 6570/TCP | gRPC | None (optional mTLS) | Optional mTLS | Feature registry operations |
| Feast | TransformationService | 6569/TCP | gRPC | None (optional mTLS) | Optional mTLS | Feature transformations |

**Note**: MLflow, Dashboard, and Notebook Controllers use HTTP/REST exclusively.

## Data Flows

### Key Platform Workflows

#### Workflow 1: User Accesses Dashboard to Create Notebook

| Step | Component | Action | Next Component |
|------|-----------|--------|----------------|
| 1 | User Browser | Navigates to Dashboard Route | OpenShift Router |
| 2 | OpenShift Router | Forwards to Dashboard Service | kube-rbac-proxy |
| 3 | kube-rbac-proxy | Authenticates via OAuth, forwards with user headers | Dashboard Backend |
| 4 | Dashboard Backend | Validates permissions, retrieves namespace list | Kubernetes API |
| 5 | Dashboard Backend | User creates Notebook via UI | Dashboard Backend |
| 6 | Dashboard Backend | Creates Notebook CR | Kubernetes API |
| 7 | Kubernetes API | Webhook validates Notebook CR | odh-notebook-controller webhook |
| 8 | odh-notebook-controller | Reconciles Notebook CR, creates StatefulSet, Service, OAuth client, Route | Kubernetes API |
| 9 | User | Accesses notebook via Route | Notebook Pod (via OAuth Proxy) |

#### Workflow 2: Data Scientist Tracks Experiment in MLflow from Notebook

| Step | Component | Action | Next Component |
|------|-----------|--------|----------------|
| 1 | Notebook Pod | User runs training script with MLflow Python SDK | MLflow client library |
| 2 | MLflow SDK | Sends experiment metadata and metrics | MLflow server (via Istio Gateway) |
| 3 | MLflow Server | Validates K8s SA token via SubjectAccessReview | Kubernetes API |
| 4 | MLflow Server | Stores experiment metadata | PostgreSQL |
| 5 | MLflow Server | Uploads model artifacts | S3-compatible storage |
| 6 | User | Views experiment results | MLflow UI (via browser) |

#### Workflow 3: Feature Engineering with Feast from Notebook

| Step | Component | Action | Next Component |
|------|-----------|--------|----------------|
| 1 | Notebook Pod | Notebook Controller injects Feast config at startup | Feast ConfigMap |
| 2 | Notebook Pod | User defines feature views using Feast Python SDK | Feast client library |
| 3 | Feast SDK | Registers feature definitions | Feast Registry Service |
| 4 | Feast SDK | Pushes historical features for training | Feast Offline Store (BigQuery/Snowflake) |
| 5 | Training Job | Retrieves historical features for model training | Feast Offline Feature Server |
| 6 | Feast SDK (materialization) | Materializes features from offline to online store | Feast Online Store (Redis/PostgreSQL) |
| 7 | Model Serving | Retrieves online features for real-time inference | Feast Online Feature Server |

#### Workflow 4: Platform Operator Installs Components via DataScienceCluster

| Step | Component | Action | Next Component |
|------|-----------|--------|----------------|
| 1 | Platform Admin | Creates/updates DataScienceCluster CR | Kubernetes API |
| 2 | Kubernetes API | Webhook validates DSC | odh-operator webhook |
| 3 | ODH Operator | Reconciles DSC, reads component configurations | Controller Manager |
| 4 | Controller Manager | Renders component manifests (Kustomize/Helm) | Manifest Renderer |
| 5 | Controller Manager | Creates Subscriptions for component operators | OLM (Operator Lifecycle Manager) |
| 6 | OLM | Installs component operators (Feast, MLflow, etc.) | OperatorHub / Quay.io |
| 7 | Component Operators | Deploy and manage component services | Kubernetes API |

#### Workflow 5: Idle Notebook Culling

| Step | Component | Action | Next Component |
|------|-----------|--------|----------------|
| 1 | notebook-controller-culler | Periodically checks notebook /metrics endpoint | Notebook Pod |
| 2 | notebook-controller-culler | Determines notebook is idle (no activity for CULL_IDLE_TIME) | Internal logic |
| 3 | notebook-controller-culler | Stops notebook by updating Notebook CR | Kubernetes API |
| 4 | notebook-controller | Reconciles stopped Notebook, scales StatefulSet to 0 | Kubernetes API |

## Deployment Architecture

### Deployment Topology

**Operator Namespace (`opendatahub-operator-system`):**
- OpenDataHub Operator (3 replicas with leader election)
- Webhook server
- Metrics service

**Platform Namespace (`opendatahub`):**
- ODH Dashboard (frontend + backend)
- Shared platform resources (ConfigMaps, Secrets)

**Component Operator Namespaces:**
- `redhat-ods-applications`: Notebook controllers, component operators
- `feast-operator-system`: Feast operator
- `mlflow-operator-system`: MLflow operator (if using operator pattern)

**User Workspaces (per-namespace multi-tenancy):**
- User-created namespaces contain:
  - Notebook StatefulSets
  - FeatureStore instances
  - MLflow workspace resources (experiments, models)
  - User data (PVCs, Secrets, ConfigMaps)

### Resource Requirements

**OpenDataHub Operator:**
- Requests: CPU 100m, Memory 780Mi
- Limits: CPU 1000m, Memory 4Gi

**ODH Dashboard Backend:**
- Requests: CPU 500m, Memory 256Mi
- Limits: CPU 500m, Memory 4Gi

**Notebook Controller:**
- Requests: CPU 500m, Memory 256Mi
- Limits: CPU 500m, Memory 4Gi

**Note**: User notebook resource requirements are configurable per instance. MLflow and Feast do not specify default resource constraints (deployment-specific).

## Version-Specific Changes (3.3.0)

| Component | Changes |
|-----------|---------|
| OpenDataHub Operator | - Added workbenches manifest separation (ODH/RHOAI)<br>- Added cert-manager PKI bootstrap for cloud controllers<br>- Added AutoRAG UI and AutoML UI to image map<br>- Added MLflow UI support<br>- Added cloud manager infrastructure (Azure, CoreWeave)<br>- Added MaaS API key max expiration configuration<br>- Enhanced monitoring and E2E testing documentation |
| ODH Dashboard | - Add automl module to modular architecture manifests<br>- Restructure AI Hub nav with Models and MCP servers subsections<br>- External models registration UI<br>- Add RayJob details drawer layout<br>- Type Filter for Ray and Train jobs<br>- Remove tech preview label on new permissions tab<br>- Balance test load across test sets |
| Kubeflow Notebooks | - Bump Go version to latest patch (1.25.7)<br>- Fix e2e test flakiness from culling<br>- Add fallback for Public API endpoint retrieval<br>- Assure proper pipelines runtime config/secret presence<br>- Fix notebook culler failing to stop idle notebooks<br>- Update golangci-lint tool |
| MLflow | - Kubernetes dependency bumped to >=35<br>- Added module federation support for prompt management<br>- Transformers 5.x compatibility<br>- Slim down image using UBI 9 directly<br>- Fix experiment page navigation for federated mode |
| Feast | - Added MongoDB online store support<br>- Feature server high-availability on Kubernetes<br>- Added materialization, freshness, latency, and push metrics<br>- Support for ARM Docker builds<br>- MLflow integration for feature selection<br>- Optimized DynamoDB batch reads with parallelization |

## Platform Maturity

- **Total Components Analyzed**: 5 (core platform components)
- **Total CRDs**: 20+ (DataScienceCluster, Notebook, FeatureStore, MLflowConfig, and component CRDs)
- **Operator-based Components**: 5/5 (100% - all components use operator pattern)
- **Service Mesh Coverage**: Optional (Feast, Notebooks support Istio when enabled)
- **mTLS Enforcement**: PERMISSIVE (optional, configurable per component)
- **Authentication**: Multi-layered (OpenShift OAuth for UI, K8s RBAC for APIs, optional mTLS for service mesh)
- **Multi-tenancy**: Namespace-based isolation with per-namespace workspaces
- **High Availability**: ODH Operator supports 3 replicas with leader election; component HA varies by service
- **Storage Backend Flexibility**: Multiple options for databases (PostgreSQL, Redis, MongoDB, Snowflake, BigQuery)
- **Cloud Compatibility**: AWS (S3), GCP (GCS, BigQuery), Azure (AKS integration in 3.3.0), CoreWeave

## Next Steps for Documentation

1. **Generate Architecture Diagrams**:
   - Component dependency graph
   - Network flow diagrams for key workflows
   - Security architecture diagrams for SAR (Security Architecture Review)

2. **Create User-Facing Documentation**:
   - Getting started guides for each component
   - Integration tutorials (Notebook → MLflow → Feast → Model Serving)
   - Multi-tenancy and RBAC configuration guides

3. **Security Documentation**:
   - Document authentication flows in detail
   - Create network policy templates
   - RBAC role assignment guides

4. **Operational Documentation**:
   - High availability deployment patterns
   - Backup and disaster recovery procedures
   - Monitoring and alerting setup guides

5. **Update Architecture Decision Records (ADRs)**:
   - Document rationale for operator-based architecture
   - Multi-tenancy design decisions
   - Component selection criteria

## Appendix: Component Versions

| Component | Repository | Version | Distribution |
|-----------|------------|---------|--------------|
| OpenDataHub Operator | https://github.com/opendatahub-io/opendatahub-operator | 3.3.0 | ODH, RHOAI |
| ODH Dashboard | https://github.com/opendatahub-io/odh-dashboard | v3.4.0EA1 | ODH, RHOAI |
| Kubeflow Notebook Controllers | https://github.com/opendatahub-io/kubeflow | v1.7.0-15-519 | ODH, RHOAI |
| MLflow | https://github.com/opendatahub-io/mlflow | 3.10.1 | ODH, RHOAI |
| Feast | https://github.com/feast-dev/feast | 0.61.0 | ODH, RHOAI |
