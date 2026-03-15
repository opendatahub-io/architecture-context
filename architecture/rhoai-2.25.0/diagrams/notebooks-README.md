# Architecture Diagrams for Notebooks

Generated from: `architecture/rhoai-2.25.0/notebooks.md`
Date: 2026-03-14

**Note**: Diagram filenames use base component name without version (directory is already versioned).

## Available Diagrams

All Mermaid diagrams are available in both `.mmd` (source) and `.png` (3000px width, high-resolution) formats.

### For Developers
- [Component Structure](./notebooks-component.png) ([mmd](./notebooks-component.mmd)) - Mermaid diagram showing internal components, workbench images, runtime images, and build system
- [Data Flows](./notebooks-dataflow.png) ([mmd](./notebooks-dataflow.mmd)) - Sequence diagram of request/response flows including user access, pipeline execution, and image build/deployment
- [Dependencies](./notebooks-dependencies.png) ([mmd](./notebooks-dependencies.mmd)) - Component dependency graph showing external dependencies, internal ODH integration, and build infrastructure

### For Architects
- [C4 Context](./notebooks-c4-context.dsl) - System context in C4 format (Structurizr) showing notebooks in the broader RHOAI ecosystem
- [Component Overview](./notebooks-component.png) ([mmd](./notebooks-component.mmd)) - High-level component view of workbench and runtime images

### For Security Teams
- [Security Network Diagram (PNG)](./notebooks-security-network.png) - High-resolution network topology with trust boundaries
- [Security Network Diagram (Mermaid)](./notebooks-security-network.mmd) - Visual network topology (editable)
- [Security Network Diagram (ASCII)](./notebooks-security-network.txt) - Precise text format for SAR submissions with detailed port/protocol/auth information
- [RBAC Visualization](./notebooks-rbac.png) ([mmd](./notebooks-rbac.mmd)) - RBAC permissions and authentication flow (Note: This component does not define RBAC - managed by ODH Notebook Controller)

## How to Use

### PNG Files (.png files)
**Automatically generated** at 3000px width for high-resolution presentations and documentation.

- **Ready to use**: High-resolution images suitable for presentations, wikis, and documentation
- **Width**: 3000px (height auto-adjusts to content)
- **Use directly**: Include in PowerPoint, Google Slides, Confluence, etc.

