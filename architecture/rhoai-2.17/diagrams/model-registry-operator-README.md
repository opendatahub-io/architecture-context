# Architecture Diagrams for Model Registry Operator

Generated from: `architecture/rhoai-2.17/model-registry-operator.md`
Date: 2026-03-16

**Note**: Diagram filenames use base component name without version (directory is already versioned).

## Available Diagrams

All Mermaid diagrams are available in both `.mmd` (source) and `.png` (3000px width, high-resolution) formats.

### For Developers
- [Component Structure](./model-registry-operator-component.png) ([mmd](./model-registry-operator-component.mmd)) - Mermaid diagram showing internal components, operator manager, model registry instances, and dependencies
- [Data Flows](./model-registry-operator-dataflow.png) ([mmd](./model-registry-operator-dataflow.mmd)) - Sequence diagram of REST/gRPC API calls with Istio, Authorino authentication, and metrics collection flows
- [Dependencies](./model-registry-operator-dependencies.png) ([mmd](./model-registry-operator-dependencies.mmd)) - Component dependency graph showing required (PostgreSQL/MySQL, K8s API) and optional dependencies (Istio, Authorino)

### For Architects
- [C4 Context](./model-registry-operator-c4-context.dsl) - System context in C4 format (Structurizr) showing Model Registry Operator in ODH ecosystem
- [Component Overview](./model-registry-operator-component.png) ([mmd](./model-registry-operator-component.mmd)) - High-level component view with operator controller, registry instances, and external systems

### For Security Teams
- [Security Network Diagram (PNG)](./model-registry-operator-security-network.png) - High-resolution network topology with trust zones, encryption, and authentication details
- [Security Network Diagram (Mermaid)](./model-registry-operator-security-network.mmd) - Visual network topology (editable) showing Istio service mesh integration
- [Security Network Diagram (ASCII)](./model-registry-operator-security-network.txt) - Precise text format for SAR submissions with detailed RBAC, service mesh config, secrets, and network flows
- [RBAC Visualization](./model-registry-operator-rbac.png) ([mmd](./model-registry-operator-rbac.mmd)) - RBAC permissions and bindings showing ClusterRoles, ServiceAccounts, and API resource permissions

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

## Key Architecture Details

### Component Overview
- **Operator Manager**: Go-based controller that reconciles ModelRegistry CRs
- **Model Registry Instance**: Per-CR deployment with REST proxy (8080/TCP) and gRPC server (9090/TCP)
- **Istio Integration**: Optional service mesh for mTLS, traffic management, and external access via Gateways
- **Authorino Authentication**: Kubernetes-native authentication using bearer tokens and RBAC

### Security Highlights
- **mTLS**: ISTIO_MUTUAL mode for automatic mutual TLS between services in the mesh
- **Authentication**: Bearer token validation via Kubernetes TokenReview API
- **Authorization**: RBAC enforcement through SubjectAccessReview (GET permission on service/{registry-name})
- **Database Encryption**: Optional TLS for PostgreSQL (sslmode) and MySQL (SSL certs)
- **Gateway TLS**: Supports SIMPLE, MUTUAL, ISTIO_MUTUAL, and OPTIONAL_MUTUAL TLS modes

### Dependencies
- **Required**: PostgreSQL OR MySQL database, Kubernetes API Server
- **Optional**: Istio (service mesh), Authorino (authentication), Prometheus Operator (metrics), OpenShift (routes), cert-manager (TLS certificates)
- **ODH Consumers**: ODH Dashboard, Data Science Pipelines, KServe, ModelMesh Serving

### Data Flows
1. **REST API Call (with Istio)**: Client → Istio Gateway (443/TCP HTTPS) → Authorino (TokenReview + RBAC) → Envoy Sidecar (mTLS) → REST Proxy (8080) → gRPC Server (9090) → Database (5432/3306)
2. **gRPC API Call (with Istio)**: Client → Istio Gateway (443/TCP HTTPS HTTP/2) → Authorino → Envoy → gRPC Server (9090) → Database
3. **Operator Reconciliation**: Operator Manager → Kubernetes API (6443/TCP HTTPS) → Creates/Updates Deployments, Services, Istio Resources, Authorino AuthConfigs
4. **Metrics Collection**: Prometheus → Kube-RBAC Proxy (8443/TCP HTTPS) → TokenReview/SubjectAccessReview → Operator Manager (/metrics)

## Updating Diagrams

To regenerate after architecture changes:
```bash
# From repository root
cd /home/jtanner/workspace/github/jctanner.redhat/2026_03_12_arch_diagrams/kahowell.rhoai-architecture-diagrams

# Regenerate diagrams (this will update .mmd and .png files)
# (Use your diagram generation workflow here)
```

## Architecture Documentation

For complete architecture details, see:
- [Model Registry Operator Architecture](../model-registry-operator.md)
- Component metadata, APIs, dependencies, security, and data flows

## Related Components

Model Registry Operator integrates with:
- **ODH Dashboard**: Web UI for managing model registry instances
- **Data Science Pipelines**: ML pipeline orchestration and model tracking
- **KServe**: Model serving platform consuming model metadata
- **ModelMesh Serving**: Alternative model serving platform
- **Istio**: Service mesh for mTLS and traffic management
- **Authorino**: Kubernetes-native authentication and authorization
