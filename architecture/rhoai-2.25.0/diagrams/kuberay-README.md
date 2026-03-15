# Architecture Diagrams for KubeRay Operator

Generated from: `architecture/rhoai-2.25.0/kuberay.md`
Date: 2026-03-14
Component: KubeRay Operator - Kubernetes operator for distributed Ray clusters and ML workloads

**Note**: Diagram filenames use base component name without version (directory is already versioned).

## Available Diagrams

All Mermaid diagrams are available in both `.mmd` (source) and `.png` (3000px width, high-resolution) formats.

### For Developers
- **[Component Structure](./kuberay-component.png)** ([mmd](./kuberay-component.mmd)) - Mermaid diagram showing KubeRay operator architecture, controllers, and managed Ray cluster components
- **[Data Flows](./kuberay-dataflow.png)** ([mmd](./kuberay-dataflow.mmd)) - Sequence diagrams of RayCluster creation, RayJob submission, RayService zero-downtime updates, and autoscaling flows
- **[Dependencies](./kuberay-dependencies.png)** ([mmd](./kuberay-dependencies.mmd)) - Component dependency graph showing required/optional external dependencies and integrations

### For Architects
- **[C4 Context](./kuberay-c4-context.dsl)** - System context in C4 format (Structurizr) showing KubeRay in the broader ODH/RHOAI ecosystem
- **[Component Overview](./kuberay-component.png)** ([mmd](./kuberay-component.mmd)) - High-level component view with operator controllers and Ray cluster lifecycle

### For Security Teams
- **[Security Network Diagram (PNG)](./kuberay-security-network.png)** - High-resolution network topology with trust zones, encryption, and authentication
- **[Security Network Diagram (Mermaid)](./kuberay-security-network.mmd)** - Visual network topology (editable) with color-coded trust boundaries
- **[Security Network Diagram (ASCII)](./kuberay-security-network.txt)** - Precise text format for Security Architecture Review (SAR) submissions
- **[RBAC Visualization](./kuberay-rbac.png)** ([mmd](./kuberay-rbac.mmd)) - RBAC permissions, roles, and service account bindings

## Component Summary

**KubeRay Operator** manages the complete lifecycle of Ray clusters on Kubernetes:

- **RayCluster**: Distributed compute clusters with autoscaling head and worker nodes
- **RayJob**: Batch job submission with automatic cluster provisioning
- **RayService**: ML model serving with zero-downtime blue-green deployments
- **Ray Serve**: Production ML inference endpoints (HTTP/8000)
- **Autoscaling**: Dynamic worker scaling based on resource demand
- **Fault Tolerance**: Optional external Redis for GCS HA

### Key Features
- 3 CRDs: RayCluster, RayJob, RayService (ray.io/v1)
- Admission webhook validation (HTTPS/9443 mTLS)
- OpenShift integration (Routes, SCC)
- Gang scheduling support (Volcano, YuniKorn, Kueue)
- Prometheus metrics (HTTP/8080)
- External GCS storage via Redis (optional)

### Network Endpoints
- **Ray GCS**: 6379/TCP (TCP, optional password)
- **Ray Dashboard**: 8265/TCP (HTTP, optional token)
- **Ray Client**: 10001/TCP (TCP)
- **Ray Serve**: 8000/TCP (HTTP)
- **Operator Metrics**: 8080/TCP (HTTP)
- **Webhook**: 9443/TCP (HTTPS mTLS)

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
- **Structurizr Lite**:
  ```bash
  docker run -p 8080:8080 -v $(pwd):/usr/local/structurizr structurizr/lite
  ```
  Then open http://localhost:8080 and load `kuberay-c4-context.dsl`

- **CLI export**:
  ```bash
  structurizr-cli export -workspace kuberay-c4-context.dsl -format png
  ```

### ASCII Diagrams (.txt files)
- View in any text editor with monospace font
- Include in documentation as-is (no conversion needed)
- Perfect for security reviews (precise technical details, no ambiguity)
- Use for SAR (Security Architecture Review) submissions

## Diagram Details

### Component Diagram
Shows the internal structure of the KubeRay Operator and managed Ray cluster components:
- Operator controllers (RayCluster, RayJob, RayService)
- Admission webhook and metrics exporter
- Ray head and worker pods
- Services and networking
- External dependencies (K8s API, Redis, cert-manager, Prometheus)
- Optional schedulers (Volcano, YuniKorn, Kueue)

### Data Flow Diagram
Illustrates 4 key workflows:
1. **RayCluster Creation**: User creates CR → Operator provisions head/worker pods → Workers register with GCS
2. **RayJob Submission**: User creates RayJob CR → Operator creates RayCluster → Submitter pod executes job
3. **RayService Zero-Downtime Update**: Operator creates v2 cluster → Health checks → Updates service selector → Deletes v1
4. **Autoscaling**: Ray autoscaler monitors load → Creates/deletes worker pods via K8s API

