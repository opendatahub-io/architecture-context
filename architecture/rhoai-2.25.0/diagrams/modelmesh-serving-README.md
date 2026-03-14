# Architecture Diagrams for ModelMesh Serving

Generated from: `architecture/rhoai-2.25.0/modelmesh-serving.md`
Date: 2026-03-14
Component: modelmesh-serving
Version: 1.27.0-rhods-480-ge5d8db5

**Note**: Diagram filenames use base component name without version (directory is already versioned).

## Available Diagrams

All Mermaid diagrams are available in both `.mmd` (source) and `.png` (3000px width, high-resolution) formats.

### For Developers
- [Component Structure](./modelmesh-serving-component.png) ([mmd](./modelmesh-serving-component.mmd)) - Mermaid diagram showing internal components, controllers, runtime architecture, and integrations
- [Data Flows](./modelmesh-serving-dataflow.png) ([mmd](./modelmesh-serving-dataflow.mmd)) - Sequence diagram of request/response flows for REST, gRPC, and model loading
- [Dependencies](./modelmesh-serving-dependencies.png) ([mmd](./modelmesh-serving-dependencies.mmd)) - Component dependency graph showing external and internal dependencies

### For Architects
- [C4 Context](./modelmesh-serving-c4-context.dsl) - System context in C4 format (Structurizr) showing ModelMesh in the broader ecosystem
- [Component Overview](./modelmesh-serving-component.png) ([mmd](./modelmesh-serving-component.mmd)) - High-level component view with runtime pod architecture

### For Security Teams
- [Security Network Diagram (PNG)](./modelmesh-serving-security-network.png) - High-resolution network topology with trust zones
- [Security Network Diagram (Mermaid)](./modelmesh-serving-security-network.mmd) - Visual network topology (editable)
- [Security Network Diagram (ASCII)](./modelmesh-serving-security-network.txt) - Precise text format for SAR submissions with full RBAC, secrets, and network policy details
- [RBAC Visualization](./modelmesh-serving-rbac.png) ([mmd](./modelmesh-serving-rbac.mmd)) - RBAC permissions and bindings for controller and runtime service accounts

## Component Overview

ModelMesh Serving is a Kubernetes controller that orchestrates multi-model serving with intelligent model placement and routing. Key components:

- **modelmesh-controller**: Manages ServingRuntime, Predictor, and InferenceService CRDs
- **ModelMesh Runtime**: Java-based model serving orchestration layer
- **REST Proxy**: Translates KServe V2 REST API to gRPC
- **Runtime Adapters**: Support for Triton, MLServer, OpenVINO, TorchServe
- **Storage Helper**: Downloads model artifacts from S3/PVC
- **ETCD**: Distributed metadata storage for model coordination

## Network Architecture

### External Exposure
- **gRPC**: 8033/TCP (KServe V2 inference protocol)
- **HTTP REST**: 8008/TCP (KServe V2 REST API)
- **Metrics**: 2112/TCP (runtime pods), 8443/TCP HTTPS (controller)

### Internal Services
- **Webhook**: 9443/TCP HTTPS (ValidatingWebhook for CRDs)
- **ModelMesh Internal**: 8080/TCP gRPC (cluster communication)
- **Puller**: 8086/TCP gRPC (model loading coordination)

### Security
- **Encryption**: TLS 1.2+ for controller metrics and webhooks; plaintext for inference endpoints (optional Service Mesh integration)
- **Authentication**: ServiceAccount tokens, optional mTLS for ETCD, AWS Signature V4 for S3
- **RBAC**: ClusterRole with full management of serving.kserve.io resources

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

### 1. Component Structure (`modelmesh-serving-component.mmd/.png`)
Shows the internal architecture of ModelMesh Serving:
- Controller and webhook server
- Runtime pod multi-container architecture (ModelMesh, REST Proxy, Runtime Adapter, Puller)
- CRD relationships (ServingRuntime, InferenceService, Predictor)
- External dependencies (ETCD, S3, PVC)
- Integration with Prometheus for metrics

### 2. Data Flow (`modelmesh-serving-dataflow.mmd/.png`)
Sequence diagrams showing:
- **Flow 1**: REST inference request (HTTP → REST Proxy → ModelMesh → Runtime)
- **Flow 2**: gRPC inference request (direct gRPC → ModelMesh → Runtime)
- **Flow 3**: Model loading from S3/PVC storage via Puller init container
- Ports, protocols, encryption, and authentication at each step

### 3. Security Network Diagram (`modelmesh-serving-security-network.txt/.mmd/.png`)
Detailed network topology with:
- **Trust zones**: External, Service Layer, Control Plane, Data Plane, External Services
- **Exact ports**: 8033/TCP, 8008/TCP, 9443/TCP, 8443/TCP, 2112/TCP, 2379/TCP, 443/TCP
- **Protocols**: HTTP, HTTPS, gRPC
- **Encryption**: TLS 1.2+, optional mTLS, plaintext
- **Authentication**: Bearer tokens, ServiceAccount tokens, AWS Signature V4, K8s API certs
- **RBAC summary**: Full permissions matrix for controller and runtime service accounts
- **Secrets**: storage-config, model-serving-etcd, webhook-server-cert
- **Network Policies**: Ingress/egress rules for controller, webhook, runtimes, and ETCD

