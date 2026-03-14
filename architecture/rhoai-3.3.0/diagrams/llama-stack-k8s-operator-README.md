# Architecture Diagrams for Llama Stack Operator

Generated from: `architecture/rhoai-3.3.0/llama-stack-k8s-operator.md`
Date: 2026-03-14

**Note**: Diagram filenames use base component name without version (directory is already versioned).

## Available Diagrams

All Mermaid diagrams are available in both `.mmd` (source) and `.png` (3000px width, high-resolution) formats.

### For Developers
- [Component Structure](./llama-stack-k8s-operator-component.png) ([mmd](./llama-stack-k8s-operator-component.mmd)) - Mermaid diagram showing internal components and managed resources
- [Data Flows](./llama-stack-k8s-operator-dataflow.png) ([mmd](./llama-stack-k8s-operator-dataflow.mmd)) - Sequence diagram of request/response flows
- [Dependencies](./llama-stack-k8s-operator-dependencies.png) ([mmd](./llama-stack-k8s-operator-dependencies.mmd)) - Component dependency graph

### For Architects
- [C4 Context](./llama-stack-k8s-operator-c4-context.dsl) - System context in C4 format (Structurizr)
- [Component Overview](./llama-stack-k8s-operator-component.png) ([mmd](./llama-stack-k8s-operator-component.mmd)) - High-level component view

### For Security Teams
- [Security Network Diagram (PNG)](./llama-stack-k8s-operator-security-network.png) - High-resolution network topology
- [Security Network Diagram (Mermaid)](./llama-stack-k8s-operator-security-network.mmd) - Visual network topology (editable)
- [Security Network Diagram (ASCII)](./llama-stack-k8s-operator-security-network.txt) - Precise text format for SAR submissions
- [RBAC Visualization](./llama-stack-k8s-operator-rbac.png) ([mmd](./llama-stack-k8s-operator-rbac.mmd)) - RBAC permissions and bindings

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

### Component Structure
Shows the internal architecture of the Llama Stack Operator, including:
- Controller Manager and reconciliation components
- Metrics and health probe endpoints
- Custom Resource Definitions (LlamaStackDistribution)
- Managed Kubernetes resources (Deployments, Services, HPA, PDB, NetworkPolicy, Ingress, PVC)
- External dependencies (Kubernetes API, Ollama, vLLM, Prometheus, HuggingFace Hub)
- Internal ODH/RHOAI integrations (odh-trusted-ca-bundle, Service Mesh)

### Data Flows
Sequence diagrams showing:
1. **LlamaStackDistribution Creation**: User creates CR → Operator reconciles → Resources created
2. **Metrics Collection**: Prometheus scrapes metrics via kube-rbac-proxy
3. **Llama Stack Inference Request**: Client → Llama Stack Service → Ollama/vLLM → Inference response
4. **ConfigMap Update and Pod Restart**: User updates ConfigMap → Operator triggers rolling restart

### Security Network Diagram
Available in three formats:
- **PNG** (3000px): High-resolution visual for presentations
- **Mermaid**: Editable visual with color-coded trust zones (External, Ingress, Operator Namespace, User Namespace, Inference Providers, Platform, External Services)
- **ASCII**: Precise text format with exact network details for Security Architecture Reviews

Shows:
- Network boundaries and trust zones
- Port numbers, protocols, encryption (TLS versions)
- Authentication mechanisms (Bearer tokens, ServiceAccount tokens, HuggingFace tokens)
- RBAC summary (ClusterRoles, ClusterRoleBindings, RoleBindings)
- Service Mesh configuration (optional)
- Secrets and ConfigMaps
- Container security settings

### C4 Context Diagram
Structurizr DSL showing:
- System context: How Llama Stack Operator fits into the ODH/RHOAI ecosystem
- Container view: Internal structure of the operator (Controller Manager, Metrics Service, Health Probes)
- Component view: Controller Manager components (LlamaStackDistribution Controller, Kustomize Engine, NetworkPolicy Manager, ConfigMap Watcher)
- External systems: Kubernetes, Prometheus, Ollama, vLLM, HuggingFace Hub, Container Registry, Ingress Controller, Service Mesh
- User personas: Data Scientist/ML Engineer, DevOps/Platform Engineer

