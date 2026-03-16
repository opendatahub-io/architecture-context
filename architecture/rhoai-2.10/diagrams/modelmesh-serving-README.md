# Architecture Diagrams for ModelMesh Serving

Generated from: `architecture/rhoai-2.10/modelmesh-serving.md`
Date: 2026-03-15
Component: modelmesh-serving

**Note**: Diagram filenames use base component name without version (directory is already versioned).

## Available Diagrams

All Mermaid diagrams are available in both `.mmd` (source) and `.png` (3000px width, high-resolution) formats.

### For Developers
- [Component Structure](./modelmesh-serving-component.png) ([mmd](./modelmesh-serving-component.mmd)) - Mermaid diagram showing internal components, CRD interactions, and runtime pod architecture
- [Data Flows](./modelmesh-serving-dataflow.png) ([mmd](./modelmesh-serving-dataflow.mmd)) - Sequence diagram of model deployment, loading, inference requests, and metrics collection flows
- [Dependencies](./modelmesh-serving-dependencies.png) ([mmd](./modelmesh-serving-dependencies.mmd)) - Component dependency graph showing required/optional dependencies and integration points

### For Architects
- [C4 Context](./modelmesh-serving-c4-context.dsl) - System context in C4 format (Structurizr) showing ModelMesh Serving in broader ecosystem
- [Component Overview](./modelmesh-serving-component.png) ([mmd](./modelmesh-serving-component.mmd)) - High-level component view with controller, runtime pods, and external dependencies

### For Security Teams
- [Security Network Diagram (PNG)](./modelmesh-serving-security-network.png) - High-resolution network topology with trust boundaries
- [Security Network Diagram (Mermaid)](./modelmesh-serving-security-network.mmd) - Visual network topology (editable)
- [Security Network Diagram (ASCII)](./modelmesh-serving-security-network.txt) - Precise text format for SAR submissions with RBAC, secrets, and network policies
- [RBAC Visualization](./modelmesh-serving-rbac.png) ([mmd](./modelmesh-serving-rbac.mmd)) - RBAC permissions and bindings for controller and runtime service accounts

## Component Summary

**ModelMesh Serving** is a Kubernetes operator that orchestrates multi-model serving infrastructure:

- **Controller**: Reconciles Predictor, ServingRuntime, and InferenceService CRDs
- **Runtime Pods**: Multi-container pods with ModelMesh routing layer, model server runtimes (Triton/MLServer/OVMS/TorchServe), REST proxy, and storage puller
- **etcd**: Distributed coordination and model metadata storage
- **Inference Endpoints**: gRPC (8033/TCP) and KServe V2 REST (8008/TCP)

Key features:
- Multi-model serving (multiple models per pod)
- On-demand model loading
- Model placement and routing across runtime pods
- Support for multiple model server runtimes
- S3/PVC storage backends

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

## Architecture Highlights

### Network Security
- **Controller**: HTTPS/8443 metrics with mTLS, HTTPS/9443 webhook with K8s API auth
- **Runtime inference**: HTTP/8008 (REST) and gRPC/8033 (default: no auth, optional user-defined policy)
- **etcd**: HTTP/2379 with optional basic auth
- **S3 egress**: HTTPS/443 with AWS IAM or access keys
- **Runtime pods**: restricted SCC, capabilities dropped (ALL)

### RBAC
- **modelmesh-controller**: ClusterRole with full access to CRDs (predictors, servingruntimes, inferenceservices), deployments, services, configmaps, secrets
- **modelmesh-serving-sa**: Runtime service account with restricted SCC
- **Leader election**: Namespace-scoped role for controller HA

### Dependencies
- **Required**: etcd 3.x, Kubernetes API
- **Optional**: S3-compatible storage, model server runtimes (Triton/MLServer/OVMS/TorchServe), Prometheus, cert-manager
- **Internal ODH**: Dashboard integration, monitoring ServiceMonitor

### Data Flows
1. **Model Deployment**: User creates Predictor CR → controller reconciles → creates runtime deployment
2. **Model Loading**: ModelMesh registers in etcd → storage puller downloads from S3 → adapter loads into runtime
3. **Inference**: Client sends request → REST proxy converts to gRPC → ModelMesh routes to pod → runtime executes → response returned
4. **Metrics**: Prometheus scrapes runtime pods (HTTP/2112) and controller (HTTPS/8443 with mTLS)

## Updating Diagrams

To regenerate after architecture changes:

```bash
# From repository root
python scripts/generate_diagram_pngs.py architecture/rhoai-2.10/diagrams --width=3000
```

Or regenerate architecture documentation and diagrams together:

```bash
# Full workflow (if source repo changes)
# 1. Update architecture markdown
# 2. Regenerate diagrams
python scripts/generate_diagram_pngs.py architecture/rhoai-2.10/diagrams --width=3000
```

## Files Generated

- `modelmesh-serving-component.mmd` + `.png` - Component structure diagram
- `modelmesh-serving-dataflow.mmd` + `.png` - Data flow sequence diagram
- `modelmesh-serving-security-network.mmd` + `.png` + `.txt` - Security network diagram (3 formats)
- `modelmesh-serving-dependencies.mmd` + `.png` - Dependency graph
- `modelmesh-serving-rbac.mmd` + `.png` - RBAC visualization
- `modelmesh-serving-c4-context.dsl` - C4 context diagram (Structurizr)
- `modelmesh-serving-README.md` - This file
