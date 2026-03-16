# Platform: Red Hat OpenShift AI 2.8

## Metadata
- **Distribution**: RHOAI
- **Version**: 2.8
- **Release Date**: 2024 Q4
- **Base Platform**: OpenShift Container Platform 4.12+
- **Components Analyzed**: 12
- **Document Generated**: 2026-03-15

## Platform Overview

Red Hat OpenShift AI (RHOAI) 2.8 is a comprehensive machine learning and artificial intelligence platform built on OpenShift Container Platform. It provides an integrated suite of tools and services that enable data scientists and ML engineers to develop, train, deploy, and monitor machine learning models at scale. The platform abstracts the complexity of Kubernetes infrastructure while leveraging OpenShift's enterprise-grade security, networking, and operational capabilities.

The platform consists of multiple specialized components orchestrated by the RHODS Operator, including interactive development environments (Jupyter notebooks, VS Code, RStudio), model serving runtimes (KServe and ModelMesh), ML pipeline orchestration (Data Science Pipelines based on Kubeflow Pipelines), distributed compute frameworks (Ray, CodeFlare), job scheduling (Kueue), and AI governance tools (TrustyAI). All components integrate with OpenShift's authentication (OAuth), service mesh (Istio), monitoring (Prometheus), and certificate management systems.

RHOAI 2.8 emphasizes declarative infrastructure management through custom resources, enabling teams to define their ML workflows as code. The platform supports GPU acceleration for deep learning workloads, multi-model serving for production inference, and provides comprehensive observability through Prometheus metrics and OpenShift monitoring integration.

## Component Inventory

| Component | Type | Version | Purpose |
|-----------|------|---------|---------|
| RHODS Operator | Operator | v1.6.0-1892 | Primary operator deploying and managing all platform components |
| ODH Dashboard | Web Application | v1.21.0-18-rhods-1329 | Central web console for managing workloads, notebooks, and model serving |
| ODH Notebook Controller | Operator | v1.27.0-rhods-319 | Extends Kubeflow notebooks with OpenShift Routes and OAuth authentication |
| Notebook Workbench Images | Container Images | v1.1.1-434 | Pre-configured Jupyter, VS Code, and RStudio environments with ML frameworks |
| KServe | Operator + Runtime | c7788a198 | Serverless model serving with autoscaling and advanced deployment patterns |
| ODH Model Controller | Operator | v1.27.0-rhods-216 | Extends KServe/ModelMesh with OpenShift Routes, Service Mesh, and monitoring |
| ModelMesh Serving | Operator + Runtime | v1.27.0-rhods-217 | Multi-model serving for efficient resource utilization |
| Data Science Pipelines Operator | Operator | 266aee4 | Manages Kubeflow Pipelines v1.x deployments backed by Tekton |
| CodeFlare Operator | Operator | c7e38f8 | Manages MCAD batch scheduler and InstaScale for distributed ML workloads |
| KubeRay | Operator | e603d04d | Deploys and manages Ray clusters for distributed computing |
| Kueue | Operator | f99252525 | Job queueing and resource allocation with priority-based scheduling |
| TrustyAI Service Operator | Operator | 288fadf | AI explainability and fairness monitoring |

## Component Relationships

### Dependency Graph

