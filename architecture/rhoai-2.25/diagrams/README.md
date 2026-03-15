# Architecture Diagrams for RHOAI 2.25 Components

This directory contains architecture diagrams for all RHOAI 2.25 platform components.

Generated from: `architecture/rhoai-2.25/*.md`
Date: 2026-03-15

**Note**: Diagram filenames use base component name without version (directory is already versioned).

---

## RHOAI Operator (rhods-operator)

Generated from: `architecture/rhoai-2.25/rhods-operator.md`

The **RHOAI Operator (rhods-operator)** is the primary operator for Red Hat OpenShift AI, responsible for deploying, configuring, and managing the complete data science platform.

### Available Diagrams

All Mermaid diagrams are available in both `.mmd` (source) and `.png` (3000px width, high-resolution) formats.

#### For Developers
- [Component Structure](./rhods-operator-component.png) ([mmd](./rhods-operator-component.mmd)) - Mermaid diagram showing internal components, controllers, and deployed AI/ML components
- [Data Flows](./rhods-operator-dataflow.png) ([mmd](./rhods-operator-dataflow.mmd)) - Sequence diagram of DataScienceCluster creation, component deployment, monitoring, and platform service initialization
- [Dependencies](./rhods-operator-dependencies.png) ([mmd](./rhods-operator-dependencies.mmd)) - Component dependency graph showing relationships with Kubernetes, OpenShift, external operators, and deployed components

#### For Architects
- [C4 Context](./rhods-operator-c4-context.dsl) - System context in C4 format (Structurizr) showing the operator's role in the RHOAI ecosystem
- [Component Overview](./rhods-operator-component.png) ([mmd](./rhods-operator-component.mmd)) - High-level component view including 14 component controllers, service controllers, and manifest renderer

#### For Security Teams
- [Security Network Diagram (PNG)](./rhods-operator-security-network.png) - High-resolution network topology with trust boundaries, encryption, and authentication details
- [Security Network Diagram (Mermaid)](./rhods-operator-security-network.mmd) - Visual network topology (editable)
- [Security Network Diagram (ASCII)](./rhods-operator-security-network.txt) - Precise text format for SAR submissions with detailed RBAC, secrets, network policies, and webhook configurations
- [RBAC Visualization](./rhods-operator-rbac.png) ([mmd](./rhods-operator-rbac.mmd)) - RBAC permissions and bindings for the rhods-operator-controller-manager ServiceAccount

### Component Overview

Key features:
- **Custom Resources**: Manages DataScienceCluster and DSCInitialization CRs to enable and configure platform components
- **Component Controllers**: 14 component-specific controllers (Dashboard, KServe, Pipelines, CodeFlare, Ray, Kueue, ModelRegistry, ModelMeshServing, TrustyAI, TrainingOperator, Workbenches, FeastOperator, LlamaStackOperator, ModelController)
- **Service Controllers**: Platform service controllers for Auth, Monitoring, ServiceMesh, secret generation, and certificate management
- **Manifest Renderer**: Kustomize-based rendering of 220+ component manifests from prefetched component repositories
- **Monitoring Stack**: Deploys Prometheus, Alertmanager, OpenTelemetry Collector, and Tempo when monitoring is enabled
- **Webhook Server**: Validates and mutates DataScienceCluster and DSCInitialization resources

---

## TrustyAI Service Operator

Generated from: `architecture/rhoai-2.25/trustyai-service-operator.md`

**TrustyAI Service Operator** manages three distinct AI governance services:

1. **TrustyAI Service**: AI explainability, bias detection, and fairness metrics for ML models
2. **LM Eval Jobs**: Language model evaluation using lm-evaluation-harness
3. **Guardrails Orchestrator**: AI safety detectors for input/output content filtering

### Available Diagrams

#### For Developers
- [Component Structure](./trustyai-service-operator-component.png) ([mmd](./trustyai-service-operator-component.mmd)) - Mermaid diagram showing operator components, managed services, and resource creation
- [Data Flows](./trustyai-service-operator-dataflow.png) ([mmd](./trustyai-service-operator-dataflow.mmd)) - Sequence diagrams of 4 key flows: TrustyAI monitoring, LM evaluation, guardrails processing, operator reconciliation
- [Dependencies](./trustyai-service-operator-dependencies.png) ([mmd](./trustyai-service-operator-dependencies.mmd)) - Component dependency graph showing external/internal ODH dependencies

