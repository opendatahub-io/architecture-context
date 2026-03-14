# Platform: Red Hat OpenShift AI 3.3.0

## Metadata
- **Distribution**: RHOAI (Red Hat OpenShift AI)
- **Version**: 3.3.0
- **Release Date**: 2026-03
- **Base Platform**: OpenShift Container Platform 4.12+
- **Components Analyzed**: 15
- **Deployment Model**: Kubernetes Operator-based

## Platform Overview

Red Hat OpenShift AI (RHOAI) 3.3.0 is an enterprise AI/ML platform built on OpenShift that provides end-to-end capabilities for developing, training, serving, and monitoring machine learning models at scale. The platform integrates 15 specialized components orchestrated by a central operator to deliver a complete data science lifecycle management solution.

The platform enables data scientists to work in containerized Jupyter/RStudio/VS Code workbenches, build ML pipelines with Kubeflow Pipelines, train models using distributed frameworks (PyTorch, TensorFlow, JAX), serve models through KServe with autoscaling and canary deployments, track experiments with MLflow, manage model metadata via Model Registry, and ensure AI fairness and explainability through TrustyAI. Infrastructure services include feature stores (Feast), distributed computing (Ray), job queueing (Kueue), and LLM-specific capabilities (Llama Stack, FMS Guardrails).

The platform is designed for multi-tenancy with namespace isolation, integrates deeply with OpenShift security (OAuth, RBAC, NetworkPolicies), and leverages Istio service mesh for mTLS and traffic management. All components are deployed via Kubernetes operators following a GitOps-friendly declarative configuration approach.

## Component Inventory

| Component | Type | Version | Purpose |
|-----------|------|---------|---------|
| RHODS Operator | Central Operator | v1.6.0 | Orchestrates platform lifecycle and component deployment |
| ODH Dashboard | Web Application | v1.21.0 | Unified UI for managing projects, workbenches, models, and pipelines |
| Workbenches (Notebooks) | Container Images | v20xx.2 | JupyterLab, RStudio, VS Code IDE environments with ML frameworks |
| ODH Notebook Controller | Kubernetes Operator | v1.27.0 | Manages notebook lifecycle with Gateway API routing and auth |
| Data Science Pipelines Operator | Kubernetes Operator | v0.0.1 | ML workflow orchestration based on Kubeflow Pipelines v2 |
| KServe | Model Serving Platform | v0.15 | Kubernetes-native model serving with autoscaling and canary deployments |
| ODH Model Controller | Kubernetes Operator | v1.27.0 | Extends KServe with OpenShift Routes, KEDA, and NIM integration |
| Model Registry Operator | Kubernetes Operator | 4fdd8de | Manages model metadata storage and versioning with PostgreSQL/MySQL |
| MLflow Operator | Kubernetes Operator | 49b5d8d | Deploys MLflow tracking servers for experiment management |
| Feast Operator | Kubernetes Operator | 98a224e | Feature store for consistent online/offline feature access |
| Training Operator | Kubernetes Operator | v1.9.0 | Distributed training for PyTorch, TensorFlow, XGBoost, MPI, JAX |
| Trainer (Kubeflow Trainer) | Kubernetes Operator | v2.1.0 | LLM fine-tuning with progression tracking and RHOAI extensions |
| KubeRay Operator | Kubernetes Operator | v1.4.2 | Manages Ray clusters for distributed computing and serving |
| TrustyAI Service Operator | Kubernetes Operator | v1.39.0 | Model explainability, fairness monitoring, and LLM guardrails |
| Llama Stack Operator | Kubernetes Operator | v0.6.0 | Deploys Llama Stack servers with Ollama/vLLM integration |

## Component Relationships

### Dependency Graph

