# Platform: Red Hat OpenShift AI 2.25

## Metadata
- **Distribution**: RHOAI (Red Hat OpenShift AI)
- **Version**: 2.25
- **Release Date**: 2025-03
- **Base Platform**: OpenShift Container Platform 4.11+
- **Components Analyzed**: 16
- **Analysis Date**: 2026-03-15

## Platform Overview

Red Hat OpenShift AI (RHOAI) 2.25 is an enterprise AI/ML platform that provides a comprehensive, integrated environment for data scientists and ML engineers to develop, train, and deploy machine learning models at scale on OpenShift. The platform combines 16 major components orchestrated by the RHOAI Operator, delivering capabilities spanning the complete ML lifecycle: interactive development environments (Jupyter notebooks, VS Code, RStudio), distributed training (PyTorch, TensorFlow, XGBoost, MPI), model serving (KServe, ModelMesh), pipeline orchestration (Data Science Pipelines), distributed computing (Ray, CodeFlare), model management (Model Registry), explainability (TrustyAI), and feature engineering (Feast).

Built on Kubernetes/OpenShift with optional Istio service mesh integration, RHOAI provides enterprise-grade security, multi-tenancy, and operational features including OAuth authentication, RBAC, service mesh encryption, automated monitoring with Prometheus, and FIPS-compliant builds. The platform is designed for hybrid cloud deployments, supporting both on-premise and managed cloud configurations, with deep integration into OpenShift's ecosystem including Routes, Service CA, OAuth, and monitoring stack.

RHOAI 2.25 emphasizes production-ready AI workloads with enhanced support for large language models (LLM) through vLLM runtimes, NVIDIA NIM integration, Llama Stack operator, and guardrails orchestration, while maintaining compatibility with traditional ML workflows and offering flexible deployment modes (serverless via Knative, raw Kubernetes, or ModelMesh multi-model serving).

## Component Inventory

| Component | Type | Version | Purpose |
|-----------|------|---------|---------|
| rhods-operator | Platform Operator | v1.6.0-7305 | Main operator managing DataScienceCluster lifecycle and component deployment |
| odh-dashboard | Web Application | v1.21.0-rhods-4281 | Web UI for platform management, project creation, and resource monitoring |
| kserve | Model Serving | 4211a5da7 | Kubernetes-native model inference platform with serverless autoscaling |
| modelmesh-serving | Model Serving | 1.27.0-rhods-480 | Multi-model serving for high-throughput inference workloads |
| odh-model-controller | Operator | 1.27.0-rhods-1121 | Extends KServe with OpenShift integration, Routes, service mesh, auth |
| data-science-pipelines-operator | Operator | rhoai-2.25 (763811f) | Manages Kubeflow Pipelines (KFP) for ML workflow orchestration |
| model-registry-operator | Operator | 0b48221 | Manages model versioning, metadata, and artifact tracking |
| training-operator | Operator | 1.9.0 (3a1af789) | Distributed training for PyTorch, TensorFlow, XGBoost, MPI, JAX, PaddlePaddle |
| codeflare-operator | Operator | 1.15.0 | Manages distributed AI/ML workloads via RayCluster and AppWrapper |
| kuberay | Operator | f10d68b1 | Ray cluster lifecycle management for distributed computing |
| kueue | Operator | 7f2f72e51 | Job queueing and workload scheduling with fair sharing and preemption |
| trustyai-service-operator | Operator | d113dae | AI explainability, LM evaluation, and guardrails orchestration |
| feast-operator | Operator | 0.54.0 (aad1ebcd0) | Feature store for consistent training/serving feature management |
| llama-stack-k8s-operator | Operator | 0.3.0 | Llama Stack inference server deployment (Ollama, vLLM, TGI, Bedrock) |
| notebook-controller | Operator | v1.27.0-rhods-1295 | Manages Jupyter notebook instance lifecycle and culling |
| notebooks | Container Images | v2.25.2-55 | Jupyter, VS Code, RStudio workbench images and pipeline runtime images |

## Component Relationships

### Dependency Graph

