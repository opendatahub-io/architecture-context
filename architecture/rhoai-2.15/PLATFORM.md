# Platform: Red Hat OpenShift AI 2.15

## Metadata
- **Distribution**: RHOAI
- **Version**: 2.15
- **Base Platform**: OpenShift Container Platform 4.14+
- **Components Analyzed**: 14
- **Analysis Date**: 2026-03-15

## Platform Overview

Red Hat OpenShift AI (RHOAI) 2.15 is an enterprise-grade machine learning and artificial intelligence platform that provides comprehensive tools for the complete ML lifecycle—from data preparation and model training to deployment and monitoring. Built on OpenShift Container Platform, RHOAI integrates with Red Hat OpenShift Service Mesh (Istio), OpenShift Serverless (Knative), and OpenShift OAuth to provide a secure, scalable, and production-ready environment for data scientists and ML engineers.

The platform consists of 14 major components orchestrated by the RHOAI Operator, which manages the deployment and lifecycle of workbenches (Jupyter notebooks, RStudio, VS Code), distributed training frameworks (PyTorch, TensorFlow, MPI), model serving infrastructure (KServe, ModelMesh), ML pipeline orchestration (Data Science Pipelines based on Kubeflow Pipelines), distributed workload management (CodeFlare, Ray, Kueue), model versioning (Model Registry), and AI explainability/monitoring (TrustyAI). All components integrate with OpenShift's native security features including OAuth, RBAC, service mesh mTLS, and automated certificate management.

The architecture follows a layered approach where the RHOAI Operator deploys and configures component-specific operators and services, which in turn manage user workloads. Components share common infrastructure patterns including OpenShift Routes for external access, Istio VirtualServices for service mesh traffic management, Prometheus for monitoring, and PostgreSQL/MariaDB/S3 for persistent storage.

## Component Inventory

| Component | Type | Version | Purpose |
|-----------|------|---------|---------|
| RHOAI Operator (rhods-operator) | Platform Operator | v1.6.0-852 | Central operator managing all data science components and platform initialization |
| ODH Dashboard | Web Application | v1.21.0-18 | Unified web UI for managing projects, notebooks, models, and platform features |
| Workbenches (Notebooks) | Container Images | 2024.1 | Pre-built Jupyter, RStudio, and VS Code environments with ML frameworks |
| ODH Notebook Controller | Kubernetes Controller | v1.27.0 | Extends Kubeflow with OpenShift Routes and OAuth authentication for notebooks |
| KServe | Model Serving Platform | v0.12.1 | Serverless model inference with autoscaling and multi-framework support |
| ODH Model Controller | Kubernetes Controller | v1.27.0-rhods-478 | Extends KServe with OpenShift Routes, Istio, and Authorino integration |
| ModelMesh Serving | Multi-Model Serving | v1.27.0-rhods-267 | High-density serving for frequently-changing models |
| Data Science Pipelines Operator | Kubernetes Operator | 8330c1e | Manages Kubeflow Pipelines for ML workflow orchestration |
| Training Operator | Kubernetes Operator | 80efa250 | Unified operator for distributed training (PyTorch, TensorFlow, MPI, XGBoost) |
| CodeFlare Operator | Kubernetes Operator | v1.10.0 | Manages RayClusters and AppWrappers with OAuth and mTLS |
| KubeRay Operator | Kubernetes Operator | v1.1.0 | Ray distributed computing cluster lifecycle management |
| Kueue | Job Queue System | v0.8.1 (ODH fork) | Job-level queueing, fair sharing, and admission control |
| Model Registry Operator | Kubernetes Operator | dc70e33 | Manages Model Registry instances for ML metadata and versioning |
| TrustyAI Service Operator | Kubernetes Operator | v1.17.0 | AI explainability and bias detection for model monitoring |

## Component Relationships

### Dependency Graph

