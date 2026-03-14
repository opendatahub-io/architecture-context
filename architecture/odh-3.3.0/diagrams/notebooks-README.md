# Architecture Diagrams for Workbench Notebooks

Generated from: `architecture/odh-3.3.0/notebooks.md`
Date: 2026-03-13
Component: notebooks

**Note**: Diagram filenames use base component name without version (directory is already versioned).

## Available Diagrams

All Mermaid diagrams are available in both `.mmd` (source) and `.png` (3000px width, high-resolution) formats.

### For Developers
- [Component Structure](./notebooks-component.png) ([mmd](./notebooks-component.mmd)) - Mermaid diagram showing internal components, workbench images, runtime images, and integrations
- [Data Flows](./notebooks-dataflow.png) ([mmd](./notebooks-dataflow.mmd)) - Sequence diagram of workbench development sessions and pipeline runtime execution
- [Dependencies](./notebooks-dependencies.png) ([mmd](./notebooks-dependencies.mmd)) - Component dependency graph showing external libraries, ODH integrations, and external services

### For Architects
- [C4 Context](./notebooks-c4-context.dsl) - System context in C4 format (Structurizr) showing workbench images in the broader ODH ecosystem
- [Component Overview](./notebooks-component.png) ([mmd](./notebooks-component.mmd)) - High-level component view of base images, workbench images, and runtime images

### For Security Teams
- [Security Network Diagram (PNG)](./notebooks-security-network.png) - High-resolution network topology with trust boundaries
- [Security Network Diagram (Mermaid)](./notebooks-security-network.mmd) - Visual network topology (editable)
- [Security Network Diagram (ASCII)](./notebooks-security-network.txt) - Precise text format for SAR submissions
- [RBAC Visualization](./notebooks-rbac.png) ([mmd](./notebooks-rbac.mmd)) - RBAC permissions, service accounts, and secrets access control

## Component Overview

**Workbench Notebooks** provides pre-configured container images for data science and machine learning workflows. The component includes:

- **Base Images**: Foundation images with Python runtime and dependencies (CPU, CUDA, ROCm variants)
- **Workbench Images**: Interactive development environments with JupyterLab, VS Code Server, and RStudio
- **Runtime Images**: Lightweight images for Data Science Pipelines execution
- **Kustomize Manifests**: Kubernetes deployment configurations for StatefulSets and Services

### Key Integration Points

1. **ODH Notebook Controller**: Manages workbench lifecycle and creates StatefulSets
2. **ODH Dashboard**: Provides web UI for creating and managing notebook instances
3. **Data Science Pipelines**: Uses runtime images for pipeline step execution
4. **Model Registry**: Registers trained models from workbench development

### Security Highlights

- **External Access**: OAuth-protected ingress via OpenShift Routes (HTTPS/443, TLS 1.2+)
- **Internal Communication**: HTTP on port 8888 with Jupyter token authentication
- **Secrets Management**:
  - `notebook-tls-secret`: TLS certificates (auto-rotated by cert-manager)
  - `notebook-oauth-secret`: OAuth proxy authentication token
  - `aws-credentials`: S3 access credentials (user-provided)
  - `git-credentials`: SSH keys for private repositories (user-provided)
- **Egress**: HTTPS connections to PyPI, S3 storage, and Git repositories

### Network Flow Summary

**Workbench Development Session**:
1. User Browser → OpenShift Route (HTTPS/443, OAuth)
2. OAuth Proxy → Notebook Pod (HTTP/8888, Jupyter Token)
3. Notebook Pod → PyPI/S3/Git (HTTPS/443, various auth methods)
4. Notebook Pod → Model Registry (HTTP/8080, Bearer Token)

**Pipeline Runtime Execution**:
1. DSP Orchestrator → Runtime Pod (Kubernetes Exec)
2. Runtime Pod → S3 Artifacts (HTTPS/443, AWS IAM)
3. Runtime Pod → Model Registry (HTTP/8080, Bearer Token)

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
  Then open http://localhost:8080 in your browser
- **CLI export**:
  ```bash
  structurizr-cli export -workspace diagram.dsl -format png
  ```

### ASCII Diagrams (.txt files)
- View in any text editor
- Include in documentation as-is
- Perfect for security reviews (precise technical details)

## Updating Diagrams

To regenerate after architecture changes:

```bash
# From the repository root
python scripts/generate_diagram_pngs.py architecture/odh-3.3.0/diagrams --width=3000
```

Or regenerate everything using the architecture diagram generation workflow (if implemented).

## Architecture Documentation

For full architectural details, see:
- [Workbench Notebooks Architecture](../notebooks.md) - Complete component architecture documentation

## Related Components

- [ODH Dashboard](./odh-dashboard-README.md) - Web UI for workbench management
- [Data Science Pipelines Operator](./data-science-pipelines-operator-README.md) - Pipeline orchestration using runtime images
- [Model Registry Operator](./model-registry-operator-README.md) - Model versioning and metadata storage
- [Platform Architecture](./platform-README.md) - Overall ODH 3.3.0 platform view
