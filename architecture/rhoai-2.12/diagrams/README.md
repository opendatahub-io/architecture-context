# Architecture Diagrams for RHOAI 2.12 Components

Generated from: `architecture/rhoai-2.12/*.md`
Date: 2026-03-15

**Note**: Diagram filenames use base component name without version (directory is already versioned).

## Available Diagrams

All Mermaid diagrams are available in both `.mmd` (source) and `.png` (3000px width, high-resolution) formats.

---

## Platform Overview Diagrams

### Red Hat OpenShift AI 2.12 Platform

Complete platform architecture showing all 13 components and their relationships.

#### For Developers
- [Component Structure](./platform-component.png) ([mmd](./platform-component.mmd)) - All 13 platform components and their relationships
- [Data Flows](./platform-dataflow.png) ([mmd](./platform-dataflow.mmd)) - 5 major workflows: training to deployment, distributed training, pipelines, Ray, TrustyAI
- [Dependencies](./platform-dependencies.png) ([mmd](./platform-dependencies.mmd)) - Complete dependency graph of all components and external services

#### For Architects
- [C4 Context](./platform-c4-context.dsl) - System context in C4 format (Structurizr) showing RHOAI in broader ecosystem

#### For Security Teams
- [Security Network Diagram (PNG)](./platform-security-network.png) - High-resolution network topology with trust boundaries (356KB)
- [Security Network Diagram (Mermaid)](./platform-security-network.mmd) - Visual network topology (editable)
- [Security Network Diagram (ASCII)](./platform-security-network.txt) - Precise text format for SAR submissions with RBAC, Service Mesh config, Secrets inventory
- [RBAC Visualization](./platform-rbac.png) ([mmd](./platform-rbac.mmd)) - All 12 operator permissions and user-facing roles

**Platform Components (13 Total):**
- RHODS Operator v1.6.0 (central orchestrator)
- ODH Dashboard v1.21.0 (web UI)
- KServe 81bf82134 (serverless serving)
- ModelMesh v1.27.0 (multi-model serving)
- ODH Model Controller v1.27.0 (Routes, service mesh)
- Data Science Pipelines 6bcc644 (Kubeflow Pipelines v2)
- ODH Notebook Controller v1.27.0 (JupyterLab/RStudio/VS Code)
- CodeFlare 4e58587 (distributed workload orchestration)
- KubeRay b0225b36 (Ray cluster management)
- Kueue v0.7.0 (job queueing)
- Training Operator c7d4e1b4 (PyTorch/TensorFlow/MPI)
- TrustyAI 1.17.0 (fairness metrics)
- Prometheus Stack (monitoring)

**Key Workflows Visualized:**
1. Model training to deployment (end-to-end)
2. Distributed training with Kueue
3. ML pipeline execution with Argo
4. Ray cluster for distributed compute
5. Model fairness analysis with TrustyAI

---

## Individual Component Diagrams

### KubeRay Operator

Kubernetes operator for deploying and managing Ray clusters on Kubernetes for distributed ML/AI workloads.

#### For Developers
- [Component Structure](./kuberay-component.png) ([mmd](./kuberay-component.mmd)) - Operator controllers, Ray cluster resources, and optional components
- [Data Flows](./kuberay-dataflow.png) ([mmd](./kuberay-dataflow.mmd)) - RayCluster creation, job submission, inference, and reconciliation flows
- [Dependencies](./kuberay-dependencies.png) ([mmd](./kuberay-dependencies.mmd)) - External dependencies and integration points

#### For Architects
- [C4 Context](./kuberay-c4-context.dsl) - System context in C4 format (Structurizr)

#### For Security Teams
- [Security Network Diagram (PNG)](./kuberay-security-network.png) - High-resolution network topology
- [Security Network Diagram (Mermaid)](./kuberay-security-network.mmd) - Visual network topology (editable)
- [Security Network Diagram (ASCII)](./kuberay-security-network.txt) - Precise text format for SAR submissions
- [RBAC Visualization](./kuberay-rbac.png) ([mmd](./kuberay-rbac.mmd)) - RBAC permissions and bindings

---

### Data Science Pipelines Operator

Manages Kubeflow Pipelines deployments for ML workflow orchestration.

#### For Developers
- [Component Structure](./data-science-pipelines-operator-component.png) ([mmd](./data-science-pipelines-operator-component.mmd)) - Operator and pipeline components
- [Data Flows](./data-science-pipelines-operator-dataflow.png) ([mmd](./data-science-pipelines-operator-dataflow.mmd)) - Pipeline execution flows
- [Dependencies](./data-science-pipelines-operator-dependencies.png) ([mmd](./data-science-pipelines-operator-dependencies.mmd)) - Component dependency graph

#### For Architects
- [C4 Context](./data-science-pipelines-operator-c4-context.dsl) - System context in C4 format (Structurizr)

#### For Security Teams
- [Security Network Diagram (PNG)](./data-science-pipelines-operator-security-network.png) - High-resolution network topology
- [Security Network Diagram (Mermaid)](./data-science-pipelines-operator-security-network.mmd) - Visual network topology (editable)
- [Security Network Diagram (ASCII)](./data-science-pipelines-operator-security-network.txt) - Precise text format for SAR submissions
- [RBAC Visualization](./data-science-pipelines-operator-rbac.png) ([mmd](./data-science-pipelines-operator-rbac.mmd)) - RBAC permissions and bindings

---

### CodeFlare Operator

Manages distributed workload orchestration for batch AI/ML jobs.