### Mermaid Source Files (.mmd files)
- **In GitHub/GitLab**: Paste into markdown with \`\`\`mermaid code blocks - renders automatically!
- **Live editor**: https://mermaid.live (paste code, edit, export)
- **Editable**: Modify and regenerate if needed

**Manual PNG regeneration** (if you edit .mmd files):

1. **Ensure Mermaid CLI is installed**:
   \`\`\`bash
   npm install -g @mermaid-js/mermaid-cli
   \`\`\`

2. **Regenerate PNG** (3000px width):
   \`\`\`bash
   PUPPETEER_EXECUTABLE_PATH=/usr/bin/google-chrome mmdc -i diagram.mmd -o diagram.png -w 3000
   \`\`\`

3. **Alternative formats** (if needed):
   \`\`\`bash
   # SVG (vector, scales perfectly)
   PUPPETEER_EXECUTABLE_PATH=/usr/bin/google-chrome mmdc -i diagram.mmd -o diagram.svg

   # PDF
   PUPPETEER_EXECUTABLE_PATH=/usr/bin/google-chrome mmdc -i diagram.mmd -o diagram.pdf
   \`\`\`

**Note**: If \`google-chrome\` is not found, try \`chromium\` or \`which google-chrome\` to locate it

### C4 Diagrams (.dsl files)
- **Structurizr Lite**: \`docker run -p 8080:8080 -v .:/usr/local/structurizr structurizr/lite\`
- **CLI export**: \`structurizr-cli export -workspace diagram.dsl -format png\`

### ASCII Diagrams (.txt files)
- View in any text editor
- Include in documentation as-is
- Perfect for security reviews (precise technical details)

## Diagram Details

### Component Structure
Shows the complete notebooks architecture including:
- **Workbench Images**: Jupyter (CPU/CUDA/ROCm variants), Code Server, RStudio
- **Runtime Images**: Lightweight containers for Kubeflow Pipelines
- **Base Images**: UBI9, CUDA, and ROCm foundations
- **Build System**: Tekton pipelines, Kustomize manifests, build scripts
- **Integration**: ODH Notebook Controller, Dashboard, Kubeflow Pipelines, ImageStreams

### Data Flows
Three major flows:
1. **User Access Flow**: Browser → OpenShift Router → OAuth Proxy → Jupyter → Object Storage
2. **Pipeline Execution Flow**: Kubeflow Controller → Runtime Container → S3/API
3. **Image Build Flow**: Konflux → GitHub/Registries → Quay.io → ImageStream → Kubelet

### Security Network Diagram
Detailed network topology with:
- **External zone**: User browser access
- **Ingress DMZ**: OpenShift Router with TLS termination
- **Pod Network**: OAuth Proxy and workbench containers (same pod)
- **External Services**: S3, Quay.io, Red Hat Registry, GitHub, PyPI
- **Control Plane**: Kubeflow Pipelines controller and runtime containers
- **Build-time**: Konflux multi-arch build system

Includes precise technical details:
- Port numbers (8888/TCP for Jupyter, 8787/TCP for RStudio, 8080/TCP for Code Server)
- Protocols (HTTP, HTTPS)
- Encryption (TLS 1.2+, internal CA certs, no encryption for localhost)
- Authentication (OpenShift OAuth, S3 credentials, AWS SigV4, pull secrets)
- Service accounts and namespaces

### Dependencies
Shows:
- **External Dependencies**: UBI9, CUDA/ROCm base images, JupyterLab, PyTorch, TensorFlow, TrustyAI, LLMCompressor
- **Internal ODH Dependencies**: Notebook Controller, Dashboard, Kubeflow Pipelines, Model Mesh
- **Build Infrastructure**: Konflux, GitHub, Quay.io, Red Hat Registry, PyPI
- **Platform Integration**: ImageStreams, OpenShift Router, OAuth Proxy

### RBAC Visualization
Important note: This component does NOT define RBAC resources. Shows:
- ServiceAccounts created by ODH Notebook Controller
- OAuth Proxy authentication enforcement
- OpenShift namespace RBAC for authorization
- Pull secrets for container registries
- User-provided secrets for data access

## Updating Diagrams

To regenerate after architecture changes:
\`\`\`bash
# Update the architecture file first
# Then regenerate diagrams (would need the full skill/script)

# Manual regeneration of PNGs from .mmd files
cd architecture/rhoai-2.25.0/diagrams
for file in notebooks-*.mmd; do
  PUPPETEER_EXECUTABLE_PATH=/usr/bin/google-chrome mmdc -i "$file" -o "${file%.mmd}.png" -w 3000
done
\`\`\`

## Component Variants

This repository provides multiple image variants:

### Workbench Images
- **Jupyter**: minimal-cpu, minimal-cuda, minimal-rocm, datascience-cpu, pytorch-cuda, pytorch-rocm, pytorch-llmcompressor-cuda, tensorflow-cuda, tensorflow-rocm, trustyai-cpu
- **Code Server**: datascience-cpu
- **RStudio**: minimal-cpu, minimal-cuda

### Runtime Images (Kubeflow Pipelines)
- minimal-cpu, datascience-cpu, pytorch-cuda, pytorch-rocm, pytorch-llmcompressor-cuda, tensorflow-cuda, tensorflow-rocm

All images support:
- **Python**: 3.12 (primary), 3.11 (RStudio)
- **Base OS**: UBI9 (Universal Base Image 9)
- **Platforms**: linux/x86_64, linux/arm64, linux/ppc64le, linux/s390x
- **GPU Support**: NVIDIA CUDA (12.6, 12.8), AMD ROCm (6.2, 6.4)

## References

- **Architecture File**: [../notebooks.md](../notebooks.md)
- **GitHub Repository**: https://github.com/red-hat-data-services/notebooks
- **Container Registry**: https://quay.io/repository/opendatahub/workbench-images
- **Upstream (ODH)**: https://github.com/opendatahub-io/notebooks
- **Wiki**: https://github.com/opendatahub-io/notebooks/wiki/Workbenches
