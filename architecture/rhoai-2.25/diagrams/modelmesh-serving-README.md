# Architecture Diagrams for ModelMesh Serving

Generated from: `architecture/rhoai-2.25/modelmesh-serving.md`
Date: 2026-03-15
Component: modelmesh-serving
Version: 1.27.0-rhods-480-ge5d8db5

**Note**: Diagram filenames use base component name without version (directory is already versioned).

## Available Diagrams

All Mermaid diagrams are available in both `.mmd` (source) and `.png` (3000px width, high-resolution) formats.

### For Developers
- [Component Structure](./modelmesh-serving-component.png) ([mmd](./modelmesh-serving-component.mmd)) - Mermaid diagram showing internal components, runtime pod architecture, and CRD relationships
- [Data Flows](./modelmesh-serving-dataflow.png) ([mmd](./modelmesh-serving-dataflow.mmd)) - Sequence diagram of inference requests (gRPC/REST), model loading, and metrics collection
- [Dependencies](./modelmesh-serving-dependencies.png) ([mmd](./modelmesh-serving-dependencies.mmd)) - Component dependency graph showing ETCD, runtimes, and integrations

### For Architects
- [C4 Context](./modelmesh-serving-c4-context.dsl) - System context in C4 format (Structurizr) showing ModelMesh in the RHOAI ecosystem
- [Component Overview](./modelmesh-serving-component.png) ([mmd](./modelmesh-serving-component.mmd)) - High-level component view of controller and multi-container runtime pods

### For Security Teams
- [Security Network Diagram (PNG)](./modelmesh-serving-security-network.png) - High-resolution network topology with trust boundaries
- [Security Network Diagram (Mermaid)](./modelmesh-serving-security-network.mmd) - Visual network topology (editable)
- [Security Network Diagram (ASCII)](./modelmesh-serving-security-network.txt) - Precise text format for SAR submissions with RBAC, Network Policies, and Secrets
- [RBAC Visualization](./modelmesh-serving-rbac.png) ([mmd](./modelmesh-serving-rbac.mmd)) - RBAC permissions and bindings for modelmesh-controller

## Architecture Overview

ModelMesh Serving is a Kubernetes controller that orchestrates multi-model serving infrastructure using the ModelMesh runtime. Key architectural characteristics:

- **Hub-and-spoke architecture**: Controller manages multiple runtime pods across namespaces
- **Multi-container pods**: Each runtime pod contains ModelMesh, REST Proxy, Runtime Adapter, Model Runtime, and Storage Puller
- **Distributed coordination**: ETCD cluster provides model metadata storage and cluster state
- **Pluggable runtimes**: Supports Triton, MLServer, OpenVINO, and TorchServe via adapter pattern
- **Dual protocols**: gRPC (8033/TCP) and REST (8008/TCP) inference endpoints
- **High availability**: Supports multi-replica deployments with leader election and pod anti-affinity

## Key Security Features

- **RBAC**: ClusterRole with full lifecycle management for InferenceService, ServingRuntime, and Predictor CRDs
- **Webhook validation**: ValidatingWebhook for ServingRuntime and ClusterServingRuntime resources (9443/TCP HTTPS)
- **Metrics security**: kube-rbac-proxy protects controller metrics endpoint (8443/TCP HTTPS, Bearer Token)
- **Optional mTLS**: ETCD supports optional TLS/mTLS, Service Mesh can add mTLS for pod-to-pod communication
- **Secrets management**: Storage credentials (S3), ETCD connection config, webhook TLS certificates
- **Network policies**: Ingress rules for controller (8443/TCP), webhook (9443/TCP), runtimes (8033/8008/2112/TCP)

## Network Architecture

```
External Client
    ↓ 8033/TCP (gRPC) or 8008/TCP (HTTP)
modelmesh-serving Service (ClusterIP)
    ↓
Runtime Pod:
  - REST Proxy (8008/TCP) → ModelMesh (8033/TCP)
  - ModelMesh (8033/TCP external, 8080/TCP internal, 2112/TCP metrics)
    → Runtime Adapter → Model Runtime (8001/TCP gRPC or UDS)
  - Storage Puller (8086/TCP) ← S3 (443/TCP HTTPS) / PVC
    ↓ 2379/TCP (HTTP/gRPC, optional TLS)
ETCD Cluster
```

