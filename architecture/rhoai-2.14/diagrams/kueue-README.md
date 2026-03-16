# Architecture Diagrams for Kueue

Generated from: `architecture/rhoai-2.14/kueue.md`
Date: 2026-03-15
Component: kueue (derived from filename)
Version: v0.8.1 (RHOAI 2.14)

**Note**: Diagram filenames use base component name without version (directory is already versioned).

## Available Diagrams

All Mermaid diagrams are available in both `.mmd` (source) and `.png` (3000px width, high-resolution) formats.

### For Developers
- [Component Structure](./kueue-component.png) ([mmd](./kueue-component.mmd)) - Mermaid diagram showing internal components, CRDs, job frameworks, and external dependencies
- [Data Flows](./kueue-dataflow.png) ([mmd](./kueue-dataflow.mmd)) - Sequence diagram of job submission, admission, metrics collection, and visibility API flows
- [Dependencies](./kueue-dependencies.png) ([mmd](./kueue-dependencies.mmd)) - Component dependency graph showing integrations with Kubeflow, Ray, CodeFlare, and cluster autoscaler

### For Architects
- [C4 Context](./kueue-c4-context.dsl) - System context in C4 format (Structurizr) showing Kueue in the broader RHOAI ecosystem
- [Component Overview](./kueue-component.png) ([mmd](./kueue-component.mmd)) - High-level component view with job framework integrations

### For Security Teams
- [Security Network Diagram (PNG)](./kueue-security-network.png) - High-resolution network topology with trust zones
- [Security Network Diagram (Mermaid)](./kueue-security-network.mmd) - Visual network topology (editable)
- [Security Network Diagram (ASCII)](./kueue-security-network.txt) - Precise text format for SAR submissions with detailed RBAC, network policies, and authentication
- [RBAC Visualization](./kueue-rbac.png) ([mmd](./kueue-rbac.mmd)) - RBAC permissions and bindings for controller, batch admins, and users

## Component Overview

**Kueue** is a Kubernetes-native job queueing system that manages job admission and resource allocation across multiple workload types. It provides:

- **Job Queueing**: Priority-based queueing with StrictFIFO and BestEffortFIFO strategies
- **Resource Management**: Cluster-level and namespace-level resource quotas
- **Multi-Framework Support**: Integrates with Batch Jobs, Kubeflow (MPIJob, PyTorchJob, TFJob), Ray, JobSet, and RHOAI AppWrappers
- **Cluster Autoscaling**: Dynamic node provisioning via ProvisioningRequest API
- **Visibility API**: REST API for querying pending workloads and queue status

### Key Components

1. **kueue-controller-manager**: Main operator managing job admission, queueing, and resource allocation
2. **webhook-server**: Admission webhooks for validating and mutating job resources
3. **visibility-server**: REST API for querying queue and workload status
4. **importer**: Utility for importing and converting existing jobs to Kueue workloads
5. **kueuectl**: CLI tool for managing Kueue resources

### Custom Resource Definitions

- **ClusterQueue**: Cluster-level resource pool with quotas and queuing policies
- **LocalQueue**: Namespace-scoped queue mapping to a ClusterQueue
- **Workload**: Internal representation of a job with resource requirements
- **ResourceFlavor**: Defines resource variants (node types, zones)
- **WorkloadPriorityClass**: Priority levels for workload scheduling
- **AdmissionCheck**: Pre-admission checks for workloads
- **ProvisioningRequestConfig**: Configuration for cluster autoscaler integration

### RHOAI-Specific Features

