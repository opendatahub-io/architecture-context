# Architecture Diagrams for Training Operator

Generated from: `architecture/rhoai-2.12/training-operator.md`
Date: 2026-03-15
Component: training-operator

**Note**: Diagram filenames use base component name without version (directory is already versioned).

## Available Diagrams

All Mermaid diagrams are available in both `.mmd` (source) and `.png` (3000px width, high-resolution) formats.

### For Developers
- [Component Structure](./training-operator-component.png) ([mmd](./training-operator-component.mmd)) - Mermaid diagram showing internal components and controllers
- [Data Flows](./training-operator-dataflow.png) ([mmd](./training-operator-dataflow.mmd)) - Sequence diagram of training job creation and lifecycle flows
- [Dependencies](./training-operator-dependencies.png) ([mmd](./training-operator-dependencies.mmd)) - Component dependency graph showing integrations

### For Architects
- [C4 Context](./training-operator-c4-context.dsl) - System context in C4 format (Structurizr)
- [Component Overview](./training-operator-component.png) ([mmd](./training-operator-component.mmd)) - High-level component view with all controllers

### For Security Teams
- [Security Network Diagram (PNG)](./training-operator-security-network.png) - High-resolution network topology with trust zones
- [Security Network Diagram (Mermaid)](./training-operator-security-network.mmd) - Visual network topology (editable)
- [Security Network Diagram (ASCII)](./training-operator-security-network.txt) - Precise text format for SAR submissions
- [RBAC Visualization](./training-operator-rbac.png) ([mmd](./training-operator-rbac.mmd)) - RBAC permissions and bindings for operator and user roles

## Component Overview

The Kubeflow Training Operator is a unified Kubernetes operator for distributed ML training across multiple frameworks:

**Supported Frameworks**:
- PyTorch (with elastic training support)
- TensorFlow
- MPI
- MXNet
- XGBoost
- PaddlePaddle

**Key Features**:
- Multi-framework support via unified operator
- Gang scheduling integration (Volcano/scheduler-plugins)
- PyTorch elastic training with HPA
- Webhook-based validation and mutation
- Python SDK for programmatic job management

**Deployment**:
- Namespace: `opendatahub`
- Replicas: 1 (with leader election support)
- Istio sidecar: Disabled
- Security: Non-root, no privilege escalation

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
- **Structurizr Lite**:
  ```bash
  docker run -p 8080:8080 -v .:/usr/local/structurizr structurizr/lite
  ```
- **CLI export**:
  ```bash
  structurizr-cli export -workspace training-operator-c4-context.dsl -format png
  ```

### ASCII Diagrams (.txt files)
- View in any text editor
- Include in documentation as-is
- Perfect for security reviews (precise technical details)

## Diagram Descriptions

### Component Diagram
Shows the internal structure of the training operator with:
- Main controller and 6 framework-specific reconcilers
- Webhook server for admission control
- Custom Resource Definitions (CRDs) for each framework
- Created Kubernetes resources (Pods, Services, ConfigMaps, HPA, PodGroups)
- External integrations (Kubernetes API, Prometheus, gang schedulers)

### Data Flow Diagram
Illustrates key operational flows:
1. **Training Job Creation**: User creates job → API Server → Webhook validation → Operator reconciliation → Resource creation
2. **Metrics Collection**: Prometheus scrapes operator metrics endpoint
3. **Gang Scheduling**: Optional PodGroup creation for atomic pod scheduling
4. **PyTorch Elastic**: HPA-based dynamic worker scaling

### Security Network Diagram
Detailed network topology with:
- **ASCII version**: Precise text format with full RBAC summary, secrets, and service mesh config
- **Mermaid version**: Visual representation with color-coded trust zones
- All network flows with ports, protocols, encryption (TLS versions), and authentication
- Trust boundaries: External, Kubernetes API, Operator namespace, User namespaces

### C4 Context Diagram
Architectural context showing:
- Training operator in the broader ecosystem
- External dependencies (Kubernetes, Prometheus, Volcano, scheduler-plugins, cert-manager)
- Internal ODH dependencies (opendatahub-operator, monitoring)
- User interactions via kubectl and Python SDK
- Component breakdown with individual framework controllers

### Dependencies Graph
Visual map of all dependencies and integration points:
- **Required**: Kubernetes 1.25+
- **Optional**: Volcano, scheduler-plugins, cert-manager, Prometheus
- **Internal ODH**: opendatahub-operator (deployment), monitoring (PodMonitor)
- All 6 framework CRDs
- Created resources (Pods, Services, ConfigMaps, HPA, PodGroups)

### RBAC Visualization
Complete RBAC structure:
- **Operator ClusterRole**: Full permissions on training CRDs, core resources, autoscaling, gang scheduling
- **User-facing ClusterRoles**: `training-edit` (create/manage jobs), `training-view` (read-only)
- ServiceAccount bindings
- Detailed permissions for all API groups and resources

## Updating Diagrams

To regenerate after architecture changes:

```bash
# From repository root
cd architecture/rhoai-2.12

# Method 1: Direct invocation (if skill is available)
/generate-architecture-diagrams --architecture=training-operator.md

# Method 2: Python script for PNG regeneration only
python3 ../../scripts/generate_diagram_pngs.py diagrams/ --width=3000
```

## Architecture Documentation

For complete architecture details, see: [training-operator.md](../training-operator.md)

Key sections:
- **APIs Exposed**: 6 CRDs (PyTorchJob, TFJob, MPIJob, MXJob, XGBoostJob, PaddleJob)
- **Dependencies**: Kubernetes 1.25+, optional gang schedulers
- **Network Architecture**: ClusterIP service for metrics, webhook server with mTLS
- **Security**: Comprehensive RBAC with 3 ClusterRoles, non-root containers
- **Data Flows**: 4 documented flows (job creation, metrics, gang scheduling, elastic training)
- **Integration Points**: Kubernetes API, Prometheus, gang schedulers, Python SDK
