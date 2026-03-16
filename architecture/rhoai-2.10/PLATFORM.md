# Platform: Red Hat OpenShift AI 2.10

## Metadata
- **Distribution**: RHOAI
- **Version**: 2.10
- **Release Date**: 2024
- **Base Platform**: OpenShift Container Platform 4.11+
- **Components Analyzed**: 13
- **Architecture Directory**: architecture/rhoai-2.10

## Platform Overview

Red Hat OpenShift AI (RHOAI) 2.10 is a comprehensive enterprise AI/ML platform built on OpenShift that provides end-to-end capabilities for the complete machine learning lifecycle. The platform enables data scientists and ML engineers to develop, train, serve, and monitor AI models at scale with integrated tools for data science workspaces (Jupyter notebooks, VS Code, RStudio), distributed training (PyTorch, TensorFlow, Ray), model serving (KServe, ModelMesh), ML workflow orchestration (Data Science Pipelines), and workload management (Kueue).

The platform is architected around a central operator (RHODS Operator) that orchestrates deployment of specialized component operators, each managing specific aspects of the AI/ML workflow. Integration is achieved through shared service mesh infrastructure (Istio), unified authentication (OpenShift OAuth + Authorino), centralized monitoring (Prometheus), and a web-based management console (ODH Dashboard). The platform emphasizes enterprise requirements including multi-tenancy, security (mTLS, RBAC, network policies), compliance (FIPS, restricted SCC), and observability (metrics, logs, distributed tracing).

RHOAI 2.10 supports flexible deployment modes including serverless model serving with autoscaling, distributed training across GPUs and specialized accelerators (Habana Gaudi, Intel GPU), and integrated MLOps workflows connecting notebooks, pipelines, training, and serving with model registry integration for lineage tracking and governance.

## Component Inventory

| Component | Type | Version | Purpose |
|-----------|------|---------|---------|
| RHODS Operator | Platform Operator | 2.9.0 | Primary platform operator orchestrating deployment and lifecycle of all data science components |
| ODH Dashboard | Web Application | v1.21.0-18-rhods-1883 | Web-based UI and API gateway for platform management, project creation, and resource access |
| Notebook Controller | Kubernetes Operator | v1.27.0-rhods-305 | Manages lifecycle of Jupyter notebook servers with culling and resource management |
| Notebook Images | Container Images | v1.1.1-637 | Pre-built workbench images for Jupyter, VS Code, RStudio with ML frameworks |
| Data Science Pipelines | Kubernetes Operator | a91ea11 | Deploys and manages Kubeflow Pipelines (v1/v2) for ML workflow orchestration |
| KServe | Kubernetes Operator | c3b84e599 | Serverless model serving with autoscaling, multi-framework support, canary deployments |
| ModelMesh Serving | Kubernetes Operator | v1.27.0-rhods-256 | High-density multi-model serving with intelligent routing and resource pooling |
| ODH Model Controller | Kubernetes Operator | v1.27.0-rhods-341 | Extends KServe/ModelMesh with OpenShift integration (Routes, ServiceMesh, monitoring) |
| Training Operator | Kubernetes Operator | 78eedd82 | Distributed training for PyTorch, TensorFlow, MPI, XGBoost, MXNet, PaddlePaddle |
| CodeFlare Operator | Kubernetes Operator | rhoai-2.10 (1d122da) | Manages Ray clusters and AppWrappers for distributed ML workloads |
| KubeRay Operator | Kubernetes Operator | v1.1.0 (b0225b36) | Ray cluster management for distributed Python computing |
| Kueue | Kubernetes Operator | 5b3bf2841 (v0.6.2) | Multi-tenant job queueing and resource quota management with fair sharing |
| TrustyAI Service Operator | Kubernetes Operator | a77b326 | AI fairness, bias detection, and model explainability services |

## Component Relationships

### Dependency Graph

