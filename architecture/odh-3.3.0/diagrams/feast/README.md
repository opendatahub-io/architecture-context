# Architecture Diagrams for Feast Feature Store

Generated from: `architecture/odh-3.3.0/feast.md`
Date: 2026-03-12
Version: 0.61.0 (ODH 3.3.0)

## Available Diagrams

### For Developers
- **[Component Structure](./feast-component.mmd)** - Mermaid diagram showing Feast internal components, CRs, storage backends, and client interactions
- **[Data Flows](./feast-dataflow.mmd)** - Sequence diagram of feature retrieval, materialization, and push flows with protocols and ports
- **[Dependencies](./feast-dependencies.mmd)** - Component dependency graph showing infrastructure, storage, and integration points

### For Architects
- **[C4 Context](./feast-c4-context.dsl)** - System context in C4 format (Structurizr) showing Feast in the broader ODH/RHOAI ecosystem
- **[Component Overview](./feast-component.mmd)** - High-level component view with deployment topology

### For Security Teams
- **[Security Network Diagram](./feast-security-network.txt)** - Detailed ASCII network topology with:
  - Exact ports, protocols, and encryption (TLS versions)
  - Authentication mechanisms (Bearer tokens, OIDC, mTLS, IAM)
  - Trust boundaries (external, ingress, application, operator)
  - RBAC matrix with all permissions
  - Secrets and credential management
  - Network policy recommendations
  - Observability and monitoring endpoints
- **[RBAC Visualization](./feast-rbac.mmd)** - RBAC permissions, service accounts, and resource access patterns

---

## How to Use

### Mermaid Diagrams (.mmd files)

**Option 1: Embed in GitHub/GitLab Markdown**
Mermaid diagrams render automatically in markdown files on GitHub, GitLab, and many other platforms:

\`\`\`markdown
```mermaid
graph TB
    ... (paste diagram content) ...
```
\`\`\`

**Option 2: Render to PNG/SVG locally (recommended for presentations)**

1. **Install Mermaid CLI** (one-time setup):
   ```bash
   npm install -g @mermaid-js/mermaid-cli
   ```

2. **Generate PNG** (using system Chrome for rendering):
   ```bash
   # Basic (default resolution)
   PUPPETEER_EXECUTABLE_PATH=/usr/bin/google-chrome mmdc -i feast-component.mmd -o feast-component.png

   # High resolution (recommended - 3x scale for presentations)
   PUPPETEER_EXECUTABLE_PATH=/usr/bin/google-chrome mmdc -i feast-component.mmd -o feast-component.png -s 3

   # Custom width (height auto-adjusts to maintain aspect ratio)
   PUPPETEER_EXECUTABLE_PATH=/usr/bin/google-chrome mmdc -i feast-component.mmd -o feast-component.png -w 2400
   ```

3. **Alternative formats**:
   ```bash
   # SVG (vector format - scales perfectly, ideal for PDFs)
   PUPPETEER_EXECUTABLE_PATH=/usr/bin/google-chrome mmdc -i feast-component.mmd -o feast-component.svg

   # PDF
   PUPPETEER_EXECUTABLE_PATH=/usr/bin/google-chrome mmdc -i feast-component.mmd -o feast-component.pdf
   ```

**Note**: If `google-chrome` is not at `/usr/bin/google-chrome`, find it with:
```bash
which google-chrome   # or
which chromium
```

**Option 3: Online Editor**
- Visit https://mermaid.live
- Paste diagram code
- Click "Export PNG" or "Export SVG"

---

### C4 Diagrams (.dsl files)

**Option 1: Structurizr Lite (Docker)**
```bash
cd architecture/odh-3.3.0/diagrams/feast/
docker run -it --rm -p 8080:8080 -v $(pwd):/usr/local/structurizr structurizr/lite
# Open http://localhost:8080 in browser
```

**Option 2: Structurizr CLI Export**
```bash
# Install Structurizr CLI
wget https://github.com/structurizr/cli/releases/latest/download/structurizr-cli.zip
unzip structurizr-cli.zip

# Export to PNG
./structurizr.sh export -workspace feast-c4-context.dsl -format png

