# Architecture Diagrams for RHOAI 2.25.0 Components

Generated from architecture documentation in `architecture/rhoai-2.25.0/`
Date: 2026-03-14

**Note**: Diagram filenames use base component name without version (directory is already versioned).

## Available Diagrams

All Mermaid diagrams are available in both `.mmd` (source) and `.png` (3000px width, high-resolution) formats.

---

## Platform Overview (All Components)

Generated from: `architecture/rhoai-2.25.0/PLATFORM.md`

### For Developers
- [Component Structure](./platform-component.png) ([mmd](./platform-component.mmd)) - Mermaid diagram showing all 15 platform components organized by functional layer
- [Data Flows](./platform-dataflow.png) ([mmd](./platform-dataflow.mmd)) - End-to-end sequence diagram from model development to production serving
- [Dependencies](./platform-dependencies.png) ([mmd](./platform-dependencies.mmd)) - Platform-wide dependency graph showing all component relationships

### For Architects
- [C4 Context](./platform-c4-context.dsl) - System context in C4 format (Structurizr) showing RHOAI in broader enterprise ecosystem
- [Component Overview](./platform-component.png) ([mmd](./platform-component.mmd)) - High-level platform architecture with all 15 components

### For Security Teams
- [Security Network Diagram (PNG)](./platform-security-network.png) - High-resolution network topology with trust zones
- [Security Network Diagram (Mermaid)](./platform-security-network.mmd) - Visual network topology (editable)
- [Security Network Diagram (ASCII)](./platform-security-network.txt) - Comprehensive SAR format with RBAC, secrets, auth mechanisms, compliance posture
- [RBAC Visualization](./platform-rbac.png) ([mmd](./platform-rbac.mmd)) - Complete RBAC permissions across all 14 operators

### Platform Overview

Red Hat OpenShift AI (RHOAI) 2.25.0 is a comprehensive enterprise AI/ML platform with **15 integrated components**:

**User Interface Layer**:
- ODH Dashboard (v1.21.0-18) - Primary web UI for platform management

**Development Environment**:
- Kubeflow Notebook Controller (v1.27.0) - Manages Jupyter, VS Code, RStudio instances
- Notebook Images (v2.25.2) - JupyterLab, VS Code, RStudio workbench containers

**Model Serving Layer**:
- KServe Operator (4211a5da7) - Serverless model inference with autoscaling
- ModelMesh Serving (1.27.0) - Multi-model serving with high-density placement
- ODH Model Controller (1.27.0) - Routes, service mesh, authentication orchestration
- Llama Stack Operator (0.3.0) - LLM inference server deployment

**Training & Distributed Compute**:
- Training Operator (1.9.0) - PyTorch, TensorFlow, XGBoost, MPI, JAX, PaddlePaddle
- KubeRay Operator (f10d68b1) - Ray distributed computing clusters
- CodeFlare Operator (1.15.0) - Distributed AI/ML workload orchestration

**Pipeline Orchestration**:
- Data Science Pipelines Operator (rhoai-2.25) - Kubeflow Pipelines with Argo Workflows

**Resource Management**:
- Kueue (7f2f72e51) - Job queueing and resource quota management

**Model Lifecycle Management**:
- Model Registry Operator (0b48221) - Model metadata storage and versioning
- Feast Operator (0.54.0) - Feature store for ML feature management

**AI Governance**:
- TrustyAI Service Operator (d113dae) - Explainability, bias detection, LM evaluation

**Key Platform Metrics**:
- Total Components: 15
- Operator-based: 14 (93%)
- External Platform Dependencies: 7 (Istio, Knative, OpenShift, cert-manager, Prometheus, Volcano, Authorino)
- Custom Resource Definitions: 30+ types
- Service Mesh Coverage: ~40%
- OAuth Integration: 6 components
- Webhook Coverage: 12 of 14 operators

**Security Highlights**:
- FIPS-compliant (Go 1.25+ in RHOAI 2.25.0)
- All containers run as non-root
- mTLS for service mesh (STRICT mode available)
- TLS 1.2+ for all external connections
- 8 authentication mechanisms (OAuth, Kubernetes RBAC, Istio mTLS, AWS IAM, database auth, etc.)
- Multi-tenant with namespace isolation

