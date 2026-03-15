# Platform: Red Hat OpenShift AI 2.25.0

## Metadata
- **Distribution**: RHOAI
- **Version**: 2.25.0
- **Release Date**: 2026-03
- **Base Platform**: OpenShift Container Platform 4.11+
- **Components Analyzed**: 15

## Platform Overview

Red Hat OpenShift AI (RHOAI) 2.25.0 is a comprehensive enterprise AI/ML platform that provides an integrated environment for developing, training, serving, and monitoring machine learning models at scale. The platform extends Red Hat OpenShift with specialized components for data science workflows, including interactive development environments (Jupyter notebooks, VS Code, RStudio), distributed training frameworks (PyTorch, TensorFlow, MPI), model serving infrastructure (KServe, ModelMesh), pipeline orchestration (Data Science Pipelines), and AI governance tools (TrustyAI, Model Registry).

The platform architecture is built on cloud-native principles with Kubernetes-native operators managing the lifecycle of each component. RHOAI integrates deeply with OpenShift services including OAuth for authentication, service mesh (Istio/Maistra) for secure communication, Prometheus for observability, and Routes for external access. The platform supports both CPU and GPU accelerators (NVIDIA CUDA, AMD ROCm, Intel Gaudi) and enables multi-tenant data science environments with resource quotas, workload queueing (Kueue), and role-based access control.

Key platform capabilities include: serverless model inference with auto-scaling, distributed training across multiple nodes, feature stores for ML feature management, model registries for versioning and metadata tracking, explainability and bias detection, pipeline orchestration for MLOps workflows, and integration with NVIDIA NIM for enterprise LLM deployment. All components are built with FIPS compliance, run as non-root containers, and support disconnected/air-gapped deployments.

## Component Inventory

| Component | Type | Version | Purpose |
|-----------|------|---------|---------|
| CodeFlare Operator | Operator | 1.15.0 | Distributed AI/ML workload orchestration with RayCluster and AppWrapper resources |
| Data Science Pipelines Operator | Operator | rhoai-2.25 (763811f) | Lifecycle management of Kubeflow Pipelines for ML workflow orchestration |
| Feast | Operator + Service | 0.54.0 | Feature store for ML feature management with online and offline serving |
| KServe | Operator + Runtime | 4211a5da7 | Serverless model inference platform with autoscaling and traffic management |
| Kubeflow Notebook Controller | Operator | v1.27.0-rhods-1295 | Jupyter notebook instance lifecycle management |
| KubeRay Operator | Operator | f10d68b1 | Ray distributed computing cluster management for ML workloads |
| Kueue | Operator | 7f2f72e51 | Job queueing and resource quota management for batch workloads |
| Llama Stack K8s Operator | Operator | 0.3.0 | Llama Stack inference server deployment and lifecycle management |
| ModelMesh Serving | Operator + Runtime | 1.27.0-rhods-480 | Multi-model serving with high-density model placement |
| Model Registry Operator | Operator | 0b48221 | ML model metadata storage and versioning with ML Metadata backend |
| Notebooks (Workbench Images) | Container Images | v2.25.2-55 | JupyterLab, VS Code, and RStudio development environments |
| ODH Dashboard | Web Application | v1.21.0-18-rhods-4281 | Primary web UI for platform management and resource creation |
| ODH Model Controller | Operator | 1.27.0-rhods-1121 | KServe/ModelMesh integration with OpenShift Routes, service mesh, and authentication |
| Training Operator | Operator | 1.9.0 (3a1af789) | Distributed ML training for PyTorch, TensorFlow, XGBoost, MPI, JAX, PaddlePaddle |
| TrustyAI Service Operator | Operator | d113dae | AI explainability, bias detection, LM evaluation, and guardrails orchestration |

## Component Relationships

### Dependency Graph

```
ODH Dashboard → Kubeflow Notebook Controller (create Notebook CRs)
              → KServe (create InferenceService CRs)
              → Model Registry Operator (create ModelRegistry CRs)
              → Data Science Pipelines Operator (create DSPA CRs)
              → Training Operator (create PyTorchJob/TFJob CRs)

KServe → Knative Serving (serverless mode)
       → Istio (traffic routing, mTLS)
       → ODH Model Controller (OpenShift Routes, auth, monitoring)
       → Model Registry (model metadata)

ODH Model Controller → KServe (watch InferenceService)
                     → ModelMesh (watch ServingRuntime)
                     → Istio (create VirtualServices, Gateways)
                     → Authorino (create AuthConfigs)
                     → Prometheus Operator (create ServiceMonitors)

Data Science Pipelines → Argo Workflows (pipeline execution in v2)
                        → KServe (model deployment from pipelines)
                        → Model Registry (model artifact storage)
                        → S3-compatible storage (pipeline artifacts)

Training Operator → Kueue (workload queueing)
                  → Volcano/Scheduler Plugins (gang scheduling)
                  → Model Registry (trained model storage)

CodeFlare Operator → KubeRay (RayCluster CRD)
                   → Kueue (AppWrapper scheduling)
                   → OpenShift OAuth (Ray dashboard access)

KubeRay → Kueue (gang scheduling)
        → Volcano/YuniKorn (alternative schedulers)

Kueue → Training Operator (job admission)
      → CodeFlare Operator (AppWrapper admission)
      → KubeRay (RayJob/RayCluster admission)
      → Data Science Pipelines (pipeline scheduling)

TrustyAI Service Operator → KServe (monitor InferenceService)
                           → ModelMesh (payload processors)
                           → Kueue (LM evaluation jobs)

Feast → PostgreSQL/Redis (feature storage)
      → S3/GCS (offline data)

Model Registry Operator → PostgreSQL/MySQL (ML Metadata backend)
                        → OpenShift OAuth (authentication)

ModelMesh → ETCD (cluster coordination)
          → S3-compatible storage (model artifacts)
          → KServe (shared InferenceService CRD)

Llama Stack Operator → Ollama/vLLM/TGI (inference backends)
                      → OpenShift Ingress (external access)
```

