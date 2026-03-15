# Architecture Diagrams for KServe

Generated from: `architecture/rhoai-2.25.0/kserve.md`
Date: 2026-03-14
Component: kserve
Version: RHOAI 2.25.0 (commit 4211a5da7)

**Note**: Diagram filenames use base component name without version (directory is already versioned).

## Available Diagrams

All Mermaid diagrams are available in both `.mmd` (source) and `.png` (3000px width, high-resolution) formats.

### For Developers
- [Component Structure](./kserve-component.png) ([mmd](./kserve-component.mmd)) - Mermaid diagram showing internal components, CRDs, dependencies
- [Data Flows](./kserve-dataflow.png) ([mmd](./kserve-dataflow.mmd)) - Sequence diagram of request/response flows including model deployment, inference, InferenceGraph, and LLM distributed inference
- [Dependencies](./kserve-dependencies.png) ([mmd](./kserve-dependencies.mmd)) - Component dependency graph showing external and internal RHOAI dependencies

### For Architects
- [C4 Context](./kserve-c4-context.dsl) - System context in C4 format (Structurizr) with container and component views
- [Component Overview](./kserve-component.png) ([mmd](./kserve-component.mmd)) - High-level component view with CRDs and integrations

### For Security Teams
- [Security Network Diagram (PNG)](./kserve-security-network.png) - High-resolution network topology with trust zones
- [Security Network Diagram (Mermaid)](./kserve-security-network.mmd) - Visual network topology (editable, color-coded trust zones)
- [Security Network Diagram (ASCII)](./kserve-security-network.txt) - Precise text format for SAR submissions with detailed RBAC, Service Mesh config, secrets, and network policies
- [RBAC Visualization](./kserve-rbac.png) ([mmd](./kserve-rbac.mmd)) - RBAC permissions and bindings across all API groups

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
- **Structurizr Lite**:
  ```bash
  docker run -p 8080:8080 -v $(pwd):/usr/local/structurizr structurizr/lite
  ```
  Then open http://localhost:8080 and navigate to the workspace

- **CLI export**:
  ```bash
  structurizr-cli export -workspace kserve-c4-context.dsl -format png
  ```

### ASCII Diagrams (.txt files)
- View in any text editor
- Include in documentation as-is
- Perfect for security reviews (precise technical details)
- **Security Network Diagram** includes:
  - Exact port numbers, protocols, encryption methods
  - Authentication mechanisms for each connection
  - RBAC summary with ClusterRole permissions
  - Service Mesh configuration (PeerAuthentication, AuthorizationPolicy)
  - Secrets management and rotation policies
  - Network policies
  - Security best practices applied
  - Recent security fixes (path traversal vulnerabilities)

## Diagram Descriptions

### kserve-component.mmd
Shows the internal architecture of KServe including:
- **Control Plane**: kserve-controller-manager, webhook server, localmodel-controller
- **Data Plane**: storage-initializer, agent, model-server, router
- **Custom Resources**: InferenceService, ServingRuntime, TrainedModel, InferenceGraph, LLMInferenceService
- **External Dependencies**: Knative, Istio, KEDA, cert-manager
- **Internal RHOAI**: Dashboard, Model Registry, Service Mesh
- **External Services**: S3, GCS, Azure Blob Storage

### kserve-dataflow.mmd
Sequence diagrams showing:
- **Flow 1**: Model deployment and loading (InferenceService creation → model download → pod ready)
- **Flow 2**: Inference request (serverless mode with Istio, scale-from-zero, batching, logging)
- **Flow 3**: Multi-model InferenceGraph (parallel model calls, ensemble results)
- **Flow 4**: LLM distributed inference (LeaderWorkerSet, vLLM, Ray cluster)

### kserve-security-network.txt & .mmd
Detailed network topology with trust zones:
- **EXTERNAL**: Untrusted clients (443/TCP HTTPS TLS 1.2+, Bearer Token)
- **INGRESS (DMZ)**: Istio Gateway / OpenShift Route (TLS termination, JWT validation)
- **SERVICE MESH**: mTLS STRICT enforcement, Knative Activator, InferenceService pods
- **CONTROL PLANE**: kserve-controller-manager, webhook server, Kubernetes API
- **EXTERNAL SERVICES**: S3/GCS/Azure storage, Knative API

Includes:
- Exact port/protocol/encryption/auth for each connection
- RBAC summary (ClusterRole permissions across 15+ API groups)
- Service Mesh config (PeerAuthentication STRICT, AuthorizationPolicy, DestinationRule, VirtualService)
- Secrets (webhook certs, storage credentials, SA tokens, rotation policies)
- Network policies (ingress/egress rules)
- Security best practices and recent CVE fixes