# Export to SVG
./structurizr.sh export -workspace feast-c4-context.dsl -format svg
```

**Option 3: Online Editor**
- Visit https://structurizr.com/dsl
- Paste DSL code
- Export diagrams

---

### ASCII Diagrams (.txt files)

**View in any text editor** (best with monospace font):
```bash
cat feast-security-network.txt
# or
less feast-security-network.txt
```

**Include in documentation as-is** - Perfect for:
- Security Architecture Reviews (SAR)
- Compliance documentation
- Technical specifications
- No ambiguity about protocols, ports, or encryption

---

## Diagram Descriptions

### feast-component.mmd
Shows the Feast deployment architecture:
- Feast Operator managing FeatureStore CR
- Feature Servers (Online and Offline) for serving
- Registry Service for metadata
- Transformation Service for on-demand features
- UI Service for exploration
- Storage backends (Redis, PostgreSQL, BigQuery, Snowflake, S3, GCS)
- Client interactions from ML applications, training jobs, and stream processing

**Best for**: Understanding component relationships and deployment topology

---

### feast-dataflow.mmd
Sequence diagram showing three critical data flows:
1. **Real-Time Feature Retrieval**: ML app → Online Server → Registry → Online Store → Transform
2. **Feature Materialization**: User/CronJob → Online Server → Offline Store → Online Store
3. **Feature Push**: Stream app → Online Server → Online/Offline Store

Includes exact ports, protocols, encryption, and authentication for each hop.

**Best for**: Understanding request/response flows and technical integration details

---

### feast-security-network.txt
Comprehensive ASCII network diagram with:
- **Trust Boundaries**: External → Ingress → Application → Operator → Egress
- **Network Details**: Exact ports (80/TCP, 6566/TCP, 5432/TCP, etc.), protocols (HTTP, gRPC, PostgreSQL, Redis), encryption (TLS 1.2+, optional mTLS)
- **Authentication Matrix**: Bearer tokens, OIDC, mTLS, AWS IAM, GCP Service Accounts
- **RBAC Summary**: All ClusterRoles, ClusterRoleBindings, and permissions
- **Secrets Management**: TLS certs, database credentials, registry backends, OIDC
- **Service Mesh**: Optional Istio PeerAuthentication and AuthorizationPolicy
- **Observability**: Metrics endpoints, health checks, logs, tracing
- **Network Policy Recommendations**: Suggested ingress/egress rules

**Best for**: Security Architecture Reviews, compliance audits, and deployment planning

---

### feast-c4-context.dsl
C4 System Context and Container diagrams showing:
- **Actors**: Data Scientists, ML Applications
- **Feast Containers**: Operator, Feature Servers, Registry, Transform, UI
- **External Dependencies**: Kubernetes, Istio, Prometheus, cert-manager
- **Storage Systems**: Redis, PostgreSQL, BigQuery, Snowflake, S3, GCS
- **ODH/RHOAI Integrations**: KServe, Seldon Core, MLflow, Kubeflow
- **Data Pipelines**: Kafka, Spark, Ray, OpenLineage

**Best for**: Architectural presentations, stakeholder communication, and understanding ecosystem context

---

### feast-dependencies.mmd
Dependency graph categorized by:
- **External Infrastructure**: Kubernetes, Python, Protobuf (required)
- **Optional Infrastructure**: Istio, cert-manager, Prometheus, OpenShift Route
- **Storage Backends**: Online stores (Redis, PostgreSQL, DynamoDB, etc.), Offline stores (BigQuery, Snowflake, Spark), Registry (PostgreSQL, S3, GCS)
- **ODH/RHOAI Integration**: KServe, Seldon Core, MLflow, Kubeflow, Service Mesh
- **Data Pipeline Integration**: Kafka, Spark, Ray, OpenLineage
- **Observability**: OpenTelemetry, Prometheus metrics

**Best for**: Technology stack planning, integration analysis, and dependency tracking

---

### feast-rbac.mmd
RBAC visualization showing:
- **Service Accounts**: feast-operator-controller-manager
- **ClusterRoles**: manager-role, featurestore-editor-role, featurestore-viewer-role, metrics-reader
- **ClusterRoleBindings**: How service accounts are bound to roles
- **Resource Permissions**:
  - Feast CRDs (FeatureStore, status, finalizers)
  - Kubernetes core resources (Deployments, Services, ConfigMaps, Secrets, etc.)
  - RBAC resources (Roles, RoleBindings, ClusterRoles, ClusterRoleBindings)
  - OpenShift resources (Routes)
  - Batch and scaling resources (CronJobs, HPAs, PDBs)
  - Authentication resources (TokenReviews)

**Best for**: Understanding permissions, security audits, and RBAC troubleshooting

---

## Updating Diagrams

To regenerate diagrams after architecture changes:

```bash
# From repository root
/generate-architecture-diagrams --architecture=architecture/odh-3.3.0/feast.md

# Or with custom output directory
/generate-architecture-diagrams --architecture=architecture/odh-3.3.0/feast.md --output-dir=./custom-diagrams

# Or generate specific formats only
/generate-architecture-diagrams --architecture=architecture/odh-3.3.0/feast.md --formats=mermaid,security
```

---

## Integration with Documentation

### Embedding in Markdown
```markdown
## Feast Architecture

The Feast Feature Store consists of multiple services:

```mermaid
graph TB
    ... (paste feast-component.mmd content) ...
```

### Network Flow

```mermaid
sequenceDiagram
    ... (paste feast-dataflow.mmd content) ...
```
\`\`\`

### Including in Security Reviews
```markdown
## Network Architecture

See [Security Network Diagram](./diagrams/feast/feast-security-network.txt) for complete details on:
- Network topology with exact ports and protocols
- Authentication and authorization mechanisms
- TLS/mTLS configuration
- RBAC permissions matrix
- Secrets and credential management
```

---

## Related Documentation

- **Source Architecture**: [feast.md](../../feast.md)
- **Feast Official Docs**: https://docs.feast.dev
- **ODH Feast Operator**: https://github.com/feast-dev/feast/tree/master/infra/feast-operator
- **Mermaid Syntax**: https://mermaid.js.org/intro/
- **C4 Model**: https://c4model.com/
- **Structurizr DSL**: https://github.com/structurizr/dsl

---

## Feedback & Contributions

Found an issue or want to improve these diagrams?
- Report issues or suggest improvements in the repository
- Diagrams are auto-generated from structured architecture markdown
- Update the source architecture file and regenerate diagrams