**Integration Patterns**:
- CRD Watch & Reconciliation (all operators)
- Service Mesh Integration (KServe, ODH Model Controller, TrustyAI)
- OpenShift Route Creation (KServe, Model Registry, DSPA, TrustyAI)
- OAuth Authentication (Dashboard, Model Registry, DSPA, CodeFlare, Notebooks)
- Metrics Collection (all operators expose Prometheus metrics)
- Webhook Admission Control (12 operators)
- Gang Scheduling (Training Operator, KubeRay, CodeFlare via Volcano)
- Workload Queueing (Kueue manages admission for training, pipelines, Ray)
- Model Artifact Storage (S3 API used by KServe, ModelMesh, DSPA, Training)

---

## Feast (Feature Store)

Generated from: `architecture/rhoai-2.25.0/feast.md`

### For Developers
- [Component Structure](./feast-component.png) ([mmd](./feast-component.mmd)) - Mermaid diagram showing internal components
- [Data Flows](./feast-dataflow.png) ([mmd](./feast-dataflow.mmd)) - Sequence diagram of request/response flows
- [Dependencies](./feast-dependencies.png) ([mmd](./feast-dependencies.mmd)) - Component dependency graph

### For Architects
- [C4 Context](./feast-c4-context.dsl) - System context in C4 format (Structurizr)
- [Component Overview](./feast-component.png) ([mmd](./feast-component.mmd)) - High-level component view

### For Security Teams
- [Security Network Diagram (PNG)](./feast-security-network.png) - High-resolution network topology
- [Security Network Diagram (Mermaid)](./feast-security-network.mmd) - Visual network topology (editable)
- [Security Network Diagram (ASCII)](./feast-security-network.txt) - Precise text format for SAR submissions
- [RBAC Visualization](./feast-rbac.png) ([mmd](./feast-rbac.mmd)) - RBAC permissions and bindings

### Component Overview

Feast is an open-source feature store for machine learning that provides:
- **Online Feature Store**: Low-latency feature serving for real-time inference
- **Offline Feature Store**: Historical feature retrieval for model training
- **Registry Server**: Centralized metadata repository for feature definitions
- **UI Server** (Optional): Web interface for feature discovery
- **CronJob**: Scheduled materialization tasks

**Version**: 0.54.0 (aad1ebcd0)

**Key Features**:
- Multiple storage backends (Redis, PostgreSQL, SQLite, S3/GCS, Snowflake)
- Configurable authentication (None, Kubernetes RBAC, OIDC)
- Optional TLS encryption for all services
- Point-in-time correct feature retrieval (prevents data leakage)

---

## Data Science Pipelines Operator

Generated from: `architecture/rhoai-2.25.0/data-science-pipelines-operator.md`

### For Developers
- [Component Structure](./data-science-pipelines-operator-component.png) ([mmd](./data-science-pipelines-operator-component.mmd)) - Mermaid diagram showing internal components, CRDs, and dependencies
- [Data Flows](./data-science-pipelines-operator-dataflow.png) ([mmd](./data-science-pipelines-operator-dataflow.mmd)) - Sequence diagram of pipeline submission, execution, artifact access, and MLMD queries
- [Dependencies](./data-science-pipelines-operator-dependencies.png) ([mmd](./data-science-pipelines-operator-dependencies.mmd)) - Component dependency graph showing external and internal dependencies

### For Architects
- [C4 Context](./data-science-pipelines-operator-c4-context.dsl) - System context in C4 format (Structurizr)
- [Component Overview](./data-science-pipelines-operator-component.png) ([mmd](./data-science-pipelines-operator-component.mmd)) - High-level component view with DSPO controller, API server, and workflow controllers

### For Security Teams
- [Security Network Diagram (PNG)](./data-science-pipelines-operator-security-network.png) - High-resolution network topology with trust zones
- [Security Network Diagram (Mermaid)](./data-science-pipelines-operator-security-network.mmd) - Visual network topology (editable)
- [Security Network Diagram (ASCII)](./data-science-pipelines-operator-security-network.txt) - Precise text format for SAR submissions
- [RBAC Visualization](./data-science-pipelines-operator-rbac.png) ([mmd](./data-science-pipelines-operator-rbac.mmd)) - RBAC permissions and bindings for operator and DSPA instances

