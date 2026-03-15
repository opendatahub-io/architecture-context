# Architecture Diagrams for Notebooks (Workbench Images)

Generated from: `architecture/rhoai-2.25/notebooks.md`
Date: 2026-03-15
Component: notebooks

**Note**: Diagram filenames use base component name without version (directory `rhoai-2.25/` is already versioned).

## Available Diagrams

All Mermaid diagrams are available in both `.mmd` (source) and `.png` (3000px width, high-resolution) formats.

### For Developers
- [Component Structure](./notebooks-component.png) ([mmd](./notebooks-component.mmd)) - Mermaid diagram showing workbench images, runtime images, and build infrastructure
- [Data Flows](./notebooks-dataflow.png) ([mmd](./notebooks-dataflow.mmd)) - Sequence diagrams of user workbench access, pipeline execution, and image build/deployment flows
- [Dependencies](./notebooks-dependencies.png) ([mmd](./notebooks-dependencies.mmd)) - Component dependency graph showing external dependencies and ODH integrations

### For Architects
- [C4 Context](./notebooks-c4-context.dsl) - System context in C4 format (Structurizr) showing notebooks in the broader RHOAI ecosystem
- [Component Overview](./notebooks-component.png) ([mmd](./notebooks-component.mmd)) - High-level component view of all workbench and runtime image variants

### For Security Teams
- [Security Network Diagram (PNG)](./notebooks-security-network.png) - High-resolution network topology
- [Security Network Diagram (Mermaid)](./notebooks-security-network.mmd) - Visual network topology (editable)
- [Security Network Diagram (ASCII)](./notebooks-security-network.txt) - Precise text format for SAR submissions
- [RBAC Visualization](./notebooks-rbac.png) ([mmd](./notebooks-rbac.mmd)) - RBAC permissions and authentication mechanisms

## Component Overview

The **Notebooks** component provides containerized development environments and pipeline runtimes for data science workflows in RHOAI. It includes:

### Workbench Images
Interactive development environments with various ML frameworks and accelerator support:
- **Jupyter Images**: JupyterLab 4.4 with CPU, CUDA (NVIDIA GPU), and ROCm (AMD GPU) variants
  - Minimal, Data Science, PyTorch, TensorFlow, TrustyAI, LLMCompressor variants
- **Code Server Images**: VS Code-based development with data science libraries
- **RStudio Images**: R-based data science with CPU and CUDA support

### Runtime Images
Lightweight images for Kubeflow Pipelines task execution:
- Minimal, Data Science, PyTorch, TensorFlow variants
- CPU and GPU accelerator support

### Build Infrastructure
- **Konflux CI/CD**: Multi-architecture builds (x86_64, arm64, ppc64le, s390x)
- **Base Images**: UBI9 Python, CUDA, ROCm foundations
- **ImageStreams**: OpenShift image references for deployment

## Key Architectural Patterns

1. **OAuth Proxy Pattern**: All workbench access goes through OAuth proxy sidecar for authentication
2. **Multi-Variant Strategy**: Single repository produces 20+ image variants for different use cases
3. **Incremental Builds**: Weekly security patches without changing major versions
4. **Multi-Arch Support**: All images support x86_64, arm64, ppc64le, and s390x architectures

## Network Security

- **Ingress**: OpenShift Router (443/TCP HTTPS) → OAuth Proxy (8443/TCP HTTPS Internal CA) → Workbench Container (8888/8080/8787 HTTP localhost)
- **Egress**: S3 Storage (443/TCP HTTPS TLS1.2+, S3 credentials), Quay.io (image pulls)
- **Authentication**: OpenShift OAuth via proxy sidecar (workbenches), ServiceAccount tokens (pipelines)
- **No Service Mesh**: TLS termination at OpenShift Route level, not pod-to-pod mTLS

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
# From the repository root
python scripts/generate_diagram_pngs.py architecture/rhoai-2.25/diagrams --width=3000
```

## References

- **Architecture Source**: [notebooks.md](../notebooks.md)
- **GitHub Repository**: https://github.com/red-hat-data-services/notebooks
- **Container Registry**: https://quay.io/organization/opendatahub/workbench-images
- **Wiki**: https://github.com/opendatahub-io/notebooks/wiki/Workbenches