### Security Network Diagram
Provides comprehensive security topology in 3 formats:
- **ASCII (.txt)**: Precise, detailed, text-based - ideal for SAR documentation
- **Mermaid (.mmd)**: Visual, color-coded trust zones - editable source
- **PNG**: High-resolution render - ready for presentations

Shows:
- Trust zones (External, Ingress, Control Plane, Operator, User Namespace, External Services)
- Exact ports and protocols (6379/TCP, 8265/TCP, 8000/TCP, etc.)
- Encryption (TLS 1.2+, mTLS, plaintext)
- Authentication mechanisms (Bearer token, ServiceAccount token, Redis password, optional token)
- RBAC summary (ClusterRole permissions, ServiceAccount bindings)
- Secrets (webhook-server-cert, redis-password, auth-token)
- OpenShift SCC configuration
- Network flows with security details

### Dependencies Diagram
Visualizes external and internal dependencies:
- **Required**: Kubernetes 1.21+, Container Registry, Object Storage, Ray Package Index
- **Optional External**: cert-manager, Prometheus, Grafana, Redis, Volcano, YuniKorn, Kueue
- **OpenShift/RHOAI**: Routes, SCC, ODH Dashboard
- **Integration**: Data Science Pipelines, Jupyter Notebooks

### RBAC Diagram
Maps permissions and roles:
- **ClusterRole**: `kuberay-operator` with extensive permissions for managing pods, services, jobs, CRDs, ingresses, routes, RBAC
- **ServiceAccounts**: `kuberay-operator` (operator), `{cluster}-ray-head` (autoscaler), `{cluster}-ray-worker`
- **API Resources**: Core, batch, ray.io, networking, route.openshift.io, rbac, coordination
- **Verbs**: Full CRUD on most resources, read-only on some (endpoints, ingressclasses)

### C4 Context Diagram
Architectural overview showing:
- **Users**: Data Scientists/ML Engineers, Platform Administrators
- **KubeRay System**: Operator (controllers, webhook, metrics) + Ray Cluster (head, workers, serve)
- **External Systems**: Kubernetes, OpenShift, cert-manager, Prometheus, Redis, schedulers
- **Integrations**: Container Registry, Object Storage, ODH Dashboard
- **Relationships**: How components interact, what protocols they use

## Architecture Highlights

### High Availability
- **Operator**: Single replica (Recreate strategy), optional leader election
- **Ray Cluster**: External Redis for GCS fault tolerance, automatic worker pod recreation
- **RayService**: Zero-downtime blue-green deployments, health monitoring, automatic rollback

### Security Features
- **Admission Webhook**: Validates RayCluster CR operations (mTLS authenticated)
- **OpenShift SCC**: MustRunAsRange for Ray pods (non-privileged)
- **Optional Authentication**: Ray Dashboard token auth, Redis password for GCS
- **Network Isolation**: Internal ClusterIP services, external access via Routes/Ingress
- **RBAC**: Granular permissions for operator and Ray cluster components

### Monitoring
- **Operator Metrics**: Controller reconciliation, CRD watches, webhook latency
- **Ray Cluster Metrics**: Worker replicas, cluster state, resource allocation, pod events
- **RayJob Metrics**: Job submission rates, execution duration, cluster creation latency
- **RayService Metrics**: Serve deployment health, upgrade transitions, endpoint availability

### Deployment
- **Namespace**: opendatahub (default for RHOAI)
- **Base Image**: UBI9 ubi-minimal (FIPS-compliant Go)
- **Build System**: Konflux
- **Resource Requirements**: 100m CPU, 512Mi memory (request and limit)

## Updating Diagrams

To regenerate diagrams after architecture changes:

```bash
# Using the generate-architecture-diagrams skill
/generate-architecture-diagrams --architecture=architecture/rhoai-2.25.0/kuberay.md

# Or manually with Python script (for PNGs only)
python scripts/generate_diagram_pngs.py architecture/rhoai-2.25.0/diagrams --width=3000
```

## Related Documentation

- **Architecture Source**: [kuberay.md](../kuberay.md)
- **Upstream Repository**: https://github.com/red-hat-data-services/kuberay
- **Ray Documentation**: https://docs.ray.io/
- **RHOAI Version**: 2.25.0
- **Branch**: rhoai-2.25

## Questions or Issues?

For questions about these diagrams or the KubeRay architecture:
1. Review the source architecture file: `architecture/rhoai-2.25.0/kuberay.md`
2. Check the upstream KubeRay repository for technical details
3. Consult the RHOAI documentation for deployment guidance
