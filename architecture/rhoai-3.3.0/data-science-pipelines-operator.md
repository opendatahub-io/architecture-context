# Component: Data Science Pipelines Operator (DSPO)

## Metadata
- **Repository**: https://github.com/red-hat-data-services/data-science-pipelines-operator.git
- **Version**: 0.0.1 (rhoai-3.3 branch)
- **Distribution**: RHOAI
- **Languages**: Go
- **Deployment Type**: Kubernetes Operator (namespace-scoped pipeline deployments)

## Purpose
**Short**: Kubernetes operator that manages lifecycle of Data Science Pipelines (DSP) applications, enabling ML workflow orchestration based on Kubeflow Pipelines.

**Detailed**: The Data Science Pipelines Operator (DSPO) deploys and manages namespace-scoped Data Science Pipeline stacks on OpenShift clusters. It is based on the upstream Kubeflow Pipelines (KFP) project and enables data scientists to create, track, and manage ML workflows for data preparation, model training, validation, and experimentation. The operator manages the complete lifecycle of pipeline infrastructure including API servers, persistence agents, workflow controllers, metadata tracking, and optional database/storage components. Each DataSciencePipelinesApplication (DSPA) custom resource instance creates an isolated pipeline environment within a namespace, supporting multiple concurrent pipeline deployments across different namespaces.

The operator integrates with Argo Workflows for pipeline execution, provides optional MariaDB and Minio deployments for development/testing, supports external object storage (AWS S3, etc.), and includes ML Metadata (MLMD) for artifact lineage tracking. Data scientists interact with pipelines through the KFP SDK, Elyra, or the ODH dashboard UI.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| DSPO Controller Manager | Kubernetes Operator | Reconciles DataSciencePipelinesApplication CRs and manages pipeline component lifecycle |
| DS Pipeline API Server | REST/gRPC Service | Provides KFP v2 API for pipeline/run management, artifact retrieval, and workflow orchestration |
| Persistence Agent | Controller | Watches Argo Workflows and persists execution metadata to database |
| Scheduled Workflow Controller | Controller | Manages scheduled/recurring pipeline runs via ScheduledWorkflow CRs |
| Argo Workflow Controller | Workflow Engine | Executes pipeline tasks as Kubernetes workflows (namespace-scoped) |
| ML Metadata gRPC Server | gRPC Service | Stores artifact lineage and metadata for ML experiments (optional) |
| ML Metadata Envoy Proxy | Proxy | Provides HTTP/gRPC proxy with mTLS support for MLMD access (optional) |
| MariaDB | Database | MySQL-compatible database for pipeline metadata storage (optional dev/test) |
| Minio | Object Storage | S3-compatible object storage for pipeline artifacts (optional dev/test) |
| Kube RBAC Proxy | Security Proxy | Provides authenticated/authorized access to metrics and API endpoints |

## APIs Exposed

### Custom Resource Definitions (CRDs)

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| datasciencepipelinesapplications.opendatahub.io | v1 | DataSciencePipelinesApplication | Namespaced | Main CR for deploying pipeline stack with DB, storage, API server, and workflow controllers |
| pipelines.kubeflow.org | v2beta1 | Pipeline | Namespaced | Represents a versioned pipeline definition |
| pipelines.kubeflow.org | v2beta1 | PipelineVersion | Namespaced | Represents a specific version of a pipeline with execution spec |
| kubeflow.org | v1beta1 | ScheduledWorkflow | Namespaced | Defines scheduled/recurring pipeline executions |
| argoproj.io | v1alpha1 | Workflow | Namespaced | Argo Workflow for pipeline execution (managed by Argo controller) |