#### For Developers
- [Component Structure](./codeflare-operator-component.png) ([mmd](./codeflare-operator-component.mmd)) - Operator components
- [Data Flows](./codeflare-operator-dataflow.png) ([mmd](./codeflare-operator-dataflow.mmd)) - Workload execution flows
- [Dependencies](./codeflare-operator-dependencies.png) ([mmd](./codeflare-operator-dependencies.mmd)) - Component dependencies

#### For Architects
- [C4 Context](./codeflare-operator-c4-context.dsl) - System context in C4 format (Structurizr)

#### For Security Teams
- [Security Network Diagram (PNG)](./codeflare-operator-security-network.png) - High-resolution network topology
- [Security Network Diagram (Mermaid)](./codeflare-operator-security-network.mmd) - Visual network topology (editable)
- [Security Network Diagram (ASCII)](./codeflare-operator-security-network.txt) - Precise text format for SAR submissions
- [RBAC Visualization](./codeflare-operator-rbac.png) ([mmd](./codeflare-operator-rbac.mmd)) - RBAC permissions and bindings

---

### KServe

Serverless model serving platform with autoscaling and traffic management.

#### For Developers
- [Component Structure](./kserve-component.png) ([mmd](./kserve-component.mmd)) - KServe controller and model serving components
- [Data Flows](./kserve-dataflow.png) ([mmd](./kserve-dataflow.mmd)) - Inference request flows
- [Dependencies](./kserve-dependencies.png) ([mmd](./kserve-dependencies.mmd)) - Component dependencies

#### For Architects
- [C4 Context](./kserve-c4-context.dsl) - System context in C4 format (Structurizr)

#### For Security Teams
- [Security Network Diagram (PNG)](./kserve-security-network.png) - High-resolution network topology
- [Security Network Diagram (Mermaid)](./kserve-security-network.mmd) - Visual network topology (editable)
- [Security Network Diagram (ASCII)](./kserve-security-network.txt) - Precise text format for SAR submissions
- [RBAC Visualization](./kserve-rbac.png) ([mmd](./kserve-rbac.mmd)) - RBAC permissions and bindings

---

### Kubeflow Notebooks

Jupyter notebook environment for data science and ML development.

#### For Developers
- [Data Flows](./kubeflow-dataflow.png) ([mmd](./kubeflow-dataflow.mmd)) - Notebook access and execution flows
- [Dependencies](./kubeflow-dependencies.png) ([mmd](./kubeflow-dependencies.mmd)) - Component dependencies

#### For Architects
- [C4 Context](./kubeflow-c4-context.dsl) - System context in C4 format (Structurizr)

#### For Security Teams
- [Security Network Diagram (PNG)](./kubeflow-security-network.png) - High-resolution network topology
- [Security Network Diagram (Mermaid)](./kubeflow-security-network.mmd) - Visual network topology (editable)
- [Security Network Diagram (ASCII)](./kubeflow-security-network.txt) - Precise text format for SAR submissions
- [RBAC Visualization](./kubeflow-rbac.png) ([mmd](./kubeflow-rbac.mmd)) - RBAC permissions and bindings

---

### Kueue

Cloud-native job queueing system for fair resource sharing and batch workload management.

#### For Developers
- [Component Structure](./kueue-component.png) ([mmd](./kueue-component.mmd)) - Controller, webhooks, visibility API, and CRDs
- [Data Flows](./kueue-dataflow.png) ([mmd](./kueue-dataflow.mmd)) - Job admission, metrics collection, visibility queries, and autoscaling flows
- [Dependencies](./kueue-dependencies.png) ([mmd](./kueue-dependencies.mmd)) - Integration with Kubernetes, Kubeflow, Ray, and cluster autoscaler

#### For Architects
- [C4 Context](./kueue-c4-context.dsl) - System context in C4 format (Structurizr)

#### For Security Teams
- [Security Network Diagram (PNG)](./kueue-security-network.png) - High-resolution network topology
- [Security Network Diagram (Mermaid)](./kueue-security-network.mmd) - Visual network topology (editable)
- [Security Network Diagram (ASCII)](./kueue-security-network.txt) - Precise text format for SAR submissions
- [RBAC Visualization](./kueue-rbac.png) ([mmd](./kueue-rbac.mmd)) - RBAC permissions and bindings

## How to Use

### PNG Files (.png files)
**Automatically generated** at 3000px width for high-resolution presentations and documentation.

- **Ready to use**: High-resolution images suitable for presentations, wikis, and documentation
- **Width**: 3000px (height auto-adjusts to content)
- **Use directly**: Include in PowerPoint, Google Slides, Confluence, etc.

### Mermaid Source Files (.mmd files)
- **In GitHub/GitLab**: Paste into markdown with \`\`\`\`mermaid\` code blocks - renders automatically!
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

**Note**: If \`google-chrome\` is not found, try \`chromium\` or \`which google-chrome\` to locate it

### C4 Diagrams (.dsl files)
- **Structurizr Lite**: \`docker run -p 8080:8080 -v .:/usr/local/structurizr structurizr/lite\`
- **CLI export**: \`structurizr-cli export -workspace diagram.dsl -format png\`

### ASCII Diagrams (.txt files)
- View in any text editor
- Include in documentation as-is
- Perfect for security reviews (precise technical details)

## Updating Diagrams

To regenerate diagrams after architecture changes, use the Python script:

```bash
# Regenerate all diagrams in this directory
python scripts/generate_diagram_pngs.py architecture/rhoai-2.12/diagrams --width=3000 --force

# Or regenerate incrementally (only changed .mmd files)
python scripts/generate_diagram_pngs.py architecture/rhoai-2.12/diagrams --width=3000
```
