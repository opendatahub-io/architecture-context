# Architecture Diagrams for RHOAI 2.25.0 Components

This directory contains architecture diagrams for multiple RHOAI 2.25.0 components.

**Note**: Diagram filenames use base component name without version (directory is already versioned).

All Mermaid diagrams are available in both `.mmd` (source) and `.png` (3000px width, high-resolution) formats.

---

## Components

### [CodeFlare Operator](#codeflare-operator)
Distributed AI/ML workload orchestration through RayCluster and AppWrapper

### [Data Science Pipelines Operator](#data-science-pipelines-operator)
ML pipeline orchestration and management (Kubeflow Pipelines-based)

### [Feast](#feast)
Feature store for ML model serving

### [KServe](#kserve)
Model serving platform with serverless inference

### [Kubeflow](#kubeflow)
ML toolkit for Kubernetes

### [KubeRay Operator](#kuberay-operator)
Ray cluster lifecycle management for distributed computing

### [Kueue](#kueue)
Job queuing and resource management

### [Llama Stack K8s Operator](#llama-stack-k8s-operator)
Llama model deployment and serving

### [Notebooks](#notebooks)
Container images for JupyterLab, VS Code, and RStudio workbenches plus Kubeflow Pipelines runtime images

### [ODH Model Controller](#odh-model-controller)
Extends KServe with OpenShift integration, service mesh, authentication, and monitoring

### [TrustyAI Service Operator](#trustyai-service-operator)
Manages TrustyAI services, LM evaluation jobs, and guardrails orchestrators for AI model explainability, evaluation, and safety

---

## CodeFlare Operator

Generated from: `architecture/rhoai-2.25.0/codeflare-operator.md`
Version: RHOAI 2.25.0 (CodeFlare Operator v1.15.0)

### Diagrams
- [Component Structure](./codeflare-operator-component.png) ([mmd](./codeflare-operator-component.mmd))
- [Data Flow - RayCluster Creation with OAuth](./codeflare-operator-dataflow.png) ([mmd](./codeflare-operator-dataflow.mmd))
- [Data Flow - AppWrapper Scheduling](./codeflare-operator-dataflow2.png) ([mmd](./codeflare-operator-dataflow2.mmd))
- [Data Flow - Ray Client Connection](./codeflare-operator-dataflow3.png) ([mmd](./codeflare-operator-dataflow3.mmd))
- [Dependencies](./codeflare-operator-dependencies.png) ([mmd](./codeflare-operator-dependencies.mmd))
- [C4 Context](./codeflare-operator-c4-context.dsl)
- [Security Network (PNG)](./codeflare-operator-security-network.png) | [Mermaid](./codeflare-operator-security-network.mmd) | [ASCII](./codeflare-operator-security-network.txt)
- [RBAC Visualization](./codeflare-operator-rbac.png) ([mmd](./codeflare-operator-rbac.mmd))

### Overview
Manages distributed AI/ML workload orchestration with:
- RayCluster Controller with OAuth dashboard access and mTLS
- AppWrapper Controller for Kueue-based batch scheduling
- Security features: OAuth, mTLS, NetworkPolicies

---

## Data Science Pipelines Operator

Generated from: `architecture/rhoai-2.25.0/data-science-pipelines-operator.md`

### Diagrams
- [Component Structure](./data-science-pipelines-operator-component.png) ([mmd](./data-science-pipelines-operator-component.mmd))
- [Data Flow](./data-science-pipelines-operator-dataflow.png) ([mmd](./data-science-pipelines-operator-dataflow.mmd))
- [Dependencies](./data-science-pipelines-operator-dependencies.png) ([mmd](./data-science-pipelines-operator-dependencies.mmd))
- [C4 Context](./data-science-pipelines-operator-c4-context.dsl)
- [Security Network (PNG)](./data-science-pipelines-operator-security-network.png) | [Mermaid](./data-science-pipelines-operator-security-network.mmd) | [ASCII](./data-science-pipelines-operator-security-network.txt)
- [RBAC Visualization](./data-science-pipelines-operator-rbac.png) ([mmd](./data-science-pipelines-operator-rbac.mmd))

### Overview
ML pipeline orchestration based on Kubeflow Pipelines with S3-compatible storage and MariaDB metadata store.

---

