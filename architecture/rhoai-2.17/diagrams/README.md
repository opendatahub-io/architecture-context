# Architecture Diagrams for RHOAI 2.17 Components

Generated from architecture files in `architecture/rhoai-2.17/`
Date: 2026-03-16

**Note**: Diagram filenames use base component name without version (directory is already versioned).

## Available Components

This directory contains architecture diagrams for the following RHOAI 2.17 components:

- **CodeFlare Operator** - Manages distributed AI/ML workloads and batch scheduling
- **Data Science Pipelines Operator** - Manages lifecycle of Kubeflow Pipelines instances
- **KServe** - Model serving platform for standardized serverless inference
- **Kubeflow** - ML workflow orchestration and pipeline management
- **KubeRay** - Ray cluster lifecycle management for distributed computing
- **Kueue** - Job queueing and resource quota management
- **ModelMesh Serving** - Multi-model serving for high-density deployments
- **Model Registry Operator** - ML model metadata and version management
- **Notebooks** - Jupyter notebook environments for data science
- **ODH Dashboard** - Central UI for Open Data Hub components
- **ODH Model Controller** - Model deployment and serving controller
- **RHODS Operator** - Red Hat OpenShift Data Science operator
- **Training Operator** - Distributed ML training job management
- **TrustyAI Service Operator** - AI explainability and fairness monitoring

---

## Diagram Types

All Mermaid diagrams are available in both `.mmd` (source) and `.png` (3000px width, high-resolution) formats.

### For Developers
- **Component Structure** - Mermaid diagram showing internal components and relationships
- **Data Flows** - Sequence diagram of request/response flows with technical details
- **Dependencies** - Component dependency graph showing external and internal dependencies

### For Architects
- **C4 Context** - System context in C4 format (Structurizr DSL)
- **Component Overview** - High-level component view with integrations

### For Security Teams
- **Security Network Diagram (PNG)** - High-resolution network topology visualization
- **Security Network Diagram (Mermaid)** - Visual network topology (editable)
- **Security Network Diagram (ASCII)** - Precise text format for SAR submissions
- **RBAC Visualization** - RBAC permissions and bindings

---

## CodeFlare Operator Diagrams

Generated from: `architecture/rhoai-2.17/codeflare-operator.md`

### For Developers
- [Component Structure](./codeflare-operator-component.png) ([mmd](./codeflare-operator-component.mmd)) - Operator manager, controllers, webhooks, and resource creation
- [Data Flows](./codeflare-operator-dataflow.png) ([mmd](./codeflare-operator-dataflow.mmd)) - RayCluster creation, dashboard access with OAuth, AppWrapper orchestration
- [Dependencies](./codeflare-operator-dependencies.png) ([mmd](./codeflare-operator-dependencies.mmd)) - KubeRay, Kueue, and platform dependencies

### For Architects
- [C4 Context](./codeflare-operator-c4-context.dsl) - System context in C4 format (Structurizr)

### For Security Teams
- [Security Network Diagram (PNG)](./codeflare-operator-security-network.png) - High-resolution network topology with trust boundaries
- [Security Network Diagram (Mermaid)](./codeflare-operator-security-network.mmd) - Visual network topology (editable)
- [Security Network Diagram (ASCII)](./codeflare-operator-security-network.txt) - Precise text format for SAR submissions with network policies and RBAC
- [RBAC Visualization](./codeflare-operator-rbac.png) ([mmd](./codeflare-operator-rbac.mmd)) - Service accounts, ClusterRoles, permissions for operator and OAuth proxies

### Key Features
- **OAuth-Secured Ray Dashboard (OpenShift)**: Automatic OAuth proxy sidecar with OpenShift authentication for external dashboard access
- **mTLS for Ray Client API**: Optional mutual TLS encryption using cluster-specific CA certificates (1-year validity)
- **Gang Scheduling with AppWrapper**: Multi-resource workload units (RayClusters, Jobs, Deployments) integrated with Kueue for resource quota management
- **Network Isolation**: NetworkPolicies enforce strict ingress rules for Ray head (same cluster + namespace + KubeRay + monitoring) and worker pods (same cluster only)
- **Admission Control**: Mutating and validating webhooks for RayCluster and AppWrapper resources
- **Platform-Aware**: Auto-detects OpenShift (Routes + OAuth) vs vanilla Kubernetes (Ingress), reads DSCInitialization for namespace configuration

