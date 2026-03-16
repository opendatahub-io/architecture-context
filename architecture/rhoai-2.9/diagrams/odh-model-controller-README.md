# Architecture Diagrams for ODH Model Controller

Generated from: `architecture/rhoai-2.9/odh-model-controller.md`
Date: 2026-03-15

**Note**: Diagram filenames use base component name without version (directory is already versioned).

## Available Diagrams

All Mermaid diagrams are available in both `.mmd` (source) and `.png` (3000px width, high-resolution) formats.

### For Developers
- [Component Structure](./odh-model-controller-component.png) ([mmd](./odh-model-controller-component.mmd)) - Mermaid diagram showing internal components, reconcilers, and resource management
- [Data Flows](./odh-model-controller-dataflow.png) ([mmd](./odh-model-controller-dataflow.mmd)) - Sequence diagram of InferenceService creation, inference requests, and monitoring
- [Dependencies](./odh-model-controller-dependencies.png) ([mmd](./odh-model-controller-dependencies.mmd)) - Component dependency graph showing KServe, OpenShift, Istio, Authorino integrations

### For Architects
- [C4 Context](./odh-model-controller-c4-context.dsl) - System context in C4 format (Structurizr) showing ODH Model Controller in the broader ecosystem
- [Component Overview](./odh-model-controller-component.png) ([mmd](./odh-model-controller-component.mmd)) - High-level component view

### For Security Teams
- [Security Network Diagram (PNG)](./odh-model-controller-security-network.png) - High-resolution network topology with trust zones
- [Security Network Diagram (Mermaid)](./odh-model-controller-security-network.mmd) - Visual network topology (editable)
- [Security Network Diagram (ASCII)](./odh-model-controller-security-network.txt) - Precise text format for SAR submissions with detailed RBAC, service mesh config, secrets, and authentication details
- [RBAC Visualization](./odh-model-controller-rbac.png) ([mmd](./odh-model-controller-rbac.mmd)) - RBAC permissions and bindings showing ClusterRoles, ServiceAccounts, and resource access

## Component Overview

**ODH Model Controller** is an OpenShift integration controller that extends KServe with:
- **OpenShift Routes** for external HTTP/HTTPS access to InferenceServices
- **Istio Service Mesh** integration for mTLS, traffic routing, and telemetry
- **Authorino** authentication/authorization for JWT validation
- **Prometheus** monitoring integration via ServiceMonitors and PodMonitors
- **Network Policies** for pod-level isolation
- **Multiple deployment modes**: ModelMesh, KServe Serverless, KServe RawDeployment

The controller watches KServe InferenceService CRs and automatically provisions OpenShift-specific networking, security, and monitoring resources.

## Key Architecture Highlights

### Controllers and Reconcilers
- **OpenshiftInferenceServiceReconciler**: Main controller that delegates to mode-specific sub-reconcilers
- **KServeServerlessReconciler**: Manages Knative-based deployments with Routes, AuthConfigs, NetworkPolicies, mTLS
- **ModelMeshReconciler**: Manages multi-model serving deployments
- **MonitoringReconciler**: Creates RoleBindings for Prometheus access
- **StorageSecretReconciler**: Manages storage credentials for model artifacts

### Security Features
- **mTLS STRICT mode** enforced via PeerAuthentication in service mesh
- **Optional JWT authentication** via Authorino (controlled by annotation)
- **Network Policies** for pod-to-pod isolation
- **Non-root deployment** (UID 65532) with no privilege escalation
- **RBAC scoped** to specific resources and verbs
- **TLS 1.2+ encryption** for all external communications

### Integration Points
- **KServe**: Watches InferenceService and ServingRuntime CRDs
- **OpenShift Router**: Creates Routes for external access
- **Istio**: Creates VirtualServices, PeerAuthentication, Telemetry
- **Authorino**: Creates AuthConfig resources for JWT validation
- **Prometheus**: Creates ServiceMonitor/PodMonitor for metrics
- **Service Mesh**: Updates ServiceMeshMemberRoll to include InferenceService namespaces

### Network Flows
1. **External requests** → OpenShift Router (443/TCP HTTPS) → Istio Gateway → Authorino (optional) → InferenceService Pod (mTLS)
2. **Model loading** → InferenceService Pod → S3/PVC (443/TCP HTTPS or local)
3. **Monitoring** → Prometheus → InferenceService Pods (HTTP/HTTPS via ServiceMonitor)
4. **Control plane** → Controller → Kubernetes API (6443/TCP HTTPS) → Create/manage resources

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
- Perfect for security reviews (precise technical details with RBAC, service mesh config, secrets)

## Updating Diagrams

To regenerate after architecture changes:
```bash
# From repository root
python scripts/generate_diagram_pngs.py architecture/rhoai-2.9/diagrams --width=3000 --force
```

Or regenerate all diagrams from architecture markdown:
```bash
# This would be done via the architecture diagram generation workflow
# (not currently automated - manual generation)
```

## Architecture Details

### Deployment Modes Supported
1. **ModelMesh**: Multi-model serving with shared runtime pools
2. **KServe Serverless**: Knative-based autoscaling with scale-to-zero
3. **KServe RawDeployment**: Direct Kubernetes Deployments without Knative

### Resources Created per InferenceService (Serverless mode)
- OpenShift Route (external HTTPS access)
- NetworkPolicy (pod isolation)
- PeerAuthentication (mTLS STRICT)
- VirtualService (Istio routing)
- Telemetry (observability config)
- ServiceMonitor/PodMonitor (Prometheus scraping)
- AuthConfig (JWT validation - optional)
- ServiceMeshMemberRoll update (namespace enrollment)

### RBAC Permissions
The controller requires broad permissions to manage InferenceService infrastructure:
- **KServe CRDs**: InferenceService, ServingRuntime (get, list, watch, update/create)
- **Networking**: Routes, VirtualServices, NetworkPolicies (CRUD)
- **Security**: PeerAuthentication, AuthConfig (CRUD), AuthorizationPolicy (read-only)
- **Service Mesh**: ServiceMeshMemberRoll, Telemetry (CRUD)
- **Monitoring**: ServiceMonitor, PodMonitor (CRUD)
- **Core**: Secrets, ConfigMaps, ServiceAccounts, Services (CRUD)
- **Platform**: DataScienceCluster, DSCInitialization (read-only)

### High Availability
- **3 replicas** with leader election
- **Pod anti-affinity** for node distribution
- **Health probes**: /healthz (liveness), /readyz (readiness)

### Conditional Features
- **Service Mesh**: Enabled via DataScienceCluster CR or MESH_DISABLED env var
- **Authorization**: Enabled when Authorino CRD is available
- **Monitoring**: Enabled when --monitoring-namespace flag provided
- **Model Registry**: Enabled when --model-registry-inference-reconcile flag set

## References

- Architecture documentation: [odh-model-controller.md](../odh-model-controller.md)
- Repository: https://github.com/red-hat-data-services/odh-model-controller
- Version: v1.27.0-rhods-297-g863a266
- Branch: rhoai-2.9
