# Component: Kubeflow Training Operator

## Metadata
- **Repository**: https://github.com/opendatahub-io/training-operator.git
- **Version**: bfceb079
- **Distribution**: ODH and RHOAI (both)
- **Languages**: Go, Python, YAML
- **Deployment Type**: Kubernetes Operator

## Purpose
**Short**: Kubernetes operator for distributed training of ML models using PyTorch, TensorFlow, JAX, XGBoost, MPI, and PaddlePaddle frameworks.

**Detailed**: The Kubeflow Training Operator is a Kubernetes-native framework for running scalable distributed training and fine-tuning of machine learning models across multiple ML frameworks. It provides custom resources for defining training jobs that automatically orchestrate distributed training workloads across multiple nodes and GPUs. The operator supports PyTorch (PyTorchJob), TensorFlow (TFJob), JAX (JAXJob), XGBoost (XGBoostJob), MPI for HPC workloads (MPIJob), and PaddlePaddle (PaddleJob). It handles the complexities of distributed training including pod creation for master/worker/parameter server roles, service discovery for distributed communication, gang scheduling for synchronous training, autoscaling based on workload, and integration with Kubernetes resource management. The operator includes a Python SDK to simplify job creation for data scientists and integrates with the broader Kubeflow ecosystem for end-to-end ML workflows.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| Training Operator | Go Controller | Reconciles training job CRDs across multiple ML frameworks |
| PyTorchJob Controller | Reconciler | Manages distributed PyTorch training with elastic training support |
| TFJob Controller | Reconciler | Manages TensorFlow parameter server and collective training |
| MPIJob Controller | Reconciler | Manages MPI-based HPC and distributed training workloads |
| JAXJob Controller | Reconciler | Manages JAX distributed training jobs |
| XGBoostJob Controller | Reconciler | Manages XGBoost distributed training for gradient boosting |
| PaddleJob Controller | Reconciler | Manages PaddlePaddle distributed training |
| Webhook Server | Admission Controller | Validates and mutates training job resources before creation |
| Python SDK | Client Library | Simplifies training job creation and management for data scientists |

## APIs Exposed

### Custom Resource Definitions (CRDs)

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| kubeflow.org | v1 | PyTorchJob | Namespaced | Define distributed PyTorch training jobs with elastic training |
| kubeflow.org | v1 | TFJob | Namespaced | Define TensorFlow distributed training with parameter servers |
| kubeflow.org | v1 | MPIJob | Namespaced | Define MPI-based high-performance computing training jobs |
| kubeflow.org | v1 | JAXJob | Namespaced | Define JAX distributed training jobs |
| kubeflow.org | v1 | XGBoostJob | Namespaced | Define XGBoost distributed gradient boosting jobs |
| kubeflow.org | v1 | PaddleJob | Namespaced | Define PaddlePaddle distributed training jobs |

### HTTP Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /metrics | GET | 8080/TCP | HTTP | None | None | Prometheus metrics for operator health and job stats |
| /mutate-kubeflow-org-v1-* | POST | 9443/TCP | HTTPS | TLS 1.2+ | Webhook cert | Mutating webhook for training jobs |
| /validate-kubeflow-org-v1-* | POST | 9443/TCP | HTTPS | TLS 1.2+ | Webhook cert | Validating webhook for training jobs |

### gRPC Services
No gRPC services are exposed by the operator. Training frameworks may use gRPC internally for inter-worker communication.

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| PyTorch | 1.x, 2.x | No | Distributed training runtime (PyTorchJob) |
| TensorFlow | 2.x | No | Distributed training runtime (TFJob) |
| JAX | Latest | No | Distributed training runtime (JAXJob) |
| XGBoost | 1.x+ | No | Gradient boosting runtime (XGBoostJob) |
| PaddlePaddle | 2.x | No | Deep learning runtime (PaddleJob) |
| MPI | OpenMPI, Intel MPI | No | Message Passing Interface for HPC (MPIJob) |
| Volcano | 1.x+ | No | Advanced gang scheduling and job queueing |
| Kueue | 0.5+ | No | Job queueing and resource quota management |

### Internal ODH Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| Notebooks | Job Submission | Submit training jobs from workbench environments |
| Data Science Pipelines | Pipeline Steps | Execute distributed training as pipeline components |
| Ray | Integration | Coordinate with Ray for hybrid workloads |
| Model Registry | API Client | Register trained models after job completion |
| S3 Storage | Data Access | Access training datasets and checkpoints |

## Network Architecture

### Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| <job-name>-master-0 | ClusterIP | 23456/TCP | 23456 | TCP | None | None | Internal |
| <job-name>-worker-<n> | ClusterIP | 23456/TCP | 23456 | TCP | None | None | Internal |
| training-operator-webhook | ClusterIP | 9443/TCP | 9443 | HTTPS | TLS 1.2+ | Webhook cert | Internal |
| training-operator-metrics | ClusterIP | 8080/TCP | 8080 | HTTP | None | None | Internal |

