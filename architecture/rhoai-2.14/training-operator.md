# Component: Kubeflow Training Operator

## Metadata
- **Repository**: https://github.com/red-hat-data-services/training-operator.git
- **Version**: 4b4e3bb4 (rhoai-2.14 branch)
- **Distribution**: RHOAI
- **Languages**: Go 1.21
- **Deployment Type**: Kubernetes Operator
- **Namespace**: opendatahub

## Purpose
**Short**: Kubernetes-native operator for distributed training of machine learning models across multiple frameworks.

**Detailed**:
The Kubeflow Training Operator is a unified operator that enables scalable distributed training and fine-tuning of machine learning models on Kubernetes. It provides Custom Resource Definitions (CRDs) for six major ML frameworks: PyTorch, TensorFlow, Apache MXNet, XGBoost, MPI, and PaddlePaddle. The operator manages the lifecycle of training jobs, automatically creating and managing pods, services, and configuration for distributed training workloads.

The operator implements a reconciliation loop that watches training job CRDs and ensures the desired state matches the actual state by creating worker pods, setting up networking between distributed training workers, managing job lifecycle (start, restart, completion), and optionally integrating with gang schedulers (Volcano or scheduler-plugins) for better resource allocation. It supports elastic training for PyTorch jobs with horizontal pod autoscaling, and exposes metrics for monitoring training job health and performance.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| Training Operator Manager | Go Binary | Main controller process that reconciles training job CRDs |
| PyTorch Controller | Reconciler | Manages PyTorchJob custom resources and worker pods |
| TensorFlow Controller | Reconciler | Manages TFJob custom resources and parameter servers/workers |
| MPI Controller | Reconciler | Manages MPIJob custom resources for MPI-based training |
| MXNet Controller | Reconciler | Manages MXJob custom resources for Apache MXNet training |
| XGBoost Controller | Reconciler | Manages XGBoostJob custom resources for gradient boosting |
| PaddlePaddle Controller | Reconciler | Manages PaddleJob custom resources for PaddlePaddle training |
| Metrics Server | HTTP Endpoint | Exposes Prometheus metrics on port 8080 |
| Health Probe Server | HTTP Endpoint | Provides liveness and readiness probes on port 8081 |

## APIs Exposed

### Custom Resource Definitions (CRDs)

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| kubeflow.org | v1 | PyTorchJob | Namespaced | Defines distributed PyTorch training jobs with support for elastic training and torchrun |
| kubeflow.org | v1 | TFJob | Namespaced | Defines TensorFlow distributed training jobs with parameter servers and workers |
| kubeflow.org | v1 | MPIJob | Namespaced | Defines MPI-based distributed training jobs using Message Passing Interface |
| kubeflow.org | v1 | MXJob | Namespaced | Defines Apache MXNet distributed training jobs |
| kubeflow.org | v1 | XGBoostJob | Namespaced | Defines XGBoost gradient boosting training jobs |
| kubeflow.org | v1 | PaddleJob | Namespaced | Defines PaddlePaddle distributed deep learning training jobs |

### HTTP Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /metrics | GET | 8080/TCP | HTTP | None | None | Prometheus metrics endpoint for job and controller metrics |
| /healthz | GET | 8081/TCP | HTTP | None | None | Liveness probe for operator health status |
| /readyz | GET | 8081/TCP | HTTP | None | None | Readiness probe to indicate operator is ready to accept requests |

### gRPC Services

No gRPC services exposed.

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| Kubernetes | 1.25+ | Yes | Runtime platform for operator and training workloads |
| controller-runtime | v0.17.2 | Yes | Kubernetes controller framework for building operators |
| Prometheus Operator | Any | No | Required for PodMonitor metrics collection |
| Volcano Scheduler | v1.8.0 | No | Optional gang scheduler for batch scheduling of training pods |
| scheduler-plugins | v0.26.7 | No | Optional gang scheduler alternative to Volcano |

### Internal ODH Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| ODH Dashboard | UI Integration | Provides user interface for creating and monitoring training jobs |
| ODH Monitoring | Metrics Collection | Collects training operator and job metrics via PodMonitor |

## Network Architecture

### Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| kubeflow-training-operator | ClusterIP | 8080/TCP | 8080 | HTTP | None | None | Internal |

### Ingress

No ingress resources. The operator is accessed internally via Kubernetes API for CRD operations.

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| Kubernetes API Server | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token | Watch CRDs, manage pods/services/configmaps |
| Training Worker Pods | 23456/TCP (default) | TCP | None | None | Inter-worker communication for PyTorch distributed training |
| Container Registry | 443/TCP | HTTPS | TLS 1.2+ | Pull Secrets | Pull training container images |

## Security

### RBAC - Cluster Roles

| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|
| kubeflow-training-operator | "" | pods | create, delete, get, list, patch, update, watch |
| kubeflow-training-operator | "" | pods/exec | create |
| kubeflow-training-operator | "" | services | create, delete, get, list, watch |
| kubeflow-training-operator | "" | configmaps | create, list, update, watch |
| kubeflow-training-operator | "" | events | create, delete, get, list, patch, update, watch |
| kubeflow-training-operator | "" | serviceaccounts | create, get, list, watch |
| kubeflow-training-operator | kubeflow.org | pytorchjobs, tfjobs, mpijobs, mxjobs, xgboostjobs, paddlejobs | create, delete, get, list, patch, update, watch |
| kubeflow-training-operator | kubeflow.org | pytorchjobs/status, tfjobs/status, mpijobs/status, mxjobs/status, xgboostjobs/status, paddlejobs/status | get, patch, update |
| kubeflow-training-operator | kubeflow.org | pytorchjobs/finalizers, tfjobs/finalizers, mpijobs/finalizers, mxjobs/finalizers, xgboostjobs/finalizers, paddlejobs/finalizers | update |
| kubeflow-training-operator | rbac.authorization.k8s.io | roles, rolebindings | create, list, update, watch |
| kubeflow-training-operator | autoscaling | horizontalpodautoscalers | create, delete, get, list, patch, update, watch |
| kubeflow-training-operator | scheduling.volcano.sh | podgroups | create, delete, get, list, patch, update, watch |
| kubeflow-training-operator | scheduling.x-k8s.io | podgroups | create, delete, get, list, patch, update, watch |
| kubeflow-training-edit | kubeflow.org | mpijobs, tfjobs, pytorchjobs, mxjobs, xgboostjobs, paddlejobs | create, delete, get, list, patch, update, watch |
| kubeflow-training-edit | kubeflow.org | mpijobs/status, tfjobs/status, pytorchjobs/status, mxjobs/status, xgboostjobs/status, paddlejobs/status | get |
| kubeflow-training-view | kubeflow.org | mpijobs, tfjobs, pytorchjobs, mxjobs, xgboostjobs, paddlejobs | get, list, watch |
| kubeflow-training-view | kubeflow.org | mpijobs/status, tfjobs/status, pytorchjobs/status, mxjobs/status, xgboostjobs/status, paddlejobs/status | get |

### RBAC - Role Bindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| kubeflow-training-operator | opendatahub | kubeflow-training-operator (ClusterRole) | kubeflow-training-operator |
| kubeflow-training-edit | N/A (ClusterRole) | Aggregates to edit and admin roles | N/A |
| kubeflow-training-view | N/A (ClusterRole) | Aggregates to view role | N/A |

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| Training job pull secrets | kubernetes.io/dockerconfigjson | Pull training container images from registries | User/Admin | No |
| Training job service account tokens | kubernetes.io/service-account-token | Authenticate training pods to Kubernetes API | Kubernetes | Yes |

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| Kubernetes API (CRD operations) | All | ServiceAccount Token (JWT) | Kubernetes API Server | RBAC ClusterRole kubeflow-training-operator |
| /metrics | GET | None (internal only) | Network (ClusterIP) | Accessible only within cluster |
| /healthz, /readyz | GET | None (internal only) | Network (ClusterIP) | Accessible only within cluster |

### Container Security

| Aspect | Configuration | Purpose |
|--------|---------------|---------|
| Base Image | registry.access.redhat.com/ubi9/ubi-minimal:latest | Red Hat Universal Base Image with security updates |
| Build Image | registry.access.redhat.com/ubi9/go-toolset:1.21 | FIPS-compliant Go toolchain |
| FIPS Mode | Enabled (-tags strictfipsruntime) | Ensures cryptographic operations use FIPS 140-2 validated modules |
| Non-root User | 65532:65532 | Runs as unprivileged user for container security |
| Privilege Escalation | allowPrivilegeEscalation: false | Prevents container from gaining additional privileges |

## Data Flows

### Flow 1: Training Job Creation and Reconciliation

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User/Dashboard | Kubernetes API Server | 443/TCP | HTTPS | TLS 1.2+ | User credentials (token/cert) |
| 2 | Kubernetes API Server | Training Operator | N/A | Watch API | N/A | ServiceAccount Token |
| 3 | Training Operator | Kubernetes API Server | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 4 | Training Operator | Kubernetes API Server | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |

**Description**: User creates a training job CRD (e.g., PyTorchJob). The operator watches for new jobs, validates the spec, creates required pods/services, and updates the job status.

