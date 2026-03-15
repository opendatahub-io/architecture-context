# Component: Kubeflow Training Operator

## Metadata
- **Repository**: https://github.com/red-hat-data-services/training-operator
- **Version**: 1.9.0 (commit 2d07807b)
- **Branch**: rhoai-3.2
- **Distribution**: RHOAI
- **Languages**: Go 1.23
- **Deployment Type**: Kubernetes Operator
- **Build System**: Konflux (RHOAI builds)

## Purpose
**Short**: Kubernetes operator for distributed machine learning training jobs across multiple ML frameworks.

**Detailed**: The Kubeflow Training Operator is a Kubernetes-native operator that enables scalable distributed training and fine-tuning of machine learning models. It provides a unified API for running training workloads across multiple ML frameworks including PyTorch, TensorFlow, XGBoost, JAX, PaddlePaddle, and MPI-based HPC applications. The operator manages the lifecycle of training jobs by creating and orchestrating Pods, Services, and NetworkPolicies, while providing features like elastic scaling, gang scheduling, and automatic fault recovery. It exposes metrics for monitoring and uses validating webhooks to ensure job configurations are correct before execution.

The operator reconciles custom resources for each ML framework, creating the necessary Kubernetes resources (Pods, Services) for distributed training, managing communication between training replicas, and handling job status updates. It integrates with gang schedulers (Volcano, scheduler-plugins) for efficient resource allocation and supports elastic training with dynamic scaling based on HPA metrics.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| training-operator | Deployment | Main controller managing all training job types |
| pytorchjob-controller | Controller | Reconciles PyTorchJob CRDs, manages distributed PyTorch training |
| tfjob-controller | Controller | Reconciles TFJob CRDs, manages distributed TensorFlow training |
| xgboostjob-controller | Controller | Reconciles XGBoostJob CRDs, manages distributed XGBoost training |
| mpijob-controller | Controller | Reconciles MPIJob CRDs, manages MPI-based HPC and training workloads |
| paddlejob-controller | Controller | Reconciles PaddleJob CRDs, manages distributed PaddlePaddle training |
| jaxjob-controller | Controller | Reconciles JAXJob CRDs, manages distributed JAX training |
| webhook-server | Webhook Server | Validates training job CRDs on create/update operations |
| metrics-server | HTTP Server | Exposes Prometheus metrics for operator and training jobs |

## APIs Exposed

### Custom Resource Definitions (CRDs)

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| kubeflow.org | v1 | PyTorchJob | Namespaced | Defines distributed PyTorch training jobs with master/worker replicas |
| kubeflow.org | v1 | TFJob | Namespaced | Defines distributed TensorFlow training jobs with chief/worker/ps replicas |
| kubeflow.org | v1 | XGBoostJob | Namespaced | Defines distributed XGBoost training jobs with master/worker replicas |
| kubeflow.org | v1 | MPIJob | Namespaced | Defines MPI-based training/HPC jobs with launcher/worker replicas |
| kubeflow.org | v1 | PaddleJob | Namespaced | Defines distributed PaddlePaddle training jobs with master/worker replicas |
| kubeflow.org | v1 | JAXJob | Namespaced | Defines distributed JAX training jobs with worker replicas |

### HTTP Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /metrics | GET | 8080/TCP | HTTP | None | None | Prometheus metrics endpoint for operator and job metrics |
| /healthz | GET | 8081/TCP | HTTP | None | None | Liveness probe endpoint |
| /readyz | GET | 8081/TCP | HTTP | None | None | Readiness probe endpoint (includes webhook cert check) |
| /validate-kubeflow-org-v1-pytorchjob | POST | 9443/TCP | HTTPS | TLS 1.2+ | mTLS | Validating webhook for PyTorchJob resources |
| /validate-kubeflow-org-v1-tfjob | POST | 9443/TCP | HTTPS | TLS 1.2+ | mTLS | Validating webhook for TFJob resources |
| /validate-kubeflow-org-v1-xgboostjob | POST | 9443/TCP | HTTPS | TLS 1.2+ | mTLS | Validating webhook for XGBoostJob resources |
| /validate-kubeflow-org-v1-mpijob | POST | 9443/TCP | HTTPS | TLS 1.2+ | mTLS | Validating webhook for MPIJob resources |
| /validate-kubeflow-org-v1-paddlejob | POST | 9443/TCP | HTTPS | TLS 1.2+ | mTLS | Validating webhook for PaddleJob resources |
| /validate-kubeflow-org-v1-jaxjob | POST | 9443/TCP | HTTPS | TLS 1.2+ | mTLS | Validating webhook for JAXJob resources |