```
rhods-operator (Platform Orchestrator)
├── odh-dashboard (UI)
│   ├── kserve (API calls for model serving status)
│   ├── model-registry-operator (API calls for model metadata)
│   ├── notebook-controller (creates Notebook CRs)
│   ├── data-science-pipelines-operator (pipeline management)
│   └── Kubernetes API (resource management)
│
├── kserve (Model Serving - Serverless)
│   ├── Knative Serving (autoscaling, traffic routing)
│   ├── Istio (service mesh, mTLS, traffic management)
│   ├── odh-model-controller (OpenShift Routes, auth, monitoring)
│   ├── model-registry (optional model metadata)
│   └── S3 Storage (model artifacts)
│
├── modelmesh-serving (Model Serving - Multi-Model)
│   ├── ETCD (distributed state)
│   ├── S3 Storage (model artifacts)
│   └── odh-model-controller (configuration)
│
├── odh-model-controller (Integration Layer)
│   ├── kserve (watches InferenceService CRDs)
│   ├── Istio (creates VirtualServices, Gateways)
│   ├── Authorino (creates AuthConfigs)
│   ├── NVIDIA NGC API (NIM account management)
│   └── model-registry (optional integration)
│
├── data-science-pipelines-operator (ML Pipelines)
│   ├── Argo Workflows (pipeline execution)
│   ├── MariaDB/PostgreSQL (metadata storage)
│   ├── S3 Storage (artifact storage)
│   ├── kserve (model deployment from pipelines)
│   └── model-registry (model registration)
│
├── model-registry-operator (Model Metadata)
│   ├── PostgreSQL/MySQL (ML metadata storage)
│   ├── OpenShift OAuth (authentication)
│   └── odh-dashboard (UI integration)
│
├── training-operator (Distributed Training)
│   ├── Volcano/Kueue (gang scheduling)
│   ├── S3 Storage (training data and checkpoints)
│   └── model-registry (post-training model registration)
│
├── codeflare-operator (Distributed Workloads)
│   ├── kuberay (RayCluster management)
│   ├── kueue (AppWrapper scheduling)
│   └── OpenShift OAuth (Ray dashboard auth)
│
├── kuberay (Ray Clusters)
│   ├── Redis (optional GCS fault tolerance)
│   └── S3 Storage (application data)
│
├── kueue (Workload Queueing)
│   ├── training-operator (training job admission)
│   ├── codeflare-operator (AppWrapper admission)
│   └── Cluster Autoscaler (provisioning requests)
│
├── trustyai-service-operator (AI Safety & Evaluation)
│   ├── kserve (InferenceService monitoring)
│   ├── modelmesh-serving (payload injection)
│   ├── PostgreSQL/MySQL (metrics storage)
│   └── kueue (LM evaluation job scheduling)
│
├── feast-operator (Feature Store)
│   ├── PostgreSQL/Redis (feature storage)
│   ├── S3/GCS (offline data storage)
│   └── OpenShift OAuth (authentication)
│
├── llama-stack-k8s-operator (LLM Serving)
│   ├── Ollama/vLLM/TGI (inference providers)
│   └── HuggingFace Hub (model downloads)
│
└── notebook-controller (Interactive Notebooks)
    ├── notebooks (workbench container images)
    ├── OpenShift OAuth (authentication)
    └── S3 Storage (user data)
```

### Central Components

Components with the most dependencies and integrations:

1. **rhods-operator**: Core platform orchestrator managing all component deployments via DataScienceCluster CR
2. **odh-dashboard**: Primary user interface integrating with all components for management and monitoring
3. **kserve**: Central model serving platform with integrations across serving, pipelines, and monitoring
4. **odh-model-controller**: Integration glue layer connecting KServe to OpenShift ecosystem (Routes, OAuth, Istio)
5. **Kubernetes API Server**: Universal dependency for all operators and services
6. **Istio Service Mesh**: Optional but critical for mTLS, traffic management, and observability when enabled
7. **S3-compatible Storage**: Nearly universal storage backend for models, artifacts, training data
8. **Prometheus**: Monitoring integration point for all components via ServiceMonitors

### Integration Patterns

**Common Integration Patterns:**
- **CRD Creation**: Dashboard → Notebook Controller, Dashboard → KServe, Pipelines → KServe
- **CRD Watching**: Model Controller → KServe, TrustyAI → KServe, RHOAI Operator → All Components
- **API Proxying**: Dashboard → Kubernetes API, Dashboard → Model Registry, Dashboard → Prometheus
- **Event Watching**: All operators watch their respective CRDs via Kubernetes API watches
- **Webhook Validation**: Most operators provide admission webhooks for resource validation
- **Metrics Scraping**: Prometheus scrapes all components via ServiceMonitor/PodMonitor resources
- **Service Mesh Integration**: Optional Istio VirtualService/Gateway creation for external access

## Platform Network Architecture

### Namespaces

| Namespace | Purpose | Components |
|-----------|---------|------------|
| redhat-ods-operator | Operator Management | rhods-operator controller manager |
| redhat-ods-applications | Platform Services | dashboard, model-controller, notebook-controller, all component operators |
| redhat-ods-monitoring | Monitoring Stack | Prometheus, Alertmanager, Grafana (when monitoring service enabled) |
| istio-system | Service Mesh | Istio control plane (when service mesh enabled) |
| User Namespaces | Workloads | Notebooks, InferenceServices, Pipelines, Training Jobs, Ray Clusters |
| opendatahub | ODH Distribution | Alternative to redhat-ods-applications for ODH deployments |

### External Ingress Points