### Flow 2: Distributed Training Communication (PyTorch)

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | PyTorch Master Pod | PyTorch Worker Pods | 23456/TCP | TCP | None | None |
| 2 | PyTorch Worker Pods | PyTorch Master Pod | 23456/TCP | TCP | None | None |
| 3 | PyTorch Worker Pods | PyTorch Worker Pods | 23456/TCP | TCP | None | None |

**Description**: Distributed PyTorch training communication using torchrun/torch.distributed. Master coordinates with workers for gradient synchronization.

### Flow 3: Metrics Collection

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Prometheus | Training Operator | 8080/TCP | HTTP | None | None |

**Description**: Prometheus scrapes metrics from the training operator's /metrics endpoint using the PodMonitor configuration.

### Flow 4: Gang Scheduling with Volcano

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Training Operator | Kubernetes API Server | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 2 | Volcano Scheduler | Kubernetes API Server | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |

**Description**: When gang scheduling is enabled, the operator creates PodGroups for training jobs, and Volcano scheduler ensures all pods in a group are scheduled together.

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| Kubernetes API Server | REST API | 443/TCP | HTTPS | TLS 1.2+ | Create/manage pods, services, CRDs; watch for changes |
| Prometheus | HTTP Scrape | 8080/TCP | HTTP | None | Metrics collection for training jobs and operator health |
| Volcano Scheduler | CRD (PodGroup) | 443/TCP | HTTPS | TLS 1.2+ | Gang scheduling for batch job allocation |
| scheduler-plugins | CRD (PodGroup) | 443/TCP | HTTPS | TLS 1.2+ | Alternative gang scheduling implementation |
| ODH Dashboard | Kubernetes API | 443/TCP | HTTPS | TLS 1.2+ | UI for creating/monitoring training jobs |
| Container Registry | Image Pull | 443/TCP | HTTPS | TLS 1.2+ | Pull training container images and operator image |

## Deployment Architecture

### Operator Deployment

| Aspect | Configuration | Notes |
|--------|---------------|-------|
| Replicas | 1 | Single active controller (leader election not enabled by default in RHOAI) |
| Resource Requests | Not specified | Should be configured based on cluster size and job count |
| Resource Limits | Not specified | Should be configured to prevent resource exhaustion |
| Update Strategy | RollingUpdate (default) | Ensures availability during updates |
| Service Account | kubeflow-training-operator | Dedicated SA with ClusterRole permissions |
| Security Context | Non-root (65532), no privilege escalation | Follows security best practices |
| Istio Sidecar | Disabled (sidecar.istio.io/inject: "false") | Operator doesn't require service mesh |

### Kustomize Structure

| Layer | Path | Purpose |
|-------|------|---------|
| Base | manifests/base | Core operator resources (deployment, service, RBAC, CRDs) |
| RHOAI Overlay | manifests/rhoai | RHOAI-specific configuration with ODH namespace and image |
| Kubeflow Overlay | manifests/overlays/kubeflow | Kubeflow-specific RBAC aggregation labels |
| Standalone Overlay | manifests/overlays/standalone | Minimal standalone deployment |

### Configuration Parameters

| Parameter | Default | Purpose |
|-----------|---------|---------|
| metrics-bind-address | :8080 | Address for Prometheus metrics endpoint |
| health-probe-bind-address | :8081 | Address for health and readiness probes |
| enable-scheme | All | Comma-separated list of enabled job types (tfjob, pytorchjob, etc.) |
| gang-scheduler-name | "" | Gang scheduler to use (volcano or scheduler-plugins) |
| namespace | "" | Namespace to monitor (empty = all namespaces) |
| controller-threads | 1 | Number of worker threads per controller |
| pytorch-init-container-image | Default | Image for PyTorch init container |
| mpi-kubectl-delivery-image | Default | Image for MPI launcher init container |

## Recent Changes

