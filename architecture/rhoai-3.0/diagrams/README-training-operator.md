# Architecture Diagrams for Kubeflow Training Operator

Generated from: `architecture/rhoai-3.0/training-operator.md`
Date: 2026-03-16

**Note**: Diagram filenames use base component name without version (directory is already versioned).

## Available Diagrams

All Mermaid diagrams are available in both `.mmd` (source) and `.png` (3000px width, high-resolution) formats.

### For Developers
- [Component Structure](./training-operator-component.png) ([mmd](./training-operator-component.mmd)) - Mermaid diagram showing internal components, job controllers, validation webhooks
- [Data Flows](./training-operator-dataflow.png) ([mmd](./training-operator-dataflow.mmd)) - Sequence diagram of training job creation, execution, and monitoring flows
- [Dependencies](./training-operator-dependencies.png) ([mmd](./training-operator-dependencies.mmd)) - Component dependency graph showing external/internal dependencies and created resources

### For Architects
- [C4 Context](./training-operator-c4-context.dsl) - System context in C4 format (Structurizr)
- [Component Overview](./training-operator-component.png) ([mmd](./training-operator-component.mmd)) - High-level component view with 6 framework-specific controllers

### For Security Teams
- [Security Network Diagram (PNG)](./training-operator-security-network.png) - High-resolution network topology
- [Security Network Diagram (Mermaid)](./training-operator-security-network.mmd) - Visual network topology (editable)
- [Security Network Diagram (ASCII)](./training-operator-security-network.txt) - Precise text format for SAR submissions
- [RBAC Visualization](./training-operator-rbac.png) ([mmd](./training-operator-rbac.mmd)) - RBAC permissions and bindings for operator and user-facing roles

## Component Overview

**Kubeflow Training Operator** is a Kubernetes-native operator for distributed machine learning training across multiple frameworks:
- **PyTorch**: Distributed training with elastic scaling support
- **TensorFlow**: Parameter server/worker topology
- **MPI**: HPC and distributed training workloads
- **XGBoost**: Distributed gradient boosting
- **JAX**: Distributed neural network training
- **PaddlePaddle**: PaddlePaddle framework support

### Key Features
- **6 Framework Controllers**: Dedicated reconcilers for PyTorch, TensorFlow, MPI, XGBoost, JAX, PaddlePaddle
- **Validation Webhooks**: Pre-admission validation for all job types (9443/TCP HTTPS mTLS)
- **Gang Scheduling**: Optional integration with Volcano or scheduler-plugins for all-or-nothing pod scheduling
- **Elastic Training**: HPA integration for PyTorch jobs with autoscaling capabilities
- **Python SDK**: `kubeflow-training` PyPI package for programmatic job creation

### Security Highlights
- **Non-root user**: UID 65532
- **FIPS-compliant**: Built with `GOEXPERIMENT=strictfipsruntime`
- **Webhook mTLS**: 9443/TCP HTTPS TLS 1.2+ with client certificate validation
- **RBAC**: ClusterRole with granular permissions for CRDs, pods, services, secrets
- **Read-only filesystem**: Certificates mounted read-only

### Network Architecture
- **Operator → K8s API**: 6443/TCP HTTPS (ServiceAccount Token)
- **K8s API → Webhooks**: 9443/TCP HTTPS mTLS (validation)
- **Prometheus → Metrics**: 8080/TCP HTTP (scraping)
- **Training Pods**: 23456/TCP (default PyTorch inter-pod communication, unencrypted)
- **Training Pods → S3**: 443/TCP HTTPS (datasets/checkpoints)

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
python scripts/generate_diagram_pngs.py architecture/rhoai-3.0/diagrams --width=3000
```

## Technical Details

### Training Job Lifecycle
1. **Submission**: User creates job CRD via kubectl or Python SDK
2. **Validation**: Webhook validates job spec (9443/TCP HTTPS mTLS)
3. **Reconciliation**: Controller creates PodGroup (optional gang scheduling)
4. **Pod Creation**: Master + worker pods created with framework-specific init containers
5. **Service Creation**: ClusterIP services for pod discovery (23456/TCP)
6. **Training Execution**: Distributed training with inter-pod communication
7. **Monitoring**: Controller updates job status, Prometheus scrapes metrics
8. **Completion**: Job marked Succeeded/Failed, cleanup after TTL

### Custom Resource Definitions
- `PyTorchJob` (kubeflow.org/v1) - PyTorch distributed training
- `TFJob` (kubeflow.org/v1) - TensorFlow training
- `MPIJob` (kubeflow.org/v1) - MPI-based training/HPC
- `XGBoostJob` (kubeflow.org/v1) - XGBoost distributed training
- `JAXJob` (kubeflow.org/v1) - JAX distributed training
- `PaddleJob` (kubeflow.org/v1) - PaddlePaddle training

### RBAC Summary
- **ClusterRole**: `training-operator` (operator ServiceAccount)
  - Full CRUD on all training job CRDs (`kubeflow.org`)
  - Pod/service/configmap/secret management
  - HPA creation (elastic training)
  - PodGroup creation (gang scheduling)
  - NetworkPolicy management

- **ClusterRole**: `training-edit` (user-facing)
  - Create/edit training jobs
  - Read job status

- **ClusterRole**: `training-view` (user-facing)
  - Read-only access to training jobs

### Dependencies
**Required**:
- Kubernetes 1.27+

**Optional**:
- cert-manager (webhook certificate automation)
- Volcano Scheduler (gang scheduling)
- scheduler-plugins (alternative gang scheduling)
- Prometheus (metrics collection)

**Internal ODH**:
- opendatahub-operator (deployment)
- ODH Dashboard (UI integration)

## Related Documentation
- Source: [training-operator.md](../training-operator.md)
- Repository: https://github.com/red-hat-data-services/training-operator
- Version: 1.9.0 (RHOAI 3.0)
- Deployment: opendatahub namespace, kubeflow-training-operator ServiceAccount