## Feast

Generated from: `architecture/rhoai-2.25.0/feast.md`

### Diagrams
- [Component Structure](./feast-component.png) ([mmd](./feast-component.mmd))
- [Data Flow](./feast-dataflow.png) ([mmd](./feast-dataflow.mmd))
- [Dependencies](./feast-dependencies.png) ([mmd](./feast-dependencies.mmd))
- [C4 Context](./feast-c4-context.dsl)
- [Security Network (PNG)](./feast-security-network.png) | [Mermaid](./feast-security-network.mmd) | [ASCII](./feast-security-network.txt)
- [RBAC Visualization](./feast-rbac.png) ([mmd](./feast-rbac.mmd))

### Overview
Feature store for ML with online/offline serving, PostgreSQL metadata, and Redis online store.

---

## KServe

Generated from: `architecture/rhoai-2.25.0/kserve.md`

### Diagrams
- [Component Structure](./kserve-component.png) ([mmd](./kserve-component.mmd))
- [Data Flow](./kserve-dataflow.png) ([mmd](./kserve-dataflow.mmd))
- [Dependencies](./kserve-dependencies.png) ([mmd](./kserve-dependencies.mmd))
- [C4 Context](./kserve-c4-context.dsl)
- [Security Network (PNG)](./kserve-security-network.png) | [Mermaid](./kserve-security-network.mmd) | [ASCII](./kserve-security-network.txt)
- [RBAC Visualization](./kserve-rbac.png) ([mmd](./kserve-rbac.mmd))

### Overview
Serverless ML model serving with autoscaling, multi-framework support, and model versioning.

---

## Kubeflow

Generated from: `architecture/rhoai-2.25.0/kubeflow.md`

### Diagrams
- [Component Structure](./kubeflow-component.png) ([mmd](./kubeflow-component.mmd))
- [Data Flow](./kubeflow-dataflow.png) ([mmd](./kubeflow-dataflow.mmd))
- [Dependencies](./kubeflow-dependencies.png) ([mmd](./kubeflow-dependencies.mmd))
- [C4 Context](./kubeflow-c4-context.dsl)
- [Security Network (PNG)](./kubeflow-security-network.png) | [Mermaid](./kubeflow-security-network.mmd) | [ASCII](./kubeflow-security-network.txt)
- [RBAC Visualization](./kubeflow-rbac.png) ([mmd](./kubeflow-rbac.mmd))

### Overview
ML toolkit for Kubernetes with notebook servers, pipelines, and model training.

---

## KubeRay Operator

Generated from: `architecture/rhoai-2.25.0/kuberay.md`
Date: 2026-03-13

### Diagrams
- [Component Structure](./kuberay-component.png) ([mmd](./kuberay-component.mmd))
- [Data Flows](./kuberay-dataflow.png) ([mmd](./kuberay-dataflow.mmd))
- [Dependencies](./kuberay-dependencies.png) ([mmd](./kuberay-dependencies.mmd))
- [C4 Context](./kuberay-c4-context.dsl)
- [Security Network (PNG)](./kuberay-security-network.png) | [Mermaid](./kuberay-security-network.mmd) | [ASCII](./kuberay-security-network.txt)
- [RBAC Visualization](./kuberay-rbac.png) ([mmd](./kuberay-rbac.mmd))

### Overview
Manages lifecycle of Ray clusters, jobs, and services for distributed computing and ML workloads:
- **RayCluster**: Distributed compute clusters with autoscaling and fault tolerance
- **RayJob**: Automatic cluster creation and batch job submission
- **RayService**: ML model serving with zero-downtime upgrades and high availability

**Key Features**:
- Autoscaling workers based on resource demand
- Gang scheduling support (Volcano, YuniKorn)
- GCS fault tolerance with external Redis
- Ray Serve for production ML inference
- OpenShift Route integration for external access
- Prometheus metrics for monitoring

---

## Kueue

Generated from: `architecture/rhoai-2.25.0/kueue.md`

### Diagrams
- [Component Structure](./kueue-component.png) ([mmd](./kueue-component.mmd))
- [Data Flow](./kueue-dataflow.png) ([mmd](./kueue-dataflow.mmd))
- [Dependencies](./kueue-dependencies.png) ([mmd](./kueue-dependencies.mmd))
- [C4 Context](./kueue-c4-context.dsl)
- [Security Network (PNG)](./kueue-security-network.png) | [Mermaid](./kueue-security-network.mmd) | [ASCII](./kueue-security-network.txt)