---

## Data Science Pipelines Operator Diagrams

Generated from: `architecture/rhoai-2.17/data-science-pipelines-operator.md`

### For Developers
- [Component Structure](./data-science-pipelines-operator-component.png) ([mmd](./data-science-pipelines-operator-component.mmd)) - Internal components and lifecycle management
- [Data Flows](./data-science-pipelines-operator-dataflow.png) ([mmd](./data-science-pipelines-operator-dataflow.mmd)) - Pipeline submission and execution flows
- [Dependencies](./data-science-pipelines-operator-dependencies.png) ([mmd](./data-science-pipelines-operator-dependencies.mmd)) - External and internal dependencies

### For Architects
- [C4 Context](./data-science-pipelines-operator-c4-context.dsl) - System context in C4 format (Structurizr)

### For Security Teams
- [Security Network Diagram (PNG)](./data-science-pipelines-operator-security-network.png) - High-resolution network topology
- [Security Network Diagram (Mermaid)](./data-science-pipelines-operator-security-network.mmd) - Visual network topology (editable)
- [Security Network Diagram (ASCII)](./data-science-pipelines-operator-security-network.txt) - Precise text format for SAR submissions
- [RBAC Visualization](./data-science-pipelines-operator-rbac.png) ([mmd](./data-science-pipelines-operator-rbac.mmd)) - RBAC permissions and bindings

---

## KubeRay Operator Diagrams

Generated from: `architecture/rhoai-2.17/kuberay.md`

### For Developers
- [Component Structure](./kuberay-component.png) ([mmd](./kuberay-component.mmd)) - Operator and Ray cluster architecture
- [Data Flows](./kuberay-dataflow.png) ([mmd](./kuberay-dataflow.mmd)) - Cluster creation, job submission, and monitoring flows
- [Dependencies](./kuberay-dependencies.png) ([mmd](./kuberay-dependencies.mmd)) - External and internal dependencies

### For Architects
- [C4 Context](./kuberay-c4-context.dsl) - System context in C4 format (Structurizr)

### For Security Teams
- [Security Network Diagram (PNG)](./kuberay-security-network.png) - High-resolution network topology
- [Security Network Diagram (Mermaid)](./kuberay-security-network.mmd) - Visual network topology (editable)
- [Security Network Diagram (ASCII)](./kuberay-security-network.txt) - Precise text format for SAR submissions
- [RBAC Visualization](./kuberay-rbac.png) ([mmd](./kuberay-rbac.mmd)) - RBAC permissions and bindings

---

## KServe Diagrams

Generated from: `architecture/rhoai-2.17/kserve.md`

### For Developers
- [Component Structure](./kserve-component.png) ([mmd](./kserve-component.mmd)) - Control plane (controller, webhook) and data plane (model servers, agent, router)
- [Data Flows](./kserve-dataflow.png) ([mmd](./kserve-dataflow.mmd)) - Model deployment, inference requests (serverless + Istio), InferenceGraph routing
- [Dependencies](./kserve-dependencies.png) ([mmd](./kserve-dependencies.mmd)) - External (Knative, Istio, cert-manager) and internal (ODH) dependencies

### For Architects
- [C4 Context](./kserve-c4-context.dsl) - System context in C4 format (Structurizr)

### For Security Teams
- [Security Network Diagram (PNG)](./kserve-security-network.png) - High-resolution network topology with trust zones
- [Security Network Diagram (Mermaid)](./kserve-security-network.mmd) - Visual network topology (editable)
- [Security Network Diagram (ASCII)](./kserve-security-network.txt) - Precise text format for SAR submissions with RBAC, secrets, mTLS
- [RBAC Visualization](./kserve-rbac.png) ([mmd](./kserve-rbac.mmd)) - Service accounts, ClusterRoles, permissions matrix

