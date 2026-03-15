# Component: Kubeflow Trainer

## Metadata
- **Repository**: https://github.com/red-hat-data-services/trainer.git
- **Version**: 2.1.0
- **Distribution**: RHOAI
- **Branch**: rhoai-3.2
- **Commit**: 46393c34
- **Languages**: Go
- **Deployment Type**: Kubernetes Operator

## Purpose
**Short**: Kubernetes-native operator for distributed training of large language models (LLMs) and machine learning workloads across PyTorch, JAX, TensorFlow, and other ML frameworks.

**Detailed**: Kubeflow Trainer (formerly Kubeflow Training Operator) is a Kubernetes operator that provides a declarative API for running distributed ML training jobs. It enables fine-tuning of LLMs and scalable distributed training by managing the lifecycle of training workloads through Custom Resource Definitions (CRDs). The operator watches TrainJob resources and automatically creates the necessary Kubernetes resources (JobSets, Pods, Services) to execute distributed training using various ML frameworks and communication protocols (MPI, PyTorch Distributed, DeepSpeed). It integrates with Volcano and Kubernetes gang scheduling for optimized resource allocation and supports data initialization, model loading, and caching strategies. The RHOAI distribution includes specialized training runtimes optimized for CUDA and ROCm GPU environments, with progression tracking integration for distributed training observability.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| trainer-controller-manager | Deployment | Main controller that reconciles TrainJob, TrainingRuntime, and ClusterTrainingRuntime resources |
| webhook-server | Webhook Server | Validates TrainJob, TrainingRuntime, and ClusterTrainingRuntime resources on CREATE/UPDATE operations |
| trainjob-controller | Controller | Watches TrainJob CRDs and creates corresponding JobSet resources with configured training runtime |
| trainingruntime-controller | Controller | Manages namespaced TrainingRuntime resources that define training execution templates |
| clustertrainingruntime-controller | Controller | Manages cluster-scoped ClusterTrainingRuntime resources for shared training templates |
| progression-watcher | RHOAI Plugin | Tracks distributed training job progression and updates status (RHOAI-specific) |

## APIs Exposed

### Custom Resource Definitions (CRDs)

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| trainer.kubeflow.org | v1alpha1 | TrainJob | Namespaced | Represents a training job with specifications for dataset, model, training parameters, and runtime reference |
| trainer.kubeflow.org | v1alpha1 | TrainingRuntime | Namespaced | Defines a namespaced training runtime template (e.g., PyTorch, DeepSpeed) that can be referenced by TrainJobs in the same namespace |
| trainer.kubeflow.org | v1alpha1 | ClusterTrainingRuntime | Cluster | Defines a cluster-wide training runtime template that can be referenced by TrainJobs in any namespace |

### HTTP Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /healthz | GET | 8081/TCP | HTTP | None | None | Liveness probe for controller health checks |
| /readyz | GET | 8081/TCP | HTTP | None | None | Readiness probe to determine if controller is ready to serve requests |
| /validate-trainer-kubeflow-org-v1alpha1-trainjob | POST | 9443/TCP | HTTPS | TLS 1.2+ | mTLS | Validating webhook for TrainJob resources on CREATE/UPDATE operations |
| /validate-trainer-kubeflow-org-v1alpha1-trainingruntime | POST | 9443/TCP | HTTPS | TLS 1.2+ | mTLS | Validating webhook for TrainingRuntime resources on CREATE/UPDATE operations |
| /validate-trainer-kubeflow-org-v1alpha1-clustertrainingruntime | POST | 9443/TCP | HTTPS | TLS 1.2+ | mTLS | Validating webhook for ClusterTrainingRuntime resources on CREATE/UPDATE operations |
| /metrics | GET | 8443/TCP | HTTPS | TLS 1.2+ | Bearer Token | Prometheus metrics endpoint for controller monitoring (RHOAI uses HTTPS) |

### gRPC Services