```
RHOAI Operator (rhods-operator)
├── Deploys all component operators and services
├── Manages DSCInitialization (monitoring, service mesh, namespaces)
└── Manages DataScienceCluster (component enablement)

ODH Dashboard
├── UI → KServe API (model serving management)
├── UI → Kubeflow Notebook API (notebook lifecycle)
├── UI → Model Registry API (model versioning)
├── UI → DataSciencePipelinesApplication API (pipeline management)
└── UI → Prometheus (metrics queries)

Workbenches/Notebooks
├── User Code → Data Science Pipelines (submit pipelines)
├── User Code → KServe (deploy models)
├── User Code → Model Registry (register models)
├── User Code → S3/Object Storage (datasets, artifacts)
└── Managed by → ODH Notebook Controller

Data Science Pipelines
├── Runtime Images → Notebooks runtime containers
├── API → KServe (pipeline-triggered model deployment)
├── API → Model Registry (model metadata)
├── Storage → MariaDB/MySQL (pipeline metadata)
├── Storage → S3/Minio (artifacts)
└── Workflow Engine → Argo Workflows (v2 pipelines)

KServe
├── Depends on → Knative Serving (serverless autoscaling)
├── Depends on → Istio (traffic management, mTLS)
├── Storage → S3/GCS/Azure (model artifacts)
├── Monitoring → Prometheus (metrics)
└── Extended by → ODH Model Controller

ODH Model Controller
├── Watches → KServe InferenceServices
├── Creates → OpenShift Routes (external access)
├── Creates → Istio VirtualServices (traffic routing)
├── Creates → Authorino AuthConfigs (authentication)
└── Creates → ServiceMonitors (Prometheus integration)

ModelMesh Serving
├── Depends on → etcd (model routing metadata)
├── Storage → S3/Minio (model artifacts)
├── Runtimes → Triton, MLServer, OVMS, TorchServe
└── Monitoring → Prometheus (metrics)

Training Operator
├── Manages → PyTorchJobs, TFJobs, MPIJobs, XGBoostJobs
├── Optional → Kueue (job queueing)
├── Optional → Volcano (gang scheduling)
└── Storage → S3/NFS (training datasets, checkpoints)

CodeFlare Operator
├── Watches → RayCluster CRs (provided by KubeRay)
├── Creates → AppWrappers (job bundling)
├── Integrates → Kueue (workload queueing)
├── Integrates → OpenShift OAuth (Ray dashboard auth)
└── Provides → mTLS for Ray communication

KubeRay Operator
├── Manages → Ray cluster head and worker pods
├── Integrates → Prometheus (metrics)
└── Optional → External Redis (GCS fault tolerance)

Kueue
├── Watches → Jobs, PyTorchJobs, TFJobs, MPIJobs, RayJobs, RayClusters, JobSets
├── Controls → Workload admission based on quotas
├── Integrates → Cluster Autoscaler (ProvisioningRequests)
└── Provides → Multi-tenant resource sharing

Model Registry Operator
├── Manages → Model Registry service deployments
├── Storage → PostgreSQL/MySQL (metadata)
├── Integrates → Istio (service mesh, AuthorizationPolicies)
├── Integrates → Authorino (Kubernetes token auth)
└── API → REST + gRPC (ML Metadata protocol)

TrustyAI Service Operator
├── Watches → KServe InferenceServices
├── Patches → InferenceServices (payload processor injection)
├── Storage → PVC or PostgreSQL/MariaDB
├── Integrates → Istio (VirtualServices, DestinationRules)
├── Integrates → OpenShift OAuth (authentication)
└── Monitoring → Prometheus (fairness metrics)
```

### Central Components

**Core Platform Services** (highest dependencies):
1. **RHOAI Operator**: Orchestrates entire platform
2. **ODH Dashboard**: Primary user interface
3. **Istio Service Mesh**: Traffic management, security for KServe, ModelMesh, Model Registry
4. **OpenShift OAuth**: Authentication for Dashboard, Notebooks, Ray Dashboard, TrustyAI
5. **Prometheus**: Monitoring across all components
6. **Kubernetes API Server**: All operators reconcile resources via API

**Storage Infrastructure**:
- **S3/Object Storage**: Model artifacts (KServe, ModelMesh), pipeline artifacts (DSP), datasets
- **PostgreSQL/MySQL**: Pipeline metadata (DSP), model registry metadata, TrustyAI data
- **etcd**: ModelMesh routing, Kubernetes state

**Service Mesh & Networking**:
- **Knative Serving**: KServe serverless autoscaling
- **OpenShift Routes**: External ingress for Dashboard, Notebooks, KServe, ModelMesh, Ray Dashboard
- **Authorino**: Token-based authentication for KServe, Model Registry

### Integration Patterns

**Common Patterns**:
1. **CRD Watch and Reconcile**: All operators watch Kubernetes API for CRD changes
2. **OpenShift Route Creation**: ODH Notebook Controller, ODH Model Controller, CodeFlare, Model Registry create Routes
3. **Istio Integration**: KServe, ModelMesh, Model Registry use VirtualServices, DestinationRules, AuthorizationPolicies
4. **OAuth Proxy Sidecar**: Dashboard, Notebooks, Ray Dashboard, TrustyAI inject OAuth proxy for auth
5. **ServiceMonitor for Metrics**: All components expose Prometheus metrics via ServiceMonitor CRDs
6. **Storage Secret Management**: KServe, ModelMesh, DSP use Secrets for S3/database credentials
7. **Service Mesh mTLS**: KServe, Model Registry use ISTIO_MUTUAL mode for pod-to-pod encryption

## Platform Network Architecture

### Namespaces

