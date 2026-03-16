# Platform: Red Hat OpenShift AI 2.9

## Metadata
- **Distribution**: RHOAI
- **Version**: 2.9
- **Release Date**: 2024
- **Base Platform**: OpenShift Container Platform 4.12+
- **Components Analyzed**: 12

## Platform Overview

Red Hat OpenShift AI (RHOAI) 2.9 is an enterprise AI/ML platform that provides comprehensive tools for the entire machine learning lifecycle, from data exploration and model development to training, deployment, and monitoring. The platform integrates notebook-based development environments, scalable distributed computing, model serving with both single-model and multi-model approaches, ML pipeline orchestration, and explainability/monitoring capabilities.

Built on OpenShift, RHOAI leverages Kubernetes-native patterns with custom resource definitions (CRDs) and operators to deliver a consistent, declarative experience. The platform emphasizes production readiness through integration with Red Hat Service Mesh for secure mTLS communication, OpenShift OAuth for authentication, and comprehensive monitoring via Prometheus. Components are designed to work together seamlessly while remaining modular—users can selectively enable only the capabilities they need.

RHOAI 2.9 represents a mature platform with support for GPU acceleration, distributed workload management via Kueue and Ray, multiple model serving runtimes (KServe serverless, ModelMesh for multi-model efficiency), and a unified dashboard for managing all platform components. The architecture prioritizes enterprise requirements including security, multi-tenancy, observability, and integration with existing OpenShift capabilities.

## Component Inventory

| Component | Type | Version | Purpose |
|-----------|------|---------|---------|
| RHODS Operator | Operator | v1.6.0-556 | Core platform operator managing component lifecycle and platform configuration |
| ODH Dashboard | Web Application | v1.21.0-18 | Unified web UI for managing projects, workbenches, models, and pipelines |
| Notebook Controller | Operator | v1.27.0 | Manages Jupyter notebook instances as Kubernetes workloads |
| Workbench Images | Container Images | v1.1.1-555 | Pre-configured JupyterLab, VS Code, and RStudio environments with ML libraries |
| Data Science Pipelines | Operator | cf823f3 | ML workflow orchestration using Kubeflow Pipelines (Tekton/Argo backends) |
| KServe | Operator | 69cb9fee0 | Serverless model serving with autoscaling and traffic management |
| ModelMesh Serving | Operator | v1.27.0-188 | Multi-model serving for efficient resource utilization |
| ODH Model Controller | Operator | v1.27.0-297 | OpenShift integration for model serving (Routes, Service Mesh, Authorino) |
| KubeRay Operator | Operator | v1.1.0 | Distributed computing framework for ML/AI workloads |
| CodeFlare Operator | Operator | v-2160 | Security enhancements for Ray clusters (OAuth, mTLS, NetworkPolicies) |
| Kueue | Operator | v0.6.2 | Job queueing and fair resource sharing for batch workloads |
| TrustyAI Service Operator | Operator | f6fd5aa | Model explainability and bias detection services |

## Component Relationships

### Dependency Graph