### Dependencies
Shows:
- **External dependencies**: Kubernetes 1.20+, controller-runtime v0.22.4, kustomize v0.21.0, Prometheus Operator (optional), Ingress Controller (optional)
- **Internal ODH/RHOAI dependencies**: Ollama (11434/TCP), vLLM (8000/TCP), odh-trusted-ca-bundle, Service Mesh (optional)
- **Integration points**: ODH Dashboard, Data Science Pipelines
- **External services**: Kubernetes API (6443/TCP), HuggingFace Hub (443/TCP), Container Registry (443/TCP)
- **Managed resources**: All Kubernetes resources created by the operator

### RBAC Visualization
Shows:
- **Service Account**: controller-manager (namespace: redhat-ods-applications)
- **ClusterRole**: manager-role (full CRUD on core resources, apps, autoscaling, llamastack.io, networking, policy, RBAC resources; use anyuid SCC)
- **ClusterRole**: auth-proxy-role (tokenreviews, subjectaccessreviews)
- **Role**: leader-election-role (namespace-scoped: configmaps, events, leases)
- **Bindings**: ClusterRoleBindings, RoleBinding to service account
- **API Resources**: Visual flow from service account → bindings → roles → API resources

## Key Features Illustrated

### Operator Architecture
- **Leader election**: Enabled via leases for HA deployments
- **ConfigMap watcher**: Triggers reconciliation on config changes
- **Kustomize engine**: In-process manifest rendering
- **NetworkPolicy manager**: Optional network isolation

### Managed Llama Stack Server
- **Multiple distributions**: starter (Ollama), remote-vllm, meta-reference-gpu, postgres-demo
- **Autoscaling**: HorizontalPodAutoscaler with CPU/memory targets
- **High availability**: PodDisruptionBudget, topology spread constraints
- **Storage**: PersistentVolumeClaim for model storage
- **Security**: anyuid SCC, optional NetworkPolicy, optional TLS

### Network Architecture
- **Inference providers**: Ollama (HTTP/11434), vLLM (HTTPS/8000)
- **External access**: Optional Ingress when exposeRoute: true
- **Network isolation**: Optional NetworkPolicy restricting ingress to allowed namespaces
- **Service mesh**: Optional Istio integration for mTLS

### Security Features
- **RBAC**: Fine-grained permissions for operator and managed resources
- **Secrets**: HuggingFace tokens, TLS certificates, ServiceAccount tokens
- **Container security**: runAsNonRoot, drop ALL capabilities, SELinux enforcing
- **Network policies**: Namespace-based access control
- **TLS**: Optional TLS 1.3 for Llama Stack service, TLS 1.2+ for external services

## Updating Diagrams

To regenerate after architecture changes:
```bash
# From repository root
python scripts/generate_diagram_pngs.py architecture/rhoai-3.3.0/diagrams --width=3000
```

Or use the skill (from architecture directory):
```bash
/generate-architecture-diagrams --architecture=llama-stack-k8s-operator.md
```

## Version Information

- **Operator Version**: v0.6.0 (rhoai-3.3 branch, commit 7167419)
- **Llama Stack Version**: v0.4.2
- **Distribution**: RHOAI 3.3
- **Language**: Go 1.24.6
- **Framework**: controller-runtime v0.22.4
- **Deployment Namespace**: redhat-ods-applications

## References

- **Architecture Document**: [llama-stack-k8s-operator.md](../llama-stack-k8s-operator.md)
- **Llama Stack Project**: https://github.com/meta-llama/llama-stack
- **Llama Stack Distribution (ODH)**: https://github.com/opendatahub-io/llama-stack-distribution
- **Operator Source (ODH)**: https://github.com/opendatahub-io/llama-stack-k8s-operator
- **Operator Source (RHOAI)**: https://github.com/red-hat-data-services/llama-stack-k8s-operator
- **Kubebuilder**: https://book.kubebuilder.io/
- **Controller Runtime**: https://github.com/kubernetes-sigs/controller-runtime
