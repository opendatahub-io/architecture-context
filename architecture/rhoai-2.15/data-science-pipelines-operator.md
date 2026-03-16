# Component: Data Science Pipelines Operator

## Metadata
- **Repository**: https://github.com/red-hat-data-services/data-science-pipelines-operator.git
- **Version**: 8330c1e (rhoai-2.15 branch)
- **Distribution**: RHOAI (also supports ODH)
- **Languages**: Go
- **Deployment Type**: Kubernetes Operator (Namespace-scoped pipeline deployments)

## Purpose
**Short**: Manages lifecycle of Data Science Pipelines instances for ML workflow orchestration and experiment tracking.

**Detailed**: The Data Science Pipelines Operator (DSPO) is a Kubernetes operator that deploys and manages single-namespace scoped Data Science Pipeline stacks on OpenShift/Kubernetes clusters. Based on upstream Kubeflow Pipelines (KFP), it enables data scientists to create reproducible ML workflows for data preparation, model training, validation, and experimentation. The operator reconciles DataSciencePipelinesApplication (DSPA) custom resources and deploys all necessary components including API servers, persistence agents, workflow controllers (Argo-based for v2, Tekton for v1), and optional UI/metadata services. It supports both v1 (Tekton-based) and v2 (Argo Workflows-based) execution backends, with v2 being the recommended version for new deployments. DSPO manages database connections (MariaDB or external), object storage (Minio or external S3-compatible), and provides OAuth-secured REST/gRPC APIs for pipeline submission and management.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| DSPO Controller | Go Operator | Reconciles DSPA CRs and manages lifecycle of all DSP components |
| API Server | Deployment | REST/gRPC server for pipeline submission, run management, and artifact retrieval |
| Persistence Agent | Deployment | Syncs workflow execution status to database for tracking and recovery |
| Scheduled Workflow Controller | Deployment | Manages scheduled/recurring pipeline runs with cron support |
| Workflow Controller | Deployment | Argo Workflows controller for v2 pipeline orchestration (namespace-scoped) |
| MariaDB | StatefulSet (optional) | Metadata database for pipelines, runs, experiments, artifacts |
| Minio | Deployment (optional) | S3-compatible object storage for pipeline artifacts (dev/test only) |
| ML Pipelines UI | Deployment (optional) | Web UI for viewing pipelines and runs (upstream KFP UI, unsupported) |
| MLMD Envoy Proxy | Deployment (optional) | OAuth2 proxy and load balancer for ML Metadata gRPC service |
| MLMD gRPC Server | Deployment (optional) | ML Metadata lineage and artifact tracking service |

## APIs Exposed

### Custom Resource Definitions (CRDs)

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| datasciencepipelinesapplications.opendatahub.io | v1alpha1 | DataSciencePipelinesApplication | Namespaced | Defines DSP stack configuration including components, database, storage |
| argoproj.io | v1alpha1 | Workflow | Namespaced | Argo workflow execution (managed by workflow controller, v2 only) |
| argoproj.io | v1alpha1 | CronWorkflow | Namespaced | Scheduled Argo workflows (v2 only) |
| argoproj.io | v1alpha1 | WorkflowTemplate | Namespaced | Reusable workflow templates (v2 only) |
| argoproj.io | v1alpha1 | ClusterWorkflowTemplate | Cluster | Cluster-scoped workflow templates (v2 only) |

