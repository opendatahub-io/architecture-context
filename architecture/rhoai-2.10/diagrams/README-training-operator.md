# Architecture Diagrams for Training Operator

Generated from: `architecture/rhoai-2.10/training-operator.md`
Date: 2026-03-15

**Note**: Diagram filenames use base component name without version (directory is already versioned).

## Available Diagrams

All Mermaid diagrams are available in both `.mmd` (source) and `.png` (3000px width, high-resolution) formats.

### For Developers
- [Component Structure](./training-operator-component.png) ([mmd](./training-operator-component.mmd)) - Mermaid diagram showing internal components and sub-controllers
- [Data Flows](./training-operator-dataflow.png) ([mmd](./training-operator-dataflow.mmd)) - Sequence diagram of training job submission and execution flows
- [Dependencies](./training-operator-dependencies.png) ([mmd](./training-operator-dependencies.mmd)) - Component dependency graph including gang schedulers

### For Architects
- [C4 Context](./training-operator-c4-context.dsl) - System context in C4 format (Structurizr)
- [Component Overview](./training-operator-component.png) ([mmd](./training-operator-component.mmd)) - High-level component view with all framework controllers

### For Security Teams
- [Security Network Diagram (PNG)](./training-operator-security-network.png) - High-resolution network topology
- [Security Network Diagram (Mermaid)](./training-operator-security-network.mmd) - Visual network topology (editable)
- [Security Network Diagram (ASCII)](./training-operator-security-network.txt) - Precise text format for SAR submissions
- [RBAC Visualization](./training-operator-rbac.png) ([mmd](./training-operator-rbac.mmd)) - RBAC permissions and bindings

## Component Overview

The **Kubeflow Training Operator** is a unified Kubernetes operator that orchestrates distributed training workloads for multiple machine learning frameworks including PyTorch, TensorFlow, XGBoost, MPI, MXNet, and PaddlePaddle.

### Key Features
- **Multi-Framework Support**: PyTorch, TensorFlow, MPI, XGBoost, MXNet, PaddlePaddle
- **Elastic Training**: PyTorchJob supports dynamic scaling with HPA integration
- **Gang Scheduling**: Integrates with scheduler-plugins (default) or Volcano for all-or-nothing pod scheduling
- **Python SDK**: TrainingClient API for programmatic job management
- **Job Lifecycle**: Suspend/resume, configurable restart policies, status tracking

### Network Endpoints
- **Metrics**: `8080/TCP HTTP` - Prometheus metrics (no auth, ClusterIP only)
- **Health Probes**: `8081/TCP HTTP` - Liveness and readiness checks
- **Webhook**: `9443/TCP HTTPS` - Admission webhook for CRD validation

### Security Highlights
- Runs as non-root user (UID: 65532)
- Istio sidecar injection disabled on operator pods
- Fine-grained RBAC with cluster-scoped permissions
- TLS 1.2+ for all external communication
- FIPS-compliant builds for RHOAI

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
Shows the Training Operator's internal architecture:
- Main controller with sub-controllers for each framework (PyTorch, TensorFlow, MPI, XGBoost, MXNet, PaddlePaddle)
- Webhook server for CRD validation
- Python SDK integration
- CRD lifecycle management
- External dependencies (Kubernetes, gang schedulers, Prometheus)

### Data Flow Diagram
Illustrates the complete lifecycle of a training job:
1. **Job Submission**: User submits via kubectl/SDK → Kubernetes API → Webhook validation
2. **Job Reconciliation**: Operator creates PodGroup and worker pods
3. **Gang Scheduling**: scheduler-plugins ensures all-or-nothing scheduling
4. **Distributed Training**: Workers communicate via framework-specific protocols
5. **Metrics Collection**: Prometheus scrapes operator metrics
6. **Job Completion**: Status updates and event generation

### Security Network Diagram
Provides detailed network topology with security controls:
- **ASCII version**: Precise text format for Security Architecture Reviews (SAR)
- **Mermaid/PNG version**: Visual representation with color-coded trust zones
- Shows all ports, protocols, encryption (TLS versions), and authentication mechanisms
- Includes RBAC summary, service mesh configuration, and secrets management
- Details framework-specific communication patterns (PyTorch torchrun, TensorFlow gRPC, MPI SSH)

### Dependencies Diagram
Maps all component dependencies:
- **Required**: Kubernetes 1.25+, controller-runtime v0.14.0+
- **Optional**: scheduler-plugins (default), Volcano, Prometheus Operator, Istio
- **Internal RHOAI**: ODH Dashboard, Prometheus, Service Mesh
- **CRDs**: All 6 training job types (PyTorchJob, TFJob, MPIJob, XGBoostJob, MXJob, PaddleJob)

### RBAC Diagram
Visualizes permission model:
- ServiceAccount: `training-operator` (namespace: opendatahub)
- ClusterRole: `training-operator` with permissions for pods, services, CRDs, PodGroups
- User roles: `training-edit` (create/manage) and `training-view` (read-only)
- Shows granular permissions for each API resource

### C4 Context Diagram
Provides architectural context:
- System context: Training Operator in the broader RHOAI ecosystem
- Container view: Main controller, sub-controllers, webhook, SDK, metrics exporter
- Component view: Individual framework controllers
- Relationships with Kubernetes, gang schedulers, Prometheus, ODH Dashboard

## Updating Diagrams

To regenerate after architecture changes:
```bash
# From repository root
cd /home/jtanner/workspace/github/jctanner.redhat/2026_03_12_arch_diagrams/kahowell.rhoai-architecture-diagrams

# Regenerate diagrams (updates both .mmd and .png files)
# (Assuming you have a diagram generation tool/skill)
# Example command structure - adjust based on your tooling:
# ./generate-diagrams.sh architecture/rhoai-2.10/training-operator.md
```

## Related Documentation

- Architecture file: [../training-operator.md](../training-operator.md)
- Component repository: https://github.com/red-hat-data-services/training-operator
- Version: 78eedd82 (rhoai-2.10 branch)
- Distribution: RHOAI

## Framework-Specific Details

### PyTorch Jobs
- **Controller**: PyTorch controller with elastic training support
- **Communication**: torchrun protocol on dynamic ports
- **Env vars**: MASTER_ADDR, MASTER_PORT, RANK, WORLD_SIZE
- **Features**: HPA integration for auto-scaling

### TensorFlow Jobs
- **Controller**: TensorFlow controller with parameter server architecture
- **Communication**: gRPC on port 2222/TCP
- **Roles**: chief, ps (parameter server), worker, evaluator
- **Env vars**: TF_CONFIG

### MPI Jobs
- **Controller**: MPI controller with launcher/worker pattern
- **Communication**: SSH (port 2222/TCP) + MPI protocol
- **Init container**: kubectl-delivery copies kubectl to workers
- **Auth**: SSH keys auto-generated per job

### XGBoost Jobs
- **Controller**: XGBoost controller
- **Architecture**: Master/worker
- **Communication**: Framework-specific

### MXNet Jobs
- **Controller**: MXNet controller
- **Architecture**: Scheduler/server/worker
- **Communication**: Framework-specific

### PaddlePaddle Jobs
- **Controller**: PaddlePaddle controller
- **Architecture**: Distributed training
- **Communication**: Framework-specific

## Support

For issues or questions:
- File issues in the component repository
- Consult the architecture documentation
- Contact the RHOAI architecture team
