# Architecture Diagrams for RHOAI 2.16 Components

Generated from: `architecture/rhoai-2.16/*.md`
Last updated: 2026-03-16

**Note**: Diagram filenames use base component name without version (directory is already versioned).

## Available Components

- [RHODS Operator](#rhods-operator)
- [Data Science Pipelines Operator](#data-science-pipelines-operator)
- [KServe](#kserve)
- [Kubeflow](#kubeflow)
- [KubeRay](#kuberay)
- [Kueue](#kueue)
- [CodeFlare Operator](#codeflare-operator)
- [Model Registry Operator](#model-registry-operator)
- [ModelMesh Serving](#modelmesh-serving)
- [Notebooks (Workbench Images)](#notebooks-workbench-images)
- [ODH Dashboard](#odh-dashboard)
- [ODH Model Controller](#odh-model-controller)
- [Training Operator](#training-operator)
- [TrustyAI Service Operator](#trustyai-service-operator)

---


---

## RHODS Operator

Generated from: `architecture/rhoai-2.16/rhods-operator.md`

All Mermaid diagrams are available in both `.mmd` (source) and `.png` (3000px width, high-resolution) formats.

### For Developers
- [Component Structure](./rhods-operator-component.png) ([mmd](./rhods-operator-component.mmd)) - Mermaid diagram showing internal components
- [Data Flows](./rhods-operator-dataflow.png) ([mmd](./rhods-operator-dataflow.mmd)) - Sequence diagram of request/response flows
- [Dependencies](./rhods-operator-dependencies.png) ([mmd](./rhods-operator-dependencies.mmd)) - Component dependency graph

### For Architects
- [C4 Context](./rhods-operator-c4-context.dsl) - System context in C4 format (Structurizr)
- [Component Overview](./rhods-operator-component.png) ([mmd](./rhods-operator-component.mmd)) - High-level component view

### For Security Teams
- [Security Network Diagram (PNG)](./rhods-operator-security-network.png) - High-resolution network topology
- [Security Network Diagram (Mermaid)](./rhods-operator-security-network.mmd) - Visual network topology (editable)
- [Security Network Diagram (ASCII)](./rhods-operator-security-network.txt) - Precise text format for SAR submissions
- [RBAC Visualization](./rhods-operator-rbac.png) ([mmd](./rhods-operator-rbac.mmd)) - RBAC permissions and bindings

**Architecture Summary**:

**RHODS Operator** is the central orchestration component for Red Hat OpenShift AI (RHOAI) and Open Data Hub (ODH). It manages the complete lifecycle of data science components through custom resources:

- **Primary CRs**: DataScienceCluster (component enablement), DSCInitialization (platform setup)
- **Managed Components**: 11 major components (Dashboard, Workbenches, Pipelines, KServe, ModelMesh, CodeFlare, Ray, TrustyAI, Model Registry, Kueue, Training Operator)
- **Platform Integration**: Service Mesh, Knative, Authorino, Prometheus, OpenShift OAuth
- **Security**: Comprehensive RBAC, mTLS for inter-component communication, webhook-based validation
- **Deployment**: Single operator pod, manifest-based component deployment, namespace management

**Key Features**:
- **Unified API**: Single DataScienceCluster CR to enable/disable all components
- **Platform Initialization**: Automated setup of monitoring, service mesh, and trusted CA bundles
- **Manifest-Based Deployment**: Embedded Kustomize overlays for consistent component deployment
- **Cross-Component Dependencies**: Automatic handling of component interdependencies
- **Monitoring Integration**: Self-monitoring and component health tracking via Prometheus
- **Service Mesh Integration**: Automatic mTLS configuration for secure model serving
- **Multi-Distribution Support**: Works with both RHOAI (commercial) and ODH (community)

**Data Flows**:
1. **DataScienceCluster Creation**: User creates DSC → Webhook validation → Controller reconciliation
2. **Component Manifest Deployment**: Controller reads manifests → Applies to Kubernetes API
3. **Monitoring and Metrics Collection**: Prometheus scrapes operator and component metrics
4. **Service Mesh Integration**: Operator configures SMCP/SMM for KServe

**Troubleshooting**:
```bash
# View operator logs
oc logs -n redhat-ods-operator deployment/rhods-operator

# Check DataScienceCluster status
oc get datasciencecluster -o yaml

# Check DSCInitialization status
oc get dscinitialization -o yaml

# View component events
oc get events -n redhat-ods-applications
```

## Data Science Pipelines Operator

Generated from: `architecture/rhoai-2.16/data-science-pipelines-operator.md`

All Mermaid diagrams are available in both `.mmd` (source) and `.png` (3000px width, high-resolution) formats.

### For Developers
- [Component Structure](./data-science-pipelines-operator-component.png) ([mmd](./data-science-pipelines-operator-component.mmd)) - Internal DSP stack architecture
- [Data Flows](./data-science-pipelines-operator-dataflow.png) ([mmd](./data-science-pipelines-operator-dataflow.mmd)) - Pipeline submission and execution flows
- [Dependencies](./data-science-pipelines-operator-dependencies.png) ([mmd](./data-science-pipelines-operator-dependencies.mmd)) - Component dependency graph

### For Architects
- [C4 Context](./data-science-pipelines-operator-c4-context.dsl) - System context in C4 format (Structurizr)
- [Component Overview](./data-science-pipelines-operator-component.png) ([mmd](./data-science-pipelines-operator-component.mmd)) - High-level component view

### For Security Teams
- [Security Network Diagram (PNG)](./data-science-pipelines-operator-security-network.png) - High-resolution network topology
- [Security Network Diagram (Mermaid)](./data-science-pipelines-operator-security-network.mmd) - Visual network topology (editable)
- [Security Network Diagram (ASCII)](./data-science-pipelines-operator-security-network.txt) - Precise text format for SAR submissions
- [RBAC Visualization](./data-science-pipelines-operator-rbac.png) ([mmd](./data-science-pipelines-operator-rbac.mmd)) - RBAC permissions and bindings

---

## KServe

Generated from: `architecture/rhoai-2.16/kserve.md`

All Mermaid diagrams are available in both `.mmd` (source) and `.png` (3000px width, high-resolution) formats.

### For Developers
- [Component Structure](./kserve-component.png) ([mmd](./kserve-component.mmd)) - Mermaid diagram showing internal components
- [Data Flows](./kserve-dataflow.png) ([mmd](./kserve-dataflow.mmd)) - Sequence diagram of request/response flows
- [Dependencies](./kserve-dependencies.png) ([mmd](./kserve-dependencies.mmd)) - Component dependency graph

### For Architects
- [C4 Context](./kserve-c4-context.dsl) - System context in C4 format (Structurizr)
- [Component Overview](./kserve-component.png) ([mmd](./kserve-component.mmd)) - High-level component view

### For Security Teams
- [Security Network Diagram (PNG)](./kserve-security-network.png) - High-resolution network topology
- [Security Network Diagram (Mermaid)](./kserve-security-network.mmd) - Visual network topology (editable)
- [Security Network Diagram (ASCII)](./kserve-security-network.txt) - Precise text format for SAR submissions
- [RBAC Visualization](./kserve-rbac.png) ([mmd](./kserve-rbac.mmd)) - RBAC permissions and bindings

---

## Kubeflow

Generated from: `architecture/rhoai-2.16/kubeflow.md`

All Mermaid diagrams are available in both `.mmd` (source) and `.png` (3000px width, high-resolution) formats.

### For Developers
- [Component Structure](./kubeflow-component.png) ([mmd](./kubeflow-component.mmd)) - Internal components
- [Data Flows](./kubeflow-dataflow.png) ([mmd](./kubeflow-dataflow.mmd)) - Request/response flows
- [Dependencies](./kubeflow-dependencies.png) ([mmd](./kubeflow-dependencies.mmd)) - Dependency graph

### For Architects
- [C4 Context](./kubeflow-c4-context.dsl) - System context in C4 format (Structurizr)

### For Security Teams
- [Security Network Diagram (PNG)](./kubeflow-security-network.png) - Network topology
- [Security Network Diagram (Mermaid)](./kubeflow-security-network.mmd) - Visual topology (editable)
- [Security Network Diagram (ASCII)](./kubeflow-security-network.txt) - Text format for SAR
- [RBAC Visualization](./kubeflow-rbac.png) ([mmd](./kubeflow-rbac.mmd)) - RBAC permissions

---

## KubeRay

Generated from: `architecture/rhoai-2.16/kuberay.md`

All Mermaid diagrams are available in both `.mmd` (source) and `.png` (3000px width, high-resolution) formats.

### For Developers
- [Component Structure](./kuberay-component.png) ([mmd](./kuberay-component.mmd)) - Internal components
- [Data Flows](./kuberay-dataflow.png) ([mmd](./kuberay-dataflow.mmd)) - Request/response flows
- [Dependencies](./kuberay-dependencies.png) ([mmd](./kuberay-dependencies.mmd)) - Dependency graph

### For Architects
- [C4 Context](./kuberay-c4-context.dsl) - System context in C4 format (Structurizr)

### For Security Teams
- [Security Network Diagram (PNG)](./kuberay-security-network.png) - Network topology
- [Security Network Diagram (Mermaid)](./kuberay-security-network.mmd) - Visual topology (editable)
- [Security Network Diagram (ASCII)](./kuberay-security-network.txt) - Text format for SAR
- [RBAC Visualization](./kuberay-rbac.png) ([mmd](./kuberay-rbac.mmd)) - RBAC permissions

---

## CodeFlare Operator

Generated from: `architecture/rhoai-2.16/codeflare-operator.md`

All Mermaid diagrams are available in both `.mmd` (source) and `.png` (3000px width, high-resolution) formats.

### For Developers
- [Component Structure](./codeflare-operator-component.png) ([mmd](./codeflare-operator-component.mmd)) - Internal components, CRDs watched, resources created
- [Data Flows](./codeflare-operator-dataflow.png) ([mmd](./codeflare-operator-dataflow.mmd)) - RayCluster creation, dashboard access, metrics collection
- [Dependencies](./codeflare-operator-dependencies.png) ([mmd](./codeflare-operator-dependencies.mmd)) - KubeRay, Kueue, and ODH integrations

### For Architects
- [C4 Context](./codeflare-operator-c4-context.dsl) - System context in C4 format (Structurizr)
- [Component Overview](./codeflare-operator-component.png) ([mmd](./codeflare-operator-component.mmd)) - High-level component view

### For Security Teams
- [Security Network Diagram (PNG)](./codeflare-operator-security-network.png) - Network topology with trust boundaries
- [Security Network Diagram (Mermaid)](./codeflare-operator-security-network.mmd) - Visual topology (editable)
- [Security Network Diagram (ASCII)](./codeflare-operator-security-network.txt) - Text format for SAR with RBAC, NetworkPolicy, Secrets
- [RBAC Visualization](./codeflare-operator-rbac.png) ([mmd](./codeflare-operator-rbac.mmd)) - RBAC permissions for operator and OAuth proxy

**Key Features**:
- **RayCluster Enhancement**: Integrates with KubeRay to add OAuth-secured dashboards, mTLS, and network isolation
- **AppWrapper Controller**: Batch job scheduling with Kueue integration (conditionally enabled)
- **Multi-Platform**: OpenShift (OAuth, Routes) and vanilla Kubernetes (Ingress)
- **Security**: Automatic NetworkPolicies, configurable mTLS, OAuth proxy on OpenShift
- **Admission Control**: Mutating and validating webhooks for RayCluster and AppWrapper

**Known Limitations**:
- OAuth dashboard access only on OpenShift (vanilla K8s has NO auth by default)
- AppWrapper controller requires Kueue at startup
- Ray cluster certificates do not auto-rotate

---

## Model Registry Operator

Generated from: `architecture/rhoai-2.16/model-registry-operator.md`

All Mermaid diagrams are available in both `.mmd` (source) and `.png` (3000px width, high-resolution) formats.

### For Developers
- [Component Structure](./model-registry-operator-component.png) ([mmd](./model-registry-operator-component.mmd)) - Operator components and deployed Model Registry instances
- [Data Flows](./model-registry-operator-dataflow.png) ([mmd](./model-registry-operator-dataflow.mmd)) - CR creation, deployment flows, and API access patterns
- [Dependencies](./model-registry-operator-dependencies.png) ([mmd](./model-registry-operator-dependencies.mmd)) - Database backends, Istio, Authorino dependencies

### For Architects
- [C4 Context](./model-registry-operator-c4-context.dsl) - System context in C4 format (Structurizr)
- [Component Overview](./model-registry-operator-component.png) ([mmd](./model-registry-operator-component.mmd)) - High-level component view

### For Security Teams
- [Security Network Diagram (PNG)](./model-registry-operator-security-network.png) - Network topology with Istio integration
- [Security Network Diagram (Mermaid)](./model-registry-operator-security-network.mmd) - Visual topology (editable)
- [Security Network Diagram (ASCII)](./model-registry-operator-security-network.txt) - Text format for SAR with RBAC and secrets
- [RBAC Visualization](./model-registry-operator-rbac.png) ([mmd](./model-registry-operator-rbac.mmd)) - Operator RBAC and per-registry user roles

**Key Features**:
- **Model Metadata Management**: Deploys Model Registry services for ML model versioning and tracking
- **Dual API Support**: Both REST (8080/TCP) and gRPC (9090/TCP) APIs for model metadata operations
- **Flexible Deployment Modes**: Plain Kubernetes, Istio service mesh with mTLS, or Authorino-based auth
- **Database Backend**: Supports PostgreSQL or MySQL for persistent metadata storage
- **Gateway Integration**: Automatic Istio Gateway and OpenShift Route configuration for external access
- **External Authorization**: Optional integration with Authorino for JWT validation and K8s RBAC checks

**Known Limitations**:
- Database schema upgrades require manual configuration via `enable_database_upgrade` flag
- No built-in multi-tenancy (each ModelRegistry CR creates a separate deployment)
- No built-in high availability (single replica deployment)
- Only PostgreSQL and MySQL supported as database backends
- Istio/Service Mesh required for gateway and external auth features
- TLS certificates for gateways must be manually provisioned or managed by external cert-manager

---

## ModelMesh Serving

Generated from: `architecture/rhoai-2.16/modelmesh-serving.md`

All Mermaid diagrams are available in both `.mmd` (source) and `.png` (3000px width, high-resolution) formats.

### For Developers
- [Component Structure](./modelmesh-serving-component.png) ([mmd](./modelmesh-serving-component.mmd)) - Internal architecture with controller, serving pods, and ModelMesh components
- [Data Flows](./modelmesh-serving-dataflow.png) ([mmd](./modelmesh-serving-dataflow.mmd)) - Model deployment and inference request flows (gRPC and REST)
- [Dependencies](./modelmesh-serving-dependencies.png) ([mmd](./modelmesh-serving-dependencies.mmd)) - External dependencies, container images, and ODH integrations

### For Architects
- [C4 Context](./modelmesh-serving-c4-context.dsl) - System context in C4 format (Structurizr)
- [Component Overview](./modelmesh-serving-component.png) ([mmd](./modelmesh-serving-component.mmd)) - High-level component view

### For Security Teams
- [Security Network Diagram (PNG)](./modelmesh-serving-security-network.png) - Network topology with etcd coordination
- [Security Network Diagram (Mermaid)](./modelmesh-serving-security-network.mmd) - Visual topology (editable)
- [Security Network Diagram (ASCII)](./modelmesh-serving-security-network.txt) - Text format for SAR with detailed RBAC, Service Mesh config, and secrets
- [RBAC Visualization](./modelmesh-serving-rbac.png) ([mmd](./modelmesh-serving-rbac.mmd)) - Controller RBAC and user-facing roles

**Key Features**:
- **High-Density Model Serving**: Optimized for serving many models with frequent loading/unloading
- **Multi-Framework Support**: Triton, MLServer, OpenVINO, TorchServe via runtime adapter pattern
- **Dual Protocol Support**: Both gRPC (8033/TCP) and REST (8008/TCP) inference endpoints with KServe V2 API
- **etcd Coordination**: Distributed state management and model registry for multi-pod coordination
- **Model Placement**: Intelligent model routing and placement optimization across serving pods
- **Storage Integration**: S3-compatible storage for model artifact retrieval via runtime adapter/puller
- **Multi-Container Architecture**: ModelMesh (Java), REST Proxy (Go), Runtime Adapter/Puller (Go), ML Framework containers
- **Optional mTLS/TLS**: Service mesh integration for secure communication and authorization

**Architecture Highlights**:
- **Controller**: modelmesh-controller reconciles Predictor, ServingRuntime, ClusterServingRuntime CRs
- **Serving Runtime Pods**: Multi-container pods with ModelMesh, REST Proxy, Runtime Adapter, and ML framework
- **Network Flow**: Client → Istio Gateway (443/TCP TLS 1.3) → ModelMesh Service (8033 gRPC or 8008 REST) → ModelMesh → Runtime Adapter → ML Framework
- **Coordination**: ModelMesh ↔ etcd (2379/TCP) for distributed state and model registry
- **Model Loading**: Runtime Adapter → S3 Storage (443/TCP HTTPS) for model artifact download
- **Metrics**: Controller metrics (8443/TCP HTTPS OAuth), Runtime metrics (2112/TCP HTTP)

**Known Limitations**:
- Requires etcd cluster for distributed coordination (external dependency)
- Optional InferenceService CR support (controlled by ENABLE_ISVC_WATCH environment variable)
- No built-in high availability for etcd (must be provisioned externally)
- Model placement decisions are opaque (no user control over which pod serves which model)
- Runtime adapter does not support all storage backends (primarily S3-compatible)

---

## Notebooks (Workbench Images)

Generated from: `architecture/rhoai-2.16/notebooks.md`

All Mermaid diagrams are available in both `.mmd` (source) and `.png` (3000px width, high-resolution) formats.

### For Developers
- [Component Structure](./notebooks-component.png) ([mmd](./notebooks-component.mmd)) - Image variants, layering, manifests, and deployment architecture
- [Data Flows](./notebooks-dataflow.png) ([mmd](./notebooks-dataflow.mmd)) - User access, pipeline submission, package installation, S3 storage, model operations
- [Dependencies](./notebooks-dependencies.png) ([mmd](./notebooks-dependencies.mmd)) - External libraries, ODH components, and service integrations

### For Architects
- [C4 Context](./notebooks-c4-context.dsl) - System context in C4 format (Structurizr)
- [Component Overview](./notebooks-component.png) ([mmd](./notebooks-component.mmd)) - High-level component view with image variants and deployment flow

### For Security Teams
- [Security Network Diagram (PNG)](./notebooks-security-network.png) - High-resolution network topology with trust boundaries
- [Security Network Diagram (Mermaid)](./notebooks-security-network.mmd) - Visual network topology (editable)
- [Security Network Diagram (ASCII)](./notebooks-security-network.txt) - Text format for SAR with detailed RBAC, secrets, and security hardening
- [RBAC Visualization](./notebooks-rbac.png) ([mmd](./notebooks-rbac.mmd)) - RBAC managed by Notebook Controller

**Key Features**:
- **Multiple Image Variants**: Jupyter (Minimal, Data Science, PyTorch, TensorFlow, TrustAI), Code Server, RStudio
- **GPU Support**: NVIDIA CUDA, AMD ROCm, Intel oneAPI for accelerated workloads
- **Python Versions**: 3.9 and 3.11 across multiple base OS variants (UBI9, RHEL9, CentOS Stream 9)
- **Version Management**: ImageStreams maintain N to N-4 versions for compatibility and rollback
- **Elyra Integration**: Pre-configured for Data Science Pipelines workflow authoring
- **OAuth Security**: Automatic OAuth proxy sidecar for secure user authentication
- **Runtime Images**: Lightweight variants (no IDE) for pipeline execution
- **Customization**: Users can install packages at runtime (persistent via PVC)

**Deployment Model**:
1. User selects workbench image from ODH Dashboard
2. Dashboard reads ImageStream metadata and annotations
3. Notebook Controller creates StatefulSet with selected image
4. OAuth proxy sidecar provides TLS termination and authentication
5. JupyterLab container runs on port 8888 (internal only)
6. OpenShift Route exposes workbench via HTTPS/443

**Integration Points**:
- Data Science Pipelines (submit runs via Elyra)
- Model Registry (register trained models)
- KServe (deploy models for inference)
- S3 Storage (persist notebooks and data)
- PyPI (install packages at runtime)

**Known Characteristics**:
- No standalone deployment (images deployed by Notebook Controller when users create workbenches)
- No ClusterRoles/RoleBindings in repository (RBAC managed by Notebook Controller at runtime)
- RStudio requires in-cluster builds (BuildConfig) due to licensing requirements
- Images signed and scanned (Red Hat GPG signature, Quay Security Scanner)
- Automated digest updates via GitHub Actions when new builds available
- RHOAI fork with RHEL-based images (distinct from upstream ODH CentOS/community images)

---

## ODH Model Controller

Generated from: `architecture/rhoai-2.16/odh-model-controller.md`

All Mermaid diagrams are available in both `.mmd` (source) and `.png` (3000px width, high-resolution) formats.

### For Developers
- [Component Structure](./odh-model-controller-component.png) ([mmd](./odh-model-controller-component.mmd)) - Internal components, reconcilers, and webhooks
- [Data Flows](./odh-model-controller-dataflow.png) ([mmd](./odh-model-controller-dataflow.mmd)) - InferenceService creation, NIM provisioning, storage configuration, and metrics flows
- [Dependencies](./odh-model-controller-dependencies.png) ([mmd](./odh-model-controller-dependencies.mmd)) - KServe, Istio, Knative, and ODH integrations

### For Architects
- [C4 Context](./odh-model-controller-c4-context.dsl) - System context in C4 format (Structurizr)
- [Component Overview](./odh-model-controller-component.png) ([mmd](./odh-model-controller-component.mmd)) - High-level component view with mode-specific reconcilers

### For Security Teams
- [Security Network Diagram (PNG)](./odh-model-controller-security-network.png) - High-resolution network topology with trust boundaries
- [Security Network Diagram (Mermaid)](./odh-model-controller-security-network.mmd) - Visual network topology (editable)
- [Security Network Diagram (ASCII)](./odh-model-controller-security-network.txt) - Precise text format for SAR submissions with complete RBAC, secrets, and trust boundary details
- [RBAC Visualization](./odh-model-controller-rbac.png) ([mmd](./odh-model-controller-rbac.mmd)) - RBAC permissions for controller and Prometheus

**Key Features**:
- **Multi-mode Support**: KServe Serverless, KServe Raw, and ModelMesh deployment modes
- **OpenShift Integration**: Automatic Route creation, service-ca certificate injection
- **Service Mesh**: Istio Gateway, VirtualService, PeerAuthentication management
- **Authentication**: Authorino AuthConfig creation for token-based auth
- **NVIDIA NIM**: NIM Account CRD for NVIDIA proprietary model deployments
- **Storage Aggregation**: Unified storage-config secret from multiple data connections
- **Monitoring**: Automatic Prometheus RoleBinding creation

**Architecture Highlights**:
- **InferenceService Controller**: Main reconciler that delegates to mode-specific sub-reconcilers
- **Mode-Specific Reconcilers**:
  - ModelMesh Reconciler: Routes, ServiceAccounts, ClusterRoleBindings
  - KServe Serverless Reconciler: Istio resources, AuthConfigs, NetworkPolicies
  - KServe Raw Reconciler: Routes for non-mesh deployments
- **Supporting Controllers**: NIM Account, Storage Secret, CA Cert, Monitoring, Model Registry
- **Webhooks**: Knative Service and NIM Account validation

**Dependencies**:
- **Required**: Kubernetes 1.29+, KServe 0.12.1, OpenShift Routes 3.9.0+
- **Conditional**: Istio 1.21.5, Knative Serving 0.39.3, Authorino 0.15.0 (for Serverless), ModelMesh (for multi-model)
- **Optional**: Prometheus Operator 0.64.1, Model Registry 0.1.1

**Known Limitations**:
- Service Mesh Dependency: KServe Serverless mode requires Istio/Maistra service mesh
- OpenShift-Specific: Routes and service-ca integration are OpenShift-specific
- Single Controller Instance: Leader election ensures only one active controller
- Secret Label Convention: Storage secret reconciliation depends on specific labels set by ODH Dashboard
- NGC API Dependency: NIM account validation requires outbound access to NVIDIA NGC API

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
/generate-architecture-diagrams --architecture=../kserve.md
```

## Diagram Descriptions

### Component Structure (kserve-component.mmd)
Shows the internal architecture of KServe including:
- KServe Controller Manager and Webhook Server
- Model serving infrastructure (storage-initializer, agent, router, inference servers)
- Custom Resource Definitions (InferenceService, ServingRuntime, TrainedModel, InferenceGraph)
- External dependencies (Istio, Knative, cert-manager)
- Internal ODH dependencies (Model Registry, S3 Storage)

### Data Flows (kserve-dataflow.mmd)
Sequence diagrams showing:
- **Flow 1**: Model deployment in serverless mode
- **Flow 2**: Inference request from external client through Istio Gateway
- **Flow 3**: Request logging to external endpoints
- **Flow 4**: Multi-model inference graph orchestration

### Security Network Diagram (kserve-security-network.txt/.mmd)
Detailed network topology with:
- Trust zones (External, Ingress DMZ, Service Mesh, Control Plane, External Services)
- Exact port numbers and protocols
- Encryption methods (TLS 1.3, TLS 1.2+, mTLS)
- Authentication mechanisms (Bearer tokens, AWS IAM, mTLS certificates)
- RBAC summary, Service Mesh configuration, Secrets, Network Policies
- Available in both ASCII (precise, for SAR documentation) and Mermaid (visual, for presentations)

### C4 Context Diagram (kserve-c4-context.dsl)
Architectural context showing:
- User personas (Data Scientist, External Client)
- KServe system containers
- External dependencies (Kubernetes, Istio, Knative, cert-manager)
- Internal ODH dependencies (Model Registry, Service Mesh)
- External services (S3, GCS, Azure, Prometheus)
- Interaction flows and protocols

### Dependencies (kserve-dependencies.mmd)
Dependency graph showing:
- External dependencies (Kubernetes, Knative, Istio, cert-manager)
- Internal ODH dependencies (Service Mesh, Model Registry)
- External storage services (S3, GCS, Azure)
- ODH component integrations (Dashboard, Pipelines, Workbench)
- Monitoring and observability (Prometheus, OpenTelemetry)

### RBAC Visualization (kserve-rbac.mmd)
RBAC permissions showing:
- Service Account: kserve-controller-manager
- ClusterRole: kserve-manager-role with full permissions on KServe CRDs
- Permissions on Knative Services, Istio VirtualServices, Deployments, etc.
- Leader election role for high availability
- Read-only access to Secrets and Namespaces

---

## TrustyAI Service Operator

Generated from: `architecture/rhoai-2.16/trustyai-service-operator.md`

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

**Architecture Summary**:

**TrustyAI Service Operator** is a Kubernetes operator that manages TrustyAI services for ML model explainability, fairness monitoring, and language model evaluation. It provides:

- **Primary CRs**: TrustyAIService (ML explainability/fairness), LMEvalJob (language model evaluation)
- **Model Monitoring**: Integration with KServe and ModelMesh for inference payload interception
- **Storage Options**: PVC-based or database-backed (PostgreSQL/MySQL) storage
- **External Access**: OpenShift Routes with OAuth proxy for secure API access
- **Metrics**: Prometheus integration for fairness metrics (SPD, DIR) and custom metrics
- **Service Mesh**: Istio integration for mTLS and traffic management
- **LM Evaluation**: Batch job execution for language model evaluation using lm-evaluation-harness

**Key Features**:
- **Dual Capability**: Both model monitoring (TrustyAI Service) and LM evaluation (LMEvalJob)
- **KServe/ModelMesh Integration**: Automatic payload processor injection for inference monitoring
- **Flexible Storage**: Supports both PVC and database backends
- **OAuth Security**: OpenShift OAuth proxy for external API access
- **Fairness Metrics**: Statistical Parity Difference (SPD) and Disparate Impact Ratio (DIR)
- **Explainability**: Model prediction explainability features
- **Job Queue Support**: Kueue integration for LMEvalJob management
- **Hugging Face Integration**: Automatic model and dataset downloads for LM evaluation

**Data Flows**:
1. **Model Inference Monitoring**: Client → KServe → ModelMesh → TrustyAI Service → Database/PVC
2. **External API Access**: External Client → OpenShift Route → OAuth Proxy → TrustyAI Service
3. **LMEvalJob Execution**: Operator → LMEvalJob Pod → Hugging Face Hub → PVC Storage
4. **Metrics Collection**: Prometheus → ServiceMonitor → TrustyAI Service /q/metrics

**Troubleshooting**:
```bash
# View operator logs
oc logs -n {operator-namespace} deployment/trustyai-operator-controller-manager

# Check TrustyAIService status
oc get trustyaiservice -n {namespace} -o yaml

# Check LMEvalJob status
oc get lmevaljob -n {namespace} -o yaml

# View TrustyAI service logs
oc logs -n {namespace} deployment/{instance-name}

# Check OAuth proxy logs
oc logs -n {namespace} deployment/{instance-name} -c oauth-proxy

# View metrics endpoint
oc port-forward -n {namespace} svc/{instance-name} 8080:80
curl http://localhost:8080/q/metrics
```

**Storage Configuration**:
```yaml
# PVC-based storage
apiVersion: trustyai.opendatahub.io/v1alpha1
kind: TrustyAIService
metadata:
  name: trustyai-service
spec:
  storage:
    format: "PVC"
    size: "1Gi"

# Database storage
apiVersion: trustyai.opendatahub.io/v1alpha1
kind: TrustyAIService
metadata:
  name: trustyai-service
spec:
  storage:
    format: "DATABASE"
    databaseConfigurations: "database-credentials-secret"
```

**LMEvalJob Example**:
```yaml
apiVersion: trustyai.opendatahub.io/v1alpha1
kind: LMEvalJob
metadata:
  name: eval-llama-model
spec:
  model: "huggingface/llama-2-7b"
  tasks:
    - name: "hellaswag"
    - name: "arc_easy"
  batchSize: 8
  logSamples: true
```

---

## How to Use Diagrams

### PNG Files (.png files)
**Automatically generated** at 3000px width for high-resolution presentations and documentation.

- **Ready to use**: High-resolution images suitable for presentations, wikis, and documentation
- **Width**: 3000px (height auto-adjusts to content)
- **Use directly**: Include in PowerPoint, Google Slides, Confluence, etc.

### Mermaid Source Files (.mmd files)
- **In GitHub/GitLab**: Paste into markdown with ```mermaid code blocks - renders automatically!
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

To regenerate diagrams after architecture changes, use the Python script:

```bash
# Regenerate all diagrams in the directory
python scripts/generate_diagram_pngs.py architecture/rhoai-2.16/diagrams --width=3000

# Force regeneration (ignore timestamps)
python scripts/generate_diagram_pngs.py architecture/rhoai-2.16/diagrams --width=3000 --force
```

Or manually for specific components:
```bash
cd architecture/rhoai-2.16/diagrams
PUPPETEER_EXECUTABLE_PATH=/usr/bin/google-chrome mmdc -i trustyai-service-operator-component.mmd -o trustyai-service-operator-component.png -w 3000
```