### gRPC Services

| Service | Port | Protocol | Encryption | Auth | Purpose |
|---------|------|----------|------------|------|---------|
| N/A | N/A | N/A | N/A | N/A | No gRPC services exposed |

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| Kubernetes | 1.27+ | Yes | Container orchestration platform |
| controller-runtime | v0.19.1 | Yes | Kubernetes controller framework |
| Prometheus | Any | No | Metrics collection and monitoring |
| Volcano | v1.9.0 | No | Gang scheduling for batch jobs |
| scheduler-plugins | v0.28.9 | No | Alternative gang scheduling implementation |
| cert-manager | Any | No | Automated certificate management (alternative to self-signed) |

### Internal ODH Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| odh-dashboard | UI | Dashboard displays training jobs in the UI |
| prometheus | Metrics | Collects operator and training job metrics via PodMonitor |

## Network Architecture

### Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| training-operator | ClusterIP | 8080/TCP | 8080 | HTTP | None | None | Internal |
| training-operator | ClusterIP | 443/TCP | 9443 | HTTPS | TLS 1.2+ | mTLS | Internal |
| *-master-0 (per job) | ClusterIP | 23456/TCP | 23456 | TCP | Depends on job | None | Internal |
| *-worker-* (per job) | Headless | Various | Various | TCP | Depends on job | None | Internal |

### Ingress

| Name | Type | Hosts | Port | Protocol | Encryption | TLS Mode | Exposure |
|------|------|-------|------|----------|------------|----------|----------|
| N/A | N/A | N/A | N/A | N/A | N/A | N/A | No ingress resources - internal operator only |

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token | Watch/manage CRDs, Pods, Services, NetworkPolicies |
| Container Registries | 443/TCP | HTTPS | TLS 1.2+ | Image pull secrets | Pull init container and training images |

## Security

### RBAC - Cluster Roles

| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|
| training-operator | "" | configmaps | create, list, update, watch |
| training-operator | "" | events | create, delete, get, list, patch, update, watch |
| training-operator | "" | pods | create, delete, get, list, patch, update, watch |
| training-operator | "" | pods/exec | create |
| training-operator | "" | secrets | get, list, update, watch |
| training-operator | "" | serviceaccounts | create, get, list, watch |
| training-operator | "" | services | create, delete, get, list, watch |
| training-operator | admissionregistration.k8s.io | validatingwebhookconfigurations | get, list, update, watch |
| training-operator | autoscaling | horizontalpodautoscalers | create, delete, get, list, patch, update, watch |
| training-operator | kubeflow.org | pytorchjobs, pytorchjobs/status, pytorchjobs/finalizers | create, delete, get, list, patch, update, watch |
| training-operator | kubeflow.org | tfjobs, tfjobs/status, tfjobs/finalizers | create, delete, get, list, patch, update, watch |
| training-operator | kubeflow.org | xgboostjobs, xgboostjobs/status, xgboostjobs/finalizers | create, delete, get, list, patch, update, watch |
| training-operator | kubeflow.org | mpijobs, mpijobs/status, mpijobs/finalizers | create, delete, get, list, patch, update, watch |
| training-operator | kubeflow.org | paddlejobs, paddlejobs/status, paddlejobs/finalizers | create, delete, get, list, patch, update, watch |
| training-operator | kubeflow.org | jaxjobs, jaxjobs/status, jaxjobs/finalizers | create, delete, get, list, patch, update, watch |
| training-operator | rbac.authorization.k8s.io | roles, rolebindings | create, list, update, watch |
| training-operator | scheduling.volcano.sh | podgroups | create, delete, get, list, patch, update, watch |
| training-operator | scheduling.x-k8s.io | podgroups | create, delete, get, list, patch, update, watch |
| training-operator | networking.k8s.io | networkpolicies | create, delete, get, list, patch, update, watch |
| training-edit | kubeflow.org | mpijobs, tfjobs, pytorchjobs, xgboostjobs, paddlejobs | create, delete, get, list, patch, update, watch |
| training-edit | kubeflow.org | mpijobs/status, tfjobs/status, pytorchjobs/status, xgboostjobs/status, paddlejobs/status | get |
| training-view | kubeflow.org | mpijobs, tfjobs, pytorchjobs, xgboostjobs, paddlejobs | get, list, watch |
| training-view | kubeflow.org | mpijobs/status, tfjobs/status, pytorchjobs/status, xgboostjobs/status, paddlejobs/status | get |

