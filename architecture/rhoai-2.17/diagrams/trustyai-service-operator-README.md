# Architecture Diagrams for TrustyAI Service Operator

Generated from: `architecture/rhoai-2.17/trustyai-service-operator.md`
Date: 2026-03-16
Component: trustyai-service-operator

**Note**: Diagram filenames use base component name without version (directory is already versioned).

## Available Diagrams

All Mermaid diagrams are available in both `.mmd` (source) and `.png` (3000px width, high-resolution) formats.

### For Developers
- [Component Structure](./trustyai-service-operator-component.png) ([mmd](./trustyai-service-operator-component.mmd)) - Mermaid diagram showing internal components, CRDs, and managed resources
- [Data Flows](./trustyai-service-operator-dataflow.png) ([mmd](./trustyai-service-operator-dataflow.mmd)) - Sequence diagram of model monitoring, user access, and LMEvalJob execution flows
- [Dependencies](./trustyai-service-operator-dependencies.png) ([mmd](./trustyai-service-operator-dependencies.mmd)) - Component dependency graph showing KServe, Prometheus, Kueue, and database integrations

### For Architects
- [C4 Context](./trustyai-service-operator-c4-context.dsl) - System context in C4 format (Structurizr) showing TrustyAI in broader ODH ecosystem
- [Component Overview](./trustyai-service-operator-component.png) ([mmd](./trustyai-service-operator-component.mmd)) - High-level component view

### For Security Teams
- [Security Network Diagram (PNG)](./trustyai-service-operator-security-network.png) - High-resolution network topology with trust boundaries
- [Security Network Diagram (Mermaid)](./trustyai-service-operator-security-network.mmd) - Visual network topology (editable, color-coded zones)
- [Security Network Diagram (ASCII)](./trustyai-service-operator-security-network.txt) - Precise text format for SAR submissions with RBAC details, secrets, and port mappings
- [RBAC Visualization](./trustyai-service-operator-rbac.png) ([mmd](./trustyai-service-operator-rbac.mmd)) - RBAC permissions and bindings for operator and proxy service accounts

## Component Overview

The TrustyAI Service Operator manages deployment and lifecycle of TrustyAI services for:
- **AI Model Explainability**: Provides insights into model predictions
- **Fairness Metrics**: Monitors bias with SPD (Statistical Parity Difference) and DIR (Disparate Impact Ratio)
- **LLM Evaluation**: Executes Large Language Model evaluation jobs using lm-eval-harness

Key features:
- **KServe Integration**: Watches InferenceServices and injects payload processors for automatic data collection
- **Storage Options**: PVC (development) or Database (MySQL/PostgreSQL, production)
- **Authentication**: OAuth proxy sidecar for OpenShift integration
- **Monitoring**: Prometheus ServiceMonitor with fairness metrics
- **Service Mesh**: Optional Istio integration with DestinationRules and VirtualServices
- **Workload Management**: Kueue integration for LMEvalJob scheduling

## Key Architecture Patterns

### Storage Modes
1. **PVC Mode**: Namespace-scoped storage for development and small datasets
2. **DATABASE Mode**: External database (MySQL/PostgreSQL) for production and large datasets
3. **Migration**: Supports migration from PVC to Database with annotation-based triggering

### Network Security
- **External Access**: OpenShift Route with TLS Reencrypt and OAuth authentication
- **Internal Access**: ClusterIP services (port 80→8080 HTTP, port 443→8443 HTTPS)
- **Service Mesh**: Optional Istio with SIMPLE TLS mode (not STRICT mTLS by default)
- **Monitoring**: Prometheus scrapes /q/metrics endpoint via ServiceMonitor

### RBAC
- **Operator ServiceAccount**: `controller-manager` with extensive permissions (manager-role ClusterRole)
- **Proxy ServiceAccount**: Per-TrustyAIService `{name}-proxy` with view permissions
- **Key Permissions**: Full CRUD on TrustyAI CRDs, InferenceServices, Routes, and Kueue Workloads

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
- Perfect for security reviews (precise technical details with RBAC matrix, secrets, and port mappings)

## Updating Diagrams

To regenerate after architecture changes:
```bash
# From repository root
python scripts/generate_diagram_pngs.py architecture/rhoai-2.17/diagrams --width=3000
```

## Related Components

TrustyAI Service Operator integrates with:
- **KServe** ([diagrams](./kserve-component.png)): InferenceService monitoring and data collection
- **ModelMesh Serving** ([diagrams](./modelmesh-serving-component.png)): Model mesh monitoring
- **Prometheus/UWM**: Metrics collection (trustyai_spd, trustyai_dir)
- **ODH Dashboard** ([diagrams](./odh-dashboard-component.png)): Service discovery
- **Kueue** ([diagrams](./kueue-component.png)): LMEvalJob workload management
