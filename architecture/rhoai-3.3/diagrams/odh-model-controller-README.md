# Architecture Diagrams for odh-model-controller

Generated from: `architecture/rhoai-3.3/odh-model-controller.md`
Date: 2026-03-15

**Note**: Diagram filenames use base component name without version (directory is already versioned).

## Available Diagrams

All Mermaid diagrams are available in both `.mmd` (source) and `.png` (3000px width, high-resolution) formats.

### For Developers
- [Component Structure](./odh-model-controller-component.png) ([mmd](./odh-model-controller-component.mmd)) - Mermaid diagram showing internal components, reconcilers, and servers
- [Data Flows](./odh-model-controller-dataflow.png) ([mmd](./odh-model-controller-dataflow.mmd)) - Sequence diagram of InferenceService reconciliation, NIM account validation, webhook admission, and metrics collection
- [Dependencies](./odh-model-controller-dependencies.png) ([mmd](./odh-model-controller-dependencies.mmd)) - Component dependency graph showing external dependencies, internal ODH dependencies, and CRD watches

### For Architects
- [C4 Context](./odh-model-controller-c4-context.dsl) - System context in C4 format (Structurizr) showing the controller in the broader OpenShift AI ecosystem
- [Component Overview](./odh-model-controller-component.png) ([mmd](./odh-model-controller-component.mmd)) - High-level component view

### For Security Teams
- [Security Network Diagram (PNG)](./odh-model-controller-security-network.png) - High-resolution network topology
- [Security Network Diagram (Mermaid)](./odh-model-controller-security-network.mmd) - Visual network topology with trust zones (editable)
- [Security Network Diagram (ASCII)](./odh-model-controller-security-network.txt) - Precise text format for SAR submissions with complete RBAC, network policies, and secrets details
- [RBAC Visualization](./odh-model-controller-rbac.png) ([mmd](./odh-model-controller-rbac.mmd)) - RBAC permissions and bindings showing all ClusterRoles, bindings, and resource permissions

## Component Summary

**odh-model-controller** is a Kubernetes operator that extends KServe controller functionality with OpenShift-specific integrations for model serving workloads. It:

- Watches KServe custom resources (InferenceServices, InferenceGraphs, ServingRuntimes, LLMInferenceServices)
- Creates OpenShift Routes for external access to inference endpoints
- Configures NetworkPolicies for traffic control
- Sets up Prometheus ServiceMonitors for metrics collection
- Manages RBAC resources for inference workloads
- Integrates with KEDA for autoscaling
- Validates NVIDIA NIM accounts via NGC API
- Manages serving runtime templates for various frameworks (vLLM, OpenVINO, MLServer, Caikit, TGIS)

**Key Technologies**: Go, Kubebuilder, KServe v0.15.1, OpenShift v4.11+

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

## Architecture Highlights

### Security
- **Non-root container**: Runs as UID 2000 in UBI9 minimal image
- **FIPS compliance**: Built with strictfipsruntime tags
- **Webhook mTLS**: Kubernetes API server client cert validation
- **Metrics auth**: Bearer token via kube-rbac-proxy sidecar
- **Certificate management**: Auto-provisioned by OpenShift service-ca-operator
- **HTTP/2 disabled**: CVE-2023-44487 mitigation

### Network Architecture
- **Webhook server**: 9443/TCP HTTPS (TLS 1.2+, mTLS)
- **Metrics endpoint**: 8080/TCP HTTP (TODO: migrate to 8443 HTTPS)
- **Health checks**: 8081/TCP HTTP (public endpoints)
- **Kubernetes API**: 443/TCP HTTPS (TLS 1.2+, ServiceAccount token)
- **NVIDIA NGC API**: 443/TCP HTTPS (TLS 1.2+, NGC API key)

### Integration Points
- **KServe**: Core dependency - watches and extends InferenceService CRDs
- **OpenShift**: Creates Routes and Templates for model serving
- **Prometheus**: ServiceMonitors for metrics scraping
- **KEDA**: TriggerAuthentications for autoscaling
- **Istio**: EnvoyFilters for service mesh policies
- **Kuadrant**: AuthPolicies for API authentication
- **NVIDIA NGC**: Account validation and NIM model configurations

## Updating Diagrams

To regenerate after architecture changes:
```bash
# From repository root
claude generate architecture diagrams for architecture/rhoai-3.3/odh-model-controller.md
```

## Related Documentation
- [Architecture Documentation](../odh-model-controller.md)
- [KServe Documentation](https://kserve.github.io/website/)
- [OpenShift AI Documentation](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/)