```
┌──────────────────────────────────────────────────────────────────────────────┐
│                           RHODS Operator (Core)                              │
│  Deploys and manages all platform components via DSC/DSCI CRDs               │
└────┬─────────────────────────────────────────────────────────────────────────┘
     │
     ├─────────────────────────────────────────────────────────────────────────┐
     │                                                                          │
     ▼                                                                          ▼
┌──────────────────┐                                                  ┌─────────────────┐
│  ODH Dashboard   │◄─────────────────────────────────────────────────┤ Service Mesh    │
│  (User Interface)│                                                  │  (Istio/Maistra)│
└────┬─────────────┘                                                  └────┬────────────┘
     │                                                                      │
     │ Manages via API                                                      │ Provides mTLS
     │                                                                      │
     ▼                                                                      ▼
┌──────────────────────────────────────────────────────────────────────────────┐
│                         Workload Components                                  │
├──────────────────┬──────────────────┬──────────────────┬────────────────────┤
│ Notebook         │ Data Science     │ Model Serving    │ Distributed        │
│ Controller       │ Pipelines        │                  │ Computing          │
│                  │                  │                  │                    │
│ - Manages        │ - Orchestrates   │ ┌──────────────┐ │ ┌────────────────┐ │
│   Jupyter pods   │   ML workflows   │ │   KServe     │ │ │  KubeRay       │ │
│ - Integrates     │ - Tekton/Argo    │ │   (Serverless│ │ │  (Distributed  │ │
│   with Dashboard │   backends       │ │   Serving)   │ │ │   Ray Clusters)│ │
│                  │ - S3/Database    │ └───┬──────────┘ │ └───┬────────────┘ │
│                  │   storage        │     │            │     │              │
│                  │                  │     │            │     │              │
│                  │                  │ ┌───▼──────────┐ │ ┌───▼────────────┐ │
│                  │                  │ │ ODH Model    │ │ │  CodeFlare     │ │
│                  │                  │ │ Controller   │ │ │  (Security)    │ │
│                  │                  │ │ (OpenShift   │ │ │  - OAuth       │ │
│                  │                  │ │  Integration)│ │ │  - mTLS        │ │
│                  │                  │ └──────────────┘ │ │  - NetPolicies │ │
│                  │                  │                  │ └────────────────┘ │
│                  │                  │ ┌──────────────┐ │                    │
│                  │                  │ │ ModelMesh    │ │ ┌────────────────┐ │
│                  │                  │ │ (Multi-model)│ │ │     Kueue      │ │
│                  │                  │ └──────────────┘ │ │ (Job Queueing) │ │
│                  │                  │                  │ │ - Fair sharing │ │
│                  │                  │ ┌──────────────┐ │ │ - Priorities   │ │
│                  │                  │ │  TrustyAI    │ │ │ - Preemption   │ │
│                  │                  │ │ (Monitoring/ │ │ └────┬───────────┘ │
│                  │                  │ │  Explain)    │ │      │             │
│                  │                  │ └──────────────┘ │      │ Manages     │
└──────────────────┴──────────────────┴──────────────────┴──────┴─────────────┘
                                                                  │
                                                                  ▼
                                                    ┌─────────────────────────┐
                                                    │  Batch Jobs/Training    │
                                                    │  (PyTorchJob, TFJob,    │
                                                    │   RayJob, K8s Jobs)     │
                                                    └─────────────────────────┘
```

### Integration Patterns

**API Call Pattern**: Dashboard → Kubernetes API → Component Controllers
- Dashboard calls Kubernetes API to create/manage Notebook, InferenceService, DSPA CRs
- Component operators watch and reconcile their respective CRDs
- Status updates flow back through API to Dashboard UI

**Event-Driven Pattern**: Component Operators → Kubernetes Watch API → Reconciliation
- All operators use controller-runtime framework with watch-reconcile loops
- Changes to CRs or dependent resources trigger reconciliation
- Operators create/update/delete Kubernetes resources declaratively

**Sidecar Pattern**: OAuth Proxy for Authentication
- Dashboard, ModelMesh, TrustyAI, and other services use OpenShift OAuth proxy sidecar
- OAuth proxy intercepts HTTP requests, validates tokens, forwards to application container
- Consistent authentication across platform components

**Service Mesh Pattern**: mTLS for Inter-Service Communication
- KServe, ModelMesh, and other services participate in Istio service mesh
- Automatic mTLS encryption for pod-to-pod communication
- PeerAuthentication CRDs enforce STRICT mTLS mode

**Storage Integration Pattern**: S3-Compatible Object Storage
- Data Science Pipelines, KServe, ModelMesh all use S3 API for artifact storage
- Common storage-config secret pattern for credentials
- Support for AWS S3, MinIO, IBM Cloud Object Storage

**Monitoring Integration Pattern**: ServiceMonitor/PodMonitor CRDs
- All operators expose /metrics endpoints on port 8080
- Prometheus Operator watches ServiceMonitor/PodMonitor CRs
- Metrics aggregated in OpenShift monitoring namespace

### Central Components

**Core Platform Services** (Most dependencies):
1. **RHODS Operator**: Central orchestrator managing all component deployments
2. **OpenShift Service Mesh (Istio)**: Provides mTLS, traffic management, observability
3. **Kubernetes API Server**: Central coordination point for all operators
4. **OpenShift OAuth**: Authentication provider for user-facing services
5. **Prometheus**: Metrics collection and monitoring for entire platform

**User-Facing Services**:
1. **ODH Dashboard**: Primary user interface for all platform interactions
2. **Notebook Workbenches**: Interactive development environments
3. **Model Serving Endpoints**: Production inference APIs (KServe/ModelMesh)