### HTTP Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /healthz | GET | 8081/TCP | HTTP | None | None | Operator liveness probe |
| /readyz | GET | 8081/TCP | HTTP | None | None | Operator readiness probe |
| /metrics | GET | 8080/TCP | HTTP | None | ServiceMonitor | Operator Prometheus metrics endpoint |
| /apis/v2beta1/* | GET/POST/DELETE | 8888/TCP | HTTP | None | Bearer Token | KFP v2 API for pipelines, runs, experiments, artifacts |
| /apis/v2beta1/artifacts/{id} | GET | 8888/TCP | HTTP | None | Bearer Token | Artifact download with signed URLs (60s expiry default) |
| Route: ds-pipeline-{name} | ALL | 8443/TCP | HTTPS | TLS 1.2+ (Reencrypt) | OAuth Proxy | External API server access via OpenShift Route |
| Route: minio-{name} | ALL | 443/TCP | HTTPS | TLS 1.2+ (Edge) | None | External Minio S3 access (dev/test only) |
| Route: ds-pipeline-md-{name} | ALL | 8443/TCP | HTTPS | TLS 1.2+ (Reencrypt) | OAuth Proxy | External MLMD envoy access |

### gRPC Services

| Service | Port | Protocol | Encryption | Auth | Purpose |
|---------|------|----------|------------|------|---------|
| ds-pipeline-{name} | 8887/TCP | gRPC | Optional mTLS | ServiceAccount Token | KFP API gRPC interface for pipeline operations |
| ds-pipeline-metadata-grpc-{name} | 8080/TCP | gRPC | Optional mTLS | None | ML Metadata GRPC service for artifact/lineage tracking |
| ds-pipeline-md-{name} (envoy) | 9090/TCP | gRPC/HTTP2 | Optional mTLS | OAuth Proxy | Envoy proxy for MLMD with authentication |

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| OpenShift/Kubernetes | 4.11+ | Yes | Container orchestration platform |
| Argo Workflows | Embedded (namespace-scoped) | Yes | Pipeline workflow execution engine |
| MariaDB or External MySQL DB | 10.3+ | Yes | Pipeline metadata persistence (can be external) |
| S3-compatible Object Storage | Any | Yes | Pipeline artifact storage (Minio or external S3/AWS) |
| OpenShift Pipelines (Tekton) | Not required for v2 | No | DSPv1 legacy dependency only |
| cert-manager | Optional | No | Automated TLS certificate management for pod-to-pod mTLS |

### Internal ODH Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| ODH Dashboard | UI Integration | Pipeline management UI and workbench integration |
| Workbenches (Notebooks) | Network Access | Notebook pods can access pipeline API server for job submission |
| OpenShift Monitoring | ServiceMonitor | Metrics collection for DSPA status and controller health |
| ODH Operator | DataScienceCluster CR | Deployment via DSC `datasciencepipelines` component |

## Network Architecture

### Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| service (operator) | ClusterIP | 8080/TCP | 8080 | HTTP | None | None | Internal (metrics) |
| ds-pipeline-{name} | ClusterIP | 8443/TCP | proxy | HTTPS | TLS (service-cert) | OAuth Proxy | Internal |
| ds-pipeline-{name} | ClusterIP | 8888/TCP | 8888 | HTTP | Optional mTLS | Bearer Token | Internal |
| ds-pipeline-{name} | ClusterIP | 8887/TCP | 8887 | gRPC | Optional mTLS | Bearer Token | Internal |
| mariadb-{name} | ClusterIP | 3306/TCP | 3306 | MySQL | Optional TLS | Username/Password | Internal |
| minio-{name} | ClusterIP | 9000/TCP | 9000 | HTTP | None | AccessKey/SecretKey | Internal |
| minio-{name} | ClusterIP | 80/TCP | 9000 | HTTP | None | AccessKey/SecretKey | Internal (KFP UI compat) |
| ds-pipeline-metadata-grpc-{name} | ClusterIP | 8080/TCP | 8080 | gRPC | Optional mTLS | None | Internal |
| ds-pipeline-md-{name} (envoy) | ClusterIP | 9090/TCP | 9090 | gRPC/HTTP2 | Optional mTLS | OAuth Proxy | Internal |
| ds-pipeline-md-{name} (envoy) | ClusterIP | 8443/TCP | 8443 | HTTPS | TLS (service-cert) | OAuth Proxy | Internal |

### Ingress

| Name | Type | Hosts | Port | Protocol | Encryption | TLS Mode | Exposure |
|------|------|-------|------|----------|------------|----------|----------|
| ds-pipeline-{name} | OpenShift Route | Auto-generated | 8443/TCP | HTTPS | TLS 1.2+ | Reencrypt | External |
| minio-{name} | OpenShift Route | Auto-generated | 443/TCP | HTTPS | TLS 1.2+ | Edge | External (dev only) |
| ds-pipeline-md-{name} | OpenShift Route | Auto-generated | 8443/TCP | HTTPS | TLS 1.2+ | Reencrypt | External |

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| External S3 (AWS/compatible) | 443/TCP | HTTPS | TLS 1.2+ | AWS IAM/Access Keys | Pipeline artifact storage (when using external storage) |
| External MySQL/MariaDB | 3306/TCP | MySQL | Optional TLS | Username/Password | Pipeline metadata persistence (when using external DB) |
| Image Registries | 443/TCP | HTTPS | TLS 1.2+ | Pull Secrets | Container image pulls for pipeline tasks |
| Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token | Workflow/pod management by controllers |

## Security

### RBAC - Cluster Roles

| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|
| manager-role | datasciencepipelinesapplications.opendatahub.io | datasciencepipelinesapplications, datasciencepipelinesapplications/finalizers, datasciencepipelinesapplications/status | create, delete, get, list, patch, update, watch |
| manager-role | pipelines.kubeflow.org | pipelines, pipelineversions | create, delete, get, list, patch, update, watch |
| manager-role | argoproj.io | workflows, workflowartifactgctasks, workflowtaskresults | create, delete, get, list, patch, update, watch, * |
| manager-role | "" (core) | configmaps, secrets, serviceaccounts, persistentvolumeclaims, services | create, delete, get, list, patch, update, watch |
| manager-role | "" (core) | pods, pods/exec, pods/log | get, list, delete, * |
| manager-role | apps | deployments, replicasets | create, delete, get, list, patch, update, watch, * |
| manager-role | rbac.authorization.k8s.io | roles, rolebindings, clusterroles, clusterrolebindings | create, delete, get, list, patch, update, watch |
| manager-role | route.openshift.io | routes | create, delete, get, list, patch, update, watch |
| manager-role | networking.k8s.io | networkpolicies | create, delete, get, list, patch, update, watch |
| manager-role | monitoring.coreos.com | servicemonitors | create, delete, get, list, patch, update, watch |
| manager-role | admissionregistration.k8s.io | mutatingwebhookconfigurations, validatingwebhookconfigurations | create, delete, get, list, patch, update, watch |
| manager-role | serving.kserve.io | inferenceservices | create, delete, get, list, patch |
| manager-role | batch | jobs | create, delete, get, list, patch, update, watch, * |
| aggregate-dspa-admin-view | datasciencepipelinesapplications.opendatahub.io | datasciencepipelinesapplications | get, list, watch |
| aggregate-dspa-admin-view | pipelines.kubeflow.org | pipelines, pipelineversions | get, list, watch |

### RBAC - Role Bindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| rolebinding.ds-pipeline-{name} | Per DSPA instance | ds-pipeline-{name} (Role) | ds-pipeline-{name} |
| rolebinding.ds-pipeline-persistenceagent-{name} | Per DSPA instance | ds-pipeline-persistenceagent-{name} (Role) | ds-pipeline-persistenceagent-{name} |
| rolebinding.ds-pipeline-scheduledworkflow-{name} | Per DSPA instance | ds-pipeline-scheduledworkflow-{name} (Role) | ds-pipeline-scheduledworkflow-{name} |
| rolebinding.argo-{name} | Per DSPA instance | ds-pipeline-argo-role-{name} (Role) | ds-pipeline-argo-{name} |
| rolebinding.pipeline-runner-{name} | Per DSPA instance | ds-pipeline-pipeline-runner-role-{name} (Role) | pipeline-runner-{name} |
| leader-election-rolebinding | Operator namespace | leader-election-role (Role) | controller-manager |
| manager-rolebinding | Operator namespace | manager-role (ClusterRole) | controller-manager |

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| ds-pipelines-proxy-tls-{name} | kubernetes.io/tls | TLS cert for API server OAuth proxy | service.beta.openshift.io/serving-cert | Yes (OpenShift) |
| ds-pipelines-mariadb-tls-{name} | kubernetes.io/tls | TLS cert for MariaDB pod-to-pod encryption | service.beta.openshift.io/serving-cert | Yes (OpenShift) |
| ds-pipelines-envoy-proxy-tls-{name} | kubernetes.io/tls | TLS cert for MLMD Envoy proxy | service.beta.openshift.io/serving-cert | Yes (OpenShift) |
| ds-pipeline-metadata-grpc-tls-certs-{name} | kubernetes.io/tls | TLS cert for MLMD gRPC mTLS | service.beta.openshift.io/serving-cert | Yes (OpenShift) |
| {custom-db-secret} | Opaque | Database credentials (user-provided or auto-generated) | User or DSPO | No |
| {custom-storage-secret} | Opaque | Object storage credentials (S3 access/secret keys) | User or DSPO | No |

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| /apis/v2beta1/* (8888) | ALL | Bearer Token (JWT) | Kube RBAC Proxy | Kubernetes RBAC via TokenReview/SubjectAccessReview |
| Route: ds-pipeline-{name} (8443) | ALL | OAuth Proxy (OpenShift) | OpenShift Route + OAuth Proxy | OpenShift OAuth + RBAC |
| /metrics (8080) | GET | ServiceAccount Token | Kube RBAC Proxy | Prometheus ServiceMonitor auth |
| gRPC API (8887) | ALL | Bearer Token (JWT) | API Server RBAC | Kubernetes RBAC |
| MLMD gRPC (8080) | ALL | None (internal only) | NetworkPolicy | Pod label-based access control |
| MLMD Envoy (9090, 8443) | ALL | OAuth Proxy | Kube RBAC Proxy | Kubernetes RBAC |
| MariaDB (3306) | ALL | Username/Password | MySQL Auth | Database credentials in secret |
| Minio (9000) | ALL | Access Key/Secret Key | S3 Auth | S3 credentials in secret |

### Network Policies

| Policy Name | Target Pods | Ingress Rules | Purpose |
|-------------|-------------|---------------|---------|
| ds-pipelines-{name} | app={{.APIServerDefaultResourceName}} | Allow 8443 from all, 8888/8887 from monitoring, DSP components, workbenches, v2_components | Restrict API server access to authorized sources |
| mariadb-{name} | app=mariadb-{name} | Allow 3306 from operator, API server, MLMD gRPC | Restrict DB access to DSP components only |
| ds-pipeline-metadata-grpc-{name} | app=ds-pipeline-metadata-grpc-{name} | Allow 8080 from v2_components and DSP components | Restrict MLMD gRPC to pipeline tasks and internal components |
| ds-pipelines-envoy-{name} | app=ds-pipeline-metadata-envoy-{name} | Allow 8443 from all, 9090 from DSP components | Restrict MLMD Envoy access |

## Data Flows

### Flow 1: Pipeline Submission via API

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User/Notebook | ds-pipeline-{name} (Route) | 443/TCP | HTTPS | TLS 1.2+ (Reencrypt) | OAuth Proxy |
| 2 | OAuth Proxy | ds-pipeline-{name} Service | 8888/TCP | HTTP | Optional mTLS | Bearer Token |
| 3 | API Server | mariadb-{name} | 3306/TCP | MySQL | Optional TLS | Username/Password |
| 4 | API Server | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 5 | Kubernetes API | Argo Workflow Controller | N/A | Internal | N/A | ServiceAccount |
| 6 | Workflow Controller | Creates Workflow Pods | N/A | Internal | N/A | ServiceAccount |

### Flow 2: Pipeline Execution and Artifact Storage

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Argo Workflow Pod | API Server | 8887/TCP | gRPC | Optional mTLS | ServiceAccount Token |
| 2 | Workflow Pod | Minio/S3 | 9000/TCP or 443/TCP | HTTP/HTTPS | TLS for external S3 | Access/Secret Keys |
| 3 | Workflow Pod | MLMD gRPC (optional) | 8080/TCP | gRPC | Optional mTLS | None (NetworkPolicy) |
| 4 | Persistence Agent | API Server | 8887/TCP | gRPC | Optional mTLS | Bearer Token |
| 5 | Persistence Agent | mariadb-{name} | 3306/TCP | MySQL | Optional TLS | Username/Password |

### Flow 3: Scheduled Pipeline Execution

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Scheduled Workflow Controller | API Server | 8887/TCP | gRPC | Optional mTLS | Bearer Token |
| 2 | Scheduled Workflow Controller | Kubernetes API (create Workflow) | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 3 | Argo Workflow Controller | Executes scheduled workflow | N/A | Internal | N/A | ServiceAccount |

### Flow 4: Metrics Collection

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Prometheus (OpenShift Monitoring) | Operator /metrics | 8080/TCP | HTTP | None | ServiceAccount Token |
| 2 | Prometheus | API Server /metrics (if ServiceMonitor deployed) | 8888/TCP | HTTP | None | ServiceAccount Token |

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| Kubernetes API Server | REST API | 6443/TCP | HTTPS | TLS 1.2+ | Resource management (Workflows, Pods, Deployments, CRs) |
| Argo Workflow Controller | CRD Reconciliation | N/A | Internal | N/A | Pipeline execution via Workflow CRs |
| MariaDB/MySQL | Database Connection | 3306/TCP | MySQL | Optional TLS | Pipeline metadata persistence (runs, experiments, artifacts) |
| S3-compatible Storage | S3 API | 443/TCP or 9000/TCP | HTTPS/HTTP | TLS for external | Pipeline artifact storage and retrieval |
| ODH Dashboard | HTTP API | 8443/TCP | HTTPS | TLS + OAuth | UI for pipeline management and visualization |
| Workbenches (Notebooks) | KFP SDK Client | 8443/TCP | HTTPS | TLS + OAuth | Pipeline submission from Jupyter notebooks |
| OpenShift Monitoring | Prometheus Metrics | 8080/TCP | HTTP | None | Operator and DSPA health metrics |
| MLMD (ML Metadata) | gRPC | 8080/TCP | gRPC | Optional mTLS | Artifact lineage and metadata tracking |
| OAuth Proxy | Authentication Proxy | 8443/TCP | HTTPS | TLS + OAuth | User authentication for external routes |

## Recent Changes

| Commit | Date | Changes |
|--------|------|---------|
| b1b9259 | 2026-03 | chore(deps): update registry.access.redhat.com/ubi9/ubi-minimal docker digest |
| 4bece53 | 2026-03 | sync pipelineruns with konflux-central |
| bf7033d | 2026-03 | chore(deps): update registry.access.redhat.com/ubi9/ubi-minimal docker digest |
| 86320b8 | 2026-03 | chore(deps): update registry.access.redhat.com/ubi9/ubi-minimal docker digest |
| 32e63f8 | 2026-03 | chore(deps): update registry.access.redhat.com/ubi9/ubi-minimal docker digest |
| 8657b79 | 2026-02 | chore(deps): update registry.access.redhat.com/ubi9/ubi-minimal docker digest |
| a4e4211 | 2026-01 | chore(deps): update registry.access.redhat.com/ubi9/ubi-minimal docker digest |
| 7c9be6e | 2026-01 | chore(deps): update registry.access.redhat.com/ubi9/ubi-minimal docker digest |
| 445cc64 | 2025-12 | sync pipelineruns with konflux-central |
| 1121666 | 2025-12 | chore(deps): update registry.access.redhat.com/ubi9/ubi-minimal docker digest |
| e57d137 | 2025-12 | sync pipelineruns with konflux-central |
| 6def25f | 2025-12 | chore(deps): update konflux references |
| f3ef76b | 2025-12 | chore(deps): update konflux references |
| 0766a03 | 2025-12 | chore(deps): update konflux references |
| 5278791 | 2025-12 | chore(deps): update konflux references |

## Notes

### Deployment Architecture

The Data Science Pipelines Operator follows a multi-tiered architecture:

1. **Operator Level (Cluster-scoped)**: Single DSPO deployment per cluster manages all DSPA instances
2. **Application Level (Namespace-scoped)**: Each DSPA CR creates isolated pipeline infrastructure in target namespace
3. **Execution Level (Pod-scoped)**: Each pipeline run creates ephemeral Argo Workflow pods for task execution

### Key Design Decisions

- **Namespace Isolation**: Each DSPA instance is fully isolated within its namespace with dedicated controllers, DB, and storage
- **Optional Components**: MariaDB and Minio are optional dev/test components; production deployments should use external managed services
- **Argo Workflows**: Replaced Tekton (OpenShift Pipelines) in v2 for better KFP compatibility and namespace-scoped deployment
- **Pod-to-Pod TLS**: Optional mTLS support between components for enhanced security in strict environments
- **Webhook Management**: Operator manages PipelineVersion validation/mutation webhooks for pipeline spec validation
- **FIPS Compliance**: FIPS-enabled builds available via GOEXPERIMENT=strictfipsruntime flag

### Metrics Exposed

The operator exposes custom Prometheus metrics:
- `data_science_pipelines_application_apiserver_ready`: APIServer readiness (1=Ready, 0=NotReady)
- `data_science_pipelines_application_persistenceagent_ready`: PersistenceAgent readiness
- `data_science_pipelines_application_scheduledworkflow_ready`: ScheduledWorkflow controller readiness
- `data_science_pipelines_application_ready`: Overall DSPA readiness

### Configuration Management

- Image references managed via ConfigMap (dspo-config) with env var overrides
- Live config reload supported via Viper config watcher
- Template-based resource generation from `config/internal/` directory
- Kustomize overlays for ODH vs RHOAI distributions
