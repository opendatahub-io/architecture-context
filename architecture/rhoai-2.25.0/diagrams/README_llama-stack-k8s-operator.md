# Architecture Diagrams for Llama Stack Kubernetes Operator

Generated from: `architecture/rhoai-2.25.0/llama-stack-k8s-operator.md`
Date: 2026-03-13

**Note**: Diagram filenames use base component name without version (directory is already versioned).

## Available Diagrams

All Mermaid diagrams are available in both `.mmd` (source) and `.png` (3000px width, high-resolution) formats.

### For Developers
- [Component Structure](./llama-stack-k8s-operator-component.png) ([mmd](./llama-stack-k8s-operator-component.mmd)) - Mermaid diagram showing internal components, CRDs, managed resources, and dependencies
- [Data Flows](./llama-stack-k8s-operator-dataflow.png) ([mmd](./llama-stack-k8s-operator-dataflow.mmd)) - Sequence diagram of reconciliation, inference requests, metrics collection, and ConfigMap updates
- [Dependencies](./llama-stack-k8s-operator-dependencies.png) ([mmd](./llama-stack-k8s-operator-dependencies.mmd)) - Component dependency graph showing external dependencies, RHOAI integrations, and inference provider backends

### For Architects
- [C4 Context](./llama-stack-k8s-operator-c4-context.dsl) - System context in C4 format (Structurizr)
- [Component Overview](./llama-stack-k8s-operator-component.png) ([mmd](./llama-stack-k8s-operator-component.mmd)) - High-level component view

### For Security Teams
- [Security Network Diagram (PNG)](./llama-stack-k8s-operator-security-network.png) - High-resolution network topology
- [Security Network Diagram (Mermaid)](./llama-stack-k8s-operator-security-network.mmd) - Visual network topology (editable)
- [Security Network Diagram (ASCII)](./llama-stack-k8s-operator-security-network.txt) - Precise text format for SAR submissions
- [RBAC Visualization](./llama-stack-k8s-operator-rbac.png) ([mmd](./llama-stack-k8s-operator-rbac.mmd)) - RBAC permissions and bindings

## Component Summary

**Llama Stack Kubernetes Operator v0.3.0** - Kubernetes operator that automates deployment and lifecycle management of Llama Stack servers supporting multiple inference backends (Ollama, vLLM, TGI, Bedrock).

**Key Features**:
- Manages LlamaStackDistribution CRDs
- Supports multiple inference backends (Ollama, vLLM, TGI, Bedrock, Together AI)
- ConfigMap-driven feature flags and image overrides
- Optional NetworkPolicy creation for network isolation
- Kustomize-based manifest generation
- Integration with OpenShift Monitoring and Security Context Constraints

**Network Exposure**:
- Operator metrics: 8443/TCP (HTTPS with kube-rbac-proxy)
- Llama Stack API: 8321/TCP (HTTP, configurable, optional Ingress)
- Health checks: 8081/TCP (HTTP, unauthenticated)

**Security**:
- ServiceAccount-based RBAC with ClusterRole permissions
- Optional TLS for Llama Stack endpoints
- NetworkPolicy support for ingress control
- OpenShift anyuid SCC for managed pods
- kube-rbac-proxy for secured metrics endpoint

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
   PUPPETEER_EXECUTABLE_PATH=/usr/bin/google-chrome mmdc -i llama-stack-k8s-operator-component.mmd -o llama-stack-k8s-operator-component.png -w 3000
   ```

3. **Alternative formats** (if needed):
   ```bash
   # SVG (vector, scales perfectly)
   PUPPETEER_EXECUTABLE_PATH=/usr/bin/google-chrome mmdc -i llama-stack-k8s-operator-component.mmd -o llama-stack-k8s-operator-component.svg

   # PDF
   PUPPETEER_EXECUTABLE_PATH=/usr/bin/google-chrome mmdc -i llama-stack-k8s-operator-component.mmd -o llama-stack-k8s-operator-component.pdf
   ```

**Note**: If `google-chrome` is not found, try `chromium` or `which google-chrome` to locate it

### C4 Diagrams (.dsl files)
- **Structurizr Lite**: `docker run -p 8080:8080 -v .:/usr/local/structurizr structurizr/lite`
- **CLI export**: `structurizr-cli export -workspace llama-stack-k8s-operator-c4-context.dsl -format png`

### ASCII Diagrams (.txt files)
- View in any text editor
- Include in documentation as-is
- Perfect for security reviews (precise technical details)

## Diagram Details

### Component Diagram
Shows the operator's internal structure including:
- Operator Controller Manager and LlamaStackDistribution Controller
- Kustomize-based deployment engine
- Feature flags and image mapper (ConfigMap-driven)
- Managed resources (Deployments, Services, PVCs, NetworkPolicies, Ingresses)
- External dependencies (Kubernetes API, inference providers, container registries)
- RHOAI integrations (OpenShift Monitoring, Security Context Constraints)

### Data Flow Diagram
Illustrates four key flows:
1. **LlamaStackDistribution Reconciliation**: User creates CRD → Operator watches → Kustomize generates manifests → Resources created
2. **User Inference Request**: External client → Ingress Controller → Llama Stack Service → Llama Stack Pod → Inference Provider
3. **Metrics Collection**: Prometheus → kube-rbac-proxy → Operator Manager
4. **ConfigMap-driven Configuration Update**: User updates ConfigMap → Operator detects change → Deployment rollout

### Security Network Diagram
Detailed network topology with:
- External ingress (optional) with TLS configuration
- Internal cluster network (ClusterIP services)
- Operator namespace with secured metrics endpoint
- External services (Kubernetes API, container registries, HuggingFace Hub)
- Optional NetworkPolicy configuration
- Complete RBAC summary and secrets inventory

### Dependencies Diagram
Shows:
- External dependencies: Kubernetes 1.20+, controller-runtime, kustomize, inference providers
- Internal RHOAI dependencies: OpenShift Monitoring, Security Context Constraints
- Distribution-specific backends: Ollama, vLLM, TGI, Bedrock
- Integration points with ODH/RHOAI Dashboard

### RBAC Diagram
Visualizes:
- Service accounts (controller-manager, per-instance SAs)
- ClusterRoles (manager-role, auth-proxy-role, metrics-reader, editor, viewer)
- ClusterRoleBindings and namespace-scoped RoleBindings
- Permissions to API resources (CRDs, core resources, networking, security)
- Token validation flow (TokenReview, SubjectAccessReview)

### C4 Context Diagram
System context showing:
- Users (Data Scientists, Platform Administrators)
- Llama Stack Operator with internal containers
- External systems (Kubernetes, inference providers, container registries, HuggingFace)
- Internal RHOAI systems (OpenShift Monitoring, Security Context Constraints)
- Interaction flows and protocols

## Updating Diagrams

To regenerate after architecture changes:
```bash
# From repository root
cd architecture/rhoai-2.25.0
# Edit the architecture markdown file
vim llama-stack-k8s-operator.md
# Regenerate diagrams (adjust path to script as needed)
python ../../scripts/generate_diagram_pngs.py diagrams/ --width=3000
```

## Related Documentation
- Architecture Source: [llama-stack-k8s-operator.md](../llama-stack-k8s-operator.md)
- Repository: https://github.com/red-hat-data-services/llama-stack-k8s-operator
- Version: 0.3.0 (Llama Stack Server: 0.2.22)
- Distribution: RHOAI 2.25.0
