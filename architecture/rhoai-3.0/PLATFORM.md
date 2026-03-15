# Platform: Red Hat OpenShift AI 3.0

## Metadata
- **Distribution**: RHOAI
- **Version**: 3.0
- **Release Date**: 2026-03-15
- **Base Platform**: OpenShift Container Platform 4.12+
- **Components Analyzed**: 13
- **Source Directory**: architecture/rhoai-3.0

## Platform Overview

Red Hat OpenShift AI (RHOAI) 3.0 is an enterprise-grade AI/ML platform built on Kubernetes that provides a complete lifecycle management system for machine learning workloads. The platform integrates 13 core components delivered as Kubernetes operators and containerized services, enabling data scientists and ML engineers to develop, train, deploy, and monitor AI models at scale.

The platform architecture centers around the RHODS Operator, which orchestrates the deployment and lifecycle of all data science components including Jupyter-based workbenches, data science pipelines (based on Kubeflow Pipelines 2.5.0), model serving infrastructure (KServe with serverless and raw deployment modes), distributed training (PyTorch, TensorFlow, JAX, MPI), distributed compute (Ray), model registry, feature stores (Feast), and AI governance tools (TrustyAI). All components integrate with OpenShift's service mesh (Istio), monitoring (Prometheus), and authentication (OAuth) infrastructure to provide enterprise-grade security, observability, and multi-tenancy.

RHOAI 3.0 introduces enhanced support for large language models (LLMs) through the Llama Stack operator, improved model governance with TrustyAI guardrails orchestration, and expanded GPU support including NVIDIA CUDA 12.8 and AMD ROCm 6.3/6.4. The platform supports both self-managed and managed deployment models (ROSA, OSD) with FIPS 140-2 compliance across all components.

## Component Inventory

| Component | Type | Version | Purpose |
|-----------|------|---------|---------|
| RHODS Operator | Operator | v1.6.0-3582 | Platform orchestrator managing all data science components |
| Data Science Pipelines Operator | Operator | 0.0.1 | Manages Kubeflow Pipelines 2.5.0 instances for ML workflows |
| ODH Dashboard | Web Application | v1.21.0-18 | User interface for platform management and workbench access |
| KServe | Operator + Services | 5e4621c70 | Model serving platform with serverless and raw deployment modes |
| Notebook Controller | Operator | v1.27.0 | Manages Jupyter notebook lifecycle as StatefulSets |
| Notebooks (Workbenches) | Container Images | v3.0.0-1 | JupyterLab, RStudio, CodeServer workbench environments |
| Model Registry Operator | Operator | eb4d8e5 | Deploys and manages ML model metadata repositories |
| ODH Model Controller | Controller | 1.27.0-rhods-1087 | Extends KServe with OpenShift-native features |
| Training Operator | Operator | 1.9.0 | Manages distributed training jobs (PyTorch, TensorFlow, JAX, MPI, XGBoost) |
| KubeRay Operator | Operator | dac6aae7 | Manages Ray clusters for distributed computing |
| Feast Operator | Operator | e43f213a4 | Deploys Feast feature stores for ML feature management |
| Llama Stack Operator | Operator | v0.4.0 | Manages Llama Stack AI inference servers |
| TrustyAI Service Operator | Operator | 1.39.0 | Provides model explainability, evaluation, and guardrails |

## Component Relationships

### Dependency Graph

```
RHODS Operator (root)
├── ODH Dashboard ──> Model Registry (API calls)
│   ├── Notebook Controller (CRD watch)
│   ├── KServe (CRD watch)
│   ├── Model Registry (CRD/API)
│   ├── Data Science Pipelines (API proxy)
│   ├── Training Operator (CRD watch)
│   ├── KubeRay (CRD watch)
│   ├── Feast (CRD watch)
│   ├── Llama Stack (CRD watch)
│   └── TrustyAI (CRD watch)
│
├── Data Science Pipelines Operator
│   ├── KServe (API calls for model deployment)
│   ├── Model Registry (API calls for model metadata)
│   ├── Workbenches (network access from notebooks)
│   └── Service Mesh (mTLS)
│
├── KServe
│   ├── Service Mesh/Istio (traffic routing, mTLS)
│   ├── Knative Serving (autoscaling in serverless mode)
│   ├── Model Registry (optional integration)
│   ├── ODH Model Controller (OpenShift integration)
│   └── Data Science Pipelines (model deployment)
│
├── ODH Model Controller
│   ├── KServe (extends functionality)
│   ├── Service Mesh/Istio (EnvoyFilter creation)
│   ├── Model Registry (optional integration)
│   └── Prometheus (ServiceMonitor creation)
│
├── Notebook Controller
│   ├── Service Mesh/Istio (VirtualService creation)
│   ├── Workbenches (manages notebook images)
│   └── ODH Dashboard (status monitoring)
│
├── Workbenches
│   ├── Data Science Pipelines (pipeline execution)
│   ├── Model Registry (model registration)
│   └── KServe (model serving from notebooks)
│
├── Model Registry Operator
│   ├── PostgreSQL/MySQL (backend database)
│   └── Service Mesh/Istio (optional)
│
├── Training Operator
│   ├── Volcano/scheduler-plugins (optional gang scheduling)
│   └── KEDA (optional autoscaling)
│
├── KubeRay Operator
│   ├── cert-manager (optional mTLS)
│   └── Gateway API (optional ingress)
│
├── Feast Operator
│   ├── S3/GCS/Snowflake (storage backends)
│   └── OpenShift OAuth (optional OIDC)
│
├── Llama Stack Operator
│   ├── vLLM/TGI/Ollama (inference providers)
│   └── HuggingFace Hub (model downloads)
│
└── TrustyAI Service Operator
    ├── KServe (guardrails injection)
    ├── Model Mesh (payload processor injection)
    └── PostgreSQL/MySQL (optional database storage)
```