```
RHODS Operator (root)
├── ODH Dashboard
│   ├── Reads: DataScienceCluster CR (status)
│   ├── Creates: Notebook CRs (via API)
│   ├── Creates: ServingRuntime CRs (via API)
│   ├── Creates: DataSciencePipelinesApplication CRs (via API)
│   └── Queries: Prometheus (metrics)
│
├── ODH Notebook Controller
│   ├── Watches: Notebook CRs (kubeflow.org)
│   ├── Creates: OpenShift Routes (ingress)
│   ├── Creates: Services, Secrets, NetworkPolicies
│   └── Integrates: OAuth Proxy (authentication)
│
├── Notebook Workbench Images
│   ├── Used by: Notebook pods (ImageStream references)
│   ├── Connects to: S3 storage (data/models)
│   ├── Connects to: Data Science Pipelines API
│   └── Connects to: KServe API (deployment)
│
├── KServe
│   ├── Depends on: Knative Serving (serverless)
│   ├── Depends on: Istio (traffic management)
│   ├── Integrates with: ODH Model Controller (Routes)
│   └── Pulls from: S3/GCS (model artifacts)
│
├── ODH Model Controller
│   ├── Watches: InferenceService CRs (serving.kserve.io)
│   ├── Creates: OpenShift Routes (model endpoints)
│   ├── Creates: ServiceMeshMemberRoll entries
│   ├── Creates: ServiceMonitors (Prometheus)
│   ├── Creates: PeerAuthentication (mTLS)
│   └── Aggregates: Storage secrets (S3 credentials)
│
├── ModelMesh Serving
│   ├── Depends on: etcd (state management)
│   ├── Reads: storage-config secrets (S3 credentials)
│   ├── Integrates with: ODH Model Controller (Routes)
│   └── Serves: Multi-model inference workloads
│
├── Data Science Pipelines Operator
│   ├── Depends on: OpenShift Pipelines/Tekton (execution)
│   ├── Creates: MariaDB StatefulSet (metadata storage)
│   ├── Creates: Minio StatefulSet (artifact storage)
│   ├── Integrates with: OAuth Proxy (authentication)
│   └── Used by: Notebook Elyra extensions (pipeline authoring)
│
├── CodeFlare Operator
│   ├── Manages: MCAD (batch scheduler)
│   ├── Manages: InstaScale (autoscaling)
│   ├── Watches: AppWrapper CRs (job queuing)
│   ├── Integrates with: KubeRay (Ray workloads)
│   └── Integrates with: OpenShift Machine API (node scaling)
│
├── KubeRay
│   ├── Watches: RayCluster, RayJob, RayService CRs
│   ├── Integrates with: CodeFlare (AppWrapper wrapping)
│   ├── Integrates with: Kueue (job admission)
│   └── Creates: Ray head and worker pods
│
├── Kueue
│   ├── Watches: Kubernetes Jobs, RayJobs, PyTorchJobs, etc.
│   ├── Manages: ClusterQueue, LocalQueue CRs
│   ├── Controls: Job admission and suspension
│   └── Integrates with: All ML training operators
│
└── TrustyAI Service Operator
    ├── Watches: TrustyAIService CRs
    ├── Patches: InferenceService CRs (inference loggers)
    ├── Patches: ModelMesh Deployments (payload processors)
    └── Exposes: Fairness and explainability metrics
```

### Central Components

Components with the most dependencies (core platform services):

1. **RHODS Operator**: Deploys and manages all other components
2. **ODH Dashboard**: Central UI for all platform interactions
3. **KServe + ODH Model Controller**: Core model serving infrastructure
4. **Data Science Pipelines**: Workflow orchestration hub
5. **Kueue**: Job scheduling and resource management across all workload types

### Integration Patterns

| Pattern | Components | Mechanism | Purpose |
|---------|-----------|-----------|---------|
| CRD Watching | All operators | Kubernetes Watch API | React to resource creation/updates |
| CRD Creation | Dashboard, Notebooks, Operators | Kubernetes API | Declarative resource management |
| Route Creation | Model Controller, Notebook Controller | OpenShift Route API | External ingress with TLS termination |
| OAuth Delegation | Dashboard, Notebooks, Pipelines, TrustyAI | OpenShift OAuth + Proxy | User authentication |
| Service Mesh Integration | KServe, ModelMesh | Istio VirtualService, Gateway | Traffic routing, mTLS, telemetry |
| Metrics Collection | All components | Prometheus ServiceMonitor | Observability and monitoring |
| Storage Access | Notebooks, KServe, ModelMesh, Pipelines | S3 API (boto3) | Model and data artifact storage |
| Job Submission | CodeFlare, KubeRay, Kueue | CRD creation via SDK | Distributed workload execution |

## Platform Network Architecture

### Namespaces

| Namespace | Purpose | Components |
|-----------|---------|------------|
| redhat-ods-operator | Operator control plane | RHODS Operator deployment |
| redhat-ods-applications | Platform services | ODH Dashboard, Notebook Controller, Model Controller |
| redhat-ods-monitoring | Platform monitoring | Prometheus, Alertmanager, Blackbox Exporter |
| kserve | Model serving controllers | KServe Controller Manager, Webhook Server |
| modelmesh-serving | Multi-model serving controller | ModelMesh Controller |
| opendatahub | CodeFlare and distributed compute | CodeFlare Operator, MCAD, InstaScale |
| kueue-system | Job queue management | Kueue Controller Manager |
| User namespaces | User workloads | Notebooks, InferenceServices, Pipelines, Ray clusters, Jobs |

### External Ingress Points