```
rhods-operator (Central Control Plane)
├── odh-dashboard
│   ├── API calls → kserve (InferenceService management)
│   ├── API calls → model-registry (model metadata)
│   ├── API calls → data-science-pipelines (pipeline management)
│   ├── API calls → feast (feature store management)
│   └── UI integration → notebooks (workbench management)
│
├── kserve
│   ├── Istio/Knative (traffic management, autoscaling)
│   ├── model-registry (model metadata lookups)
│   └── odh-model-controller (OpenShift integration)
│
├── odh-model-controller
│   ├── Extends → kserve (Routes, NetworkPolicies, KEDA, ServiceMonitors)
│   └── Integrates → NVIDIA NIM (model serving)
│
├── data-science-pipelines-operator
│   ├── Argo Workflows (pipeline execution)
│   ├── Creates InferenceServices → kserve
│   ├── Reads metadata → model-registry
│   └── Accessed from → notebooks (KFP SDK)
│
├── model-registry-operator
│   ├── PostgreSQL/MySQL (metadata storage)
│   └── Queried by → kserve, odh-dashboard, data-science-pipelines
│
├── mlflow-operator
│   ├── PostgreSQL/S3 (artifact and metadata storage)
│   ├── Gateway API → data-science-gateway (external access)
│   └── Accessed from → notebooks (MLflow SDK)
│
├── feast-operator
│   ├── PostgreSQL/Redis (online/offline stores)
│   ├── OpenShift Routes (external access)
│   └── Accessed from → notebooks, kserve (feature retrieval)
│
├── training-operator
│   ├── JobSet (multi-node training coordination)
│   ├── Volcano/Coscheduling (gang scheduling)
│   └── Launched from → notebooks, data-science-pipelines
│
├── trainer (Kubeflow Trainer)
│   ├── JobSet (distributed training)
│   ├── Progression tracking → training pods (metrics polling)
│   └── NetworkPolicy isolation
│
├── kuberay-operator
│   ├── Ray clusters (distributed computing)
│   └── Accessed from → notebooks, data-science-pipelines
│
├── trustyai-service-operator
│   ├── Monitors → kserve InferenceServices
│   ├── FMS Guardrails orchestration
│   └── PostgreSQL/PVC (inference logging)
│
├── llama-stack-operator
│   ├── Ollama/vLLM (inference providers)
│   └── NetworkPolicy isolation
│
└── notebooks (workbench images)
    ├── Launched by → odh-notebook-controller
    ├── OAuth proxy (authentication)
    └── Gateway API → data-science-gateway (external access)
```

### Central Components

**Core Infrastructure:**
1. **rhods-operator**: Central orchestrator managing all component lifecycles
2. **odh-dashboard**: Primary user interface for all platform capabilities
3. **kserve + odh-model-controller**: Core model serving infrastructure

**Integration Hubs:**
1. **model-registry-operator**: Central metadata repository queried by multiple components
2. **data-science-gateway**: Single external entry point for notebooks, MLflow, model serving
3. **data-science-pipelines-operator**: Workflow orchestration connecting training, serving, and notebooks

### Integration Patterns

**Common Patterns:**
- **CRD-based Integration**: Components watch and create other component CRDs (e.g., DSP creates InferenceServices)
- **API Calls via Service Discovery**: REST/gRPC calls using Kubernetes Service DNS
- **Event-Driven Watches**: Operators watch ConfigMaps, Secrets, and other CRDs for changes
- **Gateway API Routing**: HTTPRoute resources provide unified external access through data-science-gateway
- **ServiceMonitor Pattern**: Prometheus scrapes metrics from all operator and service components
- **NetworkPolicy Isolation**: Fine-grained pod-to-pod traffic control per component

## Platform Network Architecture

### Namespaces

| Namespace | Purpose | Components |
|-----------|---------|------------|
| redhat-ods-operator | Operator control plane | rhods-operator, monitoring controllers |
| redhat-ods-applications | Application layer | odh-dashboard, odh-model-controller, odh-notebook-controller, operators for MLflow, Model Registry, Feast, Llama Stack, TrustyAI |
| redhat-ods-monitoring | Observability | Prometheus, AlertManager, Grafana (optional) |
| openshift-ingress | Gateway | data-science-gateway, ingress controllers |
| istio-system | Service mesh (optional) | Istio control plane for KServe traffic management |
| knative-serving | Serverless (optional) | Knative for KServe autoscaling and revision management |
| User namespaces | Workloads | Notebooks, training jobs, InferenceServices, pipelines (created by users) |

### External Ingress Points

| Component | Ingress Type | Hosts | Port | Protocol | Encryption | Purpose |
|-----------|--------------|-------|------|----------|------------|---------|
| odh-dashboard | OpenShift Route / HTTPRoute | dashboard-*.apps.cluster | 443/TCP | HTTPS | TLS 1.2+ (Reencrypt) | Web UI for platform management |
| Notebooks | HTTPRoute | data-science-gateway | 443/TCP | HTTPS | TLS 1.2+ | Jupyter/RStudio/VS Code access via /notebook/{ns}/{name} |
| KServe InferenceServices | Istio VirtualService / Route | {isvc}-{ns}.apps.cluster | 443/TCP | HTTPS | TLS 1.2+ | Model inference endpoints |
| MLflow | HTTPRoute | data-science-gateway | 443/TCP | HTTPS | TLS 1.3 | MLflow tracking UI and API via /mlflow path |
| Feast | OpenShift Route | {feast}-{ns}.apps.cluster | 443/TCP | HTTPS | TLS 1.2+ | Feature store online/offline/UI endpoints |
| Model Registry | OpenShift Route | {registry}-{ns}.apps.cluster | 443/TCP | HTTPS | TLS 1.2+ | Model metadata REST API |
| TrustyAI Service | OpenShift Route | {trustyai}-{ns}.apps.cluster | 443/TCP | HTTPS | TLS 1.2+ | Explainability and monitoring API |
| Data Science Pipelines | OpenShift Route | ds-pipeline-{name}.apps.cluster | 443/TCP | HTTPS | TLS 1.2+ (Reencrypt) | Pipeline API and UI |

