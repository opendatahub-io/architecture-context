# Architecture Diagrams for Kubeflow Training Operator

Generated from: `architecture/rhoai-3.2/training-operator.md`
Date: 2026-03-15
Component: training-operator (v1.9.0)

**Note**: Diagram filenames use base component name without version (directory is already versioned).

## Available Diagrams

All Mermaid diagrams are available in both `.mmd` (source) and `.png` (3000px width, high-resolution) formats.

### For Developers
- [Component Structure](./training-operator-component.png) ([mmd](./training-operator-component.mmd)) - Mermaid diagram showing internal components and framework controllers
- [Data Flows](./training-operator-dataflow.png) ([mmd](./training-operator-dataflow.mmd)) - Sequence diagram of training job creation and reconciliation flows
- [Dependencies](./training-operator-dependencies.png) ([mmd](./training-operator-dependencies.mmd)) - Component dependency graph showing ML frameworks and integrations

### For Architects
- [C4 Context](./training-operator-c4-context.dsl) - System context in C4 format (Structurizr)
- [Component Overview](./training-operator-component.png) ([mmd](./training-operator-component.mmd)) - High-level component view with 6 framework controllers

### For Security Teams
- [Security Network Diagram (PNG)](./training-operator-security-network.png) - High-resolution network topology
- [Security Network Diagram (Mermaid)](./training-operator-security-network.mmd) - Visual network topology (editable)
- [Security Network Diagram (ASCII)](./training-operator-security-network.txt) - Precise text format for SAR submissions
- [RBAC Visualization](./training-operator-rbac.png) ([mmd](./training-operator-rbac.mmd)) - RBAC permissions and bindings

## Component Overview

The Kubeflow Training Operator is a Kubernetes-native operator that enables scalable distributed training and fine-tuning of machine learning models across multiple ML frameworks:

- **PyTorch** - Distributed PyTorch training with master/worker replicas
- **TensorFlow** - Distributed TensorFlow training with chief/worker/ps replicas
- **XGBoost** - Distributed XGBoost training with master/worker replicas
- **MPI** - MPI-based HPC and training jobs with launcher/worker replicas
- **PaddlePaddle** - Distributed PaddlePaddle training with master/worker replicas
- **JAX** - Distributed JAX training with worker replicas

Key capabilities:
- Unified CRD-based API for all ML frameworks
- Automatic Pod, Service, and NetworkPolicy creation
- Gang scheduling support (Volcano, scheduler-plugins)
- Elastic scaling with HPA integration
- Validating webhooks for job validation
- Prometheus metrics for monitoring

## Architecture Highlights

**Deployment**: Single operator managing 6 framework-specific controllers
**Namespace**: `opendatahub`
**Service Account**: `training-operator`
**Security**: FIPS-compliant, non-root (UID 65532), Istio sidecar disabled

**Network Services**:
- Webhook Server: 9443/TCP (HTTPS, TLS 1.2+, mTLS)
- Metrics Server: 8080/TCP (HTTP, internal)
- Health Server: 8081/TCP (HTTP, /healthz, /readyz)
- Training Jobs: Framework-dependent ports (e.g., PyTorch master: 23456/TCP)

**Key Dependencies**:
- Kubernetes 1.27+ (required)
- controller-runtime v0.19.1 (required)
- Volcano v1.9.0 (optional, gang scheduling)
- scheduler-plugins v0.28.9 (optional, gang scheduling)
- Prometheus (optional, metrics collection)

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
   PUPPETEER_EXECUTABLE_PATH=/usr/bin/google-chrome mmdc -i training-operator-component.mmd -o training-operator-component.png -w 3000
   ```

3. **Alternative formats** (if needed):
   ```bash
   # SVG (vector, scales perfectly)
   PUPPETEER_EXECUTABLE_PATH=/usr/bin/google-chrome mmdc -i training-operator-component.mmd -o training-operator-component.svg

   # PDF
   PUPPETEER_EXECUTABLE_PATH=/usr/bin/google-chrome mmdc -i training-operator-component.mmd -o training-operator-component.pdf
   ```

**Note**: If `google-chrome` is not found, try `chromium` or `which google-chrome` to locate it

### C4 Diagrams (.dsl files)
- **Structurizr Lite**: `docker run -p 8080:8080 -v .:/usr/local/structurizr structurizr/lite`
- **CLI export**: `structurizr-cli export -workspace training-operator-c4-context.dsl -format png`

### ASCII Diagrams (.txt files)
- View in any text editor
- Include in documentation as-is
- Perfect for security reviews (precise technical details)

## Security Considerations

The training-operator implements several security best practices:

✅ **FIPS Compliance**: Built with `strictfipsruntime` and UBI9 base image
✅ **Non-root**: Runs as UID 65532 (non-root user)
✅ **Privilege Escalation**: Disabled in security context
✅ **Webhook Certificates**: Self-signed, auto-rotated by cert-controller
✅ **Istio Sidecar**: Disabled via annotation

⚠️ **Sensitive Permissions**:
- **pod/exec**: Required for MPI launcher functionality
- **secrets**: Can read/update (webhook certs, job configuration)

⚠️ **Training Pod Security**:
- Framework-specific communication typically not encrypted by default
- NetworkPolicies created for job isolation (enforcement depends on CNI)

## Updating Diagrams

To regenerate after architecture changes:

```bash
# From repository root
python scripts/generate_diagram_pngs.py architecture/rhoai-3.2/diagrams --width=3000
```

Or regenerate from architecture markdown:
```bash
# This would require the diagram generation skill/tool
/generate-architecture-diagrams --architecture=architecture/rhoai-3.2/training-operator.md
```

## Related Documentation

- Architecture Source: [training-operator.md](../training-operator.md)
- Upstream Repository: https://github.com/red-hat-data-services/training-operator
- Version: 1.9.0 (RHOAI 3.2 branch)
- Distribution: RHOAI (Red Hat OpenShift AI)

## Diagram Inventory

| Diagram | Format | Purpose | Audience |
|---------|--------|---------|----------|
| training-operator-component | .mmd, .png | Component structure and controllers | Developers, Architects |
| training-operator-dataflow | .mmd, .png | Request/response sequence flows | Developers, SREs |
| training-operator-security-network | .mmd, .png, .txt | Network topology with security details | Security, Compliance |
| training-operator-dependencies | .mmd, .png | Dependency graph | Architects, Integration Engineers |
| training-operator-rbac | .mmd, .png | RBAC permissions visualization | Security, Compliance |
| training-operator-c4-context | .dsl | System context (C4 model) | Architects, Stakeholders |
