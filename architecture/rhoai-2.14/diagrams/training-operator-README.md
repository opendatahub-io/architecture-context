# Architecture Diagrams for Kubeflow Training Operator

Generated from: `architecture/rhoai-2.14/training-operator.md`
Date: 2026-03-15

**Note**: Diagram filenames use base component name without version (directory is already versioned).

## Available Diagrams

All Mermaid diagrams are available in both `.mmd` (source) and `.png` (3000px width, high-resolution) formats.

### For Developers
- [Component Structure](./training-operator-component.png) ([mmd](./training-operator-component.mmd)) - Mermaid diagram showing internal components and controllers
- [Data Flows](./training-operator-dataflow.png) ([mmd](./training-operator-dataflow.mmd)) - Sequence diagram of request/response flows for training job lifecycle
- [Dependencies](./training-operator-dependencies.png) ([mmd](./training-operator-dependencies.mmd)) - Component dependency graph showing external and internal dependencies

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

### ASCII Diagrams (.txt files)
- View in any text editor
- Include in documentation as-is
- Perfect for security reviews (precise technical details)

## Diagram Details

### Component Structure
Shows the internal architecture of the Training Operator:
- Training Operator Manager (main controller)
- Framework-specific controllers (PyTorch, TensorFlow, MPI, MXNet, XGBoost, PaddlePaddle)
- Metrics and health probe servers
- Custom Resource Definitions for each framework
- Created resources (Pods, Services, ConfigMaps, PodGroups, HPAs)
- Integration with Kubernetes API, Volcano Scheduler, and Prometheus

### Data Flows
Illustrates four key operational flows:
1. **Training Job Creation**: User creates PyTorchJob CR → Operator watches → Creates Pods/Services/ConfigMaps
2. **Distributed Training Communication**: Master pod coordinates with worker pods for gradient synchronization
3. **Metrics Collection**: Prometheus scrapes metrics from operator
4. **Job Completion**: Operator watches pod events and updates job status

### Security Network Diagram
Provides detailed network topology with security information:
- **User Access**: HTTPS/443 with user token/certificate
- **Kubernetes API**: TLS 1.2+ with ServiceAccount tokens
- **Operator Namespace**: Non-root containers, FIPS mode, no privilege escalation
- **Training Job Communication**: TCP/23456 plaintext (pod-to-pod)
- **Monitoring**: HTTP endpoints (metrics, health) - internal only
- **External Services**: Container registry pull, gang scheduler integration
- **RBAC**: Detailed ClusterRole permissions for operator
- **Secrets**: Pull secrets, ServiceAccount tokens

### Dependencies
Shows all external and internal dependencies:
- **Required**: Kubernetes 1.25+, controller-runtime v0.17.2
- **Optional**: Volcano Scheduler, scheduler-plugins, Prometheus Operator
- **Internal ODH**: ODH Dashboard, ODH Monitoring
- **Supported Frameworks**: PyTorch, TensorFlow, MPI, MXNet, XGBoost, PaddlePaddle

### RBAC Visualization
Visual representation of RBAC permissions:
- ServiceAccount: kubeflow-training-operator
- ClusterRole: kubeflow-training-operator
- Permissions for core resources (pods, services, configmaps, events, serviceaccounts)
- Permissions for training job CRDs (PyTorchJob, TFJob, MPIJob, etc.)
- Status and finalizer permissions
- RBAC, autoscaling, and gang scheduling permissions
- User roles: kubeflow-training-edit, kubeflow-training-view

## Updating Diagrams

To regenerate after architecture changes:
```bash
# From repository root
cd architecture/rhoai-2.14
# Generate diagrams (auto-detects output directory)
<generate-diagrams-tool> --architecture=training-operator.md
```

## Key Security Highlights

⚠️ **Training Pod Communication**: Worker pods communicate over plaintext TCP (port 23456)
- Mitigation: Use NetworkPolicies to restrict pod-to-pod traffic
- Recommendation: Run training in isolated namespaces

✓ **Operator Security**:
- Non-root user (UID 65532)
- FIPS mode enabled for cryptographic operations
- No privilege escalation
- ServiceAccount with least-privilege RBAC
- TLS 1.2+ for all Kubernetes API communication

✓ **Monitoring Security**:
- Metrics and health endpoints are HTTP (no encryption)
- Acceptable: Internal-only access via ClusterIP service
- Network isolation ensures endpoints not exposed externally

## Related Documentation

- [Architecture Documentation](../training-operator.md) - Full component architecture
- [RHOAI Documentation](https://access.redhat.com/documentation/en-us/red_hat_openshift_ai)
- [Kubeflow Training Operator GitHub](https://github.com/kubeflow/training-operator)
