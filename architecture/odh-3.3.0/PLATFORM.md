# Platform: Open Data Hub 3.3.0

## Metadata
- **Distribution**: Open Data Hub (ODH)
- **Version**: 3.3.0
- **Release Date**: 2025-01
- **Base Platform**: OpenShift Container Platform 4.12+ / Kubernetes 1.25+
- **Components Analyzed**: 17
- **API Versions**: v1, v1alpha1, v1beta1, v1beta2

## Platform Overview

Open Data Hub 3.3.0 is a comprehensive cloud-native AI/ML platform for OpenShift that provides end-to-end data science capabilities from development to production. The platform integrates 17 specialized components orchestrated by a central operator to deliver workbench environments, distributed training, model serving, experiment tracking, and MLOps tooling. ODH enables data scientists to work with popular frameworks (PyTorch, TensorFlow, JAX) on GPU-accelerated infrastructure while platform engineers manage deployments declaratively through Kubernetes custom resources.

The platform architecture follows a layered approach with the ODH Operator as the central control plane that manages component deployment and lifecycle. Components communicate through Kubernetes APIs, REST endpoints, and gRPC services with security enforced via OAuth proxies, service mesh mTLS, and RBAC. Data scientists interact through the ODH Dashboard web UI or directly via notebook environments, while workloads scale from single-node development to multi-node distributed training and high-throughput model serving.

ODH 3.3.0 emphasizes open-source AI/ML tooling with integration points for feature stores (Feast), experiment tracking (MLflow), model registry, data pipelines (Argo Workflows), and distributed computing (Ray, Spark). The platform supports both generative AI (LLM serving with vLLM, guardrails, evaluation) and traditional ML (scikit-learn, XGBoost) workloads with enterprise features including network policies, TLS encryption, and multi-tenancy.

## Component Inventory

| Component | Type | Version | Purpose |
|-----------|------|---------|---------|
| opendatahub-operator | Control Plane Operator | 3.3.0 | Central operator managing all platform components via DataScienceCluster CRD |
| odh-dashboard | Web Application (React/Node.js) | v3.4.0EA1 | Unified web UI for platform management and user workflows |
| kserve | Model Serving Platform | 0.17.0-rc0 | Standardized multi-framework model inference with autoscaling and GPU support |
| odh-model-controller | KServe Extension Controller | $TAG_NAME-45-g3902d61 | OpenShift integrations for KServe (Routes, NIM, LLM services) |
| model-registry-operator | Operator | f8a6863 | Deploys Model Registry instances for model versioning and lineage |
| data-science-pipelines-operator | Operator | 0.0.1 | Kubeflow Pipelines integration for ML workflow orchestration |
| notebooks | Container Images | 1.42.0-46 | Pre-configured workbench images (Jupyter, VSCode, RStudio) with ML frameworks |
| kubeflow (notebook-controller) | Operator | v1.11.0-alpha.0 | Manages Jupyter notebook StatefulSet lifecycle |
| training-operator | Operator | bfceb079 | Distributed training for PyTorch, TensorFlow, MPI, JAX, XGBoost |
| trainer | Operator | 6b4be8aa | Next-gen training operator (v2) for LLM fine-tuning with JobSet |
| kuberay | Operator | 1.4.4 | Ray distributed computing for parallel processing and ML workloads |
| mlflow-operator | Operator | 33c744b | Deploys MLflow servers for experiment tracking and model registry |
| feast | Operator | 0.45.0 | Feature store for ML feature management and serving |
| trustyai-service-operator | Operator | 1.39.0 | AI governance: explainability, fairness monitoring, LLM evaluation |
| spark-operator | Operator | $(shell) | Apache Spark on Kubernetes for big data processing |
| llama-stack-k8s-operator | Operator | v0.2.24 | Llama Stack integration for LLM development and deployment |
| mlflow (standalone) | Application | 2.x | MLflow tracking server (managed by mlflow-operator) |

## Component Relationships

### Dependency Graph

