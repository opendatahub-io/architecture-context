# Architecture Diagrams for RHODS Operator

Generated from: `architecture/rhoai-2.17/rhods-operator.md`
Date: 2026-03-16

**Note**: Diagram filenames use base component name without version (directory is already versioned).

## Available Diagrams

All Mermaid diagrams are available in both `.mmd` (source) and `.png` (3000px width, high-resolution) formats.

### For Developers
- [Component Structure](./rhods-operator-component.png) ([mmd](./rhods-operator-component.mmd)) - Mermaid diagram showing internal components and controllers
- [Data Flows](./rhods-operator-dataflow.png) ([mmd](./rhods-operator-dataflow.mmd)) - Sequence diagram of request/response flows
- [Dependencies](./rhods-operator-dependencies.png) ([mmd](./rhods-operator-dependencies.mmd)) - Component dependency graph

### For Architects
- [C4 Context](./rhods-operator-c4-context.dsl) - System context in C4 format (Structurizr)
- [Component Overview](./rhods-operator-component.png) ([mmd](./rhods-operator-component.mmd)) - High-level component view

### For Security Teams
- [Security Network Diagram (PNG)](./rhods-operator-security-network.png) - High-resolution network topology
- [Security Network Diagram (Mermaid)](./rhods-operator-security-network.mmd) - Visual network topology (editable)
- [Security Network Diagram (ASCII)](./rhods-operator-security-network.txt) - Precise text format for SAR submissions
- [RBAC Visualization](./rhods-operator-rbac.png) ([mmd](./rhods-operator-rbac.mmd)) - RBAC permissions and bindings

## Component Overview

The RHODS Operator is the primary orchestration component for Red Hat OpenShift AI (RHOAI). It manages the lifecycle of data science platform components through:

- **Core Controllers**: DataScienceCluster and DSCInitialization controllers
- **Component Controllers**: 12 controllers managing Dashboard, Workbenches, KServe, ModelMesh, DSP, Ray, CodeFlare, TrustyAI, Training Operator, Kueue, Model Registry, and Model Controller
- **Service Controllers**: Auth and Monitoring service management
- **Utility Controllers**: Secret generation, certificate management, and setup tasks
- **Webhook Server**: Validation and mutation of cluster configurations

## Key Features

- **Declarative Configuration**: Uses DataScienceCluster CRD to configure all components
- **Platform Initialization**: DSCInitialization configures service mesh, monitoring, and authentication
- **Multi-Component Management**: Deploys and manages 12+ data science components
- **Monitoring Integration**: Built-in Prometheus and Alertmanager deployment
- **Security**: NetworkPolicies, RBAC, webhook validation, OAuth-protected metrics
- **Platform Detection**: Adapts behavior for ManagedRhoai, SelfManagedRhoai, or OpenDataHub

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

## Network Architecture

### Services Exposed
- **Webhook Service**: 443/TCP (HTTPS, internal, K8s API Server only)
- **Prometheus**: 9091/TCP (HTTPS, OAuth-protected, internal route)
- **Alertmanager**: 9093/TCP (HTTPS, OAuth-protected, internal route)
- **Metrics Endpoint**: 8080/TCP (HTTP, internal, monitoring namespaces only)
- **Health Endpoints**: 8081/TCP (HTTP, kubelet only)

### Network Policies
- **Operator Namespace**: Restricted access from monitoring, console, and user workload namespaces
- **Monitoring Namespace**: Isolated, allows ingress from monitoring systems
- **Applications Namespace**: Isolated, allows ingress from ingress controller and monitoring

### Security Features
- **mTLS**: Webhook communication with K8s API Server
- **OAuth Proxy**: Protects Prometheus and Alertmanager UIs
- **Service CA**: Automatic TLS certificate provisioning
- **RBAC**: Comprehensive ClusterRole for operator with least-privilege service accounts
- **NetworkPolicies**: Namespace isolation and traffic control
- **Webhook Validation**: Pre-admission validation of DataScienceCluster and DSCInitialization

## RBAC Summary

### ClusterRole: rhods-operator-role
Grants permissions to manage:
- **Core Resources**: Deployments, Services, ConfigMaps, Secrets, Namespaces, RBAC
- **ODH CRDs**: DataScienceCluster, DSCInitialization, Component CRs, Service CRs, FeatureTrackers
- **Platform Resources**: Routes, CRDs, Webhooks, ServiceMonitors, PrometheusRules, NetworkPolicies
- **External Dependencies**: Authorino AuthConfigs

### Service Account
- **Namespace**: redhat-ods-operator
- **Name**: redhat-ods-operator-controller-manager
- **Bound to**: rhods-operator-role (ClusterRole)

## Dependencies

### External (Required)
- Kubernetes 1.25+
- OpenShift 4.11+

### External (Conditional)
- Service Mesh Operator (Istio) - Required for KServe
- Serverless Operator (Knative) - Required for KServe
- Authorino Operator - Required for KServe authentication

### External (Optional)
- cert-manager - Optional certificate management

### Internal Components (Deployed by Operator)
- ODH Dashboard
- Jupyter Workbenches
- KServe
- ModelMesh Serving
- Data Science Pipelines
- Ray
- CodeFlare
- TrustyAI
- Training Operator
- Kueue
- Model Registry
- Model Controller

## Updating Diagrams

To regenerate after architecture changes:
```bash
# Using the diagram generation skill (if available)
/generate-architecture-diagrams --architecture=architecture/rhoai-2.17/rhods-operator.md

# Or manually with Python script
python scripts/generate_diagram_pngs.py architecture/rhoai-2.17/diagrams --width=3000
```

## Related Documentation

- [RHODS Operator Architecture](../rhods-operator.md) - Full architecture documentation
- [RHOAI Platform Overview](../PLATFORM.md) - Platform-level architecture
- [Component Architectures](../) - Individual component documentation

## Version Information

- **Component**: RHODS Operator
- **Version**: v1.6.0-4171-ge2d77a515
- **Branch**: rhoai-2.17
- **Distribution**: RHOAI
- **Repository**: https://github.com/red-hat-data-services/rhods-operator.git