### Component Overview

The Data Science Pipelines Operator (DSPO) manages the lifecycle of Data Science Pipeline applications based on Kubeflow Pipelines. Key components include:

- **DSPO Controller**: Kubernetes operator that reconciles DataSciencePipelinesApplication CRs
- **API Server**: Main DSP API for pipeline management, execution, and artifact access (ports 8888/8887)
- **Workflow Controller**: Namespace-scoped Argo Workflows controller for pipeline orchestration (DSP v2)
- **Persistence Agent**: Syncs workflow execution status to database
- **Scheduled Workflow Controller**: Manages recurring pipeline executions
- **Optional Components**: MariaDB, Minio, ML Pipelines UI, MLMD gRPC, MLMD Envoy

**Key Features**:
- **Dual Version Support**: DSP v1 (Tekton) and v2 (Argo Workflows, recommended)
- **Pod-to-Pod TLS**: Configurable mTLS between components (default: enabled in v2)
- **Namespace Isolation**: Each DSPA instance is namespace-scoped with dedicated resources
- **Integration**: KServe for model serving, Ray for distributed computing, ODH Dashboard for UI
- **Security**: OAuth proxy authentication, network policies, RBAC, TLS encryption

---

## Kueue (Job Queue Management)

Generated from: `architecture/rhoai-2.25.0/kueue.md`

### For Developers
- [Component Structure](./kueue-component.png) ([mmd](./kueue-component.mmd)) - Mermaid diagram showing internal components, reconcilers, job integrations, and CRDs
- [Data Flows](./kueue-dataflow.png) ([mmd](./kueue-dataflow.mmd)) - Sequence diagram of job submission, admission, metrics collection, visibility API, and autoscaling flows
- [Dependencies](./kueue-dependencies.png) ([mmd](./kueue-dependencies.mmd)) - Component dependency graph showing required and optional dependencies

### For Architects
- [C4 Context](./kueue-c4-context.dsl) - System context in C4 format (Structurizr) showing Kueue in the broader ecosystem
- [Component Overview](./kueue-component.png) ([mmd](./kueue-component.mmd)) - High-level component view with reconcilers and integrations

### For Security Teams
- [Security Network Diagram (PNG)](./kueue-security-network.png) - High-resolution network topology with trust boundaries
- [Security Network Diagram (Mermaid)](./kueue-security-network.mmd) - Visual network topology (editable)
- [Security Network Diagram (ASCII)](./kueue-security-network.txt) - Precise text format for SAR submissions with detailed RBAC, network policies, and secrets
- [RBAC Visualization](./kueue-rbac.png) ([mmd](./kueue-rbac.mmd)) - RBAC permissions, bindings, and API resource access

### Component Overview

Kueue is a Kubernetes-native job management system that provides intelligent queueing and scheduling for batch workloads. It decides when jobs can be admitted (pods can be created) based on available quota in cluster queues and local queues.

**Version**: rhoai-2.25 branch (7f2f72e51)

**Key Features**:
- **Job Queue Management**: Intelligent queueing and scheduling for batch workloads
- **Resource Quotas**: ClusterQueue and LocalQueue management with ResourceFlavors
- **Fair Sharing**: Cohorts enable resource sharing across teams with preemption policies
- **Multi-Cluster**: MultiKueue feature for job dispatching to remote clusters
- **Topology-Aware**: Optimized pod placement for GPU/network-intensive workloads
- **Autoscaling Integration**: ProvisioningRequest integration with Cluster Autoscaler
- **Job Type Support**: Batch Jobs, Kubeflow (TFJob, PyTorchJob, MPIJob), Ray, JobSet, AppWrapper
- **Visibility API**: On-demand API for querying pending workloads without polling CRDs

**Architecture Highlights**:
- Single-replica deployment with leader election
- Admission webhooks intercept job creation to inject queue annotations
- Scheduler engine evaluates workload priorities and quota
- In-memory cache for fast quota lookups

**Security**:
- FIPS-enabled UBI9 minimal runtime
- Non-root user (65532:65532)
- TLS 1.2+ for all communications
- cert-manager for webhook certificate rotation
- Comprehensive RBAC with user roles (admin, viewer, editor)

