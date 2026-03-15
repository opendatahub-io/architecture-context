# Component: Kubeflow Trainer

## Metadata
- **Repository**: https://github.com/red-hat-data-services/trainer.git
- **Version**: 59d68380 (rhoai-3.3 branch)
- **Upstream**: Kubeflow Trainer v2.1.0
- **Distribution**: RHOAI
- **Languages**: Go 1.24.0
- **Deployment Type**: Kubernetes Operator

## Purpose
**Short**: Kubernetes-native operator for distributed machine learning training and LLM fine-tuning.

**Detailed**: Kubeflow Trainer is a Kubernetes operator designed for large language model (LLM) fine-tuning and distributed training of machine learning models across various frameworks including PyTorch, JAX, TensorFlow, DeepSpeed, and MLX. It provides a declarative API for defining training jobs through custom resources (TrainJob) and reusable training runtime templates (TrainingRuntime/ClusterTrainingRuntime). The operator manages the lifecycle of distributed training workloads by creating JobSets, configuring gang scheduling, and integrating with ML-specific technologies like PyTorch torchrun, MPI, and DeepSpeed. RHOAI extends the upstream with progression tracking capabilities that poll training metrics from pods to provide real-time training status updates.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| trainer-controller-manager | Go Controller/Operator | Main reconciliation loop managing TrainJob, TrainingRuntime, and ClusterTrainingRuntime resources |
| Validating Webhooks | Admission Controller | Validates TrainJob, TrainingRuntime, and ClusterTrainingRuntime on CREATE/UPDATE operations |
| TrainJob Controller | Reconciler | Creates JobSets from TrainJobs, manages training lifecycle, updates status conditions |
| TrainingRuntime Controller | Reconciler | Watches TrainingRuntime resources and notifies TrainJobs of changes |
| ClusterTrainingRuntime Controller | Reconciler | Watches ClusterTrainingRuntime resources (cluster-scoped) and notifies TrainJobs |
| Progression Tracker (RHOAI) | Extension | Polls HTTP metrics from training pods to track real-time progress and update annotations |
| Network Policy Manager (RHOAI) | Extension | Creates NetworkPolicies to isolate training pods and secure metrics endpoints |

## APIs Exposed

### Custom Resource Definitions (CRDs)

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| trainer.kubeflow.org | v1alpha1 | TrainJob | Namespaced | Represents a training job with dataset, model, trainer config, and runtime reference |
| trainer.kubeflow.org | v1alpha1 | TrainingRuntime | Namespaced | Defines reusable training runtime template (namespaced, same namespace as TrainJob) |
| trainer.kubeflow.org | v1alpha1 | ClusterTrainingRuntime | Cluster | Defines reusable training runtime template (cluster-scoped, any namespace) |

### HTTP Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /validate-trainer-kubeflow-org-v1alpha1-trainjob | POST | 9443/TCP | HTTPS | TLS | Kubernetes API Server (mTLS) | Validating webhook for TrainJob CREATE/UPDATE |
| /validate-trainer-kubeflow-org-v1alpha1-trainingruntime | POST | 9443/TCP | HTTPS | TLS | Kubernetes API Server (mTLS) | Validating webhook for TrainingRuntime CREATE/UPDATE |
| /validate-trainer-kubeflow-org-v1alpha1-clustertrainingruntime | POST | 9443/TCP | HTTPS | TLS | Kubernetes API Server (mTLS) | Validating webhook for ClusterTrainingRuntime CREATE/UPDATE |
| /healthz | GET | 8081/TCP | HTTP | None | None | Controller liveness probe |
| /readyz | GET | 8081/TCP | HTTP | None | None | Controller readiness probe |
| /metrics | GET | 8080/TCP | HTTPS | TLS | None | Prometheus metrics for controller (RHOAI exposes via PodMonitor) |
| /metrics | GET | 28080/TCP | HTTP | None | NetworkPolicy restricted | Training pod metrics endpoint (RHOAI progression tracking) |

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| Kubernetes | v1.34.1 | Yes | Platform for running operator and training workloads |
| JobSet | v0.10.1 | Yes | Creates sets of Jobs for distributed training (multi-node, multi-job patterns) |
| Volcano Scheduler | v1.13.1 | Optional | Gang-scheduling plugin for all-or-nothing pod scheduling |
| Coscheduling Plugin | v0.34.1-devel | Optional | Kubernetes scheduler-plugins gang-scheduling (alternative to Volcano) |
| LeaderWorkerSet | latest | Optional | Manages leader-worker pod topologies for certain runtimes |
| Prometheus Operator | any | Optional (RHOAI) | Enables PodMonitor for metrics scraping |