### Overview
Job queuing and resource management for Kubernetes with quota management and fair sharing.

---

## Llama Stack K8s Operator

Generated from: `architecture/rhoai-2.25.0/llama-stack-k8s-operator.md`

### Diagrams
- [Component Structure](./llama-stack-k8s-operator-component.png) ([mmd](./llama-stack-k8s-operator-component.mmd))
- [Data Flow](./llama-stack-k8s-operator-dataflow.png) ([mmd](./llama-stack-k8s-operator-dataflow.mmd))
- [Dependencies](./llama-stack-k8s-operator-dependencies.png) ([mmd](./llama-stack-k8s-operator-dependencies.mmd))
- [C4 Context](./llama-stack-k8s-operator-c4-context.dsl)
- [Security Network (PNG)](./llama-stack-k8s-operator-security-network.png) | [Mermaid](./llama-stack-k8s-operator-security-network.mmd) | [ASCII](./llama-stack-k8s-operator-security-network.txt)
- [RBAC Visualization](./llama-stack-k8s-operator-rbac.png) ([mmd](./llama-stack-k8s-operator-rbac.mmd))

### Overview
Deploys and manages Llama models on Kubernetes with vLLM inference engine.

---

## Notebooks

Generated from: `architecture/rhoai-2.25.0/notebooks.md`
Date: 2026-03-14

### Diagrams
- [Component Structure](./notebooks-component.png) ([mmd](./notebooks-component.mmd))
- [Data Flow](./notebooks-dataflow.png) ([mmd](./notebooks-dataflow.mmd))
- [Dependencies](./notebooks-dependencies.png) ([mmd](./notebooks-dependencies.mmd))
- [C4 Context](./notebooks-c4-context.dsl)
- [Security Network (PNG)](./notebooks-security-network.png) | [Mermaid](./notebooks-security-network.mmd) | [ASCII](./notebooks-security-network.txt)
- [RBAC Visualization](./notebooks-rbac.png) ([mmd](./notebooks-rbac.mmd))

### Overview
Container image repository providing JupyterLab, VS Code, and RStudio workbench environments for data science workflows:
- **Workbench Images**: Interactive development environments (Jupyter, Code Server, RStudio) with CPU/CUDA/ROCm support
- **Runtime Images**: Lightweight containers for Kubeflow Pipelines task execution
- **Multi-arch Support**: Built for x86_64, arm64, ppc64le, s390x via Konflux CI/CD
- **ML Frameworks**: PyTorch 2.x, TensorFlow 2.x, TrustyAI, LLMCompressor
- **Version Strategy**: YYYY.N release format (e.g., 2025.2) with weekly security patches

---

## ODH Model Controller

Generated from: `architecture/rhoai-2.25.0/odh-model-controller.md`
Date: 2026-03-14
Version: RHOAI 2.25.0 (v1.27.0-rhods-1121-g0ce874f)

### Diagrams
- [Component Structure](./odh-model-controller-component.png) ([mmd](./odh-model-controller-component.mmd))
- [Data Flows](./odh-model-controller-dataflow.png) ([mmd](./odh-model-controller-dataflow.mmd))
- [Dependencies](./odh-model-controller-dependencies.png) ([mmd](./odh-model-controller-dependencies.mmd))
- [C4 Context](./odh-model-controller-c4-context.dsl)
- [Security Network (PNG)](./odh-model-controller-security-network.png) | [Mermaid](./odh-model-controller-security-network.mmd) | [ASCII](./odh-model-controller-security-network.txt)
- [RBAC Visualization](./odh-model-controller-rbac.png) ([mmd](./odh-model-controller-rbac.mmd))

