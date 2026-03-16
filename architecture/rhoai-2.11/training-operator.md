# Component: Kubeflow Training Operator

## Metadata
- **Repository**: https://github.com/red-hat-data-services/training-operator.git
- **Version**: 20c6ede9 (rhoai-2.11 branch)
- **Distribution**: RHOAI (Red Hat OpenShift AI)
- **Languages**: Go (1.20.10)
- **Deployment Type**: Kubernetes Operator

## Purpose
**Short**: Kubernetes-native operator for distributed machine learning model training across multiple frameworks.

**Detailed**: The Kubeflow Training Operator is a unified Kubernetes controller that enables scalable distributed training of machine learning models using popular frameworks including PyTorch, TensorFlow, XGBoost, MPI, Apache MXNet, and PaddlePaddle. It provides Kubernetes Custom Resources for each framework type, abstracting the complexity of distributed training configuration and orchestration. The operator manages the lifecycle of training jobs, including pod creation, service discovery, resource allocation, gang scheduling integration, and status tracking. Users can submit training jobs via custom resources or the Python SDK, and the operator handles pod-to-pod communication setup, failure recovery, and integration with Kubernetes HPA for elastic training workloads.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| training-operator | Kubernetes Deployment | Main operator controller managing all training job types |
| PyTorch Controller | Go Controller | Reconciles PyTorchJob custom resources, manages distributed PyTorch training |
| TensorFlow Controller | Go Controller | Reconciles TFJob custom resources, manages TensorFlow distributed training |
| MPI Controller | Go Controller | Reconciles MPIJob custom resources, manages MPI-based training |
| XGBoost Controller | Go Controller | Reconciles XGBoostJob custom resources, manages XGBoost distributed training |
| MXNet Controller | Go Controller | Reconciles MXNetJob custom resources, manages Apache MXNet training |
| Paddle Controller | Go Controller | Reconciles PaddleJob custom resources, manages PaddlePaddle training |
| Metrics Server | HTTP Endpoint | Exposes Prometheus metrics on port 8080 |
| Health Probes | HTTP Endpoints | Liveness and readiness checks on port 8081 |

## APIs Exposed

### Custom Resource Definitions (CRDs)

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| kubeflow.org | v1 | PyTorchJob | Namespaced | Define distributed PyTorch training jobs with master/worker topology |
| kubeflow.org | v1 | TFJob | Namespaced | Define TensorFlow distributed training jobs with PS/Chief/Worker roles |
| kubeflow.org | v1 | MPIJob | Namespaced | Define MPI-based distributed training jobs (launcher/worker pattern) |
| kubeflow.org | v1 | XGBoostJob | Namespaced | Define XGBoost distributed training jobs |
| kubeflow.org | v1 | MXJob | Namespaced | Define Apache MXNet distributed training jobs |
| kubeflow.org | v1 | PaddleJob | Namespaced | Define PaddlePaddle distributed training jobs |

### HTTP Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /metrics | GET | 8080/TCP | HTTP | None | None | Expose Prometheus metrics for monitoring |
| /healthz | GET | 8081/TCP | HTTP | None | None | Liveness probe endpoint |
| /readyz | GET | 8081/TCP | HTTP | None | None | Readiness probe endpoint |

### gRPC Services

No gRPC services exposed.

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| Kubernetes | 1.25+ | Yes | Cluster platform for running operator and training jobs |
| Prometheus | Any | No | Metrics collection and monitoring |
| Volcano Scheduler | v1beta1 | No | Optional gang scheduling for training jobs |
| Scheduler Plugins | v1alpha1 | No | Optional coscheduling plugin for gang scheduling |
| controller-runtime | v0.14.0 | Yes | Kubernetes controller framework |

### Internal ODH Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| opendatahub-operator | Deployment | Deployed and managed by ODH operator |
| Prometheus (ODH) | PodMonitor | Metrics scraping via PodMonitor CRD |

## Network Architecture

### Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| training-operator | ClusterIP | 8080/TCP | 8080 | HTTP | None | None | Internal |

### Ingress

No ingress resources configured. The operator is an internal cluster component.

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| Kubernetes API | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token | Watch and manage custom resources, pods, services |
| Container Registry | 443/TCP | HTTPS | TLS 1.2+ | Pull Secrets | Pull training job container images |

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
| training-edit | kubeflow.org | all training jobs | create, delete, get, list, patch, update, watch |
| training-view | kubeflow.org | all training jobs | get, list, watch |

### RBAC - Role Bindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| training-operator | opendatahub | ClusterRole/training-operator | training-operator |

### Secrets

No secrets directly managed by the operator. Training jobs may reference user-provided secrets for:
- Image pull credentials
- Training data access credentials
- Model storage credentials

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| User-defined | kubernetes.io/dockerconfigjson | Pull container images for training jobs | User | No |
| User-defined | Opaque | Access training data from object storage | User | No |

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| /metrics | GET | None (internal only) | Network policies (if configured) | Internal cluster access only |
| /healthz | GET | None | Kubernetes | Liveness probe |
| /readyz | GET | None | Kubernetes | Readiness probe |
| Kubernetes API | ALL | ServiceAccount Token (JWT) | Kubernetes API Server | RBAC via training-operator ClusterRole |

