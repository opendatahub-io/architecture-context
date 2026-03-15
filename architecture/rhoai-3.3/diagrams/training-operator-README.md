# Architecture Diagrams for Kubeflow Training Operator

Generated from: `architecture/rhoai-3.3/training-operator.md`
Date: 2026-03-15

**Note**: Diagram filenames use base component name without version (directory is already versioned).

## Available Diagrams

All Mermaid diagrams are available in both `.mmd` (source) and `.png` (3000px width, high-resolution) formats.

### For Developers
- [Component Structure](./training-operator-component.png) ([mmd](./training-operator-component.mmd)) - Mermaid diagram showing internal components and 6 framework controllers
- [Data Flows](./training-operator-dataflow.png) ([mmd](./training-operator-dataflow.mmd)) - Sequence diagram of training job submission and monitoring flows
- [Dependencies](./training-operator-dependencies.png) ([mmd](./training-operator-dependencies.mmd)) - Component dependency graph showing external and internal integrations

### For Architects
- [C4 Context](./training-operator-c4-context.dsl) - System context in C4 format (Structurizr) showing operator in RHOAI ecosystem
- [Component Overview](./training-operator-component.png) ([mmd](./training-operator-component.mmd)) - High-level component view with framework support

### For Security Teams
- [Security Network Diagram (PNG)](./training-operator-security-network.png) - High-resolution network topology
- [Security Network Diagram (Mermaid)](./training-operator-security-network.mmd) - Visual network topology (editable)
- [Security Network Diagram (ASCII)](./training-operator-security-network.txt) - Precise text format for SAR submissions
- [RBAC Visualization](./training-operator-rbac.png) ([mmd](./training-operator-rbac.mmd)) - RBAC permissions and bindings (ClusterRole + namespace-scoped Role for secrets)

## Key Security Considerations

**Important security details from the architecture:**

1. **Training Pod Communication**: Framework-to-framework communication (PyTorch port 23456, XGBoost port 9999) uses **PLAINTEXT** (no encryption)
2. **Secrets Access**: Restricted to namespace-scoped Role (not cluster-wide) per **CVE-2026-2353**
3. **Istio Sidecar**: **DISABLED** (`sidecar.istio.io/inject: "false"`) to avoid webhook interference
4. **Webhook TLS**: Auto-rotated certificates via built-in cert-controller
5. **Pod Security**: Operator runs as non-root (UID 65532)
6. **No Network Policies**: Not enforced by default (RBAC exists to create if configured)

## Component Features

**Supported ML Frameworks (6 total):**
- PyTorch (Master/Worker topology, port 23456/TCP)
- TensorFlow (Chief/Worker/PS topology)
- XGBoost (Master/Worker topology, port 9999/TCP)
- MPI (Launcher/Worker for HPC workloads)
- JAX (distributed training)
- PaddlePaddle (Master/Worker topology)

**Key Capabilities:**
- Distributed training job lifecycle management
- Validating webhooks for all 6 job types
- HorizontalPodAutoscaler integration for elastic scaling
- Optional gang scheduling (Volcano, scheduler-plugins)
- Metrics export for Prometheus monitoring

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
cd architecture/rhoai-3.3
# Regenerate diagrams for training-operator
/generate-architecture-diagrams --architecture=training-operator.md
```

## References

- **Architecture Source**: `architecture/rhoai-3.3/training-operator.md`
- **Upstream Docs**: https://www.kubeflow.org/docs/components/training/
- **Repository**: https://github.com/red-hat-data-services/training-operator
- **Version**: v1.9.0 (RHOAI 3.3)
- **Python SDK**: https://pypi.org/project/kubeflow-training/