| Component | Ingress Type | Hosts | Port | Protocol | Encryption | Purpose |
|-----------|--------------|-------|------|----------|------------|---------|
| odh-dashboard | OpenShift Route | cluster-dependent | 443/TCP | HTTPS | TLS 1.2+ edge | Dashboard web UI access |
| InferenceService (KServe) | OpenShift Route | {isvc}-{namespace}.apps.{cluster} | 443/TCP | HTTPS | TLS 1.2+ edge | Model inference HTTP/REST endpoint |
| InferenceService (Istio) | Istio VirtualService | {isvc}.{namespace}.{domain} | 443/TCP | HTTPS | TLS 1.2+ SIMPLE | Model inference (service mesh mode) |
| Model Registry | OpenShift Route | {name}-{namespace}.apps.{cluster} | 443/TCP | HTTPS | TLS 1.2+ edge | Model metadata API |
| Data Science Pipelines | OpenShift Route | ds-pipeline-{name}.apps.{cluster} | 443/TCP | HTTPS | TLS 1.2+ reencrypt | Pipeline API and UI |
| Ray Dashboard | OpenShift Route | ray-dashboard-{cluster}.{domain} | 443/TCP | HTTPS | TLS 1.2+ edge | Ray cluster monitoring (OAuth) |
| TrustyAI Service | OpenShift Route | {name}.apps.{cluster} | 443/TCP | HTTPS | TLS 1.2+ reencrypt | Explainability API (OAuth) |
| Feast Feature Store | OpenShift Route | {name}-online-{namespace}.apps.{cluster} | 443/TCP | HTTPS | TLS 1.2+ edge | Online feature serving |
| Prometheus | OpenShift Route | prometheus.apps.{cluster} | 443/TCP | HTTPS | TLS 1.2+ reencrypt | Metrics query interface (when enabled) |

### External Egress Dependencies

| Component | Destination | Port | Protocol | Encryption | Purpose |
|-----------|-------------|------|----------|------------|---------|
| KServe, ModelMesh, Pipelines | S3-compatible Storage (AWS, Minio, etc) | 443/TCP | HTTPS | TLS 1.2+ | Model artifacts, pipeline artifacts, training data |
| KServe | Google Cloud Storage | 443/TCP | HTTPS | TLS 1.2+ | Model artifacts from GCS |
| KServe | Azure Blob Storage | 443/TCP | HTTPS | TLS 1.2+ | Model artifacts from Azure |
| Notebooks, Pipelines | Container Registries (quay.io, docker.io, registry.redhat.io) | 443/TCP | HTTPS | TLS 1.2+ | Pull container images |
| Model Controller | NVIDIA NGC API | 443/TCP | HTTPS | TLS 1.3 | NIM account validation and model catalog |
| Training Operator, TrustyAI | HuggingFace Hub | 443/TCP | HTTPS | TLS 1.2+ | Download models and datasets |
| Pipelines | Git Repositories | 443/TCP | HTTPS | TLS 1.2+ | Pipeline code and definitions |
| Feast | PostgreSQL/MySQL/Snowflake | 5432/3306/443/TCP | PostgreSQL/MySQL/HTTPS | TLS 1.2+ | Feature store data |
| Feast | Redis | 6379/TCP | Redis Protocol | TLS 1.2+ (optional) | Online feature store backend |
| All Operators | Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | Resource management, watches |
| Dashboard | OpenShift OAuth Server | 6443/TCP | HTTPS | TLS 1.2+ | User authentication |

### Internal Service Mesh

| Setting | Value | Components Using | Notes |
|---------|-------|------------------|-------|
| mTLS Mode | PERMISSIVE (default) or STRICT | KServe, InferenceGraph, Model Controller | Configurable via DSCInitialization |
| Peer Authentication | Namespace-scoped | KServe predictor pods, transformers | Automatically created by Model Controller |
| Istio Gateways | knative-ingress-gateway, knative-local-gateway | KServe serverless mode | Shared gateways for all InferenceServices |
| VirtualServices | Per InferenceService | KServe, InferenceGraph | Created by Model Controller |
| AuthorizationPolicies | Per namespace | Dashboard, Model serving | Created by Auth service controller |
| Telemetry | Namespace-scoped | All mesh-enabled pods | Metrics collection configuration |
| ServiceMeshMember | Per namespace | Application namespaces | Enrolls namespaces in service mesh |

## Platform Security

### RBAC Summary

**Cluster-Scoped Roles (ClusterRoles):**

