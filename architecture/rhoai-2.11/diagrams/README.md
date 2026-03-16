# Architecture Diagrams for RHOAI 2.11 Components

Generated from architecture documentation in: `architecture/rhoai-2.11/`
Date: 2026-03-15

This directory contains architecture diagrams for all RHOAI 2.11 components. All Mermaid diagrams are available in both `.mmd` (source) and `.png` (3000px width, high-resolution) formats.

## Components

- [Platform Overview](#platform-overview-red-hat-openshift-ai-211)
- [CodeFlare Operator](#codeflare-operator)
- [Data Science Pipelines Operator](#data-science-pipelines-operator)
- [KServe](#kserve)
- [Kubeflow](#kubeflow)
- [KubeRay](#kuberay)
- [Kueue](#kueue)
- [ModelMesh Serving](#modelmesh-serving)
- [Notebooks](#notebooks)
- [ODH Dashboard](#odh-dashboard)
- [ODH Model Controller](#odh-model-controller)
- [RHODS Operator](#rhods-operator)
- [Training Operator](#training-operator)
- [TrustyAI Service Operator](#trustyai-service-operator)

---

## Platform Overview: Red Hat OpenShift AI 2.11

**Source**: `architecture/rhoai-2.11/PLATFORM.md`
**Purpose**: Comprehensive platform architecture showing all 13 components, their relationships, workflows, and integration patterns

### Diagrams

**For Developers**:
- [Component Structure](./platform-component.png) ([mmd](./platform-component.mmd)) - All 13 platform components and their relationships (RHODS Operator, Dashboard, Notebooks, KServe, Model Controller, ModelMesh, DSP, Training, KubeRay, CodeFlare, Kueue, TrustyAI, Monitoring)
- [Data Flows](./platform-dataflow.png) ([mmd](./platform-dataflow.mmd)) - End-to-end workflows: model development to deployment, distributed training, ML pipelines, Ray workloads, model monitoring
- [Dependencies](./platform-dependencies.png) ([mmd](./platform-dependencies.mmd)) - Platform-wide dependency graph showing component relationships and external service dependencies

**For Architects**:
- [C4 Context](./platform-c4-context.dsl) - System context (Structurizr) showing RHOAI ecosystem with OpenShift, Istio, Knative, S3, registries
- [Component Overview](./platform-component.png) ([mmd](./platform-component.mmd)) - High-level view of entire platform architecture
- [Dependencies](./platform-dependencies.png) ([mmd](./platform-dependencies.mmd)) - Integration patterns and external dependencies

**For Security Teams**:
- [Security Network (PNG)](./platform-security-network.png) - High-resolution network topology with all trust zones, namespaces, ports, protocols
- [Security Network (Mermaid)](./platform-security-network.mmd) - Visual network topology showing ingress, service mesh, applications, monitoring
- [Security Network (ASCII)](./platform-security-network.txt) - Comprehensive SAR documentation with RBAC summary, Service Mesh config, secrets inventory, network policies
- [RBAC Visualization](./platform-rbac.png) ([mmd](./platform-rbac.mmd)) - Platform-wide RBAC for all 13 components with ServiceAccounts, ClusterRoles, and API resource permissions

### Platform Components (13 Total)

**Platform Management**:
- RHODS Operator (v1.6.0-641) - Platform orchestrator
- DataScienceCluster & DSCInitialization CRs

**User Interface**:
- ODH Dashboard (v1.21.0-18) - Web UI, 2 replicas HA

**Workbenches**:
- Notebook Controller (1.27.0-rhods-318)
- Notebook Images (v1.1.1-700) - JupyterLab, RStudio, VS Code

**Model Serving**:
- KServe (v0.12.1) - Single-model serverless serving
- ODH Model Controller (1.27.0-rhods-427) - 3 replicas HA, OpenShift integration
- ModelMesh Serving (1.27.0-rhods-254) - Multi-model serving

**ML Pipelines**:
- Data Science Pipelines Operator (8d084e4) - Argo/Tekton orchestration

**Distributed Training**:
- Training Operator (20c6ede9) - PyTorch, TensorFlow, MPI, XGBoost

**Distributed Computing**:
- KubeRay (v1.1.0) - Ray cluster management
- CodeFlare Operator (7460aa9) - Ray security enhancements

**Resource Management**:
- Kueue (ae90a64c9) - Job queueing and quotas

**Model Monitoring**:
- TrustyAI Service Operator (1.17.0) - Explainability and bias detection

**Monitoring Infrastructure**:
- Prometheus, Alertmanager

### Key Workflows

1. **Model Development to Deployment**:
   - User → Dashboard → Notebook Controller → JupyterLab
   - Model training → S3 upload
   - InferenceService creation → KServe → Model Controller
   - Route/VirtualService/AuthConfig creation
   - Inference requests → Istio Gateway → Knative → Predictor
   - TrustyAI monitors for bias

2. **Distributed Training Job**:
   - PyTorchJob CR → Training Operator
   - Kueue queueing and quota evaluation
   - Master/worker pod creation
   - Inter-pod communication (port 23456)
   - Checkpoint saving to S3

3. **ML Pipeline Execution**:
   - DataSciencePipelinesApplication → DSPO
   - Argo Workflows orchestration
   - MariaDB metadata, S3 artifacts
   - Multi-stage pipeline execution

4. **Distributed Ray Workload**:
   - AppWrapper → CodeFlare → Kueue
   - RayCluster deployment with OAuth dashboard
   - Ray head/worker coordination
   - Distributed Python workload execution

5. **Model Monitoring**:
   - TrustyAIService → InferenceService patching
   - Payload processor injection
   - Fairness metrics calculation
   - Prometheus export and alerting

### Platform Namespaces

| Namespace | Purpose | Components |
|-----------|---------|------------|
| redhat-ods-operator | Control plane | RHODS Operator |
| redhat-ods-applications | Platform services | Dashboard, controllers, operators (11 components) |
| redhat-ods-monitoring | Monitoring | Prometheus, Alertmanager |
| istio-system | Service mesh | Istio control plane (optional) |
| knative-serving | Serverless | Knative controllers (optional) |
| User namespaces | Workloads | Notebooks, InferenceServices, training, Ray, TrustyAI |

### External Dependencies

**Infrastructure** (Required):
- OpenShift Container Platform 4.12+
- Istio/Maistra (for KServe)
- Knative Serving 1.12+ (for KServe serverless)
- cert-manager 1.13+

**Storage** (Required):
- S3-compatible storage (AWS S3, MinIO, OpenShift Data Foundation)
- Container Registry (Quay.io, Red Hat registries)

**External Services** (Optional):
- Git repositories (GitHub, GitLab)
- Package repositories (PyPI, Conda)
- External databases (MySQL/PostgreSQL for pipelines)

### Security Features

**Authentication**:
- OpenShift OAuth (Dashboard, Notebooks, Pipelines, Ray, TrustyAI, Prometheus)
- mTLS (Istio STRICT for InferenceServices, webhook certificates)
- ServiceAccount tokens (all operators)
- AWS IAM/S3 credentials (model storage)

**Network Security**:
- TLS 1.2+ for all external communication
- mTLS STRICT mode in service mesh
- OpenShift Routes with TLS reencrypt
- OAuth proxy sidecars for authentication

**Secrets Management**:
- Webhook certificates (cert-manager, 90d rotation)
- OAuth proxy TLS (service-ca, auto-rotation)
- Storage credentials (admin-created)
- Database passwords (admin-created)
- Ray mTLS CA (CodeFlare-generated)

### Platform Maturity

- **Total Components**: 13 (11 operators, 1 web app, 1 image collection)
- **API Stability**: v1 (core), v1beta1 (model serving), v1alpha1 (new features)
- **Service Mesh Coverage**: Full integration for KServe, optional for others
- **Security Posture**: Non-root, no privilege escalation, FIPS compliance, OpenShift OAuth
- **High Availability**: Dashboard (2 replicas), Model Controller (3 replicas), leader election for operators

---

## CodeFlare Operator

**Source**: `architecture/rhoai-2.11/codeflare-operator.md`
**Purpose**: Kubernetes operator for installation and lifecycle management of CodeFlare distributed workload stack with enhanced security (OAuth, mTLS, network policies)

### Diagrams

**For Developers**:
- [Component Structure](./codeflare-operator-component.png) ([mmd](./codeflare-operator-component.mmd)) - Internal components, controllers, webhooks
- [Data Flows](./codeflare-operator-dataflow.png) ([mmd](./codeflare-operator-dataflow.mmd)) - RayCluster creation, AppWrapper admission, OAuth flows
- [Dependencies](./codeflare-operator-dependencies.png) ([mmd](./codeflare-operator-dependencies.mmd)) - External dependencies and integrations

**For Architects**:
- [C4 Context](./codeflare-operator-c4-context.dsl) - System context (Structurizr)

**For Security Teams**:
- [Security Network (PNG)](./codeflare-operator-security-network.png) - High-resolution network topology
- [Security Network (Mermaid)](./codeflare-operator-security-network.mmd) - Visual network topology (editable)
- [Security Network (ASCII)](./codeflare-operator-security-network.txt) - Precise text for SAR
- [RBAC Visualization](./codeflare-operator-rbac.png) ([mmd](./codeflare-operator-rbac.mmd)) - RBAC permissions

### Key Features
- OAuth proxy injection for Ray Dashboard (OpenShift)
- mTLS enforcement for Ray cluster communication
- Network isolation with NetworkPolicies
- AppWrapper integration with Kueue for gang scheduling
- Certificate management (webhook TLS, Ray cluster CA)

---

## Data Science Pipelines Operator

**Source**: `architecture/rhoai-2.11/data-science-pipelines-operator.md`

### Diagrams

**For Developers**:
- [Component Structure](./data-science-pipelines-operator-component.png) ([mmd](./data-science-pipelines-operator-component.mmd))
- [Data Flows](./data-science-pipelines-operator-dataflow.png) ([mmd](./data-science-pipelines-operator-dataflow.mmd))
- [Dependencies](./data-science-pipelines-operator-dependencies.png) ([mmd](./data-science-pipelines-operator-dependencies.mmd))

**For Architects**:
- [C4 Context](./data-science-pipelines-operator-c4-context.dsl)

**For Security Teams**:
- [Security Network (PNG)](./data-science-pipelines-operator-security-network.png) - High-resolution network topology
- [Security Network (Mermaid)](./data-science-pipelines-operator-security-network.mmd) - Visual network topology (editable)
- [Security Network (ASCII)](./data-science-pipelines-operator-security-network.txt) - Precise text format for SAR submissions
- [RBAC Visualization](./data-science-pipelines-operator-rbac.png) ([mmd](./data-science-pipelines-operator-rbac.mmd)) - RBAC permissions and bindings

---

## KServe

**Source**: `architecture/rhoai-2.11/kserve.md`

### Diagrams

**For Developers**:
- [Component Structure](./kserve-component.png) ([mmd](./kserve-component.mmd))
- [Data Flows](./kserve-dataflow.png) ([mmd](./kserve-dataflow.mmd))
- [Dependencies](./kserve-dependencies.png) ([mmd](./kserve-dependencies.mmd))

**For Architects**:
- [C4 Context](./kserve-c4-context.dsl)

**For Security Teams**:
- [Security Network (PNG)](./kserve-security-network.png)
- [Security Network (Mermaid)](./kserve-security-network.mmd)
- [Security Network (ASCII)](./kserve-security-network.txt)

---

## Kubeflow

**Source**: `architecture/rhoai-2.11/kubeflow.md`

### Diagrams

**For Developers**:
- [Component Structure](./kubeflow-component.png) ([mmd](./kubeflow-component.mmd))
- [Data Flows](./kubeflow-dataflow.png) ([mmd](./kubeflow-dataflow.mmd))
- [Dependencies](./kubeflow-dependencies.png) ([mmd](./kubeflow-dependencies.mmd))

**For Architects**:
- [C4 Context](./kubeflow-c4-context.dsl)

**For Security Teams**:
- [Security Network (PNG)](./kubeflow-security-network.png)
- [Security Network (Mermaid)](./kubeflow-security-network.mmd)
- [Security Network (ASCII)](./kubeflow-security-network.txt)
- [RBAC Visualization](./kubeflow-rbac.png) ([mmd](./kubeflow-rbac.mmd))

---

## KubeRay

**Source**: `architecture/rhoai-2.11/kuberay.md`

### Diagrams

**For Developers**:
- [Component Structure](./kuberay-component.png) ([mmd](./kuberay-component.mmd))
- [Data Flows](./kuberay-dataflow.png) ([mmd](./kuberay-dataflow.mmd))
- [Dependencies](./kuberay-dependencies.png) ([mmd](./kuberay-dependencies.mmd))

**For Architects**:
- [C4 Context](./kuberay-c4-context.dsl)

**For Security Teams**:
- [Security Network (PNG)](./kuberay-security-network.png)
- [Security Network (Mermaid)](./kuberay-security-network.mmd)
- [Security Network (ASCII)](./kuberay-security-network.txt)
- [RBAC Visualization](./kuberay-rbac.png) ([mmd](./kuberay-rbac.mmd))

---

## ODH Model Controller

**Source**: `architecture/rhoai-2.11/odh-model-controller.md`
**Purpose**: Extends KServe and ModelMesh serving capabilities with OpenShift-specific integrations for routing, service mesh, authorization, and monitoring

### Diagrams

**For Developers**:
- [Component Structure](./odh-model-controller-component.png) ([mmd](./odh-model-controller-component.mmd)) - Internal components, reconcilers, webhook server
- [Data Flows](./odh-model-controller-dataflow.png) ([mmd](./odh-model-controller-dataflow.mmd)) - InferenceService creation flows, monitoring, storage secret management
- [Dependencies](./odh-model-controller-dependencies.png) ([mmd](./odh-model-controller-dependencies.mmd)) - External and internal dependencies

**For Architects**:
- [C4 Context](./odh-model-controller-c4-context.dsl) - System context (Structurizr)

**For Security Teams**:
- [Security Network (PNG)](./odh-model-controller-security-network.png) - High-resolution network topology
- [Security Network (Mermaid)](./odh-model-controller-security-network.mmd) - Visual network topology (editable)
- [Security Network (ASCII)](./odh-model-controller-security-network.txt) - Precise text for SAR submissions
- [RBAC Visualization](./odh-model-controller-rbac.png) ([mmd](./odh-model-controller-rbac.mmd)) - RBAC permissions and bindings

### Key Features
- Multi-mode reconciliation: KServe Serverless, KServe Raw, ModelMesh
- Istio/Service Mesh integration (VirtualServices, Gateways, PeerAuthentication)
- OpenShift Route creation for external access
- Authorino integration for API authorization
- Webhook validation for Knative Services
- Serving runtime templates (OVMS, TGIS, Caikit, vLLM)
- Model Registry integration for versioning

---

## RHODS Operator

**Source**: `architecture/rhoai-2.11/rhods-operator.md`
**Purpose**: Primary operator for Red Hat OpenShift AI that manages the lifecycle of data science platform components through custom resources

### Diagrams

**For Developers**:
- [Component Structure](./rhods-operator-component.png) ([mmd](./rhods-operator-component.mmd)) - Internal components, controllers (DSC, DSCI, SecretGenerator, CertGenerator), and reconcilers
- [Data Flows](./rhods-operator-dataflow.png) ([mmd](./rhods-operator-dataflow.mmd)) - Component deployment, monitoring/metrics, secret and certificate generation flows
- [Dependencies](./rhods-operator-dependencies.png) ([mmd](./rhods-operator-dependencies.mmd)) - Platform dependencies and deployed ODH components

**For Architects**:
- [C4 Context](./rhods-operator-c4-context.dsl) - System context (Structurizr)

**For Security Teams**:
- [Security Network (PNG)](./rhods-operator-security-network.png) - High-resolution network topology
- [Security Network (Mermaid)](./rhods-operator-security-network.mmd) - Visual network topology (editable)
- [Security Network (ASCII)](./rhods-operator-security-network.txt) - Precise text for SAR submissions with detailed RBAC and network policies
- [RBAC Visualization](./rhods-operator-rbac.png) ([mmd](./rhods-operator-rbac.mmd)) - RBAC permissions and bindings for controller-manager and prometheus service accounts

### Key Features
- Core orchestration for RHOAI/ODH platform (deploys Dashboard, KServe, ModelMesh, DSP, Workbenches, CodeFlare, Ray, Kueue, Training Operator, TrustyAI)
- Two primary CRs: DSCInitialization (platform infrastructure) and DataScienceCluster (component enablement)
- Platform initialization: service mesh configuration, monitoring stack deployment, namespace and RBAC setup
- Component manifest management: fetches from GitHub repos (build time), applies via kustomize
- Monitoring integration: Prometheus, Alertmanager, ServiceMonitors with OAuth-secured Routes
- Secret and certificate automation: SecretGenerator and CertConfigmapGenerator controllers
- Extensive RBAC (159 API groups): full control over core resources, service mesh, monitoring, KServe/Kubeflow
- Supports managed (RHOAI) and self-managed (ODH) deployment scenarios
- Leader election with singleton enforcement (one DataScienceCluster per cluster)
- Upgrade management: platform detection, DSCI/DSC auto-creation, deprecated resource cleanup

### Network Details
- **Operator Metrics**: 8080/TCP HTTP (internal ClusterIP)
- **Health Probes**: 8081/TCP HTTP (/healthz, /readyz)
- **Prometheus**: 9091/TCP HTTPS (TLS via Service CA, OAuth Proxy, external Route with reencrypt)
- **Alertmanager**: 9093/TCP HTTPS (TLS via Service CA, OAuth Proxy, external Route with reencrypt)
- **Reconciliation**: 6443/TCP HTTPS to Kubernetes API (ServiceAccount Token)
- **Manifest Sources**: 443/TCP HTTPS to GitHub (build-time only, embedded in operator image)

---

## Kueue

**Source**: `architecture/rhoai-2.11/kueue.md`

### Diagrams

**For Developers**:
- [Component Structure](./kueue-component.png) ([mmd](./kueue-component.mmd))
- [Data Flows](./kueue-dataflow.png) ([mmd](./kueue-dataflow.mmd))
- [Dependencies](./kueue-dependencies.png) ([mmd](./kueue-dependencies.mmd))

**For Architects**:
- [C4 Context](./kueue-c4-context.dsl)

**For Security Teams**:
- [Security Network (PNG)](./kueue-security-network.png)
- [Security Network (Mermaid)](./kueue-security-network.mmd)
- [Security Network (ASCII)](./kueue-security-network.txt)
- [RBAC Visualization](./kueue-rbac.png) ([mmd](./kueue-rbac.mmd))

---

## ModelMesh Serving

**Source**: `architecture/rhoai-2.11/modelmesh-serving.md`

### Diagrams

**For Developers**:
- [Component Structure](./modelmesh-serving-component.png) ([mmd](./modelmesh-serving-component.mmd))
- [Data Flows](./modelmesh-serving-dataflow.png) ([mmd](./modelmesh-serving-dataflow.mmd))
- [Dependencies](./modelmesh-serving-dependencies.png) ([mmd](./modelmesh-serving-dependencies.mmd))

**For Architects**:
- [C4 Context](./modelmesh-serving-c4-context.dsl)

**For Security Teams**:
- [Security Network (PNG)](./modelmesh-serving-security-network.png)
- [Security Network (Mermaid)](./modelmesh-serving-security-network.mmd)
- [Security Network (ASCII)](./modelmesh-serving-security-network.txt)
- [RBAC Visualization](./modelmesh-serving-rbac.png) ([mmd](./modelmesh-serving-rbac.mmd))

---

## Notebooks

**Source**: `architecture/rhoai-2.11/notebooks.md`

### Diagrams

**For Developers**:
- [Component Structure](./notebooks-component.png) ([mmd](./notebooks-component.mmd))
- [Data Flows](./notebooks-dataflow.png) ([mmd](./notebooks-dataflow.mmd))
- [Dependencies](./notebooks-dependencies.png) ([mmd](./notebooks-dependencies.mmd))

**For Architects**:
- [C4 Context](./notebooks-c4-context.dsl)

**For Security Teams**:
- [Security Network (PNG)](./notebooks-security-network.png)
- [Security Network (Mermaid)](./notebooks-security-network.mmd)
- [Security Network (ASCII)](./notebooks-security-network.txt)
- [RBAC Visualization](./notebooks-rbac.png) ([mmd](./notebooks-rbac.mmd))

---

## ODH Dashboard

**Source**: `architecture/rhoai-2.11/odh-dashboard.md`

### Diagrams

**For Developers**:
- [Component Structure](./odh-dashboard-component.png) ([mmd](./odh-dashboard-component.mmd))
- [Data Flows](./odh-dashboard-dataflow.png) ([mmd](./odh-dashboard-dataflow.mmd))
- [Dependencies](./odh-dashboard-dependencies.png) ([mmd](./odh-dashboard-dependencies.mmd))

**For Architects**:
- [C4 Context](./odh-dashboard-c4-context.dsl)

**For Security Teams**:
- [Security Network (PNG)](./odh-dashboard-security-network.png)
- [Security Network (Mermaid)](./odh-dashboard-security-network.mmd)
- [Security Network (ASCII)](./odh-dashboard-security-network.txt)
- [RBAC Visualization](./odh-dashboard-rbac.png) ([mmd](./odh-dashboard-rbac.mmd))

---

## ODH Model Controller

**Source**: `architecture/rhoai-2.11/odh-model-controller.md`
**Purpose**: Extends KServe and ModelMesh serving capabilities with OpenShift-specific integrations for routing, service mesh, authorization, and monitoring

### Diagrams

**For Developers**:
- [Component Structure](./odh-model-controller-component.png) ([mmd](./odh-model-controller-component.mmd)) - Internal components, reconcilers, webhook server
- [Data Flows](./odh-model-controller-dataflow.png) ([mmd](./odh-model-controller-dataflow.mmd)) - InferenceService creation flows, monitoring, storage secret management
- [Dependencies](./odh-model-controller-dependencies.png) ([mmd](./odh-model-controller-dependencies.mmd)) - External and internal dependencies

**For Architects**:
- [C4 Context](./odh-model-controller-c4-context.dsl) - System context (Structurizr)

**For Security Teams**:
- [Security Network (PNG)](./odh-model-controller-security-network.png) - High-resolution network topology
- [Security Network (Mermaid)](./odh-model-controller-security-network.mmd) - Visual network topology (editable)
- [Security Network (ASCII)](./odh-model-controller-security-network.txt) - Precise text for SAR submissions
- [RBAC Visualization](./odh-model-controller-rbac.png) ([mmd](./odh-model-controller-rbac.mmd)) - RBAC permissions and bindings

### Key Features
- Multi-mode reconciliation: KServe Serverless, KServe Raw, ModelMesh
- Istio/Service Mesh integration (VirtualServices, Gateways, PeerAuthentication)
- OpenShift Route creation for external access
- Authorino integration for API authorization
- Webhook validation for Knative Services
- Serving runtime templates (OVMS, TGIS, Caikit, vLLM)
- Model Registry integration for versioning

---

## RHODS Operator

**Source**: `architecture/rhoai-2.11/rhods-operator.md`
**Purpose**: Primary operator for Red Hat OpenShift AI that manages the lifecycle of data science platform components through custom resources

### Diagrams

**For Developers**:
- [Component Structure](./rhods-operator-component.png) ([mmd](./rhods-operator-component.mmd)) - Internal components, controllers (DSC, DSCI, SecretGenerator, CertGenerator), and reconcilers
- [Data Flows](./rhods-operator-dataflow.png) ([mmd](./rhods-operator-dataflow.mmd)) - Component deployment, monitoring/metrics, secret and certificate generation flows
- [Dependencies](./rhods-operator-dependencies.png) ([mmd](./rhods-operator-dependencies.mmd)) - Platform dependencies and deployed ODH components

**For Architects**:
- [C4 Context](./rhods-operator-c4-context.dsl) - System context (Structurizr)

**For Security Teams**:
- [Security Network (PNG)](./rhods-operator-security-network.png) - High-resolution network topology
- [Security Network (Mermaid)](./rhods-operator-security-network.mmd) - Visual network topology (editable)
- [Security Network (ASCII)](./rhods-operator-security-network.txt) - Precise text for SAR submissions with detailed RBAC and network policies
- [RBAC Visualization](./rhods-operator-rbac.png) ([mmd](./rhods-operator-rbac.mmd)) - RBAC permissions and bindings for controller-manager and prometheus service accounts

### Key Features
- Core orchestration for RHOAI/ODH platform (deploys Dashboard, KServe, ModelMesh, DSP, Workbenches, CodeFlare, Ray, Kueue, Training Operator, TrustyAI)
- Two primary CRs: DSCInitialization (platform infrastructure) and DataScienceCluster (component enablement)
- Platform initialization: service mesh configuration, monitoring stack deployment, namespace and RBAC setup
- Component manifest management: fetches from GitHub repos (build time), applies via kustomize
- Monitoring integration: Prometheus, Alertmanager, ServiceMonitors with OAuth-secured Routes
- Secret and certificate automation: SecretGenerator and CertConfigmapGenerator controllers
- Extensive RBAC (159 API groups): full control over core resources, service mesh, monitoring, KServe/Kubeflow
- Supports managed (RHOAI) and self-managed (ODH) deployment scenarios
- Leader election with singleton enforcement (one DataScienceCluster per cluster)
- Upgrade management: platform detection, DSCI/DSC auto-creation, deprecated resource cleanup

### Network Details
- **Operator Metrics**: 8080/TCP HTTP (internal ClusterIP)
- **Health Probes**: 8081/TCP HTTP (/healthz, /readyz)
- **Prometheus**: 9091/TCP HTTPS (TLS via Service CA, OAuth Proxy, external Route with reencrypt)
- **Alertmanager**: 9093/TCP HTTPS (TLS via Service CA, OAuth Proxy, external Route with reencrypt)
- **Reconciliation**: 6443/TCP HTTPS to Kubernetes API (ServiceAccount Token)
- **Manifest Sources**: 443/TCP HTTPS to GitHub (build-time only, embedded in operator image)

---

## Training Operator

**Source**: `architecture/rhoai-2.11/training-operator.md`

### Diagrams

**For Developers**:
- [Component Structure](./training-operator-component.png) ([mmd](./training-operator-component.mmd))
- [Data Flows](./training-operator-dataflow.png) ([mmd](./training-operator-dataflow.mmd))
- [Dependencies](./training-operator-dependencies.png) ([mmd](./training-operator-dependencies.mmd))

**For Architects**:
- [C4 Context](./training-operator-c4-context.dsl)

**For Security Teams**:
- [Security Network (PNG)](./training-operator-security-network.png)
- [Security Network (Mermaid)](./training-operator-security-network.mmd)
- [Security Network (ASCII)](./training-operator-security-network.txt)
- [RBAC Visualization](./training-operator-rbac.png) ([mmd](./training-operator-rbac.mmd))

---

## TrustyAI Service Operator

**Source**: `architecture/rhoai-2.11/trustyai-service-operator.md`
**Purpose**: Kubernetes operator that manages TrustyAI service deployments for AI model explainability, fairness monitoring, and bias detection

### Diagrams

**For Developers**:
- [Component Structure](./trustyai-service-operator-component.png) ([mmd](./trustyai-service-operator-component.mmd)) - Internal components, controllers, PVC manager, route manager, InferenceService integrator
- [Data Flows](./trustyai-service-operator-dataflow.png) ([mmd](./trustyai-service-operator-dataflow.mmd)) - TrustyAI service creation, InferenceService integration, external access, metrics collection
- [Dependencies](./trustyai-service-operator-dependencies.png) ([mmd](./trustyai-service-operator-dependencies.mmd)) - External dependencies and integration points

**For Architects**:
- [C4 Context](./trustyai-service-operator-c4-context.dsl) - System context (Structurizr)

**For Security Teams**:
- [Security Network (PNG)](./trustyai-service-operator-security-network.png) - High-resolution network topology
- [Security Network (Mermaid)](./trustyai-service-operator-security-network.mmd) - Visual network topology (editable)
- [Security Network (ASCII)](./trustyai-service-operator-security-network.txt) - Precise text format for SAR submissions
- [RBAC Visualization](./trustyai-service-operator-rbac.png) ([mmd](./trustyai-service-operator-rbac.mmd)) - RBAC permissions and bindings

### Key Features
- **Automated TrustyAI Deployment**: Operator-managed service instances with OAuth proxy for OpenShift authentication
- **KServe Integration**: Automatically patches InferenceServices with payload processors (MM_PAYLOAD_PROCESSORS) for real-time inference monitoring
- **ModelMesh Support**: Configures payload processors on ModelMesh deployments for data collection
- **Persistent Storage**: PVC-based storage for inference data and metrics
- **Secure External Access**: OpenShift Routes with TLS reencrypt, OAuth authentication
- **Metrics Collection**: Prometheus ServiceMonitor for fairness and explainability metrics
- **Certificate Management**: Service-ca integration for automatic TLS certificate provisioning and rotation
- **Flexible Configuration**: Configurable storage size, data format (CSV), metrics schedule, batch size

### Architecture Highlights
- **Operator Layer**: TrustyAIServiceReconciler manages lifecycle, creates deployments, services, routes, PVCs
- **Service Layer**: TrustyAI service pods with OAuth proxy sidecar (port 8443 HTTPS) and TrustyAI container (port 8080 HTTP)
- **Storage**: PVC per instance, mounted at configurable path
- **Networking**: Multiple ClusterIP services (HTTP 80, HTTPS 443), OpenShift Route with reencrypt TLS
- **Security**: OAuth 2.0 authentication, SubjectAccessReview (SAR) checks, TLS 1.2+, service-ca certificates

### Network Details
- **Operator Metrics**: 8080/TCP HTTP (internal), 8081/TCP HTTP (health probes)
- **TrustyAI Service (Internal)**: 80/TCP HTTP (metrics), 443/TCP HTTPS (internal TLS)
- **TrustyAI Service (OAuth)**: 8443/TCP HTTPS (OAuth proxy)
- **External Access**: 443/TCP HTTPS via OpenShift Route (reencrypt)
- **InferenceService Communication**: 80/TCP HTTP (payload data from KServe/ModelMesh)
- **Prometheus Scraping**: 80/TCP HTTP (ServiceMonitor)

### Integration Flow
1. User creates TrustyAIService CR via kubectl or ODH Dashboard
2. Operator creates: PVC → Deployment (TrustyAI + OAuth proxy) → Services → Route → ServiceMonitor
3. Operator patches KServe InferenceServices with MM_PAYLOAD_PROCESSORS environment variable
4. InferenceService pods forward inference payloads to TrustyAI service (HTTP/80)
5. TrustyAI analyzes data for bias and fairness, generates explainability metrics
6. Prometheus scrapes metrics from TrustyAI service (/q/metrics endpoint)
7. Users access TrustyAI via OpenShift Route (OAuth-authenticated)

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

### C4 Diagrams (.dsl files)
- **Structurizr Lite**: `docker run -p 8080:8080 -v .:/usr/local/structurizr structurizr/lite`
- **CLI export**: `structurizr-cli export -workspace diagram.dsl -format png`

### ASCII Diagrams (.txt files)
- View in any text editor
- Include in documentation as-is
- Perfect for security reviews (precise technical details)

## Diagram Types

Each component has the following diagram types:

1. **Component Diagram** (`*-component.mmd/.png`) - Internal architecture, controllers, webhooks, and resource relationships
2. **Data Flow Diagram** (`*-dataflow.mmd/.png`) - Sequence diagrams showing request/response flows with technical details
3. **Security Network Diagram** (`*-security-network.txt/.mmd/.png`) - Network topology with trust boundaries, ports, protocols, encryption
4. **Dependencies Diagram** (`*-dependencies.mmd/.png`) - External and internal dependencies and integration points
5. **C4 Context Diagram** (`*-c4-context.dsl`) - System context in C4 format for architectural overview
6. **RBAC Diagram** (`*-rbac.mmd/.png`) - RBAC permissions and bindings (where applicable)

## Naming Convention

**Filenames use base component name without version** (directory is already versioned as `rhoai-2.11/`):
- ✅ `codeflare-operator-component.mmd`
- ✅ `kserve-dataflow.png`
- ❌ `codeflare-operator-rhoai-2.11-component.mmd` (redundant)

## Regenerating Diagrams

To regenerate diagrams after architecture changes:

```bash
# Regenerate for specific component
python scripts/generate_diagram_pngs.py architecture/rhoai-2.11/diagrams --width=3000

# Or use Claude Code
# "Generate architecture diagrams from architecture/rhoai-2.11/codeflare-operator.md"
```

## Version Information

- **RHOAI Version**: 2.11
- **Architecture Source**: `architecture/rhoai-2.11/`
- **Diagram Width**: 3000px (PNG files)
- **Generated**: 2026-03-15