| Service | Port | Protocol | Encryption | Auth | Purpose |
|---------|------|----------|------------|------|---------|
| N/A | N/A | N/A | N/A | N/A | No gRPC services exposed |

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| JobSet | v1alpha2 (v0.10.1) | Yes | Creates and manages sets of Jobs for distributed training workloads |
| Kubernetes | v1.29+ | Yes | Container orchestration platform |
| Volcano | v1.13+ | No | Gang scheduling and advanced scheduling capabilities for distributed training |
| Kueue/scheduler-plugins | v1alpha1 | No | Job queueing and coscheduling for multi-pod training jobs |
| cert-manager | v1.0+ | No | Certificate provisioning for webhook TLS (can use manual cert provisioning) |

### Internal ODH/RHOAI Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| opendatahub-operator | CRD Management | Installs and manages Trainer component lifecycle in RHOAI |
| RHOAI Dashboard | UI/API | Users create TrainJobs through dashboard interface |
| RHOAI Metrics/Monitoring | Metrics | PodMonitor scrapes controller metrics for observability |
| Model Registry | Storage API | Training jobs may store trained models to model registry |
| S3 Storage | S3 API | Training jobs access datasets and checkpoints from object storage |

## Network Architecture

### Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| kubeflow-trainer-controller-manager | ClusterIP | 443/TCP | 9443 | HTTPS | TLS 1.2+ | mTLS | Internal (webhook) |

### Ingress

| Name | Type | Hosts | Port | Protocol | Encryption | TLS Mode | Exposure |
|------|------|-------|------|----------|------------|----------|----------|
| N/A | N/A | N/A | N/A | N/A | N/A | N/A | No ingress routes (internal controller only) |

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token | Watch CRDs, create/update JobSets, Pods, Services |
| S3-compatible Storage | 443/TCP | HTTPS | TLS 1.2+ | AWS IAM/S3 Credentials | Download datasets and models during training job initialization |
| Container Registry | 443/TCP | HTTPS | TLS 1.2+ | Pull Secrets | Pull training runtime container images |
| Volcano API | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token | Create PodGroups for gang scheduling (if Volcano enabled) |

## Security

### RBAC - Cluster Roles

| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|
| kubeflow-trainer-controller-manager | "" | configmaps, secrets | create, get, list, patch, update, watch |
| kubeflow-trainer-controller-manager | "" | events | create, patch, update, watch |
| kubeflow-trainer-controller-manager | "" | limitranges | get, list, watch |
| kubeflow-trainer-controller-manager | admissionregistration.k8s.io | validatingwebhookconfigurations | get, list, update, watch |
| kubeflow-trainer-controller-manager | coordination.k8s.io | leases | create, get, list, update |
| kubeflow-trainer-controller-manager | jobset.x-k8s.io | jobsets | create, get, list, patch, update, watch |
| kubeflow-trainer-controller-manager | node.k8s.io | runtimeclasses | get, list, watch |
| kubeflow-trainer-controller-manager | scheduling.volcano.sh, scheduling.x-k8s.io | podgroups | create, get, list, patch, update, watch |
| kubeflow-trainer-controller-manager | trainer.kubeflow.org | clustertrainingruntimes, trainingruntimes, trainjobs | get, list, patch, update, watch |
| kubeflow-trainer-controller-manager | trainer.kubeflow.org | clustertrainingruntimes/finalizers, trainingruntimes/finalizers, trainjobs/finalizers, trainjobs/status | get, patch, update |

### RBAC - Role Bindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| kubeflow-trainer-controller-manager | cluster-wide | kubeflow-trainer-controller-manager (ClusterRole) | opendatahub/kubeflow-trainer-controller-manager |

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| kubeflow-trainer-webhook-cert | kubernetes.io/tls | TLS certificate for validating webhook server | cert-controller/kustomize secretGenerator | No |

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| Kubernetes API | GET, LIST, WATCH, CREATE, UPDATE, PATCH | ServiceAccount Token (JWT) | Kubernetes API Server | ClusterRole RBAC |
| Webhook Endpoints | POST | mTLS (Kubernetes API Server client cert) | Webhook Server | Kubernetes admission control |
| Metrics Endpoint | GET | HTTPS (TLS bearer token auth in RHOAI) | PodMonitor/Prometheus | ServiceMonitor scrape config |

## Data Flows

