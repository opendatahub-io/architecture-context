# Architecture Diagrams for MLflow Operator

Generated from: `architecture/rhoai-3.3/mlflow-operator.md`
Date: 2026-03-15

**Note**: Diagram filenames use base component name without version (directory is already versioned).

## Available Diagrams

All Mermaid diagrams are available in both `.mmd` (source) and `.png` (3000px width, high-resolution) formats.

### For Developers
- [Component Structure](./mlflow-operator-component.png) ([mmd](./mlflow-operator-component.mmd)) - Mermaid diagram showing internal components, Helm engine, controllers, and created resources
- [Data Flows](./mlflow-operator-dataflow.png) ([mmd](./mlflow-operator-dataflow.mmd)) - Sequence diagram of request/response flows including user access, experiment tracking, and operator reconciliation
- [Dependencies](./mlflow-operator-dependencies.png) ([mmd](./mlflow-operator-dependencies.mmd)) - Component dependency graph showing external and internal ODH dependencies

### For Architects
- [C4 Context](./mlflow-operator-c4-context.dsl) - System context in C4 format (Structurizr)
- [Component Overview](./mlflow-operator-component.png) ([mmd](./mlflow-operator-component.mmd)) - High-level component view

### For Security Teams
- [Security Network Diagram (PNG)](./mlflow-operator-security-network.png) - High-resolution network topology
- [Security Network Diagram (Mermaid)](./mlflow-operator-security-network.mmd) - Visual network topology (editable)
- [Security Network Diagram (ASCII)](./mlflow-operator-security-network.txt) - Precise text format for SAR submissions
- [RBAC Visualization](./mlflow-operator-rbac.png) ([mmd](./mlflow-operator-rbac.mmd)) - RBAC permissions and bindings for operator and MLflow instances

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
Shows the MLflow Operator architecture including:
- Operator controller and embedded Helm chart engine
- HTTPRoute and ConsoleLink reconciliation controllers
- Resources created per MLflow CR (Server, Service, PVC, Secrets, etc.)
- Integration with Kubernetes API, data-science-gateway, OpenShift Console
- Optional external services (PostgreSQL, S3)

### Data Flow Diagrams
Covers 4 main flows:
1. **User Access via Gateway**: Browser → Gateway → HTTPRoute → MLflow Service → MLflow Pod → K8s API (auth)
2. **Experiment Tracking**: MLflow client → MLflow Server → PostgreSQL (metadata) → S3 (artifacts)
3. **Operator Reconciliation**: Watch MLflow CRs → Render Helm charts → Apply manifests → Create HTTPRoutes/ConsoleLinks
4. **Metrics Collection**: Prometheus → Operator metrics endpoint

### Security Network Diagram
Detailed network topology with:
- **Trust boundaries**: External, Ingress (Gateway), Application Namespace, Operator Namespace, External Services
- **Precise network details**: Ports (443/TCP, 8443/TCP, 6443/TCP, 5432/TCP), protocols (HTTPS, PostgreSQL), encryption (TLS 1.3, TLS 1.2+)
- **Authentication mechanisms**: Bearer tokens (Kubernetes auth), ServiceAccount tokens, AWS IAM, username/password
- **RBAC summary**: Operator ClusterRole/Role permissions, MLflow server ClusterRole
- **Network policies**: Ingress rules (TCP/8443), egress rules (allow all)
- **Secrets**: TLS certificates, database credentials, AWS credentials
- **Security contexts**: Non-root (UID 1001), read-only rootfs, no privilege escalation, seccomp profiles

Available in 3 formats:
- **ASCII (.txt)**: Precision format for Security Architecture Reviews - no ambiguity in network flows
- **Mermaid (.mmd)**: Visual format with trust zone coloring - editable source
- **PNG (.png)**: High-resolution image for presentations

### Dependencies Diagram
Shows:
- **External dependencies**: Kubernetes, Helm v3, MLflow image, PostgreSQL (optional), S3 (optional), service-ca-operator (optional)
- **Internal ODH dependencies**: data-science-gateway (HTTPRoute), OpenShift Console (ConsoleLink), Prometheus (metrics)
- **Build-time dependencies**: Go 1.24.6+, UBI9 base images
- Distinguishes required vs optional dependencies

### RBAC Visualization
Displays:
- **Service Accounts**: controller-manager (operator), mlflow-sa (per instance)
- **Operator ClusterRole**: Permissions for MLflow CRs, namespaces, HTTPRoutes, ConsoleLinks, RBAC resources
- **Operator Namespace Role**: Permissions for Deployments, Services, Secrets, PVCs, NetworkPolicies
- **MLflow ClusterRole**: Permissions for listing namespaces (workspaces feature)
- **Role bindings**: ClusterRoleBindings and namespace RoleBindings
- Flow of permissions from ServiceAccount → Binding → Role → API Resources

### C4 Context Diagram
System context showing:
- **Actors**: Data Scientists (use MLflow), Platform Administrators (deploy MLflow)
- **MLflow Operator containers**: Controller, Helm Engine, HTTPRoute Controller, ConsoleLink Controller
- **Related systems**: Kubernetes, data-science-gateway, OpenShift Console, Prometheus, Dashboard
- **External services**: PostgreSQL, S3, service-ca-operator
- **Relationships**: API calls, traffic routing, metrics scraping, TLS provisioning

## Updating Diagrams

To regenerate after architecture changes:
```bash
# From the repository root
/generate-architecture-diagrams --architecture=architecture/rhoai-3.3/mlflow-operator.md --output-dir=architecture/rhoai-3.3/diagrams
```

## Key Features Illustrated

1. **Kubernetes-Native Authentication**: Bearer token authentication with self_subject_access_review
2. **Gateway API Integration**: HTTPRoute resources for external traffic routing via data-science-gateway
3. **OpenShift Integration**: ConsoleLink resources for application menu links
4. **Flexible Storage**: Local PVC (development) or remote PostgreSQL + S3 (production)
5. **TLS Everywhere**: Operator metrics (8443/HTTPS), MLflow server (8443/HTTPS), external gateway (443/HTTPS)
6. **Dual Deployment Modes**: OpenDataHub (opendatahub namespace) and RHOAI (redhat-ods-applications namespace)
7. **Helm-based Templating**: Embedded Helm charts for manifest generation
8. **Security Hardening**: Non-root containers, read-only rootfs, no privilege escalation, capabilities dropped, seccomp profiles
