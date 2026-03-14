# Architecture Diagrams for Training Operator

Generated from: `architecture/odh-3.3.0/training-operator.md`
Date: 2026-03-13

**Note**: Diagram filenames use base component name without version (directory is already versioned).

## Available Diagrams

All Mermaid diagrams are available in both `.mmd` (source) and `.png` (3000px width, high-resolution) formats.

### For Developers
- [Component Structure](./training-operator-component.png) ([mmd](./training-operator-component.mmd)) - Mermaid diagram showing internal components and reconcilers
- [Data Flows](./training-operator-dataflow.png) ([mmd](./training-operator-dataflow.mmd)) - Sequence diagram of PyTorchJob, TFJob, and MPIJob workflows
- [Dependencies](./training-operator-dependencies.png) ([mmd](./training-operator-dependencies.mmd)) - Component dependency graph showing ML frameworks and integrations

### For Architects
- [C4 Context](./training-operator-c4-context.dsl) - System context in C4 format (Structurizr)
- [Component Overview](./training-operator-component.png) ([mmd](./training-operator-component.mmd)) - High-level component view with all 6 framework controllers

### For Security Teams
- [Security Network Diagram (PNG)](./training-operator-security-network.png) - High-resolution network topology
- [Security Network Diagram (Mermaid)](./training-operator-security-network.mmd) - Visual network topology (editable)
- [Security Network Diagram (ASCII)](./training-operator-security-network.txt) - Precise text format for SAR submissions
- [RBAC Visualization](./training-operator-rbac.png) ([mmd](./training-operator-rbac.mmd)) - RBAC permissions and bindings for operator

## Component Overview

The **Kubeflow Training Operator** is a Kubernetes-native framework for running scalable distributed training and fine-tuning of machine learning models across multiple ML frameworks:

- **PyTorchJob**: Distributed PyTorch training with elastic training support
- **TFJob**: TensorFlow parameter server and collective training
- **MPIJob**: MPI-based HPC and distributed training workloads
- **JAXJob**: JAX distributed training jobs
- **XGBoostJob**: XGBoost distributed gradient boosting
- **PaddleJob**: PaddlePaddle distributed training

### Key Features
- Gang scheduling support (Volcano integration)
- Job queueing and resource quotas (Kueue integration)
- Admission webhooks for validation and mutation
- Python SDK for simplified job creation
- Integration with ODH ecosystem (Notebooks, Pipelines, Model Registry)

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

## Diagram Details

### Component Structure Diagram
Shows the internal architecture of the Training Operator:
- Training Operator Controller with 6 framework-specific reconcilers
- Custom Resources (PyTorchJob, TFJob, MPIJob, JAXJob, XGBoostJob, PaddleJob)
- Webhook Server for admission control
- Python SDK for job creation
- Integration with external dependencies (Volcano, Kueue, S3, Container Registry)
- Internal ODH integrations (Notebooks, Pipelines, Model Registry, Ray)

### Data Flow Diagram
Sequence diagrams showing three key workflows:
1. **PyTorchJob Creation and Execution**: User → K8s API → Webhook → Operator → Master/Worker Pods → S3 → Model Registry
2. **Distributed TensorFlow Training**: TFJob creation with Chief, Workers, and Parameter Servers communicating via gRPC
3. **MPI-based HPC Training**: MPIJob with Launcher initiating SSH to workers for MPI communication

### Security Network Diagram
Detailed network topology with:
- **External Access**: User → Kubernetes API (6443/TCP HTTPS TLS 1.2+ Bearer Token)
- **Webhook Validation**: Kubernetes API → Webhook Server (9443/TCP HTTPS TLS 1.2+ mTLS)
- **Operator Control**: Training Operator → K8s API (6443/TCP HTTPS ServiceAccount Token)
- **Training Workloads**:
  - PyTorchJob: Master ↔ Workers (23456/TCP TCP plaintext)
  - TFJob: Workers/Chief ↔ Parameter Servers (2222/TCP gRPC plaintext)
  - MPIJob: Launcher → Workers (22/TCP SSH), Workers ↔ Workers (Dynamic TCP/UDP plaintext)
- **Egress**:
  - S3 Storage (443/TCP HTTPS TLS 1.2+ AWS credentials)
  - Container Registry (443/TCP HTTPS TLS 1.2+ Token)
  - Model Registry (8080/TCP HTTP Bearer Token)
  - MLFlow (5000/TCP HTTP no auth)

**Security Notes**:
- Plaintext communication between training pods is acceptable for performance (trusted pod-to-pod network)
- All external egress uses TLS 1.2+
- Webhook uses mTLS for API Server communication
- Secrets managed for AWS credentials, registry credentials, SSH keys, and webhook certificates

### RBAC Visualization
Shows permissions granted to the `training-operator` ServiceAccount:
- **ClusterRole**: training-operator
- **API Groups**:
  - Core: pods, services, configmaps, serviceaccounts, events (full CRUD)
  - kubeflow.org: all training job CRs (PyTorchJob, TFJob, MPIJob, JAXJob, XGBoostJob, PaddleJob) and their status subresources
  - batch: jobs (full CRUD)
  - autoscaling: horizontalpodautoscalers (full CRUD)
  - admissionregistration.k8s.io: validatingwebhookconfigurations (get, list, update, watch)

### Dependencies Diagram
Visualizes:
- **External Runtime Dependencies**: PyTorch, TensorFlow, JAX, XGBoost, PaddlePaddle, MPI (framework-specific)
- **Optional External**: Volcano (gang scheduling), Kueue (job queueing)
- **Platform Services**: Kubernetes API, Container Registry, cert-manager, PyPI
- **Internal ODH**: Model Registry, S3 Storage, MLFlow
- **Integrations**: Notebooks, Data Science Pipelines, Ray

## Updating Diagrams

To regenerate after architecture changes:
```bash
# From repository root
python scripts/generate_diagram_pngs.py architecture/odh-3.3.0/diagrams --width=3000
```

Or regenerate all diagrams from architecture markdown:
```bash
# Full regeneration (requires architecture documentation skill)
/generate-architecture-diagrams --architecture=architecture/odh-3.3.0/training-operator.md
```

## Related Components

- **Data Science Pipelines**: Orchestrates training jobs as pipeline steps
- **Notebooks**: Provides interactive environment for job submission
- **Model Registry**: Stores trained model metadata
- **Ray**: Coordinates hybrid distributed workloads
- **S3 Storage**: Persistent storage for datasets, checkpoints, and models
