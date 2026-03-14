# Architecture Diagrams for ODH Dashboard

Generated from: `architecture/rhoai-2.25.0/odh-dashboard.md`
Date: 2026-03-14
Component: odh-dashboard (derived from filename)

**Note**: Diagram filenames use base component name without version (directory is already versioned).

## Available Diagrams

All Mermaid diagrams are available in both `.mmd` (source) and `.png` (3000px width, high-resolution) formats.

### For Developers
- [Component Structure](./odh-dashboard-component.png) ([mmd](./odh-dashboard-component.mmd)) - Mermaid diagram showing internal components, CRDs, dependencies, and dynamic plugins
- [Data Flows](./odh-dashboard-dataflow.png) ([mmd](./odh-dashboard-dataflow.mmd)) - Sequence diagram of request/response flows including OAuth, WebSocket, and metrics
- [Dependencies](./odh-dashboard-dependencies.png) ([mmd](./odh-dashboard-dependencies.mmd)) - Component dependency graph showing platform, runtime, ODH components, and plugins

### For Architects
- [C4 Context](./odh-dashboard-c4-context.dsl) - System context in C4 format (Structurizr)
- [Component Overview](./odh-dashboard-component.png) ([mmd](./odh-dashboard-component.mmd)) - High-level component view

### For Security Teams
- [Security Network Diagram (PNG)](./odh-dashboard-security-network.png) - High-resolution network topology
- [Security Network Diagram (Mermaid)](./odh-dashboard-security-network.mmd) - Visual network topology (editable)
- [Security Network Diagram (ASCII)](./odh-dashboard-security-network.txt) - Precise text format for SAR submissions
- [RBAC Visualization](./odh-dashboard-rbac.png) ([mmd](./odh-dashboard-rbac.mmd)) - RBAC permissions and bindings

## Component Overview

The ODH Dashboard is a web-based user interface for managing Open Data Hub and Red Hat OpenShift AI platform components. Key features:

- **Frontend**: React 18 SPA with PatternFly 6 UI components
- **Backend**: Node.js 20 Fastify REST API server
- **Authentication**: OpenShift OAuth proxy with TLS termination
- **Architecture**: Module Federation for dynamic plugin loading (gen-ai, model-registry, feature-store, etc.)
- **Integrations**: Manages notebooks, model serving, pipelines, and distributed workloads
- **Deployment**: 2 replicas with HA across availability zones

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

## Diagram Details

### Component Structure Diagram
Shows the internal architecture of ODH Dashboard including:
- Frontend (React SPA), Backend (Fastify), OAuth Proxy
- Module Federation system for dynamic plugins
- Custom resources managed (OdhApplication, OdhDashboardConfig, HardwareProfile, etc.)
- External dependencies (Kubernetes API, OAuth Server, Prometheus)
- Internal ODH integrations (notebooks, KServe, model registry, pipelines)
- Dynamic plugins (Gen AI, Model Registry, Feature Store, LM Eval)

### Data Flow Diagram
Sequence diagrams showing:
- **Flow 1**: User dashboard access via OpenShift Router → OAuth Proxy → Backend
- **Flow 2**: Dashboard API to Kubernetes (notebook creation, resource management)
- **Flow 3**: Metrics query flow (dashboard → Prometheus)
- **Flow 4**: WebSocket communication for real-time updates
- **Flow 5**: Prometheus scraping metrics endpoint

### Security Network Diagram
Detailed network topology with:
- **External (Untrusted)**: User browser accessing via HTTPS/443
- **Ingress (DMZ)**: OpenShift Router with edge TLS termination
- **Application Pod**: OAuth Proxy (8443/TCP HTTPS) → Backend (8080/TCP HTTP)
- **Control Plane**: Kubernetes API Server, OpenShift OAuth Server
- **Monitoring**: Prometheus/Thanos with metrics scraping
- **External Services**: Model Registry, Documentation URLs, Segment Analytics
- Includes RBAC summary, secrets management, service mesh configuration

### RBAC Visualization
Shows authorization model including:
- **ServiceAccount**: odh-dashboard (in redhat-ods-applications/opendatahub namespace)
- **ClusterRole**: odh-dashboard with extensive permissions
  - Core resources: configmaps, secrets, PVCs, nodes, namespaces
  - OpenShift resources: routes, consolelinks, users, groups
  - ODH CRDs: notebooks, datascienceclusters, modelregistries, inferenceservices
  - RBAC resources: rolebindings, clusterrolebindings, roles
