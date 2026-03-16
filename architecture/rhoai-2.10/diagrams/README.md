# Architecture Diagrams for RHOAI 2.10

Generated from architecture files in: `architecture/rhoai-2.10/`
Date: 2026-03-15

**Note**: Diagram filenames use base component name without version (directory is already versioned).

## Available Diagrams

All Mermaid diagrams are available in both `.mmd` (source) and `.png` (3000px width, high-resolution) formats.

---

## Platform (Red Hat OpenShift AI 2.10)

Generated from: `architecture/rhoai-2.10/PLATFORM.md`

Comprehensive platform-level architecture showing all 13 RHOAI components and their interactions.

### For Developers
- [Component Structure](./platform-component.png) ([mmd](./platform-component.mmd)) - Mermaid diagram showing all 13 platform components organized by functional layers (control plane, workbench, serving, training, compute, workload management, governance)
- [Data Flows](./platform-dataflow.png) ([mmd](./platform-dataflow.mmd)) - Sequence diagram of complete workflow from notebook creation through model training to inference serving with technical details (ports, protocols, auth)
- [Dependencies](./platform-dependencies.png) ([mmd](./platform-dependencies.mmd)) - Platform dependency graph showing external infrastructure (OpenShift, Istio, Knative, S3), component relationships, and integration hubs (Kueue, Model Controller)

### For Architects
- [C4 Context](./platform-c4-context.dsl) - System context in C4 format (Structurizr) showing RHOAI platform in broader enterprise ecosystem with all 13 components, users (Data Scientist, ML Engineer, Platform Admin), and external systems
- [Component Overview](./platform-component.png) ([mmd](./platform-component.mmd)) - High-level platform architecture with RHODS Operator orchestrating all component deployments
- [Dependency Graph](./platform-dependencies.png) ([mmd](./platform-dependencies.mmd)) - Critical paths: KServe→Knative+Istio, Kueue→Training/CodeFlare, Dashboard→All Components

### For Security Teams
- [Security Network Diagram (PNG)](./platform-security-network.png) - High-resolution network topology showing all trust zones (External, Ingress, Service Mesh, Application Tier, Control Plane, Infrastructure, External Services)
- [Security Network Diagram (Mermaid)](./platform-security-network.mmd) - Visual network topology with color-coded zones and comprehensive authentication flows (editable)
- [Security Network Diagram (ASCII)](./platform-security-network.txt) - Precise text format for SAR submissions with complete RBAC summary for all 10+ operators, Service Mesh configuration, Network Policies, and Secrets inventory
- [RBAC Visualization](./platform-rbac.png) ([mmd](./platform-rbac.mmd)) - Platform-wide RBAC permissions showing 10 ServiceAccounts, ClusterRoles, and permissions across 40+ API resource types (Platform CRDs, Serving, Training, Ray, Kueue, Core K8s, Istio, Monitoring)

**Platform Architecture Highlights**:
- **Components**: 13 integrated components (RHODS Operator, Dashboard, Notebook Controller, Notebook Images, Data Science Pipelines, KServe, ModelMesh, Model Controller, Training Operator, CodeFlare, KubeRay, Kueue, TrustyAI)
- **Namespaces**: 7 platform namespaces + user project namespaces
- **External Ingress**: All via OpenShift Routes (443/TCP HTTPS) - Dashboard, Notebooks, Model Serving, Pipelines, Ray, TrustyAI
- **Service Mesh**: Optional mTLS (PERMISSIVE/STRICT) for KServe, ModelMesh, Notebooks via Istio
- **Authentication**: OpenShift OAuth (Dashboard, Notebooks, Ray, TrustyAI), JWT via Authorino (Model Serving), mTLS (Service Mesh), AWS IAM (S3)
- **Central Services**: RHODS Operator (orchestrator), Dashboard (UI/API gateway), Kueue (admission control), Model Controller (serving integration), Istio (networking), Prometheus (monitoring), S3 (storage)
- **Workflows**: Notebook→Training→Serving, Pipeline-driven deployment, Distributed training with queueing, Ray distributed compute, Model monitoring with TrustyAI

