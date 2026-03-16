# Platform: Red Hat OpenShift AI 2.11

## Metadata
- **Distribution**: RHOAI (Red Hat OpenShift AI)
- **Version**: 2.11
- **Base Platform**: OpenShift Container Platform 4.12+
- **Components Analyzed**: 13
- **Analysis Date**: 2026-03-15

## Platform Overview

Red Hat OpenShift AI (RHOAI) 2.11 is an enterprise AI/ML platform built on OpenShift that provides end-to-end capabilities for developing, training, serving, and monitoring machine learning models at scale. The platform integrates multiple open-source projects from the Kubeflow, KServe, and Ray ecosystems with Red Hat's enterprise-grade security, support, and lifecycle management.

The platform provides data scientists with web-based development environments (JupyterLab, RStudio, VS Code), distributed training capabilities across multiple ML frameworks (PyTorch, TensorFlow, XGBoost), scalable model serving through KServe and ModelMesh, and ML pipeline orchestration via Data Science Pipelines. It includes advanced features like workload queueing (Kueue), distributed computing (Ray), model explainability (TrustyAI), and comprehensive monitoring integrated with OpenShift's observability stack.

RHOAI 2.11 is deployed and managed through the RHODS Operator, which orchestrates all platform components through custom resources (DataScienceCluster and DSCInitialization). The platform leverages OpenShift's service mesh for secure mTLS communication, OAuth for unified authentication, and Routes for external access, providing a production-ready environment for enterprise AI workloads.

## Component Inventory

| Component | Type | Version | Purpose |
|-----------|------|---------|---------|
| RHODS Operator | Operator | v1.6.0-641 | Platform orchestrator managing all component lifecycles |
| ODH Dashboard | Web Application | v1.21.0-18 | Web UI for platform management and component access |
| ODH Notebook Controller | Operator | 1.27.0-rhods-318 | Manages Jupyter notebook workbenches with OAuth integration |
| Notebooks | Container Images | v1.1.1-700 | JupyterLab, RStudio, and VS Code workbench environments |
| KServe | Operator | v0.12.1 | Single-model serving with autoscaling and canary deployments |
| ODH Model Controller | Operator | v1.27.0-rhods-427 | Extends KServe with OpenShift Routes, service mesh, and monitoring |
| ModelMesh Serving | Operator | v1.27.0-rhods-254 | Multi-model serving with intelligent placement |
| Data Science Pipelines Operator | Operator | 8d084e4 | ML pipeline orchestration based on Kubeflow Pipelines |
| Training Operator | Operator | 20c6ede9 | Distributed training for PyTorch, TensorFlow, MPI, XGBoost |
| KubeRay | Operator | v1.1.0 | Ray cluster management for distributed Python workloads |
| CodeFlare Operator | Operator | 7460aa9 | Ray cluster security (OAuth, mTLS) and Kueue integration |
| Kueue | Operator | ae90a64c9 | Job queueing and resource quota management |
| TrustyAI Service Operator | Operator | 1.17.0 | Model explainability, fairness monitoring, bias detection |

## Component Relationships

### Dependency Graph

