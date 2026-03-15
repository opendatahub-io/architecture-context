# Platform: Red Hat OpenShift AI 3.2

## Metadata
- **Distribution**: RHOAI
- **Version**: 3.2
- **Release Date**: 2026-03-15
- **Base Platform**: OpenShift Container Platform 4.14+
- **Components Analyzed**: 15

## Platform Overview

Red Hat OpenShift AI (RHOAI) 3.2 is an enterprise-grade AI/ML platform built on OpenShift that provides end-to-end capabilities for the complete machine learning lifecycle. The platform enables data scientists and ML engineers to develop, train, deploy, monitor, and manage AI/ML models at scale with integrated tools for experiment tracking, model serving, distributed training, feature engineering, and AI trustworthiness.

RHOAI 3.2 is architected as a collection of specialized operators and services that work together to provide a unified experience. At its core, the RHODS Operator manages platform initialization and component lifecycle through declarative APIs (DataScienceCluster and DSCInitialization CRDs). The platform integrates deeply with OpenShift's service mesh (Istio), serverless (Knative), monitoring (Prometheus), and security infrastructure (OAuth, RBAC, mTLS) to provide production-grade AI/ML workloads.

Key capabilities include: interactive Jupyter/RStudio/VSCode workbenches for development, KServe-based model serving with autoscaling, Kubeflow Pipelines for ML workflow orchestration, distributed training across PyTorch/TensorFlow/JAX frameworks, model registry for versioning and metadata, MLflow for experiment tracking, Feast for feature stores, Ray for distributed computing, and TrustyAI for model explainability and fairness monitoring. The platform supports both CPU and GPU workloads (NVIDIA CUDA, AMD ROCm) with multi-architecture support (x86_64, arm64, ppc64le, s390x).

## Component Inventory

| Component | Type | Version | Purpose |
|-----------|------|---------|---------|
| RHODS Operator | Platform Operator | v1.6.0-5936-g181aacbe8 | Manages platform initialization, component lifecycle, and shared services |
| ODH Dashboard | Web Application | v1.21.0-18-rhods-4956-gb8dfd1a2d | Primary web console for platform management and user workflows |
| KServe | Model Serving Operator | 27c1e99b7 | Serverless and raw deployment model serving with autoscaling |
| ODH Model Controller | Controller | v1.27.0-rhods-1125-gd4a76a6 | Extends KServe with OpenShift Routes, monitoring, and NIM integration |
| Data Science Pipelines Operator | Pipeline Operator | rhoai-3.2 (9d94973) | Manages Kubeflow Pipelines v2 with Argo Workflows backend |
| Notebook Controller | Workbench Operator | 1.27.0-rhods-1401-gfa6368ce | Manages Jupyter notebook instances and lifecycle |
| Notebooks | Container Images | v3.2.0 | Pre-built workbench and runtime images (Jupyter, RStudio, CodeServer) |
| Model Registry Operator | Registry Operator | b068597 | Manages model metadata, versioning, and registry services |
| MLflow Operator | Experiment Tracking | cd9ad05 | Manages MLflow instances for experiment tracking and model registry |
| Training Operator | Distributed Training | 1.9.0 (2d07807b) | Runs distributed training jobs (PyTorch, TensorFlow, XGBoost, MPI, JAX) |
| Trainer | LLM Training | 2.1.0 (46393c34) | Kubernetes-native distributed training for LLMs and ML workloads |
| KubeRay Operator | Distributed Computing | 72c07895 | Manages Ray clusters for distributed computing and ML workloads |
| Feast Operator | Feature Store | 0.58.0 (4436b3c0e) | Manages Feast feature store instances for ML feature engineering |
| Llama Stack Operator | GenAI Operator | v0.5.0 (54ab19b) | Manages Llama Stack server deployments for LLM serving |
| TrustyAI Service Operator | AI Governance | a2e891d | Provides model explainability, fairness monitoring, and LLM guardrails |

## Component Relationships

### Dependency Graph

