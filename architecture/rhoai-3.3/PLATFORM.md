# Platform: Red Hat OpenShift AI 3.3

## Metadata
- **Distribution**: RHOAI
- **Version**: 3.3
- **Release Date**: 2026-03
- **Base Platform**: OpenShift Container Platform 4.12+
- **Components Analyzed**: 15
- **Source Directory**: architecture/rhoai-3.3

## Platform Overview

Red Hat OpenShift AI (RHOAI) 3.3 is an enterprise AI/ML platform built on OpenShift that provides a complete lifecycle environment for data science teams. The platform integrates 15 core components orchestrated by a central operator to deliver capabilities including interactive workbenches (Jupyter notebooks), distributed model training, model serving with KServe, ML pipelines for workflow orchestration, model registry for versioning and metadata tracking, feature store for ML feature management, and AI explainability through TrustyAI.

The platform architecture follows a modular, operator-based design where the RHODS Operator serves as the control plane, deploying and managing component-specific operators that handle specialized workloads. All components integrate with OpenShift's security model (OAuth, RBAC, NetworkPolicies), leverage OpenShift Routes and Gateway API for external access, and utilize service mesh (Istio) for secure inter-service communication. The platform supports multiple hardware accelerators including NVIDIA GPUs (CUDA), AMD GPUs (ROCm), and Intel processors, with container images built through Konflux CI/CD for FIPS compliance and security scanning.

RHOAI 3.3 introduces enhanced capabilities for LLM serving via KServe with vLLM and NVIDIA NIM runtimes, distributed training improvements through Kubeflow Trainer with progression tracking, MLflow for experiment tracking, Llama Stack integration, and extended model explainability features. The platform targets enterprise deployments requiring governance, security, and multi-tenancy with namespace-scoped isolation and comprehensive audit logging.

## Component Inventory

| Component | Type | Version | Purpose |
|-----------|------|---------|---------|
| RHODS Operator | Operator | v1.6.0-5550 | Central control plane managing platform lifecycle and component deployment |
| ODH Dashboard | Web Application | v1.21.0-18 | React-based UI for managing projects, workbenches, models, and pipelines |
| Data Science Pipelines Operator | Operator | v0.0.1 | Kubeflow Pipelines integration for ML workflow orchestration |
| KServe | Operator | v0.15 | Serverless model serving platform with KFP v2 and OpenAI APIs |
| odh-model-controller | Operator | v1.27.0-1157 | OpenShift-specific extensions for KServe (Routes, NetworkPolicies, NIM) |
| Model Registry Operator | Operator | 4fdd8de | Manages model metadata storage with PostgreSQL/MySQL backends |
| Workbenches (Notebooks) | Container Images | v20xx.2-1184 | Jupyter, RStudio, CodeServer images with ML frameworks (PyTorch, TensorFlow) |
| ODH Notebook Controller | Operator | v1.27.0-1417 | Gateway API routing and RBAC for notebook instances |
| Training Operator | Operator | v1.9.0 | Distributed training for PyTorch, TensorFlow, XGBoost, MPI, JAX, PaddlePaddle |
| Kubeflow Trainer | Operator | v2.1.0 | LLM fine-tuning with progression tracking and gang scheduling |
| KubeRay Operator | Operator | v1.4.2 | Ray cluster management for distributed computing |
| Feast Operator | Operator | 98a224e7c | Feature store for ML feature serving and materialization |
| MLflow Operator | Operator | 49b5d8d | Experiment tracking and model registry with kubernetes-auth |
| Llama Stack Operator | Operator | v0.6.0 | Deploys Llama Stack distributions (Ollama, vLLM, Meta reference) |
| TrustyAI Service Operator | Operator | v1.39.0 | AI explainability, bias detection, drift monitoring, and LLM guardrails |

## Component Relationships

### Dependency Graph

```
rhods-operator (Control Plane)
├── odh-dashboard
│   ├── Reads: ImageStreams, OdhApplications, Notebooks, InferenceServices, ModelRegistries
│   └── Creates: Notebooks, ServingRuntimes, ModelRegistries, Feast, MLflow
│
├── kserve
│   ├── Dependencies: Istio (VirtualServices), Knative Serving (optional), cert-manager
│   └── Integrations: Model Registry (storage), Data Science Pipelines (model deployment)
│
├── odh-model-controller
│   ├── Extends: KServe (Routes, NetworkPolicies, KEDA, Prometheus)
│   └── Manages: NVIDIA NIM accounts and templates
│
├── data-science-pipelines-operator
│   ├── Uses: Argo Workflows (pipeline execution)
│   └── Integrations: KServe (model deployment), Model Registry (metadata), Workbenches (API calls)
│
├── model-registry-operator
│   ├── Backend: PostgreSQL or MySQL
│   └── Integrations: KServe (model metadata), Data Science Pipelines (versioning)
│
├── kubeflow/notebook-controller (ODH variant)
│   ├── Creates: Notebook StatefulSets, Services
│   └── Integrations: Gateway API (HTTPRoutes), Data Science Pipelines (pipeline secrets)
│
├── odh-notebook-controller
│   ├── Enhances: Notebook CRs with Gateway API routing and kube-rbac-proxy injection
│   └── Integrations: Data Science Gateway, Data Science Pipelines
│
├── training-operator
│   ├── Uses: JobSet (multi-node training), Volcano/Coscheduling (gang scheduling)
│   └── Integrations: Kueue (job queueing)
│
├── kubeflow-trainer
│   ├── Uses: JobSet, Volcano/Coscheduling
│   ├── Extensions: Progression tracking (RHOAI-specific), NetworkPolicies
│   └── Integrations: HuggingFace Hub (model/dataset downloads), S3 (artifacts)
│
├── kuberay-operator
│   ├── Dependencies: cert-manager (optional), Gateway API (optional)
│   └── Integrations: Prometheus, OpenShift Routes
│
├── feast-operator
│   ├── Uses: PostgreSQL/Redis (optional), S3 (offline store)
│   └── Integrations: Kubeflow Notebooks (ConfigMap injection)
│
├── mlflow-operator
│   ├── Uses: PostgreSQL/S3 (remote storage), Helm (templating)
│   └── Integrations: Gateway API (HTTPRoutes), OpenShift Console (ConsoleLinks)
│
├── llama-stack-operator
│   ├── Uses: Ollama or vLLM (inference providers)
│   └── Integrations: odh-trusted-ca-bundle
│
└── trustyai-service-operator
    ├── Extends: KServe InferenceServices (payload processors)
    └── Uses: PostgreSQL/MySQL (storage), Istio (VirtualServices), Kueue (LMEvalJobs)
```

