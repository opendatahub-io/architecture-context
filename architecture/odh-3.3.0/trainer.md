# Component: Kubeflow Trainer v2

## Metadata
- **Repository**: https://github.com/opendatahub-io/trainer.git
- **Version**: 6b4be8aa
- **Distribution**: ODH and RHOAI (both)
- **Languages**: Go, Python, YAML
- **Deployment Type**: Kubernetes Operator

## Purpose
**Short**: Next-generation Kubernetes-native framework for LLM fine-tuning and distributed training across PyTorch, JAX, TensorFlow, and other ML frameworks.

**Detailed**: Kubeflow Trainer v2 is the evolution of the Kubeflow Training Operator, redesigned specifically for large language model (LLM) fine-tuning and scalable distributed training workloads. It provides a simplified, unified API for running training jobs across multiple frameworks (PyTorch, JAX, TensorFlow) with first-class support for modern distributed training libraries like HuggingFace Transformers, DeepSpeed, and Megatron-LM. The operator introduces TrainJob as a framework-agnostic CRD that references TrainingRuntime templates, enabling users to define training workloads without deep Kubernetes knowledge. It leverages JobSet for managing distributed worker pods, integrates with Volcano/Kueue for gang scheduling, and provides built-in support for CUDA and ROCm accelerators. The Kubeflow Python SDK allows data scientists to submit training jobs programmatically from notebooks or scripts. Trainer v2 emphasizes developer experience, performance, and extensibility for modern AI/ML workloads.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| Trainer Controller | Go Controller | Reconciles TrainJob CRs and manages training workloads |
| TrainJob Controller | Reconciler | Creates and manages JobSets for distributed training |
| TrainingRuntime Controller | Reconciler | Manages namespace-scoped training runtime templates |
| ClusterTrainingRuntime Controller | Reconciler | Manages cluster-wide training runtime templates |
| Webhook Server | Admission Controller | Validates and mutates TrainJob resources |
| Kubeflow SDK | Python Client | Provides Pythonic interface for job creation and management |
| JobSet Manager | Integration | Manages distributed training worker pods via JobSet CRD |

## APIs Exposed

### Custom Resource Definitions (CRDs)

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| trainer.kubeflow.org | v1alpha1 | TrainJob | Namespaced | Define distributed training jobs (framework-agnostic) |
| trainer.kubeflow.org | v1alpha1 | TrainingRuntime | Namespaced | Define namespace-scoped training runtime templates |
| trainer.kubeflow.org | v1alpha1 | ClusterTrainingRuntime | Cluster | Define cluster-wide training runtime templates |

### HTTP Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /metrics | GET | 8080/TCP | HTTP | None | None | Prometheus metrics for operator and job health |
| /healthz | GET | 8081/TCP | HTTP | None | None | Operator health check endpoint |
| /readyz | GET | 8081/TCP | HTTP | None | None | Operator readiness endpoint |
| /mutate-trainer-kubeflow-org-v1alpha1-trainjob | POST | 9443/TCP | HTTPS | TLS 1.2+ | Webhook cert | Mutating webhook for TrainJob |
| /validate-trainer-kubeflow-org-v1alpha1-trainjob | POST | 9443/TCP | HTTPS | TLS 1.2+ | Webhook cert | Validating webhook for TrainJob |

### gRPC Services
No gRPC services are exposed by the operator. Training frameworks use gRPC internally for distributed communication.

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| JobSet | 0.7+ | Yes | Kubernetes JobSet for managing distributed worker pods |
| PyTorch | 1.x, 2.x | No | PyTorch runtime for distributed training |
| JAX | Latest | No | JAX runtime for high-performance training |
| TensorFlow | 2.x | No | TensorFlow runtime for distributed training |
| HuggingFace Transformers | 4.x | No | LLM fine-tuning library |
| DeepSpeed | Latest | No | Microsoft DeepSpeed for memory-efficient training |
| Megatron-LM | Latest | No | NVIDIA Megatron for large-scale LLM training |
| Volcano | 1.x+ | No | Gang scheduling for synchronous distributed training |
| Kueue | 0.5+ | No | Job queuing and resource quota management |

### Internal ODH Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| Notebooks | Job Submission | Submit training jobs from workbench environments via SDK |
| Data Science Pipelines | Pipeline Steps | Execute training jobs as pipeline components |
| Model Registry | API Client | Register fine-tuned models after training completion |
| S3 Storage | Data Access | Access training datasets and save model checkpoints |
| Ray | Coordination | Hybrid workloads combining Ray and Trainer |

## Network Architecture

### Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| <trainjob>-<node-0> | ClusterIP | 23456/TCP | 23456 | TCP | None | None | Internal |
| <trainjob>-<node-n> | ClusterIP | 23456/TCP | 23456 | TCP | None | None | Internal |
| trainer-webhook-service | ClusterIP | 9443/TCP | 9443 | HTTPS | TLS 1.2+ | Webhook cert | Internal |
| trainer-metrics-service | ClusterIP | 8080/TCP | 8080 | HTTP | None | None | Internal |

### Ingress
No ingress is typically required. Training jobs communicate internally via ClusterIP services.

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| S3-compatible storage | 443/TCP | HTTPS | TLS 1.2+ | AWS credentials | Access training datasets and save checkpoints |
| Container Registry | 443/TCP | HTTPS | TLS 1.2+ | Token | Pull training runtime container images |
| HuggingFace Hub | 443/TCP | HTTPS | TLS 1.2+ | Token | Download pre-trained models for fine-tuning |
| PyPI / pip index | 443/TCP | HTTPS | TLS 1.2+ | None | Install Python dependencies at runtime |
| Model Registry API | 8080/TCP | HTTP | None | Bearer Token | Register fine-tuned models |

## Security