**Dependencies**:
- **Required**: Kubernetes 1.25+, cert-manager 1.17+
- **Optional**: Kubeflow, Ray, JobSet, AppWrapper operators, Cluster Autoscaler, Prometheus
- **No internal ODH dependencies** - standalone component

---

## Model Registry Operator

Generated from: `architecture/rhoai-2.25.0/model-registry-operator.md`

### For Developers
- [Component Structure](./model-registry-operator-component.png) ([mmd](./model-registry-operator-component.mmd)) - Mermaid diagram showing internal operator components, CRDs, and deployed instances
- [Data Flows](./model-registry-operator-dataflow.png) ([mmd](./model-registry-operator-dataflow.mmd)) - Sequence diagram of request/response flows (OAuth and non-OAuth modes)
- [Dependencies](./model-registry-operator-dependencies.png) ([mmd](./model-registry-operator-dependencies.mmd)) - Component dependency graph showing external and internal dependencies

### For Architects
- [C4 Context](./model-registry-operator-c4-context.dsl) - System context in C4 format (Structurizr)
- [Component Overview](./model-registry-operator-component.png) ([mmd](./model-registry-operator-component.mmd)) - High-level component view

### For Security Teams
- [Security Network Diagram (PNG)](./model-registry-operator-security-network.png) - High-resolution network topology
- [Security Network Diagram (Mermaid)](./model-registry-operator-security-network.mmd) - Visual network topology (editable)
- [Security Network Diagram (ASCII)](./model-registry-operator-security-network.txt) - Precise text format for SAR submissions
- [RBAC Visualization](./model-registry-operator-rbac.png) ([mmd](./model-registry-operator-rbac.mmd)) - RBAC permissions and bindings

### Component Overview

The Model Registry Operator is a Kubernetes operator that deploys and manages Model Registry instances for ML metadata storage and retrieval.

**Version**: 0b48221 (rhoai-2.25 branch)

**Key Features**:
- **Lifecycle Management**: Deploys and manages Model Registry instances via custom resources
- **Dual Authentication Modes**: OAuth (external access) and non-OAuth (internal cluster access)
- **Database Backend**: PostgreSQL or MySQL support for ML Metadata (MLMD) storage
- **External Exposure**: Optional OpenShift Route creation for external access
- **TLS Certificate Management**: Automatic certificate provisioning via OpenShift Service CA
- **REST API**: `/api/model_registry/v1alpha3/*` for model metadata operations

**Architecture Highlights**:
- **Operator Deployment**: Single replica in operator namespace (e.g., redhat-ods-applications)
- **Instance Deployments**: Per-CR deployments in user namespaces
- **OAuth Mode**: External access via OpenShift OAuth proxy with bearer token authentication
- **Non-OAuth Mode**: Internal cluster access via ClusterIP service (no authentication)
- **Two API Versions**: v1alpha1 (deprecated, Istio auth support) and v1beta1 (current, OAuth only)
- **Conversion Webhook**: Automatic migration from v1alpha1 to v1beta1

**Security**:
- OAuth proxy sidecar for user authentication
- TLS 1.2+ encryption for external access
- Network policies restrict ingress to OpenShift Router
- RBAC with namespace-scoped permissions
- Secrets for database credentials and OAuth session encryption
- Non-root containers with seccomp=RuntimeDefault
- restricted-v2 SCC (OpenShift)

**Integration Points**:
- **KServe**: Fetches model metadata for serving
- **ODH Dashboard**: UI for model registry management
- **Data Science Pipelines**: Registers models from ML workflows
- **ODH/RHOAI Operator**: Platform integration via components.platform.opendatahub.io CRD

**Dependencies**:
- **Required**: PostgreSQL 9.6+ or MySQL 5.7+ (user-managed)
- **Optional**: OpenShift Service CA, OAuth Server, Ingress Router
- **Internal**: odh-model-registry service image, Prometheus for metrics

---

## ODH Dashboard

Generated from: `architecture/rhoai-2.25.0/odh-dashboard.md`