### Central Components

Components with the most dependencies (core platform services):

1. **RHODS Operator**: Central orchestrator deploying all platform components
2. **ODH Dashboard**: Primary user interface integrating with all components
3. **KServe + odh-model-controller**: Core model serving infrastructure used by pipelines and workbenches
4. **Kubernetes API Server**: All components interact via K8s APIs for resource management
5. **OpenShift OAuth + Gateway API**: Centralized authentication and routing for all user-facing services

### Integration Patterns

**Pattern 1: Operator-Managed Components**
- RHODS Operator creates component CRs (DataScienceCluster → component CRs)
- Component operators reconcile their CRs and manage workloads
- All operators use ServiceAccount tokens for K8s API access

**Pattern 2: CRD-Based Integration**
- Dashboard creates Notebook CRs → kubeflow/notebook-controller + odh-notebook-controller process
- Dashboard creates InferenceService CRs → KServe + odh-model-controller process
- Pipelines create InferenceService CRs → KServe deploys models
- TrustyAI patches InferenceService CRs → KServe injects payload processors

**Pattern 3: API Call Integration**
- Workbenches → Data Science Pipelines API (pipeline submission)
- Dashboard → Model Registry API (model metadata queries)
- Dashboard → Prometheus API (metrics queries)
- Kubeflow Trainer → Training Pod /metrics (progression tracking)

**Pattern 4: Shared Infrastructure**
- All components use OpenShift Routes/Gateway API for external access
- All components use kube-rbac-proxy for metrics authentication
- All components use OpenShift Service CA for TLS certificate generation
- Istio VirtualServices used by KServe, TrustyAI, Feast for traffic routing

**Pattern 5: Storage Integration**
- Components share S3-compatible storage for artifacts (pipelines, KServe, training)
- Components optionally use PostgreSQL for metadata (Model Registry, MLflow, Feast, TrustyAI)
- Components use PVCs for local storage (notebooks, pipelines, feast)

## Platform Network Architecture

### Namespaces

| Namespace | Purpose | Components |
|-----------|---------|------------|
| redhat-ods-operator | Operator control plane | RHODS Operator, component operators |
| redhat-ods-applications | User-facing applications | ODH Dashboard, MLflow, Llama Stack, shared resources |
| redhat-ods-monitoring | Observability | Prometheus, AlertManager, Grafana (optional) |
| openshift-ingress | Gateway infrastructure | data-science-gateway (Gateway API) |
| istio-system | Service mesh (optional) | Istio control plane for KServe |
| knative-serving | Serverless (optional) | Knative for KServe autoscaling |
| User namespaces | Workloads | Notebooks, training jobs, inference services, pipelines, model registries |

### External Ingress Points

| Component | Ingress Type | Hosts | Port | Protocol | Encryption | Purpose |
|-----------|--------------|-------|------|----------|------------|---------|
| ODH Dashboard | OpenShift Route / HTTPRoute | odh-dashboard-{namespace}.apps.{cluster} | 443/TCP | HTTPS | TLS 1.2+ (Reencrypt) | Main UI for platform access |
| Workbenches (Notebooks) | HTTPRoute (Gateway API) | via data-science-gateway | 443/TCP | HTTPS | TLS 1.2+ (Edge) | Jupyter/RStudio/CodeServer access |
| KServe InferenceServices | Istio VirtualService / Route | {isvc}-{namespace}.{domain} | 443/TCP | HTTPS | TLS 1.2+ (SIMPLE/Reencrypt) | Model inference endpoints |
| Data Science Pipelines | OpenShift Route | ds-pipeline-{name}-{namespace}.apps.{cluster} | 443/TCP | HTTPS | TLS 1.2+ (Reencrypt) | Pipeline API and UI |
| Model Registry | OpenShift Route | {registry}-rest-{namespace}.apps.{cluster} | 443/TCP | HTTPS | TLS 1.2+ (Reencrypt) | Model metadata API |
| MLflow | HTTPRoute (Gateway API) | via data-science-gateway | 443/TCP | HTTPS | TLS 1.3 | Experiment tracking UI/API |
| Feast Feature Servers | OpenShift Route | {feast}-{server}-{namespace}.apps.{cluster} | 443/TCP | HTTPS | TLS 1.2+ (Edge) | Online/offline feature serving |
| Ray Dashboard | Ingress/Route | {cluster}-{namespace}.apps.{cluster} | 443/TCP | HTTPS | TLS 1.2+ (SIMPLE) | Ray cluster management UI |
| TrustyAI Service | OpenShift Route | {trustyai}-{namespace}.apps.{cluster} | 443/TCP | HTTPS | TLS 1.2+ (Reencrypt) | Explainability and monitoring APIs |

### External Egress Dependencies

