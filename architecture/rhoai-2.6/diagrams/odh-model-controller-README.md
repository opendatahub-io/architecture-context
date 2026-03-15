# Architecture Diagrams for odh-model-controller

Generated from: `architecture/rhoai-2.6/odh-model-controller.md`
Date: 2026-03-15

**Note**: Diagram filenames use base component name without version (directory is already versioned).

## Available Diagrams

All Mermaid diagrams are available in both `.mmd` (source) and `.png` (3000px width, high-resolution) formats.

### For Developers
- [Component Structure](./odh-model-controller-component.png) ([mmd](./odh-model-controller-component.mmd)) - Mermaid diagram showing internal components and reconcilers
- [Data Flows](./odh-model-controller-dataflow.png) ([mmd](./odh-model-controller-dataflow.mmd)) - Sequence diagram of request/response flows
- [Dependencies](./odh-model-controller-dependencies.png) ([mmd](./odh-model-controller-dependencies.mmd)) - Component dependency graph

### For Architects
- [C4 Context](./odh-model-controller-c4-context.dsl) - System context in C4 format (Structurizr)
- [Component Overview](./odh-model-controller-component.png) ([mmd](./odh-model-controller-component.mmd)) - High-level component view

### For Security Teams
- [Security Network Diagram (PNG)](./odh-model-controller-security-network.png) - High-resolution network topology
- [Security Network Diagram (Mermaid)](./odh-model-controller-security-network.mmd) - Visual network topology (editable)
- [Security Network Diagram (ASCII)](./odh-model-controller-security-network.txt) - Precise text format for SAR submissions
- [RBAC Visualization](./odh-model-controller-rbac.png) ([mmd](./odh-model-controller-rbac.mmd)) - RBAC permissions and bindings

## Component Overview

The **odh-model-controller** is a Kubernetes operator that extends KServe InferenceService with OpenShift-specific capabilities:

- **External Access**: Creates OpenShift Routes for HTTPS ingress
- **Service Mesh Integration**: Configures Istio VirtualServices, PeerAuthentications, and Telemetry
- **Monitoring**: Provisions ServiceMonitors, PodMonitors, and RoleBindings for Prometheus
- **Network Security**: Establishes NetworkPolicies for controlled traffic flow
- **Storage Configuration**: Aggregates data connection secrets into unified storage-config
- **Dual Mode Support**: Handles both KServe Serverless (Knative) and ModelMesh deployments

### Key Features

1. **Mode Detection**: Automatically detects InferenceService deployment mode and applies appropriate reconciliation logic
2. **OpenShift Integration**: Bridges KServe with OpenShift Routes, Service Mesh (Maistra), and monitoring stack
3. **Storage Secret Aggregation**: Consolidates ODH Dashboard data connections into KServe-compatible storage-config
4. **Network Isolation**: Creates NetworkPolicies allowing traffic from monitoring, ingress, and labeled namespaces

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

### Component Structure Diagram
Shows the internal architecture of odh-model-controller:
- **Manager Pod**: 3 replicas with leader election
- **Reconcilers**: OpenshiftInferenceService, KserveInferenceService, ModelMeshInferenceService, StorageSecret, Monitoring
- **Watched CRDs**: InferenceService, ServingRuntime
- **Created Resources**: Routes, VirtualServices, PeerAuthentications, Telemetry, ServiceMonitors, NetworkPolicies, etc.

### Data Flow Diagram
Three key flows:
1. **External Client Request (KServe Mode)**: Client → OpenShift Router → Istio Gateway → InferenceService Pod → S3
2. **Prometheus Metrics Scraping**: Prometheus → InferenceService Pods and Envoy sidecars
3. **Storage Secret Aggregation**: ODH Dashboard → Kubernetes API → odh-model-controller → storage-config Secret

### Security Network Diagram
Detailed network topology with:
- **Trust Zones**: External, Ingress (DMZ), Service Mesh, Application Layer, External Services
- **Precise Details**: Exact ports (443/TCP, 8080/TCP, 15020/TCP), protocols (HTTPS, HTTP), encryption (TLS 1.2+, mTLS), authentication (Bearer Token, AWS Signature v4)
- **RBAC Summary**: ClusterRole permissions for InferenceServices, Istio resources, Routes, NetworkPolicies
- **Service Mesh Config**: PeerAuthentication modes, Telemetry, ServiceMeshMemberRoll
- **Network Policies**: allow-from-openshift-monitoring-ns, allow-from-openshift-ingress, allow-from-application-namespaces
- **Secrets**: storage-config (aggregated S3 credentials), data connection secrets

