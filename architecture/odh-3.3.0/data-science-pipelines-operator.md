# Component: Data Science Pipelines Operator

## Metadata
- **Repository**: https://github.com/opendatahub-io/data-science-pipelines-operator
- **Version**: 0.0.1
- **Distribution**: ODH, RHOAI
- **Languages**: Go
- **Deployment Type**: Operator

## Purpose
**Short**: Deploys and manages Data Science Pipeline stacks for ML workflow orchestration.

**Detailed**: The Data Science Pipelines Operator (DSPO) is a Kubernetes operator that deploys namespace-scoped Data Science Pipeline stacks onto OpenShift clusters. Based on upstream Kubeflow Pipelines (KFP), it enables data scientists to create, track, and manage ML workflows for data preparation, model training, and validation. The operator reconciles DataSciencePipelinesApplication (DSPA) custom resources to deploy and configure complete pipeline stacks including API servers, persistence agents, workflow controllers, and optional components like MariaDB and Minio. It integrates with ODH Dashboard and supports workflow authoring via KFP SDK and Elyra.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| DSPO Controller Manager | Operator Controller | Reconciles DSPA resources and manages pipeline stack lifecycle |
| DS Pipelines API Server | REST API Service | Provides KFP v2 API for pipeline management and execution |
| Argo Workflow Controller | Workflow Engine | Executes pipeline workflows using Argo Workflows |
| Persistence Agent | Data Persistence | Persists workflow metadata and artifacts to database |
| Scheduled Workflow Controller | Scheduler | Manages scheduled and recurring pipeline executions |
| ML Metadata (MLMD) | Metadata Tracking | Tracks ML artifacts, models, and lineage (optional) |
| MariaDB | Database | Stores pipeline metadata and execution history (optional) |
| Minio | Object Storage | Stores pipeline artifacts and outputs (optional) |

## APIs Exposed

### Custom Resource Definitions (CRDs)

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| datasciencepipelinesapplications.opendatahub.io | v1 | DataSciencePipelinesApplication | Namespaced | Defines a complete DSP stack deployment with API server, database, and storage |
| argoproj.io | v1alpha1 | Workflow | Namespaced | Represents an Argo workflow execution |
| argoproj.io | v1alpha1 | WorkflowTemplate | Namespaced | Defines reusable workflow templates |
| argoproj.io | v1alpha1 | CronWorkflow | Namespaced | Schedules recurring workflow executions |
| argoproj.io | v1alpha1 | ClusterWorkflowTemplate | Cluster | Cluster-scoped workflow templates |
| argoproj.io | v1alpha1 | WorkflowEventBinding | Namespaced | Binds events to workflow triggers |
| argoproj.io | v1alpha1 | WorkflowArtifactGCTask | Namespaced | Garbage collection tasks for workflow artifacts |
| argoproj.io | v1alpha1 | WorkflowTaskSet | Namespaced | Groups of workflow tasks |
| argoproj.io | v1alpha1 | WorkflowTaskResult | Namespaced | Results from workflow task execution |
| pipelines.kubeflow.org | v1 | Pipeline | Namespaced | Represents a KFP pipeline definition |
| pipelines.kubeflow.org | v1 | PipelineVersion | Namespaced | Represents a version of a KFP pipeline |
| scheduledworkflow.kubeflow.org | v1beta1 | ScheduledWorkflow | Namespaced | Manages scheduled pipeline runs |