| Component | ClusterRole | Key API Groups | Key Resources | Purpose |
|-----------|-------------|----------------|---------------|---------|
| rhods-operator | rhods-operator-role | datasciencecluster.opendatahub.io, dscinitialization.opendatahub.io, components.platform.opendatahub.io | All component CRDs, deployments, services, RBAC | Platform-wide component management |
| kserve | kserve-manager-role | serving.kserve.io, serving.knative.dev, networking.istio.io | inferenceservices, servingruntimes, knative services, virtualservices | Model serving orchestration |
| odh-model-controller | odh-model-controller-role | serving.kserve.io, networking.istio.io, authorino.kuadrant.io, nim.opendatahub.io | inferenceservices, virtualservices, authconfigs, accounts | KServe extension and integration |
| modelmesh-controller | modelmesh-controller-role | serving.kserve.io | inferenceservices, servingruntimes, predictors | Multi-model serving management |
| data-science-pipelines | manager-role | datasciencepipelinesapplications.opendatahub.io, argoproj.io, serving.kserve.io | datasciencepipelinesapplications, workflows, inferenceservices | Pipeline lifecycle management |
| training-operator | training-operator | kubeflow.org | pytorchjobs, tfjobs, mpijobs, xgboostjobs, paddlejobs, jaxjobs | Distributed training job management |
| codeflare-operator | manager-role | workload.codeflare.dev, ray.io, dscinitialization.opendatahub.io | appwrappers, rayclusters | Distributed workload orchestration |
| kuberay | kuberay-operator | ray.io | rayclusters, rayjobs, rayservices | Ray cluster lifecycle |
| kueue | kueue-manager-role | kueue.x-k8s.io, batch, kubeflow.org, ray.io | workloads, clusterqueues, localqueues, jobs, training jobs | Workload queueing and admission |
| trustyai-operator | manager-role | trustyai.opendatahub.io, serving.kserve.io, kueue.x-k8s.io | trustyaiservices, lmevaljobs, guardrailsorchestrators, inferenceservices | AI explainability and evaluation |
| feast-operator | feast-operator-manager-role | feast.dev | featurestores | Feature store management |
| llama-stack-operator | manager-role | llamastack.io | llamastackdistributions | Llama Stack deployment |
| notebook-controller | notebook-controller-role | kubeflow.org, networking.istio.io | notebooks, virtualservices | Notebook instance management |
| model-registry-operator | manager-role | modelregistry.opendatahub.io | modelregistries | Model metadata management |

**Common Permissions Across Operators:**
- `pods, services, deployments, secrets, configmaps, serviceaccounts`: Full CRUD permissions
- `roles, rolebindings, clusterrolebindings`: RBAC management for component workloads
- `routes.route.openshift.io`: OpenShift Route creation for external access
- `networkpolicies.networking.k8s.io`: Network isolation policies
- `servicemonitors.monitoring.coreos.com`: Prometheus metrics integration
- `events`: Event creation for audit and troubleshooting

### Secrets Inventory

| Component | Secret Name | Type | Purpose |
|-----------|-------------|------|---------|
| Dashboard | dashboard-proxy-tls | kubernetes.io/tls | OAuth proxy TLS certificate |
| Dashboard | dashboard-oauth-config-generated | Opaque | OAuth cookie secret |
| KServe | kserve-webhook-server-cert | kubernetes.io/tls | Webhook server TLS |
| KServe | storage-config | Opaque | Default S3/storage credentials |
| Model Controller | webhook-server-cert | kubernetes.io/tls | Webhook server TLS |
| Model Controller | {account}-nim-pull-secret | kubernetes.io/dockerconfigjson | NVIDIA NGC registry credentials |
| Data Science Pipelines | ds-pipelines-proxy-tls-{name} | kubernetes.io/tls | OAuth proxy TLS |
| Data Science Pipelines | mariadb-{name} | Opaque | Database root password |
| Data Science Pipelines | mlpipeline-minio-artifact | Opaque | Minio S3 credentials |
| Model Registry | {name}-oauth-proxy | kubernetes.io/tls | OAuth proxy TLS |
| Model Registry | {name}-db-credentials | Opaque | Database connection credentials |
| Training Operator | training-operator-webhook-cert | kubernetes.io/tls | Webhook server TLS |
| CodeFlare | codeflare-operator-webhook-server-cert | kubernetes.io/tls | Webhook server TLS |
| CodeFlare | {cluster}-ca | Opaque | Ray mTLS CA certificate |
| Ray | ray-tls-{namespace} | Opaque | Ray cluster TLS certificates |
| TrustyAI | {name}-internal, {name}-tls | kubernetes.io/tls | Service TLS certificates |
| TrustyAI | {name}-db-credentials | Opaque | Database credentials |
| Feast | {name}-tls | kubernetes.io/tls | Feature store TLS |
| Feast | {name}-db-secret, {name}-redis-secret | Opaque | Storage credentials |
| All Components | {sa-name} ServiceAccount token | kubernetes.io/service-account-token | Kubernetes API authentication |

**Secret Provisioning Methods:**
- **OpenShift Service CA**: Auto-rotation via `service.beta.openshift.io/serving-cert-secret-name` annotation
- **cert-manager**: TLS certificate management and rotation
- **secret-generator.opendatahub.io**: Operator-driven secret generation
- **User-provided**: External database credentials, cloud storage credentials

### Authentication Mechanisms

| Pattern | Components Using | Enforcement Point | Description |
|---------|------------------|-------------------|-------------|
| OpenShift OAuth (Bearer Token JWT) | Dashboard, Pipelines UI, Model Registry, Ray Dashboard, TrustyAI | OAuth Proxy Sidecar | OpenShift user authentication via OAuth server |
| Kubernetes ServiceAccount Token | All Operators, Dashboard Backend | Kubernetes API Server | RBAC-enforced API access |
| mTLS Client Certificates | Webhook Servers, Ray Client (optional) | Kubernetes API Server, Ray Head Node | Certificate-based authentication |
| AWS IAM / S3 Signature V4 | KServe, ModelMesh, Pipelines, Training, Notebooks | S3 Storage Providers | Cloud storage authentication |
| Database Credentials (Username/Password) | Pipelines, Model Registry, TrustyAI, Feast | PostgreSQL/MySQL/MariaDB | Database authentication |
| Authorino/AuthPolicy | InferenceService endpoints | Istio + Authorino | JWT token validation for model serving |
| NVIDIA NGC API Key | Model Controller (NIM) | NVIDIA NGC API | NIM account validation |
| HuggingFace API Token | Training Operator, TrustyAI LM Eval | HuggingFace Hub | Model/dataset downloads |
| None (Internal ClusterIP) | Most internal service-to-service communication | Network policies | Trust within cluster network |