### Key Features
- **Model Serving**: Supports 12+ ML frameworks (sklearn, XGBoost, TensorFlow, PyTorch, Hugging Face, ONNX, Triton)
- **Protocols**: V1/V2 Inference Protocol, OpenAI-compatible API for LLMs
- **Autoscaling**: Serverless (Knative) with scale-to-zero, RawDeployment (HPA), ModelMesh (high-density)
- **Advanced Features**: InferenceGraph (multi-model pipelines), transformers, explainers (ART, AIF360)
- **Security**: Istio mTLS, optional JWT auth (Authorino), TLS 1.3 ingress, cert-manager integration

---

## Kubeflow (ODH Notebook Controller) Diagrams

Generated from: `architecture/rhoai-2.17/kubeflow.md`

### For Developers
- [Component Structure](./kubeflow-component.png) ([mmd](./kubeflow-component.mmd)) - ODH controller, webhook, metrics, and integration with Kubeflow
- [Data Flows](./kubeflow-dataflow.png) ([mmd](./kubeflow-dataflow.mmd)) - OAuth injection, user access flows, and reconciliation loops
- [Dependencies](./kubeflow-dependencies.png) ([mmd](./kubeflow-dependencies.mmd)) - OpenShift APIs, Kubeflow integration, and optional dependencies

### For Architects
- [C4 Context](./kubeflow-c4-context.dsl) - System context in C4 format (Structurizr)

### For Security Teams
- [Security Network Diagram (PNG)](./kubeflow-security-network.png) - High-resolution network topology with trust zones
- [Security Network Diagram (Mermaid)](./kubeflow-security-network.mmd) - Visual network topology (editable)
- [Security Network Diagram (ASCII)](./kubeflow-security-network.txt) - Precise text format for SAR submissions with RBAC, secrets, OAuth flows
- [RBAC Visualization](./kubeflow-rbac.png) ([mmd](./kubeflow-rbac.mmd)) - Service accounts, ClusterRoles, RoleBindings, and permissions

### Key Features
- **OAuth Proxy Injection**: Mutating webhook automatically injects OAuth proxy sidecar for authentication/authorization
- **Route Management**: Automatic TLS-enabled Routes via OpenShift ingress controller
- **Network Policies**: Pod-level network segmentation (ctrl-np restricts notebook port, oauth-np allows OAuth proxy)
- **RBAC Integration**: SubjectAccessReview-based authorization (users must have GET permission on Notebook resource)
- **Service Mesh Support**: Detects service-mesh annotation and skips OAuth NetworkPolicy creation
- **Pipeline Integration**: Optional RoleBinding to DSPA for Elyra pipeline execution
- **Automatic TLS**: Service CA Operator provisions certificates for webhook and OAuth services
- **Multiple Access Modes**: OAuth-protected access or direct access (configurable via annotation)

---

## Kueue Diagrams

Generated from: `architecture/rhoai-2.17/kueue.md`

### For Developers
- [Component Structure](./kueue-component.png) ([mmd](./kueue-component.mmd)) - Internal components, controllers, and job framework integrations
- [Data Flows](./kueue-dataflow.png) ([mmd](./kueue-dataflow.mmd)) - Job submission, workload admission, metrics collection, visibility API, and multi-cluster flows
- [Dependencies](./kueue-dependencies.png) ([mmd](./kueue-dependencies.mmd)) - Integrations with Training Operator, KubeRay, CodeFlare, and job frameworks

### For Architects
- [C4 Context](./kueue-c4-context.dsl) - System context in C4 format (Structurizr)

### For Security Teams
- [Security Network Diagram (PNG)](./kueue-security-network.png) - High-resolution network topology with trust zones and authentication
- [Security Network Diagram (Mermaid)](./kueue-security-network.mmd) - Visual network topology (editable)
- [Security Network Diagram (ASCII)](./kueue-security-network.txt) - Precise text format for SAR submissions
- [RBAC Visualization](./kueue-rbac.png) ([mmd](./kueue-rbac.mmd)) - RBAC permissions and bindings for ClusterRole manager-role