```
RHODS Operator (root)
├── ODH Dashboard → KServe (API calls)
│                → Model Registry (API calls)
│                → MLflow (API calls)
│                → Data Science Pipelines (API calls)
│                → Notebook Controller (CRD creation)
│                → Training Operator (CRD creation)
│                → Prometheus/Thanos (metrics queries)
│
├── KServe → Istio (traffic management)
│          → Knative Serving (serverless autoscaling)
│          → ODH Model Controller (Routes, monitoring)
│          → Model Registry (model metadata)
│          → TrustyAI (inference monitoring)
│
├── ODH Model Controller → KServe (InferenceService management)
│                        → Kuadrant/Authorino (AuthPolicies)
│                        → Istio (EnvoyFilters)
│                        → NVIDIA NGC API (NIM integration)
│
├── Data Science Pipelines → KServe (model deployment)
│                          → Model Registry (model storage)
│                          → S3 Storage (artifacts)
│                          → MariaDB (metadata)
│                          → Argo Workflows (execution)
│
├── Notebook Controller → Istio (VirtualServices - optional)
│
├── TrustyAI → KServe InferenceServices (monitoring)
│           → PostgreSQL/MySQL (data storage)
│           → Kueue (LMEval job queuing)
│
├── Training Operator → JobSet (distributed job management)
│                    → Volcano/Kueue (gang scheduling)
│
├── Trainer → JobSet (distributed job management)
│           → Volcano (gang scheduling)
│
├── KubeRay → cert-manager (mTLS certificates)
│           → OpenShift OAuth (dashboard auth)
│           → Gateway API/Routes (ingress)
│
├── Feast Operator → Kubeflow Notebooks (config injection)
│                 → OpenShift Routes (external access)
│
├── MLflow Operator → Gateway API (HTTPRoute)
│                  → OpenShift Console (ConsoleLink)
│                  → PostgreSQL (metadata storage)
│                  → S3 Storage (artifact storage)
│
└── Model Registry Operator → PostgreSQL/MySQL (metadata storage)
                            → Authorino (Istio auth - optional)
                            → OpenShift Routes (external access)
```

### Central Components

**Platform Control Plane:**
1. **RHODS Operator** - Core platform operator managing all component lifecycles (15 components depend on it)
2. **Kubernetes API Server** - All components interact with K8s API for resource management
3. **OpenShift OAuth** - Central authentication service for dashboard and services (8 components)

**Data Plane:**
1. **KServe** - Central model serving platform (6 components integrate with it)
2. **Istio Service Mesh** - Service-to-service communication and mTLS (7 components)
3. **ODH Dashboard** - Primary user interface (integrates with 10+ components)

**Storage Layer:**
1. **S3-compatible Object Storage** - Artifact storage (7 components use it)
2. **PostgreSQL/MySQL** - Metadata persistence (5 components use it)

### Integration Patterns

**CRD-based Integration:**
- Components extend functionality by watching and creating CRDs (KServe InferenceService, Notebook, PyTorchJob, etc.)
- Webhooks validate and mutate resources before admission
- Finalizers ensure proper cleanup on deletion

**API-based Integration:**
- Dashboard proxies requests to component REST APIs
- Model Registry provides HTTP API for model metadata
- Prometheus/Thanos for metrics aggregation

**Service Mesh Integration:**
- Istio provides mTLS, traffic routing, and observability
- AuthorizationPolicies enforce access control
- VirtualServices and DestinationRules configure routing

**Event-driven Integration:**
- Operators watch CRD changes and reconcile state
- Prometheus AlertManager for event-based actions
- Kubernetes Events for lifecycle notifications

## Platform Network Architecture

### Namespaces

| Namespace | Purpose | Components |
|-----------|---------|------------|
| redhat-ods-operator | Operator control plane | RHODS Operator, webhooks, leader election |
| redhat-ods-applications | Application services | ODH Dashboard, Model Registry, MLflow, Feast, TrustyAI |
| redhat-ods-monitoring | Observability | Prometheus, Alertmanager, Blackbox Exporter, ServiceMonitors |
| opendatahub | Kubeflow components | Notebook Controller, Training Operator, Trainer, KubeRay |
| istio-system | Service mesh | Istio control plane, ingress gateways |
| knative-serving | Serverless | Knative Serving controllers and activators |
| User namespaces | User workloads | Notebooks, InferenceServices, TrainingJobs, Ray clusters, pipelines |

### External Ingress Points