### Central Components

**Core Infrastructure** (highest number of dependencies):
1. **ODH Dashboard** - Primary user interface, creates resources across all components
2. **KServe** - Model serving hub integrating with pipelines, registry, and monitoring
3. **ODH Model Controller** - Service mesh and authentication orchestrator for inference
4. **Kueue** - Workload admission controller for training, pipelines, and distributed workloads

**Storage & Metadata** (critical shared services):
1. **Model Registry** - Centralized model metadata and versioning
2. **S3-compatible storage** - Shared artifact storage for pipelines, models, and data
3. **PostgreSQL/MySQL** - Backend for Model Registry, DSPA, Feast

**Compute Orchestration**:
1. **Kubeflow Notebook Controller** - Interactive development environment management
2. **Training Operator** - Distributed training orchestration
3. **KubeRay** - Distributed computing for Ray workloads

### Integration Patterns

| Pattern | Components | Mechanism | Purpose |
|---------|------------|-----------|---------|
| CRD Watch & Reconciliation | All operators | Kubernetes watch API | React to resource changes |
| Service Mesh Integration | KServe, ODH Model Controller, TrustyAI | Istio VirtualServices, DestinationRules | Traffic routing, mTLS, telemetry |
| OpenShift Route Creation | KServe, Model Registry, DSPA, TrustyAI | route.openshift.io API | External HTTPS access |
| OAuth Authentication | Dashboard, Model Registry, DSPA, CodeFlare | OpenShift OAuth Proxy sidecar | User authentication |
| Metrics Collection | All operators | Prometheus ServiceMonitor/PodMonitor | Observability |
| Webhook Admission Control | KServe, Training Operator, DSPA, CodeFlare | ValidatingWebhook, MutatingWebhook | Resource validation |
| Gang Scheduling | Training Operator, KubeRay, CodeFlare | Volcano/Scheduler Plugins PodGroups | Coordinated pod scheduling |
| Workload Queueing | Kueue | ClusterQueue, LocalQueue | Resource quota management |
| Model Artifact Storage | KServe, ModelMesh, DSPA, Training Operator | S3 API | Model and data persistence |

## Platform Network Architecture

### Namespaces

| Namespace | Purpose | Components |
|-----------|---------|------------|
| redhat-ods-applications | Core platform services | ODH Dashboard, operators, controllers |
| opendatahub | Alternative core namespace | Used in ODH distribution |
| istio-system | Service mesh control plane | Istio/Maistra components |
| knative-serving | Serverless infrastructure | Knative Serving controllers |
| User namespaces (data science projects) | Data science workloads | Notebooks, InferenceServices, training jobs, pipelines |

### External Ingress Points

| Component | Ingress Type | Hosts | Port | Protocol | Encryption | Purpose |
|-----------|--------------|-------|------|----------|------------|---------|
| ODH Dashboard | OpenShift Route | odh-dashboard.apps.{cluster} | 443/TCP | HTTPS | TLS 1.2+ Edge | Web UI for platform management |
| KServe InferenceService | OpenShift Route | {isvc}-{namespace}.apps.{cluster} | 443/TCP | HTTPS | TLS 1.2+ Edge | Model inference endpoints |
| KServe InferenceService | Istio VirtualService | {isvc}.{namespace}.{domain} | 443/TCP | HTTPS | TLS 1.2+ SIMPLE | Model inference (service mesh mode) |
| DSPA API Server | OpenShift Route | ds-pipeline-{name}.apps.{cluster} | 443/TCP | HTTPS | TLS 1.2+ Reencrypt | Pipeline API access |
| DSPA UI | OpenShift Route | ds-pipeline-ui-{name}.apps.{cluster} | 443/TCP | HTTPS | TLS 1.2+ Reencrypt | Pipeline web interface |
| Model Registry | OpenShift Route | {name}-{namespace}.apps.{cluster} | 443/TCP | HTTPS | TLS 1.2+ Edge/Reencrypt | Model metadata API |
| TrustyAI Service | OpenShift Route | trustyai-{name}.apps.{cluster} | 443/TCP | HTTPS | TLS 1.2+ Reencrypt | Explainability service API |
| Feast Feature Store | OpenShift Route | {name}-online-{namespace}.apps.{cluster} | 443/TCP | HTTPS | TLS 1.2+ Edge | Online feature serving |
| CodeFlare Ray Dashboard | OpenShift Route | ray-dashboard-{cluster}.{domain} | 443/TCP | HTTPS | TLS 1.2+ Edge | Ray cluster monitoring |
| Jupyter Notebooks | OpenShift Route | notebook-{username}.apps.{cluster} | 443/TCP | HTTPS | TLS 1.2+ Edge | Interactive development |