- **AppWrapper Integration**: Native support for CodeFlare AppWrappers
- **Metrics Service**: Dedicated ClusterIP service for Prometheus metrics
- **PodMonitor**: Direct pod metrics collection
- **NetworkPolicy**: Webhook server ingress network policy
- **UBI9 Base Image**: Red Hat Universal Base Image for enterprise support

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
   PUPPETEER_EXECUTABLE_PATH=/usr/bin/google-chrome mmdc -i kueue-component.mmd -o kueue-component.png -w 3000
   ```

3. **Alternative formats** (if needed):
   ```bash
   # SVG (vector, scales perfectly)
   PUPPETEER_EXECUTABLE_PATH=/usr/bin/google-chrome mmdc -i kueue-component.mmd -o kueue-component.svg

   # PDF
   PUPPETEER_EXECUTABLE_PATH=/usr/bin/google-chrome mmdc -i kueue-component.mmd -o kueue-component.pdf
   ```

**Note**: If `google-chrome` is not found, try `chromium` or `which google-chrome` to locate it

### C4 Diagrams (.dsl files)
- **Structurizr Lite**: `docker run -p 8080:8080 -v .:/usr/local/structurizr structurizr/lite`
- **CLI export**: `structurizr-cli export -workspace kueue-c4-context.dsl -format png`
- **Online editor**: https://structurizr.com/dsl

### ASCII Diagrams (.txt files)
- View in any text editor
- Include in documentation as-is
- Perfect for security reviews (precise technical details)
- Contains RBAC summary, network policies, secrets, and authentication details

## Diagram Details

### Component Structure Diagram
Shows the internal architecture of Kueue including:
- Controller manager, webhook server, visibility server
- Custom resource definitions (ClusterQueue, LocalQueue, Workload, etc.)
- Job framework integrations (Batch, Kubeflow, Ray, JobSet, AppWrapper)
- External dependencies (Kubernetes API, cert-manager, Prometheus, Cluster Autoscaler)

### Data Flow Diagram
Illustrates four key flows:
1. **Job Submission and Admission**: User submits job → webhook mutation → controller creates Workload → queue evaluation → admission or enqueue
2. **Metrics Collection**: Prometheus scrapes metrics from controller
3. **Visibility API Query**: User queries pending workloads via aggregated API
4. **Cluster Autoscaling**: Controller creates ProvisioningRequest → Cluster Autoscaler provisions nodes

### Security Network Diagram
Detailed network topology showing:
- **Trust zones**: External users, Kubernetes API, Kueue namespace, workload namespaces, external services
- **Network flows**: Precise port numbers (6443, 8080, 8082, 9443), protocols (HTTPS, HTTP), encryption (TLS 1.2+, K8s mTLS)
- **Authentication**: Bearer tokens, ServiceAccount tokens, K8s mTLS
- **RBAC**: manager-role, batch-admin-role, batch-user-role with detailed permissions
- **Secrets**: webhook-server-cert, visibility-server-cert (cert-manager provisioned)
- **Network policies**: Webhook server ingress policy

### Dependencies Diagram
Shows relationships with:
- **External dependencies**: Kubernetes 1.25+, cert-manager (optional), Prometheus Operator (optional)
- **Internal RHOAI dependencies**: Kubeflow Training Operator, CodeFlare AppWrapper, Ray Operator, JobSet
- **Integration points**: Kubernetes API Server, autoscaling.x-k8s.io API, Cluster Autoscaler

### RBAC Diagram
Visualizes permission model:
- **Service accounts**: controller-manager, visibility-server
- **Operator roles**: manager-role (full CRUD on Kueue CRDs, watch on job frameworks)
- **User roles**: batch-admin-role (manage LocalQueues), batch-user-role (view LocalQueues)
- **Resource-specific roles**: clusterqueue-editor/viewer, localqueue-editor/viewer, workload-editor/viewer, resourceflavor-editor/viewer

## Updating Diagrams

To regenerate after architecture changes:
```bash
# From repository root
python scripts/generate_diagram_pngs.py architecture/rhoai-2.14/diagrams --width=3000
```

Or regenerate all diagrams from the architecture file using the skill (if available):
```bash
/generate-architecture-diagrams --architecture=architecture/rhoai-2.14/kueue.md
```

## Related Documentation

- Architecture file: [kueue.md](../kueue.md)
- Repository: https://github.com/red-hat-data-services/kueue
- Upstream documentation: https://kueue.sigs.k8s.io/
- RHOAI version: v0.8.1 (commit 630106f49)

## Key Integration Points

### Job Framework Support
Kueue integrates with the following job frameworks via CRD watches and mutating webhooks:

- **Batch Jobs** (batch/v1): Standard Kubernetes Jobs
- **Kubeflow Training**: MPIJob, PyTorchJob, TFJob, XGBoostJob, MXJob, PaddleJob
- **Ray**: RayJob, RayCluster
- **JobSet**: Multi-job workflows
- **CodeFlare AppWrapper**: RHOAI-specific workload wrapper for distributed training

### Cluster Autoscaling
Kueue creates `ProvisioningRequest` resources (autoscaling.x-k8s.io) when pending workloads exceed available resources. The Cluster Autoscaler watches these requests and provisions nodes via cloud provider APIs.

### Observability
Prometheus scrapes metrics from the controller on port 8080/TCP (HTTP, plaintext). Metrics include:
- Queue depths (pending, admitted workloads)
- Admission performance (attempts, wait time)
- Cluster queue resource utilization
- Controller reconciliation metrics

## Security Considerations

1. **Webhook Dependencies**: Admission control requires webhook service availability; use cert-manager for production cert management
2. **RBAC Scope**: LocalQueues are namespaced; users cannot see or interact with queues in other namespaces
3. **Resource Preemption**: Configure WorkloadPriorityClass carefully to avoid disrupting running workloads
4. **Multi-cluster Features**: MultiKueue features are alpha (v1alpha1) and may have stability limitations
5. **Network Policies**: Default webhook server NetworkPolicy allows all ingress on port 9443; consider additional restrictions based on your environment
