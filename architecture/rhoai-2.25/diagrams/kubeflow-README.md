# Architecture Diagrams for Kubeflow Notebook Controller

Generated from: `architecture/rhoai-2.25/kubeflow.md`
Date: 2026-03-15

**Note**: Diagram filenames use base component name without version (directory is already versioned).

## Available Diagrams

All Mermaid diagrams are available in both `.mmd` (source) and `.png` (3000px width, high-resolution) formats.

### For Developers
- [Component Structure](./kubeflow-component.png) ([mmd](./kubeflow-component.mmd)) - Mermaid diagram showing internal components
- [Data Flows](./kubeflow-dataflow.png) ([mmd](./kubeflow-dataflow.mmd)) - Sequence diagram of request/response flows
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

## Updating Diagrams

To regenerate after architecture changes:
```bash
/generate-architecture-diagrams --architecture=../kubeflow.md
```

## Component Overview

The **Kubeflow Notebook Controller** is a Kubernetes operator that manages the lifecycle of Jupyter notebook instances as custom resources. It:

- Watches Notebook CRDs (kubeflow.org/v1, v1beta1, v1alpha1)
- Creates StatefulSets and Services for notebook instances
- Optionally creates Istio VirtualServices for ingress routing
- Provides automatic culling of idle notebooks to optimize resources
- Exposes Prometheus metrics for monitoring

### Key Components

1. **Notebook Reconciler**: Main controller that translates Notebook CRs into StatefulSets and Services
2. **Culling Reconciler**: Monitors kernel activity and stops idle notebooks after configurable timeout
3. **Metrics Server**: Prometheus metrics endpoint on port 8080
4. **Health Probe**: Kubernetes health checks on port 8081

### Security Highlights

- **RBAC**: Comprehensive ClusterRole permissions for managing notebooks, StatefulSets, Services, and VirtualServices
- **Service Account**: `notebook-controller-service-account` with scoped permissions
- **Network**: ClusterIP services for internal access, optional Istio VirtualServices for external routing
- **Authentication**: ServiceAccount Token (JWT) for Kubernetes API access
- **Encryption**: TLS 1.2+ for Kubernetes API communication

### Dependencies

- **Required**: Kubernetes 1.22.0+
- **Optional**: Istio Service Mesh (for VirtualServices), Prometheus (for metrics)
- **Internal**: Kubeflow Dashboard (consumes Notebook CRD)
