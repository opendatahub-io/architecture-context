# Architecture Diagrams for KServe

Generated from: `architecture/rhoai-2.14/kserve.md`
Date: 2026-03-15

**Note**: Diagram filenames use base component name without version (directory is already versioned).

## Available Diagrams

All Mermaid diagrams are available in both `.mmd` (source) and `.png` (3000px width, high-resolution) formats.

### For Developers
- [Component Structure](./kserve-component.png) ([mmd](./kserve-component.mmd)) - Mermaid diagram showing internal components, CRDs, and integrations
- [Data Flows](./kserve-dataflow.png) ([mmd](./kserve-dataflow.mmd)) - Sequence diagram of request/response flows including InferenceService creation, model download, inference requests (serverless & raw modes), dynamic model loading, and InferenceGraph pipelines
- [Dependencies](./kserve-dependencies.png) ([mmd](./kserve-dependencies.mmd)) - Component dependency graph showing external dependencies (Knative, Istio, Kubernetes, cert-manager), internal ODH integrations, and cloud storage backends

### For Architects
- [C4 Context](./kserve-c4-context.dsl) - System context in C4 format (Structurizr) showing KServe in the broader ecosystem with users, dependencies, and integrations
- [Component Overview](./kserve-component.png) ([mmd](./kserve-component.mmd)) - High-level component view with control plane, data plane, and external dependencies

### For Security Teams
- [Security Network Diagram (PNG)](./kserve-security-network.png) - High-resolution network topology with trust zones, ports, protocols, encryption, and authentication
- [Security Network Diagram (Mermaid)](./kserve-security-network.mmd) - Visual network topology (editable) with color-coded trust boundaries
- [Security Network Diagram (ASCII)](./kserve-security-network.txt) - Precise text format for SAR submissions with detailed RBAC, service mesh configuration, secrets, and security notes
- [RBAC Visualization](./kserve-rbac.png) ([mmd](./kserve-rbac.mmd)) - RBAC permissions and bindings for kserve-controller-manager service account

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
# From the repository root, run the diagram generation skill
# This will re-read the architecture file and regenerate all diagrams
```

## Diagram Details

### Component Structure (kserve-component.mmd)
Shows the complete KServe architecture including:
- **Control Plane**: kserve-controller-manager, kserve-webhook-server
- **Data Plane**: kserve-agent, kserve-router, storage-initializer
- **Model Serving Runtimes**: sklearn, xgboost, tensorflow, pytorch, triton, huggingface
- **Custom Resources**: InferenceService, ServingRuntime, InferenceGraph, TrainedModel
- **External Dependencies**: Knative Serving, Istio, cert-manager, Kubernetes
- **Storage Backends**: S3, GCS, Azure Blob

### Data Flow (kserve-dataflow.mmd)
Sequence diagrams for 5 major flows:
1. **InferenceService Creation**: User → API Server → Webhook → Controller → Resource creation
2. **Model Download**: storage-initializer downloads from S3/GCS/Azure
3. **Model Inference (Serverless)**: Client → Istio Gateway → Knative Activator → Agent → Model Server
4. **Dynamic Model Loading**: TrainedModel CR triggers Agent to load new models
5. **InferenceGraph Pipeline**: kserve-router orchestrates multi-step inference

### Security Network (kserve-security-network.txt/.mmd)
Detailed network topology with:
- **Trust Zones**: External (untrusted) → Ingress (DMZ) → Control Plane → Data Plane → External Services
- **Network Details**: Exact ports (e.g., 9443/TCP), protocols (HTTPS, HTTP, gRPC), encryption (TLS 1.3, mTLS)
- **Authentication**: kubeconfig, Bearer tokens, mTLS, AWS IAM, GCP Service Accounts
- **RBAC Summary**: Complete ClusterRole permissions for kserve-manager-role
- **Service Mesh Configuration**: PeerAuthentication, AuthorizationPolicy, RequestAuthentication
- **Secrets**: Webhook certs (cert-manager), storage credentials, service account tokens
- **Security Notes**: 8 security considerations for production deployments

### C4 Context (kserve-c4-context.dsl)
C4 system context and container diagrams showing:
- **Users**: Data Scientists (create models), External Clients (inference API)
- **KServe Containers**: Controller, Webhook, Agent, Router, Storage Initializer, Model Servers
- **External Dependencies**: Knative, Istio, cert-manager, Kubernetes, Prometheus
- **Internal ODH**: Model Registry, Data Science Pipelines, Authorino
- **External Services**: S3, GCS, Azure Blob, CloudEvents Broker

### Dependencies (kserve-dependencies.mmd)
Dependency graph showing:
- **External Dependencies**: Knative (conditional), Istio (conditional), Kubernetes (required), cert-manager (conditional), Prometheus (optional)
- **Internal ODH**: Model Registry (optional), Service Mesh (conditional), Dashboard, Pipelines, Authorino
- **External Services**: S3, GCS, Azure Blob, HDFS, CloudEvents Broker

### RBAC (kserve-rbac.mmd)
RBAC visualization showing:
- **Service Account**: kserve-controller-manager (kserve namespace)
- **ClusterRoles**: kserve-manager-role, kserve-leader-election-role, kserve-proxy-role
- **Permissions**: Full CRUD on KServe CRDs, Knative Services, Istio VirtualServices, K8s Deployments, Services, Secrets, etc.
- **Leader Election**: ConfigMaps and Leases for HA controller

## KServe Architecture Overview

KServe is a Kubernetes-native model serving platform supporting:
- **Serverless Mode** (default): Knative Services with autoscaling and scale-to-zero
- **Raw Deployment Mode**: Standard Kubernetes Deployments without Knative
- **ModelMesh Integration**: High-density, frequently-changing model workloads

Key features:
- Multi-framework support (TensorFlow, PyTorch, XGBoost, scikit-learn, HuggingFace, ONNX, Triton)
- Canary rollouts and traffic splitting
- GPU autoscaling and scale-to-zero
- Model explainability (Alibi, ART)
- Multi-model serving (TrainedModel API)
- Multi-step inference pipelines (InferenceGraph)
- Cloud storage integration (S3, GCS, Azure, HDFS)
- Service mesh integration (Istio mTLS, traffic management)

## Version Information

- **KServe Version**: 1fdf877e7 (rhoai-2.14)
- **Distribution**: RHOAI 2.14
- **Repository**: https://github.com/red-hat-data-services/kserve.git
- **Kubernetes**: 1.26+
- **Knative Serving**: 1.x (conditional)
- **Istio**: 1.x (conditional)
