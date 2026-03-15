# Architecture Diagrams for Red Hat OpenShift AI 2.25 Platform

Generated from: `architecture/rhoai-2.25/PLATFORM.md`
Date: 2026-03-15
Component: platform (aggregated platform view)

**Note**: Diagram filenames use base component name without version (directory `rhoai-2.25/` is already versioned).

## Available Diagrams

All Mermaid diagrams are available in both `.mmd` (source) and `.png` (3000px width, high-resolution) formats.

### For Developers

- **[Component Structure](./platform-component.png)** ([mmd](./platform-component.mmd)) - Mermaid diagram showing 16 RHOAI platform components and their relationships
  - Platform orchestration by rhods-operator
  - Model serving layer (KServe, ModelMesh, Model Controller, Model Registry)
  - ML development & training (Notebooks, Training Operator, Pipelines)
  - Distributed computing (CodeFlare, KubeRay, Kueue)
  - AI safety & features (TrustyAI, Feast)
  - LLM serving (Llama Stack Operator)
  - External dependencies (Istio, Knative, S3, OAuth, Kubernetes API)

- **[Data Flows](./platform-dataflow.png)** ([mmd](./platform-dataflow.mmd)) - Sequence diagram showing end-to-end ML workflows
  - Workflow 1: Interactive development & training (Notebook → Training → S3)
  - Workflow 2: Model deployment & serving (Dashboard → KServe → Istio Gateway)
  - Workflow 3: Inference request flow (Client → Gateway → Predictor → Response)
  - Workflow 4: Model registration (User → Model Registry → PostgreSQL)
  - Workflow 5: Monitoring (Components → Prometheus → Dashboard)
  - All protocols, ports, and authentication mechanisms annotated

- **[Dependencies](./platform-dependencies.png)** ([mmd](./platform-dependencies.mmd)) - Component dependency graph showing integration points
  - Platform orchestration: rhods-operator deploys all 16 components
  - Dashboard integrations: API calls to KServe, Model Registry, Prometheus
  - Model serving dependencies: Knative, Istio, S3, cert-manager
  - Training & pipelines: S3 storage, Model Registry, HuggingFace Hub
  - Distributed computing: CodeFlare → KubeRay → Kueue admission control
  - External services: S3, PostgreSQL, Redis, ETCD, NGC API, container registries
  - Common dependencies: Kubernetes API, Prometheus metrics, OAuth authentication

### For Architects

- **[C4 Context](./platform-c4-context.dsl)** - System context in C4 format (Structurizr)
  - Actors: Data Scientist, ML Engineer, Platform Administrator
  - Platform system with 16 containers (components)
  - External systems: OpenShift, Istio, Knative, S3, PostgreSQL, Redis, NGC, HuggingFace
  - Relationship mapping showing data flows and dependencies
  - Multiple views: System Context, Platform Containers, Model Serving, Training Pipeline, Distributed Compute

- **[Component Overview](./platform-component.png)** ([mmd](./platform-component.mmd)) - High-level platform architecture
  - Color-coded by functional area (platform core, model serving, development, compute, AI safety)
  - Shows orchestration, integration patterns, and external dependencies

### For Security Teams

- **[Security Network Diagram (PNG)](./platform-security-network.png)** - High-resolution network topology (3000px width)
  - Visual trust zones: External, Ingress (DMZ), Service Mesh, Egress
  - Color-coded security boundaries
  - Network flow annotations with ports, protocols, encryption

- **[Security Network Diagram (Mermaid)](./platform-security-network.mmd)** - Visual network topology (editable)
  - Ingress layer: OpenShift Routes (edge TLS) and Istio Gateway (TLS 1.3)
  - Service mesh: mTLS PERMISSIVE/STRICT mode between components
  - Egress: S3 (AWS IAM), Container Registries (pull secrets), NGC API (API key), OAuth
  - All authentication mechanisms and encryption protocols documented

