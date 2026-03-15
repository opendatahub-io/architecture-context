# Architecture Diagrams for Llama Stack Operator

Generated from: `architecture/rhoai-3.3/llama-stack-k8s-operator.md`
Date: 2026-03-15
Component: llama-stack-k8s-operator (v0.6.0)

**Note**: Diagram filenames use base component name without version (directory is already versioned).

## Available Diagrams

All Mermaid diagrams are available in both `.mmd` (source) and `.png` (3000px width, high-resolution) formats.

### For Developers
- [Component Structure](./llama-stack-k8s-operator-component.png) ([mmd](./llama-stack-k8s-operator-component.mmd)) - Mermaid diagram showing internal components, CRDs, and managed resources
- [Data Flows](./llama-stack-k8s-operator-dataflow.png) ([mmd](./llama-stack-k8s-operator-dataflow.mmd)) - Sequence diagram of request/response flows including CR creation, inference, metrics, and ConfigMap updates
- [Dependencies](./llama-stack-k8s-operator-dependencies.png) ([mmd](./llama-stack-k8s-operator-dependencies.mmd)) - Component dependency graph showing external dependencies, inference providers, and managed resources

### For Architects
- [C4 Context](./llama-stack-k8s-operator-c4-context.dsl) - System context in C4 format (Structurizr)
- [Component Overview](./llama-stack-k8s-operator-component.png) ([mmd](./llama-stack-k8s-operator-component.mmd)) - High-level component view

### For Security Teams
- [Security Network Diagram (PNG)](./llama-stack-k8s-operator-security-network.png) - High-resolution network topology
- [Security Network Diagram (Mermaid)](./llama-stack-k8s-operator-security-network.mmd) - Visual network topology (editable)
- [Security Network Diagram (ASCII)](./llama-stack-k8s-operator-security-network.txt) - Precise text format for SAR submissions
- [RBAC Visualization](./llama-stack-k8s-operator-rbac.png) ([mmd](./llama-stack-k8s-operator-rbac.mmd)) - RBAC permissions and bindings

## Component Overview

The Llama Stack Operator is a Kubernetes operator that automates deployment and lifecycle management of Llama Stack servers. Key features:

- **Deployment**: Creates and manages LlamaStackDistribution custom resources
- **Inference Providers**: Integrates with Ollama (11434/TCP) and vLLM (8000/TCP)
- **Security**: Optional NetworkPolicy, RBAC, SCC (anyuid), TLS support
- **Observability**: Prometheus metrics, health probes, structured logging
- **Advanced Features**: Autoscaling (HPA), PodDisruptionBudget, topology spread constraints

**Namespace**: redhat-ods-applications (RHOAI)
**Distribution**: RHOAI 3.3

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
Shows the operator's internal architecture:
- Controller Manager and reconcilers
- Custom Resource Definitions (LlamaStackDistribution)
- Managed resources (Deployments, Services, PVCs, Ingress, NetworkPolicy, HPA, PDB)
- External dependencies (Kubernetes API, Ollama, vLLM, HuggingFace, Registry)

### Data Flow Diagrams
Four key flows:
1. **LlamaStackDistribution Creation**: User creates CR → Operator reconciles → Deploys Llama Stack server
2. **ConfigMap Update**: Config changes trigger automatic pod restart
3. **Inference Request**: Client → Llama Stack → Ollama/vLLM → Response
4. **Metrics Collection**: Prometheus scrapes operator metrics via kube-rbac-proxy

### Security Network Diagram
Detailed network topology with:
- **Ports**: 6443/TCP (K8s API), 8443/TCP (metrics), 8081/TCP (health), 8321/TCP (Llama Stack)
- **Protocols**: HTTPS, HTTP, TLS 1.2+, TLS 1.3 (optional)
- **Authentication**: ServiceAccount tokens, Bearer tokens, HF tokens, pull secrets
- **Trust Zones**: External, Ingress, Operator namespace, User namespace, Inference providers, External services
- **NetworkPolicy**: Optional ingress-only policy (same namespace + operator namespace + allowed namespaces)
- **RBAC**: ClusterRoles (manager-role, auth-proxy-role), Role (leader-election-role)
- **Secrets**: hf-token-secret, TLS certificates, ServiceAccount tokens

### Dependencies
Shows relationships with:
- **External**: Kubernetes 1.20+, controller-runtime v0.22.4, kustomize v0.21.0
- **Optional**: Prometheus Operator, Ingress Controller
- **Internal RHOAI**: Ollama, vLLM, odh-trusted-ca-bundle, Service Mesh
- **External Services**: HuggingFace Hub, Container Registry

### RBAC Visualization
Complete RBAC configuration:
- **manager-role**: ClusterRole with permissions for core, apps, autoscaling, llamastack.io, networking, policy, RBAC, security (SCC)
- **auth-proxy-role**: ClusterRole for token reviews and subject access reviews
- **leader-election-role**: Role for leader election (ConfigMaps, leases, events)
- **Service Account**: controller-manager (bound to all roles)

## Updating Diagrams

To regenerate after architecture changes:
```bash
# From repository root
python scripts/generate_diagram_pngs.py architecture/rhoai-3.3/diagrams --width=3000
```

## References

- **Architecture Doc**: [llama-stack-k8s-operator.md](../llama-stack-k8s-operator.md)
- **Llama Stack Project**: https://github.com/meta-llama/llama-stack
- **Operator Source (ODH)**: https://github.com/opendatahub-io/llama-stack-k8s-operator
- **Operator Source (RHOAI)**: https://github.com/red-hat-data-services/llama-stack-k8s-operator
- **Kubebuilder**: https://book.kubebuilder.io/