### Overview
Kubernetes operator that extends KServe model serving with OpenShift integration, eliminating manual infrastructure steps:
- **Purpose**: Automates deployment of ML inference services with Routes, service mesh, auth, monitoring
- **Controllers**: InferenceService, InferenceGraph, LLMInferenceService, NIM Account, ServingRuntime, ConfigMap, Secret, Pod reconcilers
- **Admission Webhooks**: Mutating/validating webhooks for Pods, InferenceService, InferenceGraph, NIM Account, Knative Service
- **Resource Management**: Automatically creates Routes, VirtualServices, Gateways, PeerAuthentication, AuthConfig, ServiceMonitor, NetworkPolicy
- **NVIDIA NIM Integration**: Account CRD for NGC API keys, pull secrets, model catalogs, runtime templates
- **Serving Runtimes**: vLLM (CPU/CUDA/Gaudi/ROCm/multinode), Caikit, OVMS, HuggingFace
- **Multi-Mode Support**: KServe serverless (Knative), KServe raw (Kubernetes), ModelMesh
- **Security**: FIPS compliant, non-root (UID 2000), mTLS service mesh, Authorino/Kuadrant auth

**Key Features Illustrated**:
- **Component Diagram**: Reconcilers, webhooks, metrics server, watched/owned CRDs, created resources, external dependencies
- **Data Flow Diagrams**: (1) InferenceService creation with validation/reconciliation, (2) Inference request flow through Route→Gateway→Authorino→Activator→Pod→S3, (3) NIM Account management with NGC API integration, (4) Metrics collection
- **Security Network**: Trust zones (External→Ingress→Service Mesh→External Services→Control Plane), precise ports/protocols/encryption/auth, RBAC summary, Service Mesh config
- **Dependencies**: Required (KServe, OpenShift Route/Template API, K8s API), Optional (Istio, Authorino, Prometheus, KEDA, cert-manager, NGC), Internal ODH (DSCInit, DataScienceCluster, Model Registry)
- **RBAC**: ClusterRole permissions for 20+ API groups (KServe, Istio, OpenShift, monitoring, auth, networking, NIM, ODH)

**Conditional Features** (environment variables):
- `MESH_DISABLED=false`: Enable/disable Istio service mesh integration
- `MODELREGISTRY_STATE=replace`: Enable Model Registry metadata tracking
- `NIM_STATE=replace`: Enable NVIDIA NIM Account feature
- `KSERVE_STATE=replace`, `MODELMESH_STATE=replace`: Control serving mode reconciliation

**Migration Note**: Metrics endpoint currently HTTP on port 8080 (migration to HTTPS 8443 planned)

---

## TrustyAI Service Operator

Generated from: `architecture/rhoai-2.25.0/trustyai-service-operator.md`
Date: 2026-03-14
Version: RHOAI 2.25.0 (d113dae, branch: rhoai-2.25)

### Diagrams
- [Component Structure](./trustyai-service-operator-component.png) ([mmd](./trustyai-service-operator-component.mmd))
- [Data Flows](./trustyai-service-operator-dataflow.png) ([mmd](./trustyai-service-operator-dataflow.mmd))
- [Dependencies](./trustyai-service-operator-dependencies.png) ([mmd](./trustyai-service-operator-dependencies.mmd))
- [C4 Context](./trustyai-service-operator-c4-context.dsl)
- [Security Network (PNG)](./trustyai-service-operator-security-network.png) | [Mermaid](./trustyai-service-operator-security-network.mmd) | [ASCII](./trustyai-service-operator-security-network.txt)
- [RBAC Visualization](./trustyai-service-operator-rbac.png) ([mmd](./trustyai-service-operator-rbac.mmd))

### Overview
Kubernetes operator that manages three distinct AI services within the RHOAI platform:

**Three-Service Architecture**:
1. **TrustyAI Service**: AI explainability, bias detection, and fairness metrics for ML models
2. **LM Eval Jobs**: Language model evaluation using lm-evaluation-harness with Kueue integration
3. **Guardrails Orchestrator**: AI safety detectors for input/output filtering and content safety

**Purpose**: Automates deployment of AI governance, evaluation, and safety infrastructure with OAuth authentication, TLS encryption, and comprehensive observability.