| Version | Date | Changes |
|---------|------|---------|
| 4b4e3bb4 | 2024-10-01 | - CARRY: training-operator manifests kustomize v5 upgrade |
| b5256bed | 2024-10-01 | - CARRY: Update manifests to use ODH KFTO image |
| e98b0531 | 2024-10-01 | - PATCH: Update go to 1.21 (#11) |
| a466bc86 | 2024-10-01 | - CARRY: add separate file for RHOAI build and update multarch base image |
| a842690b | 2024-10-01 | - CARRY: ODH Image build actions (#4) |
| ae9ad659 | 2024-10-01 | - CARRY: Disable SFTtrainer e2e test (#7) |
| b3cc7906 | 2024-05-23 | - CARRY: Add RHOAI manifests (#3) |
| 700e8e35 | 2024-05-23 | - CARRY: implement e2e happy path (#2) |
| a08246d3 | 2024-04-03 | - Remove Dockerfile.ppc64le of pytorch example (#2042) |
| 21f25ce8 | 2024-03-30 | - Upgrade PyTorchJob examples to PyTorch v2 (#2024) |
| fb35949c | 2024-03-28 | - Support K8s v1.29 and Drop K8s v1.26 (#2039) |
| bba9af4d | 2024-03-28 | - Support K8s v1.28 and Drop K8s v1.25 (#2038) |
| bf41a680 | 2024-03-25 | - Bump google.golang.org/protobuf from 1.30.0 to 1.33.0 (#2029) |
| b7e0dbc0 | 2024-03-20 | - fix: Upgrade controller-gen to v0.14.0 (#2026) |
| bb8bba00 | 2024-03-15 | - Modify LLM Trainer to support BERT and Tiny LLaMA (#2031) |
| 8433edcf | 2024-03-13 | - Support arm64 for Hugging Face trainer (#2028) |
| 395e8cab | 2024-03-12 | - Add Fine-Tune BERT LLM Example (#2021) |

## Operational Considerations

### Monitoring and Observability

**Metrics Available**:
- Job creation/completion/failure counts per framework
- Active job count
- Pod creation/deletion metrics
- Reconciliation duration and error rates
- Controller queue depth and processing time

**Health Checks**:
- Liveness: `/healthz` on port 8081 - checks if controller manager is running
- Readiness: `/readyz` on port 8081 - checks if controller is ready to process jobs

**Logging**:
- Structured logging using zap logger
- Configurable log levels via command-line flags
- Job reconciliation events logged with job name, namespace, and action

### Troubleshooting

**Common Issues**:
1. **Jobs stuck in pending**: Check pod events, resource quotas, and gang scheduler status
2. **Worker pods fail to communicate**: Verify network policies allow pod-to-pod traffic on job ports
3. **High reconciliation latency**: Increase controller-threads or check API server performance
4. **CRD validation errors**: Ensure job spec matches CRD schema (check webhook logs if enabled)

**Debug Commands**:
```bash
# Check operator logs
kubectl logs -n opendatahub deployment/kubeflow-training-operator

# Describe training job
kubectl describe pytorchjob <job-name> -n <namespace>

# Check created pods
kubectl get pods -l training.kubeflow.org/job-name=<job-name>

# View metrics
kubectl port-forward -n opendatahub svc/kubeflow-training-operator 8080:8080
curl localhost:8080/metrics
```

### Scaling Considerations

**Operator Scaling**:
- Single replica with leader election disabled (RHOAI default)
- Vertical scaling: Increase memory/CPU for large clusters with many jobs
- Horizontal scaling: Enable leader election for HA (requires config change)

**Training Job Scaling**:
- PyTorch: Supports elastic training with HPA-based worker scaling
- Gang scheduling: Use Volcano/scheduler-plugins for better resource utilization
- Resource quotas: Implement namespace quotas to prevent resource exhaustion
- Multi-tenancy: Use namespace isolation for different teams/projects

### Backup and Recovery

**Backup Requirements**:
- CRD definitions (included in manifests)
- Training job CRs (user-created, should be in GitOps or backed up)
- No persistent state in operator itself

**Recovery Procedure**:
1. Redeploy operator using kustomize manifests
2. Operator will reconcile existing training job CRs
3. In-progress jobs may need manual cleanup/restart

### Upgrade Path

**Version Compatibility**:
- CRD API version: v1 (stable)
- Kubernetes: 1.25+ required
- Backward compatibility: v1 API is stable and backward compatible

**Upgrade Process**:
1. Review CHANGELOG for breaking changes
2. Update CRDs first: `kubectl apply -k manifests/rhoai` (or use ODH operator)
3. Operator pods will automatically update via deployment
4. Existing jobs continue running; new jobs use updated logic
5. Test with sample jobs before production rollout

## Known Limitations

1. **No built-in model versioning**: Operator focuses on job execution, not model management
2. **Limited GPU sharing**: Workers typically require exclusive GPU access
3. **No automatic retry with backoff**: Failed jobs require manual restart or external orchestration
4. **Single namespace watch**: RHOAI config monitors opendatahub namespace only
5. **No built-in cost tracking**: Resource usage monitoring requires external tools
6. **Framework version coupling**: Some features require specific framework versions (e.g., PyTorch elastic training)

## Future Enhancements

Based on upstream Kubeflow development:
1. **LLM fine-tuning support**: Enhanced support for Hugging Face transformers and BERT
2. **Improved autoscaling**: Better integration with cluster autoscaler and KEDA
3. **Multi-cluster training**: Support for training across multiple Kubernetes clusters
4. **Advanced scheduling**: Better integration with topology-aware scheduling
5. **Training templates**: Reusable job templates with parameter substitution
6. **Integration with experiment tracking**: Built-in support for MLflow, Weights & Biases