```
RHODS Operator (Root Orchestrator)
├─→ ODH Dashboard
│   ├─→ ODH Notebook Controller (API calls)
│   ├─→ KServe (API calls)
│   ├─→ ModelMesh Serving (API calls)
│   ├─→ Data Science Pipelines (API calls)
│   └─→ Prometheus (metrics queries)
│
├─→ ODH Notebook Controller
│   ├─→ Notebooks (launches workbench images)
│   ├─→ OpenShift OAuth (authentication)
│   └─→ OpenShift Routes (ingress)
│
├─→ KServe
│   ├─→ Knative Serving (serverless autoscaling)
│   ├─→ Istio (traffic routing, mTLS)
│   └─→ ODH Model Controller (OpenShift integration)
│
├─→ ODH Model Controller
│   ├─→ KServe (watches InferenceServices)
│   ├─→ Istio (creates VirtualServices, Gateways)
│   ├─→ Authorino (creates AuthConfigs)
│   └─→ OpenShift Routes (external access)
│
├─→ ModelMesh Serving
│   ├─→ etcd (distributed state)
│   ├─→ S3 (model storage)
│   └─→ Model Servers (Triton, MLServer, OpenVINO)
│
├─→ Data Science Pipelines Operator
│   ├─→ Argo Workflows (DSP v2 execution)
│   ├─→ Tekton (DSP v1 execution)
│   ├─→ MariaDB (metadata storage)
│   └─→ S3/Minio (artifact storage)
│
├─→ Training Operator
│   ├─→ Volcano (optional gang scheduling)
│   └─→ Kueue (optional queueing)
│
├─→ KubeRay
│   ├─→ Ray (distributed runtime)
│   └─→ CodeFlare Operator (security enhancements)
│
├─→ CodeFlare Operator
│   ├─→ KubeRay (watches RayCluster CRDs)
│   ├─→ Kueue (AppWrapper integration)
│   └─→ OpenShift OAuth (Ray Dashboard auth)
│
├─→ Kueue
│   ├─→ Training Operator (queues training jobs)
│   ├─→ KubeRay (queues Ray jobs)
│   └─→ Data Science Pipelines (queues pipeline jobs)
│
└─→ TrustyAI Service Operator
    ├─→ KServe (monitors InferenceServices)
    ├─→ ModelMesh (payload processors)
    └─→ Prometheus (metrics collection)
```

### Central Components

**Infrastructure Layer** (most dependencies pointing to them):
- **OpenShift API Server**: All components interact with Kubernetes API for resource management
- **Istio Service Mesh**: Used by KServe, ODH Model Controller for traffic management and mTLS
- **Prometheus**: Metrics collection from all components
- **S3/Object Storage**: Model artifacts, pipeline artifacts, training data

**Platform Layer** (orchestration):
- **RHODS Operator**: Deploys and manages all other components
- **ODH Dashboard**: User-facing entry point for all platform features

**Service Layer** (high usage):
- **KServe + ODH Model Controller**: Model serving infrastructure
- **ODH Notebook Controller**: Workbench management

### Integration Patterns

**API Calls**:
- Dashboard → Component APIs (notebooks, models, pipelines)
- ODH Model Controller → KServe InferenceServices
- TrustyAI → KServe InferenceServices
- CodeFlare → KubeRay RayClusters

**CRD Creation/Watching**:
- All operators watch their respective CRDs
- ODH Model Controller creates Istio VirtualServices, AuthConfigs
- CodeFlare creates AppWrappers for Kueue
- Data Science Pipelines creates Argo Workflows

**Event Watching**:
- Operators use Kubernetes watch API for real-time reconciliation
- Leader election used by multi-replica operators

**Service Mesh Integration**:
- KServe leverages Istio for traffic splitting, canary deployments
- ODH Model Controller manages Istio Gateways and VirtualServices
- mTLS enforced via PeerAuthentication resources

## Platform Network Architecture

### Namespaces

| Namespace | Purpose | Components |
|-----------|---------|------------|
| redhat-ods-operator | Operator control plane | RHODS Operator |
| redhat-ods-applications | Platform services | Dashboard, Model Controller, Notebook Controller, component operators |
| redhat-ods-monitoring | Monitoring infrastructure | Prometheus, Alertmanager |
| istio-system | Service mesh control plane | Istio control plane (when enabled) |
| knative-serving | Serverless runtime | Knative controllers (when KServe serverless enabled) |
| User namespaces | Workloads | Notebooks, InferenceServices, training jobs, Ray clusters |

### External Ingress Points