## Data Flows

### Flow 1: Training Job Submission

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User/SDK | Kubernetes API | 443/TCP | HTTPS | TLS 1.2+ | User credentials |
| 2 | Kubernetes API | training-operator | N/A | Watch API | TLS 1.2+ | ServiceAccount Token |
| 3 | training-operator | Kubernetes API | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 4 | Kubernetes | Container Registry | 443/TCP | HTTPS | TLS 1.2+ | Pull Secrets |

### Flow 2: Training Job Execution (PyTorch Example)

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | training-operator | Kubernetes API | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 2 | Master Pod | Worker Pods | 23456/TCP | TCP | None | None |
| 3 | Worker Pods | Master Pod | 23456/TCP | TCP | None | None |

### Flow 3: Metrics Collection

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Prometheus | training-operator | 8080/TCP | HTTP | None | None |

### Flow 4: Gang Scheduling Integration

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | training-operator | Kubernetes API | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 2 | training-operator | Volcano/Scheduler Plugins | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| Kubernetes API Server | REST API | 443/TCP | HTTPS | TLS 1.2+ | Watch CRDs, manage pods/services/configmaps |
| Prometheus | HTTP Pull | 8080/TCP | HTTP | None | Scrape operator metrics |
| Volcano Scheduler | Kubernetes API (PodGroup) | 443/TCP | HTTPS | TLS 1.2+ | Gang scheduling coordination |
| Scheduler Plugins | Kubernetes API (PodGroup) | 443/TCP | HTTPS | TLS 1.2+ | Coscheduling for training jobs |
| Container Registry | HTTPS Pull | 443/TCP | HTTPS | TLS 1.2+ | Pull training job images |
| Horizontal Pod Autoscaler | Kubernetes API | 443/TCP | HTTPS | TLS 1.2+ | Elastic PyTorch training scaling |

## Recent Changes

Based on the rhoai-2.11 branch (commit 20c6ede9):

| Commit | Date | Changes |
|--------|------|---------|
| 20c6ede9 | Recent | - CARRY: Add separate file for RHOAI build and update multarch base image |
| 158dc977 | Recent | - ODH Image build actions |
| 88b5c82d | Recent | - Disable SFTtrainer e2e test |
| b3cc7906 | Recent | - CARRY: Add RHOAI manifests |
| 700e8e35 | Recent | - CARRY: Implement e2e happy path |
| a08246d3 | Upstream | - Remove Dockerfile.ppc64le of pytorch example |
| 21f25ce8 | Upstream | - Upgrade PyTorchJob examples to PyTorch v2 |
| fb35949c | Upstream | - Support K8s v1.29 and Drop K8s v1.26 |
| bba9af4d | Upstream | - Support K8s v1.28 and Drop K8s v1.25 |
| 2eff94ea | Upstream | - Bump google.golang.org/protobuf from 1.30.0 to 1.33.0 in /hack/swagger |
| bf41a680 | Upstream | - Bump google.golang.org/protobuf from 1.30.0 to 1.33.0 |
| ee05bdee | Upstream | - Bump black from 21.12b0 to 24.3.0 in /sdk/python |
| b7e0dbc0 | Upstream | - Upgrade controller-gen to v0.14.0 |
| bb8bba00 | Upstream | - Modify LLM Trainer to support BERT and Tiny LLaMA |
| 8433edcf | Upstream | - Support arm64 for Hugging Face trainer |
| 395e8cab | Upstream | - Add Fine-Tune BERT LLM Example |
| 14eeaeb0 | Upstream | - Fix build workflow config for pytorch-torchrun-example |
| 6133600b | Upstream | - Publish torchrun example via Dockerfile |
| 57aa34d5 | Upstream | - Fix Distributed Data Samplers in PyTorch Examples |
| 5b2c6c89 | Upstream | - Fix URL in python SDK setup.py |

## Key Features

### 1. Multi-Framework Support
The operator provides unified management for six ML frameworks:
- **PyTorch**: Distributed training with torchrun/elastic support, HPA integration
- **TensorFlow**: Parameter Server and distributed strategy support
- **MPI**: OpenMPI and Intel MPI for HPC-style training
- **XGBoost**: Distributed gradient boosting
- **Apache MXNet**: Distributed deep learning
- **PaddlePaddle**: Baidu's deep learning framework

### 2. Gang Scheduling Integration
Supports two gang scheduling implementations:
- **Volcano Scheduler**: Creates PodGroups for all-or-nothing scheduling
- **Scheduler Plugins**: Coscheduling plugin for coordinated pod scheduling

### 3. Elastic Training
PyTorchJob supports elastic training with:
- Dynamic worker scaling via HPA
- Automatic checkpoint/restart on scale events
- Min/max replica configuration

### 4. Python SDK
Provides programmatic job creation and management:
- TrainingClient for unified API across job types
- Function-based job creation from Python code
- Job monitoring and log retrieval

