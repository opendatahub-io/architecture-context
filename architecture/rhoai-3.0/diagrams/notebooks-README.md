# Architecture Diagrams for Notebooks (Workbench Images)

Generated from: `architecture/rhoai-3.0/notebooks.md`
Date: 2026-03-15
Component: notebooks

**Note**: Diagram filenames use base component name without version (directory is already versioned).

## Available Diagrams

All Mermaid diagrams are available in both `.mmd` (source) and `.png` (3000px width, high-resolution) formats.

### For Developers
- [Component Structure](./notebooks-component.png) ([mmd](./notebooks-component.mmd)) - Mermaid diagram showing workbench images, supporting services, and ODH integration
- [Data Flows](./notebooks-dataflow.png) ([mmd](./notebooks-dataflow.mmd)) - Sequence diagram of user access, package installation, git operations, and model registration flows
- [Dependencies](./notebooks-dependencies.png) ([mmd](./notebooks-dependencies.mmd)) - Component dependency graph showing runtimes, frameworks, GPU support, and external services

### For Architects
- [C4 Context](./notebooks-c4-context.dsl) - System context in C4 format (Structurizr) showing workbench types, ODH platform integration, and external dependencies
- [Component Overview](./notebooks-component.png) ([mmd](./notebooks-component.mmd)) - High-level component view of all workbench variants

### For Security Teams
- [Security Network Diagram (PNG)](./notebooks-security-network.png) - High-resolution network topology showing trust boundaries, ports, protocols, and authentication
- [Security Network Diagram (Mermaid)](./notebooks-security-network.mmd) - Visual network topology (editable)
- [Security Network Diagram (ASCII)](./notebooks-security-network.txt) - Precise text format for SAR submissions with RBAC, secrets, and security context details
- [RBAC Visualization](./notebooks-rbac.png) ([mmd](./notebooks-rbac.mmd)) - OAuth proxy authentication, service account permissions, and user-provided secrets

## Component Overview

**Notebooks (Workbench Images)** provides containerized workbench environments for data science workflows in RHOAI:

### Workbench Types
- **Jupyter Variants**: Minimal, DataScience, PyTorch, TensorFlow, TrustyAI, LLMCompressor
- **RStudio Server**: R-based statistical computing and IDE
- **CodeServer**: Browser-based VS Code IDE
- **Runtime Images**: Headless versions for Kubeflow pipeline execution

### Key Features
- Multi-architecture support (x86_64, aarch64, ppc64le, s390x)
- GPU acceleration via NVIDIA CUDA 12.8 and AMD ROCm 6.3/6.4
- OAuth proxy authentication via OpenShift
- Integration with ODH Dashboard, Kubeflow Pipelines, and Model Registry
- External connectivity to PyPI, CRAN, GitHub, and S3 storage

### Network Architecture
- **Ingress**: OpenShift Router (443/TCP HTTPS) → OAuth Proxy (8443/TCP) → Workbench (8888/TCP HTTP)
- **Egress**: PyPI (443/TCP), CRAN (443/TCP), GitHub (443/22 TCP), S3 (443/TCP), Kubernetes API (6443/TCP)
- **Authentication**: OpenShift OAuth Proxy, Service Account tokens, AWS IAM, Git credentials

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

## Diagram Details

### notebooks-component.mmd
Shows the internal structure of the Notebooks component including:
- All Jupyter workbench variants (Minimal, DataScience, PyTorch, TensorFlow, TrustyAI, LLMCompressor)
- Alternative IDEs (RStudio Server, CodeServer)
- Supporting services (NGINX Proxy, Apache httpd)
- Runtime images for pipeline execution
- Base images (CPU, CUDA, ROCm)
- Integration with ODH Notebook Controller, Dashboard, and OAuth Proxy
- External dependencies (PyPI, CRAN, GitHub, S3, Quay.io)
- Integration with Kubeflow Pipelines and Model Registry

### notebooks-dataflow.mmd
Sequence diagram showing six key data flows:
1. User access to Jupyter workbench via OpenShift Router and OAuth Proxy
2. Workbench to S3 storage for data and model artifacts
3. Package installation from PyPI
4. Git operations (clone/push) to GitHub
5. Model registration to Model Registry
6. Kubernetes API access via oc CLI

### notebooks-security-network.txt / .mmd
Comprehensive security network diagram showing:
- **Trust Boundaries**: External (untrusted), Ingress (DMZ), Pod Network (trusted), Cluster Services, External Services
- **Ingress Flow**: User Browser → OpenShift Router (443/TCP TLS 1.2+) → OAuth Proxy (8443/TCP) → Workbench (8888/TCP HTTP)
- **Egress Connections**: PyPI (443/TCP HTTPS), CRAN (443/TCP HTTPS), GitHub (443/22 TCP HTTPS/SSH), S3 (443/TCP HTTPS), Quay.io (443/TCP HTTPS), Kubernetes API (6443/TCP HTTPS TLS 1.3), Model Registry (8080/TCP HTTP mTLS)
- **Authentication**: OpenShift OAuth, Service Account tokens, AWS IAM credentials, Git credentials
- **RBAC**: Service account permissions, namespace access control
- **Secrets**: OAuth config, OAuth cookie secret, git credentials, AWS credentials, database credentials
- **Security Context**: runAsNonRoot, capabilities drop, GPU device access

### notebooks-dependencies.mmd
Dependency graph showing:
- **Core Runtimes**: Python 3.12, R 4.5.1, Node.js 22.18.0
- **IDEs/Frameworks**: JupyterLab 4.4, RStudio Server, CodeServer, PyTorch 2.x, TensorFlow 2.16+
- **GPU Acceleration**: NVIDIA CUDA 12.8, AMD ROCm 6.3/6.4
- **Infrastructure**: NGINX, Apache httpd, OpenShift CLI
- **Libraries**: Pandas, NumPy, Scikit-learn, TrustyAI, LLMCompressor, Elyra
- **Internal ODH**: Notebook Controller, Dashboard, Kubeflow Pipelines, Data Science Pipelines, Model Registry
- **External Services**: PyPI, CRAN, GitHub, S3, Quay.io

### notebooks-rbac.mmd
RBAC visualization showing:
- User authentication via OpenShift OAuth
- OAuth Proxy sidecar configuration and secrets
- Workbench pod service account and token
- User-provided secrets (git, AWS, database credentials)
- Access control enforcement (namespace access, Kubernetes RBAC, S3 IAM, Git auth)
- API access patterns (Kubernetes API, S3, Git, Model Registry)
- Management by ODH Notebook Controller

### notebooks-c4-context.dsl
C4 system context diagram showing:
- **Users**: Data Scientist (develops models), ML Engineer (creates pipelines)
- **Notebooks Component**: All workbench containers and supporting services
- **ODH Platform**: Notebook Controller, Dashboard, Kubeflow Pipelines, Data Science Pipelines, Model Registry
- **OpenShift Platform**: Kubernetes API, OAuth Proxy, routing infrastructure
- **External Services**: PyPI, CRAN, GitHub, S3 Storage, Quay.io
- **Relationships**: User interactions, lifecycle management, authentication flows, external dependencies

## Updating Diagrams

To regenerate after architecture changes:
```bash
# From repository root
python scripts/generate_diagram_pngs.py architecture/rhoai-3.0/diagrams --width=3000

# Or regenerate the source .mmd files and PNGs together:
# (Requires implementing diagram generation skill/tool)
```

## Architecture Source

These diagrams were generated from the structured markdown architecture documentation at:
`architecture/rhoai-3.0/notebooks.md`

For the most up-to-date architecture information, refer to the source markdown file.
