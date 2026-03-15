# Architecture Diagrams

This directory contains architecture diagrams for multiple RHOAI 3.2 components.

Generated: 2026-03-15

**Note**: Diagram filenames use base component name without version (directory is already versioned).

## Available Components

- [Data Science Pipelines Operator](#data-science-pipelines-operator)
- [Feast](#feast)
- [KServe](#kserve)
- [Kubeflow (Notebook Controller)](#kubeflow-notebook-controller)
- [KubeRay](#kuberay)
- [Llama Stack K8s Operator](#llama-stack-k8s-operator)
- [MLflow Operator](#mlflow-operator)
- [Model Registry Operator](#model-registry-operator)
- [Notebooks](#notebooks)
- [ODH Dashboard](#odh-dashboard)
- [ODH Model Controller](#odh-model-controller)
- [Platform](#platform)
- [RHOAI Operator](#rhoai-operator)
- [Trainer](#trainer)
- [Training Operator](#training-operator)
- [TrustyAI Service Operator](#trustyai-service-operator)

---

## Data Science Pipelines Operator

Generated from: `architecture/rhoai-3.2/data-science-pipelines-operator.md`

All Mermaid diagrams are available in both `.mmd` (source) and `.png` (3000px width, high-resolution) formats.

### For Developers
- [Component Structure](./data-science-pipelines-operator-component.png) ([mmd](./data-science-pipelines-operator-component.mmd)) - Mermaid diagram showing DSPO controller, DSP stack components (API server, MLMD, Argo), and storage layers
- [Data Flows](./data-science-pipelines-operator-dataflow.png) ([mmd](./data-science-pipelines-operator-dataflow.mmd)) - Sequence diagram of pipeline submission, execution via Argo Workflows, and artifact retrieval flows
- [Dependencies](./data-science-pipelines-operator-dependencies.png) ([mmd](./data-science-pipelines-operator-dependencies.mmd)) - Component dependency graph showing Argo Workflows, OpenShift, MariaDB, S3 storage, and ODH integrations (Dashboard, KServe, Ray, CodeFlare)

### For Architects
- [C4 Context](./data-science-pipelines-operator-c4-context.dsl) - System context in C4 format (Structurizr) showing DSPO in RHOAI ML workflow ecosystem
- [Component Overview](./data-science-pipelines-operator-component.png) ([mmd](./data-science-pipelines-operator-component.mmd)) - High-level component view with operator, DSP stack, and integration points

### For Security Teams
- [Security Network Diagram (PNG)](./data-science-pipelines-operator-security-network.png) - High-resolution network topology with trust zones (external, ingress DMZ, application layer, operator layer)
- [Security Network Diagram (Mermaid)](./data-science-pipelines-operator-security-network.mmd) - Visual network topology (editable, color-coded trust boundaries)
- [Security Network Diagram (ASCII)](./data-science-pipelines-operator-security-network.txt) - Precise text format for SAR submissions with detailed network flows, RBAC summary (operator, Argo, pipeline runner SAs), secrets inventory (TLS certs, DB/storage credentials), and NetworkPolicies
- [RBAC Visualization](./data-science-pipelines-operator-rbac.png) ([mmd](./data-science-pipelines-operator-rbac.mmd)) - RBAC permissions and bindings for controller-manager, ds-pipeline, ds-pipeline-argo, and pipeline-runner service accounts

---

## Feast

Generated from: `architecture/rhoai-3.2/feast.md`

All Mermaid diagrams are available in both `.mmd` (source) and `.png` (3000px width, high-resolution) formats.

### For Developers
- [Component Structure](./feast-component.png) ([mmd](./feast-component.mmd)) - Mermaid diagram showing internal components, services, and storage
- [Data Flows](./feast-dataflow.png) ([mmd](./feast-dataflow.mmd)) - Sequence diagram of FeatureStore creation, feature retrieval, and metrics collection flows
- [Dependencies](./feast-dependencies.png) ([mmd](./feast-dependencies.mmd)) - Component dependency graph showing external platforms, internal ODH components, and optional external services

### For Architects
- [C4 Context](./feast-c4-context.dsl) - System context in C4 format (Structurizr) showing Feast in RHOAI ecosystem
- [Component Overview](./feast-component.png) ([mmd](./feast-component.mmd)) - High-level component view with operator and feature store services

### For Security Teams
- [Security Network Diagram (PNG)](./feast-security-network.png) - High-resolution network topology with trust zones
- [Security Network Diagram (Mermaid)](./feast-security-network.mmd) - Visual network topology (editable, color-coded)
- [Security Network Diagram (ASCII)](./feast-security-network.txt) - Precise text format for SAR submissions with detailed flows, RBAC, and secrets
- [RBAC Visualization](./feast-rbac.png) ([mmd](./feast-rbac.mmd)) - RBAC permissions and bindings for Feast operator service account

---

## KubeRay

Generated from: `architecture/rhoai-3.2/kuberay.md`

All Mermaid diagrams are available in both `.mmd` (source) and `.png` (3000px width, high-resolution) formats.

### For Developers
- [Component Structure](./kuberay-component.png) ([mmd](./kuberay-component.mmd)) - Mermaid diagram showing internal components, controllers, CRDs, and Ray cluster resources
- [Data Flows](./kuberay-dataflow.png) ([mmd](./kuberay-dataflow.mmd)) - Sequence diagram of RayCluster creation, RayJob submission, and OAuth dashboard access flows
- [Dependencies](./kuberay-dependencies.png) ([mmd](./kuberay-dependencies.mmd)) - Component dependency graph showing Kubernetes, OpenShift, cert-manager, and RHOAI integrations

### For Architects
- [C4 Context](./kuberay-c4-context.dsl) - System context in C4 format (Structurizr) showing KubeRay in broader RHOAI ecosystem
- [Component Overview](./kuberay-component.png) ([mmd](./kuberay-component.mmd)) - High-level component view with operator controllers and Ray cluster architecture

### For Security Teams
- [Security Network Diagram (PNG)](./kuberay-security-network.png) - High-resolution network topology with trust zones and security boundaries
- [Security Network Diagram (Mermaid)](./kuberay-security-network.mmd) - Visual network topology (editable, color-coded trust zones)
- [Security Network Diagram (ASCII)](./kuberay-security-network.txt) - Precise text format for SAR submissions with detailed network flows, RBAC summary, and secrets inventory
- [RBAC Visualization](./kuberay-rbac.png) ([mmd](./kuberay-rbac.mmd)) - RBAC permissions and bindings for kuberay-operator service account

---

## KServe

Generated from: `architecture/rhoai-3.2/kserve.md`

### For Developers
- [Component Structure](./kserve-component.png) ([mmd](./kserve-component.mmd)) - Mermaid diagram showing internal components, CRDs, and integrations
- [Data Flows](./kserve-dataflow.png) ([mmd](./kserve-dataflow.mmd)) - Sequence diagram of model deployment and inference request flows
- [Dependencies](./kserve-dependencies.png) ([mmd](./kserve-dependencies.mmd)) - Component dependency graph showing external and internal integrations

### For Architects
- [C4 Context](./kserve-c4-context.dsl) - System context in C4 format (Structurizr)
- [Component Overview](./kserve-component.png) ([mmd](./kserve-component.mmd)) - High-level component view

### For Security Teams
- [Security Network Diagram (PNG)](./kserve-security-network.png) - High-resolution network topology
- [Security Network Diagram (Mermaid)](./kserve-security-network.mmd) - Visual network topology (editable)
- [Security Network Diagram (ASCII)](./kserve-security-network.txt) - Precise text format for SAR submissions
- [RBAC Visualization](./kserve-rbac.png) ([mmd](./kserve-rbac.mmd)) - RBAC permissions and bindings

---

## Kubeflow (Notebook Controller)

Generated from: `architecture/rhoai-3.2/kubeflow.md`

### For Developers
- [Component Structure](./kubeflow-component.png) ([mmd](./kubeflow-component.mmd)) - Mermaid diagram showing internal components, controllers, and managed resources
- [Data Flows](./kubeflow-dataflow.png) ([mmd](./kubeflow-dataflow.mmd)) - Sequence diagram of notebook creation, culling, and metrics collection flows
- [Dependencies](./kubeflow-dependencies.png) ([mmd](./kubeflow-dependencies.mmd)) - Component dependency graph showing external and internal dependencies

### For Architects
- [C4 Context](./kubeflow-c4-context.dsl) - System context in C4 format (Structurizr)
- [Component Overview](./kubeflow-component.png) ([mmd](./kubeflow-component.mmd)) - High-level component view with controllers and CRDs

### For Security Teams
- [Security Network Diagram (PNG)](./kubeflow-security-network.png) - High-resolution network topology
- [Security Network Diagram (Mermaid)](./kubeflow-security-network.mmd) - Visual network topology (editable)
- [Security Network Diagram (ASCII)](./kubeflow-security-network.txt) - Precise text format for SAR submissions
- [RBAC Visualization](./kubeflow-rbac.png) ([mmd](./kubeflow-rbac.mmd)) - RBAC permissions and bindings

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
# From repository root
/generate-architecture-diagrams --architecture=architecture/rhoai-3.2/kuberay.md
# Or for other components:
/generate-architecture-diagrams --architecture=architecture/rhoai-3.2/kserve.md
/generate-architecture-diagrams --architecture=architecture/rhoai-3.2/kubeflow.md
```

## Diagram Details

### KubeRay Diagrams

#### kuberay-component.mmd
Shows the KubeRay operator architecture including:
- **Controllers**: RayCluster, RayJob, RayService, Authentication, NetworkPolicy, mTLS
- **Webhooks**: Validating and mutating webhooks for RayCluster CRs
- **Custom Resources**: RayCluster, RayJob, RayService CRDs (ray.io/v1)
- **Ray Cluster Resources**: Head pod (GCS, dashboard, client API), worker pods, services
- **Security Resources**: NetworkPolicies, cert-manager certificates, OAuth proxy sidecars
- **External Access**: OpenShift Routes and Gateway API HTTPRoutes

#### kuberay-dataflow.mmd
Sequence diagrams showing:
- **Flow 1**: RayCluster creation and pod lifecycle (webhook validation/mutation, controller reconciliation)
- **Flow 2**: RayJob submission (cluster creation, job submission to Ray dashboard API, status polling)
- **Flow 3**: Dashboard access with OAuth (Route → OAuth proxy → OpenShift OAuth Server → Ray dashboard)

#### kuberay-security-network.txt / .mmd
Detailed network topology with:
- **Trust zones**: External (untrusted), Ingress (DMZ), Cluster Internal, Ray Cluster, External Services
- **Network flows**: Precise ports, protocols, encryption (TLS versions), authentication mechanisms
- **RBAC summary**: Complete ClusterRole permissions for kuberay-operator service account
- **Service Mesh**: NetworkPolicy enforcement rules for head and worker pods (when enabled)
- **mTLS configuration**: cert-manager certificate provisioning for Ray pod mTLS
- **Secrets inventory**: webhook-server-cert, OAuth proxy TLS, mTLS CA and certificates

#### kuberay-dependencies.mmd
Shows relationships to:
- **Required External**: Kubernetes 1.26+, Ray Framework 2.0+
- **Optional External**: cert-manager 1.11+, OpenShift 4.12+, Gateway API, Prometheus, External Redis
- **Internal RHOAI**: RHOAI Operator (deploys KubeRay), Kueue (batch scheduling), ODH Dashboard, Data Science Pipelines
- **Integration Points**: OpenShift OAuth, Routes, Service CA, SecurityContextConstraints

#### kuberay-rbac.mmd
Complete RBAC permissions showing:
- **Service Account**: kuberay-operator (operator namespace)
- **ClusterRole**: kuberay-operator with permissions across 12 API groups
- **Key permissions**: Ray CRDs, Pods, Services, Routes, NetworkPolicies, Certificates, HTTPRoutes, RBAC resources
- **ClusterRoleBinding**: Grants ClusterRole to kuberay-operator service account
- **Additional Roles**: Leader election, Gateway API, ConfigMap access

#### kuberay-c4-context.dsl
Architectural context showing:
- **System context**: KubeRay operator in RHOAI ecosystem
- **Containers**: Operator, Webhook Server, Ray Cluster (head/worker pods)
- **External systems**: Kubernetes, OpenShift (OAuth, Routes, Service CA), cert-manager, Gateway API
- **Internal RHOAI**: RHOAI Operator, Kueue, ODH Dashboard, Data Science Pipelines
- **External services**: Container Registry, Prometheus, External Redis (optional)

### KServe Diagrams

#### kserve-component.mmd
Shows the KServe component architecture including:
- Controller manager and webhook server
- Custom Resource Definitions (InferenceService, ServingRuntime, InferenceGraph, etc.)
- Deployment modes (Serverless with Knative, Raw Kubernetes deployments)
- External dependencies (Kubernetes, Knative, Istio, KEDA, cert-manager, Gateway API)
- Internal ODH integrations (Model Registry, Authorino, ODH Dashboard)
- Runtime components (storage-initializer, agent sidecar, router)
- Monitoring integration with Prometheus

### kserve-dataflow.mmd
Illustrates four key data flows:
1. **Model Deployment**: User creates InferenceService → webhook validation → controller reconciliation → Knative/K8s resource creation → storage-initializer downloads model
2. **Inference Request (Serverless)**: Client → Istio Gateway → Knative Activator → Predictor Pod (optionally through Transformer)
3. **InferenceGraph Multi-Step Routing**: Client → Router Service → multiple InferenceServices in sequence
4. **Metrics Collection**: Prometheus scrapes metrics from controller and inference pods

### kserve-security-network.txt / .mmd
Detailed network security architecture showing:
- **Trust boundaries**: External (untrusted), Ingress (DMZ), Service Mesh (trusted mTLS), Control Plane, External Services
- **Network flows**: Exact ports, protocols, encryption (TLS versions), authentication mechanisms
- **RBAC summary**: ClusterRoles, RoleBindings, ServiceAccounts
- **Service Mesh configuration**: PeerAuthentication (STRICT mTLS), AuthorizationPolicy
- **Secrets management**: Webhook certs, storage credentials, image pull secrets with rotation policies
- **Network Policies**: Ingress/egress rules
- **Deployment modes**: Serverless (Knative + Istio), RawDeployment (K8s + HPA/KEDA), ModelMesh (high-density)

### kserve-dependencies.mmd
Dependency graph showing:
- **External required**: Kubernetes 1.28+
- **External optional**: Knative Serving 0.44.0, Istio 1.24+, KEDA 2.16+, cert-manager, Gateway API 1.2.1
- **Internal ODH**: Service Mesh, Model Registry, Authorino, ODH Dashboard, OpenShift OAuth
- **Integration points**: Data Science Pipelines (auto-deploy), Prometheus Operator (metrics), OpenTelemetry (traces)
- **External services**: S3/GCS storage, container registries, Kubernetes API

### kserve-rbac.mmd
RBAC visualization showing:
- **ServiceAccounts**: kserve-controller-manager, {isvc-name}-sa, {graph-name}-router-sa
- **ClusterRoles**: kserve-manager-role (full permissions), leader-election-role, proxy-role
- **ClusterRoleBindings**: kserve-manager-rolebinding, leader-election-rolebinding, proxy-rolebinding
- **API Resources**: KServe CRDs, Core K8s resources, Apps (Deployments, HPA), Networking (Knative, Istio, Gateway API, OpenShift Routes), Autoscaling (KEDA), Monitoring (ServiceMonitors, PodMonitors), RBAC & Admission webhooks
- **Verbs**: create, delete, get, list, patch, update, watch

### kserve-c4-context.dsl
C4 model showing system context:
- **People**: Data Scientist/ML Engineer (creates models), End User/Application (consumes predictions)
- **KServe containers**: Controller Manager, Webhook Server, Storage Initializer, Agent Sidecar, Router Service, LocalModel Manager
- **Inference Service Pod**: Runtime serving predictions
- **External dependencies**: Kubernetes (required), Knative, Istio, KEDA, cert-manager, Gateway API (optional)
- **Internal ODH**: Service Mesh, Model Registry, Authorino, ODH Dashboard, OpenShift OAuth, Data Science Pipelines
- **External services**: S3, GCS, Container Registries
- **Monitoring**: Prometheus

Can be visualized using Structurizr Lite or exported to PNG/SVG.

### Kubeflow (Notebook Controller) Diagrams

#### kubeflow-component.mmd
Shows the Notebook Controller architecture including:
- **NotebookReconciler**: Main controller that creates/updates StatefulSets, Services, and Istio VirtualServices
- **CullingReconciler**: Optional controller for idle notebook culling
- **Metrics Exporter**: Prometheus metrics for monitoring notebook operations
- **Custom Resources**: Notebook CRDs (v1, v1beta1, v1alpha1) with conversion support
- **Managed Resources**: StatefulSets, Services, VirtualServices, Notebook Pods
- **Integration Points**: jupyter-web-app (creates Notebook CRs), Kubernetes API, Istio, Prometheus

#### kubeflow-dataflow.mmd
Three key sequence flows:
1. **Notebook Creation**: User → jupyter-web-app → Kubernetes API → NotebookReconciler → StatefulSet/Service/VirtualService → Notebook Pod
2. **Notebook Culling**: CullingReconciler → Notebook Pod (/api/kernels) → Check idle time → Update Notebook CR with STOP_ANNOTATION → Scale down StatefulSet
3. **Metrics Collection**: Prometheus → kube-rbac-proxy (RBAC enforcement) → Manager /metrics → List StatefulSets → Calculate metrics

#### kubeflow-security-network.txt / .mmd
Comprehensive network security diagram with:
- **External Access**: User → Istio Gateway (443/HTTPS TLS1.2+) → VirtualService → Notebook Service → Notebook Pod (8888/HTTP plaintext)
- **Controller Operations**: Manager → Kubernetes API (443/HTTPS, ServiceAccount token) → Watch/Manage Notebooks, StatefulSets, Services, VirtualServices
- **Culling Access**: CullingReconciler → Notebook Pod (8888/HTTP, no authentication) for kernel activity checks
- **Metrics**: Prometheus → kube-rbac-proxy (8443/HTTPS, RBAC SubjectAccessReview) → Manager /metrics
- **RBAC Summary**: ClusterRoles (role, auth-proxy-role), RoleBindings, permissions for StatefulSets, Services, Notebooks, VirtualServices, Events, Pods
- **Security Considerations**: FIPS compliance, non-root execution (UID 1001), culling security risks (requires AuthorizationPolicy in production)

#### kubeflow-dependencies.mmd
Shows relationships to:
- **External Dependencies (Required)**: Kubernetes 1.22.0+, controller-runtime
- **External Dependencies (Optional)**: Istio (VirtualService creation when USE_ISTIO=true), Prometheus (metrics), Kubebuilder (build-time only)
- **Internal ODH Dependencies**: components/common (shared utilities), Istio Gateway (routes traffic when USE_ISTIO=true)
- **Integration Points**: jupyter-web-app (creates Notebook CRs), ODH Dashboard (UI integration)
- **Managed Resources**: StatefulSets, Services, VirtualServices → Notebook Pods
- **External Services**: S3/Object Storage, Git repositories, Databases (accessed by notebook pods)

#### kubeflow-rbac.mmd
Complete RBAC permissions showing:
- **Service Account**: service-account (odh-notebook-controller namespace)
- **ClusterRole 'role'**: Cluster-wide permissions for Events, Pods, Services, StatefulSets (apps), Notebooks (kubeflow.org), VirtualServices (networking.istio.io)
- **ClusterRole 'auth-proxy-role'**: SubjectAccessReviews, TokenReviews for kube-rbac-proxy
- **Role 'leader-election-role'**: Namespace-scoped ConfigMap permissions for leader election
- **ClusterRoleBindings**: role-binding, auth-proxy-role-binding (cluster-wide)
- **RoleBinding**: leader-election-role-binding (namespace-scoped)

#### kubeflow-c4-context.dsl
Architectural context showing:
- **People**: Data Scientist (creates and manages Jupyter notebook instances)
- **Notebook Controller containers**: Manager (NotebookReconciler, CullingReconciler, Metrics Exporter), kube-rbac-proxy
- **External systems**: Kubernetes API Server, Istio (VirtualServices), Prometheus (metrics)
- **Internal ODH**: jupyter-web-app (creates Notebook CRs)
- **Managed resources**: Notebook Pods (Jupyter server instances)
- **Data flows**: User → jupyter-web-app → Notebook CR → NotebookReconciler → StatefulSet/Service/VirtualService → Notebook Pod

## Architecture Summaries

### KubeRay

**KubeRay** is a Kubernetes operator that manages the lifecycle of Ray clusters for distributed computing and ML workloads:

- **Core CRDs**: RayCluster (clusters), RayJob (job submission), RayService (zero-downtime serving)
- **Multi-tenant security**: NetworkPolicy-based isolation, namespace-scoped resources
- **OAuth integration**: Automatic OAuth proxy injection for Ray dashboard authentication (OpenShift)
- **mTLS support**: cert-manager integration for encrypted inter-pod communication
- **Zero-downtime upgrades**: RayService controller manages rolling updates
- **Fault tolerance**: External Redis backend for GCS metadata persistence
- **Autoscaling**: Ray in-tree autoscaler with minReplicas/maxReplicas

**RHOAI-Specific Features**:
- Konflux build pipeline with FIPS-enabled Go builds on UBI9
- OpenShift Routes for first-class external access
- Gateway API support for advanced routing with HTTPRoutes
- SecurityContextConstraints: Custom SCC `run-as-ray-user` for Ray pods
- NetworkPolicy defaults via annotation for secure multi-tenant deployments

**Key Components**:
- **KubeRay Operator**: Main controller managing RayCluster, RayJob, RayService lifecycle
- **Specialized Controllers**: Authentication (OAuth/OIDC), NetworkPolicy, mTLS certificate management
- **Webhooks**: Validating and mutating admission control
- **Ray Cluster**: Head pod (GCS, dashboard, client API) + N worker pods

**Integration**: Tightly integrated with RHOAI ecosystem including OpenShift OAuth, Routes, cert-manager, Kueue (batch scheduling), and ODH Dashboard.

### KServe

**KServe** is a Kubernetes-native model serving platform providing:
- **Standardized inference protocols**: Support for TensorFlow, PyTorch, ONNX, SKLearn, XGBoost, Hugging Face models
- **Multiple deployment modes**: Serverless (Knative + autoscaling + scale-to-zero), RawDeployment (standard K8s + HPA/KEDA), ModelMesh (high-density multi-model)
- **Advanced features**: Canary rollouts, A/B testing, multi-step inference graphs, explainability
- **Production-ready**: mTLS service mesh, token-based authorization, metrics, health checks, GPU autoscaling
- **Flexible runtimes**: TensorFlow Serving, Triton, TorchServe, MLServer, vLLM, Text Generation Inference (TGI), custom servers
- **Cloud-native storage**: S3, GCS, PVC, OCI registries for model artifacts

**Key Components**:
- Controller Manager: Reconciles InferenceService CRDs and manages lifecycle
- Webhook Server: Validates and mutates CRDs with intelligent defaults
- Storage Initializer: Downloads models from cloud storage before serving starts
- Agent Sidecar: Provides logging, batching, and model agent capabilities
- Router Service: Implements multi-step inference graphs with routing logic

**Integration**: Tightly integrated with OpenShift AI (RHOAI) / Open Data Hub (ODH) ecosystem including Model Registry, ODH Dashboard, Data Science Pipelines, and Service Mesh.

### Kubeflow (Notebook Controller)

**Notebook Controller** is a Kubernetes operator that manages Jupyter notebook instances via a custom Notebook CRD:

- **Declarative notebook management**: Create and manage Jupyter notebook instances through Notebook Custom Resources
- **Multiple API versions**: v1, v1beta1, v1alpha1 with conversion support for backward compatibility
- **StatefulSet-based instances**: Stable pod identity and persistent storage association for notebook workloads
- **Optional Istio integration**: VirtualService creation for external access (configurable via USE_ISTIO flag)
- **Notebook culling**: Automatic idle notebook termination to optimize resource utilization (configurable via ENABLE_CULLING flag)
- **Prometheus metrics**: Monitoring of notebook creation, failures, and active instances across the cluster
- **Security**: FIPS-compliant, non-root execution (UID 1001), cluster-wide RBAC permissions, OpenShift restricted SCC compatible

**Key Components**:
- **NotebookReconciler**: Main controller that reconciles Notebook CRs by creating/updating StatefulSets, Services, and Istio VirtualServices
- **CullingReconciler**: Optional controller that monitors notebook kernel activity via /api/kernels and stops idle notebooks
- **Metrics Exporter**: Exposes Prometheus metrics for notebook operations and running instances
- **kube-rbac-proxy**: Optional sidecar for securing metrics endpoint with RBAC enforcement

**Key Configuration**:
- **USE_ISTIO** (default: true on Kubeflow, false on OpenShift): Enable Istio VirtualService creation
- **ENABLE_CULLING** (default: false): Enable notebook culling controller
- **CULL_IDLE_TIME** (default: 1440 minutes): Time before idle notebooks are culled
- **ADD_FSGROUP** (default: true): Automatically add fsGroup:100 to pod security context for proper file permissions

**Security Considerations**:
- **Culling Security**: CullingReconciler accesses notebook /api/kernels endpoint without authentication by default (requires Istio AuthorizationPolicy in production)
- **Namespace Isolation**: Each notebook runs in its own StatefulSet with namespace-level isolation (no built-in multi-tenancy controls)
- **FIPS Compliance**: Built with FIPS-enabled Go toolchain (GOEXPERIMENT=strictfipsruntime) using Red Hat UBI9 images

**Integration**: Part of the Kubeflow ecosystem, consumed by jupyter-web-app UI for spawning notebooks, integrated with Istio for traffic management and mTLS, and monitored via Prometheus metrics.

---

## Llama Stack K8s Operator

Generated from: `architecture/rhoai-3.2/llama-stack-k8s-operator.md`

All Mermaid diagrams are available in both `.mmd` (source) and `.png` (3000px width, high-resolution) formats.

### For Developers
- [Component Structure](./llama-stack-k8s-operator-component.png) ([mmd](./llama-stack-k8s-operator-component.mmd)) - Mermaid diagram showing operator controllers, Llama Stack server deployments, and resource management
- [Data Flows](./llama-stack-k8s-operator-dataflow.png) ([mmd](./llama-stack-k8s-operator-dataflow.mmd)) - Sequence diagram of LlamaStackDistribution creation, inference requests, metrics collection, and ConfigMap updates
- [Dependencies](./llama-stack-k8s-operator-dependencies.png) ([mmd](./llama-stack-k8s-operator-dependencies.mmd)) - Component dependency graph showing Kubernetes, controller-runtime, Llama Stack distributions, and integrations with ODH Dashboard, vLLM, Ollama, and HuggingFace Hub

### For Architects
- [C4 Context](./llama-stack-k8s-operator-c4-context.dsl) - System context in C4 format (Structurizr) showing Llama Stack Operator in RHOAI ecosystem
- [Component Overview](./llama-stack-k8s-operator-component.png) ([mmd](./llama-stack-k8s-operator-component.mmd)) - High-level component view with operator, managed resources, and external integrations

### For Security Teams
- [Security Network Diagram (PNG)](./llama-stack-k8s-operator-security-network.png) - High-resolution network topology with trust zones and detailed flows
- [Security Network Diagram (Mermaid)](./llama-stack-k8s-operator-security-network.mmd) - Visual network topology (editable, color-coded trust boundaries)
- [Security Network Diagram (ASCII)](./llama-stack-k8s-operator-security-network.txt) - Precise text format for SAR submissions with detailed network flows, RBAC summary (operator and Llama Stack server service accounts), NetworkPolicy rules (feature-flagged), secrets inventory (ServiceAccount tokens, HuggingFace tokens), and OpenShift SCC requirements
- [RBAC Visualization](./llama-stack-k8s-operator-rbac.png) ([mmd](./llama-stack-k8s-operator-rbac.mmd)) - RBAC permissions and bindings for controller-manager service account and Llama Stack server service accounts

### Llama Stack K8s Operator Summary

**Llama Stack K8s Operator** is a Kubernetes operator that automates deployment and lifecycle management of Llama Stack servers for LLM inference and agent workflows:

- **Core CRD**: LlamaStackDistribution (llamastack.io/v1alpha1) - Defines desired state for Llama Stack server deployments
- **Multiple distributions**: Support for starter, remote-vllm, meta-reference-gpu, postgres-demo, and custom images
- **Enterprise features**: Horizontal Pod Autoscaling (HPA), PodDisruptionBudget (PDB), topology-aware scheduling, uvicorn multi-worker support
- **Flexible storage**: Optional persistent storage (PVC) for model artifacts and datasets
- **Configuration management**: ConfigMap-based run.yaml configuration with hot-reload on updates
- **TLS support**: CA bundle management for secure external connections with ODH Trusted CA Bundle auto-detection
- **Network isolation**: Optional NetworkPolicy creation (feature-flagged) for ingress control
- **Image override system**: ConfigMap-driven image mappings for independent security/bug fix patching

**Key Components**:
- **LlamaStackDistribution Controller**: Main reconciliation controller that watches LlamaStackDistribution CRs
- **Cluster Info Manager**: Manages distribution images, feature flags, and ConfigMap overrides
- **Kustomizer**: Renders Kubernetes manifests from kustomize templates with instance-specific transformations
- **Resource Helper**: Constructs Kubernetes resources (Deployments, Services, PVCs, HPAs, PDBs, NetworkPolicies)
- **Network Policy Manager**: Creates and manages NetworkPolicy resources when feature flag is enabled
- **CA Bundle Manager**: Detects and manages TLS CA certificate bundles for secure connections
- **Metrics Exporter**: Exposes Prometheus metrics via kube-rbac-proxy on port 8443
- **Health Probe Handler**: Provides /healthz and /readyz endpoints on port 8081

**Created Resources**:
For each LlamaStackDistribution CR, the operator creates:
- Deployment (Llama Stack server with configurable replicas)
- ClusterIP Service (port 8321/TCP for Llama Stack API)
- ServiceAccount (with ClusterRole 'view' binding for K8s API access)
- RoleBinding (grants read-only access to Kubernetes API)
- Optional: PersistentVolumeClaim (model storage)
- Optional: HorizontalPodAutoscaler (CPU/memory-based autoscaling)
- Optional: PodDisruptionBudget (ensures availability during voluntary disruptions)
- Optional: NetworkPolicy (ingress control when feature flag enabled)

**Llama Stack Server API**:
- **Default port**: 8321/TCP (HTTP, no authentication by default)
- **Health check**: /v1/health
- **API endpoints**: /v1/* (inference, agents, safety, etc.)
- **Workers**: Configurable uvicorn worker count for production throughput
- **External exposure**: Requires manual Ingress/Route creation (not created by operator)

**Integration Points**:
- **ODH Dashboard**: UI for creating and managing LlamaStackDistribution CRs
- **ODH Trusted CA Bundle**: Auto-detects ConfigMap for TLS certificate injection
- **Model Registry**: Llama Stack servers can query for model metadata
- **vLLM/Ollama**: Remote inference backends (HTTP/gRPC on 8000/11434)
- **HuggingFace Hub**: Model and dataset downloads (HTTPS/443, optional HF Token)
- **Container Registry**: Pull Llama Stack distribution images (quay.io, docker.io)
- **Prometheus**: Metrics scraping via ServiceMonitor

**Security**:
- **Operator pod**: Non-root (UID 1001), requires anyuid SCC on OpenShift
- **Llama Stack pods**: fsGroup 1001 for volume permissions, requires anyuid SCC on OpenShift
- **Metrics auth**: kube-rbac-proxy with Bearer Token and SubjectAccessReview
- **API security**: No built-in authentication (users must implement external auth proxy for production)
- **Network isolation**: Optional NetworkPolicy (disabled by default, feature-flagged)
- **RBAC**: ClusterRole 'manager-role' for operator, ClusterRole 'view' for Llama Stack server pods

**Operational Features**:
- **Leader election**: Single operator replica with Lease-based leader election (ID: 54e06e98.llamastack.io)
- **ConfigMap-driven config**: Feature flags and image overrides via llama-stack-operator-config ConfigMap
- **Version tracking**: Operator and server versions in status.version fields
- **Upgrade support**: One-time cleanup operations, ConfigMap image overrides enable updates without operator upgrade
- **High availability**: Multi-replica Llama Stack servers, HPA, PDB, topology spread constraints

**Feature Flags** (ConfigMap: llama-stack-operator-config):
- `enableNetworkPolicy.enabled` (default: false): Enable NetworkPolicy creation for Llama Stack servers
- `image-overrides` (map): Override distribution images by name for security patching

**Recent Enhancements**:
- Uvicorn multi-worker support for production workloads and improved concurrency
- ConfigMap-driven image override system for independent security patching
- ARM64/multi-architecture support (AWS Graviton, etc.)
- Enhanced TLS CA bundle management with ODH Trusted CA Bundle auto-detection
- Improved upgrade handling and version tracking

**Known Limitations**:
- No built-in authentication for Llama Stack API (requires external proxy)
- NetworkPolicy feature opt-in (disabled by default)
- No automatic Ingress/Route creation (manual configuration required)
- PVC resizing requires manual intervention (StatefulSet not used)
- Requires anyuid SCC on OpenShift

**RHOAI-Specific Features**:
- Konflux build pipeline with FIPS-enabled Go builds on UBI9 images
- OpenShift SecurityContextConstraints (anyuid) integration
- ODH Dashboard integration for UI-based management
- ODH Trusted CA Bundle auto-detection for enterprise TLS
- RHOAI operator deployment and lifecycle management


---

## MLflow Operator

Generated from: `architecture/rhoai-3.2/mlflow-operator.md`

All Mermaid diagrams are available in both `.mmd` (source) and `.png` (3000px width, high-resolution) formats.

### For Developers
- [Component Structure](./mlflow-operator-component.png) ([mmd](./mlflow-operator-component.mmd)) - Mermaid diagram showing operator controllers (Helm renderer, ConsoleLink manager, HTTPRoute manager), MLflow instance resources (Deployment, Service, PVC, TLS secrets), and external dependencies
- [Data Flows](./mlflow-operator-dataflow.png) ([mmd](./mlflow-operator-dataflow.mmd)) - Sequence diagrams of MLflow instance creation, API requests with kubernetes-auth, artifact uploads to S3/PostgreSQL, and Prometheus metrics collection
- [Dependencies](./mlflow-operator-dependencies.png) ([mmd](./mlflow-operator-dependencies.mmd)) - Component dependency graph showing Kubernetes, OpenShift (service-ca, ConsoleLink), PostgreSQL, S3, Gateway API, and ODH integrations (Dashboard, Notebooks, Pipelines)

### For Architects
- [C4 Context](./mlflow-operator-c4-context.dsl) - System context in C4 format (Structurizr) showing MLflow Operator in RHOAI ecosystem
- [Component Overview](./mlflow-operator-component.png) ([mmd](./mlflow-operator-component.mmd)) - High-level component view with operator, Helm renderer, and managed MLflow instances

### For Security Teams
- [Security Network Diagram (PNG)](./mlflow-operator-security-network.png) - High-resolution network topology with trust zones and detailed flows
- [Security Network Diagram (Mermaid)](./mlflow-operator-security-network.mmd) - Visual network topology (editable, color-coded trust boundaries)
- [Security Network Diagram (ASCII)](./mlflow-operator-security-network.txt) - Precise text format for SAR submissions with detailed network flows, RBAC summary (operator and MLflow instance service accounts), NetworkPolicy rules, secrets inventory (TLS certs, DB/S3 credentials), and authentication flow details
- [RBAC Visualization](./mlflow-operator-rbac.png) ([mmd](./mlflow-operator-rbac.mmd)) - RBAC permissions and bindings for controller-manager and mlflow-sa service accounts, plus aggregate roles (mlflow-view, mlflow-edit)

### MLflow Operator Summary

**MLflow Operator** is a Kubernetes operator that provides declarative, Kubernetes-native management of MLflow deployments for experiment tracking and model registry:

- **Core CRD**: MLflow (mlflow.opendatahub.io/v1) - Defines desired state for MLflow server instances
- **Helm-based deployment**: Uses embedded Helm charts (helm.sh/helm/v3) to render Kubernetes manifests internally
- **Dual mode**: Supports RHOAI (redhat-ods-applications) and ODH (opendatahub) deployment modes
- **Kubernetes authentication**: Built-in `self_subject_access_review` authentication mode (no special RBAC required for users)
- **TLS termination**: TLS 1.3 termination in uvicorn within the MLflow container
- **Automatic TLS certificates**: service-ca-operator integration on OpenShift for automatic certificate provisioning and rotation
- **Workspaces feature**: Maps Kubernetes namespaces to MLflow workspaces (requires namespace list permissions)
- **Flexible storage**: Local PVC (development) or remote PostgreSQL + S3 (production)
- **OpenShift integration**: ConsoleLink creation for application menu integration
- **Gateway API support**: HTTPRoute creation for ingress routing
- **High availability**: Multi-replica support when using remote storage (single replica with PVC due to ReadWriteOnce)

**Key Components**:
- **mlflow-operator-manager**: Main controller with leader election that reconciles MLflow CRs
- **Helm Chart Renderer**: Embedded Helm library (helm.sh/helm/v3) for rendering MLflow manifests
- **ConsoleLink Manager**: Creates OpenShift console application menu links
- **HTTPRoute Manager**: Creates Gateway API HTTPRoutes for ingress
- **MLflow Server**: Python/uvicorn serving MLflow REST API and web UI on port 8443/TCP HTTPS

**Created Resources**:
For each MLflow CR, the operator creates:
- Deployment (MLflow server with configurable replicas)
- ClusterIP Service (port 8443/TCP HTTPS)
- ServiceAccount (mlflow-sa with ClusterRole 'mlflow' for namespace listing)
- ClusterRoleBinding (grants namespace list/get/watch for workspaces feature)
- NetworkPolicy (allow 8443/TCP ingress, unrestricted egress)
- PersistentVolumeClaim (optional, for local SQLite backend)
- HTTPRoute (Gateway API ingress routing)
- ConsoleLink (OpenShift application menu integration)
- Secret (TLS certificate auto-provisioned by service-ca-operator on OpenShift)

**MLflow API**:
- **Default port**: 8443/TCP (HTTPS, TLS 1.3)
- **Authentication**: Bearer Token (Kubernetes ServiceAccount token) validated via `self_subject_access_review`
- **Health check**: /health (no authentication)
- **API endpoints**: /api/* (MLflow REST API for experiments, runs, models, artifacts)
- **Web UI**: /* (MLflow web interface for experiment tracking and model registry)

**Integration Points**:
- **Kubernetes API**: Resource management (HTTPS/6443) and user authentication (self_subject_access_review)
- **service-ca-operator**: Automatic TLS certificate provisioning via Service annotation (OpenShift)
- **Gateway API**: HTTPRoute creation for ingress routing
- **OpenShift Console**: ConsoleLink CRD for application menu integration
- **PostgreSQL**: Backend and registry store for MLflow metadata (optional, 5432/TCP)
- **S3 Storage**: Artifact storage for models and files (optional, HTTPS/443)
- **ODH Dashboard**: UI integration for MLflow instance management
- **Jupyter Notebooks**: MLflow client integration for experiment logging
- **Data Science Pipelines**: Auto-logging of pipeline runs and models
- **Prometheus**: Metrics scraping from operator via ServiceMonitor (HTTPS/8443)

**Security**:
- **Operator pod**: Non-root, seccompProfile RuntimeDefault, readOnlyRootFilesystem, capabilities DROP ALL
- **MLflow pods**: Non-root, seccompProfile RuntimeDefault, readOnlyRootFilesystem=false (SQLite writes)
- **TLS**: Automatic certificate provisioning on OpenShift (service-ca-operator), 90-day rotation
- **Authentication**: kubernetes-auth with self_subject_access_review (caller token validated by K8s API)
- **Authorization**: No special RBAC required for API access (any valid K8s token can access)
- **Secrets**: Auto-rotating ServiceAccount tokens, auto-rotating TLS certificates (OpenShift), user-managed DB/S3 credentials
- **Network isolation**: NetworkPolicy allows 8443/TCP ingress from all, unrestricted egress for DB/S3/API access
- **FIPS compliance**: Built with `GOEXPERIMENT=strictfipsruntime` and `-tags strictfipsruntime`

**RBAC**:
- **Operator ClusterRole 'manager-role'**: MLflow CRs, namespaces, RBAC resources, ConsoleLinks, HTTPRoutes
- **Operator Namespace Role 'manager-role'**: ServiceAccounts, Services, Secrets, PVCs, Deployments, NetworkPolicies
- **MLflow ClusterRole 'mlflow'**: Namespaces (get, list, watch) for workspaces feature
- **Aggregate Roles**: mlflow-view (get/list/watch MLflows), mlflow-edit (create/update/patch/delete MLflows)

**Operational Features**:
- **Leader election**: Single operator replica with leader election (supports multiple replicas)
- **Resource requirements**: Operator (200m CPU / 400Mi RAM), MLflow (250m CPU / 512Mi RAM)
- **Scaling**: Horizontal scaling with remote storage, vertical scaling always supported
- **Monitoring**: Prometheus metrics from operator (/metrics on 8443/TCP), MLflow health checks (/health)
- **Logging**: Structured logging to stdout/stderr, configurable via MLFLOW_LOGGING_LEVEL

**Storage Options**:
- **Local PVC**: SQLite backend (default 2Gi), ReadWriteOnce, limits to single replica with Recreate strategy
- **Remote PostgreSQL**: Production backend/registry store, enables multi-replica with RollingUpdate strategy
- **Remote S3**: Production artifact storage (AWS S3, MinIO, Ceph), required for large artifacts and multi-replica

**Known Limitations**:
1. **Single MLflow CR per cluster**: MLflow CR name must be "mlflow" (enforced by CRD validation)
2. **PVC constraints**: Local PVC storage limits to single replica with Recreate deployment strategy
3. **Manual TLS outside OpenShift**: No automatic certificate rotation without service-ca-operator
4. **Shared ClusterRole**: MLflow ClusterRole has multiple owner references (non-standard controller ownership)
5. **Namespace enumeration**: Workspaces feature requires cluster-wide namespace list/get/watch permissions
6. **Gateway dependency**: HTTPRoute creation requires Gateway API CRDs and configured Gateway
7. **ConsoleLink dependency**: ConsoleLink creation requires OpenShift ConsoleLink CRD

**Recent Changes**:
- Updated base images (UBI9 go-toolset and ubi-minimal) with latest security patches
- Konflux pipeline synchronization for automated builds
- Digest-based image references for reproducible builds

**RHOAI-Specific Features**:
- Konflux build pipeline with FIPS-enabled Go builds on UBI9 images
- OpenShift service-ca-operator integration for automatic TLS certificates
- OpenShift ConsoleLink integration for application menu
- Gateway API HTTPRoute support for advanced routing
- RHOAI operator deployment to redhat-ods-applications namespace


---

## Model Registry Operator

Generated from: `architecture/rhoai-3.2/model-registry-operator.md`

All Mermaid diagrams are available in both `.mmd` (source) and `.png` (3000px width, high-resolution) formats.

### For Developers
- [Component Structure](./model-registry-operator-component.png) ([mmd](./model-registry-operator-component.mmd)) - Mermaid diagram showing operator controller, webhook server, Model Registry instances (REST API, OAuth/RBAC proxies, gRPC), and database backends (PostgreSQL/MySQL)
- [Data Flows](./model-registry-operator-dataflow.png) ([mmd](./model-registry-operator-dataflow.mmd)) - Sequence diagram of ModelRegistry CR creation, OAuth-secured API requests, database initialization, and operator metrics collection
- [Dependencies](./model-registry-operator-dependencies.png) ([mmd](./model-registry-operator-dependencies.mmd)) - Component dependency graph showing Kubernetes API, PostgreSQL/MySQL databases, OpenShift OAuth, cert-manager, Istio/Authorino (optional), and ODH integrations

### For Architects
- [C4 Context](./model-registry-operator-c4-context.dsl) - System context in C4 format (Structurizr) showing Model Registry Operator in RHOAI ML model lifecycle management ecosystem
- [Component Overview](./model-registry-operator-component.png) ([mmd](./model-registry-operator-component.mmd)) - High-level component view with operator, managed instances, and integration points

### For Security Teams
- [Security Network Diagram (PNG)](./model-registry-operator-security-network.png) - High-resolution network topology with trust zones (external, ingress DMZ, application layer, database layer, operator layer, service mesh)
- [Security Network Diagram (Mermaid)](./model-registry-operator-security-network.mmd) - Visual network topology (editable, color-coded trust boundaries)
- [Security Network Diagram (ASCII)](./model-registry-operator-security-network.txt) - Precise text format for SAR submissions with detailed network flows, RBAC summary (manager-role, proxy-role, registry-user roles), secrets inventory (OAuth/RBAC proxy TLS certs, webhook certs, DB credentials), NetworkPolicy rules (restrict to OpenShift router), and database security (TLS client certs)
- [RBAC Visualization](./model-registry-operator-rbac.png) ([mmd](./model-registry-operator-rbac.mmd)) - RBAC permissions and bindings for controller-manager service account and per-instance registry service accounts

### Model Registry Operator Summary

**Model Registry Operator** is a Kubernetes operator that manages the lifecycle of Model Registry instances and their associated resources:

- **Core CRDs**: ModelRegistry (v1beta1 - current, v1alpha1 - deprecated) - Defines desired state for Model Registry deployments
- **Conversion webhook**: Automatic conversion between v1alpha1 ↔ v1beta1 API versions
- **Multiple deployment modes**: Plain HTTP (disabled by default), OAuth Proxy, kube-rbac-proxy, Istio Service Mesh with Authorino
- **Database backends**: PostgreSQL 16+ (auto-provisioning supported) or MySQL 8.0+ (manual provisioning)
- **Optional TLS**: Database connection encryption with client certificate authentication
- **REST API**: Model Registry v1alpha3 REST API for model metadata operations
- **Legacy gRPC**: gRPC API on port 9090 (deprecated in v1beta1)

**Key Components**:
- **Controller Manager**: Reconciles ModelRegistry CRs and creates/manages deployments, services, routes, RBAC policies, network policies
- **Webhook Server**: Validates/mutates ModelRegistry CR operations and provides conversion webhooks
- **kube-rbac-proxy**: Secures operator metrics endpoint on port 8443
- **Model Registry REST API**: Python service providing HTTP/8080 (internal) or HTTPS/8443 (proxied) endpoints
- **OAuth Proxy** (optional): OpenShift OAuth authentication proxy for REST API
- **kube-rbac-proxy** (optional): Kubernetes RBAC authentication proxy for REST API

**Created Resources**:
For each ModelRegistry CR, the operator creates:
- Deployment (Model Registry server with optional proxy sidecars)
- ClusterIP Service (port 8080 for plain mode, 8443 for proxied mode)
- ServiceAccount (per-instance service account)
- Role + RoleBinding (registry-user-<name> role with GET on service)
- OpenShift Route (HTTP/80 or HTTPS/443 edge termination)
- NetworkPolicy (restrict ingress to OpenShift router namespace only)
- Optional: PostgreSQL Deployment + PVC (auto-provisioning)
- Secret (database credentials, TLS certificates)

**Model Registry REST API**:
- **Default port**: 8080/TCP (HTTP, no authentication - serviceRoute disabled by default)
- **Secured port**: 8443/TCP (HTTPS via OAuth/RBAC proxy with TLS 1.2+)
- **API endpoints**: /api/model_registry/v1alpha3/* (REST API for model metadata CRUD operations)
- **Health check**: /healthz, /readyz
- **Legacy gRPC**: 9090/TCP (deprecated in v1beta1)
- **External exposure**: OpenShift Route with edge TLS termination

**Integration Points**:
- **Kubernetes API Server**: CR reconciliation and resource management (HTTPS/443)
- **OpenShift OAuth Server**: User authentication for proxied services (OAuth 2.0)
- **OpenShift Router**: External route exposure (HTTP/80, HTTPS/443)
- **PostgreSQL/MySQL**: Model registry metadata storage (5432/3306 with optional TLS)
- **cert-manager** (optional): TLS certificate management
- **Istio + Authorino** (optional): Service mesh authentication (gRPC/50051 mTLS)
- **Prometheus**: Operator metrics collection (HTTPS/8443 via kube-rbac-proxy)
- **ODH Model Metadata Collection**: Catalog and benchmark data (image reference)
- **ODH Dashboard** (optional): UI for managing ModelRegistry CRs
- **Data Science Pipelines** (optional): Model registration during pipeline runs

**Security**:
- **Operator pod**: Non-root (UID 65532), restricted-v2 SCC on OpenShift, all capabilities dropped
- **Model Registry pods**: Non-root (UID 65532), all capabilities dropped, read-only root filesystem
- **Authentication modes**: OpenShift OAuth (Bearer Token), Kubernetes RBAC (Bearer Token + SubjectAccessReview), or None (disabled by default)
- **Network isolation**: NetworkPolicy restricts ingress to OpenShift router namespace only
- **Database encryption**: Optional TLS 1.2+ with client certificate authentication (PostgreSQL sslmode, MySQL tls=custom)
- **Secrets**: OAuth/RBAC proxy TLS certs (auto-rotated by OpenShift Service CA), webhook server cert (cert-manager), DB credentials
- **RBAC**: ClusterRole manager-role (operator), ClusterRole proxy-role (metrics), Role registry-user-<name> (per-instance GET on service)

**Operational Features**:
- **Leader election**: Single operator replica with Lease-based leader election
- **API version migration**: v1alpha1 (deprecated) to v1beta1 (current) with storage version migration support
- **Webhook validation**: Validates ModelRegistry CR fields before admission
- **Webhook mutation**: Sets default values for ModelRegistry CR
- **Auto-provisioning**: PostgreSQL database can be auto-provisioned with PVC storage
- **Schema migration**: Automatic database schema migration on startup (if enabled)
- **TLS support**: Webhook server, database connections, proxy endpoints all support TLS 1.2+

**Database Support**:
- **PostgreSQL 16+**: Primary supported database with auto-provisioning, SSL/TLS with client certs, connection string format `postgresql://user:pass@host:port/db?sslmode=require`
- **MySQL 8.0+**: Alternative database (manual provisioning), SSL/TLS with client certs, connection string format `user:pass@tcp(host:port)/db?charset=utf8mb4&tls=custom`

**Recent Changes**:
- UBI9 minimal base image security updates (digest: 759f5f4)
- Re-enabled default catalogs
- Ongoing dependency maintenance and security patches

**Known Limitations**:
- Plain HTTP mode (port 8080) disabled by default via serviceRoute: disabled
- gRPC API deprecated in v1beta1, will be removed in future releases
- MySQL requires manual provisioning (no auto-provisioning like PostgreSQL)
- v1alpha1 API version marked for removal in future releases

**RHOAI-Specific Features**:
- OpenShift OAuth integration for user authentication
- OpenShift Route creation for external exposure
- OpenShift Service CA for automatic TLS certificate rotation
- SecurityContextConstraints (restricted-v2) compliance
- ODH Dashboard integration for UI-based management
- ODH Model Metadata Collection for catalog data

---

## Notebooks

Generated from: `architecture/rhoai-3.2/notebooks.md`

All Mermaid diagrams are available in both `.mmd` (source) and `.png` (3000px width, high-resolution) formats.

### For Developers
- [Component Structure](./notebooks-component.png) ([mmd](./notebooks-component.mmd)) - Mermaid diagram showing workbench images (Jupyter, RStudio, CodeServer) and runtime images for pipelines
- [Data Flows](./notebooks-dataflow.png) ([mmd](./notebooks-dataflow.mmd)) - Sequence diagram of user workbench access via OAuth, pipeline runtime execution, and Konflux build/publish flows
- [Dependencies](./notebooks-dependencies.png) ([mmd](./notebooks-dependencies.mmd)) - Component dependency graph showing base OS (UBI9, CentOS Stream 9), ML frameworks (PyTorch, TensorFlow), GPU support (CUDA, ROCm), and ODH integrations

### For Architects
- [C4 Context](./notebooks-c4-context.dsl) - System context in C4 format (Structurizr) showing Notebooks in RHOAI ecosystem
- [Component Overview](./notebooks-component.png) ([mmd](./notebooks-component.mmd)) - High-level component view with workbench and runtime images

### For Security Teams
- [Security Network Diagram (PNG)](./notebooks-security-network.png) - High-resolution network topology with trust zones
- [Security Network Diagram (Mermaid)](./notebooks-security-network.mmd) - Visual network topology (editable, color-coded trust boundaries)
- [Security Network Diagram (ASCII)](./notebooks-security-network.txt) - Precise text format for SAR submissions with detailed network flows, RBAC summary, secrets inventory, and container security features
- [RBAC Visualization](./notebooks-rbac.png) ([mmd](./notebooks-rbac.mmd)) - RBAC permissions and bindings for notebook service accounts

### Notebooks Summary

**Notebooks** is a container image repository providing pre-built data science workbench and runtime images for RHOAI/ODH:

- **Workbench Images**: Interactive development environments
  - **JupyterLab**: Minimal, DataScience, PyTorch, TensorFlow, TrustyAI, PyTorch+LLMCompressor variants
  - **CodeServer**: VS Code in browser with data science libraries
  - **RStudio**: R development environment

- **Runtime Images**: Lightweight pipeline execution environments
  - **Minimal**: Basic Python runtime for pipeline tasks
  - **DataScience**: Common ML libraries (pandas, scikit-learn)
  - **PyTorch/TensorFlow**: GPU-accelerated training runtimes

- **GPU Support**:
  - **NVIDIA CUDA**: 12.6, 12.8 for x86_64 and arm64
  - **AMD ROCm**: 6.2, 6.3, 6.4 for x86_64

- **Multi-Architecture**: x86_64, arm64, ppc64le, s390x (CPU images); x86_64, arm64 (GPU images)

- **Base OS**: Red Hat UBI9/RHEL9 9.6 (workbenches), CentOS Stream 9 (RStudio)

- **Python Versions**: 3.11, 3.12 (transitioning to 3.12)

**Key Features**:
- **Pre-configured environments**: JupyterLab 4.4, jupyter-server 2.17, popular data science libraries
- **Build system**: Konflux CI/CD with multi-arch builds, vulnerability scanning (Clair/Snyk), SBOM generation (syft), image signing (Cosign)
- **Distribution**: Published to quay.io/opendatahub, referenced via OpenShift ImageStreams
- **Deployment**: Consumed by ODH Notebook Controller, Kubeflow Pipelines, and Elyra
- **Security**: Non-root execution (UID 1001), capabilities dropped, Seccomp runtime/default, SELinux enforcing
- **Access**: OAuth2 proxy sidecar provides authentication and TLS termination (HTTPS/443 → HTTP/8888)

**Integration Points**:
- **ODH Notebook Controller**: Launches workbench pods from these images
- **ODH Dashboard**: Lists available images via ImageStream metadata
- **Kubeflow Pipelines**: Executes pipeline tasks using runtime images
- **Elyra**: Submits notebook-based pipelines
- **OAuth Proxy**: Provides authentication and TLS for workbench access
- **OpenShift ImageStreams**: Manages image versions and distribution

**Workbench Deployment**:
Each workbench instance gets:
- Pod with two containers: Jupyter/RStudio/CodeServer + OAuth proxy sidecar
- ClusterIP Service (8888/TCP for workbench, 8443/TCP for OAuth proxy)
- OpenShift Route (HTTPS/443 external access)
- ServiceAccount with RBAC permissions (pods, services, configmaps, secrets, jobs)

**Egress Connections**:
- **Kubernetes API** (6443/TCP HTTPS): Create jobs, access resources
- **S3 Storage** (443/TCP HTTPS): Read/write data and models
- **Git Repositories** (443/TCP HTTPS): Clone repos, push changes
- **PyPI** (443/TCP HTTPS): Install Python packages

**Container Security**:
- Non-root user: UID 1001
- Read-only rootfs: No (workbenches need write access for user workspace)
- Capabilities: ALL dropped
- Seccomp profile: runtime/default
- SELinux: Enforcing
- Vulnerability scanning: Every build (Konflux/Clair)
- SBOM generation: Every build (syft)
- Signature verification: Cosign

**Version Management**:
- CalVer versioning: YYYY.N (e.g., 2025.2, 2025.1, 2024.2)
- Image lifecycle: N (current, fully supported), N-1 (security updates), N-2 (deprecated), N-3+ (unsupported)
- Support window: Minimum 6 months per major version

**Known Limitations**:
- GPU images limited to x86_64 (CUDA/ROCm vendor limitation)
- RStudio limited to C9S base (not all architectures)
- Workbenches require writable filesystem (cannot use read-only rootfs)
- GPU images are 5-10GB due to CUDA/ROCm dependencies
- Multi-arch builds can take 30-60 minutes

**RHOAI-Specific Features**:
- Konflux build pipeline with vulnerability scanning and signing
- Red Hat UBI9/RHEL9 base images for enterprise support
- OpenShift OAuth integration for workbench authentication
- ImageStream-based distribution for version management
- Integration with RHOAI operator and ODH Dashboard

---

## ODH Dashboard

Generated from: `architecture/rhoai-3.2/odh-dashboard.md`

All Mermaid diagrams are available in both `.mmd` (source) and `.png` (3000px width, high-resolution) formats.

### For Developers
- [Component Structure](./odh-dashboard-component.png) ([mmd](./odh-dashboard-component.mmd)) - Mermaid diagram showing frontend (React + PatternFly), backend (Node.js + Fastify), kube-rbac-proxy sidecar, module federation plugins (GenAI, Model Registry, MaaS), and custom resources (OdhApplication, OdhDocument, OdhQuickStart, OdhDashboardConfig)
- [Data Flows](./odh-dashboard-dataflow.png) ([mmd](./odh-dashboard-dataflow.mmd)) - Sequence diagram of user login/OAuth flow, notebook creation, Prometheus metrics queries, and model registry operations
- [Dependencies](./odh-dashboard-dependencies.png) ([mmd](./odh-dashboard-dependencies.mmd)) - Component dependency graph showing external dependencies (Node.js, Kubernetes, OpenShift, React, PatternFly), ODH integrations (KServe, Kubeflow Notebooks, Model Registry, Feast, LlamaStack), and OpenShift services (OAuth, Build Service, Image Registry)

### For Architects
- [C4 Context](./odh-dashboard-c4-context.dsl) - System context in C4 format (Structurizr) showing ODH Dashboard in RHOAI ecosystem with frontend/backend containers, module federation plugins, and integrations with Kubernetes, OpenShift OAuth, Thanos, and ODH components
- [Component Overview](./odh-dashboard-component.png) ([mmd](./odh-dashboard-component.mmd)) - High-level component view with web UI, backend API, OAuth authentication layer, and ODH component integrations

### For Security Teams
- [Security Network Diagram (PNG)](./odh-dashboard-security-network.png) - High-resolution network topology with trust zones (external, ingress DMZ, authentication layer, application layer)
- [Security Network Diagram (Mermaid)](./odh-dashboard-security-network.mmd) - Visual network topology (editable, color-coded trust boundaries and service flows)
- [Security Network Diagram (ASCII)](./odh-dashboard-security-network.txt) - Precise text format for SAR submissions with detailed network flows, authentication/authorization flow, RBAC summary (cluster-wide and namespace-scoped permissions), secrets inventory (dashboard-proxy-tls, odh-trusted-ca-bundle), NetworkPolicy configuration, and feature flags
- [RBAC Visualization](./odh-dashboard-rbac.png) ([mmd](./odh-dashboard-rbac.mmd)) - RBAC permissions and bindings for odh-dashboard service account (ClusterRole and namespace Role with permissions for ODH CRDs, OpenShift resources, core resources, and delegation roles)

### ODH Dashboard Summary

**ODH Dashboard** is the web-based console for Red Hat OpenShift AI (RHOAI) and Open Data Hub (ODH):

- **Core Purpose**: Unified web UI for data scientists and ML engineers to manage notebooks, model serving, data connections, model registries, and distributed workloads
- **Architecture**: React frontend + Node.js/Fastify backend + kube-rbac-proxy authentication sidecar
- **Module Federation**: Dynamic plugin system for loading UI extensions at runtime (GenAI, Model Registry, MaaS, KServe, Model Serving plugins)
- **Authentication**: OpenShift OAuth integration with bearer token validation via kube-rbac-proxy
- **Feature Flags**: Configurable via OdhDashboardConfig CR (projects, model serving, KServe, pipelines, distributed workloads, NIM serving, GenAI studio, training jobs)

**Key Components**:
- **Frontend**: React 18.2.0 + PatternFly 6.4.0 UI framework with module federation for dynamic plugins
- **Backend**: Node.js 22 + Fastify 4.28.1 REST API server, proxies Kubernetes API calls, handles authentication
- **kube-rbac-proxy**: OAuth sidecar (8443/TCP HTTPS) validates bearer tokens, injects user/group headers to backend (8080/TCP HTTP)
- **Module Federation Plugins**: GenAI, Model Registry, MaaS, KServe, Model Serving (loaded dynamically at runtime)

**Custom Resources**:
- **OdhApplication** (dashboard.opendatahub.io/v1): Defines applications in dashboard catalog (Jupyter, Starburst, NVIDIA tools)
- **OdhDashboardConfig** (opendatahub.io/v1alpha): Dashboard feature flags, notebook sizes, model serving settings
- **OdhDocument** (dashboard.opendatahub.io/v1): Documentation links and resources
- **OdhQuickStart** (console.openshift.io/v1): Interactive tutorials for guided workflows

**Network Architecture**:
- **External Access**: OpenShift Route (443/TCP HTTPS TLS 1.2+) → kube-rbac-proxy (8443/TCP HTTPS) → Backend (8080/TCP HTTP localhost)
- **Egress**: Kubernetes API (6443/TCP HTTPS), Thanos Querier (9092/TCP HTTPS), Model Registry (8080/TCP HTTP/HTTPS), Feast Registry (8080/TCP HTTP/HTTPS), OpenShift OAuth (6443/TCP HTTPS), Image Registry (5000/TCP HTTPS)
- **Service**: ClusterIP (8443/TCP), exposed via OpenShift Route or HTTPRoute (Gateway API)

**Integration Points**:
- **ODH Components**: KServe (InferenceService management), Kubeflow Notebooks (Notebook CR creation), Model Registry (ML model tracking), Feast (feature store), LlamaStack (GenAI workloads), NVIDIA NIM (model serving)
- **OpenShift Services**: OAuth (authentication), Build Service (notebook image builds), Image Registry (metadata inspection), Routes (external access)
- **Monitoring**: Thanos/Prometheus (metrics queries for dashboards)

**RBAC**:
- **ServiceAccount**: odh-dashboard (dashboard namespace)
- **ClusterRole**: Cluster-wide permissions for nodes, configmaps, secrets, namespaces, users, groups, ODH CRDs (DataScienceCluster, Notebook, InferenceService, ModelRegistry, FeatureStore, LlamaStackDistribution), OpenShift resources (Routes, ImageStreams, ClusterServiceVersions)
- **Namespace Role**: Dashboard namespace permissions for OdhDashboardConfig, templates, serving runtimes, accelerator profiles, NVIDIA NIM accounts
- **Additional Bindings**: system:auth-delegator (token delegation), system:image-puller (container images), cluster-monitoring-view (Prometheus/Thanos access)

**Security**:
- **OAuth Integration**: All requests authenticated via OpenShift OAuth before reaching backend
- **TLS Encryption**: External traffic TLS 1.2+ (user → Route → kube-rbac-proxy), internal HTTP (proxy → backend on localhost)
- **Two-Layer Authorization**: (1) kube-rbac-proxy validates OAuth token, (2) backend enforces resource-level RBAC
- **Secret Management**: dashboard-proxy-tls (auto-rotated by OpenShift), odh-trusted-ca-bundle (cluster CA operator)
- **Content Security**: DOMPurify for XSS protection in user-generated content
- **Network Policies**: Allow ingress to ports 8443, 8043, 8143/TCP; egress unrestricted for K8s API access

**Deployment**:
- **Replicas**: 2 (high availability with pod anti-affinity)
- **Resources**: CPU 500m request / 1000m limit, Memory 1Gi request / 2Gi limit
- **Health Probes**: Liveness (TCP :8080 for backend, HTTPS :8444 for proxy), Readiness (HTTP /api/health :8080)
- **Base Image**: registry.access.redhat.com/ubi9/nodejs-22

**API Endpoints** (all via 8443/TCP HTTPS with OAuth Bearer Token):
- `/` - Dashboard frontend (React SPA)
- `/api/k8s/*` - Proxy to Kubernetes API
- `/api/notebooks/*` - Jupyter notebook management
- `/api/servingRuntimes/*` - Model serving runtime management
- `/api/modelRegistries/*` - Model registry operations
- `/api/prometheus/*` - Metrics queries to Thanos
- `/api/config`, `/api/dashboardConfig` - Dashboard configuration
- `/api/quickstarts`, `/api/docs`, `/api/components` - Learning resources
- `/api/health` (8080/TCP HTTP, no auth) - Backend health check

**Feature Flags** (OdhDashboardConfig CR):
- `disableProjects`, `disableModelServing`, `disableKServe`, `disableModelRegistry` (default: false)
- `disableDistributedWorkloads`, `disablePipelines`, `disableNIMModelServing` (default: false)
- `genAiStudio`, `modelAsService`, `trainingJobs` (default: false - opt-in features)

**Known Limitations**:
- Requires OpenShift OAuth (not compatible with standalone Kubernetes)
- Broad cluster-level RBAC permissions (can create RoleBindings, potential privilege escalation risk)
- No built-in multi-tenancy (users see all projects they have access to)
- Module federation plugins require network access to federated endpoints
- Browser compatibility requires ES2020+ support
- OpenShift-specific features (ImageStreams, Templates, Routes) not available on vanilla Kubernetes

**RHOAI-Specific Features**:
- Konflux build pipeline with UBI9/Node.js 22 base images
- OpenShift OAuth, Routes, ImageStreams, Templates integration
- OpenShift-branded UI (Red Hat OpenShift AI logo, documentation links, support links)
- Integration with RHOAI operator for deployment and lifecycle management
- PatternFly design system for Red Hat UX consistency

---

## RHOAI Operator

Generated from: `architecture/rhoai-3.2/rhods-operator.md`
Component: rhods-operator
Version: v1.6.0-5936-g181aacbe8 (rhoai-3.2 branch)

All Mermaid diagrams are available in both `.mmd` (source) and `.png` (3000px width, high-resolution) formats.

### For Developers
- [Component Structure](./rhods-operator-component.png) ([mmd](./rhods-operator-component.mmd)) - Mermaid diagram showing internal components, controllers, and their relationships
- [Data Flows](./rhods-operator-dataflow.png) ([mmd](./rhods-operator-dataflow.mmd)) - Sequence diagram of DataScienceCluster reconciliation and metrics collection
- [Dependencies](./rhods-operator-dependencies.png) ([mmd](./rhods-operator-dependencies.mmd)) - Component dependency graph showing required/optional dependencies and deployed components

### For Architects
- [C4 Context](./rhods-operator-c4-context.dsl) - System context in C4 format (Structurizr) showing operator in broader RHOAI ecosystem
- [Component Overview](./rhods-operator-component.png) ([mmd](./rhods-operator-component.mmd)) - High-level component view with controllers and services

### For Security Teams
- [Security Network Diagram (PNG)](./rhods-operator-security-network.png) - High-resolution network topology with trust boundaries
- [Security Network Diagram (Mermaid)](./rhods-operator-security-network.mmd) - Visual network topology (editable, color-coded zones)
- [Security Network Diagram (ASCII)](./rhods-operator-security-network.txt) - Precise text format for SAR submissions with RBAC, NetworkPolicy, and Secrets details
- [RBAC Visualization](./rhods-operator-rbac.png) ([mmd](./rhods-operator-rbac.mmd)) - RBAC permissions, ClusterRoles, and ServiceAccount bindings

### Component Overview

**RHOAI Operator** is the primary control plane operator for Red Hat OpenShift AI. It orchestrates deployment, configuration, and lifecycle management of data science platform components.

**Purpose**: Platform operator that manages the lifecycle of Red Hat OpenShift AI (RHOAI) data science components and infrastructure through declarative DataScienceCluster (DSC) and DSCInitialization (DSCI) CRDs.

### Architecture Highlights

**Internal Structure**:
- **DSC Controller**: Reconciles DataScienceCluster resources and manages component lifecycle
- **DSCI Controller**: Initializes platform infrastructure (monitoring, service mesh, trusted CA)
- **Component Controllers**: Individual controllers for dashboard, kserve, workbenches, pipelines, model registry, ray, training operator, trustyai, kueue, feast, mlflow, llama stack
- **Service Controllers**: Manage auth, monitoring, and gateway services
- **Webhook Server**: Validates and mutates DSC and DSCI resources (9443/TCP HTTPS)
- **Manifest Deployer**: Applies kustomize manifests from /opt/manifests to cluster
- **Monitoring Stack**: Prometheus, Alertmanager, Blackbox Exporter

**Custom Resource Definitions**:
- `datasciencecluster.opendatahub.io/v1` - DataScienceCluster: Declares desired state of platform components
- `dscinitialization.opendatahub.io/v1` - DSCInitialization: Initializes platform infrastructure
- `components.opendatahub.io/v1alpha1` - Component CRs: Dashboard, DataSciencePipelines, Kserve, Kueue, Ray, TrustyAI, ModelRegistry, TrainingOperator, Workbenches, FeastOperator, MLflowOperator, LlamaStackOperator
- `services.opendatahub.io/v1alpha1` - Service CRs: Auth, Monitoring, Gateway
- `infrastructure.opendatahub.io/v1` - HardwareProfile: Defines hardware profiles for workloads

**Dependencies**:
- **Required**: Kubernetes/OpenShift 1.28+/4.14+, OLM
- **Optional**: OpenShift Service Mesh (Istio 2.x), OpenShift Serverless (Knative 1.x), cert-manager 1.x
- **Bundled**: Prometheus Operator 0.68.0

**Managed Components** (configured via DataScienceCluster CR):
- ODH Dashboard - Web console and UI
- Workbenches - Jupyter notebook environments
- Data Science Pipelines - Kubeflow/Tekton pipelines
- KServe - Model serving (RawDeployment/Serverless)
- Model Registry - Model versioning and metadata
- Ray - Distributed computing
- Training Operator - Distributed training (TFJob, PyTorchJob, etc.)
- TrustyAI - Model explainability and fairness
- Kueue - Job queuing and resource management (default: Removed)
- Feast Operator - Feature store
- MLflow Operator - Experiment tracking (default: Removed)
- Llama Stack Operator - LLM deployment (default: Removed)

**Platform Services**:
- Monitoring - Prometheus/Alertmanager stack (Managed/Removed)
- Auth - OAuth/RBAC configuration (Managed/Removed)
- Gateway - API gateway, Istio/Gateway API (Managed/Removed)
- TrustedCABundle - Custom CA injection (Managed/Removed)

**Network Services**:
- `controller-manager-metrics-service` - 8443/TCP HTTPS (TLS via kube-rbac-proxy + service-ca, Bearer Token auth) - Prometheus metrics scraping
- `webhook-service` - 443/TCP → 9443/TCP HTTPS (TLS 1.2+ service-ca, mTLS from API server) - Validating/Mutating webhooks
- `prometheus` - 9091/TCP HTTP internal, exposed via Route (HTTPS/443 Edge TLS + OpenShift OAuth)
- `alertmanager` - 9093/TCP HTTP internal, exposed via Route (HTTPS/443 Edge TLS + OpenShift OAuth)
- `blackbox-exporter` - 9115/TCP HTTP internal

**Health Endpoints** (internal only):
- `/healthz` - 8081/TCP HTTP - Liveness probe
- `/readyz` - 8081/TCP HTTP - Readiness probe

**Data Flows**:
1. **DataScienceCluster Reconciliation**: User creates DSC → API server calls webhook for validation (9443/TCP mTLS) → DSC Controller watches and reconciles → Creates Component CRs → Component Controllers deploy manifests via Kustomize → Resources created in cluster
2. **Metrics Collection**: Prometheus scrapes operator metrics (8443/TCP HTTPS, Bearer Token, kube-rbac-proxy) → ServiceMonitors for component metrics → Alertmanager for alerting
3. **Component Deployment**: Component Controller loads /opt/manifests → Kustomize build → Apply to K8s API (6443/TCP HTTPS, ServiceAccount token) → Sub-operators reconcile

**RBAC**:
- **ServiceAccount**: controller-manager (redhat-ods-operator namespace)
- **ClusterRole**: opendatahub-operator-manager-role
  - Full control (all verbs) over ODH CRDs: datascienceclusters, dscinitializations, components.*, services.*, infrastructure.*
  - Full control over core resources: pods, services, serviceaccounts, secrets, configmaps, persistentvolumeclaims
  - Full control over apps: deployments, replicasets, statefulsets
  - Full control over RBAC: roles, rolebindings, clusterroles, clusterrolebindings (enables component RBAC setup)
  - Full control over networking: networkpolicies, ingresses, routes (OpenShift)
  - Full control over monitoring: servicemonitors, podmonitors, prometheusrules, prometheuses, alertmanagers
  - Full control over CRDs, SCCs (securitycontextconstraints), OAuthClients
  - Manage OLM resources: subscriptions, clusterserviceversions, catalogsources (get, list, watch, delete, update)
  - Read-only cluster config: clusterversions, proxies (get, list, watch)
  - Create/get tokenreviews and subjectaccessreviews
- **Prometheus ServiceAccount**: prometheus (redhat-ods-monitoring) with cluster-monitoring-view and view roles

**Security**:
- **Webhook Authentication**: mTLS (Kubernetes API Server client certificate)
- **Metrics Authentication**: Bearer Token (ServiceAccount) via kube-rbac-proxy
- **External Access**: HTTPS/443 with TLS 1.2+ edge termination and OpenShift OAuth (Prometheus/Alertmanager UIs)
- **Secrets**: 
  - `opendatahub-operator-controller-webhook-cert` (kubernetes.io/tls) - Webhook TLS cert, service-ca-operator, auto-rotated
  - `prometheus-proxy-tls` (kubernetes.io/tls) - Prometheus metrics proxy TLS, service-ca, auto-rotated
  - `alertmanager-proxy-tls` (kubernetes.io/tls) - Alertmanager proxy TLS, service-ca, auto-rotated
- **NetworkPolicies**:
  - `redhat-ods-operator` - Allow ingress from: redhat-ods-monitoring, openshift-monitoring, openshift-user-workload-monitoring, openshift-console, openshift-operators, ODH namespaces, host-network
  - `monitoring-namespace` - Allow ingress from: same namespace, openshift-monitoring, ODH namespaces
- **Security Context**: runAsNonRoot, allowPrivilegeEscalation: false, drop all capabilities, seccompProfile: RuntimeDefault

**High Availability**:
- **Replicas**: 3 with pod anti-affinity
- **Leader Election**: Enabled (lease-based, ID: 07ed84f7.opendatahub.io)
- **Fault Tolerance**: Automatic failover on leader failure

**Deployment**:
- **Namespace**: redhat-ods-operator (RHOAI) or opendatahub (ODH)
- **Resources**: CPU 100m request / 500m limit, Memory 780Mi request / 4Gi limit
- **Base Images**: Builder: registry.redhat.io/ubi9/go-toolset:1.25, Runtime: registry.access.redhat.com/ubi9/ubi-minimal
- **Build Mode**: Multi-stage with FIPS-compliant Go runtime
- **Manifest Inclusion**: /opt/manifests and prefetched-manifests baked into image at build time

**Known Limitations**:
- Primarily designed for OpenShift; some features require OpenShift-specific APIs
- Some components require external operators (Service Mesh, Serverless)
- Operator must run in specific namespace (redhat-ods-operator or opendatahub)
- Only one DataScienceCluster CR supported per cluster
- Component manifests baked into operator image at build time (immutable)

**RHOAI-Specific Features**:
- Konflux-based production builds with FIPS-compliant Go runtime
- OpenShift integration (Routes, OAuth, SCCs, ImageStreams, ClusterVersions)
- Managed/self-managed deployment models via ODH_PLATFORM_TYPE
- Integration with OpenShift Service Mesh and Serverless for KServe
- Built-in monitoring stack with Prometheus/Alertmanager
- Automated cleanup of deprecated resources during upgrades
- CRD versioning with v1/v2 APIs and conversion webhooks


---

## Trainer

Generated from: `architecture/rhoai-3.2/trainer.md`

All Mermaid diagrams are available in both `.mmd` (source) and `.png` (3000px width, high-resolution) formats.

### For Developers
- [Component Structure](./trainer-component.png) ([mmd](./trainer-component.mmd)) - Mermaid diagram showing trainer-controller-manager, webhook server, controllers (TrainJob, TrainingRuntime, ClusterTrainingRuntime), progression watcher (RHOAI plugin), and integration with JobSet controller for distributed training
- [Data Flows](./trainer-dataflow.png) ([mmd](./trainer-dataflow.mmd)) - Sequence diagram of TrainJob submission, webhook validation, JobSet creation, training pod execution with S3 dataset download/checkpoint upload, and distributed training communication
- [Dependencies](./trainer-dependencies.png) ([mmd](./trainer-dependencies.mmd)) - Component dependency graph showing external dependencies (JobSet, Kubernetes, Volcano, Kueue, cert-manager), RHOAI integrations (opendatahub-operator, Dashboard, Metrics/Monitoring, Model Registry, S3), and training workload flows

### For Architects
- [C4 Context](./trainer-c4-context.dsl) - System context in C4 format (Structurizr) showing Kubeflow Trainer in distributed training ecosystem with controller components (TrainJob Controller, TrainingRuntime Controller, ClusterTrainingRuntime Controller, Progression Watcher), webhook validation, and dependencies on JobSet, Volcano, Kubernetes, cert-manager, RHOAI Dashboard, Prometheus, Model Registry, S3, and Container Registry
- [Component Overview](./trainer-component.png) ([mmd](./trainer-component.mmd)) - High-level component view with controller manager, CRD controllers, webhook server, and integrations with JobSet/Volcano for distributed training orchestration

### For Security Teams
- [Security Network Diagram (PNG)](./trainer-security-network.png) - High-resolution network topology with trust zones (external, Kubernetes control plane, opendatahub namespace, user namespaces)
- [Security Network Diagram (Mermaid)](./trainer-security-network.mmd) - Visual network topology (editable, color-coded trust boundaries for controller, workloads, external services)
- [Security Network Diagram (ASCII)](./trainer-security-network.txt) - Precise text format for SAR submissions with detailed network flows (webhook validation, controller reconciliation, training job execution), authentication/authorization mechanisms, RBAC summary (ClusterRole permissions for CRDs, JobSets, PodGroups, ConfigMaps, Secrets), secrets inventory (webhook TLS cert), security context (runAsNonRoot, no privilege escalation), and security considerations for training workloads
- [RBAC Visualization](./trainer-rbac.png) ([mmd](./trainer-rbac.mmd)) - RBAC permissions and bindings for kubeflow-trainer-controller-manager service account with ClusterRole permissions for core resources, JobSets, PodGroups, trainer.kubeflow.org CRDs, finalizers, and status updates

### Trainer Summary

**Trainer** (Kubeflow Trainer, formerly Kubeflow Training Operator) is a Kubernetes-native operator for distributed training of large language models (LLMs) and machine learning workloads:

- **Core Purpose**: Declarative API for running distributed ML training jobs across PyTorch, JAX, TensorFlow, and other frameworks using Kubernetes-native resources
- **Architecture**: Controller-based operator that reconciles TrainJob, TrainingRuntime, and ClusterTrainingRuntime CRDs and creates JobSet resources for distributed workload execution
- **Training Runtimes**: Namespaced (TrainingRuntime) and cluster-scoped (ClusterTrainingRuntime) templates that define training execution environments with framework-specific configurations
- **JobSet Backend**: Uses JobSet CRD for multi-job coordination and distributed training pod management (replaces direct pod management in Training Operator v1)
- **Scheduling Integration**: Supports Volcano gang scheduling and Kueue job queueing for optimized resource allocation across distributed training jobs
- **RHOAI Features**: Progression watcher plugin for distributed training observability, CUDA 12.8 and ROCm 6.4 GPU-optimized training runtimes

**Key Components**:
- **trainer-controller-manager**: Main controller deployment that reconciles TrainJob, TrainingRuntime, and ClusterTrainingRuntime resources
- **TrainJob Controller**: Watches TrainJob CRs, resolves runtime references, creates JobSet resources with merged configuration
- **TrainingRuntime Controller**: Manages namespaced TrainingRuntime resources that define training execution templates
- **ClusterTrainingRuntime Controller**: Manages cluster-scoped ClusterTrainingRuntime resources for shared training templates across namespaces
- **Webhook Server**: Validates TrainJob, TrainingRuntime, and ClusterTrainingRuntime resources on CREATE/UPDATE operations (9443/TCP HTTPS mTLS)
- **Progression Watcher**: RHOAI-specific plugin that tracks distributed training job progression and updates status

**Custom Resources**:
- **TrainJob** (trainer.kubeflow.org/v1alpha1): Namespaced resource representing a training job with dataset, model, training parameters, and runtime reference
- **TrainingRuntime** (trainer.kubeflow.org/v1alpha1): Namespaced training runtime template that can be referenced by TrainJobs in the same namespace
- **ClusterTrainingRuntime** (trainer.kubeflow.org/v1alpha1): Cluster-wide training runtime template that can be referenced by TrainJobs in any namespace

**Built-in ClusterTrainingRuntimes** (RHOAI):
- **torch-distributed**: PyTorch distributed training on NVIDIA GPUs (CUDA 12.8, PyTorch 2.8.0, image: quay.io/modh/training:py312-cuda128-torch280)
- **torch-distributed-rocm**: PyTorch distributed training on AMD GPUs (ROCm 6.4, PyTorch 2.8.0, image: quay.io/modh/training:py312-rocm64-torch280)
- **training-hub**: Generic training runtime for custom frameworks (CUDA 12.8, PyTorch 2.8.0)

**Network Architecture**:
- **Webhook Service**: ClusterIP 443/TCP → 9443/TCP HTTPS TLS 1.2+ mTLS (validates TrainJob/Runtime CRs from Kubernetes API)
- **Health Checks**: HTTP 8081/TCP (/healthz liveness, /readyz readiness, no auth)
- **Metrics**: HTTPS 8443/TCP (/metrics, Bearer Token auth, scraped by Prometheus PodMonitor)
- **Egress**: Kubernetes API (6443/TCP HTTPS, watch CRDs, create JobSets), S3 Storage (443/TCP HTTPS, datasets/checkpoints), Container Registry (443/TCP HTTPS, pull images), Volcano API (6443/TCP HTTPS, create PodGroups for gang scheduling)
- **Training Pod Communication**: Pod-to-pod TCP 29500 (PyTorch distributed), unencrypted NCCL/GLOO on trusted pod network

**Integration Points**:
- **JobSet Controller**: Trainer creates JobSet resources; JobSet controller creates Jobs and Pods for distributed training workloads
- **Volcano Scheduler**: Optional gang scheduling for multi-pod training jobs (creates PodGroups in scheduling.volcano.sh API)
- **Kueue/scheduler-plugins**: Optional job queueing and coscheduling for training jobs
- **RHOAI Dashboard**: Users create TrainJobs through dashboard UI (creates TrainJob CRs via Kubernetes API)
- **Prometheus**: Metrics collection via PodMonitor (scrapes controller_runtime_reconcile_total, controller_runtime_reconcile_errors_total, controller_runtime_reconcile_time_seconds, workqueue metrics)
- **Model Registry**: Training jobs may store trained model metadata to model registry (optional)
- **S3 Storage**: Training pods download datasets and upload checkpoints to S3-compatible object storage

**Data Flows**:

1. **TrainJob Submission**: User/Dashboard → Kubernetes API (HTTPS/6443 Bearer Token) → Webhook Server (HTTPS/9443 mTLS validation) → TrainJob CR created
2. **Controller Reconciliation**: TrainJob Controller watches TrainJob CR → resolves TrainingRuntime/ClusterTrainingRuntime → merges configuration → creates JobSet resource
3. **JobSet to Pods**: JobSet Controller watches JobSet → creates Jobs (master + workers) → creates Pods → Kubernetes Scheduler assigns Pods to nodes
4. **Training Execution**: Training Pods → download datasets from S3 (HTTPS/443 S3 credentials) → distributed training (pod-to-pod TCP/29500 NCCL) → upload checkpoints to S3
5. **Status Updates**: JobSet status updates → TrainJob Controller watches → updates TrainJob status (Completed/Failed)
6. **Metrics**: Prometheus scrapes controller metrics (HTTPS/8443 Bearer Token)

**RBAC**:
- **ServiceAccount**: kubeflow-trainer-controller-manager (opendatahub namespace)
- **ClusterRole**: kubeflow-trainer-controller-manager with permissions for:
  - Core resources: configmaps, secrets (create, get, list, patch, update, watch), events (create, patch, update, watch), limitranges (get, list, watch)
  - Admission control: validatingwebhookconfigurations (get, list, update, watch)
  - Coordination: leases (create, get, list, update) - leader election
  - JobSet API: jobsets (create, get, list, patch, update, watch)
  - Node API: runtimeclasses (get, list, watch)
  - Scheduling APIs: podgroups in scheduling.volcano.sh and scheduling.x-k8s.io (create, get, list, patch, update, watch)
  - Trainer CRDs: clustertrainingruntimes, trainingruntimes, trainjobs (get, list, patch, update, watch)
  - Finalizers/Status: clustertrainingruntimes/finalizers, trainingruntimes/finalizers, trainjobs/finalizers, trainjobs/status (get, patch, update)
- **ClusterRoleBinding**: kubeflow-trainer-controller-manager (cluster-wide binding)

**Security**:
- **Controller Security**: runAsNonRoot: true, allowPrivilegeEscalation: false, capabilities.drop: ALL, seccompProfile: RuntimeDefault
- **Webhook Security**: TLS 1.2+ enforced, mTLS authentication from Kubernetes API server, webhook cert (kubeflow-trainer-webhook-cert) provisioned by cert-controller/kustomize secretGenerator (manual rotation)
- **Training Pod Security**: Pods run in user namespaces with user-controlled ServiceAccounts, S3 credentials in Kubernetes secrets (recommend encryption at rest or IRSA for AWS), GPU access requires privileged capabilities
- **Network Security**: Pod-to-pod training traffic unencrypted for performance (NCCL over TCP), trust boundary assumes pod network is trusted, recommend isolating training namespaces from sensitive workloads
- **API Security**: Alpha API (v1alpha1) - use with caution in production, webhook validation prevents malformed TrainJob submissions, RBAC limits who can create TrainJob resources

**Deployment**:
- **Namespace**: opendatahub (RHOAI deployment)
- **Replicas**: 1 (single controller instance with leader election via Kubernetes leases)
- **Resources**: CPU/Memory requests/limits not specified (default to namespace LimitRange or cluster defaults)
- **Images**:
  - Controller: quay.io/opendatahub/trainer:v2.1.0 (Konflux build from odh-trainer-rhel9)
  - Training Runtimes: quay.io/modh/training:py312-cuda128-torch280 (CUDA 12.8), quay.io/modh/training:py312-rocm64-torch280 (ROCm 6.4)
- **Health Probes**: Liveness (HTTP GET /healthz :8081, initial 15s, period 20s, timeout 3s), Readiness (HTTP GET /readyz :8081, initial 10s, period 15s, timeout 3s)

**Controller Behavior**:
- **Reconciliation**: TrainJob Controller watches TrainJob CRs → resolves runtime reference → validates configuration → creates JobSet → updates TrainJob status based on JobSet conditions → handles finalizers for cleanup on deletion
- **Leader Election**: Uses Kubernetes leases (coordination.k8s.io), single active controller instance, automatic failover on pod failure
- **Observability**: Structured JSON logging (zap logger), controller_runtime metrics (reconcile operations, errors, duration), workqueue metrics (depth, adds)

**Endpoints**:
- `/healthz` - Liveness probe (HTTP 8081/TCP, no auth)
- `/readyz` - Readiness probe (HTTP 8081/TCP, no auth)
- `/validate-trainer-kubeflow-org-v1alpha1-trainjob` - Validating webhook for TrainJob (HTTPS 9443/TCP, mTLS)
- `/validate-trainer-kubeflow-org-v1alpha1-trainingruntime` - Validating webhook for TrainingRuntime (HTTPS 9443/TCP, mTLS)
- `/validate-trainer-kubeflow-org-v1alpha1-clustertrainingruntime` - Validating webhook for ClusterTrainingRuntime (HTTPS 9443/TCP, mTLS)
- `/metrics` - Prometheus metrics (HTTPS 8443/TCP, Bearer Token in RHOAI)

**Known Limitations**:
- **Alpha Status**: APIs in v1alpha1 may change; not recommended for production without thorough testing
- **Single Controller**: No horizontal scaling; single pod handles all TrainJob reconciliation (leader election for high availability)
- **No Built-in Autoscaling**: Training jobs do not automatically scale based on resource availability (manual scaling via TrainJob spec)
- **Limited Framework Support**: Built-in runtimes focus on PyTorch; other frameworks (TensorFlow, JAX, MPI) require custom TrainingRuntime/ClusterTrainingRuntime definitions
- **JobSet Dependency**: Requires JobSet CRD v1alpha2 (v0.10.1) to be installed separately (not bundled in RHOAI manifests)

**Migration from Training Operator v1**:
- **API Changes**: New TrainJob API replaces framework-specific CRDs (PyTorchJob, TFJob, MPIJob, XGBoostJob)
- **Runtime Abstraction**: TrainingRuntime/ClusterTrainingRuntime provide template-based configuration (replaces framework-specific operators)
- **JobSet Backend**: Uses JobSet instead of direct Pod management for improved multi-job coordination
- **Backward Compatibility**: RHOAI includes v1 training runtimes for transition period (torch-distributed-th03-cuda128-torch28-py312, training-hub03-cuda128-torch28-py312)

**Dependencies**:
- **Required**: JobSet (jobset.x-k8s.io/v1alpha2 v0.10.1), Kubernetes (v1.29+)
- **Optional**: Volcano (v1.13+ for gang scheduling), Kueue/scheduler-plugins (v1alpha1 for job queueing), cert-manager (v1.0+ for webhook TLS cert provisioning)
- **RHOAI**: opendatahub-operator (CRD lifecycle management), RHOAI Dashboard (TrainJob creation UI), RHOAI Metrics/Monitoring (PodMonitor for controller metrics), Model Registry (store trained models), S3 Storage (datasets/checkpoints)
