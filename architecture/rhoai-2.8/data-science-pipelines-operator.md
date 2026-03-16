# Component: Data Science Pipelines Operator

## Metadata
- **Repository**: https://github.com/red-hat-data-services/data-science-pipelines-operator
- **Version**: 266aee4 (rhoai-2.8 branch)
- **Distribution**: RHOAI
- **Languages**: Go 1.19
- **Deployment Type**: Kubernetes Operator (Kubebuilder-based)

## Purpose
**Short**: Manages lifecycle of Data Science Pipelines installations and their associated Kubernetes resources in individual namespaces.

**Detailed**: The Data Science Pipelines Operator (DSPO) is an OpenShift Operator that deploys and manages namespace-scoped Data Science Pipeline stacks. It enables data scientists to track progress as they iterate over ML model development by creating workflows for data preparation, model training, model validation, and experimentation. Based on upstream Kubeflow Pipelines (KFP) 1.x, DSPO leverages kfp-tekton to run pipelines backed by OpenShift Pipelines (Tekton) rather than Argo. For each DataSciencePipelinesApplication custom resource, the operator deploys a complete pipeline stack including API server, persistence agent, scheduled workflow controller, and optional components like MariaDB, Minio, ML Pipelines UI, and ML Metadata (MLMD) tracking.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| DSPO Controller | Kubernetes Operator | Reconciles DataSciencePipelinesApplication CRs and manages pipeline infrastructure |
| API Server | REST/gRPC Service | Provides KFP API for pipeline management and execution |
| Persistence Agent | Deployment | Syncs pipeline run status and artifacts to database |
| Scheduled Workflow Controller | Deployment | Manages cron-based pipeline scheduling |
| MariaDB | StatefulSet (optional) | Default metadata database for pipeline tracking |
| Minio | StatefulSet (optional) | Default S3-compatible object storage for artifacts |
| ML Pipelines UI | Deployment (optional) | KFP web interface (unsupported, dev/test only) |
| MLMD | Deployment (optional) | ML Metadata tracking with gRPC, Envoy, and Writer components |

## APIs Exposed

### Custom Resource Definitions (CRDs)

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| datasciencepipelinesapplications.opendatahub.io | v1alpha1 | DataSciencePipelinesApplication | Namespaced | Defines configuration for a complete Data Science Pipelines deployment including API server, database, object storage, and optional components |

### HTTP Endpoints

**Operator Metrics/Health**

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /metrics | GET | 8080/TCP | HTTP | None | None | Prometheus metrics for operator monitoring |
| /healthz | GET | 8081/TCP | HTTP | None | None | Operator health check endpoint |
| /readyz | GET | 8081/TCP | HTTP | None | None | Operator readiness check endpoint |

