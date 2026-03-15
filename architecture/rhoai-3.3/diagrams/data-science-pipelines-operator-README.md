# Architecture Diagrams for Data Science Pipelines Operator

Generated from: `architecture/rhoai-3.3/data-science-pipelines-operator.md`
Date: 2026-03-15

**Note**: Diagram filenames use base component name without version (directory is already versioned).

## Available Diagrams

All Mermaid diagrams are available in both `.mmd` (source) and `.png` (3000px width, high-resolution) formats.

### For Developers
- [Component Structure](./data-science-pipelines-operator-component.png) ([mmd](./data-science-pipelines-operator-component.mmd)) - Mermaid diagram showing DSPO architecture, DSPA instances, controllers, and optional components
- [Data Flows](./data-science-pipelines-operator-dataflow.png) ([mmd](./data-science-pipelines-operator-dataflow.mmd)) - Sequence diagram of pipeline submission, execution, artifact storage, and metadata persistence
- [Dependencies](./data-science-pipelines-operator-dependencies.png) ([mmd](./data-science-pipelines-operator-dependencies.mmd)) - Component dependency graph showing platform, database, storage, and ODH integration dependencies

### For Architects
- [C4 Context](./data-science-pipelines-operator-c4-context.dsl) - System context in C4 format (Structurizr) showing DSPO in the broader ODH ecosystem
- [Component Overview](./data-science-pipelines-operator-component.png) ([mmd](./data-science-pipelines-operator-component.mmd)) - High-level component view with DSPO operator, DSPA instances, and integrations

### For Security Teams
- [Security Network Diagram (PNG)](./data-science-pipelines-operator-security-network.png) - High-resolution network topology with trust boundaries
- [Security Network Diagram (Mermaid)](./data-science-pipelines-operator-security-network.mmd) - Visual network topology (editable)
- [Security Network Diagram (ASCII)](./data-science-pipelines-operator-security-network.txt) - Precise text format for SAR submissions with detailed RBAC, NetworkPolicies, and secrets
- [RBAC Visualization](./data-science-pipelines-operator-rbac.png) ([mmd](./data-science-pipelines-operator-rbac.mmd)) - RBAC permissions, service accounts, and bindings for operator and per-DSPA instances

## Component Overview

The Data Science Pipelines Operator (DSPO) is a Kubernetes operator that manages lifecycle of Data Science Pipeline applications based on Kubeflow Pipelines. It deploys namespace-scoped pipeline stacks including:

- **DSPO Controller Manager**: Reconciles DataSciencePipelinesApplication CRs
- **DS Pipeline API Server**: Provides KFP v2 REST/gRPC API (8888/8887 TCP)
- **Argo Workflow Controller**: Executes pipeline tasks as Kubernetes workflows (namespace-scoped)
- **Persistence Agent**: Watches workflows and persists metadata
- **Scheduled Workflow Controller**: Manages recurring pipeline runs
- **ML Metadata gRPC Server**: Optional artifact lineage tracking (8080 TCP)
- **MariaDB**: Optional database for dev/test (3306 TCP)
- **Minio**: Optional S3-compatible storage for dev/test (9000 TCP)

## Architecture Highlights

### Multi-Tier Architecture
1. **Operator Level (Cluster-scoped)**: Single DSPO deployment per cluster manages all DSPA instances
2. **Application Level (Namespace-scoped)**: Each DSPA CR creates isolated pipeline infrastructure in target namespace
3. **Execution Level (Pod-scoped)**: Each pipeline run creates ephemeral Argo Workflow pods for task execution

### Security Features
- **OAuth Proxy**: OpenShift OAuth authentication for external routes (8443 HTTPS)
- **Kube RBAC Proxy**: Bearer token validation via TokenReview/SubjectAccessReview
- **NetworkPolicies**: Restrict API server, MariaDB, MLMD gRPC access to authorized sources
- **Optional mTLS**: Pod-to-pod encryption support for strict environments
- **Auto-Rotating TLS**: Service certificates via OpenShift service-ca

