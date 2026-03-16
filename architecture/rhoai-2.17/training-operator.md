# Component: Kubeflow Training Operator

## Metadata
- **Repository**: https://github.com/red-hat-data-services/training-operator.git
- **Version**: 1.8.0-rc.0 (git: 36be2dda, branch: rhoai-2.17)
- **Distribution**: RHOAI
- **Languages**: Go 1.21
- **Deployment Type**: Kubernetes Operator

## Purpose
**Short**: Kubernetes-native operator for distributed machine learning training jobs across multiple ML frameworks.

**Detailed**: The Kubeflow Training Operator is a Kubernetes operator that enables scalable distributed training of machine learning models using custom resources. It provides unified APIs for managing training jobs across six major ML frameworks: PyTorch, TensorFlow, Apache MPI, XGBoost, Apache MXNet, and PaddlePaddle. The operator handles the lifecycle of distributed training workloads including pod creation, service discovery, failure recovery, and status reporting.

The operator supports advanced features such as elastic training (dynamic worker scaling), gang scheduling for coordinated pod scheduling, and horizontal pod autoscaling for PyTorch elastic workloads. It integrates with Kubernetes-native tooling including Prometheus for metrics, optional Volcano or Scheduler-Plugins for gang scheduling, and provides both Kubernetes API access and a Python SDK for job management.

Built on the controller-runtime framework, the operator runs as a single deployment managing all job types through separate reconciliation controllers. Each controller watches its respective custom resources and creates the necessary Kubernetes primitives (Pods, Services, ConfigMaps, RoleBindings) to execute distributed training workloads.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| training-operator manager | Go binary | Main controller process managing all training job CRDs |
| PyTorchJob controller | Reconciler | Manages PyTorch distributed training jobs with elastic support |
| TFJob controller | Reconciler | Manages TensorFlow distributed training jobs |
| MPIJob controller | Reconciler | Manages MPI-based distributed training jobs |
| XGBoostJob controller | Reconciler | Manages XGBoost distributed training jobs |
| MXJob controller | Reconciler | Manages Apache MXNet distributed training jobs |
| PaddleJob controller | Reconciler | Manages PaddlePaddle distributed training jobs |
| Webhook server | HTTP server | Validates and mutates training job resources (port 9443) |
| Metrics server | HTTP server | Exposes Prometheus metrics (port 8080) |
| Health probe server | HTTP server | Provides health and readiness endpoints (port 8081) |

## APIs Exposed

### Custom Resource Definitions (CRDs)

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| kubeflow.org | v1 | PyTorchJob | Namespaced | Defines distributed PyTorch training jobs with elastic scaling support |
| kubeflow.org | v1 | TFJob | Namespaced | Defines distributed TensorFlow training jobs |
| kubeflow.org | v1 | MPIJob | Namespaced | Defines MPI-based distributed training jobs |
| kubeflow.org | v1 | XGBoostJob | Namespaced | Defines distributed XGBoost training jobs |
| kubeflow.org | v1 | MXJob | Namespaced | Defines distributed Apache MXNet training jobs |
| kubeflow.org | v1 | PaddleJob | Namespaced | Defines distributed PaddlePaddle training jobs |

