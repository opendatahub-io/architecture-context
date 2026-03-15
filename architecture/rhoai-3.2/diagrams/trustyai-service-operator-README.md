# Architecture Diagrams for TrustyAI Service Operator

Generated from: `architecture/rhoai-3.2/trustyai-service-operator.md`
Date: 2026-03-15

**Note**: Diagram filenames use base component name without version (directory is already versioned).

## Available Diagrams

All Mermaid diagrams are available in both `.mmd` (source) and `.png` (3000px width, high-resolution) formats.

### For Developers
- [Component Structure](./trustyai-service-operator-component.png) ([mmd](./trustyai-service-operator-component.mmd)) - Mermaid diagram showing internal components, CRDs, and managed resources
- [Data Flows](./trustyai-service-operator-dataflow.png) ([mmd](./trustyai-service-operator-dataflow.mmd)) - Sequence diagrams of TrustyAI monitoring, LMEval jobs, and guardrails orchestration flows
- [Dependencies](./trustyai-service-operator-dependencies.png) ([mmd](./trustyai-service-operator-dependencies.mmd)) - Component dependency graph showing KServe, Istio, Kueue integrations

### For Architects
- [C4 Context](./trustyai-service-operator-c4-context.dsl) - System context in C4 format (Structurizr)
- [Component Overview](./trustyai-service-operator-component.png) ([mmd](./trustyai-service-operator-component.mmd)) - High-level component view with operator, TrustyAI Service, LMEval, Guardrails Orchestrator, and NeMo Guardrails

### For Security Teams
- [Security Network Diagram (PNG)](./trustyai-service-operator-security-network.png) - High-resolution network topology
- [Security Network Diagram (Mermaid)](./trustyai-service-operator-security-network.mmd) - Visual network topology (editable)
- [Security Network Diagram (ASCII)](./trustyai-service-operator-security-network.txt) - Precise text format for SAR submissions
- [RBAC Visualization](./trustyai-service-operator-rbac.png) ([mmd](./trustyai-service-operator-rbac.mmd)) - RBAC permissions and bindings showing manager-role with extensive API access

## Component Summary

The TrustyAI Service Operator manages four main service types:
1. **TrustyAI Service**: Model explainability, fairness monitoring, and drift detection for KServe models
2. **LMEval Jobs**: LLM evaluation using EleutherAI's lm-evaluation-harness
3. **Guardrails Orchestrator**: LLM safety and policy enforcement with built-in and external detectors
4. **NeMo Guardrails**: NVIDIA NeMo guardrails integration

### Key Integration Points
- **KServe**: Patches InferenceServices for payload logging, integrates with inference endpoints
- **Istio**: Creates VirtualService and DestinationRule for mTLS and routing
- **OpenShift**: Creates Routes for external HTTPS access with edge TLS termination
- **Kueue**: Optional job queuing and resource management for LMEval
- **Prometheus**: Metrics collection via ServiceMonitor

### Security Highlights
- **Authentication**: kube-rbac-proxy with Bearer Token → SubjectAccessReview for all external APIs
- **Encryption**: TLS 1.2+ for all HTTPS endpoints, optional database TLS
- **Service Mesh**: mTLS enforcement via Istio for service-to-service communication
- **Secrets**: Auto-rotating TLS certificates via OpenShift service-ca
- **RBAC**: Extensive ClusterRole with access to core, apps, KServe, Istio, OpenShift Routes, Kueue APIs