**Key Features Illustrated**:
- **Component Diagram**: Operator with three controllers (TrustyAI, LMEvalJob, Guardrails), conversion webhook, managed services, OAuth proxy sidecars, platform resources
- **Data Flow Diagrams**: (1) Model prediction monitoring, (2) OAuth-protected API access, (3) LM evaluation job execution, (4) Guardrails request processing with detector/generator coordination
- **Security Network**: Trust zones (External→Ingress→Auth Layer→App Layer→Control Plane), OpenShift Routes with reencrypt mode, OAuth proxy layer, service-ca certificates, ClusterIP isolation
- **Dependencies**: Platform (Kubernetes, OpenShift OAuth, Istio, service-ca, Prometheus, Kueue), External (PostgreSQL/MySQL, S3, Hugging Face), Internal ODH (KServe, ModelMesh, Data Science Pipelines)
- **RBAC**: manager-role (full operator permissions), non-admin-lmeval-role (LMEvalJob CRUD for all users), per-service ServiceAccounts

**Custom Resources**:
- TrustyAIService (v1/v1alpha1) - Declarative configuration for explainability service
- LMEvalJob (v1alpha1) - Language model evaluation job specification
- GuardrailsOrchestrator (v1alpha1) - Guardrails configuration for AI safety

**Integration Points**:
- **KServe**: Monitors InferenceService predictions, patches resources for explainability tracking
- **ModelMesh**: Injects payload processors via pod exec for model monitoring
- **Kueue**: Workload queue management for LM evaluation jobs
- **Prometheus**: ServiceMonitor-based metrics scraping (TrustyAI service + operator)
- **S3 Storage**: Evaluation results storage
- **Hugging Face Hub**: Model and dataset downloads for evaluation
- **OpenShift OAuth**: Authentication for external access via proxy sidecars
- **Istio Service Mesh**: VirtualServices for KServe serverless mode integration

**Security Features**:
- OAuth Proxy sidecars on all external endpoints
- service-ca automatic certificate rotation (TLS 1.2+)
- OpenShift SAR (SubjectAccessReview) for namespace-level authorization
- Skip-auth regex for health check endpoints (`^/apis/v1beta1/healthz`)
- Internal ClusterIP isolation with Route/VirtualService exposure
- Database TLS support (PostgreSQL/MySQL)
- mTLS for ModelMesh payload processor injection

**Storage Flexibility**:
- PVC: Default persistent volume claims for TrustyAI data
- Database: PostgreSQL/MySQL support with optional TLS encryption
- S3: Evaluation results storage with AWS IAM/Access Key auth
- Shared PVC: PVC sharing with Data Science Pipelines

**Network Services**:
- TrustyAI Service: 80/TCP (internal HTTP), 443/TCP (internal HTTPS with service-ca), 8443/TCP (OAuth-protected external)
- Guardrails Orchestrator: 8032-8432/TCP (HTTPS API), 8090-8490/TCP (gateway), 8034/TCP (health)
- Operator: 8081/TCP (health checks), 8443/TCP (metrics via kube-rbac-proxy), 9443/TCP (conversion webhook)

**Observability**:
- Operator Metrics: `/metrics` on 8443/TCP HTTPS (controller-runtime, via kube-rbac-proxy)
- TrustyAI Service Metrics: `/q/metrics` on 8080/TCP HTTP (Quarkus/Prometheus, explainability/bias metrics)
- ServiceMonitors: Automatic Prometheus scraping for operator and TrustyAI services
- Health Checks: `/healthz`, `/readyz` (operator), `/oauth/healthz` (OAuth proxy), `/apis/v1beta1/healthz` (guardrails)

**Multi-Platform Integration**:
- **OpenShift**: Routes with reencrypt TLS mode, OAuth authentication, service-ca certificates
- **Istio**: VirtualServices and DestinationRules for KServe serverless mode
- **Kueue**: Workload admission and queue management for evaluation jobs
- **Prometheus**: ServiceMonitor-based metrics collection
- **KServe/ModelMesh**: Dual model serving platform support

**Conversion Webhook**:
- v1alpha1 to v1 migration support for TrustyAIService CR
- Port 9443/TCP HTTPS with cert-manager certificates

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

---

*Last updated: 2026-03-14*

---

# Architecture Diagrams for Kueue

Generated from: `architecture/rhoai-2.25.0/kueue.md`
Date: 2026-03-13
Version: RHOAI 2.25.0

**Note**: Diagram filenames use base component name without version (directory is already versioned).

## Available Diagrams

All Mermaid diagrams are available in both `.mmd` (source) and `.png` (3000px width, high-resolution) formats.