**Version 2.10 Updates**: KServe CVE fixes, Kueue v0.6.2 rebase, Training Operator scheduler-plugins, TrustyAI reencrypt routes, CodeFlare v1.4.3, KubeRay k8s 1.22.2

---

## CodeFlare Operator

Generated from: `architecture/rhoai-2.10/codeflare-operator.md`

### For Developers
- [Component Structure](./codeflare-operator-component.png) ([mmd](./codeflare-operator-component.mmd)) - Mermaid diagram showing operator manager, webhook server, RayCluster/AppWrapper controllers
- [Data Flows](./codeflare-operator-dataflow.png) ([mmd](./codeflare-operator-dataflow.mmd)) - Sequence diagrams of AppWrapper admission, RayCluster reconciliation, Kueue workload scheduling, and mTLS flows
- [Dependencies](./codeflare-operator-dependencies.png) ([mmd](./codeflare-operator-dependencies.mmd)) - Component dependency graph showing KubeRay, Kueue, cert-controller, and ODH integrations

### For Architects
- [C4 Context](./codeflare-operator-c4-context.dsl) - System context in C4 format (Structurizr) showing CodeFlare in the RHOAI distributed AI/ML ecosystem
- [Component Overview](./codeflare-operator-component.png) ([mmd](./codeflare-operator-component.mmd)) - High-level component view with webhook, controllers, and certificate management

### For Security Teams
- [Security Network Diagram (PNG)](./codeflare-operator-security-network.png) - High-resolution network topology with operator, Ray clusters, and trust boundaries
- [Security Network Diagram (Mermaid)](./codeflare-operator-security-network.mmd) - Visual network topology with color-coded trust zones (editable)
- [Security Network Diagram (ASCII)](./codeflare-operator-security-network.txt) - Precise text format for SAR submissions with RBAC, NetworkPolicies, mTLS, and Secrets
- [RBAC Visualization](./codeflare-operator-rbac.png) ([mmd](./codeflare-operator-rbac.mmd)) - RBAC permissions for operator manager with RayCluster, AppWrapper, and Kueue Workload resources

---

## Data Science Pipelines Operator

Generated from: `architecture/rhoai-2.10/data-science-pipelines-operator.md`

### For Developers
- [Component Structure](./data-science-pipelines-operator-component.png) ([mmd](./data-science-pipelines-operator-component.mmd)) - Mermaid diagram showing DSPO operator, deployed pipeline stack (API Server, Argo Workflows, MLMD, MariaDB, Minio), and integrations
- [Data Flows](./data-science-pipelines-operator-dataflow.png) ([mmd](./data-science-pipelines-operator-dataflow.mmd)) - Sequence diagrams for pipeline submission, execution, artifact retrieval, and metadata tracking flows
- [Dependencies](./data-science-pipelines-operator-dependencies.png) ([mmd](./data-science-pipelines-operator-dependencies.mmd)) - Component dependency graph showing Argo Workflows, Tekton (deprecated), storage/database deployment options, and ODH integration

### For Architects
- [C4 Context](./data-science-pipelines-operator-c4-context.dsl) - System context in C4 format (Structurizr) showing DSPO in the ODH/RHOAI ecosystem
- [Component Overview](./data-science-pipelines-operator-component.png) ([mmd](./data-science-pipelines-operator-component.mmd)) - High-level view with operator, API server, workflow controllers, and optional components (MariaDB, Minio, UI, MLMD)

