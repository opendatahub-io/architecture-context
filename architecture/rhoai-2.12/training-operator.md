# Component: Kubeflow Training Operator

## Metadata
- **Repository**: https://github.com/red-hat-data-services/training-operator.git
- **Version**: c7d4e1b4 (rhoai-2.12 branch)
- **Distribution**: RHOAI
- **Languages**: Go 1.21
- **Deployment Type**: Kubernetes Operator

## Purpose
**Short**: Kubernetes-native operator for distributed training of machine learning models across multiple ML frameworks.

**Detailed**: The Kubeflow Training Operator is a unified Kubernetes operator that enables scalable distributed training and fine-tuning of machine learning models using various frameworks including PyTorch, TensorFlow, XGBoost, MPI, MXNet, and PaddlePaddle. It provides Kubernetes Custom Resources for each framework, abstracting the complexity of distributed training by managing pod orchestration, service discovery, and gang scheduling. The operator handles the lifecycle of training jobs including creation, scaling, monitoring, and cleanup of training pods and associated resources. It supports advanced features like PyTorch elastic training with horizontal pod autoscaling, gang scheduling integration with Volcano and scheduler-plugins, and suspend/resume semantics for resource management.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| training-operator | Deployment | Main controller managing all training job types |
| PyTorch Controller | Reconciler | Manages PyTorchJob CRDs and supports elastic training |
| TensorFlow Controller | Reconciler | Manages TFJob CRDs for distributed TensorFlow training |
| MPI Controller | Reconciler | Manages MPIJob CRDs for MPI-based training |
| MXNet Controller | Reconciler | Manages MXJob CRDs for Apache MXNet training |
| XGBoost Controller | Reconciler | Manages XGBoostJob CRDs for XGBoost training |
| PaddlePaddle Controller | Reconciler | Manages PaddleJob CRDs for PaddlePaddle training |
| Gang Scheduler Integration | Optional Plugin | Integrates with Volcano or scheduler-plugins for gang scheduling |
| Webhook Server | Admission Webhook | Validates and mutates training job specifications |
| Python SDK | Client Library | Provides Python API for creating and managing training jobs |

## APIs Exposed

### Custom Resource Definitions (CRDs)

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| kubeflow.org | v1 | PyTorchJob | Namespaced | Defines distributed PyTorch training jobs with master/worker replicas |
| kubeflow.org | v1 | TFJob | Namespaced | Defines distributed TensorFlow training jobs with parameter servers and workers |
| kubeflow.org | v1 | MPIJob | Namespaced | Defines MPI-based distributed training jobs with launcher and worker processes |
| kubeflow.org | v1 | MXJob | Namespaced | Defines Apache MXNet distributed training jobs |
| kubeflow.org | v1 | XGBoostJob | Namespaced | Defines distributed XGBoost training jobs |
| kubeflow.org | v1 | PaddleJob | Namespaced | Defines PaddlePaddle distributed training jobs |

### HTTP Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /metrics | GET | 8080/TCP | HTTP | None | None | Prometheus metrics endpoint for operator health and job statistics |
| /healthz | GET | 8081/TCP | HTTP | None | None | Liveness probe endpoint for operator health checks |
| /readyz | GET | 8081/TCP | HTTP | None | None | Readiness probe endpoint for operator startup verification |

### gRPC Services

None - This operator uses Kubernetes API and HTTP endpoints only.

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| Kubernetes | 1.25+ | Yes | Container orchestration platform for running training jobs |
| Prometheus | Any | No | Metrics collection and monitoring of training jobs |
| Volcano | v1beta1 | No | Gang scheduling for coordinated pod scheduling |
| scheduler-plugins | v1alpha1 | No | Alternative gang scheduling implementation |
| cert-manager | Any | No | Certificate management for webhook server TLS |

### Internal ODH Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| opendatahub-operator | Deployment | Deploys and manages training-operator via kustomize manifests |
| monitoring | Metrics | PodMonitor scrapes metrics from training-operator pods |

## Network Architecture

### Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| training-operator | ClusterIP | 8080/TCP | 8080 | HTTP | None | None | Internal (metrics) |

### Ingress

No ingress resources - operator uses internal Kubernetes API communication only.

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token | Watch and reconcile training job CRDs |
| Container Registries | 443/TCP | HTTPS | TLS 1.2+ | Image Pull Secrets | Pull training container images |
| Volcano API (optional) | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token | Create and manage PodGroup resources for gang scheduling |

