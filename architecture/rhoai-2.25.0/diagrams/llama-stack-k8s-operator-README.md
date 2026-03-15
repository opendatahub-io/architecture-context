# Architecture Diagrams for Llama Stack Kubernetes Operator

Generated from: `architecture/rhoai-2.25.0/llama-stack-k8s-operator.md`
Date: 2026-03-14
Component: llama-stack-k8s-operator (derived from filename)

**Note**: Diagram filenames use base component name without version (directory is already versioned).

## Available Diagrams

All Mermaid diagrams are available in both `.mmd` (source) and `.png` (3000px width, high-resolution) formats.

### For Developers
- [Component Structure](./llama-stack-k8s-operator-component.png) ([mmd](./llama-stack-k8s-operator-component.mmd)) - Mermaid diagram showing internal components, CRDs, and managed resources
- [Data Flows](./llama-stack-k8s-operator-dataflow.png) ([mmd](./llama-stack-k8s-operator-dataflow.mmd)) - Sequence diagram of request/response flows (inference requests, reconciliation, metrics, config updates)
- [Dependencies](./llama-stack-k8s-operator-dependencies.png) ([mmd](./llama-stack-k8s-operator-dependencies.mmd)) - Component dependency graph showing external/internal dependencies

### For Architects
- [C4 Context](./llama-stack-k8s-operator-c4-context.dsl) - System context in C4 format (Structurizr) with deployment relationships
- [Component Overview](./llama-stack-k8s-operator-component.png) ([mmd](./llama-stack-k8s-operator-component.mmd)) - High-level component view

### For Security Teams
- [Security Network Diagram (PNG)](./llama-stack-k8s-operator-security-network.png) - High-resolution network topology
- [Security Network Diagram (Mermaid)](./llama-stack-k8s-operator-security-network.mmd) - Visual network topology (editable)
- [Security Network Diagram (ASCII)](./llama-stack-k8s-operator-security-network.txt) - Precise text format for SAR submissions
- [RBAC Visualization](./llama-stack-k8s-operator-rbac.png) ([mmd](./llama-stack-k8s-operator-rbac.mmd)) - RBAC permissions and bindings

## Architecture Overview

The Llama Stack Kubernetes Operator automates deployment and lifecycle management of Meta's Llama Stack inference servers across various distribution types:

- **Distributions Supported**: Ollama, vLLM, TGI, Bedrock, Together AI, and more
- **CRD**: `LlamaStackDistribution` (llamastack.io/v1alpha1)
- **Managed Resources**: Deployments, Services, PVCs, NetworkPolicies, Ingresses
- **Key Features**:
  - ConfigMap-based feature flags (NetworkPolicy creation)
  - ConfigMap-based image overrides
  - Kustomize-based manifest generation
  - Optional TLS configuration
  - Persistent storage for model weights
  - Network isolation with configurable ingress rules

## Key Components

1. **Operator Controller Manager**: Reconciles LlamaStackDistribution CRDs and manages lifecycle
2. **LlamaStackDistribution Controller**: Watches CRDs, creates Deployments/Services/PVCs/NetworkPolicies
3. **Kustomize Deployment Engine**: Generates manifests from templates
4. **Feature Flags Manager**: Controls optional features via ConfigMap
5. **Distribution Image Mapper**: Maps distribution names to container images with override support
6. **Network Policy Transformer**: Dynamically generates NetworkPolicy rules

## Data Flows

### Flow 1: User Inference Request (with Ingress)
External Client → Ingress Controller (443/TCP HTTPS) → Llama Stack Service (8321/TCP HTTP) → Llama Stack Pod → Inference Provider (Ollama/vLLM/TGI)

### Flow 2: LlamaStackDistribution Reconciliation
User creates CR → Operator watches via K8s API → Generates manifests with kustomize → Applies resources to cluster

### Flow 3: Metrics Collection
Prometheus → kube-rbac-proxy (8443/TCP HTTPS, Bearer Token) → Operator Manager (8080/TCP HTTP localhost)

### Flow 4: ConfigMap-driven Configuration Update
User updates ConfigMap → Operator watches ConfigMap → Reconciles affected LlamaStackDistributions → Restarts pods

## Security Highlights

- **Authentication**: kube-rbac-proxy for metrics endpoint (Bearer Token)
- **RBAC**: ClusterRoles for operator (manager-role, auth-proxy-role), user-facing roles (editor/viewer)
- **Network Policies**: Optional NetworkPolicy creation per instance (configurable via feature flag)
- **Secrets**: HF tokens, custom CA bundles, image pull secrets
- **OpenShift SCC**: Requires `anyuid` SCC for managed pods

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

## Updating Diagrams

To regenerate after architecture changes:
```bash
# From repository root
python scripts/generate_diagram_pngs.py architecture/rhoai-2.25.0/diagrams --width=3000
```

Or use the full workflow to regenerate from source:
```bash
# If architecture markdown is updated
/generate-architecture-diagrams --architecture=architecture/rhoai-2.25.0/llama-stack-k8s-operator.md
```

## Technical Details

- **Operator Version**: 0.3.0
- **Llama Stack Server**: 0.2.22
- **Language**: Go 1.24
- **Controller Framework**: controller-runtime v0.19.4
- **Manifest Engine**: kustomize kyaml v0.18.1
- **Distribution**: RHOAI 2.25.0
- **Repository**: https://github.com/red-hat-data-services/llama-stack-k8s-operator

## Related Documentation

- [Component Architecture](../llama-stack-k8s-operator.md) - Full architecture documentation
- [RHOAI Platform Overview](../PLATFORM.md) - Platform-level architecture
