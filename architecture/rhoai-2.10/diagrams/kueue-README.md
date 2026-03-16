# Architecture Diagrams for Kueue

Generated from: `architecture/rhoai-2.10/kueue.md`
Date: 2026-03-15
Component: kueue (job queueing system)

**Note**: Diagram filenames use base component name without version (directory is already versioned).

## Available Diagrams

All Mermaid diagrams are available in both `.mmd` (source) and `.png` (3000px width, high-resolution) formats.

### For Developers
- **[Component Structure](./kueue-component.png)** ([mmd](./kueue-component.mmd)) - Mermaid diagram showing internal components, CRDs, and job types
- **[Data Flows](./kueue-dataflow.png)** ([mmd](./kueue-dataflow.mmd)) - Sequence diagram of job submission, admission, queueing, and autoscaler integration flows
- **[Dependencies](./kueue-dependencies.png)** ([mmd](./kueue-dependencies.mmd)) - Component dependency graph with job frameworks and CRDs

### For Architects
- **[C4 Context](./kueue-c4-context.dsl)** - System context in C4 format (Structurizr) showing Kueue in the ODH ecosystem
- **[Component Overview](./kueue-component.png)** ([mmd](./kueue-component.mmd)) - High-level component view

### For Security Teams
- **[Security Network Diagram (PNG)](./kueue-security-network.png)** - High-resolution network topology with trust zones
- **[Security Network Diagram (Mermaid)](./kueue-security-network.mmd)** - Visual network topology (editable)
- **[Security Network Diagram (ASCII)](./kueue-security-network.txt)** - Precise text format for SAR submissions
- **[RBAC Visualization](./kueue-rbac.png)** ([mmd](./kueue-rbac.mmd)) - RBAC permissions and bindings

## Component Overview

**Kueue** is a Kubernetes-native job queueing system that manages job admission and resource allocation based on quotas and priorities. It provides:

- **Multi-tenant resource management**: ClusterQueues and LocalQueues for fair resource distribution
- **Priority-based scheduling**: StrictFIFO and BestEffortFIFO queueing strategies
- **Job framework support**: Kubernetes Jobs, Kubeflow training jobs, Ray, JobSets
- **Advanced features**: Preemption, quota borrowing, autoscaler integration
- **Webhook-based admission**: Intercepts job creation to manage queueing

### Key Components
- **kueue-controller-manager**: Main controller reconciling workloads and queues
- **kueue-webhook-server**: Mutating/validating webhooks for jobs and CRDs
- **Queue Manager**: FIFO/priority queueing strategies
- **Scheduler**: Workload admission decisions based on quotas

### Network Topology
- **Namespace**: opendatahub
- **Webhook endpoint**: 9443/TCP (HTTPS, TLS 1.2+)
- **Metrics**: 8080/TCP (HTTP, unauthenticated) and 8443/TCP (HTTPS, authenticated via kube-rbac-proxy)
- **Health probes**: 8081/TCP (HTTP, /healthz, /readyz)
- **No external ingress**: All services are internal ClusterIP

### Security Highlights
- **RBAC**: ClusterRole `kueue-manager-role` with full CRUD access to Kueue CRDs and job types
- **Webhook auth**: Kubernetes API Server certificate authentication
- **Pod security**: runAsNonRoot=true, User 65532:65532, no privilege escalation
- **Secrets**: TLS certificates for webhook server (cert-manager or internal generation)
- **Network policy**: Allows webhook traffic (9443/TCP) from Kubernetes API Server

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
- **Structurizr Lite**:
  ```bash
  docker run -p 8080:8080 -v $(pwd):/usr/local/structurizr structurizr/lite
  ```
  Then open http://localhost:8080 and load the .dsl file

- **CLI export**:
  ```bash
  structurizr-cli export -workspace kueue-c4-context.dsl -format png
  ```

### ASCII Diagrams (.txt files)
- View in any text editor with monospace font
- Include in documentation as-is (preserves formatting)
- Perfect for security reviews (precise technical details, no ambiguity)
- Required format for Security Architecture Reviews (SAR)

## Diagram Details

### Component Structure Diagram
Shows:
- Kueue controller manager with Queue Manager, Scheduler, and Job Framework
- Webhook server for job mutation/validation
- Custom resources (ClusterQueue, LocalQueue, Workload, ResourceFlavor, AdmissionCheck)
- Supported job types (Batch Jobs, Kubeflow, Ray, JobSets)
- External dependencies (Kubernetes, cert-manager, Prometheus, Cluster Autoscaler)