### Central Components

Components with the most dependencies (core platform services):

1. **RHODS Operator** - Platform orchestrator, manages all component lifecycle
2. **KServe** - Model serving hub, integrated by pipelines, model controller, TrustyAI
3. **Service Mesh (Istio)** - Used by KServe, DSP, ODH Model Controller, Model Registry for mTLS and routing
4. **ODH Dashboard** - Central UI, integrates with all components for status monitoring
5. **Model Registry** - Referenced by Dashboard, DSP, KServe, Workbenches for model metadata
6. **Workbenches** - Foundation for data science workflows, used to submit pipelines and deploy models

### Integration Patterns

| Pattern | Components Using | Implementation |
|---------|------------------|----------------|
| **CRD Watch** | Dashboard, ODH Model Controller, TrustyAI | Watch Kubernetes Custom Resources for status updates |
| **API Proxy** | Dashboard, DSP | Backend proxies API requests to component services |
| **Operator Deployment** | RHODS Operator | Manages component operators via Kustomize manifests |
| **Service Mesh Integration** | KServe, DSP, Model Registry | VirtualService, DestinationRule for routing and mTLS |
| **OAuth Proxy** | Dashboard, Model Registry, TrustyAI | kube-rbac-proxy sidecar for authentication |
| **ServiceMonitor** | All operators | Prometheus metrics scraping |
| **Webhook Validation** | KServe, Training Operator, Llama Stack, TrustyAI | ValidatingWebhookConfiguration for admission control |
| **Storage Abstraction** | Feast, Model Registry, TrustyAI | Support for PVC, S3, and database backends |

## Platform Network Architecture

### Namespaces

| Namespace | Purpose | Components |
|-----------|---------|------------|
| redhat-ods-operator-system | Operator deployment | RHODS Operator controller manager |
| redhat-ods-applications | Default components | Dashboard, Notebook Controller, Model Controller, Component Operators |
| redhat-ods-monitoring | Monitoring stack | Prometheus, AlertManager, Blackbox Exporter |
| opendatahub | KubeRay/Training | KubeRay Operator, Training Operator |
| User namespaces | Data science workloads | Notebooks, Pipelines, Models, Training Jobs, Feature Stores |

### External Ingress Points

| Component | Ingress Type | Hosts | Port | Protocol | Encryption | Purpose |
|-----------|--------------|-------|------|----------|------------|---------|
| ODH Dashboard | OpenShift Route | Auto-generated | 443/TCP | HTTPS | TLS 1.2+ (reencrypt) | Web UI access |
| Prometheus | OpenShift Route | prometheus-{ns}.apps.{cluster} | 443/TCP | HTTPS | TLS 1.2+ (reencrypt) | Monitoring dashboard |
| AlertManager | OpenShift Route | alertmanager-{ns}.apps.{cluster} | 443/TCP | HTTPS | TLS 1.2+ (reencrypt) | Alert management |
| Data Science Pipelines | OpenShift Route | ds-pipeline-{name} | 443/TCP | HTTPS | TLS 1.2+ (reencrypt) | Pipeline API access |
| Model Registry | OpenShift Route | {registry-name}-https | 443/TCP | HTTPS | TLS 1.2+ (edge) | Model registry API |
| KServe InferenceServices | OpenShift Route/Istio VirtualService | {isvc-name} | 443/TCP | HTTPS | TLS 1.2+ | Model inference endpoints |
| Notebooks | OpenShift Route | {notebook-name} | 443/TCP | HTTPS | TLS 1.2+ (edge) | Jupyter/RStudio/CodeServer |
| TrustyAI Service | OpenShift Route | {trustyai-name} | 443/TCP | HTTPS | TLS 1.2+ (edge) | Explainability API |
| Feast Feature Store | OpenShift Route (optional) | {feast-name} | 443/TCP | HTTPS | TLS 1.2+ | Feature serving API |

### External Egress Dependencies

