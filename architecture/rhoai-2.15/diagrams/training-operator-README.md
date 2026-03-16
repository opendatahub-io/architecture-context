# Architecture Diagrams for Training Operator

Generated from: `architecture/rhoai-2.15/training-operator.md`
Date: 2026-03-15

**Note**: Diagram filenames use base component name without version (directory is already versioned).

## Available Diagrams

All Mermaid diagrams are available in both `.mmd` (source) and `.png` (3000px width, high-resolution) formats.

### For Developers
- [Component Structure](./training-operator-component.png) ([mmd](./training-operator-component.mmd)) - Mermaid diagram showing internal components
- [Data Flows](./training-operator-dataflow.png) ([mmd](./training-operator-dataflow.mmd)) - Sequence diagram of request/response flows
- [Dependencies](./training-operator-dependencies.png) ([mmd](./training-operator-dependencies.mmd)) - Component dependency graph

### For Architects
- [C4 Context](./training-operator-c4-context.dsl) - System context in C4 format (Structurizr)
- [Component Overview](./training-operator-component.png) ([mmd](./training-operator-component.mmd)) - High-level component view

### For Security Teams
- [Security Network Diagram (PNG)](./training-operator-security-network.png) - High-resolution network topology
- [Security Network Diagram (Mermaid)](./training-operator-security-network.mmd) - Visual network topology (editable)
- [Security Network Diagram (ASCII)](./training-operator-security-network.txt) - Precise text format for SAR submissions
- [RBAC Visualization](./training-operator-rbac.png) ([mmd](./training-operator-rbac.mmd)) - RBAC permissions and bindings

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
/generate-architecture-diagrams --architecture=../training-operator.md
```

## Component Overview

The **Kubeflow Training Operator** is a unified Kubernetes operator that provides declarative APIs for running scalable distributed training jobs using various machine learning frameworks (PyTorch, TensorFlow, MPI, XGBoost, MXNet, PaddlePaddle). It manages the lifecycle of training jobs by creating and monitoring pods, services, and other resources required for distributed training.

### Key Features
- **Multi-framework support**: PyTorch, TensorFlow, MPI/Horovod, XGBoost, MXNet, PaddlePaddle
- **Elastic training**: Autoscaling support for dynamic resource allocation
- **Gang scheduling**: Optional integration with Volcano or scheduler-plugins
- **Comprehensive observability**: Prometheus metrics for job tracking and reconciliation
- **Python SDK**: Programmatic job submission and management

### Architecture Highlights
- **Namespace**: opendatahub (RHOAI)
- **Leader Election**: Enabled for high availability
- **Service Mesh**: Disabled (Istio sidecar injection disabled)
- **Metrics**: Exposed on port 8080/TCP (HTTP)
- **Webhooks**: Validation and mutation on port 9443/TCP (HTTPS TLS 1.2+)
- **Health Probes**: Port 8081/TCP (HTTP)

### Security
- **RBAC**: ClusterRole with permissions for all job types and core resources
- **Webhook Certificates**: Managed by cert-manager or manual provisioning
- **ServiceAccount**: training-operator in opendatahub namespace
- **Network Policies**: User responsibility for training pod isolation

### Dependencies
- **Required**: Kubernetes 1.25+, controller-runtime v0.17.2
- **Optional**: Volcano v1.8.0+, scheduler-plugins v0.26.7+, cert-manager, Prometheus Operator
- **Internal**: Prometheus (metrics scraping)

### Deployment
- **Image**: quay.io/opendatahub/training-operator:v1-odh-c7d4e1b
- **Replicas**: 1 (leader election ID: 1ca428e5.training-operator.kubeflow.org)
- **Build System**: Konflux (Dockerfile.konflux)