### kserve-c4-context.dsl
C4 Model with multiple views:
- **SystemContext**: KServe in the broader ecosystem (users, external systems, RHOAI components)
- **Containers**: Internal KServe components (controller, webhook, pods, router)
- **Components**: InferenceService Pod internals (storage-initializer, agent, model-server, Envoy)
- **Dynamic Views**:
  - InferenceRequestFlow: External client → Istio → model server → response
  - ModelDeploymentFlow: InferenceService creation → Knative/Deployment → pod ready

### kserve-dependencies.mmd
Dependency graph showing:
- **External Dependencies**: Knative (optional), Istio (optional), KEDA, OTel, Prometheus, Gateway API, cert-manager
- **Internal RHOAI**: OpenDataHub Operator, Service Mesh, Dashboard, Model Registry, Pipelines
- **External Services**: S3, GCS, Azure, Event Sink
- **Platform**: Kubernetes API, OpenShift Routes
- **Managed Resources**: Knative Services, Deployments, VirtualServices, ScaledObjects, HPA
- **Reverse Dependencies**: ModelMesh, Notebooks, CodeFlare

### kserve-rbac.mmd
RBAC visualization showing:
- **Service Account**: kserve-controller-manager
- **ClusterRole**: kserve-manager-role with permissions across:
  - serving.kserve.io (InferenceService, ServingRuntime, TrainedModel, InferenceGraph, LLMInferenceService, etc.)
  - serving.knative.dev (Services)
  - networking.istio.io (VirtualServices, DestinationRules)
  - apps (Deployments), autoscaling (HPA), core (Services, Secrets, ConfigMaps)
  - networking.k8s.io (Ingresses), route.openshift.io (Routes)
  - gateway.networking.k8s.io (HTTPRoutes, Gateways)
  - keda.sh (ScaledObjects), opentelemetry.io (OpenTelemetryCollectors)
  - monitoring.coreos.com (ServiceMonitors, PodMonitors)
  - admissionregistration.k8s.io (MutatingWebhookConfigurations, ValidatingWebhookConfigurations)
  - rbac.authorization.k8s.io (ClusterRoleBindings, RoleBindings, Roles)
  - security.openshift.io (SecurityContextConstraints - use permission)
  - leaderworkerset.x-k8s.io (LeaderWorkerSets for LLM inference)
  - inference.networking.x-k8s.io (InferenceModels, InferencePools)

## KServe Component Overview

**Purpose**: Serverless ML inference platform for deploying and serving machine learning models on Kubernetes

**Key Capabilities**:
- Standardized inference protocols (V1 REST, V2 REST/gRPC)
- Multi-framework support (TensorFlow, PyTorch, Scikit-Learn, XGBoost, HuggingFace, vLLM, etc.)
- Serverless autoscaling with scale-to-zero (via Knative)
- Service mesh integration for mTLS, traffic routing, canary rollouts (via Istio)
- Advanced inference patterns:
  - Pre/post-processing transformers
  - Model explainability
  - InferenceGraph for multi-model pipelines (sequence, switch, ensemble)
  - Multi-node distributed inference for large language models (LeaderWorkerSet, vLLM, Ray)
- Multiple deployment modes:
  - Serverless (Knative) with scale-to-zero
  - Raw Kubernetes (Deployments) for always-on workloads
- Storage support: S3, GCS, Azure Blob, HTTP, PVC
- Event-driven autoscaling (KEDA) with custom metrics (queue depth, RPS)
- Request/response logging to event sinks (CloudEvents)
- GPU autoscaling and multi-GPU support
- Local model caching for edge/disconnected deployments

**Architecture**:
- **Control Plane**: Go operator reconciling InferenceService CRDs, creating Knative Services or Deployments
- **Data Plane**: Python/C++ model servers with storage-initializer (init container) and agent (sidecar)
- **Webhook**: Validates and mutates InferenceServices, injects sidecars and storage config
- **Networking**: Istio VirtualServices for traffic routing, OpenShift Routes or Gateway API for ingress

**Security**:
- mTLS STRICT across service mesh
- TLS 1.2+ for all external communications
- RBAC with least privilege (ClusterRole across 15+ API groups)
- AWS IRSA / GCP Workload Identity support (no long-lived credentials)
- Path traversal vulnerabilities patched (RHOAIENG-47407, commits bb03ddbbe, 16e11a862)
- Security context constraints on OpenShift

**Recent Changes (RHOAI 2.25)**:
- Multi-architecture support (ppc64le, s390x)
- Security hardening (path traversal fixes, image size reduction)
- Proxy configuration support
- Konflux CI/CD integration

## Network Architecture Highlights

### Inference Request Flow (Serverless Mode)
1. External Client → Istio Ingress Gateway (443/TCP HTTPS TLS 1.2+, Bearer Token)
2. Gateway → Istio VirtualService (TLS termination, route selection)
3. VirtualService → Knative Activator (80/TCP HTTP, mTLS, scale-from-zero)
4. Activator → InferenceService Pod Agent Sidecar (8012/TCP HTTP, mTLS)
5. Agent → Model Server (8080/TCP HTTP, localhost, batching)
6. Model Server → Response (JSON prediction)
7. (Optional) Agent → Event Sink (80/443 TCP, CloudEvents logging)