### For Developers
- [Component Structure](./odh-dashboard-component.png) ([mmd](./odh-dashboard-component.mmd)) - Mermaid diagram showing internal components
- [Data Flows](./odh-dashboard-dataflow.png) ([mmd](./odh-dashboard-dataflow.mmd)) - Sequence diagram of request/response flows
- [Dependencies](./odh-dashboard-dependencies.png) ([mmd](./odh-dashboard-dependencies.mmd)) - Component dependency graph

### For Architects
- [C4 Context](./odh-dashboard-c4-context.dsl) - System context in C4 format (Structurizr)
- [Component Overview](./odh-dashboard-component.png) ([mmd](./odh-dashboard-component.mmd)) - High-level component view

### For Security Teams
- [Security Network Diagram (PNG)](./odh-dashboard-security-network.png) - High-resolution network topology
- [Security Network Diagram (Mermaid)](./odh-dashboard-security-network.mmd) - Visual network topology (editable)
- [Security Network Diagram (ASCII)](./odh-dashboard-security-network.txt) - Precise text format for SAR submissions
- [RBAC Visualization](./odh-dashboard-rbac.png) ([mmd](./odh-dashboard-rbac.mmd)) - RBAC permissions and bindings

### Component Overview

ODH Dashboard is the web-based user interface for managing Open Data Hub and Red Hat OpenShift AI platform components. It provides:
- **React Frontend**: Single-page application with PatternFly 6 UI components
- **Fastify Backend**: Node.js API server proxying requests to Kubernetes API
- **OAuth Proxy**: OpenShift OAuth integration for authentication and TLS termination
- **Module Federation**: Dynamic plugin system for feature extensions (Gen AI, Model Registry, Feature Store, LM Eval)

**Version**: v1.21.0-18-rhods-4281-g475248a55

**Key Features**:
- Unified interface for Jupyter notebooks, model serving, pipelines, and distributed workloads
- OpenShift OAuth authentication with RBAC enforcement
- WebSocket support for real-time resource updates
- Modular plugin architecture for dynamic feature loading
- Integration with all ODH/RHOAI platform components
- Multiple deployment modes (ODH, RHOAI Addon, RHOAI On-Premise)

**APIs Managed**:
- Custom Resources: OdhApplication, OdhDashboardConfig, OdhDocument, OdhQuickStart, AcceleratorProfile, HardwareProfile
- Kubernetes Resources: Notebooks, InferenceServices, ModelRegistries, ServingRuntimes
- Platform Resources: DataScienceCluster, DSCInitialization, LlamaStackDistributions

**Dependencies**:
- **Required**: Node.js 20.x, React 18, OpenShift OAuth Server, Kubernetes API
- **Optional**: Prometheus/Thanos for metrics, Segment Analytics for usage tracking
- **Internal**: Integration with all ODH operators (KServe, Notebooks, Model Registry, Pipelines, TrustyAI, Kueue, CodeFlare)

---

## ODH Model Controller

Generated from: `architecture/rhoai-2.25.0/odh-model-controller.md`

### For Developers
- [Component Structure](./odh-model-controller-component.png) ([mmd](./odh-model-controller-component.mmd)) - Mermaid diagram showing internal components, reconcilers, webhooks, and managed resources
- [Data Flows](./odh-model-controller-dataflow.png) ([mmd](./odh-model-controller-dataflow.mmd)) - Sequence diagram of InferenceService creation, inference requests, NIM account management, and metrics collection
- [Dependencies](./odh-model-controller-dependencies.png) ([mmd](./odh-model-controller-dependencies.mmd)) - Component dependency graph showing KServe, Istio, Authorino, and ODH integrations

### For Architects
- [C4 Context](./odh-model-controller-c4-context.dsl) - System context in C4 format (Structurizr) showing ODH Model Controller in the broader ecosystem
- [Component Overview](./odh-model-controller-component.png) ([mmd](./odh-model-controller-component.mmd)) - High-level component view with reconcilers and webhooks

### For Security Teams
- [Security Network Diagram (PNG)](./odh-model-controller-security-network.png) - High-resolution network topology
- [Security Network Diagram (Mermaid)](./odh-model-controller-security-network.mmd) - Visual network topology (editable)
- [Security Network Diagram (ASCII)](./odh-model-controller-security-network.txt) - Precise text format for SAR submissions with RBAC, secrets, and network policies
- [RBAC Visualization](./odh-model-controller-rbac.png) ([mmd](./odh-model-controller-rbac.mmd)) - RBAC permissions showing ClusterRole bindings for KServe, Istio, OpenShift, and NIM resources

