# Component: Data Science Pipelines Operator

## Metadata
- **Repository**: https://github.com/red-hat-data-services/data-science-pipelines-operator.git
- **Version**: 0.0.1 (rhoai-3.0 branch)
- **Distribution**: RHOAI
- **Languages**: Go 1.21
- **Deployment Type**: Kubernetes Operator
- **Based on**: Kubeflow Pipelines 2.5.0

## Purpose
**Short**: Manages lifecycle of Data Science Pipelines instances on OpenShift/Kubernetes clusters.

**Detailed**: The Data Science Pipelines Operator (DSPO) is a Kubernetes operator that manages the deployment and lifecycle of Data Science Pipeline (DSP) instances based on Kubeflow Pipelines. It allows data scientists to create ML workflows for data preparation, model training, model validation, and experiment tracking. The operator deploys namespace-scoped pipeline infrastructure including API servers, persistence agents, workflow controllers, and optional components like MariaDB databases and Minio object storage. DSPO is designed for multi-tenant environments where each namespace can have its own isolated DSP instance. It integrates with Argo Workflows for pipeline execution orchestration and provides ML Metadata (MLMD) for artifact lineage tracking. The operator handles automatic TLS certificate generation, network policies, RBAC, and service mesh integration for secure pod-to-pod communication.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| DSPO Controller | Operator | Reconciles DataSciencePipelinesApplication CRs and manages component lifecycle |
| DSP API Server | REST/gRPC Service | Provides KFP v2 API for pipeline management, runs, and artifacts |
| Persistence Agent | Workflow Monitor | Syncs workflow state to database for pipeline run persistence |
| Scheduled Workflow | Cron Controller | Manages scheduled and recurring pipeline runs |
| Workflow Controller | Argo Controller | Namespace-scoped Argo Workflows controller for pipeline execution |
| MariaDB | Database (Optional) | Stores pipeline metadata, runs, and experiment tracking data |
| Minio | Object Storage (Optional) | Stores pipeline artifacts and intermediate data (dev/test only) |
| ML Metadata (MLMD) | Lineage Service (Optional) | Tracks artifact lineage and metadata using gRPC |
| MLMD Envoy | Proxy (Optional) | Envoy proxy for MLMD service |

## APIs Exposed

### Custom Resource Definitions (CRDs)

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| datasciencepipelinesapplications.opendatahub.io | v1 | DataSciencePipelinesApplication | Namespaced | Main CR to configure and deploy a DSP instance |
| argoproj.io | v1alpha1 | Workflow | Namespaced | Argo Workflows for pipeline execution |
| argoproj.io | v1alpha1 | WorkflowTemplate | Namespaced | Reusable workflow templates |
| argoproj.io | v1alpha1 | CronWorkflow | Namespaced | Scheduled workflow definitions |
| argoproj.io | v1alpha1 | ClusterWorkflowTemplate | Cluster | Cluster-scoped workflow templates |
| argoproj.io | v1alpha1 | WorkflowArtifactGCTask | Namespaced | Garbage collection tasks for workflow artifacts |
| argoproj.io | v1alpha1 | WorkflowEventBinding | Namespaced | Event-driven workflow triggers |
| argoproj.io | v1alpha1 | WorkflowTaskResult | Namespaced | Task execution results |
| argoproj.io | v1alpha1 | WorkflowTaskSet | Namespaced | Sets of workflow tasks |
| pipelines.kubeflow.org | v1 | Pipeline | Namespaced | Pipeline definitions (when pipelineStore=kubernetes) |
| pipelines.kubeflow.org | v1 | PipelineVersion | Namespaced | Pipeline version definitions (when pipelineStore=kubernetes) |
| kubeflow.org | scheduledworkflows/v1beta1 | ScheduledWorkflow | Namespaced | Legacy scheduled workflow CRD |