| Component | Ingress Type | Hosts | Port | Protocol | Encryption | Purpose |
|-----------|--------------|-------|------|----------|------------|---------|
| ODH Dashboard | OpenShift Route | cluster-generated | 443/TCP | HTTPS | TLS 1.2+ (Reencrypt) | Web UI access |
| Notebooks (OAuth) | OpenShift Route | cluster-generated | 443/TCP | HTTPS | TLS 1.2+ (Reencrypt) | Workbench access |
| KServe InferenceServices | OpenShift Route + Istio Gateway | cluster-generated | 443/TCP | HTTPS | TLS 1.2+ | Model inference endpoints |
| ModelMesh InferenceServices | OpenShift Route | cluster-generated | 443/TCP | HTTPS | TLS 1.2+ | Multi-model inference |
| Data Science Pipelines UI | OpenShift Route | cluster-generated | 443/TCP | HTTPS | TLS 1.2+ (Reencrypt) | Pipeline UI access |
| Ray Dashboard (CodeFlare) | OpenShift Route | cluster-generated | 443/TCP | HTTPS | TLS 1.2+ (Reencrypt) | Ray cluster monitoring |
| TrustyAI Service | OpenShift Route | cluster-generated | 443/TCP | HTTPS | TLS 1.2+ (Reencrypt) | Model explainability APIs |
| Prometheus | OpenShift Route | cluster-generated | 443/TCP | HTTPS | TLS 1.2+ (Reencrypt) | Metrics dashboard |
| Alertmanager | OpenShift Route | cluster-generated | 443/TCP | HTTPS | TLS 1.2+ (Reencrypt) | Alert management |

### External Egress Dependencies

| Component | Destination | Port | Protocol | Encryption | Purpose |
|-----------|-------------|------|----------|------------|---------|
| KServe | S3/GCS/Azure Blob Storage | 443/TCP | HTTPS | TLS 1.2+ | Model artifact downloads |
| Data Science Pipelines | External S3/MySQL | 443/TCP, 3306/TCP | HTTPS, MySQL | TLS 1.2+ | Artifact and metadata storage |
| Notebooks | PyPI, Conda repos, GitHub | 443/TCP | HTTPS | TLS 1.2+ | Package installation, Git operations |
| Training Operator | Container registries | 443/TCP | HTTPS | TLS 1.2+ | Training job image pulls |
| ModelMesh | S3/MinIO | 443/TCP, 9000/TCP | HTTPS/HTTP | TLS 1.2+ (optional) | Model artifact retrieval |
| All operators | Container registries | 443/TCP | HTTPS | TLS 1.2+ | Component image pulls |

### Internal Service Mesh

| Setting | Value | Components Using |
|---------|-------|------------------|
| mTLS Mode | STRICT (when enabled) | KServe InferenceServices, ODH Model Controller |
| Peer Authentication | istio-system namespace | KServe, Model serving pods |
| Traffic Management | VirtualServices, Gateways | KServe, ODH Model Controller |
| Authorization | AuthConfigs (Authorino) | KServe (when auth enabled) |
| Telemetry | Istio telemetry resources | KServe, ODH Model Controller |

## Platform Security

### RBAC Summary

**Platform-Level Permissions** (RHODS Operator):
- Full control over all ODH/RHOAI CRDs (DataScienceCluster, DSCInitialization)
- Cluster-wide RBAC management for component operators
- Monitoring resources (ServiceMonitors, PrometheusRules)
- Service mesh resources (ServiceMeshControlPlane, ServiceMeshMemberRoll)

**Model Serving Permissions**:
- KServe: InferenceServices, ServingRuntimes, Knative Services, Istio resources
- ODH Model Controller: Routes, VirtualServices, AuthConfigs, NetworkPolicies
- ModelMesh: Deployments, Services, etcd access

**Workbench Permissions**:
- ODH Notebook Controller: Notebooks, Routes, Services, OAuth proxies
- Notebooks: User-level permissions via RBAC

**Training Permissions**:
- Training Operator: PyTorchJobs, TFJobs, MPIJobs, XGBoostJobs, PaddleJobs, MXJobs
- CodeFlare: RayClusters, AppWrappers
- KubeRay: RayClusters, RayJobs, RayServices

**Queue Management**:
- Kueue: Workloads, ClusterQueues, LocalQueues, ResourceFlavors

**Monitoring Permissions**:
- TrustyAI: InferenceServices (read/patch), ServiceMonitors

### Secrets Inventory