### Key Features
- **Fair Resource Sharing**: ClusterQueues and LocalQueues for multi-tenant workload scheduling
- **Queueing Strategies**: StrictFIFO, BestEffortFIFO with priority-based scheduling and preemption
- **Multi-Framework Support**: Batch, Kubeflow (TFJob, PyTorchJob, MPIJob, XGBoost, MXNet, PaddlePaddle), Ray, JobSet, AppWrapper, Pods
- **Admission Checks**: External validation before workload admission
- **Multi-Cluster**: Job distribution via MultiKueue to remote Kubernetes clusters
- **Auto-Scaling**: Integration with cluster-autoscaler via ProvisioningRequests
- **Comprehensive Metrics**: Queue depth, resource usage, admission latency, and performance monitoring
- **Components**: Controller Manager (reconciles queues/workloads), Webhook Server (validates jobs), Visibility API (query pending workloads)

---

## ModelMesh Serving Diagrams

Generated from: `architecture/rhoai-2.17/modelmesh-serving.md`

### For Developers
- [Component Structure](./modelmesh-serving-component.png) ([mmd](./modelmesh-serving-component.mmd)) - Operator, webhook, runtime pod architecture with multi-container deployment
- [Data Flows](./modelmesh-serving-dataflow.png) ([mmd](./modelmesh-serving-dataflow.mmd)) - Model deployment, gRPC/REST inference flows, metrics collection, state synchronization
- [Dependencies](./modelmesh-serving-dependencies.png) ([mmd](./modelmesh-serving-dependencies.mmd)) - External (etcd, S3, Kubernetes) and internal (KServe, Service Mesh) dependencies

### For Architects
- [C4 Context](./modelmesh-serving-c4-context.dsl) - System context in C4 format (Structurizr)

### For Security Teams
- [Security Network Diagram (PNG)](./modelmesh-serving-security-network.png) - High-resolution network topology with trust boundaries
- [Security Network Diagram (Mermaid)](./modelmesh-serving-security-network.mmd) - Visual network topology (editable)
- [Security Network Diagram (ASCII)](./modelmesh-serving-security-network.txt) - Precise text format for SAR submissions with RBAC, NetworkPolicies, secrets
- [RBAC Visualization](./modelmesh-serving-rbac.png) ([mmd](./modelmesh-serving-rbac.mmd)) - Service accounts, ClusterRoles, permissions for controller and runtime pods

### Key Features
- **Multi-Model Serving**: High-density model serving with intelligent placement and loading/unloading
- **Runtime Flexibility**: Supports Triton, MLServer, OpenVINO Model Server, TorchServe
- **Dual Protocol Support**: KServe V2 gRPC inference (8033/TCP) and REST (8008/TCP via REST proxy)
- **Distributed State Management**: etcd-based coordination for model assignments and cluster membership
- **Storage Integration**: S3-compatible storage (AWS S3, MinIO, IBM COS) for model artifacts
- **Multi-Container Architecture**: ModelMesh router (Java), runtime adapter, REST proxy, model server, storage helper init container
- **Optional Service Mesh**: Istio/OpenShift Service Mesh integration for mTLS and AuthorizationPolicy
- **Webhook Validation**: ValidatingWebhookConfiguration for ServingRuntime/ClusterServingRuntime resources
- **Network Isolation**: NetworkPolicies for controller (metrics/webhook) and runtime pods (inference/internal communication)

---

## Model Registry Operator Diagrams

Generated from: `architecture/rhoai-2.17/model-registry-operator.md`

### For Developers
- [Component Structure](./model-registry-operator-component.png) ([mmd](./model-registry-operator-component.mmd)) - Operator and model registry service architecture
- [Data Flows](./model-registry-operator-dataflow.png) ([mmd](./model-registry-operator-dataflow.mmd)) - Model registration, metadata queries, and lifecycle flows
- [Dependencies](./model-registry-operator-dependencies.png) ([mmd](./model-registry-operator-dependencies.mmd)) - External and internal dependencies

