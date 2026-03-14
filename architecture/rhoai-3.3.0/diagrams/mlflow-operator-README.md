# Architecture Diagrams for MLflow Operator

Generated from: `architecture/rhoai-3.3.0/mlflow-operator.md`
Date: 2026-03-14
Component: mlflow-operator (from filename)

**Note**: Diagram filenames use base component name without version (directory is already versioned).

## Available Diagrams

All Mermaid diagrams are available in both `.mmd` (source) and `.png` (3000px width, high-resolution) formats.

### For Developers
- [Component Structure](./mlflow-operator-component.png) ([mmd](./mlflow-operator-component.mmd)) - Mermaid diagram showing internal components, operator controllers, and created resources
- [Data Flows](./mlflow-operator-dataflow.png) ([mmd](./mlflow-operator-dataflow.mmd)) - Sequence diagrams of user access, artifact storage, operator reconciliation, and metrics collection
- [Dependencies](./mlflow-operator-dependencies.png) ([mmd](./mlflow-operator-dependencies.mmd)) - Component dependency graph showing required and optional dependencies

### For Architects
- [C4 Context](./mlflow-operator-c4-context.dsl) - System context in C4 format (Structurizr) showing MLflow Operator in the broader ODH/RHOAI ecosystem
- [Component Overview](./mlflow-operator-component.png) ([mmd](./mlflow-operator-component.mmd)) - High-level component view with operator controllers and MLflow instances

### For Security Teams
- [Security Network Diagram (PNG)](./mlflow-operator-security-network.png) - High-resolution network topology with trust zones
- [Security Network Diagram (Mermaid)](./mlflow-operator-security-network.mmd) - Visual network topology (editable)
- [Security Network Diagram (ASCII)](./mlflow-operator-security-network.txt) - Precise text format for SAR submissions with complete RBAC, secrets, and security features
- [RBAC Visualization](./mlflow-operator-rbac.png) ([mmd](./mlflow-operator-rbac.mmd)) - RBAC permissions, role bindings, and API resource access

## Component Overview

The MLflow Operator is a Kubernetes operator that automates deployment and lifecycle management of MLflow experiment tracking and model registry servers. Key features:

- **Operator**: Go-based controller with embedded Helm charts for template rendering
- **Deployment Modes**: RHOAI (redhat-ods-applications) and ODH (opendatahub)
- **Storage Options**: Local PVC (dev) or remote PostgreSQL + S3 (production)
- **Security**: TLS everywhere, kubernetes-auth, non-root containers, network policies
- **Integration**: Gateway API (HTTPRoute), OpenShift Console (ConsoleLink), Prometheus metrics

## Diagram Details

### Component Diagram
Shows the MLflow Operator architecture including:
- **Operator Controllers**: Main controller, HTTPRoute controller, ConsoleLink controller
- **Helm Engine**: Embedded Helm chart template rendering
- **Created Resources**: MLflow server deployment, services, RBAC, storage, networking
- **External Dependencies**: Kubernetes API, data-science-gateway, PostgreSQL (optional), S3 (optional)

### Data Flow Diagram
Illustrates five key flows:
1. **User Access via Gateway**: External user → gateway → HTTPRoute → MLflow service → MLflow pod → K8s API auth
2. **Operator Reconciliation**: Operator watches CRs → renders Helm templates → creates resources
3. **Artifact Storage (S3)**: User → MLflow → S3 with AWS IAM authentication
4. **Metadata Storage (PostgreSQL)**: User → MLflow → PostgreSQL with username/password
5. **Metrics Collection**: Prometheus → operator metrics service (HTTPS, bearer token)

### Security Network Diagram
**ASCII version** (for SAR documentation):
- Complete network topology with exact ports, protocols, encryption (TLS versions)
- Trust zones: External, Ingress DMZ, Application Namespace, Operator Namespace, K8s Cluster, External Services
- Authentication mechanisms: Bearer tokens, AWS IAM, username/password
- RBAC summary: ClusterRoles, Roles, RoleBindings
- Secrets: TLS certificates, database credentials, AWS keys
- Security features: Non-root containers, read-only rootfs, dropped capabilities, seccomp profiles

**Mermaid version** (for presentations):
- Visual representation with color-coded trust zones
- Same information as ASCII but more readable for stakeholders

### C4 Context Diagram
System context showing MLflow Operator relationships:
- **Actors**: Data Scientist (uses MLflow), Platform Admin (deploys MLflow)
- **System**: MLflow Operator with internal containers
- **External Dependencies**: Kubernetes API, PostgreSQL, S3
- **Internal ODH Dependencies**: data-science-gateway, OpenShift Console, Prometheus, service-ca-operator

### Dependencies Diagram
Shows all dependencies with visual distinction:
- **Required External**: Kubernetes 1.11.3+, Helm v3 (embedded), MLflow v3.6.0
- **Optional External**: PostgreSQL 9.6+, S3-compatible storage, service-ca-operator
- **Internal ODH**: data-science-gateway (Gateway API), OpenShift Console (ConsoleLink), Prometheus (metrics)
- **Build-time**: Go 1.24.6+ (compilation only)