| Component | Destination | Port | Protocol | Encryption | Purpose |
|-----------|-------------|------|----------|------------|---------|
| KServe | S3 (AWS/Minio/GCS/Azure) | 443/TCP | HTTPS | TLS 1.2+ | Model artifact download |
| KServe | HuggingFace Hub | 443/TCP | HTTPS | TLS 1.2+ | HuggingFace model download |
| Data Science Pipelines | S3-compatible storage | 443/TCP | HTTPS | TLS 1.2+ | Pipeline artifact storage |
| Data Science Pipelines | External Database | 3306/5432/TCP | MySQL/PostgreSQL | TLS 1.2+ | Pipeline metadata (if external) |
| Workbenches | PyPI (files.pythonhosted.org) | 443/TCP | HTTPS | TLS 1.2+ | Python package installation |
| Workbenches | CRAN (cran.rstudio.com) | 443/TCP | HTTPS | TLS 1.2+ | R package installation |
| Workbenches | GitHub | 443/TCP | HTTPS | TLS 1.2+ | Git repository access |
| Workbenches | S3 storage | 443/TCP | HTTPS | TLS 1.2+ | Training data and model storage |
| Model Registry | PostgreSQL/MySQL | 5432/3306/TCP | PostgreSQL/MySQL | TLS 1.2+ (optional) | Model metadata persistence |
| Feast | S3/GCS/Snowflake | 443/TCP | HTTPS | TLS 1.2+ | Feature data persistence |
| Feast | PostgreSQL/MySQL | 5432/3306/TCP | PostgreSQL/MySQL | TLS 1.2+ | Feature registry and online store |
| Llama Stack | HuggingFace Hub | 443/TCP | HTTPS | TLS 1.2+ | Model downloads |
| Llama Stack | vLLM/TGI/Ollama | Varies | HTTP/HTTPS | Varies | Inference provider backends |
| TrustyAI | KServe InferenceServices | 443/TCP | HTTPS/gRPC | mTLS | Inference request monitoring |
| TrustyAI | PostgreSQL/MySQL | Varies | JDBC | TLS 1.2+ (optional) | Data persistence |
| Training Operator | Container Registries | 443/TCP | HTTPS | TLS 1.2+ | Training job container images |
| All Operators | Container Registries (quay.io, registry.redhat.io) | 443/TCP | HTTPS | TLS 1.2+ | Container image pulls |

### Internal Service Mesh

| Setting | Value | Components Using |
|---------|-------|------------------|
| **mTLS Mode** | PERMISSIVE (default) / STRICT (configurable) | KServe, Data Science Pipelines, Model Registry (optional) |
| **Peer Authentication** | Service mesh namespace-scoped | KServe serverless deployments, ODH Model Controller injected services |
| **VirtualServices** | 100+ (dynamic per InferenceService/Notebook) | KServe, Notebooks, Data Science Pipelines |
| **DestinationRules** | Per service with mTLS | KServe, Model Registry |
| **EnvoyFilters** | SSL passthrough for LLM services | ODH Model Controller for LLMInferenceServices |
| **AuthorizationPolicies** | JWT validation for inference endpoints | ODH Model Controller (Authorino integration) |

## Platform Security

### RBAC Summary

| Component | ClusterRole | Key Permissions |
|-----------|-------------|-----------------|
| RHODS Operator | rhods-operator-role | Full CRD management, namespace/pod/deployment CRUD, RBAC management |
| Data Science Pipelines | manager-role | Workflow/Pod/Service CRUD, InferenceService/RayCluster integration |
| KServe | kserve-manager-role | InferenceService/ServingRuntime CRUD, Knative/Istio/Gateway API resources |
| ODH Dashboard | odh-dashboard (cluster + namespaced) | Read-only cluster resources, namespace CRUD, CRD watches |
| ODH Model Controller | odh-model-controller-role | InferenceService patch, Route/NetworkPolicy/ServiceMonitor CRUD |
| Notebook Controller | notebook-controller-role | Notebook/StatefulSet/Service CRUD, Istio VirtualService management |
| Model Registry Operator | manager-role | ModelRegistry CRUD, Deployment/Service/Route CRUD, StorageVersionMigration |
| Training Operator | training-operator | Training job CRDs CRUD, Pod/Service CRUD, Volcano/scheduler-plugins PodGroups |
| KubeRay Operator | kuberay-operator | Ray CRDs CRUD, Pod/Service/NetworkPolicy CRUD, cert-manager integration |
| Feast Operator | manager-role | FeatureStore CRUD, Deployment/Service/Route CRUD, OpenShift OAuth integration |
| Llama Stack Operator | manager-role | LlamaStackDistribution CRUD, Deployment/Service/PVC/NetworkPolicy CRUD |
| TrustyAI Operator | manager-role | TrustyAI CRDs CRUD, InferenceService patch, Kueue integration |

### Secrets Inventory

