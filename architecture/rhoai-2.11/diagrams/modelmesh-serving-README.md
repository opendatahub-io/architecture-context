# Architecture Diagrams for ModelMesh Serving

Generated from: `architecture/rhoai-2.11/modelmesh-serving.md`
Date: 2026-03-15

**Note**: Diagram filenames use base component name without version (directory is already versioned).

## Available Diagrams

All Mermaid diagrams are available in both `.mmd` (source) and `.png` (3000px width, high-resolution) formats.

### For Developers
- [Component Structure](./modelmesh-serving-component.png) ([mmd](./modelmesh-serving-component.mmd)) - Mermaid diagram showing internal components, CRDs, and dependencies
- [Data Flows](./modelmesh-serving-dataflow.png) ([mmd](./modelmesh-serving-dataflow.mmd)) - Sequence diagram of model deployment and inference request flows
- [Dependencies](./modelmesh-serving-dependencies.png) ([mmd](./modelmesh-serving-dependencies.mmd)) - Component dependency graph showing required and optional dependencies

### For Architects
- [C4 Context](./modelmesh-serving-c4-context.dsl) - System context in C4 format (Structurizr)
- [Component Overview](./modelmesh-serving-component.png) ([mmd](./modelmesh-serving-component.mmd)) - High-level component view

### For Security Teams
- [Security Network Diagram (PNG)](./modelmesh-serving-security-network.png) - High-resolution network topology with trust zones
- [Security Network Diagram (Mermaid)](./modelmesh-serving-security-network.mmd) - Visual network topology (editable)
- [Security Network Diagram (ASCII)](./modelmesh-serving-security-network.txt) - Precise text format for SAR submissions
- [RBAC Visualization](./modelmesh-serving-rbac.png) ([mmd](./modelmesh-serving-rbac.mmd)) - RBAC permissions and bindings

## Component Overview

ModelMesh Serving is a Kubernetes operator that manages ModelMesh deployments for intelligent multi-model serving with automatic model placement and routing.

**Key Features**:
- Multi-model serving with intelligent placement
- Support for multiple inference runtimes (Triton, MLServer, OpenVINO, TorchServe)
- Distributed state management via etcd
- LRU-based memory management
- Optional Service Mesh (Istio) integration for mTLS

**Architecture Highlights**:
- **Controller**: Reconciles InferenceService, Predictor, ServingRuntime CRs
- **Webhook**: Validates ServingRuntime and ClusterServingRuntime CRs
- **Runtime Deployment**: Per-namespace ModelMesh pods with model servers and adapters
- **State Store**: etcd for model registry and coordination
- **Model Storage**: S3/MinIO for model artifacts

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

## Security Architecture Details

The security network diagram highlights:

**Trust Zones**:
- External (untrusted): Data scientists and inference clients
- Kubernetes API Server: Control plane entry point
- Control Plane: ModelMesh controller and webhook
- Data Plane: Per-namespace ModelMesh runtime deployments
- State Storage: etcd cluster
- External Services: S3/MinIO

**Network Flows**:
- User → K8s API: HTTPS/6443 TLS 1.2+ with Bearer Token
- K8s API → Webhook: HTTPS/9443 TLS 1.2+ with K8s API Token
- Controller → K8s API: HTTPS/6443 TLS 1.2+ with ServiceAccount Token
- ModelMesh → etcd: HTTP/2379 plaintext (⚠️ no encryption)
- ModelMesh → Model Server: gRPC/8001 plaintext (⚠️ no encryption)
- Runtime Adapter → S3: HTTPS/443 TLS 1.2+ with AWS IAM or Access Keys
- Inference Client → ModelMesh: gRPC/8033 plaintext or mTLS (if Istio enabled)

**Security Considerations**:
- ⚠️ etcd and internal ModelMesh communications are plaintext
- ⚠️ No authentication on internal gRPC services
- ✅ Optional Service Mesh (Istio) provides mTLS for inference traffic
- ✅ NetworkPolicies isolate controller and runtime pods
- ✅ RBAC controls CRD operations

**Secrets**:
- `modelmesh-webhook-server-cert`: Webhook TLS certificate (cert-manager, 90d rotation)
- `storage-config`: S3/MinIO credentials (manual rotation required)
- `model-serving-etcd`: etcd connection configuration

## Data Flows

### Flow 1: Model Deployment
1. User creates InferenceService CR via kubectl
2. K8s API validates CR via webhook
3. Predictor controller watches CR and triggers deployment
4. Controller registers model with ModelMesh
5. ModelMesh stores metadata in etcd
6. Runtime adapter downloads model from S3
7. Model loaded into server runtime

### Flow 2: Inference Request
1. Client sends gRPC request to ModelMesh service
2. ModelMesh queries etcd for model location
3. Request routed to appropriate model server
4. Server processes inference and returns result
5. ModelMesh returns response to client

### Flow 3: ServingRuntime Validation
1. User creates ServingRuntime CR
2. K8s API calls webhook for validation
3. Webhook validates runtime configuration
4. CR created if valid

## Updating Diagrams

To regenerate after architecture changes:
```bash
# From repository root
python scripts/generate_diagram_pngs.py architecture/rhoai-2.11/diagrams --width=3000
```

Or regenerate all diagrams from source:
```bash
# Implement as needed - regenerate from architecture markdown
```

## Component Dependencies

**Required External Dependencies**:
- etcd v3.5.4+ (distributed state)
- S3/MinIO (model storage)
- modelmesh v0.11.2 (core runtime)
- modelmesh-runtime-adapter v0.11.2 (model pulling)

**Optional Model Servers** (at least one required):
- Triton Inference Server 2.x
- MLServer 1.x
- OpenVINO Model Server 1.x
- TorchServe 0.x

**Optional Internal ODH Components**:
- Service Mesh (Istio) - mTLS and traffic management
- Prometheus Operator - metrics collection
- cert-manager - webhook certificate management

## Related Documentation

- [ModelMesh Serving Repository](https://github.com/red-hat-data-services/modelmesh-serving)
- [KServe Documentation](https://kserve.github.io/website/)
- [ModelMesh Architecture](https://github.com/kserve/modelmesh)
