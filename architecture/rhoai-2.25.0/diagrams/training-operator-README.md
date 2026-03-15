# Architecture Diagrams for Kubeflow Training Operator

Generated from: `architecture/rhoai-2.25.0/training-operator.md`
Date: 2026-03-14
Component Version: 1.9.0 (git: 3a1af789)

**Note**: Diagram filenames use base component name without version (directory is already versioned).

## Available Diagrams

All Mermaid diagrams are available in both `.mmd` (source) and `.png` (3000px width, high-resolution) formats.

### For Developers
- [Component Structure](./training-operator-component.png) ([mmd](./training-operator-component.mmd)) - Mermaid diagram showing internal controllers and framework support
- [Data Flows](./training-operator-dataflow.png) ([mmd](./training-operator-dataflow.mmd)) - Sequence diagram of training job creation and execution flows
- [Dependencies](./training-operator-dependencies.png) ([mmd](./training-operator-dependencies.mmd)) - Component dependency graph showing ML frameworks and integrations

### For Architects
- [C4 Context](./training-operator-c4-context.dsl) - System context in C4 format (Structurizr)
- [Component Overview](./training-operator-component.png) ([mmd](./training-operator-component.mmd)) - High-level component view with controllers

### For Security Teams
- [Security Network Diagram (PNG)](./training-operator-security-network.png) - High-resolution network topology
- [Security Network Diagram (Mermaid)](./training-operator-security-network.mmd) - Visual network topology (editable)
- [Security Network Diagram (ASCII)](./training-operator-security-network.txt) - Precise text format for SAR submissions
- [RBAC Visualization](./training-operator-rbac.png) ([mmd](./training-operator-rbac.mmd)) - RBAC permissions and bindings

## Component Overview

The Kubeflow Training Operator manages distributed training workloads for multiple ML frameworks:

- **PyTorch** - Elastic training with HPA support, master-worker topology
- **TensorFlow** - Parameter server and Ring AllReduce strategies
- **MPI** - Launcher-worker architecture for HPC workloads
- **XGBoost** - Distributed XGBoost training
- **PaddlePaddle** - Distributed PaddlePaddle training
- **JAX** - Distributed JAX training

### Key Features

- **Gang Scheduling**: Volcano and Scheduler Plugins support
- **Elastic Training**: Dynamic worker scaling for PyTorch jobs
- **Network Isolation**: Optional NetworkPolicies per job
- **Webhook Validation**: Validates job specs before creation
- **FIPS Compliance**: Built with GOEXPERIMENT=strictfipsruntime
- **Python SDK**: High-level APIs for job creation and monitoring

## How to Use

### PNG Files (.png files)
**Automatically generated** at 3000px width for high-resolution presentations and documentation.

- **Ready to use**: High-resolution images suitable for presentations, wikis, and documentation
- **Width**: 3000px (height auto-adjusts to content)
- **Use directly**: Include in PowerPoint, Google Slides, Confluence, etc.

### Mermaid Source Files (.mmd files)
- **In GitHub/GitLab**: Paste into markdown with ` ```mermaid` code blocks - renders automatically!
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
Shows the training operator's internal architecture:
- Controller Manager with 6 framework-specific controllers
- Webhook server for validation
- Certificate manager for TLS rotation
- Metrics exporter for Prometheus
- Integration with gang schedulers (Volcano, Scheduler Plugins)
- ODH integration (Dashboard, Model Registry)

### Data Flow Diagram
Illustrates three key flows:
1. **Training Job Creation**: User → K8s API → Webhook → Controller → Resource creation
2. **Training Job Execution**: Image pull → Master/Worker pods → Inter-pod communication → Model storage
3. **Metrics Collection**: Prometheus scraping operator metrics

### Security Network Diagram
Detailed network topology showing:
- **Operator Control Plane** (namespace: opendatahub)
  - Webhook server: 9443/TCP HTTPS TLS1.2+ with K8s API Server mTLS
  - Metrics endpoint: 8080/TCP HTTP for Prometheus
- **Training Workload** (user namespaces)
  - Master/Worker pods with framework-specific communication ports
  - Inter-pod TCP communication (typically port 23456 for PyTorch)
- **External Services**
  - Container registry pulls with TLS
  - Object storage (S3) with AWS IAM authentication
  - Gang scheduler APIs (optional)

### Dependencies Diagram
Shows relationships with:
- **Required**: Kubernetes 1.27+, controller-runtime v0.19+
- **Optional**: Volcano Scheduler, Scheduler Plugins, Prometheus Operator
- **Internal ODH**: Dashboard, Model Registry, Distributed Workloads
- **External**: Container registries, object storage (S3/Azure/GCS)
- **Frameworks**: PyTorch, TensorFlow, MPI, XGBoost, PaddlePaddle, JAX

### RBAC Diagram
Visualizes permissions:
- **ClusterRole**: training-operator (full CRUD on training job CRs, pods, services, etc.)
- **Role**: training-operator-webhook-secret (namespace-scoped secrets access)
- **Service Account**: training-operator (namespace: opendatahub)
- **Resources**: PyTorchJob, TFJob, MPIJob, XGBoostJob, PaddleJob, JAXJob CRs
- **Special permissions**: HPA, PodGroups (gang scheduling), NetworkPolicies

## Security Considerations

1. **FIPS Compliance**: Built with `GOEXPERIMENT=strictfipsruntime` for FIPS 140-2 compliance
2. **Minimal RBAC**: Secrets access restricted to namespace-scoped Role (security improvement)
3. **Webhook TLS**: Self-managed certificate rotation via in-operator cert-manager
4. **Network Isolation**: Optional NetworkPolicies per training job
5. **Istio Sidecar**: Explicitly disabled (`sidecar.istio.io/inject: "false"`) for direct TCP communication
6. **CVE Scanning**: Konflux CI/CD pipeline with regular base image updates

## Integration Points

- **ODH Dashboard**: UI-based training job creation and monitoring via K8s API
- **Model Registry**: Post-training model metadata and artifact storage
- **Distributed Workloads**: Coordination with other distributed workload components
- **Gang Schedulers**: Volcano and Scheduler Plugins for all-or-nothing pod scheduling
- **Prometheus**: Metrics collection via PodMonitor on port 8080

## Updating Diagrams

To regenerate after architecture changes:
```bash
# From repository root
python scripts/generate_architecture_diagrams.py \
  --architecture=architecture/rhoai-2.25.0/training-operator.md \
  --output-dir=architecture/rhoai-2.25.0/diagrams
```

Or use the automatic output directory:
```bash
python scripts/generate_architecture_diagrams.py \
  --architecture=architecture/rhoai-2.25.0/training-operator.md
# Outputs to: architecture/rhoai-2.25.0/diagrams/
```

## References

- **Repository**: https://github.com/red-hat-data-services/training-operator
- **Version**: 1.9.0 (git: 3a1af789)
- **Branch**: rhoai-2.25
- **Documentation**: See `training-operator.md` for detailed architecture
