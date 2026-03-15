# Architecture Diagrams for TrustyAI Service Operator

Generated from: `architecture/rhoai-3.3/trustyai-service-operator.md`
Date: 2026-03-15
Component: trustyai-service-operator

**Note**: Diagram filenames use base component name without version (directory is already versioned).

## Available Diagrams

All Mermaid diagrams are available in both `.mmd` (source) and `.png` (3000px width, high-resolution) formats.

### For Developers
- [Component Structure](./trustyai-service-operator-component.png) ([mmd](./trustyai-service-operator-component.mmd)) - Mermaid diagram showing internal components and managed resources
- [Data Flows](./trustyai-service-operator-dataflow.png) ([mmd](./trustyai-service-operator-dataflow.mmd)) - Sequence diagram of deployment, monitoring, evaluation, and guardrails flows
- [Dependencies](./trustyai-service-operator-dependencies.png) ([mmd](./trustyai-service-operator-dependencies.mmd)) - Component dependency graph showing KServe, Istio, Kueue integrations

### For Architects
- [C4 Context](./trustyai-service-operator-c4-context.dsl) - System context in C4 format (Structurizr)
- [Component Overview](./trustyai-service-operator-component.png) ([mmd](./trustyai-service-operator-component.mmd)) - High-level component view

### For Security Teams
- [Security Network Diagram (PNG)](./trustyai-service-operator-security-network.png) - High-resolution network topology
- [Security Network Diagram (Mermaid)](./trustyai-service-operator-security-network.mmd) - Visual network topology (editable)
- [Security Network Diagram (ASCII)](./trustyai-service-operator-security-network.txt) - Precise text format for SAR submissions
- [RBAC Visualization](./trustyai-service-operator-rbac.png) ([mmd](./trustyai-service-operator-rbac.mmd)) - RBAC permissions and bindings

## Component Overview

The TrustyAI Service Operator is a Kubernetes operator that manages deployment and lifecycle of TrustyAI components:

- **TrustyAI Service**: Model explainability, fairness monitoring, and drift detection
- **LM Evaluation Driver**: Language model evaluation using lm-evaluation-harness
- **Guardrails Orchestrator**: FMS guardrail detectors for LLM safety
- **Nemo Guardrails**: NVIDIA NeMo guardrails integration

### Key Features

1. **Multi-Storage Support**: PVC or database (PostgreSQL/MySQL) backends
2. **Service Mesh Integration**: Istio VirtualServices and DestinationRules for traffic management
3. **Metrics Collection**: Prometheus ServiceMonitors for fairness and drift metrics
4. **Job Queueing**: Kueue integration for LM evaluation workloads
5. **OpenShift Integration**: Routes and service-serving certificates

### Custom Resources

| CRD | Purpose |
|-----|---------|
| TrustyAIService (v1/v1alpha1) | Deploy TrustyAI service with storage and metrics configuration |
| LMEvalJob (v1alpha1) | Run LLM evaluation jobs with model and task configuration |
| GuardrailsOrchestrator (v1alpha1) | Configure FMS guardrails with detector services |
| NemoGuardrails (v1alpha1) | Deploy NVIDIA NeMo guardrails |

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

## Architecture Highlights

### Data Flows

1. **TrustyAI Service Deployment**: User creates TrustyAIService CR → Operator creates Deployment, Service, PVC → TrustyAI service initializes storage
2. **Inference Monitoring**: KServe sends inference data → TrustyAI stores and analyzes → Prometheus scrapes fairness/drift metrics
3. **LM Evaluation**: User creates LMEvalJob → Operator submits to Kueue → Job downloads models from HuggingFace → Queries inference service → Updates status
4. **Guardrails Orchestration**: Operator patches InferenceService → Requests route through detector services → Guardrails orchestrator validates → Forwards to LLM

### Security Features

- **TLS Everywhere**: OpenShift Routes with reencrypt mode, service-serving certificates
- **Service Mesh**: Istio mTLS for service-to-service communication
- **RBAC**: Comprehensive permissions for managing TrustyAI CRDs, KServe InferenceServices, Istio resources
- **kube-rbac-proxy**: Secures metrics endpoints with TokenReview and SubjectAccessReview
- **Database TLS**: Optional TLS with CA verification for PostgreSQL/MySQL connections

### Integration Points

| Component | Integration | Purpose |
|-----------|-------------|---------|
| KServe | API (InferenceService patching) | Monitor and inject guardrails into inference services |
| Istio | CRD (VirtualService, DestinationRule) | Traffic routing and service mesh integration |
| Prometheus | ServiceMonitor | Metrics collection for fairness and drift |
| Kueue | Workload API | Job queueing for LM evaluation |
| OpenShift | Routes, service-serving certs | External access and certificate management |
| HuggingFace | HTTPS API | Model and dataset downloads for evaluation |

## Updating Diagrams

To regenerate after architecture changes:
```bash
# From the architecture/rhoai-3.3 directory
python ../../scripts/generate_diagram_pngs.py diagrams --width=3000
```

Or regenerate from the architecture file:
```bash
# (if using the generate-architecture-diagrams skill)
/generate-architecture-diagrams --architecture=architecture/rhoai-3.3/trustyai-service-operator.md
```

## Related Documentation

- [TrustyAI Service Operator Repository](https://github.com/red-hat-data-services/trustyai-service-operator)
- [Architecture Documentation](../trustyai-service-operator.md)
- [RHOAI 3.3 Platform Architecture](../PLATFORM.md)
