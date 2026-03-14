# Architecture Diagrams for ODH Dashboard

Generated from: `architecture/odh-3.3.0/odh-dashboard.md`
Date: 2026-03-13
Component: odh-dashboard (v3.4.0EA1)

**Note**: Diagram filenames use base component name without version (directory is already versioned).

## Available Diagrams

All Mermaid diagrams are available in both `.mmd` (source) and `.png` (3000px width, high-resolution) formats.

### For Developers
- [Component Structure](./odh-dashboard-component.png) ([mmd](./odh-dashboard-component.mmd)) - Mermaid diagram showing internal components, feature packages, and custom resources
- [Data Flows](./odh-dashboard-dataflow.png) ([mmd](./odh-dashboard-dataflow.mmd)) - Sequence diagram of authentication, notebook creation, and metrics query flows
- [Dependencies](./odh-dashboard-dependencies.png) ([mmd](./odh-dashboard-dependencies.mmd)) - Component dependency graph showing external and internal ODH dependencies

### For Architects
- [C4 Context](./odh-dashboard-c4-context.dsl) - System context in C4 format (Structurizr)
- [Component Overview](./odh-dashboard-component.png) ([mmd](./odh-dashboard-component.mmd)) - High-level component view with feature packages

### For Security Teams
- [Security Network Diagram (PNG)](./odh-dashboard-security-network.png) - High-resolution network topology
- [Security Network Diagram (Mermaid)](./odh-dashboard-security-network.mmd) - Visual network topology (editable)
- [Security Network Diagram (ASCII)](./odh-dashboard-security-network.txt) - Precise text format for SAR submissions
- [RBAC Visualization](./odh-dashboard-rbac.png) ([mmd](./odh-dashboard-rbac.mmd)) - RBAC permissions and bindings

## Component Overview

**ODH Dashboard** is a web-based UI for managing and interacting with Open Data Hub (ODH) and Red Hat OpenShift AI (RHOAI) components. It provides:

- **Frontend**: React/TypeScript SPA using PatternFly v6
- **Backend**: Node.js/Fastify REST API server
- **Authentication**: OAuth via kube-rbac-proxy
- **Feature Packages**: Modular plugins for Gen AI, Model Registry, MLflow, AutoML, AutoRAG, KServe

### Key Features

1. **Workbench Management**: Create and manage Jupyter notebooks (Kubeflow Notebook CRs)
2. **Model Serving**: Monitor KServe InferenceService deployments
3. **Model Registry**: Manage ModelRegistry CRs and model metadata
4. **Data Science Projects**: Namespace and resource management
5. **Distributed Workloads**: Integration with Ray, Spark, and training operators
6. **AI Guardrails**: TrustyAI integration for responsible AI
7. **Feature Stores**: Feast integration for ML feature management
8. **LLM Deployments**: LlamaStack integration for large language models

### Network Architecture

```
User Browser (HTTPS/443)
    ↓
OpenShift Router (Reencrypt TLS)
    ↓
kube-rbac-proxy (OAuth, HTTPS/8443)
    ↓
ODH Dashboard Backend (HTTP/8080)
    ↓
Kubernetes API (HTTPS/6443)
```

### Authentication Flow

1. User requests dashboard URL → OpenShift Router
2. Router redirects to OpenShift OAuth Server
3. User authenticates → OAuth Server issues Bearer Token (cookie)
4. User browser sends authenticated request → kube-rbac-proxy
5. kube-rbac-proxy validates token and forwards to backend (with X-Auth-Request-User header)
6. Backend uses ServiceAccount token for Kubernetes API calls

### RBAC Summary

The `odh-dashboard` ServiceAccount has ClusterRole permissions for:
- **Core resources**: ConfigMaps, Secrets, PVCs, Pods, Services, Namespaces
- **Kubeflow**: Notebooks (full CRUD)
- **KServe**: InferenceServices (read-only)
- **Model Registry**: ModelRegistries (full CRUD)
- **ODH CRs**: DataScienceClusters, DSCInitializations (read-only)
- **Feast, TrustyAI, LlamaStack**: Feature stores, guardrails, LLM distributions (read-only)
- **OpenShift**: Routes, ImageStreams, ClusterVersions, Users, Groups
- **RBAC**: RoleBindings, Roles (full CRUD for project access management)

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
# From repository root
python scripts/generate_diagram_pngs.py architecture/odh-3.3.0/diagrams --width=3000
```

## Diagram Details

### 1. Component Structure Diagram
Shows the internal architecture of ODH Dashboard:
- Frontend (React/PatternFly)
- Backend (Node.js/Fastify)
- kube-rbac-proxy for authentication
- Feature packages (Gen AI, Model Registry, MLflow, AutoML, AutoRAG, KServe)
- Custom Resource Definitions (CRDs)
- Integration with ODH components

### 2. Data Flow Diagram
Illustrates three key flows:
- **Flow 1**: User authentication and dashboard access (OAuth flow)
- **Flow 2**: Notebook creation (CR creation with PVC and RoleBinding)
- **Flow 3**: Metrics query via Prometheus proxy

### 3. Security Network Diagram
Available in two formats:
- **Mermaid/PNG**: Visual representation with color-coded trust zones
- **ASCII**: Precise text format for Security Architecture Reviews (SAR)

Shows:
- Network topology from user browser to backend services
- Port numbers, protocols, encryption (TLS versions)
- Authentication mechanisms (OAuth, Bearer tokens, ServiceAccount tokens)
- Trust boundaries (External, Ingress, Application Layer, Backend Services)
- Network policies, RBAC summary, secrets management

### 4. C4 Context Diagram
Structurizr DSL format showing:
- System context: ODH Dashboard in the broader ecosystem
- Container view: Frontend, Backend, kube-rbac-proxy
- Component view: Feature packages
- Relationships with external systems (OpenShift, Kubernetes, Prometheus)
- Integration with internal ODH components (KServe, Model Registry, Notebooks, etc.)

### 5. Dependencies Graph
Shows all dependencies:
- **External**: Node.js, Kubernetes, OpenShift, kube-rbac-proxy, Prometheus
- **Internal ODH**: ODH Operator, Kubeflow Notebooks, KServe, Model Registry, TrustyAI, Feast, LlamaStack
- **Integration Points**: User access, API calls, OAuth authentication
- **Feature Packages**: Plugin modules extending functionality

### 6. RBAC Visualization
Complete RBAC permissions:
- ServiceAccount: `odh-dashboard`
- ClusterRole: `odh-dashboard` with permissions across multiple API groups
- RoleBindings: auth-delegator (kube-system), cluster-monitoring-view (openshift-monitoring)
- API resources: Core, RBAC, Storage, ODH/RHOAI, Kubeflow, KServe, OpenShift, Auth

## Related Documentation

- Architecture file: [../odh-dashboard.md](../odh-dashboard.md)
- Repository: https://github.com/opendatahub-io/odh-dashboard
- Version: v3.4.0EA1

## Questions or Issues?

For questions about these diagrams or the ODH Dashboard architecture:
1. Review the source architecture file: `architecture/odh-3.3.0/odh-dashboard.md`
2. Check the ODH Dashboard repository: https://github.com/opendatahub-io/odh-dashboard
3. Regenerate diagrams after architecture updates using the Python script