| Component | Ingress Type | Hosts | Port | Protocol | Encryption | Purpose |
|-----------|--------------|-------|------|----------|------------|---------|
| ODH Dashboard | OpenShift Route | odh-dashboard-{namespace}.apps.{cluster} | 443/TCP | HTTPS | TLS 1.2+ (reencrypt) | Platform web console |
| Jupyter Notebooks | OpenShift Route | {username}-notebook-{namespace}.apps.{cluster} | 443/TCP | HTTPS | TLS 1.2+ (edge) | User notebook access |
| VS Code Server | OpenShift Route | {username}-code-server-{namespace}.apps.{cluster} | 443/TCP | HTTPS | TLS 1.2+ (edge) | Browser-based IDE |
| RStudio Server | OpenShift Route | {username}-rstudio-{namespace}.apps.{cluster} | 443/TCP | HTTPS | TLS 1.2+ (edge) | R programming IDE |
| KServe InferenceServices | OpenShift Route, Istio VirtualService | {isvc}-{namespace}.apps.{cluster} | 443/TCP | HTTPS | TLS 1.2+ (edge) | Model inference endpoints |
| ModelMesh Serving | OpenShift Route | {predictor}-{namespace}.apps.{cluster} | 443/TCP | HTTPS | TLS 1.2+ (edge) | Multi-model inference |
| Data Science Pipelines API | OpenShift Route | ds-pipeline-{name}-{namespace}.apps.{cluster} | 443/TCP | HTTPS | TLS 1.2+ (reencrypt) | Pipeline management API |
| TrustyAI Services | OpenShift Route | {trustyai-instance}-{namespace}.apps.{cluster} | 443/TCP | HTTPS | TLS 1.2+ (passthrough) | AI explainability API |
| Ray Dashboard | OpenShift Route | {raycluster}-dashboard-{namespace}.apps.{cluster} | 443/TCP | HTTPS | TLS 1.2+ (edge) | Ray cluster monitoring |
| Prometheus (Platform) | OpenShift Route | prometheus-{monitoring-ns}.apps.{cluster} | 443/TCP | HTTPS | TLS 1.2+ (edge) | Platform metrics (internal) |

### External Egress Dependencies

| Component | Destination | Port | Protocol | Encryption | Purpose |
|-----------|-------------|------|----------|------------|---------|
| All components | Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | Resource management and watch operations |
| All components | OpenShift OAuth Server | 6443/TCP | HTTPS | TLS 1.2+ | User authentication |
| Dashboard, Notebooks, Pipelines | S3-compatible storage (AWS S3, Minio, etc.) | 443/TCP | HTTPS | TLS 1.2+ | Data and model artifact storage |
| KServe, ModelMesh | S3/GCS/Azure Blob storage | 443/TCP | HTTPS | TLS 1.2+ | Model artifact download |
| Dashboard, All Operators | Prometheus/Thanos Querier | 9091/TCP | HTTPS | TLS 1.2+ | Metrics queries |
| Notebooks | PyPI (pypi.org) | 443/TCP | HTTPS | TLS 1.2+ | Python package installation |
| Notebooks | Git repositories (github.com, gitlab.com) | 443/TCP, 22/TCP | HTTPS, SSH | TLS 1.2+, SSH | Source code version control |
| Notebooks | Database endpoints (PostgreSQL, MySQL, MongoDB) | 5432/TCP, 3306/TCP, 27017/TCP | DB protocols | TLS 1.2+ | Data access |
| All components | Container registries (quay.io, registry.redhat.io) | 443/TCP | HTTPS | TLS 1.2+ | Container image pulls |
| CodeFlare InstaScale | OpenShift Machine API | 6443/TCP | HTTPS (K8s API) | TLS 1.2+ | Node autoscaling |
| KubeRay | External Redis (optional) | 6379/TCP | TCP | Optional TLS | Ray GCS fault tolerance |
| Data Science Pipelines | Tekton API (OpenShift Pipelines) | 6443/TCP | HTTPS (K8s API) | TLS 1.2+ | Pipeline execution |

### Internal Service Mesh

| Setting | Value | Components Using |
|---------|-------|------------------|
| mTLS Mode | PERMISSIVE (default) | KServe InferenceServices, ModelMesh (optional) |
| Peer Authentication | Namespace-scoped PeerAuthentication resources | KServe namespaces (created by ODH Model Controller) |
| Service Mesh Membership | ServiceMeshMemberRoll | User namespaces with InferenceServices (auto-managed) |
| Telemetry | Namespace-scoped Telemetry resources | KServe namespaces (metrics collection) |
| Gateway | istio-ingressgateway | KServe external traffic routing |
| VirtualService | Per InferenceService | KServe traffic routing and canary deployments |

## Platform Security

### RBAC Summary

