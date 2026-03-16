# Architecture Diagrams for Llama Stack Kubernetes Operator

Generated from: `architecture/rhoai-3.0/llama-stack-k8s-operator.md`
Date: 2026-03-16

**Note**: Diagram filenames use base component name without version (directory is already versioned).

## Available Diagrams

All Mermaid diagrams are available in both `.mmd` (source) and `.png` (3000px width, high-resolution) formats.

### For Developers
- [Component Structure](./llama-stack-k8s-operator-component.png) ([mmd](./llama-stack-k8s-operator-component.mmd)) - Mermaid diagram showing internal components, CRDs, and managed resources
- [Data Flows](./llama-stack-k8s-operator-dataflow.png) ([mmd](./llama-stack-k8s-operator-dataflow.mmd)) - Sequence diagram of LlamaStackDistribution creation, health checks, inference requests, and metrics collection
- [Dependencies](./llama-stack-k8s-operator-dependencies.png) ([mmd](./llama-stack-k8s-operator-dependencies.mmd)) - Component dependency graph showing Kubernetes, inference providers, and external services

### For Architects
- [C4 Context](./llama-stack-k8s-operator-c4-context.dsl) - System context in C4 format (Structurizr) showing operator, managed resources, and inference providers
- [Component Overview](./llama-stack-k8s-operator-component.png) ([mmd](./llama-stack-k8s-operator-component.mmd)) - High-level component view with operator controller and managed deployments

### For Security Teams
- [Security Network Diagram (PNG)](./llama-stack-k8s-operator-security-network.png) - High-resolution network topology with trust zones
- [Security Network Diagram (Mermaid)](./llama-stack-k8s-operator-security-network.mmd) - Visual network topology (editable)
- [Security Network Diagram (ASCII)](./llama-stack-k8s-operator-security-network.txt) - Precise text format for SAR submissions with RBAC summary, network policies, and deployment configuration
- [RBAC Visualization](./llama-stack-k8s-operator-rbac.png) ([mmd](./llama-stack-k8s-operator-rbac.mmd)) - RBAC permissions and bindings for operator and managed resources

## Component Overview

The Llama Stack Kubernetes Operator automates the deployment and lifecycle management of Llama Stack AI inference servers. It provides a declarative, Kubernetes-native approach through the LlamaStackDistribution CRD to manage multiple inference backend distributions including Ollama, vLLM, TGI, Bedrock, and Together AI.

### Key Features
- **Multiple Distribution Support**: Ollama, vLLM, TGI, Bedrock, Together, vLLM-GPU, and custom images
- **Automated Resource Management**: Creates Deployments, Services, NetworkPolicies, and PVCs
- **Storage Provisioning**: Configurable persistent storage for model artifacts (default: 10Gi)
- **Network Isolation**: NetworkPolicy-based ingress restrictions
- **Health Monitoring**: Automated health checks via /providers endpoint
- **Metrics**: Prometheus integration via ServiceMonitor
- **Security**: Non-root execution, capability dropping, OpenShift SCC support

### Architecture Highlights
- **Operator Namespace**: redhat-ods-applications
- **Managed Resources**: Per-namespace LlamaStackDistribution instances
- **API Port**: 8321/TCP (HTTP, no auth - protected by NetworkPolicy)
- **Metrics Port**: 8443/TCP (HTTPS, Bearer Token via kube-rbac-proxy)
- **Health Probes**: 8081/TCP (/healthz, /readyz)

### Network Security
- **External Access**: None by default (no Ingress created)
- **Internal Access**: NetworkPolicy restricts ingress to:
  - Pods with label `app.kubernetes.io/part-of=llama-stack`
  - Operator namespace (redhat-ods-applications)
- **Egress**: Unrestricted (allows downloads from HuggingFace, container registries)

### Supported Distributions

| Distribution | Image | Port | Use Case |
|--------------|-------|------|----------|
| ollama | llamastack/distribution-ollama:latest | 11434 | Ollama-based inference |
| vllm | llamastack/distribution-remote-vllm:latest | 8000 | Remote vLLM inference |
| tgi | llamastack/distribution-tgi:latest | 8080 | HuggingFace TGI |
| bedrock | llamastack/distribution-bedrock:latest | - | AWS Bedrock integration |
| together | llamastack/distribution-together:latest | - | Together AI integration |
| vllm-gpu | llamastack/distribution-vllm-gpu:latest | 8000 | GPU-accelerated vLLM |
| custom | User-specified | varies | Custom distribution |