```
RHODS Operator (Platform Control Plane)
├── ODH Dashboard
│   ├── Notebook Controller (creates Notebook CRs)
│   ├── Data Science Pipelines (creates DSPA CRs)
│   ├── KServe (creates InferenceService CRs)
│   ├── Model Registry (API calls)
│   └── Prometheus (metrics queries)
│
├── Notebook Controller
│   ├── Notebook Images (container images)
│   ├── Istio (VirtualService for routing)
│   └── Kubeflow Notebook CRD
│
├── Data Science Pipelines
│   ├── Argo Workflows (v2 execution engine)
│   ├── MariaDB (metadata storage)
│   ├── Minio/S3 (artifact storage)
│   ├── KServe (model deployment from pipelines)
│   └── Model Registry (metadata tracking)
│
├── KServe
│   ├── Knative Serving (serverless autoscaling)
│   ├── Istio (traffic management, VirtualServices)
│   ├── ODH Model Controller (OpenShift integration)
│   ├── S3 Storage (model artifacts)
│   └── Model Registry (model metadata)
│
├── ModelMesh Serving
│   ├── etcd (distributed coordination)
│   ├── ODH Model Controller (OpenShift integration)
│   ├── S3 Storage (model artifacts)
│   └── TrustyAI (inference monitoring)
│
├── ODH Model Controller
│   ├── KServe InferenceService (watches and extends)
│   ├── Authorino (authentication policies)
│   ├── Istio (VirtualServices, PeerAuthentication)
│   ├── Prometheus (ServiceMonitors)
│   └── OpenShift Routes (external access)
│
├── Training Operator
│   ├── Kueue (workload queueing)
│   ├── scheduler-plugins/Volcano (gang scheduling)
│   └── S3 Storage (training data and checkpoints)
│
├── CodeFlare Operator
│   ├── KubeRay (RayCluster CRD)
│   ├── Kueue (AppWrapper scheduling)
│   └── OAuth Proxy (Ray dashboard auth)
│
├── KubeRay Operator
│   ├── Prometheus (metrics)
│   └── OpenShift Routes (Ray dashboard access)
│
├── Kueue
│   ├── Training Operator (job admission)
│   ├── CodeFlare (AppWrapper admission)
│   └── Cluster Autoscaler (ProvisioningRequest)
│
└── TrustyAI Service Operator
    ├── KServe/ModelMesh (inference monitoring)
    ├── Prometheus (fairness metrics)
    └── OAuth Proxy (authentication)
```

### Central Components

**Core Platform Services** (most dependencies):
- **RHODS Operator**: Central orchestrator managing all component deployments
- **ODH Dashboard**: Primary user interface and API gateway for all platform interactions
- **Istio Service Mesh**: Shared networking layer for traffic management, mTLS, telemetry
- **Prometheus**: Centralized monitoring and metrics collection for all components
- **S3-compatible Storage**: Shared storage layer for models, artifacts, data, and checkpoints

**Integration Hubs**:
- **Kueue**: Central admission control for all batch workloads (Training, CodeFlare, Ray)
- **ODH Model Controller**: Integration layer connecting KServe/ModelMesh to OpenShift services
- **Authorino**: Centralized authentication/authorization for model serving endpoints

### Integration Patterns

| Pattern | Components Using | Mechanism | Purpose |
|---------|------------------|-----------|---------|
| **CRD Creation** | Dashboard → Notebook Controller, KServe, Pipelines | Kubernetes API | Users create resources via dashboard |
| **CRD Watching** | Model Controller → KServe/ModelMesh | Kubernetes Watch API | Extend resources with platform features |
| **Admission Webhooks** | Kueue → Training/CodeFlare/Ray Jobs | Mutating/Validating Webhooks | Job queueing and quota enforcement |
| **API Calls (gRPC/HTTP)** | Dashboard → Pipelines, Model Registry, Prometheus | REST/gRPC APIs | Query status and metrics |
| **Sidecar Injection** | CodeFlare → Ray Dashboard, Dashboard/Notebooks → OAuth Proxy | Pod mutation | Authentication enforcement |
| **Service Mesh Integration** | KServe, ModelMesh → Istio | VirtualService, PeerAuthentication | Traffic routing, mTLS |
| **Storage Initialization** | KServe, ModelMesh → S3 | Init containers | Download models before serving |
| **Metrics Scraping** | All components → Prometheus | ServiceMonitor/PodMonitor | Unified observability |
| **Operator-managed Operators** | RHODS Operator → All component operators | Kustomize manifests | Declarative deployment |

## Platform Network Architecture

### Namespaces

| Namespace | Purpose | Components |
|-----------|---------|------------|
| openshift-operators | Platform operators | RHODS Operator |
| redhat-ods-applications | User workloads and services | Dashboard, Notebooks, Pipelines, Model Serving |
| redhat-ods-monitoring | Monitoring stack | Prometheus, Alertmanager, Grafana |
| istio-system | Service mesh control plane | Istio (ServiceMeshControlPlane) |
| redhat-ods-applications-auth-provider | Authentication services | Authorino |
| opendatahub | Component operators | Notebook Controller, Model Controller, Training Operator, Kueue, etc. |
| User namespaces | Data science projects | User workbenches, models, pipelines, training jobs |

### External Ingress Points

