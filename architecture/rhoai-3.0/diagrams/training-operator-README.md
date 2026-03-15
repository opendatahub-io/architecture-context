# Architecture Diagrams for Training Operator

Generated from: `architecture/rhoai-3.0/training-operator.md`
Date: 2026-03-15
Component: training-operator

**Note**: Diagram filenames use base component name without version (directory is already versioned).

## Available Diagrams

All Mermaid diagrams are available in both `.mmd` (source) and `.png` (3000px width, high-resolution) formats.

### For Developers
- [Component Structure](./training-operator-component.png) ([mmd](./training-operator-component.mmd)) - Mermaid diagram showing internal components (controller manager, reconcilers, webhooks)
- [Data Flows](./training-operator-dataflow.png) ([mmd](./training-operator-dataflow.mmd)) - Sequence diagram of training job creation, execution, and monitoring flows
- [Dependencies](./training-operator-dependencies.png) ([mmd](./training-operator-dependencies.mmd)) - Component dependency graph showing Kubernetes, gang schedulers, and ODH integrations

### For Architects
- [C4 Context](./training-operator-c4-context.dsl) - System context in C4 format (Structurizr) showing Training Operator in broader ecosystem
- [Component Overview](./training-operator-component.png) ([mmd](./training-operator-component.mmd)) - High-level component view with CRD controllers

### For Security Teams
- [Security Network Diagram (PNG)](./training-operator-security-network.png) - High-resolution network topology with trust boundaries
- [Security Network Diagram (Mermaid)](./training-operator-security-network.mmd) - Visual network topology (editable)
- [Security Network Diagram (ASCII)](./training-operator-security-network.txt) - Precise text format for SAR submissions
- [RBAC Visualization](./training-operator-rbac.png) ([mmd](./training-operator-rbac.mmd)) - RBAC permissions and bindings for operator and user roles

## Component Summary

**Kubeflow Training Operator** - Kubernetes-native operator for distributed training of machine learning models across multiple frameworks (PyTorch, TensorFlow, JAX, XGBoost, MPI, PaddlePaddle).

**Key Features**:
- Multi-framework support (6 ML frameworks)
- Gang scheduling integration (Volcano/scheduler-plugins)
- PyTorch elastic training with autoscaling
- Validation webhooks for job specifications
- Python SDK for programmatic job management

**Deployment**: RHOAI 3.0 (namespace: opendatahub)

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
# Auto-regeneration (from architecture file location)
python scripts/generate_diagram_pngs.py architecture/rhoai-3.0/diagrams --width=3000
```

## Diagram Details

### 1. Component Structure Diagram
Shows the internal architecture of the Training Operator:
- Controller Manager with 6 framework-specific reconcilers
- Validation webhook server (mTLS-secured)
- CRD management for PyTorch, TensorFlow, MPI, XGBoost, JAX, PaddlePaddle jobs
- Resource creation (pods, services, PodGroups)

### 2. Data Flow Diagram
Illustrates the complete lifecycle of a training job:
- Job submission via kubectl/Python SDK
- Webhook validation (mTLS)
- Controller reconciliation
- Gang scheduling (optional with Volcano/scheduler-plugins)
- Pod creation and initialization
- Distributed training communication (TCP/23456)
- Model checkpoint storage (S3/object storage)
- Monitoring via Prometheus metrics

### 3. Security Network Diagram
Detailed network architecture for security reviews:
- **ASCII format**: Precise port/protocol/encryption details for SAR documentation
- **Mermaid format**: Visual representation with color-coded trust zones
- Trust boundaries: External → K8s API → Operator → Training Pods → External Services
- Authentication: kubeconfig, ServiceAccount tokens, mTLS, AWS IAM
- Encryption: TLS 1.2+ for API/webhooks, plaintext for inter-pod training communication

### 4. Dependency Graph
Shows all component dependencies:
- **Required**: Kubernetes 1.27+
- **Optional**: cert-manager, Volcano, scheduler-plugins, Prometheus
- **Internal ODH**: OpenDataHub Operator (deployment), ODH Dashboard (UI)
- **External Services**: Container registries, S3/object storage

### 5. RBAC Visualization
Visualizes Role-Based Access Control:
- **Operator ClusterRole** (`training-operator`): Manages all training job CRDs, pods, services, secrets
- **User Roles**: `training-edit` (create/manage jobs), `training-view` (read-only access)
- ServiceAccount: `kubeflow-training-operator` in `opendatahub` namespace
- Permissions for gang scheduling (PodGroups), autoscaling (HPA), networking

### 6. C4 Context Diagram
High-level system context showing:
- Data Scientist interactions
- Training Operator containers (Controller, Webhook, Python SDK)
- External dependencies (Kubernetes, Prometheus, Volcano, etc.)
- Internal ODH integrations (Operator, Dashboard)
- External services (container registries, S3 storage)

## Training Job Lifecycle

1. **Submission**: User creates job CRD via kubectl or Python SDK
2. **Validation**: Webhook validates job specification (replica counts, resource requests, etc.)
3. **Reconciliation**: Controller watches job, creates PodGroup (if gang scheduling enabled)
4. **Pod Creation**: Controller creates pods for each replica type (master/workers/parameter servers)
5. **Service Creation**: Controller creates headless services for pod discovery
6. **Initialization**: Init containers run (PyTorch: coordinate master selection, MPI: deliver kubectl)
7. **Training**: Main containers execute training code with framework-specific coordination
8. **Monitoring**: Controller updates job status based on pod states
9. **Completion**: Job marked as Succeeded when all pods complete successfully
10. **Cleanup**: Failed replicas restarted based on restart policy, job cleaned up after TTL

## Security Notes

- **Operator Security**: Non-root user (UID 65532), read-only filesystem, FIPS-compliant build
- **Webhook Authentication**: mTLS certificates validated by Kubernetes API Server
- **Metrics Endpoint**: No authentication (8080/TCP) - relies on cluster network isolation
- **Training Pod Communication**: Plaintext TCP (23456/TCP) - frameworks handle their own security
- **External Access**: HTTPS/TLS for container registries and S3 storage

## Integration Points

- **Kubernetes API Server**: REST API (watch CRDs, manage resources), Admission webhooks
- **Prometheus**: HTTP scrape on port 8080 for operator metrics
- **Volcano/scheduler-plugins**: CRD-based (PodGroup) for gang scheduling
- **Training Pods**: Service discovery for distributed communication (port 23456)
- **ODH Dashboard**: UI for viewing and managing training jobs
- **Python SDK**: `kubeflow-training` package for programmatic job creation

## Framework Support

| Framework | CRD | Topology | Notable Features |
|-----------|-----|----------|------------------|
| PyTorch | PyTorchJob | Master/Worker | Elastic training, HPA autoscaling, custom init containers |
| TensorFlow | TFJob | Parameter Server/Worker/Chief | Classic distributed TensorFlow |
| MPI | MPIJob | Launcher/Worker | HPC workloads, kubectl delivery |
| XGBoost | XGBoostJob | Master/Worker | Distributed gradient boosting |
| JAX | JAXJob | Worker | Distributed neural network training |
| PaddlePaddle | PaddleJob | Master/Worker | PaddlePaddle framework support |

## References

- **Repository**: https://github.com/red-hat-data-services/training-operator
- **Version**: v1.9.0 (RHOAI 3.0 branch)
- **Architecture Doc**: [training-operator.md](../training-operator.md)
- **Python SDK**: `kubeflow-training` on PyPI