### Dependencies
- **Required Platform**: Kubernetes/OpenShift 4.11+, Argo Workflows (embedded)
- **Required Data**: Database (MariaDB or external MySQL) + Object Storage (Minio or external S3)
- **Optional**: cert-manager for TLS certificate management
- **ODH Integration**: Dashboard (UI), Workbenches (KFP SDK), Monitoring (Prometheus)

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

## Updating Diagrams

To regenerate after architecture changes:
```bash
# Regenerate all diagrams (from repository root)
python scripts/generate_diagram_pngs.py architecture/rhoai-3.3/diagrams --width=3000
```

## Key Flows

### Pipeline Submission via API
1. Data Scientist → OpenShift Route (HTTPS 443, OAuth Token)
2. OAuth Proxy → Kube RBAC Proxy (Bearer Token validation)
3. API Server → MariaDB (MySQL 3306, store metadata)
4. API Server → Kubernetes API (HTTPS 6443, create Workflow CR)
5. Argo Controller → Creates Workflow Pods (ephemeral task execution)

### Pipeline Execution and Artifact Storage
1. Argo Workflow Pod → API Server (gRPC 8887, get pipeline artifacts)
2. Workflow Pod → Minio/S3 (HTTP 9000 or HTTPS 443, upload/download artifacts)
3. Workflow Pod → MLMD gRPC (gRPC 8080, log artifact lineage)
4. Persistence Agent → Watches Workflows (via K8s API)
5. Persistence Agent → MariaDB (MySQL 3306, persist execution metadata)

### Metrics Collection
1. Prometheus → Operator /metrics (HTTP 8080, ServiceAccount Token)
2. Prometheus → API Server /metrics (HTTP 8888, optional)

## RBAC Summary

### Operator Level (Cluster-scoped)
- **ServiceAccount**: controller-manager
- **ClusterRole**: manager-role
- **Permissions**: Full control over DSPA CRs, pipelines, workflows, Argo resources, pods, deployments, routes, networkpolicies, servicemonitors

### Per-DSPA Instance (Namespace-scoped)
- **ds-pipeline-{name}**: API Server service account (access to pipelines, runs, workflows)
- **ds-pipeline-persistenceagent-{name}**: Persistence Agent service account (workflow watch, DB write)
- **ds-pipeline-scheduledworkflow-{name}**: Scheduled Workflow Controller service account
- **ds-pipeline-argo-{name}**: Argo Workflow Controller service account (pod management)
- **pipeline-runner-{name}**: Pipeline task pod service account (task execution permissions)

## Network Policies

- **ds-pipelines-{name}**: Restricts API server access to authorized sources (8443, 8888, 8887)
- **mariadb-{name}**: Restricts database access to DSP components only (3306)
- **ds-pipeline-metadata-grpc-{name}**: Restricts MLMD gRPC to pipeline tasks and internal components (8080)
- **ds-pipelines-envoy-{name}**: Restricts MLMD Envoy access (8443, 9090)

## Secrets

### TLS Certificates (auto-rotated by OpenShift service-ca)
- `ds-pipelines-proxy-tls-{name}`: API Server OAuth Proxy TLS
- `ds-pipelines-mariadb-tls-{name}`: MariaDB pod-to-pod TLS encryption
- `ds-pipelines-envoy-proxy-tls-{name}`: MLMD Envoy Proxy TLS
- `ds-pipeline-metadata-grpc-tls-certs-{name}`: MLMD gRPC mTLS

### Credentials (user-managed)
- `{custom-db-secret}`: Database credentials (username, password, connection string)
- `{custom-storage-secret}`: S3 credentials (AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, endpoint)

## References

- **Repository**: https://github.com/red-hat-data-services/data-science-pipelines-operator
- **Version**: 0.0.1 (rhoai-3.3 branch)
- **Based on**: Kubeflow Pipelines (KFP) v2
- **Architecture Doc**: [data-science-pipelines-operator.md](../data-science-pipelines-operator.md)