## How to Use

### PNG Files (.png files)
**Automatically generated** at 3000px width for high-resolution presentations and documentation.

- **Ready to use**: High-resolution images suitable for presentations, wikis, and documentation
- **Width**: 3000px (height auto-adjusts to content)
- **Use directly**: Include in PowerPoint, Google Slides, Confluence, etc.

### Mermaid Source Files (.mmd files)
- **In GitHub/GitLab**: Paste into markdown with ` ```mermaid` code blocks - renders automatically!
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
- **Online**: Upload to https://structurizr.com/

### ASCII Diagrams (.txt files)
- View in any text editor
- Include in documentation as-is
- Perfect for security reviews (precise technical details)
- Contains RBAC summary, network policies, and deployment configuration

## Diagram Details

### Component Structure Diagram
Shows the operator's internal components and how they interact:
- Operator Controller Manager and sub-controllers
- LlamaStackDistribution CRD lifecycle
- Managed resources (Deployments, Services, PVCs, NetworkPolicies)
- External dependencies (Kubernetes API, Prometheus, inference providers)

### Data Flow Diagram
Illustrates four key operational flows:
1. **LlamaStackDistribution Creation**: User creates CR → Operator creates resources
2. **Health Check**: Operator queries /providers endpoint → Updates status
3. **Inference Request**: Client → Service → Pod → Inference Provider → Response
4. **Metrics Collection**: Prometheus → kube-rbac-proxy → Operator

### Security Network Diagram
**ASCII version** (for SAR documentation):
- Precise port numbers, protocols, and encryption details
- Trust zone boundaries (External, K8s API, Operator, User Namespaces)
- Complete RBAC summary with permissions matrix
- NetworkPolicy rules and enforcement points
- Deployment configuration and security context

**Mermaid version** (for presentations):
- Visual representation with color-coded trust zones
- Same network architecture as ASCII version
- Interactive and editable

### Dependencies Diagram
Maps all operator dependencies:
- **Required**: Kubernetes 1.20+, controller-runtime v0.20+, Kustomize (embedded)
- **Optional**: Prometheus Operator, OpenShift SCC
- **Inference Providers**: Ollama, vLLM, TGI, Bedrock, Together (one required)
- **External Services**: Container registries, HuggingFace Hub

### RBAC Visualization
Complete RBAC model showing:
- **Service Accounts**: controller-manager, managed instance SAs
- **ClusterRoles**: manager-role (main), leader-election-role, metrics-reader, editor/viewer
- **Permissions**: Full permission breakdown by API group and resource
- **Bindings**: ClusterRoleBindings and RoleBindings

### C4 Context Diagram
Strategic architecture view:
- **People**: Data Scientists/ML Engineers, Platform Administrators
- **Systems**: Operator, Kubernetes, inference providers, external services
- **Containers**: Controller Manager, kube-rbac-proxy, managed Llama Stack servers
- **Components**: Internal controller components (LlamaStackDistribution Controller, Kustomize Transformer, etc.)

## Updating Diagrams

To regenerate after architecture changes:

```bash
# From repository root
cd architecture/rhoai-3.0

# Regenerate diagrams (automatically detects output directory)
# This will:
# 1. Read llama-stack-k8s-operator.md
# 2. Generate all diagram formats in diagrams/ directory
# 3. Auto-generate PNG files at 3000px width
# 4. Update this README
<command to regenerate>
```

## Related Documentation

- **Architecture Source**: [llama-stack-k8s-operator.md](../llama-stack-k8s-operator.md)
- **Repository**: https://github.com/red-hat-data-services/llama-stack-k8s-operator
- **Version**: v0.4.0
- **Distribution**: RHOAI 3.0

## Version Information

- **Operator Version**: v0.4.0
- **Go Version**: 1.24
- **controller-runtime**: v0.20+
- **Base Image**: UBI9 Go toolset 1.24
- **Kubernetes**: 1.20+
