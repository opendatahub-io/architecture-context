# Component: Data Science Pipelines Operator

## Metadata
- **Repository**: https://github.com/red-hat-data-services/data-science-pipelines-operator.git
- **Version**: rhoai-2.6 (commit: 025e77a)
- **Distribution**: RHOAI
- **Languages**: Go 1.19
- **Deployment Type**: Kubernetes Operator
- **Manifests Location**: config/ (Kustomize-based)

## Purpose
**Short**: Kubernetes operator that deploys and manages namespace-scoped Data Science Pipelines (DSP) application stacks on OpenShift.

**Detailed**: The Data Science Pipelines Operator (DSPO) is a Kubernetes operator based on the operator-sdk framework that enables data scientists to create, track, and manage machine learning workflows. It manages the deployment and lifecycle of DSP application stacks, which are based on Kubeflow Pipelines (KFP) v1.x with Tekton backend (via kfp-tekton). Each DSP instance is namespace-scoped and configured through a DataSciencePipelinesApplication custom resource. The operator deploys core pipeline components (API server, persistence agent, scheduled workflow controller) along with optional components (MariaDB database, Minio object storage, ML Pipelines UI, and ML Metadata tracking). Data scientists can author workflows using the kfp-tekton SDK or Elyra and interact with pipelines through the ODH Dashboard or directly via API. The operator handles all Kubernetes resource creation including deployments, services, routes, RBAC, network policies, and TLS certificates.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| DSPO Controller Manager | Kubernetes Operator | Reconciles DataSciencePipelinesApplication CRs and manages all DSPA lifecycle operations |
| API Server | REST/gRPC Service | KFP API server that handles pipeline CRUD operations, run management, and artifact tracking |
| Persistence Agent | Kubernetes Controller | Syncs Tekton PipelineRun status to DSP database for tracking and visualization |
| Scheduled Workflow Controller | Kubernetes Controller | Manages cron-based pipeline execution schedules |
| MariaDB | Database (Optional) | Default metadata storage for pipeline definitions, runs, experiments, and metrics |
| Minio | Object Storage (Optional) | Default S3-compatible storage for pipeline artifacts (dev/test only) |
| ML Pipelines UI | Web Frontend (Optional) | Upstream KFP UI for pipeline visualization and management (unsupported) |
| MLMD gRPC Server | gRPC Service (Optional) | ML Metadata server for artifact lineage tracking |
| MLMD Envoy Proxy | Proxy (Optional) | Envoy proxy providing external access to MLMD gRPC server |
| MLMD Writer | Kubernetes Controller (Optional) | Writes pipeline execution metadata to MLMD database |
| OAuth Proxy | Sidecar Container | OpenShift OAuth proxy for securing API server and UI endpoints |

## APIs Exposed

### Custom Resource Definitions (CRDs)

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| datasciencepipelinesapplications.opendatahub.io | v1alpha1 | DataSciencePipelinesApplication | Namespaced | Defines a complete DSP application stack with all component configurations |

**DSPA Spec Fields**:
- `apiServer`: API server configuration (image, resources, TLS CA bundle, artifact tracking settings)
- `persistenceAgent`: Persistence agent configuration (image, resources, worker count)
- `scheduledWorkflow`: Scheduled workflow controller configuration (image, resources, timezone)
- `database`: Database configuration (MariaDB deployment or external DB connection)
- `objectStorage`: Object storage configuration (Minio deployment or external S3/compatible storage)
- `mlpipelineUI`: Optional ML Pipelines UI configuration
- `mlmd`: Optional ML Metadata configuration (envoy, gRPC, writer components)