### 5. Lifecycle Management
- Pod creation and cleanup policies
- Service discovery for distributed communication
- Status tracking and event generation
- Finalizer-based cleanup

## Deployment Configuration

### RHOAI-Specific Configuration
The manifests/rhoai directory contains RHOAI-specific overlays:

**Namespace**: opendatahub
**Name Prefix**: kubeflow-
**Replicas**: 1 (leader election enabled)
**Container Security**: allowPrivilegeEscalation: false
**Istio**: Sidecar injection disabled (annotation: sidecar.istio.io/inject: "false")

**Resource Limits**: Not specified in base manifests (can be configured via patches)

**Monitoring**:
- PodMonitor for Prometheus integration
- Metrics exposed on port 8080 at /metrics path
- Prometheus annotations on service

**Health Checks**:
- Liveness: /healthz on port 8081 (15s initial delay, 20s period)
- Readiness: /readyz on port 8081 (10s initial delay, 15s period)

## Configuration Options

The operator supports the following command-line flags:

| Flag | Default | Purpose |
|------|---------|---------|
| --metrics-bind-address | :8080 | Metrics server listening address |
| --health-probe-bind-address | :8081 | Health probe server listening address |
| --leader-elect | false | Enable leader election |
| --enable-scheme | all | Enable specific job types (tfjob, pytorchjob, etc.) |
| --gang-scheduler-name | "" | Gang scheduler integration (volcano or scheduler-plugins) |
| --namespace | all | Limit operator to specific namespace |
| --controller-threads | 1 | Number of worker threads per controller |
| --pytorch-init-container-image | (default) | Image for PyTorch init container |
| --mpi-kubectl-delivery-image | (default) | Image for MPI kubectl delivery container |

## Build Configuration

**RHOAI Build**: Uses Dockerfile.rhoai
- Base image: registry.access.redhat.com/ubi9/go-toolset:1.20.10
- Runtime image: registry.access.redhat.com/ubi9/ubi-minimal:latest
- FIPS mode: Enabled (strictfipsruntime build tag)
- CGO: Enabled for FIPS compliance
- User: 65532:65532 (non-root)

## Training Job Communication Patterns

### PyTorch Jobs
- **Port**: 23456/TCP (default pytorchjob-port)
- **Communication**: Master coordinates with workers via torchrun
- **Elastic**: Supports dynamic worker scaling with rendezvous

### TensorFlow Jobs
- **Parameter Server**: Workers communicate with PS for gradient exchange
- **AllReduce**: Direct worker-to-worker communication
- **Ports**: User-configurable per replica type

### MPI Jobs
- **Launcher/Worker**: Launcher pod executes mpirun to coordinate workers
- **SSH**: Inter-pod SSH communication
- **Init Container**: Sets up SSH keys and hostfiles

### XGBoost Jobs
- **Rabit**: Uses Rabit (Reliable Allreduce and Broadcast Interface)
- **Port**: Configurable tracker service port

## Observability

### Metrics Exposed
The operator exposes Prometheus metrics including:
- Job reconciliation duration
- Job creation/deletion counts
- Job status transitions
- Controller queue depth
- API call latencies

### Events
Kubernetes events generated for:
- Job creation/deletion
- Pod creation/failure
- Status changes (Running, Succeeded, Failed)
- Validation errors

### Logs
Structured logging with configurable log levels:
- Controller reconciliation logs
- Job lifecycle events
- Error conditions
- Gang scheduling decisions

## Failure Modes & Recovery

### Pod Failures
- **RestartPolicy**: OnFailure (default), Never, Always, ExitCode
- **BackoffLimit**: Maximum retries before job fails
- **CleanPodPolicy**: Running, All, None

### Operator Failures
- **Leader Election**: Ensures single active controller
- **Graceful Shutdown**: 10-second termination grace period
- **Health Checks**: Automatic restart on liveness failure

### Gang Scheduling Failures
- **PodGroup Status**: Monitors scheduling queue state
- **Timeout**: Configurable gang scheduling timeout
- **Backoff**: Exponential backoff on scheduling failures

## Security Considerations

### Pod Security
- **Non-root**: Operator runs as user 65532
- **No privilege escalation**: allowPrivilegeEscalation: false
- **FIPS compliance**: Built with strictfipsruntime tag

### Network Security
- **No TLS**: Metrics endpoint not encrypted (internal only)
- **Service Account**: Minimal RBAC permissions
- **Istio**: Sidecar disabled (training jobs may enable)

### Multi-tenancy
- **Namespace isolation**: Jobs run in user namespaces
- **RBAC**: training-edit/training-view roles for user access
- **Resource Quotas**: Kubernetes quotas apply to training jobs

## Known Limitations

1. **Single Operator Instance**: Leader election used but only one active replica
2. **No Webhook Validation**: CRD validation only (webhook server not deployed in RHOAI)
3. **No Network Policies**: Network segmentation not enforced by operator
4. **Plaintext Communication**: Training job pod-to-pod communication unencrypted
5. **No Built-in Auth**: Metrics endpoint has no authentication
