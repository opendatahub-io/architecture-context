# Component: Kubeflow Training Operator

## Metadata
- **Repository**: https://github.com/red-hat-data-services/training-operator
- **Version**: 78eedd82 (rhoai-2.10 branch)
- **Distribution**: RHOAI
- **Languages**: Go (operator), Python (SDK)
- **Deployment Type**: Kubernetes Operator

## Purpose
**Short**: Kubernetes-native operator for distributed training of machine learning models across multiple frameworks.

**Detailed**: The Kubeflow Training Operator is a unified Kubernetes operator that orchestrates distributed training workloads for multiple machine learning frameworks including PyTorch, TensorFlow, XGBoost, MPI, MXNet, and PaddlePaddle. It provides Kubernetes Custom Resource Definitions (CRDs) that allow users to define training jobs declaratively, handling pod orchestration, distributed coordination, scaling, and lifecycle management. The operator automatically manages worker pod creation, service discovery, environment variable injection for distributed training, and integrates with gang schedulers (Volcano, scheduler-plugins) for optimized resource allocation. It also provides a Python SDK for programmatic job creation and management, making it easier for data scientists to submit training workloads without deep Kubernetes knowledge.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| training-operator controller | Go application | Main reconciliation controller that watches CRDs and manages training job lifecycle |
| PyTorch controller | Sub-controller | Manages PyTorchJob resources including elastic training support |
| TensorFlow controller | Sub-controller | Manages TFJob resources for distributed TensorFlow training |
| MPI controller | Sub-controller | Manages MPIJob resources for MPI-based distributed training |
| XGBoost controller | Sub-controller | Manages XGBoostJob resources for distributed XGBoost training |
| MXNet controller | Sub-controller | Manages MXJob resources for distributed Apache MXNet training |
| PaddlePaddle controller | Sub-controller | Manages PaddleJob resources for PaddlePaddle distributed training |
| Python SDK | Python library | Client library for creating and managing training jobs programmatically |
| Metrics exporter | Prometheus metrics | Exposes operator metrics on port 8080 for monitoring |
| Webhook server | Admission webhooks | Validates and defaults training job specifications (port 9443) |

## APIs Exposed

### Custom Resource Definitions (CRDs)

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| kubeflow.org | v1 | PyTorchJob | Namespaced | Defines distributed PyTorch training jobs with support for elastic training and HPA |
| kubeflow.org | v1 | TFJob | Namespaced | Defines distributed TensorFlow training jobs with parameter server and worker roles |
| kubeflow.org | v1 | MPIJob | Namespaced | Defines MPI-based distributed training jobs with launcher and worker architecture |
| kubeflow.org | v1 | XGBoostJob | Namespaced | Defines distributed XGBoost training jobs with master and worker roles |
| kubeflow.org | v1 | MXJob | Namespaced | Defines distributed Apache MXNet training jobs with scheduler, server, and worker roles |
| kubeflow.org | v1 | PaddleJob | Namespaced | Defines distributed PaddlePaddle training jobs |

### HTTP Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /metrics | GET | 8080/TCP | HTTP | None | None | Prometheus metrics endpoint for operator monitoring |
| /healthz | GET | 8081/TCP | HTTP | None | None | Liveness probe endpoint for operator health |
| /readyz | GET | 8081/TCP | HTTP | None | None | Readiness probe endpoint for operator readiness |

### Webhook Services

| Service | Port | Protocol | Encryption | Auth | Purpose |
|---------|------|----------|------------|------|---------|
| Admission webhook | 9443/TCP | HTTPS | TLS | Kubernetes API | Validates and sets defaults for training job CRDs |

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| Kubernetes | 1.25+ | Yes | Container orchestration platform |
| controller-runtime | v0.14.0+ | Yes | Kubernetes controller framework |
| Prometheus Operator | Any | No | Metrics collection via PodMonitor |
| Volcano | v1beta1 | No | Optional gang scheduler for co-scheduling training pods |
| scheduler-plugins | v0.25.7+ | No | Optional gang scheduler (default) for co-scheduling training pods |
| Istio | Any | No | Service mesh (operator disables injection on its own pods) |

### Internal ODH Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| OpenDataHub Dashboard | UI Integration | Displays training jobs in ODH dashboard |
| Prometheus | Metrics scraping | Collects operator metrics via PodMonitor |
| Service Mesh | Network policy | Training pods may use mesh for communication |

## Network Architecture

### Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| training-operator | ClusterIP | 8080/TCP | 8080 | HTTP | None | None | Internal |

### Ingress