### Ingress
No ingress is typically required. Training jobs communicate internally via ClusterIP services.

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| S3-compatible storage | 443/TCP | HTTPS | TLS 1.2+ | AWS credentials | Access training datasets and model checkpoints |
| Container Registry | 443/TCP | HTTPS | TLS 1.2+ | Token | Pull training container images |
| PyPI / pip index | 443/TCP | HTTPS | TLS 1.2+ | None | Install Python dependencies at runtime |
| Model Registry API | 8080/TCP | HTTP | None | Bearer Token | Register trained models |
| MLFlow Server | 5000/TCP | HTTP | None | None | Log training metrics and experiments |

## Security

### RBAC - Cluster Roles

| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|
| training-operator | "" | pods, services, configmaps, serviceaccounts, events | create, delete, get, list, patch, update, watch |
| training-operator | kubeflow.org | pytorchjobs, tfjobs, mpijobs, jaxjobs, xgboostjobs, paddlejobs | create, delete, get, list, patch, update, watch |
| training-operator | kubeflow.org | pytorchjobs/status, tfjobs/status, etc. | get, patch, update |
| training-operator | batch | jobs | create, delete, get, list, patch, update, watch |
| training-operator | autoscaling | horizontalpodautoscalers | create, delete, get, list, patch, update, watch |
| training-operator | admissionregistration.k8s.io | validatingwebhookconfigurations | get, list, update, watch |

### RBAC - Role Bindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| training-operator | kubeflow | training-operator | training-operator |

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| training-operator-webhook-cert | kubernetes.io/tls | TLS certificate for admission webhooks | cert-manager / Operator | Yes |
| aws-s3-credentials | Opaque | S3 access for training data and checkpoints | User-provided | No |
| registry-credentials | kubernetes.io/dockerconfigjson | Pull training container images from private registries | User-provided | No |
| ssh-key-secret | kubernetes.io/ssh-auth | SSH keys for MPI inter-node communication (MPIJob) | User-provided | No |

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| Webhook Endpoints | POST | mTLS | Kubernetes API Server | Webhook certificate validation |
| Operator Metrics | GET | None | None | Internal access only |
| Training Job Pods | N/A | ServiceAccount | Kubernetes RBAC | Pod permissions for S3, API access |

## Data Flows

### Flow 1: PyTorchJob Creation and Execution

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User/Notebook | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | Bearer Token |
| 2 | Kubernetes API | Webhook Server | 9443/TCP | HTTPS | TLS 1.2+ | Webhook cert |
| 3 | Training Operator | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 4 | Training Operator | Master/Worker Pods (create) | N/A | N/A | N/A | N/A |
| 5 | Master Pod | Worker Pods | 23456/TCP | TCP | None | None |
| 6 | Worker Pods | S3 Storage | 443/TCP | HTTPS | TLS 1.2+ | AWS credentials |
| 7 | Master Pod | Model Registry API | 8080/TCP | HTTP | None | Bearer Token |

### Flow 2: Distributed TensorFlow Training

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User | Kubernetes API (create TFJob) | 6443/TCP | HTTPS | TLS 1.2+ | Bearer Token |
| 2 | Training Operator | Chief/Worker/PS Pods (create) | N/A | N/A | N/A | N/A |
| 3 | Chief Pod | Parameter Server Pods | 2222/TCP | gRPC | None | None |
| 4 | Worker Pods | Parameter Server Pods | 2222/TCP | gRPC | None | None |
| 5 | Worker Pods | S3 Storage (checkpoints) | 443/TCP | HTTPS | TLS 1.2+ | AWS credentials |

### Flow 3: MPI-based HPC Training

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Launcher Pod | Worker Pods | 22/TCP | SSH | SSH | SSH Key |
| 2 | Worker Pods | Worker Pods (MPI comm) | Dynamic | TCP/UDP | None | None |
| 3 | Worker Pods | S3 Storage | 443/TCP | HTTPS | TLS 1.2+ | AWS credentials |

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| Kubernetes API | REST API | 6443/TCP | HTTPS | TLS 1.2+ | Manage training job resources (Pods, Services, ConfigMaps) |
| S3 Storage | HTTP API | 443/TCP | HTTPS | TLS 1.2+ | Access training data, save checkpoints and models |
| Model Registry | REST API | 8080/TCP | HTTP | None | Register trained models after job completion |
| Prometheus | Metrics Scraping | 8080/TCP | HTTP | None | Collect operator and job metrics |
| Volcano | CRD Integration | 6443/TCP | HTTPS | TLS 1.2+ | Advanced gang scheduling for distributed jobs |
| Kueue | CRD Integration | 6443/TCP | HTTPS | TLS 1.2+ | Job queuing and resource quota management |
| MLFlow | HTTP API | 5000/TCP | HTTP | None | Track training experiments and metrics |

## Recent Changes

| Version | Date | Changes |
|---------|------|---------|
| bfceb079 | 2025-01 | - Fix precommit issues<br>- Add pipelineruns for ODH CI builds<br>- Restrict secrets RBAC to namespace-scoped Role<br>- Sync security config files<br>- Upgrade Go version to 1.25 |
