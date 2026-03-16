# Component: Kubeflow Training Operator

## Metadata
- **Repository**: https://github.com/red-hat-data-services/training-operator
- **Version**: 80efa250
- **Branch**: rhoai-2.15
- **Distribution**: RHOAI
- **Languages**: Go
- **Deployment Type**: Kubernetes Operator
- **Build System**: Konflux (Dockerfile.konflux)

## Purpose
**Short**: Kubernetes-native operator for distributed ML training across multiple frameworks (PyTorch, TensorFlow, MPI, XGBoost, MXNet, PaddlePaddle).

**Detailed**: The Kubeflow Training Operator is a unified Kubernetes operator that provides declarative APIs for running scalable distributed training jobs using various machine learning frameworks. It manages the lifecycle of training jobs by creating and monitoring pods, services, and other resources required for distributed training. The operator supports elastic training with autoscaling, gang scheduling integration (Volcano, scheduler-plugins), and provides comprehensive observability through Prometheus metrics. Users can submit training jobs either through Kubernetes Custom Resources or the Training Operator Python SDK, enabling both declarative and programmatic workflows.

The operator consolidates what were previously separate operators (PyTorch-operator, TF-operator, MPI-operator, etc.) into a single all-in-one operator, simplifying deployment and maintenance while providing consistent behavior across different ML frameworks.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| training-operator | Go Binary | Main operator manager executable, reconciles all job types |
| PyTorchJob Controller | Reconciler | Manages distributed PyTorch training jobs with elastic scaling support |
| TFJob Controller | Reconciler | Manages distributed TensorFlow training jobs with parameter server architecture |
| MPIJob Controller | Reconciler | Manages MPI-based distributed training jobs (e.g., Horovod) |
| XGBoostJob Controller | Reconciler | Manages distributed XGBoost training jobs |
| MXNetJob Controller | Reconciler | Manages distributed MXNet training jobs |
| PaddleJob Controller | Reconciler | Manages distributed PaddlePaddle training jobs |
| Gang Scheduler Integration | Scheduler Plugin | Optional integration with Volcano or scheduler-plugins for gang scheduling |
| Metrics Server | HTTP Server | Exposes Prometheus metrics on port 8080 |
| Health Probe Server | HTTP Server | Provides liveness/readiness endpoints on port 8081 |
| Webhook Server | HTTPS Server | Validates and mutates job CRs (port 9443) |

## APIs Exposed

### Custom Resource Definitions (CRDs)

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| kubeflow.org | v1 | PyTorchJob | Namespaced | Define distributed PyTorch training jobs with master/worker topology |
| kubeflow.org | v1 | TFJob | Namespaced | Define distributed TensorFlow training jobs with PS/worker/chief/evaluator roles |
| kubeflow.org | v1 | MPIJob | Namespaced | Define MPI-based distributed training jobs with launcher/worker topology |
| kubeflow.org | v1 | XGBoostJob | Namespaced | Define distributed XGBoost training jobs with master/worker topology |
| kubeflow.org | v1 | MXNetJob | Namespaced | Define distributed MXNet training jobs with server/worker/scheduler roles |
| kubeflow.org | v1 | PaddleJob | Namespaced | Define distributed PaddlePaddle training jobs with master/worker topology |