### Component Overview

**ODH Model Controller** extends KServe model serving with OpenShift integration, service mesh configuration, authentication, and automated resource management.

**Version**: 1.27.0-rhods-1121-g0ce874f (rhoai-2.25 branch)

**Key Features**:
- **InferenceService Extensions**: Automatically creates OpenShift Routes, Istio VirtualServices, Authorino AuthConfigs, and monitoring resources
- **NVIDIA NIM Integration**: Manages NGC API keys, pull secrets, and ServingRuntime templates for NVIDIA Inference Microservices
- **Multi-Runtime Support**: vLLM (CPU, CUDA, Gaudi, ROCm, multinode), Caikit, OVMS, HuggingFace
- **Service Mesh Integration**: Istio/Maistra PeerAuthentication, Telemetry, and Gateway configuration
- **Security Hardened**: FIPS-compliant, runs as non-root (UID 2000), drops all capabilities

**Architecture Highlights**:
- **Controllers**: InferenceService, InferenceGraph, LLMInferenceService, NIM Account, ServingRuntime, ConfigMap, Secret, Pod
- **Webhooks**: Pod mutation, InferenceService/InferenceGraph validation/mutation, NIM Account validation, Knative Service validation
- **Managed Resources**: Routes, VirtualServices, Gateways, PeerAuthentication, AuthConfigs, ServiceMonitors, NetworkPolicies, RBAC
- **Dependencies**: KServe (required), Istio/Maistra (optional), Authorino (optional), Model Registry (optional)
- **Integration**: Coordinates with KServe Controller, creates OpenShift Routes, manages service mesh resources

**Data Flows**:
1. **InferenceService Creation**: User → K8s API → Webhook validation → Controller reconciliation → KServe creates workload
2. **Inference Request (Serverless)**: Client → Route → Istio Gateway → Authorino → Knative Activator → Predictor Pod → S3 storage
3. **NIM Account Management**: User creates Account → Webhook validation → Controller → NGC API validation → Creates ConfigMap, Secret, Template
4. **Metrics Collection**: Prometheus scrapes controller and inference pod metrics

**Security**:
- **FIPS Mode**: strictfipsruntime (Konflux build)
- **Pod Security**: runAsNonRoot=true, runAsUser=2000, allowPrivilegeEscalation=false, drop all capabilities
- **Network Security**: OpenShift Routes (TLS 1.3), Istio mTLS (optional), Authorino auth, NetworkPolicies
- **RBAC**: Comprehensive ClusterRole for KServe, Istio, OpenShift, monitoring, auth, and NIM resources
- **Secrets**: webhook-server-cert (cert-manager), InferenceService SA tokens, NGC pull secrets, Ray TLS certs
- **Webhooks**: mTLS with K8s API Server for admission control

**Serving Runtime Templates**:
- caikit-standalone, caikit-tgis (NLP models)
- ovms-kserve, ovms-mm (TensorFlow, PyTorch, ONNX)
- vllm-cpu, vllm-cuda, vllm-gaudi, vllm-rocm, vllm-spyre, vllm-multinode (LLMs)
- hf-detector (HuggingFace-based content detection)

---

## TrustyAI Service Operator

Generated from: `architecture/rhoai-2.25.0/trustyai-service-operator.md`

### For Developers
- [Component Structure](./trustyai-service-operator-component.png) ([mmd](./trustyai-service-operator-component.mmd)) - Operator controllers, CRD conversion webhook, managed services
- [Data Flows](./trustyai-service-operator-dataflow.png) ([mmd](./trustyai-service-operator-dataflow.mmd)) - Four main flows: model prediction monitoring, external access, LM eval jobs, guardrails processing
- [Dependencies](./trustyai-service-operator-dependencies.png) ([mmd](./trustyai-service-operator-dependencies.mmd)) - External (K8s, Istio, Kueue, databases) and internal (KServe, ModelMesh, DSP) dependencies

