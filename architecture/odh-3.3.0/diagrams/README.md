# ODH 3.3.0 - Architecture Diagrams

Generated from: `architecture/odh-3.3.0/PLATFORM.md`
Date: 2026-03-12
Components: 17

## Overview

This directory contains comprehensive architecture diagrams for Open Data Hub 3.3.0 platform. The diagrams cover platform-level views including component dependencies, data flows, security architecture, and RBAC policies.

## Diagram Inventory

### 1. Platform Overview (`odh-3.3.0-platform-overview.mmd`)

**Format**: Mermaid Graph
**Purpose**: High-level platform architecture showing all 17 components organized by functional layers

**What it shows**:
- Control Plane layer (opendatahub-operator, odh-dashboard)
- Model Serving layer (KServe, odh-model-controller)
- Model Management layer (model-registry, MLflow)
- Development Workbenches (notebooks, notebook-controller)
- Training & Distributed Computing (training-operator, trainer, kuberay, spark-operator)
- ML Workflows & Data (data-science-pipelines, feast)
- AI Governance (TrustyAI)
- LLM Tools (llama-stack)
- External dependencies (S3, PyPI, HuggingFace, Container Registry)
- Component relationships and integration points

**When to use**: Understanding overall platform architecture, onboarding new users, architecture reviews

**Rendering**:
```bash
# Using Mermaid CLI
mmdc -i odh-3.3.0-platform-overview.mmd -o odh-3.3.0-platform-overview.png

# Or view in VS Code with Mermaid Preview extension
# Or paste into https://mermaid.live
```

---

### 2. Component Dependencies (`odh-3.3.0-dependencies.mmd`)

**Format**: Mermaid Graph (Left-to-Right)
**Purpose**: Component dependency graph showing how components depend on and integrate with each other

**What it shows**:
- ODH Operator manages all component lifecycles
- Dashboard creates CRs for notebooks, KServe, model registry
- Model serving dependencies (KServe → Model Registry, TrustyAI)
- Notebook integrations (notebooks → MLflow, Feast, Model Registry, KServe, Pipelines)
- Pipeline orchestration (pipelines → training operators, KServe)
- Training integrations (training-operator/trainer → MLflow, Model Registry)
- TrustyAI monitoring (TrustyAI → KServe, MLflow)

**When to use**: Understanding component relationships, planning deployments, troubleshooting integration issues

**Rendering**:
```bash
mmdc -i odh-3.3.0-dependencies.mmd -o odh-3.3.0-dependencies.png
```

---

### 3. Data Flow: Model Development to Production (`odh-3.3.0-flow-model-dev-to-prod.mmd`)

**Format**: Mermaid Sequence Diagram
**Purpose**: End-to-end workflow from model development in notebooks to production deployment

**What it shows**:
1. User accesses dashboard and creates notebook
2. Model development (read features from Feast, train, log to MLflow)
3. Model registration (register to Model Registry)
4. Model deployment (create InferenceService via KServe)
5. OpenShift integration (odh-model-controller creates Route)
6. AI governance (TrustyAI monitors inferences)
7. Inference requests from external clients

**When to use**: Understanding ML lifecycle, training data scientists, documenting workflows

**Rendering**:
```bash
mmdc -i odh-3.3.0-flow-model-dev-to-prod.mmd -o odh-3.3.0-flow-model-dev-to-prod.png
```

---

### 4. Data Flow: Automated ML Pipeline (`odh-3.3.0-flow-ml-pipeline.mmd`)

**Format**: Mermaid Sequence Diagram
**Purpose**: MLOps pipeline workflow using Data Science Pipelines (Argo Workflows)

**What it shows**:
1. User submits pipeline via dashboard
2. Data preparation step (read/write from S3)
3. Training step (create PyTorchJob/TFJob, distributed training)
4. Model registration (register to Model Registry)
5. Model deployment (create InferenceService)
6. Pipeline completion and status updates

**When to use**: MLOps automation, pipeline development, CI/CD for ML

**Rendering**:
```bash
mmdc -i odh-3.3.0-flow-ml-pipeline.mmd -o odh-3.3.0-flow-ml-pipeline.png
```

---

### 5. Data Flow: Distributed LLM Fine-tuning (`odh-3.3.0-flow-llm-finetuning.mmd`)

**Format**: Mermaid Sequence Diagram
**Purpose**: LLM fine-tuning workflow using Trainer v2 with distributed training

**What it shows**:
1. User creates TrainJob CR for LLM fine-tuning
2. Trainer creates JobSet for distributed pod coordination
3. Download base LLM from HuggingFace
4. Load training dataset from S3
5. Distributed training with DeepSpeed/Megatron
6. Checkpointing and metrics logging (S3, MLflow)
7. Model registration and deployment as LLMInferenceService

**When to use**: LLM fine-tuning, generative AI workflows, distributed training

**Rendering**:
```bash
mmdc -i odh-3.3.0-flow-llm-finetuning.mmd -o odh-3.3.0-flow-llm-finetuning.png
```

---

### 6. Security & Network Architecture (`odh-3.3.0-security-network.mmd` / `.txt`)

**Format**: Mermaid Graph + ASCII Diagram
**Purpose**: Platform security architecture showing namespaces, network policies, auth mechanisms, encryption

**What it shows**:
- External network (users, S3, PyPI, HuggingFace, Container Registry)
- OpenShift cluster namespaces (opendatahub, istio-system, knative-serving, user namespaces)
- Ingress layer (OpenShift Router with TLS termination)
- Authentication mechanisms (OAuth, mTLS, ServiceAccount tokens, AWS IAM, API keys)
- Network policies (ingress/egress rules per component)
- Encryption (TLS 1.2+ for all external endpoints, mTLS for service mesh)
- RBAC enforcement points
- Secrets management