**Authorization Patterns:**
- **Kubernetes RBAC**: Primary authorization mechanism for API resources
- **SubjectAccessReview (SAR)**: OAuth proxy validates user permissions on resources
- **Istio AuthorizationPolicies**: Service mesh-based access control
- **Authorino AuthConfigs**: External auth for model serving endpoints
- **Network Policies**: Network-level access control

## Platform APIs

### Custom Resource Definitions

| Component | API Group | Kind | Scope | Purpose |
|-----------|-----------|------|-------|---------|
| RHOAI Operator | datasciencecluster.opendatahub.io | DataScienceCluster | Cluster | Main platform CR for component enablement |
| RHOAI Operator | dscinitialization.opendatahub.io | DSCInitialization | Cluster | Platform initialization (monitoring, auth, service mesh) |
| RHOAI Operator | components.platform.opendatahub.io | Dashboard, KServe, DataSciencePipelines, CodeFlare, Ray, Kueue, ModelRegistry, ModelMeshServing, TrustyAI, TrainingOperator, Workbenches, FeastOperator, LlamaStackOperator, ModelController | Cluster | Component-specific configuration |
| RHOAI Operator | services.platform.opendatahub.io | Auth, Monitoring, ServiceMesh | Cluster | Platform service configuration |
| RHOAI Operator | features.opendatahub.io | FeatureTracker | Cluster | Feature enablement tracking |
| RHOAI Operator | infrastructure.opendatahub.io | HardwareProfile | Cluster | GPU/accelerator profiles |
| Dashboard | dashboard.opendatahub.io | OdhApplication, OdhDocument, AcceleratorProfile | Namespaced | Dashboard applications and documentation |
| Dashboard | console.openshift.io | OdhQuickStart | Namespaced | Interactive quickstart tutorials |
| KServe | serving.kserve.io/v1beta1 | InferenceService | Namespaced | Model inference service definition |
| KServe | serving.kserve.io/v1alpha1 | ServingRuntime, ClusterServingRuntime, TrainedModel, InferenceGraph, LLMInferenceService, LLMInferenceServiceConfig, ClusterStorageContainer, LocalModelCache | Namespaced/Cluster | Model serving infrastructure |
| Model Controller | nim.opendatahub.io/v1 | Account | Namespaced | NVIDIA NIM account management |
| Pipelines | datasciencepipelinesapplications.opendatahub.io/v1 | DataSciencePipelinesApplication | Namespaced | Pipeline stack configuration |
| Pipelines | pipelines.kubeflow.org/v1 | Pipeline, PipelineVersion | Namespaced | Pipeline definitions |
| Pipelines | argoproj.io/v1alpha1 | Workflow, WorkflowTemplate | Namespaced | Argo workflow orchestration |
| Model Registry | modelregistry.opendatahub.io/v1beta1 | ModelRegistry | Namespaced | Model metadata repository |
| Training Operator | kubeflow.org/v1 | PyTorchJob, TFJob, MPIJob, XGBoostJob, PaddleJob, JAXJob | Namespaced | Distributed training jobs |
| CodeFlare | workload.codeflare.dev/v1beta2 | AppWrapper | Namespaced | Grouped resource workloads |
| Ray | ray.io/v1 | RayCluster, RayJob, RayService | Namespaced | Ray distributed computing |
| Kueue | kueue.x-k8s.io/v1beta1 | Workload, ClusterQueue, LocalQueue, ResourceFlavor, WorkloadPriorityClass, AdmissionCheck, ProvisioningRequestConfig, MultiKueueConfig, MultiKueueCluster | Namespaced/Cluster | Workload queueing |
| TrustyAI | trustyai.opendatahub.io/v1 | TrustyAIService | Namespaced | AI explainability service |
| TrustyAI | trustyai.opendatahub.io/v1alpha1 | LMEvalJob, GuardrailsOrchestrator | Namespaced | LM evaluation and guardrails |
| Feast | feast.dev/v1alpha1 | FeatureStore | Namespaced | Feature store deployment |
| Llama Stack | llamastack.io/v1alpha1 | LlamaStackDistribution | Namespaced | Llama Stack deployment |
| Notebooks | kubeflow.org/v1 | Notebook | Namespaced | Jupyter notebook instances |

**Total CRDs**: 60+ custom resource definitions across the platform

### Public HTTP Endpoints

**Platform Management:**
- **Dashboard**: `https://odh-dashboard-{namespace}.apps.{cluster}/*` - Web UI for all platform operations
- **Prometheus**: `https://prometheus-{namespace}.apps.{cluster}/api/v1/query` - Metrics query API