### External Egress Dependencies

| Component | Destination | Port | Protocol | Encryption | Purpose |
|-----------|-------------|------|----------|------------|---------|
| KServe, ModelMesh, DSPA | s3.amazonaws.com, *.s3.amazonaws.com | 443/TCP | HTTPS | TLS 1.2+ | Model artifact storage (AWS S3) |
| KServe, DSPA | storage.googleapis.com | 443/TCP | HTTPS | TLS 1.2+ | Model artifacts (Google Cloud Storage) |
| KServe, DSPA | blob.core.windows.net | 443/TCP | HTTPS | TLS 1.2+ | Model artifacts (Azure Blob) |
| Notebooks, DSPA, Training | quay.io, registry.redhat.io | 443/TCP | HTTPS | TLS 1.2+ | Container image pulls |
| Notebooks, DSPA | pypi.org | 443/TCP | HTTPS | TLS 1.2+ | Python package installation |
| Notebooks, Training Operator | huggingface.co | 443/TCP | HTTPS | TLS 1.2+ | Model and dataset downloads |
| ODH Model Controller, Llama Stack | nvcr.io (NVIDIA NGC) | 443/TCP | HTTPS | TLS 1.2+ | NVIDIA NIM images and models |
| Feast | Snowflake, Redshift, BigQuery | 443/TCP | HTTPS | TLS 1.2+ | Cloud data warehouse integration |
| Model Registry, DSPA, Feast | PostgreSQL/MySQL hosts | 5432/3306/TCP | PostgreSQL/MySQL | TLS 1.2+ (optional) | Database backends |
| Feast, TrustyAI | Redis hosts | 6379/TCP | Redis | TLS 1.2+ (optional) | Feature store / caching |
| All components | Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | Platform API access |

### Internal Service Mesh

| Setting | Value | Components Using |
|---------|-------|------------------|
| mTLS Mode | STRICT (when enabled) | KServe predictor pods, ModelMesh pods |
| mTLS Mode | PERMISSIVE (default) | Most platform services |
| Peer Authentication | ISTIO_MUTUAL (when service mesh enabled) | Namespaces with KServe InferenceServices |
| Traffic Policy | Round Robin (default) | InferenceServices, training jobs |
| Circuit Breaking | Configurable per InferenceService | KServe predictor endpoints |
| Timeout | 300s (default for inference) | InferenceService routes |
| Retry | 3 attempts (default) | InferenceService traffic |

## Platform Security

### RBAC Summary

**Cluster-wide Permissions** (ClusterRoles):

| Component | ClusterRole | Key API Groups | Key Resources | Critical Verbs |
|-----------|-------------|----------------|---------------|----------------|
| KServe | kserve-manager-role | serving.kserve.io | inferenceservices, servingruntimes | create, delete, get, list, patch, update, watch |
| KServe | kserve-manager-role | serving.knative.dev | services | create, delete, get, list, patch, update, watch |
| ODH Model Controller | odh-model-controller-role | serving.kserve.io | inferenceservices, llminferenceservices | get, list, patch, update, watch |
| ODH Model Controller | odh-model-controller-role | networking.istio.io | virtualservices, gateways | create, delete, get, list, patch, update, watch |
| ODH Model Controller | odh-model-controller-role | route.openshift.io | routes | create, delete, get, list, patch, update, watch |
| DSPA | manager-role | datasciencepipelinesapplications.opendatahub.io | datasciencepipelinesapplications | create, delete, get, list, patch, update, watch |
| DSPA | manager-argo-role | argoproj.io | workflows, workflowtemplates | create, delete, get, list, patch, update, watch |
| Training Operator | training-operator | kubeflow.org | pytorchjobs, tfjobs, mpijobs, xgboostjobs, paddlejobs, jaxjobs | create, delete, get, list, patch, update, watch |
| Kueue | kueue-manager-role | kueue.x-k8s.io | workloads, clusterqueues, localqueues | create, delete, get, list, patch, update, watch |
| CodeFlare Operator | manager-role | ray.io | rayclusters, rayjobs | create, delete, get, list, patch, update, watch |
| KubeRay | kuberay-operator | ray.io | rayclusters, rayjobs, rayservices | create, delete, get, list, patch, update, watch |
| Model Registry Operator | manager-role | modelregistry.opendatahub.io | modelregistries | create, delete, get, list, patch, update, watch |
| Feast | feast-operator-manager-role | feast.dev | featurestores | create, delete, get, list, patch, update, watch |
| TrustyAI Operator | manager-role | trustyai.opendatahub.io | trustyaiservices, lmevaljobs, guardrailsorchestrators | create, delete, get, list, patch, update, watch |
| ODH Dashboard | odh-dashboard | kubeflow.org | notebooks | create, delete, get, list, patch, update, watch |