**Infrastructure Services**:
1. **Data Science Pipelines**: Workflow orchestration engine
2. **Kueue**: Resource management and fair queueing
3. **Model Registry**: Model versioning and metadata (future integration)

## Platform Network Architecture

### Namespaces

| Namespace | Purpose | Components |
|-----------|---------|------------|
| redhat-ods-operator | Operator deployment | RHODS Operator controller-manager |
| redhat-ods-applications | Application workloads | Dashboard, Notebook Controller, Model Controllers, Component Operators |
| redhat-ods-monitoring | Monitoring stack | Prometheus, Grafana, Alertmanager (RHOAI-specific) |
| istio-system | Service mesh control plane | Istio control plane, Ingress Gateway |
| openshift-monitoring | Cluster monitoring | Cluster Prometheus, Thanos |
| User project namespaces | Data science workloads | Notebooks, InferenceServices, Pipelines, RayClusters |

### External Ingress Points

| Component | Ingress Type | Hosts | Port | Protocol | Encryption | Purpose |
|-----------|--------------|-------|------|----------|------------|---------|
| ODH Dashboard | OpenShift Route | {cluster-domain} | 443/TCP | HTTPS | TLS 1.2+ (Reencrypt) | Web UI for platform management |
| Notebook Workbenches | OpenShift Route | Per notebook | 443/TCP | HTTPS | TLS 1.2+ (Edge) | JupyterLab/VS Code/RStudio access |
| KServe InferenceServices | OpenShift Route + Istio VirtualService | {isvc}-{ns}.{domain} | 443/TCP | HTTPS | TLS 1.2+ (Edge → mTLS) | Model inference endpoints |
| ModelMesh InferenceServices | OpenShift Route | {model}-{ns}.{domain} | 443/TCP | HTTPS | TLS 1.2+ (Edge) | Multi-model inference endpoints |
| Data Science Pipelines API | OpenShift Route | {dspa}-{ns}.{domain} | 443/TCP | HTTPS | TLS 1.2+ (Reencrypt) | Pipeline management API |
| Ray Dashboard | OpenShift Route | {cluster}-{ns}.{domain} | 443/TCP | HTTPS | TLS 1.2+ (Reencrypt) | Ray cluster monitoring UI |
| TrustyAI Service | OpenShift Route | {trustyai}-{ns}.{domain} | 443/TCP | HTTPS | TLS 1.2+ (Passthrough) | Model explainability API |

### External Egress Dependencies

| Component | Destination | Port | Protocol | Encryption | Purpose |
|-----------|-------------|------|----------|------------|---------|
| KServe, ModelMesh, Pipelines | S3-compatible Storage (AWS, MinIO, IBM COS) | 443/TCP | HTTPS | TLS 1.2+ | Model artifacts, pipeline data, datasets |
| Data Science Pipelines | External Database (MariaDB/MySQL) | 3306/TCP or 5432/TCP | TCP | TLS (optional) | Pipeline metadata storage |
| Workbench Images | PyPI, Conda, GitHub | 443/TCP | HTTPS | TLS 1.2+ | Package installation, code repositories |
| All Operators | Container Registries (Quay.io, RedHat) | 443/TCP | HTTPS | TLS 1.2+ | Pull component container images |
| All Components | Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | Resource management and watches |
| Dashboard, Operators | OpenShift OAuth Server | 443/TCP | HTTPS | TLS 1.2+ | User authentication |
| Dashboard, Model Controller | Prometheus/Thanos Querier | 9092/TCP | HTTPS | TLS 1.2+ | Query metrics for monitoring |

### Internal Service Mesh

| Setting | Value | Components Using |
|---------|-------|------------------|
| mTLS Mode | STRICT (when enabled) | KServe InferenceServices, ModelMesh serving pods, Data Science Pipelines |
| Peer Authentication | STRICT | All services in service mesh member namespaces |
| Service Mesh Version | 2.x (Maistra/Istio) | Platform-wide when KServe enabled with Service Mesh |
| Ingress Gateway | knative-ingress-gateway | KServe serverless inference services |
| Authorization | Authorino (optional) | KServe InferenceServices when auth enabled |

## Platform Security

### RBAC Summary

**Cluster-Scoped Roles** (Selected key permissions):

