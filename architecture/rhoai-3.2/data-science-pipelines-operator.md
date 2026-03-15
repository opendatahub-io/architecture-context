# Component: Data Science Pipelines Operator

## Metadata
- **Repository**: https://github.com/red-hat-data-services/data-science-pipelines-operator.git
- **Version**: rhoai-3.2 (commit 9d94973)
- **Distribution**: RHOAI
- **Languages**: Go
- **Deployment Type**: Kubernetes Operator

## Purpose
**Short**: Manages lifecycle of Data Science Pipelines applications and their supporting infrastructure on OpenShift/Kubernetes.

**Detailed**: The Data Science Pipelines Operator (DSPO) is a Kubernetes operator that deploys and manages namespace-scoped Data Science Pipelines (DSP) stacks on OpenShift. Based on upstream Kubeflow Pipelines (KFP), it enables data scientists to create, track, and execute ML workflows for data preparation, model training, and validation. The operator manages the complete lifecycle of DSP components including API servers, databases, object storage, ML metadata tracking, and workflow orchestration using Argo Workflows. It supports both DSP v1 (OpenShift Pipelines/Tekton) and v2 (Argo Workflows) execution backends, with pod-to-pod mTLS encryption and comprehensive RBAC controls for secure multi-tenant deployments.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| DSPO Controller | Kubernetes Operator | Reconciles DataSciencePipelinesApplication CRs and manages DSP stack deployments |
| DS Pipelines API Server | REST/gRPC API | Kubeflow Pipelines API server for pipeline management and execution |
| Persistence Agent | Background Service | Syncs Argo Workflow status to KFP database |
| Scheduled Workflow Controller | Controller | Manages scheduled/recurring pipeline runs via cron |
| MariaDB | Database | Stores pipeline metadata, runs, and experiments (optional managed deployment) |
| Minio | Object Storage | Stores pipeline artifacts and intermediate data (optional managed deployment) |
| MLMD gRPC | gRPC Service | ML Metadata service for tracking ML artifacts and lineage |
| MLMD Envoy Proxy | Reverse Proxy | Envoy proxy with mTLS termination for MLMD gRPC |
| Argo Workflow Controller | Workflow Engine | Namespace-scoped Argo controller for executing pipeline workflows |

## APIs Exposed

### Custom Resource Definitions (CRDs)

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| datasciencepipelinesapplications.opendatahub.io | v1 | DataSciencePipelinesApplication | Namespaced | Primary CR for deploying DSP stack with API server, database, storage, MLMD |
| pipelines.kubeflow.org | v1 | Pipeline | Namespaced | Pipeline definition stored in Kubernetes (when pipelineStore=kubernetes) |
| pipelines.kubeflow.org | v1 | PipelineVersion | Namespaced | Pipeline version resource with validation webhook |
| kubeflow.org | v1beta1 | ScheduledWorkflow | Namespaced | Cron-based recurring workflow execution schedule |
| argoproj.io | v1alpha1 | Workflow | Namespaced | Argo Workflow execution definition (pipeline runs) |
| argoproj.io | v1alpha1 | WorkflowTemplate | Namespaced | Reusable workflow templates |
| argoproj.io | v1alpha1 | CronWorkflow | Namespaced | Cron-scheduled workflows |