### For Architects
- [C4 Context](./model-registry-operator-c4-context.dsl) - System context in C4 format (Structurizr)

### For Security Teams
- [Security Network Diagram (PNG)](./model-registry-operator-security-network.png) - High-resolution network topology
- [Security Network Diagram (Mermaid)](./model-registry-operator-security-network.mmd) - Visual network topology (editable)
- [Security Network Diagram (ASCII)](./model-registry-operator-security-network.txt) - Precise text format for SAR submissions
- [RBAC Visualization](./model-registry-operator-rbac.png) ([mmd](./model-registry-operator-rbac.mmd)) - RBAC permissions and bindings

---

## Notebooks Diagrams

Generated from: `architecture/rhoai-2.17/notebooks.md`

### For Developers
- [Component Structure](./notebooks-component.png) ([mmd](./notebooks-component.mmd)) - Notebook controller and Jupyter environments
- [Data Flows](./notebooks-dataflow.png) ([mmd](./notebooks-dataflow.mmd)) - Notebook creation and access flows
- [Dependencies](./notebooks-dependencies.png) ([mmd](./notebooks-dependencies.mmd)) - External and internal dependencies

### For Architects
- [C4 Context](./notebooks-c4-context.dsl) - System context in C4 format (Structurizr)

### For Security Teams
- [Security Network Diagram (PNG)](./notebooks-security-network.png) - High-resolution network topology
- [Security Network Diagram (Mermaid)](./notebooks-security-network.mmd) - Visual network topology (editable)
- [Security Network Diagram (ASCII)](./notebooks-security-network.txt) - Precise text format for SAR submissions
- [RBAC Visualization](./notebooks-rbac.png) ([mmd](./notebooks-rbac.mmd)) - RBAC permissions and bindings

---

## ODH Dashboard Diagrams

Generated from: `architecture/rhoai-2.17/odh-dashboard.md`

### For Developers
- [Component Structure](./odh-dashboard-component.png) ([mmd](./odh-dashboard-component.mmd)) - Dashboard frontend and backend architecture
- [Data Flows](./odh-dashboard-dataflow.png) ([mmd](./odh-dashboard-dataflow.mmd)) - User authentication and API interaction flows
- [Dependencies](./odh-dashboard-dependencies.png) ([mmd](./odh-dashboard-dependencies.mmd)) - External and internal dependencies

### For Architects
- [C4 Context](./odh-dashboard-c4-context.dsl) - System context in C4 format (Structurizr)

### For Security Teams
- [Security Network Diagram (PNG)](./odh-dashboard-security-network.png) - High-resolution network topology
- [Security Network Diagram (Mermaid)](./odh-dashboard-security-network.mmd) - Visual network topology (editable)
- [Security Network Diagram (ASCII)](./odh-dashboard-security-network.txt) - Precise text format for SAR submissions
- [RBAC Visualization](./odh-dashboard-rbac.png) ([mmd](./odh-dashboard-rbac.mmd)) - RBAC permissions and bindings

---

## ODH Model Controller Diagrams

Generated from: `architecture/rhoai-2.17/odh-model-controller.md`

### For Developers
- [Component Structure](./odh-model-controller-component.png) ([mmd](./odh-model-controller-component.mmd)) - Model controller architecture
- [Data Flows](./odh-model-controller-dataflow.png) ([mmd](./odh-model-controller-dataflow.mmd)) - Model deployment flows
- [Dependencies](./odh-model-controller-dependencies.png) ([mmd](./odh-model-controller-dependencies.mmd)) - External and internal dependencies

### For Architects
- [C4 Context](./odh-model-controller-c4-context.dsl) - System context in C4 format (Structurizr)