### For Security Teams
- [Security Network Diagram (PNG)](./data-science-pipelines-operator-security-network.png) - High-resolution network topology with OAuth proxy, NetworkPolicies, and multi-tier architecture
- [Security Network Diagram (Mermaid)](./data-science-pipelines-operator-security-network.mmd) - Visual network topology with trust zones and authentication flows (editable)
- [Security Network Diagram (ASCII)](./data-science-pipelines-operator-security-network.txt) - Precise text format for SAR submissions with complete RBAC summary, NetworkPolicy details, and Secrets inventory
- [RBAC Visualization](./data-science-pipelines-operator-rbac.png) ([mmd](./data-science-pipelines-operator-rbac.mmd)) - RBAC permissions for operator ClusterRole and namespace-scoped pipeline service accounts (API server, runner, MLMD, persistence agent, scheduled workflow)

---

## KubeRay Operator

Generated from: `architecture/rhoai-2.10/kuberay.md`

### For Developers
- [Component Structure](./kuberay-component.png) ([mmd](./kuberay-component.mmd)) - Mermaid diagram showing KubeRay operator internal components and Ray cluster infrastructure
- [Data Flows](./kuberay-dataflow.png) ([mmd](./kuberay-dataflow.mmd)) - Sequence diagram of RayCluster creation, RayJob submission, and Ray Serve request flows
- [Dependencies](./kuberay-dependencies.png) ([mmd](./kuberay-dependencies.mmd)) - Component dependency graph showing Kubernetes, OpenShift, and optional integrations

### For Architects
- [C4 Context](./kuberay-c4-context.dsl) - System context in C4 format (Structurizr) showing KubeRay in the ODH ecosystem
- [Component Overview](./kuberay-component.png) ([mmd](./kuberay-component.mmd)) - High-level component view with operator controllers

### For Security Teams
- [Security Network Diagram (PNG)](./kuberay-security-network.png) - High-resolution network topology with trust zones
- [Security Network Diagram (Mermaid)](./kuberay-security-network.mmd) - Visual network topology (editable)
- [Security Network Diagram (ASCII)](./kuberay-security-network.txt) - Precise text format for SAR submissions
- [RBAC Visualization](./kuberay-rbac.png) ([mmd](./kuberay-rbac.mmd)) - RBAC permissions and bindings for operator and Ray pods

---

## Kubeflow Notebook Controller

Generated from: `architecture/rhoai-2.10/kubeflow.md`

### For Developers
- [Component Structure](./kubeflow-component.png) ([mmd](./kubeflow-component.mmd)) - Mermaid diagram showing Notebook and Culling reconcilers with notebook lifecycle management
- [Data Flows](./kubeflow-dataflow.png) ([mmd](./kubeflow-dataflow.mmd)) - Sequence diagrams showing notebook creation, idle culling, and Istio routing flows
- [Dependencies](./kubeflow-dependencies.png) ([mmd](./kubeflow-dependencies.mmd)) - Component dependency graph showing Kubernetes, Istio, and ODH Dashboard integration

### For Architects
- [C4 Context](./kubeflow-c4-context.dsl) - System context in C4 format (Structurizr) showing Kubeflow in the ODH ecosystem
- [Component Overview](./kubeflow-component.png) ([mmd](./kubeflow-component.mmd)) - High-level component view with reconcilers and metrics

### For Security Teams
- [Security Network Diagram (PNG)](./kubeflow-security-network.png) - High-resolution network topology with controller and user namespaces
- [Security Network Diagram (Mermaid)](./kubeflow-security-network.mmd) - Visual network topology (editable)
- [Security Network Diagram (ASCII)](./kubeflow-security-network.txt) - Precise text format for SAR submissions with RBAC details
- [RBAC Visualization](./kubeflow-rbac.png) ([mmd](./kubeflow-rbac.mmd)) - RBAC permissions for controller, edit, and view roles

---

## KServe

Generated from: `architecture/rhoai-2.10/kserve.md`

