# Architecture Diagrams for Data Science Pipelines Operator

Generated from: `architecture/rhoai-2.9/data-science-pipelines-operator.md`
Date: 2026-03-15

**Note**: Diagram filenames use base component name without version (directory is already versioned).

## Available Diagrams

All Mermaid diagrams are available in both `.mmd` (source) and `.png` (3000px width, high-resolution) formats.

### For Developers
- [Component Structure](./data-science-pipelines-operator-component.png) ([mmd](./data-science-pipelines-operator-component.mmd)) - Mermaid diagram showing internal components, operator architecture, and DSPA instance deployments
- [Data Flows](./data-science-pipelines-operator-dataflow.png) ([mmd](./data-science-pipelines-operator-dataflow.mmd)) - Sequence diagram of pipeline submission, execution, artifact storage, and metadata tracking flows
- [Dependencies](./data-science-pipelines-operator-dependencies.png) ([mmd](./data-science-pipelines-operator-dependencies.mmd)) - Component dependency graph showing external (Argo, Tekton) and internal ODH dependencies

### For Architects
- [C4 Context](./data-science-pipelines-operator-c4-context.dsl) - System context in C4 format (Structurizr) showing DSPO in the broader ODH ecosystem
- [Component Overview](./data-science-pipelines-operator-component.png) ([mmd](./data-science-pipelines-operator-component.mmd)) - High-level component view with operator and DSPA instance components

### For Security Teams
- [Security Network Diagram (PNG)](./data-science-pipelines-operator-security-network.png) - High-resolution network topology with trust boundaries
- [Security Network Diagram (Mermaid)](./data-science-pipelines-operator-security-network.mmd) - Visual network topology (editable)
- [Security Network Diagram (ASCII)](./data-science-pipelines-operator-security-network.txt) - Precise text format for SAR submissions with detailed ports, protocols, TLS, authentication, RBAC, secrets, and trust boundaries
- [RBAC Visualization](./data-science-pipelines-operator-rbac.png) ([mmd](./data-science-pipelines-operator-rbac.mmd)) - RBAC permissions and bindings for operator and DSPA instances

## Component Overview

**Data Science Pipelines Operator (DSPO)** is a Kubernetes operator that deploys and manages namespace-scoped Data Science Pipelines instances for ML workflow orchestration. Based on upstream Kubeflow Pipelines (KFP), it supports both Tekton (v1) and Argo Workflows (v2) backends.

**Key Components**:
- **Operator**: DSPO Controller Manager (cluster-scoped)
- **DSPA Instance** (per namespace):
  - API Server (REST/gRPC)
  - Persistence Agent
  - Scheduled Workflow Controller
  - Workflow Controller (Argo v2 only)
  - ML Metadata (MLMD) gRPC + Envoy Proxy (optional)
  - MariaDB (built-in or external)
  - Minio (built-in or external S3)
  - ML Pipelines UI (optional, dev/test only)

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
cd architecture/rhoai-2.9
# Regenerate diagrams
python ../../scripts/generate_diagram_pngs.py diagrams/ --width=3000
```

## Architecture Details

### Network Architecture
- **External Access**: OpenShift Routes with OAuth proxy (HTTPS/443 TLS 1.2+)
- **Internal Communication**: HTTP/gRPC within namespace, service mesh optional
- **Database**: MariaDB 3306/TCP (built-in or external with optional TLS)
- **Object Storage**: Minio 9000/HTTP (built-in) or S3 443/HTTPS (production)
- **Authentication**: OpenShift OAuth for external, Service Account tokens for internal

### Security Highlights
- **TLS Certificates**: Auto-provisioned via service-serving-cert annotation
- **Network Policies**: Restrict pod-to-pod communication to authorized components
- **RBAC**: Operator-level (manager-role) and instance-level (ds-pipeline-{name}, pipeline-runner-{name})
- **Secrets**: Separate secrets for TLS certificates, DB credentials, and object storage credentials
- **Trust Boundaries**: External → Ingress (OAuth) → Application Tier (internal) → Storage

### Multi-Version Support
- **DSP v1**: Tekton-based pipeline execution
- **DSP v2**: Argo Workflows-based execution
- Configured via `spec.dspVersion` in DataSciencePipelinesApplication CR

### Production vs Development
- **Development**: Built-in MariaDB and Minio (single-node, no HA)
- **Production**: External database (MariaDB/MySQL) and S3-compatible storage (AWS S3, etc.)

## Related Documentation
- [Architecture Document](../data-science-pipelines-operator.md)
- [Upstream Kubeflow Pipelines](https://www.kubeflow.org/docs/components/pipelines/)
- [Argo Workflows](https://argoproj.github.io/argo-workflows/)
- [Tekton Pipelines](https://tekton.dev/)