### RBAC - Role Bindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| training-operator | Cluster-scoped | ClusterRole: training-operator | opendatahub:training-operator |

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| training-operator-webhook-cert | kubernetes.io/tls | TLS certificates for validating webhook server | cert-controller (self-signed) | Yes |

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| /validate-kubeflow-org-v1-* | POST | mTLS (Kubernetes API Server) | Webhook Server | ValidatingWebhookConfiguration with clientConfig |
| /metrics | GET | None | Application | Public metrics endpoint (internal cluster access only) |
| /healthz | GET | None | Application | Public health endpoint |
| /readyz | GET | None | Application | Public readiness endpoint |
| Kubernetes API | ALL | ServiceAccount Token (JWT) | Kubernetes API Server | ClusterRole permissions for training-operator SA |

## Data Flows

### Flow 1: Training Job Creation

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User/Dashboard | Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | Bearer Token |
| 2 | Kubernetes API Server | training-operator webhook | 9443/TCP | HTTPS | TLS 1.2+ | mTLS |
| 3 | training-operator webhook | Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |

### Flow 2: Job Reconciliation Loop

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Kubernetes API Server | training-operator controller | Internal | Watch Stream | TLS 1.2+ | ServiceAccount Token |
| 2 | training-operator controller | Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |

### Flow 3: Distributed Training Communication

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Worker Pod | Master Pod | 23456/TCP | TCP | None (framework-dependent) | None |
| 2 | Worker Pod | Worker Pod | Various/TCP | TCP | None (framework-dependent) | None |

### Flow 4: Metrics Collection

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Prometheus | training-operator | 8080/TCP | HTTP | None | None |

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| Kubernetes API Server | REST API | 6443/TCP | HTTPS | TLS 1.2+ | Watch CRDs, manage Pods/Services/NetworkPolicies |
| Prometheus | HTTP Scrape | 8080/TCP | HTTP | None | Collect operator and training job metrics |
| Volcano Scheduler | CRD API | 6443/TCP | HTTPS | TLS 1.2+ | Create PodGroups for gang scheduling |
| Scheduler Plugins | CRD API | 6443/TCP | HTTPS | TLS 1.2+ | Create PodGroups for gang scheduling |
| Container Registry | Image Pull | 443/TCP | HTTPS | TLS 1.2+ | Pull training images and init containers |

## Recent Changes

| Version | Date | Changes |
|---------|------|---------|
| 2d07807b | 2026-03-14 | - Update UBI9 minimal base image digest to 759f5f4<br>- Security updates for base image |
| 750e835c | 2026-03-10 | - Update UBI9 minimal base image digest to ecd4751<br>- Dependency maintenance |
| a9dc25b0 | 2026-03-05 | - Update UBI9 minimal base image digest to bb08f23<br>- Container image updates |
| d2e4ec61 | 2026-02-28 | - Update UBI9 minimal base image digest to 90bd85d<br>- Security patch updates |
| 852ea6e6 | 2026-02-25 | - Update Konflux references<br>- Build system improvements for RHOAI 3.2 |

