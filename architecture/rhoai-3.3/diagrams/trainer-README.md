# Architecture Diagrams for Kubeflow Trainer

Generated from: `architecture/rhoai-3.3/trainer.md`
Date: 2026-03-15
Component: **trainer** (Kubeflow Trainer - Distributed ML Training and LLM Fine-tuning Operator)

**Note**: Diagram filenames use base component name without version (directory is already versioned).

## Available Diagrams

All Mermaid diagrams are available in both `.mmd` (source) and `.png` (3000px width, high-resolution) formats.

### For Developers
- [Component Structure](./trainer-component.png) ([mmd](./trainer-component.mmd)) - Mermaid diagram showing internal components, controllers, and RHOAI extensions
- [Data Flows](./trainer-dataflow.png) ([mmd](./trainer-dataflow.mmd)) - Sequence diagram of TrainJob creation, training execution, and progression tracking flows
- [Dependencies](./trainer-dependencies.png) ([mmd](./trainer-dependencies.mmd)) - Component dependency graph showing JobSet, Volcano, and built-in training runtimes

### For Architects
- [C4 Context](./trainer-c4-context.dsl) - System context in C4 format (Structurizr) showing Trainer in the broader ML ecosystem
- [Component Overview](./trainer-component.png) ([mmd](./trainer-component.mmd)) - High-level component view with operator, controllers, and extensions

### For Security Teams
- [Security Network Diagram (PNG)](./trainer-security-network.png) - High-resolution network topology with trust zones
- [Security Network Diagram (Mermaid)](./trainer-security-network.mmd) - Visual network topology (editable)
- [Security Network Diagram (ASCII)](./trainer-security-network.txt) - Precise text format for SAR submissions
- [RBAC Visualization](./trainer-rbac.png) ([mmd](./trainer-rbac.mmd)) - RBAC permissions, ClusterRole, and API resource access

## Component Overview

**Kubeflow Trainer** is a Kubernetes-native operator for distributed machine learning training and large language model (LLM) fine-tuning. It provides:

- **Declarative Training API**: Define training jobs through TrainJob custom resources
- **Reusable Runtime Templates**: TrainingRuntime and ClusterTrainingRuntime for framework configurations
- **Multi-Framework Support**: PyTorch, JAX, TensorFlow, DeepSpeed, and MLX
- **Distributed Training**: JobSet integration for multi-node training with gang scheduling
- **RHOAI Extensions**:
  - **Progression Tracking**: Real-time metrics polling from training pods
  - **Network Isolation**: Automatic NetworkPolicy creation for pod security

## Key Architecture Highlights

### Controllers
- **TrainJob Controller**: Creates JobSets from TrainJobs, manages training lifecycle
- **TrainingRuntime Controller**: Watches runtime templates (namespaced)
- **ClusterTrainingRuntime Controller**: Watches cluster-scoped runtime templates
- **Validating Webhooks**: Validates TrainJob and runtime resources on CREATE/UPDATE

### RHOAI Extensions
- **Progression Tracker**: Polls HTTP metrics from training pods (port 28080) every 30s for real-time training progress
- **Network Policy Manager**: Creates NetworkPolicies to isolate training pods and secure metrics endpoints

### Built-in Training Runtimes (RHOAI)
- `torch-distributed`: PyTorch with CUDA 12.8 (NVIDIA GPUs)
- `torch-distributed-rocm`: PyTorch with ROCm 6.4 (AMD GPUs)
- `training-hub`: PyTorch + HuggingFace Transformers (LLM fine-tuning)
- `deepspeed-distributed`: DeepSpeed for memory-efficient training
- `mlx-distributed`: Apple Silicon (M-series GPUs)