| Namespace | Purpose | Components |
|-----------|---------|------------|
| redhat-ods-operator | RHOAI operator deployment | rhods-operator controller-manager |
| redhat-ods-applications | Application controllers | ODH Dashboard, ODH Notebook Controller, ODH Model Controller, KServe, ModelMesh, CodeFlare, KubeRay, Kueue, Training Operator, TrustyAI Operator |
| redhat-ods-monitoring | Platform monitoring | Prometheus, Alertmanager, Blackbox Exporter |
| opendatahub | Alternative deployment namespace | (Same as redhat-ods-applications for ODH distribution) |
| {user-namespaces} | Data science projects | User notebooks, InferenceServices, training jobs, pipelines, Ray clusters |
| istio-system | Service mesh control plane | Istio control plane, ingress gateways (Route passthroughs) |

### External Ingress Points

| Component | Ingress Type | Hosts | Port | Protocol | Encryption | Purpose |
|-----------|--------------|-------|------|----------|------------|---------|
| ODH Dashboard | OpenShift Route | Auto-generated | 443/TCP | HTTPS | TLS 1.2+ (Reencrypt) | Web UI access for platform management |
| Jupyter Notebooks | OpenShift Route | Auto-generated per notebook | 443/TCP | HTTPS | TLS 1.2+ (Edge/Reencrypt) | Interactive notebook access |
| KServe InferenceService | OpenShift Route + Istio Gateway | {isvc-name}-{namespace}.{domain} | 443/TCP | HTTPS | TLS 1.2+ (Edge) | Model inference endpoints (REST/gRPC) |
| ModelMesh Serving | OpenShift Route | {predictor-name}.{domain} | 443/TCP | HTTPS | TLS 1.2+ (Reencrypt) | Multi-model inference endpoints |
| Data Science Pipelines UI | OpenShift Route | {pipeline-name}.{domain} | 443/TCP | HTTPS | TLS 1.2+ (Reencrypt) | Pipeline visualization and management |
| Model Registry | OpenShift Route + Istio Gateway | {registry-name}-rest.{domain}<br>{registry-name}-grpc.{domain} | 443/TCP | HTTPS | TLS 1.2+ (Passthrough via Istio) | Model metadata REST/gRPC API |
| Ray Dashboard | OpenShift Route | Auto-generated | 443/TCP | HTTPS | TLS 1.2+ (Reencrypt) | Ray cluster monitoring and job submission |
| TrustyAI Service | OpenShift Route | Auto-generated | 443/TCP | HTTPS | TLS 1.2+ (Reencrypt) | Model explainability and bias metrics API |

### External Egress Dependencies

| Component | Destination | Port | Protocol | Encryption | Purpose |
|-----------|-------------|------|----------|------------|---------|
| All Components | Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | Resource management via ServiceAccount tokens |
| KServe, ModelMesh, DSP | S3-compatible storage (AWS, MinIO) | 443/TCP | HTTPS | TLS 1.2+ | Model artifact and pipeline artifact download |
| KServe | GCS (storage.googleapis.com) | 443/TCP | HTTPS | TLS 1.2+ | Model artifact download from Google Cloud |
| KServe | Azure Blob Storage | 443/TCP | HTTPS | TLS 1.2+ | Model artifact download from Azure |
| Model Registry, TrustyAI, DSP | PostgreSQL/MySQL | 5432/TCP, 3306/TCP | PostgreSQL/MySQL | TLS (optional) | Metadata persistence |
| Notebooks, DSP Runtime | pypi.org, quay.io, cdn.redhat.com | 443/TCP | HTTPS | TLS 1.2+ | Package and image downloads |
| All Components | OpenShift OAuth Server | 443/TCP | HTTPS | TLS 1.2+ | User authentication and token validation |
| CodeFlare, ODH Notebook Controller | OpenShift Service CA | N/A | N/A | N/A | TLS certificate provisioning |
| All Operators | Component Git Repositories | 443/TCP | HTTPS | TLS 1.2+ | Manifest downloads (build-time) |
| KubeRay (optional) | External Redis | 6379/TCP | Redis Protocol | TLS (optional) | Ray GCS fault tolerance |

### Internal Service Mesh

| Setting | Value | Components Using |
|---------|-------|------------------|
| mTLS Mode | ISTIO_MUTUAL (default for mesh) | KServe predictors/transformers/explainers, Model Registry, ModelMesh (optional) |
| PeerAuthentication | STRICT (configurable per namespace) | KServe namespaces, Model Registry namespace |
| AuthorizationPolicy | Authorino external authorization | KServe InferenceServices, Model Registry services |
| VirtualService Traffic Management | HTTP/gRPC routing, canary, A/B testing | KServe, Model Registry, TrustyAI (InferenceLogger) |
| DestinationRule | TLS mode configuration | KServe, Model Registry, TrustyAI |
| Gateway | External ingress routing | KServe (istio-ingressgateway), Model Registry (istio-ingressgateway) |