| Component | Ingress Type | Hosts | Port | Protocol | Encryption | Purpose |
|-----------|--------------|-------|------|----------|------------|---------|
| ODH Dashboard | OpenShift Route / HTTPRoute | dashboard-{namespace}.apps.{cluster} | 443/TCP | HTTPS | TLS 1.2+ | Web console access |
| KServe InferenceService | OpenShift Route / Istio Gateway | {model}-{namespace}.apps.{cluster} | 443/TCP | HTTPS | TLS 1.2+ | Model inference endpoints |
| Jupyter Notebooks | OpenShift Route | {notebook}-{namespace}.apps.{cluster} | 443/TCP | HTTPS | TLS 1.2+ | Notebook web interface |
| Data Science Pipelines | OpenShift Route | ds-pipeline-{name}-{namespace}.apps.{cluster} | 443/TCP | HTTPS | TLS 1.3 | Pipeline API and UI |
| MLflow | HTTPRoute (Gateway API) | {gateway-host}/mlflow | 443/TCP | HTTPS | TLS 1.3 | Experiment tracking UI |
| Model Registry | OpenShift Route | {registry}-{namespace}.apps.{cluster} | 443/TCP | HTTPS | TLS 1.2+ | Model registry API |
| Ray Dashboard | OpenShift Route | {cluster}-{namespace}.apps.{cluster} | 443/TCP | HTTPS | TLS 1.2+ | Ray cluster dashboard |
| Prometheus | OpenShift Route | prometheus-{namespace}.apps.{cluster} | 443/TCP | HTTPS | TLS 1.2+ | Metrics UI |
| Alertmanager | OpenShift Route | alertmanager-{namespace}.apps.{cluster} | 443/TCP | HTTPS | TLS 1.2+ | Alert management UI |
| Feast Services | OpenShift Route | feast-{name}-{service}-{namespace}.apps.{cluster} | 443/TCP | HTTPS | TLS 1.2+ | Feature store services |
| TrustyAI Service | OpenShift Route | trustyai-service-{name}-{namespace}.apps.{cluster} | 443/TCP | HTTPS | TLS 1.2+ | Model monitoring API |
| Guardrails Orchestrator | OpenShift Route | guardrails-orchestrator-{name}-{namespace}.apps.{cluster} | 443/TCP | HTTPS | TLS 1.2+ | LLM guardrails API |

### External Egress Dependencies

| Component | Destination | Port | Protocol | Encryption | Purpose |
|-----------|-------------|------|----------|------------|---------|
| Multiple | S3-compatible Storage (AWS S3, OCS, Minio) | 443/TCP | HTTPS | TLS 1.2+ | Model artifacts, pipeline artifacts, training data |
| Multiple | PostgreSQL Database | 5432/TCP | PostgreSQL | TLS 1.2+ (optional) | Metadata storage (pipelines, model registry, MLflow, TrustyAI) |
| Multiple | MariaDB/MySQL Database | 3306/TCP | MySQL | TLS 1.2+ (optional) | Alternative metadata storage |
| Notebooks, Pipelines, Training | Container Registries (quay.io, registry.redhat.io) | 443/TCP | HTTPS | TLS 1.2+ | Image pulls for workloads |
| Notebooks, Workbenches | PyPI, npm, CRAN | 443/TCP | HTTPS | TLS 1.2+ | Package installation |
| Notebooks, Workbenches | Git Repositories (GitHub, GitLab) | 443/TCP | HTTPS | TLS 1.2+ | Source code access |
| Notebooks, Training | HuggingFace Hub | 443/TCP | HTTPS | TLS 1.2+ | Model and dataset downloads |
| ODH Model Controller | NVIDIA NGC API | 443/TCP | HTTPS | TLS 1.2+ | NIM account validation and model lists |
| KubeRay, Feast | External Redis (optional) | 6379/TCP | Redis | TLS 1.2+ (optional) | GCS fault tolerance |
| Feast | Snowflake (optional) | 443/TCP | HTTPS | TLS 1.2+ | Cloud data warehouse integration |
| Data Science Pipelines | External Services | 443/TCP | HTTPS | TLS 1.2+ | Custom pipeline integrations |

### Internal Service Mesh

| Setting | Value | Components Using |
|---------|-------|------------------|
| mTLS Mode | STRICT (model serving), PERMISSIVE (general) | KServe, Model Registry, TrustyAI |
| Peer Authentication | STRICT for InferenceServices | KServe predictor pods |
| Istio Gateway | kubeflow/kubeflow-gateway | KServe, Notebooks (optional) |
| Istio Injection | Enabled in model serving namespaces | User namespaces with label `istio-injection=enabled` |
| EnvoyFilter | LLM routing, request transformation | ODH Model Controller (LLMInferenceService) |
| AuthorizationPolicy | JWT validation, token-based auth | KServe, Model Registry (with Authorino) |

## Platform Security

### RBAC Summary

**Critical Cluster Roles:**

| Component | ClusterRole | Key Permissions |
|-----------|-------------|----------------|
| RHODS Operator | opendatahub-operator-manager-role | All CRDs, deployments, services, secrets, RBAC resources, OLM operators |
| KServe | kserve-manager-role | InferenceServices, ServingRuntimes, Knative Services, Istio resources |
| ODH Model Controller | odh-model-controller-role | InferenceServices, Routes, NetworkPolicies, AuthPolicies, NIM Accounts |
| Data Science Pipelines | manager-role | DataSciencePipelinesApplications, Argo Workflows, KServe, Ray |
| Notebook Controller | role | Notebooks, StatefulSets, Services, Istio VirtualServices |
| Training Operator | training-operator | PyTorchJobs, TFJobs, XGBoostJobs, MPIJobs, PaddleJobs, JAXJobs, JobSets |
| Trainer | kubeflow-trainer-controller-manager | TrainJobs, TrainingRuntimes, JobSets, PodGroups |
| KubeRay | kuberay-operator | RayClusters, RayJobs, RayServices, NetworkPolicies, Routes, Certificates |
| TrustyAI | manager-role | TrustyAIServices, LMEvalJobs, GuardrailsOrchestrators, InferenceServices |
| ODH Dashboard | odh-dashboard | Extensive read/write across all component CRDs, monitoring, and OpenShift resources |

