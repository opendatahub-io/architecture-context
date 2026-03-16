# Architecture Diagrams for ODH Model Controller

Generated from: `architecture/rhoai-2.15/odh-model-controller.md`
Date: 2026-03-15

**Note**: Diagram filenames use base component name without version (directory is already versioned).

## Available Diagrams

All Mermaid diagrams are available in both `.mmd` (source) and `.png` (3000px width, high-resolution) formats.

### For Developers
- [Component Structure](./odh-model-controller-component.png) ([mmd](./odh-model-controller-component.mmd)) - Mermaid diagram showing internal components, reconcilers, and watched CRDs
- [Data Flows](./odh-model-controller-dataflow.png) ([mmd](./odh-model-controller-dataflow.mmd)) - Sequence diagram of InferenceService reconciliation, webhook validation, and monitoring
- [Dependencies](./odh-model-controller-dependencies.png) ([mmd](./odh-model-controller-dependencies.mmd)) - Component dependency graph showing external/internal dependencies and deployment modes

### For Architects
- [C4 Context](./odh-model-controller-c4-context.dsl) - System context in C4 format (Structurizr) showing ODH Model Controller in the broader ecosystem
- [Component Overview](./odh-model-controller-component.png) ([mmd](./odh-model-controller-component.mmd)) - High-level component view with reconcilers and runtime templates

### For Security Teams
- [Security Network Diagram (PNG)](./odh-model-controller-security-network.png) - High-resolution network topology with trust boundaries
- [Security Network Diagram (Mermaid)](./odh-model-controller-security-network.mmd) - Visual network topology (editable)
- [Security Network Diagram (ASCII)](./odh-model-controller-security-network.txt) - Precise text format for SAR submissions with complete RBAC, service mesh config, and secrets
- [RBAC Visualization](./odh-model-controller-rbac.png) ([mmd](./odh-model-controller-rbac.mmd)) - RBAC permissions and bindings for all API resources

## Component Overview

**ODH Model Controller** extends KServe functionality with OpenShift-specific integrations for production model serving. It watches KServe InferenceService resources and automatically configures:

- **OpenShift Routes** for external access
- **Istio service mesh** components (VirtualServices, PeerAuthentications, Telemetries)
- **Prometheus monitoring** resources (ServiceMonitors, PodMonitors)
- **Authorino authentication** policies (AuthConfigs)
- **Network policies** for traffic control
- **Service mesh membership** for namespaces
- **Serving runtime templates** (vLLM, TGIS, Caikit, OpenVINO Model Server)

### Deployment Modes

The controller supports three deployment modes:

1. **ModelMesh**: Multi-model serving with ModelMesh runtime
2. **KServe Serverless**: Knative-based autoscaling with full service mesh integration
3. **KServe Raw**: Direct Kubernetes deployments without Knative

### Key Features

- **Pre-configured serving runtimes**: vLLM, TGIS, Caikit, OpenVINO Model Server
- **Automatic service mesh integration**: mTLS, traffic routing, telemetry
- **Webhook validation**: Ensures Knative Services are properly configured for service mesh
- **Storage secret management**: Handles S3 credentials and PVC access
- **Custom CA certificates**: Manages custom CA bundles for secure communication
- **Model registry integration**: Optional integration for model lineage tracking

## Network Architecture

### Controller Services

| Service | Type | Port | Protocol | Encryption | Auth |
|---------|------|------|----------|------------|------|
| odh-model-controller-metrics-service | ClusterIP | 8080/TCP | HTTP | None | Bearer Token |
| odh-model-controller-webhook-service | ClusterIP | 443/TCP → 9443 | HTTPS | TLS 1.2+ (mTLS) | K8s API Server |

### Egress

- **Kubernetes API Server**: 6443/TCP HTTPS TLS1.2+ (ServiceAccount Token)
- **Prometheus**: 9090/TCP HTTP (optional, Bearer Token)

### Resources Created per InferenceService

In **KServe Serverless mode**, the controller creates:

