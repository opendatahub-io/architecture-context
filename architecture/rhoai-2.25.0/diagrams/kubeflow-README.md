# Architecture Diagrams for Notebook Controller (Kubeflow)

Generated from: `architecture/rhoai-2.25.0/kubeflow.md`
Date: 2026-03-14

**Note**: Diagram filenames use base component name without version (directory is already versioned).

## Available Diagrams

All Mermaid diagrams are available in both `.mmd` (source) and `.png` (3000px width, high-resolution) formats.

### For Developers
- [Component Structure](./kubeflow-component.png) ([mmd](./kubeflow-component.mmd)) - Mermaid diagram showing internal components (NotebookReconciler, CullingReconciler)
- [Data Flows](./kubeflow-dataflow.png) ([mmd](./kubeflow-dataflow.mmd)) - Sequence diagram of notebook creation, culling, and metrics flows
- [Dependencies](./kubeflow-dependencies.png) ([mmd](./kubeflow-dependencies.mmd)) - Component dependency graph

### For Architects
- [C4 Context](./kubeflow-c4-context.dsl) - System context in C4 format (Structurizr)
- [Component Overview](./kubeflow-component.png) ([mmd](./kubeflow-component.mmd)) - High-level component view

### For Security Teams
- [Security Network Diagram (PNG)](./kubeflow-security-network.png) - High-resolution network topology
- [Security Network Diagram (Mermaid)](./kubeflow-security-network.mmd) - Visual network topology (editable)
- [Security Network Diagram (ASCII)](./kubeflow-security-network.txt) - Precise text format for SAR submissions
- [RBAC Visualization](./kubeflow-rbac.png) ([mmd](./kubeflow-rbac.mmd)) - RBAC permissions and bindings

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

## Architecture Summary

The **Notebook Controller** is a Kubernetes operator that manages the lifecycle of Jupyter notebook instances. Key features:

- **Custom Resource**: Notebook CRD (kubeflow.org/v1)
- **Reconciliation**: Translates Notebook CRs into StatefulSets and Services
- **Auto Culling**: Optional idle notebook detection and automatic stopping
- **Istio Integration**: Optional VirtualService creation for ingress routing
- **Metrics**: Prometheus metrics for monitoring notebook operations

### Key Components

1. **Notebook Reconciler**: Main controller managing notebook lifecycle
2. **Culling Reconciler**: Monitors and stops idle notebooks
3. **Metrics Server**: Exposes Prometheus metrics (:8080/TCP)
4. **Health Probe**: Kubernetes health checks (:8081/TCP)

### Security Highlights

- **RBAC**: ClusterRole with permissions for notebooks, statefulsets, services
- **ServiceAccount**: notebook-controller-service-account
- **API Auth**: ServiceAccount tokens for K8s API operations
- **Culling**: Unauthenticated HTTP/8888 access to notebook pods (limitation)
- **Metrics**: HTTP only (no TLS) - relies on network policies

### Network Architecture

- **Ingress**: Optional Istio VirtualService (when USE_ISTIO=true)
- **Service**: ClusterIP per notebook (80/TCP to 8888/TCP)
- **Egress**: Kubernetes API Server (6443/TCP HTTPS TLS 1.2+)
- **Monitoring**: Prometheus scrapes :8080/TCP (HTTP)

## Updating Diagrams

To regenerate after architecture changes:
```bash
# From repository root
python scripts/generate_diagram_pngs.py architecture/rhoai-2.25.0/diagrams --width=3000
```

Or use the full diagram generation workflow (if available).
