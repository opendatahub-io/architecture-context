# Architecture Diagrams for RHOAI 3.3 Components

Generated from: `architecture/rhoai-3.3/*.md`
Last updated: 2026-03-15

**Note**: Diagram filenames use base component name without version (directory is already versioned in `rhoai-3.3/`).

## Available Components

This directory contains architecture diagrams for multiple RHOAI 3.3 components:

- [**Platform Overview**](#platform-overview) - Complete RHOAI 3.3 platform architecture with all 15 components
- [RHODS Operator](#rhods-operator) - Central control plane for RHOAI/ODH platform
- [Feast Feature Store](#feast-feature-store)
- [KServe](#kserve)
- [KubeFlow](#kubeflow)
- [KubeRay Operator](#kuberay-operator)
- [Data Science Pipelines Operator](#data-science-pipelines-operator)
- [ODH Dashboard](#odh-dashboard)
- [Notebooks (Workbench Images)](#notebooks-workbench-images)

All Mermaid diagrams are available in both `.mmd` (source) and `.png` (3000px width, high-resolution) formats.

---

## Platform Overview

Generated from: `architecture/rhoai-3.3/PLATFORM.md`

**Complete platform architecture** showing all 15 RHOAI components, their relationships, dependencies, and integration patterns.

### For Developers
- [Component Structure](./platform-component.png) ([mmd](./platform-component.mmd)) - All 15 platform components and their relationships
- [Data Flows](./platform-dataflow.png) ([mmd](./platform-dataflow.mmd)) - Notebook-based model development and deployment workflow
- [Dependencies](./platform-dependencies.png) ([mmd](./platform-dependencies.mmd)) - Complete platform dependency graph

### For Architects
- [C4 Context](./platform-c4-context.dsl) - System context in C4 format (Structurizr) with workflows
- [Component Overview](./platform-component.png) ([mmd](./platform-component.mmd)) - High-level platform view
- [Dependency Graph](./platform-dependencies.png) ([mmd](./platform-dependencies.mmd)) - Platform-wide dependency visualization

### For Security Teams
- [Security Network Diagram (PNG)](./platform-security-network.png) - High-resolution network topology
- [Security Network Diagram (Mermaid)](./platform-security-network.mmd) - Visual network topology (editable)
- [Security Network Diagram (ASCII)](./platform-security-network.txt) - Precise text format for SAR submissions
- [RBAC Visualization](./platform-rbac.png) ([mmd](./platform-rbac.mmd)) - RBAC permissions across all 15+ operators

**Platform Summary**: Red Hat OpenShift AI (RHOAI) 3.3 is an enterprise AI/ML platform built on OpenShift that provides a complete lifecycle environment for data science teams. Integrates 15 core components: RHODS Operator (control plane), ODH Dashboard (UI), KServe + odh-model-controller (model serving), Data Science Pipelines (workflow orchestration), Model Registry (metadata), Workbenches (Jupyter/RStudio/CodeServer), Training Operators (distributed training), Kubeflow Trainer (LLM fine-tuning), KubeRay (distributed computing), Feast (feature store), MLflow (experiment tracking), Llama Stack (LLM serving), and TrustyAI (explainability).

---

## Feast Feature Store

Generated from: `architecture/rhoai-3.3/feast.md`

### For Developers
- [Component Structure](./feast-component.png) ([mmd](./feast-component.mmd)) - Internal components and feature servers
- [Data Flows](./feast-dataflow.png) ([mmd](./feast-dataflow.mmd)) - Sequence diagrams for online/offline retrieval and materialization
- [Dependencies](./feast-dependencies.png) ([mmd](./feast-dependencies.mmd)) - Component dependency graph

### For Architects
- [C4 Context](./feast-c4-context.dsl) - System context in C4 format (Structurizr)

### For Security Teams
- [Security Network Diagram (PNG)](./feast-security-network.png) - High-resolution network topology
- [Security Network Diagram (Mermaid)](./feast-security-network.mmd) - Visual network topology (editable)
- [Security Network Diagram (ASCII)](./feast-security-network.txt) - Precise text format for SAR submissions
- [RBAC Visualization](./feast-rbac.png) ([mmd](./feast-rbac.mmd)) - RBAC permissions and bindings

---

## KServe

Generated from: `architecture/rhoai-3.3/kserve.md`

### For Developers
- [Component Structure](./kserve-component.png) ([mmd](./kserve-component.mmd)) - KServe controller and inference services
- [Data Flows](./kserve-dataflow.png) ([mmd](./kserve-dataflow.mmd)) - Inference request flows and model loading
- [Dependencies](./kserve-dependencies.png) ([mmd](./kserve-dependencies.mmd)) - Component dependency graph

### For Architects
- [C4 Context](./kserve-c4-context.dsl) - System context in C4 format (Structurizr)

### For Security Teams
- [Security Network Diagram (PNG)](./kserve-security-network.png) - High-resolution network topology
- [Security Network Diagram (Mermaid)](./kserve-security-network.mmd) - Visual network topology (editable)
- [Security Network Diagram (ASCII)](./kserve-security-network.txt) - Precise text format for SAR submissions
- [RBAC Visualization](./kserve-rbac.png) ([mmd](./kserve-rbac.mmd)) - RBAC permissions and bindings

---

## KubeFlow (ODH Notebook Controller)

Generated from: `architecture/rhoai-3.3/kubeflow.md`

### For Developers
- [Component Structure](./kubeflow-component.png) ([mmd](./kubeflow-component.mmd)) - ODH Notebook Controller components and Gateway API integration
- [Data Flows](./kubeflow-dataflow.png) ([mmd](./kubeflow-dataflow.mmd)) - Notebook access flows, webhook mutation, and DSPA integration
- [Dependencies](./kubeflow-dependencies.png) ([mmd](./kubeflow-dependencies.mmd)) - Component dependency graph

### For Architects
- [C4 Context](./kubeflow-c4-context.dsl) - System context in C4 format (Structurizr)

### For Security Teams
- [Security Network Diagram (PNG)](./kubeflow-security-network.png) - High-resolution network topology
- [Security Network Diagram (Mermaid)](./kubeflow-security-network.mmd) - Visual network topology (editable)
- [Security Network Diagram (ASCII)](./kubeflow-security-network.txt) - Precise text format for SAR submissions
- [RBAC Visualization](./kubeflow-rbac.png) ([mmd](./kubeflow-rbac.mmd)) - RBAC permissions and bindings

**Component Summary**: Kubernetes operator extending Kubeflow Notebook functionality with OpenShift integration. Provides Gateway API routing, kube-rbac-proxy authentication injection, cross-namespace HTTPRoutes with ReferenceGrants, NetworkPolicies, and Data Science Pipelines integration. Supports both authenticated (RBAC-based) and unauthenticated notebook access modes.

---

## KubeRay Operator

Generated from: `architecture/rhoai-3.3/kuberay.md`

### For Developers
- [Component Structure](./kuberay-component.png) ([mmd](./kuberay-component.mmd)) - KubeRay operator, controllers, and Ray clusters
- [Data Flows](./kuberay-dataflow.png) ([mmd](./kuberay-dataflow.mmd)) - RayCluster creation, job submission, and model serving flows
- [Dependencies](./kuberay-dependencies.png) ([mmd](./kuberay-dependencies.mmd)) - Component dependency graph

### For Architects
- [C4 Context](./kuberay-c4-context.dsl) - System context in C4 format (Structurizr)

### For Security Teams
- [Security Network Diagram (PNG)](./kuberay-security-network.png) - High-resolution network topology
- [Security Network Diagram (Mermaid)](./kuberay-security-network.mmd) - Visual network topology (editable)
- [Security Network Diagram (ASCII)](./kuberay-security-network.txt) - Precise text format for SAR submissions
- [RBAC Visualization](./kuberay-rbac.png) ([mmd](./kuberay-rbac.mmd)) - RBAC permissions and bindings

**Component Summary**: Kubernetes operator managing Ray cluster lifecycle for distributed computing. Provides RayCluster (distributed compute), RayJob (batch execution), and RayService (model serving with HA). Supports autoscaling, fault tolerance with external Redis, mTLS, OAuth, Gateway API integration, and network policies.

---

## Data Science Pipelines Operator

Generated from: `architecture/rhoai-3.3/data-science-pipelines-operator.md`

### For Developers
- [Component Structure](./data-science-pipelines-operator-component.png) ([mmd](./data-science-pipelines-operator-component.mmd)) - Operator and pipeline components
- [Data Flows](./data-science-pipelines-operator-dataflow.png) ([mmd](./data-science-pipelines-operator-dataflow.mmd)) - Pipeline execution flows
- [Dependencies](./data-science-pipelines-operator-dependencies.png) ([mmd](./data-science-pipelines-operator-dependencies.mmd)) - Component dependency graph

### For Security Teams
- [Security Network Diagram (PNG)](./data-science-pipelines-operator-security-network.png) - High-resolution network topology
- [Security Network Diagram (Mermaid)](./data-science-pipelines-operator-security-network.mmd) - Visual network topology (editable)
- [Security Network Diagram (ASCII)](./data-science-pipelines-operator-security-network.txt) - Precise text format for SAR submissions
- [RBAC Visualization](./data-science-pipelines-operator-rbac.png) ([mmd](./data-science-pipelines-operator-rbac.mmd)) - RBAC permissions and bindings

---

## ODH Dashboard

Generated from: `architecture/rhoai-3.3/odh-dashboard.md`

### For Developers
- [Component Structure](./odh-dashboard-component.png) ([mmd](./odh-dashboard-component.mmd)) - Frontend, backend, kube-rbac-proxy, and modular micro-frontends
- [Data Flows](./odh-dashboard-dataflow.png) ([mmd](./odh-dashboard-dataflow.mmd)) - Authentication, notebook creation, WebSocket watches, and metrics queries
- [Dependencies](./odh-dashboard-dependencies.png) ([mmd](./odh-dashboard-dependencies.mmd)) - Component dependency graph

### For Architects
- [C4 Context](./odh-dashboard-c4-context.dsl) - System context in C4 format (Structurizr)

### For Security Teams
- [Security Network Diagram (PNG)](./odh-dashboard-security-network.png) - High-resolution network topology
- [Security Network Diagram (Mermaid)](./odh-dashboard-security-network.mmd) - Visual network topology (editable)
- [Security Network Diagram (ASCII)](./odh-dashboard-security-network.txt) - Precise text format for SAR submissions
- [RBAC Visualization](./odh-dashboard-rbac.png) ([mmd](./odh-dashboard-rbac.mmd)) - RBAC permissions and bindings

**Component Summary**: Web-based UI for Open Data Hub and Red Hat OpenShift AI platform management. Provides React 18 frontend with PatternFly 6, Node.js/Fastify backend, kube-rbac-proxy OAuth authentication with user impersonation, and optional federated micro-frontends (Model Registry, GenAI, MaaS). Manages Jupyter notebooks, KServe model serving, model registries, feature stores, pipelines, and distributed workloads via Kubernetes API.

---

## Notebooks (Workbench Images)

Generated from: `architecture/rhoai-3.3/notebooks.md`

### For Developers
- [Component Structure](./notebooks-component.png) ([mmd](./notebooks-component.mmd)) - Workbench images (Jupyter, RStudio, CodeServer), runtime images, and deployment infrastructure
- [Data Flows](./notebooks-dataflow.png) ([mmd](./notebooks-dataflow.mmd)) - User access, package installation, pipeline execution, and kubectl commands
- [Dependencies](./notebooks-dependencies.png) ([mmd](./notebooks-dependencies.mmd)) - Component dependency graph

### For Architects
- [C4 Context](./notebooks-c4-context.dsl) - System context in C4 format (Structurizr)

### For Security Teams
- [Security Network Diagram (PNG)](./notebooks-security-network.png) - High-resolution network topology
- [Security Network Diagram (Mermaid)](./notebooks-security-network.mmd) - Visual network topology (editable)
- [Security Network Diagram (ASCII)](./notebooks-security-network.txt) - Precise text format for SAR submissions
- [RBAC Visualization](./notebooks-rbac.png) ([mmd](./notebooks-rbac.mmd)) - RBAC permissions and bindings

**Component Summary**: Provides containerized IDE environments (Jupyter, RStudio, CodeServer) for data scientists to develop, train, and experiment with machine learning models. Includes pre-built workbench images with PyTorch, TensorFlow, and other ML frameworks optimized for CPU/CUDA/ROCM, runtime images for Elyra pipeline execution, OAuth proxy authentication, multi-architecture support (x86_64, aarch64, ppc64le, s390x), and Konflux CI/CD-based builds. No cluster-level RBAC (managed by odh-notebook-controller operator).

---

## RHODS Operator

Generated from: `architecture/rhoai-3.3/rhods-operator.md`

### For Developers
- [Component Structure](./rhods-operator-component.png) ([mmd](./rhods-operator-component.mmd)) - Operator manager, controllers (DSCInitialization, DataScienceCluster, 15+ component controllers), webhook server, and managed CRDs
- [Data Flows](./rhods-operator-dataflow.png) ([mmd](./rhods-operator-dataflow.mmd)) - DSC creation workflow, component reconciliation, and metrics scraping
- [Dependencies](./rhods-operator-dependencies.png) ([mmd](./rhods-operator-dependencies.mmd)) - External dependencies (Kubernetes, OpenShift, cert-manager, Istio, Serverless) and managed components (Dashboard, KServe, Pipelines, etc.)

### For Architects
- [C4 Context](./rhods-operator-c4-context.dsl) - System context in C4 format (Structurizr) showing operator as central control plane
- [Component Overview](./rhods-operator-component.png) ([mmd](./rhods-operator-component.mmd)) - High-level view of operator architecture

### For Security Teams
- [Security Network Diagram (PNG)](./rhods-operator-security-network.png) - High-resolution network topology
- [Security Network Diagram (Mermaid)](./rhods-operator-security-network.mmd) - Visual network topology (editable)
- [Security Network Diagram (ASCII)](./rhods-operator-security-network.txt) - Precise text format for SAR submissions
- [RBAC Visualization](./rhods-operator-rbac.png) ([mmd](./rhods-operator-rbac.mmd)) - Cluster-admin level RBAC permissions and bindings

**Component Summary**: Central control plane for Red Hat OpenShift AI (RHOAI) and Open Data Hub platforms. Orchestrates lifecycle of data science components via `DataScienceCluster` and `DSCInitialization` CRDs. Manages 15+ component-specific controllers (Dashboard, KServe, Workbenches, Pipelines, Ray, ModelRegistry, TrainingOperator, etc.), infrastructure services (monitoring, auth, gateway), and platform initialization. Runs 3 replicas with leader election for high availability. Requires cluster-admin level permissions for platform-wide infrastructure management including full RBAC control, CRD lifecycle, SCC modification, and cross-namespace resource management. Integrates with Istio/Service Mesh and OpenShift Serverless for advanced model serving capabilities.

---

## How to Use

### PNG Files (.png files)
**Automatically generated** at 3000px width for high-resolution presentations and documentation.

- **Ready to use**: High-resolution images suitable for presentations, wikis, and documentation
- **Width**: 3000px (height auto-adjusts to content)
- **Use directly**: Include in PowerPoint, Google Slides, Confluence, etc.

### Mermaid Source Files (.mmd files)
- **In GitHub/GitLab**: Paste into markdown with ` ```mermaid ` code blocks - renders automatically!
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

To regenerate after architecture changes:
```bash
# Regenerate PNG files for all diagrams
python ../../scripts/generate_diagram_pngs.py . --width=3000

# Or regenerate for specific component architecture file
# (requires diagram generation skill/tool)
```

## File Naming Convention

All diagrams follow the pattern: `{component-name}-{diagram-type}.{ext}`

**Component names** (derived from architecture filenames):
- `rhods-operator` - RHODS Operator (OpenDataHub Operator)
- `feast` - Feast Feature Store
- `kserve` - KServe model serving
- `kubeflow` - Kubeflow components
- `kuberay` - KubeRay operator
- `data-science-pipelines-operator` - Data Science Pipelines
- `odh-dashboard` - ODH Dashboard
- `notebooks` - Notebooks (Workbench Images)

**Diagram types**:
- `component` - Internal component structure
- `dataflow` - Sequence diagrams showing request/response flows
- `security-network` - Network topology with security details (.txt = ASCII, .mmd/.png = visual)
- `dependencies` - Dependency graph
- `rbac` - RBAC permissions visualization
- `c4-context` - C4 system context (.dsl = Structurizr DSL)

**Extensions**:
- `.mmd` - Mermaid source diagram (editable, renderable in GitHub/GitLab)
- `.png` - High-resolution PNG (3000px width, auto-generated)
- `.txt` - ASCII diagram (for security reviews)
- `.dsl` - Structurizr DSL (for C4 diagrams)
