# Architecture Diagrams for RHOAI 3.3.0

This directory contains architecture diagrams for all RHOAI 3.3.0 components.

**Note**: Diagram filenames use base component name without version (directory `rhoai-3.3.0/` is already versioned).

All Mermaid diagrams are available in both `.mmd` (source) and `.png` (3000px width, high-resolution) formats.

---

## Available Components

- [**Platform Overview (Aggregated)**](#platform-overview-aggregated) ⭐
- [Data Science Pipelines Operator](#data-science-pipelines-operator)
- [Feast](#feast)
- [KServe](#kserve)
- [Kubeflow (ODH Notebook Controller)](#kubeflow-odh-notebook-controller)
- [KubeRay](#kuberay)
- [Llama Stack K8s Operator](#llama-stack-k8s-operator)
- [Notebooks (Workbench Images)](#notebooks-workbench-images)
- [Trainer (Kubeflow Trainer)](#trainer-kubeflow-trainer)
- [Training Operator (Kubeflow Training Operator)](#training-operator-kubeflow-training-operator)
- [TrustyAI Service Operator](#trustyai-service-operator)

---

## Platform Overview (Aggregated)

**Source**: `architecture/rhoai-3.3.0/PLATFORM.md`

⭐ **This section provides a comprehensive view of the entire RHOAI 3.3.0 platform**, showing how all 15 components work together.

### Diagrams
- [Component Structure](./platform-component.png) ([mmd](./platform-component.mmd)) - Complete platform architecture showing all 15 components across control plane, application layer, and workload tier
- [Data Flows](./platform-dataflow.png) ([mmd](./platform-dataflow.mmd)) - End-to-end workflows: training to deployment, pipeline orchestration, feature engineering, model monitoring
- [Dependencies](./platform-dependencies.png) ([mmd](./platform-dependencies.mmd)) - Complete dependency graph of all components and external services
- [Security Network](./platform-security-network.png) ([mmd](./platform-security-network.mmd)) ([txt](./platform-security-network.txt)) - Platform-wide network topology with trust boundaries, all ingress/egress points, complete RBAC, secrets inventory, NetworkPolicies
- [RBAC](./platform-rbac.png) ([mmd](./platform-rbac.mmd)) - Complete RBAC matrix for all operators and user workloads (cluster-level and namespace-scoped)
- [C4 Context](./platform-c4-context.dsl) - System context in C4 format (Structurizr) showing RHOAI in the OpenShift ecosystem

### Platform Summary

**Red Hat OpenShift AI 3.3.0** - Enterprise AI/ML platform with:

**15 Specialized Components**:
1. **RHODS Operator** (v1.6.0) - Central orchestrator
2. **ODH Dashboard** (v1.21.0) - Unified web UI
3. **Notebooks** - JupyterLab, RStudio, VS Code workbenches
4. **ODH Notebook Controller** (v1.27.0) - Workbench lifecycle management
5. **Data Science Pipelines Operator** (v0.0.1) - ML workflow orchestration (KFP v2)
6. **KServe** (v0.15) - Model serving with autoscaling
7. **ODH Model Controller** (v1.27.0) - KServe OpenShift extensions
8. **Model Registry Operator** (4fdd8de) - Model metadata versioning
9. **MLflow Operator** (49b5d8d) - Experiment tracking
10. **Feast Operator** (98a224e) - Feature store
11. **Training Operator** (v1.9.0) - Distributed training (PyTorch, TensorFlow, JAX)
12. **Trainer** (v2.1.0) - LLM fine-tuning with progression tracking
13. **KubeRay Operator** (v1.4.2) - Ray distributed computing
14. **TrustyAI Service Operator** (v1.39.0) - Model explainability and guardrails
15. **Llama Stack Operator** (v0.6.0) - Llama Stack deployment

**Key Workflows**:
- **Model Training to Deployment**: Notebook → Training Job → S3 → Model Registry → InferenceService → Client
- **Distributed Training with Pipelines**: Dashboard → DSP → Argo Workflow → Training Operator → Multi-node training → MLflow → InferenceService
- **Feature Engineering**: Feast Feature Store → Offline training features + Online inference features → Model serving
- **Model Monitoring**: TrustyAI → InferenceService payload logging → PostgreSQL → Prometheus metrics → Dashboard

**Security Highlights**:
- Multi-tenancy with namespace isolation
- OpenShift OAuth authentication
- mTLS service mesh (optional, Istio PERMISSIVE/STRICT mode)
- Auto-rotating TLS certificates (cert-manager, OpenShift Service CA)
- RBAC at cluster and namespace levels
- NetworkPolicies for pod isolation
- FIPS compliance builds
- Multi-architecture support (x86_64, aarch64, ppc64le, s390x)

**External Dependencies**:
- **Required**: OpenShift 4.12+, Kubernetes API, OpenShift OAuth
- **Optional**: Istio 1.20+, Knative Serving 1.12+, cert-manager 1.13+, Argo Workflows, Volcano, KEDA
- **User-Provisioned**: S3 storage, PostgreSQL/MySQL/Redis, Container registries, HuggingFace Hub, NVIDIA NGC

---

## Data Science Pipelines Operator

**Source**: `architecture/rhoai-3.3.0/data-science-pipelines-operator.md`

### Diagrams
- [Component Structure](./data-science-pipelines-operator-component.png) ([mmd](./data-science-pipelines-operator-component.mmd))
- [Data Flows](./data-science-pipelines-operator-dataflow.png) ([mmd](./data-science-pipelines-operator-dataflow.mmd))
- [Dependencies](./data-science-pipelines-operator-dependencies.png) ([mmd](./data-science-pipelines-operator-dependencies.mmd))
- [Security Network](./data-science-pipelines-operator-security-network.png) ([mmd](./data-science-pipelines-operator-security-network.mmd)) ([txt](./data-science-pipelines-operator-security-network.txt))
- [RBAC](./data-science-pipelines-operator-rbac.png) ([mmd](./data-science-pipelines-operator-rbac.mmd))

---

## Feast

**Source**: `architecture/rhoai-3.3.0/feast.md`

### Diagrams
- [Component Structure](./feast-component.png) ([mmd](./feast-component.mmd))
- [Data Flows](./feast-dataflow.png) ([mmd](./feast-dataflow.mmd))
- [Dependencies](./feast-dependencies.png) ([mmd](./feast-dependencies.mmd))
- [Security Network](./feast-security-network.png) ([mmd](./feast-security-network.mmd)) ([txt](./feast-security-network.txt))
- [RBAC](./feast-rbac.png) ([mmd](./feast-rbac.mmd))

---

## KServe

**Source**: `architecture/rhoai-3.3.0/kserve.md`

### Diagrams
- [Component Structure](./kserve-component.png) ([mmd](./kserve-component.mmd)) - Internal components, CRDs, serving runtimes, and dependencies
- [Data Flows](./kserve-dataflow.png) ([mmd](./kserve-dataflow.mmd)) - Model deployment, inference requests, InferenceGraph pipelines, LLM disaggregated inference, and local model cache flows
- [Dependencies](./kserve-dependencies.png) ([mmd](./kserve-dependencies.mmd)) - External dependencies (Istio, Knative, cert-manager), internal ODH integrations, and storage services
- [Security Network](./kserve-security-network.png) ([mmd](./kserve-security-network.mmd)) ([txt](./kserve-security-network.txt)) - Network topology with trust boundaries, TLS/mTLS, authentication, RBAC, Service Mesh config, and Secrets
- [RBAC](./kserve-rbac.png) ([mmd](./kserve-rbac.mmd)) - ClusterRole permissions for KServe CRDs, Knative, Istio, autoscaling, ingress/routing, monitoring, and admission webhooks
- [C4 Context](./kserve-c4-context.dsl) - System context in C4 format (Structurizr)

### Key Features
- **Model Serving**: Kubernetes-native serving for TensorFlow, XGBoost, scikit-learn, PyTorch, Hugging Face Transformer/LLM models
- **Serving Runtimes**: sklearn, xgboost, pytorch, huggingface, triton, vllm
- **Deployment Modes**: Serverless (Knative) and raw Kubernetes deployment
- **Advanced Features**: InferenceGraph multi-model pipelines, LLM disaggregated inference (prefill/decode), local model caching, canary rollouts
- **CRDs**: InferenceService, ServingRuntime, InferenceGraph, TrainedModel, LLMInferenceService, LocalModelCache
- **Protocols**: KServe v1, KServe v2 (NVIDIA Triton), OpenAI-compatible (for LLMs)

---

## Kubeflow (ODH Notebook Controller)

**Source**: `architecture/rhoai-3.3.0/kubeflow.md`

### Diagrams
- [Component Structure](./kubeflow-component.png) ([mmd](./kubeflow-component.mmd))
- [Data Flows](./kubeflow-dataflow.png) ([mmd](./kubeflow-dataflow.mmd))
- [Dependencies](./kubeflow-dependencies.png) ([mmd](./kubeflow-dependencies.mmd))
- [Security Network](./kubeflow-security-network.png) ([mmd](./kubeflow-security-network.mmd)) ([txt](./kubeflow-security-network.txt))
- [RBAC](./kubeflow-rbac.png) ([mmd](./kubeflow-rbac.mmd))
- [C4 Context](./kubeflow-c4-context.dsl)

### Key Features
- **Gateway API Integration**: HTTPRoutes for external access through data-science-gateway
- **RBAC Authentication**: kube-rbac-proxy sidecars for Kubernetes RBAC-based authentication
- **Cross-Namespace Architecture**: HTTPRoutes in controller namespace, notebooks in user namespaces
- **Network Isolation**: NetworkPolicies restrict traffic to controller namespace only
- **Pipeline Integration**: Automatic secrets and RBAC for Data Science Pipelines access
- **FIPS Compliance**: Built with FIPS-compliant Go 1.25 using strict FIPS runtime mode

---

## KubeRay

**Source**: `architecture/rhoai-3.3.0/kuberay.md`

### Diagrams
- [Component Structure](./kuberay-component.png) ([mmd](./kuberay-component.mmd))
- [Data Flows](./kuberay-dataflow.png) ([mmd](./kuberay-dataflow.mmd))
- [Dependencies](./kuberay-dependencies.png) ([mmd](./kuberay-dependencies.mmd))
- [Security Network](./kuberay-security-network.png) ([mmd](./kuberay-security-network.mmd)) ([txt](./kuberay-security-network.txt))
- [RBAC](./kuberay-rbac.png) ([mmd](./kuberay-rbac.mmd))

---

## Llama Stack K8s Operator

**Source**: `architecture/rhoai-3.3.0/llama-stack-k8s-operator.md`

### Diagrams
*(Diagrams not yet generated)*

---

## Notebooks (Workbench Images)

**Source**: `architecture/rhoai-3.3.0/notebooks.md`

### Diagrams
- [Component Structure](./notebooks-component.png) ([mmd](./notebooks-component.mmd)) - Workbench images (Jupyter, RStudio, CodeServer), runtime images for Elyra pipelines, and base images
- [Data Flows](./notebooks-dataflow.png) ([mmd](./notebooks-dataflow.mmd)) - User workbench access via OAuth, Python package installation, Elyra pipeline execution, and S3 data access
- [Dependencies](./notebooks-dependencies.png) ([mmd](./notebooks-dependencies.mmd)) - External dependencies (UBI9, JupyterLab, PyTorch, TensorFlow), internal ODH integrations, and build pipeline
- [Security Network](./notebooks-security-network.png) ([mmd](./notebooks-security-network.mmd)) ([txt](./notebooks-security-network.txt)) - Network topology with OAuth proxy authentication, workbench pod security context, egress to PyPI/S3, and RBAC summary
- [RBAC](./notebooks-rbac.png) ([mmd](./notebooks-rbac.mmd)) - Workbench pod ServiceAccount permissions, odh-notebook-controller ClusterRole, and odh-dashboard RBAC
- [C4 Context](./notebooks-c4-context.dsl) - System context in C4 format (Structurizr)

### Key Features
- **Workbench Images**: Jupyter, RStudio, CodeServer IDE environments for interactive data science
- **ML Frameworks**: PyTorch, TensorFlow pre-installed with GPU support (CUDA, ROCM)
- **Runtime Images**: Headless execution environments for Elyra pipeline nodes
- **Multi-Architecture**: x86_64, aarch64, ppc64le, s390x support where GPU vendors allow
- **GPU Acceleration**: NVIDIA CUDA 12.6/12.8/13.0 and AMD ROCM 6.2/6.3/6.4
- **Authentication**: OAuth proxy sidecar for OpenShift OAuth integration
- **Build Pipeline**: Konflux CI/CD for automated multi-arch builds with security scanning
- **Package Management**: UV package manager for fast, reproducible Python dependency resolution

---

## Trainer (Kubeflow Trainer)

**Source**: `architecture/rhoai-3.3.0/trainer.md`

### Diagrams
- [Component Structure](./trainer-component.png) ([mmd](./trainer-component.mmd)) - trainer-controller-manager, controllers, progression tracker (RHOAI), network policy manager (RHOAI)
- [Data Flows](./trainer-dataflow.png) ([mmd](./trainer-dataflow.mmd)) - TrainJob creation, training execution, progression tracking (RHOAI), gang scheduling
- [Dependencies](./trainer-dependencies.png) ([mmd](./trainer-dependencies.mmd)) - JobSet, Volcano/Coscheduling, Kueue, Service Mesh, built-in runtimes
- [Security Network](./trainer-security-network.png) ([mmd](./trainer-security-network.mmd)) ([txt](./trainer-security-network.txt)) - Network topology, NetworkPolicies, RBAC, gang scheduling, training runtimes
- [RBAC](./trainer-rbac.png) ([mmd](./trainer-rbac.mmd)) - ClusterRole permissions for TrainJobs, JobSets, PodGroups, NetworkPolicies (RHOAI)
- [C4 Context](./trainer-c4-context.dsl) - System context in C4 format (Structurizr)

### Key Features
- **Distributed Training**: Kubernetes-native operator for distributed machine learning training and LLM fine-tuning
- **Frameworks**: PyTorch, JAX, TensorFlow, DeepSpeed, MLX
- **CRDs**: TrainJob, TrainingRuntime, ClusterTrainingRuntime
- **Built-in Runtimes**: torch-distributed (CUDA/ROCm), training-hub (HuggingFace), deepspeed-distributed, mlx-distributed
- **Gang Scheduling**: Volcano Scheduler and Coscheduling Plugin support for all-or-nothing pod scheduling
- **RHOAI Extensions**: Progression tracking (polls training metrics from pods), Network Policy Manager (isolates training pods)
- **JobSet Integration**: Creates JobSets for multi-node training patterns
- **ML Technologies**: PyTorch torchrun, MPI, NCCL, DeepSpeed

---

## Training Operator (Kubeflow Training Operator)

**Source**: `architecture/rhoai-3.3.0/training-operator.md`

### Diagrams
- [Component Structure](./training-operator-component.png) ([mmd](./training-operator-component.mmd)) - Training operator controllers, webhooks, cert management, and 6 framework controllers
- [Data Flows](./training-operator-dataflow.png) ([mmd](./training-operator-dataflow.mmd)) - Job submission, validation, reconciliation, distributed training communication, metrics, and health checks
- [Dependencies](./training-operator-dependencies.png) ([mmd](./training-operator-dependencies.mmd)) - External dependencies (Kubernetes, controller-runtime, optional Volcano/scheduler-plugins), internal ODH integrations
- [Security Network](./training-operator-security-network.png) ([mmd](./training-operator-security-network.mmd)) ([txt](./training-operator-security-network.txt)) - Network topology with webhook server, training pod communication, plaintext protocols, RBAC, CVE-2026-2353 fix
- [RBAC](./training-operator-rbac.png) ([mmd](./training-operator-rbac.mmd)) - ClusterRole permissions for all 6 job types, optional gang scheduling, NetworkPolicies, namespace-scoped secrets access
- [C4 Context](./training-operator-c4-context.dsl) - System context in C4 format (Structurizr)

### Key Features
- **Multi-Framework Support**: PyTorch, TensorFlow, XGBoost, MPI, JAX, PaddlePaddle distributed training
- **CRDs**: PyTorchJob, TFJob, XGBoostJob, MPIJob, JAXJob, PaddleJob (all kubeflow.org/v1)
- **Topologies**: Master/Worker (PyTorch, XGBoost, PaddlePaddle), Chief/Worker/PS (TensorFlow), Launcher/Worker (MPI)
- **Gang Scheduling**: Optional integration with Volcano Scheduler or scheduler-plugins for all-or-nothing pod scheduling
- **Elastic Scaling**: HorizontalPodAutoscaler integration for dynamic worker scaling
- **Validating Webhooks**: Pre-flight validation for all 6 job types on port 9443/TCP HTTPS TLS 1.2+
- **Security**: CVE-2026-2353 fix (secrets RBAC restricted to namespace scope), non-root execution (UID 65532), Istio sidecar disabled
- **Note**: Framework communication (e.g., PyTorch port 23456/TCP) uses plaintext protocols - users must configure network isolation if required

---

## TrustyAI Service Operator

**Source**: `architecture/rhoai-3.3.0/trustyai-service-operator.md`

### Diagrams
- [Component Structure](./trustyai-service-operator-component.png) ([mmd](./trustyai-service-operator-component.mmd)) - Operator controller, conversion webhook, CRDs, managed deployments, storage backends, and dependencies
- [Data Flows](./trustyai-service-operator-dataflow.png) ([mmd](./trustyai-service-operator-dataflow.mmd)) - TrustyAI service deployment, inference monitoring, LM evaluation jobs, and guardrails orchestration
- [Dependencies](./trustyai-service-operator-dependencies.png) ([mmd](./trustyai-service-operator-dependencies.mmd)) - External dependencies (Kubernetes, KServe, Istio, Prometheus, Kueue, OpenShift), storage, and managed components
- [Security Network](./trustyai-service-operator-security-network.png) ([mmd](./trustyai-service-operator-security-network.mmd)) ([txt](./trustyai-service-operator-security-network.txt)) - Network topology with OpenShift Routes, operator namespace, user namespaces, mTLS service mesh, RBAC, and secrets
- [RBAC](./trustyai-service-operator-rbac.png) ([mmd](./trustyai-service-operator-rbac.mmd)) - ClusterRole permissions for TrustyAI CRDs, KServe, Istio, OpenShift routes, monitoring, and Kueue
- [C4 Context](./trustyai-service-operator-c4-context.dsl) - System context in C4 format (Structurizr)

### Key Features
- **Model Explainability & Monitoring**: Provides explainability, fairness monitoring, and drift detection for ML models served by KServe
- **LLM Guardrails**: Orchestrates FMS-Guardrails for modular LLM safety and NeMo Guardrails for NVIDIA-based guardrailing
- **LLM Evaluation**: Job-based architecture for language model evaluation using lm-evaluation-harness library
- **CRDs**: TrustyAIService (v1/v1alpha1), LMEvalJob (v1alpha1), GuardrailsOrchestrator (v1alpha1), NemoGuardrails (v1alpha1)
- **Storage Options**: PersistentVolumeClaim or PostgreSQL/MySQL database with optional TLS verification
- **Service Mesh Integration**: Istio VirtualService and DestinationRule for traffic routing with mTLS
- **Metrics Collection**: Prometheus ServiceMonitor for observability
- **TLS Management**: OpenShift service-serving certificates with auto-rotation
- **Kueue Integration**: Job queueing for LM evaluation workloads

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

## Diagram Types

All components include the following diagram types:

### For Developers
- **Component Structure** - Internal architecture, CRDs, controllers, and dependencies
- **Data Flows** - Sequence diagrams showing request/response flows and interactions
- **Dependencies** - Dependency graphs showing external and internal dependencies

### For Architects
- **C4 Context** - System context diagrams in C4 format (Structurizr DSL)
- **Component Overview** - High-level component views

### For Security Teams
- **Security Network Diagrams** - Detailed network topology with trust boundaries
  - **PNG** - High-resolution visual diagrams
  - **Mermaid** - Editable visual diagrams
  - **ASCII** - Precise text format for SAR (Security Architecture Review) submissions
- **RBAC Visualizations** - Complete RBAC permissions, bindings, and service accounts

---

## Updating Diagrams

To regenerate diagrams for a specific component after architecture changes:

```bash
# From repository root
cd architecture/rhoai-3.3.0

# Edit the component architecture file
vi kserve.md  # or feast.md, kubeflow.md, etc.

# Regenerate diagrams for that component
cd ../..
python scripts/generate_diagram_pngs.py architecture/rhoai-3.3.0/diagrams --width=3000
```

To regenerate diagrams for all components in this version:

```bash
# Regenerate all PNGs
python scripts/generate_diagram_pngs.py architecture/rhoai-3.3.0/diagrams --width=3000
```

---

## Architecture Documentation

For detailed architecture documentation, see the markdown files in `architecture/rhoai-3.3.0/`:

- `data-science-pipelines-operator.md`
- `feast.md`
- `kserve.md`
- `kubeflow.md`
- `kuberay.md`
- `llama-stack-k8s-operator.md`
- `model-registry-operator.md`
- `notebooks.md`
- `odh-dashboard.md`
- `odh-model-controller.md`
- `PLATFORM.md` - Platform-wide architecture and integration points
- `rhods-operator.md`
- `trainer.md`
- `training-operator.md`
- `trustyai-service-operator.md`
