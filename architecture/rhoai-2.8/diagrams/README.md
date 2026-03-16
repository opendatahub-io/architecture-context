# Architecture Diagrams for RHOAI 2.8 Components

Generated from: `architecture/rhoai-2.8/*.md`
Date: 2026-03-15

**Note**: Diagram filenames use base component name without version (directory is already versioned).

## Available Diagrams

All Mermaid diagrams are available in both `.mmd` (source) and `.png` (3000px width, high-resolution) formats.

---

## Platform Overview

Complete Red Hat OpenShift AI 2.8 platform architecture showing all components, integrations, and workflows.

### For Developers
- [Component Structure](./platform-component.png) ([mmd](./platform-component.mmd)) - All 12 platform components with CRDs and relationships
- [Data Flows](./platform-dataflow.png) ([mmd](./platform-dataflow.mmd)) - End-to-end workflows: model development, deployment, distributed training, AI explainability
- [Dependencies](./platform-dependencies.png) ([mmd](./platform-dependencies.mmd)) - Complete dependency graph of all platform components and external services

### For Architects
- [C4 Context](./platform-c4-context.dsl) - System context showing RHOAI in enterprise ecosystem (Structurizr)
- [Component Overview](./platform-component.png) ([mmd](./platform-component.mmd)) - High-level platform architecture

### For Security Teams
- [Security Network Diagram (PNG)](./platform-security-network.png) - Complete network topology with all trust zones
- [Security Network Diagram (Mermaid)](./platform-security-network.mmd) - Visual network topology (editable)
- [Security Network Diagram (ASCII)](./platform-security-network.txt) - Precise text format for SAR submissions with RBAC, secrets, Service Mesh config
- [RBAC Visualization](./platform-rbac.png) ([mmd](./platform-rbac.mmd)) - All ClusterRoles, bindings, and API resource permissions

**Key Details**: 12 components (9 operators, 2 platform services, 1 container image collection), OpenShift 4.12+ required, Istio Service Mesh (PERMISSIVE mTLS), Knative Serving (serverless), Tekton Pipelines, S3-compatible storage, OAuth authentication, Prometheus monitoring, GPU support (NVIDIA CUDA), Python 3.9 UBI9 production track

---

## RHODS Operator

Central control plane for Red Hat OpenShift AI, managing deployment and lifecycle of all data science and ML components.

### For Developers
- [Component Structure](./rhods-operator-component.png) ([mmd](./rhods-operator-component.mmd)) - Controllers, webhook server, managed components architecture
- [Data Flows](./rhods-operator-dataflow.png) ([mmd](./rhods-operator-dataflow.mmd)) - DataScienceCluster creation, monitoring, manifest application, service mesh integration
- [Dependencies](./rhods-operator-dependencies.png) ([mmd](./rhods-operator-dependencies.mmd)) - Platform dependencies and managed component relationships

### For Architects
- [C4 Context](./rhods-operator-c4-context.dsl) - System context showing RHODS Operator in RHOAI ecosystem (Structurizr)

### For Security Teams
- [Security Network Diagram (PNG)](./rhods-operator-security-network.png) - Network topology with trust boundaries
- [Security Network Diagram (Mermaid)](./rhods-operator-security-network.mmd) - Visual network topology (editable)
- [Security Network Diagram (ASCII)](./rhods-operator-security-network.txt) - Precise text format for SAR submissions
- [RBAC Visualization](./rhods-operator-rbac.png) ([mmd](./rhods-operator-rbac.mmd)) - Extensive ClusterRole permissions for operator and monitoring

**Key Details**: Four primary controllers (DSCInitialization, DataScienceCluster, SecretGenerator, CertConfigmapGenerator), manages 9 data science components, admission webhooks for CR validation, embedded manifests from odh-manifests repository, platform detection (OSD/ROSA/Self-managed), upgrade logic and migrations

---

## CodeFlare Operator

Manages distributed ML workload scheduling and auto-scaling.

### For Developers
- [Component Structure](./codeflare-operator-component.png) ([mmd](./codeflare-operator-component.mmd)) - MCAD and InstaScale controllers, CRDs, integrations
- [Data Flows](./codeflare-operator-dataflow.png) ([mmd](./codeflare-operator-dataflow.mmd)) - AppWrapper submission, InstaScale auto-scaling, metrics collection
- [Dependencies](./codeflare-operator-dependencies.png) ([mmd](./codeflare-operator-dependencies.mmd)) - MCAD, InstaScale, KubeRay, Machine API dependencies

