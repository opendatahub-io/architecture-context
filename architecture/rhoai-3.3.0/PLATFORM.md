# Platform: Red Hat OpenShift AI 3.3.0

## Metadata
- **Distribution**: RHOAI
- **Version**: 3.3.0
- **Release Date**: 2026-03
- **Base Platform**: OpenShift Container Platform 4.17+
- **Components Analyzed**: 14

## Platform Overview

Red Hat OpenShift AI (RHOAI) 3.3.0 is a comprehensive platform for end-to-end machine learning and AI workloads on OpenShift. It provides a complete data science lifecycle toolkit spanning interactive development environments (Jupyter notebooks, RStudio, VS Code), distributed training frameworks (PyTorch, TensorFlow, JAX, MPI), model serving infrastructure (KServe with multi-framework runtimes), experiment tracking (MLflow), feature stores (Feast), model registries, and ML workflow orchestration (Data Science Pipelines based on Kubeflow Pipelines).

The platform is designed for enterprise-grade ML operations with deep OpenShift integration including OAuth authentication, OpenShift Routes for ingress, service mesh support via Istio, and comprehensive RBAC. RHOAI 3.3 introduces enhanced LLM capabilities with support for vLLM, NVIDIA NIM integration, Llama Stack operator, and distributed training/fine-tuning via the Kubeflow Trainer. The architecture emphasizes security with TLS everywhere, network policies, and RBAC-based access control across all components.

RHOAI provides both a centralized web dashboard for user interaction and declarative Kubernetes APIs for GitOps-driven ML workflows. The platform supports multi-cloud deployments with flexible storage backends (S3, PostgreSQL, PVC) and GPU acceleration from NVIDIA (CUDA), AMD (ROCm), and Intel (Gaudi). Components are independently scalable and can be selectively enabled based on workload requirements.

## Component Inventory

| Component | Type | Version | Purpose |
|-----------|------|---------|---------|
| Data Science Pipelines Operator | Operator | 0.0.1 | ML workflow orchestration based on Kubeflow Pipelines v2 with Argo Workflows |
| Feast | Operator + Service | v0.59.0 | Feature store for ML feature management and serving |
| KServe | Operator + Controller | v0.15 | Model serving platform with autoscaling and multi-framework support |
| ODH Notebook Controller | Operator | v1.27.0 | Extends Kubeflow Notebook with OpenShift integration and Gateway API routing |
| KubeRay | Operator | v1.4.2 | Ray cluster management for distributed computing and model serving |
| Llama Stack Operator | Operator | v0.6.0 | Manages Llama Stack server deployments for LLM inference |
| MLflow Operator | Operator | rhoai-3.3 | Experiment tracking and model registry management |
| Model Registry Operator | Operator | rhoai-3.3 | Model metadata and versioning registry with multi-database support |
| Notebooks | Container Images | v20xx.2 | Jupyter/RStudio/VS Code workbench images with ML frameworks (PyTorch, TensorFlow) |
| ODH Dashboard | Web Application | 1.21.0 | Unified web UI for platform management and user workflows |
| odh-model-controller | Operator | v1.27.0 | Extends KServe with OpenShift Routes, NetworkPolicies, NVIDIA NIM integration |
| Kubeflow Trainer | Operator | v2.1.0 | Distributed training and LLM fine-tuning with progression tracking |
| Kubeflow Training Operator | Operator | v1.9.0 | Multi-framework distributed training (PyTorch, TensorFlow, XGBoost, MPI, JAX) |
| TrustyAI Service Operator | Operator | v1.39.0 | Model explainability, fairness monitoring, guardrails, and LLM evaluation |

## Component Relationships

### Dependency Graph

