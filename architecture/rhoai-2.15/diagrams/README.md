# Architecture Diagrams for ODH Dashboard

Generated from: `architecture/rhoai-2.15/odh-dashboard.md`
Date: 2026-03-15

**Note**: Diagram filenames use base component name without version (directory is already versioned).

## Available Diagrams

All Mermaid diagrams are available in both `.mmd` (source) and `.png` (3000px width, high-resolution) formats.

### For Developers
- [Component Structure](./odh-dashboard-component.png) ([mmd](./odh-dashboard-component.mmd)) - Mermaid diagram showing internal components
- [Data Flows](./odh-dashboard-dataflow.png) ([mmd](./odh-dashboard-dataflow.mmd)) - Sequence diagram of request/response flows
- [Dependencies](./odh-dashboard-dependencies.png) ([mmd](./odh-dashboard-dependencies.mmd)) - Component dependency graph

### For Architects
- [C4 Context](./odh-dashboard-c4-context.dsl) - System context in C4 format (Structurizr)
- [Component Overview](./odh-dashboard-component.png) ([mmd](./odh-dashboard-component.mmd)) - High-level component view

### For Security Teams
- [Security Network Diagram (PNG)](./odh-dashboard-security-network.png) - High-resolution network topology
- [Security Network Diagram (Mermaid)](./odh-dashboard-security-network.mmd) - Visual network topology (editable)
- [Security Network Diagram (ASCII)](./odh-dashboard-security-network.txt) - Precise text format for SAR submissions
- [RBAC Visualization](./odh-dashboard-rbac.png) ([mmd](./odh-dashboard-rbac.mmd)) - RBAC permissions and bindings

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
/generate-architecture-diagrams --architecture=../odh-dashboard.md
```

## Diagram Descriptions

### Component Structure (odh-dashboard-component.mmd)
Shows the internal architecture of the ODH Dashboard including:
- React Frontend with PatternFly UI components
- Node.js/Fastify Backend API server
- OAuth Proxy sidecar for authentication
- Custom Resources managed (OdhDashboardConfig, OdhApplication, etc.)
- External dependencies (Kubernetes API, OAuth Server, Prometheus, Image Registry)
- Internal ODH component integrations (KServe, Notebooks, Model Registry, etc.)

### Data Flows (odh-dashboard-dataflow.mmd)
Sequence diagrams showing:
- **User Login Flow**: OAuth authentication via OpenShift OAuth Server
- **API Request Flow**: Creating notebooks through Kubernetes API
- **Metrics Collection**: Prometheus scraping /metrics endpoint
- **Dashboard Configuration Query**: Reading OdhDashboardConfig CRs

All flows include detailed port numbers, protocols, encryption methods, and authentication mechanisms.

### Security Network Diagram (odh-dashboard-security-network.txt/.mmd)
Detailed network topology for Security Architecture Reviews:
- **ASCII version (.txt)**: Precise text format with complete RBAC details, secrets, and deployment configuration
- **Mermaid version (.mmd)**: Visual diagram with color-coded trust zones

Includes:
- External ingress path (443/TCP HTTPS)
- OpenShift Route with TLS reencrypt
- OAuth Proxy authentication layer (8443/TCP)
- Backend API server (8080/TCP)
- Egress to Kubernetes API, Prometheus, Image Registry, and partner services
- Complete RBAC summary (ClusterRole, Role, bindings)
- Secret management (TLS certs, OAuth config)
- Deployment configuration (replicas, health checks, resources)

### C4 Context Diagram (odh-dashboard-c4-context.dsl)
System context showing:
- **Users**: Data Scientists and Platform Administrators
- **Dashboard Containers**: Frontend, Backend, OAuth Proxy
- **External Systems**: Kubernetes API, OpenShift OAuth Server, Prometheus, Image Registry, Console
- **Internal ODH Systems**: DSC/DSCI Operators, KServe, Notebooks, Model Registry
- **Partner Systems**: ISV applications

### Component Dependencies (odh-dashboard-dependencies.mmd)
Dependency graph showing:
- **External Dependencies**: Node.js, React, Fastify, PatternFly, Kubernetes client libraries
- **Platform Dependencies**: Kubernetes API, OAuth Server, Prometheus, Image Registry, Build Service
- **Internal ODH Dependencies**: DSC/DSCI Operators, KServe, Notebooks, Model Registry
- **Custom Resources**: CRDs defined and managed by the dashboard
- **Partner Integrations**: ISV application validation

### RBAC Visualization (odh-dashboard-rbac.mmd)
Complete RBAC structure:
- **Service Account**: odh-dashboard
- **ClusterRole**: odh-dashboard (cluster-wide permissions)
- **Role**: odh-dashboard (namespace-scoped permissions)
- **ClusterRoleBindings**: 4 bindings (dashboard, monitoring, auth-delegator, image-puller)
- **RoleBinding**: 1 namespace-scoped binding
- **API Resources**: Detailed permissions for all accessed resources
  - Core API (nodes, configmaps, secrets, namespaces, etc.)
  - Storage API (storageclasses)
  - Machine API (machinesets, autoscalers)
  - OpenShift APIs (routes, consoles, images, builds, users)
  - ODH APIs (datascienceclusters, notebooks, inferenceservices, modelregistries)
  - Dashboard-specific APIs (acceleratorprofiles, odhdashboardconfigs, etc.)

## Architecture Summary

The ODH Dashboard is a web-based management console for Open Data Hub and Red Hat OpenShift AI. It provides:

**Key Components**:
- React-based frontend with PatternFly components for consistent OpenShift UX
- Node.js/Fastify backend for Kubernetes API operations
- OpenShift OAuth Proxy for SSO authentication

**Primary Functions**:
- Manage data science projects and namespaces
- Launch and configure Jupyter notebooks
- Deploy and monitor ML models (KServe, ModelMesh)
- Configure GPU/accelerator profiles
- Manage data connections and storage
- Access integrated partner applications
- Platform configuration and user permissions

**Security**:
- All access authenticated via OpenShift OAuth
- Fine-grained RBAC permissions
- TLS encryption for all external communications
- Service account-based Kubernetes API access

**Integration**:
- Monitors platform status via DSC/DSCI operators
- Manages notebooks, inference services, and model registries
- Integrates with OpenShift console, image registry, and build service
- Validates ISV partner applications

**Deployment**:
- 2 replicas with pod anti-affinity for high availability
- Resource requests/limits: 500m-1000m CPU, 1Gi-2Gi memory
- Health checks on both frontend and backend containers
- Separate deployment variants for ODH, RHOAI Add-on, and RHOAI On-Premise
