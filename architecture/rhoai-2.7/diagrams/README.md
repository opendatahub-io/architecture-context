# Architecture Diagrams for RHOAI 2.7 Components

This directory contains architecture diagrams for multiple RHOAI 2.7 components.

Generated: 2026-03-15

**Note**: Diagram filenames use base component name without version (directory is already versioned).

## Available Components

- [Platform (Aggregated View)](#platform-aggregated-view) ⭐ **NEW**
- [CodeFlare Operator](#codeflare-operator)
- [Data Science Pipelines Operator](#data-science-pipelines-operator)
- [KServe](#kserve)
- [Kubeflow](#kubeflow)
- [KubeRay](#kuberay)
- [ModelMesh Serving](#modelmesh-serving)
- [Notebooks (Workbench Images)](#notebooks-workbench-images)
- [ODH Model Controller](#odh-model-controller)
- [RHOAI Operator](#rhoai-operator)
- [TrustyAI Service Operator](#trustyai-service-operator)

All Mermaid diagrams are available in both `.mmd` (source) and `.png` (3000px width, high-resolution) formats.

---

## Platform (Aggregated View)

**Source**: [PLATFORM.md](../PLATFORM.md)

This is the **aggregated platform view** showing all 10 components working together in the Red Hat OpenShift AI 2.7 ecosystem.

### For Developers
- [Component Structure](./platform-component.png) ([mmd](./platform-component.mmd)) - Complete platform architecture with all operators
- [Data Flows](./platform-dataflow.png) ([mmd](./platform-dataflow.mmd)) - End-to-end model training to deployment workflow
- [Dependencies](./platform-dependencies.png) ([mmd](./platform-dependencies.mmd)) - Platform-wide dependency graph

### For Architects
- [C4 Context](./platform-c4-context.dsl) - System context with all platform containers and components
- [Component Overview](./platform-component.png) ([mmd](./platform-component.mmd)) - High-level platform architecture

### For Security Teams
- [Security Network (PNG)](./platform-security-network.png) | [Mermaid](./platform-security-network.mmd) | [ASCII](./platform-security-network.txt)
- [RBAC](./platform-rbac.png) ([mmd](./platform-rbac.mmd)) - Platform-wide RBAC visualization

**Key Highlights**:
- Shows interaction between all 10 operators
- Complete network flow from external users to model serving
- Platform-wide RBAC across all components
- Service mesh integration (Istio mTLS)
- OpenShift integration (OAuth, Routes, Monitoring)
- External dependencies (S3, Knative, Tekton)

---

## CodeFlare Operator

**Source**: [codeflare-operator.md](../codeflare-operator.md)

### For Developers
- [Component Structure](./codeflare-operator-component.png) ([mmd](./codeflare-operator-component.mmd))
- [Data Flows](./codeflare-operator-dataflow.png) ([mmd](./codeflare-operator-dataflow.mmd))
- [Dependencies](./codeflare-operator-dependencies.png) ([mmd](./codeflare-operator-dependencies.mmd))

### For Architects
- [C4 Context](./codeflare-operator-c4-context.dsl)

### For Security Teams
- [Security Network (PNG)](./codeflare-operator-security-network.png) | [Mermaid](./codeflare-operator-security-network.mmd) | [ASCII](./codeflare-operator-security-network.txt)
- [RBAC](./codeflare-operator-rbac.png) ([mmd](./codeflare-operator-rbac.mmd))

---

## Data Science Pipelines Operator

**Source**: [data-science-pipelines-operator.md](../data-science-pipelines-operator.md)

### For Developers
- [Component Structure](./data-science-pipelines-operator-component.png) ([mmd](./data-science-pipelines-operator-component.mmd))
- [Data Flows](./data-science-pipelines-operator-dataflow.png) ([mmd](./data-science-pipelines-operator-dataflow.mmd))
- [Dependencies](./data-science-pipelines-operator-dependencies.png) ([mmd](./data-science-pipelines-operator-dependencies.mmd))

### For Architects
- [C4 Context](./data-science-pipelines-operator-c4-context.dsl)

### For Security Teams
- [Security Network (PNG)](./data-science-pipelines-operator-security-network.png) | [Mermaid](./data-science-pipelines-operator-security-network.mmd) | [ASCII](./data-science-pipelines-operator-security-network.txt)
- [RBAC](./data-science-pipelines-operator-rbac.png) ([mmd](./data-science-pipelines-operator-rbac.mmd))

---

## KServe

**Source**: [kserve.md](../kserve.md)

### For Developers
- [Component Structure](./kserve-component.png) ([mmd](./kserve-component.mmd))
- [Data Flows](./kserve-dataflow.png) ([mmd](./kserve-dataflow.mmd))
- [Dependencies](./kserve-dependencies.png) ([mmd](./kserve-dependencies.mmd))

### For Architects
- [C4 Context](./kserve-c4-context.dsl)

### For Security Teams
- [Security Network (PNG)](./kserve-security-network.png) | [Mermaid](./kserve-security-network.mmd) | [ASCII](./kserve-security-network.txt)
- [RBAC](./kserve-rbac.png) ([mmd](./kserve-rbac.mmd))

---

## Kubeflow

**Source**: [kubeflow.md](../kubeflow.md)

### For Developers
- [Component Structure](./kubeflow-component.png) ([mmd](./kubeflow-component.mmd))
- [Data Flows](./kubeflow-dataflow.png) ([mmd](./kubeflow-dataflow.mmd))
- [Dependencies](./kubeflow-dependencies.png) ([mmd](./kubeflow-dependencies.mmd))

### For Architects
- [C4 Context](./kubeflow-c4-context.dsl)

### For Security Teams
- [Security Network (PNG)](./kubeflow-security-network.png) | [Mermaid](./kubeflow-security-network.mmd) | [ASCII](./kubeflow-security-network.txt)
- [RBAC](./kubeflow-rbac.png) ([mmd](./kubeflow-rbac.mmd))

---

## KubeRay

**Source**: [kuberay.md](../kuberay.md)

### For Developers
- [Component Structure](./kuberay-component.png) ([mmd](./kuberay-component.mmd))
- [Data Flows](./kuberay-dataflow.png) ([mmd](./kuberay-dataflow.mmd))
- [Dependencies](./kuberay-dependencies.png) ([mmd](./kuberay-dependencies.mmd))

### For Architects
- [C4 Context](./kuberay-c4-context.dsl)

### For Security Teams
- [Security Network (PNG)](./kuberay-security-network.png) | [Mermaid](./kuberay-security-network.mmd) | [ASCII](./kuberay-security-network.txt)
- [RBAC](./kuberay-rbac.png) ([mmd](./kuberay-rbac.mmd))

---

## ModelMesh Serving

**Source**: [modelmesh-serving.md](../modelmesh-serving.md)

### For Developers
- [Component Structure](./modelmesh-serving-component.png) ([mmd](./modelmesh-serving-component.mmd))
- [Data Flows](./modelmesh-serving-dataflow.png) ([mmd](./modelmesh-serving-dataflow.mmd))
- [Dependencies](./modelmesh-serving-dependencies.png) ([mmd](./modelmesh-serving-dependencies.mmd))

### For Architects
- [C4 Context](./modelmesh-serving-c4-context.dsl)

### For Security Teams
- [Security Network (PNG)](./modelmesh-serving-security-network.png) | [Mermaid](./modelmesh-serving-security-network.mmd) | [ASCII](./modelmesh-serving-security-network.txt)
- [RBAC](./modelmesh-serving-rbac.png) ([mmd](./modelmesh-serving-rbac.mmd))

---

## Notebooks (Workbench Images)

**Source**: [notebooks.md](../notebooks.md)

### For Developers
- [Component Structure](./notebooks-component.png) ([mmd](./notebooks-component.mmd))
- [Data Flows](./notebooks-dataflow.png) ([mmd](./notebooks-dataflow.mmd))
- [Dependencies](./notebooks-dependencies.png) ([mmd](./notebooks-dependencies.mmd))

### For Architects
- [C4 Context](./notebooks-c4-context.dsl)

### For Security Teams
- [Security Network (PNG)](./notebooks-security-network.png) | [Mermaid](./notebooks-security-network.mmd) | [ASCII](./notebooks-security-network.txt)
- [RBAC](./notebooks-rbac.png) ([mmd](./notebooks-rbac.mmd))

---

## ODH Model Controller

**Source**: [odh-model-controller.md](../odh-model-controller.md)

### For Developers
- [Component Structure](./odh-model-controller-component.png) ([mmd](./odh-model-controller-component.mmd))
- [Data Flows](./odh-model-controller-dataflow.png) ([mmd](./odh-model-controller-dataflow.mmd))
- [Dependencies](./odh-model-controller-dependencies.png) ([mmd](./odh-model-controller-dependencies.mmd))

### For Architects
- [C4 Context](./odh-model-controller-c4-context.dsl)

### For Security Teams
- [Security Network (PNG)](./odh-model-controller-security-network.png) | [Mermaid](./odh-model-controller-security-network.mmd) | [ASCII](./odh-model-controller-security-network.txt)
- [RBAC](./odh-model-controller-rbac.png) ([mmd](./odh-model-controller-rbac.mmd))

---

## RHOAI Operator

**Source**: [rhods-operator.md](../rhods-operator.md)

### For Developers
- [Component Structure](./rhods-operator-component.png) ([mmd](./rhods-operator-component.mmd))
- [Data Flows](./rhods-operator-dataflow.png) ([mmd](./rhods-operator-dataflow.mmd))
- [Dependencies](./rhods-operator-dependencies.png) ([mmd](./rhods-operator-dependencies.mmd))

### For Architects
- [C4 Context](./rhods-operator-c4-context.dsl)

### For Security Teams
- [Security Network (PNG)](./rhods-operator-security-network.png) | [Mermaid](./rhods-operator-security-network.mmd) | [ASCII](./rhods-operator-security-network.txt)
- [RBAC](./rhods-operator-rbac.png) ([mmd](./rhods-operator-rbac.mmd))

---

## TrustyAI Service Operator

**Source**: [trustyai-service-operator.md](../trustyai-service-operator.md)

### For Developers
- [Component Structure](./trustyai-service-operator-component.png) ([mmd](./trustyai-service-operator-component.mmd))
- [Data Flows](./trustyai-service-operator-dataflow.png) ([mmd](./trustyai-service-operator-dataflow.mmd))
- [Dependencies](./trustyai-service-operator-dependencies.png) ([mmd](./trustyai-service-operator-dependencies.mmd))

### For Architects
- [C4 Context](./trustyai-service-operator-c4-context.dsl)

### For Security Teams
- [Security Network (PNG)](./trustyai-service-operator-security-network.png) | [Mermaid](./trustyai-service-operator-security-network.mmd) | [ASCII](./trustyai-service-operator-security-network.txt)
- [RBAC](./trustyai-service-operator-rbac.png) ([mmd](./trustyai-service-operator-rbac.mmd))

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
# From the repository root
python scripts/generate_diagram_pngs.py architecture/rhoai-2.7/diagrams --width=3000
```

Or regenerate from architecture markdown:
```bash
# Example for KubeRay
/generate-architecture-diagrams --architecture=architecture/rhoai-2.7/kuberay.md
```

## Component Summaries

### Platform (Aggregated View)
Complete Red Hat OpenShift AI 2.7 platform architecture showing all 10 components integrated together. Includes platform control plane (RHOAI Operator), notebook management, ML pipelines (DSP + Tekton), model serving (KServe + ModelMesh), distributed computing (CodeFlare + KubeRay), and AI governance (TrustyAI). Shows end-to-end workflows, service mesh integration, OpenShift-native features (OAuth, Routes), and platform-wide RBAC and network security.

### CodeFlare Operator
Manages distributed workload scheduling with MCAD (Multi-Cluster App Dispatcher) and optional InstaScale for dynamic node scaling.

### Data Science Pipelines Operator
Deploys and manages Kubeflow Pipelines instances with MariaDB/MySQL backend, MinIO storage, and ML metadata tracking.

### KServe
Serverless ML inference platform with standardized model serving, autoscaling, canary rollouts, and multi-framework support.

### Kubeflow
Notebook controller for managing Jupyter notebook servers with various ML framework images and persistent storage.

### KubeRay
Kubernetes operator for Ray clusters, distributed computing jobs, and Ray Serve model inference with autoscaling.

### ModelMesh Serving
Multi-model serving platform with intelligent model placement, caching, and resource sharing across multiple ML frameworks.

### Notebooks (Workbench Images)
Containerized workbench environments (Jupyter, code-server, RStudio) for interactive data science and ML workflows with support for CPU and GPU acceleration.

### ODH Model Controller
Extends KServe model serving with OpenShift-specific integrations including Routes, NetworkPolicies, and service mesh configuration.

### RHOAI Operator
Primary operator for Red Hat OpenShift AI that manages the lifecycle of all data science platform components. Orchestrates deployment and configuration via DataScienceCluster and DSCInitialization CRDs for Dashboard, KServe, ModelMesh, Pipelines, CodeFlare, Ray, and Workbenches with integrated service mesh and monitoring.

### TrustyAI Service Operator
Manages AI explainability and fairness monitoring services for model inference. Integrates with KServe and ModelMesh to capture inference payloads, calculate fairness metrics (SPD, DIR), and expose Prometheus metrics. Optional component in RHOAI 2.7 (removed from default installation).

For detailed architecture information, see the corresponding `.md` files in the parent directory.
