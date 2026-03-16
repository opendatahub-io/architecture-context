# Architecture Diagrams for Kueue

Generated from: `architecture/rhoai-2.16/kueue.md`
Date: 2026-03-16

**Note**: Diagram filenames use base component name without version (directory is already versioned).

## Available Diagrams

All Mermaid diagrams are available in both `.mmd` (source) and `.png` (3000px width, high-resolution) formats.

### For Developers
- [Component Structure](./kueue-component.png) ([mmd](./kueue-component.mmd)) - Mermaid diagram showing internal components, CRDs, and integrations
- [Data Flows](./kueue-dataflow.png) ([mmd](./kueue-dataflow.mmd)) - Sequence diagram of job submission, admission, and reconciliation flows
- [Dependencies](./kueue-dependencies.png) ([mmd](./kueue-dependencies.mmd)) - Component dependency graph showing integrations with Kubeflow, Ray, and JobSet

### For Architects
- [C4 Context](./kueue-c4-context.dsl) - System context in C4 format (Structurizr)
- [Component Overview](./kueue-component.png) ([mmd](./kueue-component.mmd)) - High-level component view with external dependencies

### For Security Teams
- [Security Network Diagram (PNG)](./kueue-security-network.png) - High-resolution network topology
- [Security Network Diagram (Mermaid)](./kueue-security-network.mmd) - Visual network topology (editable)
- [Security Network Diagram (ASCII)](./kueue-security-network.txt) - Precise text format for SAR submissions
- [RBAC Visualization](./kueue-rbac.png) ([mmd](./kueue-rbac.mmd)) - RBAC permissions and bindings

## Key Architecture Highlights

### Component Overview
Kueue is a Kubernetes job queueing controller that manages workload admission and resource allocation based on priorities and quotas. It consists of:

- **kueue-controller-manager**: Main controller managing workload admission and queue reconciliation
- **webhook-service**: Admission webhook for mutating and validating job resources
- **visibility-server**: Extended API server providing visibility into pending workloads
- **metrics-service**: Prometheus metrics endpoint for monitoring queue and workload state

### Supported Job Types
Kueue manages admission for multiple job frameworks:
- Kubernetes Batch Jobs
- Kubeflow Training Jobs (PyTorchJob, TFJob, MPIJob, XGBoostJob, MXJob, PaddleJob)
- Ray Workloads (RayJob, RayCluster)
- JobSets (multi-job workflows)
- Plain Pods

### Key Features
- **Queue Management**: StrictFIFO and BestEffortFIFO queueing strategies
- **Resource Quotas**: Per-ClusterQueue resource management with ResourceFlavors
- **Fair Sharing**: Multi-tenant resource sharing and preemption
- **Autoscaling Integration**: cluster-autoscaler integration via ProvisioningRequests
- **Multi-Cluster**: Alpha support for distributing workloads across multiple clusters (MultiKueue)
- **Admission Checks**: Extensible pre-admission validation framework

### Network Architecture
- **Webhook Service**: Port 9443/TCP HTTPS (mTLS with K8s API Server)
- **Visibility API**: Port 8082/TCP HTTPS (mTLS via APIService aggregation)
- **Metrics**: Port 8443/TCP HTTPS (Bearer Token authentication)
- **Health Probes**: Port 8081/TCP HTTP (unauthenticated for kubelet)

### Security
- **RBAC**: Comprehensive ClusterRole for managing jobs, workloads, and Kueue CRDs
- **Authentication**: mTLS for webhooks and visibility API, Bearer Token for metrics
- **Certificates**: TLS certificates provisioned by cert-manager or internal generator
- **Network Policy**: Allows TCP/9443 from any source for webhook calls

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
# From repository root
/generate-architecture-diagrams --architecture=architecture/rhoai-2.16/kueue.md
```

## Component Details

### Custom Resource Definitions (CRDs)
- **ClusterQueue**: Cluster-wide queue managing resource quotas and admission policies
- **LocalQueue**: Namespace-scoped queue mapping workloads to ClusterQueues
- **Workload**: Abstract representation of job resource requirements
- **ResourceFlavor**: Defines resource variants (node types, zones) for quota management
- **WorkloadPriorityClass**: Defines priority levels for workload admission ordering
- **AdmissionCheck**: Configures pre-admission validation checks for workloads
- **ProvisioningRequestConfig**: Configuration for cluster-autoscaler provisioning requests
- **MultiKueueCluster**: Defines remote clusters for multi-cluster job distribution (alpha)
- **MultiKueueConfig**: Configuration for multi-cluster queue management (alpha)

### Integration Points
- **Kubernetes API Server**: Watch and reconcile jobs, workloads, and queue resources (6443/TCP)
- **Kubeflow Training Operator**: Manage admission for ML training jobs (via CRD watching)
- **Ray Operator**: Manage admission for Ray distributed workloads (via CRD watching)
- **JobSet Controller**: Manage admission for multi-job workflows (via CRD watching)
- **cluster-autoscaler**: Create ProvisioningRequests for node autoscaling (443/TCP)
- **Prometheus**: Collect queue and workload metrics (8443/TCP)

### RHOAI Deployment Configuration
- **Namespace**: opendatahub
- **Resources**: CPU 500m-2, Memory 512Mi
- **Components**: CRDs, RBAC, Controller, Webhooks, Metrics, Network Policy
- **Version**: rhoai-2.16 (v-2160-163-g191c1eac5)