| Name | Type | Hosts | Port | Protocol | Encryption | TLS Mode | Exposure |
|------|------|-------|------|----------|----------|----------|----------|
| N/A | N/A | N/A | N/A | N/A | N/A | N/A | Operator has no external ingress |

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount token | Watch CRDs, manage pods, services |
| Container registries | 443/TCP | HTTPS | TLS 1.2+ | Image pull secrets | Pull training container images |
| Volcano API | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount token | Manage PodGroups for gang scheduling (optional) |

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
| training-operator | kubeflow.org | pytorchjobs, pytorchjobs/status, pytorchjobs/finalizers | create, delete, get, list, patch, update, watch |
| training-operator | kubeflow.org | tfjobs, tfjobs/status, tfjobs/finalizers | create, delete, get, list, patch, update, watch |
| training-operator | kubeflow.org | mpijobs, mpijobs/status, mpijobs/finalizers | create, delete, get, list, patch, update, watch |
| training-operator | kubeflow.org | xgboostjobs, xgboostjobs/status, xgboostjobs/finalizers | create, delete, get, list, patch, update, watch |
| training-operator | kubeflow.org | mxjobs, mxjobs/status, mxjobs/finalizers | create, delete, get, list, patch, update, watch |
| training-operator | kubeflow.org | paddlejobs, paddlejobs/status, paddlejobs/finalizers | create, delete, get, list, patch, update, watch |
| training-operator | rbac.authorization.k8s.io | roles, rolebindings | create, list, update, watch |
| training-operator | scheduling.volcano.sh | podgroups | create, delete, get, list, patch, update, watch |
| training-operator | scheduling.x-k8s.io | podgroups | create, delete, get, list, patch, update, watch |
| training-edit | kubeflow.org | all training job CRDs | create, delete, get, list, patch, update, watch |
| training-view | kubeflow.org | all training job CRDs | get, list, watch |

### RBAC - Role Bindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| training-operator | opendatahub | training-operator | training-operator |

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| webhook-server-cert | kubernetes.io/tls | TLS certificate for webhook server | cert-manager or manual | Depends on provisioner |

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| Kubernetes API | ALL | ServiceAccount token (JWT) | Kubernetes API Server | RBAC ClusterRole |
| /metrics | GET | None | Application | Cluster-internal only via ClusterIP |
| /healthz, /readyz | GET | None | Application | Cluster-internal health checks |
| Webhook server | POST | Kubernetes API auth | Kubernetes API Server | Authenticated webhook calls |

## Data Flows

### Flow 1: PyTorchJob Submission and Execution

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User/SDK | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | kubeconfig credentials |
| 2 | Kubernetes API | training-operator | Watch | HTTPS | TLS 1.2+ | ServiceAccount token |
| 3 | training-operator | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount token |
| 4 | Kubernetes API | kubelet | 10250/TCP | HTTPS | TLS 1.2+ | Node auth |
| 5 | Worker pods | Worker pods | Framework-specific | TCP/gRPC | Varies | Framework-specific |

### Flow 2: Metrics Collection

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Prometheus | training-operator service | 8080/TCP | HTTP | None | None |
| 2 | Prometheus | training-operator pod | 8080/TCP | HTTP | None | None |

### Flow 3: Gang Scheduling with Volcano/scheduler-plugins

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | training-operator | Kubernetes API (PodGroup) | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount token |
| 2 | Scheduler | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount token |
| 3 | Scheduler | kubelet | 10250/TCP | HTTPS | TLS 1.2+ | Node auth |

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| Kubernetes API Server | REST API | 6443/TCP | HTTPS | TLS 1.2+ | CRD watching, pod/service management |
| Prometheus | Metrics scraping | 8080/TCP | HTTP | None | Operator health and performance monitoring |
| Volcano Scheduler | CRD (PodGroup) | 6443/TCP | HTTPS | TLS 1.2+ | Gang scheduling for co-located training pods |
| scheduler-plugins | CRD (PodGroup) | 6443/TCP | HTTPS | TLS 1.2+ | Gang scheduling (default option) |
| Container Registry | Image pull | 443/TCP | HTTPS | TLS 1.2+ | Pull training workload images |
| ODH Dashboard | REST API | 80/443 | HTTP/HTTPS | Varies | Display and manage training jobs via UI |

## Deployment Configuration

### Container Images

| Image | Purpose | Build Source |
|-------|---------|--------------|
| training-operator | Main operator controller | build/images/training-operator/Dockerfile.rhoai |
| kubectl-delivery | MPI launcher init container | build/images/kubectl-delivery/Dockerfile |

### Environment Variables

| Variable | Default | Purpose |
|----------|---------|---------|
| MY_POD_NAMESPACE | metadata.namespace | Operator pod namespace for leader election |
| MY_POD_NAME | metadata.name | Operator pod name for identification |
| KUBEFLOW_NAMESPACE | (optional) | Limit operator to specific namespace |

### Configuration Flags

| Flag | Default | Purpose |
|------|---------|---------|
| --metrics-bind-address | :8080 | Metrics endpoint address |
| --health-probe-bind-address | :8081 | Health probe endpoint address |
| --leader-elect | false | Enable leader election |
| --enable-scheme | all | Enable specific job types (tfjob, pytorchjob, etc.) |
| --gang-scheduler-name | scheduler-plugins | Gang scheduler to use (volcano, scheduler-plugins) |
| --namespace | "" | Namespace to monitor (empty = all) |
| --webhook-server-port | 9443 | Webhook server port |
| --controller-threads | 1 | Number of worker threads per controller |