## Platform Security

### RBAC Summary

**Cluster-Level Permissions** (abbreviated, see component files for complete list):

| Component | ClusterRole Highlights | Key Permissions |
|-----------|------------------------|-----------------|
| RHOAI Operator | Full platform management | datascienceclusters, dscinitializations, CRDs, operators.coreos.com subscriptions, all managed component CRDs |
| KServe | InferenceService management | inferenceservices, servingruntimes, knative services, istio resources, HPA |
| ODH Model Controller | KServe extension | Same as KServe + authorino authconfigs, servicemeshmembers, routes |
| ModelMesh | Multi-model serving | inferenceservices, predictors, servingruntimes, deployments, services, servicemonitors |
| Data Science Pipelines | Pipeline orchestration | datasciencepipelinesapplications, workflows (Argo), pods, services, configmaps, secrets, jobs |
| Training Operator | Distributed training | pytorchjobs, tfjobs, mpijobs, xgboostjobs, mxjobs, paddlejobs, podgroups (Volcano/scheduler-plugins) |
| CodeFlare | Ray and AppWrapper management | rayclusters, appwrappers, routes, networkpolicies, workloads (Kueue), services |
| KubeRay | Ray cluster management | rayclusters, rayjobs, rayservices, pods, services, ingresses, routes |
| Kueue | Job queue management | workloads, clusterqueues, localqueues, all job types (batch, kubeflow, ray, jobset), provisioningrequests |
| Model Registry Operator | Model Registry lifecycle | modelregistries, istio resources (gateways, virtualservices), authorino authconfigs, routes, deployments |
| TrustyAI Operator | TrustyAI service management | trustyaiservices, inferenceservices (patch), servicemonitors, istio resources, routes |
| ODH Notebook Controller | Notebook lifecycle | notebooks (kubeflow.org), routes, services, networkpolicies, configmaps |
| ODH Dashboard | Platform UI operations | All component CRDs (read), namespaces, users, groups, rolebindings, image streams, build configs |

### Secrets Inventory

**Common Secret Types**:

| Secret Type | Components Using | Purpose |
|-------------|------------------|---------|
| kubernetes.io/tls | All operators (webhook certs), Dashboard, Notebooks, KServe, Model Registry, TrustyAI | TLS certificates for webhooks and services (auto-provisioned by OpenShift service-ca) |
| Opaque (S3 credentials) | KServe, ModelMesh, Data Science Pipelines, Notebooks | AWS Access Key, Secret Key for S3-compatible storage |
| Opaque (Database credentials) | Data Science Pipelines, Model Registry, TrustyAI | Username, password, host, port for PostgreSQL/MySQL |
| Opaque (OAuth config) | Dashboard, Notebooks, Ray Dashboard, TrustyAI | OAuth proxy configuration (cookie secret, client ID/secret) |
| kubernetes.io/dockerconfigjson | All components | Container image pull secrets for private registries |
| kubernetes.io/service-account-token | All components | ServiceAccount tokens for Kubernetes API access (auto-generated) |

**Security-Critical Secrets**:
- **Webhook Server Certificates**: All operators require valid TLS certs for admission webhooks
- **Storage Credentials**: S3 access keys, database passwords must be securely managed
- **OAuth Secrets**: Cookie secrets, OAuth client credentials for authentication
- **CA Certificates**: Custom CA bundles for trusting enterprise certificates (notebooks, pipelines)

### Authentication Mechanisms

| Pattern | Components Using | Enforcement Point |
|---------|------------------|-------------------|
| OpenShift OAuth (Bearer Token) | Dashboard, Notebooks, Ray Dashboard, TrustyAI | OAuth Proxy sidecar with SubjectAccessReview |
| Kubernetes ServiceAccount Token | All operators, pipelines, training jobs | Kubernetes API Server via RBAC |
| Authorino (Kubernetes Token Review) | KServe InferenceServices, Model Registry | Istio external authorization (ext-authz) |
| mTLS Client Certificates | Webhook servers, KServe agent, Ray cluster internal | Kubernetes API Server, Istio service mesh |
| AWS IAM / S3 Access Keys | KServe storage-initializer, ModelMesh, Pipelines, Notebooks | S3-compatible storage providers |
| Database Username/Password + TLS | Data Science Pipelines, Model Registry, TrustyAI | PostgreSQL/MySQL authentication |
| No Authentication (Internal) | Prometheus metrics endpoints, health checks | NetworkPolicies restrict to internal cluster access |

## Platform APIs

### Custom Resource Definitions

