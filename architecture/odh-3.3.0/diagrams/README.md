# Architecture Diagrams for Open Data Hub 3.3.0 Platform

Generated from: `architecture/odh-3.3.0/PLATFORM.md`
Date: 2026-03-12

**Note**: Diagram filenames use base component name without version (directory is already versioned).

## Available Diagrams

All Mermaid diagrams are available in both `.mmd` (source) and `.png` (3000px width, high-resolution) formats.

### For Developers
- [Component Structure](./platform-component.png) ([mmd](./platform-component.mmd)) - Mermaid diagram showing platform components and relationships
- [Data Flows](./platform-dataflow.png) ([mmd](./platform-dataflow.mmd)) - Sequence diagram of model development to production workflows
- [Dependencies](./platform-dependencies.png) ([mmd](./platform-dependencies.mmd)) - Component dependency graph showing external and internal integrations

### For Architects
- [C4 Context](./platform-c4-context.dsl) - System context in C4 format (Structurizr)
- [Component Overview](./platform-component.png) ([mmd](./platform-component.mmd)) - High-level platform component view

### For Security Teams
- [Security Network Diagram (PNG)](./platform-security-network.png) - High-resolution network topology
- [Security Network Diagram (Mermaid)](./platform-security-network.mmd) - Visual network topology (editable)
- [Security Network Diagram (ASCII)](./platform-security-network.txt) - Precise text format for SAR submissions
- [RBAC Visualization](./platform-rbac.png) ([mmd](./platform-rbac.mmd)) - RBAC permissions and bindings

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
/generate-architecture-diagrams --architecture=architecture/odh-3.3.0/PLATFORM.md
```

## Platform Overview

Open Data Hub 3.3.0 is a comprehensive cloud-native AI/ML platform for OpenShift that provides end-to-end data science capabilities:

**17 Integrated Components**:
- **Platform Control**: ODH Operator, Dashboard
- **Model Serving**: KServe, ODH Model Controller
- **Development**: Notebook Controller, Notebook Images (Jupyter, VSCode, RStudio)
- **Model Management**: Model Registry, MLflow
- **Training**: Training Operator, Trainer v2, KubeRay, Spark
- **Workflows**: Data Science Pipelines, Feast
- **AI Governance**: TrustyAI, Llama Stack

**Key Workflows**:
1. **Model Development**: Dashboard → Notebooks → MLflow → Model Registry → KServe
2. **Automated Pipelines**: Data Science Pipelines → Training → Model Registry → KServe
3. **LLM Fine-tuning**: Trainer v2 → JobSet → Distributed Training → Model Registry → KServe

**Security Features**:
- OAuth/mTLS authentication
- Service mesh (Istio) integration
- RBAC with 60+ CRDs
- TLS 1.2+ encryption
- NetworkPolicy support
- FIPS compliance

**External Dependencies**:
- Required: Kubernetes 1.25+, Knative Serving, cert-manager
- Optional: Istio (service mesh)
- Services: S3 storage, PostgreSQL/MySQL, HuggingFace Hub, Container Registry
