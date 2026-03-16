# Architecture Diagrams for ModelMesh Serving

Generated from: `architecture/rhoai-2.13/modelmesh-serving.md`
Date: 2026-03-15

**Note**: Diagram filenames use base component name without version (directory is already versioned).

## Available Diagrams

All Mermaid diagrams are available in both `.mmd` (source) and `.png` (3000px width, high-resolution) formats.

### For Developers
- [Component Structure](./modelmesh-serving-component.png) ([mmd](./modelmesh-serving-component.mmd)) - Mermaid diagram showing internal components and architecture
- [Data Flows](./modelmesh-serving-dataflow.png) ([mmd](./modelmesh-serving-dataflow.mmd)) - Sequence diagram of model registration, loading, and inference flows
- [Dependencies](./modelmesh-serving-dependencies.png) ([mmd](./modelmesh-serving-dependencies.mmd)) - Component dependency graph showing external and internal dependencies

### For Architects
- [C4 Context](./modelmesh-serving-c4-context.dsl) - System context in C4 format (Structurizr)
- [Component Overview](./modelmesh-serving-component.png) ([mmd](./modelmesh-serving-component.mmd)) - High-level component view with CRDs, controllers, and runtime pods

### For Security Teams
- [Security Network Diagram (PNG)](./modelmesh-serving-security-network.png) - High-resolution network topology with trust boundaries
- [Security Network Diagram (Mermaid)](./modelmesh-serving-security-network.mmd) - Visual network topology (editable)
- [Security Network Diagram (ASCII)](./modelmesh-serving-security-network.txt) - Precise text format for SAR submissions
- [RBAC Visualization](./modelmesh-serving-rbac.png) ([mmd](./modelmesh-serving-rbac.mmd)) - RBAC permissions and bindings

## Component Overview

ModelMesh Serving is a Kubernetes operator that manages multi-model serving deployments. It provides:

- **Multi-model serving**: Multiple models loaded in the same runtime pods for efficient resource utilization
- **Multiple runtime backends**: Triton, MLServer, OpenVINO Model Server, TorchServe
- **Flexible CRDs**: Predictor, ServingRuntime, ClusterServingRuntime, InferenceService (KServe compatibility)
- **Protocol support**: KServe V2 gRPC and REST APIs
- **Storage integration**: S3-compatible storage for model artifacts
- **Metadata management**: etcd for model state and coordination

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

## Key Architecture Highlights

### Runtime Pod Architecture
Each runtime pod contains multiple containers working together:
- **ModelMesh**: Java-based model routing and placement orchestration
- **Runtime Adapter**: Coordinates model pull, load, and unload operations
- **REST Proxy**: Translates KServe V2 REST API to gRPC
- **Storage Helper**: Downloads model artifacts from S3-compatible storage
- **Model Server**: Actual inference engine (Triton/MLServer/OVMS/TorchServe)

### Network Flows
1. **Model Registration**: User creates Predictor CR → Controller registers with ModelMesh → Runtime pulls from S3
2. **gRPC Inference**: Client → Service → ModelMesh → Runtime Adapter → Model Server
3. **REST Inference**: Client → REST Proxy → ModelMesh → Runtime Adapter → Model Server

### Security Considerations
- ⚠️ etcd communication uses unencrypted HTTP (should use TLS in production)
- ⚠️ Inference endpoints (8033, 8008) have no built-in authentication (rely on service mesh)
- ✓ Controller metrics protected by kube-rbac-proxy
- ✓ Webhook server uses TLS 1.2+ with cert-manager integration

## Updating Diagrams

To regenerate after architecture changes:
```bash
python scripts/generate_diagram_pngs.py architecture/rhoai-2.13/diagrams --width=3000
```

Or regenerate from the architecture markdown:
```bash
# (Future: add diagram generation command when available)
```

## Related Components

- **KServe**: Alternative serverless model serving (different architecture)
- **ODH Model Controller**: Integration for model registry and serving coordination
- **ODH Dashboard**: UI for managing Predictors and ServingRuntimes
- **Data Science Pipelines**: Can auto-deploy models to ModelMesh Serving

## References

- Architecture Documentation: [modelmesh-serving.md](../modelmesh-serving.md)
- Repository: https://github.com/red-hat-data-services/modelmesh-serving
- Upstream: https://github.com/kserve/modelmesh-serving
- Version: v1.27.0-rhods-292 (based on upstream v0.11.0)
