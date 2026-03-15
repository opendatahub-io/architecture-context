# Architecture Diagrams for CodeFlare Operator

Generated from: `architecture/rhoai-2.6/codeflare-operator.md`
Date: 2026-03-15
Component: codeflare-operator

**Note**: Diagram filenames use base component name without version (directory `rhoai-2.6/` is already versioned).

## Available Diagrams

All Mermaid diagrams are available in both `.mmd` (source) and `.png` (3000px width, high-resolution) formats.

### For Developers
- [Component Structure](./codeflare-operator-component.png) ([mmd](./codeflare-operator-component.mmd)) - Mermaid diagram showing internal components, embedded controllers (MCAD, InstaScale), CRDs, and dependencies
- [Data Flows](./codeflare-operator-dataflow.png) ([mmd](./codeflare-operator-dataflow.mmd)) - Sequence diagram of request/response flows for AppWrapper creation, InstaScale auto-scaling, and metrics collection
- [Dependencies](./codeflare-operator-dependencies.png) ([mmd](./codeflare-operator-dependencies.mmd)) - Component dependency graph showing MCAD, InstaScale, KubeRay, Machine API, and integration points

### For Architects
- [C4 Context](./codeflare-operator-c4-context.dsl) - System context in C4 format (Structurizr) showing CodeFlare Operator in the broader RHOAI ecosystem
- [Component Overview](./codeflare-operator-component.png) ([mmd](./codeflare-operator-component.mmd)) - High-level component view with MCAD queue controller and InstaScale

### For Security Teams
- [Security Network Diagram (PNG)](./codeflare-operator-security-network.png) - High-resolution network topology with trust zones
- [Security Network Diagram (Mermaid)](./codeflare-operator-security-network.mmd) - Visual network topology (editable)
- [Security Network Diagram (ASCII)](./codeflare-operator-security-network.txt) - Precise text format for SAR submissions with complete RBAC details
- [RBAC Visualization](./codeflare-operator-rbac.png) ([mmd](./codeflare-operator-rbac.mmd)) - RBAC permissions and bindings showing manager-role, instascale-role, mcad-controller-ray-clusterrole, and leader-election-role

## Component Overview

**CodeFlare Operator** manages the CodeFlare distributed workload stack including:
- **MCAD (Multi-Cluster App Dispatcher)**: Embedded queue controller (v1.38.1) for intelligent workload scheduling
- **InstaScale**: Optional embedded controller (v0.3.1) for OpenShift MachineSet auto-scaling (disabled by default)
- **AppWrapper CRDs**: Wrap generic Kubernetes resources (Pods, Jobs, Deployments, RayClusters) with scheduling policies, priority, and quotas
- **Gang Scheduling**: All-or-nothing pod scheduling for distributed workloads
- **Quota Management**: Hierarchical quota trees via QuotaSubtree CRDs

## Key Features

- **Queue-based Scheduling**: MCAD queues AppWrappers and dispatches when resources are available
- **Auto-scaling**: InstaScale (when enabled) automatically scales MachineSets based on pending workload demands
- **Ray Integration**: Primary workload type is Ray clusters for distributed AI/ML workloads
- **Priority Scheduling**: AppWrappers support priority-based scheduling with dynamic slopes
- **Requeuing**: Automatic requeuing with exponential/linear backoff when resources unavailable

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

**Example markdown usage**:
````markdown
```mermaid
<paste content of .mmd file>
```
````

**Manual PNG regeneration** (if you edit .mmd files):

1. **Ensure Mermaid CLI is installed**:
   ```bash
   npm install -g @mermaid-js/mermaid-cli
   ```

2. **Regenerate PNG** (3000px width):
   ```bash
   PUPPETEER_EXECUTABLE_PATH=/usr/bin/google-chrome mmdc -i codeflare-operator-component.mmd -o codeflare-operator-component.png -w 3000
   ```

3. **Alternative formats** (if needed):
   ```bash
   # SVG (vector, scales perfectly)
   PUPPETEER_EXECUTABLE_PATH=/usr/bin/google-chrome mmdc -i codeflare-operator-component.mmd -o codeflare-operator-component.svg

   # PDF
   PUPPETEER_EXECUTABLE_PATH=/usr/bin/google-chrome mmdc -i codeflare-operator-component.mmd -o codeflare-operator-component.pdf
   ```

**Note**: If `google-chrome` is not found, try `chromium` or `which google-chrome` to locate it

### C4 Diagrams (.dsl files)
- **Structurizr Lite**:
  ```bash
  docker run -p 8080:8080 -v $(pwd):/usr/local/structurizr structurizr/lite
  ```
  Then open http://localhost:8080 and upload the `.dsl` file

- **CLI export**:
  ```bash
  structurizr-cli export -workspace codeflare-operator-c4-context.dsl -format png
  ```

### ASCII Diagrams (.txt files)
- View in any text editor
- Include in documentation as-is
- Perfect for security reviews (precise technical details with complete RBAC breakdown)

## Architecture Highlights

### Network Architecture
- **Metrics Service**: ClusterIP on 8080/TCP (HTTP, no auth) for Prometheus scraping
- **Health Checks**: /healthz and /readyz on 8081/TCP
- **No Ingress**: Operator itself has no external ingress (creates Routes/Ingresses for Ray dashboards)

### Security
- **RBAC**: 4 ClusterRoles (manager-role, instascale-role, mcad-controller-ray-clusterrole, leader-election-role)
- **ServiceAccount**: controller-manager in opendatahub namespace
- **Container Security**: Non-root user (65532:65532), all capabilities dropped, no privilege escalation
- **FIPS Compliant**: Built with UBI8 Go toolset 1.20.10

### Data Flows
1. **AppWrapper Creation**: User creates AppWrapper → MCAD watches → queues → dispatches by creating wrapped resources
2. **InstaScale Auto-Scaling** (optional): Watches pending AppWrappers → calculates resource gap → scales MachineSets
3. **Metrics Collection**: Prometheus scrapes /metrics endpoint for queue depth and controller performance

## Dependencies

### Required
- **MCAD** (v1.38.1): Embedded queue controller
- **KubeRay Operator** (v1.0.0-rc.0): Manages Ray clusters wrapped by AppWrappers
- **Kubernetes API Server**: All watch/create/manage operations

### Optional
- **InstaScale** (v0.3.1): Embedded auto-scaler (disabled by default)
- **OpenShift Machine API**: Required when InstaScale is enabled
- **CodeFlare SDK** (v0.12.1): Python client library for users
- **Prometheus**: Metrics collection

## Updating Diagrams

To regenerate after architecture changes:

```bash
# From repository root
python scripts/generate_diagram_pngs.py architecture/rhoai-2.6/diagrams/ --width=3000
```

Or regenerate from source:
```bash
# This would be the hypothetical command if you have the full diagram generation skill
/generate-architecture-diagrams --architecture=architecture/rhoai-2.6/codeflare-operator.md
```

## Related Documentation

- **Source Architecture**: [../codeflare-operator.md](../codeflare-operator.md)
- **Repository**: https://github.com/red-hat-data-services/codeflare-operator.git
- **Version**: cff798d (rhoai-2.6 branch)
- **RHOAI Platform Docs**: [../PLATFORM.md](../PLATFORM.md)