### External Egress Dependencies

| Component | Destination | Port | Protocol | Encryption | Purpose |
|-----------|-------------|------|----------|------------|---------|
| KServe, Training Operator, Notebooks | S3-compatible storage (AWS S3, Minio, etc.) | 443/TCP | HTTPS | TLS 1.2+ | Model artifacts, datasets, pipeline storage |
| Model Registry, MLflow, Feast, DSP | PostgreSQL / MySQL / MariaDB | 5432/TCP, 3306/TCP | PostgreSQL/MySQL | TLS 1.2+ (optional) | Metadata persistence |
| Feast | Redis | 6379/TCP | Redis | TLS 1.2+ (optional) | High-performance online feature store |
| All components | Container Registries (quay.io, registry.redhat.io) | 443/TCP | HTTPS | TLS 1.2+ | Container image pulls |
| Notebooks, Training Jobs | PyPI, HuggingFace Hub, Git repos | 443/TCP | HTTPS | TLS 1.2+ | Package installation, model/dataset downloads |
| KServe, Notebooks | Google Cloud Storage | 443/TCP | HTTPS | TLS 1.2+ | Model artifacts (alternative to S3) |
| KServe, Notebooks | Azure Blob Storage | 443/TCP | HTTPS | TLS 1.2+ | Model artifacts (alternative to S3) |
| Feast (optional) | External Git repositories | 443/TCP | HTTPS/SSH | TLS 1.2+ / SSH | Feature repository synchronization |
| odh-model-controller | NVIDIA NGC API | 443/TCP | HTTPS | TLS 1.2+ | NIM account validation and model configs |
| rhods-operator | Component Git Repos | 443/TCP | HTTPS | TLS 1.2+ | Fetch component manifests (optional) |

### Internal Service Mesh

| Setting | Value | Components Using |
|---------|-------|------------------|
| mTLS Mode | PERMISSIVE (default) or STRICT | KServe, Data Science Pipelines, TrustyAI |
| Peer Authentication | Optional per namespace | KServe InferenceServices, Pipeline components |
| VirtualServices | Per InferenceService/InferenceGraph | KServe, odh-model-controller |
| DestinationRules | Per InferenceService | KServe, TrustyAI |
| Gateways | Shared data-science-gateway | Notebooks, MLflow, Feast, Model Registry |
| EnvoyFilters | Custom Istio configurations | odh-model-controller for NIM, Authorino integration |

## Platform Security

### RBAC Summary

**Cluster-Admin Level Permissions:**

| Component | ClusterRole Capabilities | Justification |
|-----------|-------------------------|---------------|
| rhods-operator | Full CRD lifecycle, RBAC management, SCC modification, cross-namespace resource management | Central orchestrator managing entire platform |
| kserve | InferenceService/ServingRuntime CRDs, Knative Services, Istio resources, Gateway API | Model serving across namespaces with service mesh |
| odh-model-controller | KServe extensions, Routes, NetworkPolicies, KEDA, ServiceMonitors, Templates | OpenShift-specific integrations for KServe |

**Namespace-Scoped Permissions:**

| Component | Namespace Scope | Key Resources Managed |
|-----------|----------------|----------------------|
| data-science-pipelines-operator | Per DSPA instance | Argo Workflows, MariaDB, Minio, Secrets, Services |
| model-registry-operator | Per registry instance | PostgreSQL, Secrets, Services, Routes |
| mlflow-operator | Per MLflow instance | PostgreSQL, S3 secrets, Deployments, HTTPRoutes |
| feast-operator | Per feature store | PostgreSQL/Redis, Services, Routes, ConfigMaps |
| odh-notebook-controller | Controller + user namespaces | Notebooks, HTTPRoutes, NetworkPolicies, ServiceAccounts |

### Secrets Inventory

**Auto-Rotated (OpenShift Service CA):**

