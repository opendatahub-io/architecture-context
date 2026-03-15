# Architecture Diagrams for RHODS Operator

Generated from: `architecture/rhoai-3.0/rhods-operator.md`
Date: 2026-03-15

**Note**: Diagram filenames use base component name without version (directory is already versioned).

## Available Diagrams

All Mermaid diagrams are available in both `.mmd` (source) and `.png` (3000px width, high-resolution) formats.

### For Developers
- [Component Structure](./rhods-operator-component.png) ([mmd](./rhods-operator-component.mmd)) - Mermaid diagram showing internal components, controllers, and managed resources
- [Data Flows](./rhods-operator-dataflow.png) ([mmd](./rhods-operator-dataflow.mmd)) - Sequence diagram of DataScienceCluster creation and metrics collection flows
- [Dependencies](./rhods-operator-dependencies.png) ([mmd](./rhods-operator-dependencies.mmd)) - Component dependency graph showing external dependencies and deployed components

### For Architects
- [C4 Context](./rhods-operator-c4-context.dsl) - System context in C4 format (Structurizr) showing RHODS Operator in the broader ODH ecosystem
- [Component Overview](./rhods-operator-component.png) ([mmd](./rhods-operator-component.mmd)) - High-level component view with operator manager and controllers

### For Security Teams
- [Security Network Diagram (PNG)](./rhods-operator-security-network.png) - High-resolution network topology with trust zones
- [Security Network Diagram (Mermaid)](./rhods-operator-security-network.mmd) - Visual network topology (editable)
- [Security Network Diagram (ASCII)](./rhods-operator-security-network.txt) - Precise text format for SAR submissions with RBAC, network policies, and secrets
- [RBAC Visualization](./rhods-operator-rbac.png) ([mmd](./rhods-operator-rbac.mmd)) - RBAC permissions, service accounts, and resource access

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
Shows the RHODS Operator architecture including:
- **Operator Manager**: Main controller runtime with reconciliation loops
- **Component Controllers**: Dashboard, KServe, Ray, Pipelines, Training Operator, Workbenches, Model Registry, TrustyAI
- **Platform Controllers**: DSCInitialization, DataScienceCluster, Auth Service, Monitoring Service, Gateway Config
- **Supporting Services**: Webhook Server (admission control), Metrics Server (Prometheus integration)
- **Dependencies**: Kubernetes API, Service Mesh, Serverless, Prometheus Operator

### Data Flows
Illustrates two key operational flows:
1. **DataScienceCluster Creation**: User → K8s API → Webhook validation → DSC Controller → Component Controllers → Resource creation
2. **Metrics Collection**: Prometheus → ServiceMonitor discovery → Operator metrics endpoint → Federation to OpenShift Monitoring

### Security Network Diagram
Comprehensive network architecture showing:
- **Trust Zones**: External, Control Plane, Operator Namespace, Monitoring Namespace, Cluster Monitoring
- **Network Flows**:
  - Platform Admin → K8s API (6443/TCP HTTPS)
  - K8s API ↔ Webhook Server (9443/TCP HTTPS mTLS)
  - Operator Manager ↔ K8s API (6443/TCP HTTPS)
  - Prometheus → Metrics Endpoint (8443/TCP HTTPS)
  - OpenShift Monitoring → RHODS Prometheus (9091/TCP HTTPS federation)
- **RBAC Details**: ClusterRoles, ClusterRoleBindings, ServiceAccounts
- **Network Policies**: Ingress/egress rules for operator and monitoring namespaces
- **Secrets**: Webhook cert, Prometheus TLS, AlertManager TLS, CA bundle

### Dependencies
Visualizes component relationships:
- **External (Required)**: Kubernetes/OpenShift 4.12+
- **External (Conditional)**: Service Mesh 2.4+, Serverless 1.28+, Prometheus Operator 0.56+, Gateway API v1
- **External (Optional)**: cert-manager 1.11+
- **Deployed Components**: Dashboard, KServe, Pipelines, Ray, Training, Model Registry, TrustyAI, Workbenches, Model Controller, Feast, Llama Stack, Kueue
- **Integration Points**: K8s API, OLM, Prometheus, OpenShift Monitoring, Image Registries

### RBAC Visualization
Maps authorization flow:
- **Service Accounts**:
  - `redhat-ods-operator-controller-manager` (operator namespace)
  - `prometheus` (monitoring namespace)
- **ClusterRole**: `rhods-operator-role` with comprehensive permissions:
  - Core resources: configmaps, secrets, namespaces, pods (all verbs)
  - Apps: deployments, replicasets, statefulsets (all verbs)
  - RBAC: clusterroles, rolebindings
  - ODH CRDs: datascienceclusters, dscinitializations, components.*, services.*
  - Monitoring: servicemonitors, prometheusrules
  - Admission: webhook configurations
  - CRDs: customresourcedefinitions
- **Auth Proxy**: tokenreviews, subjectaccessreviews for kube-rbac-proxy

## Updating Diagrams

To regenerate after architecture changes:
```bash
# From repository root
claude "Generate architecture diagrams from architecture/rhoai-3.0/rhods-operator.md"
```

Or regenerate all RHOAI 3.0 component diagrams:
```bash
for arch_file in architecture/rhoai-3.0/*.md; do
  [ "$arch_file" = "architecture/rhoai-3.0/README.md" ] && continue
  [ "$arch_file" = "architecture/rhoai-3.0/PLATFORM.md" ] && continue
  claude "Generate architecture diagrams from $arch_file"
done
```

## Component Context

The RHODS Operator is the **central control plane** for Red Hat OpenShift AI (RHOAI) and Open Data Hub (ODH). Key characteristics:

- **Role**: Platform operator orchestrating data science and AI/ML component lifecycle
- **Deployment**: 3 replicas (HA), redhat-ods-operator-system namespace
- **Main CRs**:
  - `DataScienceCluster` - declares which components to enable
  - `DSCInitialization` - platform-wide settings (monitoring, service mesh, certs)
- **Managed Components**: 12+ operators/services (Dashboard, KServe, Pipelines, Ray, Training, etc.)
- **Security**: Runs as non-root (UID 1001), RBAC-protected, mTLS for webhooks and metrics
- **Observability**: Prometheus metrics, ServiceMonitors, PrometheusRules, structured JSON logging
- **HA**: Pod anti-affinity spreads replicas across nodes

## Related Documentation

- Architecture: [../rhods-operator.md](../rhods-operator.md)
- Repository: https://github.com/red-hat-data-services/rhods-operator
- Version: v1.6.0-3582-g331819fa5 (rhoai-3.0 branch)