### HTTP Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /metrics | GET | 8080/TCP | HTTP | None | None | Prometheus metrics endpoint for operator and job statistics |
| /healthz | GET | 8081/TCP | HTTP | None | None | Liveness probe endpoint |
| /readyz | GET | 8081/TCP | HTTP | None | None | Readiness probe endpoint |
| /validate/* | POST | 9443/TCP | HTTPS | TLS 1.2+ | Kubernetes API Server | Webhook validation for job CRs |
| /mutate/* | POST | 9443/TCP | HTTPS | TLS 1.2+ | Kubernetes API Server | Webhook mutation for job CRs |

### gRPC Services

| Service | Port | Protocol | Encryption | Auth | Purpose |
|---------|------|----------|------------|------|---------|
| N/A | N/A | N/A | N/A | N/A | No gRPC services exposed |

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| Kubernetes | 1.25+ | Yes | Platform for running operator and training jobs |
| controller-runtime | v0.17.2 | Yes | Kubernetes controller framework |
| Prometheus Operator | Latest | No | PodMonitor support for metrics collection |
| Volcano | v1.8.0+ | No | Optional gang scheduling for training jobs |
| scheduler-plugins | v0.26.7+ | No | Optional gang scheduling alternative to Volcano |
| cert-manager | Latest | No | Webhook certificate management (if webhooks enabled) |

### Internal ODH Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| Prometheus | Metrics Scraping | PodMonitor scrapes metrics from training-operator pods |
| Service Mesh (Istio) | Sidecar Injection | Disabled via annotation `sidecar.istio.io/inject: "false"` |

## Network Architecture

### Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| training-operator | ClusterIP | 8080/TCP | 8080 | HTTP | None | None | Internal |

### Ingress

| Name | Type | Hosts | Port | Protocol | Encryption | TLS Mode | Exposure |
|------|------|-------|------|----------|------------|----------|----------|
| N/A | N/A | N/A | N/A | N/A | N/A | N/A | No external ingress configured |

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token | Watch/update CRs, pods, services, configmaps |
| Container Registry | 443/TCP | HTTPS | TLS 1.2+ | Image Pull Secret | Pull training job container images |
| Volcano API (optional) | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token | Create/update PodGroups for gang scheduling |

## Security

### RBAC - Cluster Roles

| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|
| training-operator | "" | pods | create, delete, get, list, patch, update, watch |
| training-operator | "" | pods/exec | create |
| training-operator | "" | services | create, delete, get, list, watch |
| training-operator | "" | serviceaccounts | create, get, list, watch |
| training-operator | "" | events | create, delete, get, list, patch, update, watch |
| training-operator | "" | configmaps | create, list, update, watch |
| training-operator | kubeflow.org | pytorchjobs | create, delete, get, list, patch, update, watch |
| training-operator | kubeflow.org | pytorchjobs/status | get, patch, update |
| training-operator | kubeflow.org | pytorchjobs/finalizers | update |
| training-operator | kubeflow.org | tfjobs | create, delete, get, list, patch, update, watch |
| training-operator | kubeflow.org | tfjobs/status | get, patch, update |
| training-operator | kubeflow.org | tfjobs/finalizers | update |
| training-operator | kubeflow.org | mpijobs | create, delete, get, list, patch, update, watch |
| training-operator | kubeflow.org | mpijobs/status | get, patch, update |
| training-operator | kubeflow.org | mpijobs/finalizers | update |
| training-operator | kubeflow.org | xgboostjobs | create, delete, get, list, patch, update, watch |
| training-operator | kubeflow.org | xgboostjobs/status | get, patch, update |
| training-operator | kubeflow.org | xgboostjobs/finalizers | update |
| training-operator | kubeflow.org | mxjobs | create, delete, get, list, patch, update, watch |
| training-operator | kubeflow.org | mxjobs/status | get, patch, update |
| training-operator | kubeflow.org | mxjobs/finalizers | update |
| training-operator | kubeflow.org | paddlejobs | create, delete, get, list, patch, update, watch |
| training-operator | kubeflow.org | paddlejobs/status | get, patch, update |
| training-operator | kubeflow.org | paddlejobs/finalizers | update |
| training-operator | autoscaling | horizontalpodautoscalers | create, delete, get, list, patch, update, watch |
| training-operator | rbac.authorization.k8s.io | roles | create, list, update, watch |
| training-operator | rbac.authorization.k8s.io | rolebindings | create, list, update, watch |
| training-operator | scheduling.volcano.sh | podgroups | create, delete, get, list, patch, update, watch |
| training-operator | scheduling.x-k8s.io | podgroups | create, delete, get, list, patch, update, watch |

### RBAC - Role Bindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| training-operator | All (ClusterRoleBinding) | training-operator | opendatahub/training-operator |

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| webhook-server-cert | kubernetes.io/tls | Webhook server TLS certificate | cert-manager or manual | Yes (if cert-manager) |

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| /metrics | GET | None (internal only) | Kubernetes NetworkPolicy | ClusterIP service restricts to internal access |
| /healthz | GET | None (internal only) | Kubernetes NetworkPolicy | Used by kubelet for liveness |
| /readyz | GET | None (internal only) | Kubernetes NetworkPolicy | Used by kubelet for readiness |
| Kubernetes API | GET, LIST, WATCH, CREATE, UPDATE, PATCH, DELETE | ServiceAccount Token | Kubernetes RBAC | ClusterRole permissions |
| Webhook endpoints | POST | Kubernetes API Server mTLS | Kubernetes API Server | API server validates certificate |

## Data Flows

### Flow 1: User Submits PyTorchJob

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User/CI System | Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | User Credentials (kubeconfig) |
| 2 | Kubernetes API Server | training-operator webhook | 9443/TCP | HTTPS | TLS 1.2+ | mTLS (API server client cert) |
| 3 | training-operator | Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 4 | training-operator | Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |

**Description**: User creates PyTorchJob CR → API server validates via webhook → Operator watches CR → Creates pods/services for distributed training

### Flow 2: Metrics Collection

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Prometheus | training-operator service | 8080/TCP | HTTP | None | None |

**Description**: Prometheus scrapes metrics endpoint based on PodMonitor configuration

### Flow 3: Gang Scheduling (Optional)

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | training-operator | Kubernetes API Server (Volcano API) | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 2 | Volcano Scheduler | Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |

**Description**: Operator creates PodGroup for gang scheduling → Volcano scheduler ensures all pods scheduled together

### Flow 4: Training Job Execution

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | training-operator | Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 2 | Training Worker Pods | Training Master Pod | Framework-specific (e.g., 23456/TCP for PyTorch) | TCP | Framework-dependent | None or framework auth |
| 3 | Training Pods | External Storage (S3/NFS) | 443/TCP or NFS | HTTPS/NFS | TLS 1.2+ or None | AWS IAM or NFS auth |

**Description**: Operator creates worker/master pods → Pods communicate for distributed training → Access shared storage for datasets/checkpoints

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| Kubernetes API Server | REST API | 6443/TCP | HTTPS | TLS 1.2+ | Watch CRs, create/update pods, services, events |
| Prometheus | Metrics Pull | 8080/TCP | HTTP | None | Scrape operator metrics (job counts, reconciliation times) |
| Volcano Scheduler | CRD (PodGroup) | 6443/TCP | HTTPS | TLS 1.2+ | Gang scheduling for training jobs |
| scheduler-plugins | CRD (PodGroup) | 6443/TCP | HTTPS | TLS 1.2+ | Alternative gang scheduling implementation |
| Container Registry | Image Pull | 443/TCP | HTTPS | TLS 1.2+ | Pull training job container images |
| cert-manager | CRD (Certificate) | 6443/TCP | HTTPS | TLS 1.2+ | Automatic webhook certificate provisioning |

## Deployment Architecture

### Deployment Configuration

| Parameter | Value | Purpose |
|-----------|-------|---------|
| Namespace | opendatahub | Deployment namespace for RHOAI |
| Name Prefix | kubeflow- | Prefix for all resources |
| Replicas | 1 | Single replica deployment (leader election enabled) |
| Image | quay.io/opendatahub/training-operator:v1-odh-c7d4e1b | Container image |
| Service Account | training-operator | ServiceAccount for RBAC |
| Leader Election | Enabled | Ensures single active controller |
| Leader Election ID | 1ca428e5.training-operator.kubeflow.org | Lock resource identifier |
| Controller Threads | 1 (configurable) | Number of worker threads per controller |
| Istio Sidecar | Disabled | Annotation: `sidecar.istio.io/inject: "false"` |

### Resource Limits

| Resource | Request | Limit | Notes |
|----------|---------|-------|-------|
| CPU | Not specified | Not specified | Define based on cluster size and job volume |
| Memory | Not specified | Not specified | Define based on cluster size and job volume |

### Environment Variables

| Variable | Source | Purpose |
|----------|--------|---------|
| MY_POD_NAMESPACE | metadata.namespace | Namespace awareness for operator |
| MY_POD_NAME | metadata.name | Pod identity for logging/debugging |
| KUBEFLOW_NAMESPACE | Environment | Optional: restrict operator to single namespace |

### Monitoring

| Monitor Type | Name | Selector | Port | Purpose |
|--------------|------|----------|------|---------|
| PodMonitor | training-operator-metrics-monitor | app.kubernetes.io/name=training-operator | metrics | Scrape operator metrics for Prometheus |

## Configuration

### Supported Job Types (Enabled by Default)

| Job Type | Framework | Default Port | Default Restart Policy | Replica Types |
|----------|-----------|--------------|------------------------|---------------|
| PyTorchJob | PyTorch | 23456 | OnFailure | Master, Worker |
| TFJob | TensorFlow | 2222 | Never | PS, Worker, Chief, Master, Evaluator |
| MPIJob | MPI/Horovod | 9999 | Never | Launcher, Worker |
| XGBoostJob | XGBoost | 9999 | Never | Master, Worker |
| MXNetJob | MXNet | Various | Never | Server, Worker, Scheduler |
| PaddleJob | PaddlePaddle | Various | OnFailure | Master, Worker |

### Gang Scheduling Options

| Scheduler | CRD Group | CRD Kind | Purpose |
|-----------|-----------|----------|---------|
| Volcano | scheduling.volcano.sh | PodGroup | Gang scheduling with Volcano scheduler |
| scheduler-plugins | scheduling.x-k8s.io | PodGroup | Gang scheduling with Kubernetes scheduler-plugins |
| None (default) | N/A | N/A | Standard Kubernetes scheduling |

### Init Containers

| Init Container | Image | Purpose | Job Types |
|----------------|-------|---------|-----------|
| pytorch-init-container | Default from config | Setup distributed training environment | PyTorchJob |
| mpi-kubectl-delivery | Default from config | Deliver kubectl to launcher pod | MPIJob |

## Observability

### Metrics Exposed

| Metric Name | Type | Labels | Description |
|-------------|------|--------|-------------|
| training_operator_jobs_created_total | Counter | job_type, namespace | Total number of training jobs created |
| training_operator_jobs_successful_total | Counter | job_type, namespace | Total number of successful training jobs |
| training_operator_jobs_failed_total | Counter | job_type, namespace | Total number of failed training jobs |
| training_operator_reconcile_duration_seconds | Histogram | job_type | Duration of reconciliation loops |

### Logs

| Component | Log Level | Format | Destination |
|-----------|-----------|--------|-------------|
| training-operator | Info (configurable) | JSON (zap logger) | stdout |

### Health Checks

| Check | Endpoint | Port | Type |
|-------|----------|------|------|
| Liveness | /healthz | 8081 | HTTP GET |
| Readiness | /readyz | 8081 | HTTP GET |

## Recent Changes

| Commit | Date | Changes |
|--------|------|---------|
| 80efa250 | 2026 (RHOAI 2.15) | - Current RHOAI 2.15 release<br>- Konflux-based build system<br>- Updated dependencies<br>- RHOAI-specific configuration |

## Known Limitations

| Limitation | Impact | Workaround |
|------------|--------|------------|
| Single namespace watch (optional) | Operator can only watch jobs in configured namespace | Deploy multiple operators for multi-tenancy |
| No built-in model registry integration | Training jobs must handle model artifacts separately | Use external tools like MLflow, KServe ModelRegistry |
| Resource limits not set by default | Could consume excessive cluster resources | Configure resource requests/limits in job specs |

## Security Considerations

| Concern | Mitigation | Status |
|---------|------------|--------|
| Elevated pod permissions | ClusterRole with pod creation/exec | Required for job management |
| Training job isolation | Use Kubernetes namespaces and NetworkPolicies | User responsibility |
| Secrets in training jobs | Use Kubernetes secrets with RBAC | User responsibility |
| Container image trust | Use trusted registries and image scanning | User responsibility |
| Service mesh exclusion | Istio sidecar injection disabled | Simplifies networking, reduces overhead |

## Best Practices

1. **Resource Management**: Always define resource requests/limits in job replica specs to prevent resource exhaustion
2. **Gang Scheduling**: Use Volcano or scheduler-plugins for large multi-pod jobs to avoid partial scheduling deadlocks
3. **Job Cleanup**: Configure TTLSecondsAfterFinished in RunPolicy to automatically clean up completed jobs
4. **Monitoring**: Enable PodMonitor and configure Prometheus alerts for job failures
5. **Namespace Isolation**: Deploy training jobs in separate namespaces with appropriate RBAC and resource quotas
6. **Storage**: Use PersistentVolumeClaims or object storage (S3) for training datasets and model checkpoints
7. **Fault Tolerance**: Configure appropriate restart policies and backoffLimit for transient failure recovery
8. **Elastic Training**: Use PyTorchJob elastic policy with HPA for dynamic scaling based on metrics

## Troubleshooting

| Issue | Symptom | Resolution |
|-------|---------|------------|
| Jobs not progressing | Pods in Pending state | Check gang scheduling requirements, resource availability |
| Webhook failures | Job creation rejected | Verify webhook certificate is valid and service is accessible |
| Pod exec errors | Permission denied logs | Verify training-operator ServiceAccount has pods/exec permission |
| Network communication failures | Worker pods can't reach master | Check NetworkPolicies, Services created correctly |
| Metrics not scraped | No operator metrics in Prometheus | Verify PodMonitor configuration and selector labels |

## Related Documentation

- [Kubeflow Training Operator Documentation](https://www.kubeflow.org/docs/components/training/)
- [PyTorchJob Guide](https://www.kubeflow.org/docs/components/training/pytorch/)
- [TFJob Guide](https://www.kubeflow.org/docs/components/training/tftraining/)
- [Gang Scheduling Documentation](docs/gang-scheduling/)
- [Monitoring Documentation](docs/monitoring/README.md)
- [Python SDK Documentation](sdk/python/kubeflow/training/api/training_client.py)