### For Architects
- [C4 Context](./trustyai-service-operator-c4-context.dsl) - Three service types in RHOAI ecosystem (explainability, evaluation, guardrails)
- [Component Overview](./trustyai-service-operator-component.png) ([mmd](./trustyai-service-operator-component.mmd)) - Operator architecture with three controllers

### For Security Teams
- [Security Network Diagram (PNG)](./trustyai-service-operator-security-network.png) - Network topology with trust zones (362K, high-resolution)
- [Security Network Diagram (Mermaid)](./trustyai-service-operator-security-network.mmd) - Visual network diagram (editable)
- [Security Network Diagram (ASCII)](./trustyai-service-operator-security-network.txt) - SAR format with RBAC, OAuth, TLS, secrets details
- [RBAC Visualization](./trustyai-service-operator-rbac.png) ([mmd](./trustyai-service-operator-rbac.mmd)) - Four roles: manager, leader-election, auth-proxy, non-admin-lmeval

### Component Overview

**Three Services Managed**:
1. **TrustyAI Service**: AI explainability (LIME, SHAP), bias detection, fairness metrics for deployed ML models
2. **LM Eval Jobs**: Language model evaluation using lm-evaluation-harness with Kueue workload management
3. **Guardrails Orchestrator**: AI safety detectors for input/output filtering and content moderation

**Key CRDs**:
- `TrustyAIService` (v1, v1alpha1 with conversion webhook)
- `LMEvalJob` (v1alpha1)
- `GuardrailsOrchestrator` (v1alpha1)

**Architecture**:
- **Operator Controller**: Go operator with three reconciliation controllers and CRD conversion webhook
- **OAuth Proxy Sidecars**: OpenShift OAuth authentication for external access via Routes
- **Storage Backends**: PVC (default) or PostgreSQL/MySQL database for TrustyAI Service
- **Metrics**: Operator metrics (8443/HTTPS), service metrics (8080/HTTP) via ServiceMonitors

**Integration Points**:
- **KServe**: Monitors InferenceServices for prediction payloads (ModelMesh payload processor injection)
- **Kueue**: Workload admission and queue management for LM evaluation batch jobs
- **OpenShift OAuth**: User authentication via SAR checks (namespace pods get permission)
- **Istio Service Mesh**: VirtualServices and DestinationRules for KServe serverless mode
- **Prometheus**: Metrics scraping via ServiceMonitors
- **Hugging Face Hub**: Model and dataset downloads for LM evaluations
- **S3 Storage**: LM evaluation result storage

**Data Flows**:
1. **Model Monitoring**: User → KServe → TrustyAI Service (via payload processor) → PVC/Database
2. **External Access**: User → Route → OAuth Proxy → TrustyAI Service
3. **LM Eval Jobs**: User creates LMEvalJob CR → Kueue admission → LMES Pod → Hugging Face/KServe/S3
4. **Guardrails**: User → Route → OAuth Proxy → Guardrails Orchestrator → Detector/Generator InferenceServices

**Security**:
- **Authentication**: OpenShift OAuth with SAR check for service endpoints; health endpoints bypass auth
- **Authorization**: RBAC with manager-role (operator resources) and non-admin-lmeval-role (all users can create jobs)
- **Network Security**: OpenShift Routes (reencrypt TLS 1.2+), service-ca certs (auto-rotate 90 days)
- **Secrets**: TLS certificates (service-ca, cert-manager), database credentials (user-provided), storage credentials (AWS IAM/access keys)
- **Encryption**: TLS 1.2+ for external services, mTLS for ModelMesh integration, service-ca for internal HTTPS

**Deployment**:
- **Images**: quay.io/trustyai (operator, services, LMES, guardrails, driver)
- **Kustomize Overlays**: odh, rhoai, lmes, odh-kueue, testing
- **Resource Requirements**: Operator (10m CPU, 64Mi mem), services (configurable)
- **Health Checks**: /healthz (liveness), /readyz (readiness) for operator and services

---

## How to Use

### PNG Files (.png files)
**Automatically generated** at 3000px width for high-resolution presentations and documentation.

- **Ready to use**: High-resolution images suitable for presentations, wikis, and documentation
- **Width**: 3000px (height auto-adjusts to content)
- **Use directly**: Include in PowerPoint, Google Slides, Confluence, etc.