## Security

### RBAC - Cluster Roles

| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|
| training-operator | "" | pods, services, configmaps, events, serviceaccounts | create, delete, get, list, patch, update, watch |
| training-operator | "" | pods/exec | create |
| training-operator | kubeflow.org | pytorchjobs, tfjobs, mpijobs, mxjobs, xgboostjobs, paddlejobs | create, delete, get, list, patch, update, watch |
| training-operator | kubeflow.org | pytorchjobs/status, tfjobs/status, mpijobs/status, mxjobs/status, xgboostjobs/status, paddlejobs/status | get, patch, update |
| training-operator | kubeflow.org | pytorchjobs/finalizers, tfjobs/finalizers, mpijobs/finalizers, mxjobs/finalizers, xgboostjobs/finalizers, paddlejobs/finalizers | update |
| training-operator | autoscaling | horizontalpodautoscalers | create, delete, get, list, patch, update, watch |
| training-operator | rbac.authorization.k8s.io | roles, rolebindings | create, list, update, watch |
| training-operator | scheduling.volcano.sh | podgroups | create, delete, get, list, patch, update, watch |
| training-operator | scheduling.x-k8s.io | podgroups | create, delete, get, list, patch, update, watch |
| training-edit | kubeflow.org | pytorchjobs, tfjobs, mpijobs, mxjobs, xgboostjobs, paddlejobs | create, delete, get, list, patch, update, watch |
| training-edit | kubeflow.org | pytorchjobs/status, tfjobs/status, mpijobs/status, mxjobs/status, xgboostjobs/status, paddlejobs/status | get |
| training-view | kubeflow.org | pytorchjobs, tfjobs, mpijobs, mxjobs, xgboostjobs, paddlejobs | get, list, watch |
| training-view | kubeflow.org | pytorchjobs/status, tfjobs/status, mpijobs/status, mxjobs/status, xgboostjobs/status, paddlejobs/status | get |

### RBAC - Role Bindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| training-operator | opendatahub | training-operator (ClusterRole) | training-operator |

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| webhook-server-cert | kubernetes.io/tls | TLS certificate for webhook server HTTPS | cert-manager or manual | No |

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| /metrics | GET | None | Service Level | Internal cluster access only via ClusterIP |
| /healthz, /readyz | GET | None | Pod Level | Kubelet access for health probes |
| Kubernetes API | ALL | ServiceAccount Token (JWT) | API Server | RBAC policies enforce least privilege access |
| Webhook Server | POST | mTLS | API Server | API server validates operator certificate |

## Data Flows

### Flow 1: Training Job Creation

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User/SDK | Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | User credentials or ServiceAccount token |
| 2 | Kubernetes API Server | training-operator | N/A | Watch/List | TLS 1.2+ | ServiceAccount token (watch events) |
| 3 | training-operator | Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount token |
| 4 | training-operator | Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount token (create pods/services) |

### Flow 2: Metrics Collection

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Prometheus | training-operator Service | 8080/TCP | HTTP | None | None |
| 2 | Prometheus | training-operator Pod | 8080/TCP | HTTP | None | None (internal scrape) |

### Flow 3: Gang Scheduling (Optional)

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | training-operator | Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount token (create PodGroup) |
| 2 | Volcano/Scheduler | Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount token (watch PodGroups) |
| 3 | Volcano/Scheduler | Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount token (schedule pods atomically) |

### Flow 4: PyTorch Elastic Training with HPA

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | training-operator | Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount token (create HPA) |
| 2 | HPA Controller | Metrics Server | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount token |
| 3 | HPA Controller | Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount token (scale replicas) |
| 4 | training-operator | Training Pods | Varies | Varies | Varies | Training workload manages coordination |

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| Kubernetes API Server | REST API | 6443/TCP | HTTPS | TLS 1.2+ | Watch CRDs, manage pods/services/configmaps |
| Prometheus | HTTP Scrape | 8080/TCP | HTTP | None | Export operator and job metrics |
| Volcano Scheduler | Kubernetes CRD | 6443/TCP | HTTPS | TLS 1.2+ | Gang scheduling via PodGroup resources |
| scheduler-plugins | Kubernetes CRD | 6443/TCP | HTTPS | TLS 1.2+ | Alternative gang scheduling implementation |
| Python SDK | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | Create and manage training jobs programmatically |

