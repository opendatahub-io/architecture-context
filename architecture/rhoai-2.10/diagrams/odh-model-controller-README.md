# Architecture Diagrams for ODH Model Controller

Generated from: `architecture/rhoai-2.10/odh-model-controller.md`
Date: 2026-03-15
Component: odh-model-controller

**Note**: Diagram filenames use base component name without version (directory is already versioned).

## Available Diagrams

All Mermaid diagrams are available in both `.mmd` (source) and `.png` (3000px width, high-resolution) formats.

### For Developers
- [Component Structure](./odh-model-controller-component.png) ([mmd](./odh-model-controller-component.mmd)) - Mermaid diagram showing internal components, controllers, sub-reconcilers, watched CRDs, and created resources
- [Data Flows](./odh-model-controller-dataflow.png) ([mmd](./odh-model-controller-dataflow.mmd)) - Sequence diagram of all 5 major flows: InferenceService reconciliation, StorageSecret aggregation, CA cert propagation, monitoring RoleBinding creation, and Knative service validation
- [Dependencies](./odh-model-controller-dependencies.png) ([mmd](./odh-model-controller-dependencies.mmd)) - Component dependency graph showing external dependencies (KServe, Istio, Authorino, etc.), internal ODH dependencies, and integration points

### For Architects
- [C4 Context](./odh-model-controller-c4-context.dsl) - System context in C4 format (Structurizr) showing the controller in the broader OpenShift AI ecosystem
- [Component Overview](./odh-model-controller-component.png) ([mmd](./odh-model-controller-component.mmd)) - High-level component view with controllers, reconcilers, and managed resources

### For Security Teams
- [Security Network Diagram (PNG)](./odh-model-controller-security-network.png) - High-resolution network topology with trust zones, encryption, and authentication
- [Security Network Diagram (Mermaid)](./odh-model-controller-security-network.mmd) - Visual network topology (editable, color-coded trust zones)
- [Security Network Diagram (ASCII)](./odh-model-controller-security-network.txt) - Precise text format for SAR submissions with complete RBAC, secrets, network policies, and service mesh configuration details
- [RBAC Visualization](./odh-model-controller-rbac.png) ([mmd](./odh-model-controller-rbac.mmd)) - RBAC permissions showing ClusterRoles, RoleBindings, and API resource access patterns

## Component Overview

The ODH Model Controller extends KServe and ModelMesh serving controllers with OpenShift-specific capabilities:

- **Purpose**: Provides OpenShift-native extensions for model serving platforms including Routes for external access, Istio service mesh integration, Authorino authentication, and Prometheus monitoring
- **Version**: v1.27.0-rhods-341-gfcca5f2
- **Deployment**: 3 replicas with leader election, high availability
- **Key Features**:
  - Three deployment modes: ModelMesh (multi-model), KServe Serverless (Knative), KServe Raw (direct K8s)
  - OpenShift Route creation for external inference access
  - Service mesh integration (VirtualServices, PeerAuthentications, Telemetries)
  - Authorino AuthConfig creation for endpoint authentication
  - Prometheus ServiceMonitor/PodMonitor creation for metrics
  - Storage secret aggregation for ModelMesh/KServe
  - Custom CA certificate propagation for secure S3 access
  - NetworkPolicy and RBAC management

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
   PUPPETEER_EXECUTABLE_PATH=/usr/bin/google-chrome mmdc -i odh-model-controller-component.mmd -o odh-model-controller-component.png -w 3000
   ```

3. **Alternative formats** (if needed):
   ```bash
   # SVG (vector, scales perfectly)
   PUPPETEER_EXECUTABLE_PATH=/usr/bin/google-chrome mmdc -i odh-model-controller-component.mmd -o odh-model-controller-component.svg

   # PDF
   PUPPETEER_EXECUTABLE_PATH=/usr/bin/google-chrome mmdc -i odh-model-controller-component.mmd -o odh-model-controller-component.pdf
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
  structurizr-cli export -workspace odh-model-controller-c4-context.dsl -format png
  ```

### ASCII Diagrams (.txt files)
- View in any text editor
- Include in documentation as-is
- Perfect for security reviews (precise technical details including RBAC summary, secrets, network policies, service mesh config)

## Diagram Details

### Component Structure Diagram
Shows the internal architecture of the ODH Model Controller:
- **Controllers**: InferenceService, StorageSecret, KServeCustomCACert, Monitoring, ModelRegistry controllers
- **Webhook**: Knative Service validator
- **Sub-Reconcilers**: 10 KServe sub-reconcilers (Route, AuthConfig, NetworkPolicy, PeerAuth, Telemetry, SMMR, ServiceMonitor, PodMonitor, MetricsService, PrometheusRB)
- **ModelMesh Sub-Reconcilers**: Route, ServiceAccount, ClusterRoleBinding reconcilers
- **Watched CRDs**: InferenceService, ServingRuntime, data connection Secrets, trusted CA bundle ConfigMaps, Knative Services
- **Created Resources**: Routes, VirtualServices, AuthConfigs, PeerAuthentications, Telemetries, NetworkPolicies, ServiceMonitors, PodMonitors, SMMR, storage-config Secrets, custom CA ConfigMaps, Prometheus RoleBindings

### Data Flow Diagram
Visualizes 5 major operational flows:

1. **InferenceService Reconciliation** (KServe Serverless Mode):
   - User creates InferenceService → Controller watches → Creates Route, VirtualService, AuthConfig, NetworkPolicy, ServiceMonitor, PodMonitor, PeerAuthentication, Telemetry, SMMR, Prometheus RoleBinding

2. **StorageSecret Reconciliation**:
   - User creates data connection Secret (labeled `opendatahub.io/managed=true`) → Controller aggregates all labeled secrets → Creates/updates storage-config Secret

3. **Custom CA Certificate Propagation**:
   - OpenShift injects cluster CA bundle into odh-trusted-ca-bundle ConfigMap → Controller watches → Copies to inference namespaces → Updates storage-config Secrets

4. **Monitoring RoleBinding Creation**:
   - User creates InferenceService → Controller creates RoleBinding granting prometheus-custom ServiceAccount access → Prometheus can scrape metrics

5. **Knative Service Validation** (Webhook):
   - KServe creates Knative Service → API Server calls validation webhook → Controller validates configuration → Returns admission decision

### Dependencies Diagram
Shows component relationships:
- **Required External**: KServe v0.11.0 (InferenceService CRD)
- **Optional External**: Istio v1.17+, Authorino v0.15.0, OpenShift Service Mesh v2.x, Prometheus Operator v0.64.1, Knative Serving v0.37.1, Model Registry v0.1.1
- **Internal ODH**: KServe Controller, ModelMesh Serving, ODH Dashboard (serving runtime templates), DataScienceCluster (feature flags), DSCInitialization (Authorino/Mesh config)
- **Integration Points**: Kubernetes API Server, Prometheus (metrics scraping), Authorino Service, Istio Control Plane, OpenShift Router

### Security Network Diagram
Comprehensive security view with three formats:

**ASCII Format** (`.txt`) - For Security Architecture Reviews:
- Complete network topology with exact ports, protocols, encryption (TLS 1.2+, mTLS, plaintext)
- Authentication mechanisms (ServiceAccount tokens, User tokens, API Server mTLS)
- Trust boundaries (External → API Server → Controller → User Namespaces → Service Mesh → External Services)
- **RBAC Summary**: Full ClusterRole permissions, Role permissions, RoleBindings
- **Secrets**: Webhook cert (OpenShift Service CA, auto-rotated), storage-config (aggregated S3 credentials), data connection secrets
- **Network Policies**: Ingress restriction to webhook port 9443 from API Server only
- **Service Mesh Configuration**: PeerAuthentication modes, ServiceMeshMember, VirtualServices, Telemetry
- **Authentication & Authorization**: Webhook mTLS, metrics endpoint (no auth), Authorino integration (optional)
- **Deployment Configuration**: Replicas, anti-affinity, resource limits, security context, environment variables

**Mermaid/PNG Format** (`.mmd`/`.png`) - For Visual Presentations:
- Color-coded trust zones (External, API Server, Controller Namespace, User Namespaces, Service Mesh, External Integrations)
- Network flows with encryption and authentication details
- Visual representation of managed resources

### RBAC Visualization Diagram
Detailed RBAC structure:
- **Service Accounts**: odh-model-controller, prometheus-custom
- **ClusterRoles**: odh-model-controller-role (full CRUD on Routes, VirtualServices, AuthConfigs, PeerAuthentications, Telemetries, ServiceMonitors, PodMonitors, NetworkPolicies, ServingRuntimes, etc.), prometheus-ns-access (granted to Prometheus in inference namespaces)
- **Namespaced Roles**: leader-election-role (ConfigMaps, Events, Leases)
- **Bindings**: ClusterRoleBinding (odh-model-controller-rolebinding), leader-election-rolebinding, prometheus-ns-access RoleBindings (created in inference namespaces)
- **API Resources**:
  - KServe: InferenceService (get, list, watch, update), ServingRuntime (full CRUD)
  - Istio: VirtualService, PeerAuthentication, Telemetry (full CRUD), AuthorizationPolicy (read-only)
  - Maistra: ServiceMeshMember, ServiceMeshMemberRoll, ServiceMeshControlPlane
  - OpenShift: Route (full CRUD + custom-host)
  - Networking: NetworkPolicy, Ingress (full CRUD)
  - RBAC: ClusterRoleBinding, RoleBinding (full CRUD)
  - Monitoring: ServiceMonitor, PodMonitor (full CRUD)
  - Core: Service, Secret, ConfigMap, ServiceAccount (full CRUD), Namespace, Pod, Endpoint (get, list, watch, create, update, patch)
  - Authorino: AuthConfig (full CRUD)
  - ODH: DataScienceCluster, DSCInitialization (read-only)

### C4 Context Diagram
Shows the controller in the broader OpenShift AI ecosystem:
- **Users**: Data Scientists, ML Engineers
- **ODH Model Controller**: Central system with containers (InferenceService Controller, StorageSecret Controller, KServeCustomCACert Controller, Monitoring Controller, ModelRegistry Controller, Webhook Server)
- **External Systems**: KServe, ModelMesh, Istio/Service Mesh, Authorino, Prometheus, Knative, Model Registry, OpenShift Router, S3 Storage
- **Internal Systems**: Kubernetes API Server, ODH Dashboard
- **Relationships**: User → Dashboard → API Server → Controller → External Dependencies

## Updating Diagrams

To regenerate after architecture changes:
```bash
# Regenerate all diagrams for odh-model-controller
cd /path/to/repo
python scripts/generate_diagram_pngs.py architecture/rhoai-2.10/diagrams --width=3000
```

## Notes

- **Deployment Modes**: The controller supports three InferenceService deployment modes:
  - **ModelMesh**: Multi-model serving (optimized for many small models)
  - **KServe Serverless**: Knative-based autoscaling (scale-to-zero)
  - **KServe Raw**: Standard Kubernetes deployments (always-on)

- **Optional Features**: Service mesh (Istio), Authorino authentication, and Model Registry integration are optional and controlled by:
  - MESH_DISABLED environment variable (disables service mesh)
  - DSCInitialization CR (configures Authorino)
  - --model-registry-inference-reconcile flag (enables Model Registry sync)
  - --monitoring-namespace flag (enables monitoring RoleBinding creation)

- **Leader Election**: Only one replica actively reconciles resources (HA with 3 replicas)

- **Security**:
  - NetworkPolicy restricts ingress to webhook port 9443 from API Server only
  - Security context: runAsNonRoot=true, allowPrivilegeEscalation=false
  - Webhook TLS certificate auto-rotated by OpenShift Service CA

- **Storage Integration**:
  - Data connection secrets are auto-aggregated from secrets labeled `opendatahub.io/managed=true`
  - Custom CA certificates propagated from cluster-wide trusted CA bundle to inference namespaces
  - Storage-config secrets created in inference namespaces with aggregated S3 credentials

- **Default Serving Runtimes**: Controller deploys templates for:
  - OpenVINO Model Server (ModelMesh and KServe variants)
  - Caikit-TGIS (Text Generation Inference Server with Caikit NLP)
  - TGIS Standalone (Text Generation Inference Server for LLMs)
  - vLLM (High-throughput LLM serving)

## Additional Resources

- **Source Repository**: https://github.com/red-hat-data-services/odh-model-controller
- **Version**: v1.27.0-rhods-341-gfcca5f2
- **Branch**: rhoai-2.10
- **Architecture Documentation**: [../odh-model-controller.md](../odh-model-controller.md)
- **KServe Integration**: https://github.com/kserve/kserve
- **ModelMesh Integration**: https://github.com/kserve/modelmesh-serving
