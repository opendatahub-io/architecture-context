# Architecture Diagrams for KServe

Generated from: `architecture/rhoai-2.7/kserve.md`
Date: 2026-03-15

**Note**: Diagram filenames use base component name without version (directory is already versioned).

## Available Diagrams

All Mermaid diagrams are available in both `.mmd` (source) and `.png` (3000px width, high-resolution) formats.

### For Developers
- [Component Structure](./kserve-component.png) ([mmd](./kserve-component.mmd)) - Mermaid diagram showing internal components
- [Data Flows](./kserve-dataflow.png) ([mmd](./kserve-dataflow.mmd)) - Sequence diagram of request/response flows
- [Dependencies](./kserve-dependencies.png) ([mmd](./kserve-dependencies.mmd)) - Component dependency graph

### For Architects
- [C4 Context](./kserve-c4-context.dsl) - System context in C4 format (Structurizr)
- [Component Overview](./kserve-component.png) ([mmd](./kserve-component.mmd)) - High-level component view

### For Security Teams
- [Security Network Diagram (PNG)](./kserve-security-network.png) - High-resolution network topology
- [Security Network Diagram (Mermaid)](./kserve-security-network.mmd) - Visual network topology (editable)
- [Security Network Diagram (ASCII)](./kserve-security-network.txt) - Precise text format for SAR submissions
- [RBAC Visualization](./kserve-rbac.png) ([mmd](./kserve-rbac.mmd)) - RBAC permissions and bindings

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
/generate-architecture-diagrams --architecture=../kserve.md
```

## KServe Overview

KServe is a Kubernetes Custom Resource Definition (CRD) operator for serving machine learning models with serverless inference, autoscaling, and multi-framework support.

### Key Components

- **KServe Controller Manager**: Go operator that reconciles InferenceService, ServingRuntime, and InferenceGraph CRDs
- **Webhook Server**: Validates and mutates KServe CRDs (9443/TCP HTTPS)
- **Model Servers**: Python-based servers for various ML frameworks (sklearn, XGBoost, LightGBM, PaddlePaddle, PMML)
- **Agent Sidecar**: Model lifecycle management, logging, and batching
- **Router**: Multi-step inference pipeline routing for InferenceGraph
- **Storage Initializer**: Downloads models from S3, GCS, or Azure before pod starts
- **Explainers**: Alibi and ART libraries for model interpretability and adversarial testing

### Custom Resources

- **InferenceService** (v1beta1): Main resource for deploying ML models with predictor, transformer, and explainer components
- **ServingRuntime** (v1alpha1): Defines model serving runtime (container, supported formats, protocol)
- **ClusterServingRuntime** (v1alpha1): Cluster-wide serving runtime configuration
- **InferenceGraph** (v1alpha1): Multi-step inference pipeline with routing between nodes
- **TrainedModel** (v1alpha1): Represents a trained model artifact with storage location
- **ClusterStorageContainer** (v1alpha1): Storage container configuration for model downloads

### Dependencies

**External Dependencies:**
- Knative Serving v0.39.3 (Optional) - Serverless deployment, scale-to-zero
- Istio v1.x (Optional) - Service mesh, traffic splitting, mTLS
- cert-manager v1.x (Optional) - TLS certificate provisioning
- Kubernetes v1.26+ (Required) - Core platform

**Internal ODH Dependencies:**
- Service Mesh (Istio) - Traffic routing, canary deployments
- Model Registry - Model metadata and storage URIs
- Prometheus - Metrics collection

**Storage Backends:**
- AWS S3 - Model artifact storage (HTTPS/443, AWS IAM)
- Google Cloud Storage - Model artifact storage (HTTPS/443, GCP Service Account)
- Azure Blob Storage - Model artifact storage (HTTPS/443, Azure Storage Key)

### Deployment Modes

1. **Serverless Mode** (Default): Uses Knative Serving for autoscaling and scale-to-zero with Istio VirtualServices
2. **RawDeployment Mode**: Uses standard Kubernetes Deployments with Kubernetes Ingress
3. **ModelMesh Mode**: High-density model serving with shared model servers (different architecture)

### Security Highlights

- **RBAC**: Extensive ClusterRole permissions for managing KServe CRDs, Knative Services, Istio VirtualServices, and K8s resources
- **Authentication**:
  - Webhook endpoints use K8s API Server mTLS (9443/TCP)
  - Inference endpoints support optional Bearer Token authentication (8080/TCP)
  - Storage access uses cloud provider credentials (AWS IAM, GCP SA, Azure Key)
- **Security Context**: runAsNonRoot=true, allowPrivilegeEscalation=false
- **TLS**: Webhook server uses cert-manager for automated TLS certificate provisioning
- **Service Mesh**: Optional Istio integration for mTLS and traffic encryption

### Network Architecture

**Ingress Flow (Serverless):**
```
External Client (HTTPS/443 TLS 1.3)
  → Istio Ingress Gateway
  → Knative Activator (HTTP/8012)
  → Predictor Pod (HTTP/8080)
```

**Ingress Flow (RawDeployment):**
```
External Client (HTTPS/443 TLS 1.3)
  → Kubernetes Ingress
  → Predictor Service (HTTP/8080)
  → Predictor Pod (HTTP/8080)
```

**Model Deployment Flow:**
```
User kubectl (HTTPS/6443)
  → K8s API Server
  → KServe Webhook (HTTPS/9443 mTLS)
  → KServe Controller (watches CRDs)
  → Storage Initializer (downloads from S3/GCS/Azure HTTPS/443)
  → Model Server Pod (serves on HTTP/8080)
```

For detailed architecture information, see [kserve.md](../kserve.md).