| Component | API Group | Kind | Scope | Purpose |
|-----------|-----------|------|-------|---------|
| RHOAI Operator | datasciencecluster.opendatahub.io | DataScienceCluster | Cluster | Platform component enablement and configuration |
| RHOAI Operator | dscinitialization.opendatahub.io | DSCInitialization | Cluster | Platform infrastructure initialization |
| RHOAI Operator | features.opendatahub.io | FeatureTracker | Namespaced | Feature usage tracking |
| ODH Dashboard | opendatahub.io | OdhDashboardConfig | Namespaced | Dashboard configuration |
| ODH Dashboard | dashboard.opendatahub.io | OdhApplication, OdhDocument | Namespaced | Application catalog and documentation |
| ODH Dashboard | console.openshift.io | OdhQuickStart | Namespaced | Interactive tutorials |
| ODH Dashboard | dashboard.opendatahub.io | AcceleratorProfile | Namespaced | GPU/accelerator configurations |
| Kubeflow (Notebook Controller) | kubeflow.org | Notebook | Namespaced | Jupyter notebook instances |
| KServe | serving.kserve.io | InferenceService | Namespaced | Model serving deployments |
| KServe | serving.kserve.io | ServingRuntime, ClusterServingRuntime | Namespaced, Cluster | Model server runtime configurations |
| KServe | serving.kserve.io | InferenceGraph | Namespaced | Multi-step inference pipelines |
| KServe | serving.kserve.io | TrainedModel | Namespaced | Model artifact references |
| KServe | serving.kserve.io | ClusterStorageContainer | Cluster | Storage backend configurations |
| ModelMesh | serving.kserve.io | Predictor | Namespaced | ModelMesh model definitions |
| Data Science Pipelines | datasciencepipelinesapplications.opendatahub.io | DataSciencePipelinesApplication | Namespaced | DSP stack configuration |
| Data Science Pipelines | argoproj.io | Workflow, CronWorkflow, WorkflowTemplate | Namespaced | Argo workflow execution (v2) |
| Training Operator | kubeflow.org | PyTorchJob, TFJob, MPIJob, XGBoostJob, MXNetJob, PaddleJob | Namespaced | Distributed training jobs |
| CodeFlare | workload.codeflare.dev | AppWrapper | Namespaced | Job bundling with Kueue integration |
| KubeRay | ray.io | RayCluster, RayJob, RayService | Namespaced | Ray distributed computing |
| Kueue | kueue.x-k8s.io | Workload, ClusterQueue, LocalQueue, ResourceFlavor, AdmissionCheck, WorkloadPriorityClass | Namespaced/Cluster | Job queueing and admission control |
| Model Registry | modelregistry.opendatahub.io | ModelRegistry | Namespaced | Model metadata service instances |
| TrustyAI | trustyai.opendatahub.io | TrustyAIService | Namespaced | AI explainability service instances |

**Total CRD Count**: 40+ Custom Resource Definitions across 14 components

### Public HTTP Endpoints

**User-Facing APIs** (external access via Routes):