### For Developers
- [Component Structure](./kserve-component.png) ([mmd](./kserve-component.mmd)) - Mermaid diagram showing KServe controller, webhook, agent, storage-initializer, and model server runtimes
- [Data Flows](./kserve-dataflow.png) ([mmd](./kserve-dataflow.mmd)) - Sequence diagrams of InferenceService creation, inference requests, InferenceGraph pipelines, and canary rollouts
- [Dependencies](./kserve-dependencies.png) ([mmd](./kserve-dependencies.mmd)) - Component dependency graph showing Kubernetes, Knative, Istio, and ODH integrations

### For Architects
- [C4 Context](./kserve-c4-context.dsl) - System context in C4 format (Structurizr) showing KServe in the RHOAI ecosystem
- [Component Overview](./kserve-component.png) ([mmd](./kserve-component.mmd)) - High-level component view with deployment modes and model server runtimes

### For Security Teams
- [Security Network Diagram (PNG)](./kserve-security-network.png) - High-resolution network topology with trust boundaries and mTLS flows
- [Security Network Diagram (Mermaid)](./kserve-security-network.mmd) - Visual network topology with color-coded trust zones (editable)
- [Security Network Diagram (ASCII)](./kserve-security-network.txt) - Precise text format for SAR submissions with RBAC, Service Mesh config, and Secrets
- [RBAC Visualization](./kserve-rbac.png) ([mmd](./kserve-rbac.mmd)) - RBAC permissions for controller, webhook, and model serving

---

## ODH Dashboard

Generated from: `architecture/rhoai-2.10/odh-dashboard.md`

### For Developers
- [Component Structure](./odh-dashboard-component.png) ([mmd](./odh-dashboard-component.mmd)) - Mermaid diagram showing React frontend, Node.js backend, OAuth proxy, and integrations with ODH components
- [Data Flows](./odh-dashboard-dataflow.png) ([mmd](./odh-dashboard-dataflow.mmd)) - Sequence diagrams of user authentication, Kubernetes API operations, Prometheus metrics queries, and WebSocket watch streams
- [Dependencies](./odh-dashboard-dependencies.png) ([mmd](./odh-dashboard-dependencies.mmd)) - Component dependency graph showing OpenShift OAuth, Kubernetes API, and internal ODH service integrations

### For Architects
- [C4 Context](./odh-dashboard-c4-context.dsl) - System context in C4 format (Structurizr) showing ODH Dashboard as API gateway and UI for RHOAI platform
- [Component Overview](./odh-dashboard-component.png) ([mmd](./odh-dashboard-component.mmd)) - High-level component view with frontend, backend, OAuth proxy containers

### For Security Teams
- [Security Network Diagram (PNG)](./odh-dashboard-security-network.png) - High-resolution network topology with OpenShift Route, OAuth proxy, and backend service flows
- [Security Network Diagram (Mermaid)](./odh-dashboard-security-network.mmd) - Visual network topology with trust boundaries (DMZ, application pod, cluster services)
- [Security Network Diagram (ASCII)](./odh-dashboard-security-network.txt) - Precise text format for SAR submissions with TLS reencrypt configuration, RBAC summary, and secret rotation policies
- [RBAC Visualization](./odh-dashboard-rbac.png) ([mmd](./odh-dashboard-rbac.mmd)) - RBAC permissions for cluster-wide and namespace-scoped resource management (extensive permissions for project/notebook/model serving management)

---

## Notebook Workbench Images

Generated from: `architecture/rhoai-2.10/notebooks.md`

### For Developers
- [Component Structure](./notebooks-component.png) ([mmd](./notebooks-component.mmd)) - Mermaid diagram showing notebook image build chains (Base → Jupyter → Specialized), GPU variants (CUDA, Intel, Habana), alternative IDEs (Code Server, RStudio), and runtime images for Elyra pipelines
- [Data Flows](./notebooks-dataflow.png) ([mmd](./notebooks-dataflow.mmd)) - Sequence diagrams showing user access via OAuth Proxy, notebook operations with Kubernetes API, S3 data access, Elyra pipeline execution, and package installation flows
- [Dependencies](./notebooks-dependencies.png) ([mmd](./notebooks-dependencies.mmd)) - Component dependency graph showing UBI base images, JupyterLab/ML frameworks, ODH integrations (Notebook Controller, Dashboard, KFP), and external services (S3, PyPI, Git, Quay.io)

