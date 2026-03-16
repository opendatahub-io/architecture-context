# Architecture Diagrams for Kueue

Generated from: `architecture/rhoai-2.13/kueue.md`
Date: 2026-03-15
Component: **Kueue** - Kubernetes job queueing controller

**Note**: Diagram filenames use base component name without version (directory is already versioned).

## Available Diagrams

All Mermaid diagrams are available in both `.mmd` (source) and `.png` (3000px width, high-resolution) formats.

### For Developers
- [Component Structure](./kueue-component.png) ([mmd](./kueue-component.mmd)) - Mermaid diagram showing internal components, CRDs, and job framework integrations
- [Data Flows](./kueue-dataflow.png) ([mmd](./kueue-dataflow.mmd)) - Sequence diagram of job submission, admission, visibility API queries, and multi-cluster distribution
- [Dependencies](./kueue-dependencies.png) ([mmd](./kueue-dependencies.mmd)) - Component dependency graph showing Kubernetes, job frameworks, and optional integrations

### For Architects
- [C4 Context](./kueue-c4-context.dsl) - System context in C4 format (Structurizr) showing Kueue in the RHOAI ecosystem
- [Component Overview](./kueue-component.png) ([mmd](./kueue-component.mmd)) - High-level component view with manager, webhook, visibility API, and scheduler

### For Security Teams
- [Security Network Diagram (PNG)](./kueue-security-network.png) - High-resolution network topology with trust boundaries
- [Security Network Diagram (Mermaid)](./kueue-security-network.mmd) - Visual network topology (editable)
- [Security Network Diagram (ASCII)](./kueue-security-network.txt) - Precise text format for SAR submissions with RBAC, secrets, and network policies
- [RBAC Visualization](./kueue-rbac.png) ([mmd](./kueue-rbac.mmd)) - RBAC permissions, bindings, and user-facing roles

## Diagram Descriptions

### Component Structure (`kueue-component.mmd/png`)
Shows the internal architecture of Kueue including:
- **Manager Controller**: Reconciles ClusterQueues, LocalQueues, Workloads
- **Webhook Server**: Mutates/validates job submissions (9443/TCP HTTPS)
- **Visibility API Server**: REST API for pending workloads (8082/TCP HTTPS)
- **Queue Manager**: In-memory cache for workload queues
- **Scheduler Engine**: Admission decision logic
- **Job Framework Integrations**: Batch, Kubeflow Training, Ray, JobSet, CodeFlare AppWrapper
- **Kueue CRDs**: ClusterQueue, LocalQueue, Workload, ResourceFlavor, AdmissionCheck, WorkloadPriorityClass
- **External Dependencies**: Kubernetes API, cert-manager, Prometheus, Cluster Autoscaler, Remote Clusters

### Data Flows (`kueue-dataflow.mmd/png`)
Sequence diagrams showing:
1. **Job Submission and Admission**: User → API Server → Webhook → Manager → Queue → Scheduler → Job unsuspended
2. **Visibility API Query**: User → API Server (aggregation) → Visibility Server → Queue Manager → Response
3. **Metrics Collection**: Prometheus → Metrics endpoint (8080/TCP HTTP)
4. **Multi-Cluster Distribution (MultiKueue)**: Manager distributes workloads to remote clusters, monitors status

### Security Network Diagram (`kueue-security-network.txt/mmd/png`)
**Three formats** for different use cases:

#### ASCII Format (`.txt`) - For Security Architecture Reviews
Precise text-based diagram with:
- Port numbers, protocols, encryption (TLS versions)
- Authentication mechanisms (Bearer Token, mTLS, ServiceAccount, KubeConfig)
- Trust boundaries (External, Control Plane, Kueue Namespace, Monitoring)
- **RBAC Summary**: ClusterRoles, bindings, permissions for all API groups
- **Network Policies**: kueue-webhook-server ingress rules
- **Secrets**: Webhook cert, Visibility cert, MultiKueue credentials
- **Health Probes**: Liveness/readiness endpoints
- **Integration Points**: Detailed interaction with Batch, Kubeflow, Ray, JobSet, CodeFlare
- **Feature Flags**: Controller settings and enabled integrations

#### Mermaid Format (`.mmd`) - Editable Visual Diagram
Color-coded network topology showing:
- Trust zones: External, Control Plane, opendatahub namespace, Monitoring
- Network flows with ports, protocols, encryption, auth
- Service accounts, secrets, certificates
- Integration with job frameworks

#### PNG Format (`.png`) - High-Resolution Image
3000px width image for presentations and documentation.

### Dependencies (`kueue-dependencies.mmd/png`)
Dependency graph showing:
- **External Dependencies (Required)**: Kubernetes 1.22+
- **External Dependencies (Optional)**: cert-manager, Prometheus Operator, Cluster Autoscaler (dashed lines)
- **Internal RHOAI Dependencies**: Kubeflow Training Operator, Ray Operator, CodeFlare Operator
- **Integration Points**: ODH Dashboard (future), Data Science Pipelines
- **Job Frameworks**: Kubernetes Batch Job, JobSet
- **Observability**: Prometheus metrics scraping