### HTTP Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /apis/v2beta1/* | GET/POST/DELETE | 8888/TCP | HTTP | TLS (pod-to-pod) | Bearer Token | KFP v2 API for pipeline operations |
| /apis/v2beta1/artifacts/* | GET | 8888/TCP | HTTP | TLS (pod-to-pod) | Bearer Token | Artifact download with signed URLs |
| /apis/v2beta1/pipelines | GET/POST | 8888/TCP | HTTP | TLS (pod-to-pod) | Bearer Token | Pipeline CRUD operations |
| /apis/v2beta1/runs | GET/POST | 8888/TCP | HTTP | TLS (pod-to-pod) | Bearer Token | Pipeline run management |
| /apis/v2beta1/experiments | GET/POST | 8888/TCP | HTTP | TLS (pod-to-pod) | Bearer Token | Experiment tracking |
| /healthz | GET | 8081/TCP | HTTP | None | None | Operator liveness probe |
| /readyz | GET | 8081/TCP | HTTP | None | None | Operator readiness probe |
| /metrics | GET | 8080/TCP | HTTP | None | None | Operator Prometheus metrics |
| /* (External Route) | ALL | 443/TCP | HTTPS | TLS 1.2+ | OAuth Proxy | External access via OpenShift Route |

### gRPC Services

| Service | Port | Protocol | Encryption | Auth | Purpose |
|---------|------|----------|------------|------|---------|
| DSP API Server | 8887/TCP | gRPC | TLS (pod-to-pod) | mTLS | Internal gRPC API for pipeline operations |
| MLMD gRPC | 8080/TCP | gRPC | TLS (pod-to-pod) | mTLS | ML Metadata artifact lineage service |

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| OpenShift / Kubernetes | 4.11+ | Yes | Container orchestration platform |
| Argo Workflows | v3.4+ | Yes | Workflow execution engine (deployed by operator) |
| MariaDB | 10.3 | No | Metadata database (can use external DB) |
| S3-compatible Object Storage | - | Yes | Artifact storage (Minio or external S3) |
| Kubeflow Pipelines SDK | 2.x | No | Client SDK for pipeline authoring |
| OpenShift Pipelines (Tekton) | 1.8+ | No | For DSPv1 only (legacy) |

### Internal ODH/RHOAI Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| ODH/RHOAI Dashboard | UI Integration | Provides web interface for pipeline management |
| ODH Operator / DataScienceCluster | CR Management | Deploys and manages DSPO via DSC CR |
| KServe | API Calls | Pipeline integration for model serving deployments |
| Workbenches (Notebooks) | Network Access | Data scientists access DSP API from notebooks |
| Service Mesh (Istio) | Network/mTLS | Optional service mesh integration |
| OpenShift Monitoring | ServiceMonitor | Metrics collection for pipelines and operator |

## Network Architecture

### Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| ds-pipeline-{name} | ClusterIP | 8888/TCP | 8888 | HTTP | TLS (pod-to-pod) | Bearer Token | Internal |
| ds-pipeline-{name} | ClusterIP | 8887/TCP | 8887 | gRPC | TLS (pod-to-pod) | mTLS | Internal |
| ds-pipeline-{name} | ClusterIP | 8443/TCP | proxy | HTTPS | TLS 1.2+ | OAuth Proxy | Internal/External |
| mariadb-{name} | ClusterIP | 3306/TCP | 3306 | MySQL | TLS (pod-to-pod) | Password | Internal |
| minio-{name} | ClusterIP | 9000/TCP | 9000 | HTTP | None | S3 Credentials | Internal |
| minio-{name} | ClusterIP | 80/TCP | 9000 | HTTP | None | S3 Credentials | Internal |
| ds-pipeline-metadata-grpc-{name} | ClusterIP | 8080/TCP | 8080 | gRPC | TLS (pod-to-pod) | mTLS | Internal |
| ds-pipeline-metadata-envoy-{name} | ClusterIP | 9090/TCP | 9090 | HTTP | TLS (pod-to-pod) | None | Internal |
| ds-pipeline-workflow-controller-metrics-{name} | ClusterIP | 9090/TCP | 9090 | HTTP | None | None | Internal |
| controller-manager-service | ClusterIP | 8080/TCP | 8080 | HTTP | None | None | Internal |

### Ingress

| Name | Type | Hosts | Port | Protocol | Encryption | TLS Mode | Exposure |
|------|------|-------|------|----------|------------|----------|----------|
| ds-pipeline-{name} | OpenShift Route | *.apps.cluster.domain | 443/TCP | HTTPS | TLS 1.2+ | Reencrypt | External |

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| External S3 (e.g., AWS S3) | 443/TCP | HTTPS | TLS 1.2+ | AWS IAM/S3 Credentials | Pipeline artifact storage |
| External Database | 3306/TCP or 5432/TCP | MySQL/PostgreSQL | TLS 1.2+ | DB Credentials | Pipeline metadata storage |
| Container Registries | 443/TCP | HTTPS | TLS 1.2+ | Pull Secrets | Pull pipeline component images |
| OpenShift API Server | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token | Create/manage workflow pods |

## Security

### RBAC - Cluster Roles

| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|
| manager-role | datasciencepipelinesapplications.opendatahub.io | datasciencepipelinesapplications, datasciencepipelinesapplications/status, datasciencepipelinesapplications/finalizers | create, delete, get, list, patch, update, watch |
| manager-role | argoproj.io | workflows, workflowartifactgctasks, workflowtaskresults | create, delete, get, list, patch, update, watch |
| manager-role | pipelines.kubeflow.org | pipelines, pipelineversions | create, delete, get, list, patch, update, watch |
| manager-role | "" | pods, pods/exec, pods/log | get, list, watch, create, delete |
| manager-role | "" | configmaps, secrets, serviceaccounts, services, persistentvolumeclaims | create, delete, get, list, patch, update, watch |
| manager-role | apps | deployments, replicasets | create, delete, get, list, patch, update, watch |
| manager-role | rbac.authorization.k8s.io | roles, rolebindings, clusterroles, clusterrolebindings | create, delete, get, list, patch, update, watch |
| manager-role | route.openshift.io | routes | create, delete, get, list, patch, update, watch |
| manager-role | networking.k8s.io | networkpolicies | create, delete, get, list, patch, update, watch |
| manager-role | batch | jobs | create, delete, get, list, patch, update, watch |
| manager-role | serving.kserve.io | inferenceservices | create, delete, get, list, patch |
| manager-role | ray.io | rayclusters, rayjobs, rayservices | create, delete, get, list, patch |
| manager-role | admissionregistration.k8s.io | validatingwebhookconfigurations, mutatingwebhookconfigurations | create, delete, get, list, patch, update, watch |
| ds-pipeline-{name} | argoproj.io | workflows, workflowtemplates | create, get, list, watch, update, patch, delete |
| pipeline-runner-{name} | "" | pods, pods/log | create, get, list, watch, patch, delete |
| pipeline-runner-{name} | "" | configmaps, secrets, persistentvolumeclaims, services | create, get, list, delete |
| argo-aggregate-to-admin | argoproj.io | workflows, workflowtemplates, cronworkflows, clusterworkflowtemplates | create, delete, deletecollection, get, list, patch, update, watch |
| argo-aggregate-to-edit | argoproj.io | workflows, workflowtemplates, cronworkflows | create, delete, deletecollection, get, list, patch, update, watch |
| argo-aggregate-to-view | argoproj.io | workflows, workflowtemplates, cronworkflows, clusterworkflowtemplates | get, list, watch |

### RBAC - Role Bindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| manager-rolebinding | {dspo-namespace} | manager-role | controller-manager |
| leader-election-rolebinding | {dspo-namespace} | leader-election-role | controller-manager |
| ds-pipeline-{name}-binding | {dspa-namespace} | ds-pipeline-{name} | ds-pipeline-{name} |
| pipeline-runner-{name}-binding | {dspa-namespace} | pipeline-runner-{name} | pipeline-runner-{name} |
| ds-pipeline-argo-binding | {dspa-namespace} | ds-pipeline-argo-cluster-role | ds-pipeline-argo-{name} |

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| ds-pipelines-proxy-tls-{name} | kubernetes.io/tls | OAuth proxy TLS certificate | service.beta.openshift.io/serving-cert | Yes |
| ds-pipelines-mariadb-tls-{name} | kubernetes.io/tls | MariaDB pod-to-pod TLS | service.beta.openshift.io/serving-cert | Yes |
| ds-pipeline-metadata-grpc-tls-certs-{name} | kubernetes.io/tls | MLMD gRPC TLS certificate | service.beta.openshift.io/serving-cert | Yes |
| {db-credentials-secret} | Opaque | Database username/password | User or DSPO | No |
| {storage-credentials-secret} | Opaque | S3 access key and secret key | User or DSPO | No |

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| /apis/v2beta1/* (external) | ALL | Bearer Token (OAuth) | OAuth Proxy (port 8443) | OpenShift RBAC + DSPA namespace access |
| /apis/v2beta1/* (internal) | ALL | Bearer Token (ServiceAccount) | DSP API Server | Kubernetes RBAC based on ServiceAccount |
| gRPC API (8887) | ALL | mTLS (pod-to-pod) | Service Mesh / NetworkPolicy | Pod label selectors |
| MariaDB (3306) | ALL | MySQL Password + mTLS | MariaDB + NetworkPolicy | Credentials from Secret |
| MLMD gRPC (8080) | ALL | mTLS (pod-to-pod) | NetworkPolicy | Pod label selectors |
| Minio (9000) | ALL | S3 Credentials | Minio Server | Access key from Secret |

### Network Policies

| Policy Name | Applies To | Ingress Rules | Egress Rules |
|-------------|------------|---------------|--------------|
| ds-pipelines-{name} | API Server pods | Port 8443/TCP from all; Ports 8888,8887/TCP from monitoring, DSPA components, workbenches, pipeline pods | Not restricted |
| mariadb-{name} | MariaDB pods | Port 3306/TCP from DSPO operator, API Server, MLMD gRPC only | Not restricted |
| ds-pipeline-metadata-grpc-{name} | MLMD gRPC pods | Port 8080/TCP from API Server, MLMD Envoy only | Not restricted |
| mlmd-envoy-dashboard-access | MLMD Envoy pods | From dashboard namespace pods | Not restricted |

## Data Flows

### Flow 1: Pipeline Submission via Dashboard

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User Browser | OpenShift Route | 443/TCP | HTTPS | TLS 1.2+ | OAuth Token |
| 2 | OpenShift Route | OAuth Proxy (API Server Pod) | 8443/TCP | HTTPS | TLS 1.2+ (Reencrypt) | OAuth Proxy |
| 3 | OAuth Proxy | DSP API Server | 8888/TCP | HTTP | TLS (pod-to-pod) | Bearer Token |
| 4 | DSP API Server | MariaDB | 3306/TCP | MySQL | TLS (pod-to-pod) | DB Password |
| 5 | DSP API Server | Workflow Controller | 8001/TCP | HTTP | TLS (pod-to-pod) | ServiceAccount Token |
| 6 | Workflow Controller | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |

### Flow 2: Pipeline Execution

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Workflow Controller | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 2 | Pipeline Pod | DSP API Server | 8888/TCP | HTTP | TLS (pod-to-pod) | ServiceAccount Token |
| 3 | Pipeline Pod | Object Storage (S3) | 443/TCP | HTTPS | TLS 1.2+ | S3 Credentials |
| 4 | Pipeline Pod | MLMD gRPC | 8080/TCP | gRPC | TLS (pod-to-pod) | mTLS |
| 5 | Persistence Agent | DSP API Server | 8887/TCP | gRPC | TLS (pod-to-pod) | ServiceAccount Token |
| 6 | Persistence Agent | MariaDB | 3306/TCP | MySQL | TLS (pod-to-pod) | DB Password |

### Flow 3: Artifact Lineage Tracking

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Pipeline Pod | MLMD Envoy | 9090/TCP | HTTP | TLS (pod-to-pod) | None |
| 2 | MLMD Envoy | MLMD gRPC | 8080/TCP | gRPC | TLS (pod-to-pod) | mTLS |
| 3 | MLMD gRPC | MariaDB | 3306/TCP | MySQL | TLS (pod-to-pod) | DB Password |

### Flow 4: Scheduled Pipeline Execution

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Scheduled Workflow Controller | DSP API Server | 8887/TCP | gRPC | TLS (pod-to-pod) | ServiceAccount Token |
| 2 | DSP API Server | Workflow Controller | 8001/TCP | HTTP | TLS (pod-to-pod) | ServiceAccount Token |
| 3 | Workflow Controller | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| OpenShift API Server | REST API | 6443/TCP | HTTPS | TLS 1.2+ | Create/manage Workflows, Pods, Services |
| Argo Workflows | Workflow CRDs | N/A | N/A | N/A | Pipeline execution orchestration |
| KServe | REST API | 8080/TCP or 443/TCP | HTTP/HTTPS | TLS 1.2+ | Deploy inference services from pipelines |
| Ray Clusters | REST API | 8265/TCP | HTTP | TLS 1.2+ | Distributed compute for pipeline tasks |
| ODH Dashboard | REST API | 8888/TCP via Route | HTTPS | TLS 1.2+ | UI for pipeline management |
| Workbenches (Notebooks) | REST/gRPC API | 8888/TCP, 8887/TCP | HTTP/gRPC | TLS (pod-to-pod) | Submit pipelines from notebooks |
| Prometheus | ServiceMonitor | 8080/TCP, 9090/TCP | HTTP | None | Metrics collection for monitoring |
| External Object Storage (S3) | S3 API | 443/TCP | HTTPS | TLS 1.2+ | Store pipeline artifacts |
| External Database | MySQL/PostgreSQL | 3306/TCP or 5432/TCP | MySQL/PostgreSQL | TLS 1.2+ | Pipeline metadata persistence |
| Service Mesh (Istio) | Sidecar Injection | N/A | N/A | mTLS | Pod-to-pod encryption and traffic management |

## Deployment Architecture

### Operator Deployment
- **Namespace**: Typically `redhat-ods-applications` or custom
- **Replicas**: 1 (leader election enabled)
- **Resource Requests**: 200m CPU, 400Mi Memory
- **Resource Limits**: 1 CPU, 4Gi Memory
- **Health Checks**: /healthz (liveness), /readyz (readiness)
- **Configuration**: ConfigMap `dspo-config` with image references

### DSPA Instance Deployment (per namespace)
When a DataSciencePipelinesApplication CR is created, the operator deploys:

1. **Namespace-scoped Argo Workflows Controller**
   - Manages workflow execution for pipeline runs
   - ServiceAccount: ds-pipeline-argo-{name}

2. **DSP API Server**
   - Deployment with 1+ replicas
   - Ports: 8888 (HTTP), 8887 (gRPC), 8443 (OAuth proxy)
   - ServiceAccount: ds-pipeline-{name}

3. **Persistence Agent**
   - Deployment with 1 replica
   - Syncs workflow state to database
   - Configurable worker count (default: 2)

4. **Scheduled Workflow Controller**
   - Deployment with 1 replica
   - Manages cron-scheduled pipelines

5. **Optional: MariaDB**
   - StatefulSet with 1 replica
   - PVC for data persistence
   - Port: 3306

6. **Optional: Minio**
   - Deployment with 1 replica
   - PVC for data persistence
   - Ports: 9000, 80

7. **Optional: ML Metadata (MLMD)**
   - MLMD gRPC server deployment
   - MLMD Envoy proxy deployment
   - Ports: 8080 (gRPC), 9090 (Envoy)

## Configuration Options

### Database Configuration
- **Default**: MariaDB deployed by operator
- **External DB**: MySQL/MariaDB/PostgreSQL with credentials in Secret
- **Connection**: Host, port, database name, username/password

### Object Storage Configuration
- **Default**: Minio (dev/test only, not supported for production)
- **External Storage**: S3-compatible storage (AWS S3, Ceph, etc.)
- **Connection**: Endpoint, bucket, region, access key/secret key, TLS settings

### Pod-to-Pod TLS
- **Default**: Enabled (`podToPodTLS: true`)
- **Certificate Management**: OpenShift service-serving certificates
- **Rotation**: Automatic certificate rotation

### Custom CA Bundles
- **Support**: Custom CA certificates for external storage/DB
- **Configuration**: ConfigMap with PEM-encoded CA bundle
- **Injection**: Mounted into API server and pipeline executor pods

## Metrics

The operator exposes custom metrics for monitoring DSPA status:

| Metric Name | Type | Labels | Description |
|-------------|------|--------|-------------|
| data_science_pipelines_application_apiserver_ready | Gauge | dspa_name, namespace | API Server readiness (1=Ready, 0=Not Ready) |
| data_science_pipelines_application_persistenceagent_ready | Gauge | dspa_name, namespace | Persistence Agent readiness (1=Ready, 0=Not Ready) |
| data_science_pipelines_application_scheduledworkflow_ready | Gauge | dspa_name, namespace | Scheduled Workflow readiness (1=Ready, 0=Not Ready) |
| data_science_pipelines_application_ready | Gauge | dspa_name, namespace | Overall DSPA readiness (1=Ready, 0=Not Ready) |

ServiceMonitors are created for:
- DSPO operator metrics (port 8080)
- Workflow controller metrics (port 9090)
- DSP API Server metrics (port 8888)

## Recent Changes

| Commit | Date | Changes |
|--------|------|---------|
| bf550ea | 2026-03-15 | - Update UBI minimal base image digest to 759f5f4<br>- Dependency update for security patches |
| d46e68b | 2026-03-14 | - Update UBI minimal base image digest to ecd4751<br>- Container image security update |
| 7c5460f | 2026-03-13 | - Update UBI minimal base image digest to bb08f23<br>- Base image security maintenance |
| e5f76ad | 2026-03-12 | - Update UBI minimal base image digest to 90bd85d<br>- Container runtime security update |
| 2122977 | 2026-03-11 | - Update Konflux build references<br>- CI/CD pipeline maintenance |
| 0182ee6 | 2026-03-10 | - Update Konflux build references<br>- Build system updates |
| 08902d4 | 2026-03-09 | - Update Konflux build references<br>- Continuous integration updates |
| 1e1144d | 2026-03-08 | - Update Konflux build references<br>- Build infrastructure maintenance |
| d4f2ca3 | 2026-03-07 | - Update Konflux build references<br>- CI system updates |
| 1d12344 | 2026-03-06 | - Update Konflux build references<br>- Build pipeline maintenance |

## Notes

- **Multi-tenancy**: Each namespace can have its own DSPA instance with isolated resources
- **Pipeline Execution**: Uses Argo Workflows (v3.4+) instead of legacy Tekton (DSPv1)
- **Production Deployment**: Always use external object storage (S3) and database; Minio is for dev/test only
- **TLS Everywhere**: Pod-to-pod TLS is enabled by default using OpenShift service-serving certificates
- **FIPS Compliance**: Built with FIPS-enabled Go runtime (GOEXPERIMENT=strictfipsruntime)
- **Konflux Build**: Container images built entirely through Red Hat Konflux CI/CD system
- **Health Checks**: Database and object storage connectivity validated before component deployment
- **Artifact Storage**: Pipeline artifacts stored in object storage; metadata in relational database
- **Workspace Support**: Ephemeral shared PVC storage for large intermediate data between pipeline steps
- **Caching**: Pipeline step caching configurable (enabled by default)
- **Pipeline Storage**: Supports both database storage and Kubernetes CRD storage for pipeline definitions