### For Developers
- [Component Structure](./kueue-component.png) ([mmd](./kueue-component.mmd)) - Mermaid diagram showing internal components, controllers, and managed resources
- [Data Flows](./kueue-dataflow.png) ([mmd](./kueue-dataflow.mmd)) - Sequence diagrams for job submission, admission, metrics, visibility API, MultiKueue, and provisioning
- [Dependencies](./kueue-dependencies.png) ([mmd](./kueue-dependencies.mmd)) - Component dependency graph showing Kubernetes, cert-manager, and workload integrations

### For Architects
- [C4 Context](./kueue-c4-context.dsl) - System context in C4 format (Structurizr)
- [Component Overview](./kueue-component.png) ([mmd](./kueue-component.mmd)) - High-level component view

### For Security Teams
- [Security Network Diagram (PNG)](./kueue-security-network.png) - High-resolution network topology
- [Security Network Diagram (Mermaid)](./kueue-security-network.mmd) - Visual network topology (editable)
- [Security Network Diagram (ASCII)](./kueue-security-network.txt) - Precise text format for SAR submissions
- [RBAC Visualization](./kueue-rbac.png) ([mmd](./kueue-rbac.mmd)) - RBAC permissions and bindings

## Component Overview

**Kueue** is a Kubernetes-native job management system that provides intelligent queueing and scheduling for batch workloads. It acts as a job-level manager that decides when a job can be admitted (pods can be created) based on available quota in cluster queues and local queues.

Key features:
- **Job Queueing**: Manages when Kubernetes jobs should be admitted based on resource quotas and priorities
- **Multi-Workload Support**: Batch Jobs, Kubeflow training (TFJob, PyTorchJob, MPIJob), Ray (RayJob, RayCluster), JobSet, AppWrapper
- **Fair Sharing & Preemption**: Prevents resource starvation across teams
- **Cohorts**: Resource sharing across multiple queues
- **MultiKueue**: Multi-cluster job dispatching
- **Topology-Aware Scheduling**: Optimized pod placement for GPU/network-intensive workloads
- **Cluster Autoscaling**: Integration with cluster autoscaler via provisioning requests

## Key Features Illustrated

### Component Diagram
Shows the controller's internal structure:
- kueue-controller-manager deployment
- Webhook server for admission control
- Metrics service for Prometheus
- Visibility server for on-demand queue queries
- Core reconcilers: Workload, ClusterQueue, LocalQueue
- Job integrations for Batch, Kubeflow, Ray, JobSet, AppWrapper
- Scheduler and cache components

### Data Flow Diagrams
Five critical flows illustrated:
1. **Job Submission and Admission**: User creates job → Webhook mutates → Controller watches → Admission decision → Unsuspend job
2. **Metrics Collection**: Prometheus scrapes queue and workload state
3. **Visibility API Query**: User queries pending workloads via aggregated API
4. **Multi-Cluster Job Dispatching (MultiKueue)**: Controller dispatches jobs to remote clusters
5. **Provisioning Request (Autoscaling)**: Controller creates ProvisioningRequest → Cluster Autoscaler provisions nodes

### Security Network Diagram
Network topology showing:
- **Trust Boundaries**: External → K8s API Server → Kueue Namespace → External Services
- **Ports & Protocols**: 
  - 443/TCP HTTPS (K8s API Server)
  - 9443/TCP HTTPS TLS 1.2+ (Webhook service, mTLS)
  - 8443/TCP HTTPS TLS 1.2+ (Metrics service, Bearer Token)
  - 8081/TCP HTTP (Health checks, no auth)
- **Encryption**: TLS 1.2+ for all external communications, mTLS for webhooks
- **Authentication**: Bearer Tokens (ServiceAccount), mTLS (API Server client cert), K8s RBAC
- **Secrets**: webhook TLS certificates (cert-manager), metrics bearer tokens
- **RBAC Summary**: Extensive ClusterRole permissions for Kueue CRDs, batch jobs, and workload integrations

### Dependency Graph
Shows:
- **External Required Dependencies**: Kubernetes API Server 1.25+, cert-manager 1.17+
- **External Optional Dependencies**: Prometheus, Kubeflow Training Operator 1.9+, Ray Operator 1.3+, JobSet 0.8+, AppWrapper 1.1+, Cluster Autoscaler
- **Internal ODH Dependencies**: None (standalone component)
- **Integration Points**: Webhook server, visibility API, metrics endpoint, workload CRD watches