| Component | ClusterRole | API Groups | Key Resources | Verbs |
|-----------|-------------|------------|---------------|-------|
| RHODS Operator | controller-manager-role | datasciencecluster.opendatahub.io, dscinitialization.opendatahub.io | All platform CRDs | create, delete, get, list, patch, update, watch |
| RHODS Operator | controller-manager-role | "", apps, rbac.authorization.k8s.io, route.openshift.io | All core resources | Full CRUD |
| ODH Dashboard | odh-dashboard | "", kubeflow.org, serving.kserve.io, datasciencecluster.opendatahub.io | notebooks, inferenceservices, datascienceclusters, namespaces, secrets, configmaps, services, rolebindings | create, delete, get, list, patch, update, watch |
| ODH Notebook Controller | odh-notebook-controller-manager-role | kubeflow.org, route.openshift.io, networking.k8s.io | notebooks, routes, networkpolicies, secrets, services | create, get, list, patch, update, watch |
| KServe | kserve-manager-role | serving.kserve.io, serving.knative.dev, networking.istio.io | inferenceservices, servingruntimes, services (Knative), virtualservices | create, delete, get, list, patch, update, watch |
| ODH Model Controller | odh-model-controller-role | serving.kserve.io, route.openshift.io, maistra.io, monitoring.coreos.com | inferenceservices, routes, servicemeshmemberrolls, servicemonitors | create, delete, get, list, patch, update, watch |
| ModelMesh Controller | modelmesh-controller-role | serving.kserve.io, apps, "", monitoring.coreos.com | predictors, servingruntimes, deployments, services, secrets | create, delete, get, list, patch, update, watch |
| Data Science Pipelines Operator | manager-role | datasciencepipelinesapplications.opendatahub.io, tekton.dev, apps | datasciencepipelinesapplications, pipelineruns, deployments, secrets | Full CRUD |
| CodeFlare Operator | manager-role | workload.codeflare.dev, quota.codeflare.dev, ray.io, machine.openshift.io | appwrappers, quotasubtrees, rayclusters, machinesets | create, delete, get, list, patch, update, watch |
| KubeRay | kuberay-operator | ray.io, batch, "", route.openshift.io | rayclusters, rayjobs, rayservices, jobs, pods, services, routes | create, delete, get, list, patch, update, watch |
| Kueue | manager-role | kueue.x-k8s.io, batch, kubeflow.org, ray.io | clusterqueues, localqueues, workloads, jobs, pytorchjobs, rayjobs | create, delete, get, list, patch, update, watch |
| TrustyAI Service Operator | manager-role | trustyai.opendatahub.io, serving.kserve.io, apps, route.openshift.io | trustyaiservices, inferenceservices, deployments, routes | create, delete, get, list, patch, update, watch |

### Secrets Inventory

| Component | Secret Name | Type | Purpose |
|-----------|-------------|------|---------|
| All components | {sa-name}-token | kubernetes.io/service-account-token | Service account token for Kubernetes API authentication |
| ODH Dashboard | dashboard-proxy-tls | kubernetes.io/tls | OAuth proxy TLS certificate |
| ODH Dashboard | dashboard-oauth-config-generated | Opaque | OAuth cookie secret |
| ODH Notebook Controller | {notebook-name}-oauth-config | Opaque | OAuth proxy configuration for notebook access |
| ODH Notebook Controller | {notebook-name}-tls | kubernetes.io/tls | TLS certificate for OAuth proxy |
| KServe | kserve-webhook-server-cert | kubernetes.io/tls | TLS certificate for webhook server |
| KServe, ModelMesh | {storage}-secret | Opaque | S3/GCS/Azure credentials for model storage |
| ODH Model Controller | storage-config | Opaque | Aggregated S3 credentials (auto-generated from data connection secrets) |
| ModelMesh | model-serving-etcd | Opaque | etcd connection configuration |
| ModelMesh | modelmesh-webhook-server-cert | kubernetes.io/tls | Webhook server TLS certificate |
| Data Science Pipelines | ds-pipeline-db-{name} | Opaque | MariaDB root password |
| Data Science Pipelines | mlpipeline-minio-artifact | Opaque | S3/Minio access credentials |
| Data Science Pipelines | ds-pipelines-proxy-tls-{name} | kubernetes.io/tls | OAuth proxy TLS certificates |
| TrustyAI | {instance-name}-tls | kubernetes.io/tls | TLS certificate for OAuth proxy |
| TrustyAI | {instance-name}-proxy-token | kubernetes.io/service-account-token | OAuth proxy service account token |
| Notebooks (user-provided) | {username}-git-credentials | kubernetes.io/ssh-auth | Git repository authentication |
| Notebooks (user-provided) | {username}-db-credentials | Opaque | Database connection credentials |
| Notebooks (user-provided) | {username}-s3-credentials | Opaque | S3/object storage access keys |

### Authentication Mechanisms

