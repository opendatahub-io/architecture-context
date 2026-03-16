# Architecture Diagrams for Notebooks

Generated from: `architecture/rhoai-2.11/notebooks.md`
Date: 2026-03-15

**Note**: Diagram filenames use base component name without version (directory is already versioned).

## Available Diagrams

All Mermaid diagrams are available in both `.mmd` (source) and `.png` (3000px width, high-resolution) formats.

### For Developers
- [Component Structure](./notebooks-component.png) ([mmd](./notebooks-component.mmd)) - Mermaid diagram showing internal components and build hierarchy
- [Data Flows](./notebooks-dataflow.png) ([mmd](./notebooks-dataflow.mmd)) - Sequence diagram of request/response flows
- [Dependencies](./notebooks-dependencies.png) ([mmd](./notebooks-dependencies.mmd)) - Component dependency graph

### For Architects
- [C4 Context](./notebooks-c4-context.dsl) - System context in C4 format (Structurizr)
- [Component Overview](./notebooks-component.png) ([mmd](./notebooks-component.mmd)) - High-level component view

### For Security Teams
- [Security Network Diagram (PNG)](./notebooks-security-network.png) - High-resolution network topology
- [Security Network Diagram (Mermaid)](./notebooks-security-network.mmd) - Visual network topology (editable)
- [Security Network Diagram (ASCII)](./notebooks-security-network.txt) - Precise text format for SAR submissions
- [RBAC Visualization](./notebooks-rbac.png) ([mmd](./notebooks-rbac.mmd)) - RBAC permissions and bindings

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
# From repository root
python scripts/generate_diagram_pngs.py architecture/rhoai-2.11/diagrams --width=3000
```

## Architecture Overview

### Component: Notebooks (Workbench Images)

**Purpose**: Provides container images for data science workbench environments including Jupyter notebooks, RStudio, and VS Code Server with pre-configured ML frameworks and libraries.

**Key Features**:
- Multiple workbench types: JupyterLab, RStudio, Code Server
- GPU acceleration support: NVIDIA CUDA, Intel Gaudi/Habana, AMD ROCm, Intel XPU
- Pre-configured ML frameworks: TensorFlow, PyTorch, TrustyAI
- Hierarchical image builds starting from UBI base images
- OAuth proxy authentication for secure access
- Persistent storage via PVCs

### Workbench Image Types

| Workbench | Python | R | JupyterLab | Code Server | RStudio | GPU Support | Runtime Available |
|-----------|--------|---|------------|-------------|---------|-------------|-------------------|
| Minimal | ✓ | ✗ | ✓ | ✗ | ✗ | ✗ | ✓ |
| Data Science | ✓ | ✗ | ✓ | ✗ | ✗ | ✗ | ✓ |
| TensorFlow | ✓ | ✗ | ✓ | ✗ | ✗ | CUDA | ✓ |
| PyTorch | ✓ | ✗ | ✓ | ✗ | ✗ | CUDA | ✓ |
| TrustyAI | ✓ | ✗ | ✓ | ✗ | ✗ | ✗ | ✗ |
| Habana | ✓ | ✗ | ✓ | ✗ | ✗ | Gaudi | ✗ |
| Intel ML | ✓ | ✗ | ✓ | ✗ | ✗ | XPU | ✗ |
| AMD PyTorch | ✓ | ✗ | ✓ | ✗ | ✗ | ROCm | ✗ |
| AMD TensorFlow | ✓ | ✗ | ✓ | ✗ | ✗ | ROCm | ✗ |
| Code Server | ✓ | ✗ | ✗ | ✓ | ✗ | ✗ | ✗ |
| RStudio | ✓ | ✓ | ✗ | ✗ | ✓ | Optional CUDA | ✗ |

### Image Build Hierarchy

```
base-ubi9-python-3.9
├── jupyter-minimal-ubi9-python-3.9
│   ├── jupyter-datascience-ubi9-python-3.9
│   │   ├── jupyter-tensorflow-ubi9-python-3.9
│   │   └── jupyter-pytorch-ubi9-python-3.9
│   └── jupyter-trustyai-ubi9-python-3.9
└── cuda-ubi9-python-3.9
    └── cuda-jupyter-minimal-ubi9-python-3.9
        └── cuda-jupyter-datascience-ubi9-python-3.9