### Internal ODH Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| Kueue | CRD watch | Integrates with Kueue for queue-based job management (via managedBy field) |
| OpenShift Service Mesh | NetworkPolicy | Training pods may use mesh for secure inter-pod communication |
| OpenShift Monitoring | PodMonitor | RHOAI exposes controller metrics via PodMonitor to cluster monitoring |

## Network Architecture

### Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| kubeflow-trainer-controller-manager | ClusterIP | 443/TCP | 9443 | HTTPS | TLS | Kubernetes API Server mTLS | Internal (webhook) |
| kubeflow-trainer-controller-manager | ClusterIP | 8080/TCP | 8080 | HTTPS | TLS (RHOAI) | None | Internal (metrics) |

### Ingress

| Name | Type | Hosts | Port | Protocol | Encryption | TLS Mode | Exposure |
|------|------|-------|------|----------|------------|----------|----------|
| N/A | N/A | N/A | N/A | N/A | N/A | N/A | No ingress (internal operator only) |

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token | Watch CRDs, create JobSets, manage resources |
| Training Pods | 28080/TCP | HTTP | None | NetworkPolicy (pod selector) | Poll metrics for progression tracking (RHOAI) |
| Training Pods | Dynamic | TCP | None | None | Inter-pod communication for NCCL, MPI, gRPC (same-job pods) |

## Security

### RBAC - Cluster Roles

| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|
| kubeflow-trainer-controller-manager | "" | configmaps, secrets | create, get, list, patch, update, watch |
| kubeflow-trainer-controller-manager | "" | events | create, patch, update, watch |
| kubeflow-trainer-controller-manager | "" | limitranges | get, list, watch |
| kubeflow-trainer-controller-manager | "" | pods (RHOAI) | get, list |
| kubeflow-trainer-controller-manager | admissionregistration.k8s.io | validatingwebhookconfigurations | get, list, update, watch |
| kubeflow-trainer-controller-manager | coordination.k8s.io | leases | create, get, list, update |
| kubeflow-trainer-controller-manager | jobset.x-k8s.io | jobsets | create, get, list, patch, update, watch |
| kubeflow-trainer-controller-manager | node.k8s.io | runtimeclasses | get, list, watch |
| kubeflow-trainer-controller-manager | scheduling.volcano.sh, scheduling.x-k8s.io | podgroups | create, get, list, patch, update, watch |
| kubeflow-trainer-controller-manager | trainer.kubeflow.org | clustertrainingruntimes, trainingruntimes, trainjobs | get, list, patch, update, watch |
| kubeflow-trainer-controller-manager | trainer.kubeflow.org | clustertrainingruntimes/finalizers, trainingruntimes/finalizers, trainjobs/finalizers, trainjobs/status | get, patch, update |
| kubeflow-trainer-controller-manager | networking.k8s.io (RHOAI) | networkpolicies | get, list, watch, create, update, patch |

### RBAC - Role Bindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| kubeflow-trainer-controller-manager | cluster-wide | kubeflow-trainer-controller-manager (ClusterRole) | kubeflow-trainer-controller-manager (opendatahub namespace) |

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| kubeflow-trainer-webhook-cert | kubernetes.io/tls | TLS certificate for validating webhook server | cert-controller (OPA) | Yes |

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| /validate-* | POST | Kubernetes API Server mTLS | API Server | API server verifies service account token and TLS cert |
| /healthz, /readyz | GET | None | None | Public (internal cluster only) |
| /metrics (controller) | GET | None (RHOAI uses TLS) | PodMonitor scraping | Cluster monitoring scrapes via TLS |
| /metrics (training pods) | GET | NetworkPolicy | NetworkPolicy | RHOAI restricts to controller pods only via podSelector |

### Network Policies (RHOAI)