### Flow 1: TrainJob Submission and Execution

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User/Dashboard | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | Bearer Token (user credentials) |
| 2 | Kubernetes API | Webhook Server | 9443/TCP | HTTPS | TLS 1.2+ | mTLS (API server client cert) |
| 3 | TrainJob Controller | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 4 | TrainJob Controller | Kubernetes API (create JobSet) | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 5 | JobSet Controller | Kubernetes API (create Jobs/Pods) | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 6 | Training Pods | S3 Storage (dataset download) | 443/TCP | HTTPS | TLS 1.2+ | S3 Credentials (secret) |
| 7 | Training Pods | Training Pods (distributed comm) | 29500/TCP | TCP | None/NCCL | None (Pod network) |
| 8 | Training Pods | S3 Storage (checkpoint upload) | 443/TCP | HTTPS | TLS 1.2+ | S3 Credentials (secret) |

### Flow 2: Webhook Validation

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Kubernetes API | Webhook Server | 9443/TCP | HTTPS | TLS 1.2+ | mTLS (API server client cert) |
| 2 | Webhook Server | Kubernetes API (validation response) | N/A | N/A | N/A | N/A (HTTP response) |

### Flow 3: Metrics Collection

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Prometheus | Controller Metrics Endpoint | 8443/TCP | HTTPS | TLS 1.2+ | Bearer Token (ServiceAccount) |
| 2 | Prometheus | Prometheus Time-Series DB | Internal | Internal | Internal | Internal |

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| Kubernetes API Server | REST API | 6443/TCP | HTTPS | TLS 1.2+ | Watch CRDs, create/manage resources |
| JobSet Controller | CRD Watch | 6443/TCP | HTTPS | TLS 1.2+ | Trainer creates JobSet resources; JobSet controller creates Jobs |
| Volcano Scheduler | CRD API | 6443/TCP | HTTPS | TLS 1.2+ | Create PodGroups for gang scheduling (optional) |
| Prometheus | Metrics Scrape | 8443/TCP | HTTPS | TLS 1.2+ | Metrics collection via PodMonitor |
| RHOAI Dashboard | API/UI | 6443/TCP | HTTPS | TLS 1.2+ | Users create TrainJobs through dashboard |

## Training Runtimes (RHOAI)

### Built-in ClusterTrainingRuntimes

| Runtime Name | Framework | Hardware | Image | Purpose |
|--------------|-----------|----------|-------|---------|
| torch-distributed | PyTorch | CUDA 12.8 | quay.io/modh/training:py312-cuda128-torch280 | PyTorch distributed training on NVIDIA GPUs |
| torch-distributed-rocm | PyTorch | ROCm 6.4 | quay.io/modh/training:py312-rocm64-torch280 | PyTorch distributed training on AMD GPUs |
| torch-distributed-th03-cuda128-torch28-py312 | PyTorch | CUDA 12.8 | quay.io/modh/training:py312-cuda128-torch280 | PyTorch distributed with TorchHub03 support |
| training-hub | Generic | CUDA 12.8 | quay.io/modh/training:py312-cuda128-torch280 | Generic training runtime for custom frameworks |
| training-hub03-cuda128-torch28-py312 | Generic | CUDA 12.8 | quay.io/modh/training:py312-cuda128-torch280 | TorchHub03-enabled generic runtime |

## Recent Changes

| Version | Date | Changes |
|---------|------|---------|
| 46393c34 | 3 months ago | - Merge upstream changes from Kubeflow main branch<br>- Remove old Trainer operator image builds<br>- Provide training runtimes from Training Operator v1 for backward compatibility |
| 8d43151c | 3 months ago | - Fix testing issues in midstream CI<br>- Fix golint issues in codebase<br>- Disable golangci-lint-kal in CI |
| 8ddd0ab9 | 3 months ago | - Update Tekton output-image tags to version 2.1.0<br>- Refactor: Remove RHAI preStop hook injection from JobSet plugin |
| c66632be | 3 months ago | - Merge upstream main branch<br>- Maintain RHOAI 3.2 branch compatibility |
| 30b841f1 | 3 months ago | - Remove unused Dockerfile.rhoai<br>- Consolidate to Dockerfile.rhoai.konflux for Konflux builds |

## Deployment Architecture

### Container Images