### Data Flow Diagram
Visualizes 4 main flows:
1. **Job Submission and Admission**: User → API Server → Webhook → Controller → Scheduler → Job admission
2. **Metrics Collection**: Prometheus scraping from metrics endpoints (8080/TCP and 8443/TCP)
3. **Workload Queueing and Preemption**: Priority-based queue management and pod eviction
4. **Autoscaler Integration**: ProvisioningRequest creation for guaranteed node provisioning

### Security Network Diagram
Detailed network topology showing:
- **External tier**: User/application access via Kubernetes API (6443/TCP)
- **Control plane**: Kubernetes API Server with webhook calls
- **Service mesh**: Kueue pods in opendatahub namespace with ClusterIP services
- **Egress**: API Server calls for managing resources and autoscaling
- **RBAC summary**: ClusterRole permissions for controller and users
- **Webhook configurations**: Mutating and validating webhook details
- **Secrets**: TLS certificates and rotation policies
- **Network policies**: Webhook traffic allowlist
- **Pod security**: Non-root execution, capability dropping

Available in 3 formats:
- **ASCII (.txt)**: Precise text format for SAR documentation
- **Mermaid (.mmd)**: Editable diagram source
- **PNG (.png)**: High-resolution visual for presentations

### C4 Context Diagram
Shows Kueue's position in the broader ecosystem:
- **Users**: Data Scientists, ML Engineers, Cluster Administrators
- **Kueue containers**: Controller Manager, Webhook Server, Visibility Server
- **External dependencies**: Kubernetes, cert-manager, Prometheus, Cluster Autoscaler
- **Internal ODH components**: Kubeflow Training Operator, Ray Operator, Dashboard, Pipelines
- **Job types**: Batch Jobs, Kubeflow jobs, Ray jobs, JobSets
- **Integration points**: Webhook interception, ProvisioningRequest API

### Dependency Graph
Visualizes:
- **Required dependencies**: Kubernetes 1.22+
- **Optional dependencies**: cert-manager, Prometheus, Cluster Autoscaler, job framework operators
- **Internal ODH dependencies**: Kubeflow Training Operator, Ray Operator, Monitoring Stack
- **Integration points**: Dashboard, Data Science Pipelines
- **Managed job types**: All supported job CRDs
- **Provided CRDs**: ClusterQueue, LocalQueue, Workload, ResourceFlavor, AdmissionCheck, WorkloadPriorityClass, ProvisioningRequestConfig

### RBAC Visualization
Shows:
- **Service account**: kueue-controller-manager (opendatahub namespace)
- **ClusterRole**: kueue-manager-role with full CRUD access to:
  - Core resources (Pods, Jobs, Events, Secrets)
  - Kueue CRDs (ClusterQueues, LocalQueues, Workloads, etc.)
  - Job framework CRDs (Kubeflow, Ray, JobSets)
  - Autoscaling API (ProvisioningRequests)
  - Webhook configurations
- **User role**: kueue-batch-user-role for authenticated users (read-only access to queues and workloads)
- **Aggregate roles**: kueue-batch-admin-role, kueue-clusterqueue-viewer-role

## Updating Diagrams

To regenerate after architecture changes:

```bash
# From repository root
cd architecture/rhoai-2.10

# Regenerate all diagrams
python ../../scripts/generate_diagram_pngs.py diagrams --width=3000
```

Or use the full workflow:
```bash
# Update architecture documentation first, then regenerate diagrams
# (Add your architecture update process here)
```

## Related Documentation

- **Architecture file**: [../kueue.md](../kueue.md)
- **Upstream project**: https://github.com/kubernetes-sigs/kueue
- **Upstream docs**: https://kueue.sigs.k8s.io/
- **RHOAI fork**: https://github.com/red-hat-data-services/kueue
- **Version**: Based on upstream Kueue v0.6.2 with RHOAI patches
- **API version**: v1beta1 (Kubernetes Deprecation Policy compliant)

## Notes

- **Namespace**: Deployed to `opendatahub` (not `kueue-system` as in upstream)
- **RHOAI customizations**: Network Policy, metrics service, RBAC enhancements, waitForPodsReady default
- **Webhook failure policy**: Fail (blocks job submission if webhook unavailable)
- **Leader election**: Enabled (only one active controller instance)
- **Pod security**: Restricted profile (non-root, no privilege escalation)
- **Certificate management**: cert-manager recommended, internal generation available as fallback