| Component | Secret Name | Type | Purpose |
|-----------|-------------|------|---------|
| ODH Dashboard | dashboard-proxy-tls | kubernetes.io/tls | OAuth proxy TLS cert |
| ODH Dashboard | dashboard-oauth-config | Opaque | OAuth cookie secret |
| Notebooks | {notebook}-oauth-config | Opaque | Per-notebook OAuth config |
| Notebooks | {notebook}-tls | kubernetes.io/tls | OAuth proxy service cert |
| KServe | kserve-webhook-server-cert | kubernetes.io/tls | Webhook TLS cert |
| KServe | storage-config | Opaque | S3/GCS/Azure credentials |
| ModelMesh | storage-config | Opaque | S3/MinIO credentials |
| ModelMesh | model-serving-etcd | Opaque | etcd connection config |
| Data Science Pipelines | ds-pipeline-db-{name} | Opaque | MariaDB password |
| Data Science Pipelines | ds-pipeline-s3-{name} | Opaque | S3 access keys |
| CodeFlare | {raycluster}-ca-secret | Opaque | Ray mTLS CA cert |
| CodeFlare | {raycluster}-oauth-proxy | Opaque | Ray Dashboard OAuth |
| TrustyAI | {instance}-tls | kubernetes.io/tls | OAuth proxy TLS cert |
| All components | webhook-server-cert | kubernetes.io/tls | Operator webhook certs |

### Authentication Mechanisms

| Pattern | Components Using | Enforcement Point |
|---------|------------------|-------------------|
| OpenShift OAuth (Bearer Tokens) | Dashboard, Notebooks, Data Science Pipelines UI, Ray Dashboard, TrustyAI, Prometheus | OAuth Proxy sidecars |
| mTLS (Service Mesh) | KServe InferenceServices, Model serving pods | Istio mutual TLS |
| mTLS (Webhooks) | All operators | Kubernetes API Server |
| ServiceAccount Tokens | All operators | Kubernetes API Server |
| AWS IAM/S3 Credentials | KServe, ModelMesh, Data Science Pipelines | Application-level |
| Database Passwords | Data Science Pipelines, ModelMesh | Application-level |
| API Keys (Authorino) | KServe (when enabled) | Authorino AuthConfigs |

### Authorization Mechanisms

| Component | Authorization Method | Policy Enforcement |
|-----------|---------------------|-------------------|
| ODH Dashboard | OpenShift RBAC | OAuth Proxy SubjectAccessReview |
| Notebooks | OpenShift RBAC | OAuth Proxy SAR (get notebook resource) |
| KServe (with auth) | Authorino | AuthConfig policies |
| All APIs | Kubernetes RBAC | API Server authorization |

## Platform APIs

### Custom Resource Definitions

**Platform Management**:
| Component | API Group | Kind | Scope | Purpose |
|-----------|-----------|------|-------|---------|
| RHODS Operator | datasciencecluster.opendatahub.io | DataScienceCluster | Cluster | Platform component enablement |
| RHODS Operator | dscinitialization.opendatahub.io | DSCInitialization | Cluster | Platform initialization config |
| RHODS Operator | features.opendatahub.io | FeatureTracker | Cluster | Feature tracking for GC |

**Dashboard**:
| Component | API Group | Kind | Scope | Purpose |
|-----------|-----------|------|-------|---------|
| ODH Dashboard | dashboard.opendatahub.io | OdhApplication | Namespaced | Application catalog entries |
| ODH Dashboard | dashboard.opendatahub.io | OdhDocument | Namespaced | Documentation resources |
| ODH Dashboard | opendatahub.io | OdhDashboardConfig | Namespaced | Dashboard configuration |
| ODH Dashboard | dashboard.opendatahub.io | AcceleratorProfile | Namespaced | GPU/accelerator profiles |

**Workbenches**:
| Component | API Group | Kind | Scope | Purpose |
|-----------|-----------|------|-------|---------|
| ODH Notebook Controller | kubeflow.org | Notebook | Namespaced | Jupyter/RStudio/VS Code instances |

**Model Serving**:
| Component | API Group | Kind | Scope | Purpose |
|-----------|-----------|------|-------|---------|
| KServe | serving.kserve.io | InferenceService | Namespaced | Model serving deployments |
| KServe | serving.kserve.io | ServingRuntime | Namespaced | Model server runtime configs |
| KServe | serving.kserve.io | ClusterServingRuntime | Cluster | Cluster-wide runtime templates |
| KServe | serving.kserve.io | InferenceGraph | Namespaced | Model chaining/ensembles |
| KServe | serving.kserve.io | TrainedModel | Namespaced | Model versions (multi-model) |
| ModelMesh | serving.kserve.io | Predictor | Namespaced | ModelMesh-specific predictors |