- **[Security Network Diagram (ASCII)](./platform-security-network.txt)** - Precise text format for SAR submissions
  - Exact port numbers (443/TCP, 8443/TCP, 6443/TCP, etc.)
  - Protocols (HTTPS, HTTP, PostgreSQL, Redis)
  - Encryption details (TLS 1.2+, TLS 1.3, mTLS PERMISSIVE/STRICT)
  - Authentication mechanisms (OAuth Bearer Token, ServiceAccount JWT, AWS IAM, mTLS certs)
  - Trust boundaries (External → Ingress → Service Mesh → Egress)
  - **RBAC Summary** (15+ ClusterRoles with API group permissions)
  - **Service Mesh Configuration** (PeerAuthentication, AuthorizationPolicy, RequestAuthentication, Telemetry)
  - **Secrets Inventory** (40+ secrets: TLS certs, OAuth tokens, S3 credentials, NGC pull secrets, database passwords)
  - **Network Policies** (egress restrictions, DNS, Kubernetes API)
  - **Compliance & Security Posture** (FIPS compliance, mTLS coverage, authentication layers, secret rotation, audit logging)

- **[RBAC Visualization](./platform-rbac.png)** ([mmd](./platform-rbac.mmd)) - RBAC permissions and bindings
  - 15 Service Accounts (redhat-ods-applications namespace)
  - 15 ClusterRoles with detailed permissions
  - 15 ClusterRoleBindings mapping SAs to roles
  - API resources: 60+ CRDs across platform
  - Common Kubernetes resources: Pods, Services, Deployments, Secrets, Routes, NetworkPolicies
  - Permission flow: ServiceAccount → ClusterRoleBinding → ClusterRole → API Resources

## Platform Component Summary

Red Hat OpenShift AI 2.25 includes **16 major components**:

1. **rhods-operator** - Platform orchestrator managing DataScienceCluster lifecycle
2. **odh-dashboard** - Web UI for platform management and monitoring
3. **kserve** - Kubernetes-native serverless model serving
4. **modelmesh-serving** - Multi-model serving for high-throughput inference
5. **odh-model-controller** - KServe extension with OpenShift integration (Routes, OAuth, Istio)
6. **data-science-pipelines-operator** - Kubeflow Pipelines for ML workflows
7. **model-registry-operator** - Model versioning and metadata tracking
8. **training-operator** - Distributed training (PyTorch, TensorFlow, XGBoost, MPI, JAX, PaddlePaddle)
9. **codeflare-operator** - Distributed AI/ML workload orchestration
10. **kuberay** - Ray cluster lifecycle management
11. **kueue** - Job queueing and workload scheduling
12. **trustyai-service-operator** - AI explainability, LM evaluation, guardrails
13. **feast-operator** - Feature store for consistent training/serving
14. **llama-stack-k8s-operator** - Llama Stack inference (Ollama, vLLM, TGI, Bedrock)
15. **notebook-controller** - Jupyter, VS Code, RStudio workbench instances
16. **notebooks** - Container images for interactive development environments

## Platform Statistics

- **Total CRDs**: 60+ custom resource definitions
- **Namespaces**:
  - `redhat-ods-operator` - Operator management
  - `redhat-ods-applications` - Platform services and component operators
  - `redhat-ods-monitoring` - Prometheus, Alertmanager, Grafana (optional)
  - `istio-system` - Istio control plane (optional)
  - User namespaces - Workloads (notebooks, models, pipelines, training jobs)
- **Operator-based Components**: 14 of 16 (87.5%)
- **External Dependencies**:
  - Required: Kubernetes API, OpenShift OAuth
  - Optional: Istio, Knative Serving
  - Storage: S3-compatible, PostgreSQL/MySQL, Redis, ETCD
  - External Services: NVIDIA NGC, HuggingFace Hub, Container Registries
- **Security**:
  - FIPS-compliant builds
  - mTLS PERMISSIVE/STRICT (optional Istio service mesh)
  - OpenShift OAuth for external access
  - ServiceAccount tokens for internal API calls
  - 40+ secrets with auto-rotation (service-ca, cert-manager)

## How to Use

### PNG Files (.png files)
**Automatically generated** at 3000px width for high-resolution presentations and documentation.

- **Ready to use**: High-resolution images suitable for presentations, wikis, and documentation
- **Width**: 3000px (height auto-adjusts to content)
- **Use directly**: Include in PowerPoint, Google Slides, Confluence, etc.

