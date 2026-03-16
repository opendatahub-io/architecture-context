# Component: Kubeflow Training Operator

## Metadata
- **Repository**: https://github.com/red-hat-data-services/training-operator
- **Version**: f43318d8 (branch: rhoai-2.13)
- **Distribution**: RHOAI
- **Languages**: Go, Python (SDK)
- **Deployment Type**: Kubernetes Operator

## Purpose
**Short**: Kubernetes operator for distributed training of machine learning models across multiple frameworks (PyTorch, TensorFlow, XGBoost, MPI, MXNet, PaddlePaddle).

**Detailed**: The Kubeflow Training Operator is a Kubernetes-native operator that enables scalable distributed training of machine learning models. It provides Custom Resource Definitions (CRDs) for defining training jobs using popular ML frameworks including PyTorch, TensorFlow, XGBoost, MPI, MXNet, and PaddlePaddle. The operator manages the lifecycle of distributed training jobs, including pod orchestration, service creation for inter-worker communication, and job status tracking.

The operator reconciles training job CRDs and creates the necessary Kubernetes resources (pods, services, configmaps) to execute distributed training workloads. It supports advanced features like elastic training for PyTorch, gang scheduling integration with Volcano or scheduler-plugins, and horizontal pod autoscaling. Users can interact with the operator either through Kubernetes CRDs directly or via the Python SDK which provides a higher-level interface for job creation and management.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| training-operator | Go Controller | Main operator that reconciles training job CRDs and manages training workloads |
| Python SDK | Python Library | High-level API for creating and managing training jobs from Python code |
| PyTorch Controller | Reconciler | Manages PyTorchJob resources and orchestrates distributed PyTorch training |
| TensorFlow Controller | Reconciler | Manages TFJob resources and orchestrates distributed TensorFlow training |
| MPI Controller | Reconciler | Manages MPIJob resources for MPI-based distributed training |
| XGBoost Controller | Reconciler | Manages XGBoostJob resources for distributed XGBoost training |
| MXNet Controller | Reconciler | Manages MXNetJob resources for distributed MXNet training |
| PaddlePaddle Controller | Reconciler | Manages PaddleJob resources for distributed PaddlePaddle training |
| kubectl-delivery Init Container | Init Container | Delivers kubectl binary to MPI launcher pods |
| PyTorch Init Container | Init Container | Sets up PyTorch distributed training environment |

## APIs Exposed

### Custom Resource Definitions (CRDs)

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| kubeflow.org | v1 | PyTorchJob | Namespaced | Define distributed PyTorch training jobs with master/worker topology |
| kubeflow.org | v1 | TFJob | Namespaced | Define distributed TensorFlow training jobs with parameter server/worker topology |
| kubeflow.org | v1 | MPIJob | Namespaced | Define MPI-based distributed training jobs with launcher/worker topology |
| kubeflow.org | v1 | XGBoostJob | Namespaced | Define distributed XGBoost training jobs with master/worker topology |
| kubeflow.org | v1 | MXJob | Namespaced | Define distributed MXNet training jobs with scheduler/server/worker topology |
| kubeflow.org | v1 | PaddleJob | Namespaced | Define distributed PaddlePaddle training jobs with master/worker topology |

### HTTP Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /metrics | GET | 8080/TCP | HTTP | None | None | Prometheus metrics endpoint for operator telemetry |
| /healthz | GET | 8081/TCP | HTTP | None | None | Liveness probe endpoint |
| /readyz | GET | 8081/TCP | HTTP | None | None | Readiness probe endpoint |

### gRPC Services

No gRPC services exposed by the operator itself. Training jobs may use gRPC for inter-worker communication.

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| Kubernetes | 1.25+ | Yes | Container orchestration platform for running training jobs |
| Prometheus | Any | No | Metrics collection and monitoring (via PodMonitor) |
| Volcano | Any | No | Gang scheduling for coordinated pod scheduling |
| scheduler-plugins | Any | No | Alternative gang scheduling implementation |
| kubectl | Any | No | Used by MPI launcher pods for worker orchestration |

### Internal ODH Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| Prometheus | Metrics scraping | Operator exposes metrics on port 8080 for monitoring |
| None | - | Operator is self-contained, training jobs may depend on other components |

## Network Architecture

### Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| training-operator | ClusterIP | 8080/TCP | 8080 | HTTP | None | None | Internal |
| <job-name>-master-0 | ClusterIP | 23456/TCP (PyTorch) | 23456 | TCP | None | None | Internal (per PyTorchJob) |
| <job-name>-worker-* | ClusterIP | 23456/TCP (PyTorch) | 23456 | TCP | None | None | Internal (per PyTorchJob) |

Note: Training jobs create ephemeral services for inter-worker communication. Port numbers vary by framework (PyTorch default: 23456).

### Ingress

No ingress resources defined. Operator is internal only.

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| Kubernetes API | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token | Watch CRDs, create/update pods, services, configmaps |
| Container Registries | 443/TCP | HTTPS | TLS 1.2+ | Pull Secrets | Pull training container images |
| Object Storage (S3/etc) | 443/TCP | HTTPS | TLS 1.2+ | Varies | Training jobs may access datasets (job-dependent) |