### HTTP Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /apis/v1beta1/* | GET/POST/DELETE | 8888/TCP | HTTP/HTTPS | TLS 1.3 (optional) | Bearer Token | KFP API v1beta1 (pipelines, runs, experiments) |
| /apis/v2beta1/* | GET/POST/DELETE | 8888/TCP | HTTP/HTTPS | TLS 1.3 (optional) | Bearer Token | KFP API v2beta1 (pipeline versions, artifacts) |
| /apis/v1beta1/healthz | GET | 8888/TCP | HTTP/HTTPS | TLS 1.3 (optional) | None | API server health check |
| / | ALL | 8443/TCP | HTTPS | TLS 1.3 | kube-rbac-proxy (SAR) | External route with RBAC authorization |
| /healthz | GET | 8081/TCP | HTTP | None | None | Operator health check |
| /readyz | GET | 8081/TCP | HTTP | None | None | Operator readiness check |
| /metrics | GET | 8080/TCP | HTTP | None | None | Operator Prometheus metrics |

### gRPC Services

| Service | Port | Protocol | Encryption | Auth | Purpose |
|---------|------|----------|------------|------|---------|
| ml_metadata.MetadataStoreService | 8080/TCP (configurable) | gRPC | mTLS (optional) | mTLS client certs | ML Metadata GRPC API for artifact tracking |
| ds-pipeline API | 8887/TCP | gRPC | TLS 1.3 (optional) | Bearer Token | KFP gRPC API for pipeline operations |
| metadata-grpc via Envoy | 9090/TCP | gRPC/HTTP2 | mTLS | mTLS client certs | MLMD gRPC proxied through Envoy with mTLS |

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| OpenShift | 4.11+ | Yes | Platform for operator deployment |
| Argo Workflows | v3.x | No | Workflow execution engine (deployed by operator if enabled) |
| MariaDB | 10.x | No | Pipeline metadata storage (can use external DB) |
| S3-compatible Storage | - | Yes | Artifact storage (Minio or external S3/OBC) |
| cert-manager | - | No | TLS certificate management (uses service-ca if on OpenShift) |

### Internal ODH Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| ODH Dashboard | UI Integration | Provides UI for pipeline management and visualization |
| OpenShift Pipelines (Tekton) | Execution Backend | Optional DSP v1 execution backend (replaced by Argo in v2) |
| Distributed Workloads (CodeFlare) | AppWrapper CRD | Submit pipelines as distributed workload appwrappers |
| KServe | InferenceService CRD | Deploy trained models from pipelines to KServe |
| Ray | RayCluster/RayJob CRD | Execute distributed training jobs within pipelines |

## Network Architecture

### Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| ds-pipeline-{name} | ClusterIP | 8888/TCP | 8888 | HTTP/HTTPS | TLS 1.3 (optional) | Bearer/mTLS | Internal |
| ds-pipeline-{name} | ClusterIP | 8887/TCP | 8887 | gRPC | TLS 1.3 (optional) | Bearer | Internal |
| ds-pipeline-{name} | ClusterIP | 8443/TCP | 8443 | HTTPS | TLS 1.3 | kube-rbac-proxy | Internal/Route |
| mariadb-{name} | ClusterIP | 3306/TCP | 3306 | MySQL | TLS 1.2+ (optional) | MySQL auth | Internal |
| minio-{name} | ClusterIP | 9000/TCP | 9000 | HTTP | None | AWS SigV4 | Internal |
| minio-{name} | ClusterIP | 80/TCP | 9000 | HTTP | None | AWS SigV4 | Internal (KFP UI) |
| ds-pipeline-metadata-grpc-{name} | ClusterIP | 8080/TCP | 8080 | gRPC | mTLS (optional) | mTLS | Internal |
| ds-pipeline-md-{name} | ClusterIP | 9090/TCP | 9090 | gRPC/HTTP2 | mTLS | mTLS | Internal |
| ds-pipeline-md-{name} | ClusterIP | 8443/TCP | 8443 | HTTPS | TLS 1.3 | kube-rbac-proxy | Internal/Route |
| ds-pipeline-workflow-controller-metrics-{name} | ClusterIP | 9090/TCP | 9090 | HTTP | None | None | Internal |
| data-science-pipelines-operator-controller-metrics | ClusterIP | 8080/TCP | 8080 | HTTP | None | None | Internal |

### Ingress

| Name | Type | Hosts | Port | Protocol | Encryption | TLS Mode | Exposure |
|------|------|-------|------|----------|------------|----------|----------|
| ds-pipeline-{name} | OpenShift Route | Auto-generated | 8443/TCP | HTTPS | TLS 1.3 | Reencrypt | External |
| ds-pipeline-md-{name} | OpenShift Route | Auto-generated | 8443/TCP | HTTPS | TLS 1.3 | Reencrypt | External (optional) |

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| mariadb-{name}.{ns}.svc.cluster.local | 3306/TCP | MySQL | TLS 1.2+ (optional) | MySQL password | Pipeline metadata storage |
| minio-{name}.{ns}.svc.cluster.local | 9000/TCP | HTTP/S3 | TLS (optional) | AWS SigV4 | Artifact storage access |
| External S3/ODF | 443/TCP | HTTPS | TLS 1.2+ | AWS IAM/SigV4 | External object storage |
| External Database | 3306/TCP | MySQL | TLS 1.2+ | MySQL password | External database connection |
| ds-pipeline-metadata-grpc-{name} | 8080/TCP | gRPC | mTLS (optional) | mTLS certs | ML Metadata tracking |
| Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | Service Account | Resource management |

## Security

### RBAC - Cluster Roles

| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|
| manager-role | datasciencepipelinesapplications.opendatahub.io | datasciencepipelinesapplications, datasciencepipelinesapplications/status, datasciencepipelinesapplications/finalizers | create, delete, get, list, patch, update, watch |
| manager-role | pipelines.kubeflow.org | pipelines, pipelineversions, pipelines/finalizers, pipelineversions/finalizers, pipelineversions/status | create, delete, get, list, patch, update, watch |
| manager-role | argoproj.io | workflows, workflowartifactgctasks, workflowartifactgctasks/finalizers, workflowtaskresults | *, create, patch |
| manager-role | "" (core) | configmaps, secrets, serviceaccounts, services, persistentvolumeclaims, persistentvolumes | create, delete, get, list, patch, update, watch |
| manager-role | "" (core) | pods, pods/exec, pods/log | * |
| manager-role | apps | deployments, replicasets, deployments/finalizers | *, create, delete, get, list, patch, update, watch |
| manager-role | rbac.authorization.k8s.io | roles, rolebindings, clusterroles, clusterrolebindings | create, delete, get, list, patch, update, watch |
| manager-role | route.openshift.io | routes | create, delete, get, list, patch, update, watch |
| manager-role | networking.k8s.io | networkpolicies | create, delete, get, list, patch, update, watch |
| manager-role | monitoring.coreos.com | servicemonitors | create, delete, get, list, patch, update, watch |
| manager-role | serving.kserve.io | inferenceservices | create, delete, get, list, patch |
| manager-role | ray.io | rayclusters, rayjobs, rayservices | create, delete, get, list, patch |
| manager-role | workload.codeflare.dev | appwrappers, appwrappers/finalizers, appwrappers/status | create, delete, deletecollection, get, list, patch, update, watch |
| manager-role | admissionregistration.k8s.io | mutatingwebhookconfigurations, validatingwebhookconfigurations | create, delete, get, list, patch, update, watch |
| manager-role | authentication.k8s.io | tokenreviews | create |
| manager-role | authorization.k8s.io | subjectaccessreviews | create |
| argo-cluster-role | argoproj.io | workflows, workflowtemplates, cronworkflows, clusterworkflowtemplates | create, delete, get, list, watch, update, patch |
| argo-cluster-role | "" (core) | pods, pods/log, pods/exec | create, get, list, watch, delete, patch |
| argo-cluster-role | "" (core) | configmaps | get, watch, list |
| argo-cluster-role | "" (core) | persistentvolumeclaims | create, delete |

### RBAC - Role Bindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| manager-rolebinding | All DSP namespaces | manager-role (ClusterRole) | controller-manager |
| ds-pipeline-argo-binding | Per DSPA namespace | argo-cluster-role (ClusterRole) | ds-pipeline-argo-{name} |
| argo-binding | Per DSPA namespace | argo (Role) | ds-pipeline-argo-{name} |
| ds-pipeline-{name} | Per DSPA namespace | ds-pipeline (Role) | ds-pipeline-{name} |
| pipeline-runner-{name} | Per DSPA namespace | pipeline-runner (Role) | pipeline-runner-{name} |

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| ds-pipelines-proxy-tls-{name} | kubernetes.io/tls | API server proxy TLS cert | service-ca-operator | No |
| ds-pipelines-mariadb-tls-{name} | kubernetes.io/tls | MariaDB TLS cert for pod-to-pod encryption | service-ca-operator | No |
| ds-pipeline-metadata-grpc-tls-certs-{name} | kubernetes.io/tls | MLMD gRPC TLS cert | service-ca-operator | No |
| ds-pipelines-envoy-proxy-tls-{name} | kubernetes.io/tls | MLMD Envoy proxy TLS cert | service-ca-operator | No |
| {user-provided} | Opaque | Database credentials (username, password) | User/Admin | No |
| {user-provided} | Opaque | Object storage credentials (access key, secret key) | User/Admin | No |
| mariadb-{name} (generated) | Opaque | Auto-generated MariaDB password | DSPO | No |
| minio-{name} (generated) | Opaque | Auto-generated Minio credentials | DSPO | No |

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| ds-pipeline-{name}:8443/* | ALL | Bearer Token (JWT) + SAR | kube-rbac-proxy | SubjectAccessReview against Kubernetes RBAC |
| ds-pipeline-{name}:8888/* | ALL | Bearer Token (JWT) | API Server | OpenShift OAuth token validation |
| ds-pipeline-{name}:8887/* | ALL | Bearer Token (JWT) | API Server | OpenShift OAuth token validation |
| mariadb-{name}:3306 | - | MySQL username/password | MariaDB | Database authentication |
| minio-{name}:9000 | - | AWS SigV4 (access key/secret) | Minio | S3 signature verification |
| ds-pipeline-metadata-grpc-{name}:8080 | - | mTLS client certificates | MLMD gRPC | Mutual TLS authentication (optional) |
| ds-pipeline-md-{name}:9090 | - | mTLS client certificates | Envoy Proxy | Mutual TLS authentication |

### Network Policies

| Policy Name | Namespace | Pod Selector | Ingress Rules |
|-------------|-----------|--------------|---------------|
| mariadb-{name} | Per DSPA | app=mariadb-{name} | Allow 3306/TCP from: DSPO namespace (operator), ds-pipeline API server, ds-pipeline-metadata-grpc |

## Data Flows

### Flow 1: Pipeline Submission and Execution

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User/Dashboard | ds-pipeline-{name} Route | 443/TCP | HTTPS | TLS 1.3 | Bearer Token |
| 2 | Route | ds-pipeline-{name}:8443 | 8443/TCP | HTTPS | TLS 1.3 | Bearer Token |
| 3 | kube-rbac-proxy | ds-pipeline-{name}:8888 | 8888/TCP | HTTPS/HTTP | TLS 1.3 (optional) | Bearer Token |
| 4 | API Server | mariadb-{name}:3306 | 3306/TCP | MySQL | TLS 1.2+ (optional) | MySQL password |
| 5 | API Server | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | Service Account |
| 6 | API Server | ds-pipeline-metadata-grpc-{name}:8080 | 8080/TCP | gRPC | mTLS (optional) | mTLS certs |

### Flow 2: Workflow Execution (Argo)

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Workflow Controller | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | Service Account |
| 2 | Workflow Pod (driver) | ds-pipeline-{name}:8887 | 8887/TCP | gRPC | TLS 1.3 (optional) | Bearer Token |
| 3 | Workflow Pod (launcher) | minio-{name}:9000 | 9000/TCP | HTTP/S3 | None/TLS | AWS SigV4 |
| 4 | Workflow Pod | ds-pipeline-metadata-grpc-{name}:8080 | 8080/TCP | gRPC | mTLS (optional) | mTLS certs |
| 5 | Persistence Agent | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | Service Account |
| 6 | Persistence Agent | mariadb-{name}:3306 | 3306/TCP | MySQL | TLS 1.2+ (optional) | MySQL password |

### Flow 3: Artifact Retrieval

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User/Dashboard | ds-pipeline-{name} Route | 443/TCP | HTTPS | TLS 1.3 | Bearer Token |
| 2 | API Server | minio-{name}:9000 | 9000/TCP | HTTP/S3 | None/TLS | AWS SigV4 |
| 3 | API Server generates | Pre-signed S3 URL | - | - | - | Temporary SigV4 |
| 4 | User/Dashboard | minio-{name}:80 | 80/TCP | HTTP | None | Pre-signed URL |

### Flow 4: ML Metadata Tracking

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Workflow Pod | ds-pipeline-metadata-grpc-{name}:8080 | 8080/TCP | gRPC | mTLS (optional) | mTLS certs |
| 2 | MLMD gRPC | mariadb-{name}:3306 | 3306/TCP | MySQL | TLS 1.2+ (optional) | MySQL password |
| 3 | External Client | ds-pipeline-md-{name} Route (Envoy) | 443/TCP | HTTPS | TLS 1.3 | Bearer Token |
| 4 | Envoy Proxy | ds-pipeline-metadata-grpc-{name}:8080 | 8080/TCP | gRPC | mTLS | mTLS certs |

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| Kubernetes API Server | REST API | 6443/TCP | HTTPS | TLS 1.2+ | Resource CRUD, watch events, auth |
| MariaDB/MySQL | Database | 3306/TCP | MySQL | TLS 1.2+ (optional) | Pipeline metadata persistence |
| S3/Minio | S3 API | 9000/TCP, 443/TCP | HTTP/HTTPS | TLS (optional) | Artifact storage and retrieval |
| Argo Workflows | CRD API | 6443/TCP | HTTPS | TLS 1.2+ | Workflow execution and monitoring |
| MLMD gRPC | gRPC API | 8080/TCP | gRPC | mTLS (optional) | ML artifact and lineage tracking |
| Prometheus | Metrics Scraping | 8080/TCP, 9090/TCP | HTTP | None | Operator and component metrics |
| OpenShift Service CA | Certificate API | 6443/TCP | HTTPS | TLS 1.2+ | TLS certificate provisioning |
| ODH Dashboard | HTTP/REST | 8443/TCP | HTTPS | TLS 1.3 | UI for pipeline management |

## Recent Changes

| Version | Date | Changes |
|---------|------|---------|
| 9d94973 | 2026-02-05 | - Update UBI9 minimal base image digest<br>- Dependency updates for container security |
| be05484 | 2026-02-04 | - Update UBI9 minimal base image digest |
| eb0533d | 2026-01-26 | - Update UBI9 minimal base image digest |
| a3ecaf8 | 2026-01-01 | - Update Konflux build references for RHOAI CI/CD |
| 96e665b | 2025-12-19 | - Clean up OWNERS file for maintainer management |
| cd79dd4 | 2025-12-04 | - Merge upstream main into rhoai-3.2 branch |
| 530174c | 2025-12-01 | - Merge upstream main into rhoai-3.2 branch<br>- Multiple Dockerfile digest updates for security patches |

## Component Configuration

### DataSciencePipelinesApplication Spec

The primary CR supports configuration of:

- **API Server**: Custom images, route enablement, sample pipelines, launcher/driver images, CA bundles, artifact URL expiry, pipeline store (database/kubernetes), caching, workspace PVC templates
- **Database**: Managed MariaDB (image, username, DB name, PVC size, storage class, resources) or External DB (host, port, username, DB name, password secret)
- **Object Storage**: Managed Minio (image, bucket, PVC size, storage class, resources) or External S3 (host, bucket, scheme, region, base path, credentials, secure mode, port)
- **Persistence Agent**: Deployment toggle, custom image, worker count, resources
- **Scheduled Workflow**: Deployment toggle, custom image, cron timezone, resources
- **MLMD**: Deployment toggle, Envoy proxy (resources, image, route), gRPC (resources, image, port)
- **Workflow Controller**: Deployment toggle, custom image, Argo executor image, custom config, resources
- **Pod-to-Pod TLS**: Enable/disable mTLS between DSP components (default: enabled in DSP v2 on OpenShift)
- **Proxy Configuration**: HTTP/HTTPS proxy URLs and NO_PROXY exceptions for air-gapped environments

### Operator Configuration

Configured via ConfigMap `dspo-config` with environment overrides:

- **Images**: API server, persistence agent, scheduled workflow, MLMD (Envoy, gRPC), Argo (exec, workflow controller), launcher, driver, kube-rbac-proxy, MariaDB
- **Argo Workflows Controllers**: Management state (Managed/Removed) for workflow controller deployments
- **Health Checks**: Database and object store connection timeouts
- **Requeue Time**: Controller reconciliation interval
- **Platform Version**: Tracking for version-specific features
- **FIPS Mode**: Enable FIPS-compliant cryptography
