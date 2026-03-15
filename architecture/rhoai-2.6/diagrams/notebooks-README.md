# Architecture Diagrams for Notebook Images

Generated from: `architecture/rhoai-2.6/notebooks.md`
Date: 2026-03-15
Component: notebooks

**Note**: Diagram filenames use base component name without version (directory is already versioned).

## Available Diagrams

All Mermaid diagrams are available in both `.mmd` (source) and `.png` (3000px width, high-resolution) formats.

### For Developers
- [Component Structure](./notebooks-component.png) ([mmd](./notebooks-component.mmd)) - Mermaid diagram showing image variants, layering, and build dependencies
- [Data Flows](./notebooks-dataflow.png) ([mmd](./notebooks-dataflow.mmd)) - Sequence diagram of user access, S3 storage, pipeline execution, and image distribution flows
- [Dependencies](./notebooks-dependencies.png) ([mmd](./notebooks-dependencies.mmd)) - Component dependency graph showing external and internal RHOAI dependencies

### For Architects
- [C4 Context](./notebooks-c4-context.dsl) - System context in C4 format (Structurizr)
- [Component Overview](./notebooks-component.png) ([mmd](./notebooks-component.mmd)) - High-level component view showing image variants

### For Security Teams
- [Security Network Diagram (PNG)](./notebooks-security-network.png) - High-resolution network topology
- [Security Network Diagram (Mermaid)](./notebooks-security-network.mmd) - Visual network topology (editable)
- [Security Network Diagram (ASCII)](./notebooks-security-network.txt) - Precise text format for SAR submissions
- [RBAC Visualization](./notebooks-rbac.png) ([mmd](./notebooks-rbac.mmd)) - RBAC permissions (managed by Notebook Controller)

## Component Overview

The Notebook Images component provides pre-built container images for Jupyter notebooks and IDE environments optimized for data science and ML workloads in RHOAI. Key features:

- **Base Images**: UBI8/UBI9/C9S with Python 3.8/3.9
- **Jupyter Variants**: Minimal, Data Science, PyTorch, TensorFlow, TrustyAI
- **GPU Support**: CUDA 11.8 + cuDNN 8.9 for NVIDIA GPUs
- **Habana AI**: Specialized images for Habana AI accelerators (versions 1.9.0, 1.10.0, 1.11.0)
- **Runtime Images**: Python environments without Jupyter for pipeline execution
- **IDEs**: code-server (VS Code) and RStudio
- **Distribution**: Published to quay.io/modh/* and distributed via OpenShift ImageStreams

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
# From repository root
claude generate architecture diagrams from notebooks.md
```

## Key Security Details

### Network Flows
- **Ingress**: HTTPS/443 (TLS 1.2+) → OAuth Proxy → HTTP/8888 (mTLS optional)
- **Egress**: S3 (HTTPS/443), PyPI (HTTPS/443), Databases (various ports)
- **Internal**: Data Science Pipelines (HTTP/8888), Model Registry (HTTP/8080)

### Authentication
- **External Access**: OAuth Bearer Token (JWT) or Session Cookie
- **Jupyter API**: Token authentication (typically disabled in RHOAI)
- **S3 Access**: AWS Signature v4 from mounted secrets
- **Database Access**: Username/Password

### Container Security
- **User**: UID 1001, GID 0 (non-root)
- **SELinux**: container_t (OpenShift default)
- **Root Filesystem**: Read-write (required for pip installs)
- **SCC**: restricted-v2

### Secrets
- `{workbench}-notebook-token`: Jupyter authentication
- `aws-connection-{name}`: S3 credentials
- `generic-s3-secret`: Default S3 storage

## Image Variants

### Python 3.8 (UBI8)
- base-ubi8-python-3.8
  - jupyter-minimal-ubi8-python-3.8
    - jupyter-datascience-ubi8-python-3.8
      - jupyter-trustyai-ubi8-python-3.8
      - habana-jupyter-{1.9.0,1.10.0,1.11.0}-ubi8-python-3.8
  - cuda-ubi8-python-3.8
    - cuda-jupyter-minimal-ubi8-python-3.8
      - cuda-jupyter-datascience-ubi8-python-3.8
        - cuda-jupyter-pytorch-ubi8-python-3.8
        - cuda-jupyter-tensorflow-ubi8-python-3.8
  - runtime-minimal-ubi8-python-3.8
  - runtime-datascience-ubi8-python-3.8
  - runtime-pytorch-ubi8-python-3.8

### Python 3.9 (UBI9)
- base-ubi9-python-3.9
  - jupyter-minimal-ubi9-python-3.9
    - jupyter-datascience-ubi9-python-3.9
      - jupyter-pytorch-ubi9-python-3.9
      - jupyter-tensorflow-ubi9-python-3.9
      - jupyter-trustyai-ubi9-python-3.9
  - cuda-ubi9-python-3.9
    - cuda-jupyter-minimal-ubi9-python-3.9
      - cuda-jupyter-datascience-ubi9-python-3.9
        - cuda-jupyter-pytorch-ubi9-python-3.9
        - cuda-jupyter-tensorflow-ubi9-python-3.9
  - runtime-minimal-ubi9-python-3.9
  - runtime-datascience-ubi9-python-3.9
  - runtime-pytorch-ubi9-python-3.9
  - cuda-runtime-tensorflow-ubi9-python-3.9

### Python 3.9 (C9S - IDEs)
- c9s-python-3.9
  - code-server-c9s-python-3.9 (VS Code)
  - r-studio-c9s-python-3.9 (RStudio)

## Related Documentation

- **Architecture File**: [../notebooks.md](../notebooks.md)
- **Repository**: https://github.com/red-hat-data-services/notebooks
- **Upstream ODH**: https://github.com/opendatahub-io/notebooks