| Component | Secret Name | Type | Purpose |
|-----------|-------------|------|---------|
| RHODS Operator | redhat-ods-operator-controller-webhook-cert | kubernetes.io/tls | Operator webhook TLS |
| RHODS Operator | prometheus-tls, alertmanager-tls | kubernetes.io/tls | Monitoring service TLS |
| Data Science Pipelines | ds-pipelines-proxy-tls-{name} | kubernetes.io/tls | OAuth proxy TLS |
| Data Science Pipelines | {db-credentials-secret} | Opaque | Database username/password |
| Data Science Pipelines | {storage-credentials-secret} | Opaque | S3 access credentials |
| KServe | kserve-webhook-server-cert | kubernetes.io/tls | Webhook server TLS |
| KServe | storage-config | Opaque | S3/GCS/Azure model storage credentials |
| Model Registry | {registry-name}-kube-rbac-proxy | kubernetes.io/tls | RBAC proxy TLS |
| Model Registry | model-registry-db-credential | Opaque | Database TLS CA certificates |
| Dashboard | dashboard-proxy-tls | kubernetes.io/tls | OAuth proxy TLS |
| Notebooks | {notebook-name}-oauth-config | Opaque | OAuth proxy configuration |
| Workbenches | git-credentials, aws-credentials, database-credentials | Opaque/basic-auth | User-provided credentials |
| Feast | {name}-tls, {name}-client-tls | kubernetes.io/tls | Service and client mTLS |
| Feast | oidc-secret | Opaque | OIDC authentication credentials |
| Llama Stack | hf-token-secret | Opaque | HuggingFace API token |
| TrustyAI | {trustyai-name}-internal, {trustyai-name}-tls | kubernetes.io/tls | Service TLS certificates |
| TrustyAI | {trustyai-name}-db-credentials | Opaque | Database connection credentials |
| ODH Model Controller | odh-model-controller-webhook-cert | kubernetes.io/tls | Webhook server TLS |
| Training Operator | kubeflow-training-operator-webhook-cert | kubernetes.io/tls | Webhook server TLS |

### Authentication Mechanisms

| Pattern | Components Using | Enforcement Point |
|---------|------------------|-------------------|
| **Bearer Tokens (JWT)** | All web UIs (Dashboard, Prometheus, Notebooks) | OAuth Proxy / kube-rbac-proxy |
| **ServiceAccount Tokens** | All operators, KServe models, DSP pods | Kubernetes API Server RBAC |
| **mTLS Client Certificates** | Service Mesh, Feast (optional), Model Registry (optional) | Istio/Envoy, Database servers |
| **OAuth2 (OpenShift)** | Dashboard, Notebooks, Model Registry, TrustyAI | kube-rbac-proxy with OpenShift OAuth |
| **OIDC** | Feast (optional), Llama Stack (optional) | Application-level JWT validation |
| **AWS IAM/SigV4** | KServe S3 access, DSP S3 access | S3-compatible storage providers |
| **Database Auth** | DSP (MariaDB/PostgreSQL), Model Registry, Feast, TrustyAI | Database server authentication |
| **Webhook mTLS** | All operators with admission webhooks | Kubernetes API Server |

## Platform APIs

### Custom Resource Definitions

| Component | API Group | Kind | Scope | Purpose |
|-----------|-----------|------|-------|---------|
| RHODS Operator | datasciencecluster.opendatahub.io | DataScienceCluster | Cluster | Platform-wide component enablement |
| RHODS Operator | dscinitialization.opendatahub.io | DSCInitialization | Cluster | Platform initialization configuration |
| RHODS Operator | components.platform.opendatahub.io | Dashboard, DataSciencePipelines, Kserve, Ray, etc. | Cluster | Individual component configurations |
| RHODS Operator | services.platform.opendatahub.io | Auth, Monitoring, GatewayConfig | Cluster | Platform service configurations |
| RHODS Operator | infrastructure.opendatahub.io | HardwareProfile | Cluster | Hardware resource profiles |
| Data Science Pipelines | datasciencepipelinesapplications.opendatahub.io | DataSciencePipelinesApplication | Namespaced | DSP instance configuration |
| Data Science Pipelines | argoproj.io | Workflow, WorkflowTemplate, CronWorkflow | Namespaced | Argo Workflows for pipeline execution |
| KServe | serving.kserve.io | InferenceService, ServingRuntime, ClusterServingRuntime | Namespaced/Cluster | Model serving definitions |
| KServe | serving.kserve.io | LLMInferenceService, InferenceGraph, TrainedModel | Namespaced | Advanced serving patterns |
| Notebook Controller | kubeflow.org | Notebook | Namespaced | Jupyter notebook instance definitions |
| Model Registry | modelregistry.opendatahub.io | ModelRegistry | Namespaced | Model registry instance configuration |
| Training Operator | kubeflow.org | PyTorchJob, TFJob, MPIJob, XGBoostJob, JAXJob, PaddleJob | Namespaced | Distributed training job definitions |
| KubeRay | ray.io | RayCluster, RayJob, RayService | Namespaced | Ray cluster and job definitions |
| Feast | feast.dev | FeatureStore | Namespaced | Feature store configuration |
| Llama Stack | llamastack.io | LlamaStackDistribution | Namespaced | Llama Stack server deployment |
| TrustyAI | trustyai.opendatahub.io | TrustyAIService, LMEvalJob, GuardrailsOrchestrator | Namespaced | AI governance services |
| ODH Dashboard | dashboard.opendatahub.io | OdhApplication, OdhDocument | Namespaced | Dashboard application tiles and docs |
| ODH Dashboard | console.openshift.io | OdhQuickStart | Namespaced | Interactive tutorials |
| ODH Model Controller | nim.opendatahub.io | Account | Namespaced | NVIDIA NIM account integration |

