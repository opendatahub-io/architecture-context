# Architecture Diagrams for RHODS Operator

Generated from: `architecture/rhoai-2.10/rhods-operator.md`
Date: 2026-03-15

**Note**: Diagram filenames use base component name without version (directory is already versioned).

## Available Diagrams

All Mermaid diagrams are available in both `.mmd` (source) and `.png` (3000px width, high-resolution) formats.

### For Developers
- [Component Structure](./rhods-operator-component.png) ([mmd](./rhods-operator-component.mmd)) - Mermaid diagram showing internal controllers and managed components
- [Data Flows](./rhods-operator-dataflow.png) ([mmd](./rhods-operator-dataflow.mmd)) - Sequence diagram of component deployment, webhook, metrics, and initialization flows
- [Dependencies](./rhods-operator-dependencies.png) ([mmd](./rhods-operator-dependencies.mmd)) - Component dependency graph showing external and internal dependencies

### For Architects
- [C4 Context](./rhods-operator-c4-context.dsl) - System context in C4 format (Structurizr)
- [Component Overview](./rhods-operator-component.png) ([mmd](./rhods-operator-component.mmd)) - High-level component view showing controllers and integrations

### For Security Teams
- [Security Network Diagram (PNG)](./rhods-operator-security-network.png) - High-resolution network topology
- [Security Network Diagram (Mermaid)](./rhods-operator-security-network.mmd) - Visual network topology (editable)
- [Security Network Diagram (ASCII)](./rhods-operator-security-network.txt) - Precise text format for SAR submissions
- [RBAC Visualization](./rhods-operator-rbac.png) ([mmd](./rhods-operator-rbac.mmd)) - RBAC permissions and bindings

## Component Overview

**RHODS Operator** is the primary platform operator for Red Hat OpenShift AI that orchestrates deployment and lifecycle management of data science and ML components.

### Key Controllers
- **DataScienceCluster Controller**: Manages component deployment and lifecycle
- **DSCInitialization Controller**: Initializes platform infrastructure (namespaces, service mesh, monitoring)
- **FeatureTracker Controller**: Tracks cross-namespace resources for garbage collection
- **SecretGenerator Controller**: Generates and manages platform secrets
- **CertConfigMapGenerator Controller**: Generates TLS certificate ConfigMaps
- **Webhook Server**: CRD conversion webhook for API version compatibility

### Managed Components
The operator deploys and manages 10 data science components:
- ODH Dashboard (Web UI)
- Notebook Controller (Jupyter workbenches)
- Data Science Pipelines (ML workflows)
- KServe (serverless model serving)
- ModelMesh Serving (multi-model serving)
- CodeFlare Operator (distributed workload orchestration)
- KubeRay Operator (Ray cluster management)
- TrustyAI Operator (AI fairness and explainability)
- Training Operator (distributed training)
- Kueue (multi-tenant job queueing)

### External Dependencies
- **Required**: Kubernetes/OpenShift 1.25+
- **Conditional**: OpenShift Service Mesh, Authorino, Serverless, Pipelines
- **Optional**: Prometheus Operator, cert-manager

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

## Diagram Details

### Component Diagram
Shows the internal structure of the RHODS Operator:
- 6 controllers (DSC, DSCI, FeatureTracker, SecretGenerator, CertConfigMapGenerator, Status)
- Webhook server for CRD conversion
- Metrics server for Prometheus
- Custom Resources (DataScienceCluster, DSCInitialization, FeatureTracker)
- 10 managed components
- External dependencies and integrations

### Data Flow Diagram
Illustrates 4 key flows:
1. **DataScienceCluster Component Deployment**: User creates DSC CR → Operator fetches manifests from GitHub → Deploys components
2. **CRD Conversion Webhook**: User submits legacy API version → API server calls webhook → Converted CR returned
3. **Metrics Collection**: Prometheus scrapes metrics via kube-rbac-proxy → Metrics endpoint
4. **Platform Initialization**: Admin creates DSCI CR → Operator creates namespaces → Configures service mesh and monitoring

### Security Network Diagram
Available in both ASCII (.txt) and Mermaid (.mmd) formats showing:
- Trust boundaries (External, Control Plane, Operator Pod, Kubernetes Resources)
- Port numbers (6443/TCP for K8s API, 9443/TCP for webhook, 8443/TCP for metrics)
- Protocols and encryption (HTTPS with TLS 1.2+, mTLS for webhook)
- Authentication mechanisms (ServiceAccount tokens, mTLS certificates)
- RBAC summary with ClusterRole permissions
- Service configurations and secrets