### RBAC Diagram
Visualizes RBAC structure:
- **Service Accounts**: controller-manager (operator), mlflow-sa (per instance)
- **ClusterRole**: manager-role (manages MLflow CRs, HTTPRoutes, ConsoleLinks, RBAC)
- **Namespace Role**: manager-role (manages PVCs, secrets, services, deployments, network policies)
- **MLflow ClusterRole**: mlflow (reads namespaces for workspaces feature)
- **Bindings**: ClusterRoleBindings and RoleBindings connecting SAs to roles

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
   PUPPETEER_EXECUTABLE_PATH=/usr/bin/google-chrome mmdc -i mlflow-operator-component.mmd -o mlflow-operator-component.png -w 3000
   ```

3. **Alternative formats** (if needed):
   ```bash
   # SVG (vector, scales perfectly)
   PUPPETEER_EXECUTABLE_PATH=/usr/bin/google-chrome mmdc -i mlflow-operator-component.mmd -o mlflow-operator-component.svg

   # PDF
   PUPPETEER_EXECUTABLE_PATH=/usr/bin/google-chrome mmdc -i mlflow-operator-component.mmd -o mlflow-operator-component.pdf
   ```

**Note**: If `google-chrome` is not found, try `chromium` or `which google-chrome` to locate it

### C4 Diagrams (.dsl files)
- **Structurizr Lite**: `docker run -p 8080:8080 -v .:/usr/local/structurizr structurizr/lite`
- **CLI export**: `structurizr-cli export -workspace mlflow-operator-c4-context.dsl -format png`

### ASCII Diagrams (.txt files)
- View in any text editor
- Include in documentation as-is
- Perfect for security reviews (precise technical details)

## Key Technical Details

### Deployment Modes
- **RHOAI**: Namespace `redhat-ods-applications` for Red Hat OpenShift AI customers
- **ODH**: Namespace `opendatahub` for Open Data Hub community users

### Storage Configurations

**Local Storage (Development)**:
- Backend Store: `sqlite:////mlflow/mlflow.db`
- Registry Store: `sqlite:////mlflow/mlflow.db`
- Artifacts: `file:///mlflow/artifacts`
- PVC: Required, default 2Gi

**Remote Storage (Production)**:
- Backend Store: PostgreSQL via secret
- Registry Store: PostgreSQL via secret
- Artifacts: S3 via secret
- PVC: Not required

### Security Features
1. TLS Everywhere (operator metrics 8443/HTTPS, MLflow server 8443/HTTPS TLS1.3)
2. Non-Root Containers (UID 1001)
3. Read-Only Root Filesystem
4. No Privilege Escalation
5. Capabilities Dropped (ALL)
6. Seccomp Profile (RuntimeDefault)
7. Network Policies (ingress restricted to 8443/TCP)
8. Kubernetes-Native Auth (Bearer tokens, self_subject_access_review)
9. Secret References (database credentials, AWS keys)
10. Service CA Integration (automatic cert rotation on OpenShift)

### Network Ports

**Operator**:
- 8443/TCP: Metrics (HTTPS, bearer token auth)
- 8081/TCP: Health probes (HTTP, no auth)
- 6443/TCP: Kubernetes API (HTTPS, SA token)

**MLflow Server**:
- 8443/TCP: MLflow REST API and UI (HTTPS TLS1.3, bearer token)
- 6443/TCP: Kubernetes API for auth (HTTPS, SA token)
- 5432/TCP: PostgreSQL (optional, TLS optional, username/password)
- 443/TCP: S3 storage (optional, HTTPS TLS1.2+, AWS IAM)

### Authentication & Authorization

**Operator Metrics** (/metrics):
- Port: 8443/TCP HTTPS
- Auth: Bearer Token (ServiceAccount)
- Enforcement: kube-rbac-proxy
- Policy: Must have metrics reader role

**MLflow API** (/api/2.0/*):
- Port: 8443/TCP HTTPS TLS1.3
- Auth: Bearer Token (kubernetes-auth mode)
- Enforcement: MLflow server (self_subject_access_review)
- Policy: Valid Kubernetes ServiceAccount token

**Gateway Traffic**:
- External: 443/TCP HTTPS TLS1.3
- Internal: 8443/TCP HTTPS TLS1.3
- Auth: Passthrough (bearer token forwarded to MLflow)
- TLS Termination: Gateway handles external TLS, forwards HTTPS to MLflow

## Updating Diagrams

To regenerate after architecture changes:
```bash
# From repository root
python scripts/generate_diagram_pngs.py architecture/rhoai-3.3.0/diagrams --width=3000
```

## Related Documentation
- Architecture: [mlflow-operator.md](../mlflow-operator.md)
- Repository: https://github.com/red-hat-data-services/mlflow-operator
- Version: rhoai-3.3 (commit 49b5d8d)