## Security

### RBAC - Cluster Roles

| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|
| training-operator | "" | configmaps | create, list, update, watch |
| training-operator | "" | events | create, delete, get, list, patch, update, watch |
| training-operator | "" | pods | create, delete, get, list, patch, update, watch |
| training-operator | "" | pods/exec | create |
| training-operator | "" | serviceaccounts | create, get, list, watch |
| training-operator | "" | services | create, delete, get, list, watch |
| training-operator | autoscaling | horizontalpodautoscalers | create, delete, get, list, patch, update, watch |
| training-operator | kubeflow.org | mpijobs, mpijobs/status, mpijobs/finalizers | * |
| training-operator | kubeflow.org | mxjobs, mxjobs/status, mxjobs/finalizers | * |
| training-operator | kubeflow.org | paddlejobs, paddlejobs/status, paddlejobs/finalizers | * |
| training-operator | kubeflow.org | pytorchjobs, pytorchjobs/status, pytorchjobs/finalizers | * |
| training-operator | kubeflow.org | tfjobs, tfjobs/status, tfjobs/finalizers | * |
| training-operator | kubeflow.org | xgboostjobs, xgboostjobs/status, xgboostjobs/finalizers | * |
| training-operator | rbac.authorization.k8s.io | roles, rolebindings | create, list, update, watch |
| training-operator | scheduling.volcano.sh | podgroups | create, delete, get, list, patch, update, watch |
| training-operator | scheduling.x-k8s.io | podgroups | create, delete, get, list, patch, update, watch |
| training-edit | kubeflow.org | mpijobs, tfjobs, pytorchjobs, mxjobs, xgboostjobs, paddlejobs | create, delete, get, list, patch, update, watch |
| training-edit | kubeflow.org | mpijobs/status, tfjobs/status, pytorchjobs/status, mxjobs/status, xgboostjobs/status, paddlejobs/status | get |
| training-view | kubeflow.org | mpijobs, tfjobs, pytorchjobs, mxjobs, xgboostjobs, paddlejobs | get, list, watch |
| training-view | kubeflow.org | mpijobs/status, tfjobs/status, pytorchjobs/status, mxjobs/status, xgboostjobs/status, paddlejobs/status | get |

### RBAC - Role Bindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| training-operator | opendatahub (via kustomize) | ClusterRole: training-operator | training-operator |

### Secrets

No secrets directly managed by the operator. Training jobs may reference secrets for image pull or data access.

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| /metrics | GET | None | None | Open for Prometheus scraping |
| /healthz | GET | None | None | Open for kubelet health checks |
| /readyz | GET | None | None | Open for kubelet readiness checks |
| Kubernetes API | * | ServiceAccount Token | kube-apiserver | RBAC (ClusterRole: training-operator) |

## Data Flows

### Flow 1: Training Job Creation and Reconciliation

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User/Client | Kubernetes API | 443/TCP | HTTPS | TLS 1.2+ | User credentials |
| 2 | Kubernetes API | training-operator | Watch | Informer | In-cluster | ServiceAccount Token |
| 3 | training-operator | Kubernetes API | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 4 | training-operator | Kubernetes API (create pods) | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 5 | training-operator | Kubernetes API (create services) | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 6 | training-operator | Kubernetes API (update status) | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |

### Flow 2: Distributed Training Communication (PyTorch Example)

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Worker Pods | Master Pod | 23456/TCP | TCP | None (framework-dependent) | None |
| 2 | Master Pod | Worker Pods | 23456/TCP | TCP | None (framework-dependent) | None |
| 3 | All Pods | External Storage | 443/TCP | HTTPS | TLS 1.2+ | Job credentials |

### Flow 3: Metrics Collection

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Prometheus | training-operator | 8080/TCP | HTTP | None | None |

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| Kubernetes API | REST API | 443/TCP | HTTPS | TLS 1.2+ | CRD watching, resource management |
| Prometheus | Metrics scraping | 8080/TCP | HTTP | None | Operator monitoring via PodMonitor |
| Volcano Scheduler | API (PodGroups) | 443/TCP | HTTPS | TLS 1.2+ | Gang scheduling coordination (optional) |
| Scheduler Plugins | API (PodGroups) | 443/TCP | HTTPS | TLS 1.2+ | Gang scheduling coordination (optional) |

## Recent Changes

Note: No recent commits in the last 3 months (branch rhoai-2.13 is a stable release branch).

| Version | Date | Changes |
|---------|------|---------|
| f43318d8 | N/A | RHOAI 2.13 release branch - stable snapshot |
| v1.7.0 | 2023 | - Python SDK version 1.7.0<br>- Kubernetes 1.25+ support<br>- Multiple framework support (PyTorch, TensorFlow, XGBoost, MPI, MXNet, PaddlePaddle) |

## Build Configuration

### Container Images

| Image | Purpose | Build Method | Base Image |
|-------|---------|--------------|------------|
| odh-training-operator | Main operator | Konflux (Dockerfile.konflux) | registry.redhat.io/ubi8/ubi-minimal |
| kubectl-delivery | MPI launcher init | Dockerfile | N/A |