**Model Serving:**
- **InferenceService (KServe)**: `https://{isvc}-{namespace}.apps.{cluster}/v2/models/{model}/infer` - Model inference
- **Model Registry**: `https://{name}-{namespace}.apps.{cluster}/api/model_registry/v1alpha3/*` - Model metadata API

**Pipelines:**
- **DSP API**: `https://ds-pipeline-{name}.apps.{cluster}/apis/v2beta1/*` - Pipeline management API
- **DSP UI**: `https://ds-pipeline-ui-{name}.apps.{cluster}/` - Pipeline visualization

**Explainability & Safety:**
- **TrustyAI**: `https://{name}.apps.{cluster}/` - Explainability metrics API
- **Guardrails**: `https://{name}-gateway.apps.{cluster}/` - Guardrails orchestration

**Feature Store:**
- **Feast Online**: `https://{name}-online-{namespace}.apps.{cluster}/get-online-features` - Online features
- **Feast Offline**: `https://{name}-offline-{namespace}.apps.{cluster}/get-historical-features` - Historical features

**Distributed Computing:**
- **Ray Dashboard**: `https://ray-dashboard-{cluster}.apps.{cluster}/` - Ray cluster monitoring (OAuth)

**All endpoints** use TLS 1.2+ encryption with edge or reencrypt termination at OpenShift Routes.

## Data Flows

### Key Platform Workflows

#### Workflow 1: Model Training to Deployment

| Step | Component | Action | Next Component |
|------|-----------|--------|----------------|
| 1 | Notebook (Jupyter) | User develops model code, trains locally or submits training job | Training Operator or Pipelines |
| 2 | Training Operator | Creates PyTorchJob/TFJob, launches distributed pods, trains model | S3 Storage (saves checkpoints) |
| 3 | Training Job Pod | Uploads trained model artifacts to S3 bucket | S3 Storage |
| 4 | User/Pipeline | Creates InferenceService CR referencing S3 model path | KServe |
| 5 | KServe Controller | Creates Knative Service or Deployment, downloads model | Model Server Pod |
| 6 | Model Controller | Creates Route, VirtualService, AuthConfig, ServiceMonitor | OpenShift Router, Istio |
| 7 | Model Server Pod | Loads model from S3, starts serving inference requests | Ready for traffic |
| 8 | Dashboard | Registers InferenceService metadata (optional) | Model Registry |

#### Workflow 2: ML Pipeline Execution

| Step | Component | Action | Next Component |
|------|-----------|--------|----------------|
| 1 | User/Dashboard | Submits pipeline definition (YAML or Python SDK) | Data Science Pipelines API |
| 2 | DSP API Server | Creates Workflow CR, stores pipeline in MariaDB | Argo Workflows Controller |
| 3 | Argo Controller | Launches pipeline step pods in DAG order | Pipeline Task Pods |
| 4 | Task Pod (data prep) | Reads data from S3, preprocesses, writes back to S3 | S3 Storage |
| 5 | Task Pod (training) | Launches TrainingJob CR (PyTorchJob) | Training Operator |
| 6 | Training Operator | Executes distributed training, saves model | S3 Storage |
| 7 | Task Pod (model eval) | Evaluates model metrics, logs to pipeline | DSP API Server |
| 8 | Task Pod (model deploy) | Creates InferenceService CR | KServe |
| 9 | Task Pod (register) | Registers model in Model Registry | Model Registry |
| 10 | Persistence Agent | Syncs workflow status to MariaDB | Pipeline completed |

#### Workflow 3: Interactive Development Session

| Step | Component | Action | Next Component |
|------|-----------|--------|----------------|
| 1 | User via Dashboard | Selects Jupyter workbench image (e.g., PyTorch CUDA) | Dashboard Backend |
| 2 | Dashboard Backend | Creates Notebook CR with PodSpec | Notebook Controller |
| 3 | Notebook Controller | Creates StatefulSet, Service, OAuth Route | Kubelet |
| 4 | Kubelet | Pulls notebook container image, starts pod | Notebook Pod |
| 5 | Notebook Pod | Jupyter server starts on port 8888 | OAuth Proxy Sidecar |
| 6 | User Browser | Accesses notebook via OpenShift Route | OAuth Proxy |
| 7 | OAuth Proxy | Authenticates user via OpenShift OAuth | Jupyter Container |
| 8 | User in Jupyter | Installs libraries, writes code, trains models | S3 Storage (data access) |
| 9 | User in Jupyter | Submits training job or inference service | Training Operator or KServe |

#### Workflow 4: Distributed Ray Workload