| Component | Ingress Type | Hosts | Port | Protocol | Encryption | Purpose |
|-----------|--------------|-------|------|----------|------------|---------|
| ODH Dashboard | OpenShift Route | Dynamic (cluster domain) | 443/TCP | HTTPS | TLS 1.3 (Reencrypt) | Web UI and API gateway |
| Jupyter Notebooks | OpenShift Route | {notebook}-{namespace}.{domain} | 443/TCP | HTTPS | TLS 1.2+ (Edge/Reencrypt) | User notebook access |
| RStudio | OpenShift Route | {rstudio}-{namespace}.{domain} | 443/TCP | HTTPS | TLS 1.2+ (Edge) | RStudio IDE access |
| Code Server | OpenShift Route | {codeserver}-{namespace}.{domain} | 443/TCP | HTTPS | TLS 1.2+ (Edge) | VS Code IDE access |
| KServe InferenceServices | Istio Gateway + Route | {isvc}.{namespace}.{domain} | 443/TCP | HTTPS | TLS 1.2+ (SIMPLE/MUTUAL) | Model inference endpoints |
| ModelMesh Predictors | OpenShift Route | {predictor}-{namespace}.{domain} | 443/TCP | HTTPS | TLS 1.2+ (Reencrypt) | Multi-model inference |
| Ray Dashboard | OpenShift Route | {cluster}-{namespace}.{domain} | 443/TCP | HTTPS | TLS 1.2+ (Edge) | Ray cluster monitoring |
| Data Science Pipelines UI | OpenShift Route | {generated}.cluster.local | 443/TCP | HTTPS | TLS 1.3 (Reencrypt) | Pipeline visualization |
| Data Science Pipelines API | OpenShift Route | {generated}.cluster.local | 443/TCP | HTTPS | TLS 1.3 (Reencrypt) | Pipeline API access |
| TrustyAI Service | OpenShift Route | {instance}-{namespace}.{domain} | 443/TCP | HTTPS | TLS 1.2+ (Reencrypt) | Explainability/fairness metrics |

### External Egress Dependencies

| Component | Destination | Port | Protocol | Encryption | Purpose |
|-----------|-------------|------|----------|------------|---------|
| KServe/ModelMesh | S3-compatible Storage (AWS S3, MinIO, Ceph) | 443/TCP | HTTPS | TLS 1.2+ | Model artifact download |
| Data Science Pipelines | S3-compatible Storage | 443/TCP | HTTPS | TLS 1.2+ | Pipeline artifacts and outputs |
| Data Science Pipelines | External MySQL/MariaDB (optional) | 3306/TCP | TCP | TLS (optional) | Pipeline metadata storage |
| Notebooks | PyPI, Conda repositories | 443/TCP | HTTPS | TLS 1.2+ | Install Python packages |
| Notebooks | Git repositories (GitHub, GitLab) | 443/TCP | HTTPS | TLS 1.2+ | Clone source code |
| Notebooks | S3 Storage | 443/TCP | HTTPS | TLS 1.2+ | Data science datasets and results |
| Training Jobs | S3 Storage | 443/TCP | HTTPS | TLS 1.2+ | Training data and model checkpoints |
| Training Jobs | Container Registries (Quay, Docker Hub) | 443/TCP | HTTPS | TLS 1.2+ | Pull training framework images |
| RHODS Operator | GitHub (manifests) | 443/TCP | HTTPS | TLS 1.2+ | Fetch component Kustomize manifests |
| All Operators | Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | Cluster resource management |
| All Operators | Container Registries | 443/TCP | HTTPS | TLS 1.2+ | Pull component images |

### Internal Service Mesh

| Setting | Value | Components Using | Purpose |
|---------|-------|------------------|---------|
| mTLS Mode | PERMISSIVE (default) or STRICT | KServe, ModelMesh | Service-to-service encryption |
| Peer Authentication | Namespace-scoped | Inference namespaces | Configure mTLS for model serving |
| Virtual Services | Per InferenceService | KServe | Traffic routing and canary deployments |
| Authorization Policies | Per InferenceService | KServe + Authorino | Token-based authentication |
| Telemetry | Namespace-scoped | KServe | Metrics collection configuration |
| Ingress Gateway | knative-serving/knative-ingress-gateway | KServe Serverless | External traffic entry point |

## Platform Security

### RBAC Summary

**Platform-Level Cluster Roles**:

| Component | ClusterRole Purpose | Key Permissions |
|-----------|-------------------|-----------------|
| RHODS Operator | Platform orchestration | Full access to all component CRDs, namespaces, RBAC, operators |
| ODH Dashboard | Resource management | Create/manage namespaces, notebooks, pipelines, models, users |
| Notebook Controller | Notebook lifecycle | StatefulSets, Services, VirtualServices for notebooks |
| Model Controller | Serving integration | InferenceServices, Routes, Istio resources, monitoring |
| Training Operator | Training jobs | PyTorchJob, TFJob, MPIJob, XGBoostJob, PodGroups |
| Kueue | Workload admission | Jobs, Workloads, ClusterQueues, ResourceFlavors |
| CodeFlare Operator | Distributed workloads | RayClusters, AppWrappers, Routes, NetworkPolicies |
| KubeRay Operator | Ray clusters | Pods, Services, Routes, Ingresses for Ray |
| TrustyAI Operator | Model monitoring | InferenceServices (patch), Routes, ServiceMonitors |