| Pattern | Components Using | Enforcement Point | Protocol |
|---------|------------------|-------------------|----------|
| Bearer Tokens (JWT) | All operators | Kubernetes API Server | HTTPS with ServiceAccount token |
| OpenShift OAuth | Dashboard, Notebooks, Pipelines, TrustyAI | OAuth Proxy sidecar | OAuth 2.0 code flow |
| mTLS (Service Mesh) | KServe InferenceServices, ModelMesh (optional) | Istio Envoy sidecar | mTLS in PERMISSIVE mode |
| AWS IAM Credentials | All S3 integrations | S3-compatible storage endpoints | AWS Signature V4 |
| Basic Auth | etcd (ModelMesh) | etcd server | HTTP Basic Auth (optional) |
| Redis Password | Ray GCS | Redis server | TCP with password authentication |
| Database Credentials | Data Science Pipelines, Notebooks | Database servers | Protocol-specific (MySQL, PostgreSQL) |
| Git Credentials | Notebooks | Git servers | SSH keys or Personal Access Tokens |
| TLS Client Certificates | Webhook servers | Kubernetes API Server | mTLS for admission webhooks |

## Platform APIs

### Custom Resource Definitions

| Component | API Group | Kind | Scope | Purpose |
|-----------|-----------|------|-------|---------|
| RHODS Operator | datasciencecluster.opendatahub.io | DataScienceCluster | Cluster | Defines which components are enabled and their configuration |
| RHODS Operator | dscinitialization.opendatahub.io | DSCInitialization | Cluster | Configures platform-level settings (namespaces, service mesh, monitoring) |
| RHODS Operator | features.opendatahub.io | FeatureTracker | Cluster | Tracks resources created by Features API for garbage collection |
| ODH Dashboard | dashboard.opendatahub.io | AcceleratorProfile | Namespaced | Defines accelerator hardware profiles (GPUs) with tolerations |
| ODH Dashboard | dashboard.opendatahub.io | OdhApplication | Namespaced | Application catalog entries shown in dashboard |
| ODH Dashboard | opendatahub.io | OdhDashboardConfig | Namespaced | Central configuration for dashboard features |
| ODH Dashboard | dashboard.opendatahub.io | OdhDocument | Namespaced | Documentation resources displayed in dashboard |
| ODH Dashboard | console.openshift.io | OdhQuickStart | Namespaced | Guided tutorial workflows |
| ODH Notebook Controller | kubeflow.org | Notebook | Namespaced | Jupyter notebook instance with pod template spec |
| KServe | serving.kserve.io | InferenceService | Namespaced | Primary API for deploying ML models with predictor, transformer, explainer |
| KServe | serving.kserve.io | InferenceGraph | Namespaced | Inference pipelines with multiple nodes |
| KServe | serving.kserve.io | TrainedModel | Namespaced | Individual models for multi-model serving |
| KServe | serving.kserve.io | ServingRuntime | Namespaced | Templates for model server deployments |
| KServe | serving.kserve.io | ClusterServingRuntime | Cluster | Cluster-wide ServingRuntime templates |
| KServe | serving.kserve.io | ClusterStorageContainer | Cluster | Cluster-wide storage configuration |
| ModelMesh | serving.kserve.io | Predictor | Namespaced | Model deployment with storage location, model type, runtime selection |
| Data Science Pipelines | datasciencepipelinesapplications.opendatahub.io | DataSciencePipelinesApplication | Namespaced | Configuration for complete Data Science Pipelines deployment |
| CodeFlare | workload.codeflare.dev | AppWrapper | Namespaced | Wraps Kubernetes resources for batch scheduling with priority/quota |
| CodeFlare | quota.codeflare.dev | QuotaSubtree | Namespaced | Hierarchical quota trees for resource allocation |
| CodeFlare | workload.codeflare.dev | SchedulingSpec | Namespaced | Scheduling parameters including requeuing strategy |
| KubeRay | ray.io | RayCluster | Namespaced | Ray cluster specification with head and worker groups |
| KubeRay | ray.io | RayJob | Namespaced | Batch jobs on Ray clusters with automatic lifecycle management |
| KubeRay | ray.io | RayService | Namespaced | Ray Serve deployments with zero-downtime updates |
| Kueue | kueue.x-k8s.io | AdmissionCheck | Cluster | Admission checks that workloads must pass |
| Kueue | kueue.x-k8s.io | ClusterQueue | Cluster | Cluster-wide resource quotas and queueing policies |
| Kueue | kueue.x-k8s.io | LocalQueue | Namespaced | Namespace-scoped queues linked to ClusterQueues |
| Kueue | kueue.x-k8s.io | ResourceFlavor | Cluster | Resource types/flavors (GPU types, node pools) |
| Kueue | kueue.x-k8s.io | Workload | Namespaced | Unit of work to be queued and admitted |
| Kueue | kueue.x-k8s.io | WorkloadPriorityClass | Cluster | Priority values for workload scheduling |
| TrustyAI | trustyai.opendatahub.io | TrustyAIService | Namespaced | Configuration for TrustyAI service deployments |

### Public HTTP Endpoints (External User Access)

