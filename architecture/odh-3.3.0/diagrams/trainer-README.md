# Architecture Diagrams for Kubeflow Trainer v2

Generated from: `architecture/odh-3.3.0/trainer.md`
Date: 2026-03-13

**Note**: Diagram filenames use base component name without version (directory is already versioned).

## Available Diagrams

All Mermaid diagrams are available in both `.mmd` (source) and `.png` (3000px width, high-resolution) formats.

### For Developers
- [Component Structure](./trainer-component.png) ([mmd](./trainer-component.mmd)) - Mermaid diagram showing internal components, CRDs, and integrations
- [Data Flows](./trainer-dataflow.png) ([mmd](./trainer-dataflow.mmd)) - Sequence diagram of TrainJob submission, LLM fine-tuning, and gang scheduling flows
- [Dependencies](./trainer-dependencies.png) ([mmd](./trainer-dependencies.mmd)) - Component dependency graph showing external and internal integrations

### For Architects
- [C4 Context](./trainer-c4-context.dsl) - System context in C4 format (Structurizr)
- [Component Overview](./trainer-component.png) ([mmd](./trainer-component.mmd)) - High-level component view

### For Security Teams
- [Security Network Diagram (PNG)](./trainer-security-network.png) - High-resolution network topology
- [Security Network Diagram (Mermaid)](./trainer-security-network.mmd) - Visual network topology (editable)
- [Security Network Diagram (ASCII)](./trainer-security-network.txt) - Precise text format for SAR submissions
- [RBAC Visualization](./trainer-rbac.png) ([mmd](./trainer-rbac.mmd)) - RBAC permissions and bindings

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

## Diagram Descriptions

### Component Structure (trainer-component.mmd)
Shows the internal architecture of Kubeflow Trainer v2:
- **Controllers**: Trainer Controller, TrainJob Controller, TrainingRuntime Controller, ClusterTrainingRuntime Controller
- **Webhook Server**: Validates and mutates TrainJob CRs
- **Kubeflow SDK**: Python client for job submission
- **Custom Resources**: TrainJob, TrainingRuntime, ClusterTrainingRuntime CRDs
- **External Dependencies**: JobSet, Volcano, Kueue, PyTorch, JAX, TensorFlow, HuggingFace, DeepSpeed, Megatron-LM
- **ODH Integrations**: Notebooks, Data Science Pipelines, Model Registry, S3 Storage, Ray

### Data Flows (trainer-dataflow.mmd)
Sequence diagrams showing three key workflows:
1. **TrainJob Submission and Execution**: User creates TrainJob → Webhook validation → Controller creates JobSet → Worker pods execute training
2. **LLM Fine-tuning with DeepSpeed**: Master and worker pods download base model from HuggingFace, load training data from S3, perform distributed training with gradient synchronization, save checkpoints, register fine-tuned model
3. **Gang Scheduling with Volcano**: Controller creates PodGroup → Volcano waits for all pods → Simultaneous start of all workers

### Security Network Diagram (trainer-security-network.txt/.mmd)
Detailed network topology with security details:
- **External Zone**: User → Kubernetes API (HTTPS/6443, TLS 1.2+, Bearer Token)
- **Control Plane**: Webhook Server (HTTPS/9443), Trainer Controller (metrics, health endpoints)
- **Training Workload**: Master and Worker pods with inter-worker communication (TCP/23456, ⚠️ plaintext)
- **External Services**: S3 (HTTPS/443), HuggingFace Hub (HTTPS/443), Container Registry (HTTPS/443), PyPI (HTTPS/443), Model Registry (HTTP/8080, ⚠️ no encryption)
- **RBAC Summary**: ClusterRole permissions, RoleBinding, ServiceAccount details
- **NetworkPolicy**: Ingress/egress rules for training pods
- **Secrets**: webhook-cert, aws-s3-credentials, huggingface-token, registry-credentials
- **Security Considerations**: Plaintext inter-worker communication, HTTP Model Registry API

### Dependencies (trainer-dependencies.mmd)
Dependency graph showing:
- **Required External Dependencies**: JobSet 0.7+ (manages distributed worker pods)
- **Optional Training Frameworks**: PyTorch, JAX, TensorFlow
- **Optional Training Libraries**: HuggingFace Transformers, DeepSpeed, Megatron-LM
- **Optional Scheduling**: Volcano (gang scheduling), Kueue (job queuing)
- **Internal ODH Dependencies**: Model Registry (API calls), Service Mesh (integration)
- **Integration Points**: Notebooks (SDK submission), Data Science Pipelines (pipeline steps), Ray (hybrid workloads)
- **External Services**: S3, HuggingFace Hub, Container Registry, PyPI, Kubernetes API

### RBAC Visualization (trainer-rbac.mmd)
RBAC permissions for the Trainer operator:
- **ServiceAccount**: trainer-controller-manager (namespace: kubeflow)
- **RoleBinding**: trainer-rolebinding → kubeflow-trainer-controller-manager ClusterRole
- **Permissions**:
  - Core resources: ConfigMaps, Secrets, Events (create, get, list, patch, update, watch)
  - Trainer CRDs: TrainJobs, TrainingRuntimes, ClusterTrainingRuntimes (get, list, patch, update, watch)
  - TrainJobs/status, TrainJobs/finalizers (get, patch, update)
  - JobSet: jobsets (create, get, list, patch, update, watch)
  - Scheduling: podgroups (create, get, list, patch, update, watch)
  - Admission: validatingwebhookconfigurations (get, list, update, watch)
  - Node: runtimeclasses (get, list, watch)
  - Networking: networkpolicies (create, delete, get, list, patch, update, watch)

### C4 Context Diagram (trainer-c4-context.dsl)
System context showing:
- **User**: Data Scientist
- **Trainer v2**: Controller, TrainJob Controller, TrainingRuntime Controller, ClusterTrainingRuntime Controller, Webhook Server, Kubeflow SDK
- **External Dependencies**: JobSet, PyTorch, JAX, TensorFlow, HuggingFace, DeepSpeed, Megatron-LM, Volcano, Kueue
- **External Services**: S3 Storage, HuggingFace Hub, Container Registry, PyPI
- **Internal ODH**: Notebooks, Data Science Pipelines, Model Registry, Ray
- **Infrastructure**: Kubernetes API

## Updating Diagrams

To regenerate after architecture changes:
```bash
# From repository root
cd architecture/odh-3.3.0
# Edit trainer.md with architecture updates
# Then regenerate diagrams (requires appropriate tooling)
```

## Component Information

**Component**: Kubeflow Trainer v2
**Repository**: https://github.com/opendatahub-io/trainer.git
**Version**: 6b4be8aa
**Distribution**: ODH and RHOAI
**Languages**: Go, Python, YAML
**Deployment Type**: Kubernetes Operator

**Purpose**: Next-generation Kubernetes-native framework for LLM fine-tuning and distributed training across PyTorch, JAX, TensorFlow, and other ML frameworks. Provides simplified TrainJob CRD with TrainingRuntime templates, JobSet integration, gang scheduling with Volcano/Kueue, and built-in support for modern distributed training libraries (HuggingFace Transformers, DeepSpeed, Megatron-LM).
