# Architecture Diagrams for Model Registry Operator

Generated from: `architecture/rhoai-2.25/model-registry-operator.md`
Date: 2026-03-15

**Note**: Diagram filenames use base component name without version (directory is already versioned).

## Available Diagrams

All Mermaid diagrams are available in both `.mmd` (source) and `.png` (3000px width, high-resolution) formats.

### For Developers
- [Component Structure](./model-registry-operator-component.png) ([mmd](./model-registry-operator-component.mmd)) - Mermaid diagram showing internal components
- [Data Flows](./model-registry-operator-dataflow.png) ([mmd](./model-registry-operator-dataflow.mmd)) - Sequence diagram of request/response flows
- [Dependencies](./model-registry-operator-dependencies.png) ([mmd](./model-registry-operator-dependencies.mmd)) - Component dependency graph

### For Architects
- [C4 Context](./model-registry-operator-c4-context.dsl) - System context in C4 format (Structurizr)
- [Component Overview](./model-registry-operator-component.png) ([mmd](./model-registry-operator-component.mmd)) - High-level component view

### For Security Teams
- [Security Network Diagram (PNG)](./model-registry-operator-security-network.png) - High-resolution network topology
- [Security Network Diagram (Mermaid)](./model-registry-operator-security-network.mmd) - Visual network topology (editable)
- [Security Network Diagram (ASCII)](./model-registry-operator-security-network.txt) - Precise text format for SAR submissions
- [RBAC Visualization](./model-registry-operator-rbac.png) ([mmd](./model-registry-operator-rbac.mmd)) - RBAC permissions and bindings

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

### Component Structure
Shows the Model Registry Operator architecture including:
- Controller Manager and Webhook Server
- ModelRegistry CR versions (v1beta1 current, v1alpha1 deprecated)
- Per-instance deployment components (REST API, OAuth Proxy)
- Kubernetes resources created (Deployments, Services, Routes, RBAC, NetworkPolicies)
- External dependencies (PostgreSQL/MySQL databases, OpenShift OAuth Server)
- Platform integrations (opendatahub-operator, Prometheus)

### Data Flows
Sequence diagrams showing:
1. **External User Access (OAuth Mode)**: Client → Router → OAuth Proxy → REST API → Database
2. **Internal Cluster Access (Non-OAuth Mode)**: Pod → Service → REST API → Database
3. **Operator Reconciliation**: Controller → Kubernetes API → Webhook validation
4. **Metrics Collection**: Prometheus → Metrics Service

### Security Network Diagram
Comprehensive network topology including:
- **Trust Boundaries**: External (untrusted), Ingress (DMZ), Cluster (trusted), External Services
- **Network Details**: Ports, protocols, encryption (TLS 1.2+, mTLS), authentication methods
- **RBAC Summary**: ClusterRoles, Roles, RoleBindings with permissions
- **Secrets Management**: OAuth certs, database passwords, cookie secrets, webhook certs
- **NetworkPolicies**: Ingress rules for OAuth proxy access
- **Security Best Practices**: TLS encryption, authentication, authorization, pod security

Available in three formats:
- **ASCII (.txt)**: Precise text format for Security Architecture Reviews (SAR)
- **Mermaid (.mmd)**: Editable visual diagram with trust zones
- **PNG (.png)**: High-resolution image for presentations

### Dependencies
Shows:
- **External Dependencies**: PostgreSQL 9.6+, MySQL 5.7+ (required), OpenShift components (optional)
- **Internal ODH/RHOAI Dependencies**: odh-model-registry service, Prometheus, opendatahub-operator
- **Kubernetes Core**: API Server, cert-manager (optional)
- **Integration Points**: ODH Dashboard, Data Science Pipelines

### RBAC Visualization
Detailed RBAC structure showing:
- **Service Accounts**: controller-manager (operator), per-registry instances
- **ClusterRoles**: manager-role (full permissions), proxy-role (metrics), leader-election-role
- **Roles**: Per-instance registry-user roles for OAuth authorization
- **Permissions**: Grouped by API group with verbs for each resource type
- **Bindings**: Linking service accounts to roles

### C4 Context Diagram
Structurizr DSL showing:
- System context with data scientists as users
- Model Registry Operator containers (Controller, Webhook, Model Registry Instance)
- External systems (Kubernetes, databases, OpenShift OAuth, Prometheus)
- Integration points and relationships
- Data flow between components

## Updating Diagrams

To regenerate after architecture changes:

```bash
# From the repository root
cd architecture/rhoai-2.25
# Edit the architecture markdown file
vim model-registry-operator.md

# Regenerate diagrams (when skill is available)
# The skill will:
# 1. Read model-registry-operator.md
# 2. Generate all diagram formats in diagrams/
# 3. Create PNG files from Mermaid diagrams
# 4. Update this README
```

## Architecture Documentation

For complete architectural details, see:
- [Model Registry Operator Architecture](../model-registry-operator.md)

## Component Summary

**Purpose**: Manages lifecycle of Model Registry instances for machine learning model metadata storage and retrieval.

**Key Features**:
- Deploys Model Registry instances per namespace
- REST API access to ML Metadata (MLMD)
- Optional OAuth proxy authentication for secure external access
- PostgreSQL or MySQL database backends
- OpenShift Route creation for external access
- RBAC setup and network policy management
- Supports v1alpha1 (deprecated) and v1beta1 (current) APIs with conversion webhooks

**Deployment**:
- Operator runs in dedicated namespace (e.g., `redhat-ods-applications`)
- Each ModelRegistry CR creates isolated deployment in its namespace
- Single replica per instance (no HA support currently)
- Security contexts: runAsNonRoot, restricted-v2 SCC

**Known Limitations**:
1. Single replica only (no HA)
2. User must provision database separately
3. OAuth-only authentication in v1beta1
4. No built-in backup/restore
5. OpenShift-specific features (OAuth, Routes)
6. No multi-tenancy (independent deployments per CR)