| Policy Name | Namespace | Pod Selector | Ingress From | Ports | Purpose |
|-------------|-----------|--------------|--------------|-------|---------|
| {trainjob-name} | TrainJob namespace | jobset.sigs.k8s.io/jobset-name={trainjob-name} | Same JobSet pods | All | Allow inter-pod communication for NCCL, MPI, gRPC |
| {trainjob-name} | TrainJob namespace | jobset.sigs.k8s.io/jobset-name={trainjob-name} | Controller pods (opendatahub namespace) | 28080/TCP | Allow controller to poll metrics for progression tracking |

## Data Flows

### Flow 1: TrainJob Creation

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User (kubectl/SDK) | Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.3 | User credentials |
| 2 | API Server | Validating Webhook | 9443/TCP | HTTPS | TLS | API Server mTLS |
| 3 | API Server | TrainJob Controller | Watch stream | HTTPS | TLS 1.3 | ServiceAccount token |
| 4 | TrainJob Controller | Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.3 | ServiceAccount token |
| 5 | TrainJob Controller | JobSet (created) | N/A | N/A | N/A | Kubernetes resource creation |

### Flow 2: Training Execution

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | JobSet Controller | Training Pods (node-0, node-1...) | N/A | N/A | N/A | Kubernetes pod scheduling |
| 2 | Training Pod (launcher) | Training Pods (workers) | Dynamic | TCP | None | MPI/NCCL internal |
| 3 | Training Pods | Training Pods | Dynamic | TCP | None | Inter-pod communication (NCCL all-reduce, gRPC) |
| 4 | Training Pods | S3/Storage | 443/TCP | HTTPS | TLS 1.2+ | AWS IAM (via secret) |

### Flow 3: Progression Tracking (RHOAI)

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | TrainJob Controller | Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.3 | ServiceAccount token |
| 2 | TrainJob Controller (list pods) | Training Pods | N/A | N/A | N/A | API response with pod IPs |
| 3 | TrainJob Controller | Training Pod /metrics | 28080/TCP | HTTP | None | NetworkPolicy restricted |
| 4 | Training Pod | TrainJob Controller | Response | HTTP | None | JSON metrics response |
| 5 | TrainJob Controller | Kubernetes API Server (update annotation) | 6443/TCP | HTTPS | TLS 1.3 | ServiceAccount token |

### Flow 4: Gang Scheduling (Volcano/Coscheduling)

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | TrainJob Controller | PodGroup (created) | N/A | N/A | N/A | Kubernetes resource creation |
| 2 | Scheduler Plugin | PodGroup (watch) | 6443/TCP | HTTPS | TLS 1.3 | ServiceAccount token |
| 3 | Scheduler Plugin | All training pods | N/A | N/A | N/A | All-or-nothing scheduling decision |

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| Kubernetes API Server | gRPC/HTTP2 | 6443/TCP | HTTPS | TLS 1.3 | Watch CRDs, create/update resources |
| JobSet Controller | CRD watch | 6443/TCP | HTTPS | TLS 1.3 | JobSet creates/manages Jobs from TrainJob |
| Volcano Scheduler | CRD watch (PodGroup) | 6443/TCP | HTTPS | TLS 1.3 | Gang-scheduling for all-or-nothing pod scheduling |
| Prometheus (RHOAI) | HTTP (PodMonitor) | 8080/TCP | HTTPS | TLS | Scrape controller metrics for monitoring |
| Training Pods | HTTP | 28080/TCP | HTTP | None | Poll metrics for progression tracking (RHOAI) |
| Kueue | CRD watch | 6443/TCP | HTTPS | TLS 1.3 | Multi-cluster job queueing (via managedBy field) |

## Training Runtimes

### Built-in Runtimes (RHOAI)

| Runtime Name | Framework | Image | GPU Support | Purpose |
|--------------|-----------|-------|-------------|---------|
| torch-distributed | PyTorch | odh-training-cuda128-torch29-py312 | CUDA 12.8 | PyTorch distributed training with torchrun |
| torch-distributed-rocm | PyTorch | odh-training-rocm64-torch29-py312 | ROCm 6.4 | PyTorch on AMD GPUs |
| training-hub | PyTorch + HuggingFace | odh-training-cuda128-torch29-py312 | CUDA 12.8 | LLM fine-tuning with Transformers |
| deepspeed-distributed | DeepSpeed | pytorch/pytorch:2.7.1-cuda12.8 | CUDA 12.8 | DeepSpeed for memory-efficient training |
| mlx-distributed | MLX | N/A | Apple Silicon | Training on Apple M-series GPUs |

