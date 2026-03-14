# Architecture Diagrams for ODH Model Controller

Generated from: `architecture/odh-3.3.0/odh-model-controller.md`
Date: 2026-03-13

**Note**: Diagram filenames use base component name without version (directory is already versioned).

## Available Diagrams

All Mermaid diagrams are available in both `.mmd` (source) and `.png` (3000px width, high-resolution) formats.

### For Developers
- [Component Structure](./odh-model-controller-component.png) ([mmd](./odh-model-controller-component.mmd)) - Mermaid diagram showing internal components, controllers, CRDs watched, and resources created
- [Data Flows](./odh-model-controller-dataflow.png) ([mmd](./odh-model-controller-dataflow.mmd)) - Sequence diagram of InferenceService creation, NIM model serving, and LLM inference flows
- [Dependencies](./odh-model-controller-dependencies.png) ([mmd](./odh-model-controller-dependencies.mmd)) - Component dependency graph showing required/optional dependencies

### For Architects
- [C4 Context](./odh-model-controller-c4-context.dsl) - System context in C4 format (Structurizr) showing ODH Model Controller in broader ecosystem
- [Component Overview](./odh-model-controller-component.png) ([mmd](./odh-model-controller-component.mmd)) - High-level component view with controllers and integrations

### For Security Teams
- [Security Network Diagram (PNG)](./odh-model-controller-security-network.png) - High-resolution network topology with trust zones
- [Security Network Diagram (Mermaid)](./odh-model-controller-security-network.mmd) - Visual network topology (editable)
- [Security Network Diagram (ASCII)](./odh-model-controller-security-network.txt) - Precise text format for SAR submissions with RBAC, Service Mesh config, and Secrets details
- [RBAC Visualization](./odh-model-controller-rbac.png) ([mmd](./odh-model-controller-rbac.mmd)) - RBAC permissions and bindings for all API groups

## Component Summary

The ODH Model Controller extends KServe functionality with OpenShift-specific capabilities:

- **Purpose**: Extension controller for KServe with OpenShift ingress, routing, and LLM inference management
- **Key Features**:
  - OpenShift Router integration for InferenceService external access
  - NVIDIA NIM (NVIDIA Inference Microservices) account management
  - LLM inference services with flow control and AuthorizationPolicy
  - Kubernetes Gateway API HTTPRoutes (alternative ingress)
  - KEDA auto-scaling integration
  - Serving runtime template management (TensorFlow, PyTorch, ONNX, MLServer, vLLM)

- **Controllers**:
  - InferenceService Controller - Manages Routes and ingress
  - ServingRuntime Controller - Manages runtime templates
  - LLM InferenceService Controller - Orchestrates LLM services
  - NIM Account Controller - Manages NGC integration
  - ConfigMap/Pod/Secret Watchers - Syncs configurations

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
# From the repository root
cd architecture/odh-3.3.0
# Update the architecture markdown file first
# Then regenerate diagrams (command would be provided by the skill)
```

## Related Components

The ODH Model Controller integrates with:
- **KServe** - Core model serving framework (extended by this controller)
- **OpenShift Router** - Exposes InferenceService endpoints externally
- **Istio** - Service mesh for mTLS and AuthorizationPolicy
- **NVIDIA NIM** - GPU-accelerated inference microservices
- **Model Registry** - Model metadata and versioning
- **ODH Dashboard** - UI for model serving management
- **S3 Storage** - Model artifact storage
- **KEDA** - Auto-scaling for inference workloads

## Architecture Highlights

### Security
- **mTLS**: Istio service mesh enforces mTLS for service-to-service communication
- **AuthorizationPolicy**: LLM InferenceServices use Istio AuthorizationPolicy for token validation
- **TLS Termination**: OpenShift Routes perform TLS 1.2+ edge termination (HTTPS → HTTP)
- **Secrets Management**: NGC API keys and AWS credentials stored in Kubernetes Secrets
- **RBAC**: ClusterRole with fine-grained permissions for KServe, OpenShift, Gateway API, and Istio resources

### Network Flows
1. **InferenceService Creation**: User → K8s API → KServe Controller → Predictor Pod → S3 (model download) → ODH Controller → OpenShift Route
2. **NIM Model Serving**: User → Account CR → ODH Controller → NGC API (config) → ConfigMap → InferenceService → NIM Predictor → NGC (model download)
3. **LLM Inference**: Client → OpenShift Route → Istio Gateway → AuthorizationPolicy check → Predictor Pod → S3 (model) → Response

### Dependencies
- **Required**: KServe 0.14+, OpenShift Router 4.x
- **Optional**: NVIDIA NIM, Istio 1.20+, Gateway API v1beta1, KEDA 2.x
- **Internal ODH**: Model Registry, ODH Dashboard, TrustyAI (sidecar integration)

## Files Generated

```
diagrams/
├── odh-model-controller-component.mmd           # Component structure (Mermaid source)
├── odh-model-controller-component.png           # Component structure (3000px PNG)
├── odh-model-controller-dataflow.mmd            # Data flows (Mermaid source)
├── odh-model-controller-dataflow.png            # Data flows (3000px PNG)
├── odh-model-controller-security-network.mmd    # Security network (Mermaid source)
├── odh-model-controller-security-network.png    # Security network (3000px PNG)
├── odh-model-controller-security-network.txt    # Security network (ASCII - for SAR)
├── odh-model-controller-c4-context.dsl          # C4 context (Structurizr DSL)
├── odh-model-controller-dependencies.mmd        # Dependencies (Mermaid source)
├── odh-model-controller-dependencies.png        # Dependencies (3000px PNG)
├── odh-model-controller-rbac.mmd                # RBAC visualization (Mermaid source)
├── odh-model-controller-rbac.png                # RBAC visualization (3000px PNG)
└── odh-model-controller-README.md               # This file
```

## Additional Resources

- **Source Repository**: https://github.com/opendatahub-io/odh-model-controller.git
- **KServe Documentation**: https://kserve.github.io/website/
- **OpenShift Routes**: https://docs.openshift.com/container-platform/latest/networking/routes/route-configuration.html
- **Kubernetes Gateway API**: https://gateway-api.sigs.k8s.io/
- **NVIDIA NIM**: https://docs.nvidia.com/nim/
