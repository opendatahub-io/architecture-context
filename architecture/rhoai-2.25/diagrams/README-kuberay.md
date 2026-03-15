# Architecture Diagrams for KubeRay

Generated from: `architecture/rhoai-2.25/kuberay.md`
Date: 2026-03-15

**Note**: Diagram filenames use base component name without version (directory is already versioned).

## Available Diagrams

All Mermaid diagrams are available in both `.mmd` (source) and `.png` (3000px width, high-resolution) formats.

### For Developers
- [Component Structure](./kuberay-component.png) ([mmd](./kuberay-component.mmd)) - Mermaid diagram showing internal components, controllers, and Ray cluster resources
- [Data Flows](./kuberay-dataflow.png) ([mmd](./kuberay-dataflow.mmd)) - Sequence diagrams of RayCluster creation, RayJob execution, RayService deployment, and autoscaling
- [Dependencies](./kuberay-dependencies.png) ([mmd](./kuberay-dependencies.mmd)) - Component dependency graph showing required and optional integrations

### For Architects
- [C4 Context](./kuberay-c4-context.dsl) - System context in C4 format (Structurizr) showing KubeRay in the broader RHOAI ecosystem
- [Component Overview](./kuberay-component.png) ([mmd](./kuberay-component.mmd)) - High-level component view with operator controllers and dynamically created resources

### For Security Teams
- [Security Network Diagram (PNG)](./kuberay-security-network.png) - High-resolution network topology with trust zones and encryption details
- [Security Network Diagram (Mermaid)](./kuberay-security-network.mmd) - Visual network topology (editable)
- [Security Network Diagram (ASCII)](./kuberay-security-network.txt) - Precise text format for SAR submissions with RBAC, secrets, and SCC details
- [RBAC Visualization](./kuberay-rbac.png) ([mmd](./kuberay-rbac.mmd)) - RBAC permissions for operator and dynamically created Ray cluster ServiceAccounts

## Component Overview

**KubeRay Operator** manages the lifecycle of Ray clusters, jobs, and ML serving workloads on Kubernetes. It provides:

- **RayCluster**: Distributed Ray compute clusters with autoscaling and fault tolerance
- **RayJob**: Batch job execution with automatic cluster creation and cleanup
- **RayService**: ML model serving with zero-downtime updates (blue-green deployments)

### Key Features

