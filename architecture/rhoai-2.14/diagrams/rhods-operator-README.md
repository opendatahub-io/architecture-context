# Architecture Diagrams for rhods-operator

Generated from: `architecture/rhoai-2.14/rhods-operator.md`
Date: 2026-03-15

**Note**: Diagram filenames use base component name without version (directory is already versioned).

## Available Diagrams

All Mermaid diagrams are available in both `.mmd` (source) and `.png` (3000px width, high-resolution) formats.

### For Developers
- [Component Structure](./rhods-operator-component.png) ([mmd](./rhods-operator-component.mmd)) - Mermaid diagram showing internal components, controllers, and deployed components
- [Data Flows](./rhods-operator-dataflow.png) ([mmd](./rhods-operator-dataflow.mmd)) - Sequence diagram of component deployment, platform initialization, and metrics collection flows
- [Dependencies](./rhods-operator-dependencies.png) ([mmd](./rhods-operator-dependencies.mmd)) - Component dependency graph showing external operators and deployed ODH components

### For Architects
- [C4 Context](./rhods-operator-c4-context.dsl) - System context in C4 format (Structurizr)
- [Component Overview](./rhods-operator-component.png) ([mmd](./rhods-operator-component.mmd)) - High-level component view with controllers and integrations

### For Security Teams
- [Security Network Diagram (PNG)](./rhods-operator-security-network.png) - High-resolution network topology
- [Security Network Diagram (Mermaid)](./rhods-operator-security-network.mmd) - Visual network topology (editable)
- [Security Network Diagram (ASCII)](./rhods-operator-security-network.txt) - Precise text format for SAR submissions
- [RBAC Visualization](./rhods-operator-rbac.png) ([mmd](./rhods-operator-rbac.mmd)) - RBAC permissions and bindings for controller-manager

## Component Overview

The **rhods-operator** (also known as opendatahub-operator) is the central orchestration component for the RHOAI/ODH platform. It manages the lifecycle of all data science components including:

- ODH Dashboard
- KServe (model serving)
- ModelMesh Serving
- Data Science Pipelines
- CodeFlare Operator
- KubeRay Operator
- Training Operator
- Kueue
- Model Registry
- TrustyAI Service

### Key Architecture Components

1. **DataScienceCluster Controller**: Manages deployment and lifecycle of data science components
2. **DSCInitialization Controller**: Initializes platform-wide infrastructure (monitoring, service mesh, namespaces, trusted CA)
3. **SecretGenerator Controller**: Dynamically generates and manages secrets for components
4. **CertConfigmapGenerator Controller**: Generates and manages certificate ConfigMaps
5. **Validating Webhook**: Validates DataScienceCluster and DSCInitialization CR creation/deletion
6. **Mutating Webhook**: Provides default values for DataScienceCluster CRs (e.g., ModelRegistry namespace)

### Custom Resource Definitions (CRDs)

- **DataScienceCluster** (`datasciencecluster.opendatahub.io/v1`): Defines which data science components to enable and their configuration
- **DSCInitialization** (`dscinitialization.opendatahub.io/v1`): Initializes platform infrastructure (monitoring, service mesh, namespaces)
- **FeatureTracker** (`features.opendatahub.io/v1`): Tracks resources created by internal Features API for garbage collection

### Network Services

| Service | Port | Purpose | Encryption | Auth |
|---------|------|---------|------------|------|
| webhook-service | 443→9443/TCP | Admission webhooks | TLS 1.2+ (service-ca) | API Server mTLS |
| controller-manager-metrics-service | 8443/TCP | Prometheus metrics | TLS 1.2+ | kube-rbac-proxy |
| Health/Ready endpoints | 8081/TCP | Liveness/readiness probes | None | NetworkPolicy |

### External Dependencies

**Required**:
- Kubernetes 1.25+ / OpenShift 4.12+

**Conditional** (for KServe):
- Service Mesh Operator (Istio)
- Serverless Operator (Knative Serving)
- Authorino Operator (authentication)

**Optional**:
- cert-manager (certificate management)
- Prometheus Operator (monitoring)
- OpenShift Console (ConsoleLinks, ODHQuickStarts)

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

## Diagram Details

