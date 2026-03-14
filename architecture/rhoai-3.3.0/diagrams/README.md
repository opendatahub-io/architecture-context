# Architecture Diagrams for RHOAI 3.3.0 Components

This directory contains architecture diagrams for multiple RHOAI 3.3.0 components.

**Last Updated**: 2026-03-14

**Note**: Diagram filenames use base component name without version (directory is already versioned).

## Available Components

- [Platform Overview](#platform-overview) - Complete RHOAI 3.3.0 platform architecture (14 components)
- [ODH Dashboard](#odh-dashboard) - Web-based UI for managing ODH and RHOAI components
- [KServe](#kserve) - Kubernetes-native model serving platform
- [Kubeflow Notebook Controller](#kubeflow-notebook-controller) - ODH Notebook Controller
- [Feast](#feast) - Feature store for ML
- [Data Science Pipelines Operator](#data-science-pipelines-operator) - Pipeline orchestration
- [MLflow Operator](#mlflow-operator) - MLflow experiment tracking and model registry
- [Notebooks](#notebooks) - Workbench container images (Jupyter, RStudio, CodeServer)

---

## Platform Overview

**Source**: `architecture/rhoai-3.3.0/PLATFORM.md`

Comprehensive platform architecture for Red Hat OpenShift AI 3.3.0, covering all 14 core components and their integrations. Provides end-to-end ML lifecycle toolkit spanning interactive development, distributed training, model serving, experiment tracking, feature stores, model registries, and ML workflow orchestration.

### Diagrams

All Mermaid diagrams are available in both `.mmd` (source) and `.png` (3000px width, high-resolution) formats.

#### For Developers
- [Component Structure](./platform-component.png) ([mmd](./platform-component.mmd)) - All platform components, controllers, training infrastructure, and LLM services
- [Data Flows](./platform-dataflow.png) ([mmd](./platform-dataflow.mmd)) - End-to-end workflows: training to deployment, distributed training, inference requests, feature store integration
- [Dependencies](./platform-dependencies.png) ([mmd](./platform-dependencies.mmd)) - Complete dependency graph showing all platform, external, and OpenShift integrations

#### For Architects
- [C4 Context](./platform-c4-context.dsl) - System context showing RHOAI 3.3.0 in broader ecosystem with multiple views (SystemContext, PlatformContainers, ModelServing, ModelTraining, MLWorkflow)
- [Component Overview](./platform-component.png) ([mmd](./platform-component.mmd)) - High-level platform architecture with all 14 components

#### For Security Teams
- [Security Network Diagram (PNG)](./platform-security-network.png) - High-resolution network topology with trust zones
- [Security Network Diagram (Mermaid)](./platform-security-network.mmd) - Visual network topology (editable)
- [Security Network Diagram (ASCII)](./platform-security-network.txt) - Precise text format for SAR submissions (includes RBAC summary, service mesh config, secrets inventory)
- [RBAC Visualization](./platform-rbac.png) ([mmd](./platform-rbac.mmd)) - Platform-wide RBAC permissions and bindings for all 12 operators

### Platform Components (14 Total)

| Component | Type | Purpose |
|-----------|------|---------|
| **ODH Dashboard** | Web Application | Unified web UI for platform management |
| **KServe** | Operator + Controller | Model serving with autoscaling (v0.15) |
| **Data Science Pipelines** | Operator | ML workflow orchestration (Kubeflow Pipelines v2 + Argo) |
| **Notebooks** | Container Images | JupyterLab/RStudio/VS Code workbenches (v20xx.2) |
| **Model Registry** | Operator | Model metadata and versioning (rhoai-3.3) |
| **MLflow** | Operator | Experiment tracking and model registry (rhoai-3.3) |
| **Feast** | Operator + Service | Feature store for ML features (v0.59.0) |
| **Kubeflow Trainer** | Operator | Distributed training & LLM fine-tuning (v2.1.0) |
| **Training Operator** | Operator | Multi-framework training: PyTorch/TF/JAX/MPI/XGBoost (v1.9.0) |
| **TrustyAI** | Operator | Model explainability, fairness, guardrails, LLM evaluation (v1.39.0) |
| **KubeRay** | Operator | Ray cluster management (v1.4.2) |
| **Llama Stack** | Operator | LLM inference server management (v0.6.0) |
| **odh-model-controller** | Operator | KServe OpenShift integration: Routes, NetworkPolicies, NVIDIA NIM (v1.27.0) |
| **odh-notebook-controller** | Operator | Gateway API integration for notebooks (v1.27.0) |

### Key Platform Workflows

1. **Model Training to Deployment**:
   - User develops in Notebook → trains model → saves to S3 → registers in Model Registry → deploys via KServe → TrustyAI monitors

2. **Pipeline-driven Model Deployment**:
   - Notebook/Elyra submits pipeline → Data Science Pipelines orchestrates (Argo) → training steps execute → model uploaded to S3 → registered in Model Registry → KServe deploys

3. **Feature Engineering to Inference**:
   - Notebook engineers features → Feast registers FeatureView → materialization (offline → online) → training fetches historical features → InferenceService fetches online features

4. **Distributed Training with Tracking**:
   - User creates TrainJob → Trainer downloads dataset/model (HuggingFace/S3) → creates JobSet (multi-node) → training pods execute → logs to MLflow → saves to S3 → Model Registry registers

5. **End-to-End LLM Fine-tuning**:
   - Prepare data in Notebook → submit TrainJob for LLM → Trainer downloads base LLM (HF) → distributed fine-tuning (GPU pods) → upload to S3 → deploy via NVIDIA NIM (odh-model-controller + KServe) → serve with vLLM runtime (OpenAI API) → TrustyAI evaluates (LMEvalJob) → add guardrails

### Platform Architecture Highlights

**Namespaces**:
- `redhat-ods-applications` / `opendatahub`: Core platform services
- `kserve`: Model serving operator
- `openshift-ingress`: Gateway API routing
- User namespaces: Notebooks, InferenceServices, training jobs, pipelines

**External Dependencies**:
- **Infrastructure**: Istio (service mesh), Knative Serving (autoscaling), Argo Workflows, Gateway API, cert-manager, Prometheus, Volcano (gang scheduling)
- **Storage**: S3-compatible (AWS/GCS/Azure), PostgreSQL, MySQL, Redis
- **External Services**: HuggingFace Hub, NVIDIA NGC, PyPI, image registries

**Security**:
- **Authentication**: OpenShift OAuth, Kubernetes RBAC, OIDC, mTLS (PERMISSIVE mode for KServe)
- **Encryption**: TLS 1.2+ everywhere, mTLS in service mesh (optional)
- **Secrets**: TLS certificates (cert-manager, 90-day rotation), database credentials, S3 access keys, NGC API keys
- **NetworkPolicies**: Training job isolation (RHOAI 3.3), Llama Stack (enabled by default)

**Platform Maturity**:
- **Operator-based**: 13 of 14 components (93%)
- **Multi-architecture**: x86_64, aarch64, ppc64le, s390x
- **GPU Support**: NVIDIA CUDA 12.6/12.8/13.0, AMD ROCm 6.2/6.3/6.4, Intel Gaudi
- **CI/CD**: Konflux pipelines (Tekton) with security scanning, SBOM, multi-arch builds

### RHOAI 3.3.0 Version Highlights

- **KServe**: Graceful handling of missing LeaderWorkerSet CRD, multi-arch storage-initializer, auth proxy preservation during upgrades, vLLM block-size parameter updates
- **Kubeflow Trainer**: NetworkPolicy for TrainJobs, progression tracking (metrics polling), multiple CUDA/ROCm runtime additions
- **Notebooks**: Package retry loop (CVE fixes), Konflux CI/CD migration, multi-arch builds (ppc64le, aarch64)
- **Llama Stack**: NetworkPolicy enabled by default, CA bundle volume conflict fixes
- **Training Operator**: CVE-2026-2353 (namespace-scoped secrets RBAC), Go 1.25 upgrade
- **Feast**: v0.59.0 with dbt integration, Lambda materialization improvements, OIDC secret in repo config
- **Model Registry**: PostgreSQL NetworkPolicy, gRPC field validation cleanup
- **TrustyAI**: urllib3 security fixes (v2.6.3), GuardrailsOrchestrator status updates

---

## ODH Dashboard

**Source**: `architecture/rhoai-3.3.0/odh-dashboard.md`

Web-based user interface for managing Open Data Hub and Red Hat OpenShift AI components, projects, and workloads. Provides unified UX for data scientists and administrators to interact with platform components including Jupyter notebooks, model serving (KServe), data science pipelines, model registry, distributed workloads, and GenAI capabilities.

### Diagrams

All Mermaid diagrams are available in both `.mmd` (source) and `.png` (3000px width, high-resolution) formats.

#### For Developers
- [Component Structure](./odh-dashboard-component.png) ([mmd](./odh-dashboard-component.mmd)) - Frontend (React/PatternFly), backend (Node.js/Fastify), kube-rbac-proxy, and micro-frontends (modular architecture)
- [Data Flows](./odh-dashboard-dataflow.png) ([mmd](./odh-dashboard-dataflow.mmd)) - User authentication, notebook creation, WebSocket watch, model registry UI access, and Prometheus queries
- [Dependencies](./odh-dashboard-dependencies.png) ([mmd](./odh-dashboard-dependencies.mmd)) - External dependencies (Node.js, OpenShift, React, PatternFly) and ODH component integrations

#### For Architects
- [C4 Context](./odh-dashboard-c4-context.dsl) - System context showing Dashboard as control plane UI in ODH/RHOAI ecosystem
- [Component Overview](./odh-dashboard-component.png) ([mmd](./odh-dashboard-component.mmd)) - High-level component architecture

#### For Security Teams
- [Security Network Diagram (PNG)](./odh-dashboard-security-network.png) - High-resolution network topology
- [Security Network Diagram (Mermaid)](./odh-dashboard-security-network.mmd) - Visual network topology (editable)
- [Security Network Diagram (ASCII)](./odh-dashboard-security-network.txt) - Precise text format for SAR submissions
- [RBAC Visualization](./odh-dashboard-rbac.png) ([mmd](./odh-dashboard-rbac.mmd)) - ClusterRole and namespace-scoped Role permissions and bindings

### Key Features
- **Unified Control Plane**: Single web UI for all ODH/RHOAI components and workloads
- **OpenShift OAuth**: Integrated authentication with kube-rbac-proxy enforcement
- **REST API Backend**: Node.js/Fastify server proxying Kubernetes API with user impersonation
- **WebSocket Support**: Real-time resource updates for notebooks, pipelines, and models
- **Modular Architecture**: Module federation for micro-frontends (Model Registry UI, GenAI UI, MaaS UI)
- **CRD Management**: OdhApplication, OdhDashboardConfig, OdhDocument, OdhQuickStart
- **Project Management**: Namespace creation, RBAC, PVCs, data connections, model serving
- **Multi-deployment**: Supports ODH, RHOAI addon (managed), and RHOAI onprem (self-managed)
- **Security**: TLS reencrypt routes, HSTS, non-root containers (UID 1001), OAuth + RBAC
- **Observability**: Prometheus metrics, JSON logging (pino), admin activity tracking

---

## KServe

**Source**: `architecture/rhoai-3.3.0/kserve.md`

Kubernetes-native model serving platform for predictive and generative ML models with standardized inference protocols and autoscaling.

### Diagrams

All Mermaid diagrams are available in both `.mmd` (source) and `.png` (3000px width, high-resolution) formats.

#### For Developers
- [Component Structure](./kserve-component.png) ([mmd](./kserve-component.mmd)) - Control plane, runtime components, LLM components, and local caching
- [Data Flows](./kserve-dataflow.png) ([mmd](./kserve-dataflow.mmd)) - Model deployment and inference request sequences
- [Dependencies](./kserve-dependencies.png) ([mmd](./kserve-dependencies.mmd)) - External and internal dependencies (Knative, Istio, cert-manager, ODH integrations)

#### For Architects
- [C4 Context](./kserve-c4-context.dsl) - System context showing KServe in broader ecosystem
- [Component Overview](./kserve-component.png) ([mmd](./kserve-component.mmd)) - High-level component architecture

#### For Security Teams
- [Security Network Diagram (PNG)](./kserve-security-network.png) - High-resolution network topology
- [Security Network Diagram (Mermaid)](./kserve-security-network.mmd) - Visual network topology (editable)
- [Security Network Diagram (ASCII)](./kserve-security-network.txt) - Precise text format for SAR submissions
- [RBAC Visualization](./kserve-rbac.png) ([mmd](./kserve-rbac.mmd)) - ClusterRole permissions and bindings

### Key Features
- **Standardized Inference**: KServe v1, v2 (NVIDIA Triton), OpenAI-compatible APIs
- **Autoscaling**: Serverless (Knative) or raw Kubernetes (HPA/KEDA), including scale-to-zero
- **Advanced Patterns**: Canary rollouts, InferenceGraphs, disaggregated LLM serving
- **Storage**: S3, GCS, Azure Blob, PVC, OCI registries
- **Security**: mTLS via Istio, Bearer Token auth, RBAC, optional Authorino

---

## Kubeflow Notebook Controller

**Source**: `architecture/rhoai-3.3.0/kubeflow.md`

Kubernetes operator that extends Kubeflow Notebook functionality with OpenShift integration, Gateway API routing, and RBAC-based authentication.

### Diagrams

#### For Developers
- [Component Structure](./kubeflow-component.png) ([mmd](./kubeflow-component.mmd)) - Controller components and integrations
- [Data Flows](./kubeflow-dataflow.png) ([mmd](./kubeflow-dataflow.mmd)) - Notebook creation and access flows
- [Dependencies](./kubeflow-dependencies.png) ([mmd](./kubeflow-dependencies.mmd)) - Component dependency graph

#### For Architects
- [C4 Context](./kubeflow-c4-context.dsl) - System context in C4 format
- [Component Overview](./kubeflow-component.png) ([mmd](./kubeflow-component.mmd)) - High-level component view

#### For Security Teams
- [Security Network Diagram (PNG)](./kubeflow-security-network.png) - High-resolution network topology
- [Security Network Diagram (Mermaid)](./kubeflow-security-network.mmd) - Visual network topology (editable)
- [Security Network Diagram (ASCII)](./kubeflow-security-network.txt) - Precise text format for SAR submissions
- [RBAC Visualization](./kubeflow-rbac.png) ([mmd](./kubeflow-rbac.mmd)) - RBAC permissions and bindings

### Key Features
- **Gateway API Integration**: HTTPRoutes for external notebook access
- **Cross-Namespace Architecture**: HTTPRoutes in controller namespace, services in user namespaces
- **Optional Authentication**: kube-rbac-proxy sidecar injection via webhook
- **Data Science Pipeline Integration**: Automatic RBAC and secret provisioning
- **OpenShift Integration**: Service CA certificates, OAuth, ImageStreams

---

## Feast

**Source**: `architecture/rhoai-3.3.0/feast.md`

Open-source feature store for managing, serving, and tracking ML features with consistent access for training and serving.

### Diagrams

#### For Developers
- [Component Structure](./feast-component.png) ([mmd](./feast-component.mmd)) - Operator, feature servers (online/offline), registry, UI, and storage backends
- [Data Flows](./feast-dataflow.png) ([mmd](./feast-dataflow.mmd)) - Online/offline feature retrieval, materialization, and registry management flows
- [Dependencies](./feast-dependencies.png) ([mmd](./feast-dependencies.mmd)) - External dependencies (Kubernetes, Python, databases) and ODH integrations

#### For Architects
- [C4 Context](./feast-c4-context.dsl) - System context showing Feast in broader RHOAI ecosystem
- [Component Overview](./feast-component.png) ([mmd](./feast-component.mmd)) - High-level component architecture

#### For Security Teams
- [Security Network Diagram (PNG)](./feast-security-network.png) - High-resolution network topology
- [Security Network Diagram (Mermaid)](./feast-security-network.mmd) - Visual network topology (editable)
- [Security Network Diagram (ASCII)](./feast-security-network.txt) - Precise text format for SAR submissions
- [RBAC Visualization](./feast-rbac.png) ([mmd](./feast-rbac.mmd)) - RBAC permissions and bindings

### Key Features
- **Multiple Feature Servers**: Online (low-latency, ports 6566/6567), Offline (training, ports 8815/8816), Registry (metadata, gRPC 6570/6571, REST 6572/6573)
- **Flexible Storage**: SQLite (default), PostgreSQL, Redis (online), S3 (offline/registry)
- **Authentication**: OIDC Bearer tokens, mTLS, Kubernetes RBAC
- **Materialization**: CronJob-based offline-to-online feature synchronization
- **Web UI**: Feature discovery and exploration (ports 8888/8443)

---

## Data Science Pipelines Operator

**Source**: `architecture/rhoai-3.3.0/data-science-pipelines-operator.md`

Kubernetes operator that manages namespace-scoped Data Science Pipeline stacks based on Kubeflow Pipelines, enabling ML workflow orchestration for data preparation, model training, validation, and experimentation.

### Diagrams

All Mermaid diagrams are available in both `.mmd` (source) and `.png` (3000px width, high-resolution) formats.

#### For Developers
- [Component Structure](./data-science-pipelines-operator-component.png) ([mmd](./data-science-pipelines-operator-component.mmd)) - Multi-tiered architecture showing operator, application, and execution layers
- [Data Flows](./data-science-pipelines-operator-dataflow.png) ([mmd](./data-science-pipelines-operator-dataflow.mmd)) - Pipeline submission, execution, artifact storage, and scheduled pipeline flows
- [Dependencies](./data-science-pipelines-operator-dependencies.png) ([mmd](./data-science-pipelines-operator-dependencies.mmd)) - External and internal dependencies (Argo Workflows, MariaDB, S3, ODH components)

#### For Architects
- [C4 Context](./data-science-pipelines-operator-c4-context.dsl) - System context showing DSPO in broader ODH ecosystem
- [Component Overview](./data-science-pipelines-operator-component.png) ([mmd](./data-science-pipelines-operator-component.mmd)) - High-level component architecture

#### For Security Teams
- [Security Network Diagram (PNG)](./data-science-pipelines-operator-security-network.png) - High-resolution network topology
- [Security Network Diagram (Mermaid)](./data-science-pipelines-operator-security-network.mmd) - Visual network topology (editable)
- [Security Network Diagram (ASCII)](./data-science-pipelines-operator-security-network.txt) - Precise text format for SAR submissions
- [RBAC Visualization](./data-science-pipelines-operator-rbac.png) ([mmd](./data-science-pipelines-operator-rbac.mmd)) - ClusterRole and namespace-scoped Role permissions and bindings

### Key Features
- **Namespace-Scoped Deployments**: Each DataSciencePipelinesApplication CR creates isolated pipeline infrastructure
- **KFP v2 API**: REST/gRPC API for pipeline and run management
- **Argo Workflows**: Namespace-scoped workflow execution engine (replaced Tekton in v2)
- **ML Metadata (MLMD)**: Optional artifact lineage tracking and experiment metadata
- **Flexible Storage**: Optional MariaDB/Minio for dev/test, external MySQL/S3 for production
- **Security**: Optional mTLS, OpenShift OAuth, Kubernetes RBAC, NetworkPolicies, auto-rotating TLS certs
- **FIPS Compliance**: Available via GOEXPERIMENT=strictfipsruntime flag

---

## MLflow Operator

**Source**: `architecture/rhoai-3.3.0/mlflow-operator.md`

Kubernetes operator that automates deployment and lifecycle management of MLflow experiment tracking and model registry servers with declarative configuration and Gateway API integration.

### Diagrams

All Mermaid diagrams are available in both `.mmd` (source) and `.png` (3000px width, high-resolution) formats.

#### For Developers
- [Component Structure](./mlflow-operator-component.png) ([mmd](./mlflow-operator-component.mmd)) - Operator controller, Helm engine, HTTPRoute/ConsoleLink reconcilers, and created MLflow instances
- [Data Flows](./mlflow-operator-dataflow.png) ([mmd](./mlflow-operator-dataflow.mmd)) - User access via Gateway, operator reconciliation, artifact storage, and metrics collection flows
- [Dependencies](./mlflow-operator-dependencies.png) ([mmd](./mlflow-operator-dependencies.mmd)) - External dependencies (Kubernetes, Helm, PostgreSQL, S3) and internal ODH integrations

#### For Architects
- [C4 Context](./mlflow-operator-c4-context.dsl) - System context showing MLflow Operator in broader RHOAI/ODH ecosystem with multiple views
- [Component Overview](./mlflow-operator-component.png) ([mmd](./mlflow-operator-component.mmd)) - High-level component architecture

#### For Security Teams
- [Security Network Diagram (PNG)](./mlflow-operator-security-network.png) - High-resolution network topology
- [Security Network Diagram (Mermaid)](./mlflow-operator-security-network.mmd) - Visual network topology (editable)
- [Security Network Diagram (ASCII)](./mlflow-operator-security-network.txt) - Precise text format for SAR submissions
- [RBAC Visualization](./mlflow-operator-rbac.png) ([mmd](./mlflow-operator-rbac.mmd)) - ClusterRole and namespace-scoped Role permissions and bindings

### Key Features
- **Declarative Deployment**: MLflow CRs (mlflow.opendatahub.io/v1) for automated MLflow instance creation
- **Embedded Helm Charts**: Template rendering for Kubernetes manifests
- **Gateway API Integration**: HTTPRoutes for external access via data-science-gateway (/mlflow/*)
- **OpenShift Console**: ConsoleLink CRDs for application menu integration
- **Dual Deployment Modes**: OpenDataHub (opendatahub) and RHOAI (redhat-ods-applications) namespaces
- **Flexible Storage**: Local PVC + SQLite (dev) or remote PostgreSQL + S3 (production)
- **Kubernetes-native Auth**: Bearer token authentication with self_subject_access_review authorization
- **Auto-TLS**: service-ca-operator integration for automatic certificate provisioning and rotation
- **Security**: Non-root containers (UID 1001), RuntimeDefault seccomp, NetworkPolicies, TLS 1.2+/1.3

---

## Notebooks

**Source**: `architecture/rhoai-3.3.0/notebooks.md`

Provides containerized IDE environments (Jupyter, RStudio, CodeServer) for data scientists to develop, train, and experiment with machine learning models.

### Diagrams

All Mermaid diagrams are available in both `.mmd` (source) and `.png` (3000px width, high-resolution) formats.

#### For Developers
- [Component Structure](./notebooks-component.png) ([mmd](./notebooks-component.mmd)) - Workbench images, runtime images, build infrastructure, and deployment flow
- [Data Flows](./notebooks-dataflow.png) ([mmd](./notebooks-dataflow.mmd)) - User access, package installation, data access, and Elyra pipeline execution flows
- [Dependencies](./notebooks-dependencies.png) ([mmd](./notebooks-dependencies.mmd)) - External dependencies (UBI9, JupyterLab, ML frameworks) and ODH integrations

#### For Architects
- [C4 Context](./notebooks-c4-context.dsl) - System context showing Notebooks in broader RHOAI/ODH ecosystem
- [Component Overview](./notebooks-component.png) ([mmd](./notebooks-component.mmd)) - High-level component architecture

#### For Security Teams
- [Security Network Diagram (PNG)](./notebooks-security-network.png) - High-resolution network topology
- [Security Network Diagram (Mermaid)](./notebooks-security-network.mmd) - Visual network topology (editable)
- [Security Network Diagram (ASCII)](./notebooks-security-network.txt) - Precise text format for SAR submissions
- [RBAC Visualization](./notebooks-rbac.png) ([mmd](./notebooks-rbac.mmd)) - Namespace-scoped RBAC permissions and service accounts

### Key Features
- **Multiple IDEs**: Jupyter (Minimal, DataScience, PyTorch, TensorFlow, TrustyAI, LLMCompressor), RStudio, CodeServer (VS Code)
- **Multi-Accelerator Support**: CPU, CUDA (NVIDIA 12.6/12.8/13.0), ROCM (AMD 6.2/6.3/6.4) variants
- **Multi-Architecture Builds**: x86_64, aarch64, ppc64le, s390x (via Konflux CI/CD)
- **Runtime Images**: Headless containers for Elyra pipeline execution (no IDE overhead)
- **OAuth-First Security**: OpenShift OAuth proxy sidecar enforces authentication (Jupyter auth disabled)
- **Non-Root Containers**: All images run as UID 1001 with Security Context Constraints
- **Stateful Workbenches**: StatefulSets with PVCs preserve user data across restarts
- **Konflux Builds**: Automated multi-arch builds with security scanning, image signing, SBOM generation
- **Package Management**: UV package manager with pylock.toml for reproducible builds
- **ImageStreams**: OpenShift ImageStreams maintain N-6 version history for rollback

---

## How to Use

### PNG Files (.png files)
**Automatically generated** at 3000px width for high-resolution presentations and documentation.

- **Ready to use**: High-resolution images suitable for presentations, wikis, and documentation
- **Width**: 3000px (height auto-adjusts to content)
- **Use directly**: Include in PowerPoint, Google Slides, Confluence, etc.

### Mermaid Source Files (.mmd files)
- **In GitHub/GitLab**: Paste into markdown with ````mermaid` code blocks - renders automatically!
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

## Updating Diagrams

To regenerate all diagrams after architecture changes:
```bash
# Regenerate PNG files from Mermaid sources
python /path/to/scripts/generate_diagram_pngs.py /path/to/architecture/rhoai-3.3.0/diagrams --width=3000
```

To regenerate diagrams for a specific component:
```bash
# Example: Regenerate KServe diagrams
/generate-architecture-diagrams --architecture=architecture/rhoai-3.3.0/kserve.md

# Example: Regenerate Kubeflow diagrams
/generate-architecture-diagrams --architecture=architecture/rhoai-3.3.0/kubeflow.md
```

## Directory Structure

```
architecture/rhoai-3.3.0/
├── diagrams/                                    # Shared diagrams directory (this location)
│   ├── kserve-component.mmd                     # Component names without version
│   ├── kserve-component.png                     # Auto-generated PNG (3000px width)
│   ├── kserve-dataflow.mmd
│   ├── kserve-dataflow.png
│   ├── kserve-security-network.mmd              # Mermaid (visual, editable)
│   ├── kserve-security-network.png              # PNG (high-res)
│   ├── kserve-security-network.txt              # ASCII (precise)
│   ├── kserve-c4-context.dsl
│   ├── kserve-dependencies.mmd
│   ├── kserve-dependencies.png
│   ├── kserve-rbac.mmd
│   ├── kserve-rbac.png
│   ├── kubeflow-*.mmd / .png / .dsl / .txt      # Kubeflow diagrams
│   ├── feast-*.mmd / .png / .dsl / .txt         # Feast diagrams
│   └── README.md                                # This file
├── kserve.md                                    # Architecture documentation
├── kubeflow.md
├── feast.md
└── data-science-pipelines-operator.md
```

**Key principles**:
- Filenames use base component name only (no version)
- Directory `rhoai-3.3.0/` provides versioning context
- PNG files auto-generated at 3000px width for all Mermaid diagrams
- Shared diagrams directory for all components in this version
