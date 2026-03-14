# Architecture Diagrams for Model Registry Operator

Generated from: `architecture/rhoai-2.25.0/model-registry-operator.md`
Date: 2026-03-13

**Note**: Diagram filenames use base component name without version (directory is already versioned).

## Available Diagrams

All Mermaid diagrams are available in both `.mmd` (source) and `.png` (3000px width, high-resolution) formats.

### For Developers
- [Component Structure](./model-registry-operator-component.png) ([mmd](./model-registry-operator-component.mmd)) - Mermaid diagram showing internal components, CR lifecycle, and created resources
- [Data Flows](./model-registry-operator-dataflow.png) ([mmd](./model-registry-operator-dataflow.mmd)) - Sequence diagram of OAuth authentication, internal access, operator reconciliation, and metrics collection
- [Dependencies](./model-registry-operator-dependencies.png) ([mmd](./model-registry-operator-dependencies.mmd)) - Component dependency graph showing external and internal dependencies

### For Architects
- [C4 Context](./model-registry-operator-c4-context.dsl) - System context in C4 format (Structurizr) showing Model Registry Operator in the broader ODH/RHOAI ecosystem
- [Component Overview](./model-registry-operator-component.png) ([mmd](./model-registry-operator-component.mmd)) - High-level component view

### For Security Teams
- [Security Network Diagram (PNG)](./model-registry-operator-security-network.png) - High-resolution network topology with trust boundaries
- [Security Network Diagram (Mermaid)](./model-registry-operator-security-network.mmd) - Visual network topology (editable) with OAuth flow and network policies
- [Security Network Diagram (ASCII)](./model-registry-operator-security-network.txt) - Precise text format for SAR submissions with detailed RBAC, secrets, and authentication
- [RBAC Visualization](./model-registry-operator-rbac.png) ([mmd](./model-registry-operator-rbac.mmd)) - RBAC permissions, service accounts, and role bindings

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
- **controller-manager**: Main operator reconciliation loop
- **webhook-service**: CR validation and mutation
- **Model Registry instances**: Per-CR deployments with REST API and optional OAuth proxy
- **External dependencies**: PostgreSQL/MySQL databases, OpenShift OAuth, Service CA
- **Platform integration**: opendatahub-operator/rhods-operator CRD watching

### Data Flow Sequences
Four key flows are documented:
1. **External User Access (OAuth Mode)**: User → Router → Service → OAuth Proxy → OAuth Server → REST → Database
2. **Internal Cluster Access (Non-OAuth Mode)**: Pod → Service → REST → Database
3. **Operator Reconciliation**: controller-manager → Kubernetes API ← webhook-service
4. **Metrics Collection**: Prometheus → controller-manager-metrics-service

### Security Network Diagram
Comprehensive security architecture including:
- **Trust boundaries**: External (Untrusted) → Ingress (DMZ) → Cluster Internal (Trusted) → External Services
- **OAuth authentication flow**: OpenShift OAuth Server validation with Bearer tokens
- **Network policies**: Ingress filtering for OAuth proxy pods
- **RBAC details**: manager-role, proxy-role, leader-election-role, per-instance registry-user roles
- **Secrets management**: OAuth TLS certs, cookie secrets, database credentials, webhook certs
- **TLS encryption**: Edge termination at Router, TLS 1.2+ to OAuth proxy, optional TLS to database

### Dependencies
External and internal dependencies:
- **Required**: PostgreSQL 9.6+ OR MySQL 5.7+ (backend storage)
- **Optional**: OpenShift Service CA, OAuth Server, Ingress Router, cert-manager
- **Internal ODH/RHOAI**: opendatahub-operator, odh-model-registry service image, Prometheus
- **Integration points**: ODH Dashboard, Data Science Pipelines, KServe (future/current integrations)

