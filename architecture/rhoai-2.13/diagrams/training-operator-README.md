# Architecture Diagrams for Training Operator

Generated from: `architecture/rhoai-2.13/training-operator.md`
Date: 2026-03-15

**Note**: Diagram filenames use base component name without version (directory is already versioned).

## Available Diagrams

All Mermaid diagrams are available in both `.mmd` (source) and `.png` (3000px width, high-resolution) formats.

### For Developers
- [Component Structure](./training-operator-component.png) ([mmd](./training-operator-component.mmd)) - Mermaid diagram showing internal components (PyTorch, TensorFlow, MPI, XGBoost, MXNet, PaddlePaddle controllers)
- [Data Flows](./training-operator-dataflow.png) ([mmd](./training-operator-dataflow.mmd)) - Sequence diagram of training job creation, distributed communication, and metrics collection
- [Dependencies](./training-operator-dependencies.png) ([mmd](./training-operator-dependencies.mmd)) - Component dependency graph showing framework support and integrations

### For Architects
- [C4 Context](./training-operator-c4-context.dsl) - System context in C4 format (Structurizr) showing operator in broader ML ecosystem
- [Component Overview](./training-operator-component.png) ([mmd](./training-operator-component.mmd)) - High-level component view with all framework controllers

### For Security Teams
- [Security Network Diagram (PNG)](./training-operator-security-network.png) - High-resolution network topology with trust zones
- [Security Network Diagram (Mermaid)](./training-operator-security-network.mmd) - Visual network topology (editable)
- [Security Network Diagram (ASCII)](./training-operator-security-network.txt) - Precise text format for SAR submissions with RBAC details
- [RBAC Visualization](./training-operator-rbac.png) ([mmd](./training-operator-rbac.mmd)) - ClusterRoles, bindings, and permissions for operator and user access

## Component Overview

The **Kubeflow Training Operator** is a Kubernetes-native operator that enables distributed training of ML models across six frameworks:

- **PyTorch** - Distributed PyTorch training with master/worker topology
- **TensorFlow** - TensorFlow training with parameter server/worker architecture
- **MPI** - MPI-based training with launcher/worker setup
- **XGBoost** - Distributed XGBoost training
- **MXNet** - MXNet training with scheduler/server/worker topology
- **PaddlePaddle** - PaddlePaddle distributed training

### Key Features
- **Multi-framework support** - 6 ML frameworks with dedicated controllers
- **Python SDK** - High-level TrainingClient API (`kubeflow-training 1.7.0`)
- **Gang scheduling** - Optional integration with Volcano or scheduler-plugins
- **Elastic training** - PyTorch elastic training support
- **HPA support** - Horizontal pod autoscaling for training workloads

### Security Highlights
- Non-root execution (UID 65532)
- FIPS compliance (strictfipsruntime tag)
- Istio sidecar disabled (operator doesn't need service mesh)
- Least-privilege RBAC with cluster-scoped permissions
- No privilege escalation

### Known Limitations
- Inter-worker communication not encrypted by default (framework-dependent)
- No authentication between training pods (framework-dependent)
- Metrics endpoint is HTTP, not HTTPS
- Single replica operator (no leader election)

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
   PUPPETEER_EXECUTABLE_PATH=/usr/bin/google-chrome mmdc -i training-operator-component.mmd -o training-operator-component.png -w 3000
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
- **CLI export**: `structurizr-cli export -workspace training-operator-c4-context.dsl -format png`

### ASCII Diagrams (.txt files)
- View in any text editor
- Include in documentation as-is
- Perfect for security reviews (precise technical details, RBAC summary)

## Updating Diagrams

To regenerate after architecture changes:
```bash
# From repository root
python scripts/generate_diagram_pngs.py architecture/rhoai-2.13/diagrams --width=3000
```

## Integration with Other Components

The Training Operator integrates with:

- **Kubernetes API** - Core orchestration (watches CRDs, creates pods/services)
- **Prometheus** - Operator metrics collection via PodMonitor
- **Volcano Scheduler** - Optional gang scheduling for all-or-nothing pod scheduling
- **Scheduler Plugins** - Alternative gang scheduling implementation
- **Object Storage** - Training jobs access S3/etc for datasets and checkpoints
- **Container Registries** - Pull training framework images

## Python SDK Example

```python
from kubeflow.training import TrainingClient

# Create client
client = TrainingClient()

# Create PyTorch training job
client.create_pytorchjob(
    name="pytorch-distributed",
    namespace="my-namespace",
    master_replicas=1,
    worker_replicas=3,
    container_image="pytorch/pytorch:latest",
    command=["python", "train.py"]
)

# Monitor job status
client.wait_for_job("pytorch-distributed", namespace="my-namespace")
```

## Framework-Specific Details

### PyTorch
- Default port: 23456/TCP
- Master/worker topology
- PyTorch init container for environment setup
- Elastic training support

### TensorFlow
- Parameter server/worker architecture
- Supports TF distributed strategies

### MPI
- Launcher/worker topology
- kubectl-delivery init container for MPI orchestration
- SSH or MPI transport for inter-worker communication

### Gang Scheduling
- Prevents resource deadlocks in multi-tenant clusters
- Ensures all pods scheduled together or not at all
- Supports both Volcano and scheduler-plugins

## References

- **Repository**: https://github.com/red-hat-data-services/training-operator
- **Upstream**: https://github.com/kubeflow/training-operator
- **Documentation**: https://www.kubeflow.org/docs/components/training/
- **Python SDK**: https://pypi.org/project/kubeflow-training/