**User-facing Roles:**

| Role | Scope | Purpose |
|------|-------|---------|
| training-edit | Cluster | Create/edit training jobs (PyTorchJob, TFJob, etc.) |
| training-view | Cluster | View training jobs and status |
| mlflow-edit | Cluster | Create/edit MLflow instances |
| mlflow-view | Cluster | View MLflow instances |
| featurestore-editor-role | Cluster | Create/edit FeatureStore instances |
| featurestore-viewer-role | Cluster | View FeatureStore instances |

### Secrets Inventory

| Component | Secret Name | Type | Purpose |
|-----------|-------------|------|---------|
| RHODS Operator | opendatahub-operator-controller-webhook-cert | kubernetes.io/tls | Webhook server TLS |
| ODH Dashboard | dashboard-proxy-tls | kubernetes.io/tls | OAuth proxy TLS certificate |
| KServe | kserve-webhook-server-cert | kubernetes.io/tls | Webhook server TLS |
| Data Science Pipelines | ds-pipelines-proxy-tls-{name} | kubernetes.io/tls | API server proxy TLS |
| Data Science Pipelines | mariadb-{name} | Opaque | Database credentials |
| Data Science Pipelines | minio-{name} | Opaque | Object storage credentials |
| Notebooks | {notebook}-oauth-config | Opaque | OAuth proxy configuration |
| Notebooks | {notebook}-tls | kubernetes.io/tls | Notebook HTTPS certificate |
| Model Registry | {registry-name}-oauth-proxy | kubernetes.io/tls | OAuth proxy TLS |
| Model Registry | {registry-name}-db | Opaque | Database credentials |
| MLflow | mlflow-tls | kubernetes.io/tls | Service TLS certificate |
| MLflow | mlflow-db-credentials | Opaque | Database connection strings |
| KubeRay | {raycluster}-proxy-tls-secret | kubernetes.io/tls | OAuth proxy TLS |
| KubeRay | {raycluster}-ca-secret | Opaque | mTLS CA certificate |
| Feast | {name}-tls | kubernetes.io/tls | Feature service TLS |
| Feast | {name}-oidc | Opaque | OIDC client credentials |
| TrustyAI | {trustyai-service}-tls | kubernetes.io/tls | Service endpoint TLS |
| TrustyAI | {trustyai-service}-db-credentials | Opaque | Database connection credentials |
| Training Operator | training-operator-webhook-cert | kubernetes.io/tls | Webhook server TLS |
| Trainer | kubeflow-trainer-webhook-cert | kubernetes.io/tls | Webhook server TLS |

### Authentication Mechanisms

| Pattern | Components Using | Enforcement Point |
|---------|------------------|-------------------|
| Bearer Tokens (JWT) - OpenShift OAuth | ODH Dashboard, Notebooks, Ray Dashboard, Routes | kube-rbac-proxy, OAuth proxy |
| Bearer Tokens (ServiceAccount) | All operators, internal service calls | Kubernetes API Server |
| mTLS Client Certificates | KServe (service mesh), Ray GCS, Data Science Pipelines MLMD | Istio sidecar, Ray GCS, Envoy proxy |
| AWS IAM Credentials / S3 SigV4 | Data Science Pipelines, Notebooks, Training jobs, MLflow | S3-compatible storage |
| Kubernetes RBAC (self_subject_access_review) | MLflow, Feast, Model Registry (optional) | Application-level RBAC |
| OIDC (OAuth 2.0/OpenID Connect) | Feast (optional), external IdP integration | Feature server, external OAuth providers |
| Kuadrant AuthPolicy | KServe InferenceServices (optional), LLMInferenceServices | Authorino enforcement |
| API Keys | NVIDIA NGC (NIM), HuggingFace Hub, external APIs | Application-level validation |

## Platform APIs

### Custom Resource Definitions

**Platform Control Plane:**

| Component | API Group | Kind | Purpose |
|-----------|-----------|------|---------|
| RHODS Operator | datasciencecluster.opendatahub.io/v1,v2 | DataScienceCluster | Platform component configuration |
| RHODS Operator | dscinitialization.opendatahub.io/v1,v2 | DSCInitialization | Platform initialization and shared services |
| RHODS Operator | components.opendatahub.io/v1alpha1 | Dashboard, Kserve, Workbenches, etc. | Individual component configurations |
| RHODS Operator | services.opendatahub.io/v1alpha1 | Auth, Monitoring, Gateway | Platform service configurations |
| RHODS Operator | infrastructure.opendatahub.io/v1 | HardwareProfile | Hardware profiles for workloads |