- **ClusterRoleBindings**: odh-dashboard, odh-dashboard-image-puller, odh-dashboard-auth-delegator, odh-dashboard-monitoring
- **Aggregate Roles**: hardware-profiles-permissions, accelerator-profiles-permissions

### Dependencies Diagram
Comprehensive dependency graph showing:
- **External Platform**: OpenShift OAuth, Kubernetes API, Prometheus, Service Certificates
- **Runtime Dependencies**: Node.js 20, React 18, Fastify 4, PatternFly 6, Redux, Webpack 5
- **Internal ODH Components**: opendatahub-operator, notebooks, KServe, model-registry, pipelines, CodeFlare, Kueue
- **Dynamic Plugins**: Gen AI, Model Registry, Feature Store, LM Eval, Model Serving, Model Training
- **External Services**: S3 Storage, Segment Analytics, External Documentation

### C4 Context Diagram
Structurizr DSL showing:
- **People**: Data Scientist, Platform Admin
- **Dashboard System**: Frontend SPA, Backend API, OAuth Proxy, Module Federation
- **External Systems**: Kubernetes API, OAuth Server, Prometheus
- **Internal ODH Systems**: ODH Operator, Notebooks, KServe, Model Registry, Pipelines, CodeFlare, Kueue
- **External Services**: S3 Storage, Segment Analytics
- Relationships with protocols and authentication methods

## Updating Diagrams

To regenerate after architecture changes:

```bash
# From repository root
cd /path/to/rhoai-architecture-diagrams

# Regenerate diagrams for ODH Dashboard
# (assumes architecture/rhoai-2.25.0/odh-dashboard.md has been updated)

# Manual regeneration:
# 1. Edit the .mmd files as needed
# 2. Run PNG generation:
python scripts/generate_diagram_pngs.py architecture/rhoai-2.25.0/diagrams --width=3000

# Or use the full workflow if architecture file changed:
# (this would require the generate-architecture-diagrams skill/tool)
```

## Technical Details

### OAuth Flow
1. User accesses dashboard URL (HTTPS/443)
2. OpenShift Router forwards to OAuth Proxy (HTTPS/8443)
3. OAuth Proxy redirects unauthenticated users to OpenShift OAuth Server
4. User authenticates with OpenShift credentials
5. OAuth Server issues Bearer Token (stored in encrypted cookie)
6. OAuth Proxy validates token on subsequent requests
7. Validated requests forwarded to backend (HTTP/8080 with Bearer header)

### ServiceAccount Permissions
The `odh-dashboard` ServiceAccount has broad permissions including:
- **Read/Write**: configmaps, secrets, PVCs (for managing user resources)
- **Read**: cluster version, nodes, routes, console links (for platform integration)
- **Manage**: notebooks, model registries, serving runtimes (for data science workloads)
- **List**: users, groups (for access control and display)
- **RBAC management**: create/patch/delete role bindings (for project access control)

### High Availability
- **Replicas**: 2 pods by default
- **Pod Anti-Affinity**: Distributes pods across availability zones
- **Readiness Probe**: HTTP GET /api/health ensures traffic to healthy pods
- **Liveness Probe**: TCP socket check detects crashed processes
- **Resource Limits**: 1 CPU, 2Gi memory per container

### Module Federation
Dynamic plugin system using Webpack 5 Module Federation:
- Plugins loaded at runtime from separate bundles
- Enabled/disabled via OdhDashboardConfig feature flags
- Available plugins: gen-ai, model-registry, feature-store, lm-eval, kserve, model-serving, model-training
- Configuration via federation-configmap.yaml

## Version Information

- **Component Version**: v1.21.0-18-rhods-4281-g475248a55
- **Distribution**: Both ODH and RHOAI
- **Node.js**: 20.x
- **React**: 18.2.0
- **PatternFly**: 6.3.1
- **Fastify**: 4.28.1
- **Kubernetes Client**: @kubernetes/client-node 0.12.2

## Repository

Source: https://github.com/red-hat-data-services/odh-dashboard