| Component | ClusterRole | Key Permissions | Purpose |
|-----------|-------------|-----------------|---------|
| RHODS Operator | controller-manager-role | Full control over DSC, DSCI, all component CRDs, deployments, services, RBAC, SCCs | Platform orchestration and component deployment |
| ODH Dashboard | odh-dashboard | Read nodes, configmaps, secrets; manage namespaces, rolebindings; read all component CRs | User interface for platform management |
| Notebook Controller | notebook-controller-role | Manage statefulsets, services, notebooks, virtualservices | Notebook lifecycle management |
| Data Science Pipelines | manager-role | Manage DSPA CRs, deployments, Argo/Tekton resources, secrets | Pipeline orchestration |
| KServe | kserve-manager-role | Manage InferenceServices, ServingRuntimes, Knative Services, Istio VirtualServices | Model serving lifecycle |
| ODH Model Controller | odh-model-controller-role | Manage Routes, Istio resources, Authorino AuthConfigs, NetworkPolicies, ServiceMonitors | OpenShift integration for model serving |
| ModelMesh Serving | modelmesh-controller-role | Manage InferenceServices, Predictors, ServingRuntimes, Deployments, HorizontalPodAutoscalers | Multi-model serving |
| KubeRay | kuberay-operator | Manage RayClusters, RayJobs, RayServices, pods, services, ingresses, routes | Distributed computing |
| CodeFlare | manager-role | Manage RayClusters, secrets, routes, networkpolicies, clusterrolebindings | Ray security enhancements |
| Kueue | kueue-manager-role | Manage ClusterQueues, LocalQueues, Workloads, AdmissionChecks; watch all job types | Job queueing and resource management |
| TrustyAI | manager-role | Manage TrustyAIServices, InferenceServices, deployments, routes, servicemonitors | Model explainability and monitoring |

### Secrets Inventory

| Component | Secret Name | Type | Purpose |
|-----------|-------------|------|---------|
| Dashboard | dashboard-proxy-tls | kubernetes.io/tls | OAuth proxy TLS certificate (auto-rotated) |
| Dashboard | dashboard-oauth-client-generated | Opaque | OAuth client credentials |
| Notebooks | {notebook}-oauth-config | Opaque | Notebook OAuth proxy configuration |
| Notebooks | {notebook}-tls | kubernetes.io/tls | Notebook Route TLS certificate |
| KServe | kserve-webhook-server-cert | kubernetes.io/tls | Webhook server TLS (cert-manager) |
| KServe | storage-config | Opaque | S3 credentials for model storage |
| ModelMesh | modelmesh-webhook-server-cert | kubernetes.io/tls | Webhook server TLS (cert-manager) |
| ModelMesh | model-serving-proxy-tls | kubernetes.io/tls | OAuth proxy TLS (service-ca) |
| ModelMesh | storage-config | Opaque | S3 credentials for model storage |
| Data Science Pipelines | ds-pipelines-proxy-tls-{name} | kubernetes.io/tls | API OAuth proxy TLS (service-ca) |
| Data Science Pipelines | {custom-db-secret} | Opaque | Database credentials |
| Data Science Pipelines | {custom-storage-secret} | Opaque | S3 credentials |
| CodeFlare | {cluster}-oauth-config | Opaque | Ray dashboard OAuth configuration |
| CodeFlare | ca-secret-{cluster} | Opaque | Ray cluster CA for mTLS |
| TrustyAI | {cr-name}-tls | kubernetes.io/tls | OAuth service TLS (service-ca) |
| Kueue | kueue-webhook-server-cert | kubernetes.io/tls | Webhook server TLS |

### Authentication Mechanisms

| Pattern | Components Using | Enforcement Point | Description |
|---------|------------------|-------------------|-------------|
| Bearer Tokens (JWT) | Dashboard, Notebook access, Pipeline API, Model inference (optional) | OpenShift OAuth Proxy, Istio + Authorino | Users authenticate with OpenShift, receive JWT token, token validated at proxy/gateway |
| mTLS Client Certs | Service mesh components (KServe, ModelMesh), Ray clusters | Istio PeerAuthentication, Ray cluster CA | Automatic mutual TLS for pod-to-pod communication within mesh |
| ServiceAccount Tokens | All operators, API calls between components | Kubernetes API Server RBAC | Component-to-component authentication for API operations |
| AWS IAM Credentials | S3 storage access | S3 endpoints | Model storage, pipeline artifacts, dataset access |
| OpenShift SCCs | Ray pods, Notebook pods | OpenShift admission | Security Context Constraints enforce user IDs and capabilities |

