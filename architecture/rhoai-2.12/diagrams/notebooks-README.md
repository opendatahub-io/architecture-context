# Architecture Diagrams for Notebooks (Workbench Images)

Generated from: `architecture/rhoai-2.12/notebooks.md`
Date: 2026-03-15

**Note**: Diagram filenames use base component name without version (directory `rhoai-2.12/` is already versioned).

## Available Diagrams

All Mermaid diagrams are available in both `.mmd` (source) and `.png` (3000px width, high-resolution) formats.

### For Developers
- [Component Structure](./notebooks-component.png) ([mmd](./notebooks-component.mmd)) - Mermaid diagram showing internal components, image hierarchy, and build system
- [Data Flows](./notebooks-dataflow.png) ([mmd](./notebooks-dataflow.mmd)) - Sequence diagram of image build, pod launch, package installation, and data science workflows
- [Dependencies](./notebooks-dependencies.png) ([mmd](./notebooks-dependencies.mmd)) - Component dependency graph showing external libraries and internal ODH dependencies

### For Architects
- [C4 Context](./notebooks-c4-context.dsl) - System context in C4 format (Structurizr) showing notebooks in broader RHOAI/ODH ecosystem
- [Component Overview](./notebooks-component.png) ([mmd](./notebooks-component.mmd)) - High-level component view with base images, Jupyter variants, IDE images, and runtime images

### For Security Teams
- [Security Network Diagram (PNG)](./notebooks-security-network.png) - High-resolution network topology with trust zones
- [Security Network Diagram (Mermaid)](./notebooks-security-network.mmd) - Visual network topology (editable)
- [Security Network Diagram (ASCII)](./notebooks-security-network.txt) - Precise text format for SAR submissions with detailed RBAC, secrets, and authentication flows
- [RBAC Visualization](./notebooks-rbac.png) ([mmd](./notebooks-rbac.mmd)) - RBAC permissions, role bindings, and authentication flow

## Component Summary

**Notebooks (Workbench Images)** builds and maintains Jupyter notebook and IDE workbench container images for data science and machine learning workflows in RHOAI/ODH.

**Key Features**:
- **Base Images**: UBI8/UBI9/RHEL9/CentOS Stream 9 with Python 3.8/3.9
- **Jupyter Images**: Minimal, Data Science, PyTorch, TensorFlow, TrustyAI variants
- **GPU Support**: NVIDIA CUDA, AMD ROCm, Intel, Habana Gaudi accelerators
- **Alternative IDEs**: RStudio Server, VS Code Server
- **Runtime Images**: Lightweight Elyra pipeline execution images
- **Build System**: Makefile-based multi-stage builds with Kustomize manifests
- **Versioning**: N/N-1/N-2/N-3 strategy via OpenShift ImageStreams

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

### Component Structure Diagram
Shows the layered architecture of notebook images:
- Base layer (UBI9/UBI8, CUDA, ROCm, Habana, Intel)
- Jupyter image variants (Minimal, Data Science, PyTorch, TensorFlow, TrustyAI, Minimal GPU)
- Alternative IDEs (RStudio Server, VS Code Server)
- Runtime images for Elyra pipelines
- Build system (Makefile, Kustomize manifests, CI/CD scripts)
- External dependencies (UBI, JupyterLab, PyTorch, TensorFlow, CUDA, Elyra, KFP)
- Internal ODH dependencies (Notebook Controller, Dashboard, ImageStreams, BuildConfig, Kubeflow Pipelines)
- Container registries (Quay.io, OpenShift Image Registry)

### Data Flow Diagram
Four main flows:
1. **Image Build and Deployment**: Developer → GitHub → GitHub Actions/Konflux → Red Hat Registry → Quay.io → ImageStream
2. **Notebook Pod Launch**: User → ODH Dashboard → Kubernetes API → Notebook Controller → Kubelet → Quay.io → OAuth Proxy → JupyterLab Pod
3. **Runtime Package Installation**: User → Notebook Pod → PyPI → Package installation
4. **Data Science Workflow**: Notebook Pod → S3 Storage → PostgreSQL → Kubernetes API → Kubeflow Pipelines