### Mermaid Source Files (.mmd files)
- **In GitHub/GitLab**: Paste into markdown with \`\`\`mermaid code blocks - renders automatically!
- **Live editor**: https://mermaid.live (paste code, edit, export)
- **Editable**: Modify and regenerate if needed

**Manual PNG regeneration** (if you edit .mmd files):

1. **Ensure Mermaid CLI is installed**:
   ```bash
   npm install -g @mermaid-js/mermaid-cli
   ```

2. **Regenerate PNG** (3000px width):
   ```bash
   PUPPETEER_EXECUTABLE_PATH=/usr/bin/google-chrome mmdc -i diagram.mmd -o diagram.png -w 3000
   ```

3. **Alternative formats** (if needed):
   ```bash
   # SVG (vector, scales perfectly)
   PUPPETEER_EXECUTABLE_PATH=/usr/bin/google-chrome mmdc -i diagram.mmd -o diagram.svg

   # PDF
   PUPPETEER_EXECUTABLE_PATH=/usr/bin/google-chrome mmdc -i diagram.mmd -o diagram.pdf
   ```

**Note**: If `google-chrome` is not found, try `chromium` or `which google-chrome` to locate it

### C4 Diagrams (.dsl files)
- **Structurizr Lite**: `docker run -p 8080:8080 -v .:/usr/local/structurizr structurizr/lite`
- **CLI export**: `structurizr-cli export -workspace diagram.dsl -format png`

### ASCII Diagrams (.txt files)
- View in any text editor
- Include in documentation as-is
- Perfect for security reviews (precise technical details)

---

## Diagram Types Explained

### Component Diagram
Shows the internal structure of the component, including:
- Operator/controller components
- Services and their interactions
- CRDs and their relationships
- External dependencies
- Internal ODH integrations

### Data Flow Diagram
Sequence diagrams showing request/response flows:
- Primary user flows (e.g., feature retrieval, pipeline execution)
- Service-to-service communication
- External API calls
- Operator reconciliation loops

### Security Network Diagram
Detailed network topology with security information:
- **ASCII format** (.txt): Precise text format for Security Architecture Reviews
- **Mermaid format** (.mmd + .png): Visual diagram with color-coded trust zones
- Includes: ports, protocols, TLS versions, authentication mechanisms, trust boundaries

### C4 Context Diagram
System context showing component in broader ecosystem:
- External actors (users, applications)
- Component containers (operator, services)
- Dependencies (Kubernetes, storage, ODH components)
- Integration points

### Dependency Graph
Shows component dependencies and integration points:
- External dependencies (required and optional)
- Internal ODH dependencies
- Integration points with other components
- Storage/infrastructure requirements

### RBAC Diagram
Visualizes RBAC permissions:
- Service accounts
- ClusterRoles and Roles with their permissions
- RoleBindings
- API resources and access levels

---

## File Naming Convention

All diagrams follow the pattern: `{component-name}-{diagram-type}.{extension}`

Examples:
- `feast-component.mmd` / `feast-component.png`
- `data-science-pipelines-operator-dataflow.mmd` / `data-science-pipelines-operator-dataflow.png`
- `feast-security-network.mmd` / `feast-security-network.png` / `feast-security-network.txt`
- `feast-c4-context.dsl`

**Note**: Component names are lowercase and derived from architecture filenames. Version is not included in filenames since the directory `rhoai-2.25.0/` already provides versioning context.

---

## Updating Diagrams

To regenerate diagrams after architecture changes, use the diagram generation workflow or manually run the generation script.

---

## Support

For questions or issues with diagrams:
1. Check the source architecture markdown files in `../` (parent directory)
2. Verify Mermaid CLI installation: `mmdc --version`
3. Test diagrams at https://mermaid.live for syntax validation
4. Regenerate PNGs if needed (see instructions above)

---

## Version Information

**RHOAI Version**: 2.25.0

**Component Versions**:
- Feast: 0.54.0 (aad1ebcd0)
- Data Science Pipelines Operator: (see architecture markdown for version details)

---

## License

These diagrams are generated from RHOAI/ODH architecture documentation. Refer to the original component repositories for licensing information.