### For Architects
- [C4 Context](./codeflare-operator-c4-context.dsl) - System context showing CodeFlare in RHOAI ecosystem (Structurizr)

### For Security Teams
- [Security Network Diagram (PNG)](./codeflare-operator-security-network.png) - Network topology with trust boundaries
- [Security Network Diagram (Mermaid)](./codeflare-operator-security-network.mmd) - Visual network topology (editable)
- [Security Network Diagram (ASCII)](./codeflare-operator-security-network.txt) - Precise text format for SAR submissions
- [RBAC Visualization](./codeflare-operator-rbac.png) ([mmd](./codeflare-operator-rbac.mmd)) - ClusterRoles, bindings, API resource access

**Key Details**: MCAD for batch scheduling, InstaScale for auto-scaling (OpenShift only), AppWrapper CRD, QuotaSubtree for hierarchical quotas

---

## Data Science Pipelines Operator

Manages Kubeflow Pipelines on Tekton for ML workflow orchestration.

### For Developers
- [Component Structure](./data-science-pipelines-operator-component.png) ([mmd](./data-science-pipelines-operator-component.mmd)) - DSPO and DSPA instance architecture
- [Data Flows](./data-science-pipelines-operator-dataflow.png) ([mmd](./data-science-pipelines-operator-dataflow.mmd)) - Pipeline submission, execution, artifact storage
- [Dependencies](./data-science-pipelines-operator-dependencies.png) ([mmd](./data-science-pipelines-operator-dependencies.mmd)) - Tekton, KFP, ODH Dashboard integrations

### For Architects
- [C4 Context](./data-science-pipelines-operator-c4-context.dsl) - System context in C4 format (Structurizr)

### For Security Teams
- [Security Network Diagram (PNG)](./data-science-pipelines-operator-security-network.png) - Network topology
- [Security Network Diagram (Mermaid)](./data-science-pipelines-operator-security-network.mmd) - Visual network topology (editable)
- [Security Network Diagram (ASCII)](./data-science-pipelines-operator-security-network.txt) - Precise text format for SAR submissions
- [RBAC Visualization](./data-science-pipelines-operator-rbac.png) ([mmd](./data-science-pipelines-operator-rbac.mmd)) - Operator and per-DSPA RBAC

**Key Details**: Hub-and-spoke architecture, OAuth proxy for external access, Tekton-based execution, optional Minio/MariaDB or external storage

---

## KServe

Serverless model inference platform.

### For Developers
- [Component Structure](./kserve-component.png) ([mmd](./kserve-component.mmd)) - Controller, webhook, predictor architecture
- [Data Flows](./kserve-dataflow.png) ([mmd](./kserve-dataflow.mmd)) - Inference request flows through Istio/Knative
- [Dependencies](./kserve-dependencies.png) ([mmd](./kserve-dependencies.mmd)) - Istio, Knative, ServiceMesh integrations

### For Architects
- [C4 Context](./kserve-c4-context.dsl) - System context (Structurizr)

### For Security Teams
- [Security Network Diagram (PNG)](./kserve-security-network.png) - Network topology
- [Security Network Diagram (Mermaid)](./kserve-security-network.mmd) - Visual network topology (editable)
- [RBAC Visualization](./kserve-rbac.mmd) - InferenceService RBAC permissions

**Key Details**: Knative Serving for autoscaling, Istio for routing, mTLS service mesh, model storage integrations

---

## Kubeflow (ODH Notebook Controller)

Extends Kubeflow Notebook Controller with OpenShift-specific features.

### For Developers
- [Component Structure](./kubeflow-component.png) ([mmd](./kubeflow-component.mmd)) - Webhook, reconciler, OAuth proxy injection
- [Data Flows](./kubeflow-dataflow.png) ([mmd](./kubeflow-dataflow.mmd)) - Notebook creation, OAuth access flow, reconciliation
- [Dependencies](./kubeflow-dependencies.png) ([mmd](./kubeflow-dependencies.mmd)) - OpenShift Route API, OAuth, Kubeflow integrations

### For Architects
- [C4 Context](./kubeflow-c4-context.dsl) - System context (Structurizr)

