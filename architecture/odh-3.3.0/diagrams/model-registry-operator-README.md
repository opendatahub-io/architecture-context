# Architecture Diagrams for Model Registry Operator

Generated from: `architecture/odh-3.3.0/model-registry-operator.md`
Date: 2026-03-13

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

## Component Overview

The Model Registry Operator is a Kubernetes controller that deploys and manages instances of the OpenShift AI Model Registry service. It provides:

- **Model Metadata Management**: Centralized repository for tracking ML model metadata, versioning, and lineage
- **Flexible Database Backend**: Supports PostgreSQL or MySQL for metadata storage
- **Authentication Integration**: Optional OAuth Proxy integration with OpenShift authentication
- **Secure Communication**: TLS/SSL support for database connections and API endpoints
- **RBAC Management**: Automatic provisioning of service accounts, roles, and role bindings
- **Network Security**: NetworkPolicy creation for database access control

### Architecture Highlights

- **CRDs**: ModelRegistry (v1alpha1 deprecated, v1beta1 current)
- **APIs**: REST API (HTTP/8080, HTTPS/8443 with OAuth) and gRPC API (9090)
- **Database**: PostgreSQL 13+ or MySQL 8.0+ with optional TLS encryption
- **Authentication**: Bearer Token (JWT) via OAuth Proxy
- **Deployment**: Kubernetes Deployment with Service and OpenShift Route exposure

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

### 1. Component Diagram
**File**: [model-registry-operator-component.mmd](./model-registry-operator-component.mmd) | [PNG](./model-registry-operator-component.png)

Shows the internal structure of the Model Registry Operator, including:
- Operator Controller and ModelRegistry Reconciler
- Model Registry Service deployment (REST API + gRPC)
- Optional sidecars (OAuth Proxy, Database Proxy)
- Custom Resources (v1alpha1, v1beta1)
- Created Kubernetes resources (Deployments, Services, Routes, NetworkPolicies, RBAC)
- External dependencies (PostgreSQL/MySQL, OAuth Service, Kubernetes API)
- ODH integrations (Dashboard, Notebooks, Pipelines, KServe, TrustyAI)

### 2. Data Flow Diagram
**File**: [model-registry-operator-dataflow.mmd](./model-registry-operator-dataflow.mmd) | [PNG](./model-registry-operator-dataflow.png)

Sequence diagrams showing three key flows:
1. **ModelRegistry CR Creation**: User creates ModelRegistry CR → Operator reconciles and deploys service
2. **Model Registration from Notebook**: Notebook Pod → OAuth Proxy → Model Registry Service → PostgreSQL
3. **Model Query from Dashboard**: User Browser → OpenShift Route → OAuth Proxy → Model Registry Service → PostgreSQL

### 3. Security Network Diagram
**Files**:
- [ASCII](./model-registry-operator-security-network.txt) - Precise text format for Security Architecture Reviews
- [Mermaid](./model-registry-operator-security-network.mmd) | [PNG](./model-registry-operator-security-network.png) - Visual diagram with trust zones

Detailed network topology showing:
- **Trust Boundaries**: External → Ingress → Application → Database → Control Plane
- **Ports & Protocols**: Exact port numbers (8080/TCP, 8443/TCP, 5432/TCP, etc.)
- **Encryption**: TLS 1.2+, mTLS, plaintext (localhost only)
- **Authentication**: Bearer Token (JWT), Password, ServiceAccount Token, AWS IAM
- **Network Policies**: Database access restricted to Model Registry namespace
- **RBAC Summary**: ClusterRoles, Roles, Bindings
- **Secrets Management**: Database credentials, OAuth TLS certs, DB TLS CA

### 4. Dependency Graph
**File**: [model-registry-operator-dependencies.mmd](./model-registry-operator-dependencies.mmd) | [PNG](./model-registry-operator-dependencies.png)

Component dependency visualization:
- **External Dependencies**: PostgreSQL 13+, MySQL 8.0+ (required), OAuth Proxy (optional), ML Metadata (embedded)
- **Platform Dependencies**: Kubernetes API, OpenShift (for Routes)
- **Internal ODH Integrations**: Dashboard, Notebooks, Data Science Pipelines, KServe, TrustyAI
- **External Services**: OAuth Service, S3 Storage, Prometheus

### 5. RBAC Matrix
**File**: [model-registry-operator-rbac.mmd](./model-registry-operator-rbac.mmd) | [PNG](./model-registry-operator-rbac.png)

RBAC visualization showing:
- **Service Accounts**: model-registry-operator, {registry-name}-sa, {user-serviceaccount}
- **ClusterRole**: manager-role (full CRUD on ModelRegistry CRs, Deployments, Services, Routes, NetworkPolicies, RBAC)
- **Role**: registry-user-{registry-name} (get services)
- **Bindings**: ClusterRoleBinding (manager-rolebinding), RoleBinding (custom per registry)
- **API Resources**: Core resources, Apps, ModelRegistry CRDs, OpenShift Routes, NetworkPolicies, Authorization

### 6. C4 Context Diagram
**File**: [model-registry-operator-c4-context.dsl](./model-registry-operator-c4-context.dsl)

System context diagram showing:
- **Users**: Data Scientist, ML Engineer, Platform Administrator
- **Main System**: Model Registry Operator (Operator Controller, Model Registry Service, OAuth Proxy, Database Proxy)
- **External Systems**: Kubernetes API, PostgreSQL, MySQL, OAuth Service, S3 Storage, Prometheus
- **Internal ODH Systems**: Dashboard, Notebooks, Data Science Pipelines, KServe, TrustyAI
- **Relationships**: API calls, authentication flows, data storage, monitoring

## Key Security Features

1. **Authentication Options**:
   - OAuth-secured endpoints (HTTPS/8443) with Bearer Token (JWT) validation
   - Non-OAuth endpoints (HTTP/8080) for internal cluster-only access
   - gRPC with optional mTLS client certificate validation

2. **Database Security**:
   - Optional TLS encryption for PostgreSQL/MySQL connections
   - NetworkPolicy restricts database access to Model Registry namespace only
   - Credentials stored in Kubernetes Secrets

3. **RBAC**:
   - Operator uses ClusterRole with full CRUD on ModelRegistry resources
   - Per-registry Role for user access to services
   - ServiceAccount Token authentication for Kubernetes API

4. **Secrets Management**:
   - Database credentials (model-registry-db-credential)
   - OAuth TLS certificates (auto-rotated by cert-manager/Service CA)
   - Database TLS CA certificate (model-registry-db-tls)

## Integration Points

The Model Registry Operator integrates with:

1. **ODH Dashboard**: Provides UI for browsing and managing registered models
2. **Notebooks**: Data scientists register models from Jupyter/VS Code workbenches
3. **Data Science Pipelines**: Automatically track models created in pipeline runs
4. **KServe**: Link InferenceServices to registered model versions for deployment tracking
5. **TrustyAI**: Access model metadata for monitoring and explainability analysis

## Updating Diagrams

To regenerate after architecture changes:
```bash
# From the repository root
cd architecture/odh-3.3.0
# Update the architecture file
vim model-registry-operator.md
# Regenerate diagrams (requires Claude Code or manual generation)
# The diagrams will be created in architecture/odh-3.3.0/diagrams/
```

## References

- **Architecture Documentation**: [../model-registry-operator.md](../model-registry-operator.md)
- **Repository**: https://github.com/opendatahub-io/model-registry-operator.git
- **Version**: f8a6863
- **Mermaid Documentation**: https://mermaid.js.org/
- **Structurizr DSL**: https://structurizr.com/dsl
