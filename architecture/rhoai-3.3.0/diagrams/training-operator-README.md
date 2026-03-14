# Architecture Diagrams for Kubeflow Training Operator

Generated from: `architecture/rhoai-3.3.0/training-operator.md`
Date: 2026-03-14
Component: training-operator (from filename)

**Note**: Diagram filenames use base component name without version (directory is already versioned).

## Available Diagrams

All Mermaid diagrams are available in both `.mmd` (source) and `.png` (3000px width, high-resolution) formats.

### For Developers
- [Component Structure](./training-operator-component.png) ([mmd](./training-operator-component.mmd)) - Mermaid diagram showing internal components (controllers, webhook, metrics)
- [Data Flows](./training-operator-dataflow.png) ([mmd](./training-operator-dataflow.mmd)) - Sequence diagram of request/response flows (job submission, metrics, health, distributed training)
- [Dependencies](./training-operator-dependencies.png) ([mmd](./training-operator-dependencies.mmd)) - Component dependency graph showing required and optional dependencies

### For Architects
- [C4 Context](./training-operator-c4-context.dsl) - System context in C4 format (Structurizr) showing operator in broader RHOAI ecosystem
- [Component Overview](./training-operator-component.png) ([mmd](./training-operator-component.mmd)) - High-level component view with framework controllers

### For Security Teams
- [Security Network Diagram (PNG)](./training-operator-security-network.png) - High-resolution network topology with trust zones
- [Security Network Diagram (Mermaid)](./training-operator-security-network.mmd) - Visual network topology (editable, color-coded trust zones)
- [Security Network Diagram (ASCII)](./training-operator-security-network.txt) - Precise text format for SAR submissions with RBAC details
- [RBAC Visualization](./training-operator-rbac.png) ([mmd](./training-operator-rbac.mmd)) - RBAC permissions and bindings including CVE-2026-2353 fix

## Component Summary

**Kubeflow Training Operator** is a Kubernetes-native operator for distributed ML training across multiple frameworks:

- **Supported Frameworks**: PyTorch, TensorFlow, XGBoost, MPI, JAX, PaddlePaddle
- **Version**: v1.9.0 (RHOAI 3.3)
- **Deployment**: Namespace `opendatahub`, ServiceAccount `training-operator`
- **Key Features**:
  - Declarative API for distributed training jobs
  - Automatic resource creation (Pods, Services, ConfigMaps)
  - Optional gang scheduling (Volcano, scheduler-plugins)
  - Elastic scaling via HorizontalPodAutoscaler
  - Validating webhooks for all 6 job types

### Network Endpoints

| Endpoint | Port | Protocol | Encryption | Purpose |
|----------|------|----------|------------|---------|
| Webhook Server | 9443/TCP | HTTPS | TLS 1.2+ | Admission control (validates job specs) |
| Metrics | 8080/TCP | HTTP | None | Prometheus metrics |
| Health Probes | 8081/TCP | HTTP | None | Liveness/Readiness |

### Custom Resources

- `PyTorchJob` (kubeflow.org/v1) - PyTorch distributed training (Master/Worker)
- `TFJob` (kubeflow.org/v1) - TensorFlow distributed training (Chief/Worker/PS)
- `XGBoostJob` (kubeflow.org/v1) - XGBoost distributed training
- `MPIJob` (kubeflow.org/v1) - MPI-based HPC training (Launcher/Worker)
- `JAXJob` (kubeflow.org/v1) - JAX distributed training
- `PaddleJob` (kubeflow.org/v1) - PaddlePaddle distributed training

### Security Highlights

- **Webhook TLS**: Auto-rotated certificates via cert-controller
- **RBAC**: ClusterRole with namespace-scoped secrets access (CVE-2026-2353 fix)
- **Non-root**: Operator runs as UID 65532
- **Istio**: Disabled on operator pod (prevents webhook interference)
- **Training Communication**: Framework-specific, typically plaintext (user responsibility to isolate)