**Examples:**
- `platform-component.png` - 339 KB, shows all 16 components and relationships
- `platform-dependencies.png` - **1.1 MB**, comprehensive dependency graph (large!)
- `platform-security-network.png` - 343 KB, visual security topology

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
   PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium-browser mmdc -i platform-component.mmd -o platform-component.png -w 3000 -b transparent
   ```

3. **Alternative formats** (if needed):
   ```bash
   # SVG (vector, scales perfectly)
   PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium-browser mmdc -i platform-component.mmd -o platform-component.svg

   # PDF
   PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium-browser mmdc -i platform-component.mmd -o platform-component.pdf
   ```

**Note**: If `chromium-browser` is not found, try `google-chrome` or `which chromium-browser` to locate it

### C4 Diagrams (.dsl files)
- **Structurizr Lite**:
  ```bash
  docker run -it --rm -p 8080:8080 -v $(pwd):/usr/local/structurizr structurizr/lite
  ```
  Then open http://localhost:8080 and navigate to the workspace

- **CLI export** (requires Structurizr CLI):
  ```bash
  structurizr-cli export -workspace platform-c4-context.dsl -format png
  ```

### ASCII Diagrams (.txt files)
- **View in any text editor** with monospace font
- **Include in documentation** as-is (copy-paste preserves formatting)
- **Perfect for security reviews** (precise technical details, no ambiguity)
- **SAR submissions** (Security Architecture Review documentation)

**Example use case**: The `platform-security-network.txt` file contains:
- Detailed network topology with exact ports and protocols
- RBAC summary with ClusterRoles and permissions
- Service mesh configuration (PeerAuthentication, AuthorizationPolicies)
- Secrets inventory with rotation policies
- Compliance checklist (FIPS, mTLS, authentication layers)

## Updating Diagrams

To regenerate after architecture changes:

```bash
# Navigate to repository root
cd /path/to/kahowell.rhoai-architecture-diagrams

# Regenerate platform diagrams
# (Use your diagram generation tool/script with PLATFORM.md as input)
```

## Individual Component Diagrams

In addition to this platform overview, individual component diagrams are also available in this directory:

- `codeflare-operator-*` - CodeFlare operator diagrams
- `data-science-pipelines-operator-*` - DSP operator diagrams
- `feast-*` - Feast operator diagrams
- `kserve-*` - KServe diagrams
- `kubeflow-*` - Notebook controller (Kubeflow) diagrams
- `kuberay-*` - KubeRay operator diagrams
- `kueue-*` - Kueue operator diagrams
- `llama-stack-k8s-operator-*` - Llama Stack operator diagrams
- `modelmesh-serving-*` - ModelMesh diagrams
- `model-registry-operator-*` - Model Registry diagrams
- `notebooks-*` - Notebook workbench diagrams
- `odh-dashboard-*` - Dashboard diagrams
- `odh-model-controller-*` - Model Controller diagrams
- `rhods-operator-*` - RHOAI operator diagrams
- `training-operator-*` - Training operator diagrams
- `trustyai-service-operator-*` - TrustyAI operator diagrams (in progress)

Each component has its own set of diagrams:
- `*-component.mmd/.png` - Component internal structure
- `*-dataflow.mmd/.png` - Request/response flows
- `*-dependencies.mmd/.png` - Dependency graph
- `*-rbac.mmd/.png` - RBAC permissions
- `*-security-network.mmd/.png/.txt` - Security network topology
- `*-c4-context.dsl` - C4 system context

See individual component README files for details (e.g., `kubeflow-README.md`, `modelmesh-serving-README.md`, etc.)

## Architecture Review Checklist

When using these diagrams for architecture reviews:

- [ ] **Component diagram** - Understand platform structure and component relationships
- [ ] **Dependency graph** - Identify integration points and external dependencies
- [ ] **Data flow diagram** - Trace end-to-end ML workflows
- [ ] **Security network diagram** - Review trust boundaries, encryption, authentication
- [ ] **RBAC diagram** - Verify least-privilege permissions
- [ ] **C4 context** - Present system context to stakeholders
- [ ] **ASCII security diagram** - Submit for SAR with precise technical details

## Questions or Issues?

For questions about:
- **Platform architecture**: Review `../PLATFORM.md` source document
- **Individual components**: See component-specific `GENERATED_ARCHITECTURE.md` files
- **Diagram updates**: Regenerate from updated architecture markdown files
- **Security details**: Refer to `platform-security-network.txt` for comprehensive security documentation

---

**Generated with architectural diagram tooling**
**Source**: `architecture/rhoai-2.25/PLATFORM.md`
**Component naming**: Filename-derived (PLATFORM.md → platform-*)
**Versioning**: Directory-based (`rhoai-2.25/`)