```
Platform Control Plane:
└─ opendatahub-operator (manages all components via DataScienceCluster)
   ├─ Component Operators (deploy and manage their respective services)
   └─ Service Controllers (Auth, Gateway, Monitoring)

User Interface Layer:
└─ odh-dashboard
   ├─ Reads: DataScienceCluster, DSCInitialization (platform status)
   ├─ Manages: Notebooks, ModelRegistry, InferenceService CRs
   └─ Integrates: KServe, Feast, TrustyAI, LlamaStack, MLflow

Development Workbenches:
└─ kubeflow (notebook-controller)
   ├─ Creates: StatefulSets for notebook pods
   ├─ Uses: notebooks (container images)
   └─ Integrates:
      ├─ data-science-pipelines (pipeline execution from notebooks)
      ├─ model-registry (model registration)
      ├─ mlflow (experiment tracking)
      └─ kserve (model deployment)

Model Serving:
└─ kserve
   ├─ Extended by: odh-model-controller (OpenShift Routes, NIM, LLM services)
   ├─ Integrates:
   │  ├─ model-registry (model metadata and versioning)
   │  ├─ trustyai-service-operator (model monitoring and explainability)
   │  └─ Service Mesh (mTLS, AuthZ policies)
   └─ Backends: vLLM, TensorFlow Serving, Triton, TorchServe, MLServer

Training & Distributed Computing:
├─ training-operator (PyTorch, TensorFlow, MPI, JAX, XGBoost)
│  └─ Uses: notebooks images as training containers
├─ trainer (v2 - LLM fine-tuning with DeepSpeed, Megatron)
│  └─ Uses: JobSet for distributed pod management
├─ kuberay (Ray clusters)
│  └─ Integrates: notebooks, data-science-pipelines
└─ spark-operator (Apache Spark)
   └─ Integrates: data-science-pipelines, S3 storage

ML Workflows & Data:
├─ data-science-pipelines-operator
│  ├─ Orchestrates: training jobs, data processing, model deployment
│  ├─ Integrates: training-operator, kserve, model-registry
│  └─ Uses: Argo Workflows engine
└─ feast
   └─ Serves: features to training jobs and inference services

Model Management:
├─ model-registry-operator
│  ├─ Used by: kserve (link InferenceServices to models)
│  ├─ Used by: data-science-pipelines (track pipeline models)
│  ├─ Used by: notebooks (register trained models)
│  └─ Integrates: trustyai-service-operator (model metadata)
└─ mlflow-operator
   ├─ Used by: notebooks (experiment logging)
   ├─ Used by: training-operator, trainer (training metrics)
   └─ Used by: trustyai-service-operator (LLM eval experiment tracking)

AI Governance & Evaluation:
└─ trustyai-service-operator
   ├─ Monitors: kserve InferenceServices (fairness, drift)
   ├─ Evaluates: LLMs via EvalHub (lm-eval-harness, MLflow)
   └─ Provides: Explainability (SHAP, LIME)

LLM Tools:
└─ llama-stack-k8s-operator
   └─ Integrates: kserve (model serving), notebooks (development)
```

### Central Components (Highest Dependencies)

1. **opendatahub-operator** - Central control plane for all components
2. **kserve** - Model serving platform used by pipelines, registry, monitoring
3. **model-registry-operator** - Model versioning used by serving, pipelines, notebooks
4. **data-science-pipelines-operator** - Workflow orchestration integrating training, serving, registry
5. **odh-dashboard** - User interface for all platform components

### Integration Patterns

| Pattern | Components | Purpose |
|---------|-----------|---------|
| CRD Creation | Dashboard → Notebooks, KServe, ModelRegistry | User-initiated resource creation |
| CRD Watching | Dashboard, Pipelines, TrustyAI → Component CRs | Status monitoring and UI updates |
| REST API Calls | Notebooks → Model Registry, MLflow, KServe | Programmatic interaction from notebooks |
| Operator Chaining | ODH Operator → Component Operators | Hierarchical deployment management |
| Service Mesh | KServe, Model Registry → Istio | mTLS, AuthZ, traffic routing |

## Platform Network Architecture

### Namespaces

| Namespace | Purpose | Components |
|-----------|---------|------------|
| opendatahub | Platform control plane | opendatahub-operator, odh-dashboard, component operators |
| istio-system | Service mesh control plane | Istio, Gateway controllers |
| knative-serving | Serverless platform | Knative Serving (for KServe autoscaling) |
| cert-manager | Certificate management | cert-manager operator |
| <user-namespaces> | Data science workloads | Notebooks, InferenceServices, Pipelines, Training jobs |

