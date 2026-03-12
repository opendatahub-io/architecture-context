# Component: MLflow Operator

## Metadata
- **Repository**: https://github.com/opendatahub-io/mlflow-operator.git
- **Version**: 33c744b
- **Distribution**: ODH and RHOAI (both)
- **Languages**: Go, Python, Helm, YAML
- **Deployment Type**: Kubernetes Operator

## Purpose
**Short**: Kubernetes operator for deploying and managing MLflow experiment tracking and model registry servers.

**Detailed**: The MLflow Operator automates the deployment and lifecycle management of MLflow on Kubernetes and OpenShift clusters. MLflow is an open-source platform for tracking experiments, packaging ML code, and sharing and deploying models. The operator uses Helm charts internally to render and apply Kubernetes manifests while providing a declarative Custom Resource API for configuration. It supports multiple deployment modes (ODH and RHOAI), flexible storage backends (SQLite for development, PostgreSQL for production, S3 for artifacts), built-in Kubernetes authentication using SubjectAccessReview, automatic TLS certificate provisioning via OpenShift service-ca, NetworkPolicy-based network security, CA bundle management for private certificate authorities, CORS configuration for web UI access, and namespace-scoped artifact storage overrides via MLflowConfig. The operator handles MLflow server deployment, persistent volume provisioning, RBAC configuration, OpenShift Console integration, and Gateway API HTTPRoute creation for ingress.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| MLflow Operator | Go Controller | Reconciles MLflow and MLflowConfig CRs to manage MLflow deployments |
| MLflow Controller | Reconciler | Deploys MLflow server with database, artifact storage, and TLS |
| MLflowConfig Controller | Watcher | Manages namespace-scoped artifact storage overrides |
| Helm Renderer | Template Engine | Renders Helm charts into Kubernetes manifests |
| NetworkPolicy Manager | Resource Creator | Creates egress/ingress policies for MLflow pods |
| TLS Certificate Manager | Integration | Manages TLS certificates via OpenShift service-ca or manual secrets |

## APIs Exposed

### Custom Resource Definitions (CRDs)

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| mlflow.opendatahub.io | v1 | MLflow | Cluster | Deploy and configure MLflow server instances |
| mlflow.kubeflow.org | v1 | MLflowConfig | Namespaced | Override artifact storage settings per namespace |

### HTTP Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /api/2.0/mlflow/* | GET, POST | 8443/TCP | HTTPS | TLS 1.2+ | Bearer Token (K8s) | MLflow REST API for experiments and models |
| / | GET | 8443/TCP | HTTPS | TLS 1.2+ | Bearer Token (K8s) | MLflow web UI |
| /health | GET | 8443/TCP | HTTPS | TLS 1.2+ | None | MLflow health check endpoint |
| /metrics | GET | 8080/TCP | HTTP | None | None | Prometheus metrics for operator |

### gRPC Services
No gRPC services are exposed. MLflow uses REST/HTTP APIs for all communication.

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| MLflow | 2.x | Yes | Core experiment tracking and model registry service |
| PostgreSQL | 12+ | No | Production database backend for experiments and models |
| SQLite | 3.x | No | Default development database (file-based) |
| S3-compatible storage | Any | No | Remote artifact storage (MinIO, AWS S3, etc.) |
| Helm | 3.x | Yes | Template rendering engine (embedded in operator) |
| OpenShift service-ca | 4.x | No | Automatic TLS certificate provisioning (OpenShift only) |

### Internal ODH Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| Notebooks | API Client | Track experiments and log metrics from workbench notebooks |
| Data Science Pipelines | Integration | Log pipeline run metrics and artifacts to MLflow |
| Training Operator | Integration | Track distributed training experiments |
| Model Registry | Alternative | MLflow provides its own model registry functionality |
| S3 Storage | Artifact Storage | Store model artifacts and experiment files |

## Network Architecture

### Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| mlflow | ClusterIP | 8443/TCP | 8443 | HTTPS | TLS 1.2+ | Bearer Token | Internal |
| mlflow-operator-metrics | ClusterIP | 8080/TCP | 8080 | HTTP | None | None | Internal |

### Ingress

| Name | Type | Hosts | Port | Protocol | Encryption | TLS Mode | Exposure |
|------|------|-------|------|----------|------------|----------|----------|
| mlflow-httproute | Gateway HTTPRoute | *.apps.cluster | 443/TCP | HTTPS | TLS 1.2+ | Gateway TLS | External |
| mlflow-consolelink | OpenShift ConsoleLink | Console UI | N/A | HTTPS | TLS 1.2+ | Browser | External |

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| PostgreSQL Database | 5432/TCP | PostgreSQL | TLS 1.2+ (optional) | Password | Store experiment and model metadata |
| MySQL Database | 3306/TCP | MySQL | TLS 1.2+ (optional) | Password | Alternative database backend |
| S3-compatible storage | 443/TCP, 9000/TCP, 8333/TCP | HTTPS | TLS 1.2+ | AWS credentials | Store experiment artifacts and models |
| DNS | 53/UDP, 53/TCP | DNS | None | None | Resolve hostnames |
| Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token | SubjectAccessReview for authentication |

## Security

### RBAC - Cluster Roles

| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|
| manager-role | "" | namespaces | get, list, watch |
| manager-role | "" (resourceNames: mlflow-artifact-connection) | secrets | get |
| manager-role | mlflow.opendatahub.io | mlflows | create, delete, get, list, patch, update, watch |
| manager-role | mlflow.kubeflow.org | mlflowconfigs | get, list, watch |
| manager-role | rbac.authorization.k8s.io | clusterroles, clusterrolebindings | create, delete, get, list, patch, update, watch |
| manager-role | gateway.networking.k8s.io | httproutes | create, delete, get, list, patch, update, watch |
| manager-role | console.openshift.io | consolelinks | create, delete, get, list, patch, update, watch |
| mlflow (server pod role) | "" | namespaces | get, list, watch |
| mlflow (server pod role) | "" (resourceNames: mlflow-artifact-connection) | secrets | get |
| mlflow (server pod role) | mlflow.kubeflow.org | mlflowconfigs | get, list, watch |