### Network Architecture
- **Ingress**: OpenShift Routes with edge TLS termination (443/TCP HTTPS)
- **Internal Services**: Multiple ClusterIP services with HTTP (internal) and HTTPS (via proxy)
- **Egress**: Database (PostgreSQL/MySQL), KServe InferenceServices, S3 storage
- **Ports**:
  - Operator: 8080/TCP (metrics), 8081/TCP (health/ready)
  - TrustyAI Service: 8443/TCP HTTPS (via proxy)
  - Guardrails Orchestrator: 8032/TCP HTTP, 8432/TCP HTTPS (via proxy), 8080/TCP (detectors), 8090/TCP (gateway)
  - NeMo Guardrails: 8000/TCP HTTP, 8443/TCP HTTPS (via proxy)
  - LMES Driver: 18080/TCP HTTP (sidecar)

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
python scripts/generate_diagram_pngs.py architecture/rhoai-3.2/diagrams --width=3000 --force
```

## Data Flows

### Flow 1: TrustyAI Model Monitoring
1. KServe InferenceService → TrustyAI Service (8443/TCP HTTPS, mTLS)
2. TrustyAI Service → PostgreSQL/MySQL (5432/3306 TCP, TLS 1.2+ optional)
3. TrustyAI Service → Prometheus (9443/TCP HTTPS, mTLS)
4. User/Dashboard → TrustyAI Service via Route (443/TCP HTTPS, Bearer Token)

### Flow 2: LMEval Job Execution
1. User → Kubernetes API (6443/TCP HTTPS, Bearer Token) - Create LMEvalJob CR
2. Operator → Kueue API - Create Workload
3. LMEval Job Pod → Model Endpoint (443/TCP HTTPS or 8080/TCP HTTP)
4. LMEval Job Pod → S3 Storage (443/TCP HTTPS, AWS Signature V4)
5. LMES Driver ↔ LMEval Job Container (18080/TCP HTTP sidecar)

### Flow 3: Guardrails Orchestration
1. LLM Application → Guardrails Gateway (8090/TCP HTTP)
2. Gateway → Orchestrator (8032/TCP HTTP)
3. Orchestrator → Built-in Detectors (8080/TCP HTTP)
4. Orchestrator → External Detector InferenceService (443/TCP HTTPS, mTLS)
5. Orchestrator → LLM InferenceService (443/TCP HTTPS, mTLS)

### Flow 4: Operator Reconciliation
1. Operator → Kubernetes API (6443/TCP HTTPS, ServiceAccount Token)
2. Operator → Istio API (VirtualService/DestinationRule CRDs)
3. Operator → OpenShift Routes API
4. Operator → KServe API (patch InferenceServices)

## Architecture Highlights

### Multi-Service Operator
The operator manages four distinct service types through separate CRDs and reconcilers, enabling modular deployment based on use case.

### KServe Integration
Deep integration with KServe for:
- Model monitoring (TrustyAI Service)
- Model evaluation (LMEval Jobs)
- LLM safety (Guardrails Orchestrator)

### Security-First Design
- All external APIs secured with kube-rbac-proxy
- Optional service mesh mTLS enforcement
- Auto-rotating TLS certificates
- Database encryption support

### Storage Flexibility
- TrustyAI Service: PVC or database backend (PostgreSQL/MySQL)
- LMEval Jobs: S3-compatible object storage
- Configuration: ConfigMaps and Secrets

## Custom Resource Definitions

| CRD | Version | Purpose |
|-----|---------|---------|
| TrustyAIService | v1 | Model explainability, fairness monitoring, drift detection |
| LMEvalJob | v1alpha1 | LLM evaluation with lm-evaluation-harness |
| GuardrailsOrchestrator | v1alpha1 | LLM guardrails orchestration |
| NemoGuardrails | v1alpha1 | NVIDIA NeMo guardrails integration |

## Dependencies

### Required
- KServe v0.12.1+ (inference services)
- Kubernetes v1.19+ (runtime platform)
- Go 1.23 (build toolchain)

### Optional
- Kueue v0.6.2 (job queuing and resource management)
- Prometheus Operator v0.64.1 (metrics collection)
- Istio Service Mesh (mTLS and traffic management)

### External Services
- PostgreSQL or MySQL (TrustyAI data persistence)
- S3-compatible storage (LMEval job outputs)
- Model Registry (LLM model metadata)