### For Security Teams
- [Security Network Diagram (PNG)](./odh-model-controller-security-network.png) - High-resolution network topology
- [Security Network Diagram (Mermaid)](./odh-model-controller-security-network.mmd) - Visual network topology (editable)
- [Security Network Diagram (ASCII)](./odh-model-controller-security-network.txt) - Precise text format for SAR submissions
- [RBAC Visualization](./odh-model-controller-rbac.png) ([mmd](./odh-model-controller-rbac.mmd)) - RBAC permissions and bindings

---

## RHODS Operator Diagrams

Generated from: `architecture/rhoai-2.17/rhods-operator.md`

### For Developers
- [Component Structure](./rhods-operator-component.png) ([mmd](./rhods-operator-component.mmd)) - RHODS operator architecture
- [Data Flows](./rhods-operator-dataflow.png) ([mmd](./rhods-operator-dataflow.mmd)) - Platform lifecycle flows
- [Dependencies](./rhods-operator-dependencies.png) ([mmd](./rhods-operator-dependencies.mmd)) - External and internal dependencies

### For Architects
- [C4 Context](./rhods-operator-c4-context.dsl) - System context in C4 format (Structurizr)

### For Security Teams
- [Security Network Diagram (PNG)](./rhods-operator-security-network.png) - High-resolution network topology
- [Security Network Diagram (Mermaid)](./rhods-operator-security-network.mmd) - Visual network topology (editable)
- [Security Network Diagram (ASCII)](./rhods-operator-security-network.txt) - Precise text format for SAR submissions
- [RBAC Visualization](./rhods-operator-rbac.png) ([mmd](./rhods-operator-rbac.mmd)) - RBAC permissions and bindings

---

## Training Operator Diagrams

Generated from: `architecture/rhoai-2.17/training-operator.md`

### For Developers
- [Component Structure](./training-operator-component.png) ([mmd](./training-operator-component.mmd)) - Training operator architecture
- [Data Flows](./training-operator-dataflow.png) ([mmd](./training-operator-dataflow.mmd)) - Distributed training flows
- [Dependencies](./training-operator-dependencies.png) ([mmd](./training-operator-dependencies.mmd)) - External and internal dependencies

### For Architects
- [C4 Context](./training-operator-c4-context.dsl) - System context in C4 format (Structurizr)

### For Security Teams
- [Security Network Diagram (PNG)](./training-operator-security-network.png) - High-resolution network topology
- [Security Network Diagram (Mermaid)](./training-operator-security-network.mmd) - Visual network topology (editable)
- [Security Network Diagram (ASCII)](./training-operator-security-network.txt) - Precise text format for SAR submissions
- [RBAC Visualization](./training-operator-rbac.png) ([mmd](./training-operator-rbac.mmd)) - RBAC permissions and bindings

---

## Platform Diagrams (RHOAI 2.17 - Aggregate View)

Generated from: `architecture/rhoai-2.17/PLATFORM.md`

### Overview

Platform-level diagrams showing the complete RHOAI 2.17 ecosystem with all 14 integrated components:
- **rhods-operator**: Platform orchestration
- **odh-dashboard**: Web UI
- **odh-notebook-controller**: Notebook management
- **workbench-images**: Jupyter/RStudio/Code Server
- **kserve, modelmesh-serving, odh-model-controller**: Model serving
- **data-science-pipelines-operator, model-registry-operator**: ML pipelines & registry
- **kuberay, codeflare-operator, kueue**: Distributed computing
- **training-operator, trustyai-service-operator**: Training & AI trust

### For Developers
- [Component Structure](./platform-component.png) ([mmd](./platform-component.mmd)) - Complete RHOAI platform architecture with all 14 components and their relationships
- [Data Flows](./platform-dataflow.png) ([mmd](./platform-dataflow.mmd)) - End-to-end workflow: Data Science Project → Jupyter → Training → KServe → TrustyAI → Prometheus
- [Dependencies](./platform-dependencies.png) ([mmd](./platform-dependencies.mmd)) - Platform-wide dependency graph showing OpenShift services, service mesh, and external dependencies