- **Autoscaling**: Dynamic worker scaling based on resource demand
- **Fault Tolerance**: Optional external Redis for GCS high availability
- **Gang Scheduling**: Integration with Volcano/YuniKorn for distributed workloads
- **OpenShift Support**: Routes, SCCs, and UBI-based images
- **Observability**: Prometheus metrics and Ray Dashboard integration

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
   PUPPETEER_EXECUTABLE_PATH=/usr/bin/google-chrome mmdc -i kuberay-component.mmd -o kuberay-component.png -w 3000
   ```

3. **Alternative formats** (if needed):
   ```bash
   # SVG (vector, scales perfectly)
   PUPPETEER_EXECUTABLE_PATH=/usr/bin/google-chrome mmdc -i kuberay-component.mmd -o kuberay-component.svg

   # PDF
   PUPPETEER_EXECUTABLE_PATH=/usr/bin/google-chrome mmdc -i kuberay-component.mmd -o kuberay-component.pdf
   ```

**Note**: If `google-chrome` is not found, try `chromium` or `which google-chrome` to locate it

### C4 Diagrams (.dsl files)
- **Structurizr Lite**: `docker run -p 8080:8080 -v $(pwd):/usr/local/structurizr structurizr/lite`
- **CLI export**: `structurizr-cli export -workspace kuberay-c4-context.dsl -format png`
- **Online**: Upload to https://structurizr.com/workspace

### ASCII Diagrams (.txt files)
- View in any text editor
- Include in documentation as-is
- Perfect for security reviews (precise technical details with RBAC, secrets, SCC)

## Diagram Details

### 1. Component Diagram
Shows the KubeRay operator architecture with:
- Main operator controllers (RayCluster, RayJob, RayService)
- Admission webhook for CR validation
- Dynamically created Ray cluster resources (head pod, worker pods, services)
- External dependencies (Kubernetes API, Prometheus, Redis, cert-manager, Volcano)
- Integration with OpenShift Routes and Ingress

### 2. Data Flow Diagram
Four key operational flows:
- **Flow 1**: RayCluster creation and lifecycle management
- **Flow 2**: RayJob batch execution with automatic cluster provisioning
- **Flow 3**: RayService model serving with zero-downtime updates (blue-green deployment)
- **Flow 4**: Autoscaling worker nodes based on resource demand

### 3. Security Network Diagram
Comprehensive network architecture with:
- **Trust zones**: External, Ingress (DMZ), Control Plane, Operator Namespace, Application Namespace, External Services
- **Network flows**: Exact ports, protocols, encryption (TLS 1.2+, mTLS, plaintext)
- **Authentication**: ServiceAccount tokens, mTLS, optional Redis password, optional Dashboard token
- **Services**: Operator metrics (8080), webhook (9443), Ray GCS (6379), Dashboard (8265), Serve (8000)
- **RBAC summary**: Cluster-scoped operator permissions and namespace-scoped Ray cluster autoscaler
- **Secrets**: Webhook TLS cert, optional Redis password, optional Dashboard auth token
- **OpenShift SCC**: Security constraints for Ray workloads

### 4. C4 Context Diagram
System context showing:
- **Users**: Data scientists, ML engineers, platform administrators
- **KubeRay components**: Operator controllers, admission webhook, metrics exporter
- **Ray cluster**: Head pod, worker pods, GCS, Dashboard, Serve
- **External dependencies**: Kubernetes, Prometheus, cert-manager, Redis, schedulers (Volcano, YuniKorn, Kueue)
- **RHOAI integrations**: OpenShift API (Routes), ODH Dashboard
- **External services**: Container registry, Ray package index, S3/cloud storage
- **Dynamic views**: RayCluster creation, RayJob execution, RayService deployment flows

### 5. Dependencies Diagram
Shows:
- **Required**: Kubernetes 1.21+
- **Optional external**: cert-manager, Prometheus, Grafana, Redis, Volcano, YuniKorn, Kueue
- **Internal RHOAI**: OpenShift API (Routes), SCC, ODH Dashboard
- **Integration points**: Data Science Pipelines, Jupyter Notebooks, RHOAI Workbenches
- **Runtime dependencies**: Container registry, Ray package index, Git/S3/GCS

### 6. RBAC Diagram
Visualizes:
- **Operator identity**: ServiceAccount `kuberay-operator` in `kuberay-system` or `opendatahub` namespace
- **ClusterRole permissions**: Manages Pods, Services, Jobs, Ray CRDs, Ingresses, Routes, Roles, RoleBindings, Leases
- **Ray cluster identity**: Dynamically created ServiceAccount `{cluster-name}-sa` with namespace-scoped permissions
- **Autoscaler permissions**: Pod creation/deletion for auto-scaling workers

## Security Considerations

### Network Security
- **Operator to K8s API**: HTTPS/443 with TLS 1.2+ and ServiceAccount token authentication
- **Admission webhook**: HTTPS/9443 with mTLS (K8s API server client cert)
- **Ray intra-cluster**: Plain TCP (GCS on port 6379, Dashboard on 8265)
- **External access**: Optional TLS termination via Ingress/Route
- **External Redis**: Optional TLS and password authentication for GCS fault tolerance

### Authentication & Authorization
- **Operator**: Cluster-scoped ClusterRole with broad permissions (Pods, Services, Jobs, CRDs, Routes)
- **Ray clusters**: Namespace-scoped Role for autoscaler (create/delete Pods)
- **Ray Dashboard**: Optional Bearer token authentication (configurable per cluster)
- **Ray GCS**: Optional Redis password (configurable per cluster)
- **Ray Serve**: No built-in auth (application-level authentication required)

### OpenShift Security Context Constraints
KubeRay creates a restrictive SCC for Ray workloads:
- No host access (network, PID, IPC, ports, directories)
- No privileged containers
- No additional capabilities
- `runAsUser`: MustRunAsRange
- `seLinuxContext`: MustRunAs

### Secrets Management
- **webhook-server-cert**: TLS certificate for admission webhook (cert-manager, 90-day rotation)
- **{cluster}-redis-password**: Optional Redis authentication (user-managed)
- **{cluster}-auth-token**: Optional Ray Dashboard authentication (user-managed)

## Updating Diagrams

To regenerate after architecture changes:

```bash
# Read architecture documentation and generate all diagram formats
cd /path/to/repository

# Generate diagrams (auto-detects output directory from architecture file location)
# This creates diagrams in: architecture/rhoai-2.25/diagrams/
python scripts/generate_architecture_diagrams.py architecture/rhoai-2.25/kuberay.md
```

## Version Information

- **Component**: KubeRay Operator
- **Version**: f10d68b1 (RHOAI 2.25 branch)
- **Repository**: https://github.com/red-hat-data-services/kuberay
- **Distribution**: RHOAI (Red Hat OpenShift AI)
- **Base Image**: UBI9 minimal (FIPS-compliant Go 1.24.2)
- **Build System**: Konflux
- **Deployment**: Kustomize manifests in `ray-operator/config/openshift/`

## Additional Resources

- **KubeRay Documentation**: https://docs.ray.io/en/latest/cluster/kubernetes/index.html
- **Ray Dashboard**: Access via Ingress/Route on port 8265 (if enabled)
- **Prometheus Metrics**: Operator exposes metrics on port 8080 at `/metrics`
- **Health Checks**: `/healthz` and `/readyz` endpoints on port 8080