## Data Flow Patterns

1. **gRPC Inference**: Client → Service:8033 → ModelMesh → Runtime:8001 → Response
2. **REST Inference**: Client → Service:8008 → REST Proxy → ModelMesh:8033 → Runtime:8001 → Response
3. **InferenceService Creation**: User → K8s API:6443 → Webhook:9443 → Controller → Deployment/Service
4. **Model Loading**: Puller → storage-config Secret → S3:443 → Shared Volume → Runtime
5. **Metrics Collection**: Prometheus → Controller:8443 (HTTPS) + Runtime:2112 (HTTP)

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
   PUPPETEER_EXECUTABLE_PATH=/usr/bin/google-chrome mmdc -i modelmesh-serving-component.mmd -o modelmesh-serving-component.png -w 3000
   ```

3. **Alternative formats** (if needed):
   ```bash
   # SVG (vector, scales perfectly)
   PUPPETEER_EXECUTABLE_PATH=/usr/bin/google-chrome mmdc -i modelmesh-serving-component.mmd -o modelmesh-serving-component.svg

   # PDF
   PUPPETEER_EXECUTABLE_PATH=/usr/bin/google-chrome mmdc -i modelmesh-serving-component.mmd -o modelmesh-serving-component.pdf
   ```

**Note**: If `google-chrome` is not found, try `chromium` or `which google-chrome` to locate it

### C4 Diagrams (.dsl files)
- **Structurizr Lite**: `docker run -p 8080:8080 -v $(pwd):/usr/local/structurizr structurizr/lite`
- **CLI export**: `structurizr-cli export -workspace modelmesh-serving-c4-context.dsl -format png`
- **Online**: Upload to https://structurizr.com/dsl

### ASCII Diagrams (.txt files)
- View in any text editor or terminal
- Include in documentation as-is (monospace font recommended)
- Perfect for security architecture reviews (precise technical details)
- Contains RBAC summary, Network Policies, and Secrets management details

## Updating Diagrams

To regenerate after architecture changes:

```bash
# Re-run diagram generation skill
/generate-architecture-diagrams --architecture=architecture/rhoai-2.25/modelmesh-serving.md

# Or manually regenerate PNGs only (if .mmd files were edited)
python scripts/generate_diagram_pngs.py architecture/rhoai-2.25/diagrams --width=3000
```

## Related Documentation

- Architecture specification: `architecture/rhoai-2.25/modelmesh-serving.md`
- Upstream repository: https://github.com/red-hat-data-services/modelmesh-serving
- KServe InferenceService v1beta1 API: Shared with KServe component
- ModelMesh documentation: https://github.com/kserve/modelmesh

## Integration Points

ModelMesh Serving integrates with:
- **KServe**: Shares InferenceService CRD v1beta1 schema
- **ETCD**: Required for model metadata and cluster coordination (2379/TCP)
- **OpenShift Service Mesh**: Optional mTLS and traffic management
- **Prometheus**: Metrics collection (8443/TCP, 2112/TCP)
- **S3-compatible storage**: Model artifact storage (443/TCP HTTPS)
- **Model Registry**: Optional model metadata integration
- **ODH Dashboard**: UI management of InferenceServices
- **Data Science Pipelines**: Automated model deployment

## Version Information

- **Component Version**: 1.27.0-rhods-480-ge5d8db5
- **Branch**: rhoai-2.25
- **Go Version**: 1.25.7
- **ETCD Version**: v3.5.9
- **Kubernetes**: 1.28+
- **Recent Changes**:
  - Update UBI9 go-toolset base image
  - Update controller-gen to 0.17.0
  - Fix CVE-2025-61729 (crypto/x509) by upgrading to Go 1.25.7