### For Security Teams
- [Security Network Diagram (PNG)](./kubeflow-security-network.png) - Network topology with trust boundaries
- [Security Network Diagram (Mermaid)](./kubeflow-security-network.mmd) - Visual network topology (editable)
- [Security Network Diagram (ASCII)](./kubeflow-security-network.txt) - Precise text format for SAR submissions
- [RBAC Visualization](./kubeflow-rbac.png) ([mmd](./kubeflow-rbac.mmd)) - Controller RBAC and OAuth authorization

**Key Details**: Mutating webhook for OAuth sidecar injection, OpenShift Routes with Edge TLS, SubjectAccessReview for notebook access, network policies

---

## KubeRay

Ray cluster management for distributed computing.

### For Developers
- [Component Structure](./kuberay-component.png) ([mmd](./kuberay-component.mmd)) - RayCluster and RayJob controllers
- [Data Flows](./kuberay-dataflow.png) ([mmd](./kuberay-dataflow.mmd)) - Cluster creation and job submission flows
- [Dependencies](./kuberay-dependencies.png) ([mmd](./kuberay-dependencies.mmd)) - Ray dependencies and integrations

### For Security Teams
- [Security Network Diagram (PNG)](./kuberay-security-network.png) - Network topology
- [Security Network Diagram (Mermaid)](./kuberay-security-network.mmd) - Visual network topology (editable)
- [RBAC Visualization](./kuberay-rbac.png) ([mmd](./kuberay-rbac.mmd)) - RayCluster RBAC permissions

**Key Details**: Head and worker pod architecture, GCS port for distributed communication, dashboard for monitoring

---

## Kueue

Job queueing controller for managing workload admission and resource allocation.

### For Developers
- [Component Structure](./kueue-component.png) ([mmd](./kueue-component.mmd)) - Controller manager, webhook server, visibility API, internal controllers
- [Data Flows](./kueue-dataflow.png) ([mmd](./kueue-dataflow.mmd)) - Job submission, workload admission, visibility API queries, metrics collection, multi-cluster distribution
- [Dependencies](./kueue-dependencies.png) ([mmd](./kueue-dependencies.mmd)) - Kubernetes, Training Operator, Ray Operator, JobSet, Cluster Autoscaler integrations

### For Architects
- [C4 Context](./kueue-c4-context.dsl) - System context showing Kueue in the Kubernetes ecosystem (Structurizr)

### For Security Teams
- [Security Network Diagram (PNG)](./kueue-security-network.png) - Network topology with trust boundaries
- [Security Network Diagram (Mermaid)](./kueue-security-network.mmd) - Visual network topology (editable)
- [Security Network Diagram (ASCII)](./kueue-security-network.txt) - Precise text format for SAR submissions with complete RBAC, secrets, and network policy details
- [RBAC Visualization](./kueue-rbac.png) ([mmd](./kueue-rbac.mmd)) - Controller manager RBAC, leader election, auth proxy, and user/tenant roles

**Key Details**: Priority-based queueing (StrictFIFO, BestEffortFIFO), resource fair sharing, preemption policies, quota borrowing, multi-cluster distribution (MultiKueue), supports Kubernetes Jobs, Kubeflow training jobs, Ray workloads, and JobSet

---

## Notebook Workbench Images

Container image build definitions for Jupyter notebook and IDE workbench images.

### For Developers
- [Component Structure](./notebooks-component.png) ([mmd](./notebooks-component.mmd)) - Build chain, base images, Jupyter variants, CUDA notebooks, runtime images, IDE alternatives
- [Data Flows](./notebooks-dataflow.png) ([mmd](./notebooks-dataflow.mmd)) - User notebook access, S3 storage, Git operations, pipeline execution, database connections
- [Dependencies](./notebooks-dependencies.png) ([mmd](./notebooks-dependencies.mmd)) - UBI/RHEL base images, JupyterLab, Elyra, Code Server, RStudio dependencies

### For Architects
- [C4 Context](./notebooks-c4-context.dsl) - System context showing notebook images in RHOAI ecosystem (Structurizr)

### For Security Teams
- [Security Network Diagram (PNG)](./notebooks-security-network.png) - Network topology with trust boundaries
- [Security Network Diagram (Mermaid)](./notebooks-security-network.mmd) - Visual network topology (editable)
- [Security Network Diagram (ASCII)](./notebooks-security-network.txt) - Precise text format for SAR submissions
- [RBAC Visualization](./notebooks-rbac.png) ([mmd](./notebooks-rbac.mmd)) - Notebook Controller and pod RBAC permissions