| Image Name | Registry | Tag | Build System | Purpose |
|------------|----------|-----|--------------|---------|
| odh-trainer-rhel9 | quay.io/opendatahub/trainer | v2.1.0 | Konflux | Main controller manager container |
| training | quay.io/modh/training | py312-cuda128-torch280 | RHOAI Build | CUDA 12.8 PyTorch 2.8.0 training runtime |
| training | quay.io/modh/training | py312-rocm64-torch280 | RHOAI Build | ROCm 6.4 PyTorch 2.8.0 training runtime |

### Namespace Configuration

- **Default Namespace**: opendatahub (RHOAI deployment)
- **ServiceAccount**: kubeflow-trainer-controller-manager
- **Deployment Replicas**: 1 (single controller instance with leader election)

### Resource Requirements

| Container | CPU Request | CPU Limit | Memory Request | Memory Limit |
|-----------|-------------|-----------|----------------|--------------|
| manager | Not specified | Not specified | Not specified | Not specified |

### Security Context

| Setting | Value | Purpose |
|---------|-------|---------|
| runAsNonRoot | true | Prevent container from running as root user |
| allowPrivilegeEscalation | false | Prevent privilege escalation attacks |
| seccompProfile | RuntimeDefault | Apply default seccomp profile for syscall filtering |
| capabilities.drop | ALL | Drop all Linux capabilities for minimal privileges |

## Controller Behavior

### Reconciliation Logic

1. **TrainJob Controller**:
   - Watches TrainJob resources
   - Resolves TrainingRuntime or ClusterTrainingRuntime reference
   - Validates runtime configuration and initializer settings
   - Creates JobSet resource with merged configuration from TrainJob and runtime template
   - Updates TrainJob status based on JobSet conditions
   - Handles finalizers for cleanup on deletion

2. **TrainingRuntime Controller**:
   - Watches TrainingRuntime resources
   - Validates runtime template specifications
   - Triggers re-reconciliation of dependent TrainJobs when runtime changes

3. **ClusterTrainingRuntime Controller**:
   - Watches ClusterTrainingRuntime resources
   - Validates cluster-wide runtime template specifications
   - Triggers re-reconciliation of dependent TrainJobs when runtime changes

### Leader Election

- Uses Kubernetes leases in coordination.k8s.io API group
- Single active controller instance at a time
- Automatic failover on controller pod failure

## Observability

### Metrics

| Metric Name | Type | Purpose |
|-------------|------|---------|
| controller_runtime_reconcile_total | Counter | Total number of reconciliation operations |
| controller_runtime_reconcile_errors_total | Counter | Total number of reconciliation errors |
| controller_runtime_reconcile_time_seconds | Histogram | Reconciliation duration histogram |
| workqueue_depth | Gauge | Current depth of work queue |
| workqueue_adds_total | Counter | Total number of items added to queue |

### Logging

- Structured JSON logging using zap logger
- Log levels: info, debug, error
- Request-scoped logging with TrainJob name/namespace context

### Health Checks

- **Liveness Probe**: HTTP GET /healthz on port 8081
  - Initial delay: 15 seconds
  - Period: 20 seconds
  - Timeout: 3 seconds
- **Readiness Probe**: HTTP GET /readyz on port 8081
  - Initial delay: 10 seconds
  - Period: 15 seconds
  - Timeout: 3 seconds

## Known Limitations

1. **Alpha Status**: APIs in v1alpha1 may change; not recommended for production without thorough testing
2. **Single Controller**: No horizontal scaling; single pod handles all TrainJob reconciliation
3. **No Built-in Autoscaling**: Training jobs do not automatically scale based on resource availability
4. **Limited Framework Support**: Built-in runtimes focus on PyTorch; other frameworks require custom runtime definitions
5. **JobSet Dependency**: Requires JobSet CRD to be installed separately (not bundled in RHOAI manifests)

## Migration Notes

This is Kubeflow Trainer v2 (successor to Training Operator v1). Users migrating from Training Operator v1 should note:

- **API Changes**: New TrainJob API replaces framework-specific CRDs (PyTorchJob, TFJob, etc.)
- **Runtime Abstraction**: TrainingRuntime/ClusterTrainingRuntime provide template-based configuration
- **JobSet Backend**: Uses JobSet instead of direct Pod management for improved multi-job coordination
- **Backward Compatibility**: RHOAI includes v1 training runtimes for transition period

Refer to upstream migration guide: https://www.kubeflow.org/docs/components/trainer/operator-guides/migration/