### Component Diagram
Shows the internal structure of the rhods-operator:
- 4 reconciliation controllers (DataScienceCluster, DSCInitialization, SecretGenerator, CertConfigmapGenerator)
- Webhook server for admission control
- Auth proxy (kube-rbac-proxy) for authenticated metrics
- Custom Resources (DataScienceCluster, DSCInitialization, FeatureTracker)
- External dependencies (Kubernetes API, GitHub, Quay.io, Service Mesh, Serverless, Authorino)
- Deployed components (all ODH/RHOAI components)

### Data Flow Diagram
Three main flows:
1. **Component Deployment**: User creates DataScienceCluster CR → Webhook validates/mutates → Controller downloads manifests from GitHub → Deploys component resources
2. **Platform Initialization**: Operator creates DSCInitialization CR → Sets up monitoring namespace → Deploys service mesh resources → Configures trusted CA bundles
3. **Metrics Collection**: Prometheus scrapes metrics from operator via authenticated auth proxy endpoint

### Security Network Diagram
Detailed network topology with:
- **Trust boundaries**: External → Kubernetes API → Operator → External Services
- **Ports and protocols**: Exact port numbers (6443/TCP, 9443/TCP, 8443/TCP, 8080/TCP, 8081/TCP, 443/TCP, 5000/TCP)
- **Encryption**: TLS 1.3 (API), TLS 1.2+ (webhooks, metrics, external)
- **Authentication**: kubeconfig credentials, API Server mTLS, ServiceAccount tokens, Bearer tokens
- **Network policies**: Ingress from monitoring/console namespaces, egress unrestricted
- **RBAC summary**: ClusterRole controller-manager-role with full permissions on ODH CRDs, core resources, networking, etc.
- **Secrets**: webhook-cert (service-ca, auto-rotate), prometheus-secrets, segment-key-secret
- **Admission webhooks**: ValidatingWebhookConfiguration and MutatingWebhookConfiguration

### Dependencies Diagram
Shows:
- **External platform dependencies**: Kubernetes, Service Mesh, Serverless, Authorino (required for KServe), cert-manager (optional), Prometheus (optional)
- **Deployed components**: All 10 ODH components managed by the operator
- **External services**: GitHub (manifests), Quay.io (images), Kubernetes API
- **Integration points**: Dashboard UI, DSP pipeline deployment

### RBAC Diagram
Visual representation of:
- ServiceAccount: controller-manager (redhat-ods-operator namespace)
- ClusterRoleBinding: controller-manager-rolebinding
- ClusterRole: controller-manager-role
- Permissions on:
  - ODH CRDs (datasciencecluster, dscinitialization, featuretracker)
  - Core resources (namespaces, configmaps, secrets, services, serviceaccounts)
  - Apps resources (deployments, replicasets, statefulsets)
  - RBAC resources (roles, rolebindings, clusterroles, clusterrolebindings)
  - Networking (routes, networkpolicies)
  - API extensions (CRDs, webhooks)
  - Component CRDs (KServe, DSP, Authorino)
  - OpenShift Console (consolelinks, odhquickstarts)
  - Monitoring (servicemonitors, prometheusrules)
  - Batch (jobs, cronjobs)

### C4 Context Diagram
System context showing:
- **Actors**: Platform Administrator, Data Scientist
- **System**: rhods-operator with containers (Operator Manager with 4 controllers, Webhook Server, Auth Proxy)
- **External systems**: Kubernetes API, GitHub, Quay.io, Prometheus, Service Mesh, Serverless, Authorino
- **Deployed components**: All 10 ODH components
- **Relationships**: API calls, manifest downloads, image pulls, metrics scraping, component deployment

## Updating Diagrams

To regenerate after architecture changes:
```bash
# From repository root
cd architecture/rhoai-2.14
# Edit rhods-operator.md with updated architecture details
# Then regenerate diagrams (assuming you have the generation script)
```

## Related Components

- [ODH Dashboard](./odh-dashboard-component.png) - Web UI for the platform
- [KServe](./kserve-component.png) - Model serving infrastructure
- [Data Science Pipelines](./data-science-pipelines-operator-component.png) - ML workflow orchestration
- [Model Registry](./model-registry-operator-component.png) - Model metadata storage

---

**Generated by**: Architecture diagram generation workflow
**Source**: `architecture/rhoai-2.14/rhods-operator.md`
**Component version**: v1.6.0-826-gf50f02777 (rhoai-2.14 branch)