## Monitoring

### Metrics Exposed

| Metric Name | Type | Purpose |
|-------------|------|---------|
| controller_runtime_* | Various | Controller runtime metrics (reconciliation, queue depth) |
| workqueue_* | Various | Work queue metrics (adds, retries, depth) |
| rest_client_* | Various | Kubernetes API client metrics |

### Health Checks

| Endpoint | Port | Type | Purpose |
|----------|------|------|---------|
| /healthz | 8081 | Liveness | Indicates if operator is alive |
| /readyz | 8081 | Readiness | Indicates if operator is ready to serve |

### Observability

| Type | Implementation | Purpose |
|------|----------------|---------|
| Metrics | Prometheus PodMonitor | Scrapes metrics from controller pods |
| Logging | Structured logging (zap) | Operator logs for debugging |
| Events | Kubernetes Events | Job lifecycle events for user visibility |

## Recent Changes

Based on CHANGELOG.md (v1.7.0-rc.0 and v1.6.0):

| Version | Date | Changes |
|---------|------|---------|
| v1.7.0-rc.0 | 2023-07-07 | - Upgraded to Kubernetes 1.27 dependencies<br>- Made scheduler-plugins the default gang scheduler (v0.25.7)<br>- Merged kubeflow/common into training-operator<br>- Implemented suspend semantics for jobs<br>- Set correct ENV for PyTorchJob to support torchrun<br>- Auto-generate RBAC manifests with controller-gen |
| v1.6.0 | 2023-03-21 | - Added Kubernetes 1.25 support<br>- Implemented HPA support for PyTorch Elastic<br>- Added PaddlePaddle framework support<br>- Adopted coscheduling plugin for gang scheduling<br>- Created unified Training Client SDK<br>- Added support for creating jobs from Python function APIs<br>- Fixed infinite loop in init-pytorch container<br>- Fixed XGBoost and MXNet status update bugs |

## Key Features

### Distributed Training Support
- **PyTorch**: Supports standard distributed training and elastic training with HPA integration
- **TensorFlow**: Supports parameter server and worker roles for distributed training
- **MPI**: Launcher/worker architecture for MPI-based frameworks (Horovod, DeepSpeed)
- **XGBoost**: Master/worker distributed training
- **MXNet**: Scheduler/server/worker architecture
- **PaddlePaddle**: Full distributed training support

### Gang Scheduling
- Integrates with Volcano and scheduler-plugins for gang scheduling
- Creates PodGroups to ensure all training pods are scheduled together
- Prevents resource deadlocks in multi-tenant clusters
- Default: scheduler-plugins (v0.25.7+)

### Elastic Training
- PyTorchJob supports elastic training with dynamic scaling
- Integrates with HorizontalPodAutoscaler for automatic scaling
- Supports min/max replicas and metrics-based scaling

### Job Lifecycle Management
- Suspend/resume semantics for pausing training
- Configurable restart policies (OnFailure, Never, Always, ExitCode)
- Clean pod policies (None, Running, All)
- Job status tracking with conditions
- Event generation for visibility

### Python SDK Features
- Unified TrainingClient for all job types
- Create jobs from Python functions
- List, get, delete, and monitor jobs
- Get job logs programmatically
- Works with and without kube config

## Security Considerations

1. **Pod Security**: Operator runs as non-root user (65532:65532)
2. **No Privilege Escalation**: securityContext prevents privilege escalation
3. **Istio Sidecar Injection**: Disabled on operator pods (`sidecar.istio.io/inject: "false"`)
4. **RBAC**: Fine-grained permissions via ClusterRole
5. **Service Account**: Dedicated service account per namespace
6. **Webhook TLS**: Admission webhooks require TLS certificates
7. **FIPS Compliance**: RHOAI build uses `-tags strictfipsruntime` for FIPS mode

## Known Limitations

1. **Namespace Scope**: While operator can watch all namespaces, it can be limited to single namespace
2. **Gang Scheduler**: scheduler-plugins v0.24.x and lower not supported in v1.7+
3. **Backwards Compatibility**: SDK v1.6+ requires operator v1.6.0+
4. **Leader Election**: Single active controller (default: disabled, can be enabled)

## Production Considerations

1. **Leader Election**: Enable for high availability in production
2. **Gang Scheduler**: Required for multi-tenant environments to prevent deadlocks
3. **Monitoring**: Configure PodMonitor for Prometheus metrics collection
4. **Resource Limits**: Set appropriate limits on operator and training pods
5. **Namespace Isolation**: Consider running operator per namespace for isolation
6. **Image Caching**: Pre-pull training images to reduce startup time
7. **Persistent Storage**: Training pods typically need PVCs for datasets and checkpoints