### 4. C4 Context Diagram (`modelmesh-serving-c4-context.dsl`)
System context showing:
- Users: Data Scientist, Platform Admin
- ModelMesh Serving containers: Controller, Webhook, ModelMesh, REST Proxy, Runtime Adapter, Puller
- External systems: ETCD, Kubernetes, S3, cert-manager, Prometheus
- Internal RHOAI systems: KServe, OpenShift Service Mesh
- Relationships and communication flows

### 5. Dependencies (`modelmesh-serving-dependencies.mmd/.png`)
Component dependency graph:
- **External (Required)**: ETCD v3.5.9, Kubernetes 1.28+
- **External (Optional)**: cert-manager, Prometheus Operator, OpenShift Service Mesh
- **Internal RHOAI**: KServe (shared CRD schema), Object Storage S3
- **Runtime Dependencies**: Triton, MLServer, OpenVINO, TorchServe
- **Integration Points**: ODH Dashboard, Data Science Pipelines, Jupyter Notebooks

### 6. RBAC Visualization (`modelmesh-serving-rbac.mmd/.png`)
RBAC permissions structure:
- **ServiceAccount**: modelmesh-controller
- **ClusterRole**: modelmesh-controller-role with full CRUD on:
  - serving.kserve.io: InferenceServices, Predictors, ServingRuntimes, ClusterServingRuntimes
  - core: ConfigMaps, Secrets, Services, Namespaces
  - apps: Deployments
  - autoscaling: HorizontalPodAutoscalers
  - monitoring.coreos.com: ServiceMonitors
- **User Roles**: inferenceservice-editor-role (CRUD), inferenceservice-viewer-role (read-only)

## Key Security Considerations

1. **Plaintext Inference**: By default, inference endpoints (8033/TCP gRPC, 8008/TCP HTTP) use plaintext communication. For production, integrate with OpenShift Service Mesh for mTLS.

2. **ETCD Security**: ETCD connection can be secured with TLS and mTLS. Configure via `model-serving-etcd` Secret.

3. **Storage Credentials**: S3 credentials stored in `storage-config` Secret. Use AWS IAM roles (IRSA) for production instead of static credentials.

4. **Webhook TLS**: Webhook server requires TLS certificate. Use cert-manager for automatic rotation or provision manually.

5. **Network Policies**: Default policies allow all ingress to inference endpoints. Restrict based on your security requirements.

6. **Service Mesh**: Optional but recommended for:
   - mTLS between services
   - AuthN/AuthZ policies
   - Traffic management and observability

## Updating Diagrams

To regenerate after architecture changes:

```bash
# Navigate to project root
cd /path/to/kahowell.rhoai-architecture-diagrams

# Regenerate all diagrams for modelmesh-serving
# (Specify the component and output directory will auto-determine)

# Or manually:
cd architecture/rhoai-2.25.0/diagrams
for mmd in modelmesh-serving-*.mmd; do
    PUPPETEER_EXECUTABLE_PATH=/usr/bin/google-chrome mmdc -i "$mmd" -o "${mmd%.mmd}.png" -w 3000
done
```

## Integration with Documentation

### Embed in Markdown (GitHub/GitLab)

Use PNG files for maximum compatibility:

```markdown
## ModelMesh Serving Architecture

![Component Structure](./diagrams/modelmesh-serving-component.png)

For detailed network security architecture, see:
![Security Network](./diagrams/modelmesh-serving-security-network.png)
```

Or use Mermaid source (renders on GitHub/GitLab):

```markdown
## ModelMesh Serving Architecture

```mermaid
graph TB
    [paste content from modelmesh-serving-component.mmd]
```
```

### Use in Presentations

1. Copy PNG files directly to your presentation
2. High resolution (3000px width) ensures quality at any zoom level
3. Transparent backgrounds work well on light or dark slides

### Security Architecture Reviews (SAR)

For SAR submissions, use the ASCII format:

```markdown
## Network Architecture

```
[paste content from modelmesh-serving-security-network.txt]
```
```

This provides precise, unambiguous technical details with full RBAC, secrets, and network policy information.

## References

- **Architecture Source**: [modelmesh-serving.md](../modelmesh-serving.md)
- **Component Repository**: https://github.com/red-hat-data-services/modelmesh-serving.git
- **Version**: 1.27.0-rhods-480-ge5d8db5 (RHOAI 2.25)
- **KServe Documentation**: https://kserve.github.io/website/
- **ModelMesh Documentation**: https://github.com/kserve/modelmesh-serving
