# Component: MLflow

## Metadata
- **Repository**: https://github.com/opendatahub-io/mlflow
- **Version**: 3.10.1 (targeting RHOAI 3.4-EA1)
- **Distribution**: ODH, RHOAI
- **Languages**: Python 3.12, TypeScript/JavaScript (React frontend), Node.js
- **Deployment Type**: Service (containerized application)

## Purpose
**Short**: Machine learning lifecycle platform for experiment tracking, model versioning, and LLM observability.

**Detailed**: MLflow is an open-source platform for managing the end-to-end machine learning lifecycle. It provides tools for experiment tracking (logging parameters, metrics, and artifacts), model versioning and deployment through a centralized model registry, LLM observability and tracing for GenAI applications, automated model evaluation, and prompt management. In RHOAI/ODH deployments, MLflow is enhanced with a Kubernetes workspace provider that maps namespaces to MLflow workspaces, enabling multi-tenant operation with Kubernetes RBAC enforcement for fine-grained access control. The service includes a React-based web UI for visualization and a comprehensive REST API for programmatic access.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| MLflow Server | Python/Flask web service | REST API and UI serving for experiment tracking and model registry |
| React Frontend | TypeScript/React SPA | Web UI for visualizing experiments, models, traces, and evaluations |
| Kubernetes Workspace Provider | Python extension | Maps Kubernetes namespaces to MLflow workspaces for multi-tenancy |
| Kubernetes Auth Plugin | Python middleware | Enforces Kubernetes RBAC on all MLflow API requests via SubjectAccessReview |
| Backend Store | PostgreSQL database | Persistent storage for experiments, runs, metrics, and model metadata |
| Artifact Store | S3-compatible storage | Object storage for model artifacts, datasets, and trace data |
| Prometheus Exporter | Python/Flask extension | Exposes MLflow server metrics for monitoring |

## APIs Exposed

### Custom Resource Definitions (CRDs)

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| mlflow.kubeflow.org | v1alpha1 | MLflowConfig | Namespaced | Per-namespace artifact storage overrides (S3 bucket and path configuration) |

**Note**: The CRD is optional. It allows namespace owners to override default artifact storage by referencing a Secret named `mlflow-artifact-connection` containing `AWS_S3_BUCKET`.