- **OpenShift Route**: 443/TCP HTTPS Edge TLS for external access
- **Istio VirtualService**: 80/TCP, 443/TCP HTTP/HTTPS with mTLS
- **PeerAuthentication**: mTLS STRICT mode enforcement
- **Authorino AuthConfig**: Authentication policies
- **ServiceMonitor**: Prometheus scrape configuration
- **NetworkPolicy**: Traffic control (allow 9443/TCP to controller)
- **ServiceMeshMember**: Namespace mesh membership
- **ServingRuntime**: Runtime template (vLLM/TGIS/Caikit/OVMS)

## Security Architecture

### RBAC Summary

The controller has broad cluster-wide permissions to manage inference infrastructure:

**Primary ClusterRole: `odh-model-controller-role`**

- **KServe API**: Full CRUD on InferenceServices, ServingRuntimes
- **Istio API**: Full CRUD on VirtualServices, PeerAuthentications, Telemetries; read-only on AuthorizationPolicies
- **Maistra API**: Full CRUD on ServiceMeshMembers; read+use on ServiceMeshMemberRolls, ServiceMeshControlPlanes
- **OpenShift Route API**: Full CRUD on Routes (including custom-host)
- **Networking**: Full CRUD on NetworkPolicies; read-only on Ingresses
- **Monitoring**: Full CRUD on ServiceMonitors, PodMonitors
- **Authorino**: Full CRUD on AuthConfigs
- **RBAC**: Full CRUD on ClusterRoleBindings, RoleBindings
- **Core Resources**: Full CRUD on Services, Secrets, ConfigMaps, ServiceAccounts; read+update on Namespaces, Pods, Endpoints
- **ODH Platform**: Read-only on DataScienceClusters, DSCInitializations

**Leader Election ClusterRole: `odh-model-controller-leader-election-role`**

- ConfigMaps, Leases, Events (for leader election mechanism)

### Authentication & Authorization

| Endpoint | Port | Protocol | Encryption | Auth | Purpose |
|----------|------|----------|------------|------|---------|
| /metrics | 8080/TCP | HTTP | None | Bearer Token | Prometheus metrics |
| /healthz | 8081/TCP | HTTP | None | None | Liveness probe |
| /readyz | 8081/TCP | HTTP | None | None | Readiness probe |
| /validate-serving-knative-dev-v1-service | 9443/TCP | HTTPS | TLS 1.2+ (mTLS) | K8s API Server | Webhook validation |

### Secrets

| Secret | Type | Purpose | Auto-Rotate |
|--------|------|---------|-------------|
| odh-model-controller-webhook-cert | kubernetes.io/tls | TLS certificate for webhook server | Yes (OpenShift service CA, 90d) |
| Storage secrets (per InferenceService) | Opaque | S3 credentials, PVC access tokens | No (manual) |

### Service Mesh Configuration

- **PeerAuthentication**: STRICT mTLS mode (namespace or workload-level)
- **VirtualService**: Traffic routing to predictor/transformer/explainer
- **NetworkPolicy**: Restrict webhook traffic to K8s API Server (allow 9443/TCP)
- **ServiceMeshMember**: Namespace membership in istio-system control plane

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

## Deployment Information

### Container Build