**Common Permission Patterns**:
- **Full CRD Management**: All operators manage their respective CRDs with create/delete/get/list/patch/update/watch
- **Namespace Management**: RHODS Operator and Dashboard can create/manage namespaces for user projects
- **Service Mesh Integration**: Model Controller and KServe create Istio VirtualServices and PeerAuthentications
- **Monitoring Integration**: All operators create ServiceMonitors/PodMonitors for Prometheus
- **OpenShift Integration**: Operators create Routes for external access, leverage OAuth for authentication

### Secrets Inventory

| Component | Secret Name | Type | Purpose |
|-----------|-------------|------|---------|
| ODH Dashboard | dashboard-proxy-tls | kubernetes.io/tls | OAuth proxy TLS certificate |
| ODH Dashboard | dashboard-oauth-config-generated | Opaque | OAuth cookie secret |
| Notebooks | notebook-{user}-oauth-config | Opaque | Per-notebook OAuth proxy config |
| Data Science Pipelines | ds-pipeline-db-{name} | Opaque | MariaDB credentials (auto-generated) |
| Data Science Pipelines | ds-pipeline-s3-{name} | Opaque | S3/Minio access keys |
| KServe/ModelMesh | storage-config | Opaque | Aggregated S3 credentials for model storage |
| KServe | kserve-webhook-server-cert | kubernetes.io/tls | Webhook server TLS certificate |
| ModelMesh | modelmesh-webhook-server-cert | kubernetes.io/tls | Webhook server TLS certificate |
| CodeFlare | {raycluster}-ca | Opaque | Ray cluster CA certificate for mTLS |
| Training Operator | webhook-server-cert | kubernetes.io/tls | Admission webhook certificate |
| TrustyAI | {instance}-tls | kubernetes.io/tls | OAuth proxy TLS certificate |
| All Operators | controller-manager-token | ServiceAccount Token | Kubernetes API authentication |

### Authentication Mechanisms

| Pattern | Components Using | Enforcement Point | Protocol |
|---------|------------------|-------------------|----------|
| **OpenShift OAuth (Cookie + Token)** | Dashboard, Notebooks, RStudio, Code Server, TrustyAI | OAuth Proxy Sidecar | HTTPS with Bearer Token |
| **Bearer Tokens (JWT)** | KServe, ModelMesh (via Authorino) | Istio AuthorizationPolicy | HTTPS with JWT validation |
| **mTLS (Service Mesh)** | KServe, ModelMesh (optional) | Istio PeerAuthentication | HTTPS with client certificates |
| **ServiceAccount Tokens** | All Operators → Kubernetes API | Kubernetes API Server | HTTPS with JWT |
| **AWS Signature v4** | Storage access to S3 | S3 endpoints | HTTPS with HMAC signatures |
| **MySQL Native Auth** | Pipelines → MariaDB | MariaDB server | TCP with username/password |
| **Webhook mTLS** | API Server → Operator Webhooks | Kubernetes API Server | HTTPS with CA bundle validation |

### Network Policies

**Operator Network Policies**:
- **Model Controller**: Ingress restricted to port 9443 (webhook) from API server
- **Kueue**: Ingress restricted to port 9443 (webhook) from API server
- **ModelMesh**: Ingress allowed on 8033 (gRPC), 8008 (REST), 2112 (metrics) from modelmesh pods and external

**Workload Network Policies** (dynamically created):
- **RayCluster**: Head pod allows ingress from workers, same namespace, and Prometheus
- **Data Science Pipelines**: MariaDB restricted to DSPO operator and API server pods
- **Notebooks**: Default Kubernetes policies (no custom restrictions)

## Platform APIs

### Custom Resource Definitions

**Platform Management**:

| Component | API Group | Kind | Scope | Purpose |
|-----------|-----------|------|-------|---------|
| RHODS Operator | datasciencecluster.opendatahub.io | DataScienceCluster | Cluster | Define which platform components to deploy |
| RHODS Operator | dscinitialization.opendatahub.io | DSCInitialization | Cluster | Initialize platform infrastructure (namespaces, service mesh, monitoring) |
| RHODS Operator | features.opendatahub.io | FeatureTracker | Cluster | Track resources for cross-namespace garbage collection |
| ODH Dashboard | dashboard.opendatahub.io | AcceleratorProfile | Namespaced | GPU/accelerator device configurations |
| ODH Dashboard | dashboard.opendatahub.io | OdhApplication | Namespaced | Application catalog entries |
| ODH Dashboard | opendatahub.io | OdhDashboardConfig | Namespaced | Dashboard feature flags |
| ODH Dashboard | dashboard.opendatahub.io | OdhDocument | Namespaced | Documentation links |
| ODH Dashboard | console.openshift.io | OdhQuickStart | Namespaced | Interactive tutorials |

**Workbenches**:

| Component | API Group | Kind | Scope | Purpose |
|-----------|-----------|------|-------|---------|
| Notebook Controller | kubeflow.org | Notebook | Namespaced | Jupyter notebook instances with PodSpec template |

**Model Serving**:

| Component | API Group | Kind | Scope | Purpose |
|-----------|-----------|------|-------|---------|
| KServe | serving.kserve.io | InferenceService | Namespaced | Model serving with predictor, transformer, explainer |
| KServe | serving.kserve.io | ServingRuntime | Namespaced | Model server runtime configuration |
| KServe | serving.kserve.io | TrainedModel | Namespaced | Trained model artifact with storage location |
| KServe | serving.kserve.io | InferenceGraph | Namespaced | Multi-step inference pipelines |
| ModelMesh | serving.kserve.io | Predictor | Namespaced | ModelMesh model serving definition |

**ML Workflows**:

| Component | API Group | Kind | Scope | Purpose |
|-----------|-----------|------|-------|---------|
| Data Science Pipelines | datasciencepipelinesapplications.opendatahub.io | DataSciencePipelinesApplication | Namespaced | Pipeline stack with database, storage, components |

**Distributed Training**:

| Component | API Group | Kind | Scope | Purpose |
|-----------|-----------|------|-------|---------|
| Training Operator | kubeflow.org | PyTorchJob | Namespaced | Distributed PyTorch training with elastic support |
| Training Operator | kubeflow.org | TFJob | Namespaced | Distributed TensorFlow training |
| Training Operator | kubeflow.org | MPIJob | Namespaced | MPI-based distributed training |
| Training Operator | kubeflow.org | XGBoostJob | Namespaced | Distributed XGBoost training |
| Training Operator | kubeflow.org | MXJob | Namespaced | Distributed MXNet training |
| Training Operator | kubeflow.org | PaddleJob | Namespaced | Distributed PaddlePaddle training |

**Distributed Computing**:

| Component | API Group | Kind | Scope | Purpose |
|-----------|-----------|------|-------|---------|
| KubeRay | ray.io | RayCluster | Namespaced | Ray cluster with head and worker groups |
| KubeRay | ray.io | RayJob | Namespaced | Ray job with cluster template and lifecycle |
| KubeRay | ray.io | RayService | Namespaced | Ray Serve deployment with zero-downtime upgrades |
| CodeFlare | workload.codeflare.dev | AppWrapper | Namespaced | Batch workload scheduling with Kueue |

**Workload Management**:

| Component | API Group | Kind | Scope | Purpose |
|-----------|-----------|------|-------|---------|
| Kueue | kueue.x-k8s.io | ClusterQueue | Cluster | Cluster-wide resource quotas and admission policies |
| Kueue | kueue.x-k8s.io | LocalQueue | Namespaced | User-facing queue for workload submission |
| Kueue | kueue.x-k8s.io | Workload | Namespaced | Job submission with resource requirements |
| Kueue | kueue.x-k8s.io | ResourceFlavor | Cluster | Resource types/flavors with node selectors |
| Kueue | kueue.x-k8s.io | WorkloadPriorityClass | Cluster | Priority values for workload scheduling |

**AI Governance**:

| Component | API Group | Kind | Scope | Purpose |
|-----------|-----------|------|-------|---------|
| TrustyAI | trustyai.opendatahub.io | TrustyAIService | Namespaced | AI fairness and explainability service |

### Public HTTP Endpoints

**User-Facing Web Interfaces**:

| Component | Path | Port | Protocol | Auth | Purpose |
|-----------|------|------|----------|------|---------|
| ODH Dashboard | / | 8443/TCP | HTTPS | OAuth | Platform management console |
| Jupyter Notebook | /notebook/{ns}/{name}/ | 8888/TCP | HTTP (via OAuth proxy) | OAuth | Notebook IDE |
| RStudio | / | 8787/TCP | HTTP (via OAuth proxy) | OAuth | R IDE |
| Code Server | / | 8080/TCP | HTTP (via OAuth proxy) | OAuth | VS Code IDE |
| Ray Dashboard | / | 8265/TCP | HTTP (via OAuth proxy) | OAuth | Ray cluster monitoring |
| Pipelines UI | / | 8443/TCP | HTTPS | OAuth | Pipeline visualization |

