# Architecture Diagrams for RHOAI Operator (rhods-operator)

Generated from: `architecture/rhoai-2.15/rhods-operator.md`
Date: 2026-03-15

**Note**: Diagram filenames use base component name without version (directory is already versioned).

## Available Diagrams

All Mermaid diagrams are available in both `.mmd` (source) and `.png` (3000px width, high-resolution) formats.

### For Developers
- [Component Structure](./rhods-operator-component.png) ([mmd](./rhods-operator-component.mmd)) - Mermaid diagram showing internal components, controllers, and managed components
- [Data Flows](./rhods-operator-dataflow.png) ([mmd](./rhods-operator-dataflow.mmd)) - Sequence diagram of DataScienceCluster deployment, platform initialization, metrics collection, and webhook validation flows
- [Dependencies](./rhods-operator-dependencies.png) ([mmd](./rhods-operator-dependencies.mmd)) - Component dependency graph showing required, conditional, and optional dependencies

### For Architects
- [C4 Context](./rhods-operator-c4-context.dsl) - System context in C4 format (Structurizr) showing RHOAI Operator in broader ecosystem
- [Component Overview](./rhods-operator-component.png) ([mmd](./rhods-operator-component.mmd)) - High-level view of operator architecture and managed components

### For Security Teams
- [Security Network Diagram (PNG)](./rhods-operator-security-network.png) - High-resolution network topology with trust zones
- [Security Network Diagram (Mermaid)](./rhods-operator-security-network.mmd) - Visual network topology (editable)
- [Security Network Diagram (ASCII)](./rhods-operator-security-network.txt) - Precise text format for SAR submissions with RBAC, secrets, network policies, and resource requirements
- [RBAC Visualization](./rhods-operator-rbac.png) ([mmd](./rhods-operator-rbac.mmd)) - RBAC permissions and bindings showing cluster-wide permissions

## Component Overview

The RHOAI Operator (rhods-operator) is the central operator for Red Hat OpenShift AI and Open Data Hub platforms. Key responsibilities:

- **DataScienceCluster Controller**: Deploys and manages all data science components (Dashboard, KServe, ModelMesh, Pipelines, etc.)
- **DSCInitialization Controller**: Initializes platform infrastructure (monitoring, service mesh, namespaces, trusted CAs)
- **Webhook Server**: Validates and mutates DataScienceCluster and DSCInitialization resources
- **SecretGenerator & CertGenerator**: Manages component secrets and TLS certificates
- **Monitoring Stack**: Deploys Prometheus, Alertmanager, and metrics federation

### Managed Components

The operator deploys and manages 11 major components:
1. ODH Dashboard - Web UI for data science workflows
2. Workbenches - Jupyter notebooks and IDE environments
3. KServe - Serverless model serving
4. ModelMesh - Multi-model serving infrastructure
5. Data Science Pipelines - Kubeflow Pipelines
6. CodeFlare - Distributed workload management
7. Ray Operator - Ray cluster operator
8. Kueue - Job queueing system
9. Training Operator - Distributed training frameworks
10. TrustyAI - AI explainability and bias detection
11. Model Registry - Model metadata and versioning

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
   PUPPETEER_EXECUTABLE_PATH=/usr/bin/google-chrome mmdc -i rhods-operator-component.mmd -o rhods-operator-component.png -w 3000
   ```

3. **Alternative formats** (if needed):
   ```bash
   # SVG (vector, scales perfectly)
   PUPPETEER_EXECUTABLE_PATH=/usr/bin/google-chrome mmdc -i rhods-operator-component.mmd -o rhods-operator-component.svg

   # PDF
   PUPPETEER_EXECUTABLE_PATH=/usr/bin/google-chrome mmdc -i rhods-operator-component.mmd -o rhods-operator-component.pdf
   ```

**Note**: If `google-chrome` is not found, try `chromium` or `which google-chrome` to locate it

### C4 Diagrams (.dsl files)
- **Structurizr Lite**:
  ```bash
  docker run -p 8080:8080 -v $(pwd):/usr/local/structurizr structurizr/lite
  ```
  Then navigate to http://localhost:8080

- **CLI export**:
  ```bash
  structurizr-cli export -workspace rhods-operator-c4-context.dsl -format png
  ```

### ASCII Diagrams (.txt files)
- View in any text editor
- Include in documentation as-is
- Perfect for security reviews (precise technical details)

## Key Architecture Highlights

### Security
- **RBAC**: Highly privileged ClusterRole with cluster-wide permissions
- **Network Policies**: Restricts ingress to monitoring, console, and generated namespaces
- **TLS**: All external endpoints use TLS 1.2+ with auto-rotating Service CA certificates
- **Webhook Security**: K8s API Server mTLS for admission control

### Network Architecture
- **Operator Metrics**: 8443/TCP (HTTP with kube-rbac-proxy, Bearer Token auth)
- **Webhook Service**: 9443/TCP (HTTPS, K8s API Server mTLS)
- **Health Checks**: 8081/TCP (HTTP, no auth for liveness/readiness)
- **Monitoring Stack**: Prometheus (9090/10443), Alertmanager (10443), Blackbox Exporter (9115)

### Dependencies
- **Required**: Kubernetes/OpenShift 1.28+
- **Conditional**: Service Mesh (for KServe/ModelMesh), Knative (for KServe), Authorino (for auth)
- **Optional**: Prometheus Operator, Cert Manager

### Custom Resources
- **DataScienceCluster**: Declares which components to enable/disable
- **DSCInitialization**: Configures platform infrastructure
- **FeatureTracker**: Tracks feature usage and component state

## Updating Diagrams

To regenerate after architecture changes:

```bash
# From repository root
cd architecture/rhoai-2.15

# Update the architecture markdown
vim rhods-operator.md

# Regenerate diagrams (from repo root)
# Note: This would require the diagram generation skill/tool to be run
```

## Related Documentation

- [Architecture Documentation](../rhods-operator.md) - Full component architecture
- [Platform Overview](../PLATFORM.md) - RHOAI platform architecture
- [Component Repository](https://github.com/red-hat-data-services/rhods-operator) - Source code

## Diagram Legend

### Color Coding
- **Blue (#4a90e2)**: Operator components and controllers
- **Orange (#f5a623)**: Custom Resources and role bindings
- **Green (#7ed321)**: Managed data science components
- **Gray (#e8e8e8, #999)**: External dependencies
- **Light Blue (#dae8fc)**: Monitoring and infrastructure
- **Yellow (#fff2cc)**: RBAC and security resources

### Network Diagrams - Trust Zones
- **External (Untrusted)**: User/CI access points
- **Kubernetes API Server (Trusted Control Plane)**: API server and RBAC enforcement
- **Operator Namespace**: RHOAI Operator components
- **Monitoring Namespace**: Prometheus, Alertmanager, exporters
- **Component Namespaces**: Generated namespaces for data science components
- **External Dependencies**: Service Mesh, Knative, Authorino