- **Build System**: Konflux (Red Hat's cloud-native CI/CD)
- **Base Images**:
  - Builder: `registry.redhat.io/ubi8/go-toolset` (SHA-pinned)
  - Runtime: `registry.redhat.io/ubi8/ubi-minimal` (SHA-pinned)
- **Binary**: `/manager`
- **User**: UID 2000 (non-root)

### Runtime Configuration

- **Replicas**: 1 (with leader election)
- **Resource Limits**: CPU 500m, Memory 2Gi
- **Resource Requests**: CPU 10m, Memory 64Mi
- **Namespace**: redhat-ods-applications
- **ServiceAccount**: odh-model-controller

### Environment Variables

| Variable | Purpose | Source |
|----------|---------|--------|
| POD_NAMESPACE | Controller's namespace | DownwardAPI |
| AUTH_AUDIENCE | Authorino audience | ConfigMap (optional) |
| AUTHORINO_LABEL | Authorino instance label | ConfigMap (optional) |
| CONTROL_PLANE_NAME | Service mesh control plane name | ConfigMap (optional) |
| MESH_NAMESPACE | Service mesh namespace | ConfigMap (optional) |
| MESH_DISABLED | Disable service mesh integration | ConfigMap (optional) |

### Command-line Flags

- `--leader-elect`: Enable leader election (default in deployment)
- `--metrics-bind-address`: Metrics server address (default :8080)
- `--health-probe-bind-address`: Health probe address (default :8081)
- `--monitoring-namespace`: Prometheus namespace (optional)
- `--model-registry-inference-reconcile`: Enable model registry integration (optional)

## Serving Runtime Templates

The controller manages pre-configured serving runtime templates:

| Runtime | Protocol | Model Format | GPU Support | Use Case |
|---------|----------|--------------|-------------|----------|
| vLLM | REST (OpenAI-compatible) | vLLM | Required | High-throughput LLM inference |
| TGIS | gRPC | Flan-T5, Llama | Required | Text generation with IBM TGIS |
| Caikit-TGIS | gRPC | Caikit text generation | Required | Caikit framework with TGIS backend |
| Caikit Standalone | gRPC | Caikit models | Optional | General Caikit model serving |
| OVMS (ModelMesh) | gRPC | ONNX, OpenVINO, TensorFlow | Optional | Multi-model serving |
| OVMS (KServe) | gRPC/REST | ONNX, OpenVINO, TensorFlow | Optional | Single model serving |

All runtime templates are labeled with `opendatahub.io/dashboard=true` for ODH Dashboard discovery.

## Integration Points

| Component | Interaction Type | Port | Protocol | Purpose |
|-----------|------------------|------|----------|---------|
| Kubernetes API Server | REST API | 6443/TCP | HTTPS TLS1.2+ | CRUD operations on all managed resources |
| KServe Controller | Shared CRD Watch | 6443/TCP | HTTPS TLS1.2+ | Co-manages InferenceService resources |
| Istio Control Plane | CRD Management | 6443/TCP | HTTPS TLS1.2+ | Creates VirtualServices, PeerAuthentications, Telemetries |
| Authorino | CRD Management | 6443/TCP | HTTPS TLS1.2+ | Creates AuthConfig resources |
| Prometheus | ServiceMonitor | 8080/TCP | HTTP | Scrapes controller metrics |
| OpenShift Router | Route Creation | 6443/TCP | HTTPS TLS1.2+ | Creates Routes for external access |
| Service Mesh Operator | ServiceMeshMember | 6443/TCP | HTTPS TLS1.2+ | Manages mesh membership |
| Model Registry | gRPC API (optional) | 9090/TCP | gRPC mTLS | Associates InferenceServices with models |

## Updating Diagrams

To regenerate after architecture changes:

```bash
# Regenerate all diagrams
cd architecture/rhoai-2.15
python ../../scripts/generate_architecture_diagrams.py --architecture=odh-model-controller.md

# Or regenerate PNG files only
cd diagrams
for file in odh-model-controller-*.mmd; do
  PUPPETEER_EXECUTABLE_PATH=/usr/bin/google-chrome mmdc -i "$file" -o "${file%.mmd}.png" -w 3000
done
```

## Related Documentation

- Architecture source: [../odh-model-controller.md](../odh-model-controller.md)
- KServe documentation: [KServe InferenceService](https://kserve.github.io/website/latest/)
- OpenShift Service Mesh: [Red Hat Service Mesh](https://docs.openshift.com/container-platform/latest/service_mesh/v2x/ossm-about.html)
- Authorino: [Authorino Authentication](https://github.com/Kuadrant/authorino)

## Version Information

- **Component Version**: v1.27.0-rhods-478-g099ff49
- **Branch**: rhoai-2.15
- **Distribution**: Red Hat OpenShift AI (RHOAI)
- **Repository**: https://github.com/red-hat-data-services/odh-model-controller.git