## Deployment Architecture

### Manifest Structure

The training-operator uses Kustomize for deployment with the following structure:

- **Base manifests** (`manifests/base/`):
  - CRDs for all 6 training job types
  - Deployment, Service, ServiceAccount
  - ClusterRole and ClusterRoleBinding
  - ValidatingWebhookConfiguration

- **RHOAI overlay** (`manifests/rhoai/`):
  - Namespace: `opendatahub`
  - Name prefix: `kubeflow-`
  - Custom image configuration via ConfigMap
  - PodMonitor for Prometheus metrics
  - Additional ClusterRoles for user access (training-edit, training-view)
  - Webhook certificate generation

### Container Images

**Primary Image** (built via Konflux):
- Path: `build/images/training-operator/Dockerfile.konflux`
- Base: `registry.access.redhat.com/ubi9/ubi-minimal` (FIPS-compliant)
- Builder: `registry.access.redhat.com/ubi9/go-toolset:1.24`
- Build flags: `CGO_ENABLED=1`, `GOEXPERIMENT=strictfipsruntime`, `-tags strictfipsruntime`
- Runtime user: UID 65532 (non-root)

**Init Containers**:
- PyTorch init container: Configurable via `--pytorch-init-container-image` flag
- MPI kubectl delivery: Configurable via `--mpi-kubectl-delivery-image` flag

## Configuration

### Operator Flags

| Flag | Default | Purpose |
|------|---------|---------|
| --metrics-bind-address | :8080 | Prometheus metrics server address |
| --health-probe-bind-address | :8081 | Health/readiness probe server address |
| --enable-scheme | All enabled | Comma-separated list of job types to enable |
| --gang-scheduler-name | None | Gang scheduler to use (volcano or scheduler-plugins) |
| --namespace | All namespaces | Limit operator to specific namespace |
| --controller-threads | 1 | Number of worker threads per controller |
| --kube-api-qps | 20 | Max QPS to Kubernetes API server |
| --kube-api-burst | 30 | Max burst for API throttling |
| --webhook-server-port | 9443 | Webhook server port |

### Environment Variables

| Variable | Purpose |
|----------|---------|
| KUBEFLOW_NAMESPACE | Namespace for operator when deployed on Kubernetes |
| MY_POD_NAMESPACE | Injected from downward API - operator's namespace |
| MY_POD_NAME | Injected from downward API - operator's pod name |

## Observability

### Metrics

The operator exposes Prometheus metrics on port 8080 at `/metrics`:

- Controller reconciliation metrics
- Training job status metrics
- Webhook validation metrics
- Resource creation/deletion metrics
- Queue depth and latency metrics

### Logging

- Structured logging via zap logger
- Configurable log levels via command-line flags
- Kubernetes events for job lifecycle changes

### Health Checks

- **Liveness**: `/healthz` on port 8081 - simple ping check
- **Readiness**: `/readyz` on port 8081 - includes webhook cert validation

## Known Limitations

1. **Single Replica**: Operator runs with 1 replica (leader election disabled by default)
2. **Framework-specific networking**: Each ML framework may use different ports and protocols for inter-worker communication
3. **NetworkPolicy creation**: Operator creates NetworkPolicies for job isolation, but actual enforcement depends on CNI plugin support
4. **Webhook dependency**: Operator readiness depends on webhook certificate generation completing
5. **Gang scheduling**: Optional gang scheduling requires separate scheduler installation (Volcano or scheduler-plugins)

## Security Considerations

1. **FIPS Compliance**: Built with FIPS-compliant Go runtime and UBI9 base image
2. **Non-root**: Runs as UID 65532 (non-root user)
3. **Privilege Escalation**: Disabled in security context
4. **Pod Exec**: Operator has pod/exec permissions (required for MPI launcher)
5. **Webhook Certificates**: Self-signed certificates rotated by cert-controller
6. **Istio Sidecar**: Disabled via annotation (`sidecar.istio.io/inject: "false"`)
7. **Secrets Access**: Operator can read/update secrets (used for webhook certs and job configuration)