### RBAC - Role Bindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| mlflow-operator-rolebinding | opendatahub / redhat-ods-applications | manager-role | mlflow-operator |
| mlflow-server-rolebinding | <deployment-namespace> | mlflow (ClusterRole) | mlflow |

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| mlflow-tls | kubernetes.io/tls | TLS certificate and key for HTTPS | OpenShift service-ca / User-provided | Yes (service-ca) |
| mlflow-db-credentials | Opaque | PostgreSQL/MySQL connection strings | User-provided | No |
| mlflow-artifact-connection | Opaque | S3/object storage credentials (AWS_ACCESS_KEY_ID, etc.) | User-provided | No |
| aws-credentials | Opaque | Alternative S3 credentials via envFrom | User-provided | No |

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| MLflow REST API | GET, POST, PUT, DELETE | Bearer Token (K8s) | MLflow kubernetes-auth | SubjectAccessReview (in-process) |
| MLflow Web UI | GET, POST | Bearer Token (K8s) | MLflow kubernetes-auth | SubjectAccessReview (in-process) |
| Operator Metrics | GET | None | None | Internal access only |
| Health Endpoint | GET | None | None | Public access |

## Data Flows

### Flow 1: Experiment Tracking from Notebook

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Notebook Pod | MLflow Service | 8443/TCP | HTTPS | TLS 1.2+ | Bearer Token |
| 2 | MLflow Pod | Kubernetes API (SubjectAccessReview) | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 3 | MLflow Pod | PostgreSQL DB | 5432/TCP | PostgreSQL | TLS 1.2+ (optional) | Password |
| 4 | MLflow Pod | S3 Storage (artifacts) | 443/TCP | HTTPS | TLS 1.2+ | AWS credentials |
| 5 | MLflow Pod | Notebook (response) | 8443/TCP | HTTPS | TLS 1.2+ | N/A |

### Flow 2: MLflow CR Creation

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User/Dashboard | Kubernetes API (create MLflow CR) | 6443/TCP | HTTPS | TLS 1.2+ | Bearer Token |
| 2 | MLflow Operator | Kubernetes API (create Deployment) | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 3 | MLflow Operator | Kubernetes API (create PVC) | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 4 | MLflow Operator | Kubernetes API (create Service + annotation) | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 5 | OpenShift service-ca | mlflow-tls Secret (create cert) | N/A | N/A | N/A | N/A |
| 6 | MLflow Operator | HTTPRoute (create for Gateway) | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 7 | MLflow Pod | PostgreSQL DB (initialize schema) | 5432/TCP | PostgreSQL | TLS 1.2+ (optional) | Password |

### Flow 3: Web UI Access via Gateway

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User Browser | Gateway (HTTPRoute) | 443/TCP | HTTPS | TLS 1.2+ | Session Cookie |
| 2 | Gateway | MLflow Service | 8443/TCP | HTTPS | TLS 1.2+ | Bearer Token |
| 3 | MLflow Pod | Kubernetes API (auth check) | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 4 | MLflow Pod | PostgreSQL DB | 5432/TCP | PostgreSQL | TLS 1.2+ (optional) | Password |
| 5 | MLflow Pod | User Browser (via Gateway) | 443/TCP | HTTPS | TLS 1.2+ | N/A |

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| Kubernetes API | REST API | 6443/TCP | HTTPS | TLS 1.2+ | Manage MLflow deployments and perform SubjectAccessReview |
| PostgreSQL/MySQL Database | Database Protocol | 5432/3306 | PostgreSQL/MySQL | TLS 1.2+ (optional) | Store experiment and model metadata |
| S3-compatible Storage | HTTP API | 443/TCP, 9000/TCP | HTTPS | TLS 1.2+ | Store experiment artifacts and model files |
| OpenShift service-ca | Certificate Injection | N/A | N/A | N/A | Automatic TLS certificate provisioning |
| Gateway API | HTTPRoute CRD | 6443/TCP | HTTPS | TLS 1.2+ | Expose MLflow via data science gateway |
| OpenShift Console | ConsoleLink CRD | 6443/TCP | HTTPS | TLS 1.2+ | Add MLflow link to OpenShift web console |
| Prometheus | Metrics Scraping | 8080/TCP | HTTP | None | Collect operator metrics |
| ServiceMonitor | CRD Integration | N/A | N/A | N/A | Auto-configure Prometheus scraping |

## Recent Changes

| Version | Date | Changes |
|---------|------|---------|
| 33c744b | 2025-01 | - Fix test flake issues<br>- Restructure MLflow RBAC aggregate roles and add mlflow-integration<br>- Correct test image filepath reference in builder GHA<br>- Harden NetworkPolicy egress and make it configurable |
| 1399d47 | 2024-12 | - Document RBAC requirements and rationale<br>- Prevent MLflow CRs from setting MLFLOW_SERVER_DISABLE_SECURITY_MIDDLEWARE<br>- Preconfigure CORS allowed origins with safe defaults<br>- Update OWNERS file to current developers |
| 8dd2980 | 2024-12 | - Iterate on storage options for integration tests<br>- Regenerate CRDs after dependency update<br>- Bump k8s modules to 0.32.4 and opentelemetry to 1.40.0<br>- Add integration test image builder GHA<br>- Add .syft.yaml for SBOM generation<br>- Upgrade k8s client version for tests |
