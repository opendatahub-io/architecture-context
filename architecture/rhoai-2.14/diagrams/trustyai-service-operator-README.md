# Architecture Diagrams for TrustyAI Service Operator

Generated from: `architecture/rhoai-2.14/trustyai-service-operator.md`
Date: 2026-03-15

**Note**: Diagram filenames use base component name without version (directory is already versioned).

## Available Diagrams

All Mermaid diagrams are available in both `.mmd` (source) and `.png` (3000px width, high-resolution) formats.

### For Developers
- [Component Structure](./trustyai-service-operator-component.png) ([mmd](./trustyai-service-operator-component.mmd)) - Mermaid diagram showing internal components, operator controller, TrustyAI service deployment, OAuth proxy, and resource management
- [Data Flows](./trustyai-service-operator-dataflow.png) ([mmd](./trustyai-service-operator-dataflow.mmd)) - Sequence diagram of request/response flows including service creation, external access, metrics scraping, KServe integration, and database storage
- [Dependencies](./trustyai-service-operator-dependencies.png) ([mmd](./trustyai-service-operator-dependencies.mmd)) - Component dependency graph showing external and internal RHOAI dependencies

### For Architects
- [C4 Context](./trustyai-service-operator-c4-context.dsl) - System context in C4 format (Structurizr) showing TrustyAI operator in the broader RHOAI/ODH ecosystem
- [Component Overview](./trustyai-service-operator-component.png) ([mmd](./trustyai-service-operator-component.mmd)) - High-level component view with operator, services, and integration points

### For Security Teams
- [Security Network Diagram (PNG)](./trustyai-service-operator-security-network.png) - High-resolution network topology with trust zones and authentication layers
- [Security Network Diagram (Mermaid)](./trustyai-service-operator-security-network.mmd) - Visual network topology (editable) showing external, ingress, authentication, application, and monitoring layers
- [Security Network Diagram (ASCII)](./trustyai-service-operator-security-network.txt) - Precise text format for SAR submissions with detailed port, protocol, encryption, authentication, RBAC, secrets, and security context information
- [RBAC Visualization](./trustyai-service-operator-rbac.png) ([mmd](./trustyai-service-operator-rbac.mmd)) - RBAC permissions and bindings including manager-role and leader-election-role

## Component Overview

**TrustyAI Service Operator** is a Kubernetes operator that manages TrustyAI service deployments for AI/ML model explainability, fairness monitoring, and bias detection. It watches for `TrustyAIService` custom resources and automatically provisions:

- TrustyAI Service Deployments (Quarkus application)
- OAuth Proxy Sidecars for authentication
- Internal Services (ClusterIP) for HTTP/HTTPS communication
- OpenShift Routes for external access with re-encryption
- ServiceMonitors for Prometheus metrics collection
- PersistentVolumeClaims or external database backends
- Integration with KServe InferenceServices for model monitoring

### Key Features

- **Storage Options**: PVC-based or external database (PostgreSQL/MySQL) with TLS encryption
- **Authentication**: OAuth proxy integration for secure external access on OpenShift
- **Monitoring**: Prometheus ServiceMonitor with fairness metrics (SPD, DIR)
- **KServe Integration**: Automatic payload processor injection for bias detection
- **Security**: TLS encryption, RBAC policies, and automatic certificate provisioning

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

## Technical Details

### APIs Exposed

**Custom Resource Definitions**:
- `trustyai.opendatahub.io/v1alpha1` - TrustyAIService (declarative configuration)

**Operator Endpoints**:
- `/metrics` (8080/TCP HTTP) - Prometheus metrics
- `/healthz` (8081/TCP HTTP) - Liveness probe
- `/readyz` (8081/TCP HTTP) - Readiness probe

**TrustyAI Service Endpoints**:
- `/q/metrics` (8080/TCP HTTP) - Quarkus metrics for Prometheus
- `/*` (8080/TCP HTTP) - TrustyAI HTTP API (internal)
- `/*` (4443/TCP HTTPS) - TrustyAI HTTPS API with service certificate
- `/oauth/healthz` (8443/TCP HTTPS) - OAuth proxy health check
- `/*` (8443/TCP HTTPS) - External API access via OAuth proxy

### Network Architecture

**Services**:
- `controller-manager-metrics-service` (ClusterIP, 8443/TCP HTTPS)
- `{instance-name}` (ClusterIP, 80/TCP HTTP, 443/TCP HTTPS)
- `{instance-name}-tls` (ClusterIP, 443/TCP HTTPS with OAuth)

**Ingress**:
- OpenShift Route (443/TCP HTTPS, re-encrypt TLS termination)

**Egress**:
- External Database (varies/TCP JDBC, TLS 1.2+ optional)
- KServe InferenceService Pods (8080/TCP HTTP)
- Kubernetes API Server (6443/TCP HTTPS)

### Security

**RBAC**:
- `manager-role` (ClusterRole) - Full resource management permissions
- `leader-election-role` (ClusterRole) - Leader election for HA

**Secrets**:
- `{instance-name}-internal` (kubernetes.io/tls) - Internal service TLS cert (auto-rotate)
- `{instance-name}-tls` (kubernetes.io/tls) - OAuth proxy TLS cert (auto-rotate)
- `{instance-name}-db-credentials` (Opaque) - Database credentials
- `{instance-name}-db-tls` (kubernetes.io/tls) - Database TLS certificates

**Authentication**:
- OAuth/Bearer Token (external access via Route)
- Bearer Token/ServiceAccount (Prometheus metrics)
- Username/Password (database connections)
- ServiceAccount Token (Kubernetes API)

## Integration Points

- **KServe**: Watches and patches InferenceServices for monitoring
- **ModelMesh**: Injects payload processor configuration
- **Prometheus**: Metrics collection via ServiceMonitor
- **OpenShift Router**: External access with re-encrypt TLS
- **OpenShift OAuth**: User authentication
- **External Database**: Optional persistent storage backend
- **Persistent Volumes**: Local storage for PVC mode

## Updating Diagrams

To regenerate after architecture changes:
```bash
# From the architecture/rhoai-2.14 directory
claude generate diagrams from trustyai-service-operator.md
```

Or use the architecture diagram generation workflow to regenerate all diagrams.