### HTTP Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /metrics | GET | 8080/TCP | HTTP | None | None | Prometheus metrics scraping |
| /healthz | GET | 8081/TCP | HTTP | None | None | Liveness probe endpoint |
| /readyz | GET | 8081/TCP | HTTP | None | None | Readiness probe endpoint |
| /validate/* | POST | 9443/TCP | HTTPS | TLS 1.2+ | mTLS | Webhook validation for training job CRDs |
| /mutate/* | POST | 9443/TCP | HTTPS | TLS 1.2+ | mTLS | Webhook mutation for training job CRDs |

### gRPC Services

None - This operator uses HTTP-based APIs only.

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| Kubernetes | 1.25+ | Yes | Container orchestration platform |
| controller-runtime | v0.17.2 | Yes | Kubernetes operator framework |
| Volcano | v1.8.0 | No | Optional gang scheduling for coordinated pod scheduling |
| Scheduler-Plugins | v0.26.7 | No | Optional alternative gang scheduling implementation |
| Prometheus | N/A | No | Metrics collection via PodMonitor |
| cert-manager | N/A | No | TLS certificate provisioning for webhooks |

### Internal ODH Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| odh-model-controller | CRD watches | Training jobs may produce models consumed by model serving |
| Prometheus | Metrics scraping | Operator metrics collection via PodMonitor |
| Service Mesh (Istio) | Network policy | Sidecar injection disabled for operator pod |

## Network Architecture

### Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| training-operator | ClusterIP | 8080/TCP | 8080 | HTTP | None | None | Internal |

### Ingress

None - The training operator does not expose external ingress. Training jobs created by the operator may define their own services/ingress.

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| Kubernetes API Server | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount token | CRD reconciliation, pod/service management |
| Container Registry | 443/TCP | HTTPS | TLS 1.2+ | Pull secrets | Pull training job container images |
| Volcano API Server | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount token | Gang scheduling PodGroup management (optional) |

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

### RBAC - Role Bindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| training-operator | opendatahub | ClusterRole/training-operator | training-operator |

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| webhook-server-cert | kubernetes.io/tls | TLS certificate for webhook server | cert-manager | Yes |

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| /metrics | GET | None | N/A | Prometheus scrapes internally |
| /healthz, /readyz | GET | None | N/A | Health probes from kubelet |
| /validate/*, /mutate/* | POST | mTLS client certificates | Kubernetes API Server | API Server validates webhook certs |
| Kubernetes API | ALL | ServiceAccount token (JWT) | API Server | RBAC ClusterRole permissions |

## Data Flows

### Flow 1: Training Job Creation

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User/SDK | Kubernetes API Server | 443/TCP | HTTPS | TLS 1.2+ | Bearer Token (user credentials) |
| 2 | Kubernetes API Server | training-operator webhook | 9443/TCP | HTTPS | TLS 1.2+ | mTLS (API server client cert) |
| 3 | training-operator controller | Kubernetes API Server | 443/TCP | HTTPS | TLS 1.2+ | Bearer Token (ServiceAccount) |
| 4 | training-operator controller | Kubernetes API Server | 443/TCP | HTTPS | TLS 1.2+ | Bearer Token (ServiceAccount) |

**Description**: User creates PyTorchJob/TFJob/etc → API Server validates via webhook → Operator watches CRD → Operator creates Pods/Services for training job.

### Flow 2: Gang Scheduling (Optional)

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | training-operator controller | Kubernetes API Server | 443/TCP | HTTPS | TLS 1.2+ | Bearer Token (ServiceAccount) |
| 2 | training-operator controller | Volcano/Scheduler-Plugins API | 443/TCP | HTTPS | TLS 1.2+ | Bearer Token (ServiceAccount) |
| 3 | Gang Scheduler | Kubernetes Scheduler | N/A | In-process | N/A | N/A |

**Description**: Operator creates PodGroup for gang scheduling → Gang scheduler ensures all pods scheduled atomically → Training pods start together.

### Flow 3: Metrics Collection

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Prometheus | training-operator pod | 8080/TCP | HTTP | None | None |

**Description**: Prometheus scrapes /metrics endpoint based on PodMonitor configuration.

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| Kubernetes API Server | REST API client | 443/TCP | HTTPS | TLS 1.2+ | Watch CRDs, manage pods/services/configmaps |
| Volcano Scheduler | CRD creation | 443/TCP | HTTPS | TLS 1.2+ | Create PodGroups for gang scheduling |
| Scheduler-Plugins | CRD creation | 443/TCP | HTTPS | TLS 1.2+ | Create PodGroups for alternative gang scheduling |
| Prometheus | Metrics scraping | 8080/TCP | HTTP | None | Expose operator and job metrics |
| Training Job Pods | Service creation | Varies | Varies | Varies | Create services for pod-to-pod communication |

## Recent Changes

| Version | Date | Changes |
|---------|------|---------|
| 1.8.0-rc.0 | 2024 | - Component metadata for RHOAI 2.17<br>- Konflux build pipeline integration<br>- UBI9 base image updates<br>- Multi-arch manifest support |
| 1.7.0 | 2023-07 | - Kubernetes 1.27 support<br>- Scheduler-plugins as default gang scheduler<br>- Suspend semantics implementation<br>- Controller startup optimization via goroutines<br>- PyTorch torchrun environment support<br>- Merged kubeflow/common into training-operator |
| 1.6.0 | 2023-03 | - Kubernetes 1.25 support<br>- HPA support for PyTorch Elastic<br>- PaddlePaddle framework support<br>- Python SDK unified Training Client<br>- Function API for creating jobs from SDK<br>- PodGroup as controller watch source |

## Deployment Configuration

### RHOAI-Specific Configuration

The operator is deployed to the `opendatahub` namespace with the `kubeflow-` name prefix. The deployment uses Kustomize with RHOAI-specific patches:

- **Image**: `quay.io/opendatahub/training-operator:v1-odh-c7d4e1b`
- **Metrics**: Named port "metrics" on container port 8080
- **Monitoring**: PodMonitor resource for Prometheus integration
- **Service Mesh**: Istio sidecar injection explicitly disabled
- **Security**: Non-root user (UID 65532), no privilege escalation
- **Health Checks**:
  - Liveness: HTTP GET /healthz:8081 (15s initial delay, 20s period)
  - Readiness: HTTP GET /readyz:8081 (10s initial delay, 15s period)

### Controller Configuration

The operator supports the following runtime configurations:

- **Enabled Schemes**: Selectively enable job types (default: all enabled)
- **Gang Scheduler**: Configure Volcano or Scheduler-Plugins (default: Scheduler-Plugins)
- **Namespace Scope**: Monitor all namespaces or specific namespace only
- **Controller Threads**: Number of worker threads per controller (default: 1)
- **Leader Election**: High availability mode with leader election
- **PyTorch Init Container**: Customizable image and retry settings
- **MPI Kubectl Delivery**: Customizable image for MPI launcher init container

## Build and Container

The operator is built using a multi-stage Dockerfile with FIPS compliance:

1. **Builder Stage**: UBI8 Go 1.21 toolset
   - CGO enabled with strict FIPS runtime tags
   - Builds `/manager` binary from `cmd/training-operator.v1/main.go`

2. **Runtime Stage**: UBI8 minimal base image
   - Non-root user (UID 65532)
   - Minimal attack surface
   - RHOAI component labels and metadata

**Container Labels**:
- Component: `odh-training-operator-container`
- Name: `managed-open-data-hub/odh-training-operator-rhel8`
- Maintainer: `managed-open-data-hub@redhat.com`

## Observability

### Metrics

The operator exposes Prometheus metrics on port 8080:

- **Controller metrics**: Reconciliation latency, queue depth, error rates
- **Workqueue metrics**: Queue length, work duration, retries
- **Go runtime metrics**: Memory, goroutines, GC stats
- **Custom metrics**: Job success/failure counts, job duration

### Logging

Structured logging using zap with configurable levels:
- Development mode enabled by default
- Stacktrace level: DPanic (development panic)
- Logs controller reconciliation events, pod status changes, errors

### Health Probes

- **Liveness**: Ensures manager process is responsive
- **Readiness**: Ensures controller is ready to reconcile resources
- Both probes use simple HTTP GET to verify process health