**Common Cross-Component Permissions**:
- **Events**: All operators create/patch events for audit trails
- **Secrets**: Most operators get/list/watch secrets for credentials
- **ConfigMaps**: All operators read configuration from ConfigMaps
- **Pods**: All operators get/list/watch pods for workload monitoring
- **ServiceAccounts**: Most operators create ServiceAccounts for workloads

### Secrets Inventory

| Component | Secret Name | Type | Purpose |
|-----------|-------------|------|---------|
| All operators | webhook-server-cert | kubernetes.io/tls | Admission webhook TLS certificates |
| KServe, ModelMesh, DSPA | storage-config | Opaque | S3/storage credentials for model retrieval |
| Model Registry, DSPA, Feast | {db-secret} | Opaque | PostgreSQL/MySQL database credentials |
| ODH Dashboard, Model Registry, DSPA | {oauth-proxy-secret} | Opaque | OAuth proxy session cookies |
| ODH Dashboard, Model Registry | {oauth-client-secret} | Opaque | OAuth client credentials |
| CodeFlare | {cluster}-ca | Opaque | mTLS CA certificates for Ray clusters |
| Notebooks, Training, DSPA | User-defined credentials | Opaque | Cloud provider, registry, API tokens |
| NVIDIA NIM | {account}-nim-pull-secret | kubernetes.io/dockerconfigjson | NVIDIA NGC registry authentication |
| All workloads | ServiceAccount tokens | kubernetes.io/service-account-token | Kubernetes API authentication |

### Authentication Mechanisms

| Pattern | Components Using | Enforcement Point | Technology |
|---------|------------------|-------------------|------------|
| OpenShift OAuth (Bearer Token JWT) | Dashboard, Model Registry, DSPA UI, TrustyAI, CodeFlare Ray Dashboard | OAuth Proxy Sidecar | OpenShift OAuth Server + TokenReview |
| Kubernetes RBAC (ServiceAccount Token) | All operators, workloads | Kubernetes API Server | JWT ServiceAccount tokens |
| mTLS Client Certificates | KServe predictors (service mesh mode), Istio communication | Istio sidecars | X.509 certificates via Istio CA |
| Webhook mTLS | Admission webhooks (all operators) | Kubernetes API Server | API Server client certificate |
| AWS IAM Credentials | KServe, DSPA, Training (S3 access) | AWS S3 endpoints | AWS Signature V4 |
| Database Authentication | Model Registry, DSPA, Feast | PostgreSQL/MySQL servers | Username/password or client certificates |
| Bearer Tokens (API calls) | Dashboard → K8s API, KServe inference | Application layer | JWT or OAuth2 tokens |
| None (internal ClusterIP) | Inter-component communication within cluster | Network policies | Kubernetes network isolation |

### Authorization Policies

**Istio AuthorizationPolicies** (when service mesh enabled):
- KServe InferenceServices: JWT validation with Authorino or Kuadrant AuthPolicy
- Principal-based access: Users must have namespace access
- Path-based authorization: Different rules for /v1/models/:predict vs. /metrics

**Kubernetes RBAC Policies**:
- Namespace admins can create all ML resources
- Data scientists can create Notebooks, InferenceServices, training jobs
- View-only users can list resources but not modify
- Service accounts have least-privilege access per component

## Platform APIs

### Custom Resource Definitions