| Step | Component | Action | Next Component |
|------|-----------|--------|----------------|
| 1 | User | Creates AppWrapper CR with RayCluster spec | CodeFlare Operator |
| 2 | CodeFlare Operator | Validates AppWrapper, sends to Kueue for admission | Kueue |
| 3 | Kueue | Evaluates quota, admits AppWrapper when resources available | CodeFlare Operator |
| 4 | CodeFlare Operator | Creates RayCluster CR | KubeRay Operator |
| 5 | KubeRay Operator | Creates Ray head pod and worker pods, Services | Ray Head Pod |
| 6 | CodeFlare Operator | Injects OAuth proxy for Ray dashboard, creates Route | OAuth Proxy |
| 7 | Ray Head Pod | Workers connect, form Ray cluster | Ray Workers |
| 8 | User Application | Submits Ray job to cluster via dashboard or client | Ray Head |
| 9 | Ray Head | Distributes tasks across workers, aggregates results | Ray Workers |
| 10 | Ray Workers | Execute parallel tasks, access S3 data | S3 Storage |

#### Workflow 5: Model Explainability Analysis

| Step | Component | Action | Next Component |
|------|-----------|--------|----------------|
| 1 | User | Creates TrustyAIService CR in namespace | TrustyAI Operator |
| 2 | TrustyAI Operator | Deploys TrustyAI service with OAuth proxy, creates Route | TrustyAI Service Pod |
| 3 | TrustyAI Operator | Patches InferenceService to inject payload logging | KServe InferenceService |
| 4 | Inference Request | Client sends prediction request | InferenceService |
| 5 | InferenceService | Forwards request payload to TrustyAI for logging | TrustyAI Service |
| 6 | TrustyAI Service | Stores input/output pairs in PVC or database | Storage |
| 7 | User | Requests bias metrics via TrustyAI API | TrustyAI Service |
| 8 | TrustyAI Service | Analyzes stored data, computes fairness metrics | Response with metrics |
| 9 | Dashboard | Displays TrustyAI metrics in UI | User |

## Deployment Architecture

### Deployment Topology

**Operator Namespace** (`redhat-ods-operator`):
- rhods-operator (Deployment, 1 replica)
- Leader election ConfigMap/Lease

**Application Namespace** (`redhat-ods-applications`):
- odh-dashboard (Deployment, 2 replicas with anti-affinity)
- odh-model-controller (Deployment, 1 replica)
- notebook-controller (Deployment, 1 replica)
- kserve-controller (Deployment, 1 replica)
- modelmesh-controller (Deployment, 1 replica)
- data-science-pipelines-operator (Deployment, 1 replica)
- model-registry-operator (Deployment, 1 replica)
- training-operator (Deployment, 1 replica)
- codeflare-operator (Deployment, 1 replica)
- kuberay-operator (Deployment, 1 replica)
- kueue-controller (Deployment, 1 replica)
- trustyai-operator (Deployment, 1 replica)
- feast-operator (Deployment, 1 replica)
- llama-stack-operator (Deployment, 1 replica)

**User Workload Namespaces** (user-created):
- Notebooks (StatefulSet per notebook)
- InferenceServices (Knative Service or Deployment per model)
- DataSciencePipelinesApplication (Deployment for API, persistence agent, workflow controller)
- ModelRegistry (Deployment per instance)
- TrustyAIService (Deployment per instance)
- Training Jobs (Pods per job)
- Ray Clusters (Deployment for head + workers)
- FeatureStore (Deployment per instance)

**Monitoring Namespace** (`redhat-ods-monitoring`, optional):
- Prometheus (StatefulSet)
- Alertmanager (StatefulSet)
- Grafana (Deployment)

**Service Mesh Namespace** (`istio-system`, optional):
- Istio Control Plane (ServiceMeshControlPlane)

### Resource Requirements

**Operator Pods** (typical):
- CPU Requests: 10m-500m per operator
- Memory Requests: 64Mi-1Gi per operator
- CPU Limits: 500m-1000m per operator
- Memory Limits: 700Mi-2Gi per operator

**Workload Pods** (highly variable):
- Notebooks: User-configurable (default: 1 CPU, 8Gi memory)
- Training Jobs: User-configurable (often multi-GPU, 16-64 cores)
- Model Serving: Configurable per runtime (CPU-only: 1-2 cores, GPU: 1-4 GPUs)
- Ray Clusters: Configurable per node (head: 4 cores, workers: 8-16 cores)

## Version-Specific Changes (2.25)