### ML Policy Capabilities

| Feature | PyTorch Runtime | MPI Runtime | Purpose |
|---------|-----------------|-------------|---------|
| numProcPerNode | auto, cpu, gpu, int | int | Number of processes/workers per node |
| Elastic Training | Yes (via elasticPolicy) | No | Dynamic node scaling with HPA |
| Gang Scheduling | Yes (Volcano/Coscheduling) | Yes | All-or-nothing pod scheduling |
| SSH Auth | No | Yes (for MPI) | Inter-node SSH for MPI launcher |

## Initializers

| Initializer | Container | Purpose | Configuration |
|-------------|-----------|---------|---------------|
| Dataset Initializer | dataset-initializer | Downloads/preprocesses datasets from S3, GCS, HuggingFace Hub | storageUri, secretRef, env vars |
| Model Initializer | model-initializer | Downloads pre-trained models from HuggingFace, S3 | storageUri, secretRef, env vars |

## Container Images

| Image | Purpose | Registry | Konflux Built |
|-------|---------|----------|---------------|
| odh-trainer-rhel9 | Trainer controller manager | quay.io/opendatahub/trainer:v2.1.0 | Yes (Dockerfile.rhoai.konflux) |
| odh-training-cuda128-torch29-py312 | PyTorch CUDA training runtime | quay.io/opendatahub | Yes |
| odh-training-rocm64-torch29-py312 | PyTorch ROCm training runtime | quay.io/opendatahub | Yes |

## Recent Changes

| Commit | Date | Changes |
|--------|------|---------|
| 59d68380 | Recent | - Sync pipelineruns with konflux-central<br>- Merge upstream main into rhoai-3.3 |
| 7a55d6c1 | Recent | - Merge remote-tracking branch 'upstream/main' into rhoai-3.3 |
| c7191b6d | Recent | - Update kustomization resources |
| 77a2aa67 | Recent | - Remove torch28 params |
| 3f69ba66 | Recent | - Add more runtimes (CUDA, ROCm variants) |
| 1f555d80 | Recent | - Remove universal image and add new runtimes for cuda and rocm |
| c0df7487 | Recent | - feat: Add network policy for TrainJobs |

## RHOAI-Specific Extensions

### Progression Tracking

| Feature | Implementation | Purpose |
|---------|---------------|---------|
| Metrics Polling | HTTP GET to pod /metrics endpoint | Real-time training progress (loss, step, percentage) |
| Status Annotation | trainer.opendatahub.io/trainerStatus | JSON with current training metrics |
| Poll Interval | trainer.opendatahub.io/metrics-poll-interval (default 30s) | Configurable polling frequency |
| Metrics Port | trainer.opendatahub.io/metrics-port (default 28080) | Configurable metrics endpoint port |
| NetworkPolicy | Auto-created per TrainJob | Restricts metrics endpoint to controller pods only |

### Annotations

| Annotation | Values | Purpose |
|------------|--------|---------|
| trainer.opendatahub.io/progression-tracking | enabled/disabled | Enable real-time metrics polling |
| trainer.opendatahub.io/metrics-port | port number (default 28080) | Training pod metrics endpoint port |
| trainer.opendatahub.io/metrics-poll-interval | duration (default 30s) | How often to poll metrics |
| trainer.opendatahub.io/trainerStatus | JSON object | Current training progress (written by controller) |

### Expected Metrics Format

```json
{
  "progressPercentage": 45,
  "currentStep": 450,
  "totalSteps": 1000,
  "trainMetrics": {
    "loss": 0.235,
    "accuracy": 0.89
  }
}
```

## Deployment Configuration

### Kustomize Structure

| Directory | Purpose |
|-----------|---------|
| manifests/base/crds | CRD definitions for TrainJob, TrainingRuntime, ClusterTrainingRuntime |
| manifests/base/manager | Deployment for trainer-controller-manager |
| manifests/base/rbac | ServiceAccount, ClusterRole, ClusterRoleBinding |
| manifests/base/webhook | ValidatingWebhookConfiguration |
| manifests/base/runtimes | Built-in ClusterTrainingRuntime templates (torch, deepspeed, mlx, torchtune) |
| manifests/rhoai | RHOAI overlay with image replacements, PodMonitor, progression RBAC |
| manifests/third-party/jobset | JobSet CRD and controller |
| manifests/third-party/leaderworkerset | LeaderWorkerSet CRD and controller |