### RBAC - Cluster Roles

| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|
| kubeflow-trainer-controller-manager | "" | configmaps, secrets, events | create, get, list, patch, update, watch |
| kubeflow-trainer-controller-manager | trainer.kubeflow.org | trainjobs, trainingruntimes, clustertrainingruntimes | get, list, patch, update, watch |
| kubeflow-trainer-controller-manager | trainer.kubeflow.org | trainjobs/status, trainjobs/finalizers | get, patch, update |
| kubeflow-trainer-controller-manager | jobset.x-k8s.io | jobsets | create, get, list, patch, update, watch |
| kubeflow-trainer-controller-manager | scheduling.volcano.sh, scheduling.x-k8s.io | podgroups | create, get, list, patch, update, watch |
| kubeflow-trainer-controller-manager | admissionregistration.k8s.io | validatingwebhookconfigurations | get, list, update, watch |
| kubeflow-trainer-controller-manager | node.k8s.io | runtimeclasses | get, list, watch |
| kubeflow-trainer-controller-manager | networking.k8s.io | networkpolicies | create, delete, get, list, patch, update, watch |

### RBAC - Role Bindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| trainer-rolebinding | kubeflow | kubeflow-trainer-controller-manager | trainer-controller-manager |

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| trainer-webhook-cert | kubernetes.io/tls | TLS certificate for admission webhooks | cert-manager / Operator | Yes |
| aws-s3-credentials | Opaque | S3 access for training data and checkpoints | User-provided | No |
| huggingface-token | Opaque | HuggingFace Hub token for model downloads | User-provided | No |
| registry-credentials | kubernetes.io/dockerconfigjson | Pull training runtime images from private registries | User-provided | No |

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| Webhook Endpoints | POST | mTLS | Kubernetes API Server | Webhook certificate validation |
| Operator Metrics | GET | None | None | Internal access only |
| Training Job Pods | N/A | ServiceAccount | Kubernetes RBAC | Pod permissions for S3, registry access |

## Data Flows

### Flow 1: TrainJob Submission and Execution

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User/SDK | Kubernetes API (create TrainJob) | 6443/TCP | HTTPS | TLS 1.2+ | Bearer Token |
| 2 | Kubernetes API | Webhook Server | 9443/TCP | HTTPS | TLS 1.2+ | Webhook cert |
| 3 | Trainer Controller | Kubernetes API (create JobSet) | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 4 | JobSet Controller | Worker Pods (create) | N/A | N/A | N/A | N/A |
| 5 | Worker Pods | Worker Pods (distributed training) | 23456/TCP | TCP | None | None |
| 6 | Worker Pods | S3 Storage | 443/TCP | HTTPS | TLS 1.2+ | AWS credentials |
| 7 | Worker Pods | HuggingFace Hub | 443/TCP | HTTPS | TLS 1.2+ | Token |

### Flow 2: LLM Fine-tuning with DeepSpeed

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Notebook (SDK) | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | Bearer Token |
| 2 | Trainer Controller | JobSet (create) | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 3 | Master Pod | Worker Pods (DeepSpeed init) | 23456/TCP | TCP | None | None |
| 4 | Worker Pods | HuggingFace Hub (download base model) | 443/TCP | HTTPS | TLS 1.2+ | Token |
| 5 | Worker Pods | S3 Storage (training data) | 443/TCP | HTTPS | TLS 1.2+ | AWS credentials |
| 6 | Worker Pods | S3 Storage (save checkpoints) | 443/TCP | HTTPS | TLS 1.2+ | AWS credentials |
| 7 | Master Pod | Model Registry API | 8080/TCP | HTTP | None | Bearer Token |

### Flow 3: Gang Scheduling with Volcano

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Trainer Controller | PodGroup CR (create) | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 2 | Volcano Scheduler | PodGroup (schedule when all pods ready) | N/A | N/A | N/A | N/A |
| 3 | Volcano Scheduler | Kubernetes API (bind pods) | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 4 | Worker Pods | Start training simultaneously | N/A | N/A | N/A | N/A |

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| Kubernetes API | REST API | 6443/TCP | HTTPS | TLS 1.2+ | Manage TrainJobs, JobSets, PodGroups, and NetworkPolicies |
| JobSet Controller | CRD Integration | 6443/TCP | HTTPS | TLS 1.2+ | Manage distributed worker pod groups |
| Volcano Scheduler | CRD Integration | 6443/TCP | HTTPS | TLS 1.2+ | Gang scheduling for synchronous distributed training |
| Kueue | CRD Integration | 6443/TCP | HTTPS | TLS 1.2+ | Job queuing and resource quota management |
| S3 Storage | HTTP API | 443/TCP | HTTPS | TLS 1.2+ | Access training data and save model checkpoints |
| HuggingFace Hub | HTTP API | 443/TCP | HTTPS | TLS 1.2+ | Download pre-trained models for fine-tuning |
| Model Registry | REST API | 8080/TCP | HTTP | None | Register fine-tuned models after training |
| Prometheus | Metrics Scraping | 8080/TCP | HTTP | None | Collect operator and job metrics |

## Recent Changes

| Version | Date | Changes |
|---------|------|---------|
| 6b4be8aa | 2025-01 | - Sync security config files<br>- Add Lake gate PR merge protection<br>- Sync changes from main to stable branch<br>- Add script for custom Trainer v2 manifest in ODH/RHOAI<br>- Update to latest runtime images with transformers 4.57.1 |
| fc484ac8 | 2024-12 | - Add pipelineruns for ODH CI builds<br>- Update kustomization resources<br>- Add more runtimes (CUDA and ROCm variants)<br>- Remove torch28 params<br>- Remove universal image in favor of specific CUDA/ROCm runtimes<br>- Add NetworkPolicy for TrainJobs |
