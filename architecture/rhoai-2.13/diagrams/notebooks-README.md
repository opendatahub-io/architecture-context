# Architecture Diagrams for Workbench Images (Notebooks)

Generated from: `architecture/rhoai-2.13/notebooks.md`
Date: 2026-03-15

**Note**: Diagram filenames use base component name without version (directory is already versioned).

## Available Diagrams

All Mermaid diagrams are available in both `.mmd` (source) and `.png` (3000px width, high-resolution) formats.

### For Developers
- [Component Structure](./notebooks-component.png) ([mmd](./notebooks-component.mmd)) - Mermaid diagram showing internal components, image variants, and platform integration
- [Data Flows](./notebooks-dataflow.png) ([mmd](./notebooks-dataflow.mmd)) - Sequence diagram of request/response flows for workbench access and operations
- [Dependencies](./notebooks-dependencies.png) ([mmd](./notebooks-dependencies.mmd)) - Component dependency graph showing external and internal dependencies

### For Architects
- [C4 Context](./notebooks-c4-context.dsl) - System context in C4 format (Structurizr) showing notebooks in broader ODH/RHOAI ecosystem
- [Component Overview](./notebooks-component.png) ([mmd](./notebooks-component.mmd)) - High-level component view of image variants and layering

### For Security Teams
- [Security Network Diagram (PNG)](./notebooks-security-network.png) - High-resolution network topology
- [Security Network Diagram (Mermaid)](./notebooks-security-network.mmd) - Visual network topology (editable)
- [Security Network Diagram (ASCII)](./notebooks-security-network.txt) - Precise text format for SAR submissions
- [RBAC Visualization](./notebooks-rbac.png) ([mmd](./notebooks-rbac.mmd)) - RBAC permissions and bindings for workbench pods

## Diagram Details

### notebooks-component.mmd / .png
Shows the complete workbench images architecture including:
- Jupyter image variants (Minimal, DataScience, PyTorch, TensorFlow, TrustyAI, Habana)
- Alternative IDEs (CodeServer, RStudio)
- Runtime images for model serving
- Base layers (UBI9, CUDA, ROCm, Intel oneAPI)
- Platform integration with notebook-controller, oauth-proxy, ODH Dashboard
- External dependencies (PyPI, CRAN, S3, Git, Kubeflow Pipelines)

### notebooks-dataflow.mmd / .png
Sequence diagrams showing:
- **Flow 1**: User accessing Jupyter notebook through OpenShift Route and oauth-proxy
- **Flow 2**: Installing Python packages from PyPI
- **Flow 3**: Accessing S3 data via boto3
- **Flow 4**: Submitting ML pipelines via Elyra to Kubeflow Pipelines
- **Flow 5**: Health checks for CodeServer/RStudio via NGINX

### notebooks-security-network.txt / .mmd / .png
Detailed network topology showing:
- **External ingress**: User browser → OpenShift Router (HTTPS/443 TLS1.2+)
- **Authentication layer**: oauth-proxy sidecar with OAuth2 validation
- **Workbench pod**: Jupyter/CodeServer/RStudio container (HTTP/8888 localhost)
- **Egress destinations**:
  - PyPI (443/TCP HTTPS) - Package installation
  - CRAN (443/TCP HTTPS) - R package installation
  - S3 Storage (443/TCP HTTPS with AWS IAM)
  - Git Repositories (443/TCP HTTPS or 22/TCP SSH)
  - Kubeflow Pipelines API (8888/TCP HTTP)
  - Kubernetes API (6443/TCP HTTPS)
- **RBAC details**: ServiceAccount with namespace-scoped read permissions
- **Security context**: Non-root user (UID 1001), restricted SCC
- **Secrets**: User-provided credentials for Git, S3, and data connections

### notebooks-c4-context.dsl
C4 architecture model showing:
- **People**: Data Scientists and ML Engineers
- **System**: Workbench Images with Jupyter, CodeServer, and RStudio containers
- **Dependencies**: notebook-controller, oauth-proxy, ODH Dashboard, Kubeflow Pipelines, Model Mesh
- **External systems**: PyPI, CRAN, S3, Git, Kubernetes API, Image Registry
- **Container and component views** for detailed architecture exploration

