# Architecture Diagrams for CodeFlare Operator

Generated from: `architecture/rhoai-2.25.0/codeflare-operator.md`
Date: 2026-03-13
Version: RHOAI 2.25.0 (CodeFlare Operator v1.15.0)

**Note**: Diagram filenames use base component name without version (directory is already versioned).

## Available Diagrams

All Mermaid diagrams are available in both `.mmd` (source) and `.png` (3000px width, high-resolution) formats.

### For Developers
- [Component Structure](./codeflare-operator-component.png) ([mmd](./codeflare-operator-component.mmd)) - Mermaid diagram showing internal components, controllers, webhooks, and managed resources
- [Data Flow - RayCluster Creation with OAuth](./codeflare-operator-dataflow.png) ([mmd](./codeflare-operator-dataflow.mmd)) - Sequence diagram for RayCluster creation flow with OpenShift OAuth
- [Data Flow - AppWrapper Scheduling](./codeflare-operator-dataflow2.png) ([mmd](./codeflare-operator-dataflow2.mmd)) - Sequence diagram for AppWrapper scheduling with Kueue
- [Data Flow - Ray Client Connection](./codeflare-operator-dataflow3.png) ([mmd](./codeflare-operator-dataflow3.mmd)) - Sequence diagram for Ray client connection with mTLS
- [Dependencies](./codeflare-operator-dependencies.png) ([mmd](./codeflare-operator-dependencies.mmd)) - Component dependency graph showing KubeRay, Kueue, and ODH integrations

### For Architects
- [C4 Context](./codeflare-operator-c4-context.dsl) - System context in C4 format (Structurizr)
- [Component Overview](./codeflare-operator-component.png) ([mmd](./codeflare-operator-component.mmd)) - High-level component view

### For Security Teams
- [Security Network Diagram (PNG)](./codeflare-operator-security-network.png) - High-resolution network topology
- [Security Network Diagram (Mermaid)](./codeflare-operator-security-network.mmd) - Visual network topology (editable)
- [Security Network Diagram (ASCII)](./codeflare-operator-security-network.txt) - Precise text format for SAR submissions
- [RBAC Visualization](./codeflare-operator-rbac.png) ([mmd](./codeflare-operator-rbac.mmd)) - RBAC permissions and bindings

## Component Overview

**CodeFlare Operator** manages distributed AI/ML workload orchestration through RayCluster and AppWrapper custom resources. It provides:

- **RayCluster Controller**: Enhances KubeRay-managed RayClusters with OAuth dashboard access, mTLS encryption, and network isolation
- **AppWrapper Controller**: Enables Kueue-based batch scheduling for grouped Kubernetes resources
- **Admission Webhooks**: Validates and mutates RayCluster and AppWrapper resources
- **Security Features**: OAuth integration (OpenShift), mTLS for Ray clients, NetworkPolicies for isolation

## Key Features Illustrated

### Component Diagram
Shows the operator's internal structure:
- Manager pod with embedded controllers
- RayCluster and AppWrapper controllers
- Mutating and validating webhooks
- Integration with KubeRay, Kueue, and ODH components

### Data Flow Diagrams
Three critical flows:
1. **RayCluster Creation with OAuth**: User creates RayCluster → Webhook validation → Controller creates Route, OAuth proxy, NetworkPolicies
2. **AppWrapper Scheduling with Kueue**: User creates AppWrapper → Kueue admission → Controller deploys wrapped resources
3. **Ray Client Connection with mTLS**: Client connects via Route → mTLS to Ray head → Distributed to workers

### Security Network Diagram
Network topology showing:
- **Trust Boundaries**: External → Ingress (DMZ) → User Namespaces → Operator Services → Control Plane
- **Ports & Protocols**: Exact specifications (443/TCP HTTPS, 10001/TCP gRPC mTLS, 8080/TCP HTTP)
- **Encryption**: TLS 1.2+ for ingress, mTLS for Ray client, plaintext for internal pod communication
- **Authentication**: OAuth Bearer tokens, mTLS client certificates, ServiceAccount tokens
- **Network Policies**: Head and worker pod isolation rules
- **RBAC Summary**: ClusterRole permissions and bindings

### Dependency Graph
Shows:
- **External Required Dependencies**: KubeRay v1.2.1, cert-controller v0.12.0, Kubernetes 1.31+
- **External Optional Dependencies**: Kueue v0.10.1+, OpenShift 4.11+
- **Internal ODH Dependencies**: ODH Dashboard, ODH Operator
- **Integration Points**: Prometheus metrics, API Server interactions

### RBAC Visualization
Complete RBAC structure:
- ServiceAccount: `controller-manager`
- ClusterRole: `manager-role` with extensive permissions (Ray CRDs, apps, networking, OpenShift routes, etc.)
- ClusterRoleBinding: `manager-rolebinding` (cluster-wide)
- Role: `leader-election-role` (namespace-scoped)

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
cd architecture/rhoai-2.25.0
# Update the architecture markdown file first
# Then regenerate diagrams (this would require running the diagram generation command)
```

## Technical Specifications Summary

**Operator Version**: 1.15.0 (RHOAI 2.25 branch)
**Language**: Go 1.25
**Deployment**: Operator (Kubernetes controller)

**Key Dependencies**:
- KubeRay Operator v1.2.1 (required)
- Kueue v0.10.1+ (optional, for batch scheduling)
- cert-controller v0.12.0 (required, for webhook TLS)
- Kubernetes 1.31+ (required)
- OpenShift 4.11+ (optional, for OAuth and Routes)

**Custom Resources**:
- AppWrapper (workload.codeflare.dev/v1beta2) - Groups resources for batch scheduling
- RayCluster (ray.io/v1) - Ray distributed computing cluster (watched, provided by KubeRay)

**Network Services**:
- Metrics Service: 8080/TCP HTTP (Prometheus)
- Webhook Service: 443/TCP → 9443/TCP HTTPS TLS 1.2+ (API Server)
- Ray Dashboard: 443/TCP HTTPS (via Route/Ingress, OAuth optional)
- Ray Client: 10001/TCP gRPC mTLS (via Route/Ingress)

**Security**:
- FIPS-compliant Go runtime
- Non-root container (UID 65532)
- mTLS for Ray client connections
- OAuth integration for Ray dashboard (OpenShift)
- NetworkPolicies for pod isolation
- TLS 1.2+ for all external communications

---

*Generated by CodeFlare Operator architecture diagram generator - 2026-03-13*
