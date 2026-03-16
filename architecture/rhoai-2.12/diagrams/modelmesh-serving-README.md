# Architecture Diagrams for ModelMesh Serving

Generated from: `architecture/rhoai-2.12/modelmesh-serving.md`
Date: 2026-03-15

**Note**: Diagram filenames use base component name without version (directory is already versioned).

## Available Diagrams

All Mermaid diagrams are available in both `.mmd` (source) and `.png` (3000px width, high-resolution) formats.

### For Developers
- [Component Structure](./modelmesh-serving-component.png) ([mmd](./modelmesh-serving-component.mmd)) - Mermaid diagram showing internal components, CRDs, and dependencies
- [Data Flows](./modelmesh-serving-dataflow.png) ([mmd](./modelmesh-serving-dataflow.mmd)) - Sequence diagram of request/response flows (gRPC inference, REST inference, model loading, controller reconciliation, metrics collection)
- [Dependencies](./modelmesh-serving-dependencies.png) ([mmd](./modelmesh-serving-dependencies.mmd)) - Component dependency graph showing external dependencies (Etcd, Kubernetes), internal ODH components, and model server runtimes

### For Architects
- [C4 Context](./modelmesh-serving-c4-context.dsl) - System context in C4 format (Structurizr) showing ModelMesh in broader ecosystem
- [Component Overview](./modelmesh-serving-component.png) ([mmd](./modelmesh-serving-component.mmd)) - High-level component view

### For Security Teams
- [Security Network Diagram (PNG)](./modelmesh-serving-security-network.png) - High-resolution network topology with trust zones
- [Security Network Diagram (Mermaid)](./modelmesh-serving-security-network.mmd) - Visual network topology (editable) with trust zones
- [Security Network Diagram (ASCII)](./modelmesh-serving-security-network.txt) - Precise text format for SAR submissions with detailed port/protocol/encryption/auth information
- [RBAC Visualization](./modelmesh-serving-rbac.png) ([mmd](./modelmesh-serving-rbac.mmd)) - RBAC permissions and bindings showing ClusterRoles, ServiceAccounts, and API resource access

## Key Architecture Highlights

### Component Architecture
- **modelmesh-controller**: Kubernetes Operator managing InferenceService, Predictor, and ServingRuntime CRDs
- **ModelMesh Runtime Pods**: Multi-container pods with ModelMesh routing layer, REST proxy, model servers (Triton/MLServer/OpenVINO/TorchServe), and storage puller
- **Webhook Server**: Validates ServingRuntime and ClusterServingRuntime configurations
- **Etcd Integration**: Required external dependency for distributed state management

### Network Architecture
- **Inference Endpoints**: gRPC (8033/TCP) and REST (8008/TCP) for model inference
- **Control Plane**: Webhook server (9443/TCP HTTPS), metrics (8443/TCP HTTPS with kube-rbac-proxy)
- **Internal Communication**: ModelMesh internal (8080/TCP gRPC), runtime adapters (8001-8090/TCP gRPC)
- **External Dependencies**: S3 storage (443/TCP HTTPS), Etcd (2379/TCP gRPC with optional TLS)

### Security
- **RBAC**: Comprehensive ClusterRoles for managing serving.kserve.io resources, Deployments, Services, and monitoring
- **Secrets**: Etcd credentials, S3 storage config, webhook TLS certificates
- **Optional mTLS**: Service mesh integration via Istio for traffic encryption
- **Network Policies**: Restrict traffic to controller (8443/TCP), runtimes (8033/TCP, 8008/TCP, 2112/TCP), and webhook (9443/TCP)

### Data Flows
1. **gRPC Inference**: Client → Service (8033) → ModelMesh → Model Server
2. **REST Inference**: Client → Service (8008) → REST Proxy → ModelMesh → Model Server
3. **Model Loading**: Puller Init Container → S3 (443/HTTPS) → Shared Volume → Model Server
4. **Controller Reconciliation**: Controller → K8s API (6443/HTTPS) + Etcd (2379/gRPC)
5. **Metrics Collection**: Prometheus → Controller (8443/HTTPS), Runtime Pods (2112/HTTP)

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
python scripts/generate_architecture_diagrams.py --architecture=architecture/rhoai-2.12/modelmesh-serving.md
```

## Component Details

### Custom Resource Definitions
- **InferenceService** (serving.kserve.io/v1beta1): Defines model inference service with model location and serving configuration
- **Predictor** (serving.kserve.io/v1alpha1): Internal representation of deployed model predictor
- **ServingRuntime** (serving.kserve.io/v1alpha1): Namespace-scoped runtime configuration (container image, resource limits, supported formats)
- **ClusterServingRuntime** (serving.kserve.io/v1alpha1): Cluster-wide ServingRuntime template

### Supported Model Servers
- **Triton Inference Server**: NVIDIA's inference server for deep learning models
- **MLServer**: Python-based inference server supporting scikit-learn, XGBoost, LightGBM
- **OpenVINO Model Server**: Intel's inference server optimized for CPU/GPU/VPU
- **TorchServe**: PyTorch model serving framework

### Deployment Modes
- **Cluster-scoped** (default): Controller watches all namespaces
- **Namespace-scoped**: Controller watches single namespace (NAMESPACE_SCOPE=true)
- **High Availability**: Support for 3 controller replicas with leader election

## Version Information

- **Component Version**: v1.27.0-rhods-254-g3d48699
- **Branch**: rhoai-2.12
- **Distribution**: RHOAI
- **Based on**: KServe ModelMesh Serving v0.11.0 with RHOAI patches
- **ModelMesh Runtime**: v0.11.2
- **REST Proxy**: v0.11.2
