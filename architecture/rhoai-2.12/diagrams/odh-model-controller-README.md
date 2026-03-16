# Architecture Diagrams for ODH Model Controller

Generated from: `architecture/rhoai-2.12/odh-model-controller.md`
Date: 2026-03-15
Component Version: v1.27.0-rhods-453-g5a5992d

**Note**: Diagram filenames use base component name without version (directory is already versioned).

## Available Diagrams

All Mermaid diagrams are available in both `.mmd` (source) and `.png` (3000px width, high-resolution) formats.

### For Developers
- [Component Structure](./odh-model-controller-component.png) ([mmd](./odh-model-controller-component.mmd)) - Mermaid diagram showing internal components and reconcilers
- [Data Flows](./odh-model-controller-dataflow.png) ([mmd](./odh-model-controller-dataflow.mmd)) - Sequence diagram of InferenceService creation and validation flows
- [Dependencies](./odh-model-controller-dependencies.png) ([mmd](./odh-model-controller-dependencies.mmd)) - Component dependency graph showing external and internal dependencies

### For Architects
- [C4 Context](./odh-model-controller-c4-context.dsl) - System context in C4 format (Structurizr)
- [Component Overview](./odh-model-controller-component.png) ([mmd](./odh-model-controller-component.mmd)) - High-level component view with reconciler architecture

### For Security Teams
- [Security Network Diagram (PNG)](./odh-model-controller-security-network.png) - High-resolution network topology
- [Security Network Diagram (Mermaid)](./odh-model-controller-security-network.mmd) - Visual network topology (editable)
- [Security Network Diagram (ASCII)](./odh-model-controller-security-network.txt) - Precise text format for SAR submissions
- [RBAC Visualization](./odh-model-controller-rbac.png) ([mmd](./odh-model-controller-rbac.mmd)) - RBAC permissions and bindings

## Component Overview

The ODH Model Controller extends KServe InferenceService functionality with OpenShift and service mesh integration capabilities. It operates in three deployment modes:

1. **ModelMesh Mode**: Multi-model serving with shared model servers
2. **Serverless Mode**: Knative-based auto-scaling inference services with service mesh
3. **RawDeployment Mode**: Direct Kubernetes deployments without Knative

### Key Features

- **OpenShift Integration**: Creates Routes for external access to inference endpoints
- **Service Mesh Integration**: Manages Istio VirtualServices, Gateways, PeerAuthentication, and Telemetry
- **Authentication**: Configures Authorino AuthConfigs for inference service authentication
- **Monitoring**: Creates ServiceMonitors and PodMonitors for Prometheus integration
- **Storage Management**: Handles storage secrets and custom CA certificates
- **Validation**: Webhook for Knative Service validation when service mesh is enabled

### Deployment Details

- **Replicas**: 3 (with leader election, 1 active controller)
- **Pod Anti-Affinity**: Preferred scheduling on different nodes for HA
- **Resource Limits**: CPU 10m-500m, Memory 64Mi-2Gi
- **Security**: Non-root user (65532), no privilege escalation, restricted pod security

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

## Architecture Highlights

### Multi-Mode Reconciliation
The controller implements a strategy pattern with three reconciliation modes, delegating to mode-specific reconcilers based on InferenceService configuration.

### Service Mesh Integration
When service mesh is enabled, the controller:
- Creates VirtualServices for routing rules
- Configures Gateways for ingress
- Establishes PeerAuthentication policies for mTLS
- Sets up Telemetry collection
- Manages ServiceMeshMember resources
- Creates AuthConfigs for authentication

### Resource Ownership
Uses Kubernetes owner references for automatic garbage collection when InferenceServices are deleted.

### Conditional Feature Activation
Features are conditionally enabled based on:
- Service mesh detection (DataScienceCluster/DSCInitialization)
- AuthConfig CRD availability
- Command-line flags (`--monitoring-namespace`, `--model-registry-inference-reconcile`)
- Environment variables (`MESH_DISABLED`)

## Key Integration Points

| Component | Interaction | Purpose |
|-----------|-------------|---------|
| **KServe Controller** | CRD Watch | Works alongside KServe, watches same InferenceService resources |
| **Istio/Maistra** | CRD Management | Creates VirtualServices, Gateways, PeerAuthentication, Telemetry |
| **OpenShift Router** | Route CRD | Creates Routes for external access |
| **Authorino** | CRD Management | Creates AuthConfigs for authentication |
| **Prometheus** | Metrics & ServiceMonitors | Exposes metrics and creates monitoring resources |
| **Knative Serving** | Webhook Validation | Validates Knative Services for mesh compatibility |

## Serving Runtime Templates

The controller deploys the following serving runtime templates:

- **OpenVINO Model Server** (KServe and ModelMesh modes)
- **Caikit-TGIS**: Caikit NLP with Text Generation Inference Server
- **Caikit Standalone**: Standalone Caikit runtime
- **TGIS**: Text Generation Inference Server
- **vLLM**: Very Large Language Model inference

## Security Features

### RBAC
- **ClusterRole**: `odh-model-controller-role` with permissions for InferenceServices, ServingRuntimes, Istio resources, Routes, NetworkPolicies, Monitoring resources, and more
- **Auth Proxy Role**: Enables token and subject access reviews
- **Leader Election Role**: Manages leader election ConfigMaps/Leases

### Network Security
- **NetworkPolicies**: Created for inference services to control ingress traffic
- **mTLS**: PeerAuthentication policies enforce mutual TLS in service mesh
- **Authentication**: AuthConfig resources for inference endpoint authentication

### Pod Security
- Runs as non-root user (65532)
- No privilege escalation allowed
- Restricted pod security context
- TLS for all webhook communication

## Troubleshooting

### Health Probes
- **Liveness**: `http://localhost:8081/healthz`
- **Readiness**: `http://localhost:8081/readyz`

### Metrics
- **Controller Metrics**: `http://localhost:8080/metrics`
- **ServiceMonitor**: Automatically created if `--monitoring-namespace` is set

### Logs
The controller uses structured logging with contextual information. Check pod logs:
```bash
oc logs -n opendatahub deployment/odh-model-controller -f
```

### Common Issues

1. **Service Mesh Not Working**:
   - Check `MESH_DISABLED` environment variable
   - Verify `DataScienceCluster` and `DSCInitialization` configuration
   - Check `service-mesh-refs` ConfigMap

2. **AuthConfig Not Created**:
   - Verify Authorino is installed
   - Check `auth-refs` ConfigMap
   - Ensure AuthConfig CRD is available

3. **Routes Not Created**:
   - Verify OpenShift Route API is available
   - Check ClusterRole permissions for `route.openshift.io`

4. **Monitoring Not Working**:
   - Ensure `--monitoring-namespace` flag is set
   - Verify Prometheus Operator is installed
   - Check ServiceMonitor creation permissions

## Updating Diagrams

To regenerate after architecture changes:
```bash
# From repository root
python scripts/generate_diagram_pngs.py architecture/rhoai-2.12/diagrams --width=3000
```

Or update the architecture file and re-run the full diagram generation workflow.

## Additional Resources

- **Architecture Documentation**: [../odh-model-controller.md](../odh-model-controller.md)
- **Repository**: https://github.com/red-hat-data-services/odh-model-controller
- **KServe Documentation**: https://kserve.github.io/website/
- **Istio/Maistra Documentation**: https://docs.openshift.com/container-platform/latest/service_mesh/
