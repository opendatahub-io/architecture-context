# Architecture Diagrams for ModelMesh Serving

Generated from: `architecture/rhoai-2.9/modelmesh-serving.md`
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

## Component Overview

**ModelMesh Serving** is a Kubernetes operator that manages the lifecycle of ModelMesh deployments, providing efficient multi-model serving capabilities. It reconciles InferenceService and Predictor custom resources to deploy and manage machine learning models across various runtime engines (Triton, MLServer, OpenVINO, TorchServe).

### Key Features
- **Multi-Model Serving**: Efficiently loads multiple models into shared serving pods
- **Intelligent Routing**: ModelMesh orchestration layer routes inference requests
- **Multiple Runtimes**: Support for Triton, MLServer, OpenVINO, and TorchServe
- **Distributed Metadata**: Uses etcd for model metadata and placement decisions
- **S3 Storage**: Model artifacts stored in S3-compatible object storage
- **OAuth Authentication**: OpenShift OAuth integration for secure inference endpoints

### Architecture Highlights
- **Controller**: modelmesh-controller reconciles CRDs and manages runtime deployments
- **Runtime Pods**: Multi-container pods with ModelMesh, runtime adapters, model servers, REST proxy, and OAuth proxy
- **Webhook**: Validates ServingRuntime and ClusterServingRuntime resources
- **External Dependencies**: etcd (required), S3 storage (required), Prometheus (optional)
- **Internal Dependencies**: OpenShift OAuth, RHOAI Dashboard, OpenShift Monitoring

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
python scripts/generate_diagram_pngs.py architecture/rhoai-2.9/diagrams --width=3000
```

## Component Details

### Custom Resource Definitions

| CRD | API Group | Version | Scope |
|-----|-----------|---------|-------|
| InferenceService | serving.kserve.io | v1beta1 | Namespaced |
| Predictor | serving.kserve.io | v1alpha1 | Namespaced |
| ServingRuntime | serving.kserve.io | v1alpha1 | Namespaced |
| ClusterServingRuntime | serving.kserve.io | v1alpha1 | Cluster |

### Key Ports and Protocols

| Port | Protocol | Encryption | Purpose |
|------|----------|------------|---------|
| 8443/TCP | HTTPS | TLS 1.2+ | OAuth-protected inference endpoint |
| 8033/TCP | gRPC | None | ModelMesh inference (internal) |
| 8008/TCP | HTTP | None | REST proxy (internal) |
| 8001/TCP | gRPC | None | Model server runtime management |
| 2379/TCP | gRPC | None | etcd metadata storage |
| 443/TCP | HTTPS | TLS 1.2+ | S3 model artifact storage |
| 9443/TCP | HTTPS | TLS 1.2+ | Webhook server |
| 6443/TCP | HTTPS | TLS 1.3 | Kubernetes API |

### Security Considerations

- **Authentication**: OpenShift OAuth for external inference requests
- **Authorization**: RBAC-based access control for CRDs and services
- **Encryption**: TLS 1.2+ for external communication, unencrypted internal pod communication
- **Secrets**: storage-config (S3 credentials), model-serving-proxy-tls (TLS certs), modelmesh-webhook-server-cert (webhook TLS)
- **Network Policies**: Restrict access to controller, runtime pods, and webhook server

## Additional Resources

- **Upstream Documentation**: https://github.com/kserve/modelmesh-serving
- **Runtime Adapters**: https://github.com/kserve/modelmesh-runtime-adapter
- **ModelMesh Core**: https://github.com/kserve/modelmesh
- **KServe V2 Protocol**: https://github.com/kserve/kserve/tree/master/docs/predict-api/v2
- **Architecture Documentation**: [modelmesh-serving.md](../modelmesh-serving.md)
