# RHOAI 2.9 Architecture Diagrams

This directory contains architecture diagrams for all components in Red Hat OpenShift AI (RHOAI) 2.9.

**Generated**: 2026-03-15
**Source**: `architecture/rhoai-2.9/*.md`

## Components

1. [CodeFlare Operator](#codeflare-operator)
2. [Data Science Pipelines Operator](#data-science-pipelines-operator)
3. [KServe](#kserve)
4. [Kubeflow (Notebook Controller)](#kubeflow-notebook-controller)
5. [KubeRay Operator](#kuberay-operator)
6. [Kueue](#kueue)
7. [ModelMesh Serving](#modelmesh-serving)
8. [Notebooks (Workbench Images)](#notebooks-workbench-images)
9. [ODH Dashboard](#odh-dashboard)
10. [ODH Model Controller](#odh-model-controller)
11. [RHODS Operator](#rhods-operator)
12. [TrustyAI Service Operator](#trustyai-service-operator)

---

## CodeFlare Operator

Enhances KubeRay RayClusters with OAuth authentication, mTLS encryption, and network security policies for Ray distributed computing clusters.

### Diagrams
- [Component Structure](./codeflare-operator-component.png) ([mmd](./codeflare-operator-component.mmd))
- [Data Flows](./codeflare-operator-dataflow.png) ([mmd](./codeflare-operator-dataflow.mmd))
- [Dependencies](./codeflare-operator-dependencies.png) ([mmd](./codeflare-operator-dependencies.mmd))
- [RBAC Visualization](./codeflare-operator-rbac.png) ([mmd](./codeflare-operator-rbac.mmd))
- [Security Network (PNG)](./codeflare-operator-security-network.png) | [Mermaid](./codeflare-operator-security-network.mmd) | [ASCII](./codeflare-operator-security-network.txt)
- [C4 Context Diagram](./codeflare-operator-c4-context.dsl)

### Architecture Source
[../codeflare-operator.md](../codeflare-operator.md)

---

## Data Science Pipelines Operator

Manages Kubeflow Pipelines deployments for ML workflow orchestration.

### Diagrams
- [Component Structure](./data-science-pipelines-operator-component.png) ([mmd](./data-science-pipelines-operator-component.mmd))
- [Data Flows](./data-science-pipelines-operator-dataflow.png) ([mmd](./data-science-pipelines-operator-dataflow.mmd))
- [Dependencies](./data-science-pipelines-operator-dependencies.png) ([mmd](./data-science-pipelines-operator-dependencies.mmd))
- [RBAC Visualization](./data-science-pipelines-operator-rbac.png) ([mmd](./data-science-pipelines-operator-rbac.mmd))
- [Security Network (PNG)](./data-science-pipelines-operator-security-network.png) | [Mermaid](./data-science-pipelines-operator-security-network.mmd) | [ASCII](./data-science-pipelines-operator-security-network.txt)

### Architecture Source
[../data-science-pipelines-operator.md](../data-science-pipelines-operator.md)

---

## KServe

Standardized serverless ML model inference platform with autoscaling and multi-framework support.

### Diagrams
- [Component Structure](./kserve-component.png) ([mmd](./kserve-component.mmd))
- [Data Flows](./kserve-dataflow.png) ([mmd](./kserve-dataflow.mmd))
- [Dependencies](./kserve-dependencies.png) ([mmd](./kserve-dependencies.mmd))
- [RBAC Visualization](./kserve-rbac.png) ([mmd](./kserve-rbac.mmd))
- [Security Network (PNG)](./kserve-security-network.png) | [Mermaid](./kserve-security-network.mmd) | [ASCII](./kserve-security-network.txt)
- [C4 Context Diagram](./kserve-c4-context.dsl)

### Architecture Source
[../kserve.md](../kserve.md)

---

## Kubeflow (Notebook Controller)

Kubernetes operator managing Jupyter notebook server instances with idle culling and multi-version CRD support.

### Diagrams
- [Component Structure](./kubeflow-component.png) ([mmd](./kubeflow-component.mmd))
- [Data Flows](./kubeflow-dataflow.png) ([mmd](./kubeflow-dataflow.mmd))
- [Dependencies](./kubeflow-dependencies.png) ([mmd](./kubeflow-dependencies.mmd))
- [RBAC Visualization](./kubeflow-rbac.png) ([mmd](./kubeflow-rbac.mmd))
- [Security Network (PNG)](./kubeflow-security-network.png) | [Mermaid](./kubeflow-security-network.mmd) | [ASCII](./kubeflow-security-network.txt)
- [C4 Context Diagram](./kubeflow-c4-context.dsl)

### Architecture Source
[../kubeflow.md](../kubeflow.md)

---

## KubeRay Operator

Kubernetes operator for deploying and managing Ray distributed computing clusters for ML/AI workloads.

### Diagrams
- [Component Structure](./kuberay-component.png) ([mmd](./kuberay-component.mmd))
- [Data Flows](./kuberay-dataflow.png) ([mmd](./kuberay-dataflow.mmd))
- [Dependencies](./kuberay-dependencies.png) ([mmd](./kuberay-dependencies.mmd))
- [RBAC Visualization](./kuberay-rbac.png) ([mmd](./kuberay-rbac.mmd))
- [Security Network (PNG)](./kuberay-security-network.png) | [Mermaid](./kuberay-security-network.mmd) | [ASCII](./kuberay-security-network.txt)
- [C4 Context Diagram](./kuberay-c4-context.dsl)

### Architecture Source
[../kuberay.md](../kuberay.md)

### Key Features
- **RayCluster**: Manage Ray cluster lifecycle with autoscaling and fault tolerance
- **RayJob**: Automatically create clusters, submit jobs, and cleanup
- **RayService**: Zero-downtime ML model serving with high availability
- **Gang Scheduling**: Optional Volcano integration for distributed training
- **Service Mesh**: Optional Istio mTLS for encrypted Ray communication

---

## Kueue

Job queueing and resource management controller that manages when jobs should be admitted to start based on available cluster resources.

### Diagrams
- [Component Structure](./kueue-component.png) ([mmd](./kueue-component.mmd))
- [Data Flows](./kueue-dataflow.png) ([mmd](./kueue-dataflow.mmd))
- [Dependencies](./kueue-dependencies.png) ([mmd](./kueue-dependencies.mmd))
- [RBAC Visualization](./kueue-rbac.png) ([mmd](./kueue-rbac.mmd))
- [Security Network (PNG)](./kueue-security-network.png) | [Mermaid](./kueue-security-network.mmd) | [ASCII](./kueue-security-network.txt)
- [C4 Context Diagram](./kueue-c4-context.dsl)

### Architecture Source
[../kueue.md](../kueue.md)

### Key Features
- **Fair Resource Sharing**: Multi-tenancy with ClusterQueues and LocalQueues, cohort-based borrowing
- **Flexible Queueing**: StrictFIFO and BestEffortFIFO strategies with priority support
- **Preemption**: Policy-based workload preemption to reclaim resources
- **Job Framework Integration**: Supports Kubernetes Jobs, JobSet, Kubeflow training, Ray, and plain Pods
- **Autoscaling Integration**: ProvisioningRequest support for cluster-autoscaler
- **Admission Checks**: External validation before admitting workloads
- **Partial Admission**: Run jobs with reduced parallelism based on available quota

---

## ModelMesh Serving

Multi-model serving platform for scalable ML inference with intelligent model placement and auto-scaling.

### Diagrams
- [Component Structure](./modelmesh-serving-component.png) ([mmd](./modelmesh-serving-component.mmd))
- [Data Flows](./modelmesh-serving-dataflow.png) ([mmd](./modelmesh-serving-dataflow.mmd))
- [Dependencies](./modelmesh-serving-dependencies.png) ([mmd](./modelmesh-serving-dependencies.mmd))
- [RBAC Visualization](./modelmesh-serving-rbac.png) ([mmd](./modelmesh-serving-rbac.mmd))
- [Security Network (PNG)](./modelmesh-serving-security-network.png) | [Mermaid](./modelmesh-serving-security-network.mmd) | [ASCII](./modelmesh-serving-security-network.txt)
- [C4 Context Diagram](./modelmesh-serving-c4-context.dsl)

### Architecture Source
[../modelmesh-serving.md](../modelmesh-serving.md)

---

## Notebooks (Workbench Images)

Pre-configured notebook and IDE workbench container images for data science and ML workflows in OpenShift.

### Diagrams
- [Component Structure](./notebooks-component.png) ([mmd](./notebooks-component.mmd))
- [Data Flows](./notebooks-dataflow.png) ([mmd](./notebooks-dataflow.mmd))
- [Dependencies](./notebooks-dependencies.png) ([mmd](./notebooks-dependencies.mmd))
- [RBAC Visualization](./notebooks-rbac.png) ([mmd](./notebooks-rbac.mmd))
- [Security Network (PNG)](./notebooks-security-network.png) | [Mermaid](./notebooks-security-network.mmd) | [ASCII](./notebooks-security-network.txt)
- [C4 Context Diagram](./notebooks-c4-context.dsl)

### Architecture Source
[../notebooks.md](../notebooks.md)

### Key Features
- **Jupyter Images**: Multiple variants (Minimal, Data Science, TensorFlow, PyTorch, TrustyAI)
- **Hardware Acceleration**: CUDA (NVIDIA GPU), Habana Gaudi, Intel GPU support
- **Alternative IDEs**: VS Code Server, RStudio Server
- **Pipeline Execution**: Headless runtime images for Elyra pipelines
- **Version Management**: N/N-1/N-2/N-3 release strategy via ImageStreams
- **OAuth Integration**: Authentication via OAuth Proxy sidecar

---

## ODH Dashboard

Web-based user interface for managing data science projects, workbenches, and model serving in OpenShift AI.

### Diagrams
- [Component Structure](./odh-dashboard-component.png) ([mmd](./odh-dashboard-component.mmd))
- [Data Flows](./odh-dashboard-dataflow.png) ([mmd](./odh-dashboard-dataflow.mmd))
- [Dependencies](./odh-dashboard-dependencies.png) ([mmd](./odh-dashboard-dependencies.mmd))
- [RBAC Visualization](./odh-dashboard-rbac.png) ([mmd](./odh-dashboard-rbac.mmd))
- [Security Network (PNG)](./odh-dashboard-security-network.png) | [Mermaid](./odh-dashboard-security-network.mmd) | [ASCII](./odh-dashboard-security-network.txt)
- [C4 Context Diagram](./odh-dashboard-c4-context.dsl)

### Architecture Source
[../odh-dashboard.md](../odh-dashboard.md)

### Key Features
- **React + Fastify**: Modern web architecture with PatternFly UI components
- **OpenShift OAuth**: Integrated authentication with RBAC delegation
- **Multi-Component Management**: Notebooks, KServe, ModelMesh, Data Science Pipelines
- **CRD Integration**: Manages AcceleratorProfiles, OdhDashboardConfig, and platform components
- **Metrics & Monitoring**: Thanos/Prometheus integration for resource usage tracking

---

## ODH Model Controller

Kubernetes operator that manages KServe InferenceService deployments and model serving infrastructure.

### Diagrams
- [Component Structure](./odh-model-controller-component.png) ([mmd](./odh-model-controller-component.mmd))
- [Data Flows](./odh-model-controller-dataflow.png) ([mmd](./odh-model-controller-dataflow.mmd))

### Architecture Source
[../odh-model-controller.md](../odh-model-controller.md)

---

## RHODS Operator

Primary operator for Red Hat OpenShift AI (RHOAI) that manages the lifecycle of all data science components.

### Diagrams
- [Component Structure](./rhods-operator-component.png) ([mmd](./rhods-operator-component.mmd))
- [Data Flows](./rhods-operator-dataflow.png) ([mmd](./rhods-operator-dataflow.mmd))
- [Dependencies](./rhods-operator-dependencies.png) ([mmd](./rhods-operator-dependencies.mmd))
- [RBAC Visualization](./rhods-operator-rbac.png) ([mmd](./rhods-operator-rbac.mmd))
- [Security Network (PNG)](./rhods-operator-security-network.png) | [Mermaid](./rhods-operator-security-network.mmd) | [ASCII](./rhods-operator-security-network.txt)
- [C4 Context Diagram](./rhods-operator-c4-context.dsl)

### Architecture Source
[../rhods-operator.md](../rhods-operator.md)

### Key Features
- **DataScienceCluster Management**: Deploys and manages all RHOAI components (Dashboard, Workbenches, KServe, ModelMesh, Pipelines, CodeFlare, Ray, Kueue)
- **Platform Initialization**: Configures service mesh, monitoring, namespaces, and network policies via DSCInitialization CRD
- **Secret & Certificate Management**: Automated generation and rotation of secrets and certificates for components
- **Legacy Migration**: Handles migration from KfDef-based deployments to DataScienceCluster API
- **Extensive RBAC**: Cluster-wide permissions for managing Kubernetes, OpenShift, service mesh, and ML-specific resources
- **Manifest Management**: Build-time bundling of component manifests with runtime kustomize overlays
- **Monitoring Integration**: Prometheus metrics, ServiceMonitors, and PodMonitors for all components
- **High Availability**: Leader election with lease-based coordination to prevent split-brain

### Controllers
- **DataScienceCluster Controller**: Reconciles component deployments based on enabled/disabled state
- **DSCInitialization Controller**: Initializes platform infrastructure on operator startup
- **SecretGenerator Controller**: Generates component-specific credentials
- **CertConfigmapGenerator Controller**: Manages TLS certificate ConfigMaps
- **Upgrade Manager**: Handles version migrations and KfDef→DSC conversion

### Security Highlights
- **Non-root execution**: UID 1001, no privilege escalation
- **Minimal capabilities**: All capabilities dropped
- **SELinux**: Enforced (OpenShift default)
- **Seccomp**: RuntimeDefault profile
- **Leader Election**: Single active reconciler prevents conflicts
- **Service Mesh Integration**: Manages ServiceMeshMember resources for component namespaces

---

## TrustyAI Service Operator

Kubernetes operator that manages deployment and lifecycle of TrustyAI explainability services for model monitoring and bias detection.

### Diagrams
- [Component Structure](./trustyai-service-operator-component.png) ([mmd](./trustyai-service-operator-component.mmd))
- [Data Flows](./trustyai-service-operator-dataflow.png) ([mmd](./trustyai-service-operator-dataflow.mmd))
- [Dependencies](./trustyai-service-operator-dependencies.png) ([mmd](./trustyai-service-operator-dependencies.mmd))
- [RBAC Visualization](./trustyai-service-operator-rbac.png) ([mmd](./trustyai-service-operator-rbac.mmd))
- [Security Network (PNG)](./trustyai-service-operator-security-network.png) | [Mermaid](./trustyai-service-operator-security-network.mmd) | [ASCII](./trustyai-service-operator-security-network.txt)
- [C4 Context Diagram](./trustyai-service-operator-c4-context.dsl)

### Architecture Source
[../trustyai-service-operator.md](../trustyai-service-operator.md)

### Key Features
- **Automated Deployment**: Operator watches TrustyAIService CRs and provisions complete infrastructure (deployment, storage, monitoring, external access)
- **KServe/ModelMesh Integration**: Automatically configures payload logging to capture inference data for bias analysis
- **Fairness Metrics**: Exports Prometheus metrics (trustyai_spd, trustyai_dir) for monitoring model bias and fairness
- **OAuth-Protected Access**: Secure external API access via OpenShift Routes with OAuth proxy
- **Persistent Storage**: Per-instance PVCs for inference data and metrics storage
- **Dual Deployment Modes**: Supports both KServe (Logger.URL patching) and ModelMesh (MM_PAYLOAD_PROCESSORS injection)

---

## How to Use Diagrams

### PNG Files (.png files)
**Automatically generated** at 3000px width for high-resolution presentations and documentation.

- ✅ Ready to use in PowerPoint, Google Slides, Confluence
- ✅ High resolution (3000px width, height auto-adjusts)
- ✅ Suitable for printing and detailed presentations

### Mermaid Source Files (.mmd files)
- **GitHub/GitLab**: Paste into markdown with ````mermaid` code blocks - renders automatically!
- **Live editor**: https://mermaid.live (paste, edit, export)
- **Editable**: Modify diagrams and regenerate PNGs as needed

**Regenerate PNG from Mermaid**:
```bash
# Install Mermaid CLI (one-time)
npm install -g @mermaid-js/mermaid-cli

# Generate PNG (3000px width)
PUPPETEER_EXECUTABLE_PATH=/usr/bin/google-chrome mmdc -i diagram.mmd -o diagram.png -w 3000

# Generate SVG (vector, scales perfectly)
PUPPETEER_EXECUTABLE_PATH=/usr/bin/google-chrome mmdc -i diagram.mmd -o diagram.svg
```

### C4 Diagrams (.dsl files)
Structurizr DSL format for system context diagrams.

```bash
# View in Structurizr Lite
docker run -p 8080:8080 -v .:/usr/local/structurizr structurizr/lite

# Export to PNG
structurizr-cli export -workspace diagram.dsl -format png
```

### ASCII Diagrams (.txt files)
Text-based diagrams for Security Architecture Reviews (SARs).

- ✅ View in any text editor
- ✅ Include directly in documentation
- ✅ Precise technical details (ports, protocols, encryption, auth)
- ✅ RBAC summaries and security recommendations

---

## Diagram Types

### 1. Component Diagrams
Show internal component structure, controllers, CRDs, and managed resources.

**Use for**: Understanding component architecture, integration points, controller design

### 2. Data Flow Diagrams
Sequence diagrams showing request/response flows with technical details (ports, protocols, encryption, auth).

**Use for**: Understanding request paths, debugging, performance analysis

### 3. Security Network Diagrams
Network topology with trust zones, exact ports, protocols, encryption, and authentication mechanisms.

**Formats**:
- **PNG**: High-resolution visual diagram
- **Mermaid**: Editable visual diagram with color-coded trust zones
- **ASCII**: Precise text format for SAR submissions (includes RBAC, secrets, security recommendations)

**Use for**: Security reviews, compliance documentation, threat modeling

### 4. Dependency Graphs
Component dependencies and integration points (external and internal RHOAI).

**Use for**: Impact analysis, upgrade planning, integration design

### 5. RBAC Visualizations
Visual representation of RBAC permissions, bindings, and security constraints.

**Use for**: Security reviews, permission audits, access control design

### 6. C4 Context Diagrams
System context showing component in broader RHOAI ecosystem (Structurizr DSL).

**Use for**: Architectural overviews, stakeholder presentations, strategic planning

---

## Updating Diagrams

To regenerate diagrams after architecture changes:

```bash
# For a specific component
/generate-architecture-diagrams --architecture=architecture/rhoai-2.9/kuberay.md

# Or use the Python script directly
cd architecture/rhoai-2.9/diagrams
python3 ../../../scripts/generate_diagram_pngs.py . --width=3000
```

---

## Color Legend

### Mermaid Diagrams
- **Blue (#4a90e2)**: Controller/operator components
- **Orange (#f5a623)**: Custom Resource Definitions (CRDs)
- **Green (#7ed321)**: Managed resources / internal RHOAI components
- **Gray (#999)**: External dependencies (Kubernetes, Prometheus, etc.)
- **Purple (#e1d5e7)**: External services (S3, registries)
- **Dashed lines**: Optional or disabled features

### ASCII Diagrams
- **═══ Double lines**: Trust zone boundaries
- **⚠️  Warning symbol**: Security concerns
- **━━━ Single lines**: Section separators
- **Plaintext/None**: Unencrypted communication
- **TLS 1.2+/mTLS**: Encrypted communication

---

## Known Issues & Security Considerations

### Common Security Patterns

1. **Metrics Endpoints**: Most components expose `/metrics` on port 8080 without authentication
   - **Mitigation**: Network policies should restrict access to Prometheus only

2. **Webhook Certificates**: Managed by cert-manager with automatic rotation
   - **Configuration**: TLS 1.2+ with Kubernetes API server mTLS

3. **Service Mesh Integration**: Optional Istio/OpenShift Service Mesh for mTLS
   - **Status**: Varies by component (see individual architecture docs)

4. **RBAC Scope**: Most operators use ClusterRoles for cross-namespace resource management
   - **Review**: See individual RBAC diagrams for exact permissions

### Component-Specific Concerns

See individual architecture documentation ([`../`](../)) for detailed security considerations, limitations, and hardening recommendations.

---

## Additional Resources

- **Architecture Documentation**: [`../`](../) (all component `.md` files)
- **RHOAI Documentation**: https://access.redhat.com/documentation/en-us/red_hat_openshift_ai/
- **Platform Architecture**: [../PLATFORM.md](../PLATFORM.md)
- **Diagram Generation Script**: [`../../../scripts/generate_diagram_pngs.py`](../../../scripts/generate_diagram_pngs.py)

---

**Note**: All diagrams use base component names without version numbers (e.g., `kuberay-component.mmd`). The directory `rhoai-2.9/` provides the version context.
