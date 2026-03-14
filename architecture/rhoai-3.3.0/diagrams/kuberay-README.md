# Architecture Diagrams for KubeRay Operator

Generated from: `architecture/rhoai-3.3.0/kuberay.md`
Date: 2026-03-14

**Note**: Diagram filenames use base component name without version (directory is already versioned).

## Available Diagrams

All Mermaid diagrams are available in both `.mmd` (source) and `.png` (3000px width, high-resolution) formats.

### For Developers
- [Component Structure](./kuberay-component.png) ([mmd](./kuberay-component.mmd)) - Mermaid diagram showing internal components, controllers, and managed resources
- [Data Flows](./kuberay-dataflow.png) ([mmd](./kuberay-dataflow.mmd)) - Sequence diagram of RayCluster creation, job submission, and model serving flows
- [Dependencies](./kuberay-dependencies.png) ([mmd](./kuberay-dependencies.mmd)) - Component dependency graph showing external and internal integrations

### For Architects
- [C4 Context](./kuberay-c4-context.dsl) - System context in C4 format (Structurizr)
- [Component Overview](./kuberay-component.png) ([mmd](./kuberay-component.mmd)) - High-level component view with controllers and managed Ray clusters

### For Security Teams
- [Security Network Diagram (PNG)](./kuberay-security-network.png) - High-resolution network topology with trust zones
- [Security Network Diagram (Mermaid)](./kuberay-security-network.mmd) - Visual network topology (editable)
- [Security Network Diagram (ASCII)](./kuberay-security-network.txt) - Precise text format for SAR submissions
- [RBAC Visualization](./kuberay-rbac.png) ([mmd](./kuberay-rbac.mmd)) - RBAC permissions and bindings

## Component Overview

**KubeRay Operator** is a Kubernetes operator that manages the lifecycle of Ray clusters for distributed computing workloads.

Key capabilities:
- **Ray Clusters**: Manages RayCluster CR with head and worker nodes, autoscaling, and fault tolerance
- **Batch Jobs**: Manages RayJob CR for batch job execution on Ray clusters
- **Model Serving**: Manages RayService CR for Ray Serve deployments with HA and zero-downtime upgrades
- **Security**: NetworkPolicy controller, mTLS/OAuth authentication, and cert-manager integration
- **Integrations**: Gateway API, OpenShift Routes, Prometheus monitoring, external Redis for GCS HA

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

## Architecture Highlights

### Controllers
The operator includes 5 main controllers:
- **RayCluster Controller**: Manages RayCluster lifecycle, autoscaling, and resource reconciliation
- **RayJob Controller**: Manages batch job execution on Ray clusters
- **RayService Controller**: Manages Ray Serve deployments with HA and zero-downtime upgrades
- **NetworkPolicy Controller**: Creates and manages network policies for Ray cluster isolation
- **Authentication Controller**: Manages mTLS certificates, OAuth integration, and Gateway API authentication

### Custom Resources
- **RayCluster** (ray.io/v1): Defines a Ray cluster with head and worker groups, autoscaling, and fault tolerance
- **RayJob** (ray.io/v1): Defines a batch job to run on a Ray cluster with automatic cluster lifecycle
- **RayService** (ray.io/v1): Defines a Ray Serve deployment for model serving with HA and zero-downtime upgrades

### Ray Cluster Services
Managed clusters expose:
- **Ray GCS Server** (6379/TCP): Global Control Service for cluster metadata (optional mTLS)
- **Ray Dashboard** (8265/TCP): Web UI for cluster monitoring and management (optional OAuth)
- **Ray Client Server** (10001/TCP): Client connection endpoint for job submission (optional mTLS)
- **Ray Serve** (8000/TCP): Model serving endpoints for RayService (optional TLS)

### Security Features
- **mTLS**: Optional mutual TLS for Ray cluster communication (cert-manager integration)
- **OAuth**: Optional OAuth/bearer token authentication for Ray Dashboard and Serve
- **NetworkPolicies**: Automatic network isolation for multi-tenant deployments
- **SCC**: Security Context Constraints (runAsUser: 1000, no privilege escalation)
- **RBAC**: Comprehensive cluster-scoped permissions for managing Ray resources

### Dependencies
**External** (Required):
- Kubernetes 1.30+
- controller-runtime v0.22.1

**External** (Optional):
- cert-manager v1.x (TLS certificate management)
- Gateway API v1/v1beta1 (advanced routing)
- OpenShift Route API v1 (OpenShift ingress)
- Prometheus (monitoring)
- External Redis (GCS fault tolerance)

**Internal ODH** (Integration):
- ODH Dashboard (displays Ray cluster status)
- Model Registry (distributed training)
- Data Science Pipelines (Ray job execution)

## Updating Diagrams

To regenerate after architecture changes:
```bash
# From repository root
cd architecture/rhoai-3.3.0
python ../../scripts/generate_diagram_pngs.py diagrams --width=3000
```

Or regenerate all diagrams from the architecture file (not yet implemented - manual for now).