```
odh-dashboard → KServe (manage InferenceServices)
              → Notebooks (create/manage workbenches)
              → Data Science Pipelines (manage pipeline runs)
              → Model Registry (manage registries)
              → MLflow (manage experiments)
              → Feast (manage feature stores)
              → Kubernetes API (all resource operations)

KServe → Istio (VirtualServices, DestinationRules for traffic management)
       → Knative Serving (serverless autoscaling)
       → odh-model-controller (OpenShift Routes, NetworkPolicies, ServiceMonitors)
       → Model Registry (model metadata storage)
       → S3-compatible storage (model artifacts)
       → cert-manager (TLS certificates)

Data Science Pipelines → Argo Workflows (workflow execution)
                       → KServe (model deployment from pipelines)
                       → S3-compatible storage (pipeline artifacts)
                       → MariaDB/MySQL (pipeline metadata)
                       → Model Registry (model storage/retrieval)

Notebooks → Data Science Pipelines (submit jobs via KFP SDK)
          → KServe (interact with inference endpoints)
          → MLflow (log experiments)
          → Feast (feature retrieval)
          → Model Registry (model metadata)
          → S3-compatible storage (data access)

odh-notebook-controller → Gateway API (HTTPRoute creation)
                        → Data Science Pipelines (RBAC provisioning)
                        → kube-rbac-proxy (authentication sidecar)

Feast → PostgreSQL/Redis (feature storage)
      → S3/Object Storage (offline features)
      → Kubeflow Notebooks (configuration injection)

MLflow → PostgreSQL/S3 (backend/artifact storage)
       → data-science-gateway (HTTPRoute for UI access)
       → OpenShift Console (ConsoleLink integration)

Model Registry → PostgreSQL/MySQL (metadata storage)
               → kube-rbac-proxy (authentication)
               → OpenShift Routes (external access)

Kubeflow Trainer → JobSet (distributed training orchestration)
                 → Volcano/Coscheduling (gang scheduling)
                 → S3/storage (dataset/model downloads)
                 → NetworkPolicies (training pod isolation)

Kubeflow Training Operator → JobSet (distributed training)
                            → Volcano/scheduler-plugins (gang scheduling)
                            → HorizontalPodAutoscaler (elastic training)

TrustyAI → KServe InferenceServices (monitoring integration)
         → PostgreSQL/MySQL (metrics storage)
         → Prometheus (metrics export)
         → Kueue (LM evaluation job queueing)

KubeRay → cert-manager (mTLS certificates)
        → Prometheus (metrics collection)
        → Gateway API/Routes (external access)

Llama Stack → Ollama/vLLM (inference providers)
            → HuggingFace Hub (model downloads)
            → NetworkPolicies (access control)

odh-model-controller → KServe (extends functionality)
                     → OpenShift Routes (ingress)
                     → Prometheus Operator (ServiceMonitors)
                     → KEDA (autoscaling)
                     → NVIDIA NGC API (NIM account validation)
```

### Central Components

**Core Infrastructure** (highest dependencies):
- **Kubernetes API Server**: All components depend on K8s API for resource management
- **OpenShift OAuth**: Authentication for dashboard, notebook access, and service endpoints
- **Istio Service Mesh**: Traffic management for KServe, training workloads, and service-to-service communication
- **S3-compatible Storage**: Shared across pipelines, model serving, training, and feature stores

**Platform Services** (many dependents):
- **KServe**: Central model serving platform used by dashboard, pipelines, TrustyAI, and notebooks
- **Data Science Pipelines**: ML workflow orchestration used by notebooks, dashboard, and model deployment
- **ODH Dashboard**: Primary UI for all user interactions with the platform
- **Model Registry**: Model metadata hub used by KServe, pipelines, and notebooks

### Integration Patterns

**Common Patterns**:
1. **CRD-based Control Plane**: All operators expose Kubernetes CRDs for declarative configuration
2. **API Proxy Pattern**: Dashboard backend proxies Kubernetes API calls with user impersonation
3. **Sidecar Injection**: kube-rbac-proxy, OAuth proxy, and storage-initializer sidecars across components
4. **Gateway API Routing**: HTTPRoute resources for external access (notebooks, MLflow, dashboard)
5. **ServiceMonitor Pattern**: Prometheus Operator integration for metrics collection
6. **NetworkPolicy Isolation**: Training jobs, inference services isolated with namespace/pod-level policies
7. **Storage Abstraction**: PVC, S3, PostgreSQL, MySQL backends configurable per component
8. **Gang Scheduling**: Volcano/Coscheduling integration for all-or-nothing pod scheduling in training
9. **Module Federation**: Dashboard uses micro-frontends for specialized features (Model Registry UI, GenAI UI, MaaS UI)

## Platform Network Architecture

### Namespaces

| Namespace | Purpose | Components |
|-----------|---------|------------|
| redhat-ods-applications | Core platform services | odh-dashboard, odh-notebook-controller, odh-model-controller, MLflow, Model Registry, Feast, Llama Stack |
| opendatahub | Alternative namespace for ODH distribution | Same as redhat-ods-applications |
| kserve | Model serving operator | kserve-controller-manager, kserve-webhook-server |
| openshift-ingress | Gateway and routing | data-science-gateway (Gateway API) |
| User namespaces | Per-user/project workspaces | Notebooks, InferenceServices, training jobs, feature stores, model registries |

### External Ingress Points