### Key Parameters (RHOAI)

| Parameter | Value | Purpose |
|-----------|-------|---------|
| namespace | opendatahub | Deployment namespace for controller |
| odh-kubeflow-trainer-controller-image | quay.io/opendatahub/trainer:v2.1.0 | Controller manager image |
| odh-training-cuda128-torch29-py312-image | quay.io/opendatahub/odh-training-cuda128-torch29-py312@sha256:87539ef... | CUDA PyTorch runtime image |
| odh-training-rocm64-torch29-py312-image | quay.io/opendatahub/odh-training-rocm64-torch29-py312@sha256:4f72c0... | ROCm PyTorch runtime image |

## Monitoring & Observability

| Metric Type | Endpoint | Port | Protocol | Purpose |
|-------------|----------|------|----------|---------|
| Controller Metrics | /metrics | 8080/TCP | HTTPS (TLS) | Prometheus metrics for controller (reconciliation, errors, latency) |
| Training Metrics (RHOAI) | /metrics | 28080/TCP | HTTP | Training progress (loss, accuracy, step) exposed by user code |

### PodMonitor Configuration (RHOAI)

```yaml
apiVersion: monitoring.coreos.com/v1
kind: PodMonitor
metadata:
  name: kubeflow-trainer-controller-manager-metrics-monitor
spec:
  selector:
    matchLabels:
      app.kubernetes.io/name: trainer
      app.kubernetes.io/component: controller
  podMetricsEndpoints:
    - port: metrics (8080)
      scheme: https
      tlsConfig:
        insecureSkipVerify: true
```

## Limitations & Constraints

| Limitation | Impact | Workaround |
|------------|--------|------------|
| TrainJob name must be RFC 1035 DNS label | Max 63 characters, lowercase alphanumeric + hyphens | Use short, descriptive names |
| RuntimeRef is immutable | Cannot change runtime after creation | Delete and recreate TrainJob |
| Progression tracking HTTP only | No encryption for metrics endpoint | NetworkPolicy restricts access to controller pods |
| Gang scheduling requires Volcano or Coscheduling | External dependency for all-or-nothing scheduling | Deploy scheduler plugin or use default Kubernetes scheduler (may cause deadlock) |
| Elastic training only for PyTorch | MPI runtime doesn't support dynamic scaling | Use PyTorch runtime with elasticPolicy for auto-scaling |

## Example TrainJob

```yaml
apiVersion: trainer.kubeflow.org/v1alpha1
kind: TrainJob
metadata:
  name: llama-finetune
  annotations:
    trainer.opendatahub.io/progression-tracking: "enabled"
    trainer.opendatahub.io/metrics-port: "28080"
spec:
  runtimeRef:
    name: torch-distributed
    kind: ClusterTrainingRuntime
  initializer:
    dataset:
      storageUri: "hf://datasets/my-dataset"
      secretRef:
        name: hf-token
    model:
      storageUri: "hf://meta-llama/Llama-3.2-1B"
      secretRef:
        name: hf-token
  trainer:
    image: quay.io/opendatahub/odh-training-cuda128-torch29-py312
    numNodes: 2
    resourcesPerNode:
      requests:
        nvidia.com/gpu: 1
      limits:
        nvidia.com/gpu: 1
    numProcPerNode: 1
    command:
      - torchrun
      - train.py
    args:
      - --epochs=10
      - --batch-size=32
```

## Notes

- **Upstream alignment**: RHOAI tracks Kubeflow Trainer v2.1.0 with RHOAI-specific extensions in `pkg/rhai/`
- **Konflux CI/CD**: All container images built via Konflux pipelines (`.tekton/` directory)
- **JobSet dependency**: Critical dependency for multi-node training; bundled in RHOAI manifests
- **Network isolation**: NetworkPolicies ensure training pods can only communicate with same-job pods and controller (for metrics)
- **Gang scheduling**: Optional but recommended for multi-node training to avoid resource deadlock
- **Python SDK**: Users can create TrainJobs via `kubeflow-sdk` Python library (not included in this component)
- **Storage integration**: Supports S3, GCS, HuggingFace Hub, and PVCs for datasets and models
- **GPU support**: CUDA (NVIDIA) and ROCm (AMD) runtimes available; MLX for Apple Silicon