### External Ingress Points

| Component | Ingress Type | Protocol | Encryption | Purpose |
|-----------|--------------|----------|------------|---------|
| odh-dashboard | OpenShift Route | HTTPS (443) | TLS 1.2+ (Reencrypt) | Dashboard web UI |
| kserve | Istio VirtualService / Route | HTTPS (443) | TLS 1.2+ | Model inference endpoints |
| model-registry | Route / Gateway HTTPRoute | HTTPS (443) | TLS 1.2+ | Model registry REST API |
| mlflow | Gateway HTTPRoute | HTTPS (443) | TLS 1.2+ | MLflow tracking UI and API |
| data-science-pipelines | OpenShift Route | HTTPS (443) | TLS 1.2+ | Pipeline API and UI |

### External Egress Dependencies

| Destination | Protocol | Purpose | Used By |
|-------------|----------|---------|---------|
| S3-compatible storage | HTTPS (443) | Model artifacts, data, pipeline artifacts | kserve, notebooks, pipelines |
| PyPI / pip index | HTTPS (443) | Python packages | notebooks, training-operator |
| Container Registry | HTTPS (443) | Pull images | All components |
| HuggingFace Hub | HTTPS (443) | LLM models | trustyai, notebooks |
| PostgreSQL/MySQL | PostgreSQL/MySQL (5432/3306) | Metadata persistence | model-registry, mlflow, pipelines |
| Kubernetes API | HTTPS (6443) | Resource management | All operators |

## Platform Security

### Authentication Mechanisms

| Pattern | Components | Enforcement |
|---------|-----------|-------------|
| OAuth Bearer Tokens (Kubernetes) | dashboard, model-registry, mlflow | kube-rbac-proxy / OAuth Proxy |
| mTLS Client Certificates | kserve (service mesh), kuberay | Istio / Service |
| Kubernetes ServiceAccount Tokens | All operators, pods | Kubernetes RBAC |
| AWS IAM Credentials | kserve, notebooks, pipelines | S3 SDK |
| API Keys | odh-model-controller (NGC), trustyai (HF) | External APIs |

### RBAC Roles (Top-Level)

| Component | ClusterRole Permissions | Purpose |
|-----------|------------------------|---------|
| opendatahub-operator | DataScienceCluster, Component CRs, Deployments | Platform orchestration |
| kserve | InferenceService, ServingRuntime, Pods, VirtualServices | Model serving |
| notebook-controller | Notebook CRs, StatefulSets | Workbench management |
| data-science-pipelines | DSPA CRs, Argo Workflows, Deployments | Pipeline orchestration |
| training-operator | PyTorchJob, TFJob, MPIJob, etc. | Distributed training |

### Secrets Management

| Purpose | Secret Type | Components |
|---------|-------------|------------|
| Webhook TLS | kubernetes.io/tls | All operators (cert-manager) |
| S3 Access | Opaque | kserve, notebooks, pipelines |
| Database Credentials | Opaque | model-registry, mlflow, pipelines |
| OAuth Certificates | kubernetes.io/tls | dashboard, model-registry, mlflow |

## Platform APIs

### Custom Resource Definitions (60+ CRDs)

**Platform Orchestration**:
- datasciencecluster.opendatahub.io (DataScienceCluster, DSCInitialization)
- components.platform.opendatahub.io (Dashboard, Kserve, Ray, etc.)
- services.platform.opendatahub.io (Auth, GatewayConfig, Monitoring)

**Development**:
- kubeflow.org (Notebook)
- dashboard.opendatahub.io (OdhApplication, OdhDocument)

**Model Serving**:
- serving.kserve.io (InferenceService, ServingRuntime, InferenceGraph, LLMInferenceService)
- nim.opendatahub.io (Account)

**Model Management**:
- modelregistry.opendatahub.io (ModelRegistry)
- mlflow.opendatahub.io (MLflow, MLflowConfig)

