# Architecture Diagrams for Kubeflow Trainer

Generated from: `architecture/rhoai-3.3.0/trainer.md`
Date: 2026-03-14

**Note**: Diagram filenames use base component name without version (directory is already versioned).

## Available Diagrams

All Mermaid diagrams are available in both `.mmd` (source) and `.png` (3000px width, high-resolution) formats.

### For Developers
- [Component Structure](./trainer-component.png) ([mmd](./trainer-component.mmd)) - Mermaid diagram showing internal components, controllers, and RHOAI extensions
- [Data Flows](./trainer-dataflow.png) ([mmd](./trainer-dataflow.mmd)) - Sequence diagram of TrainJob creation, training execution, progression tracking, and gang scheduling
- [Dependencies](./trainer-dependencies.png) ([mmd](./trainer-dependencies.mmd)) - Component dependency graph showing JobSet, Volcano, and RHOAI integrations

### For Architects
- [C4 Context](./trainer-c4-context.dsl) - System context in C4 format (Structurizr) showing Trainer in the broader ML platform ecosystem
- [Component Overview](./trainer-component.png) ([mmd](./trainer-component.mmd)) - High-level component view with controllers and extensions

### For Security Teams
- [Security Network Diagram (PNG)](./trainer-security-network.png) - High-resolution network topology
- [Security Network Diagram (Mermaid)](./trainer-security-network.mmd) - Visual network topology (editable)
- [Security Network Diagram (ASCII)](./trainer-security-network.txt) - Precise text format for SAR submissions
- [RBAC Visualization](./trainer-rbac.png) ([mmd](./trainer-rbac.mmd)) - RBAC permissions and bindings for controller service account

## Component Overview

**Kubeflow Trainer** is a Kubernetes operator for distributed machine learning training and LLM fine-tuning. It provides:

- **TrainJob CRD**: Declarative API for defining training jobs with dataset, model, trainer config
- **TrainingRuntime**: Reusable runtime templates (PyTorch, DeepSpeed, MLX, TensorFlow)
- **Gang Scheduling**: Integration with Volcano/Coscheduling for all-or-nothing pod scheduling
- **RHOAI Extensions**:
  - **Progression Tracking**: Real-time metrics polling from training pods (HTTP/28080)
  - **Network Policy Management**: Auto-created NetworkPolicies to isolate training workloads

Key integrations:
- **JobSet v0.10.1** (required): Creates sets of Jobs for multi-node distributed training
- **Volcano/Coscheduling** (optional): Gang scheduling for resource deadlock prevention
- **Kueue** (optional): Multi-cluster job queueing
- **OpenShift Monitoring** (RHOAI): PodMonitor for controller metrics

## Security Highlights

### Network Policies (RHOAI Extension)
Each TrainJob gets an auto-created NetworkPolicy that:
- Allows inter-pod communication within the same JobSet (NCCL, MPI)
- Restricts metrics endpoint (28080/TCP) to controller pods only
- Isolates training workloads from other namespaces

### RBAC
- **ServiceAccount**: `kubeflow-trainer-controller-manager` (opendatahub namespace)
- **ClusterRole**: Manages TrainJob, TrainingRuntime, ClusterTrainingRuntime CRDs
- **Permissions**:
  - Creates JobSets, PodGroups, NetworkPolicies
  - Gets/lists pods for progression tracking (RHOAI)
  - Manages secrets, configmaps, events

### Secrets
- `kubeflow-trainer-webhook-cert` (kubernetes.io/tls): Webhook TLS cert, auto-rotated by cert-controller
- User-provided secrets: AWS credentials, HuggingFace tokens, SSH keys

## Data Flows

### 1. TrainJob Creation
User → API Server → Validating Webhook → TrainJob Controller → JobSet created

### 2. Training Execution
JobSet Controller → Training Pods scheduled → Download models from S3/HF → Distributed training with NCCL/MPI → Upload checkpoints to S3

### 3. Progression Tracking (RHOAI)
Controller lists pods → HTTP GET to pod /metrics (28080/TCP) → Update TrainJob annotation with progress

### 4. Gang Scheduling
Controller creates PodGroup → Scheduler watches PodGroup → All pods scheduled atomically (all-or-nothing)

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
python scripts/generate_diagram_pngs.py architecture/rhoai-3.3.0/diagrams --width=3000
```

Or regenerate from architecture markdown:
```bash
# Run the full diagram generation workflow
# (This would require the diagram generation skill/tool)
```

## Training Runtimes (RHOAI)

Built-in ClusterTrainingRuntimes:
- **torch-distributed**: PyTorch with CUDA 12.8 (NVIDIA GPUs)
- **torch-distributed-rocm**: PyTorch with ROCm 6.4 (AMD GPUs)
- **training-hub**: PyTorch + HuggingFace Transformers for LLM fine-tuning
- **deepspeed-distributed**: DeepSpeed for memory-efficient large model training
- **mlx-distributed**: MLX for Apple Silicon M-series GPUs

## RHOAI-Specific Features

### Progression Tracking
- **Annotation**: `trainer.opendatahub.io/progression-tracking: enabled`
- **Metrics Port**: `trainer.opendatahub.io/metrics-port` (default: 28080)
- **Poll Interval**: `trainer.opendatahub.io/metrics-poll-interval` (default: 30s)
- **Status**: Controller writes progress to `trainer.opendatahub.io/trainerStatus` annotation

Expected metrics format (served by user training code):
```json
{
  "progressPercentage": 45,
  "currentStep": 450,
  "totalSteps": 1000,
  "trainMetrics": {
    "loss": 0.235,
    "accuracy": 0.89
  }
}
```

### Network Isolation
Auto-created NetworkPolicy per TrainJob:
- Allows same-JobSet pod communication (all ports for NCCL/MPI)
- Allows controller access to metrics endpoint (28080/TCP)
- Denies all other ingress traffic

## References

- **Architecture Doc**: `architecture/rhoai-3.3.0/trainer.md`
- **Repository**: https://github.com/red-hat-data-services/trainer.git
- **Upstream**: Kubeflow Trainer v2.1.0
- **Branch**: rhoai-3.3
- **Namespace**: opendatahub (controller), user-namespaces (training pods)
