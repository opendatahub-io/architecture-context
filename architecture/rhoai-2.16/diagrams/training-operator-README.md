# Architecture Diagrams for Training Operator

Generated from: `architecture/rhoai-2.16/training-operator.md`
Date: 2026-03-16

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

## Diagram Descriptions

### Component Structure (training-operator-component.mmd)
Shows the internal architecture of the Training Operator including:
- 6 framework controllers (PyTorch, TensorFlow, MPI, XGBoost, MXNet, PaddlePaddle)
- Resource controllers (PodControl, ServiceControl)
- Metrics and health servers
- Integration with Kubernetes API, Prometheus, and Volcano
- Custom Resource Definitions (CRDs) for each training framework

### Data Flows (training-operator-dataflow.mmd)
Sequence diagram illustrating:
1. Training job creation workflow (User → K8s API → Operator)
2. Gang scheduling coordination (optional with Volcano)
3. Distributed training pod-to-pod communication via headless services
4. Metrics collection by Prometheus
5. Job completion status updates

### Security Network Diagram
Available in both visual (Mermaid) and precise (ASCII) formats:
- Network topology with exact ports and protocols
- TLS encryption details (TLS 1.2+)
- Authentication mechanisms (User tokens, ServiceAccount tokens)
- Trust boundaries (External, Control Plane, Operator Namespace, User Namespace)
- RBAC summary with ClusterRole permissions
- Security context (non-root UID 65532, no privilege escalation)
- Attack surface analysis

### Dependencies (training-operator-dependencies.mmd)
Dependency graph showing:
- Required external dependencies (Kubernetes 1.25+, controller-runtime)
- Optional dependencies (Volcano, scheduler-plugins, Prometheus Operator)
- Internal RHOAI dependencies (RHOAI Operator, User Workload Monitoring)
- Created resources (Pods, Services, ConfigMaps, PodGroups)

### RBAC Visualization (training-operator-rbac.mmd)
Visual representation of:
- ServiceAccount: kubeflow-training-operator
- ClusterRole permissions (pods, services, training job CRDs, PodGroups)
- Aggregated roles for users (edit, view)
- Special permissions (pods/exec for MPIJob launcher)

### C4 Context Diagram (training-operator-c4-context.dsl)
System context showing:
- Training Operator in the broader RHOAI ecosystem
- External actors (Data Scientists)
- External systems (Kubernetes API, Container Registry, Volcano)
- Internal RHOAI systems (Prometheus, RHOAI Operator)
- Container-level and component-level views

## Updating Diagrams

To regenerate after architecture changes:
```bash
# From repository root
python scripts/generate_diagram_pngs.py architecture/rhoai-2.16/diagrams --width=3000
```

## Architecture Highlights

Key architectural patterns to understand:

1. **Multi-Framework Support**: Single operator manages 6 ML training frameworks
2. **Headless Services**: DNS-based peer discovery for distributed training pods
3. **Gang Scheduling**: Optional all-or-nothing scheduling via Volcano/scheduler-plugins
4. **RBAC Aggregation**: Edit/view roles automatically grant training job permissions
5. **No Service Mesh**: Istio sidecar injection disabled to prevent networking conflicts
6. **Metrics Pipeline**: PodMonitor → Prometheus → User Workload Monitoring
7. **Security**: Non-root UID, no privilege escalation, TLS for all external communication

## Known Limitations

- Webhook server disabled in RHOAI deployment
- Gang scheduling requires separate Volcano/scheduler-plugins installation
- Single replica deployment (no HA)
- Training pod-to-pod communication is plaintext by default (application-level encryption available)