## Platform APIs

### Custom Resource Definitions

**Platform Management**:

| Component | API Group | Kind | Scope | Purpose |
|-----------|-----------|------|-------|---------|
| RHODS Operator | datasciencecluster.opendatahub.io/v1 | DataScienceCluster | Cluster | Enable and configure platform components |
| RHODS Operator | dscinitialization.opendatahub.io/v1 | DSCInitialization | Cluster | Configure service mesh, monitoring, trusted CAs |
| RHODS Operator | features.opendatahub.io/v1 | FeatureTracker | Cluster | Track feature-created resources for cleanup |

**Workbench Management**:

| Component | API Group | Kind | Scope | Purpose |
|-----------|-----------|------|-------|---------|
| Notebook Controller | kubeflow.org/v1 | Notebook | Namespaced | Define Jupyter/RStudio/VS Code workbench instances |
| Dashboard | opendatahub.io/v1alpha | OdhDashboardConfig | Namespaced | Dashboard configuration and feature flags |
| Dashboard | dashboard.opendatahub.io/v1 | OdhApplication | Namespaced | Application catalog entries |
| Dashboard | dashboard.opendatahub.io/v1 | AcceleratorProfile | Namespaced | GPU/accelerator configurations |

**Model Serving**:

| Component | API Group | Kind | Scope | Purpose |
|-----------|-----------|------|-------|---------|
| KServe | serving.kserve.io/v1beta1 | InferenceService | Namespaced | Deploy ML models with autoscaling and traffic management |
| KServe | serving.kserve.io/v1alpha1 | ServingRuntime | Namespaced | Define model server runtime configurations |
| KServe | serving.kserve.io/v1alpha1 | ClusterServingRuntime | Cluster | Cluster-wide runtime templates |
| KServe | serving.kserve.io/v1alpha1 | InferenceGraph | Namespaced | Multi-model inference pipelines |
| KServe | serving.kserve.io/v1alpha1 | TrainedModel | Namespaced | Individual trained model references |
| ModelMesh | serving.kserve.io/v1alpha1 | Predictor | Namespaced | Legacy multi-model serving workload definition |

**ML Pipelines**:

| Component | API Group | Kind | Scope | Purpose |
|-----------|-----------|------|-------|---------|
| Data Science Pipelines | datasciencepipelinesapplications.opendatahub.io/v1alpha1 | DataSciencePipelinesApplication | Namespaced | Complete DSP stack including API, database, storage |

**Distributed Computing**:

| Component | API Group | Kind | Scope | Purpose |
|-----------|-----------|------|-------|---------|
| KubeRay | ray.io/v1 | RayCluster | Namespaced | Ray cluster with head and worker nodes |
| KubeRay | ray.io/v1 | RayJob | Namespaced | Ray job with automatic cluster lifecycle |
| KubeRay | ray.io/v1 | RayService | Namespaced | Ray Serve for zero-downtime model serving |
| Kueue | kueue.x-k8s.io/v1beta1 | ClusterQueue | Cluster | Resource pool with quotas and policies |
| Kueue | kueue.x-k8s.io/v1beta1 | LocalQueue | Namespaced | Namespace queue mapping to ClusterQueue |
| Kueue | kueue.x-k8s.io/v1beta1 | Workload | Namespaced | Unit of work with resource requirements |

**Model Monitoring**:

| Component | API Group | Kind | Scope | Purpose |
|-----------|-----------|------|-------|---------|
| TrustyAI | trustyai.opendatahub.io/v1alpha1 | TrustyAIService | Namespaced | Explainability service deployment |

### Public HTTP Endpoints

**User-Facing Dashboards/UIs**:

| Component | Path | Port | Auth | Purpose |
|-----------|------|------|------|---------|
| ODH Dashboard | / | 8443/TCP | OpenShift OAuth | Platform management web UI |
| Notebooks | /notebook/{namespace}/{user}/ | 8888/TCP | OAuth Proxy | JupyterLab/VS Code/RStudio interface |
| Ray Dashboard | / (via Route) | 8265/TCP | OAuth Proxy (OpenShift) | Ray cluster monitoring and job management |
| Data Science Pipelines UI | / (via Route) | 8443/TCP | OAuth Proxy | Pipeline visualization (dev/test only) |