### For Architects
- [C4 Context](./platform-c4-context.dsl) - Complete RHOAI platform in C4 format (Structurizr) with workflows and external integrations
- [Component Overview](./platform-component.png) - High-level view of 14 components organized by function (UI, Development, Model Serving, Pipelines, Distributed Computing, Training)

### For Security Teams
- [Security Network Diagram (PNG)](./platform-security-network.png) - High-resolution platform-wide network topology with all trust zones
- [Security Network Diagram (Mermaid)](./platform-security-network.mmd) - Visual platform network topology (editable)
- [Security Network Diagram (ASCII)](./platform-security-network.txt) - **Comprehensive SAR documentation** including:
  - Complete network topology (external → ingress → service mesh → egress)
  - RBAC summary for all 14 operators (ClusterRoles, permissions, verbs)
  - Service Mesh configuration (PeerAuthentication STRICT, AuthorizationPolicy, Gateway config)
  - Secrets inventory (40+ secrets: webhooks, OAuth, storage, databases, certificates, mTLS)
  - Network Policies for all namespaces
  - Compliance standards (FIPS, Pod Security, encryption)
- [RBAC Visualization](./platform-rbac.png) ([mmd](./platform-rbac.mmd)) - Platform-wide RBAC matrix showing all 8 primary operators and their permissions across 40+ CRDs

### Platform Statistics
- **Total Components**: 14 (1 platform operator + 13 specialized operators/services)
- **CRDs**: 40+ custom resource definitions
- **Container Images**: 50+ (operators, runtimes, workbench variants)
- **Namespaces**: 4 platform namespaces (redhat-ods-operator, redhat-ods-applications, opendatahub, redhat-ods-monitoring) + user project namespaces
- **Service Mesh Coverage**: ~35-40% (KServe, Model Registry, DSP optional)
- **Operator-based**: 93% of components are Kubernetes operators

### Key Workflows Documented
1. **Interactive Model Development to Deployment** (10 steps: Project creation → Notebook → Training → S3 → InferenceService → Inference → TrustyAI monitoring)
2. **Distributed Training Job** (9 steps: PyTorchJob → Kueue → Gang scheduling → Training → S3 → Model Registry)
3. **Data Science Pipeline Execution** (10 steps: Pipeline upload → Argo → Training → Validation → InferenceService → Metadata)
4. **Ray Distributed Computing** (9 steps: RayCluster → CodeFlare security → Ray jobs → Autoscaling → Metrics)
5. **Multi-Model Serving with ModelMesh** (9 steps: Predictor CRs → ModelMesh → S3 → Model placement → Inference)

---

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

---

## Updating Diagrams

To regenerate diagrams after architecture changes:

```bash
# Navigate to repository root
cd /path/to/rhoai-architecture-diagrams

# For a specific component
python scripts/generate_architecture_diagrams.py \
  --architecture=architecture/rhoai-2.17/data-science-pipelines-operator.md

# Regenerate PNGs only (after editing .mmd files)
python scripts/generate_diagram_pngs.py architecture/rhoai-2.17/diagrams --width=3000
```

---

## Diagram Naming Convention

All diagrams follow the pattern: `{component-name}-{diagram-type}.{ext}`

**Component names** are derived from architecture filenames (lowercase, without version):
- `data-science-pipelines-operator.md` → `data-science-pipelines-operator-*`
- `kuberay.md` → `kuberay-*`
- `kserve.md` → `kserve-*`
- `PLATFORM.md` → `platform-*`

**Diagram types**:
- `component` - Component structure and relationships
- `dataflow` - Sequence diagrams showing request/response flows
- `security-network` - Network topology with security details
- `dependencies` - Dependency graph
- `rbac` - RBAC permissions visualization
- `c4-context` - C4 system context diagram

**Extensions**:
- `.mmd` - Mermaid source (editable)
- `.png` - High-resolution PNG (3000px width)
- `.txt` - ASCII diagram (for security network)
- `.dsl` - Structurizr DSL (for C4 diagrams)
