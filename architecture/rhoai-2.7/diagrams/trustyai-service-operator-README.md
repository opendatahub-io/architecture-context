# Architecture Diagrams for TrustyAI Service Operator

Generated from: `architecture/rhoai-2.7/trustyai-service-operator.md`
Date: 2026-03-15

**Note**: Diagram filenames use base component name without version (directory is already versioned).

## Available Diagrams

All Mermaid diagrams are available in both `.mmd` (source) and `.png` (3000px width, high-resolution) formats.

### For Developers
- [Component Structure](./trustyai-service-operator-component.png) ([mmd](./trustyai-service-operator-component.mmd)) - Mermaid diagram showing internal components
- [Data Flows](./trustyai-service-operator-dataflow.png) ([mmd](./trustyai-service-operator-dataflow.mmd)) - Sequence diagram of request/response flows
- [Dependencies](./trustyai-service-operator-dependencies.png) ([mmd](./trustyai-service-operator-dependencies.mmd)) - Component dependency graph

### For Architects
- [C4 Context](./trustyai-service-operator-c4-context.dsl) - System context in C4 format (Structurizr)
- [Component Overview](./trustyai-service-operator-component.png) ([mmd](./trustyai-service-operator-component.mmd)) - High-level component view

### For Security Teams
- [Security Network Diagram (PNG)](./trustyai-service-operator-security-network.png) - High-resolution network topology
- [Security Network Diagram (Mermaid)](./trustyai-service-operator-security-network.mmd) - Visual network topology (editable)
- [Security Network Diagram (ASCII)](./trustyai-service-operator-security-network.txt) - Precise text format for SAR submissions
- [RBAC Visualization](./trustyai-service-operator-rbac.png) ([mmd](./trustyai-service-operator-rbac.mmd)) - RBAC permissions and bindings

## Component Overview

**TrustyAI Service Operator** manages the deployment and lifecycle of TrustyAI explainability services for AI/ML model monitoring and fairness metrics. Key features:

- **Kubernetes Operator**: Reconciles TrustyAIService custom resources
- **KServe Integration**: Automatically configures inference logging for ModelMesh and KServe deployments
- **OAuth Authentication**: Secures services with OpenShift OAuth proxy
- **Prometheus Integration**: Exposes fairness metrics (SPD, DIR) for monitoring
- **Storage Management**: Manages PVCs for inference data persistence

## Key Architecture Highlights

### Components
- **Operator Controller Manager**: Go-based operator managing TrustyAI service lifecycle
- **TrustyAI Service**: Quarkus-based service providing explainability and fairness metrics
- **OAuth Proxy**: Sidecar providing OpenShift OAuth authentication
- **PVC Storage**: Persistent storage for inference payloads and metrics

### Network Architecture
- **External Access**: HTTPS/443 via OpenShift Route with TLS passthrough
- **OAuth Flow**: OpenShift OAuth + SubjectAccessReview for authentication/authorization
- **Internal Communication**: HTTP/8080 for service-to-service (KServe → TrustyAI)
- **Metrics Collection**: HTTP/80 for Prometheus scraping

### Security
- **TLS Encryption**: TLS 1.2+ for external access (Route and OAuth proxy)
- **Authentication**: OpenShift OAuth with SubjectAccessReview checks
- **Authorization**: Users must have 'get pods' permission in TrustyAI namespace
- **RBAC**: Comprehensive cluster roles for operator and proxy service accounts

### Integration Points
- **KServe**: Patches InferenceService logger spec to send payloads to TrustyAI
- **ModelMesh**: Injects `MM_PAYLOAD_PROCESSORS` environment variable
- **Prometheus**: ServiceMonitor-based metrics collection
- **OpenShift**: Routes, OAuth, and service-ca for TLS certificates

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

## Updating Diagrams

To regenerate after architecture changes:
```bash
cd architecture/rhoai-2.7
# Regenerate diagrams from updated architecture file
<regenerate with your preferred method>
```

## Data Flows

### 1. TrustyAI Service Deployment
User creates TrustyAIService CR → Operator watches event → Operator creates PVC, Deployment, Service, Route → TrustyAI service starts with OAuth proxy

### 2. KServe Inference Logging
Operator patches InferenceService logger → KServe sends payloads to TrustyAI → TrustyAI stores data in PVC → Metrics calculated and exposed

### 3. External User Access
User → OpenShift Route (HTTPS/443) → OAuth Proxy (HTTPS/443) → OpenShift OAuth validation → SubjectAccessReview check → TrustyAI Service (HTTP/8080)

### 4. Prometheus Metrics Collection
Prometheus scrapes TrustyAI service via ServiceMonitor → GET /q/metrics (HTTP/80) → Fairness metrics collected (trustyai_spd, trustyai_dir)

## Security Considerations

- **OAuth Authentication**: All external access requires OpenShift OAuth authentication
- **SubjectAccessReview**: Users must have 'get pods' permission in TrustyAI namespace
- **TLS Encryption**: TLS 1.2+ for Route and OAuth proxy service
- **Service-CA Certificates**: Auto-rotated TLS certificates for OAuth proxy
- **Internal Communication**: HTTP (plaintext) for cluster-internal service-to-service communication
- **RBAC**: Least-privilege roles for operator and proxy service accounts

## Dependencies

### External
- Kubernetes v1.19+
- OpenShift v4.6+ (optional, for Route and OAuth features)
- Prometheus Operator v0.64.1
- KServe v0.11.0 (optional, for InferenceService integration)

### Internal RHOAI
- KServe (InferenceService CRD watching and patching)
- ModelMesh (payload processor injection)
- Prometheus (metrics collection)

## Custom Resource Definition

```yaml
apiVersion: trustyai.opendatahub.io/v1alpha1
kind: TrustyAIService
metadata:
  name: trustyai-service-example
  namespace: trustyai-demo
spec:
  storage:
    format: "PVC"
    folder: "/inputs"
    size: "1Gi"
  data:
    filename: "data.csv"
    format: "CSV"
  metrics:
    schedule: "5s"
    batchSize: 5000
  replicas: 1
```

## Metrics Exposed

- `trustyai_spd` - Statistical Parity Difference fairness metric
- `trustyai_dir` - Disparate Impact Ratio fairness metric
- `trustyai_*` - Additional TrustyAI-specific metrics

Scrape interval: 4 seconds (configurable via ServiceMonitor)

## Known Limitations

1. **Platform Dependency**: OAuth and Route features require OpenShift; not available on vanilla Kubernetes
2. **Storage Requirement**: PVC must be created and bound before deployment becomes ready
3. **Namespace Scope**: Automatically patches InferenceServices in the same namespace only
4. **ModelMesh Label**: ModelMesh deployments must have label `modelmesh-service=modelmesh-serving`
5. **Authentication Scope**: Skip-auth-regex only applies to `/apis/v1beta1/healthz`; all other endpoints require OAuth

## References

- Repository: https://github.com/red-hat-data-services/trustyai-service-operator
- Version: eb7d626 (rhoai-2.7 branch)
- Distribution: Red Hat OpenShift AI (RHOAI) 2.7
