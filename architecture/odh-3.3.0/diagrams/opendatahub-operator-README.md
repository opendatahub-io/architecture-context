# Architecture Diagrams for Open Data Hub Operator

Generated from: `architecture/odh-3.3.0/opendatahub-operator.md`
Date: 2026-03-13

**Note**: Diagram filenames use base component name without version (directory is already versioned).

## Available Diagrams

All Mermaid diagrams are available in both `.mmd` (source) and `.png` (3000px width, high-resolution) formats.

### For Developers
- [Component Structure](./opendatahub-operator-component.png) ([mmd](./opendatahub-operator-component.mmd)) - Mermaid diagram showing internal components, controllers, and CRDs
- [Data Flows](./opendatahub-operator-dataflow.png) ([mmd](./opendatahub-operator-dataflow.mmd)) - Sequence diagram of reconciliation, webhook validation, and component deployment flows
- [Dependencies](./opendatahub-operator-dependencies.png) ([mmd](./opendatahub-operator-dependencies.mmd)) - Component dependency graph showing all 20+ managed components

### For Architects
- [C4 Context](./opendatahub-operator-c4-context.dsl) - System context in C4 format (Structurizr)
- [Component Overview](./opendatahub-operator-component.png) ([mmd](./opendatahub-operator-component.mmd)) - High-level component view

### For Security Teams
- [Security Network Diagram (PNG)](./opendatahub-operator-security-network.png) - High-resolution network topology
- [Security Network Diagram (Mermaid)](./opendatahub-operator-security-network.mmd) - Visual network topology (editable)
- [Security Network Diagram (ASCII)](./opendatahub-operator-security-network.txt) - Precise text format for SAR submissions
- [RBAC Visualization](./opendatahub-operator-rbac.png) ([mmd](./opendatahub-operator-rbac.mmd)) - RBAC permissions and bindings

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

## Updating Diagrams

To regenerate after architecture changes:
```bash
/generate-architecture-diagrams --architecture=../opendatahub-operator.md
```

## Diagram Descriptions

### Component Structure
Shows the internal architecture of the Open Data Hub Operator including:
- Controller Manager with leader election and 3 replicas
- 20+ component controllers (Dashboard, KServe, Ray, Pipelines, etc.)
- Service controllers (Auth, Gateway, Monitoring)
- Webhook server for admission control
- Manifest engine for Kustomize/Helm rendering
- Custom Resource Definitions (DataScienceCluster, DSCInitialization)
- Integration with OLM, cert-manager, Service Mesh, and Prometheus

### Data Flows
Sequence diagrams showing:
1. **DataScienceCluster Reconciliation**: User creates DSC → API validation → Controller reconciliation → Manifest rendering → Resource creation
2. **Component Deployment via OLM**: Controller creates Subscription → OLM installs operator → Component reconciles
3. **Webhook Validation**: User creates/updates CR → API calls webhook → Validation logic → Allow/Deny response
4. **Component Management State Change**: Update management state (Managed/Unmanaged/Removed) → Controller reacts → Resources deployed/removed

### Security Network Diagram
Detailed network topology showing:
- User access via Kubernetes API (HTTPS/443, TLS 1.2+)
- Webhook admission control (HTTPS/9443, TLS service certs)
- Controller Manager pods (3 replicas, leader-elected, non-root UID 1001)
- Metrics endpoint with kube-rbac-proxy authorization (8443→8080/TCP)
- Health check endpoints (8081/TCP, localhost only)
- Integration with OLM and container registries
- RBAC summary with ClusterRole permissions
- Secrets management (webhook TLS cert, auto-rotation)
- Security context (seccomp, dropped capabilities, non-root)

### Dependencies
Graph showing:
- **External Dependencies**: Kubernetes 1.25+, OpenShift 4.19+, OLM, Prometheus Operator
- **Optional Dependencies**: cert-manager, Kueue, LeaderWorkerSet, OpenTelemetry, Tempo, Service Mesh
- **Deployed Components**: 14 major components including KServe, Dashboard, Pipelines, Ray, Training, Model Registry, TrustyAI, Notebooks, and more
- **Cloud Integrations**: Azure AKS and CoreWeave Kubernetes support
- **External Services**: Container registry (Quay.io)

### RBAC Visualization
Visual representation of:
- **Service Accounts**: controller-manager, auth-proxy-client
- **ClusterRoles**: Broad permissions across core, apps, RBAC, ODH CRDs, OLM, monitoring, OpenShift, and networking APIs
- **API Resources**: Full CRUD on Namespaces, Services, Deployments, StatefulSets, Secrets, ConfigMaps, DSC/DSCI, component CRDs, Subscriptions, ServiceMonitors, Routes, NetworkPolicies
- **Verbs**: get, list, watch, create, update, patch, delete (read-only for ClusterVersions)

### C4 Context Diagram
Architectural context showing:
- **Users**: Data Scientists and Platform Admins
- **System**: Open Data Hub Operator with Controller Manager, Webhook Server, and Cloud Manager
- **External Systems**: Kubernetes/OpenShift, OLM, cert-manager, Service Mesh, Prometheus
- **Internal ODH Components**: Dashboard, KServe, Pipelines, Ray, Training, Model Registry, TrustyAI, Notebooks, Model Controller
- **Interactions**: CRD creation, operator deployment, manifest rendering, monitoring configuration

## Component Overview

The Open Data Hub Operator is the central control plane for the Open Data Hub and Red Hat OpenShift AI platforms. Key features:

- **20+ Managed Components**: Dashboard, KServe, Data Science Pipelines, Ray, Training Operator, Model Registry, TrustyAI, Workbenches, Feast, MLflow, Spark, and more
- **Two-Level CRD Hierarchy**: DSCInitialization (platform config) + DataScienceCluster (component management)
- **Management States**: Managed, Unmanaged, Removed for flexible component lifecycle
- **High Availability**: 3 replicas with leader election
- **Admission Control**: Validating and mutating webhooks for security enforcement
- **Manifest Rendering**: Kustomize and Helm support for component customization
- **Cloud Integration**: Azure AKS and CoreWeave support via Cloud Manager
- **Dual Distribution**: Supports Open Data Hub (community) and Red Hat OpenShift AI (product)

## Version Information

- **Component**: Open Data Hub Operator
- **Version**: 3.3.0
- **Languages**: Go 1.25.7
- **Repository**: https://github.com/opendatahub-io/opendatahub-operator
- **Platform**: Kubernetes 1.25.0+ / OpenShift 4.19+