**ML Pipelines**:
| Component | API Group | Kind | Scope | Purpose |
|-----------|-----------|------|-------|---------|
| Data Science Pipelines | datasciencepipelinesapplications.opendatahub.io | DataSciencePipelinesApplication | Namespaced | Pipeline stack deployment |
| Data Science Pipelines | argoproj.io | Workflow | Namespaced | Argo workflow definitions |
| Data Science Pipelines | argoproj.io | WorkflowTemplate | Namespaced | Reusable workflow templates |

**Distributed Training**:
| Component | API Group | Kind | Scope | Purpose |
|-----------|-----------|------|-------|---------|
| Training Operator | kubeflow.org | PyTorchJob | Namespaced | PyTorch distributed training |
| Training Operator | kubeflow.org | TFJob | Namespaced | TensorFlow distributed training |
| Training Operator | kubeflow.org | MPIJob | Namespaced | MPI-based training |
| Training Operator | kubeflow.org | XGBoostJob | Namespaced | XGBoost distributed training |
| Training Operator | kubeflow.org | MXJob | Namespaced | MXNet training |
| Training Operator | kubeflow.org | PaddleJob | Namespaced | PaddlePaddle training |

**Distributed Computing**:
| Component | API Group | Kind | Scope | Purpose |
|-----------|-----------|------|-------|---------|
| KubeRay | ray.io | RayCluster | Namespaced | Ray compute clusters |
| KubeRay | ray.io | RayJob | Namespaced | Ray batch jobs |
| KubeRay | ray.io | RayService | Namespaced | Ray Serve deployments |
| CodeFlare | workload.codeflare.dev | AppWrapper | Namespaced | Gang scheduling for Ray |

**Resource Management**:
| Component | API Group | Kind | Scope | Purpose |
|-----------|-----------|------|-------|---------|
| Kueue | kueue.x-k8s.io | ClusterQueue | Cluster | Cluster-wide resource quotas |
| Kueue | kueue.x-k8s.io | LocalQueue | Namespaced | Namespace-scoped queues |
| Kueue | kueue.x-k8s.io | Workload | Namespaced | Queued workload unit |
| Kueue | kueue.x-k8s.io | ResourceFlavor | Cluster | Resource variant definitions |
| Kueue | kueue.x-k8s.io | WorkloadPriorityClass | Cluster | Priority levels |

**Model Monitoring**:
| Component | API Group | Kind | Scope | Purpose |
|-----------|-----------|------|-------|---------|
| TrustyAI | trustyai.opendatahub.io | TrustyAIService | Namespaced | Explainability service instances |

### Public HTTP Endpoints