### Security Features
- **Validating Webhooks**: mTLS authentication from Kubernetes API Server (port 9443)
- **NetworkPolicy Isolation**: Training pods restricted to same-JobSet communication and controller metrics access
- **Gang Scheduling**: Volcano or Coscheduling Plugin for all-or-nothing pod scheduling (prevents resource deadlock)
- **TLS Metrics**: Controller metrics exposed via HTTPS (port 8080) with PodMonitor

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
   PUPPETEER_EXECUTABLE_PATH=/usr/bin/google-chrome mmdc -i trainer-component.mmd -o trainer-component.png -w 3000
   ```

3. **Alternative formats** (if needed):
   ```bash
   # SVG (vector, scales perfectly)
   PUPPETEER_EXECUTABLE_PATH=/usr/bin/google-chrome mmdc -i trainer-component.mmd -o trainer-component.svg

   # PDF
   PUPPETEER_EXECUTABLE_PATH=/usr/bin/google-chrome mmdc -i trainer-component.mmd -o trainer-component.pdf
   ```

**Note**: If `google-chrome` is not found, try `chromium` or `which google-chrome` to locate it

### C4 Diagrams (.dsl files)
- **Structurizr Lite**:
  ```bash
  docker run -p 8080:8080 -v $(pwd):/usr/local/structurizr structurizr/lite
  ```
  Then open http://localhost:8080 and load `trainer-c4-context.dsl`
- **CLI export**:
  ```bash
  structurizr-cli export -workspace trainer-c4-context.dsl -format png
  ```

### ASCII Diagrams (.txt files)
- View in any text editor
- Include in documentation as-is
- Perfect for security reviews (precise technical details)

## Diagram Details

### 1. Component Structure (`trainer-component.mmd/.png`)
Shows the internal architecture of Kubeflow Trainer:
- **Controllers**: TrainJob, TrainingRuntime, ClusterTrainingRuntime reconcilers
- **RHOAI Extensions**: Progression Tracker (metrics polling), Network Policy Manager
- **Custom Resources**: TrainJob, TrainingRuntime, ClusterTrainingRuntime CRDs
- **Created Resources**: JobSet, PodGroup (gang scheduling), NetworkPolicy, Training Pods
- **External Dependencies**: JobSet Controller, Volcano Scheduler, Prometheus, Kueue

### 2. Data Flow Sequences (`trainer-dataflow.mmd/.png`)
Four key flows:
1. **TrainJob Creation**: User creates TrainJob → Webhook validation → Controller creates JobSet + PodGroup + NetworkPolicy
2. **Training Execution**: JobSet Controller creates pods → Gang scheduling → Inter-pod communication (NCCL/MPI) → Dataset/model download from S3/HuggingFace
3. **Progression Tracking (RHOAI)**: Controller polls training pod metrics (HTTP/28080) every 30s → Updates TrainJob annotation with real-time progress
4. **Completion**: Training pods save checkpoints → Job completes → TrainJob status updated

### 3. Security Network Diagram (`trainer-security-network.txt/.mmd/.png`)
Detailed network topology with trust zones:
- **External**: Data Scientist → Kubernetes API Server (HTTPS/6443 TLS 1.3)
- **Control Plane**: API Server → Validating Webhook (HTTPS/9443 mTLS)
- **Opendatahub Namespace**: Controller components (webhook, health, metrics, progression tracker)
- **User Namespace**: Training pods (launcher + workers) with NetworkPolicy isolation
- **External Services**: S3 Storage, HuggingFace Hub (HTTPS/443 with AWS IAM or HF Token)

**NetworkPolicy Isolation**:
- Training pods can communicate with same-JobSet pods (all ports for NCCL/MPI/gRPC)
- Controller can access training pod metrics (port 28080)
- All other traffic blocked

### 4. C4 Context Diagram (`trainer-c4-context.dsl`)
System context showing Kubeflow Trainer in the broader ecosystem:
- **Users**: Data Scientists creating distributed training jobs
- **External Dependencies**: Kubernetes API, JobSet Controller, Volcano Scheduler (gang scheduling)
- **Internal ODH**: Kueue (queue management), Prometheus (monitoring), Service Mesh (secure comms)
- **External Services**: S3 Storage, HuggingFace Hub (datasets and models)
- **RHOAI Extensions**: Progression Tracking, Network Policy Management

### 5. Dependency Graph (`trainer-dependencies.mmd/.png`)
Shows all component dependencies:
- **Required External**: Kubernetes v1.34.1, JobSet v0.10.1
- **Optional External**: Volcano Scheduler v1.13.1, Coscheduling Plugin, LeaderWorkerSet, Prometheus Operator
- **Internal ODH**: Kueue, Service Mesh, OpenShift Monitoring
- **External Services**: S3, HuggingFace Hub, GCS, PVCs
- **Built-in Runtimes**: torch-distributed (CUDA/ROCm), training-hub, deepspeed-distributed, mlx-distributed

### 6. RBAC Visualization (`trainer-rbac.mmd/.png`)
Visualizes RBAC permissions:
- **ServiceAccount**: `kubeflow-trainer-controller-manager` (opendatahub namespace)
- **ClusterRole**: Permissions across multiple API groups:
  - **Core**: ConfigMaps, Secrets, Events, LimitRanges, Pods (RHOAI)
  - **Admission**: ValidatingWebhookConfigurations
  - **JobSet**: JobSets (create, manage)
  - **Scheduling**: PodGroups (Volcano/Coscheduling)
  - **Trainer**: TrainJobs, TrainingRuntimes, ClusterTrainingRuntimes
  - **Networking (RHOAI)**: NetworkPolicies (create, manage)
- **ClusterRoleBinding**: Grants ClusterRole to ServiceAccount cluster-wide

## Integration with RHOAI Ecosystem

### Progression Tracking (RHOAI Extension)
- **Metrics Endpoint**: Training pods expose `/metrics` on port 28080 (HTTP)
- **Poll Interval**: Configurable via `trainer.opendatahub.io/metrics-poll-interval` (default 30s)
- **Status Annotation**: Controller writes real-time progress to `trainer.opendatahub.io/trainerStatus`
- **Expected Metrics Format**:
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
- **NetworkPolicy**: Auto-created to restrict metrics endpoint to controller pods only

### Built-in Training Runtimes
RHOAI provides pre-configured ClusterTrainingRuntimess for common use cases:
- **torch-distributed**: PyTorch with torchrun, CUDA 12.8, NVIDIA GPUs
- **torch-distributed-rocm**: PyTorch with torchrun, ROCm 6.4, AMD GPUs
- **training-hub**: PyTorch + HuggingFace Transformers for LLM fine-tuning
- **deepspeed-distributed**: DeepSpeed for memory-efficient large model training
- **mlx-distributed**: MLX framework for Apple Silicon (M-series GPUs)

### Gang Scheduling
- **Volcano Scheduler** or **Coscheduling Plugin** required for multi-node training
- **PodGroup** created per TrainJob for all-or-nothing scheduling
- Prevents resource deadlock when training requires multiple nodes

## Updating Diagrams

To regenerate after architecture changes:
```bash
# From repository root
python scripts/generate_architecture_diagrams.py --architecture=architecture/rhoai-3.3/trainer.md
```

Or regenerate all diagrams for RHOAI 3.3:
```bash
python scripts/generate_architecture_diagrams.py --version=rhoai-3.3
```

## Related Documentation

- **Architecture Source**: [trainer.md](../trainer.md)
- **Platform Architecture**: [PLATFORM.md](../PLATFORM.md)
- **Other Components**: See [README.md](../README.md) for all RHOAI 3.3 components

## Example TrainJob

```yaml
apiVersion: trainer.kubeflow.org/v1alpha1
kind: TrainJob
metadata:
  name: llama-finetune
  annotations:
    trainer.opendatahub.io/progression-tracking: "enabled"
    trainer.opendatahub.io/metrics-port: "28080"
