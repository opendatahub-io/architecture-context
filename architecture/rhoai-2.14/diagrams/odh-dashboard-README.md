# Architecture Diagrams for ODH Dashboard

Generated from: `architecture/rhoai-2.14/odh-dashboard.md`
Date: 2026-03-15

**Note**: Diagram filenames use base component name without version (directory is already versioned).

## Available Diagrams

All Mermaid diagrams are available in both `.mmd` (source) and `.png` (3000px width, high-resolution) formats.

### For Developers
- [Component Structure](./odh-dashboard-component.png) ([mmd](./odh-dashboard-component.mmd)) - Mermaid diagram showing internal components, CRDs, and integrations
- [Data Flows](./odh-dashboard-dataflow.png) ([mmd](./odh-dashboard-dataflow.mmd)) - Sequence diagram of authentication, API requests, and WebSocket flows
- [Dependencies](./odh-dashboard-dependencies.png) ([mmd](./odh-dashboard-dependencies.mmd)) - Component dependency graph showing external and internal ODH dependencies

### For Architects
- [C4 Context](./odh-dashboard-c4-context.dsl) - System context in C4 format (Structurizr) showing users, external systems, and ODH components
- [Component Overview](./odh-dashboard-component.png) ([mmd](./odh-dashboard-component.mmd)) - High-level component view with pod structure

### For Security Teams
- [Security Network Diagram (PNG)](./odh-dashboard-security-network.png) - High-resolution network topology
- [Security Network Diagram (Mermaid)](./odh-dashboard-security-network.mmd) - Visual network topology (editable)
- [Security Network Diagram (ASCII)](./odh-dashboard-security-network.txt) - Precise text format for SAR submissions with RBAC, secrets, and auth flows
- [RBAC Visualization](./odh-dashboard-rbac.png) ([mmd](./odh-dashboard-rbac.mmd)) - RBAC permissions and bindings for ClusterRole and namespace-scoped Roles

## Component Overview

**ODH Dashboard** is the central web console for Red Hat OpenShift AI (RHOAI) and Open Data Hub (ODH) platforms. It provides:

- **Web UI**: React/TypeScript SPA with PatternFly components
- **Backend API**: Node.js/Fastify with 39+ REST endpoints
- **Authentication**: OpenShift OAuth proxy integration
- **Resource Management**: Kubernetes API integration for notebooks, models, pipelines
- **Monitoring**: Prometheus/Thanos metrics integration

**Key Features**:
- Jupyter notebook lifecycle management
- Model serving deployment UI (KServe/ModelMesh)
- Data science pipelines integration
- Model registry management
- Accelerator profile configuration
- Multi-tenancy with RBAC

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

## Architecture Highlights

### Network Flow
1. **User → OpenShift Route (443/TCP HTTPS)** - External access with TLS 1.2+
2. **Route → oauth-proxy (8443/TCP HTTPS)** - TLS reencryption with service cert
3. **oauth-proxy → OpenShift OAuth** - User authentication via OAuth 2.0
4. **oauth-proxy → backend (8080/TCP HTTP)** - Pod-local communication with Bearer token
5. **backend → Kubernetes API (6443/TCP HTTPS)** - Resource management with ServiceAccount token

### Security Features
- **Authentication**: OpenShift OAuth 2.0 with session cookies
- **Authorization**: Kubernetes RBAC enforced at API server
- **Encryption**: TLS 1.2+ for all external communication
- **Secrets**: Auto-rotating service certs, OAuth client credentials
- **RBAC**: ClusterRole for cluster-wide resources + namespace-scoped Role

### High Availability
- **Replicas**: 2 pods for HA
- **Anti-affinity**: Zone-based topology spread
- **Health checks**: Liveness (TCP) and Readiness (HTTP) probes
- **Resource limits**: 1 CPU, 2Gi memory per container

## Updating Diagrams

To regenerate after architecture changes:
```bash
# Update the architecture markdown first
vim architecture/rhoai-2.14/odh-dashboard.md

# Then regenerate diagrams
/generate-architecture-diagrams --architecture=architecture/rhoai-2.14/odh-dashboard.md
```

## Related Documentation
- Architecture source: [odh-dashboard.md](../odh-dashboard.md)
- Repository: https://github.com/red-hat-data-services/odh-dashboard.git
- Version: v1.21.0-18-rhods-2393-gcb94ecb33
- Branch: rhoai-2.14