| Component | Destination | Port | Protocol | Encryption | Purpose |
|-----------|-------------|------|----------|------------|---------|
| Data Science Pipelines | S3-compatible storage | 443/TCP | HTTPS | TLS 1.2+ | Pipeline artifact storage |
| Data Science Pipelines | External MySQL/MariaDB (optional) | 3306/TCP | MySQL | TLS 1.2+ | Pipeline metadata persistence |
| KServe | S3/GCS/Azure Blob | 443/TCP | HTTPS | TLS 1.2+ | Model artifact download |
| Training Operators | HuggingFace Hub | 443/TCP | HTTPS | TLS 1.2+ | Model/dataset downloads |
| Training Operators | S3-compatible storage | 443/TCP | HTTPS | TLS 1.2+ | Training data and checkpoints |
| Workbenches | pypi.org | 443/TCP | HTTPS | TLS 1.2+ | Python package installation |
| Workbenches | Git repositories | 443/TCP | HTTPS | TLS 1.2+ | Code repository cloning |
| Feast | PostgreSQL/Redis (optional) | 5432/6379/TCP | PostgreSQL/Redis | TLS 1.2+ | Feature store backend |
| Feast | S3-compatible storage | 443/TCP | HTTPS | TLS 1.2+ | Offline feature data |
| Model Registry | PostgreSQL/MySQL | 5432/3306/TCP | PostgreSQL/MySQL | TLS 1.2+ | Model metadata storage |
| MLflow | PostgreSQL (optional) | 5432/TCP | PostgreSQL | TLS 1.2+ | Experiment metadata storage |
| MLflow | S3-compatible storage | 443/TCP | HTTPS | TLS 1.2+ | Artifact storage |
| odh-model-controller | NVIDIA NGC API | 443/TCP | HTTPS | TLS 1.2+ | NIM account validation |
| TrustyAI | PostgreSQL/MySQL (optional) | 5432/3306/TCP | PostgreSQL/MySQL | TLS 1.2+ | Inference data storage |
| All Components | Image Registries | 443/TCP | HTTPS | TLS 1.2+ | Container image pulls |
| All Components | OpenShift OAuth Server | 443/TCP | HTTPS | TLS 1.2+ | User authentication |

### Internal Service Mesh

| Setting | Value | Components Using |
|---------|-------|------------------|
| mTLS Mode | PERMISSIVE (default) / STRICT (optional) | KServe, TrustyAI, Feast (optional) |
| Peer Authentication | Namespace-scoped | KServe inference namespaces |
| Authorization Policies | AuthPolicy (Kuadrant) / AuthorizationPolicy (Istio) | KServe InferenceServices (optional) |
| Traffic Management | VirtualService + DestinationRule | KServe (canary, blue-green), TrustyAI (traffic splitting) |
| Gateway API Integration | Istio Gateway + HTTPRoute | KServe (alternative to VirtualService) |

## Platform Security

### RBAC Summary

**Cluster-Admin Level Operators** (require extensive cluster permissions):

| Component | ClusterRole Highlights | Justification |
|-----------|----------------------|---------------|
| RHODS Operator | Full CRUD on CRDs, ClusterRoles, ClusterRoleBindings, SCCs | Manages platform-wide infrastructure and sub-operators |
| KServe | Full management of serving.kserve.io CRDs, Istio resources, Knative Services | Manages model serving across all namespaces |
| odh-model-controller | KServe extensions, Route creation, Kuadrant AuthPolicies, Istio EnvoyFilters | Extends KServe with OpenShift-specific features |
| Data Science Pipelines Operator | Argo Workflows, Deployments, NetworkPolicies per namespace | Manages pipeline stacks in multiple namespaces |

**Namespace-Scoped Operators** (limited to specific namespaces):

| Component | ClusterRole Highlights | Scope |
|-----------|----------------------|-------|
| Model Registry Operator | ModelRegistry CRs, PostgreSQL deployments, Routes | Cluster-wide CR watch, namespace-scoped deployments |
| MLflow Operator | MLflow CRs, HTTPRoutes, ConsoleLinks | Cluster-scoped with namespace deployments |
| Feast Operator | FeatureStore CRs, Deployments, Services, Routes | Namespace-scoped feature stores |
| TrustyAI Operator | TrustyAI CRs, InferenceService patches, Kueue integration | Namespace-scoped with InferenceService patching |
| Training Operators | Job CRDs, PodGroups (gang scheduling), HorizontalPodAutoscalers | Namespace-scoped training jobs |

**Aggregated Permissions** (user-facing roles):

| Role | API Group | Resources | Verbs | Purpose |
|------|-----------|-----------|-------|---------|
| notebooks-edit | kubeflow.org | notebooks, notebooks/status | get, list, watch, create, delete, patch, update | Data scientists manage workbenches |
| aggregate-dspa-admin-view | datasciencepipelinesapplications.opendatahub.io | datasciencepipelinesapplications | get, list, watch | View pipeline configurations |
| modelregistry-editor-role | modelregistry.opendatahub.io | modelregistries | get, list, watch, create, update, patch | Manage model registries |
| featurestore-editor-role | feast.dev | featurestores | get, list, watch, create, update, patch, delete | Manage feature stores |

### Secrets Inventory