### HTTP Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /health | GET | 5000/TCP | HTTP | None | None | Health check endpoint |
| /version | GET | 5000/TCP | HTTP | None | None | MLflow version information |
| /api/2.0/mlflow/experiments/* | GET, POST, DELETE | 5000/TCP | HTTP | None | Bearer Token (K8s SA) | Experiment CRUD operations |
| /api/2.0/mlflow/runs/* | GET, POST, DELETE | 5000/TCP | HTTP | None | Bearer Token (K8s SA) | Run tracking and metrics logging |
| /api/2.0/mlflow/model-versions/* | GET, POST, PATCH, DELETE | 5000/TCP | HTTP | None | Bearer Token (K8s SA) | Model registry version management |
| /api/2.0/mlflow/registered-models/* | GET, POST, PATCH, DELETE | 5000/TCP | HTTP | None | Bearer Token (K8s SA) | Registered model management |
| /api/2.0/mlflow-artifacts/artifacts/* | GET, PUT, POST | 5000/TCP | HTTP | None | Bearer Token (K8s SA) | Artifact upload and download |
| /api/3.0/mlflow/traces/* | GET, POST | 5000/TCP | HTTP | None | Bearer Token (K8s SA) | LLM trace ingestion and retrieval |
| /api/2.0/mlflow/datasets/* | GET, POST, DELETE | 5000/TCP | HTTP | None | Bearer Token (K8s SA) | Evaluation dataset management |
| /ajax-api/2.0/mlflow/* | GET, POST | 5000/TCP | HTTP | None | Bearer Token (K8s SA) | UI-specific endpoints (bulk metrics, gateway proxy) |
| /ajax-api/3.0/mlflow/ui-telemetry | GET, POST | 5000/TCP | HTTP | None | Bearer Token (K8s SA) | UI telemetry collection |
| / | GET | 5000/TCP | HTTP | None | None | React frontend (index.html) |
| /static-files/* | GET | 5000/TCP | HTTP | None | None | React frontend static assets (JS, CSS) |

**Note**: In production RHOAI deployments, MLflow is typically exposed via Istio Gateway with TLS termination. The service itself runs on HTTP port 5000, but external access uses HTTPS/443 through the gateway. Authentication uses Kubernetes service account tokens passed via `Authorization: Bearer <token>` header or `X-Forwarded-Access-Token` when behind a proxy.

### gRPC Services

| Service | Port | Protocol | Encryption | Auth | Purpose |
|---------|------|----------|------------|------|---------|
| N/A | N/A | N/A | N/A | N/A | MLflow uses REST API only; no gRPC services |

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| PostgreSQL | 12+ | Yes | Backend store for experiment and model metadata |
| S3-compatible storage | N/A | Yes | Artifact storage (models, datasets, traces) |
| Kubernetes API | 1.24+ | Yes (for workspace provider) | Namespace listing, RBAC enforcement via SubjectAccessReview |
| Node.js | 20 | Build-time only | React frontend build (not runtime dependency) |

### Internal ODH Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| S3-compatible storage (Minio/Ceph) | REST API | Artifact storage backend |
| PostgreSQL database | SQL | Persistent metadata storage |
| Istio Gateway | HTTP proxy | External HTTPS exposure with TLS termination |
| Service Mesh (Istio) | mTLS | Optional service-to-service encryption |

## Network Architecture

### Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| mlflow-server | ClusterIP | 5000/TCP | 5000 | HTTP | None (TLS at gateway) | Bearer Token | Internal (via Istio) |

**Note**: Service configuration is typically managed by the ODH operator or deployment manifests external to this repository.

### Ingress

| Name | Type | Hosts | Port | Protocol | Encryption | TLS Mode | Exposure |
|------|------|-------|------|----------|------------|----------|----------|
| mlflow-gateway | Istio Gateway | mlflow.apps.* | 443/TCP | HTTPS | TLS 1.2+ | SIMPLE | External |

**Note**: Ingress/Gateway resources are managed by ODH operator, not included in this repository.

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| PostgreSQL database | 5432/TCP | PostgreSQL | TLS 1.2+ (optional) | Username/password | Backend metadata storage |
| S3 endpoint | 443/TCP | HTTPS | TLS 1.2+ | AWS IAM/access keys | Artifact storage operations |
| Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | Service account token | Namespace watch, RBAC checks (SubjectAccessReview) |

## Security

### RBAC - Cluster Roles

| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|
| mlflow-k8s-workspace-provider | "" (core) | namespaces | list, watch |
| mlflow-k8s-workspace-provider | mlflow.kubeflow.org | mlflowconfigs | list, watch |
| mlflow-k8s-workspace-provider | "" (core) | secrets (resourceNames: mlflow-artifact-connection) | get |
| mlflow-k8s-workspace-provider | authorization.k8s.io | subjectaccessreviews | create (for subject_access_review mode) |

### RBAC - Role Bindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| mlflow-k8s-workspace-provider | N/A (cluster-scoped) | ClusterRole: mlflow-k8s-workspace-provider | mlflow-server SA |

### RBAC - Custom API Resources (mlflow.kubeflow.org)

Users and service accounts interacting with MLflow must have permissions on the following resources in the `mlflow.kubeflow.org` API group:

| Resource | Verbs | Purpose |
|----------|-------|---------|
| experiments | get, list, create, update, delete | Experiment management |
| datasets | get, list, create, update, delete | Evaluation dataset management |
| registeredmodels | get, list, create, update, delete | Model registry operations (also covers prompts) |
| assistants | get, create, update | AI assistant operations (restricted to localhost) |
| gatewaysecrets | get, list, create, update, delete | Gateway secret management |
| gatewaysecrets/use | create | Permission to reference secrets in model definitions |
| gatewayendpoints | get, list, create, update, delete | Gateway endpoint management |
| gatewayendpoints/use | create | Permission to invoke gateway endpoints |
| gatewaymodeldefinitions | get, list, create, update, delete | Gateway model definition management |
| gatewaymodeldefinitions/use | create | Permission to reference model definitions |

**Note**: Runs use experiment permissions. Prompts use registeredmodels permissions. Scorers use experiment permissions. No separate RBAC resources for these.

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| mlflow-artifact-connection | Opaque | S3 credentials (AWS_S3_BUCKET, AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY) | Namespace owner (for MLflowConfig CRD) | No |
| mlflow-db-credentials | Opaque | PostgreSQL connection string and credentials | ODH operator | No |
| mlflow-flask-secret-key | Opaque | Flask application secret key for session signing | ODH operator | No |

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| /api/2.0/mlflow/* | All | Bearer Token (K8s SA JWT) | kubernetes-auth middleware | SelfSubjectAccessReview on mlflow.kubeflow.org resources |
| /api/3.0/mlflow/* | All | Bearer Token (K8s SA JWT) | kubernetes-auth middleware | SelfSubjectAccessReview on mlflow.kubeflow.org resources |
| /ajax-api/* | All | Bearer Token (K8s SA JWT) | kubernetes-auth middleware | SelfSubjectAccessReview on mlflow.kubeflow.org resources |
| / (UI) | GET | None (public) | None | UI is public; API calls from UI use bearer tokens |

**Authentication Modes**:
1. **self_subject_access_review** (default): Client sends `Authorization: Bearer <token>` with K8s SA token. Server performs `SelfSubjectAccessReview` using that token.
2. **subject_access_review**: Proxy (e.g., kube-rbac-proxy) authenticates user and forwards identity via `x-remote-user` and `x-remote-groups` headers. Server performs `SubjectAccessReview` using its own SA.

## Data Flows

### Flow 1: Experiment Tracking (Run Creation and Logging)

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Data scientist workstation | MLflow server | 5000/TCP (via Istio 443/TCP) | HTTPS | TLS 1.2+ | Bearer Token (K8s SA) |
| 2 | MLflow server | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | Service account token |
| 3 | MLflow server | PostgreSQL | 5432/TCP | PostgreSQL | TLS 1.2+ (optional) | Username/password |
| 4 | MLflow server | S3 storage | 443/TCP | HTTPS | TLS 1.2+ | AWS IAM/access keys |

**Description**: User creates experiment run via Python SDK or UI. MLflow validates permissions with Kubernetes API (SubjectAccessReview), stores metadata in PostgreSQL, and uploads artifacts to S3.

### Flow 2: Model Registry (Model Version Registration)

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Data scientist workstation | MLflow server | 5000/TCP (via Istio 443/TCP) | HTTPS | TLS 1.2+ | Bearer Token (K8s SA) |
| 2 | MLflow server | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | Service account token |
| 3 | MLflow server | PostgreSQL | 5432/TCP | PostgreSQL | TLS 1.2+ (optional) | Username/password |
| 4 | MLflow server | S3 storage | 443/TCP | HTTPS | TLS 1.2+ | AWS IAM/access keys |

**Description**: User registers model version. MLflow checks `registeredmodels` permissions via RBAC, stores model metadata in PostgreSQL, and links to artifacts in S3.

### Flow 3: LLM Trace Ingestion (OTLP Traces)

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | LLM application | MLflow server | 5000/TCP (via Istio 443/TCP) | HTTPS | TLS 1.2+ | Bearer Token (K8s SA) |
| 2 | MLflow server | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | Service account token |
| 3 | MLflow server | PostgreSQL | 5432/TCP | PostgreSQL | TLS 1.2+ (optional) | Username/password |
| 4 | MLflow server | S3 storage | 443/TCP | HTTPS | TLS 1.2+ | AWS IAM/access keys |

**Description**: LLM app sends OTLP traces to MLflow. Server validates permissions, stores trace metadata in PostgreSQL, and artifacts in S3. UI retrieves traces for visualization.

### Flow 4: Workspace Provider Initialization

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | MLflow server (startup) | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | Service account token |
| 2 | MLflow server (watch loop) | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | Service account token |

**Description**: On startup, MLflow establishes a watch on Namespaces and MLflowConfigs. Changes trigger cache updates. List/watch permissions are cluster-scoped.

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| PostgreSQL | SQL client | 5432/TCP | PostgreSQL | TLS 1.2+ (optional) | Metadata storage for experiments, runs, models |
| S3-compatible storage | REST API | 443/TCP | HTTPS | TLS 1.2+ | Artifact storage and retrieval |
| Kubernetes API | REST API | 6443/TCP | HTTPS | TLS 1.2+ | Namespace listing, RBAC enforcement (SubjectAccessReview) |
| Istio Gateway | HTTP proxy | 8080/TCP (internal) | HTTP | mTLS (service mesh) | External HTTPS exposure at 443/TCP |
| Prometheus | HTTP scrape | 5000/TCP | HTTP | None | Metrics export via prometheus-flask-exporter |
| Jupyter Notebook | REST API client | 5000/TCP (via Istio 443/TCP) | HTTPS | TLS 1.2+ | Experiment tracking from data science notebooks |
| Model serving (KServe) | REST API client | 5000/TCP (via Istio 443/TCP) | HTTPS | TLS 1.2+ | Model retrieval for deployment |

## Deployment Configuration

### Environment Variables

| Variable | Default | Purpose |
|----------|---------|---------|
| MLFLOW_DISABLE_TELEMETRY | true | Disable upstream MLflow telemetry |
| MLFLOW_SERVER_ENABLE_JOB_EXECUTION | false | Disable job execution feature (not used in RHOAI) |
| MLFLOW_ENABLE_ASSISTANT | false | Disable AI assistant feature (restricted to localhost) |
| MLFLOW_ENABLE_AI_GATEWAY | false | Disable AI gateway feature (deprecated in favor of deployments API) |
| MLFLOW_K8S_WORKSPACE_LABEL_SELECTOR | "" | Label selector for filtering namespaces (e.g., "mlflow-enabled=true") |
| MLFLOW_K8S_DEFAULT_WORKSPACE | "" | Default workspace/namespace when X-MLFLOW-WORKSPACE header is omitted |
| MLFLOW_K8S_NAMESPACE_EXCLUDE_GLOBS | "" | Comma-separated glob patterns to hide namespaces (in addition to kube-*, openshift-*) |
| MLFLOW_K8S_AUTH_CACHE_TTL_SECONDS | 300 | TTL for cached RBAC decisions (seconds) |
| MLFLOW_K8S_AUTH_USERNAME_CLAIM | sub | JWT claim to extract as username |
| MLFLOW_K8S_AUTH_AUTHORIZATION_MODE | self_subject_access_review | Authorization mode (self_subject_access_review or subject_access_review) |

### Container Build

Built via Konflux CI/CD pipeline using `Dockerfile.konflux`:
- **Base images**: UBI 9.7 (nodejs-20 for frontend build, python-312 for runtime, ubi:9.7 for final image)
- **Python package index**: AIPCC (Assured and Instrumented Python Container Catalog) for RHOAI 3.4-EA1
- **Build process**: Multi-stage build (Node.js frontend build → Python wheel build → final UBI image)
- **Container registry**: quay.io/opendatahub/mlflow:odh-stable
- **Supported architectures**: amd64, arm64, ppc64le

### Runtime Command

```bash
python3.12 -m mlflow server \
  --host 0.0.0.0 \
  --port 5000 \
  --app-name kubernetes-auth \
  --enable-workspaces \
  --workspace-store-uri kubernetes:// \
  --serve-artifacts
```

## Recent Changes

| Version | Date | Changes |
|---------|------|---------|
| 3.10.1 | 2024-12 | - Kubernetes dependency bumped to >=35<br>- Added module federation support for prompt management<br>- Transformers 5.x compatibility<br>- Slim down image using UBI 9 directly<br>- Fix experiment page navigation for federated mode |
| 3.10.0 | 2024-11 | - Added .syft.yaml for SBOM generation<br>- Fix Mistral autologging compatibility (mistralai >= 2.0)<br>- Fix transformers 5.0 compatibility<br>- UI improvements (tags, sorting, evaluation artifacts) |

## Notes

- **No CRD controllers**: While MLflow defines the `MLflowConfig` CRD, it does not include a Kubernetes controller. The workspace provider watches the CRD using client-go's watch API and caches configurations in-memory.
- **Multi-tenancy**: Each Kubernetes namespace maps to an MLflow workspace. All API requests must include `X-MLFLOW-WORKSPACE: <namespace>` header or set `MLFLOW_WORKSPACE` environment variable.
- **RBAC enforcement**: Every API call triggers a Kubernetes SubjectAccessReview. Permissions are evaluated on virtual resources in the `mlflow.kubeflow.org` API group (not real CRD instances).
- **Workspace read-only**: The workspace provider is read-only. Namespace creation/deletion is managed outside MLflow (via kubectl, OpenShift console, etc.).
- **Token acquisition**: Users obtain Kubernetes service account tokens via `kubectl create token <service-account> -n <namespace>` and pass them in the `Authorization: Bearer <token>` header.
- **Artifact storage overrides**: Namespaces can override default artifact storage by creating an `MLflowConfig` CR pointing to a Secret named `mlflow-artifact-connection` with S3 credentials.
- **UI federation**: The React frontend supports module federation, allowing deployment as a standalone app or federated into other UIs (e.g., ODH dashboard).
- **Hermetic builds**: Konflux builds are not yet fully hermetic (yarn/npm prefetching not supported). Python dependencies are hermetic via Cachi2 + AIPCC.