### RBAC Visualization (`kueue-rbac.mmd/png`)
Visual representation of RBAC configuration:
- **Service Account**: `opendatahub/kueue-controller-manager`
- **ClusterRole Bindings**: kueue-manager-rolebinding, kueue-proxy-rolebinding, kueue-leader-election-rolebinding
- **ClusterRoles**:
  - `kueue-manager-role`: Manages Kueue CRDs, jobs, pods, Kubeflow/Ray/JobSet resources, provisioning requests
  - `kueue-proxy-role`: Token/access reviews for API aggregation
  - `kueue-leader-election-role`: Leader election for HA
- **User-Facing Roles**: batch-user, batch-admin, clusterqueue-editor/viewer, localqueue-editor/viewer
- **Permissions**: Detailed verbs (create, delete, get, list, patch, update, watch) for each API group

### C4 Context Diagram (`kueue-c4-context.dsl`)
Structurizr DSL diagram showing:
- **Actors**: Data Scientists, Platform Administrators
- **Kueue System**: Manager, Webhook Server, Visibility API Server with internal components
- **Related Systems**: Kubernetes, Kubeflow Training, Ray, CodeFlare, cert-manager, Prometheus, Cluster Autoscaler, Remote Clusters
- **Interactions**: Job submission, queue configuration, metrics scraping, autoscaling, multi-cluster distribution

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

**Example** (embed in markdown):

\`\`\`mermaid
graph TB
    User[User] --> Kueue[Kueue Manager]
    Kueue --> Job[Batch Job]
\`\`\`

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
- **Structurizr Lite** (Docker):
  ```bash
  docker run -it --rm -p 8080:8080 -v $(pwd):/usr/local/structurizr structurizr/lite
  ```
  Then open http://localhost:8080 and upload `kueue-c4-context.dsl`

- **Structurizr CLI** (export to PNG/SVG):
  ```bash
  # Install CLI: https://github.com/structurizr/cli
  structurizr-cli export -workspace kueue-c4-context.dsl -format png
  structurizr-cli export -workspace kueue-c4-context.dsl -format svg
  ```

### ASCII Diagrams (.txt files)
- View in any text editor (monospaced font recommended)
- Include in documentation as-is (preserves formatting)
- Perfect for security reviews (precise technical details, no ambiguity)
- Copy directly into SAR documentation, compliance reports, or technical specifications

## Updating Diagrams

To regenerate after architecture changes:

1. **Update the architecture file**: `architecture/rhoai-2.13/kueue.md`

2. **Regenerate diagrams** (use the appropriate skill/command):
   ```bash
   # If you have the diagram generation skill:
   /generate-architecture-diagrams --architecture=architecture/rhoai-2.13/kueue.md
   ```

3. **Regenerate PNGs only** (if you edited .mmd files):
   ```bash
   python scripts/generate_diagram_pngs.py architecture/rhoai-2.13/diagrams --width=3000
   ```

## Architecture Summary

**Kueue** is a Kubernetes-native job queueing controller that manages workload admission based on resource availability, priorities, and fair sharing policies. Key features:

- **Queueing Strategies**: StrictFIFO, BestEffortFIFO
- **Preemption**: Support for LowerPriority, LowerOrNewerEqualPriority, Any
- **Cohorts**: Multiple ClusterQueues can share quota and borrow/lend resources
- **Admission Checks**: Extension points for cluster autoscaling and multi-cluster distribution
- **Job Framework Support**: Batch, Kubeflow Training (TF, PyTorch, MPI), Ray, JobSet, CodeFlare AppWrapper
- **Visibility API**: Query pending workloads with position tracking and priority information
- **Multi-Cluster (MultiKueue)**: Distribute workloads across remote clusters
- **Observability**: Comprehensive Prometheus metrics for queue usage and admission statistics

### Network Architecture
- **Webhook Server**: 9443/TCP HTTPS (TLS 1.2+, mTLS from API Server)
- **Visibility API**: 8082/TCP HTTPS (TLS, K8s RBAC via API Aggregation)
- **Metrics**: 8080/TCP HTTP (Prometheus scraping, no auth)
- **Health Probes**: 8081/TCP HTTP (/healthz, /readyz)

### Security
- **TLS Certificates**: Auto-provisioned by cert-manager or internal cert manager, auto-rotated
- **RBAC**: ClusterRole `kueue-manager-role` with permissions for Kueue CRDs, jobs, pods, Kubeflow/Ray resources
- **Network Policies**: Allow TCP/9443 to webhook server from any (K8s API Server access)
- **Service Account**: `opendatahub/kueue-controller-manager` with cluster-scoped permissions

### Resource Requirements
- **CPU**: 500m (request and limit)
- **Memory**: 512Mi (request and limit)

---

**For questions or issues**, refer to:
- Architecture documentation: `architecture/rhoai-2.13/kueue.md`
- Kueue repository: https://github.com/red-hat-data-services/kueue.git (rhoai-2.13 branch)
- Kueue upstream documentation: https://kueue.sigs.k8s.io/