### Dependencies Diagram
Shows relationships with:
- **External Dependencies (Required)**: KServe v0.11.0, OpenShift Routes API v3.9.0+
- **External Dependencies (Optional)**: Istio v1.17.4, Knative Serving v0.39.3, OpenShift Service Mesh (Maistra v1+), Prometheus Operator v0.64.1
- **Internal ODH Dependencies**: KServe Controller, ODH Dashboard, OpenShift Monitoring Stack
- **Integration Points**: Kubernetes API Server (6443/TCP HTTPS TLS 1.3)

### RBAC Diagram
Visualizes RBAC structure:
- **Service Accounts**: odh-model-controller, prometheus-custom, {namespace}-sa
- **ClusterRoles**: odh-model-controller-role (broad permissions), odh-model-controller-leader-election-role, prometheus-ns-access
- **Permissions**: InferenceServices, ServingRuntimes, VirtualServices, PeerAuthentications, Telemetries, Routes, NetworkPolicies, ServiceMonitors, PodMonitors, and more
- **Bindings**: ClusterRoleBinding (cluster-scoped), RoleBindings (per namespace for Prometheus access)

### C4 Context Diagram
System context showing:
- **Users**: Data Scientist, External Client
- **Core System**: odh-model-controller with Manager Pod containing 5 reconcilers
- **External Systems**: KServe, Istio, Knative, OpenShift Router, OpenShift Service Mesh, Prometheus, S3 Storage, Kubernetes API
- **Internal ODH Systems**: ODH Dashboard, KServe Controller, OpenShift Monitoring Stack
- **Relationships**: Watch/create resources, traffic routing, metrics scraping, storage configuration

## Architecture Highlights

### Deployment Modes

The controller supports two InferenceService deployment modes:

1. **KServe Serverless (Knative)**:
   - Requires Istio for networking and Knative Serving for autoscaling
   - Creates: VirtualServices, PeerAuthentications, Telemetry, ServiceMonitors, PodMonitors
   - Supports mTLS (PERMISSIVE or STRICT mode)

2. **ModelMesh**:
   - Simpler resource model, no Istio integration
   - Creates: ServiceAccounts, ClusterRoleBindings
   - Direct HTTP routing via OpenShift Routes

### Storage Secret Aggregation

The controller watches for secrets labeled:
- `opendatahub.io/managed: "true"`
- `opendatahub.io/dashboard: "true"`

It aggregates these into a single `storage-config` secret in each InferenceService namespace, supporting:
- AWS S3 (access key, secret key, endpoint, bucket, region)
- Custom CA bundles for TLS verification
- Dual key format (both KServe and ModelMesh compatible)

### Service Mesh Integration (Optional)

When service mesh is enabled (`MESH_DISABLED=false`):
- Adds InferenceService namespaces to ServiceMeshMemberRoll
- Creates PeerAuthentication resources for mTLS enforcement
- Creates Telemetry resources for Prometheus metrics from Envoy sidecars
- Creates NetworkPolicies compatible with mesh security policies

### Monitoring Integration

The controller requires `--monitoring-namespace` flag for monitoring features:
- Creates RoleBindings granting prometheus-custom SA access to InferenceService namespaces
- Creates ServiceMonitors for InferenceService metrics (8080/TCP)
- Creates PodMonitors for Istio Envoy sidecar metrics (15020/TCP)

### Network Security

NetworkPolicies created per namespace:
- **allow-from-openshift-monitoring-ns**: Prometheus scraping (8080/TCP, 15020/TCP)
- **allow-from-openshift-ingress**: OpenShift Router traffic (8080/TCP, 8443/TCP)
- **allow-from-application-namespaces**: Traffic from namespaces labeled `modelmesh-enabled=true` or `opendatahub.io/dashboard=true`

### Recent Security Fixes

- **CVE-2022-21698 and CVE-2023-45142**: otelhttp dependency vulnerabilities
- **CVE-2023-48795**: golang.org/x/crypto authentication bypass (Terrapin attack)
- **Stack-based buffer overflow**: protobuf dependency

## Updating Diagrams

To regenerate after architecture changes:
```bash
# From repository root
python scripts/generate_diagram_pngs.py architecture/rhoai-2.6/diagrams --width=3000
```

## Related Documentation

- Architecture File: [../odh-model-controller.md](../odh-model-controller.md)
- Repository: https://github.com/red-hat-data-services/odh-model-controller
- Version: v1.27.0-rhods-153-ga294986
- Branch: rhoai-2.6