### Dependencies Diagram
Visualizes:
- **External Required**: Kubernetes/OpenShift 1.25+
- **External Conditional**: Service Mesh, Authorino, Serverless, Pipelines (required for specific components)
- **External Optional**: Prometheus Operator, cert-manager
- **Internal Components**: 10 managed ODH components
- **External Services**: GitHub (manifests), Quay.io and Red Hat Registry (images)

### RBAC Diagram
Comprehensive view of RBAC configuration:
- ServiceAccount: `controller-manager` in `openshift-operators` namespace
- ClusterRole: `controller-manager-role` with extensive permissions
- Permissions for:
  - Platform CRDs (DataScienceCluster, DSCInitialization, FeatureTracker)
  - Core resources (namespaces, configmaps, secrets, services, serviceaccounts)
  - Workloads (deployments, statefulsets, jobs)
  - RBAC resources (roles, rolebindings, clusterroles, clusterrolebindings)
  - OpenShift resources (routes)
  - Networking (networkpolicies)
  - Admission webhooks
  - API extensions (CRDs)
  - OLM (subscriptions, CSVs)
  - Service Mesh (SMCP, SMMR, SMM)
  - KServe (InferenceServices, ServingRuntimes)
  - Knative (Services, KnativeServings)
  - Authorino (AuthConfigs)
  - Monitoring (ServiceMonitors, Prometheuses, Alertmanagers)
  - Cert Manager (Certificates, Issuers)
- Additional roles for editor/viewer access to DataScienceCluster and DSCInitialization

### C4 Context Diagram
Shows the RHODS Operator in the broader system context:
- Users: Platform Administrator, Data Scientist
- RHODS Operator containers (6 controllers, webhook, metrics)
- External dependencies (Kubernetes, Service Mesh, Serverless, etc.)
- Internal ODH components (10 managed components)
- Integration points and data flows

## Network Architecture

### Exposed Services
- **controller-manager-metrics-service**: ClusterIP, 8443/TCP (kube-rbac-proxy) → 8080/TCP (metrics), internal only
- **webhook-service**: ClusterIP, 9443/TCP HTTPS with TLS 1.2+ and mTLS, internal only

### Ingress
No external ingress configured - operator is cluster-internal only

### Egress
- **GitHub**: 443/TCP HTTPS for fetching component manifests
- **Quay.io**: 443/TCP HTTPS for pulling container images
- **Red Hat Registry**: 443/TCP HTTPS for pulling base images
- **Kubernetes API**: 6443/TCP HTTPS for managing cluster resources

## Security Highlights

### Authentication & Authorization
- **Webhook endpoint**: mTLS client certificates (Kubernetes API Server only)
- **Metrics endpoint**: kube-rbac-proxy validates ServiceAccount tokens
- **Kubernetes API**: ServiceAccount token authentication with RBAC enforcement

### Secrets
- **webhook-server-cert**: TLS certificate for webhook server (auto-rotated by cert-manager or operator)
- **controller-manager-token**: ServiceAccount authentication token (auto-rotated by Kubernetes)

### Security Context
- `runAsNonRoot: true`
- `allowPrivilegeEscalation: false`
- Capabilities dropped
- Read-only root filesystem recommended

## Updating Diagrams

To regenerate after architecture changes:
```bash
# From the architecture directory
python ../scripts/generate_diagram_pngs.py diagrams --width=3000
```

Or use the full workflow:
```bash
# Update architecture documentation first, then regenerate diagrams
# (Manual process - update rhods-operator.md, then regenerate)
```

## Related Documentation
- Source architecture: [rhods-operator.md](../rhods-operator.md)
- RHOAI platform overview: [PLATFORM.md](../PLATFORM.md)
- Component repositories:
  - https://github.com/red-hat-data-services/rhods-operator
  - https://github.com/opendatahub-io/odh-dashboard
  - https://github.com/opendatahub-io/notebooks
  - https://github.com/opendatahub-io/data-science-pipelines-operator
  - https://github.com/kserve/kserve
  - https://github.com/opendatahub-io/modelmesh-serving
  - https://github.com/project-codeflare/codeflare-operator
  - https://github.com/ray-project/kuberay
  - https://github.com/trustyai-explainability/trustyai-service-operator
  - https://github.com/kubeflow/training-operator
  - https://github.com/kubernetes-sigs/kueue
