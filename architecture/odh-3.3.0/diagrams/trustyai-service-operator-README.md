# Architecture Diagrams for TrustyAI Service Operator

Generated from: `architecture/odh-3.3.0/trustyai-service-operator.md`
Date: 2026-03-13

**Note**: Diagram filenames use base component name without version (directory is already versioned).

## Available Diagrams

All Mermaid diagrams are available in both `.mmd` (source) and `.png` (3000px width, high-resolution) formats.

### For Developers
- [Component Structure](./trustyai-service-operator-component.png) ([mmd](./trustyai-service-operator-component.mmd)) - Mermaid diagram showing internal components, controllers, and service deployments
- [Data Flows](./trustyai-service-operator-dataflow.png) ([mmd](./trustyai-service-operator-dataflow.mmd)) - Sequence diagram of model monitoring, fairness calculation, and LLM evaluation flows
- [Dependencies](./trustyai-service-operator-dependencies.png) ([mmd](./trustyai-service-operator-dependencies.mmd)) - Component dependency graph showing integrations with KServe, Model Registry, and external services

### For Architects
- [C4 Context](./trustyai-service-operator-c4-context.dsl) - System context in C4 format (Structurizr) showing TrustyAI in the broader ODH ecosystem
- [Component Overview](./trustyai-service-operator-component.png) ([mmd](./trustyai-service-operator-component.mmd)) - High-level component view with operator controllers and managed services

### For Security Teams
- [Security Network Diagram (PNG)](./trustyai-service-operator-security-network.png) - High-resolution network topology with trust zones
- [Security Network Diagram (Mermaid)](./trustyai-service-operator-security-network.mmd) - Visual network topology (editable) with authentication and encryption details
- [Security Network Diagram (ASCII)](./trustyai-service-operator-security-network.txt) - Precise text format for SAR submissions with complete RBAC and secrets documentation
- [RBAC Visualization](./trustyai-service-operator-rbac.png) ([mmd](./trustyai-service-operator-rbac.mmd)) - RBAC permissions and bindings for operator and service accounts

## Component Overview

The TrustyAI Service Operator manages multiple AI governance and monitoring services:

1. **TrustyAI Service** - Model explainability, fairness monitoring, and data drift detection for KServe models
2. **EvalHub** - LLM evaluation hub using lm-evaluation-harness with MLFlow experiment tracking
3. **FMS Guardrails** - Foundation Model safety and guardrails framework
4. **NeMo Guardrails** - NVIDIA NeMo Guardrails for LLM safety mechanisms

## Key Architectural Features

- **Multi-Controller Design**: Separate reconcilers for TrustyAIService, EvalHub, LMEvalJob, GuardrailsOrchestrator, and NemoGuardrails
- **KServe Integration**: Sidecar-based inference data collection for fairness and drift monitoring
- **PostgreSQL Persistence**: Optional database integration for storing inference payloads and evaluation results
- **Multi-Tenant RBAC**: Namespace-scoped service accounts and role bindings for tenant isolation
- **External Service Integration**: HuggingFace Hub for model downloads, S3 for datasets, MLFlow for experiment tracking
- **OAuth/JWT Authentication**: Bearer token authentication for service APIs with OAuth proxy support

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

## Diagram Descriptions

### Component Structure Diagram
Shows the internal architecture of the TrustyAI Service Operator:
- 5 reconciler controllers (TrustyAIService, EvalHub, LMEvalJob, GuardrailsOrchestrator, NemoGuardrails)
- Custom Resource Definitions (CRDs) managed by the operator
- Deployed services (TrustyAI Service, EvalHub, Guardrails)
- External dependencies (PostgreSQL, MLFlow, HuggingFace, S3)
- Internal ODH integrations (KServe, Model Registry, Dashboard, Pipelines)

### Data Flow Diagram
Three key flows:
1. **Model Inference Monitoring**: Client → KServe → TrustyAI Service → PostgreSQL
2. **Fairness Metric Calculation**: User → TrustyAI Service → PostgreSQL (calculates SPD, DIR)
3. **LLM Evaluation Job**: User creates LMEvalJob CR → Operator creates Job → Downloads models from HuggingFace → Runs evaluation → Tracks in MLFlow → Uploads results to S3

### Security Network Diagram
Comprehensive network topology showing:
- **External Zone**: User/client connections via HTTPS
- **Ingress (DMZ)**: OpenShift Routes with TLS edge termination and OAuth
- **Cluster Internal**: TrustyAI services with optional TLS and Bearer token auth
- **Egress**: Connections to PostgreSQL, HuggingFace, S3, MLFlow
- **RBAC Details**: ClusterRoles, RoleBindings, ServiceAccounts
- **Secrets**: Database credentials, S3 credentials, HuggingFace tokens, OAuth tokens
- **Authentication**: OAuth proxy, Bearer tokens, mTLS for metrics

### C4 Context Diagram
System-level view showing:
- Users: Data Scientists and Platform Administrators
- TrustyAI containers: Operator, TrustyAI Service, EvalHub, Guardrails
- External systems: KServe, Model Registry, Dashboard, Pipelines
- External services: PostgreSQL, MLFlow, HuggingFace, S3, Kubernetes API

### Dependency Graph
Visual representation of:
- Required dependencies: TrustyAI Service image, KServe, Kubernetes API
- Optional dependencies: PostgreSQL, MLFlow, FMS Guardrails, NeMo Guardrails
- Internal ODH integrations: Model Registry, Dashboard, Pipelines
- External services: HuggingFace Hub, S3 Storage

### RBAC Visualization
Shows permission flows:
- **manager-role**: Full CRUD on TrustyAI CRDs, core resources, Jobs, Deployments, Routes
- **evalhub-mlflow-role**: Permissions for EvalHub to create Jobs and manage secrets in tenant namespaces
- Service accounts and their bindings
- API resource permissions with verb details

## Updating Diagrams

To regenerate after architecture changes:
```bash
# From repository root
python scripts/generate_diagram_pngs.py architecture/odh-3.3.0/diagrams --width=3000
```

Or use the full workflow:
```bash
# Update architecture documentation first, then regenerate diagrams
/generate-architecture-diagrams --architecture=architecture/odh-3.3.0/trustyai-service-operator.md
```

## Related Documentation

- Architecture source: [trustyai-service-operator.md](../trustyai-service-operator.md)
- Repository: https://github.com/opendatahub-io/trustyai-service-operator
- Version: 1.39.0
- Distribution: ODH and RHOAI (both)