| Secret Pattern | Type | Purpose | Components Using |
|----------------|------|---------|------------------|
| *-webhook-cert | kubernetes.io/tls | Webhook server TLS certificates | All operators with admission webhooks |
| *-proxy-tls | kubernetes.io/tls | kube-rbac-proxy TLS for metrics | Dashboard, Model Registry, TrustyAI |
| *-tls / *-serving-cert | kubernetes.io/tls | Service-to-service TLS | KServe, MLflow, Feast, Model Registry |

**User-Provisioned (Manual Rotation):**

| Secret Pattern | Type | Purpose | Components Using |
|----------------|------|---------|------------------|
| aws-credentials, s3-secret | Opaque | S3/AWS access keys | KServe, DSP, MLflow, Training, Notebooks |
| {db}-credentials | Opaque | Database passwords | Model Registry, MLflow, Feast, DSP |
| hf-token | Opaque | HuggingFace API tokens | Notebooks, Training, Llama Stack |
| registry-pull-secret | kubernetes.io/dockerconfigjson | Container registry auth | All components |
| {nim}-ngc-api-key | Opaque | NVIDIA NGC API keys | odh-model-controller (NIM) |

### Authentication Mechanisms

| Pattern | Components Using | Enforcement Point | Protocol |
|---------|------------------|-------------------|----------|
| OpenShift OAuth (Bearer Token) | Dashboard, Notebooks, MLflow, Model Registry | OpenShift OAuth Server + kube-rbac-proxy | HTTPS with JWT |
| Kubernetes RBAC (ServiceAccount Token) | All operators | Kubernetes API Server | HTTPS with SA JWT |
| mTLS Client Certificates | KServe (optional), Feast (optional) | Istio service mesh or application level | mTLS (mutual TLS) |
| Database Username/Password | Model Registry, MLflow, Feast, DSP | Database server | PostgreSQL/MySQL with optional TLS |
| S3 Access Keys / AWS IAM | KServe, DSP, MLflow, Training | S3 API | HTTPS with HMAC signatures |
| API Tokens (Custom) | HuggingFace, NGC, Git | External APIs | HTTPS with Bearer tokens |

### Authorization Policies

| Policy Type | Implementation | Components Using |
|-------------|---------------|------------------|
| Kubernetes RBAC | ClusterRoles, Roles, RoleBindings | All components |
| SubjectAccessReview | kube-rbac-proxy validation | Dashboard, Model Registry, MLflow |
| Istio AuthorizationPolicy | Service mesh policies | KServe (optional with Authorino) |
| NetworkPolicy | Pod-level ingress/egress rules | All components with network isolation |
| Kuadrant AuthPolicy | API-level authorization | odh-model-controller (KServe integration) |

## Platform APIs

### Custom Resource Definitions

**Platform Management:**

| API Group | Kind | Version | Scope | Component | Purpose |
|-----------|------|---------|-------|-----------|---------|
| datasciencecluster.opendatahub.io | DataScienceCluster | v1, v2 | Cluster | rhods-operator | Declare platform component enablement |
| dscinitialization.opendatahub.io | DSCInitialization | v1, v2 | Cluster | rhods-operator | Platform infrastructure initialization |
| components.platform.opendatahub.io | Dashboard, Workbenches, Kserve, etc. | v1alpha1 | Cluster | rhods-operator | Per-component configuration |

**Model Serving:**

| API Group | Kind | Version | Scope | Component | Purpose |
|-----------|------|---------|-------|-----------|---------|
| serving.kserve.io | InferenceService | v1beta1 | Namespaced | kserve | Deploy ML models with predictor/transformer/explainer |
| serving.kserve.io | ServingRuntime | v1alpha1 | Namespaced | kserve | Define model serving runtime templates |
| serving.kserve.io | ClusterServingRuntime | v1alpha1 | Cluster | kserve | Cluster-wide serving runtime templates |
| serving.kserve.io | InferenceGraph | v1alpha1 | Namespaced | kserve | Multi-model inference pipelines |
| serving.kserve.io | LLMInferenceService | v1 | Namespaced | kserve | Specialized LLM serving with disaggregation |

**Pipelines and Workflows:**

| API Group | Kind | Version | Scope | Component | Purpose |
|-----------|------|---------|-------|-----------|---------|
| datasciencepipelinesapplications.opendatahub.io | DataSciencePipelinesApplication | v1 | Namespaced | data-science-pipelines-operator | Deploy pipeline stack |
| pipelines.kubeflow.org | Pipeline, PipelineVersion | v2beta1 | Namespaced | data-science-pipelines | Define pipeline workflows |
| argoproj.io | Workflow | v1alpha1 | Namespaced | Argo (via DSP) | Execute pipeline tasks |