**Inference APIs**:

| Component | Path | Port | Auth | Purpose |
|-----------|------|------|------|---------|
| KServe | /v1/models/{model}:predict | 8080/TCP | Optional (Authorino) | KServe v1 inference protocol |
| KServe | /v2/models/{model}/infer | 8080/TCP | Optional (Authorino) | KServe v2 / Open Inference Protocol |
| ModelMesh | /v2/models/{model}/infer | 8443/TCP | OAuth (external) | KServe V2 REST via OAuth proxy |

**Backend APIs**:

| Component | Path | Port | Auth | Purpose |
|-----------|------|------|------|---------|
| Dashboard | /api/* | 8080/TCP | Bearer Token | REST API for all dashboard operations |
| Data Science Pipelines | /apis/v1beta1/* | 8888/TCP | Service Account / OAuth | Pipeline management REST API |

## Data Flows

### Key Platform Workflows

#### Workflow 1: Notebook Workbench Creation and Development

| Step | Component | Action | Next Component |
|------|-----------|--------|----------------|
| 1 | User | Selects notebook image and resources in Dashboard UI | Dashboard Backend |
| 2 | Dashboard Backend | Creates Notebook CR via Kubernetes API | Notebook Controller |
| 3 | Notebook Controller | Creates StatefulSet, Service, VirtualService | Kubernetes |
| 4 | Kubernetes | Pulls workbench image, creates pod with OAuth proxy sidecar | Container Registry → Pod |
| 5 | User | Accesses notebook via Route with OAuth authentication | OpenShift Router → OAuth Proxy → JupyterLab |
| 6 | JupyterLab | User develops models, saves to PVC or S3 | S3 Storage |

#### Workflow 2: Model Training to Deployment (KServe)

| Step | Component | Action | Next Component |
|------|-----------|--------|----------------|
| 1 | Notebook | User trains model, saves to S3 bucket | S3 Storage |
| 2 | User/Notebook | Creates InferenceService CR specifying model URI and runtime | Kubernetes API |
| 3 | KServe Controller | Creates Knative Service with storage-initializer | Knative Serving |
| 4 | Storage Initializer | Downloads model from S3 to /mnt/models volume | Model Server Container |
| 5 | ODH Model Controller | Creates Route, PeerAuthentication, VirtualService, NetworkPolicy | Istio + OpenShift |
| 6 | External Client | Sends inference request to Route | OpenShift Router → Istio Gateway → Model Pod |
| 7 | Model Runtime | Processes request, returns prediction | Client |
| 8 | TrustyAI (optional) | Logs payload for bias/fairness monitoring | TrustyAI Service |

#### Workflow 3: ML Pipeline Execution

| Step | Component | Action | Next Component |
|------|-----------|--------|----------------|
| 1 | User | Creates DataSciencePipelinesApplication CR | Data Science Pipelines Operator |
| 2 | DSP Operator | Deploys API Server, Persistence Agent, MariaDB, Minio, Workflow Controller | Kubernetes |
| 3 | User/Dashboard | Uploads pipeline YAML via Dashboard | DSP API Server |
| 4 | DSP API Server | Creates Argo Workflow or Tekton PipelineRun | Workflow Controller |
| 5 | Workflow Controller | Launches pipeline step pods | Kubernetes |
| 6 | Pipeline Pods | Execute training code, read/write data to S3 | S3 Storage |
| 7 | Persistence Agent | Syncs workflow status to MariaDB | MariaDB |
| 8 | User | Views pipeline run results in Dashboard | Dashboard → DSP API |

#### Workflow 4: Distributed Training with Ray and Kueue

| Step | Component | Action | Next Component |
|------|-----------|--------|----------------|
| 1 | User | Creates RayCluster CR with Kueue LocalQueue annotation | Kubernetes API |
| 2 | Kueue | Creates Workload CR, suspends RayCluster until resources available | Kueue Controller |
| 3 | Kueue | Admits workload when cluster resources match requirements | KubeRay Operator |
| 4 | KubeRay Operator | Creates Ray head pod, worker pods, services | Kubernetes |
| 5 | CodeFlare Operator | Injects OAuth proxy, mTLS certificates, NetworkPolicies | Ray Pods |
| 6 | User | Submits training job via Ray Dashboard or Python API | Ray Head Node |
| 7 | Ray | Distributes computation across workers, saves checkpoints | S3 Storage |
| 8 | User | Monitors progress via Ray Dashboard (OAuth-protected Route) | Ray Dashboard UI |

#### Workflow 5: Model Monitoring with TrustyAI

| Step | Component | Action | Next Component |
|------|-----------|--------|----------------|
| 1 | User | Creates TrustyAIService CR in model namespace | TrustyAI Operator |
| 2 | TrustyAI Operator | Deploys TrustyAI service with PVC, OAuth proxy, ServiceMonitor | Kubernetes |
| 3 | TrustyAI Operator | Patches InferenceService to enable payload logging | KServe/ModelMesh |
| 4 | InferenceService | Sends inference requests and responses to TrustyAI consumer endpoint | TrustyAI Service |
| 5 | TrustyAI Service | Stores payloads, computes fairness metrics (SPD, DIR) | PVC Storage |
| 6 | Prometheus | Scrapes TrustyAI metrics via ServiceMonitor | TrustyAI /q/metrics |
| 7 | User | Views fairness metrics in monitoring dashboard | Prometheus/Grafana |

## Deployment Architecture

### Deployment Topology

**Core Platform Components** (Namespace: redhat-ods-operator):
- RHODS Operator (1 replica with leader election)

**Application Components** (Namespace: redhat-ods-applications):
- ODH Dashboard (2 replicas for HA)
- Notebook Controller (1 replica)
- Data Science Pipelines Operator (1 replica)
- KServe Controller Manager (1 replica)
- ModelMesh Serving Controller (1-3 replicas)
- ODH Model Controller (3 replicas for HA)
- KubeRay Operator (1 replica)
- CodeFlare Operator (1 replica)
- Kueue Controller Manager (1 replica)
- TrustyAI Service Operator (1 replica)

**Monitoring Components** (Namespace: redhat-ods-monitoring):
- Prometheus (RHOAI-specific metrics)
- Grafana
- Alertmanager

**Service Mesh** (Namespace: istio-system):
- Istio Control Plane
- Istio Ingress Gateway

**User Workloads** (User-created namespaces):
- Notebook Pods (StatefulSets)
- InferenceService Pods (Knative Services or Deployments)
- Pipeline Pods (Argo Workflows or Tekton PipelineRuns)
- RayClusters (Head + Worker Pods)
- TrustyAI Service Instances

### Resource Requirements

**Operator Pods** (Aggregate):

| Component | CPU Request | CPU Limit | Memory Request | Memory Limit |
|-----------|-------------|-----------|----------------|--------------|
| RHODS Operator | 500m | 500m | 256Mi | 4Gi |
| ODH Dashboard (2 replicas) | 1000m | 2000m | 2Gi | 4Gi |
| Notebook Controller | 500m | 500m | 256Mi | 4Gi |
| DSP Operator | 500m | 500m | 512Mi | 512Mi |
| KServe Controller | 100m | 100m | 200Mi | 300Mi |
| ModelMesh Controller | 50m | 1000m | 96Mi | 512Mi |
| ODH Model Controller (3 replicas) | 30m | 1500m | 192Mi | 6Gi |
| KubeRay Operator | 100m | 100m | 512Mi | 512Mi |
| CodeFlare Operator | 1000m | 1000m | 1Gi | 1Gi |
| Kueue | 500m | 500m | 512Mi | 512Mi |
| TrustyAI Operator | 10m | 500m | 64Mi | 128Mi |

**Total Operator Overhead**: ~4.3 CPU cores, ~9 GB memory (approximate minimum for platform)

**User Workload Examples**:
- Jupyter Notebook Pod: 500m-2 CPU, 1-8Gi memory (user-configurable)
- InferenceService (KServe): 100m-4 CPU, 200Mi-8Gi memory (depends on model)
- ModelMesh Runtime: 800m-8 CPU, 1.5-2Gi memory (multi-model serving)
- Ray Head Node: 1-4 CPU, 2-8Gi memory
- Ray Worker Node: 1-16 CPU, 4-64Gi memory (scales with workload)

## Version-Specific Changes (2.9)

| Component | Key Changes |
|-----------|-------------|
| RHODS Operator | - Added Kueue alerting<br>- Fixed namespace watch handling<br>- CodeFlare, Ray, Kueue prepared for GA<br>- Fixed DSC error when DSCI missing |
| ODH Dashboard | - Read pipeline node details from MLMD context<br>- Support RayCluster/Job workloads for CPU/memory usage queries<br>- Fixed Jupyter environment variable handling<br>- Added DSCI fetch permissions |
| Data Science Pipelines | - Added oauth2-proxy to MLMD envoy proxy pod<br>- Added SSL env to functional tests<br>- System cert handling improvements<br>- Integration tests for external storage/DB |
| KServe | - Updated to support 2.9 Tekton with floating tags<br>- Red Hat Konflux build pipeline updates for all images |
| ODH Model Controller | - Fixed Knative webhook when KServe-Serverless disabled<br>- Improved Authorino capability detection<br>- CVE fixes (container breakout CVE-2024-21626, network DoS CVE-2023-45288) |
| KubeRay | - CVE fix: Upgraded golang.org/x/net<br>- Added aggregator role for admin and editor<br>- OpenShift kustomize overlay improvements |
| CodeFlare | - PATCH: Use namespace from ray cluster<br>- Start RayCluster controller only after CRD established<br>- Updated network policies for better traffic control |
| Kueue | - Stable v0.6.2 release for RHOAI 2.9<br>- v1beta1 API support<br>- Integration with Kubeflow, Ray, JobSet<br>- Admission checks and provisioning request support |
| ModelMesh | - Updated to Go 1.25.7<br>- CVE fixes for crypto/x509 resource consumption<br>- Dependency updates for UBI images<br>- Synced with upstream stable-2.x |
| TrustyAI | - Updated Go from 1.19 to 1.21<br>- ODH operator dependency checks<br>- CA bundle handling improvements |

## Platform Maturity

- **Total Components**: 12 operators + 1 web application + image catalog
- **Operator-based Components**: 11 (all use controller-runtime framework)
- **Service Mesh Coverage**: ~60% (KServe, ModelMesh, optional for others)
- **mTLS Enforcement**: STRICT when Service Mesh enabled, otherwise PERMISSIVE
- **CRD API Versions**: Mixture of v1alpha1, v1beta1, v1 (platform moving toward stability)
- **Authentication**: Consistent OAuth proxy pattern across external-facing services
- **Monitoring**: 100% ServiceMonitor/PodMonitor coverage for operators
- **High Availability**: Dashboard (2 replicas), ODH Model Controller (3 replicas), others use leader election

**Platform Characteristics**:
- **Production-Ready**: Yes, with enterprise support for RHOAI
- **Multi-Tenancy**: Strong support via namespace isolation and RBAC
- **GPU Support**: Comprehensive (NVIDIA CUDA, Intel GPU, Habana Gaudi)
- **Observability**: Excellent (Prometheus metrics, structured logging, health probes)
- **Security**: Strong (mTLS, OAuth, NetworkPolicies, RBAC, SCCs)
- **Extensibility**: High (modular component architecture, CRD-based)

## Next Steps for Documentation

1. **Generate Architecture Diagrams**
   - Component interaction sequence diagrams
   - Network flow diagrams for key workflows
   - Deployment topology diagrams
   - Create C4 model diagrams (Context, Container, Component, Code)

2. **Security Architecture Review (SAR) Documentation**
   - Data flow diagrams for security analysis
   - Trust boundary identification
   - Threat modeling for external APIs
   - Compliance documentation (NIST, FedRAMP, etc.)

3. **Update Architecture Decision Records (ADRs)**
   - Document key architectural decisions (KServe vs ModelMesh, Argo vs Tekton)
   - Service mesh integration rationale
   - Multi-tenancy approach
   - Storage architecture decisions

4. **Create User-Facing Documentation**
   - Getting Started guides for each workflow
   - Best practices for model serving
   - Performance tuning guides
   - Troubleshooting guides

5. **Generate Runbooks**
   - Operational procedures for each component
   - Disaster recovery procedures
   - Upgrade procedures
   - Monitoring and alerting setup

6. **Performance Benchmarking**
   - Model serving throughput/latency benchmarks
   - Pipeline execution performance
   - Distributed training scalability
   - Resource utilization analysis

7. **Integration Testing Matrix**
   - Component compatibility matrix
   - Supported configurations
   - Known limitations and constraints
   - Version compatibility guide