## Recent Changes

| Version | Date | Changes |
|---------|------|---------|
| c7d4e1b4 | 2024-07-26 | - PATCH: Update go to 1.21<br>- CARRY: add separate file for RHOAI build and update multarch base image<br>- ODH Image build actions<br>- Disable SFTtrainer e2e test<br>- CARRY: Add RHOAI manifests |
| 20c6ede9 | 2024-05-23 | - CARRY: add separate file for RHOAI build and update multarch base image |
| 158dc977 | 2024-04-08 | - ODH Image build actions |
| b3cc7906 | 2024-04-02 | - CARRY: Add RHOAI manifests |
| 700e8e35 | 2024-03-28 | - CARRY: implement e2e happy path |
| v1.7.0-rc.0 | 2023-07-07 | - Kubernetes v1.27 support<br>- Merge kubeflow/common to training-operator<br>- Implement suspend semantics<br>- Set correct ENV for PyTorchJob to support torchrun<br>- Make scheduler-plugins the default gang scheduler |
| v1.6.0 | 2023-03-21 | - Kubernetes v1.25 support<br>- HPA support for PyTorch Elastic<br>- PaddlePaddle framework support<br>- Create TFJob and PyTorchJob from Function APIs in Python SDK<br>- Adopt coscheduling plugin |

## Deployment Configuration

### RHOAI-Specific Configuration

The training-operator is deployed in RHOAI with the following customizations (from `manifests/rhoai/`):

**Namespace**: `opendatahub`
**Name Prefix**: `kubeflow-`

**Patches Applied**:
1. **manager_config_patch.yaml**: Configures operator-specific settings via ConfigMap
2. **manager_metrics_patch.yaml**: Exposes metrics port (8080) with name "metrics"
3. **manager_delete_metrics_service_patch.yaml**: Removes default metrics service (replaced by PodMonitor)
4. **monitor.yaml**: Adds PodMonitor for Prometheus Operator integration

**ConfigMap**: `rhoai-config` contains deployment parameters including:
- Container image reference: `odh-training-operator-controller-image`

**Labels**:
- `app.kubernetes.io/name: training-operator`
- `app.kubernetes.io/component: controller`

### Container Configuration

**Security Context**:
- `allowPrivilegeEscalation: false`
- Runs as non-root user

**Resource Limits**: Not specified in base manifests (configured at deployment time)

**Probes**:
- Liveness: HTTP GET /healthz:8081 (delay: 15s, period: 20s, timeout: 3s)
- Readiness: HTTP GET /readyz:8081 (delay: 10s, period: 15s, timeout: 3s)

**Replicas**: 1 (single-replica deployment with leader election support)

**Istio Integration**: Sidecar injection disabled (`sidecar.istio.io/inject: "false"`)

## Operational Notes

### Leader Election
The operator supports leader election (disabled by default) with configurable leader election ID (`1ca428e5.training-operator.kubeflow.org`). This enables high availability when running multiple replicas.

### Gang Scheduling
Gang scheduling ensures all pods in a training job are scheduled atomically, preventing deadlocks in resource-constrained clusters. Two implementations are supported:
- **Volcano**: Uses `scheduling.volcano.sh/v1beta1` PodGroup API
- **scheduler-plugins**: Uses `scheduling.x-k8s.io/v1alpha1` PodGroup API

### PyTorch Elastic Training
PyTorch jobs support elastic training with Horizontal Pod Autoscaler (HPA) integration, allowing dynamic scaling of worker replicas based on metrics like GPU utilization or custom application metrics.

### Init Containers
- **PyTorch**: Uses configurable init container image (`--pytorch-init-container-image`) for worker coordination
- **MPI**: Uses kubectl delivery image (`--mpi-kubectl-delivery-image`) for launcher initialization

### Monitoring
The operator exports Prometheus metrics including:
- Job creation/completion/failure counts
- Reconciliation duration
- Controller queue depth
- Per-framework job statistics

### Python SDK
The Python SDK (`kubeflow-training`) provides a unified `TrainingClient` API for managing all job types, supporting both direct Kubernetes resource manipulation and function-based job creation from Python training code.