#### For Architects
- [C4 Context](./trustyai-service-operator-c4-context.dsl) - System context in C4 format (Structurizr) showing TrustyAI operator in the ODH/RHOAI ecosystem
- [Component Overview](./trustyai-service-operator-component.png) ([mmd](./trustyai-service-operator-component.mmd)) - High-level component view with operator, managed services, and integrations

#### For Security Teams
- [Security Network Diagram (PNG)](./trustyai-service-operator-security-network.png) - High-resolution network topology with trust zones
- [Security Network Diagram (Mermaid)](./trustyai-service-operator-security-network.mmd) - Visual network topology (editable)
- [Security Network Diagram (ASCII)](./trustyai-service-operator-security-network.txt) - Precise text format for SAR submissions with detailed RBAC, secrets, auth flows
- [RBAC Visualization](./trustyai-service-operator-rbac.png) ([mmd](./trustyai-service-operator-rbac.mmd)) - RBAC permissions matrix showing service accounts, roles, bindings, and resources

---

## Other RHOAI 2.25 Components

This directory also contains diagrams for the following components:

- **CodeFlare Operator** ([codeflare-operator-*.{mmd,png}](./))
- **Data Science Pipelines Operator** ([data-science-pipelines-operator-*.{mmd,png}](./))
- **Feast** ([feast-*.{mmd,png}](./))
- **KServe** ([kserve-*.{mmd,png}](./))
- **Kubeflow** ([kubeflow-*.{mmd,png}](./))
- **KubeRay** ([kuberay-*.{mmd,png}](./))
- **Kueue** ([kueue-*.{mmd,png}](./))
- **Llama Stack K8s Operator** ([llama-stack-k8s-operator-*.{mmd,png}](./))
- **Model Registry Operator** ([model-registry-operator-*.{mmd,png}](./))
- **ModelMesh Serving** ([modelmesh-serving-*.{mmd,png}](./))
- **Notebooks** ([notebooks-*.{mmd,png}](./))
- **ODH Dashboard** ([odh-dashboard-*.{mmd,png}](./))
- **ODH Model Controller** ([odh-model-controller-*.{mmd,png}](./))
- **Platform** ([platform-*.{mmd,png}](./)) - Aggregated platform view
- **Training Operator** ([training-operator-*.{mmd,png}](./))

Each component has the following diagram types:
- **-component.{mmd,png}**: Component structure and relationships
- **-dataflow.{mmd,png}**: Data flow sequences
- **-dependencies.{mmd,png}**: Dependency graph
- **-rbac.{mmd,png}**: RBAC visualization
- **-security-network.{mmd,png,txt}**: Security network topology (PNG, Mermaid, ASCII)
- **-c4-context.dsl**: C4 context diagram (Structurizr DSL)

---

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
- **Online**: Upload to https://structurizr.com/dsl

### ASCII Diagrams (.txt files)
- View in any text editor
- Include in documentation as-is
- Perfect for security reviews (precise technical details with RBAC, secrets, auth flows)

---

## Updating Diagrams

To regenerate all diagrams after architecture changes:

```bash
# From repository root
python scripts/generate_diagram_pngs.py architecture/rhoai-2.25/diagrams --width=3000 --force
```

To regenerate diagrams for a specific component:
```bash
# Edit the .mmd file, then regenerate PNG
cd architecture/rhoai-2.25/diagrams/
PUPPETEER_EXECUTABLE_PATH=/usr/bin/google-chrome mmdc -i rhods-operator-component.mmd -o rhods-operator-component.png -w 3000
```

---

## Related Documentation

- [RHOAI 2.25 Architecture Overview](../README.md)
- Individual component architecture files in `architecture/rhoai-2.25/`
- [Platform Architecture](../PLATFORM.md) - Aggregated platform view