### For Architects
- [C4 Context](./notebooks-c4-context.dsl) - System context in C4 format (Structurizr) showing notebook images in the RHOAI ecosystem with build chains and runtime dependencies
- [Component Overview](./notebooks-component.png) ([mmd](./notebooks-component.mmd)) - High-level view of image hierarchy: Base Images → Jupyter (Minimal/DS/PyTorch/TF/TrustAI) → GPU Variants → Alternative IDEs → Runtime Images

### For Security Teams
- [Security Network Diagram (PNG)](./notebooks-security-network.png) - High-resolution network topology showing OAuth Proxy sidecar pattern, pod network trust boundaries, and egress to external services
- [Security Network Diagram (Mermaid)](./notebooks-security-network.mmd) - Visual network topology with color-coded zones: External (user) → Ingress (Route/TLS) → Pod (OAuth+Jupyter) → External Services (editable)
- [Security Network Diagram (ASCII)](./notebooks-security-network.txt) - Precise text format for SAR submissions with RBAC notes, Pod Security Standards (UID 1001, Restricted profile), OAuth config, and secrets management
- [RBAC Visualization](./notebooks-rbac.png) ([mmd](./notebooks-rbac.mmd)) - RBAC flow showing user OAuth authentication, namespace RoleBindings, and pod ServiceAccount permissions (note: component provides images, RBAC managed by Notebook Controller)

**Security Highlights**:
- JupyterLab token/password authentication DISABLED (OAuth Proxy handles all auth)
- Pod Security: Non-root user (UID 1001), restricted profile, no privilege escalation
- Encryption: TLS 1.2+ for all external connections; HTTP within trusted pod network
- Secrets: OAuth config, AWS credentials (S3), Git SSH keys (provisioned externally)
- Updates: Twice-yearly major releases (2024a, 2024b), weekly security patches, Quay vulnerability scanning

---

## TrustyAI Service Operator

Generated from: `architecture/rhoai-2.10/trustyai-service-operator.md`

### For Developers
- [Component Structure](./trustyai-service-operator-component.png) ([mmd](./trustyai-service-operator-component.mmd)) - Mermaid diagram showing operator controller, managed TrustyAI service instances, OAuth proxy sidecar, and KServe/ModelMesh integration
- [Data Flows](./trustyai-service-operator-dataflow.png) ([mmd](./trustyai-service-operator-dataflow.mmd)) - Sequence diagrams of TrustyAIService creation, user access via OAuth, ModelMesh payload forwarding, and metrics collection
- [Dependencies](./trustyai-service-operator-dependencies.png) ([mmd](./trustyai-service-operator-dependencies.mmd)) - Component dependency graph showing KServe, ModelMesh, OpenShift OAuth, service-ca, and Prometheus integrations

### For Architects
- [C4 Context](./trustyai-service-operator-c4-context.dsl) - System context in C4 format (Structurizr) showing TrustyAI operator in the RHOAI ecosystem with model serving and monitoring integration
- [Component Overview](./trustyai-service-operator-component.png) ([mmd](./trustyai-service-operator-component.mmd)) - High-level component view with operator managing Quarkus-based TrustyAI services with OAuth proxy sidecars