### HTTP Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /healthz | GET | 8081/TCP | HTTP | None | None | Operator liveness probe |
| /readyz | GET | 8081/TCP | HTTP | None | None | Operator readiness probe |
| /metrics | GET | 8080/TCP | HTTP | None | Bearer | Prometheus metrics endpoint |
| /apis/v2beta1/* | Multiple | 8888/TCP | HTTPS | TLS 1.2+ | Bearer Token | KFP v2 API for pipelines, runs, experiments |

### gRPC Services

| Service | Port | Protocol | Encryption | Auth | Purpose |
|---------|------|----------|------------|------|---------|
| ml_metadata.MetadataStoreService | 8080/TCP | gRPC | mTLS | cert | ML Metadata tracking service |

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| OpenShift | 4.11+ | Yes | Kubernetes platform for operator deployment |
| Argo Workflows | v3.4+ | Yes | Workflow execution engine (deployed by operator) |
| MariaDB | 10.11+ | No | Pipeline metadata persistence (can be external) |
| Minio | latest | No | Artifact storage (can be external S3) |
| cert-manager | latest | No | TLS certificate management for webhooks |

### Internal ODH Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| ODH Dashboard | UI Integration | Provides pipeline UI and notebook integration |
| ODH Operator | CRD | Managed via DataScienceCluster for ODH deployments |
| Notebooks | Pipeline Execution | Launches pipeline steps in notebook containers |

## Network Architecture

### Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| controller-manager | ClusterIP | 8080/TCP | 8080 | HTTP | None | None | Internal |
| ds-pipeline-api-server | ClusterIP | 8888/TCP | 8888 | HTTPS | TLS 1.2+ | Bearer | Internal |
| ds-pipeline-metadata-grpc | ClusterIP | 8080/TCP | 8080 | gRPC | mTLS | cert | Internal |
| ds-pipeline-metadata-envoy | ClusterIP | 9090/TCP | 9090 | gRPC | mTLS | cert | Internal |
| ds-pipeline-persistenceagent | ClusterIP | 8888/TCP | 8888 | HTTP | None | None | Internal |
| ds-pipeline-scheduledworkflow | ClusterIP | 8888/TCP | 8888 | HTTP | None | None | Internal |
| mariadb | ClusterIP | 3306/TCP | 3306 | MySQL | TLS 1.2+ | Password | Internal |
| minio | ClusterIP | 9000/TCP | 9000 | HTTP | TLS 1.2+ | Access Key | Internal |

### Ingress

| Name | Type | Hosts | Port | Protocol | Encryption | TLS Mode | Exposure |
|------|------|-------|------|----------|------------|----------|----------|
| ds-pipeline-api | OpenShift Route | ds-pipeline-api-{namespace}.{cluster-domain} | 443/TCP | HTTPS | TLS 1.2+ | Edge | External |
| ds-pipeline-ui | OpenShift Route | ds-pipeline-ui-{namespace}.{cluster-domain} | 443/TCP | HTTPS | TLS 1.2+ | Edge | External |

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| External S3 | 443/TCP | HTTPS | TLS 1.2+ | AWS IAM | Pipeline artifact storage (when using external S3) |
| External MariaDB | 3306/TCP | MySQL | TLS 1.2+ | Password | Pipeline metadata storage (when using external DB) |
| Container Registry | 443/TCP | HTTPS | TLS 1.2+ | Pull Secret | Pull workflow executor images |

## Security

### RBAC - Cluster Roles

| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|
| manager-role | "" | configmaps, secrets, serviceaccounts | create, delete, get, list, patch, update, watch |
| manager-role | "" | services, persistentvolumeclaims, persistentvolumes | create, delete, get, list, patch, update, watch |
| manager-role | "" | pods, pods/exec, pods/log | all |
| manager-role | apps, extensions | deployments, replicasets | all |
| manager-role | datasciencepipelinesapplications.opendatahub.io | datasciencepipelinesapplications | all |
| manager-role | argoproj.io | workflows, workflowtemplates, cronworkflows | all |
| manager-role | pipelines.kubeflow.org | pipelines, pipelineversions | all |
| manager-role | scheduledworkflow.kubeflow.org | scheduledworkflows | all |
| manager-role | route.openshift.io | routes | create, delete, get, list, patch, update, watch |
| manager-role | admissionregistration.k8s.io | mutatingwebhookconfigurations, validatingwebhookconfigurations | create, delete, get, list, patch, update, watch |
| argo-cluster-role | "" | pods, pods/exec | create, get, list, watch, update, patch, delete |
| argo-cluster-role | "" | configmaps | get, watch, list |
| argo-cluster-role | argoproj.io | workflows, workflowtemplates | get, list, watch, update, patch, delete, create |

### RBAC - Role Bindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| manager-rolebinding | datasciencepipelinesapplications-controller | manager-role | controller-manager |
| leader-election-rolebinding | datasciencepipelinesapplications-controller | leader-election-role | controller-manager |
| ds-pipeline-argo-binding | {dspa-namespace} | argo-cluster-role | ds-pipeline-argo |

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| ds-pipeline-db-{name} | Opaque | MariaDB connection credentials | DSPO | No |
| ds-pipeline-s3-{name} | Opaque | S3/Minio access credentials | DSPO | No |
| ds-pipeline-tls | kubernetes.io/tls | API server TLS certificates | cert-manager | Yes |
| webhook-server-cert | kubernetes.io/tls | Webhook server TLS certificates | cert-manager | Yes |

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| /apis/v2beta1/* | All | Bearer Token (K8s SA token) | API Server | Kubernetes RBAC |
| ML Metadata gRPC | All | mTLS client certificates | Envoy Proxy | Certificate validation |
| MariaDB | All | Username/Password | MariaDB Server | Database auth |
| Minio | All | Access Key/Secret Key | Minio Server | IAM-style auth |

## Data Flows

### Flow 1: Pipeline Submission

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User/SDK | ds-pipeline-api-server | 8888/TCP | HTTPS | TLS 1.2+ | Bearer Token |
| 2 | API Server | MariaDB | 3306/TCP | MySQL | TLS 1.2+ | Password |
| 3 | API Server | Argo Workflow Controller | 8080/TCP | HTTP | None | ServiceAccount |
| 4 | Workflow Controller | Kubernetes API | 6443/TCP | HTTPS | TLS 1.3 | ServiceAccount |

### Flow 2: Workflow Execution

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Argo Workflow Controller | Kubernetes API (Pod create) | 6443/TCP | HTTPS | TLS 1.3 | ServiceAccount |
| 2 | Pipeline Step Pod | Minio | 9000/TCP | HTTP | TLS 1.2+ | Access Key |
| 3 | Pipeline Step Pod | ML Metadata Envoy | 9090/TCP | gRPC | mTLS | Client Cert |
| 4 | Persistence Agent | MariaDB | 3306/TCP | MySQL | TLS 1.2+ | Password |

### Flow 3: Artifact Storage

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Pipeline Step Pod | Minio/S3 | 9000/TCP or 443/TCP | HTTP or HTTPS | TLS 1.2+ | Access Key |
| 2 | API Server | Minio/S3 (signed URL generation) | 9000/TCP or 443/TCP | HTTP or HTTPS | TLS 1.2+ | Access Key |
| 3 | User | Minio/S3 (artifact download via signed URL) | 9000/TCP or 443/TCP | HTTPS | TLS 1.2+ | Signed URL |

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| Argo Workflows | CRD | N/A | N/A | N/A | Workflow execution engine |
| Kubernetes API | REST API | 6443/TCP | HTTPS | TLS 1.3 | Pod/resource management |
| MariaDB | MySQL | 3306/TCP | MySQL | TLS 1.2+ | Metadata persistence |
| Minio/S3 | S3 API | 9000/TCP or 443/TCP | HTTPS | TLS 1.2+ | Artifact storage |
| ML Metadata | gRPC | 8080/TCP | gRPC | mTLS | Lineage tracking |
| ODH Dashboard | UI Embedding | 443/TCP | HTTPS | TLS 1.2+ | Pipeline UI integration |

## Recent Changes

| Version | Date | Changes |
|---------|------|---------|
| 0.0.1 | 2025-03 | - Upgrade to Go 1.25.7<br>- Add ResourceTTL field to DSPAs<br>- Add METADATA_SERVICE_NAME value to API server<br>- Support for non-FIPS local builds on Apple Silicon<br>- Enable CI workflows for versioned branches<br>- Update TLS env vars configuration<br>- Remove hardcoded secrets from configs |
