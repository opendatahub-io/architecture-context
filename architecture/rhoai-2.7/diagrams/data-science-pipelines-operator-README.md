# Architecture Diagrams for Data Science Pipelines Operator

Generated from: `architecture/rhoai-2.7/data-science-pipelines-operator.md`
Date: 2026-03-15
Component: data-science-pipelines-operator

**Note**: Diagram filenames use base component name without version (directory is already versioned).

## Available Diagrams

All Mermaid diagrams are available in both `.mmd` (source) and `.png` (3000px width, high-resolution) formats.

### For Developers
- [Component Structure](./data-science-pipelines-operator-component.png) ([mmd](./data-science-pipelines-operator-component.mmd)) - Mermaid diagram showing internal components, DSPO controller, API server, persistence agent, scheduled workflow, MariaDB, Minio, MLMD, and their relationships
- [Data Flows](./data-science-pipelines-operator-dataflow.png) ([mmd](./data-science-pipelines-operator-dataflow.mmd)) - Sequence diagram of request/response flows: UI submission, pipeline execution via kfp-tekton SDK, scheduled execution, and MLMD metadata tracking
- [Dependencies](./data-science-pipelines-operator-dependencies.png) ([mmd](./data-science-pipelines-operator-dependencies.mmd)) - Component dependency graph showing relationships with Tekton, ODH Dashboard, OpenShift OAuth, external S3/DB

### For Architects
- [C4 Context](./data-science-pipelines-operator-c4-context.dsl) - System context in C4 format (Structurizr) showing DSPO in broader ecosystem with Tekton, ODH Dashboard, external storage, and user interactions
- [Component Overview](./data-science-pipelines-operator-component.png) ([mmd](./data-science-pipelines-operator-component.mmd)) - High-level component view of DSPO architecture

### For Security Teams
- [Security Network Diagram (PNG)](./data-science-pipelines-operator-security-network.png) - High-resolution network topology with trust boundaries, authentication layers (OAuth, Service Accounts), encryption (TLS, mTLS), ports, and protocols
- [Security Network Diagram (Mermaid)](./data-science-pipelines-operator-security-network.mmd) - Visual network topology (editable) showing external → ingress → OAuth → application → external services flows
- [Security Network Diagram (ASCII)](./data-science-pipelines-operator-security-network.txt) - Precise text format for SAR submissions with detailed RBAC summary, NetworkPolicy rules, secrets, and service mesh configuration
- [RBAC Visualization](./data-science-pipelines-operator-rbac.png) ([mmd](./data-science-pipelines-operator-rbac.mmd)) - RBAC permissions and bindings: ClusterRole manager-role, namespace-scoped roles for API server, pipeline-runner, scheduled workflow, and persistence agent

## Component Overview

The **Data Science Pipelines Operator (DSPO)** is a Kubernetes operator that deploys and manages single-namespace scoped Data Science Pipeline stacks. Based on upstream Kubeflow Pipelines (KFP) with kfp-tekton backend, it enables data scientists to create, track, and iterate on ML workflows.

**Key Components**:
- **DSPO Controller Manager**: Reconciles DataSciencePipelinesApplication CRs
- **API Server**: KFP API server (HTTP/8888, gRPC/8887, HTTPS/8443 via OAuth)
- **Persistence Agent**: Syncs Tekton PipelineRun metadata to database
- **Scheduled Workflow Controller**: Manages cron-based pipeline triggers
- **MariaDB**: Metadata database (dev/test; use external for production)
- **Minio**: S3-compatible storage (dev/test; use external S3 for production)
- **ML Pipelines UI**: Web UI (unsupported; ODH Dashboard integration recommended)
- **MLMD Components**: Optional ML Metadata tracking (Envoy proxy, gRPC server, writer)

**Key Dependencies**:
- **OpenShift Pipelines (Tekton) 1.8+**: Required for pipeline execution (kfp-tekton backend)
- **OpenShift OAuth**: External route authentication via OAuth proxy
- **External S3 Storage**: Production artifact storage (AWS S3, Azure Blob, etc.)
- **External Database**: Production metadata storage (MySQL/PostgreSQL)

## Security Highlights

**Authentication**:
- External access: OAuth Bearer Token (JWT) via OpenShift OAuth proxy on Routes (8443/TCP HTTPS TLS 1.2+ Reencrypt)
- Internal API calls: Service Account Tokens
- MariaDB: Username/Password
- S3: Access/Secret Key (or AWS IAM for external S3)
- MLMD: No authentication (internal only, protected by NetworkPolicy)

**Network Policies**:
- **Port 8443/TCP**: Open to all (OAuth proxy endpoint)
- **Ports 8888/TCP, 8887/TCP**: Restricted to DSPA components, monitoring namespaces (openshift-user-workload-monitoring, redhat-ods-monitoring)

**RBAC**:
- **ClusterRole manager-role**: Extensive permissions for DSPO controller (DSPA CRs, Deployments, Services, Secrets, Routes, Tekton resources, ML workload CRs)
- **Namespace Roles**: Per-DSPA roles for API server, pipeline-runner (extensive pod/job/ML workload permissions), scheduled workflow, persistence agent

**Secrets**:
- `ds-pipeline-db-{name}`: MariaDB password (DSPO-provisioned, no auto-rotate)
- `mlpipeline-minio-artifact`: S3 access/secret keys (user or DSPO-provisioned)
- `ds-pipelines-proxy-tls-{name}`: OAuth proxy TLS cert (Service CA, 90-day auto-rotate)
- `mariadb-{name}`, `minio-{name}`: Internal deployment credentials (DSPO-provisioned)

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
# From repository root
cd architecture/rhoai-2.7
# Regenerate diagrams (auto-detects output directory)
# This command would be run from your architecture diagram generation tool
```

## Related Documentation

- [Data Science Pipelines Operator Architecture](../data-science-pipelines-operator.md)
- [RHOAI 2.7 Platform Architecture](../PLATFORM.md)
- [Kubeflow Pipelines Documentation](https://www.kubeflow.org/docs/components/pipelines/)
- [kfp-tekton Documentation](https://github.com/kubeflow/kfp-tekton)
- [OpenShift Pipelines (Tekton) Documentation](https://docs.openshift.com/pipelines/)

## Notes

- **Production Configuration**: Use external S3 (AWS/Azure) and external database (managed MySQL/PostgreSQL) for production deployments. Minio and internal MariaDB are unsupported for production.
- **ML Pipelines UI**: Unsupported; use ODH Dashboard integration for production workloads.
- **Tekton Backend**: DSPO uses kfp-tekton (not Argo) for pipeline execution, requiring OpenShift Pipelines (Tekton) to be installed.
- **Namespace Isolation**: Each DSPA is namespace-scoped. Multiple DSPA instances can exist in different namespaces but not in the same namespace.
- **Pipeline Runner Permissions**: The `pipeline-runner-{name}` service account has extensive permissions within the DSPA namespace to support various ML workload integrations (Ray, Seldon, CodeFlare, Tekton, etc.).