**Key Details**: Hierarchical image build chain (base → minimal → data science → ML frameworks), GPU acceleration with CUDA, runtime images for Elyra pipelines, OAuth Proxy sidecar authentication, ImageStream deployment with N/N-1/N-2 versioning

---

## ODH Dashboard

Web-based management dashboard for Red Hat OpenShift AI platform components and data science workflows.

### For Developers
- [Component Structure](./odh-dashboard-component.png) ([mmd](./odh-dashboard-component.mmd)) - React frontend, Node.js backend, OAuth proxy sidecar, CRDs, external dependencies
- [Data Flows](./odh-dashboard-dataflow.png) ([mmd](./odh-dashboard-dataflow.mmd)) - User authentication via OAuth, API requests for notebook creation, Prometheus metrics queries, WebSocket event streaming
- [Dependencies](./odh-dashboard-dependencies.png) ([mmd](./odh-dashboard-dependencies.mmd)) - External dependencies (K8s API, OAuth, Router), internal ODH components, NPM dependencies

### For Architects
- [C4 Context](./odh-dashboard-c4-context.dsl) - System context showing ODH Dashboard in RHOAI ecosystem (Structurizr)

### For Security Teams
- [Security Network Diagram (PNG)](./odh-dashboard-security-network.png) - Network topology with trust boundaries
- [Security Network Diagram (Mermaid)](./odh-dashboard-security-network.mmd) - Visual network topology (editable)
- [Security Network Diagram (ASCII)](./odh-dashboard-security-network.txt) - Precise text format for SAR submissions with RBAC, secrets, authentication flows
- [RBAC Visualization](./odh-dashboard-rbac.png) ([mmd](./odh-dashboard-rbac.mmd)) - odh-dashboard service account permissions, ClusterRoles, Roles, bindings

**Key Details**: React 18 + PatternFly 5 frontend, Node.js 18 + Fastify 4 backend, OpenShift OAuth proxy authentication, 2-replica HA deployment with anti-affinity, TLS reencrypt mode, manages AcceleratorProfiles, OdhApplications, OdhDashboardConfig, integrates with KServe, Kubeflow Notebooks, Prometheus, OpenShift Builds

---

## TrustyAI Service Operator

Kubernetes operator that manages TrustyAI service deployments for AI/ML explainability and fairness monitoring.

### For Developers
- [Component Structure](./trustyai-service-operator-component.png) ([mmd](./trustyai-service-operator-component.mmd)) - Operator controller, TrustyAI service pod, OAuth proxy, CRs, services, monitoring
- [Data Flows](./trustyai-service-operator-dataflow.png) ([mmd](./trustyai-service-operator-dataflow.mmd)) - Service creation, external OAuth access, KServe/ModelMesh integration, Prometheus scraping
- [Dependencies](./trustyai-service-operator-dependencies.png) ([mmd](./trustyai-service-operator-dependencies.mmd)) - KServe, ModelMesh, Prometheus, OpenShift OAuth dependencies

### For Architects
- [C4 Context](./trustyai-service-operator-c4-context.dsl) - System context in C4 format (Structurizr)

### For Security Teams
- [Security Network Diagram (PNG)](./trustyai-service-operator-security-network.png) - Network topology with trust boundaries
- [Security Network Diagram (Mermaid)](./trustyai-service-operator-security-network.mmd) - Visual network topology (editable)
- [Security Network Diagram (ASCII)](./trustyai-service-operator-security-network.txt) - Precise text format for SAR submissions with RBAC, secrets, OAuth details
- [RBAC Visualization](./trustyai-service-operator-rbac.png) ([mmd](./trustyai-service-operator-rbac.mmd)) - Operator and OAuth proxy RBAC permissions

**Key Details**: Watches TrustyAIService CR, configures KServe inference loggers and ModelMesh payload processors, OAuth proxy for external access with OpenShift OAuth, fairness metrics (SPD, DIR) to Prometheus, PVC storage for inference data

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

To regenerate diagrams for a specific component after architecture changes:
```bash
# From repository root
python scripts/generate_diagram_pngs.py architecture/rhoai-2.8/diagrams --width=3000
```

To regenerate diagrams for all components:
```bash
# Generate diagrams for each component architecture file
for component in architecture/rhoai-2.8/*.md; do
  echo "Processing $component..."
  # Generate diagrams using your diagram generation tool/script
done
```