### For Security Teams
- [Security Network Diagram (PNG)](./trustyai-service-operator-security-network.png) - High-resolution network topology with OAuth proxy authentication flow and TLS certificate management
- [Security Network Diagram (Mermaid)](./trustyai-service-operator-security-network.mmd) - Visual network topology with trust zones (External, Operator, User Namespaces, Ingress, External Services)
- [Security Network Diagram (ASCII)](./trustyai-service-operator-security-network.txt) - Precise text format for SAR submissions with RBAC summary (operator manager-role, OAuth proxy-role), service-ca certificate management, and ModelMesh integration details
- [RBAC Visualization](./trustyai-service-operator-rbac.png) ([mmd](./trustyai-service-operator-rbac.mmd)) - RBAC permissions for operator ServiceAccount (broad permissions for TrustyAIService CRDs, KServe InferenceServices, deployments, routes) and OAuth proxy ServiceAccount (TokenReview, SubjectAccessReview for authentication)

**Architecture Highlights**:
- **Operator**: Kubernetes controller managing TrustyAIService CRDs and lifecycle
- **Managed Service**: Quarkus-based TrustyAI service (port 8080/TCP) with OAuth proxy sidecar (port 8443/TCP HTTPS)
- **ModelMesh Integration**: Watches KServe InferenceServices and patches ModelMesh deployments with `MM_PAYLOAD_PROCESSORS` environment variable for automatic payload forwarding
- **OAuth Authentication**: OpenShift OAuth proxy sidecar with Subject Access Review (SAR) requiring namespace.pods.get permission
- **TLS Automation**: OpenShift service-ca automatic certificate injection and rotation for OAuth proxy HTTPS service
- **Network Access**:
  - Internal: ClusterIP service (port 80 → 8080) for ModelMesh payload forwarding and Prometheus metrics scraping
  - External: OpenShift Route with re-encrypt TLS termination (443 → service-ca cert → OAuth proxy 8443)
- **Storage**: PVC-backed persistent storage for inference data and model metadata
- **Monitoring**: Prometheus ServiceMonitor for scraping fairness and explainability metrics from /q/metrics endpoint
- **RBAC**: Operator has permissions for CRDs (TrustyAIService, InferenceService, ServingRuntime), core resources (Pods, Services, PVCs, Secrets), and OpenShift resources (Routes, ClusterRoleBindings); OAuth proxy has TokenReview/SubjectAccessReview permissions
- **Security**: User access requires OpenShift OAuth authentication + namespace pod access permissions; health endpoint (/apis/v1beta1/healthz) bypasses authentication for monitoring

---

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
# Regenerate for specific component
cd /path/to/rhoai-architecture-diagrams
python scripts/generate_diagram_pngs.py architecture/rhoai-2.10/diagrams --width=3000
```

Or manually regenerate specific diagram:
```bash
PUPPETEER_EXECUTABLE_PATH=/usr/bin/google-chrome mmdc -i kuberay-component.mmd -o kuberay-component.png -w 3000
```

## Component List

This diagrams directory contains architecture visualizations for the following RHOAI 2.10 components:

- **CodeFlare Operator** - Operator for installation and lifecycle management of CodeFlare distributed workload stack, managing Ray clusters and AppWrappers for ML/AI distributed computing
- **Data Science Pipelines Operator** - Deploys and manages namespace-scoped ML workflow orchestration infrastructure based on Kubeflow Pipelines with Argo Workflows (v2) or Tekton (v1, deprecated)
- **KServe** - Standardized serverless ML model serving platform with autoscaling and multi-framework support
- **Kubeflow Notebook Controller** - Kubernetes operator for managing Jupyter notebook server lifecycle
- **KubeRay Operator** - Kubernetes operator for Ray distributed computing clusters
- **Notebook Workbench Images** - Jupyter notebook container images with ML frameworks (PyTorch, TensorFlow, TrustyAI), GPU support, and alternative IDEs (Code Server, RStudio)
- **ODH Dashboard** - Web-based user interface and API gateway for Open Data Hub and RHOAI platform management, providing project/notebook/model serving management and configuration
- **TrustyAI Service Operator** - Kubernetes operator that automates deployment and lifecycle management of TrustyAI services for AI/ML model explainability and fairness monitoring, with automatic ModelMesh integration

Additional components will be added as their architecture documentation is completed.