**When to use**: Security assessments, SAR documentation, network architecture planning, compliance reviews

**Rendering**:
```bash
# Mermaid version
mmdc -i odh-3.3.0-security-network.mmd -o odh-3.3.0-security-network.png

# ASCII version (view in terminal or text editor)
cat odh-3.3.0-security-network.txt
```

---

### 7. C4 Context Diagram (`odh-3.3.0-c4-context.dsl`)

**Format**: Structurizr DSL
**Purpose**: C4 model system context showing ODH platform, users, and external systems

**What it shows**:
- Users: Data Scientist, ML Engineer, Platform Administrator, External Client
- Main system: Open Data Hub 3.3.0
- External systems: S3 Storage, PyPI, HuggingFace, Container Registry
- Infrastructure: Kubernetes API, Service Mesh (Istio)
- Relationships and protocols (HTTPS/443, OAuth, AWS IAM, mTLS)

**When to use**: Architecture presentations, system context documentation, stakeholder communication

**Rendering**:
```bash
# Using Structurizr CLI
structurizr-cli export -workspace odh-3.3.0-c4-context.dsl -format plantuml

# Using Structurizr Lite (Docker)
docker run -it --rm -p 8080:8080 -v $(pwd):/usr/local/structurizr structurizr/lite

# Or upload to https://structurizr.com
```

---

### 8. RBAC Visualization (`odh-3.3.0-rbac.mmd`)

**Format**: Mermaid Graph
**Purpose**: RBAC policies showing users, service accounts, roles, and resource permissions

**What it shows**:
- User identities (Platform Administrator, Data Scientist)
- Service accounts for all operators and workload pods
- ClusterRoles for platform components
- Namespace Roles for user workloads
- Kubernetes resources (CRDs, Pods, Services, Deployments, Secrets)
- Permission mappings (manage, create, read, watch)
- RoleBindings and ClusterRoleBindings

**When to use**: RBAC audits, permission troubleshooting, security reviews, least-privilege analysis

**Rendering**:
```bash
mmdc -i odh-3.3.0-rbac.mmd -o odh-3.3.0-rbac.png
```

---

## Rendering All Diagrams

### Prerequisites

Install Mermaid CLI:
```bash
npm install -g @mermaid-js/mermaid-cli
```

Install Structurizr CLI (optional):
```bash
# Download from https://github.com/structurizr/cli/releases
```

### Batch Rendering

```bash
#!/bin/bash
# Render all Mermaid diagrams to PNG

for file in *.mmd; do
    echo "Rendering $file..."
    mmdc -i "$file" -o "${file%.mmd}.png" -b transparent
done

echo "All diagrams rendered successfully!"
```

### Rendering Options

**Mermaid CLI (`mmdc`) options**:
- `-b transparent` - Transparent background
- `-w 2048` - Width in pixels
- `-H 1536` - Height in pixels
- `-t default|dark|forest|neutral` - Theme

Example:
```bash
mmdc -i odh-3.3.0-platform-overview.mmd -o odh-3.3.0-platform-overview.png -b transparent -w 2048 -t default
```

---

## Diagram Usage Guidelines

### For Data Scientists
- **Start with**: Platform Overview (understand available components)
- **Workflow diagrams**: Model Dev to Prod, ML Pipeline (understand ML lifecycle)
- **LLM work**: LLM Fine-tuning flow

### For ML Engineers
- **Essential**: Component Dependencies (understand integration points)
- **MLOps**: ML Pipeline, Model Dev to Prod flows
- **Training**: LLM Fine-tuning flow

### For Platform Administrators
- **Architecture**: Platform Overview, Component Dependencies
- **Security**: Security & Network Architecture, RBAC Visualization
- **Planning**: C4 Context Diagram

### For Security Teams
- **Critical**: Security & Network Architecture (both formats)
- **Access Control**: RBAC Visualization
- **System Context**: C4 Context Diagram

### For Stakeholders
- **Executive Summary**: Platform Overview, C4 Context Diagram
- **Use Cases**: Workflow diagrams (Model Dev to Prod, ML Pipeline, LLM Fine-tuning)

---

## Diagram Maintenance

These diagrams are generated from the platform architecture document (`PLATFORM.md`). When the platform is updated:

1. Update component architecture files (`*.md`)
2. Regenerate platform aggregation:
   ```bash
   /aggregate-platform-architecture --distribution=odh --version=3.3.0
   ```
3. Regenerate diagrams:
   ```bash
   /generate-architecture-diagrams --architecture=architecture/odh-3.3.0/PLATFORM.md
   ```

---

## File Formats

| Extension | Format | Rendering | Use Case |
|-----------|--------|-----------|----------|
| `.mmd` | Mermaid | mmdc CLI, mermaid.live, VS Code | Most diagrams (graph, sequence) |
| `.dsl` | Structurizr DSL | Structurizr CLI/Lite | C4 model diagrams |
| `.txt` | ASCII | Text editor, terminal | Security architecture (plain text) |

---

## Additional Resources

- **Source**: `architecture/odh-3.3.0/PLATFORM.md`
- **Component Details**: `architecture/odh-3.3.0/*.md`
- **Mermaid Docs**: https://mermaid.js.org/
- **Structurizr**: https://structurizr.com/
- **C4 Model**: https://c4model.com/

---

## Questions or Issues

For questions about these diagrams or to report issues:
1. Check the source architecture document: `architecture/odh-3.3.0/PLATFORM.md`
2. Review component-specific architecture: `architecture/odh-3.3.0/<component>.md`
3. Regenerate diagrams if architecture has been updated