### HTTP Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /metrics | GET | 8080/TCP | HTTP | None | None | Operator Prometheus metrics endpoint |
| /healthz | GET | 8081/TCP | HTTP | None | None | Operator liveness probe |
| /readyz | GET | 8081/TCP | HTTP | None | None | Operator readiness probe |
| /apis/v1beta1/* | GET, POST, PUT, DELETE, PATCH | 8888/TCP | HTTP | TLS (internal) | OAuth (via 8443 proxy) | DSP API server - pipeline management |
| /apis/v2beta1/* | GET, POST, PUT, DELETE, PATCH | 8888/TCP | HTTP | TLS (internal) | OAuth (via 8443 proxy) | DSP API server - runs and experiments |
| / | GET | 8443/TCP | HTTPS | TLS 1.2+ | OAuth Bearer Token | OAuth proxy to API server (external access) |
| / | GET | 8443/TCP | HTTPS | TLS 1.2+ | OAuth Bearer Token | ML Pipelines UI (external access) |
| /api/runs | GET, POST | 8888/TCP | HTTP | TLS (internal) | Service-to-service | API server internal endpoint for runs |
| /api/pipelines | GET, POST | 8888/TCP | HTTP | TLS (internal) | Service-to-service | API server internal endpoint for pipelines |

### gRPC Services

| Service | Port | Protocol | Encryption | Auth | Purpose |
|---------|------|----------|------------|------|---------|
| API Server gRPC | 8887/TCP | gRPC/HTTP2 | TLS (internal) | Service Account | Internal gRPC API for pipeline operations |
| MLMD gRPC Server | 8080/TCP (configurable) | gRPC/HTTP2 | None | None | ML Metadata artifact and execution tracking |
| MLMD Envoy Proxy | 9090/TCP | gRPC/HTTP2 | None | Network Policy | External access to MLMD gRPC from ODH Dashboard |

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| OpenShift Pipelines (Tekton) | 1.8+ | Yes | Pipeline execution engine - Tekton PipelineRuns backend for KFP workflows |
| OpenShift | 4.9+ | Yes | Kubernetes platform with Routes, OAuth, service CA injection |
| MariaDB / MySQL | 5.7+ | No (if external DB provided) | Pipeline metadata storage |
| S3-compatible Object Storage | N/A | No (if external storage provided) | Pipeline artifact and data storage |
| Prometheus Operator | N/A | No | Metrics collection via ServiceMonitor |

### Internal ODH Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| ODH Dashboard | HTTP/gRPC API | Dashboard displays pipelines UI and interacts with MLMD Envoy for artifact lineage |
| Notebook Controller | Tekton API | Notebooks can submit pipelines via kfp-tekton SDK to DSP API server |
| Model Registry | MLMD gRPC | Model registry may track model lineage via MLMD integration |

## Network Architecture

### Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| controller-manager service | ClusterIP | 8080/TCP | 8080 | HTTP | None | None | Internal (metrics) |
| ds-pipeline-{name} | ClusterIP | 8443/TCP | oauth | HTTPS | TLS 1.2+ (service CA) | OAuth proxy | Internal |
| ds-pipeline-{name} | ClusterIP | 8888/TCP | http | HTTP | TLS (service-to-service) | Service Account | Internal |
| ds-pipeline-{name} | ClusterIP | 8887/TCP | 8887 | gRPC | TLS (internal) | Service Account | Internal |
| mariadb-{name} | ClusterIP | 3306/TCP | 3306 | MySQL | None | DB credentials | Internal |
| minio-{name} | ClusterIP | 9000/TCP | 9000 | HTTP | None | S3 credentials | Internal |
| ds-pipeline-ui-{name} | ClusterIP | 8443/TCP | 8443 | HTTPS | TLS 1.2+ (service CA) | OAuth proxy | Internal |
| ds-pipeline-metadata-grpc-{name} | ClusterIP | 8080/TCP | 8080 | gRPC | None | None | Internal |
| ds-pipeline-metadata-envoy-{name} | ClusterIP | 9090/TCP | 9090 | gRPC | None | Network Policy | Internal |

### Ingress

| Name | Type | Hosts | Port | Protocol | Encryption | TLS Mode | Exposure |
|------|------|-------|------|----------|------------|----------|----------|
| ds-pipeline-{name} | OpenShift Route | Auto-generated | 8443/TCP | HTTPS | TLS 1.2+ | Reencrypt | External |
| ds-pipeline-ui-{name} | OpenShift Route | Auto-generated | 8443/TCP | HTTPS | TLS 1.2+ | Reencrypt | External |

**Route Details**:
- **Termination**: Reencrypt (TLS termination at route, re-encrypted to backend)
- **Insecure Traffic**: Redirected to HTTPS
- **Backend Certificates**: Provided by OpenShift service CA (service.alpha.openshift.io/serving-cert-secret-name)

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| External Database (if configured) | 3306/TCP or 5432/TCP | MySQL/PostgreSQL | TLS 1.2+ (optional) | DB credentials from Secret | Pipeline metadata storage |
| External S3 Storage (if configured) | 443/TCP | HTTPS | TLS 1.2+ | AWS IAM / S3 credentials | Pipeline artifact storage |
| MariaDB Service (internal) | 3306/TCP | MySQL | None | DB credentials from Secret | Default database connection |
| Minio Service (internal) | 9000/TCP | HTTP | None | S3 credentials from Secret | Default object storage connection |
| Tekton API | 443/TCP | HTTPS | TLS 1.2+ | Service Account Token | Creating and monitoring PipelineRuns |

## Security

### RBAC - Cluster Roles

| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|
| manager-role | datasciencepipelinesapplications.opendatahub.io | datasciencepipelinesapplications | create, delete, get, list, patch, update, watch |
| manager-role | datasciencepipelinesapplications.opendatahub.io | datasciencepipelinesapplications/status | get, patch, update |
| manager-role | datasciencepipelinesapplications.opendatahub.io | datasciencepipelinesapplications/finalizers | update |
| manager-role | apps, "", extensions | deployments, replicasets | * |
| manager-role | "" | configmaps, persistentvolumeclaims, secrets, serviceaccounts, services, pods | create, delete, get, list, patch, update, watch |
| manager-role | "" | events | create, list, patch |
| manager-role | batch | jobs | * |
| manager-role | rbac.authorization.k8s.io | roles, rolebindings, clusterroles, clusterrolebindings | create, delete, get, list, update, watch, patch |
| manager-role | route.openshift.io | routes | create, delete, get, list, patch, update, watch |
| manager-role | monitoring.coreos.com | servicemonitors | create, delete, get, list, patch, update, watch |
| manager-role | networking.k8s.io | networkpolicies | create, delete, get, list, patch, update, watch |
| manager-role | tekton.dev | * | * |
| manager-role | kubeflow.org | * | * |
| manager-role | custom.tekton.dev | pipelineloops | * |
| manager-role | argoproj.io | workflows | * |
| manager-role | authentication.k8s.io | tokenreviews | create |
| manager-role | authorization.k8s.io | subjectaccessreviews | create |
| manager-role | image.openshift.io | imagestreamtags | get |
| manager-role | machinelearning.seldon.io | seldondeployments | * |
| manager-role | ray.io | rayclusters, rayjobs, rayservices | create, delete, get, list, patch |
| manager-role | snapshot.storage.k8s.io | volumesnapshots | create, delete, get |
| manager-role | mcad.ibm.com, workload.codeflare.dev | appwrappers | create, delete, deletecollection, get, list, patch, update, watch |
| aggregate-dspa-admin-edit | datasciencepipelinesapplications.opendatahub.io | datasciencepipelinesapplications | get, list, watch, create, update, patch, delete |
| ds-pipeline-{name} | tekton.dev | tasks, pipelineruns, taskruns, conditions, runs, customruns, pipelineresources | create, delete, get, list, watch, update, patch |
| ds-pipeline-{name} | custom.tekton.dev | pipelineloops | create, delete, get, list, watch, update, patch |
| ds-pipeline-{name} | argoproj.io | workflows | create, delete, get, list, watch, update, patch |
| pipeline-runner-{name} | tekton.dev | pipelineruns, taskruns, runs, customruns | create, delete, get, list, watch, update, patch |
| pipeline-runner-{name} | "" | pods, pods/log | get, list, watch |

### RBAC - Role Bindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| controller-manager-rolebinding | operator namespace | manager-role (ClusterRole) | controller-manager |
| leader-election-rolebinding | operator namespace | leader-election-role (Role) | controller-manager |
| ds-pipeline-{name} | DSPA namespace | ds-pipeline-{name} (Role) | ds-pipeline-{name} |
| pipeline-runner-{name} | DSPA namespace | pipeline-runner-{name} (Role) | pipeline-runner-{name} |
| ds-pipeline-ui-{name}-binding | DSPA namespace | ds-pipeline-ui-{name} (Role) | ds-pipeline-ui-{name} |
| ds-pipeline-persistenceagent-{name} | DSPA namespace | ds-pipeline-persistenceagent-{name} (Role) | ds-pipeline-persistenceagent-{name} |
| ds-pipeline-scheduledworkflow-{name} | DSPA namespace | ds-pipeline-scheduledworkflow-{name} (Role) | ds-pipeline-scheduledworkflow-{name} |
| ds-pipeline-metadata-writer-{name} | DSPA namespace | ds-pipeline-metadata-writer-{name} (Role) | ds-pipeline-metadata-writer-{name} |

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| ds-pipelines-proxy-tls-{name} | kubernetes.io/tls | OAuth proxy TLS certificate for API server | OpenShift Service CA | Yes |
| ds-pipelines-ui-proxy-tls-{name} | kubernetes.io/tls | OAuth proxy TLS certificate for UI | OpenShift Service CA | Yes |
| mariadb-{name} | Opaque | MariaDB root password | DSPO or user-provided | No |
| {storage-secret-name} | Opaque | S3/Minio access key and secret key | User-provided | No |
| {db-secret-name} | Opaque | External database password | User-provided (for external DB) | No |

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| Route: ds-pipeline-{name} | GET, POST, PUT, DELETE | OAuth Bearer Token (JWT) | OAuth Proxy Sidecar | OpenShift OAuth - requires authenticated user |
| Route: ds-pipeline-ui-{name} | GET | OAuth Bearer Token (JWT) | OAuth Proxy Sidecar | OpenShift OAuth - requires authenticated user |
| Service: ds-pipeline-{name}:8888 | GET, POST, PUT, DELETE | Service Account Token | Network Policy | Internal services only - restricted by pod selector |
| Service: ds-pipeline-{name}:8887 | gRPC | Service Account Token | Network Policy | Internal services only - restricted by pod selector |
| Service: ds-pipeline-metadata-envoy-{name}:9090 | gRPC | None | Network Policy | ODH Dashboard pods and DSPA components only |
| Tekton API | All | Service Account Token | Kubernetes RBAC | ServiceAccount tokens with Tekton resource permissions |

### Network Policies

**Policy: ds-pipelines-{name}**
- **Target Pods**: API Server pods (app=ds-pipeline-{name})
- **Ingress Rules**:
  - Allow all sources to port 8443/TCP (OAuth proxy endpoint)
  - Allow from monitoring namespaces (openshift-user-workload-monitoring, redhat-ods-monitoring) to ports 8888/TCP, 8887/TCP
  - Allow from DSPA component pods (mariadb, minio, ui, persistenceagent, scheduledworkflow, mlmd-*) to ports 8888/TCP, 8887/TCP
- **Purpose**: External traffic must use OAuth on 8443; internal service-to-service bypasses OAuth

**Policy: ds-pipelines-envoy-{name}**
- **Target Pods**: MLMD Envoy proxy (app=ds-pipeline-metadata-envoy-{name})
- **Ingress Rules**:
  - Allow from ODH Dashboard pods (app=odh-dashboard) to port 9090/TCP
  - Allow from DSPA component pods (component=data-science-pipelines) to port 9090/TCP
- **Purpose**: Restrict MLMD gRPC access to dashboard and internal pipeline components

## Data Flows

### Flow 1: User Submits Pipeline via UI/API

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User Browser | OpenShift Router | 443/TCP | HTTPS | TLS 1.2+ | None (initial) |
| 2 | OpenShift Router | ds-pipeline-{name} Route | 8443/TCP | HTTPS | TLS 1.2+ (reencrypt) | None |
| 3 | Route | ds-pipeline-{name} Service (OAuth Proxy) | 8443/TCP | HTTPS | TLS 1.2+ (service CA) | OAuth Bearer Token |
| 4 | OAuth Proxy | API Server Container | 8888/TCP | HTTP | None (localhost) | Verified by proxy |
| 5 | API Server | MariaDB Service | 3306/TCP | MySQL | None | DB credentials (Secret) |
| 6 | API Server | Minio/S3 Service | 9000/TCP or 443/TCP | HTTP/HTTPS | TLS 1.2+ (if external) | S3 credentials (Secret) |
| 7 | API Server | Tekton API (kube-apiserver) | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |

### Flow 2: Persistence Agent Syncs Run Status

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Persistence Agent | Tekton API (kube-apiserver) | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 2 | Persistence Agent | API Server Service | 8888/TCP | HTTP | TLS (internal) | ServiceAccount Token |
| 3 | Persistence Agent | MariaDB Service | 3306/TCP | MySQL | None | DB credentials (Secret) |
| 4 | Persistence Agent | Minio/S3 Service | 9000/TCP or 443/TCP | HTTP/HTTPS | TLS 1.2+ (if external) | S3 credentials (Secret) |

### Flow 3: Scheduled Workflow Creates Pipeline Run

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Scheduled Workflow Controller | Tekton API (kube-apiserver) | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 2 | Scheduled Workflow Controller | API Server Service | 8888/TCP | HTTP | TLS (internal) | ServiceAccount Token |
| 3 | API Server | Tekton API | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token (pipeline-runner SA) |

### Flow 4: MLMD Lineage Tracking (Optional)

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | ODH Dashboard | MLMD Envoy Service | 9090/TCP | gRPC/HTTP2 | None | Network Policy |
| 2 | MLMD Envoy | MLMD gRPC Service | 8080/TCP | gRPC/HTTP2 | None | None (internal) |
| 3 | MLMD gRPC | MariaDB Service | 3306/TCP | MySQL | None | DB credentials |
| 4 | MLMD Writer | MLMD gRPC Service | 8080/TCP | gRPC/HTTP2 | None | None (internal) |
| 5 | MLMD Writer | Tekton API | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| Tekton (OpenShift Pipelines) | Kubernetes API | 443/TCP | HTTPS | TLS 1.2+ | Create/monitor PipelineRuns, TaskRuns, and custom resources |
| MariaDB/External DB | MySQL/PostgreSQL | 3306/TCP or 5432/TCP | MySQL/PostgreSQL | TLS 1.2+ (optional) | Store pipeline metadata, runs, experiments, metrics |
| Minio/S3 Storage | S3 API | 9000/TCP or 443/TCP | HTTP/HTTPS | TLS 1.2+ (if external) | Store pipeline artifacts, data, and model files |
| ODH Dashboard | HTTP API + gRPC | 8443/TCP, 9090/TCP | HTTPS, gRPC | TLS 1.2+, None | Display pipeline UI and artifact lineage visualization |
| Prometheus | HTTP Metrics | 8080/TCP | HTTP | None | Scrape operator and DSPA component metrics |
| OpenShift OAuth | OAuth 2.0 | N/A | HTTPS | TLS 1.2+ | Authenticate users accessing pipeline API and UI |
| OpenShift Service CA | Certificate Injection | N/A | N/A | N/A | Automatic TLS certificate provisioning for services |
| Notebook Server | HTTP API | 8443/TCP | HTTPS | TLS 1.2+ | Submit pipelines from notebooks via kfp-tekton SDK |

## Deployment Architecture

### Operator Deployment
- **Namespace**: Configurable (typically `opendatahub` or `redhat-ods-applications`)
- **Replicas**: 1 (leader election enabled)
- **Resources**: CPU: 10m request / 1 CPU limit, Memory: 64Mi request / 4Gi limit
- **Security Context**: Non-root, no privilege escalation, all capabilities dropped

### DSPA Instance Deployment (per namespace)
When a DataSciencePipelinesApplication CR is created, DSPO deploys:

**Always Deployed**:
- API Server Deployment (1 replica) with OAuth proxy sidecar
- Persistence Agent Deployment (1 replica)
- Scheduled Workflow Deployment (1 replica)

**Conditionally Deployed** (based on DSPA spec):
- MariaDB Deployment + PVC (if `database.mariaDB.deploy=true`)
- Minio Deployment + PVC (if `objectStorage.minio.deploy=true`)
- ML Pipelines UI Deployment with OAuth proxy (if `mlpipelineUI.deploy=true`)
- MLMD gRPC Server Deployment (if `mlmd.deploy=true`)
- MLMD Envoy Proxy Deployment (if `mlmd.deploy=true`)
- MLMD Writer Deployment (if `mlmd.deploy=true`)

**Supporting Resources** (always created):
- ConfigMaps (artifact script, UI config, MLMD envoy config)
- Secrets (DB credentials, S3 credentials, TLS certificates)
- Services (for each deployed component)
- Routes (for API server and UI if enabled)
- ServiceAccounts (for each component)
- Roles and RoleBindings (namespace-scoped permissions)
- NetworkPolicies (ingress restrictions)
- ServiceMonitors (Prometheus metrics)

## Monitoring & Observability

### Operator Metrics (Port 8080)
- Standard controller-runtime metrics (reconciliation, queue depth, errors)
- Custom DSPA metrics:
  - `data_science_pipelines_application_apiserver_ready`: Gauge (0/1) - API server readiness
  - `data_science_pipelines_application_persistenceagent_ready`: Gauge (0/1) - Persistence agent readiness
  - `data_science_pipelines_application_scheduledworkflow_ready`: Gauge (0/1) - Scheduled workflow readiness
  - `data_science_pipelines_application_ready`: Gauge (0/1) - Overall DSPA readiness

### Health Checks
- **Operator Liveness**: HTTP GET /healthz on port 8081
- **Operator Readiness**: HTTP GET /readyz on port 8081
- **Component Health**: Each DSPA component has liveness/readiness probes configured

### Logging
- Operator logs to stdout/stderr (captured by OpenShift logging)
- Structured logging with log levels (info, debug, error)
- Pipeline run logs stored in Tekton TaskRun pods and archived to object storage (if enabled)

## Configuration Management

### Operator Configuration
- ConfigMap: `dspo-config` - Contains default images, parameters, and feature flags
- Environment Variables: Override config file settings (IMAGES_*, feature flags)
- Command-line Flags: `--config`, `--leader-elect`, `--metrics-bind-address`, `--health-probe-bind-address`

### DSPA Configuration
- Custom Resource: `DataSciencePipelinesApplication` - Declarative configuration for entire stack
- Secrets: Database credentials, S3 credentials, custom TLS CA bundles
- ConfigMaps: Artifact scripts, UI configurations, CA bundles

## High Availability & Scalability

- **Operator**: Single replica with leader election (active-passive HA)
- **API Server**: Single replica (stateless, can be scaled but not configured by default)
- **Persistence Agent**: Single replica (active reconciliation, scaling not recommended)
- **Scheduled Workflow**: Single replica (active reconciliation, scaling not recommended)
- **Database**: Single MariaDB replica (default), external DB can be HA-configured
- **Object Storage**: Single Minio replica (default), external S3 is typically HA

**Note**: DSPA instances are namespace-scoped and isolated. Multiple DSPAs can run in different namespaces.

## Limitations & Constraints

1. **Namespace Scope**: Each DSPA instance is confined to a single namespace
2. **Single Operator**: One DSPO instance manages all DSPAs across the cluster
3. **Tekton Dependency**: Requires OpenShift Pipelines (Tekton) 1.8+ to be pre-installed
4. **Default Storage**: Minio and MariaDB are for dev/test only, not production-supported
5. **UI Support**: Upstream KFP UI is unsupported; ODH Dashboard is the supported interface
6. **KFP Version**: Currently supports KFP v1.x with Tekton backend, v2 support in progress
7. **Platform**: Designed for OpenShift; uses OpenShift-specific features (Routes, OAuth, Service CA)

## Recent Changes

| Commit | Date | Changes |
|--------|------|---------|
| 025e77a | 2024 | Merge pull request #540 - Stable branch update |
| 4ad7227 | 2024 | Merge remote-tracking branch 'odh/v1.5.x' into stable |
| 6c9550c | 2024 | Merge pull request #525 - Update to latest 1.5 DSP images |
| 9a45136 | 2024 | Update params.env to latest 1.5 dsp images |
| 961edf9 | 2024 | Merge pull request #524 - Pre-commit and linting updates |
| 7eb7d7e | 2024 | Update pre-commit to support golang 1.19 |
| 30209d8 | 2024 | Correct linting issues |
| e874fa4 | 2024 | Add support for CA bundle injection for external DB/storage with custom TLS |
| b5c93c5 | 2024 | Update golang grpc package for security fixes |
| 9e1fbae | 2024 | Update x/net package for security vulnerabilities |
| 6395cbb | 2024 | Upgrade to Go 1.19 for latest security and performance improvements |
| 4402e56 | 2024 | Merge pull request #452 - Stable branch sync |
| d6632ba | 2024 | Merge branch 'v1.4.x' into stable |
| c3393ab | 2024 | Add params for v1.4.1 release |
| 5907202 | 2024 | Add support for CA bundle injection feature |
| 7a590dd | 2024 | Update http2/grpc packages and Go version to 1.19 |
| c9cd9b2 | 2024 | Merge pull request #420 - HTTP2 and gRPC security updates |
| 9a5ce76 | 2024 | Update http2/grpc packages for CVE fixes |
| 0297169 | 2024 | Merge pull request #410 - Stable branch maintenance |
| 14b7434 | 2024 | Merge tag 'v1.3.2' into stable - Backport security fixes |

**Key Theme**: Recent changes focus on security updates (Go 1.19 upgrade, gRPC/HTTP2 package updates), CA bundle injection support for external TLS connections, and stable branch maintenance.