**Workbenches & Development:**

| Component | API Group | Kind | Purpose |
|-----------|-----------|------|---------|
| Notebook Controller | kubeflow.org/v1 | Notebook | Jupyter notebook instance definition |
| ODH Dashboard | dashboard.opendatahub.io/v1 | OdhApplication, OdhDocument | Application catalog and documentation |
| ODH Dashboard | opendatahub.io/v1alpha | OdhDashboardConfig | Dashboard feature flags and configuration |
| ODH Dashboard | console.openshift.io/v1 | OdhQuickStart | Interactive tutorials |

**Model Serving:**

| Component | API Group | Kind | Purpose |
|-----------|-----------|------|---------|
| KServe | serving.kserve.io/v1beta1 | InferenceService | ML model serving deployment |
| KServe | serving.kserve.io/v1alpha1 | ServingRuntime, ClusterServingRuntime | Model server runtime templates |
| KServe | serving.kserve.io/v1alpha1 | InferenceGraph | Multi-step inference pipelines |
| KServe | serving.kserve.io/v1alpha1 | TrainedModel | Individual trained models for multi-model serving |
| ODH Model Controller | nim.opendatahub.io/v1 | Account | NVIDIA NIM account integration |

**ML Pipelines:**

| Component | API Group | Kind | Purpose |
|-----------|-----------|------|---------|
| Data Science Pipelines | datasciencepipelinesapplications.opendatahub.io/v1 | DataSciencePipelinesApplication | DSP stack deployment |
| Data Science Pipelines | argoproj.io/v1alpha1 | Workflow, WorkflowTemplate, CronWorkflow | Argo Workflow execution |
| Data Science Pipelines | pipelines.kubeflow.org/v1 | Pipeline, PipelineVersion | Pipeline definitions |

**Distributed Training:**

| Component | API Group | Kind | Purpose |
|-----------|-----------|------|---------|
| Training Operator | kubeflow.org/v1 | PyTorchJob, TFJob, XGBoostJob, MPIJob, PaddleJob, JAXJob | Framework-specific distributed training |
| Trainer | trainer.kubeflow.org/v1alpha1 | TrainJob, TrainingRuntime, ClusterTrainingRuntime | Unified training API |

**Distributed Computing:**

| Component | API Group | Kind | Purpose |
|-----------|-----------|------|---------|
| KubeRay | ray.io/v1 | RayCluster, RayJob, RayService | Ray distributed computing |

**ML Operations:**

| Component | API Group | Kind | Purpose |
|-----------|-----------|------|---------|
| Model Registry | modelregistry.opendatahub.io/v1beta1 | ModelRegistry | Model metadata and versioning service |
| MLflow | mlflow.opendatahub.io/v1 | MLflow | Experiment tracking and model registry |
| Feast | feast.dev/v1 | FeatureStore | Feature store for ML feature management |

**AI Governance:**

| Component | API Group | Kind | Purpose |
|-----------|-----------|------|---------|
| TrustyAI | trustyai.opendatahub.io/v1 | TrustyAIService | Model explainability and fairness monitoring |
| TrustyAI | trustyai.opendatahub.io/v1alpha1 | LMEvalJob | LLM evaluation jobs |
| TrustyAI | trustyai.opendatahub.io/v1alpha1 | GuardrailsOrchestrator | LLM guardrails orchestration |
| TrustyAI | trustyai.opendatahub.io/v1alpha1 | NemoGuardrails | NVIDIA NeMo guardrails |

**GenAI:**

| Component | API Group | Kind | Purpose |
|-----------|-----------|------|---------|
| Llama Stack | llamastack.io/v1alpha1 | LlamaStackDistribution | Llama Stack server deployment |

### Public HTTP Endpoints

**Platform UI:**