### Model Deployment Flow
1. User → kubectl apply InferenceService (Kubernetes API 6443/TCP HTTPS, Bearer Token)
2. Kubernetes API → kserve-webhook-server (9443/TCP HTTPS TLS 1.2+, validation/mutation)
3. kserve-controller-manager watches InferenceService CR
4. Controller → Creates Knative Service OR Deployment (Kubernetes API)
5. Controller → Creates Istio VirtualService + DestinationRule (traffic routing)
6. InferenceService Pod starts:
   - storage-initializer init container → S3/GCS/Azure (443/TCP HTTPS TLS 1.2+, AWS IAM/GCP SA)
   - storage-initializer → Writes model to /mnt/models volume
   - model-server → Loads model from /mnt/models
   - Pod becomes ready (liveness/readiness probes)

### Multi-Model InferenceGraph Flow
1. External Client → Istio Gateway (443/TCP HTTPS)
2. Gateway → InferenceGraph Router Pod (80/TCP HTTP mTLS)
3. Router → Model A Service (80/TCP HTTP mTLS, parallel)
4. Router → Model B Service (80/TCP HTTP mTLS, parallel)
5. Router → Combines results (sequence/switch/ensemble pattern)
6. Router → Returns response to client

### LLM Distributed Inference Flow
1. External Client → OpenShift Route or Gateway (443/TCP HTTPS TLS 1.2+)
2. Route → LeaderWorkerSet Leader Pod (vLLM) (8080/TCP HTTP mTLS)
3. Leader → Worker Pods (Ray cluster, 6379/TCP + 8265/TCP, pod network)
4. Workers → Shared storage for model shards (filesystem or S3)
5. Leader → Returns LLM response

### Security Layers
- **External**: TLS 1.2+ encryption, Bearer Token authentication (optional)
- **Ingress**: Istio Gateway TLS termination, RequestAuthentication (JWT validation)
- **Service Mesh**: mTLS STRICT enforcement via PeerAuthentication, AuthorizationPolicy for access control
- **Application**: Agent sidecar for batching/logging, localhost communication to model server
- **Storage**: AWS IRSA or GCP Workload Identity (no long-lived secrets), TLS 1.2+ for S3/GCS/Azure
- **Control Plane**: Webhook server with cert-manager TLS certs (90-day rotation), Kubernetes API auth

## RBAC Summary

### Operator Level
- **ClusterRole**: `kserve-manager-role` - Manages InferenceService lifecycle, CRD operations, webhook management
  - Full control over serving.kserve.io CRDs (InferenceService, ServingRuntime, etc.)
  - Creates/manages Knative Services, Istio VirtualServices, Deployments, HPA, Services, Secrets
  - Integrates with KEDA (ScaledObjects), OTel (OpenTelemetryCollectors), Prometheus (ServiceMonitors)
  - Manages Gateway API resources (HTTPRoutes, Gateways)
  - OpenShift Routes and SecurityContextConstraints (SCC use permission)

### InferenceService Instance Level (per namespace)
- **ServiceAccount**: `{isvc-name}-sa` - Runs inference pod workloads
  - Read access to Secrets (storage credentials)
  - Write access to ConfigMaps (for model config)
  - Limited to namespace scope

## Version Compatibility

| Component | Version | Required | Notes |
|-----------|---------|----------|-------|
| Kubernetes | 1.27+ | Yes | Platform |
| Knative Serving | 1.x | No | Optional for serverless mode |
| Istio | 1.x | No | Optional for service mesh (can use other networking) |
| KEDA | v2.x | No | Optional for metrics-based autoscaling |
| cert-manager | v1.x | No | Optional for TLS cert management |
| OpenTelemetry Operator | v1beta1 | No | Optional for LLM observability |
| Prometheus Operator | v1 | No | Optional for metrics scraping |
| Gateway API | v1 | No | Optional alternative to Istio VirtualServices |

## Updating Diagrams

To regenerate after architecture changes:
```bash
# From repository root
# 1. Update architecture file
vim architecture/rhoai-2.25.0/kserve.md

# 2. Regenerate diagrams (example command, adjust as needed)
# claude generate architecture diagrams from architecture/rhoai-2.25.0/kserve.md
```

## Additional Resources

- **KServe Documentation**: https://kserve.github.io/website/
- **RHOAI Documentation**: https://access.redhat.com/documentation/en-us/red_hat_openshift_ai_self-managed/
- **Architecture File**: [../kserve.md](../kserve.md)
- **Repository**: https://github.com/red-hat-data-services/kserve (rhoai-2.25 branch)
- **Upstream**: https://github.com/kserve/kserve