### RBAC Visualization
Complete RBAC hierarchy:
- **Service Accounts**: controller-manager, per-instance {name}
- **ClusterRoles**: manager-role (full operator permissions), proxy-role (token review), leader-election-role
- **Roles**: registry-user-{name} (per-instance OAuth authorization)
- **Permissions**: ModelRegistry CRs, Deployments, Services, Routes, RBAC, NetworkPolicies, ConfigMaps, Secrets

### C4 Context
Architectural context showing:
- **Users**: Data Scientists, ML Engineers
- **System**: Model Registry Operator with controller, webhook, and registry deployment containers
- **External systems**: PostgreSQL/MySQL, OpenShift OAuth, Kubernetes API
- **Internal systems**: opendatahub-operator, Prometheus, cert-manager, Service CA
- **Integrations**: ODH Dashboard, Data Science Pipelines, KServe

## Key Security Details

### Authentication Modes
1. **OAuth Mode (Recommended for External Access)**:
   - OpenShift OAuth proxy sidecar
   - Bearer token authentication
   - User must have GET permission on service/{name}
   - TLS 1.2+ encryption
   - Route: {name}-https.{domain} on 443/TCP

2. **Non-OAuth Mode (Internal Only)**:
   - No authentication
   - HTTP/8080 internal ClusterIP only
   - No external Route
   - Relies on network isolation

### Network Policies
- Policy: `{name}-https-route`
- Allows: Ingress from `network.openshift.io/policy-group=ingress` namespaces
- Target: OAuth proxy container (8443/TCP)
- Purpose: Enable OpenShift Router access while blocking other traffic

### Secrets
1. **{name}-oauth-proxy** (kubernetes.io/tls): OAuth proxy TLS certificate (auto-rotated by Service CA)
2. **{name}-oauth-cookie-secret** (Opaque): Session cookie encryption (operator-generated)
3. **{db-secret-name}** (Opaque): Database password (user-provided)
4. **{ssl-cert-secret}** (Opaque): Database client SSL certs (optional, user-provided)
5. **webhook-server-cert** (kubernetes.io/tls): Webhook TLS cert (cert-manager or Service CA)

### Security Context
- **runAsNonRoot**: true
- **SeccompProfile**: RuntimeDefault
- **SCC**: restricted-v2 (OpenShift)
- **Capabilities**: None added
- **Privileged**: false

## Known Limitations

1. **Single Replica**: Model registry deployments run with 1 replica (no HA support)
2. **Database Backend**: User must provision and manage PostgreSQL or MySQL database separately
3. **OAuth Only**: OpenShift OAuth proxy is the only authentication mechanism in v1beta1 (Istio/Authorino removed)
4. **No Built-in Backup**: Database backup/restore must be handled externally
5. **OpenShift Specific**: OAuth mode and Routes are OpenShift-specific features
6. **No Multi-Tenancy**: Each ModelRegistry CR creates an independent deployment

## Migration Notes (v1alpha1 → v1beta1)

- **Removed**: Istio/Authorino authentication support (spec.istio field)
- **Removed**: Gateway configuration (spec.gateway field)
- **Removed**: gRPC server support
- **Changed**: OAuth proxy is now the only supported authentication method
- **Changed**: Conversion webhook handles automatic migration of existing v1alpha1 CRs

## Updating Diagrams

To regenerate after architecture changes:
```bash
# From repository root
cd architecture/rhoai-2.25.0
# Regenerate diagrams (auto-output to diagrams/ subdirectory)
/generate-architecture-diagrams --architecture=model-registry-operator.md
```

## References

- **Source Architecture**: [model-registry-operator.md](../model-registry-operator.md)
- **Upstream Project**: https://github.com/opendatahub-io/model-registry
- **Operator Repository**: https://github.com/red-hat-data-services/model-registry-operator
- **API Documentation**: https://github.com/opendatahub-io/model-registry-operator/tree/main/api
- **OpenShift OAuth Proxy**: https://github.com/openshift/oauth-proxy
