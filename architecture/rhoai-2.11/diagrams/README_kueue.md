# Architecture Diagrams for Kueue

Generated from: `architecture/rhoai-2.11/kueue.md`
Date: 2026-03-15
Component: kueue (derived from filename)

**Note**: Diagram filenames use base component name without version (directory is already versioned).

## Available Diagrams

All Mermaid diagrams are available in both `.mmd` (source) and `.png` (3000px width, high-resolution) formats.

### For Developers
- [Component Structure](./kueue-component.png) ([mmd](./kueue-component.mmd)) - Mermaid diagram showing internal components, controllers, and CRD relationships
- [Data Flows](./kueue-dataflow.png) ([mmd](./kueue-dataflow.mmd)) - Sequence diagram of job submission, admission, reconciliation, and metrics collection flows
- [Dependencies](./kueue-dependencies.png) ([mmd](./kueue-dependencies.mmd)) - Component dependency graph showing integration with Kubeflow, Ray, KServe

### For Architects
- [C4 Context](./kueue-c4-context.dsl) - System context in C4 format (Structurizr)
- [Component Overview](./kueue-component.png) ([mmd](./kueue-component.mmd)) - High-level component view with controllers and services

### For Security Teams
- [Security Network Diagram (PNG)](./kueue-security-network.png) - High-resolution network topology with trust zones
- [Security Network Diagram (Mermaid)](./kueue-security-network.mmd) - Visual network topology (editable)
- [Security Network Diagram (ASCII)](./kueue-security-network.txt) - Precise text format for SAR submissions with RBAC details
- [RBAC Visualization](./kueue-rbac.png) ([mmd](./kueue-rbac.mmd)) - RBAC permissions, bindings, and user-facing roles

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

## Updating Diagrams

To regenerate after architecture changes:
```bash
# From the repository root
cd architecture/rhoai-2.11
# The script will auto-detect the output directory as architecture/rhoai-2.11/diagrams/
```

## Component Summary

**Kueue** is a Kubernetes-native job-level queue manager that provides sophisticated resource management and fair sharing for batch workloads. It implements queueing strategies (StrictFIFO, BestEffortFIFO) to control when jobs are admitted to start and when they should stop.

### Key Features
- **Multi-framework support**: Kubernetes Batch Jobs, JobSet, Kubeflow training jobs (TFJob, PyTorchJob, MPIJob), Ray (RayJob, RayCluster)
- **Resource management**: ClusterQueue quotas, ResourceFlavors, priority-based scheduling, preemption
- **Fair sharing**: Cohorts for resource borrowing between tenants
- **Autoscaling**: Integration with Cluster Autoscaler via ProvisioningRequest API
- **Multi-tenant**: Namespace-scoped LocalQueues linked to cluster-wide ClusterQueues

### Architecture Highlights
- **Deployment**: Single controller with leader election in `opendatahub` namespace
- **CRDs**: 9 custom resources (Workload, ClusterQueue, LocalQueue, ResourceFlavor, AdmissionCheck, etc.)
- **Webhooks**: Mutating and validating webhooks for Jobs, JobSets, and Kueue CRDs
- **Security**: Non-root execution (UID 65532), mTLS for webhooks, NetworkPolicy enforcement
- **Monitoring**: Prometheus metrics on ports 8080 (HTTP) and 8443 (HTTPS with kube-rbac-proxy)

### Network Services
- `kueue-webhook-service`: 443/TCP (webhook validation/mutation, mTLS)
- `kueue-visibility-server`: 443/TCP (extended APIs for pending workloads)
- `kueue-metrics-service`: 8080/TCP (HTTP metrics, unauthenticated)
- `kueue-controller-manager-metrics-service`: 8443/TCP (HTTPS metrics, authenticated)

### RBAC Summary
- **Controller Role**: `kueue-manager-role` with permissions for:
  - Kueue CRDs (full CRUD)
  - Batch Jobs (watch, update)
  - Kubeflow training jobs (watch, update)
  - Ray jobs and clusters (watch, update)
  - JobSet (watch, update)
  - ProvisioningRequests (full CRUD for autoscaling)
- **User Roles**: Pre-created roles for batch job management, queue management, and workload visibility

### Integration Points
- **Kubeflow Training Operator**: Queues TFJob, PyTorchJob, MPIJob, MXJob, PaddleJob, XGBoostJob
- **Ray Operator**: Queues RayJob and RayCluster resources
- **KServe**: Optional queueing for inference serving workloads
- **Cluster Autoscaler**: Triggers node provisioning for queued workloads
- **Prometheus**: Metrics collection for monitoring queue depths and admission rates