### Recent Security Fixes

- **CVE-2026-2353**: Secrets RBAC restricted to namespace-scoped Role (not cluster-wide)
- **CVE-2025-61726**: Go version upgraded to 1.25

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
- **Online**: Upload to https://structurizr.com

### ASCII Diagrams (.txt files)
- View in any text editor
- Include in documentation as-is
- Perfect for security reviews (precise technical details)
- Contains RBAC summary, secrets, and service mesh configuration

## Updating Diagrams

To regenerate after architecture changes:
```bash
# From repository root
python scripts/generate_diagram_pngs.py architecture/rhoai-3.3.0/diagrams --width=3000
```

Or use the skill command (if available):
```bash
/generate-architecture-diagrams --architecture=architecture/rhoai-3.3.0/training-operator.md
```

## Related Documentation

- **Architecture Documentation**: [../training-operator.md](../training-operator.md)
- **Upstream Docs**: https://www.kubeflow.org/docs/components/training/
- **API Reference**: Included in repository at `docs/api/kubeflow.org_v1_generated.asciidoc`
- **Python SDK**: https://pypi.org/project/kubeflow-training/
- **Examples**: Repository `examples/` directory contains sample jobs for all frameworks

## Diagram Types Explained

### Component Diagram
Shows the internal structure of the training operator including:
- Six framework-specific controllers (PyTorch, TensorFlow, XGBoost, MPI, JAX, PaddlePaddle)
- Webhook server for admission control
- Certificate controller for TLS management
- Metrics and health endpoints
- Kubernetes resources created by the operator

### Data Flow Diagram
Sequence diagram illustrating:
- **Job Submission**: User → K8s API → Webhook validation → Controller reconciliation
- **Metrics Collection**: Prometheus scraping operator metrics
- **Health Monitoring**: Kubelet health checks
- **Distributed Training**: Pod-to-pod communication (framework-specific)

### Security Network Diagram
Available in three formats:
- **PNG**: High-resolution visual for presentations
- **Mermaid**: Color-coded trust zones (external, control plane, operator, training jobs)
- **ASCII**: Precise text format with RBAC summary and secrets details

Shows network flows with exact ports, protocols, encryption (TLS versions), and authentication mechanisms.

### C4 Context Diagram
System context showing:
- Training operator containers (controller, webhook, cert controller, metrics)
- External systems (Kubernetes, Prometheus, optional Volcano/scheduler-plugins)
- Internal RHOAI integrations (opendatahub-operator, dashboard, pipelines)
- User interactions (data scientist submitting jobs)

### Dependencies Diagram
Dependency graph showing:
- **Required**: Kubernetes 1.27+, controller-runtime v0.19.1
- **Optional**: Volcano v1.9.0, scheduler-plugins v0.28.9, external cert-manager
- **Internal RHOAI**: Prometheus, opendatahub-operator, dashboard, pipelines
- **Supported ML Frameworks**: PyTorch, TensorFlow, XGBoost, MPI, JAX, PaddlePaddle

### RBAC Diagram
Visual representation of:
- ServiceAccount: `training-operator` (opendatahub namespace)
- ClusterRole permissions (job CRDs, Pods, Services, HPA, PodGroups, NetworkPolicies, etc.)
- Namespace-scoped Role for secrets access (CVE-2026-2353 fix)
- ClusterRoleBinding and RoleBinding relationships

## Notes

- **Istio**: Operator pod has sidecar injection disabled to prevent webhook interference
- **Gang Scheduling**: Optional - requires separate Volcano or scheduler-plugins installation
- **Training Communication**: Framework-specific protocols (typically plaintext) - operator does not enforce encryption
- **Security Context**: Operator runs as non-root (UID 65532), training pods use user-specified context
- **Metrics**: PodMonitor used for direct pod scraping (metrics port removed from Service in RHOAI overlay)