**Training:**

| API Group | Kind | Version | Scope | Component | Purpose |
|-----------|------|---------|-------|-----------|---------|
| trainer.kubeflow.org | TrainJob | v1alpha1 | Namespaced | trainer | LLM fine-tuning with progression tracking |
| trainer.kubeflow.org | TrainingRuntime, ClusterTrainingRuntime | v1alpha1 | Namespaced/Cluster | trainer | Training runtime templates |
| kubeflow.org | PyTorchJob, TFJob, XGBoostJob, MPIJob, JAXJob, PaddleJob | v1 | Namespaced | training-operator | Framework-specific distributed training |

**Data and Features:**

| API Group | Kind | Version | Scope | Component | Purpose |
|-----------|------|---------|-------|-----------|---------|
| feast.dev | FeatureStore | v1 | Namespaced | feast | Deploy feature store instances |
| modelregistry.opendatahub.io | ModelRegistry | v1beta1 | Namespaced | model-registry-operator | Deploy model metadata registry |
| mlflow.opendatahub.io | MLflow | v1 | Cluster | mlflow-operator | Deploy MLflow tracking servers |

**Workbenches:**

| API Group | Kind | Version | Scope | Component | Purpose |
|-----------|------|---------|-------|-----------|---------|
| kubeflow.org | Notebook | v1 | Namespaced | odh-notebook-controller | Jupyter/RStudio/VS Code workbenches |

**Distributed Computing:**

| API Group | Kind | Version | Scope | Component | Purpose |
|-----------|------|---------|-------|-----------|---------|
| ray.io | RayCluster, RayJob, RayService | v1 | Namespaced | kuberay-operator | Ray distributed computing |

**AI Explainability and Guardrails:**

| API Group | Kind | Version | Scope | Component | Purpose |
|-----------|------|---------|-------|-----------|---------|
| trustyai.opendatahub.io | TrustyAIService | v1 | Namespaced | trustyai-service-operator | Model explainability and monitoring |
| trustyai.opendatahub.io | GuardrailsOrchestrator, NemoGuardrails | v1alpha1 | Namespaced | trustyai-service-operator | LLM safety guardrails |
| trustyai.opendatahub.io | LMEvalJob | v1alpha1 | Namespaced | trustyai-service-operator | LLM evaluation jobs |

**LLM Infrastructure:**

| API Group | Kind | Version | Scope | Component | Purpose |
|-----------|------|---------|-------|-----------|---------|
| llamastack.io | LlamaStackDistribution | v1alpha1 | Namespaced | llama-stack-operator | Llama Stack server deployment |
| nim.opendatahub.io | Account | v1 | Namespaced | odh-model-controller | NVIDIA NIM account configuration |

### Public HTTP Endpoints

**User-Facing Services:**