### notebooks-dependencies.mmd / .png
Dependency graph showing:
- **External build dependencies**: UBI9, JupyterLab, code-server, RStudio Server, NGINX, supervisord
- **ML frameworks**: PyTorch, TensorFlow, pandas, scikit-learn
- **GPU/accelerator support**: CUDA, ROCm, Intel oneAPI
- **Cloud SDKs**: boto3, codeflare-sdk, Elyra
- **Internal ODH dependencies**: notebook-controller, oauth-proxy, ODH Dashboard, Kubeflow Pipelines, Model Mesh
- **External runtime services**: PyPI, CRAN, S3, Git repositories, Kubernetes API

### notebooks-rbac.mmd / .png
RBAC visualization showing:
- **ServiceAccount**: `notebook-{name}` (created per workbench instance)
- **RoleBinding**: Grants namespace-scoped `view` role
- **Permissions**: Read-only access to ConfigMaps, Secrets, Pods, Services, PVCs in workbench namespace
- **No cluster permissions**: No ClusterRole or cross-namespace access
- **API access**: Auto-mounted token for Kubernetes API and Kubeflow Pipelines API
- **Security context**: Non-root user (UID 1001), restricted OpenShift SCC

## Key Architecture Points

### Image Variants
The notebooks component provides three categories of container images:

1. **Jupyter Images** (7 variants):
   - **jupyter-minimal**: Base notebook environment
   - **jupyter-datascience**: Full data science stack (pandas, scikit-learn, boto3, Elyra)
   - **jupyter-pytorch**: PyTorch with GPU support (CUDA/ROCm)
   - **jupyter-tensorflow**: TensorFlow with GPU support (CUDA/ROCm)
   - **jupyter-trustyai**: AI fairness and explainability
   - **jupyter-habana**: Intel Habana Gaudi (deprecated in rhoai-2.13)
   - **jupyter-intel-ml**: Intel GPU/oneAPI optimization

2. **Alternative IDEs** (2 variants):
   - **codeserver**: VS Code in browser with NGINX proxy
   - **rstudio**: RStudio Server for R development with NGINX proxy

3. **Runtime Images** (6 variants):
   - Minimal serving containers for model deployment (no IDE)
   - CPU and GPU variants for PyTorch and TensorFlow

### Security Model
- **Authentication**: OAuth2 via oauth-proxy sidecar (no auth in container itself)
- **Network**: TLS terminated at OpenShift Router, plain HTTP on localhost within pod
- **RBAC**: Namespace-scoped read-only permissions, no cluster-level access
- **Isolation**: Non-root user (UID 1001), restricted OpenShift SCC
- **Secrets**: User-provided, mounted at runtime (Git, S3, data connections)

### Network Flow
1. User → OpenShift Route (HTTPS/443, TLS 1.2+, OAuth2 cookie)
2. Router → oauth-proxy sidecar (HTTPS/8443, OAuth2 validation)
3. oauth-proxy → Jupyter container (HTTP/8888 localhost, trusted)
4. Jupyter → External services (PyPI, S3, Git, KFP) via various protocols

### Known Limitations
- JupyterLab pinned to 3.6.x (extension compatibility blocks v4 upgrade)
- NGINX overhead (~50MB memory) for CodeServer/RStudio health checks
- No mTLS between oauth-proxy and workbench container (localhost trust)
- Python versions limited by UBI9 repos (3.9, 3.11)
- GPU drivers must be pre-installed on host nodes (not in images)
- Habana notebook support deprecated as of rhoai-2.13

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
# Assuming you're in the architecture/rhoai-2.13 directory
/generate-architecture-diagrams --architecture=notebooks.md

# Or from repository root
/generate-architecture-diagrams --architecture=architecture/rhoai-2.13/notebooks.md
```