| Component | API Group | Kind | Scope | Purpose |
|-----------|-----------|------|-------|---------|
| KServe | serving.kserve.io/v1beta1 | InferenceService | Namespaced | Model serving instances with predictor/transformer/explainer |
| KServe | serving.kserve.io/v1alpha1 | ServingRuntime | Namespaced | Model server runtime templates |
| KServe | serving.kserve.io/v1alpha1 | ClusterServingRuntime | Cluster | Cluster-wide runtime templates |
| KServe | serving.kserve.io/v1alpha1 | InferenceGraph | Namespaced | Multi-model inference pipelines |
| KServe | serving.kserve.io/v1alpha1 | LLMInferenceService | Namespaced | LLM-specific inference services |
| DSPA | datasciencepipelinesapplications.opendatahub.io/v1 | DataSciencePipelinesApplication | Namespaced | Pipeline deployment configuration |
| DSPA | pipelines.kubeflow.org/v1 | Pipeline | Namespaced | Pipeline definitions (kubernetes pipelineStore) |
| DSPA | pipelines.kubeflow.org/v1 | PipelineVersion | Namespaced | Pipeline versions |
| DSPA | argoproj.io/v1alpha1 | Workflow | Namespaced | Argo Workflow execution |
| Training Operator | kubeflow.org/v1 | PyTorchJob | Namespaced | PyTorch distributed training |
| Training Operator | kubeflow.org/v1 | TFJob | Namespaced | TensorFlow distributed training |
| Training Operator | kubeflow.org/v1 | MPIJob | Namespaced | MPI-based HPC training |
| Training Operator | kubeflow.org/v1 | XGBoostJob | Namespaced | XGBoost distributed training |
| Training Operator | kubeflow.org/v1 | PaddleJob | Namespaced | PaddlePaddle training |
| Training Operator | kubeflow.org/v1 | JAXJob | Namespaced | JAX distributed training |
| KubeRay | ray.io/v1 | RayCluster | Namespaced | Ray distributed computing cluster |
| KubeRay | ray.io/v1 | RayJob | Namespaced | Ray batch job with auto-created cluster |
| KubeRay | ray.io/v1 | RayService | Namespaced | Ray Serve for ML model serving |
| CodeFlare | workload.codeflare.dev/v1beta2 | AppWrapper | Namespaced | Grouped resources for Kueue batch scheduling |
| Kueue | kueue.x-k8s.io/v1beta1 | ClusterQueue | Cluster | Cluster-wide resource quotas |
| Kueue | kueue.x-k8s.io/v1beta1 | LocalQueue | Namespaced | Namespace-scoped queue mapping |
| Kueue | kueue.x-k8s.io/v1beta1 | Workload | Namespaced | Job or pod group with resource requirements |
| Kueue | kueue.x-k8s.io/v1beta1 | ResourceFlavor | Cluster | Resource variant definition (GPU types, node pools) |
| Model Registry | modelregistry.opendatahub.io/v1beta1 | ModelRegistry | Namespaced | Model metadata repository instance |
| Feast | feast.dev/v1alpha1 | FeatureStore | Namespaced | Feature store deployment configuration |
| TrustyAI | trustyai.opendatahub.io/v1 | TrustyAIService | Namespaced | AI explainability service |
| TrustyAI | trustyai.opendatahub.io/v1alpha1 | LMEvalJob | Namespaced | Language model evaluation job |
| TrustyAI | trustyai.opendatahub.io/v1alpha1 | GuardrailsOrchestrator | Namespaced | AI safety guardrails orchestration |
| Notebook Controller | kubeflow.org/v1 | Notebook | Namespaced | Jupyter notebook instance |
| Llama Stack | llamastack.io/v1alpha1 | LlamaStackDistribution | Namespaced | Llama Stack server deployment |
| ODH Dashboard | dashboard.opendatahub.io/v1 | OdhApplication | Namespaced | Dashboard application tiles |
| ODH Dashboard | opendatahub.io/v1alpha | OdhDashboardConfig | Namespaced | Dashboard feature flags and settings |
| ODH Dashboard | infrastructure.opendatahub.io/v1 | HardwareProfile | Namespaced | GPU/accelerator profiles |
| ODH Model Controller | nim.opendatahub.io/v1 | Account | Namespaced | NVIDIA NIM account integration |

### Public HTTP Endpoints

**User-Facing APIs**:

| Component | Path | Method | Port | Protocol | Auth | Purpose |
|-----------|------|--------|------|----------|------|---------|
| KServe | /v1/models/{model}:predict | POST | 443/TCP | HTTPS | OAuth/mTLS | V1 inference protocol |
| KServe | /v2/models/{model}/infer | POST | 443/TCP | HTTPS | OAuth/mTLS | V2 inference protocol |
| DSPA | /apis/v2beta1/* | ALL | 443/TCP | HTTPS | OAuth | Pipeline API v2beta1 |
| Model Registry | /api/model_registry/v1alpha3/* | ALL | 443/TCP | HTTPS | OAuth | Model metadata API |
| TrustyAI | /* | ALL | 443/TCP | HTTPS | OAuth | Explainability service API |
| Feast | /get-online-features | POST | 443/TCP | HTTPS | OIDC/RBAC | Online feature retrieval |
| ODH Dashboard | /* | GET | 443/TCP | HTTPS | OAuth | Web UI and backend APIs |
| Ray Dashboard | /* | ALL | 443/TCP | HTTPS | OAuth | Ray cluster monitoring |
| Notebooks | /notebook/{namespace}/{username} | ALL | 443/TCP | HTTPS | OAuth | Jupyter/VS Code/RStudio |

**Operator/Metrics Endpoints** (internal):

| Component | Path | Port | Purpose |
|-----------|------|------|---------|
| All operators | /metrics | 8080 or 8443/TCP | Prometheus metrics |
| All operators | /healthz | 8081/TCP | Liveness probes |
| All operators | /readyz | 8081/TCP | Readiness probes |

## Data Flows

### Key Platform Workflows

#### Workflow 1: Model Development to Deployment

| Step | Component | Action | Next Component |
|------|-----------|--------|----------------|
| 1 | User via ODH Dashboard | Create Notebook (Jupyter/VS Code) | Notebook Controller |
| 2 | Notebook Controller | Deploy StatefulSet with workbench image | Kubelet → Container Runtime |
| 3 | Data Scientist in Notebook | Train model, save to S3 or Model Registry | S3 / Model Registry |
| 4 | User via ODH Dashboard | Create InferenceService CR | KServe Controller |
| 5 | KServe Controller | Create Knative Service or Deployment | Knative / Kubernetes |
| 6 | ODH Model Controller | Create Route, VirtualService, AuthConfig, ServiceMonitor | OpenShift Router / Istio |
| 7 | KServe Predictor Pod | Download model from S3 (storage-initializer) | S3 |
| 8 | KServe Predictor Pod | Serve predictions via /v2/models/{model}/infer | External clients |
| 9 | TrustyAI Service (optional) | Monitor predictions for bias/drift | KServe predictor |

#### Workflow 2: Pipeline-Driven ML Workflow

| Step | Component | Action | Next Component |
|------|-----------|--------|----------------|
| 1 | User via ODH Dashboard | Create DataSciencePipelinesApplication | DSPA Operator |
| 2 | DSPA Operator | Deploy API Server, Workflow Controller, Database, S3 | Kubernetes |
| 3 | User via DSPA UI | Submit pipeline (data prep → training → evaluation → deployment) | DSPA API Server |
| 4 | DSPA API Server | Create Argo Workflow CR | Argo Workflow Controller |
| 5 | Workflow Controller | Create pods for each pipeline step | Kubelet |
| 6 | Pipeline Step: Data Prep | Process data, save to S3 | S3 |
| 7 | Pipeline Step: Training | Train model (using Training Operator PyTorchJob if distributed) | Training Operator |
| 8 | Training Operator | Create training pods (master + workers) | Kueue → Scheduler → Kubelet |
| 9 | Pipeline Step: Evaluation | Evaluate model metrics | DSPA API Server (record metrics) |
| 10 | Pipeline Step: Deployment | Create InferenceService CR | KServe |
| 11 | Pipeline Step: Registry | Register model in Model Registry | Model Registry API |

#### Workflow 3: Distributed Training with Queueing

| Step | Component | Action | Next Component |
|------|-----------|--------|----------------|
| 1 | User via ODH Dashboard | Create PyTorchJob CR | Training Operator |
| 2 | Training Operator Webhook | Validate job spec | Kubernetes API Server |
| 3 | Training Operator Controller | Create PodGroup for gang scheduling | Kueue |
| 4 | Kueue Controller | Evaluate ClusterQueue quotas | LocalQueue → ClusterQueue |
| 5 | Kueue Controller | Admit workload when quota available | Kubernetes Scheduler |
| 6 | Scheduler (with gang scheduling) | Schedule all pods together | Volcano/Scheduler Plugins |
| 7 | Training Pods | Distributed training with PyTorch DDP | Inter-pod communication |
| 8 | Training Pods | Save model to S3 or Model Registry | S3 / Model Registry |
| 9 | Training Operator | Update PyTorchJob status to Succeeded | User notification |

#### Workflow 4: Feature Engineering and Model Serving

| Step | Component | Action | Next Component |
|------|-----------|--------|----------------|
| 1 | User via Dashboard/kubectl | Create FeatureStore CR | Feast Operator |
| 2 | Feast Operator | Deploy Online Store, Offline Store, Registry | Kubernetes |
| 3 | Feature Engineer in Notebook | Define features, materialize to online store | Feast CLI → Feast Offline Store |
| 4 | Feast CronJob | Scheduled materialization from offline to online store | Redis/PostgreSQL |
| 5 | Model Training Job | Fetch historical features from offline store | Feast Offline Store → S3/Snowflake |
| 6 | Model Serving (KServe) | Fetch online features for real-time inference | Feast Online Store → Redis |
| 7 | Inference Request | Client → KServe → Feast Online → Model Prediction | Response to client |

#### Workflow 5: Model Explainability and Monitoring

| Step | Component | Action | Next Component |
|------|-----------|--------|----------------|
| 1 | User via Dashboard/kubectl | Create TrustyAIService CR | TrustyAI Operator |
| 2 | TrustyAI Operator | Deploy TrustyAI Service with PVC/database | Kubernetes |
| 3 | TrustyAI Operator | Patch KServe InferenceService for payload monitoring | KServe |
| 4 | Client | Send inference request | KServe InferenceService |
| 5 | KServe (with payload processor) | Log request/response to TrustyAI Service | TrustyAI Service |
| 6 | TrustyAI Service | Store predictions in PVC/database | Storage |
| 7 | User via TrustyAI API | Request LIME/SHAP explanations for predictions | TrustyAI Service |
| 8 | TrustyAI Service | Compute explanations, detect bias | Response to user |
| 9 | Prometheus | Scrape TrustyAI metrics (fairness, drift) | TrustyAI Service /q/metrics |

## Deployment Architecture

### Deployment Topology

**Platform Operators** (redhat-ods-applications namespace):
- ODH Dashboard (2 replicas with anti-affinity)
- KServe Controller (1 replica)
- ODH Model Controller (1 replica)
- Data Science Pipelines Operator (1 replica)
- Training Operator (1 replica)
- Kubeflow Notebook Controller (1 replica)
- KubeRay Operator (1 replica)
- CodeFlare Operator (1 replica)
- Kueue Controller (1 replica with leader election)
- Model Registry Operator (1 replica)
- Feast Operator (1 replica)
- TrustyAI Service Operator (1 replica)
- ModelMesh Serving Controller (1 replica)
- Llama Stack Operator (1 replica)

**User Workload Namespaces** (data science projects):
- Jupyter Notebooks (StatefulSets, 1 pod per user)
- InferenceService Predictors (Knative Services or Deployments, autoscaling)
- ModelMesh Runtime Pods (Deployments, typically 2 replicas)
- Training Job Pods (Jobs/Pods, ephemeral)
- Pipeline Workflow Pods (Pods, ephemeral)
- RayClusters (StatefulSets for head + workers)
- TrustyAI Service instances (Deployments, 1 replica)
- Model Registry instances (Deployments, 1 replica)
- Feast Feature Stores (Deployments, scalable)
- DSPA instances (Deployments for API Server, controllers, database, UI)

**Shared Infrastructure Namespaces**:
- istio-system: Istio control plane (istiod), ingress/egress gateways
- knative-serving: Knative controllers (activator, autoscaler, webhook)
- openshift-monitoring: Prometheus, Thanos, Alertmanager (if cluster monitoring)
- openshift-ingress: OpenShift Router pods

### Resource Requirements

**Operator Pods** (typical requests/limits):
- CPU: 10m-500m requests, 500m-2000m limits
- Memory: 64Mi-1Gi requests, 512Mi-2Gi limits
- Most operators run with minimal resources; spikes during reconciliation

**Workload Pods** (user-configurable):
- Notebooks: 1-8 CPU, 1-64Gi memory, 0-8 GPUs
- Training Jobs: 1-128 CPU per pod, 1-512Gi memory, 0-16 GPUs per pod
- InferenceService Predictors: 0.1-4 CPU, 128Mi-8Gi memory, 0-2 GPUs
- DSPA API Server: 500m-1000m CPU, 1-2Gi memory
- RayCluster: 1-64 CPU per node, 1-256Gi memory per node, 0-8 GPUs per node

## Version-Specific Changes (2.25.0)

| Component | Changes |
|-----------|---------|
| CodeFlare Operator | - Update UBI9 go-toolset base image to 1.25<br>- Update dependencies for security patches |
| DSPA | - Update Go to 1.25.5 to address CVE-2025-61729<br>- Update registry base images |
| Feast | - Sync Konflux pipelineruns with konflux-central<br>- Bump urllib3 to >2.6.0 for security |
| KServe | - Security: Reject root path and prevent directory traversal<br>- Add proxy configuration support<br>- Fix ppc64le and s390x hermetic builds |
| Kubeflow Notebook Controller | - Bump golang version from 1.24 to 1.25<br>- Add govulncheck for vulnerability scanning |
| KubeRay | - Update UBI9 go-toolset digest to 3cdf0d1<br>- Security patch updates |
| Kueue | - Update OpenShift Go builder to v1.24<br>- Regular base image security patches |
| Llama Stack Operator | - Fix NetworkPolicy to remove podSelectors<br>- Multiple UBI base image updates |
| ModelMesh Serving | - Fix CVE-2025-61729 (crypto/x509) by upgrading to Go 1.25.7<br>- Update controller-gen to 0.17.0 |
| Model Registry Operator | - Update to Go 1.25.7 toolchain<br>- Merge upstream stable-2.x branch |
| Notebooks | - TrustyAI pandas issue fixed<br>- Add PyTorch LLMCompressor CUDA variant<br>- Move up-to-date ntb/ and scripts from main |
| ODH Dashboard | - Merge upstream stable-2.x into rhoai-2.25<br>- Add rhoai-version parameter (2.25.0)<br>- Go version bump refactoring |
| ODH Model Controller | - FIPS Compliance: replace math/rand with crypto/rand<br>- Upgrade Go to 1.25.7<br>- Fix UID mismatch in ray-tls secrets |
| Training Operator | - Restrict secrets RBAC to namespace-scoped Role<br>- Fix CVE-2025-61726 by upgrading Go to 1.25<br>- Update go-toolset base image |
| TrustyAI Service Operator | - Sync pipelineruns with konflux-central (multiple updates) |

**Common Themes Across Components**:
- **Security**: Go version updates to 1.25+ for CVE fixes
- **Base Images**: Regular UBI9 (ubi-minimal, go-toolset) digest updates
- **Build System**: Konflux pipeline synchronization across all components
- **FIPS Compliance**: Strict FIPS runtime enforcement
- **Multi-Architecture**: Fixes for ppc64le, s390x, arm64 builds
- **Dependency Updates**: Automated renovate updates for security patches

## Platform Maturity

- **Total Components**: 15
- **Operator-based Components**: 14 (93%)
- **Container Image-Only Components**: 1 (Notebooks/Workbenches)
- **Service Mesh Coverage**: ~40% (KServe serverless mode, ModelMesh, TrustyAI)
- **mTLS Enforcement**: PERMISSIVE by default, STRICT in service mesh mode (configurable)
- **CRD API Versions**: v1beta1 (KServe, Kueue), v1 (most others), v1alpha1 (experimental features)
- **Webhook Coverage**: 12 of 14 operators have admission webhooks
- **Metrics Coverage**: 100% (all operators expose Prometheus metrics)
- **OAuth Integration**: Dashboard, Model Registry, DSPA UI, TrustyAI, CodeFlare Ray Dashboard
- **Multi-Tenancy Support**: Full (namespace isolation, quotas, RBAC, workload queueing)
- **GPU Support**: NVIDIA CUDA, AMD ROCm, Intel Gaudi across notebooks, training, inference
- **Storage Backends**: S3 (AWS, Minio, compatible), GCS, Azure Blob, PostgreSQL, MySQL, Redis, PVCs
- **AI/ML Frameworks**: PyTorch, TensorFlow, XGBoost, JAX, PaddlePaddle, Scikit-Learn, Caikit, vLLM, HuggingFace
- **Inference Protocols**: KServe V1, KServe V2 (REST and gRPC), ModelMesh gRPC
- **Pipeline Orchestrators**: Argo Workflows (DSP v2), Tekton (DSP v1 legacy)
- **Distributed Computing**: Ray, MPI, Horovod, PyTorch DDP, TensorFlow Parameter Server
- **Model Serving Modes**: Serverless (Knative), Raw Kubernetes, Multi-model (ModelMesh)
- **LLM Support**: vLLM (CPU, CUDA, Gaudi, ROCm, multinode), NVIDIA NIM, Llama Stack, Caikit-TGIS
- **Explainability**: TrustyAI (LIME, SHAP, bias detection, drift monitoring)
- **Feature Engineering**: Feast (online/offline stores, materialization, time-travel)
- **Job Queueing**: Kueue (ClusterQueue, LocalQueue, fair sharing, preemption, cohorts)
- **Gang Scheduling**: Volcano, Scheduler Plugins integration
- **High Availability**: Leader election for operators, multi-replica for services, autoscaling for inference
- **Security Posture**: FIPS-compliant, non-root containers, RBAC, mTLS, OAuth, network policies, admission webhooks

## Next Steps for Documentation

1. **Generate Architecture Diagrams**:
   - Component dependency graph (directed acyclic graph showing CRD watches and API calls)
   - Network flow diagram (ingress → service mesh → workloads → egress)
   - Data flow sequence diagrams for key workflows
   - Deployment topology diagram (namespaces, pods, services)

2. **Update ADRs (Architecture Decision Records)**:
   - ADR: Why Knative Serving for serverless inference
   - ADR: Choice of Argo Workflows over Tekton for DSPA v2
   - ADR: Multi-mode serving (serverless vs raw vs ModelMesh)
   - ADR: Kueue integration for workload management
   - ADR: OAuth proxy pattern for authentication
   - ADR: Service mesh integration strategy

3. **Create User-Facing Documentation**:
   - Getting Started Guide (notebook → training → serving)
   - Advanced Topics: Distributed training, multi-model pipelines, custom runtimes
   - Operations Guide: Monitoring, troubleshooting, scaling
   - Security Guide: RBAC setup, network policies, secret management
   - Integration Guide: Connecting external storage, databases, identity providers

4. **Generate Security Architecture Review (SAR) Documentation**:
   - Network security diagram (zones, trust boundaries, encryption)
   - Authentication/authorization flow diagrams
   - Secret management and rotation policies
   - Compliance matrix (FIPS, PCI-DSS, HIPAA considerations)
   - Threat model and mitigations

5. **Platform Governance**:
   - Resource quota recommendations by workload type
   - Multi-tenancy best practices
   - Backup and disaster recovery procedures
   - Upgrade and rollback strategies
   - SLA definitions for platform components

6. **Performance and Scaling Guidance**:
   - Sizing guide for different deployment scales (small/medium/large/enterprise)
   - GPU allocation strategies
   - Inference autoscaling tuning
   - Database performance tuning for Model Registry and DSPA
   - Network bandwidth planning for distributed training

7. **Integration Examples**:
   - CI/CD integration with OpenShift Pipelines/GitOps
   - MLOps workflow examples (end-to-end)
   - External data source integration (databases, data lakes, streaming)
   - Model registry migration strategies
   - Custom runtime creation guides
