# Architecture Diagrams for ModelMesh Serving

Generated from: `architecture/rhoai-2.25.0/modelmesh-serving.md`
Date: 2026-03-14

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
/generate-architecture-diagrams --architecture=../modelmesh-serving.md
```

## Architecture Summary

**ModelMesh Serving** is a Kubernetes controller for multi-model serving with ModelMesh orchestration. Key components:

- **modelmesh-controller**: Main operator managing ServingRuntime, Predictor, and InferenceService resources
- **ModelMesh**: Java-based model orchestration and routing layer
- **REST Proxy**: Translates KServe V2 REST API to gRPC
- **Runtime Adapters**: Bridge between ModelMesh and model servers (Triton, MLServer, OpenVINO, TorchServe)
- **Storage Puller**: Downloads models from S3/PVC storage
- **ETCD**: Distributed key-value store for model metadata

### Key Network Endpoints

| Port | Protocol | Encryption | Purpose |
|------|----------|------------|---------|
| 8033/TCP | gRPC | None | Model inference (gRPC) |
| 8008/TCP | HTTP | None | Model inference (REST) |
| 9443/TCP | HTTPS | TLS 1.2+ | ValidatingWebhook |
| 8443/TCP | HTTPS | TLS 1.2+ | Controller metrics |
| 2112/TCP | HTTP | None | Runtime pod metrics |
| 2379/TCP | gRPC/HTTP | Optional TLS | ETCD metadata storage |
| 443/TCP | HTTPS | TLS 1.2+ | S3 model artifact storage |

### Security Considerations

- **Inference endpoints (8033, 8008)**: No built-in encryption - recommend using OpenShift Routes with TLS or Service Mesh
- **ETCD connection**: Optional TLS/mTLS - strongly recommended for production
- **Storage access**: Secured via AWS Signature V4 / IAM credentials
- **Webhook**: TLS 1.2+ with certificates from cert-manager or manual provisioning
- **Metrics**: Controller metrics protected by kube-rbac-proxy with Bearer token auth
- **Network Policies**: Available for controller, webhook, runtime pods, and ETCD

### Dependencies

**Required**:
- ETCD v3.5.9 (model metadata storage)
- Kubernetes 1.28+ (container orchestration)

**Optional**:
- cert-manager (automatic webhook TLS certificates)
- Prometheus Operator (ServiceMonitor CRD for metrics)
- OpenShift Service Mesh (mTLS and traffic management)

**Integrations**:
- KServe (shared InferenceService CRD schema v1beta1)
- S3-compatible storage (model artifacts)
- ODH Dashboard (UI management)
- Data Science Pipelines (automated deployment)