**API Endpoints**:

| Component | Path | Port | Protocol | Auth | Purpose |
|-----------|------|------|----------|------|---------|
| Dashboard | /api/* | 8080/TCP | HTTP (via OAuth proxy) | Bearer Token | Resource management APIs |
| Pipelines | /apis/* | 8888/TCP | HTTP (via OAuth proxy) | Bearer Token | Pipeline CRUD, runs, experiments |
| KServe | /v1/models/{model}:predict | 8080/TCP | HTTP/HTTPS | Bearer/None | V1 inference protocol |
| KServe | /v2/models/{model}/infer | 8080/TCP | HTTP/HTTPS | Bearer/None | V2 inference protocol |
| ModelMesh | /v2/models/{model}/infer | 8008/TCP | HTTP | None (internal) | V2 REST inference via proxy |
| TrustyAI | /* | 8443/TCP | HTTPS | OAuth | Fairness and explainability APIs |

**Metrics Endpoints** (Prometheus scraping):

All components expose `/metrics` on port 8080/TCP (HTTP) for Prometheus metrics collection.

### gRPC Services

| Component | Service | Port | Purpose |
|-----------|---------|------|---------|
| Data Science Pipelines | ds-pipeline API | 8887/TCP | Pipeline submission and management |
| Data Science Pipelines | MLMD MetadataStoreService | 8080/TCP | ML metadata and lineage tracking |
| ModelMesh | ModelMesh Inference | 8033/TCP | KServe V2 gRPC inference protocol |
| KServe | GRPCInferenceService | 8081/TCP | V2 gRPC inference for model servers |

## Key Platform Workflows

### Workflow 1: Notebook to Model Training to Serving

| Step | Component | Action | Next Component |
|------|-----------|--------|----------------|
| 1 | Dashboard | User creates data science project (namespace) | Kubernetes API |
| 2 | Dashboard | User creates notebook workbench | Notebook Controller |
| 3 | Notebook Controller | Creates StatefulSet with notebook image | Kubelet |
| 4 | User (in Notebook) | Develops and trains model, saves to S3 | S3 Storage |
| 5 | Dashboard | User creates InferenceService for model | KServe |
| 6 | KServe | Creates Knative Service (serverless mode) | Knative Serving |
| 7 | Model Controller | Creates Route, VirtualService, AuthConfig | OpenShift Router, Istio |
| 8 | KServe Pod (storage-initializer) | Downloads model from S3 | S3 Storage |
| 9 | External Client | Sends inference request to model endpoint | Istio Gateway → KServe Pod |

### Workflow 2: Pipeline-Driven Training and Deployment

| Step | Component | Action | Next Component |
|------|-----------|--------|----------------|
| 1 | Dashboard | User creates DSPA instance | Data Science Pipelines Operator |
| 2 | DSPO | Deploys Argo Workflows, MariaDB, Minio | Kubernetes |
| 3 | User (via Pipelines UI) | Defines pipeline with training and deployment steps | Pipelines API |
| 4 | Pipelines API | Submits Argo Workflow | Argo Workflows |
| 5 | Argo Workflow | Creates training job pod | Training Operator (PyTorchJob) |
| 6 | Training Job | Reads data from S3, trains model, saves checkpoint | S3 Storage |
| 7 | Argo Workflow | Creates InferenceService for trained model | KServe |
| 8 | KServe | Deploys model and registers metadata | Model Registry (optional) |

### Workflow 3: Distributed Training with Queue Management

| Step | Component | Action | Next Component |
|------|-----------|--------|----------------|
| 1 | User | Submits PyTorchJob with queue annotation | Kubernetes API |
| 2 | Kueue Webhook | Intercepts job creation, injects queue info | Kubernetes API |
| 3 | Kueue Controller | Creates Workload CR, checks quota | ClusterQueue |
| 4 | Kueue Controller | Admits workload if quota available | Training Operator |
| 5 | Training Operator | Creates worker pods | Kubernetes Scheduler |
| 6 | Scheduler Plugins | Gang schedules all pods together | Kubelet |
| 7 | Training Pods | Execute distributed training | Inter-pod communication |
| 8 | Training Pods | Save checkpoints to S3 | S3 Storage |

### Workflow 4: Ray Distributed Compute

| Step | Component | Action | Next Component |
|------|-----------|--------|----------------|
| 1 | User | Creates RayCluster CR | Kubernetes API |
| 2 | KubeRay Operator | Creates head and worker pods | Kubelet |
| 3 | CodeFlare Operator (optional) | Injects OAuth proxy for dashboard | Ray Head Pod |
| 4 | Ray Workers | Connect to head node GCS | Ray Head (port 6379) |
| 5 | User | Submits Ray job via dashboard or API | Ray Head (port 8265) |
| 6 | Ray | Distributes tasks across workers | Ray Workers |
| 7 | CodeFlare (with AppWrapper) | Integrates with Kueue for resource management | Kueue |

### Workflow 5: Model Monitoring with TrustyAI

| Step | Component | Action | Next Component |
|------|-----------|--------|----------------|
| 1 | User | Creates TrustyAIService CR | TrustyAI Operator |
| 2 | TrustyAI Operator | Deploys TrustyAI service, creates PVC | Kubernetes |
| 3 | TrustyAI Operator | Patches ModelMesh deployment with payload processor env | ModelMesh |
| 4 | Client | Sends inference request to ModelMesh | ModelMesh |
| 5 | ModelMesh | Forwards request and response to TrustyAI service | TrustyAI Service |
| 6 | TrustyAI Service | Stores inference data, calculates fairness metrics | PVC, Prometheus |
| 7 | User | Queries fairness and explainability metrics | TrustyAI API (via OAuth) |

## Deployment Architecture

### Deployment Topology

**Control Plane** (openshift-operators, opendatahub):
- RHODS Operator (1 replica)
- Component Operators (1-3 replicas with leader election)
- ODH Dashboard (2 replicas with anti-affinity)

**User Plane** (redhat-ods-applications, user namespaces):
- Notebook workbenches (1 pod per notebook)
- Model serving deployments (1-N replicas based on autoscaling)
- Training jobs (distributed pods)
- Ray clusters (1 head + N workers)
- Pipeline infrastructure (API server, persistence agent, scheduler, UI)

**Infrastructure Plane** (istio-system, redhat-ods-monitoring):
- Istio control plane (istiod)
- Prometheus, Alertmanager, Grafana
- Authorino

### Resource Requirements

**Operator Minimum Requirements**:

| Component | CPU Request | Memory Request | Notes |
|-----------|-------------|----------------|-------|
| RHODS Operator | 500m | 256Mi | Can use up to 4Gi memory |
| ODH Dashboard | 500m | 1Gi | Per replica (2 replicas) |
| Notebook Controller | Not specified | Not specified | Lightweight operator |
| Model Controller | 10m | 64Mi | Minimal footprint |
| Training Operator | Not specified | Not specified | Lightweight operator |
| Kueue | 500m | 512Mi | Single replica |
| KubeRay Operator | 100m | 512Mi | Default limits |
| CodeFlare Operator | 1 core | 1Gi | Fixed requests/limits |
| TrustyAI Operator | 10m | 64Mi | Minimal footprint |

**User Workload Examples**:

| Workload Type | Typical Resources | Scalability |
|---------------|-------------------|-------------|
| Jupyter Notebook | 500m CPU, 2Gi memory | 1 pod per user, can request more |
| Small Model Serving | 100m CPU, 200Mi memory | KServe autoscales 0-N based on traffic |
| GPU Training Job | 4+ CPU, 16Gi+ memory, 1+ GPU | Distributed across multiple nodes |
| Ray Cluster | Head: 1 CPU, 4Gi; Workers: 4 CPU, 16Gi | Autoscales based on workload |

## Version-Specific Changes (2.10)

| Component | Key Changes in 2.10 |
|-----------|---------------------|
| KServe | - CVE-2024-6119 fix (Type Confusion)<br>- Updated storage-initializer, agent, router components<br>- Konflux integration updates |
| Data Science Pipelines | - MariaDB network policy deployment fix<br>- Removed image health check validation<br>- Updated release automation for DSP v2 |
| Kueue | - Rebased on upstream v0.6.2<br>- RHTAP/Konflux purge<br>- Default waitForPodsReady set to true<br>- Enhanced RBAC for non-admin users |
| Notebook Images | - Habana notebook deactivated from manifests<br>- CVE fixes in jupyter-server-proxy<br>- Kustomize version pinning |
| Training Operator | - Updated to Kubernetes 1.27 dependencies<br>- scheduler-plugins as default gang scheduler<br>- PyTorchJob ENV fixes for torchrun |
| TrustyAI | - Route termination changed to reencrypt<br>- Golang net library updated to 0.23.0<br>- ODH operator readiness checks added |
| CodeFlare | - Based on upstream v1.4.3<br>- AppWrapper v0.12.0<br>- KubeRay v1.1.0 support |
| KubeRay | - Upgraded to Kubernetes 1.22.2<br>- Added SecurityContext for restricted pod-security<br>- CVE fixes for golang.org/x/net |

## Platform Maturity

### Component Statistics

- **Total Components**: 13
- **Operator-based Components**: 11 (85%)
- **Container Image Repository**: 1 (Notebooks)
- **Web Application**: 1 (Dashboard - includes backend service)

### Service Mesh Coverage

- **Service Mesh Integration**: Optional but recommended
- **Components with Mesh Support**: KServe, ModelMesh, Notebooks (via VirtualServices)
- **mTLS Enforcement**: PERMISSIVE (default), configurable to STRICT
- **Components Requiring Mesh**: KServe Serverless mode (for full feature set)

### API Maturity

| API Group | Version | Status | Components Using |
|-----------|---------|--------|------------------|
| datasciencecluster.opendatahub.io | v1 | GA | RHODS Operator |
| dscinitialization.opendatahub.io | v1 | GA | RHODS Operator |
| serving.kserve.io | v1beta1 | Beta | KServe, ModelMesh, Model Controller |
| serving.kserve.io | v1alpha1 | Alpha | ModelMesh, KServe (TrainedModel, InferenceGraph) |
| kubeflow.org | v1 | GA | Training Operator, Notebook Controller |
| kueue.x-k8s.io | v1beta1 | Beta | Kueue |
| ray.io | v1 | GA | KubeRay |
| workload.codeflare.dev | v1beta2 | Beta | CodeFlare |
| trustyai.opendatahub.io | v1alpha1 | Alpha | TrustyAI |

### Security Posture

- **Pod Security Standards**: All operators compatible with Restricted profile
- **RBAC Enforcement**: Comprehensive cluster and namespace-scoped roles
- **Network Policies**: Implemented for operators (webhooks) and select workloads
- **mTLS Support**: Optional for service mesh, required for webhook communications
- **Authentication**: OAuth (user-facing), ServiceAccount tokens (operators), Authorino (model serving)
- **Secrets Management**: Auto-rotation for TLS certs (service-ca), manual rotation for credentials
- **FIPS Compliance**: Training Operator built with `-tags strictfipsruntime`

### Observability Maturity

- **Metrics Coverage**: 100% (all components expose Prometheus metrics)
- **ServiceMonitor Usage**: All components create ServiceMonitors for Prometheus scraping
- **Health Checks**: All operators implement /healthz and /readyz endpoints
- **Logging**: Structured logging with configurable levels across all components
- **Distributed Tracing**: Available via Istio when service mesh enabled

## Next Steps for Documentation

### Recommended Documentation Enhancements

1. **Architecture Diagrams**: Generate visual diagrams from this platform architecture
   - Component relationship diagram
   - Network topology diagram
   - Data flow sequence diagrams
   - Deployment architecture diagram

2. **Security Architecture Review (SAR)**: Create security-focused documentation
   - Network security zones and trust boundaries
   - Authentication and authorization flow diagrams
   - Secret management lifecycle
   - Compliance mapping (FIPS, PCI, HIPAA)

3. **Operations Runbooks**: Develop operational guides
   - Component upgrade procedures
   - Disaster recovery procedures
   - Capacity planning guidelines
   - Troubleshooting decision trees

4. **User Documentation**: Create user-facing guides
   - Getting started tutorials
   - Best practices for model serving
   - Distributed training patterns
   - Resource quota management

5. **ADRs (Architecture Decision Records)**: Document key architectural decisions
   - Why Kueue for workload management
   - Service mesh integration approach
   - Multi-tenant isolation strategy
   - Storage architecture for models and artifacts

### Integration Points Needing Documentation

1. **Model Registry Integration**: Document how components integrate with model registry for lineage tracking
2. **Custom CA Certificates**: Document enterprise PKI integration across all components
3. **GPU/Accelerator Support**: Comprehensive guide for GPU scheduling and accelerator profiles
4. **Multi-tenancy Patterns**: Document isolation boundaries and resource sharing patterns
5. **Disaster Recovery**: Document backup and restore procedures for stateful components

### Performance and Scalability

Document platform limits and scalability characteristics:
- Maximum concurrent notebooks per cluster
- Model serving throughput and latency SLAs
- Training job concurrency limits
- Pipeline execution parallelism
- Prometheus retention and cardinality limits

---

**Document Generated**: 2026-03-15
**Source**: Aggregated from 13 component architecture files in architecture/rhoai-2.10/
**Components Analyzed**: CodeFlare Operator, Data Science Pipelines, KServe, Notebook Controller, Notebook Images, KubeRay, Kueue, ModelMesh Serving, ODH Dashboard, ODH Model Controller, RHODS Operator, Training Operator, TrustyAI Service Operator