| Component | Ingress Type | Hosts | Port | Protocol | Encryption | Purpose |
|-----------|--------------|-------|------|----------|------------|---------|
| ODH Dashboard | OpenShift Route / HTTPRoute | Cluster-assigned | 443/TCP | HTTPS | TLS 1.2+ (reencrypt) | Web UI for platform management |
| Notebooks | HTTPRoute (Gateway API) | /notebook/{namespace}/{name} | 443/TCP | HTTPS | TLS 1.2+ (edge) | JupyterLab/RStudio/VS Code access |
| KServe InferenceServices | Istio VirtualService / Route | {isvc}-{namespace}.{domain} | 443/TCP | HTTPS | TLS 1.2+ (SIMPLE/reencrypt) | Model inference endpoints |
| MLflow | HTTPRoute (Gateway API) | /mlflow/* | 443/TCP | HTTPS | TLS 1.3 | Experiment tracking UI and API |
| Model Registry | OpenShift Route | {registry}-rest.{domain} | 443/TCP | HTTPS | TLS 1.2+ (reencrypt) | Model registry REST API |
| Feast Online Server | OpenShift Route | {name}-online-{namespace}.apps.cluster | 443/TCP | HTTPS | TLS 1.2+ (edge) | Feature serving for inference |
| Feast UI | OpenShift Route | {name}-ui-{namespace}.apps.cluster | 443/TCP | HTTPS | TLS 1.2+ (edge) | Feature discovery interface |
| Data Science Pipelines | OpenShift Route | ds-pipeline-{name} | 443/TCP | HTTPS | TLS 1.2+ (reencrypt) | Pipeline API and UI access |
| KubeRay Dashboard | Route / HTTPRoute | {cluster}-{namespace} | 443/TCP | HTTPS | TLS 1.2+ (SIMPLE/edge) | Ray cluster monitoring and management |

### External Egress Dependencies

| Component | Destination | Port | Protocol | Encryption | Purpose |
|-----------|-------------|------|----------|------------|---------|
| KServe | S3/GCS/Azure Blob | 443/TCP | HTTPS | TLS 1.2+ | Model artifact downloads |
| Data Science Pipelines | S3-compatible storage | 443/TCP | HTTPS | TLS 1.2+ | Pipeline artifacts and model storage |
| Notebooks | pypi.org | 443/TCP | HTTPS | TLS 1.2+ | Python package installation |
| Notebooks | quay.io, registry.redhat.io | 443/TCP | HTTPS | TLS 1.2+ | Container image pulls |
| Feast | PostgreSQL/Redis (external) | 5432/6379/TCP | PostgreSQL/Redis | TLS 1.2+ | Feature storage backends |
| Feast | S3/Object Storage | 443/TCP | HTTPS | TLS 1.2+ | Offline feature storage |
| MLflow | PostgreSQL/S3 | 5432/443/TCP | PostgreSQL/HTTPS | TLS 1.2+ | Backend/artifact storage |
| Model Registry | PostgreSQL/MySQL | 5432/3306/TCP | PostgreSQL/MySQL | TLS | Metadata persistence |
| Kubeflow Trainer | HuggingFace Hub | 443/TCP | HTTPS | TLS 1.2+ | Model/dataset downloads for training |
| Llama Stack | Ollama/vLLM | 11434/8000/TCP | HTTP/HTTPS | Optional TLS | LLM inference providers |
| Llama Stack | HuggingFace Hub | 443/TCP | HTTPS | TLS 1.2+ | Model downloads for vLLM |
| odh-model-controller | NVIDIA NGC API | 443/TCP | HTTPS | TLS 1.2+ | NIM account validation |
| TrustyAI | HuggingFace Hub | 443/TCP | HTTPS | TLS 1.2+ | LM evaluation model downloads |
| All components | Image Registries | 443/TCP | HTTPS | TLS 1.2+ | Container image pulls |

### Internal Service Mesh

| Setting | Value | Components Using |
|---------|-------|------------------|
| mTLS Mode | PERMISSIVE (KServe), STRICT (optional) | KServe InferenceServices, training workloads |
| Peer Authentication | Istio default namespace policy | KServe namespaces |
| VirtualServices | Per-InferenceService | KServe predictor/transformer routing |
| DestinationRules | Per-InferenceService | KServe traffic splitting, canary deployments |
| EnvoyFilters | Created by odh-model-controller | Custom Istio configurations for inference services |

## Platform Security

### RBAC Summary

**Key Cluster Roles** (selected high-privilege roles):

| Component | ClusterRole | API Groups | Resources | Verbs |
|-----------|-------------|------------|-----------|-------|
| odh-dashboard | odh-dashboard | kubeflow.org | notebooks | create, delete, get, list, patch, update, watch |
| odh-dashboard | odh-dashboard | serving.kserve.io | inferenceservices | get, list, watch |
| odh-dashboard | odh-dashboard | datasciencecluster.opendatahub.io | datascienceclusters | list, watch, get |
| kserve-controller | kserve-manager-role | serving.kserve.io | inferenceservices, servingruntimes | all verbs |
| kserve-controller | kserve-manager-role | apps | deployments | create, delete, get, list, patch, update, watch |
| kserve-controller | kserve-manager-role | networking.istio.io | virtualservices, destinationrules | all verbs |
| odh-model-controller | odh-model-controller-role | serving.kserve.io | inferenceservices, servingruntimes | get, list, patch, update, watch |
| odh-model-controller | odh-model-controller-role | route.openshift.io | routes | create, delete, get, list, patch, update, watch |
| odh-model-controller | odh-model-controller-role | monitoring.coreos.com | servicemonitors | create, delete, get, list, patch, update, watch |
| data-science-pipelines | manager-role | datasciencepipelinesapplications.opendatahub.io | datasciencepipelinesapplications | all verbs |
| data-science-pipelines | manager-role | argoproj.io | workflows | all verbs |
| odh-notebook-controller | manager-role | gateway.networking.k8s.io | httproutes, referencegrants | create, delete, get, list, patch, update, watch |
| odh-notebook-controller | manager-role | kubeflow.org | notebooks | get, list, watch, patch, update |
| model-registry-operator | manager-role | modelregistry.opendatahub.io | modelregistries | all verbs |
| mlflow-operator | manager-role | mlflow.opendatahub.io | mlflows | all verbs |
| feast-operator | manager-role | feast.dev | featurestores | all verbs |
| kuberay-operator | kuberay-operator | ray.io | rayclusters, rayjobs, rayservices | all verbs |
| trainer | kubeflow-trainer-controller-manager | trainer.kubeflow.org | trainjobs, trainingruntimes | all verbs |
| trainer | kubeflow-trainer-controller-manager | jobset.x-k8s.io | jobsets | create, get, list, patch, update, watch |
| training-operator | training-operator | kubeflow.org | pytorchjobs, tfjobs, xgboostjobs, mpijobs | all verbs |
| trustyai-operator | manager-role | trustyai.opendatahub.io | trustyaiservices, lmevaljobs | all verbs |
| trustyai-operator | manager-role | serving.kserve.io | inferenceservices | get, list, patch, update, watch |

### Secrets Inventory

| Component | Secret Name | Type | Purpose |
|-----------|-------------|------|---------|
| odh-dashboard | dashboard-proxy-tls | kubernetes.io/tls | OAuth proxy TLS certificate |
| KServe | kserve-webhook-server-cert | kubernetes.io/tls | Webhook server certificate |
| KServe | storage-config | Opaque | Default S3/GCS credentials for model downloads |
| Data Science Pipelines | ds-pipelines-proxy-tls-{name} | kubernetes.io/tls | API server OAuth proxy TLS |
| Data Science Pipelines | {custom-db-secret} | Opaque | Database credentials (user or auto-generated) |
| Data Science Pipelines | {custom-storage-secret} | Opaque | S3 access/secret keys |
| Notebooks | {workbench}-oauth-config | Opaque | OAuth proxy configuration |
| Notebooks | {workbench}-tls | kubernetes.io/tls | HTTPS route TLS certificate |
| odh-notebook-controller | {notebook-name}-tls-proxy-serving-cert | kubernetes.io/tls | kube-rbac-proxy TLS |
| odh-notebook-controller | {notebook-name}-{dspa-name}-token | Opaque | Pipeline API token |
| Model Registry | {registry-name}-kube-rbac-proxy | kubernetes.io/tls | kube-rbac-proxy TLS |
| Model Registry | {db-credential-secret} | Opaque | Database password |
| MLflow | mlflow-tls | kubernetes.io/tls | MLflow server HTTPS endpoint |
| MLflow | mlflow-db-credentials | Opaque | Database URIs with credentials |
| Feast | {name}-client-tls | kubernetes.io/tls | Client mTLS certificates |
| Feast | {name}-oidc | Opaque | OIDC credentials |
| Feast | {name}-db-secret | Opaque | PostgreSQL credentials |
| KubeRay | {cluster}-tls-cert | kubernetes.io/tls | Ray cluster mTLS certificates |
| Llama Stack | hf-token-secret | Opaque | HuggingFace API token for vLLM |
| Trainer | kubeflow-trainer-webhook-cert | kubernetes.io/tls | Webhook server certificate |
| Training Operator | training-operator-webhook-cert | kubernetes.io/tls | Webhook server certificate |
| TrustyAI | {trustyai-name}-db-credentials | Opaque | Database connection credentials |
| odh-model-controller | [NGC API Key Secrets] | Opaque | NVIDIA NGC API keys for NIM |

### Authentication Mechanisms

| Pattern | Components Using | Enforcement Point |
|---------|------------------|-------------------|
| Bearer Tokens (JWT) - OpenShift OAuth | odh-dashboard, notebooks, MLflow, Model Registry | kube-rbac-proxy, OAuth proxy sidecars |
| Bearer Tokens (JWT) - Kubernetes ServiceAccount | All operators, Data Science Pipelines API | Kubernetes API Server TokenReview |
| mTLS Client Certificates | KServe (optional), Feast (optional), KubeRay (optional) | Istio PeerAuthentication, service mesh |
| AWS IAM / Access Keys | KServe, Data Science Pipelines, Feast, training jobs | AWS SDK, S3 API |
| Database Username/Password | Model Registry, MLflow, Feast, Data Science Pipelines | PostgreSQL/MySQL authentication |
| OIDC (OpenShift OAuth) | Feast (optional), dashboard | OIDC token validation |
| SubjectAccessReview (RBAC) | kube-rbac-proxy endpoints, MLflow kubernetes-auth | Kubernetes RBAC authorization |
| NGC API Keys | odh-model-controller (NVIDIA NIM) | NVIDIA NGC API validation |

## Platform APIs

### Custom Resource Definitions

| Component | API Group | Kind | Scope | Purpose |
|-----------|-----------|------|-------|---------|
| Data Science Pipelines | datasciencepipelinesapplications.opendatahub.io | DataSciencePipelinesApplication | Namespaced | Deploy complete pipeline stack |
| Data Science Pipelines | pipelines.kubeflow.org | Pipeline, PipelineVersion | Namespaced | Pipeline definitions |
| Data Science Pipelines | argoproj.io | Workflow | Namespaced | Pipeline execution (Argo) |
| Feast | feast.dev | FeatureStore | Namespaced | Feature store deployment |
| KServe | serving.kserve.io | InferenceService | Namespaced | Model serving deployment |
| KServe | serving.kserve.io | ServingRuntime, ClusterServingRuntime | Namespaced/Cluster | Serving runtime templates |
| KServe | serving.kserve.io | InferenceGraph | Namespaced | Multi-model inference pipelines |
| KServe | serving.kserve.io | LLMInferenceService | Namespaced | LLM-specific inference |
| Notebooks | kubeflow.org | Notebook | Namespaced | Jupyter/RStudio/VS Code instances |
| odh-notebook-controller | gateway.networking.k8s.io | HTTPRoute, ReferenceGrant | Namespaced | Gateway API routing |
| Model Registry | modelregistry.opendatahub.io | ModelRegistry | Namespaced | Model registry instances |
| MLflow | mlflow.opendatahub.io | MLflow | Cluster | MLflow server deployments |
| KubeRay | ray.io | RayCluster, RayJob, RayService | Namespaced | Ray cluster management |
| Llama Stack | llamastack.io | LlamaStackDistribution | Namespaced | Llama Stack servers |
| odh-model-controller | nim.opendatahub.io | Account | Namespaced | NVIDIA NIM accounts |
| Trainer | trainer.kubeflow.org | TrainJob | Namespaced | Training jobs |
| Trainer | trainer.kubeflow.org | TrainingRuntime, ClusterTrainingRuntime | Namespaced/Cluster | Training runtime templates |
| Training Operator | kubeflow.org | PyTorchJob, TFJob, XGBoostJob, MPIJob, JAXJob, PaddleJob | Namespaced | Framework-specific training jobs |
| TrustyAI | trustyai.opendatahub.io | TrustyAIService | Namespaced | Explainability and monitoring |
| TrustyAI | trustyai.opendatahub.io | LMEvalJob | Namespaced | LLM evaluation jobs |
| TrustyAI | trustyai.opendatahub.io | GuardrailsOrchestrator | Namespaced | LLM guardrails |
| Dashboard | dashboard.opendatahub.io | OdhApplication, OdhDocument | Namespaced | Dashboard apps and docs |
| Dashboard | opendatahub.io | OdhDashboardConfig | Namespaced | Dashboard configuration |

### Public HTTP Endpoints

**User-facing APIs and UIs**:

| Component | Path | Method | Port | Protocol | Auth | Purpose |
|-----------|------|--------|------|----------|------|---------|
| ODH Dashboard | / | GET | 8443/TCP | HTTPS | OAuth | Dashboard web UI |
| ODH Dashboard | /api/* | GET/POST/PUT/PATCH | 8443/TCP | HTTPS | OAuth + RBAC | Backend API |
| Notebooks | /notebook/{ns}/{name}/* | ALL | 8888/TCP | HTTP (internal) | OAuth proxy | Jupyter/RStudio/VS Code |
| KServe | /v1/models/:name:predict | POST | 8000/TCP | HTTP/HTTPS | Bearer/None | Model prediction |
| KServe | /v2/models/:name/infer | POST | 8000/TCP | HTTP/HTTPS | Bearer/None | KServe v2 inference |
| KServe | /openai/v1/completions | POST | 8000/TCP | HTTP/HTTPS | Bearer | OpenAI-compatible LLM API |
| Data Science Pipelines | /apis/v2beta1/* | GET/POST/DELETE | 8888/TCP | HTTP | Bearer Token | Pipeline API |
| MLflow | /api/2.0/* | ALL | 8443/TCP | HTTPS | Bearer (K8s) | MLflow REST API |
| Model Registry | /api/model_registry/v1alpha3/* | ALL | 8080/8443/TCP | HTTP/HTTPS | Bearer/None | Model registry API |
| Feast Online | /get-online-features | POST | 6566/TCP | HTTP | Bearer/mTLS | Real-time feature serving |
| Feast Offline | /get-historical-features | POST | 8815/TCP | HTTP | Bearer/mTLS | Historical feature retrieval |
| Feast Registry | /registry | ALL | 6572/TCP | HTTP | Bearer/mTLS | Registry operations |
| Llama Stack | / | GET/POST | 8321/TCP | HTTP/HTTPS | None/Custom | Llama Stack API |

## Data Flows

### Key Platform Workflows

#### Workflow 1: Model Training to Deployment

| Step | Component | Action | Next Component |
|------|-----------|--------|----------------|
| 1 | Notebook | User develops/trains model | Saves to S3 or Model Registry |
| 2 | Model Registry | Registers model metadata | - |
| 3 | Dashboard UI | User creates InferenceService | Submits to KServe |
| 4 | KServe | Deploys model with runtime | Creates predictor pods |
| 5 | odh-model-controller | Creates Route, NetworkPolicy, ServiceMonitor | - |
| 6 | TrustyAI (optional) | Monitors inference for explainability | Logs to PostgreSQL |

#### Workflow 2: Pipeline-driven Model Deployment

| Step | Component | Action | Next Component |
|------|-----------|--------|----------------|
| 1 | Notebook (Elyra) | User designs pipeline | Submits to Data Science Pipelines |
| 2 | Data Science Pipelines | Orchestrates workflow | Creates Argo Workflow |
| 3 | Argo Workflow | Executes training steps | Workflow pods run |
| 4 | Pipeline Step | Uploads model to S3 | Registers with Model Registry |
| 5 | Pipeline Step | Creates InferenceService CR | KServe deploys model |
| 6 | Model Registry | Stores metadata and lineage | - |

#### Workflow 3: Feature Engineering to Inference

| Step | Component | Action | Next Component |
|------|-----------|--------|----------------|
| 1 | Notebook | Engineer features | Define FeatureView in Feast |
| 2 | Feast Registry | Registers feature definitions | - |
| 3 | Feast Materialization | Copies offline → online store | CronJob runs |
| 4 | Training Job | Fetches historical features | Feast Offline Server |
| 5 | Model Training | Trains with features | Saves to S3 |
| 6 | InferenceService | Fetches online features | Feast Online Server |
| 7 | Prediction | Returns result with fresh features | Client |

#### Workflow 4: Distributed Training with Tracking

| Step | Component | Action | Next Component |
|------|-----------|--------|----------------|
| 1 | User | Creates TrainJob CR | Kubeflow Trainer |
| 2 | Trainer | Downloads dataset/model | HuggingFace Hub, S3 |
| 3 | Trainer | Creates JobSet | Multi-node training pods |
| 4 | Training Pods | Execute distributed training | Inter-pod NCCL communication |
| 5 | Trainer (RHOAI) | Polls metrics endpoint | Updates progression annotation |
| 6 | Training Pods | Log to MLflow (optional) | MLflow tracking server |
| 7 | Training Pods | Save model to S3 | Model Registry registers |

#### Workflow 5: End-to-End LLM Fine-tuning

| Step | Component | Action | Next Component |
|------|-----------|--------|----------------|
| 1 | Notebook | Prepare training data | Upload to S3 |
| 2 | Dashboard UI | Submit TrainJob for LLM | Kubeflow Trainer |
| 3 | Trainer | Download base LLM from HF | vLLM-compatible format |
| 4 | Distributed Training | Fine-tune with LoRA/QLoRA | GPU pods (CUDA/ROCm) |
| 5 | Training Completion | Upload fine-tuned model | S3, Model Registry |
| 6 | Dashboard UI | Deploy via NVIDIA NIM | odh-model-controller + KServe |
| 7 | KServe | Serve fine-tuned LLM | vLLM runtime with OpenAI API |
| 8 | TrustyAI | Evaluate with LMEvalJob | Run benchmarks (MMLU, etc.) |
| 9 | TrustyAI Guardrails | Add safety guardrails | GuardrailsOrchestrator |

## Deployment Architecture

### Deployment Topology

**Operator Namespace** (redhat-ods-applications / opendatahub):
- odh-dashboard (2 replicas with anti-affinity)
- odh-notebook-controller (1 replica)
- odh-model-controller (1 replica)
- data-science-pipelines-operator (1 replica)
- feast-operator (1 replica)
- mlflow-operator (1 replica)
- model-registry-operator (1 replica)
- kuberay-operator (1 replica)
- llama-stack-operator (1 replica)
- kubeflow-trainer (1 replica)
- kubeflow-training-operator (1 replica)
- trustyai-service-operator (1 replica)

**KServe Namespace** (kserve):
- kserve-controller-manager (1 replica with leader election)
- kserve-webhook-server (webhooks via cert-manager)

**User Namespaces** (per-user or per-project):
- Notebook StatefulSets (workbenches)
- InferenceService Deployments (model serving)
- TrainJob pods (distributed training)
- Data Science Pipelines instances (per-namespace DSPA)
- FeatureStore instances (per-namespace Feast)
- MLflow instances (shared or per-namespace)
- Model Registry instances (shared or per-namespace)
- TrustyAI Service instances (per-namespace monitoring)

### Resource Requirements

**Operator Resource Defaults** (representative sample):

| Component | CPU Request | CPU Limit | Memory Request | Memory Limit |
|-----------|-------------|-----------|----------------|--------------|
| odh-dashboard | 500m | 1000m | 1Gi | 2Gi |
| kserve-controller | 100m | 500m | 300Mi | 1Gi |
| data-science-pipelines-operator | 10m | 500m | 64Mi | 2Gi |
| feast-operator | 10m | 1000m | 64Mi | 256Mi |
| kuberay-operator | 100m | 100m | 512Mi | 512Mi |
| trainer | 10m | 500m | 256Mi | 1Gi |
| training-operator | 10m | 500m | 64Mi | 2Gi |

**User Workload Defaults**:
- Notebook: 1 CPU, 8Gi memory (configurable per workbench)
- InferenceService: Varies by model (CPU/GPU, 1Gi-16Gi+ memory)
- Training Job: Multi-node with GPU (user-specified resources)
- Pipeline Pods: Varies per step (user-defined in pipeline spec)

## Version-Specific Changes (3.3.0)

| Component | Changes |
|-----------|---------|
| KServe | - Handle missing LeaderWorkerSet CRD gracefully<br>- RHOAI 3.3 Konflux pipeline<br>- Storage initializer multi-arch fixes (ppc64le, s390x)<br>- Preserve auth proxy containers during 2.x→3.x upgrade<br>- InferencePool v1 API migration<br>- vLLM block-size parameter updates |
| Data Science Pipelines | - Dependency updates for UBI9 base images<br>- Konflux pipeline synchronization<br>- Pod-to-pod TLS optional support |
| Feast | - Release 0.59.0 with progress bar in CLI<br>- dbt integration for importing models as FeatureViews<br>- Lambda materialization engine improvements<br>- Operator includes full OIDC secret in repo config |
| Notebooks | - Package installation retry loop (CVE fixes)<br>- Upgrade wheels package (CVE-2026-24049)<br>- ONNX version update to 1.20.1 for ppc64le<br>- Migration to Konflux CI/CD for builds<br>- Multi-architecture support (ppc64le, aarch64) |
| ODH Dashboard | - Node.js 22 base image updates<br>- Konflux pipeline synchronization<br>- Security scanning and SBOM integration (sealights variant)<br>- Gateway API HTTPRoute support |
| Model Registry | - NetworkPolicy for PostgreSQL database access control<br>- PostgreSQL secret initialization improvements<br>- Go 1.25.7 upgrade<br>- gRPC field validation cleanup (gRPC deprecated) |
| MLflow | - Tracing APIs support<br>- UBI9 base image updates<br>- Dependency security patches |
| Kubeflow Trainer | - Upstream v2.1.0 tracking<br>- NetworkPolicy for TrainJobs (RHOAI extension)<br>- Progression tracking feature (metrics polling)<br>- Multiple runtime additions (CUDA, ROCm variants)<br>- Remove torch28, add new CUDA/ROCm runtimes |
| Training Operator | - CVE-2026-2353: Restrict secrets RBAC to namespace scope<br>- CVE-2025-61726: Upgrade to Go 1.25<br>- UBI base image updates |
| TrustyAI | - urllib3 security vulnerability fixes (upgrade to 2.6.3)<br>- GuardrailsOrchestrator status logic updates |
| KubeRay | - Update to v1.4.4<br>- Authentication ready condition handling fixes<br>- Generation issue fixes in cluster refetch |
| Llama Stack | - NetworkPolicy enabled by default in RHOAI 3.3<br>- Image override support for independent patching<br>- CA bundle volume conflict fixes during upgrade<br>- Llama Stack v0.4.2, Operator v0.6.0 |
| odh-model-controller | - Spyre ppc64le template support<br>- Downward API for MAAS_NAMESPACE<br>- UBI minimal base image updates<br>- RAG ppc64le Spyre template fixes |

## Platform Maturity

- **Total Components**: 14 core components
- **Operator-based Components**: 13 (93%)
- **Service Mesh Coverage**: KServe, training workloads (Istio integration available)
- **mTLS Enforcement**: PERMISSIVE mode (KServe), optional for other components
- **CRD API Versions**: Predominantly v1, some v1alpha1/v1beta1 APIs
- **Multi-architecture Support**: x86_64 (all), aarch64 (notebooks, training), ppc64le (notebooks, training, Spyre), s390x (notebooks, storage-initializer)
- **GPU Support**: NVIDIA CUDA 12.6/12.8/13.0, AMD ROCm 6.2/6.3/6.4, Intel Gaudi (via runtimes)
- **External Storage**: S3, GCS, Azure Blob, PostgreSQL, MySQL, Redis
- **Authentication**: OpenShift OAuth, Kubernetes RBAC, OIDC, mTLS
- **Autoscaling**: Knative Serving (KServe), KEDA (KServe raw mode), HPA (training elastic)
- **Gang Scheduling**: Volcano, scheduler-plugins (training workloads)
- **CI/CD**: Konflux pipelines (Tekton) with security scanning, SBOM generation, multi-arch builds

## Next Steps for Documentation

Based on this platform architecture analysis, recommended next steps:

1. **Generate Architecture Diagrams**:
   - Platform component dependency graph (Graphviz/Mermaid)
   - Network flow diagrams for each key workflow
   - Deployment topology diagram showing namespace organization
   - Security architecture diagram (authentication/authorization flows)

2. **Update Architecture Decision Records (ADRs)**:
   - Document decisions around Gateway API adoption vs. OpenShift Routes
   - Module federation strategy for dashboard micro-frontends
   - Multi-database support patterns (PostgreSQL, MySQL, SQLite)
   - Gang scheduling integration choices (Volcano vs. scheduler-plugins)
   - Storage abstraction patterns across components

3. **Create User-facing Documentation**:
   - Getting Started guides for each key workflow
   - Best practices for production deployments (external databases, S3, GPU scheduling)
   - Multi-tenancy configuration guide
   - Performance tuning recommendations
   - Disaster recovery and backup procedures

4. **Security Architecture Review (SAR) Documentation**:
   - Network policy templates for security zones
   - TLS/mTLS configuration matrix
   - RBAC privilege escalation analysis
   - Secrets management best practices
   - Compliance mapping (FIPS, SOC2, etc.)

5. **Operator Integration Guide**:
   - API cross-reference for inter-component communication
   - Event-driven integration patterns
   - Custom resource ownership and lifecycle management
   - Monitoring and alerting configuration

6. **Upgrade and Migration Guide**:
   - RHOAI 2.x to 3.x migration procedures
   - Component version compatibility matrix
   - Breaking changes and deprecations
   - Rollback procedures

7. **Performance Benchmarks**:
   - Inference latency benchmarks per serving runtime
   - Training scalability tests (multi-node, multi-GPU)
   - Pipeline throughput measurements
   - Resource utilization baselines

8. **Troubleshooting Playbooks**:
   - Component-specific debug procedures
   - Common failure modes and resolutions
   - Log aggregation and analysis
   - Network connectivity troubleshooting
