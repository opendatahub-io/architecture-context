# Architecture Diagrams for ODH Dashboard

Generated from: `architecture/rhoai-2.12/odh-dashboard.md`
Date: 2026-03-15
Component: odh-dashboard

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

## Diagram Descriptions

### Component Structure
Shows the internal architecture of ODH Dashboard including:
- Frontend (React/PatternFly)
- Backend (Node.js Fastify)
- OAuth Proxy (OpenShift OAuth)
- Custom Resource Definitions (CRDs)
- Integration with external and internal ODH components

### Data Flows
Illustrates the complete request/response flows:
1. User access dashboard (OAuth authentication)
2. Dashboard to Kubernetes API
3. Dashboard to Data Science Pipelines
4. Dashboard to Model Registry
5. Dashboard to TrustyAI Service
6. Dashboard to Prometheus

### Security Network Diagram
Detailed network topology with:
- Exact port numbers and protocols
- TLS/encryption details
- Authentication mechanisms
- Trust boundaries (external, ingress, service mesh)
- RBAC summary
- Secrets and certificates
- Network policies

Available in three formats:
- **Mermaid (.mmd)**: Visual, color-coded, great for presentations
- **PNG (.png)**: High-resolution image for documentation
- **ASCII (.txt)**: Precise text format, no ambiguity, required for Security Architecture Reviews

### Dependencies
Visualizes all dependencies:
- External dependencies (Node.js, React, OAuth Proxy, etc.)
- External infrastructure (Kubernetes API, OpenShift OAuth)
- Internal ODH components (Pipelines, Model Registry, KServe, etc.)
- Integration points

### RBAC Visualization
Shows the complete RBAC structure:
- Service Account: odh-dashboard
- ClusterRoles and bindings
- Namespace Roles and bindings
- Permissions for each role
- Resources accessed

### C4 Context Diagram
System context showing:
- Users (Data Scientists, Platform Administrators)
- ODH Dashboard containers (Frontend, Backend, OAuth Proxy)
- External systems (Kubernetes API, OpenShift OAuth, Prometheus)
- Internal ODH components
- Deployment architecture

## Updating Diagrams

To regenerate after architecture changes:
```bash
# From repository root
python scripts/generate_diagram_pngs.py architecture/rhoai-2.12/diagrams --width=3000
```

## Component Details

**ODH Dashboard** is the central web-based UI for managing and interacting with Open Data Hub and Red Hat OpenShift AI platform components.

Key features:
- Unified web console for data scientists and administrators
- Manages projects, workbenches, model serving, pipelines
- Integrates with OpenShift OAuth for authentication
- Built with PatternFly React components
- Proxies requests to various backend services
- Manages custom resources (notebooks, serving runtimes, accelerator profiles)

**Architecture**:
- Frontend: React/PatternFly web application
- Backend: Node.js Fastify REST API server
- OAuth Proxy: OpenShift OAuth authentication layer
- Deployment: 2 replicas with zone-based anti-affinity for high availability

**Version**: v1.21.0-18-rhods-2182-ge30b77c5d (RHOAI 2.12)
