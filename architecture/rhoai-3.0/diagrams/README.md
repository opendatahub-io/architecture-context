# Architecture Diagrams for RHOAI 3.0 Components

This directory contains architecture diagrams for multiple RHOAI 3.0 components.
Date: 2026-03-16

**Note**: Diagram filenames use base component name without version (directory is already versioned).

All Mermaid diagrams are available in both `.mmd` (source) and `.png` (3000px width, high-resolution) formats.

---

## Components

- [ODH Dashboard](#odh-dashboard)
- [TrustyAI Service Operator](#trustyai-service-operator)

---

## ODH Dashboard

Generated from: `architecture/rhoai-3.0/odh-dashboard.md`

### Available Diagrams

#### For Developers
- [Component Structure](./odh-dashboard-component.png) ([mmd](./odh-dashboard-component.mmd)) - Mermaid diagram showing internal components
- [Data Flows](./odh-dashboard-dataflow.png) ([mmd](./odh-dashboard-dataflow.mmd)) - Sequence diagram of request/response flows
- [Dependencies](./odh-dashboard-dependencies.png) ([mmd](./odh-dashboard-dependencies.mmd)) - Component dependency graph

#### For Architects
- [C4 Context](./odh-dashboard-c4-context.dsl) - System context in C4 format (Structurizr)
- [Component Overview](./odh-dashboard-component.png) ([mmd](./odh-dashboard-component.mmd)) - High-level component view

#### For Security Teams
- [Security Network Diagram (PNG)](./odh-dashboard-security-network.png) - High-resolution network topology
- [Security Network Diagram (Mermaid)](./odh-dashboard-security-network.mmd) - Visual network topology (editable)
- [Security Network Diagram (ASCII)](./odh-dashboard-security-network.txt) - Precise text format for SAR submissions
- [RBAC Visualization](./odh-dashboard-rbac.png) ([mmd](./odh-dashboard-rbac.mmd)) - RBAC permissions and bindings

---

## TrustyAI Service Operator

Generated from: `architecture/rhoai-3.0/trustyai-service-operator.md`

### Available Diagrams

#### For Developers
- [Component Structure](./trustyai-service-operator-component.png) ([mmd](./trustyai-service-operator-component.mmd)) - Operator, managed components, and CRDs
- [Data Flow - TrustyAI Service](./trustyai-service-operator-dataflow.png) ([mmd](./trustyai-service-operator-dataflow.mmd)) - TrustyAI service data ingestion flow
- [Data Flow - Guardrails](./trustyai-service-operator-dataflow-guardrails.png) ([mmd](./trustyai-service-operator-dataflow-guardrails.mmd)) - Guardrails orchestration request flow
- [Data Flow - LMEval Jobs](./trustyai-service-operator-dataflow-lmeval.png) ([mmd](./trustyai-service-operator-dataflow-lmeval.mmd)) - LM evaluation job execution flow
- [Data Flow - Guardrails Injection](./trustyai-service-operator-dataflow-injection.png) ([mmd](./trustyai-service-operator-dataflow-injection.mmd)) - InferenceService guardrails injection flow
- [Dependencies](./trustyai-service-operator-dependencies.png) ([mmd](./trustyai-service-operator-dependencies.mmd)) - Component dependency graph

#### For Architects
- [C4 Context](./trustyai-service-operator-c4-context.dsl) - System context in C4 format (Structurizr)
- [Component Overview](./trustyai-service-operator-component.png) ([mmd](./trustyai-service-operator-component.mmd)) - High-level component view

#### For Security Teams
- [Security Network Diagram (PNG)](./trustyai-service-operator-security-network.png) - High-resolution network topology
- [Security Network Diagram (Mermaid)](./trustyai-service-operator-security-network.mmd) - Visual network topology (editable)
- [Security Network Diagram (ASCII)](./trustyai-service-operator-security-network.txt) - Precise text format for SAR submissions
- [RBAC Visualization](./trustyai-service-operator-rbac.png) ([mmd](./trustyai-service-operator-rbac.mmd)) - RBAC permissions and bindings

### Architecture Overview

The TrustyAI Service Operator manages three key AI governance components:

1. **TrustyAI Service**: Explainability and bias detection for ML models
   - Storage: PVC (CSV files) or external database (PostgreSQL/MySQL)
   - Endpoints: Secured with kube-rbac-proxy (8443/TCP HTTPS)
   - Metrics: Prometheus scraping via ServiceMonitor

2. **LM Evaluation Jobs (LMES)**: Language model assessment
   - Batch workloads with Kueue integration
   - Downloads models from Model Registry
   - Evaluates against KServe InferenceServices
   - Stores results in Kubernetes Secrets

3. **Guardrails Orchestrator (GORCH)**: AI safety controls
   - Intercepts inference requests
   - Routes through detector InferenceServices
   - OpenTelemetry telemetry export
   - OAuth-protected endpoints (8432/8490)

### Key Security Features

- **mTLS**: Service mesh (Istio) provides mTLS for InferenceService communication
- **RBAC**: kube-rbac-proxy enforces Kubernetes RBAC on service endpoints
- **OAuth**: Optional OAuth proxy integration via annotations
- **TLS**: All external endpoints use TLS 1.2+ encryption
- **Service-CA**: Automatic certificate rotation via OpenShift service-ca

### Integration Points

- **KServe**: Watches and patches InferenceServices for guardrails injection
- **Istio**: Creates VirtualServices and DestinationRules for traffic management
- **Prometheus**: ServiceMonitors for automated metrics collection
- **Kueue**: Job scheduling with resource quotas and priorities
- **Model Registry**: Model download for LMEval jobs
- **OpenTelemetry**: Telemetry export from guardrails orchestrator

---

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
# For ODH Dashboard
/generate-architecture-diagrams --architecture=architecture/rhoai-3.0/odh-dashboard.md

# For TrustyAI Service Operator
/generate-architecture-diagrams --architecture=architecture/rhoai-3.0/trustyai-service-operator.md
```