### HTTP Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /apis/v2beta1/* | GET, POST, DELETE | 8443/TCP | HTTPS | TLS 1.2+ (Reencrypt) | OAuth2 Bearer Token | KFP v2 API - pipeline/run management |
| /apis/v1beta1/* | GET, POST, DELETE | 8443/TCP | HTTPS | TLS 1.2+ (Reencrypt) | OAuth2 Bearer Token | KFP v1 API - legacy compatibility |
| /artifacts/{id} | GET | 8443/TCP | HTTPS | TLS 1.2+ (Reencrypt) | OAuth2 Bearer Token | Artifact download with signed URLs |
| /healthz | GET | 8081/TCP | HTTP | None | None | DSPO controller health check |
| /readyz | GET | 8081/TCP | HTTP | None | None | DSPO controller readiness check |
| /metrics | GET | 8080/TCP | HTTP | None | None | DSPO controller Prometheus metrics |

### gRPC Services

| Service | Port | Protocol | Encryption | Auth | Purpose |
|---------|------|----------|------------|------|---------|
| ml_metadata.MetadataStoreService | 9090/TCP | gRPC/HTTP2 | TLS 1.2+ (mTLS optional) | OAuth2 (via Envoy) | ML Metadata lineage and artifact tracking |
| api.PipelineService | 8887/TCP | gRPC | TLS 1.3 (pod-to-pod) or plaintext | Service mesh mTLS or None | Internal pipeline service API |
| ml_metadata.MetadataStoreService (internal) | 8080/TCP | gRPC | TLS 1.3 (pod-to-pod) or plaintext | Service mesh mTLS or None | Direct MLMD gRPC (internal only) |

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| OpenShift/Kubernetes | 4.11+ | Yes | Container orchestration platform |
| Object Storage (S3-compatible) | N/A | Yes | Pipeline artifact storage (Minio for dev, external S3 for prod) |
| MySQL-compatible Database | 5.7+ | Yes | Pipeline metadata (MariaDB 10.3+ for dev, external MySQL for prod) |
| OpenShift Pipelines (Tekton) | 1.8+ | v1 only | Workflow execution backend for DSP v1 |
| Argo Workflows | 3.4.17 | v2 only | Workflow execution backend for DSP v2 (deployed by DSPO) |
| OAuth Proxy | v4.12+ | Optional | OAuth2 authentication for external routes |

### Internal ODH/RHOAI Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| ODH Dashboard | UI Integration | Displays pipeline UIs and manages DSPA lifecycle |
| DataScienceCluster | CRD (datasciencecluster.opendatahub.io) | Manages DSPO installation via ODH operator |
| Service Mesh (Istio) | Network | mTLS for pod-to-pod encryption when podToPodTLS enabled |
| Prometheus | Metrics scraping | Monitors DSPO and DSPA component health |

## Network Architecture

### Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| ds-pipeline-{name} | ClusterIP | 8443/TCP | oauth | HTTPS | TLS (service cert) | OAuth2 Proxy | Internal/External (via Route) |
| ds-pipeline-{name} | ClusterIP | 8888/TCP | http | HTTP | TLS 1.3 or None (podToPodTLS) | None | Internal |
| ds-pipeline-{name} | ClusterIP | 8887/TCP | 8887 | gRPC | TLS 1.3 or None (podToPodTLS) | None | Internal |
| mariadb-{name} | ClusterIP | 3306/TCP | 3306 | MySQL | TLS 1.2+ or None (podToPodTLS) | Username/Password | Internal |
| minio-{name} | ClusterIP | 9000/TCP | 9000 | HTTP | None | S3 Access Key | Internal |
| minio-{name} | ClusterIP | 80/TCP | 9000 | HTTP | None | S3 Access Key | Internal (KFP UI workaround) |
| ds-pipeline-md-{name} | ClusterIP | 9090/TCP | md-envoy | gRPC/HTTP2 | TLS 1.2+ | OAuth2 (Envoy) | Internal/External (via Route) |
| ds-pipeline-md-{name} | ClusterIP | 8443/TCP | oauth2-proxy | HTTPS | TLS (service cert) | OAuth2 Proxy | Internal/External (via Route) |
| ds-pipeline-metadata-grpc-{name} | ClusterIP | 8080/TCP | 8080 | gRPC | TLS 1.3 or None (podToPodTLS) | None | Internal |
| controller-manager (DSPO) | ClusterIP | 8080/TCP | 8080 | HTTP | None | None | Internal (metrics) |

### Ingress

| Name | Type | Hosts | Port | Protocol | Encryption | TLS Mode | Exposure |
|------|------|-------|------|----------|------------|----------|----------|
| ds-pipeline-{name} | OpenShift Route | {generated}.{cluster-domain} | 8443/TCP | HTTPS | TLS 1.2+ | Reencrypt | External |
| ds-pipeline-md-{name} | OpenShift Route | {generated}.{cluster-domain} | 8443/TCP | HTTPS | TLS 1.2+ | Reencrypt | External |
| ds-pipeline-ui-{name} | OpenShift Route (optional) | {generated}.{cluster-domain} | 8443/TCP | HTTPS | TLS 1.2+ | Reencrypt | External |
| minio-{name} | OpenShift Route (optional) | {generated}.{cluster-domain} | 9000/TCP | HTTPS | TLS 1.2+ | Edge | External |

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| External S3 (AWS/Cloud) | 443/TCP | HTTPS | TLS 1.2+ | AWS IAM/Access Keys | Pipeline artifact storage |
| External MySQL/PostgreSQL | 3306/TCP or 5432/TCP | MySQL/PostgreSQL | TLS 1.2+ or None | Username/Password | Pipeline metadata storage |
| Container Registry | 443/TCP | HTTPS | TLS 1.2+ | Pull Secrets | Fetch container images for pipeline tasks |
| OpenShift API | 6443/TCP | HTTPS | TLS 1.2+ | Service Account Token | Create/manage workflow resources |

## Security

### RBAC - Cluster Roles

| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|
| manager-role | datasciencepipelinesapplications.opendatahub.io | datasciencepipelinesapplications, datasciencepipelinesapplications/status, datasciencepipelinesapplications/finalizers | create, delete, get, list, patch, update, watch |
| manager-role | argoproj.io | workflows, workflowartifactgctasks, workflowtaskresults | * (all) |
| manager-role | tekton.dev | * | * (all, v1 only) |
| manager-role | apps, "" | deployments, services | create, delete, get, list, patch, update, watch |
| manager-role | "" | configmaps, secrets, serviceaccounts, persistentvolumeclaims, pods, pods/log, events | create, delete, get, list, patch, update, watch |
| manager-role | rbac.authorization.k8s.io | roles, rolebindings, clusterroles, clusterrolebindings | create, delete, get, list, patch, update, watch |
| manager-role | route.openshift.io | routes | create, delete, get, list, patch, update, watch |
| manager-role | networking.k8s.io | networkpolicies | create, delete, get, list, patch, update, watch |
| manager-role | monitoring.coreos.com | servicemonitors | create, delete, get, list, patch, update, watch |
| manager-role | batch | jobs | * (all) |
| manager-role | kubeflow.org | * | * (all) |
| manager-role | ray.io | rayclusters, rayjobs, rayservices | create, delete, get, list, patch |
| ds-pipeline | "" | pods, pods/log, configmaps, secrets, services | get, list, watch, create, delete |
| ds-pipeline | apps | deployments | get, list, watch |
| ds-pipeline | argoproj.io | workflows | get, list, watch, create, update, patch, delete |
| pipeline-runner | "" | pods, pods/log, secrets (list only) | get, list, watch, create, delete |
| pipeline-runner | argoproj.io | workflows, workflowtemplates | get, list, watch, create, update, patch, delete |

### RBAC - Role Bindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| manager-rolebinding | {dspo-namespace} | manager-role (ClusterRole) | controller-manager |
| ds-pipeline-{name} | {dspa-namespace} | ds-pipeline (Role) | ds-pipeline-{name} |
| pipeline-runner-{name} | {dspa-namespace} | pipeline-runner (Role) | pipeline-runner-{name} |
| ds-pipeline-persistenceagent-{name} | {dspa-namespace} | ds-pipeline-persistenceagent (Role) | ds-pipeline-persistenceagent-{name} |
| ds-pipeline-scheduledworkflow-{name} | {dspa-namespace} | ds-pipeline-scheduledworkflow (Role) | ds-pipeline-scheduledworkflow-{name} |
| ds-pipeline-workflow-controller-{name} | {dspa-namespace} | ds-pipeline-workflow-controller (Role) | ds-pipeline-workflow-controller-{name} |

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| ds-pipelines-proxy-tls-{name} | kubernetes.io/tls | OAuth proxy TLS certificate | OpenShift service-ca | Yes |
| ds-pipelines-mariadb-tls-{name} | kubernetes.io/tls | MariaDB TLS certificate (when podToPodTLS enabled) | OpenShift service-ca | Yes |
| ds-pipelines-envoy-proxy-tls-{name} | kubernetes.io/tls | MLMD Envoy proxy TLS certificate | OpenShift service-ca | Yes |
| mariadb-{name} | Opaque | MariaDB root password | DSPO (generated) | No |
| minio-{name} | Opaque | Minio S3 access/secret keys | DSPO (generated) or user-provided | No |
| {user-provided} | Opaque | External database credentials | User | No |
| {user-provided} | Opaque | External S3 credentials | User | No |

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| ds-pipeline-{name}:8443/* | GET, POST, DELETE | OAuth2 Bearer Token (OpenShift) | OAuth2 Proxy sidecar | User must have access to namespace |
| ds-pipeline-md-{name}:8443/* | GET, POST | OAuth2 Bearer Token (OpenShift) | OAuth2 Proxy (Envoy) | User must have access to namespace |
| Internal gRPC/HTTP services | All | Service Account Token or mTLS | Kubernetes NetworkPolicy + Service Mesh (optional) | Pod-to-pod trust within namespace |
| MariaDB:3306 | MySQL | Username/Password | NetworkPolicy + MariaDB auth | Only authorized pods can connect |
| Minio:9000 | S3 API | S3 Access Key/Secret Key | Minio auth | S3 credential validation |

### Network Policies

| Policy Name | Selector | Ingress Rules | Purpose |
|-------------|----------|---------------|---------|
| mariadb-{name} | app=mariadb-{name} | Allow 3306/TCP from DSPO operator, API server, MLMD gRPC pods | Restrict database access to authorized components |
| ds-pipeline-metadata-grpc-{name} | app=ds-pipeline-metadata-grpc-{name} | Allow 8080/TCP from pipeline components and pods with label pipelines.kubeflow.org/v2_component=true | Restrict MLMD access to pipeline workloads |

## Data Flows

### Flow 1: Pipeline Submission via API

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User/Client | OpenShift Router | 443/TCP | HTTPS | TLS 1.2+ | None (public endpoint) |
| 2 | OpenShift Router | ds-pipeline Route | 443/TCP | HTTPS | TLS 1.2+ | Route policy |
| 3 | Route | ds-pipeline Service | 8443/TCP | HTTPS | TLS (service cert) | OAuth2 Proxy |
| 4 | OAuth2 Proxy | API Server Pod | 8888/TCP | HTTP or HTTPS | TLS 1.3 or None | Authenticated user context |
| 5 | API Server | MariaDB Service | 3306/TCP | MySQL | TLS or None | Username/Password |
| 6 | API Server | Minio/S3 | 9000/TCP or 443/TCP | HTTP/HTTPS | TLS or None | S3 Access Keys |

### Flow 2: Workflow Execution (v2)

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | API Server | Workflow Controller | 8080/TCP | HTTP | TLS 1.3 or None | Service Account Token |
| 2 | Workflow Controller | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | Service Account Token |
| 3 | Kubernetes API | Workflow Pods | N/A | N/A | N/A | Creates pods |
| 4 | Workflow Pods | MLMD gRPC | 8080/TCP | gRPC | TLS 1.3 or None | None (NetworkPolicy enforced) |
| 5 | Workflow Pods | Minio/S3 | 9000/TCP or 443/TCP | HTTP/HTTPS | TLS or None | S3 Access Keys (from KFP launcher config) |
| 6 | Persistence Agent | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | Service Account Token |
| 7 | Persistence Agent | MariaDB Service | 3306/TCP | MySQL | TLS or None | Username/Password |

### Flow 3: ML Metadata Access

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User/Dashboard | MLMD Envoy Route | 443/TCP | HTTPS | TLS 1.2+ | None |
| 2 | Route | Envoy Service | 8443/TCP | HTTPS | TLS (service cert) | OAuth2 Proxy |
| 3 | Envoy Proxy | MLMD gRPC Service | 8080/TCP | gRPC | TLS 1.3 or None | None |
| 4 | MLMD gRPC | MariaDB Service | 3306/TCP | MySQL | TLS or None | Username/Password |

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| Kubernetes API | REST API | 6443/TCP | HTTPS | TLS 1.2+ | Resource creation/management (workflows, pods, services) |
| OpenShift OAuth | OAuth2 | 443/TCP | HTTPS | TLS 1.2+ | User authentication for external routes |
| Prometheus | Metrics scraping | 8080/TCP | HTTP | None | Operator and component health monitoring |
| ODH Dashboard | UI embedding | 8443/TCP | HTTPS | TLS 1.2+ | Display pipeline UIs in dashboard |
| Object Storage (S3) | S3 API | 9000/TCP or 443/TCP | HTTP/HTTPS | TLS or None | Artifact storage and retrieval |
| MariaDB/MySQL | MySQL protocol | 3306/TCP | MySQL | TLS or None | Metadata persistence |
| Service Mesh (Istio) | mTLS | N/A | N/A | mTLS | Pod-to-pod encryption when podToPodTLS=true |

## Recent Changes

| Version | Date | Changes |
|---------|------|---------|
| 8330c1e | 2024-12+ | - Merged RHOAI-specific updates<br>- Fixed oauth-proxy FIPS compatibility<br>- Updated service mesh proxyv2 image |
| ed9d021 | 2024-12 | - Merged upstream stable branch updates |
| aa6231d | 2024-12 | - Fixed service mesh proxy image issue<br>- Updated oauth-proxy for FIPS |
| df826f0 | 2024-11 | - Upgraded Argo images to v3.4.17<br>- Enhanced security patches |
| 1667e6d | 2024-11 | - Added NetworkPolicy for DSP API server pod self-traffic<br>- Improved network security isolation |
| 005d287 | 2024-10 | - Added secrets::list permissions to pipeline-runner SA<br>- Enables secret discovery for pipeline tasks |
| 622249a | 2024-09 | - Accommodated KFP 2.2.0 upgrade changes<br>- Updated API compatibility |

## Deployment Configuration

### Kustomize Structure

The operator uses Kustomize for deployment with the following key overlays:
- **config/base**: Base operator deployment manifests
- **config/overlays/odh**: ODH-specific configuration
- **config/overlays/rhoai**: RHOAI-specific configuration (production)
- **config/argo**: Argo Workflows CRDs and RBAC for v2
- **config/internal**: Component templates deployed by operator for each DSPA

### DSP Version Support

| DSP Version | Execution Backend | Status | Default |
|-------------|------------------|--------|---------|
| v1 | Tekton Pipelines | Legacy, deprecated | No |
| v2 | Argo Workflows | Supported, recommended | Yes |

### Pod-to-Pod TLS

When `spec.podToPodTLS: true` (default in OpenShift):
- All inter-component communication uses TLS 1.3
- Service CA certificates auto-provisioned via OpenShift service-ca operator
- MariaDB, API Server gRPC, and MLMD gRPC encrypted
- Compatible with OpenShift Service Mesh for additional mTLS

## Configuration Examples

### Minimal DSPA (Development)

```yaml
apiVersion: datasciencepipelinesapplications.opendatahub.io/v1alpha1
kind: DataSciencePipelinesApplication
metadata:
  name: sample
  namespace: my-project
spec:
  apiServer:
    deploy: true
  persistenceAgent:
    deploy: true
  scheduledWorkflow:
    deploy: true
  database:
    mariaDB:
      deploy: true
  objectStorage:
    minio:
      deploy: true
      image: 'quay.io/opendatahub/minio:RELEASE.2019-08-14T20-37-41Z-license-compliance'
```

### Production DSPA (External DB and S3)

```yaml
apiVersion: datasciencepipelinesapplications.opendatahub.io/v1alpha1
kind: DataSciencePipelinesApplication
metadata:
  name: production
  namespace: ml-pipelines
spec:
  dspVersion: "v2"
  podToPodTLS: true
  apiServer:
    deploy: true
    enableRoute: true
    enableSamplePipeline: false
  database:
    externalDB:
      host: mysql.prod.example.com
      port: "3306"
      username: dsp_user
      pipelineDBName: mlpipeline
      passwordSecret:
        name: db-credentials
        key: password
  objectStorage:
    externalStorage:
      host: s3.amazonaws.com
      bucket: ml-pipeline-artifacts
      region: us-east-1
      scheme: https
      s3CredentialsSecret:
        secretName: s3-credentials
        accessKey: AWS_ACCESS_KEY_ID
        secretKey: AWS_SECRET_ACCESS_KEY
  mlmd:
    deploy: true
```

## Troubleshooting

### Common Issues

1. **Database Connection Failures**: Check NetworkPolicy allows API server to MariaDB, verify credentials
2. **Object Storage Access Denied**: Validate S3 credentials, check bucket permissions, verify Secure flag matches endpoint
3. **Route Not Accessible**: Ensure `enableRoute: true`, check OAuth proxy logs, verify user has namespace access
4. **Workflow Pods Failing**: Check pipeline-runner SA permissions, verify image pull secrets, review workflow controller logs
5. **MLMD gRPC Unavailable**: Verify NetworkPolicy, check MLMD deployment status, validate database connectivity

### Key Logs

- DSPO Controller: `oc logs -n {operator-namespace} deployment/controller-manager`
- API Server: `oc logs -n {dspa-namespace} deployment/ds-pipeline-{name}`
- Workflow Controller: `oc logs -n {dspa-namespace} deployment/ds-pipeline-workflow-controller-{name}`
- Persistence Agent: `oc logs -n {dspa-namespace} deployment/ds-pipeline-persistenceagent-{name}`

### Health Checks

DSPO exposes Prometheus metrics for monitoring DSPA health:
- `data_science_pipelines_application_ready` - Overall DSPA readiness (0=NotReady, 1=Ready)
- `data_science_pipelines_application_apiserver_ready` - API Server component status
- `data_science_pipelines_application_persistenceagent_ready` - Persistence Agent status
- `data_science_pipelines_application_scheduledworkflow_ready` - Scheduled Workflow controller status