| Component | Path Pattern | Port | Protocol | Auth | Purpose |
|-----------|--------------|------|----------|------|---------|
| ODH Dashboard | / | 443/TCP | HTTPS | OAuth | Platform UI and REST API |
| Jupyter Notebooks | / | 443/TCP | HTTPS | OAuth | JupyterLab interface |
| KServe InferenceService | /v1/models/{model}:predict<br>/v2/models/{model}/infer | 443/TCP | HTTPS | Bearer Token (Authorino) or None | Model inference (V1/V2 protocols) |
| ModelMesh | /v2/models/{model}/infer | 443/TCP | HTTPS | None or Bearer Token | Multi-model inference |
| Data Science Pipelines | /apis/v2beta1/*, /apis/v1beta1/* | 443/TCP | HTTPS | OAuth | Pipeline REST API |
| Model Registry | /api/model_registry/v1alpha3/* | 443/TCP | HTTPS | Bearer Token (Authorino) | Model metadata REST API |
| Ray Dashboard | / | 443/TCP | HTTPS | OAuth | Ray cluster dashboard |
| TrustyAI Service | /* | 443/TCP | HTTPS | OAuth | Explainability API |

**Internal Metrics Endpoints** (Prometheus scraping):

All components expose `/metrics` on internal ClusterIP services, typically ports 8080/TCP or 8443/TCP.

### gRPC Services

| Component | Service | Port | Protocol | Encryption | Auth | Purpose |
|-----------|---------|------|----------|------------|------|---------|
| KServe | inference.GRPCInferenceService | 8081/TCP | gRPC | mTLS (optional) | Bearer Token | V2 gRPC inference protocol |
| ModelMesh | ml_metadata.MetadataStoreService (MLMD) | 8080/TCP | gRPC | TLS 1.3 or None | None | Internal MLMD for pipelines |
| Data Science Pipelines | api.PipelineService | 8887/TCP | gRPC | TLS 1.3 or None | Service mesh mTLS or None | Internal pipeline service API |
| Data Science Pipelines | ml_metadata.MetadataStoreService | 9090/TCP | gRPC/HTTP2 | TLS 1.2+ | OAuth2 (via Envoy) | ML Metadata lineage tracking |
| Model Registry | ml_metadata.MetadataStoreService | 9090/TCP | gRPC | mTLS (via Istio) | Bearer Token (Authorino) | Model registry gRPC API |

## Data Flows

### Key Platform Workflows

#### Workflow 1: Data Scientist Onboarding to Model Deployment

| Step | Component | Action | Next Component |
|------|-----------|--------|----------------|
| 1 | User Browser | Access ODH Dashboard via Route with OpenShift OAuth | Dashboard Frontend |
| 2 | Dashboard UI | Create Data Science Project (namespace) | Kubernetes API |
| 3 | Dashboard UI | Launch Jupyter Notebook with selected image | Kubeflow Notebook CR |
| 4 | ODH Notebook Controller | Reconcile Notebook CR, create StatefulSet, Route, OAuth proxy | Notebook Pod |
| 5 | User via Notebook | Develop model, access S3 datasets | Training code in notebook |
| 6 | User via Notebook | Register model in Model Registry | Model Registry REST API |
| 7 | User via Dashboard/Notebook | Create InferenceService CR for model deployment | KServe API |
| 8 | KServe Controller | Create Knative Service with storage-initializer | Model server pods |
| 9 | ODH Model Controller | Create Route, VirtualService, AuthConfig, ServiceMonitor | External inference endpoint |
| 10 | External Client | Send inference requests to Route → Istio Gateway → Model server | Model predictions |

#### Workflow 2: Distributed Training Job Execution

| Step | Component | Action | Next Component |
|------|-----------|--------|----------------|
| 1 | User/CI | Submit PyTorchJob CR via kubectl or Dashboard | Kubernetes API |
| 2 | Training Operator | Reconcile PyTorchJob, create master and worker pods | Training pods |
| 3 | Optional: Kueue | Admit job when quota available, create Workload CR | Training Operator |
| 4 | Optional: Volcano | Gang schedule all pods together to avoid partial scheduling | Kubernetes Scheduler |
| 5 | Training Pods | Download dataset from S3, distributed training across workers | External S3 |
| 6 | Training Pods | Save model checkpoints to S3 or PVC | S3 or Persistent Volume |
| 7 | Training Pods | Register trained model in Model Registry | Model Registry API |
| 8 | Training Operator | Update PyTorchJob status to Succeeded | Kubernetes API |

#### Workflow 3: ML Pipeline Execution (Data Science Pipelines)

| Step | Component | Action | Next Component |
|------|-----------|--------|----------------|
| 1 | User via Notebook | Submit pipeline via Elyra or KFP SDK | Data Science Pipelines API |
| 2 | DSP API Server | Create Argo Workflow CR, store metadata in MariaDB | Workflow Controller |
| 3 | Workflow Controller | Create pipeline task pods using runtime images | Workflow pods |
| 4 | Pipeline Task Pods | Execute Python code, access S3 for data | Runtime image execution |
| 5 | Pipeline Task Pods | Log artifacts and metrics to MLMD gRPC service | MLMD gRPC |
| 6 | Pipeline Task Pods | Store output artifacts in S3 | S3 storage |
| 7 | Optional: Pipeline Task | Deploy model via InferenceService creation | KServe API |
| 8 | Persistence Agent | Sync workflow status to MariaDB | MariaDB |
| 9 | User via Dashboard/UI | View pipeline run status and artifacts | DSP UI Route |

#### Workflow 4: Model Monitoring with TrustyAI

| Step | Component | Action | Next Component |
|------|-----------|--------|----------------|
| 1 | User via Dashboard | Deploy TrustyAIService CR in namespace | TrustyAI Operator |
| 2 | TrustyAI Operator | Create TrustyAI deployment with OAuth proxy, PVC/DB storage | TrustyAI Service pods |
| 3 | TrustyAI Operator | Patch InferenceService with payload processor annotation | KServe InferenceService |
| 4 | InferenceService | Send inference payloads to TrustyAI service | TrustyAI HTTP API |
| 5 | TrustyAI Service | Store inference data, compute fairness metrics (SPD, DIR) | PVC or PostgreSQL |
| 6 | Prometheus | Scrape TrustyAI metrics via ServiceMonitor | TrustyAI /q/metrics |
| 7 | User via TrustyAI UI | Access explainability dashboards via Route | TrustyAI OAuth proxy → Service |

#### Workflow 5: Distributed Ray Workload with CodeFlare

| Step | Component | Action | Next Component |
|------|-----------|--------|----------------|
| 1 | User via Notebook | Submit RayCluster CR or AppWrapper CR | Kubernetes API |
| 2 | KubeRay Operator | Create Ray head and worker pods with services | Ray cluster pods |
| 3 | CodeFlare Operator | Inject OAuth proxy for dashboard, create Route, NetworkPolicies | Ray Dashboard Route |
| 4 | Optional: Kueue | Admit AppWrapper when resources available | CodeFlare Operator |
| 5 | User via Ray Client | Submit Ray job to cluster via client API | Ray Head pod |
| 6 | Ray Cluster | Distribute task execution across workers | Ray worker pods |
| 7 | User via Dashboard Route | Monitor Ray cluster via OAuth-protected dashboard | Ray Dashboard UI |
| 8 | Ray Workers | Access datasets from S3, process distributed workload | External S3 |

## Deployment Architecture

### Deployment Topology

**Operator Tier** (redhat-ods-operator namespace):
- 1 RHOAI Operator pod (leader election enabled)
- Manages all component deployments via DataScienceCluster CR

**Application Controller Tier** (redhat-ods-applications namespace):
- 2 ODH Dashboard pods (HA with anti-affinity)
- 1 ODH Notebook Controller pod (leader election)
- 1 ODH Model Controller pod (leader election)
- 1 KServe Controller Manager pod
- 1 ModelMesh Controller pod
- 1 Data Science Pipelines Operator pod
- 1 Training Operator pod (leader election)
- 1 CodeFlare Operator pod
- 1 KubeRay Operator pod (leader election)
- 1 Kueue Controller Manager pod (leader election)
- 1 Model Registry Operator pod (leader election)
- 1 TrustyAI Service Operator pod (leader election)

**Monitoring Tier** (redhat-ods-monitoring namespace):
- 1 Prometheus StatefulSet (with federation to user-workload monitoring)
- 1 Alertmanager Deployment
- 1 Blackbox Exporter Deployment

**User Workload Tier** (user data science project namespaces):
- Notebook StatefulSets (1 per notebook, as requested by users)
- InferenceService pods (KServe: autoscaling 0-N, ModelMesh: 2+ replicas per runtime)
- Training job pods (PyTorchJob, TFJob, etc.: 1+ master/worker pods as defined)
- Data Science Pipelines stack per DSPA (API server, persistence agent, workflow controller, MariaDB, Minio)
- Ray cluster pods (1 head + N workers per RayCluster)
- Model Registry service pods (1 gRPC + 1 REST container per ModelRegistry)
- TrustyAI service pods (1 service + 1 OAuth proxy per TrustyAIService)

**Service Mesh Tier** (istio-system namespace):
- Istio control plane (istiod)
- Istio ingress gateways (for KServe, Model Registry external access)

### Resource Requirements

**Platform Minimum** (operator and controller tier):
- CPU: ~5-7 cores total for all operators
- Memory: ~8-12 GB total for all operators
- Storage: Minimal (operator images only)

**User Workload Variable**:
- Notebooks: 1-16+ cores, 2-64+ GB per notebook (user-configurable)
- InferenceServices: 0.5-8+ cores, 512MB-16GB+ per model server (depends on model size)
- Training Jobs: 1-100+ cores per job, distributed across workers (user-defined)
- Data Science Pipelines: 1-2 cores, 2-4 GB per DSPA stack
- Ray Clusters: 1+ cores per worker (user-defined, autoscaling)

**Storage Requirements**:
- Notebook PVCs: 1-100+ GB per notebook (user-configurable)
- Pipeline artifacts: S3-based (external)
- Model artifacts: S3-based (external)
- Pipeline metadata: MariaDB/PostgreSQL (10-100+ GB depending on usage)
- Model Registry metadata: PostgreSQL (1-50 GB)
- TrustyAI data: PVC (1-10 GB) or PostgreSQL

## Version-Specific Changes (2.15)

| Component | Key Changes in 2.15 |
|-----------|---------------------|
| RHOAI Operator | - TrustyAI GA (General Availability)<br>- Dynamic namespace detection<br>- Improved platform detection for SelfManagedRHOAI<br>- Namespace validation enhancements |
| ODH Dashboard | - Upversioned to v2.28.0<br>- Updated project list to show active notebooks<br>- Model registry/version archival controls<br>- Connection type editing improvements<br>- TrustyAI bias metrics flag rename |
| KServe | - Updated to v0.12.1<br>- InferenceGraph for multi-model pipelines<br>- OCI modelcar support for storage-initializer<br>- CVE-2024-6119 fix<br>- Konflux build integration |
| ODH Model Controller | - Updated vLLM, TGIS, Caikit-TGIS, OVMS runtime images<br>- Konflux 2.16 support<br>- Enhanced serving runtime templates |
| Data Science Pipelines | - Argo Workflows v3.4.17<br>- FIPS-compatible oauth-proxy<br>- Service mesh proxyv2 image updates<br>- NetworkPolicy for API server pod self-traffic |
| Training Operator | - RHOAI 2.15 release with Konflux builds<br>- Updated dependencies<br>- RHOAI-specific overlay configuration |
| CodeFlare | - Updated to v1.10.0<br>- AppWrappers v0.26.0<br>- Renovate config for dependency management<br>- Konflux build optimization |
| KubeRay | - Updated to v1.1.0<br>- Go 1.22.2 upgrade<br>- SecurityContext for restricted pod-security compliance<br>- Konflux updates |
| Kueue | - Updated to v0.8.1 (ODH fork)<br>- Konflux build system integration<br>- Removed runbooks (RHOAI-specific) |
| Model Registry | - ConfigMap CA certificate support (RHOAIENG-14601)<br>- Unique registry name validation (RHOAIENG-13171)<br>- Konflux 2.16 support<br>- Controller metrics authentication refactor |
| TrustyAI | - v1.17.0<br>- VirtualServices for InferenceLogger traffic<br>- Database TLS CA certificate support<br>- KServe serverless mode in RHOAI overlay<br>- Readiness probes added |
| Notebooks | - Weekly digest updates (Oct 2024)<br>- Elyra v4.1.1 update<br>- codeflare-sdk version updates<br>- Poetry venv improvements |
| ODH Notebook Controller | - CA bundle newline fixes (RHOAIENG-11895)<br>- OAuth proxy updates<br>- Image version updates |

## Platform Maturity

- **Total Components**: 14 major components
- **Operator-based Components**: 12 of 14 (Dashboard and Notebooks are non-operator)
- **Service Mesh Coverage**: ~50% (KServe, ModelMesh, Model Registry, TrustyAI use Istio; others explicitly disable)
- **mTLS Enforcement**: STRICT for KServe/ModelMesh namespaces (configurable), ISTIO_MUTUAL for in-mesh services
- **CRD API Versions**: Mix of v1alpha1, v1beta1, v1beta2, v1 (maturing towards stable v1)
- **Authentication Coverage**: 100% of external endpoints (OAuth or Authorino)
- **Monitoring Coverage**: 100% (all components expose Prometheus metrics via ServiceMonitors)
- **Certificate Management**: Automated via OpenShift service-ca-operator (TLS cert rotation)
- **Build System**: Konflux (Red Hat's cloud-native CI/CD) for all production images
- **Base Images**: UBI8/UBI9 (Universal Base Image) for security and compliance
- **RBAC Model**: Fine-grained ClusterRoles and RoleBindings per component
- **Storage Abstraction**: S3-compatible (primary), PostgreSQL/MySQL/MariaDB (metadata), PVC (notebooks, pipelines)

**Maturity Indicators**:
- **Production Ready**: All components GA except InferenceGraph, ModelRegistry (some APIs still v1alpha1)
- **Enterprise Support**: Red Hat support for all RHOAI components
- **Upstream Alignment**: Based on upstream Kubeflow, KServe, Kueue, Ray, ODH projects
- **Security Posture**: Strong (OAuth, mTLS, RBAC, automated certs, non-root containers)
- **Observability**: Comprehensive (Prometheus metrics, health checks, status conditions)
- **Scalability**: Proven at scale (multi-tenant, resource quotas, job queueing)

## Next Steps for Documentation

1. **Generate Architecture Diagrams**: Create visual diagrams from this platform architecture
   - Component dependency graph
   - Network topology diagram
   - Data flow diagrams for key workflows
   - Security architecture diagram (authentication/authorization flows)

2. **Update ADRs Repository**: Document architecture decisions for
   - Service mesh integration strategy
   - Authentication approach (OAuth vs Authorino)
   - Storage backend choices (S3 vs PVC vs Database)
   - Deployment mode selection (serverless vs raw)

3. **Create User-Facing Documentation**:
   - Quick start guides for each workflow
   - Component integration tutorials
   - Best practices for production deployments
   - Troubleshooting guides

4. **Generate Security Architecture Review (SAR) Documentation**:
   - Network segmentation diagram (ingress/egress)
   - Authentication flow diagrams
   - RBAC model documentation
   - Certificate management lifecycle
   - Compliance artifacts (FIPS, encryption at rest/in transit)

5. **Performance and Scaling Documentation**:
   - Resource sizing guidelines
   - Autoscaling configurations
   - Multi-tenancy best practices
   - Quota and limit recommendations

6. **Operator Development Guidelines**:
   - Controller reconciliation patterns
   - Webhook implementation guide
   - ServiceMonitor integration
   - Status condition design patterns