| Component | Secret Name Pattern | Type | Purpose |
|-----------|---------------------|------|---------|
| RHODS Operator | opendatahub-operator-controller-webhook-cert | kubernetes.io/tls | Webhook server TLS cert |
| ODH Dashboard | dashboard-proxy-tls | kubernetes.io/tls | kube-rbac-proxy TLS cert |
| Data Science Pipelines | ds-pipelines-proxy-tls-{name} | kubernetes.io/tls | OAuth proxy TLS cert |
| Data Science Pipelines | {custom-db-secret} | Opaque | Database credentials (user/password) |
| Data Science Pipelines | {custom-storage-secret} | Opaque | S3 access/secret keys |
| KServe | kserve-webhook-server-cert | kubernetes.io/tls | Webhook server TLS cert (cert-manager) |
| KServe | storage-config | Opaque | Default S3/GCS credentials |
| odh-model-controller | odh-model-controller-webhook-cert | kubernetes.io/tls | Webhook server TLS cert |
| odh-model-controller | {NGC API Key Secrets} | Opaque | NVIDIA NGC API keys for NIM |
| Model Registry | {registry-name}-kube-rbac-proxy | kubernetes.io/tls | kube-rbac-proxy TLS cert |
| Model Registry | {db-credential-secret} | Opaque | PostgreSQL/MySQL password |
| Notebooks | {workbench}-oauth-config | Opaque | OAuth proxy configuration |
| Feast | {name}-oidc | Opaque | OIDC credentials for feature access |
| Feast | {name}-db-secret, {name}-redis-secret, {name}-s3-secret | Opaque | Backend storage credentials |
| MLflow | mlflow-tls | kubernetes.io/tls | MLflow server TLS cert |
| MLflow | mlflow-db-credentials, aws-credentials | Opaque | Database and S3 credentials |
| TrustyAI | {trustyai-name}-internal, {trustyai-name}-tls | kubernetes.io/tls | Service TLS certs |
| TrustyAI | {trustyai-name}-db-credentials | Opaque | Database credentials |
| Training Operators | training-operator-webhook-cert | kubernetes.io/tls | Webhook server TLS cert |
| Kubeflow Trainer | kubeflow-trainer-webhook-cert | kubernetes.io/tls | Webhook server TLS cert |

**Secret Auto-Rotation**:
- OpenShift Service CA secrets: Yes (30-90 days)
- cert-manager secrets: Yes (configurable, default 90 days)
- User-provided secrets: No (manual rotation required)
- ServiceAccount tokens: Yes (Kubernetes auto-rotation)

### Authentication Mechanisms

| Pattern | Components Using | Enforcement Point | Protocol |
|---------|------------------|-------------------|----------|
| Bearer Tokens (JWT) - OpenShift OAuth | Dashboard, Workbenches, MLflow, Model Registry | kube-rbac-proxy, OAuth proxy | OAuth 2.0 / OIDC |
| Bearer Tokens - Kubernetes ServiceAccount | All operators, internal service-to-service | Kubernetes API Server | Kubernetes TokenReview |
| mTLS Client Certs | KServe (Istio), Feast (optional), Ray (optional) | Istio PeerAuthentication, ServiceMesh | mTLS |
| AWS IAM Credentials | Pipelines, KServe, Training, Feast (S3 access) | AWS SDK | SigV4 |
| Username/Password | PostgreSQL, MySQL, MariaDB connections | Database servers | Database auth protocols |
| API Keys | NVIDIA NGC (odh-model-controller), HuggingFace (Training) | External APIs | HTTPS Bearer |
| Kubernetes RBAC | Feature servers (Feast, MLflow) | SubjectAccessReview on Service resources | Kubernetes RBAC |

### Network Policies

| Component | Policy Pattern | Purpose |
|-----------|---------------|---------|
| Data Science Pipelines | Allow ingress on 8443/8888/8887 from monitoring, DSP components, workbenches | Restrict API server access |
| Data Science Pipelines | Allow ingress on 3306 to MariaDB from operator, API server, MLMD | Restrict database access |
| KServe | InferenceService isolation (allow from Istio gateway, same namespace) | Inference pod security |
| Kubeflow Trainer | Allow inter-pod communication within JobSet, allow controller metrics polling | Training job isolation |
| Model Registry | Allow PostgreSQL ingress from model-registry pods only | Database isolation |
| Llama Stack | Ingress-only from same namespace, operator namespace, configured allowed namespaces | Network isolation |
| redhat-ods-applications | Allow 8443, 8080, 8081, 5432, 8082, 8099, 8181, 9443/TCP from any | Application namespace policy |

## Platform APIs

### Custom Resource Definitions

**Core Platform APIs**:

| API Group | Kind | Purpose |
|-----------|------|---------|
| datasciencecluster.opendatahub.io | DataScienceCluster | Platform-level component deployment configuration |
| dscinitialization.opendatahub.io | DSCInitialization | Platform initialization (monitoring, auth, service mesh) |
| components.platform.opendatahub.io | Dashboard, Workbenches, DataSciencePipelines, Kserve, ModelRegistry, etc. | Individual component lifecycle (15+ kinds) |
| services.platform.opendatahub.io | Monitoring, Auth, GatewayConfig | Infrastructure service configuration |
| infrastructure.opendatahub.io | HardwareProfile | Hardware acceleration profiles (GPU, etc.) |

**Workbench APIs**:

| API Group | Kind | Purpose |
|-----------|------|---------|
| kubeflow.org | Notebook | Jupyter notebook instance definition |
| gateway.networking.k8s.io | HTTPRoute, ReferenceGrant | Gateway API routing for notebooks |

**Model Serving APIs**:

| API Group | Kind | Purpose |
|-----------|------|---------|
| serving.kserve.io | InferenceService, ServingRuntime, ClusterServingRuntime | Model serving deployments and templates |
| serving.kserve.io | InferenceGraph | Multi-model inference pipelines |
| serving.kserve.io | TrainedModel, ClusterStorageContainer, LocalModelCache | Multi-model serving and caching |
| serving.kserve.io | LLMInferenceService, LLMInferenceServiceConfig | LLM-specific serving with disaggregated architecture |
| nim.opendatahub.io | Account | NVIDIA NIM account credentials and configurations |

**Pipeline APIs**:

| API Group | Kind | Purpose |
|-----------|------|---------|
| datasciencepipelinesapplications.opendatahub.io | DataSciencePipelinesApplication | Pipeline stack deployment |
| pipelines.kubeflow.org | Pipeline, PipelineVersion | Pipeline definitions |
| kubeflow.org | ScheduledWorkflow | Scheduled pipeline executions |
| argoproj.io | Workflow | Argo workflow execution (managed by pipelines) |

**Model Management APIs**:

| API Group | Kind | Purpose |
|-----------|------|---------|
| modelregistry.opendatahub.io | ModelRegistry | Model metadata registry instances |
| mlflow.opendatahub.io | MLflow | MLflow experiment tracking instances |

**Training APIs**:

| API Group | Kind | Purpose |
|-----------|------|---------|
| kubeflow.org | PyTorchJob, TFJob, XGBoostJob, MPIJob, JAXJob, PaddleJob | Framework-specific distributed training |
| trainer.kubeflow.org | TrainJob, TrainingRuntime, ClusterTrainingRuntime | Unified training API with runtime templates |

**Feature Store APIs**:

| API Group | Kind | Purpose |
|-----------|------|---------|
| feast.dev | FeatureStore | Feast feature store deployments |

**Distributed Computing APIs**:

| API Group | Kind | Purpose |
|-----------|------|---------|
| ray.io | RayCluster, RayJob, RayService | Ray distributed computing clusters |

**LLM/GenAI APIs**:

| API Group | Kind | Purpose |
|-----------|------|---------|
| llamastack.io | LlamaStackDistribution | Llama Stack server deployments |

**Explainability/Governance APIs**:

| API Group | Kind | Purpose |
|-----------|------|---------|
| trustyai.opendatahub.io | TrustyAIService, LMEvalJob, GuardrailsOrchestrator, NemoGuardrails | AI explainability and LLM safety |

### Public HTTP Endpoints

**User-Facing Endpoints**:

| Component | Path Pattern | Method | Port | Auth | Purpose |
|-----------|--------------|--------|------|------|---------|
| ODH Dashboard | / | GET, POST | 8443/TCP | OAuth Bearer | Main platform UI |
| Workbenches | /notebook/{namespace}/{username}/* | GET, POST, WebSocket | 8888/TCP (via HTTPRoute) | OAuth Bearer | Jupyter/RStudio/CodeServer |
| KServe | /v1/models/:name:predict | POST | 8000/TCP | Bearer/None | Model prediction (KServe v1) |
| KServe | /v2/models/:name/infer | POST | 8000/TCP | Bearer/None | Model inference (KServe v2) |
| KServe | /openai/v1/completions, /openai/v1/chat/completions | POST | 8000/TCP | Bearer Token | OpenAI-compatible LLM endpoints |
| Data Science Pipelines | /apis/v2beta1/* | GET, POST, DELETE | 8888/TCP | Bearer Token | Pipeline management API |
| Model Registry | /api/model_registry/v1alpha3/* | GET, POST, PUT, PATCH, DELETE | 8443/TCP | kube-rbac-proxy | Model metadata CRUD |
| MLflow | /api/2.0/*, /mlflow/* | ALL | 8443/TCP | Bearer Token | Experiment tracking and model registry |
| Feast | /get-online-features | POST | 6566/TCP or 6567/TCP | Bearer/mTLS/None | Real-time feature retrieval |
| Feast | /get-historical-features | POST | 8815/TCP or 8816/TCP | Bearer/mTLS/None | Historical features for training |
| TrustyAI | /q/metrics | GET | 8080/TCP | None | Explainability metrics |

**Operator Endpoints** (cluster-internal):

| Component | Path | Method | Port | Auth | Purpose |
|-----------|------|--------|------|------|---------|
| All Operators | /metrics | GET | 8080/TCP or 8443/TCP | Bearer Token (ServiceAccount) | Prometheus metrics |
| All Operators | /healthz | GET | 8081/TCP | None | Liveness probe |
| All Operators | /readyz | GET | 8081/TCP | None | Readiness probe |
| All Operators | /validate-*, /mutate-* | POST | 9443/TCP | K8s API Server mTLS | Admission webhooks |

## Data Flows

### Key Platform Workflows

#### Workflow 1: Notebook-Based Model Development and Deployment

| Step | Component | Action | Port/Protocol | Next Component |
|------|-----------|--------|---------------|----------------|
| 1 | User Browser | Accesses Dashboard | 443/HTTPS (OAuth) | ODH Dashboard |
| 2 | ODH Dashboard | Creates Notebook CR | 6443/HTTPS (K8s API) | kubeflow/notebook-controller |
| 3 | kubeflow/notebook-controller | Creates StatefulSet + Service | 6443/HTTPS (K8s API) | Kubernetes Scheduler |
| 4 | odh-notebook-controller | Creates HTTPRoute + NetworkPolicy | 6443/HTTPS (K8s API) | Gateway API |
| 5 | User Browser | Accesses Jupyter via Gateway | 443/HTTPS (OAuth) | Notebook Pod |
| 6 | Notebook (user code) | Trains model, saves to S3 | 443/HTTPS (S3 API) | S3 Storage |
| 7 | Notebook (user code) | Submits InferenceService CR | 6443/HTTPS (K8s API) | KServe + odh-model-controller |
| 8 | KServe | Downloads model from S3, deploys predictor | 443/HTTPS (S3 API), pod scheduling | S3 → Inference Pod |
| 9 | odh-model-controller | Creates Route + ServiceMonitor | 6443/HTTPS (K8s API) | OpenShift Router + Prometheus |

#### Workflow 2: Pipeline-Based Training and Model Deployment

| Step | Component | Action | Port/Protocol | Next Component |
|------|-----------|--------|---------------|----------------|
| 1 | User Browser | Creates Pipeline via Dashboard | 443/HTTPS (OAuth) | ODH Dashboard |
| 2 | ODH Dashboard | Submits pipeline run | 8888/HTTPS (Pipeline API) | Data Science Pipelines API |
| 3 | Pipeline API | Creates Argo Workflow | 6443/HTTPS (K8s API) | Argo Workflow Controller |
| 4 | Argo Workflow | Launches pipeline pods | Pod scheduling | Training Pods |
| 5 | Training Pod | Trains model, saves to S3 | 443/HTTPS (S3 API) | S3 Storage |
| 6 | Training Pod | Logs to MLMD gRPC | 8080/gRPC | ML Metadata Service |
| 7 | Pipeline Task | Creates InferenceService CR | 6443/HTTPS (K8s API) | KServe |
| 8 | KServe | Deploys model | Pod scheduling | Inference Pod |
| 9 | Pipeline Task | Registers model | 8443/HTTPS (Model Registry API) | Model Registry |

#### Workflow 3: Distributed Training with Kubeflow Trainer

| Step | Component | Action | Port/Protocol | Next Component |
|------|-----------|--------|---------------|----------------|
| 1 | User/SDK | Creates TrainJob CR | 6443/HTTPS (K8s API) | Kubeflow Trainer |
| 2 | Kubeflow Trainer | Validates via webhook | 9443/HTTPS (mTLS) | Validation |
| 3 | Kubeflow Trainer | Creates JobSet + NetworkPolicy | 6443/HTTPS (K8s API) | JobSet Controller |
| 4 | JobSet Controller | Creates training pods | Pod scheduling | Training Pods (multi-node) |
| 5 | Training Pods | Download dataset/model | 443/HTTPS | HuggingFace Hub / S3 |
| 6 | Training Pods | Inter-pod communication | Dynamic TCP (MPI/NCCL) | Same-job pods |
| 7 | Training Pods | Expose metrics | 28080/HTTP | Kubeflow Trainer (progression tracking) |
| 8 | Kubeflow Trainer | Polls metrics, updates status | 28080/HTTP (NetworkPolicy allowed) | Training Pods |
| 9 | Training Pods | Save checkpoints | 443/HTTPS (S3 API) | S3 Storage |

#### Workflow 4: Feature Store Integration

| Step | Component | Action | Port/Protocol | Next Component |
|------|-----------|--------|---------------|----------------|
| 1 | User/SDK | Registers feature definitions | 6570/gRPC or 6572/HTTP | Feast Registry Server |
| 2 | Feast Registry | Persists metadata | 5432/PostgreSQL or local SQLite | PostgreSQL |
| 3 | CronJob (scheduled) | Triggers materialization | 6566/HTTP (Feast API) | Feast Online Server |
| 4 | Feast Online | Fetches from offline store | 8815/HTTP | Feast Offline Server |
| 5 | Feast Offline | Reads from S3 | 443/HTTPS (S3 API) | S3 Storage |
| 6 | Feast Online | Writes to online store | 6379/Redis or 5432/PostgreSQL | Redis/PostgreSQL |
| 7 | Training Job | Retrieves features | 8815/HTTP (offline) | Feast Offline Server |
| 8 | Inference Service | Retrieves features | 6566/gRPC or HTTP (online) | Feast Online Server |

#### Workflow 5: Model Monitoring with TrustyAI

| Step | Component | Action | Port/Protocol | Next Component |
|------|-----------|--------|---------------|----------------|
| 1 | User | Creates TrustyAIService CR | 6443/HTTPS (K8s API) | TrustyAI Operator |
| 2 | TrustyAI Operator | Patches InferenceService | 6443/HTTPS (K8s API) | KServe |
| 3 | KServe | Injects TrustyAI payload processor | Istio VirtualService update | InferenceService Pod |
| 4 | Inference Request | Flows through VirtualService | 443/HTTPS (Istio mTLS) | TrustyAI Service |
| 5 | TrustyAI Service | Logs request/response | Database/PVC write | PostgreSQL or PVC |
| 6 | TrustyAI Service | Computes metrics (drift, bias) | In-memory processing | TrustyAI metrics endpoint |
| 7 | Prometheus | Scrapes TrustyAI metrics | 8080/HTTP | TrustyAI Service |
| 8 | Grafana / Dashboard | Queries metrics | Prometheus query | Prometheus |

## Deployment Architecture

### Deployment Topology

```
┌─────────────────────────────────────────────────────────────────┐
│                     OpenShift Cluster                           │
│                                                                 │
│  ┌───────────────────────────────────────────────────────────┐ │
│  │ redhat-ods-operator (Control Plane)                       │ │
│  │  • RHODS Operator (3 replicas, leader election)           │ │
│  │  • Component Operators (kserve, pipelines, model-registry)│ │
│  └───────────────────────────────────────────────────────────┘ │
│                                                                 │
│  ┌───────────────────────────────────────────────────────────┐ │
│  │ redhat-ods-applications (Platform Services)               │ │
│  │  • ODH Dashboard (2 replicas, web UI)                     │ │
│  │  • MLflow Operator + MLflow Instances                     │ │
│  │  • Llama Stack Operator                                   │ │
│  └───────────────────────────────────────────────────────────┘ │
│                                                                 │
│  ┌───────────────────────────────────────────────────────────┐ │
│  │ redhat-ods-monitoring (Observability)                     │ │
│  │  • Prometheus, AlertManager, Grafana                      │ │
│  └───────────────────────────────────────────────────────────┘ │
│                                                                 │
│  ┌───────────────────────────────────────────────────────────┐ │
│  │ openshift-ingress (Gateway)                               │ │
│  │  • data-science-gateway (Gateway API)                     │ │
│  │  • OpenShift Router                                       │ │
│  └───────────────────────────────────────────────────────────┘ │
│                                                                 │
│  ┌───────────────────────────────────────────────────────────┐ │
│  │ User Namespaces (Workloads)                               │ │
│  │  • Notebooks (StatefulSet per user)                       │ │
│  │  • InferenceServices (KServe predictors)                  │ │
│  │  • Training Jobs (PyTorchJob, TrainJob, etc.)             │ │
│  │  • Pipeline Runs (Argo Workflow pods)                     │ │
│  │  • Model Registries (PostgreSQL + REST API)               │ │
│  │  • Feature Stores (Feast online/offline/registry)         │ │
│  │  • Ray Clusters (head + workers)                          │ │
│  │  • TrustyAI Services (monitoring + guardrails)            │ │
│  └───────────────────────────────────────────────────────────┘ │
│                                                                 │
│  ┌───────────────────────────────────────────────────────────┐ │
│  │ Optional: istio-system, knative-serving                   │ │
│  └───────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘

External Dependencies:
  • S3-compatible storage (AWS S3, MinIO, etc.)
  • PostgreSQL/MySQL (for Model Registry, MLflow, Feast, TrustyAI)
  • Redis (for Feast online store)
  • Image Registries (Quay, RHIO)
  • HuggingFace Hub, NVIDIA NGC (model downloads)
```

### Resource Requirements

Aggregated resource requirements for core platform components (minimum cluster sizing):

| Component | CPU Request | CPU Limit | Memory Request | Memory Limit | Storage |
|-----------|-------------|-----------|----------------|--------------|---------|
| RHODS Operator | 100m | 1000m | 780Mi | 4Gi | N/A |
| ODH Dashboard (per replica) | 500m | 1000m | 1Gi | 2Gi | N/A |
| KServe Controller | 10m | 500m | 64Mi | 2Gi | N/A |
| odh-model-controller | 10m | 500m | 64Mi | 2Gi | N/A |
| Data Science Pipelines Operator | Varies | Varies | Varies | Varies | N/A |
| Model Registry Operator | 200m | 1 core | 400Mi | 4Gi | N/A |
| Training Operator | Varies | Varies | Varies | Varies | N/A |
| Kubeflow Trainer | Varies | Varies | Varies | Varies | N/A |
| Feast Operator | 10m | 1000m | 64Mi | 256Mi | N/A |
| MLflow Operator | 200m | 1 core | 400Mi | 4Gi | N/A |
| **Total Platform Overhead** | **~2 cores** | **~8 cores** | **~4Gi** | **~20Gi** | N/A |

**User Workload Resources** (examples):
- Notebook (Jupyter): 500m CPU, 2Gi memory, 10Gi PVC
- InferenceService (1 GPU): 1 NVIDIA GPU, 4Gi memory
- Training Job (4 nodes × 8 GPUs): 32 GPUs, 512Gi memory
- Pipeline Run (medium): 4 cores, 16Gi memory
- Model Registry (PostgreSQL): 2 cores, 4Gi memory, 20Gi PVC
- Feature Store (with Redis): 1 core, 2Gi memory, 10Gi PVC

**Recommended Minimum Cluster**:
- Control Plane: 3 nodes (16 cores, 64Gi memory each)
- Worker Nodes: 3+ nodes (16 cores, 64Gi memory each)
- GPU Nodes: Variable based on workload (1-8 GPUs per node)
- Total Storage: 500Gi+ (block storage for PVCs, object storage for artifacts)

## Version-Specific Changes (3.3)

| Component | Notable Changes in 3.3 |
|-----------|------------------------|
| RHODS Operator | - v1.6.0 with component architecture refactoring<br>- New component CRDs (components.platform.opendatahub.io)<br>- Multi-group API support<br>- Enhanced upgrade and cleanup logic |
| ODH Dashboard | - v1.21.0 with modular architecture (micro-frontends)<br>- Module federation for GenAI, MaaS, Model Registry UIs<br>- Node.js 22 upgrade<br>- PatternFly 6 adoption<br>- Gateway API HTTPRoute integration |
| KServe | - v0.15 with LLMInferenceService for disaggregated LLM serving<br>- InferencePool v1 API migration<br>- vLLM block-size configuration updates<br>- Multi-architecture support (ppc64le, s390x)<br>- Storage initializer fixes for ARM architectures |
| odh-model-controller | - NVIDIA NIM integration with Account CRD<br>- Spyre templates for ppc64le LLM serving<br>- MAAS_NAMESPACE configuration via downward API<br>- NetworkPolicy enhancements |
| Data Science Pipelines | - KFP v2 API enhancements<br>- Optional MLMD (ML Metadata) support<br>- Improved artifact handling with signed URLs<br>- Argo Workflows integration updates |
| Workbenches (Notebooks) | - Python 3.12 as default<br>- PyTorch 2.9 + TensorFlow upgrades<br>- CUDA 12.8 and ROCm 6.3 support<br>- LLM Compressor integration<br>- Konflux CI/CD migration complete |
| Kubeflow Trainer | - v2.1.0 with progression tracking (RHOAI-specific)<br>- NetworkPolicy creation for training jobs<br>- PyTorch 2.9 runtime images<br>- Enhanced metrics polling for training status |
| Training Operator | - v1.9.0 with JAX and PaddlePaddle job support<br>- CVE-2026-2353 fix (secrets RBAC scoping)<br>- Go 1.25 upgrade<br>- PodMonitor integration for metrics |
| Model Registry | - v1beta1 API stabilization<br>- NetworkPolicy for PostgreSQL isolation<br>- gRPC endpoint deprecated/removed<br>- Enhanced migration support (v1alpha1 → v1beta1) |
| MLflow | - v3.6.0 server with kubernetes-auth<br>- Gateway API HTTPRoute integration<br>- Tracing API support<br>- Helm chart updates |
| Feast | - v0.59.0 release<br>- dbt integration for FeatureViews<br>- Lambda materialization engine improvements<br>- OIDC secret improvements |
| Llama Stack | - v0.6.0 operator with v0.4.2 stack<br>- NetworkPolicy enabled by default<br>- CA bundle volume conflict fixes<br>- Image override via ConfigMap |
| TrustyAI | - v1.39.0 with GuardrailsOrchestrator enhancements<br>- urllib3 security updates<br>- LMEvalJob improvements |
| KubeRay | - v1.4.2 with authentication ready condition handling<br>- FIPS compliance updates<br>- Enhanced status handling |

## Platform Maturity

### Quantitative Analysis

- **Total Components**: 15 operators + 1 dashboard
- **Operator-based Components**: 14/15 (93%)
- **Service Mesh Coverage**: KServe, TrustyAI, Feast (optional), Ray (optional) - ~27% mandatory, 60% optional
- **mTLS Enforcement**: PERMISSIVE (default) - opt-in STRICT mode available
- **CRD API Versions**:
  - v1: 8 component groups (stable)
  - v1beta1: 5 component groups (beta stability)
  - v1alpha1: 12 component groups (evolving)
- **Authentication**: 100% OAuth-integrated user-facing services
- **TLS Coverage**: 100% external ingress encrypted (HTTPS), webhook servers mTLS
- **Konflux CI/CD**: 100% components built via Konflux with security scanning
- **FIPS Compliance**: All Go operators built with strictfipsruntime

### Qualitative Assessment

**Strengths**:
1. **Comprehensive Coverage**: End-to-end ML lifecycle from data preparation to serving
2. **OpenShift Integration**: Deep integration with Routes, OAuth, Service CA, Gateway API
3. **Modular Architecture**: Component operators can be deployed independently
4. **Multi-Framework Support**: PyTorch, TensorFlow, XGBoost, JAX, PaddlePaddle, Ray
5. **GPU Acceleration**: NVIDIA CUDA, AMD ROCm, Intel optimizations
6. **Security Posture**: OAuth, RBAC, NetworkPolicies, mTLS, secret management
7. **Observability**: Prometheus metrics, ServiceMonitors, distributed tracing
8. **Developer Experience**: Jupyter notebooks, pipelines, experiment tracking
9. **LLM Support**: vLLM, NVIDIA NIM, Llama Stack, OpenAI-compatible APIs
10. **Production Features**: Autoscaling, gang scheduling, distributed training, model monitoring

**Areas for Improvement**:
1. **API Stability**: Many components still in v1alpha1, need graduation to v1beta1/v1
2. **Service Mesh Adoption**: Optional/inconsistent service mesh integration across components
3. **Secret Management**: Manual rotation for most user-provided secrets
4. **Multi-Cluster**: No built-in multi-cluster or hybrid cloud support
5. **Unified Logging**: No centralized logging aggregation for user workloads
6. **Cost Management**: No built-in resource usage tracking or chargeback
7. **Documentation**: Need more runbooks for production operations and troubleshooting

## Next Steps for Documentation

### Immediate Priorities

1. **Generate Architecture Diagrams**:
   - Component dependency graph (directed acyclic graph)
   - Network flow diagrams (external ingress/egress)
   - Security architecture (authentication/authorization flows)
   - Deployment topology (namespace organization)

2. **Create Security Documentation**:
   - Security Architecture Review (SAR) document for compliance
   - Network policy reference guide
   - Secret rotation procedures
   - RBAC permission matrices for user roles

3. **Develop Operations Runbooks**:
   - Component upgrade procedures
   - Disaster recovery and backup strategies
   - Troubleshooting guides (organized by symptom)
   - Monitoring and alerting setup

4. **Document Integration Patterns**:
   - Service-to-service communication patterns
   - Storage integration (S3, databases, PVCs)
   - Authentication/authorization flows
   - Custom resource relationship diagrams

### Future Documentation

5. **Update Architecture Decision Records (ADRs)**:
   - Document architectural decisions for component selections
   - Gateway API vs OpenShift Routes strategy
   - Service mesh adoption patterns
   - CRD versioning and migration strategies

6. **Create User Guides**:
   - Getting started guides for each component
   - Best practices for production deployments
   - Performance tuning recommendations
   - Multi-tenancy configuration patterns

7. **Generate Reference Documentation**:
   - Complete CRD API reference (auto-generated from OpenAPI schemas)
   - Environment variable reference for all components
   - Metrics reference (Prometheus metrics catalog)
   - Alert reference (AlertManager rules documentation)

8. **Develop Training Materials**:
   - Administrator training for platform operations
   - Developer training for component usage
   - Architecture workshops for solution architects
   - Video tutorials for common workflows

### Tooling Recommendations

- **Diagrams**: Use Mermaid, PlantUML, or draw.io for architecture diagrams
- **API Docs**: Use swagger-ui or redoc for interactive API documentation
- **Runbooks**: Store in Git as Markdown with searchable index
- **Metrics**: Use Prometheus recording rules and Grafana dashboards
- **Testing**: Implement automated e2e tests validating documented workflows

---

**Document Metadata**:
- Generated: 2026-03-15
- Source: architecture/rhoai-3.3/ (15 component architecture files)
- Components: RHODS Operator, ODH Dashboard, Data Science Pipelines, KServe, odh-model-controller, Model Registry, Workbenches, ODH Notebook Controller, Training Operator, Kubeflow Trainer, KubeRay, Feast, MLflow, Llama Stack, TrustyAI
- Distribution: Red Hat OpenShift AI (RHOAI)
- Version: 3.3
- Status: Platform-level aggregation complete
