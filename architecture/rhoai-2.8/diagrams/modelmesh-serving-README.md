# Architecture Diagrams for ModelMesh Serving

Generated from: `architecture/rhoai-2.8/modelmesh-serving.md`
Date: 2026-03-15

**Note**: Diagram filenames use base component name without version (directory is already versioned).

## Available Diagrams

All Mermaid diagrams are available in both `.mmd` (source) and `.png` (3000px width, high-resolution) formats.

### For Developers
- [Component Structure](./modelmesh-serving-component.png) ([mmd](./modelmesh-serving-component.mmd)) - Mermaid diagram showing internal components
- [Data Flows](./modelmesh-serving-dataflow.png) ([mmd](./modelmesh-serving-dataflow.mmd)) - Sequence diagram of request/response flows
- [Dependencies](./modelmesh-serving-dependencies.png) ([mmd](./modelmesh-serving-dependencies.mmd)) - Component dependency graph

### For Architects
- [C4 Context](./modelmesh-serving-c4-context.dsl) - System context in C4 format (Structurizr)
- [Component Overview](./modelmesh-serving-component.png) ([mmd](./modelmesh-serving-component.mmd)) - High-level component view

### For Security Teams
- [Security Network Diagram (PNG)](./modelmesh-serving-security-network.png) - High-resolution network topology
- [Security Network Diagram (Mermaid)](./modelmesh-serving-security-network.mmd) - Visual network topology (editable)
- [Security Network Diagram (ASCII)](./modelmesh-serving-security-network.txt) - Precise text format for SAR submissions
- [RBAC Visualization](./modelmesh-serving-rbac.png) ([mmd](./modelmesh-serving-rbac.mmd)) - RBAC permissions and bindings

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
# Update the architecture markdown file first, then regenerate diagrams
python scripts/generate_diagram_pngs.py architecture/rhoai-2.8/diagrams --width=3000
```

## Component Summary

**ModelMesh Serving** is a Kubernetes operator that manages the lifecycle of ModelMesh, a general-purpose model serving management and routing layer. It orchestrates the deployment of model serving runtimes (Triton, MLServer, OpenVINO, TorchServe) and manages model placement across pods for efficient resource utilization.

### Key Components

- **modelmesh-controller**: Kubernetes operator that reconciles CRDs and manages ModelMesh runtime deployments
- **ModelMesh Runtime Pods**: Per-ServingRuntime deployments containing model mesh, runtime adapter, puller, and model server containers
- **etcd**: Distributed key-value store for ModelMesh state management and model placement coordination
- **REST Proxy**: Translates KServe V2 REST protocol to gRPC for inference requests
- **Storage Helper (Puller)**: Retrieves models from object storage (S3, PVC) before loading

### Supported Model Servers

- **Triton Inference Server**: tensorflow, pytorch, onnx, tensorrt
- **MLServer**: sklearn, xgboost, lightgbm
- **OpenVINO Model Server**: openvino_ir, onnx
- **TorchServe**: pytorch

### Key Features

- Multi-model serving with intelligent model placement
- KServe V2 protocol support (gRPC and REST)
- Integration with S3-compatible object storage
- Distributed state management via etcd
- Optional KServe InferenceService CRD compatibility
- Prometheus metrics integration
- Horizontal pod autoscaling support