```

### Key Dependencies

**External Dependencies**:
- UBI9/UBI8 Python base images (Red Hat)
- JupyterLab 3.6.x, Jupyter Notebook 6.5.x
- ML frameworks: TensorFlow 2.x, PyTorch 2.x
- GPU libraries: NVIDIA CUDA, Intel Habana, AMD ROCm, Intel oneAPI
- Data science libraries: Pandas, NumPy, Scikit-learn, Matplotlib

**Internal ODH Dependencies**:
- ODH Notebook Controller (manages workbench lifecycle)
- ODH Dashboard (displays available workbenches)
- OAuth Proxy (authentication sidecar)
- OpenShift ImageStreams (image metadata)
- OpenShift Routes (external access)
- PersistentVolumeClaims (persistent storage)

### Network Architecture

**Ingress**:
- User → OpenShift Route (HTTPS/443, TLS 1.2+)
- Route → OAuth Proxy (HTTPS/8443, OAuth2 Bearer Token)
- OAuth Proxy → Notebook Container (HTTP/8888, authenticated)

**Egress**:
- Notebook → PyPI (HTTPS/443, pip install)
- Notebook → GitHub (HTTPS/443, git operations)
- Notebook → S3/Object Storage (HTTPS/443, data access)
- Notebook → Conda Repositories (HTTPS/443, package install)

### Security

**Authentication**:
- OAuth2 Bearer Token validation via OAuth Proxy sidecar
- Policy: User must own notebook or have admin role
- OpenShift session cookie for web UI access

**Authorization**:
- Namespace-scoped service accounts per workbench
- RBAC managed by ODH Notebook Controller
- Minimal permissions for notebook pods

**Secrets**:
- `{notebook-name}-oauth-config`: OAuth proxy configuration
- `{user-git-credentials}`: User Git SSH keys or PAT
- `{data-connection}`: S3/object storage credentials
- `rhel-subscription-secret`: RHEL subscription (build-time only)

**Data Protection**:
- TLS 1.2+ for all external communications
- mTLS for Kubernetes API interactions
- PVC encryption depends on storage class configuration
- OAuth proxy enforces access control before reaching notebook

## Diagram Details

### Component Diagram
Shows the hierarchical structure of workbench images:
- Base images (UBI9/UBI8 Python)
- Jupyter workbenches (Minimal, Data Science, TensorFlow, PyTorch, TrustyAI)
- GPU-accelerated workbenches (CUDA, Habana, Intel, AMD)
- Other IDE workbenches (Code Server, RStudio)
- Runtime images (lightweight for pipelines)
- Kubernetes resources (ImageStreams, BuildConfigs)
- Integration with external components (Notebook Controller, Dashboard, OAuth Proxy, Quay.io)

### Data Flow Diagram
Illustrates four key flows:
1. **User Access**: Browser → Router → OAuth Proxy → Notebook Container → JupyterLab
2. **S3 Data Pull**: User code → boto3 → S3 (with AWS credentials from secret)
3. **Package Installation**: User command → pip → PyPI → install to /opt/app-root/src
4. **API Request**: Browser → Router → OAuth Proxy → Notebook → JupyterLab API (kernel management)

### Security Network Diagram
Comprehensive network topology showing:
- Trust boundaries (External, Ingress DMZ, Notebook Pod, Kubernetes Internal, External Services)
- Exact ports and protocols (443/TCP HTTPS, 8443/TCP HTTPS, 8888/TCP HTTP, 6443/TCP HTTPS mTLS)
- Authentication mechanisms (OAuth2 Bearer Token, TLS 1.2+, AWS IAM, SSH keys)
- Service accounts and RBAC policies
- Secret types and lifecycle
- Persistent storage configuration
- Workbench lifecycle flow (create → launch → access → data → stop)

Available in three formats:
- **ASCII (.txt)**: Precise text format for SAR documentation
- **Mermaid (.mmd)**: Visual diagram with color-coded trust zones
- **PNG (.png)**: High-resolution render for presentations

### C4 Context Diagram
Shows the Notebooks component in the broader ODH/RHOAI ecosystem:
- Users: Data Scientists, ML Engineers, Platform Administrators
- Internal systems: Notebook Controller, Dashboard, OAuth Proxy, Kubernetes API
- External dependencies: Quay.io, PyPI, Conda, GitHub, S3, Red Hat registries
- Build-time vs runtime relationships
- Image hierarchy and dependencies

### Dependencies Diagram
Visual dependency graph showing:
- **Required external dependencies**: UBI base images, JupyterLab, Python libraries
- **Optional framework dependencies**: TensorFlow, PyTorch, GPU libraries (dashed lines)
- **Internal ODH dependencies**: Notebook Controller, Dashboard, OAuth Proxy, ImageStreams
- **Integration points**: How components interact
- **External services**: Quay.io (image storage), PyPI/Conda (packages), GitHub, S3
- **Build infrastructure**: OpenShift BuildConfig for RStudio

### RBAC Diagram
Shows runtime RBAC structure (managed by Notebook Controller):
- **Note**: Notebook images don't define RBAC; diagram shows controller-created resources
- Service accounts: odh-notebook-controller-manager, odh-dashboard, {notebook-name}-sa
- Cluster-level permissions: ClusterRole and ClusterRoleBinding for controller
- Namespace-level permissions: Role and RoleBinding per notebook instance
- OAuth Proxy authorization policy
- Permissions on Kubernetes API resources (Notebook CR, StatefulSets, Services, Routes, etc.)

## Related Documentation

- [Architecture Documentation](../notebooks.md) - Full component architecture
- [RHOAI Documentation](https://access.redhat.com/documentation/en-us/red_hat_openshift_ai/) - Official product docs
- [Notebooks Repository](https://github.com/red-hat-data-services/notebooks) - Source code