spec:
  runtimeRef:
    name: torch-distributed
    kind: ClusterTrainingRuntime
  initializer:
    dataset:
      storageUri: "hf://datasets/my-dataset"
      secretRef:
        name: hf-token
    model:
      storageUri: "hf://meta-llama/Llama-3.2-1B"
      secretRef:
        name: hf-token
  trainer:
    image: quay.io/opendatahub/odh-training-cuda128-torch29-py312
    numNodes: 2
    resourcesPerNode:
      requests:
        nvidia.com/gpu: 1
      limits:
        nvidia.com/gpu: 1
    numProcPerNode: 1
    command:
      - torchrun
      - train.py
    args:
      - --epochs=10
      - --batch-size=32
```

## Notes

- **Upstream Alignment**: RHOAI tracks Kubeflow Trainer v2.1.0 with RHOAI-specific extensions
- **Konflux CI/CD**: All container images built via Konflux pipelines
- **JobSet Dependency**: Critical for multi-node training; bundled in RHOAI manifests
- **Network Isolation**: NetworkPolicies ensure training pods only communicate with same-job pods and controller
- **Gang Scheduling**: Optional but recommended for multi-node training to avoid resource deadlock
- **Python SDK**: Users can create TrainJobs via `kubeflow-sdk` Python library
- **Storage Integration**: Supports S3, GCS, HuggingFace Hub, and PVCs for datasets and models
- **GPU Support**: CUDA (NVIDIA), ROCm (AMD), and MLX (Apple Silicon) runtimes available