| Path Pattern | Component | Port | Protocol | Auth | Purpose |
|--------------|-----------|------|----------|------|---------|
| / | odh-dashboard | 8443/TCP | HTTPS | OAuth | Main platform UI |
| /notebook/{namespace}/{name} | notebooks (via gateway) | 443/TCP | HTTPS | OAuth | Jupyter/RStudio/VS Code access |
| /mlflow/* | mlflow | 8443/TCP | HTTPS | Kubernetes-auth | Experiment tracking UI and API |
| /api/model_registry/v1alpha3/* | model-registry | 8443/TCP | HTTPS | kube-rbac-proxy | Model metadata CRUD |
| /v1/models/:name:predict | kserve InferenceServices | 8000/TCP | HTTP/HTTPS | Bearer/None | Model inference (KServe v1 protocol) |
| /v2/models/:name/infer | kserve InferenceServices | 8000/TCP | HTTP/HTTPS | Bearer/None | Model inference (KServe v2/Triton protocol) |
| /openai/v1/completions | kserve LLM runtimes | 8000/TCP | HTTP/HTTPS | Bearer | OpenAI-compatible LLM inference |
| /apis/v2beta1/* | data-science-pipelines | 8888/TCP | HTTP | Bearer | Kubeflow Pipelines v2 API |
| /get-online-features | feast online server | 6566/TCP | HTTP/HTTPS | Bearer/mTLS/None | Real-time feature retrieval |
| /get-historical-features | feast offline server | 8815/TCP | HTTP/HTTPS | Bearer/mTLS/None | Historical features for training |

**Operator Metrics (Internal):**

| Component | Endpoint | Port | Protocol | Scraping Method |
|-----------|----------|------|----------|----------------|
| All operators | /metrics | 8080/TCP or 8443/TCP | HTTP/HTTPS | ServiceMonitor or PodMonitor |

## Data Flows

### Key Platform Workflows

#### Workflow 1: Model Training to Deployment

| Step | Component | Action | Next Component | Protocol |
|------|-----------|--------|----------------|----------|
| 1 | User | Create Notebook via Dashboard | odh-dashboard | HTTPS (OAuth) |
| 2 | odh-dashboard | Create Notebook CR | odh-notebook-controller | Kubernetes API |
| 3 | odh-notebook-controller | Deploy StatefulSet + OAuth proxy | Kubernetes | Kubernetes API |
| 4 | User | Train model, log to MLflow | mlflow-operator deployment | HTTPS (K8s auth) |
| 5 | User | Register model metadata | model-registry-operator | HTTPS (kube-rbac-proxy) |
| 6 | User | Create InferenceService CR | kserve | Kubernetes API |
| 7 | kserve | Deploy predictor pods, create Route | odh-model-controller | Kubernetes API |
| 8 | External Client | Invoke model inference | InferenceService | HTTPS (TLS) |

#### Workflow 2: Distributed Training with Pipelines

| Step | Component | Action | Next Component | Protocol |
|------|-----------|--------|----------------|----------|
| 1 | User | Submit pipeline via Dashboard | data-science-pipelines-operator | HTTPS (Bearer) |
| 2 | DSP API Server | Create Argo Workflow | Argo Workflow Controller | Kubernetes API |
| 3 | Argo Workflow | Launch training job pod | training-operator or trainer | Kubernetes API |
| 4 | Training Job | Create PyTorchJob/TrainJob CR | training-operator/trainer | Kubernetes API |
| 5 | Training Operator | Deploy distributed worker pods | Kubernetes | Kubernetes API |
| 6 | Worker Pods | Train model, write to S3 | External S3 | HTTPS (AWS IAM) |
| 7 | Worker Pods | Log metrics to MLflow | mlflow-operator | HTTPS (K8s auth) |
| 8 | Pipeline Persistence Agent | Update pipeline status in DB | MariaDB | MySQL (optional TLS) |

#### Workflow 3: Feature Engineering to Model Serving

| Step | Component | Action | Next Component | Protocol |
|------|-----------|--------|----------------|----------|
| 1 | User | Create FeatureStore CR | feast-operator | Kubernetes API |
| 2 | feast-operator | Deploy online/offline servers | Kubernetes | Kubernetes API |
| 3 | User | Define features in notebook | feast registry server | gRPC/HTTP |
| 4 | User | Materialize features (CronJob) | feast online store | HTTP |
| 5 | Training Job | Fetch historical features | feast offline server | HTTP/HTTPS |
| 6 | InferenceService predictor | Fetch online features | feast online server | gRPC/HTTP |
| 7 | External Client | Invoke model with features | InferenceService | HTTPS |

#### Workflow 4: LLM Fine-Tuning and Guardrails

| Step | Component | Action | Next Component | Protocol |
|------|-----------|--------|----------------|----------|
| 1 | User | Create TrainJob with LLM model | trainer | Kubernetes API |
| 2 | trainer | Download model from HuggingFace | HuggingFace Hub | HTTPS (token) |
| 3 | trainer | Deploy JobSet for distributed training | JobSet Controller | Kubernetes API |
| 4 | Training Pods | Fine-tune LLM, poll metrics | trainer (progression tracking) | HTTP (28080) |
| 5 | User | Deploy fine-tuned LLM to KServe | kserve | Kubernetes API |
| 6 | User | Configure GuardrailsOrchestrator | trustyai-service-operator | Kubernetes API |
| 7 | trustyai-service-operator | Patch InferenceService with guardrails | kserve | Kubernetes API |
| 8 | External Client | Invoke LLM with guardrails | Guardrails Orchestrator → InferenceService | HTTPS |

#### Workflow 5: Model Monitoring and Explainability

| Step | Component | Action | Next Component | Protocol |
|------|-----------|--------|----------------|----------|
| 1 | User | Create TrustyAIService CR | trustyai-service-operator | Kubernetes API |
| 2 | trustyai-service-operator | Deploy TrustyAI deployment | Kubernetes | Kubernetes API |
| 3 | trustyai-service-operator | Patch InferenceService with payload logger | kserve | Kubernetes API |
| 4 | External Client | Invoke model inference | InferenceService | HTTPS |
| 5 | InferenceService | Log payload to TrustyAI | TrustyAI Service | HTTP/HTTPS (Istio) |
| 6 | TrustyAI Service | Persist inference data | PostgreSQL or PVC | PostgreSQL/Filesystem |
| 7 | Prometheus | Scrape fairness/drift metrics | TrustyAI Service | HTTP |
| 8 | User | View metrics in Dashboard/Grafana | odh-dashboard or Grafana | HTTPS |

## Deployment Architecture

### Deployment Topology

**Three-Tier Architecture:**

1. **Control Plane Tier** (redhat-ods-operator namespace):
   - rhods-operator (3 replicas, leader election)
   - Admission webhooks for DSC/DSCI
   - Cluster-wide CRD management

2. **Application Tier** (redhat-ods-applications namespace):
   - odh-dashboard (2 replicas, user-facing UI)
   - Component operators (1 replica each): odh-model-controller, odh-notebook-controller, data-science-pipelines-operator, model-registry-operator, mlflow-operator, feast-operator, training-operator, trainer, kuberay-operator, trustyai-service-operator, llama-stack-operator
   - OAuth proxies for authentication
   - Gateway API HTTPRoutes

3. **Workload Tier** (User namespaces):
   - Notebooks (StatefulSets with PVCs)
   - InferenceServices (Deployments or Knative Services)
   - Training Jobs (Jobs or JobSets)
   - Pipeline runs (Argo Workflows)
   - Feature stores, model registries, MLflow instances

### Resource Requirements

**Operator Control Plane:**

| Component | CPU Request | CPU Limit | Memory Request | Memory Limit | Replicas |
|-----------|-------------|-----------|----------------|--------------|----------|
| rhods-operator | 100m | 1000m | 780Mi | 4Gi | 3 |
| odh-dashboard (manager) | 500m | 1000m | 1Gi | 2Gi | 2 |
| odh-dashboard (kube-rbac-proxy) | 500m | 1000m | 1Gi | 2Gi | 2 |
| odh-model-controller | 10m | 500m | 64Mi | 2Gi | 1 |
| odh-notebook-controller | 500m | 500m | 256Mi | 4Gi | 1 |

**Component Operators (Typical):**

| Component | CPU Request | CPU Limit | Memory Request | Memory Limit | Replicas |
|-----------|-------------|-----------|----------------|--------------|----------|
| data-science-pipelines-operator | TBD | TBD | TBD | TBD | 1 |
| model-registry-operator | 200m | 1000m | 400Mi | 4Gi | 1 |
| mlflow-operator | 200m | 1000m | 400Mi | 4Gi | 1 |
| feast-operator | 10m | 1000m | 64Mi | 256Mi | 1 |
| training-operator | TBD | TBD | TBD | TBD | 1 |
| trainer | TBD | TBD | TBD | TBD | 1 |
| kuberay-operator | 100m | 100m | 512Mi | 512Mi | 1 |
| trustyai-service-operator | TBD | TBD | TBD | TBD | 1 |
| llama-stack-operator | 10m | 500m | 256Mi | 1Gi | 1 |

**User Workload Defaults:**

| Workload Type | CPU Request | Memory Request | Storage | Notes |
|---------------|-------------|----------------|---------|-------|
| Notebook (minimal) | 100m | 128Mi | 10Gi PVC | User-configurable |
| Notebook (GPU) | 1000m | 8Gi | 20Gi PVC | Requires GPU node |
| InferenceService (CPU) | 100m | 128Mi | None | Autoscales with Knative |
| InferenceService (GPU) | 1000m | 2Gi | None | GPU required |
| Training Job (distributed) | Varies | Varies | Shared PVC or S3 | Multi-node configuration |

## Version-Specific Changes (3.3.0)

**Major Updates:**

| Component | Changes |
|-----------|---------|
| rhods-operator | - Go 1.25 upgrade<br>- Active component version bumping (model registry, training operator, notebook controllers, Ray)<br>- Konflux pipeline integration |
| kserve | - Multi-architecture support improvements (ppc64le, s390x)<br>- LLM inference improvements (scheduler, disaggregated architecture)<br>- InferencePool API v1 migration<br>- vLLM runtime configuration updates |
| data-science-pipelines-operator | - KFP v2 API focus<br>- Argo Workflows integration (replaced Tekton)<br>- FIPS compliance builds |
| notebooks | - Migration to Konflux CI/CD<br>- Python 3.12 runtime<br>- Multi-architecture support (x86_64, aarch64, ppc64le, s390x)<br>- PyTorch 2.9, CUDA 12.8, ROCm 6.3 updates |
| odh-dashboard | - React 18 upgrade<br>- PatternFly 6 adoption<br>- Module federation for micro-frontends (Model Registry UI, GenAI UI, MaaS UI)<br>- Node.js 22 runtime |
| model-registry-operator | - NetworkPolicy for PostgreSQL access control<br>- Go 1.25.7 upgrade<br>- v1beta1 API stabilization |
| training-operator | - CVE-2026-2353: Restricted secrets RBAC to namespace scope<br>- Go 1.25 upgrade |
| trainer | - Progression tracking with metrics polling<br>- NetworkPolicy isolation<br>- CUDA 12.8 and ROCm 6.4 runtime support |
| feast-operator | - Pyarrow v22 build fixes<br>- dbt integration for feature views<br>- Lambda materialization engine improvements |
| kuberay-operator | - v1.4.4 update<br>- Authentication ready condition handling fixes |
| trustyai-service-operator | - urllib3 security vulnerability fix (2.6.3)<br>- GuardrailsOrchestrator status logic updates |
| llama-stack-operator | - NetworkPolicy enabled by default in RHOAI 3.3<br>- Llama Stack v0.4.2, Operator v0.6.0 |
| mlflow-operator | - Tracing APIs support<br>- Go 1.24.6 upgrade |

## Platform Maturity

**Statistics:**

- **Total Components**: 15 (1 central operator + 14 specialized components)
- **Operator-based Components**: 14 (93% of components are Kubernetes operators)
- **Service Mesh Coverage**: Optional (KServe, Data Science Pipelines, TrustyAI support Istio)
- **mTLS Enforcement**: PERMISSIVE (can be configured to STRICT per namespace)
- **Gateway API Adoption**: High (Notebooks, MLflow, Model Registry use HTTPRoute)
- **CRD API Versions**: Mixed (v1, v1alpha1, v1beta1, v2)
  - Stable v1: PyTorchJob, TFJob, RayCluster, DataScienceCluster, ModelRegistry (v1beta1)
  - Alpha: TrainJob, LMEvalJob, GuardrailsOrchestrator, InferenceGraph, LLMInferenceService

**Maturity Assessment:**

- **Production-Ready**: Core components (KServe, Notebooks, Data Science Pipelines, Model Registry, Training Operator)
- **Technology Preview**: LLM-specific features (Trainer, Llama Stack, NIM integration, Guardrails)
- **Emerging**: Model-as-a-Service (MaaS) API, GenAI micro-frontend

**Enterprise Features:**

- ✅ Multi-tenancy with namespace isolation
- ✅ Role-based access control (RBAC) integration
- ✅ OpenShift OAuth authentication
- ✅ Auto-rotating TLS certificates (OpenShift Service CA)
- ✅ Operator Lifecycle Manager (OLM) packaging
- ✅ Konflux CI/CD with image signing and scanning
- ✅ FIPS compliance builds
- ✅ Multi-architecture support (x86_64, aarch64, ppc64le, s390x)
- ✅ Air-gapped installation support (prefetched manifests)
- ✅ Enterprise support lifecycle (Red Hat subscription)

## Next Steps for Documentation

**Recommended Actions:**

1. **Generate Architecture Diagrams:**
   - Component dependency graph (Graphviz/Mermaid)
   - Network topology diagram showing ingress/egress flows
   - Security architecture diagram for SAR (Security Architecture Review)
   - Data flow diagrams for key workflows

2. **Update ADRs (Architecture Decision Records):**
   - Why Gateway API was chosen over OpenShift Routes alone
   - Rationale for operator-per-component vs monolithic operator
   - Database strategy (embedded vs external, PVC vs cloud storage)
   - Service mesh optional vs required decision

3. **Create User-Facing Documentation:**
   - Getting started guide (deploy first model end-to-end)
   - Component integration matrix (which components work together)
   - Troubleshooting runbook (common failure modes and resolutions)
   - Sizing and capacity planning guide

4. **Generate Security Documentation:**
   - Network security diagram with zones and trust boundaries
   - Threat model for each component
   - Compliance documentation (PCI-DSS, HIPAA, FedRAMP considerations)
   - Secrets management best practices guide

5. **Operational Playbooks:**
   - Day 2 operations guide (backup/restore, disaster recovery)
   - Upgrade procedures and rollback strategies
   - Performance tuning guide (API rate limits, autoscaling thresholds)
   - Multi-cluster federation patterns (future consideration)

6. **Developer Documentation:**
   - Custom serving runtime creation guide
   - Pipeline component development guide
   - Operator extension patterns for custom integrations
   - Testing strategy for platform upgrades
