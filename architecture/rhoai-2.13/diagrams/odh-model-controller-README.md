# Architecture Diagrams for ODH Model Controller

Generated from: `architecture/rhoai-2.13/odh-model-controller.md`
Date: 2026-03-15
Component Version: v1.27.0-rhods-527-g5597309
Distribution: RHOAI 2.13

**Note**: Diagram filenames use base component name without version (directory is already versioned).

## Available Diagrams

All Mermaid diagrams are available in both `.mmd` (source) and `.png` (3000px width, high-resolution) formats.

### For Developers
- [Component Structure](./odh-model-controller-component.png) ([mmd](./odh-model-controller-component.mmd)) - Mermaid diagram showing internal controllers and reconcilers
- [Data Flows](./odh-model-controller-dataflow.png) ([mmd](./odh-model-controller-dataflow.mmd)) - Sequence diagrams of InferenceService creation, storage config, and monitoring flows
- [Dependencies](./odh-model-controller-dependencies.png) ([mmd](./odh-model-controller-dependencies.mmd)) - Component dependency graph showing required, conditional, and optional dependencies

### For Architects
- [C4 Context](./odh-model-controller-c4-context.dsl) - System context in C4 format (Structurizr)
- [Component Overview](./odh-model-controller-component.png) ([mmd](./odh-model-controller-component.mmd)) - High-level component view with reconcilers

### For Security Teams
- [Security Network Diagram (PNG)](./odh-model-controller-security-network.png) - High-resolution network topology with trust zones
- [Security Network Diagram (Mermaid)](./odh-model-controller-security-network.mmd) - Visual network topology (editable)
- [Security Network Diagram (ASCII)](./odh-model-controller-security-network.txt) - Precise text format for SAR submissions
- [RBAC Visualization](./odh-model-controller-rbac.png) ([mmd](./odh-model-controller-rbac.mmd)) - RBAC permissions and bindings

## Component Overview

The ODH Model Controller extends KServe functionality with OpenShift-specific integrations:

- **Deployment Modes**: Supports ModelMesh, KServe Serverless (Knative), and KServe Raw
- **Networking**: Creates OpenShift Routes, Istio VirtualServices, Gateways
- **Security**: Manages PeerAuthentication (mTLS STRICT), AuthConfigs, NetworkPolicies
- **Storage**: Aggregates data connection secrets into unified storage-config
- **Monitoring**: Creates ServiceMonitors, PodMonitors, Grafana dashboards
- **High Availability**: 3 replicas with leader election

## Key Integrations

- **KServe**: Watches InferenceService CRs, coordinates with KServe controller
- **Istio/Maistra**: Service mesh integration for mTLS and traffic management
- **Knative Serving**: Serverless autoscaling for KServe Serverless mode
- **Authorino**: Optional API authentication and authorization
- **Prometheus**: Metrics collection and monitoring
- **Model Registry**: Optional model versioning and metadata tracking
- **ODH Dashboard**: Consumes data connection secrets

## Deployment Modes Explained

### 1. ModelMesh Mode
- Multi-model serving for high-density workloads
- OpenShift Route → Service → ModelMesh Pods
- No service mesh integration
- Minimal networking resources

### 2. KServe Serverless Mode (Knative)
- Autoscaling to zero with Knative Serving
- Full Istio service mesh integration
- Flow: Route → Istio Gateway → VirtualService → Knative Service → Predictor Pod
- STRICT mTLS enforced
- Optional Authorino authentication
- Comprehensive monitoring

### 3. KServe Raw Mode
- Standard Kubernetes deployments
- OpenShift Route → Service → Deployment → Predictor Pod
- No service mesh, no autoscaling
- Simpler setup for basic use cases

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
   PUPPETEER_EXECUTABLE_PATH=/usr/bin/google-chrome mmdc -i diagram.mmd -o diagram.svg

   # PDF
   PUPPETEER_EXECUTABLE_PATH=/usr/bin/google-chrome mmdc -i diagram.mmd -o diagram.pdf
   ```

**Note**: If `google-chrome` is not found, try `chromium` or `which google-chrome` to locate it

### C4 Diagrams (.dsl files)
- **Structurizr Lite**: `docker run -p 8080:8080 -v .:/usr/local/structurizr structurizr/lite`
- **CLI export**: `structurizr-cli export -workspace odh-model-controller-c4-context.dsl -format png`

### ASCII Diagrams (.txt files)
- View in any text editor
- Include in documentation as-is
- Perfect for security reviews (precise technical details)

## Updating Diagrams

To regenerate after architecture changes:
```bash
cd architecture/rhoai-2.13
# Regenerate from updated architecture file
python ../../scripts/generate_architecture_diagrams.py --architecture=odh-model-controller.md
```

## Security Highlights

### Network Security
- **External → DMZ**: TLS 1.2+ edge termination at OpenShift Router
- **DMZ → Service Mesh**: mTLS STRICT between Router and Istio Gateway
- **Service Mesh Internal**: mTLS STRICT enforced by PeerAuthentication
- **Service Mesh → External (S3)**: TLS 1.2+ with AWS IAM credentials

### Authentication & Authorization
- **Webhook**: K8s API Server mTLS (client cert)
- **Controller**: ServiceAccount JWT tokens
- **Metrics**: Bearer token authentication
- **InferenceService** (optional): Authorino JWT validation + mTLS

### RBAC
- **Cluster-wide permissions**: InferenceServices, Routes, Istio resources, monitoring
- **Leader election**: Namespace-scoped ConfigMaps and Leases
- **Monitoring access**: Per-namespace RoleBindings for Prometheus

### Secrets Management
- **Webhook cert**: Auto-rotated every 30 days (service-ca-operator)
- **Storage credentials**: Aggregated from data connections (manual rotation)
- **Custom CAs**: Cluster admin provisioned for self-signed endpoints

## Troubleshooting

### Common Issues

1. **InferenceService not accessible externally**
   - Check Route creation: `oc get route -n <namespace>`
   - Verify Istio VirtualService: `oc get virtualservice -n <namespace>`
   - Check PeerAuthentication doesn't block traffic

2. **Storage access failures**
   - Verify storage-config secret exists: `oc get secret storage-config -n <namespace>`
   - Check data connection secrets have correct labels
   - Validate custom CA bundle if using self-signed S3

3. **Monitoring not working**
   - Check ServiceMonitor created: `oc get servicemonitor -n <namespace>`
   - Verify prometheus-ns-access RoleBinding: `oc get rolebinding prometheus-ns-access -n <namespace>`
   - Check Prometheus ServiceAccount has access

4. **Service mesh integration issues**
   - Verify ServiceMeshMember created: `oc get servicemeshmember -n <namespace>`
   - Check namespace is part of ServiceMeshMemberRoll
   - Validate control plane is healthy

## Related Documentation

- [KServe Documentation](https://kserve.github.io/website/)
- [OpenShift Service Mesh (Maistra)](https://docs.openshift.com/container-platform/latest/service_mesh/v2x/ossm-about.html)
- [Knative Serving](https://knative.dev/docs/serving/)
- [Authorino](https://docs.kuadrant.io/authorino/)
- [ODH/RHOAI Documentation](https://access.redhat.com/documentation/en-us/red_hat_openshift_ai/)

## Architecture Details

For complete architecture details including:
- API specifications
- Reconciliation logic
- Environment variables
- Serving runtime templates
- Known limitations

See the source architecture file: [odh-model-controller.md](../odh-model-controller.md)