**Training**:
- kubeflow.org (PyTorchJob, TFJob, MPIJob, JAXJob, XGBoostJob)
- trainer.kubeflow.org (TrainJob, TrainingRuntime)
- ray.io (RayCluster, RayJob, RayService)
- sparkoperator.k8s.io (SparkApplication, ScheduledSparkApplication)

**ML Workflows**:
- datasciencepipelinesapplications.opendatahub.io (DataSciencePipelinesApplication)
- argoproj.io (Workflow, WorkflowTemplate, CronWorkflow)
- pipelines.kubeflow.org (Pipeline, PipelineVersion)

**Data & Governance**:
- feast.dev (FeatureStore)
- trustyai.opendatahub.io (TrustyAIService, EvalHub, LMEvalJob, GuardrailsOrchestrator)

## Key Data Flows

### Workflow 1: Model Development to Production

1. User accesses ODH Dashboard
2. Dashboard creates Notebook CR → notebook-controller deploys workbench
3. User develops model in notebook → logs to MLflow, reads from Feast
4. User registers model → model-registry
5. User creates InferenceService → kserve deploys model
6. odh-model-controller creates Route → exposes inference endpoint
7. trustyai monitors inferences → fairness/drift detection
8. External client sends requests → kserve predictor

### Workflow 2: Automated ML Pipeline

1. User submits pipeline → data-science-pipelines API
2. Creates Argo Workflow → executes data prep, training, deployment steps
3. Training step → training-operator or trainer
4. Logs metrics → MLflow
5. Registers model → model-registry
6. Deploys model → kserve

### Workflow 3: Distributed LLM Fine-tuning

1. User creates TrainJob CR → trainer
2. Trainer creates JobSet → distributed training pods
3. Pods download LLM → HuggingFace, load data from S3
4. Distributed training → DeepSpeed/Megatron
5. Save checkpoints → S3, log metrics → MLflow
6. Register fine-tuned model → model-registry
7. Deploy model → kserve (LLMInferenceService)

## Platform Maturity

### Component Statistics
- **Total Components**: 17
- **Operators**: 14 (82%)
- **Applications**: 3 (18%)
- **CRDs**: 60+
- **API Versions**: v1 (Stable), v1beta1/v1beta2 (Beta), v1alpha1 (Alpha)

### Security Posture
- **TLS Encryption**: All external endpoints (TLS 1.2+)
- **Service Mesh**: Available (Istio, Knative)
- **mTLS Support**: Configurable (PERMISSIVE/STRICT)
- **Authentication**: OAuth, mTLS, Bearer tokens, API keys
- **RBAC**: Comprehensive cluster/namespace policies
- **NetworkPolicy**: Per-component ingress/egress
- **FIPS Compliance**: crypto/rand usage

### Platform Capabilities

| Capability | Components | Maturity |
|------------|-----------|----------|
| Workbench Development | notebooks, kubeflow, dashboard | Stable |
| Model Serving | kserve, odh-model-controller | Stable |
| Model Management | model-registry, mlflow | Beta |
| ML Pipelines | data-science-pipelines | Stable |
| Distributed Training | training-operator, trainer, kuberay | Stable/Beta |
| Big Data | spark-operator | Stable |
| Feature Store | feast | Beta |
| AI Governance | trustyai | Alpha/Beta |
| LLM Tools | llama-stack, odh-model-controller | Alpha |

## Version 3.3.0 Highlights

- **Updated Components**: All 17 components updated with latest versions
- **New Features**: LLM fine-tuning (Trainer v2), NIM integration, EvalHub for LLM evaluation
- **Security**: FIPS compliance improvements, NetworkPolicy hardening
- **GPU Support**: Enhanced CUDA/ROCm support for training and inference
- **Platform**: Go 1.25.7 upgrade, v2 APIs for DataScienceCluster

## Next Steps

1. **Generate Diagrams**: Component dependencies, network topology, data flows, security architecture
2. **User Guides**: Getting started, workflows, best practices
3. **ADRs**: Component selection rationale, multi-tenancy model, GPU allocation
4. **Security Docs**: SAR materials, network segmentation, RBAC guidelines
5. **Operations**: Installation, troubleshooting, monitoring, DR
6. **Performance**: Resource sizing, GPU optimization, autoscaling policies