### RBAC Visualization
Complete RBAC structure:
- ServiceAccount: `kueue-controller-manager`
- ClusterRole: `kueue-manager-role` with permissions for:
  - Kueue CRDs (workloads, clusterqueues, localqueues, resourceflavors, etc.)
  - Core resources (events, pods, namespaces, nodes, secrets)
  - Workload resources (batch jobs, kubeflow jobs, ray jobs, jobsets, appwrappers)
  - Autoscaling (provisioningrequests)
  - Admission webhooks (mutating/validating webhook configurations)
- Additional roles: viewer, editor, batch-admin, batch-user, metrics-reader
- Leader election role (namespace-scoped)

## Technical Specifications Summary

**Version**: 7f2f72e51 (rhoai-2.25 branch)
**Language**: Go 1.24
**Deployment**: Kubernetes Operator (Controller)

**Key Dependencies**:
- Kubernetes API Server 1.25+ (required)
- cert-manager 1.17+ (required)
- Kubeflow Training Operator 1.9+ (optional)
- Ray Operator 1.3+ (optional)
- JobSet 0.8+ (optional)
- AppWrapper 1.1+ (optional)
- Cluster Autoscaler (optional)

**Custom Resources**:
- Workload (kueue.x-k8s.io/v1beta1) - Job or group of pods with resource requirements
- ClusterQueue (kueue.x-k8s.io/v1beta1) - Cluster-wide resource quotas
- LocalQueue (kueue.x-k8s.io/v1beta1) - Namespace-scoped queue
- ResourceFlavor (kueue.x-k8s.io/v1beta1) - Resource variants (GPU types, node pools)
- WorkloadPriorityClass (kueue.x-k8s.io/v1beta1) - Priority levels
- AdmissionCheck (kueue.x-k8s.io/v1beta1) - External/internal admission checks
- ProvisioningRequestConfig (kueue.x-k8s.io/v1beta1) - Autoscaler configuration
- MultiKueueConfig (kueue.x-k8s.io/v1beta1) - Multi-cluster job dispatching config
- Cohort (kueue.x-k8s.io/v1alpha1) - ClusterQueue groups for resource sharing
- Topology (kueue.x-k8s.io/v1alpha1) - Data center topology

**Network Services**:
- Webhook Service: 443/TCP → 9443/TCP HTTPS TLS 1.2+ (API Server, mTLS)
- Metrics Service: 8443/TCP HTTPS TLS 1.2+ (Prometheus, Bearer Token)
- Health Checks: 8081/TCP HTTP (healthz/readyz, no auth)

**HTTP Endpoints**:
- `/healthz` - GET 8081/TCP HTTP (liveness)
- `/readyz` - GET 8081/TCP HTTP (readiness)
- `/metrics` - GET 8443/TCP HTTPS (Prometheus metrics)
- `/mutate-*` - POST 9443/TCP HTTPS (mutating webhooks)
- `/validate-*` - POST 9443/TCP HTTPS (validating webhooks)
- `/apis/visibility.kueue.x-k8s.io/v1beta1/clusterqueues/{name}/pendingworkloads` - GET (via K8s API aggregation)
- `/apis/visibility.kueue.x-k8s.io/v1beta1/namespaces/{ns}/localqueues/{name}/pendingworkloads` - GET (via K8s API aggregation)

**Security**:
- FIPS-enabled runtime (`GOEXPERIMENT=strictfipsruntime`)
- Non-root container (UID 65532)
- TLS 1.2+ for all HTTPS communications
- mTLS for webhook (API Server client certificate authentication)
- Bearer Token authentication for metrics
- K8s RBAC for visibility API
- cert-manager for webhook certificate provisioning and rotation

**Monitoring Metrics**:
- `kueue_pending_workloads` - Workloads waiting for admission
- `kueue_admitted_workloads_total` - Total admitted workloads
- `kueue_admission_attempts_total` - Admission attempt counts
- `kueue_cluster_queue_resource_usage` - Resource usage by ClusterQueue
- `kueue_admission_wait_time_seconds` - Wait time before admission

---

*Generated by Kueue architecture diagram generator - 2026-03-13*
