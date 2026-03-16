# Architecture Diagrams for TrustyAI Service Operator

Generated from: `architecture/rhoai-2.12/trustyai-service-operator.md`
Date: 2026-03-15

**Note**: Diagram filenames use base component name without version (directory is already versioned).

## Available Diagrams

All Mermaid diagrams are available in both `.mmd` (source) and `.png` (3000px width, high-resolution) formats.

### For Developers
- [Component Structure](./trustyai-service-operator-component.png) ([mmd](./trustyai-service-operator-component.mmd)) - Mermaid diagram showing internal components
- [Data Flows](./trustyai-service-operator-dataflow.png) ([mmd](./trustyai-service-operator-dataflow.mmd)) - Sequence diagram of request/response flows
- [Dependencies](./trustyai-service-operator-dependencies.png) ([mmd](./trustyai-service-operator-dependencies.mmd)) - Component dependency graph

### For Architects
- [C4 Context](./trustyai-service-operator-c4-context.dsl) - System context in C4 format (Structurizr)
- [Component Overview](./trustyai-service-operator-component.png) ([mmd](./trustyai-service-operator-component.mmd)) - High-level component view

### For Security Teams
- [Security Network Diagram (PNG)](./trustyai-service-operator-security-network.png) - High-resolution network topology
- [Security Network Diagram (Mermaid)](./trustyai-service-operator-security-network.mmd) - Visual network topology (editable)
- [Security Network Diagram (ASCII)](./trustyai-service-operator-security-network.txt) - Precise text format for SAR submissions
- [RBAC Visualization](./trustyai-service-operator-rbac.png) ([mmd](./trustyai-service-operator-rbac.mmd)) - RBAC permissions and bindings

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
/generate-architecture-diagrams --architecture=../trustyai-service-operator.md
```

## Component Overview

The TrustyAI Service Operator manages the deployment and lifecycle of TrustyAI explainability services for AI/ML model monitoring and bias detection. Key features:

- **Operator-based deployment**: Reconciles TrustyAIService custom resources
- **Integration with KServe/ModelMesh**: Injects payload processors for inference data collection
- **Dual storage backends**: PVC (CSV format) or external database (PostgreSQL/MariaDB/MySQL)
- **OAuth authentication**: Secured external access via OpenShift OAuth proxy
- **Prometheus metrics**: Exposes fairness metrics (SPD, DIR) for monitoring
- **Service mesh ready**: Supports mTLS for service-to-service communication

## Architecture Highlights

### Security
- Non-root container execution (UID 65532)
- OAuth proxy for external authentication
- mTLS support for service mesh integration
- Service Serving Certificates for internal TLS
- Comprehensive RBAC controls

### Data Flow
1. **Inference Collection**: KServe/ModelMesh → TrustyAI Service (HTTPS mTLS)
2. **Storage**: TrustyAI Service → PVC or Database
3. **Metrics**: Prometheus scrapes /q/metrics endpoint
4. **External Access**: User → Router → Route → OAuth Proxy → TrustyAI Service

### Dependencies
- **Required**: Kubernetes v1.19+, cert-manager or OpenShift Cert Service
- **Optional**: OpenShift v4.6+ (for Routes and OAuth), Prometheus Operator, External Database
- **Integrates with**: KServe, ModelMesh Serving, ODH/RHOAI Dashboard