| Component | Changes |
|-----------|---------|
| rhods-operator | - Go 1.24.4 upgrade<br>- 223 manifest sets for component deployment<br>- Enhanced DataScienceCluster API |
| odh-dashboard | - React 18.2.0, PatternFly 6.3.1 upgrade<br>- Module federation for dynamic plugins<br>- LlamaStack, NIM serving integration |
| kserve | - Multi-arch support (ppc64le, s390x) Konflux builds<br>- Path traversal vulnerability fixes (CVE-2025-XXXX)<br>- Proxy configuration support<br>- LLMInferenceService API for multi-node LLMs |
| odh-model-controller | - FIPS compliance (strictfipsruntime)<br>- NVIDIA NIM integration via Account CRD<br>- vLLM multinode runtime template<br>- Go 1.25.7 for CVE-2025-61729 fix |
| data-science-pipelines | - Go 1.25.5 for CVE-2025-61729 fix<br>- DSP v2 (Argo Workflows) default<br>- Pod-to-pod TLS enabled by default<br>- Managed pipelines auto-import (InstructLab) |
| model-registry-operator | - v1beta1 API as storage version<br>- v1alpha1 deprecated (Istio auth removed)<br>- OAuth proxy as only auth mechanism<br>- Go 1.25.7 upgrade |
| training-operator | - Go 1.25 upgrade for CVE fixes<br>- Namespace-scoped RBAC for secrets (security)<br>- Elastic training with HPA (PyTorch)<br>- JAX training support added |
| notebooks | - Python 3.12 as default<br>- CUDA 12.6, 12.8, ROCm 6.2, 6.4 support<br>- LLMCompressor workbench variant<br>- JupyterLab 4.4 upgrade<br>- UBI9 base images |
| codeflare-operator | - Go 1.25 upgrade<br>- Ray OAuth/mTLS enhancements<br>- Kueue integration improvements |
| kuberay | - Weekly UBI9 base image updates<br>- External Redis GCS fault tolerance<br>- RayService zero-downtime upgrades |
| kueue | - Go 1.24 upgrade<br>- MultiKueue for multi-cluster bursting<br>- Topology-aware scheduling<br>- Provisioning request autoscaling |
| trustyai-operator | - LM evaluation with lm-evaluation-harness<br>- Guardrails orchestrator for AI safety<br>- Kueue integration for LM eval jobs |
| feast-operator | - OIDC authentication support<br>- Topology API for datacenter awareness |
| llama-stack-operator | - Initial release (0.3.0)<br>- Ollama, vLLM, TGI, Bedrock distributions<br>- NetworkPolicy support |

## Platform Maturity

### Component Statistics
- **Total Components**: 16 major components
- **Operator-based Components**: 14 (87.5%)
- **Container Image Components**: 2 (notebooks, dashboard)
- **Total CRDs**: 60+
- **Total Namespaces**: 3-5 (operator, applications, monitoring, istio, user workloads)

### Security & Compliance
- **Service Mesh Coverage**: Optional (Istio integration)
- **mTLS Enforcement**: PERMISSIVE (default) or STRICT (configurable)
- **FIPS Compliance**: All Konflux-built images use strictfipsruntime
- **RBAC Model**: Kubernetes-native with least-privilege principles
- **Authentication**: OpenShift OAuth for external access, ServiceAccount tokens for internal
- **Secret Management**: Auto-rotation via service-ca, cert-manager support
- **Network Isolation**: NetworkPolicy support across components

### API Maturity
- **CRD API Versions**:
  - v1: 7 APIs (production-ready)
  - v1beta1: 5 APIs (stable, nearing GA)
  - v1alpha1: 48+ APIs (preview, subject to change)
- **Conversion Webhooks**: Support for API version migration (Model Registry, TrustyAI)
- **Admission Webhooks**: Validating and mutating webhooks across most operators

### Observability
- **Metrics**: All components expose Prometheus metrics via ServiceMonitor/PodMonitor
- **Logging**: Structured JSON logging across all operators
- **Tracing**: Optional OpenTelemetry support (Tempo integration)
- **Health Checks**: Liveness and readiness probes on all operators
- **Alerts**: PrometheusRule resources for operational alerts

### High Availability
- **Operator HA**: Leader election support (most operators single-replica by default)
- **Dashboard HA**: 2 replicas with anti-affinity
- **Workload HA**: Configurable per deployment (InferenceService autoscaling, Ray multi-replica)
- **Data HA**: Depends on backing stores (database replication, S3 versioning)

## Next Steps for Documentation

1. **Generate Diagrams**: Create visual architecture diagrams from this platform specification
   - Component dependency graph (Graphviz/Mermaid)
   - Network topology diagram (showing ingress/egress flows)
   - Data flow diagrams for each workflow
   - Security zones and trust boundaries

2. **Update ADRs**: Synchronize Architecture Decision Records
   - Document service mesh optional/required decision
   - Document v1beta1 API migrations (Model Registry, Pipelines)
   - Document security model (OAuth vs Authorino vs mTLS)

3. **Create User Documentation**: Generate user-facing architecture docs
   - Component interaction guide for data scientists
   - Best practices for multi-tenant deployments
   - Scaling and performance guidelines

4. **Security Architecture Review (SAR)**: Prepare SAR documentation
   - Network diagram with security zones
   - Data flow diagrams with encryption/auth annotations
   - Threat model for external-facing services
   - Compliance matrix (FIPS, PCI-DSS, SOC2)

5. **Platform Comparison Matrix**: Document feature parity
   - RHOAI vs ODH feature differences
   - Serverless (KServe) vs Raw (ModelMesh) serving comparison
   - DSP v1 (Tekton) vs v2 (Argo) migration guide

6. **Capacity Planning Guide**: Resource requirements
   - Cluster sizing recommendations by workload type
   - Storage requirements by component
   - Network bandwidth requirements for distributed training

7. **Disaster Recovery Plan**: Document backup/restore procedures
   - CRD backup strategy
   - Database backup (Pipelines, Model Registry, TrustyAI)
   - Model artifact backup (S3 versioning/replication)
   - Configuration management (GitOps recommendations)