| Path | Component | Port | Protocol | Auth | Purpose |
|------|-----------|------|----------|------|---------|
| / | ODH Dashboard | 8443/TCP | HTTPS | OAuth Bearer Token | Main platform web console |
| /api/* | ODH Dashboard | 8443/TCP | HTTPS | OAuth Bearer Token | Dashboard REST API |

**Model Serving:**

| Path | Component | Port | Protocol | Auth | Purpose |
|------|-----------|------|----------|------|---------|
| /v1/models/{model}:predict | KServe InferenceService | 443/TCP | HTTPS | Bearer Token / AuthPolicy | V1 prediction protocol |
| /v2/models/{model}/infer | KServe InferenceService | 443/TCP | HTTPS | Bearer Token / AuthPolicy | V2 inference protocol |

**ML Pipelines:**

| Path | Component | Port | Protocol | Auth | Purpose |
|------|-----------|------|----------|------|---------|
| /apis/v1beta1/* | Data Science Pipelines | 8443/TCP | HTTPS | Bearer Token | KFP API v1beta1 (pipelines, runs, experiments) |
| /apis/v2beta1/* | Data Science Pipelines | 8443/TCP | HTTPS | Bearer Token | KFP API v2beta1 (pipeline versions, artifacts) |

**Model Registry:**

| Path | Component | Port | Protocol | Auth | Purpose |
|------|-----------|------|----------|------|---------|
| /api/model_registry/v1alpha3/* | Model Registry | 8443/TCP | HTTPS | OAuth/RBAC | Model Registry REST API |

**Experiment Tracking:**

| Path | Component | Port | Protocol | Auth | Purpose |
|------|-----------|------|----------|------|---------|
| /api/* | MLflow | 8443/TCP | HTTPS | Bearer Token (k8s-auth) | MLflow REST API |

**Feature Store:**

| Path | Component | Port | Protocol | Auth | Purpose |
|------|-----------|------|----------|------|---------|
| /registry/* | Feast Registry | 6570/6571/TCP | HTTP/HTTPS | Configurable | Feature registry gRPC/REST API |
| /online/* | Feast Online Store | 6566/6567/TCP | HTTP/HTTPS | Configurable | Real-time feature retrieval |
| /offline/* | Feast Offline Store | 8815/8816/TCP | HTTP/HTTPS | Configurable | Historical feature processing |

**AI Governance:**

| Path | Component | Port | Protocol | Auth | Purpose |
|------|-----------|------|----------|------|---------|
| /api/v1/* | TrustyAI Service | 8443/TCP | HTTPS | Bearer Token | Model explainability and fairness API |
| /q/* | Guardrails Orchestrator | 8432/TCP | HTTPS | Bearer Token | LLM guardrails API |

## Data Flows

### Key Platform Workflows

#### Workflow 1: Model Training to Deployment

| Step | Component | Action | Next Component |
|------|-----------|--------|----------------|
| 1 | Notebook / Dashboard | User develops model code in Jupyter notebook | - |
| 2 | Notebook | User trains model or submits distributed training job | Training Operator / Trainer |
| 3 | Training Operator | Executes distributed training (PyTorchJob, TFJob) | S3 Storage (model checkpoint) |
| 4 | User / Dashboard | Registers trained model in Model Registry | Model Registry |
| 5 | User / Dashboard | Creates InferenceService CR with model URI | KServe |
| 6 | KServe | Deploys model with autoscaling configuration | Istio (traffic routing) |
| 7 | ODH Model Controller | Creates Route, NetworkPolicy, ServiceMonitor | OpenShift Router |
| 8 | Client Application | Calls inference endpoint via Route | InferenceService (prediction) |
| 9 | TrustyAI Service | Monitors inference requests/responses | PostgreSQL (monitoring data) |

#### Workflow 2: Pipeline-Based Model Lifecycle

| Step | Component | Action | Next Component |
|------|-----------|--------|----------------|
| 1 | User / Dashboard | Creates DataSciencePipelinesApplication CR | Data Science Pipelines Operator |
| 2 | DSPO | Deploys DSP stack (API, DB, storage, MLMD, Argo) | MariaDB, Minio/S3 |
| 3 | User / ODH Dashboard | Submits pipeline via DSP API | ds-pipeline API Server |
| 4 | DSP API Server | Creates Argo Workflow CR | Argo Workflow Controller |
| 5 | Argo Workflow | Executes pipeline tasks in pods | S3 (artifacts), MLMD (metadata) |
| 6 | Pipeline Task | Trains model using runtime image | S3 (model checkpoint) |
| 7 | Pipeline Task | Creates InferenceService CR for deployment | KServe |
| 8 | Pipeline Task | Registers model metadata | Model Registry |

#### Workflow 3: Feature Engineering to Model Serving

| Step | Component | Action | Next Component |
|------|-----------|--------|----------------|
| 1 | User / Dashboard | Creates FeatureStore CR | Feast Operator |
| 2 | Feast Operator | Deploys Feast registry, online, offline stores | PostgreSQL, S3 |
| 3 | Data Engineer | Defines features and materializes to online store | Feast Offline → Online Store |
| 4 | Notebook | Retrieves features for model training | Feast Online Store |
| 5 | Training Job | Trains model with features | S3 (model checkpoint) |
| 6 | Inference Application | Retrieves real-time features | Feast Online Store |
| 7 | Inference Application | Calls model prediction | KServe InferenceService |
| 8 | TrustyAI | Monitors feature drift and model fairness | PostgreSQL (monitoring data) |

#### Workflow 4: LLM Evaluation and Guardrails

| Step | Component | Action | Next Component |
|------|-----------|--------|----------------|
| 1 | User / Dashboard | Creates LMEvalJob CR for LLM evaluation | TrustyAI Operator |
| 2 | TrustyAI Operator | Creates Kubernetes Job with lm-evaluation-harness | Kueue (optional queuing) |
| 3 | LMEval Job | Evaluates LLM using specified tasks | Model endpoint (InferenceService) |
| 4 | LMEval Job | Stores evaluation results | S3 Storage |
| 5 | User / Dashboard | Creates GuardrailsOrchestrator CR | TrustyAI Operator |
| 6 | Guardrails Orchestrator | Orchestrates detector InferenceServices | Detector InferenceServices |
| 7 | LLM Application | Sends request to guardrails gateway | Guardrails Gateway |
| 8 | Guardrails Gateway | Routes through detectors and LLM | Orchestrator → Detectors → LLM |
| 9 | Guardrails Gateway | Returns validated response | LLM Application |

#### Workflow 5: Distributed Computing with Ray

| Step | Component | Action | Next Component |
|------|-----------|--------|----------------|
| 1 | User / Dashboard | Creates RayCluster CR | KubeRay Operator |
| 2 | KubeRay Operator | Deploys Ray head and worker pods | NetworkPolicy (security) |
| 3 | KubeRay Operator | Creates Route for Ray dashboard (with OAuth) | OpenShift OAuth |
| 4 | User | Submits Ray job via dashboard or API | Ray Head (port 10001) |
| 5 | Ray Head | Distributes tasks to workers | Ray Workers (GCS communication) |
| 6 | Ray Workers | Execute distributed computations | S3 (data), GPU resources |
| 7 | User | Monitors job via Ray dashboard | Ray Dashboard (port 8265 via Route) |

## Deployment Architecture

### Namespaces

**Operator Control Plane:**
- `redhat-ods-operator`: RHODS Operator (3 replicas, HA)
- `opendatahub`: Kubeflow operators (Notebook, Training, Trainer, KubeRay)

**Application Services:**
- `redhat-ods-applications`: ODH Dashboard, Model Registry, MLflow, Feast, TrustyAI, Llama Stack

**Monitoring:**
- `redhat-ods-monitoring`: Prometheus, Alertmanager, ServiceMonitors

**Infrastructure:**
- `istio-system`: Istio control plane and gateways
- `knative-serving`: Knative Serving for serverless inference

**User Workloads:**
- User-created namespaces with label `opendatahub.io/dashboard=true`

### Resource Requirements

**Operator Pods (Representative Examples):**

| Operator | CPU Request | CPU Limit | Memory Request | Memory Limit |
|----------|-------------|-----------|----------------|--------------|
| RHODS Operator | 100m | 500m | 780Mi | 4Gi |
| KServe Controller | 100m | 100m | 200Mi | 300Mi |
| ODH Dashboard | 500m | 1000m | 1Gi | 2Gi |
| Data Science Pipelines Operator | 10m | 500m | 256Mi | 1Gi |
| Training Operator | Not specified | Not specified | Not specified | Not specified |
| KubeRay Operator | Not specified | Not specified | Not specified | Not specified |

**User Workload Defaults:**

| Workload Type | CPU Request | Memory Request | GPU |
|--------------|-------------|----------------|-----|
| Jupyter Notebook | 250m | 512Mi | Optional (NVIDIA/AMD) |
| InferenceService Predictor | Varies by runtime | Varies by runtime | Optional (NVIDIA/AMD) |
| Training Job Pod | Configurable | Configurable | Optional (NVIDIA/AMD) |
| Ray Worker | Configurable | Configurable | Optional (NVIDIA/AMD) |

## Version-Specific Changes (3.2)

| Component | Changes |
|-----------|---------|
| RHODS Operator | - Updated to v1.6.0 with 15 managed components<br>- Added Llama Stack Operator support<br>- Enhanced monitoring and service mesh integration |
| ODH Dashboard | - Updated to v1.21.0 with Node.js 22<br>- Module federation architecture for plugins<br>- GenAI Studio features (feature flag)<br>- Model-as-a-Service (MaaS) support |
| KServe | - Updated to v0.15.0 compatibility<br>- Enhanced vLLM support with multiple accelerators (CUDA, ROCm, Gaudi, Spyre)<br>- Precise prefix cache examples<br>- LLMInferenceService improvements |
| Data Science Pipelines | - DSP v2 with Argo Workflows backend<br>- Pod-to-pod mTLS encryption<br>- Enhanced MLMD gRPC integration with Envoy proxy<br>- KServe and Ray CRD integration |
| Notebooks | - Python 3.12 transition<br>- CUDA 12.8 and ROCm 6.3/6.4 support<br>- LLMCompressor integration for PyTorch<br>- Multi-architecture builds (x86_64, arm64, ppc64le, s390x) |
| KubeRay | - OpenShift OAuth integration for dashboard<br>- NetworkPolicy support for secure multi-tenancy<br>- Gateway API HTTPRoute support<br>- mTLS certificate management via cert-manager |
| Training Operator | - Updated to v1.9.0<br>- Enhanced webhook validation<br>- FIPS-compliant builds<br>- JobSet integration improvements |
| Trainer | - New v2.1.0 release (successor to Training Operator v1)<br>- TrainJob unified API<br>- TrainingRuntime template abstraction<br>- JobSet backend for multi-job coordination |
| Model Registry | - v1beta1 API with conversion webhooks<br>- Enhanced database support (PostgreSQL 16+, MySQL 8.0+)<br>- Istio/Authorino integration for service mesh auth |
| MLflow | - Kubernetes-auth integration via self_subject_access_review<br>- TLS termination in uvicorn<br>- Gateway API HTTPRoute integration<br>- OpenShift ConsoleLink support |
| Feast | - Feast 0.58.0 integration<br>- Kubeflow Notebook CRD integration<br>- FIPS-compliant operator builds<br>- Multi-arch support (amd64, arm64, ppc64le) |
| TrustyAI | - NeMo Guardrails integration<br>- LMEvalJob OCI output support<br>- Built-in detector standalone mode<br>- Kueue integration for job queuing |
| Llama Stack | - New component in RHOAI 3.2<br>- Uvicorn multi-worker support<br>- ConfigMap image override feature<br>- ARM64 multi-arch builds |
| ODH Model Controller | - NVIDIA NIM Account CRD and controller<br>- Enhanced vLLM runtime templates (CUDA, ROCm, Gaudi, CPU, Spyre)<br>- HuggingFace Detector template<br>- Model Registry integration (optional) |

## Platform Maturity

- **Total Components**: 15 operators/services
- **Operator-based Components**: 14 (93%)
- **Service Mesh Coverage**: 7 components (47% - model serving, monitoring, feature store)
- **mTLS Enforcement**: STRICT for model serving (KServe), PERMISSIVE for general platform
- **CRD API Versions**: Primarily v1 (stable), v1alpha1 (evolving), v1beta1 (maturing)
- **Multi-Architecture Support**: Full support for x86_64, partial for arm64/ppc64le/s390x (CPU workloads)
- **GPU Support**: NVIDIA CUDA (12.6, 12.8), AMD ROCm (6.2, 6.3, 6.4), Intel Gaudi
- **FIPS Compliance**: All operators built with FIPS-enabled Go runtime and UBI9 base images
- **High Availability**: RHODS Operator (3 replicas), other operators single replica with leader election
- **Monitoring Coverage**: Comprehensive - all components expose Prometheus metrics
- **Security Hardening**: Non-root containers, dropped capabilities, seccomp profiles, NetworkPolicies
- **Build System**: Konflux (FIPS, multi-arch, SBOM, vulnerability scanning, image signing)

## Next Steps for Documentation

1. **Architecture Diagrams**: Generate visual diagrams from this platform architecture:
   - Component dependency graph
   - Network traffic flows
   - Security boundaries and data flow diagrams
   - Deployment topology across namespaces

2. **ADRs (Architecture Decision Records)**: Document key decisions:
   - Why Argo Workflows over Tekton for DSP v2
   - TrainJob unified API vs. framework-specific CRDs
   - Service mesh integration patterns
   - Multi-tenancy and namespace isolation strategy

3. **User-Facing Documentation**: Create guides for:
   - Getting started with RHOAI 3.2
   - Model lifecycle workflows (train → register → deploy → monitor)
   - Distributed training best practices
   - Feature engineering with Feast
   - LLM evaluation and guardrails

4. **Security Architecture Review (SAR)**: Generate diagrams and documentation for:
   - Network segmentation and policies
   - mTLS and service mesh security
   - Secret management and rotation
   - RBAC and authorization model
   - Compliance requirements (FIPS, encryption at rest/in transit)

5. **Operations Runbooks**: Document procedures for:
   - Platform installation and upgrade
   - Component health monitoring
   - Troubleshooting common issues
   - Backup and disaster recovery
   - Scaling and capacity planning

6. **API Reference**: Auto-generate from CRD schemas:
   - Complete API reference for all CRDs
   - HTTP endpoint documentation
   - Integration examples and code samples