| Component | Path | Method | Port | Protocol | Auth | Purpose |
|-----------|------|--------|------|----------|------|---------|
| ODH Dashboard | /api/* | ALL | 443/TCP | HTTPS | OAuth | Dashboard API for platform management |
| ODH Dashboard | /* | GET | 443/TCP | HTTPS | OAuth | Frontend static assets (React SPA) |
| Jupyter Notebooks | /notebook/{namespace}/{username}/* | ALL | 443/TCP | HTTPS | OAuth | JupyterLab UI and APIs |
| VS Code Server | / | ALL | 443/TCP | HTTPS | OAuth | VS Code web UI |
| RStudio Server | / | ALL | 443/TCP | HTTPS | OAuth | RStudio web UI |
| KServe InferenceServices | /v1/models/{model}:predict | POST | 443/TCP | HTTPS | None/Bearer Token | V1 prediction protocol |
| KServe InferenceServices | /v2/models/{model}/infer | POST | 443/TCP | HTTPS | None/Bearer Token | V2 inference protocol (KServe standard) |
| ModelMesh Serving | /v2/models/{model}/infer | POST | 443/TCP | HTTPS | None/Bearer Token | KServe V2 REST inference |
| Data Science Pipelines | /apis/v1beta1/* | ALL | 443/TCP | HTTPS | OAuth | KFP API Server REST endpoints |
| TrustyAI Services | /q/metrics | GET | 443/TCP | HTTPS | OAuth | Fairness and explainability metrics |
| Ray Dashboard | / | GET | 443/TCP | HTTPS | None | Ray cluster monitoring UI |

## Data Flows

### Key Platform Workflows

#### Workflow 1: Model Development to Deployment

| Step | Component | Action | Next Component |
|------|-----------|--------|----------------|
| 1 | ODH Dashboard | User creates notebook workspace | ODH Notebook Controller |
| 2 | ODH Notebook Controller | Provisions notebook pod with OAuth proxy | Notebook Workbench Image |
| 3 | Notebook (Jupyter) | User develops and trains model, saves to S3 | S3 Storage |
| 4 | Notebook (Elyra) | User creates pipeline, submits to DSPA | Data Science Pipelines API Server |
| 5 | Data Science Pipelines | Orchestrates pipeline via Tekton, stores artifacts | Tekton, S3 Storage |
| 6 | ODH Dashboard | User creates InferenceService CR for deployment | KServe Controller |
| 7 | KServe Controller | Creates Knative Service, InferenceService pod | Knative Serving |
| 8 | ODH Model Controller | Creates Route, ServiceMesh config, ServiceMonitor | OpenShift Router, Istio |
| 9 | KServe Storage Initializer | Downloads model from S3 to pod volume | S3 Storage |
| 10 | KServe Predictor | Serves inference requests via Route | External clients |

#### Workflow 2: Distributed Training Workflow

| Step | Component | Action | Next Component |
|------|-----------|--------|----------------|
| 1 | Notebook | User defines distributed PyTorch training job | PyTorchJob CR creation |
| 2 | Kueue | Intercepts job creation via webhook, creates Workload | Kueue Controller |
| 3 | Kueue Controller | Evaluates quota, admits workload to ClusterQueue | Workload CR status update |
| 4 | Training Operator | Detects admitted workload, creates training pods | Kubernetes Scheduler |
| 5 | Kubernetes Scheduler | Schedules pods to GPU nodes | Training pods start |
| 6 | Training pods | Execute distributed training, save checkpoints to S3 | S3 Storage |
| 7 | Prometheus | Scrapes training metrics from pods | ServiceMonitor |

#### Workflow 3: Multi-Model Serving with ModelMesh

| Step | Component | Action | Next Component |
|------|-----------|--------|----------------|
| 1 | ODH Dashboard | User creates multiple Predictor CRs | ModelMesh Controller |
| 2 | ModelMesh Controller | Reconciles Predictors, creates runtime deployment | ModelMesh pods |
| 3 | ODH Model Controller | Aggregates storage secrets, creates Route | storage-config secret, OpenShift Route |
| 4 | ModelMesh Puller | Downloads models from S3 to runtime pod volumes | S3 Storage |
| 5 | ModelMesh | Loads models into memory, registers in etcd | etcd |
| 6 | External client | Sends inference request to Route | ModelMesh Service |
| 7 | ModelMesh | Routes to appropriate model server, returns prediction | Client |
| 8 | TrustyAI (optional) | Intercepts payload, analyzes for bias | TrustyAI Service |

#### Workflow 4: Ray Cluster for Distributed Compute

| Step | Component | Action | Next Component |
|------|-----------|--------|----------------|
| 1 | Notebook/SDK | User submits RayCluster CR | KubeRay Operator |
| 2 | KubeRay Operator | Creates Ray head and worker pods | Kubernetes Scheduler |
| 3 | CodeFlare (optional) | Wraps RayCluster in AppWrapper for queueing | MCAD Controller |
| 4 | MCAD | Queues job, schedules when resources available | AppWrapper status update |
| 5 | InstaScale (optional) | Detects resource shortage, scales up MachineSets | OpenShift Machine API |
| 6 | Ray Head Pod | Starts Ray scheduler and dashboard | Ray Worker Pods |
| 7 | Ray Worker Pods | Connect to head via Redis GCS, execute tasks | External storage (optional) |
| 8 | User | Submits job to Ray cluster via Ray client | Ray Head |
| 9 | Ray Dashboard Route | Provides monitoring UI for cluster | User browser |

#### Workflow 5: AI Explainability and Monitoring

| Step | Component | Action | Next Component |
|------|-----------|--------|----------------|
| 1 | User/Dashboard | Creates TrustyAIService CR in namespace | TrustyAI Service Operator |
| 2 | TrustyAI Operator | Creates deployment, service, Route, PVC | TrustyAI Service pod |
| 3 | TrustyAI Operator | Patches InferenceService CRs with inference logger config | KServe Controller |
| 4 | KServe Predictor | Sends inference payloads to TrustyAI service | TrustyAI Service |
| 5 | TrustyAI Service | Stores payloads to PVC, computes fairness metrics | PVC, metrics endpoint |
| 6 | Prometheus | Scrapes TrustyAI metrics (SPD, DIR) | ServiceMonitor |
| 7 | ODH Dashboard | Displays fairness metrics to users | Prometheus API |

## Deployment Architecture

### Deployment Topology

```
Cluster-scoped Operators (control plane):
├── redhat-ods-operator namespace
│   └── RHODS Operator (1 replica, leader election)
│
├── kserve namespace
│   └── KServe Controller Manager (1 replica)
│
├── modelmesh-serving namespace
│   └── ModelMesh Controller (1-3 replicas)
│
├── opendatahub namespace
│   └── CodeFlare Operator (1 replica)
│
└── kueue-system namespace
    └── Kueue Controller Manager (1 replica, leader election)

Platform Services:
├── redhat-ods-applications namespace
│   ├── ODH Dashboard (2 replicas, HA with anti-affinity)
│   ├── ODH Notebook Controller (1 replica)
│   └── ODH Model Controller (3 replicas, leader election)
│
└── redhat-ods-monitoring namespace
    ├── Prometheus StatefulSet (1 replica)
    ├── Alertmanager Deployment (1 replica)
    └── Blackbox Exporter Deployment (1 replica)

User Workloads (per-namespace):
└── {user-namespace}
    ├── Notebook StatefulSets (1 per user)
    ├── InferenceService Pods (KServe: Knative-managed, ModelMesh: Deployment-based)
    ├── DataSciencePipelinesApplication components:
    │   ├── API Server Deployment (1 replica)
    │   ├── Persistence Agent Deployment (1 replica)
    │   ├── Scheduled Workflow Deployment (1 replica)
    │   ├── MariaDB StatefulSet (1 replica, optional)
    │   └── Minio StatefulSet (1 replica, optional)
    ├── RayCluster Pods (1 head + N workers)
    ├── Training Job Pods (PyTorchJob, TFJob, etc.)
    └── TrustyAI Service Deployment (1+ replicas)
```

### Resource Requirements

| Component | CPU Request | Memory Request | CPU Limit | Memory Limit | Notes |
|-----------|-------------|----------------|-----------|--------------|-------|
| RHODS Operator | 500m | 256Mi | 500m | 4Gi | Control plane |
| ODH Dashboard (per pod) | 500m | 1Gi | 1000m | 2Gi | 2 replicas for HA |
| ODH Notebook Controller | Not specified | Not specified | Not specified | Not specified | Lightweight |
| ODH Model Controller | 10m | 64Mi | 500m | 2Gi | 3 replicas, minimal baseline |
| KServe Controller | 100m | 200Mi | 100m | 300Mi | Single replica |
| ModelMesh Controller | 50m | 96Mi | 1000m | 512Mi | 1-3 replicas |
| Kueue Controller | 500m | 512Mi | 500m | 512Mi | Single replica with leader election |
| Jupyter Notebook (default) | Not specified | Not specified | Not specified | Not specified | User-configurable via dashboard |
| KServe InferenceService (default) | Not specified | Not specified | Not specified | Not specified | Depends on serving runtime |
| ModelMesh Runtime Pod | 300m (modelmesh) + 500m (server) | 448Mi + 1Gi | 3000m + 5000m | 448Mi + 1Gi | Multi-container pod |
| Data Science Pipelines API Server | 250m | 500Mi | 500m | 1Gi | Per DSPA instance |
| Data Science Pipelines MariaDB | 300m | 800Mi | 1000m | 1Gi | Per DSPA instance (optional) |
| Ray Head Pod | Not specified | Not specified | Not specified | Not specified | User-configured in RayCluster CR |
| Ray Worker Pod | Not specified | Not specified | Not specified | Not specified | User-configured in RayCluster CR |
| TrustyAI Service | Not specified | Not specified | Not specified | Not specified | User-configured |

## Version-Specific Changes (2.8)

| Component | Changes |
|-----------|---------|
| All components | - Base image updates to UBI8/UBI9 for security patches<br>- Konflux build system migration<br>- Dependency version bumps for CVE remediation |
| KServe | - Fixed path traversal vulnerability (#484)<br>- Fixed starlette resource allocation issues (RHOAIENG-16422)<br>- Fixed fastapi ReDoS vulnerability (RHOAIENG-16424)<br>- Fixed anyio race condition (RHOAIENG-16425)<br>- Fixed Type Confusion vulnerability (CVE-2024-6119) |
| ModelMesh Serving | - Resolved CVE-2023-44487 (HTTP/2 Rapid Reset attack)<br>- Updated k8s.io/apimachinery dependencies |
| Data Science Pipelines | - kfp-tekton backend (Tekton instead of Argo)<br>- MariaDB and Minio default storage (external recommended for production) |
| Notebooks | - **Habana notebooks deactivated** (RHOAIENG-13278)<br>- Python 3.9 UBI9 images are current production track<br>- Python 3.8 UBI8 images in maintenance mode<br>- JupyterLab 3.6.5, Elyra 3.15.0 |
| TrustyAI | - EvalHub integration for LLM evaluation<br>- MLFlow service improvements |
| CodeFlare | - MCAD v1.40.0, InstaScale v0.4.0<br>- OpenShift Machine API integration |
| KubeRay | - Multi-architecture support preparation<br>- OpenShift Route integration |
| Kueue | - Visibility API for pending workload queries<br>- Multi-cluster support (MultiKueue) |

## Platform Maturity

- **Total Components**: 12 (9 operators, 1 web application, 1 container image collection, 1 integration controller)
- **Operator-based Components**: 9 (75%)
- **Service Mesh Coverage**: KServe InferenceServices (automatic), ModelMesh (optional)
- **mTLS Enforcement**: PERMISSIVE mode (allows plaintext for backward compatibility)
- **CRD API Versions**: Mix of v1alpha1 (early), v1beta1 (stable), v1 (GA)
- **Monitoring Integration**: 100% (all components expose Prometheus metrics)
- **OAuth Integration**: Dashboard, Notebooks, Pipelines, TrustyAI (user-facing components)
- **High Availability**: Dashboard (2 replicas), Model Controller (3 replicas), others (leader election)
- **Storage Backends**: S3-compatible object storage (primary), PVC (local development)
- **GPU Support**: NVIDIA CUDA (production), Intel Habana Gaudi (deprecated in 2.8)
- **Build System**: Konflux CI/CD (RHOAI), Manual/GitHub Actions (ODH community)
- **Security Posture**: Non-root containers, pod security contexts, RBAC enforced, secrets rotation (service-ca)

## Next Steps for Documentation

1. **Generate Architecture Diagrams**: Create visual representations of:
   - Platform component relationships
   - Network traffic flows (ingress/egress)
   - User workflow sequence diagrams
   - Namespace and resource topology

2. **Update Architecture Decision Records (ADRs)**: Document key decisions:
   - Why Tekton instead of Argo for pipelines
   - Service mesh PERMISSIVE mode rationale
   - Multi-operator architecture vs. monolithic operator
   - Storage abstraction strategy

3. **Create User-Facing Documentation**:
   - Getting Started guides per persona (data scientist, ML engineer, admin)
   - Component selection matrix (when to use KServe vs. ModelMesh)
   - Best practices for production deployments
   - Troubleshooting guides

4. **Generate Security Architecture Review (SAR) Artifacts**:
   - Network diagrams with security zones
   - Data flow diagrams with encryption/auth details
   - RBAC permission matrices
   - Secrets management documentation
   - Compliance mapping (FedRAMP, PCI-DSS considerations)

5. **Performance and Scalability Analysis**:
   - Resource capacity planning guidelines
   - Scaling limits per component
   - Performance benchmarks for inference workloads
   - Cost optimization strategies

6. **Integration Guides**:
   - External S3 storage configuration
   - Enterprise CA certificate injection
   - LDAP/AD integration for user management
   - CI/CD pipeline integration (GitOps)
   - Monitoring stack integration (external Prometheus)