**Platform UI**:
| Component | Path | Method | Port | Protocol | Auth | Purpose |
|-----------|------|--------|------|----------|------|---------|
| ODH Dashboard | /* | GET, POST | 443/TCP (Route) | HTTPS | OAuth | Platform management UI |
| Notebooks | /notebook/{ns}/{user}/* | ALL | 443/TCP (Route) | HTTPS | OAuth | JupyterLab/RStudio/VS Code |
| Data Science Pipelines UI | /* | GET | 443/TCP (Route) | HTTPS | OAuth | Pipeline visualization |
| Prometheus | /* | GET | 443/TCP (Route) | HTTPS | OAuth | Metrics dashboard |
| TrustyAI | /* | ALL | 443/TCP (Route) | HTTPS | OAuth | Explainability APIs |

**Model Inference**:
| Component | Path | Method | Port | Protocol | Auth | Purpose |
|-----------|------|--------|------|----------|------|---------|
| KServe | /v1/models/{model}:predict | POST | 443/TCP (Route) | HTTPS | Bearer/mTLS | V1 inference |
| KServe | /v2/models/{model}/infer | POST | 443/TCP (Route) | HTTPS | Bearer/mTLS | V2 inference |
| ModelMesh | /v2/models/{model}/infer | POST | 8033/TCP (internal) | gRPC | None (internal) | Multi-model inference |

**Health/Metrics** (Internal):
| Component | Path | Method | Port | Protocol | Auth | Purpose |
|-----------|------|--------|------|----------|------|---------|
| All Operators | /metrics | GET | 8080/TCP | HTTP | None | Prometheus metrics |
| All Operators | /healthz | GET | 8081/TCP | HTTP | None | Liveness probes |
| All Operators | /readyz | GET | 8081/TCP | HTTP | None | Readiness probes |

## Data Flows

### Key Platform Workflows

#### Workflow 1: Model Development to Deployment

| Step | Component | Action | Next Component |
|------|-----------|--------|----------------|
| 1 | User | Access ODH Dashboard via browser | ODH Dashboard Route |
| 2 | ODH Dashboard | User launches Jupyter notebook | ODH Notebook Controller |
| 3 | ODH Notebook Controller | Creates Notebook CR, StatefulSet, Route | Notebooks (JupyterLab) |
| 4 | Notebook | User develops model, trains locally | S3 (uploads model) |
| 5 | Notebook/Dashboard | User creates InferenceService CR | KServe |
| 6 | KServe | Creates Knative Service for model | ODH Model Controller |
| 7 | ODH Model Controller | Creates Route, VirtualService, AuthConfig | Model serving pod |
| 8 | Storage Initializer | Downloads model from S3 | Model server container |
| 9 | External Client | Sends inference request to Route | Istio Gateway → Model pod |
| 10 | TrustyAI (optional) | Monitors inference data for bias | Prometheus |

#### Workflow 2: Distributed Training Job

| Step | Component | Action | Next Component |
|------|-----------|--------|----------------|
| 1 | User/Notebook | Creates PyTorchJob CR | Training Operator |
| 2 | Training Operator | Creates PodGroup (if gang scheduling) | Kueue (optional) |
| 3 | Kueue | Evaluates quotas, admits workload | Kubernetes Scheduler |
| 4 | Kubernetes | Creates master and worker pods | Container Registry |
| 5 | Training Pods | Pull images, start training | Inter-pod communication |
| 6 | Master Pod | Coordinates training across workers | Worker pods (port 23456) |
| 7 | Training Pods | Save checkpoints | S3/PVC |
| 8 | Training Job | Completes, writes final model | S3 |
| 9 | User | Downloads trained model | Creates InferenceService |

#### Workflow 3: ML Pipeline Execution

| Step | Component | Action | Next Component |
|------|-----------|--------|----------------|
| 1 | User/Dashboard | Creates DataSciencePipelinesApplication CR | Data Science Pipelines Operator |
| 2 | DSPO | Deploys API Server, Workflow Controller, MariaDB, Minio | Pipeline infrastructure |
| 3 | User | Submits pipeline via SDK/UI | ds-pipeline API Server |
| 4 | API Server | Creates Argo Workflow CR, stores metadata | MariaDB |
| 5 | Workflow Controller | Creates pipeline pods | Kubernetes |
| 6 | Pipeline Pods | Execute tasks (data prep, training, eval) | S3 (artifacts) |
| 7 | Pipeline Pods | Log metrics, artifacts | MariaDB, S3 |
| 8 | Persistence Agent | Syncs workflow state to DB | MariaDB |
| 9 | User | Views results in UI | Pipeline UI Route |

#### Workflow 4: Distributed Ray Workload with Queueing

| Step | Component | Action | Next Component |
|------|-----------|--------|----------------|
| 1 | User | Creates AppWrapper CR (wrapping RayCluster) | CodeFlare Operator |
| 2 | CodeFlare | Creates Kueue Workload CR | Kueue |
| 3 | Kueue | Evaluates quotas, queues workload | Waits for resources |
| 4 | Kueue | Admits workload when resources available | CodeFlare Operator |
| 5 | CodeFlare | Unsuspends AppWrapper, creates RayCluster | KubeRay Operator |
| 6 | KubeRay | Creates Ray head and worker pods | Ray Pods |
| 7 | CodeFlare | Injects OAuth proxy, creates Route | Ray Dashboard accessible |
| 8 | Ray Head | Starts GCS, coordinates workers | Worker pods (port 6379) |
| 9 | User | Submits Python code to Ray cluster | Ray client (port 10001) |
| 10 | Ray | Executes distributed workload | Inter-pod communication |

#### Workflow 5: Model Monitoring and Explainability

| Step | Component | Action | Next Component |
|------|-----------|--------|----------------|
| 1 | User/Dashboard | Creates TrustyAIService CR | TrustyAI Service Operator |
| 2 | TrustyAI Operator | Deploys TrustyAI service, creates Route | TrustyAI service pod |
| 3 | TrustyAI Operator | Patches InferenceService with payload processor | KServe/ModelMesh |
| 4 | InferenceService | Sends inference data to TrustyAI | TrustyAI service (HTTP) |
| 5 | TrustyAI | Stores data, calculates fairness metrics | PVC, Prometheus |
| 6 | User | Views bias metrics via TrustyAI UI | TrustyAI Route |
| 7 | Prometheus | Scrapes TrustyAI metrics | ServiceMonitor |
| 8 | User | Sets up alerts for bias thresholds | Alertmanager |

## Deployment Architecture

### Deployment Topology

**Control Plane Namespace** (redhat-ods-operator):
- RHODS Operator (1 replica, leader election)

**Applications Namespace** (redhat-ods-applications):
- ODH Dashboard (2 replicas, HA)
- ODH Notebook Controller (1 replica)
- ODH Model Controller (3 replicas, HA, leader election)
- KServe Controller Manager (1 replica)
- ModelMesh Controller (1-3 replicas)
- Data Science Pipelines Operator (1 replica)
- Training Operator (1 replica, leader election)
- KubeRay Operator (1 replica, leader election)
- CodeFlare Operator (1 replica)
- Kueue Controller Manager (1 replica, leader election)
- TrustyAI Service Operator (1 replica, leader election)

**Monitoring Namespace** (redhat-ods-monitoring):
- Prometheus (1 replica)
- Alertmanager (1 replica)

**Service Mesh Namespace** (istio-system, when enabled):
- Istio Control Plane (ServiceMeshControlPlane)

**User Workload Namespaces**:
- Notebooks (StatefulSets, 1 replica per user)
- InferenceServices (Knative Services or Deployments)
- Training Jobs (Pods managed by Training Operator)
- Ray Clusters (Head + Worker pods)
- Pipeline Runs (Argo Workflow pods)
- TrustyAI Services (Deployments)

### Resource Requirements Summary

**Operator Pods** (typical):
- CPU Request: 10m-500m
- CPU Limit: 500m-1000m
- Memory Request: 64Mi-512Mi
- Memory Limit: 512Mi-4Gi

**Application Pods**:
- Dashboard: 500m CPU / 1Gi Memory (request)
- Notebooks: User-configurable (Small/Medium/Large)
- Model Servers: Varies by model size
- Training Jobs: User-configurable, multi-pod
- Ray Clusters: User-configurable, autoscaling

## Version-Specific Changes (2.11)

| Component | Notable Changes |
|-----------|-----------------|
| RHODS Operator | - Add kserve-local-gateway Gateway and Service<br>- Fix ingress cert secret type<br>- Change serviceMesh and trustCABundle to pointer types<br>- Upgrade Go 1.20 → 1.21 |
| ODH Dashboard | - Merge fixes for v2.24.0<br>- Fix broken Fraud Detection tutorial link<br>- Cleanup S3 endpoint host in pipeline config |
| KServe | - Stable release 0.12.1 for RHOAI 2.11<br>- Konflux-based build pipeline<br>- InferenceGraph for model chaining |
| ODH Model Controller | - Update UBI minimal base image to 8.10<br>- Update Go toolset to 1.21.11-9<br>- Fix vLLM image SHA references |
| KubeRay | - Upgrade Go version to 1.22.2<br>- Add SecurityContext for restricted pod-security<br>- CVE fixes for golang.org/x/net |
| CodeFlare | - RHOAI 2.11 release branch<br>- Stability improvements<br>- Security enhancements |
| Data Science Pipelines | - Generated params for DSP 2.3<br>- Updated Go toolset to 1.21<br>- Fix DSPA status update on reconciliation |
| Training Operator | - Support K8s v1.29<br>- Upgrade PyTorchJob examples to PyTorch v2<br>- LLM Fine-Tuning support (BERT, Tiny LLaMA) |
| Kueue | - Multi-cluster job distribution features<br>- Cluster autoscaler integration<br>- Partial admission support |
| TrustyAI | - Update Go to 1.21<br>- Add internal service TLS<br>- Change route termination to reencrypt |
| ModelMesh | - Merge upstream release-0.12.0-rc0<br>- Increase etcd resources<br>- Security updates for golang.org/x/net |

## Platform Maturity

**Component Statistics**:
- **Total Components**: 13 (operators + applications)
- **Operator-based Components**: 11
- **Container Image Collections**: 1 (Notebooks)
- **Web Applications**: 1 (Dashboard)

**Service Mesh Coverage**:
- **KServe**: Full integration (VirtualServices, Gateways, mTLS)
- **ModelMesh**: Optional integration
- **Other components**: Internal cluster communication

**mTLS Enforcement**:
- **KServe InferenceServices**: STRICT (when service mesh enabled)
- **Operator Webhooks**: mTLS via Kubernetes API Server
- **Internal Services**: PERMISSIVE (varies by component)

**CRD API Versions**:
- **v1**: DataScienceCluster, DSCInitialization, Notebook, PyTorchJob, TFJob, MPIJob, RayCluster, Workflow
- **v1beta1**: InferenceService, Kueue resources, AuthConfig
- **v1alpha1**: ServingRuntime, InferenceGraph, TrustyAIService, DataSciencePipelinesApplication

**API Stability**:
- Core platform APIs (DSC, DSCI): v1 (stable)
- Model serving: v1beta1 (stable)
- New features: v1alpha1 (evolving)

**Security Posture**:
- All operators run as non-root
- Privilege escalation disabled
- FIPS compliance (where applicable)
- OpenShift OAuth integration for user-facing services
- mTLS for service mesh-enabled components
- TLS 1.2+ for all external communication

## Platform Integration Summary

**External Service Dependencies**:
- S3-compatible object storage (AWS S3, MinIO, OpenShift Data Foundation)
- Container registries (Quay.io, Red Hat registries)
- Git repositories (GitHub, GitLab)
- External databases (optional, for Data Science Pipelines)

**OpenShift Platform Integration**:
- Routes for external access
- OAuth for authentication
- Service CA for TLS certificates
- ImageStreams for container images
- BuildConfigs for custom builds
- Monitoring integration (Prometheus, Alertmanager)
- Service Mesh (Istio/Maistra)

**Kubernetes Platform Features**:
- Custom Resource Definitions (40+ CRDs)
- Admission Webhooks (mutating and validating)
- Leader Election for HA
- ServiceMonitors for metrics
- NetworkPolicies for isolation
- PersistentVolumeClaims for storage

## Next Steps for Documentation

Based on this platform architecture analysis, the following documentation efforts are recommended:

1. **Architecture Diagrams**:
   - Generate component dependency diagram from the dependency graph
   - Create network flow diagrams for each key workflow
   - Visualize namespace topology and pod distribution
   - Create security boundary diagrams showing mTLS and OAuth enforcement points

2. **Security Documentation**:
   - Generate Security Architecture Review (SAR) documentation
   - Document RBAC permission matrix across components
   - Create threat model for model serving endpoints
   - Document secrets management and rotation policies

3. **Operational Runbooks**:
   - Component health monitoring and troubleshooting guides
   - Disaster recovery procedures
   - Upgrade paths and version compatibility matrix
   - Performance tuning recommendations

4. **Developer Documentation**:
   - API reference for all CRDs
   - Integration guide for adding new components
   - Custom serving runtime development guide
   - Pipeline component development guide

5. **User Guides**:
   - End-to-end workflow tutorials
   - Model serving deployment patterns
   - Distributed training best practices
   - Cost optimization strategies for resource usage

6. **Compliance Documentation**:
   - FIPS compliance verification
   - Network segmentation policies
   - Audit logging configuration
   - Data residency and sovereignty controls