### Build Details

- **Primary Build**: `build/images/training-operator/Dockerfile.konflux`
- **Build System**: Konflux (RHOAI standard)
- **Go Version**: 1.21
- **FIPS Mode**: Enabled (strictfipsruntime tag)
- **User**: Non-root (UID 65532)
- **Entrypoint**: `/manager`

## Deployment Configuration

### Kustomize Structure

- **Base**: `manifests/base/` - Core operator resources (deployment, service, CRDs, RBAC)
- **RHOAI Overlay**: `manifests/rhoai/` - RHOAI-specific configuration
  - Namespace: `opendatahub`
  - Name Prefix: `kubeflow-`
  - Includes PodMonitor for Prometheus integration
  - Metrics port configuration
  - RBAC roles for user access (training-edit, training-view)

### Operator Configuration

| Parameter | Default | Purpose |
|-----------|---------|---------|
| metrics-bind-address | :8080 | Metrics endpoint port |
| health-probe-bind-address | :8081 | Health/readiness probe port |
| leader-elect | false | Leader election (single replica) |
| enable-scheme | all | Enabled job types (tfjob, pytorchjob, etc) |
| gang-scheduler-name | "" | Optional gang scheduler (volcano or scheduler-plugins) |
| namespace | cluster-wide | Namespace scope (default: all namespaces) |
| webhook-server-port | 9443 | Webhook server port (not currently used) |
| controller-threads | 1 | Reconciliation worker threads |

## Monitoring and Observability

### Metrics

- **Endpoint**: `:8080/metrics`
- **Format**: Prometheus
- **Collection**: PodMonitor resource (monitoring.coreos.com/v1)
- **Labels**:
  - `app.kubernetes.io/name: training-operator`
  - `app.kubernetes.io/component: controller`

### Health Checks

- **Liveness**: `GET :8081/healthz` (15s delay, 20s period)
- **Readiness**: `GET :8081/readyz` (10s delay, 15s period)

## Python SDK

### Installation

```bash
pip install kubeflow-training==1.7.0
```

### Key Features

- TrainingClient API for job management
- Support for all 6 training job types
- Kubernetes-native resource management
- HuggingFace integration (transformers, peft)

### Dependencies

- kubernetes>=23.6.0
- retrying>=1.3.3
- certifi>=14.05.14

## Training Job Workflows

### PyTorchJob Example

1. User creates PyTorchJob CRD with master and worker replica specifications
2. Operator watches PyTorchJob resources via informers
3. Operator creates master pod(s) and worker pod(s)
4. Operator creates services for inter-pod communication (port 23456)
5. PyTorch init container sets up distributed environment variables
6. Training pods communicate using PyTorch distributed primitives
7. Operator monitors pod status and updates job status conditions
8. On completion, operator updates job status (Succeeded/Failed)

### MPIJob Example

1. User creates MPIJob CRD with launcher and worker specifications
2. Operator creates worker pods first
3. Operator creates launcher pod with kubectl-delivery init container
4. Init container delivers kubectl binary to launcher
5. Launcher uses kubectl to orchestrate MPI training on workers
6. MPI communication happens via SSH or other MPI transport
7. Operator monitors launcher pod and updates job status

## Gang Scheduling

### Volcano Integration

- Creates PodGroup resources (scheduling.volcano.sh/v1beta1)
- Coordinates with Volcano scheduler for all-or-nothing pod scheduling
- Prevents resource deadlocks in multi-tenant clusters

### Scheduler Plugins Integration

- Creates PodGroup resources (scheduling.x-k8s.io/v1alpha1)
- Alternative gang scheduling implementation
- Compatible with Kubernetes scheduler framework

## Security Considerations

1. **Non-root Execution**: Operator runs as UID 65532 (non-root)
2. **FIPS Compliance**: Built with strictfipsruntime tag for FIPS 140-2 compliance
3. **Service Account Isolation**: Uses dedicated service account with least-privilege RBAC
4. **No Privilege Escalation**: `allowPrivilegeEscalation: false` in deployment
5. **Istio Compatibility**: `sidecar.istio.io/inject: "false"` - no sidecar injection (operator doesn't need service mesh)
6. **Cluster Scope**: Requires cluster-scoped permissions for cross-namespace job management

## Known Limitations

1. **Network Encryption**: Inter-worker communication is not encrypted by default (framework-dependent)
2. **Authentication**: Training pods do not enforce authentication between workers (framework-dependent)
3. **Single Replica**: Operator runs as single replica (leader election disabled)
4. **Metrics Encryption**: Metrics endpoint is HTTP, not HTTPS
5. **Webhook Disabled**: Webhook server port configured but webhooks not active in current deployment

## Future Enhancements

Based on code structure and configurations:

1. **Webhook Integration**: Port 9443 configured for future admission webhooks
2. **Multi-namespace Support**: Flag exists to limit operator to specific namespace
3. **Controller Scaling**: Thread count configurable for higher throughput
4. **HPA Support**: Operator has permissions for HorizontalPodAutoscaler management
5. **Enhanced Observability**: Framework for metrics is in place for additional metrics