**API Server (per DSPA instance)**

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /apis/v1beta1/* | ALL | 8443/TCP | HTTPS | TLS (Reencrypt) | OAuth Proxy | KFP API Server REST endpoints via OAuth-protected route |
| /apis/v1beta1/* | ALL | 8888/TCP | HTTP | None | Internal | KFP API Server internal HTTP endpoints |

### gRPC Services

**API Server gRPC (per DSPA instance)**

| Service | Port | Protocol | Encryption | Auth | Purpose |
|---------|------|----------|------------|------|---------|
| KFP API | 8887/TCP | gRPC | None | Internal | Pipeline management gRPC endpoints |

**MLMD gRPC (optional, per DSPA instance)**

| Service | Port | Protocol | Encryption | Auth | Purpose |
|---------|------|----------|------------|------|---------|
| ML Metadata | 8080/TCP | gRPC | None | Internal | ML Metadata tracking service |

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| OpenShift Pipelines (Tekton) | 1.8+ | Yes | Pipeline execution engine for running KFP workflows |
| OpenShift Container Platform | 4.9+ | Yes | Kubernetes distribution providing platform services |
| Kubeflow Pipelines | 1.x | Yes | Upstream project providing pipeline APIs and SDK |
| kfp-tekton | 1.5.x | Yes | Adapter for running KFP pipelines on Tekton |
| MySQL-compatible Database | Any | Conditional | External database if not using default MariaDB |
| S3-compatible Storage | Any | Conditional | External object storage if not using default Minio |

### Internal ODH Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| ODH Dashboard | Web UI Integration | Provides supported UI for pipeline management (replacing upstream KFP UI) |
| ODH Trusted CA Bundle | ConfigMap Watch | Mounts custom CA certificates for secure external connections |
| Service Mesh (Istio) | Network Policy | Optional: Provides mTLS and authorization policies for MLMD Envoy |

## Network Architecture

### Services

**Operator Service**

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| service | ClusterIP | 8080/TCP | 8080 | HTTP | None | None | Internal |

**API Server Services (per DSPA instance)**

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| ds-pipeline-{name} | ClusterIP | 8443/TCP | oauth | HTTPS | TLS | OAuth Proxy | Internal/External via Route |
| ds-pipeline-{name} | ClusterIP | 8888/TCP | http | HTTP | None | Internal | Internal |
| ds-pipeline-{name} | ClusterIP | 8887/TCP | 8887 | gRPC | None | Internal | Internal |

**Database Services (per DSPA instance, if MariaDB enabled)**

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| mariadb-{name} | ClusterIP | 3306/TCP | 3306 | MySQL | TLS configurable | Password | Internal |

**Object Storage Services (per DSPA instance, if Minio enabled)**

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| minio-{name} | ClusterIP | 9000/TCP | 9000 | HTTP | None | S3 Access Keys | Internal |

**MLMD Services (per DSPA instance, if MLMD enabled)**

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| ds-pipeline-metadata-envoy-{name} | ClusterIP | 8080/TCP | 8080 | gRPC | None | Internal | Internal |

### Ingress

| Name | Type | Hosts | Port | Protocol | Encryption | TLS Mode | Exposure |
|------|------|-------|------|----------|------------|----------|----------|
| ds-pipeline-{name} | OpenShift Route | Auto-generated | 8443/TCP | HTTPS | TLS 1.2+ | Reencrypt | External |

### Egress

**From Operator**

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token | Manage DSPA resources |

**From API Server (per DSPA instance)**

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| Database (MariaDB or External) | 3306/TCP | MySQL | TLS configurable | Password | Store pipeline metadata |
| Object Storage (Minio or External S3) | Varies | HTTP/HTTPS | TLS configurable | S3 Credentials | Store pipeline artifacts |
| Tekton API | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token | Create and manage pipeline runs |

## Security

### RBAC - Cluster Roles

| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|
| manager-role | datasciencepipelinesapplications.opendatahub.io | datasciencepipelinesapplications, datasciencepipelinesapplications/status, datasciencepipelinesapplications/finalizers | get, list, watch, create, update, patch, delete |
| manager-role | apps | deployments | get, list, watch, create, update, patch, delete |
| manager-role | "" | services, configmaps, secrets, serviceaccounts, persistentvolumeclaims | get, list, watch, create, update, patch, delete |
| manager-role | rbac.authorization.k8s.io | roles, rolebindings, clusterroles, clusterrolebindings | get, list, watch, create, update, patch, delete |
| manager-role | route.openshift.io | routes | get, list, watch, create, update, patch, delete |
| manager-role | tekton.dev | * | * |
| manager-role | custom.tekton.dev | pipelineloops | * |
| manager-role | networking.k8s.io | networkpolicies | get, list, watch, create, update, patch, delete |
| manager-role | monitoring.coreos.com | servicemonitors | get, list, watch, create, update, patch, delete |
| manager-role | authentication.k8s.io | tokenreviews | create |
| manager-role | authorization.k8s.io | subjectaccessreviews | create |
| manager-role | batch | jobs | * |
| manager-role | kubeflow.org | * | * |
| manager-role | argoproj.io | workflows | * |
| manager-role | ray.io | rayclusters, rayjobs, rayservices | create, get, list, patch, delete |
| manager-role | workload.codeflare.dev | appwrappers, appwrappers/finalizers, appwrappers/status | create, delete, deletecollection, get, list, patch, update, watch |

### RBAC - Role Bindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| manager-rolebinding | Operator Namespace | manager-role | controller-manager |

**Per DSPA Instance Roles (created by operator)**

| Role Name | API Group | Resources | Verbs | Purpose |
|-----------|-----------|-----------|-------|---------|
| ds-pipeline-{name} | "" | secrets, configmaps, services, serviceaccounts | get, list, watch | API server access to namespace resources |
| ds-pipeline-user-access-{name} | datasciencepipelinesapplications.opendatahub.io | datasciencepipelinesapplications | get, list, watch | User read access to DSPA CR |
| pipeline-runner-{name} | tekton.dev | pipelineruns, taskruns, pipelines, tasks | create, get, list, watch, update, patch, delete | Execute Tekton pipelines |
| pipeline-runner-{name} | custom.tekton.dev | pipelineloops | create, get, list, watch, update, patch, delete | Execute pipeline loops |
| pipeline-runner-{name} | "" | pods, pods/log | get, list, watch | Monitor pipeline execution |

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| ds-pipelines-proxy-tls-{name} | kubernetes.io/tls | OAuth proxy TLS certificates | Service CA Operator | Yes |
| ds-pipeline-db-{name} | Opaque | MariaDB root password | DSPO (if MariaDB enabled) | No |
| mlpipeline-minio-artifact | Opaque | S3/Minio access credentials | User or DSPO (if Minio enabled) | No |
| {custom-db-secret} | Opaque | External database password | User (if external DB used) | No |
| {custom-s3-secret} | Opaque | External S3 credentials | User (if external storage used) | No |

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| API Server Route (8443) | ALL | OAuth Proxy (OpenShift OAuth) | OAuth Proxy Sidecar | OpenShift RBAC |
| API Server Internal (8888) | ALL | None | N/A | Internal cluster access only |
| Operator Metrics (8080) | GET | None | N/A | Internal cluster access, scraped by Prometheus |
| MariaDB (3306) | SQL | Username/Password | MariaDB Server | Database credentials in secret |
| Minio (9000) | S3 API | S3 Access/Secret Keys | Minio Server | S3 credentials in secret |

## Data Flows

### Flow 1: User Submits Pipeline via API

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User Client | OpenShift Route | 443/TCP | HTTPS | TLS 1.2+ | OAuth Token |
| 2 | Route | OAuth Proxy (API Server Pod) | 8443/TCP | HTTPS | TLS (Reencrypt) | OAuth Token Validation |
| 3 | OAuth Proxy | API Server Container | 8888/TCP | HTTP | None | Verified Identity |
| 4 | API Server | MariaDB Service | 3306/TCP | MySQL | TLS configurable | DB Password |
| 5 | API Server | Tekton API (via K8s API) | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |

### Flow 2: Pipeline Execution Artifact Storage

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Tekton TaskRun Pod | Minio/S3 Service | 9000/TCP or 443/TCP | HTTP or HTTPS | TLS if S3 | S3 Access Keys |
| 2 | Artifact Manager Sidecar | Minio/S3 Service | 9000/TCP or 443/TCP | HTTP or HTTPS | TLS if S3 | S3 Access Keys |
| 3 | API Server | Minio/S3 Service | 9000/TCP or 443/TCP | HTTP or HTTPS | TLS if S3 | S3 Access Keys |

### Flow 3: Persistence Agent Status Sync

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Persistence Agent | Tekton API (via K8s API) | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 2 | Persistence Agent | MariaDB Service | 3306/TCP | MySQL | TLS configurable | DB Password |

### Flow 4: Scheduled Workflow Execution

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Scheduled Workflow Controller | Tekton API (via K8s API) | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 2 | Scheduled Workflow Controller | MariaDB Service | 3306/TCP | MySQL | TLS configurable | DB Password |

### Flow 5: MLMD Metadata Tracking (if enabled)

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | API Server | MLMD Envoy Service | 8080/TCP | gRPC | None | Internal |
| 2 | MLMD Envoy | MLMD gRPC Service | 8080/TCP | gRPC | None | Internal |
| 3 | MLMD gRPC | MariaDB Service | 3306/TCP | MySQL | TLS configurable | DB Password |

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| OpenShift Pipelines (Tekton) | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | Create and monitor PipelineRuns and TaskRuns |
| Prometheus | HTTP Metrics Scrape | 8080/TCP | HTTP | None | Monitor operator and DSPA component health |
| ODH Dashboard | HTTP API | 8443/TCP | HTTPS | TLS 1.2+ via Route | User interface for pipeline management |
| Elyra | HTTP API | 8443/TCP | HTTPS | TLS 1.2+ via Route | Notebook-based pipeline authoring |
| kfp-tekton SDK | HTTP/gRPC API | 8443/TCP, 8887/TCP | HTTPS/gRPC | TLS 1.2+ via Route | Programmatic pipeline submission |
| MariaDB/MySQL | MySQL Protocol | 3306/TCP | MySQL | TLS configurable | Persistent metadata storage |
| S3-compatible Storage | S3 API | Varies | HTTP/HTTPS | TLS configurable | Artifact and model storage |
| Service Mesh (Istio) | mTLS | All | All | mTLS | Optional: Secure service-to-service communication |

## Recent Changes

| Version | Date | Changes |
|---------|------|---------|
| 266aee4 | 2025-09-02 | - Update UBI8 minimal base image digest<br>- Multiple Konflux build configuration updates |
| 12ddfec | 2025-09-01 | - Update Konflux references |
| fcd3f0b | 2025-07-31 | - Update UBI8 minimal base image digest |

## Component Resource Requirements

**Default Resource Allocations (per DSPA instance)**

| Component | CPU Request | Memory Request | CPU Limit | Memory Limit |
|-----------|-------------|----------------|-----------|--------------|
| API Server | 250m | 500Mi | 500m | 1Gi |
| Persistence Agent | 120m | 500Mi | 250m | 1Gi |
| Scheduled Workflow | 120m | 100Mi | 250m | 250Mi |
| MariaDB | 300m | 800Mi | 1000m | 1Gi |
| Minio | 200m | 100Mi | 250m | 1Gi |
| ML Pipelines UI | 100m | 256Mi | 100m | 256Mi |
| MLMD Envoy | 100m | 256Mi | 100m | 256Mi |
| MLMD gRPC | 100m | 256Mi | 100m | 256Mi |
| MLMD Writer | 100m | 256Mi | 100m | 256Mi |

## Deployment Topology

The Data Science Pipelines Operator follows a hub-and-spoke architecture:

1. **Single Operator Instance**: One DSPO controller deployment per cluster (typically in `redhat-ods-applications` or similar namespace)
2. **Multiple DSPA Instances**: Each DataSciencePipelinesApplication CR deploys a complete, isolated pipeline stack in its own namespace
3. **Namespace Isolation**: Each data science project gets its own DSPA with dedicated API server, database, and storage
4. **Shared Platform Services**: All DSPAs leverage shared OpenShift Pipelines (Tekton) for execution

## Configuration

**Key ConfigMaps:**
- `dspo-config`: Operator configuration with container image references
- `ds-pipeline-ui-configmap-{name}`: UI configuration (per DSPA)
- `ds-pipeline-artifact-script-{name}`: Artifact handling script (per DSPA)
- `odh-trusted-ca-bundle`: Global CA bundle for trusted external connections
- `dsp-trusted-ca-{name}`: Custom CA bundle per DSPA

**Key Parameters:**
- `--config`: Path to operator configuration file
- `--leader-elect`: Enable leader election for HA
- `--MaxConcurrentReconciles`: Concurrent reconciliation threads (default: 10)
- `--zap-log-level`: Log verbosity (default: info)

## High Availability

- **Operator**: Supports leader election for multi-replica HA
- **API Server**: Single replica per DSPA (stateless, can be scaled)
- **Persistence Agent**: Single replica per DSPA (lease-based, safe for multi-replica)
- **Scheduled Workflow**: Single replica per DSPA (lease-based, safe for multi-replica)
- **MariaDB**: Single replica with PVC (StatefulSet, no HA by default)
- **Minio**: Single replica with PVC (StatefulSet, no HA by default)

**Note**: For production, external HA database (e.g., AWS RDS, Azure Database) and object storage (e.g., S3, Azure Blob) are recommended.

## Monitoring & Observability

**Operator Metrics:**
- `data_science_pipelines_application_ready`: Overall DSPA readiness gauge
- `data_science_pipelines_application_apiserver_ready`: API Server readiness gauge
- `data_science_pipelines_application_persistenceagent_ready`: Persistence Agent readiness gauge
- `data_science_pipelines_application_scheduledworkflow_ready`: Scheduled Workflow readiness gauge

**Collection:**
- ServiceMonitor CR for Prometheus Operator integration
- Metrics exposed on `/metrics` endpoint (port 8080)
- Dashboard integration via ODH monitoring stack

## Known Limitations

1. **Upstream KFP UI**: ML Pipelines UI component is unsupported and for dev/test only; ODH Dashboard is the supported interface
2. **Single Namespace Scope**: Each DSPA is isolated to a single namespace
3. **Minio for Production**: Default Minio deployment is not recommended for production; use external S3-compatible storage
4. **MariaDB for Production**: Default MariaDB deployment lacks HA; use external managed database for production
5. **KFP Version**: Currently supports KFP 1.x; KFP 2.x support is in development
6. **Storage Migration**: No automated migration path between object storage backends