**Total CRDs**: 50+ across all components

### Public HTTP Endpoints

| Component | Path | Method | Port | Protocol | Auth | Purpose |
|-----------|------|--------|------|----------|------|---------|
| ODH Dashboard | / | GET | 8443/TCP | HTTPS | OAuth2 | Dashboard web UI |
| ODH Dashboard | /api/* | GET/POST/PUT/DELETE | 8443/TCP | HTTPS | OAuth2 | Dashboard backend API |
| Data Science Pipelines | /apis/v2beta1/* | GET/POST/DELETE | 8888/TCP | HTTP | Bearer Token | KFP v2 API |
| KServe InferenceServices | /v1/models/:name:infer | POST | 8080/TCP | HTTP | Configurable | KServe V1 inference |
| KServe InferenceServices | /v2/models/:name/infer | POST | 8080/TCP | HTTP | Configurable | KServe V2 inference |
| Model Registry | /api/model_registry/v1alpha3/* | GET/POST/PUT/DELETE | 8443/TCP | HTTPS | Bearer Token | Model registry API |
| Notebooks | /lab | GET/POST | 8888/TCP | HTTP | OAuth2 | JupyterLab interface |
| Feast Online Store | /get-online-features | POST | 6566/6567/TCP | HTTP/HTTPS | Configurable | Real-time feature retrieval |
| Feast Offline Store | /get-historical-features | POST | 8815/8816/TCP | HTTP/HTTPS | Configurable | Historical features for training |
| Feast Registry | /registry/* | GET/POST | 6572/6573/TCP | HTTP/HTTPS | Configurable | Feature registry operations |
| TrustyAI Service | /* | ALL | 8443/TCP | HTTPS | Bearer/mTLS | Explainability API |
| Llama Stack | /v1/* | POST/GET | 8321/TCP | HTTP | None | Llama Stack inference API |

## Data Flows

### Key Platform Workflows

#### Workflow 1: Model Training to Deployment

| Step | Component | Action | Data Flow | Next Component |
|------|-----------|--------|-----------|----------------|
| 1 | Workbench (Notebook) | User develops and trains model | Jupyter → S3 (model artifacts) | S3 Storage |
| 2 | Data Science Pipelines | User creates deployment pipeline | Notebook → DSP API (pipeline definition) | DSP Operator |
| 3 | DSP Operator | Executes pipeline workflow | DSP → Argo Workflows (create Workflow CR) | Argo Workflow Controller |
| 4 | Pipeline Pod | Downloads model from S3, creates InferenceService | Argo Pod → KServe API (create ISVC) | KServe Controller |
| 5 | KServe Controller | Deploys model serving runtime | KServe → K8s API (create Deployment) | Model Server Pod |
| 6 | ODH Model Controller | Provisions Route and monitoring | Model Controller → OpenShift (create Route, ServiceMonitor) | OpenShift Router |
| 7 | Model Registry | Registers deployed model metadata | Pipeline → Model Registry API (register model) | Model Registry DB |
| 8 | TrustyAI (optional) | Injects guardrails into InferenceService | TrustyAI → ISVC (patch with guardrails) | Guardrails Orchestrator |

#### Workflow 2: Feature Engineering to Model Serving

| Step | Component | Action | Data Flow | Next Component |
|------|-----------|--------|-----------|----------------|
| 1 | Workbench | Define features and feature store | Notebook → Feast CLI (feature definitions) | Feast Operator |
| 2 | Feast Operator | Deploy feature store instance | Feast Operator → K8s API (create Deployment) | Feast Services |
| 3 | Data Pipeline | Materialize features offline to online | Feast CronJob → Offline Store → Online Store | Feature DB |
| 4 | Training Job | Retrieve historical features for training | Training Pod → Feast Offline (/get-historical-features) | Training Code |
| 5 | Training Operator | Execute distributed training | Training Operator → K8s API (create PyTorchJob) | Training Pods |
| 6 | InferenceService | Retrieve online features for inference | Model Server → Feast Online (/get-online-features) | Model Prediction |

#### Workflow 3: Distributed Training Job

| Step | Component | Action | Data Flow | Next Component |
|------|-----------|--------|-----------|----------------|
| 1 | Workbench | Submit PyTorchJob via Python SDK | Notebook → K8s API (create PyTorchJob CR) | Kubernetes API |
| 2 | Training Operator | Validate job specification | K8s API → Training Webhook (validate) | Webhook Server |
| 3 | Training Operator | Create worker and master pods | Training Operator → K8s API (create Pods, Services) | Kubernetes Scheduler |
| 4 | Volcano (optional) | Gang schedule all pods together | Scheduler → Volcano (PodGroup) | Node Assignment |
| 5 | Training Pods | Distributed training communication | Master Pod ← Workers (port 23456/TCP) | Training Execution |
| 6 | Training Pods | Save checkpoints to S3 | Training Pods → S3 (model artifacts) | S3 Storage |
| 7 | Model Registry | Register trained model | Training Pod → Model Registry API (register) | Model Registry DB |

#### Workflow 4: Model Explainability and Monitoring

| Step | Component | Action | Data Flow | Next Component |
|------|-----------|--------|-----------|----------------|
| 1 | TrustyAI Operator | Deploy TrustyAI service | TrustyAI Operator → K8s API (create Deployment) | TrustyAI Service |
| 2 | ODH Model Controller | Inject guardrails into InferenceService | Model Controller → ISVC (patch predictor) | Modified ISVC |
| 3 | Client | Send inference request | Client → Guardrails Gateway | Guardrails Orchestrator |
| 4 | Guardrails Orchestrator | Run detector models (bias, toxicity) | Orchestrator → Detector ISVCs (inference) | Detection Results |
| 5 | Guardrails Orchestrator | Forward to generator model | Orchestrator → Generator ISVC (inference) | Model Response |
| 6 | TrustyAI Service | Log request/response for monitoring | Guardrails → TrustyAI API (payload logging) | TrustyAI Storage |
| 7 | TrustyAI Service | Generate explainability metrics | TrustyAI → Prometheus (/q/metrics) | Prometheus |

#### Workflow 5: End-to-End Data Science Pipeline

| Step | Component | Action | Data Flow | Next Component |
|------|-----------|--------|-----------|----------------|
| 1 | Dashboard | User creates notebook from template | Dashboard → K8s API (create Notebook CR) | Notebook Controller |
| 2 | Notebook Controller | Provision Jupyter environment | Notebook Controller → K8s API (create StatefulSet) | Notebook Pod |
| 3 | Workbench | Data exploration and model development | Notebook → S3 (read datasets) | Training Code |
| 4 | Workbench | Create and submit pipeline | Notebook → DSP API (upload pipeline YAML) | DSP API Server |
| 5 | DSP API Server | Create Argo Workflow | DSP → Workflow Controller (create Workflow CR) | Argo Workflows |
| 6 | Pipeline Steps | Data preprocessing, training, evaluation | Pipeline Pods → S3, MLMD, Model Registry | Model Artifacts |
| 7 | Pipeline Step | Deploy model via KServe | Pipeline Pod → KServe API (create ISVC) | KServe Controller |
| 8 | Dashboard | Monitor pipeline and model status | Dashboard → K8s API (watch Workflows, ISVCs) | Status Display |

## Deployment Architecture

### Deployment Topology

```
OpenShift Cluster
│
├── redhat-ods-operator-system (Control Plane)
│   ├── RHODS Operator (3 replicas, HA)
│   └── Webhook Server
│
├── redhat-ods-applications (Platform Components)
│   ├── ODH Dashboard (2 replicas, HA)
│   ├── Notebook Controller (1 replica)
│   ├── ODH Model Controller (1 replica)
│   ├── Data Science Pipelines Operator (1 replica)
│   ├── KServe Controller (1 replica)
│   ├── Model Registry Operator (1 replica)
│   ├── Training Operator (1 replica)
│   ├── Feast Operator (1 replica)
│   ├── Llama Stack Operator (1 replica)
│   └── TrustyAI Operator (1 replica)
│
├── redhat-ods-monitoring (Observability)
│   ├── Prometheus (StatefulSet, PVC-backed)
│   ├── AlertManager (StatefulSet, PVC-backed)
│   └── Blackbox Exporter
│
├── opendatahub (Additional Operators)
│   ├── KubeRay Operator (1 replica)
│   └── Training Operator (alternative deployment location)
│
└── User Namespaces (Workloads)
    ├── Jupyter Notebooks (StatefulSet per notebook)
    ├── DSP Instances (namespace-scoped)
    │   ├── DSP API Server
    │   ├── Persistence Agent
    │   ├── Scheduled Workflow Controller
    │   ├── Workflow Controller (Argo)
    │   ├── MariaDB (optional)
    │   └── Minio (optional, dev/test only)
    ├── InferenceServices (KServe)
    │   ├── Predictor Pods (autoscaling)
    │   ├── Transformer Pods (optional)
    │   └── Explainer Pods (optional)
    ├── Model Registries (namespace-scoped)
    │   ├── Registry REST/gRPC Server
    │   └── PostgreSQL/MySQL (external or deployed)
    ├── Training Jobs
    │   ├── PyTorchJob Pods (master + workers)
    │   ├── TFJob Pods (chief + parameter servers + workers)
    │   └── MPIJob Pods (launcher + workers)
    ├── Ray Clusters
    │   ├── Ray Head Pod
    │   └── Ray Worker Pods (autoscaling)
    ├── Feature Stores (Feast)
    │   ├── Online Store Server
    │   ├── Offline Store Server
    │   ├── Registry Server
    │   └── UI (optional)
    ├── Llama Stack Instances
    │   └── Llama Stack Server Pod
    └── TrustyAI Services
        ├── TrustyAI Service Pod
        ├── LMEvalJob Pods (batch)
        └── Guardrails Orchestrator
```

### Resource Requirements

| Component | CPU Request | CPU Limit | Memory Request | Memory Limit | Notes |
|-----------|-------------|-----------|----------------|--------------|-------|
| RHODS Operator | 500m | 500m | 256Mi | 4Gi | Per replica (3 replicas for HA) |
| ODH Dashboard | 500m | 1000m | 1Gi | 2Gi | Per replica (2 replicas for HA) |
| Data Science Pipelines Operator | 200m | 1000m | 400Mi | 4Gi | Controller only |
| KServe Controller | Not specified | Not specified | Not specified | Not specified | Configured via deployment |
| Model Registry Operator | 10m | 500m | 64Mi | 2Gi | Operator pod |
| Training Operator | Not specified | Not specified | Not specified | Not specified | Operator pod |
| KubeRay Operator | 100m | 100m | 512Mi | 512Mi | Operator pod |
| Notebook Controller | 500m | 500m | 256Mi | 4Gi | Controller pod |
| Workbench (Minimal) | 500m | 2 cores | 1Gi | 4Gi | Per notebook instance |
| Workbench (Data Science) | 1 core | 4 cores | 2Gi | 8Gi | Per notebook instance |
| Workbench (GPU) | 4 cores | 16 cores | 8Gi | 32Gi | Per notebook instance + GPU |
| DSP Instance (API Server) | Not specified | Not specified | Not specified | Not specified | Per namespace deployment |
| Model Registry Instance | Not specified | Not specified | Not specified | Not specified | Per namespace deployment |
| InferenceService (CPU) | Varies | Varies | Varies | Varies | User-configurable per model |
| InferenceService (GPU) | Varies | Varies | Varies | Varies | User-configurable per model + GPU |

## Version-Specific Changes (3.0)

| Component | Changes |
|-----------|---------|
| Data Science Pipelines Operator | - Update UBI minimal base image (multiple security updates)<br>- Dependency updates via Konflux CI/CD |
| Feast | - Sync pipelineruns with konflux-central<br>- Update Konflux references |
| KServe | - Cherry-pick precise prefix routing updates<br>- Update precise prefix routing example for InferenceGraph |
| Notebook Controller (Kubeflow) | - Update UBI minimal base image digests (multiple security updates) |
| KubeRay | - Update UBI9 go-toolset and ubi-minimal base images<br>- Update Konflux pipeline references |
| Llama Stack | - Update release versions for 3.0<br>- Remove dependency on cluster-scoped resources<br>- Use new CLI to run server<br>- Fix version detection for pre-release versions<br>- Multiple security updates to UBI9 minimal base image |
| Model Registry | - Bump Go to 1.25.7<br>- Update UBI9 minimal base image (multiple security updates) |
| Notebooks | - Sync pipelineruns with konflux-central<br>- Retrigger TensorFlow CUDA build<br>- Update Codeflare-SDK to 0.32.1<br>- Fix Pyarrow build for s390x architecture<br>- Sync ODH changes to Dockerfile.konflux files<br>- Create symbolic links for ROCm 6.3.4 TensorFlow compatibility<br>- Add gettext for envsubst in run-nginx.sh<br>- Skip tf2onnx conversion test for TensorFlow 2.16+ incompatibility |
| ODH Dashboard | - Update registry.access.redhat.com/ubi9/nodejs-20 base image (multiple digest updates)<br>- Update registry.access.redhat.com/ubi9-minimal base image (multiple digest updates) |
| ODH Model Controller | - Update UBI minimal base image (multiple security updates)<br>- Update Konflux pipeline references (extensive CI/CD updates) |
| RHODS Operator | - Updating operator with latest images and manifests<br>- Update odh-must-gather-v3-0<br>- Update odh-kuberay-operator-controller-v3-0<br>- Update odh-dashboard-v3-0 (multiple dashboard updates) |
| Training Operator | - Update UBI9 ubi-minimal base image (multiple security updates)<br>- Update Konflux references (CI/CD maintenance) |
| TrustyAI | - Fix auto config service ports for guardrails orchestrator<br>- Fix logging bug in auto config serving runtime logs<br>- Update autoconfig to use service information instead of hardcoded values<br>- Fix TrustyAI operator tests for config generation<br>- Mount and reference service CA to kube-rbac-proxy<br>- Make AutoConfig TLS toggleable (default: false)<br>- Add kube-rbac-proxy support for enhanced security |

**Common Themes**:
- Base image security updates (UBI9 minimal and go-toolset)
- Konflux CI/CD pipeline integration and maintenance
- Enhanced security features (kube-rbac-proxy, TLS configuration)
- Bug fixes and configuration improvements
- Multi-architecture support (s390x, ppc64le, aarch64)

## Platform Maturity

### Component Distribution
- **Total Components**: 13
- **Operator-based Components**: 12 (92%)
- **Web Applications**: 1 (ODH Dashboard)
- **Container Image Collections**: 1 (Workbenches)

### Technology Stack
- **Primary Language**: Go (all operators)
- **UI Technologies**: TypeScript/React (Dashboard), JupyterLab, RStudio, CodeServer
- **Base Images**: Red Hat UBI9 (Universal Base Image)
- **Build System**: Konflux CI/CD (FIPS-compliant)

### Service Mesh Coverage
- **Components with Service Mesh Integration**: 6 of 13 (46%)
  - KServe (VirtualService, DestinationRule, Gateway)
  - Data Science Pipelines (VirtualService for dashboards)
  - Model Registry (optional VirtualService)
  - Notebook Controller (VirtualService when USE_ISTIO=true)
  - ODH Model Controller (EnvoyFilter creation)
  - TrustyAI (VirtualService, DestinationRule)

### mTLS Enforcement
- **Mode**: MIXED
  - Service Mesh components: PERMISSIVE (allows both plain and mTLS)
  - Database connections: Optional TLS (configurable)
  - Internal pod-to-pod: TLS via service-serving certificates
  - External ingress: TLS 1.2+ (edge termination at router)

### API Versions
- **CRD API Versions**: v1 (stable), v1beta1 (KServe, serving), v1alpha1 (components, services)
- **Kubernetes API**: v1 (core), apps/v1, rbac.authorization.k8s.io/v1
- **Service Mesh**: networking.istio.io/v1beta1, v1
- **Monitoring**: monitoring.coreos.com/v1
- **Gateway API**: gateway.networking.k8s.io/v1, v1beta1

### Authentication Coverage
- **OAuth2 Integration**: 100% of user-facing UIs (Dashboard, Notebooks, Prometheus, Model Registry)
- **RBAC Enforcement**: All components via Kubernetes RBAC
- **Webhook Authentication**: All operators with webhooks (mTLS via K8s API server)
- **ServiceAccount Tokens**: All operator-to-API communications

### Monitoring Coverage
- **ServiceMonitor/PodMonitor**: 100% of operators expose Prometheus metrics
- **Health Checks**: 100% of components have /healthz and /readyz endpoints
- **Metrics Endpoints**: All operators on port 8080 or 8443 (HTTPS via kube-rbac-proxy)

## Next Steps for Documentation

### Immediate Actions
1. **Generate Architecture Diagrams**
   - Component dependency graph visualization
   - Network flow diagrams for key workflows
   - Deployment topology diagram
   - Security zone diagram (ingress → components → external services)

2. **Security Documentation**
   - Complete Security Architecture Review (SAR) document
   - Network segmentation policies
   - Certificate management procedures
   - RBAC role matrix (user roles to component permissions)

3. **Operations Runbooks**
   - Component upgrade procedures
   - Backup and disaster recovery for stateful components
   - Troubleshooting guides per component
   - Performance tuning recommendations

### Documentation Enhancements
1. **User-Facing Documentation**
   - Getting started guide for data scientists
   - Model deployment tutorials (notebook → pipeline → serving)
   - Feature store integration guide
   - Distributed training examples

2. **Administrator Documentation**
   - Installation and configuration guide
   - Multi-tenancy setup and namespace isolation
   - Resource quota and limit recommendations
   - Monitoring and alerting configuration

3. **Integration Guides**
   - External database configuration (PostgreSQL, MySQL)
   - S3-compatible storage setup
   - Custom CA certificate injection
   - LDAP/Active Directory integration

4. **Architecture Decision Records (ADRs)**
   - Service mesh adoption rationale
   - Operator vs. Helm chart decision
   - PVC vs. database storage for components
   - Multi-version API support strategy

### Diagram Generation
Run the following command to generate visual diagrams:
```bash
/generate-architecture-diagrams --architecture=./architecture/rhoai-3.0/PLATFORM.md
```

Expected diagram outputs:
- `platform-component-dependencies.mmd` - Mermaid dependency graph
- `platform-network-flows.mmd` - Network data flow diagrams
- `platform-deployment-topology.mmd` - Deployment architecture
- `platform-security-zones.mmd` - Security boundary diagram

### Quality Assurance
1. **Review Checklist**
   - [ ] Verify all 13 components are accurately represented
   - [ ] Cross-check CRD counts and API endpoints
   - [ ] Validate network ports and protocols
   - [ ] Confirm RBAC permissions align with component needs
   - [ ] Review external dependencies for accuracy

2. **Stakeholder Review**
   - Architecture Council review (platform design patterns)
   - Security team review (authentication, authorization, network policies)
   - Product management review (feature completeness)
   - Support team review (operational readiness)

3. **Continuous Updates**
   - Update with each component version bump
   - Track breaking changes in component APIs
   - Document migration paths for deprecated features
   - Maintain compatibility matrix (RHOAI ↔ OpenShift versions)

---

**Generated**: 2026-03-15
**Source**: architecture/rhoai-3.0/ (13 component architecture files)
**Platform Version**: RHOAI 3.0
**Architecture Status**: Production Ready