### Security Network Diagram
Detailed network topology showing:
- **External**: User/Data Scientist (untrusted zone)
- **Ingress (DMZ)**: OpenShift Route with OAuth Proxy (443/TCP HTTPS TLS1.2+, edge termination)
- **Application Pod**: JupyterLab container (8888/TCP HTTP, UID 1001 non-root)
- **Egress Paths**:
  - Package Management: PyPI (443/TCP HTTPS, no auth)
  - Data Access: S3 (443/TCP HTTPS, AWS IAM), PostgreSQL (5432/TCP, TLS optional), MySQL (3306/TCP), MongoDB (27017/TCP)
  - Kubernetes API: K8s API (6443/TCP HTTPS, ServiceAccount token)
  - ML Pipelines: Kubeflow Pipelines (8888/TCP HTTPS, Bearer token)
  - Source Control: Git (443/TCP HTTPS/SSH)
  - Container Registries: Quay.io (443/TCP HTTPS)
- RBAC permissions for notebook pods
- Secrets: notebook tokens, AWS credentials, database credentials, git credentials
- Authentication flow: OAuth → OAuth Proxy → Jupyter Token

### Dependencies Diagram
Shows:
- **External Dependencies**: UBI9/UBI8/RHEL9 base images, JupyterLab, PyTorch, TensorFlow, CUDA, ROCm, Habana SynapseAI, RStudio, Code Server, Elyra, Boto3, KFP, data science libraries (Pandas, NumPy, Scikit-learn, Matplotlib), CodeFlare SDK, OpenShift CLI, Podman/Docker
- **Internal ODH Dependencies**: Notebook Controller (launches pods), Dashboard (displays images), ImageStreams (versioned references), BuildConfig (on-cluster builds), Kubeflow Pipelines (runtime integration), Model Mesh/KServe (model deployment)
- **Runtime Services**: PyPI, Quay.io, S3, databases (PostgreSQL, MySQL, MongoDB), Kubernetes API, Git, container registries, NVIDIA GPU Operator, Node Feature Discovery

### RBAC Visualization
Shows:
- Service accounts (notebook pod SA, notebook controller SA)
- Role bindings (notebook-controller-rolebinding)
- Cluster roles (notebook-controller-role)
- Permissions on Kubernetes resources:
  - Core: pods, services, PVCs (get, list, watch, create, delete)
  - Apps: deployments, statefulsets (get, list, watch)
  - OpenShift: routes (get, list, watch, create, delete)
  - Kubeflow: notebooks CR (get, list, watch, create, update, patch, delete)
- Authentication flow: User → OAuth Proxy → OpenShift OAuth → Jupyter Token → Pods

## Updating Diagrams

To regenerate after architecture changes:
```bash
# From repository root
# Regenerate for notebooks component specifically
# (assuming architecture file is at architecture/rhoai-2.12/notebooks.md)
```

## Architecture Context

This component is part of the **RHOAI 2.12** (Red Hat OpenShift AI) platform. Related components in the ecosystem:
- **ODH Notebook Controller**: Launches notebook pods using these images
- **ODH Dashboard**: Displays available images to users
- **Kubeflow Pipelines**: Executes Elyra pipelines using runtime images
- **Model Mesh / KServe**: Deploys models developed in notebooks
- **OpenShift OAuth**: Provides authentication for notebook access
- **NVIDIA GPU Operator**: Enables GPU acceleration for CUDA images

## References

- **Architecture Source**: [notebooks.md](../notebooks.md)
- **Repository**: https://github.com/red-hat-data-services/notebooks
- **Upstream**: https://github.com/opendatahub-io/notebooks
- **Published Images**: https://quay.io/opendatahub/workbench-images, https://quay.io/modh
- **RHOAI Documentation**: https://access.redhat.com/documentation/en-us/red_hat_openshift_ai
