# Component: Kubeflow Training Operator

## Metadata
- **Repository**: https://github.com/red-hat-data-services/training-operator
- **Version**: 1.9.0 (commit: c291ee50)
- **Branch**: rhoai-3.0
- **Distribution**: RHOAI
- **Languages**: Go
- **Deployment Type**: Kubernetes Operator

## Purpose
**Short**: Kubernetes-native operator for distributed training of machine learning models across multiple frameworks (PyTorch, TensorFlow, JAX, XGBoost, MPI, PaddlePaddle).

**Detailed**: The Kubeflow Training Operator is a Kubernetes controller that manages the lifecycle of distributed machine learning training jobs. It provides Custom Resource Definitions (CRDs) for defining training workloads using popular ML frameworks including PyTorch, TensorFlow, JAX, XGBoost, MPI, and PaddlePaddle. The operator automates the creation and management of pods, services, and other Kubernetes resources required for distributed training, handles job scheduling with optional gang scheduling support (Volcano/scheduler-plugins), implements elastic training for PyTorch with autoscaling capabilities, and provides validation webhooks to ensure job specifications are valid. It enables data scientists to run scalable distributed training workloads and high-performance computing (HPC) tasks on Kubernetes without managing low-level infrastructure details.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| training-operator | Go controller manager | Main operator process that reconciles training job CRDs and manages their lifecycle |
| pytorchjob-controller | Reconciler | Manages PyTorchJob resources, creates pods/services for master and worker nodes |
| tfjob-controller | Reconciler | Manages TFJob resources for TensorFlow distributed training |
| mpijob-controller | Reconciler | Manages MPIJob resources for MPI-based HPC and distributed training |
| xgboostjob-controller | Reconciler | Manages XGBoostJob resources for distributed XGBoost training |
| jaxjob-controller | Reconciler | Manages JAXJob resources for JAX-based distributed training |
| paddlejob-controller | Reconciler | Manages PaddleJob resources for PaddlePaddle distributed training |
| validation-webhooks | Admission controller | Validates job specifications on CREATE/UPDATE operations |
| python-sdk | Client library | Python SDK (kubeflow-training) for programmatic job creation |

## APIs Exposed

### Custom Resource Definitions (CRDs)

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| kubeflow.org | v1 | PyTorchJob | Namespaced | Defines distributed PyTorch training jobs with master/worker topology |
| kubeflow.org | v1 | TFJob | Namespaced | Defines distributed TensorFlow training jobs with parameter server/worker topology |
| kubeflow.org | v1 | MPIJob | Namespaced | Defines MPI-based distributed training and HPC jobs with launcher/worker topology |
| kubeflow.org | v1 | XGBoostJob | Namespaced | Defines distributed XGBoost training jobs with master/worker topology |
| kubeflow.org | v1 | JAXJob | Namespaced | Defines distributed JAX training jobs for neural network training |
| kubeflow.org | v1 | PaddleJob | Namespaced | Defines distributed PaddlePaddle training jobs |

### HTTP Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /metrics | GET | 8080/TCP | HTTP | None | None | Prometheus metrics for operator performance monitoring |
| /healthz | GET | 8081/TCP | HTTP | None | None | Liveness probe endpoint for operator health |
| /readyz | GET | 8081/TCP | HTTP | None | None | Readiness probe endpoint for operator startup |
| /validate-kubeflow-org-v1-pytorchjob | POST | 9443/TCP | HTTPS | TLS 1.2+ | mTLS | Validation webhook for PyTorchJob CREATE/UPDATE |
| /validate-kubeflow-org-v1-tfjob | POST | 9443/TCP | HTTPS | TLS 1.2+ | mTLS | Validation webhook for TFJob CREATE/UPDATE |
| /validate-kubeflow-org-v1-mpijob | POST | 9443/TCP | HTTPS | TLS 1.2+ | mTLS | Validation webhook for MPIJob CREATE/UPDATE |
| /validate-kubeflow-org-v1-xgboostjob | POST | 9443/TCP | HTTPS | TLS 1.2+ | mTLS | Validation webhook for XGBoostJob CREATE/UPDATE |
| /validate-kubeflow-org-v1-jaxjob | POST | 9443/TCP | HTTPS | TLS 1.2+ | mTLS | Validation webhook for JAXJob CREATE/UPDATE |
| /validate-kubeflow-org-v1-paddlejob | POST | 9443/TCP | HTTPS | TLS 1.2+ | mTLS | Validation webhook for PaddleJob CREATE/UPDATE |

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| Kubernetes | 1.27+ | Yes | Container orchestration platform for running operator and training jobs |
| cert-manager | Any | No | Automatic TLS certificate generation for webhooks (manual cert creation alternative) |
| Volcano | Any | No | Gang scheduling for coordinated pod scheduling across training job replicas |
| scheduler-plugins | Any | No | Alternative gang scheduling implementation for coordinated pod scheduling |
| Prometheus | Any | No | Metrics collection from operator for monitoring and alerting |

### Internal ODH Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| opendatahub-operator | Deployment | Deploys and manages training-operator as part of ODH platform |
| dashboard | UI | Provides user interface for viewing and managing training jobs |

## Network Architecture

### Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| training-operator (base) | ClusterIP | 8080/TCP | 8080 | HTTP | None | None | Internal |
| training-operator (base) | ClusterIP | 443/TCP | 9443 | HTTPS | TLS 1.2+ | mTLS | Internal |
| kubeflow-training-operator (RHOAI) | ClusterIP | 443/TCP | 9443 | HTTPS | TLS 1.2+ | mTLS | Internal |
| &lt;job-name&gt;-master-0 | ClusterIP | 23456/TCP | 23456 | TCP | None | None | Internal (PyTorch worker-to-master) |
| &lt;job-name&gt;-worker-N | ClusterIP | 23456/TCP | 23456 | TCP | None | None | Internal (PyTorch inter-worker) |

### Ingress

No ingress resources defined. Operator is accessed internally within the cluster.

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token | Watch CRDs, create/update pods, services, configmaps |
| Container Registries | 443/TCP | HTTPS | TLS 1.2+ | Image Pull Secrets | Pull training job container images and init containers |
| S3/Object Storage | 443/TCP | HTTPS | TLS 1.2+ | Credentials | Training jobs download datasets and save model checkpoints |

## Security

### RBAC - Cluster Roles

| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|
| training-operator | "" | pods | create, delete, get, list, patch, update, watch |
| training-operator | "" | pods/exec | create |
| training-operator | "" | services | create, delete, get, list, watch |
| training-operator | "" | events | create, delete, get, list, patch, update, watch |
| training-operator | "" | configmaps | create, list, update, watch |
| training-operator | "" | secrets | get, list, update, watch |
| training-operator | "" | serviceaccounts | create, get, list, watch |
| training-operator | kubeflow.org | pytorchjobs, pytorchjobs/status, pytorchjobs/finalizers | create, delete, get, list, patch, update, watch |
| training-operator | kubeflow.org | tfjobs, tfjobs/status, tfjobs/finalizers | create, delete, get, list, patch, update, watch |
| training-operator | kubeflow.org | mpijobs, mpijobs/status, mpijobs/finalizers | create, delete, get, list, patch, update, watch |
| training-operator | kubeflow.org | xgboostjobs, xgboostjobs/status, xgboostjobs/finalizers | create, delete, get, list, patch, update, watch |
| training-operator | kubeflow.org | jaxjobs, jaxjobs/status, jaxjobs/finalizers | create, delete, get, list, patch, update, watch |
| training-operator | kubeflow.org | paddlejobs, paddlejobs/status, paddlejobs/finalizers | create, delete, get, list, patch, update, watch |
| training-operator | rbac.authorization.k8s.io | roles, rolebindings | create, list, update, watch |
| training-operator | autoscaling | horizontalpodautoscalers | create, delete, get, list, patch, update, watch |
| training-operator | scheduling.volcano.sh | podgroups | create, delete, get, list, patch, update, watch |
| training-operator | scheduling.x-k8s.io | podgroups | create, delete, get, list, patch, update, watch |
| training-operator | networking.k8s.io | networkpolicies | create, delete, get, list, patch, update, watch |
| training-operator | admissionregistration.k8s.io | validatingwebhookconfigurations | get, list, update, watch |
| training-edit | kubeflow.org | mpijobs, tfjobs, pytorchjobs, xgboostjobs, paddlejobs | create, delete, get, list, patch, update, watch |
| training-edit | kubeflow.org | mpijobs/status, tfjobs/status, pytorchjobs/status, xgboostjobs/status, paddlejobs/status | get |
| training-view | kubeflow.org | mpijobs, tfjobs, pytorchjobs, xgboostjobs, paddlejobs | get, list, watch |
| training-view | kubeflow.org | mpijobs/status, tfjobs/status, pytorchjobs/status, xgboostjobs/status, paddlejobs/status | get |

### RBAC - Role Bindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| training-operator | opendatahub (RHOAI) | training-operator | kubeflow-training-operator |
| training-operator | All namespaces | training-operator (ClusterRole) | training-operator (operator namespace) |

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| training-operator-webhook-cert (base) | kubernetes.io/tls | TLS certificate for webhook server | Manual or cert-manager | No (manual), Yes (cert-manager) |
| kubeflow-training-operator-webhook-cert (RHOAI) | kubernetes.io/tls | TLS certificate for webhook server in RHOAI deployment | Kustomize secretGenerator | No |

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| /validate-* webhooks | POST | mTLS client certificates | Kubernetes API Server | ValidatingWebhookConfiguration validates client certs |
| /metrics | GET | None | Application | Metrics exposed without authentication for Prometheus scraping |
| /healthz, /readyz | GET | None | Application | Health endpoints exposed without authentication for kubelet probes |
| Kubernetes API | All | ServiceAccount Token (Bearer) | Kubernetes API Server | RBAC enforces operator permissions via ClusterRole bindings |

### Container Security

- **Runs as non-root user**: UID 65532
- **Privilege escalation disabled**: `allowPrivilegeEscalation: false`
- **Read-only root filesystem**: Certificate volume mounted read-only
- **FIPS-compliant build**: Built with `GOEXPERIMENT=strictfipsruntime` for FIPS 140-2 compliance
- **Minimal base image**: Uses UBI9 minimal image to reduce attack surface

## Data Flows

### Flow 1: Training Job Creation and Execution

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User/SDK | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | User credentials (kubeconfig) |
| 2 | Kubernetes API | Validation Webhook | 9443/TCP | HTTPS | TLS 1.2+ | mTLS |
| 3 | Validation Webhook | Kubernetes API | Response | HTTPS | TLS 1.2+ | mTLS |
| 4 | Controller | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 5 | Controller | Kubernetes API (create pods) | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 6 | Controller | Kubernetes API (create services) | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 7 | Training Pod | Container Registry | 443/TCP | HTTPS | TLS 1.2+ | Image Pull Secret |
| 8 | Training Pods (workers) | Training Pod (master) | 23456/TCP | TCP | None | None (framework-specific) |

### Flow 2: Monitoring and Observability

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Prometheus | Operator Pod | 8080/TCP | HTTP | None | None |
| 2 | Controller | Kubernetes API (update status) | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 3 | User | Kubernetes API (read status) | 6443/TCP | HTTPS | TLS 1.2+ | User credentials |

### Flow 3: Gang Scheduling (Optional with Volcano/scheduler-plugins)

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Controller | Kubernetes API (create PodGroup) | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 2 | Scheduler | Kubernetes API (watch PodGroups) | 6443/TCP | HTTPS | TLS 1.2+ | Scheduler ServiceAccount |
| 3 | Scheduler | Kubernetes API (bind pods) | 6443/TCP | HTTPS | TLS 1.2+ | Scheduler ServiceAccount |

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| Kubernetes API Server | REST API (client) | 6443/TCP | HTTPS | TLS 1.2+ | Watch CRDs, manage pods/services, update job status |
| Kubernetes API Server | Admission Webhook (server) | 9443/TCP | HTTPS | TLS 1.2+ | Validate job specifications before creation |
| Prometheus | HTTP scrape | 8080/TCP | HTTP | None | Expose operator metrics for monitoring |
| Volcano Scheduler | CRD (PodGroup) | 6443/TCP | HTTPS | TLS 1.2+ | Gang scheduling for coordinated pod placement |
| scheduler-plugins | CRD (PodGroup) | 6443/TCP | HTTPS | TLS 1.2+ | Alternative gang scheduling implementation |
| Training Job Pods | Service discovery | 23456/TCP | TCP | None | Inter-pod communication for distributed training |

## Deployment Configuration

### RHOAI-Specific Configuration

- **Namespace**: opendatahub
- **Name Prefix**: kubeflow-
- **Image**: quay.io/opendatahub/training-operator:v1.9.0-odh-3
- **PyTorch Init Container**: Uses same operator image for PyTorch init container
- **Monitoring**: PodMonitor configured for Prometheus metrics scraping on port named "metrics"
- **Istio Sidecar**: Disabled (`sidecar.istio.io/inject: "false"`) to avoid interference with training pods
- **Service Configuration**: Removes port 8080 from service (metrics only exposed via PodMonitor)

### Command-Line Flags

- `--metrics-bind-address=:8080`: Prometheus metrics endpoint
- `--health-probe-bind-address=:8081`: Health and readiness probes
- `--enable-scheme`: Enable specific job types (default: all)
- `--gang-scheduler-name`: Configure gang scheduler (volcano or scheduler-plugins)
- `--namespace`: Limit operator to specific namespace (default: cluster-wide)
- `--controller-threads`: Number of worker threads per controller
- `--kube-api-qps=20`: Rate limiting for Kubernetes API calls
- `--kube-api-burst=30`: Burst allowance for Kubernetes API calls
- `--pytorch-init-container-image`: Image for PyTorch init container
- `--mpi-kubectl-delivery-image`: Image for MPI launcher init container
- `--webhook-server-port=9443`: Port for webhook server
- `--zap-log-level=2`: Logging verbosity (RHOAI default)

### Resource Requirements

Not specified in base manifests. Should be configured via Kustomize overlays based on cluster size and workload.

## Training Job Lifecycle

1. **Submission**: User creates job CRD via kubectl or Python SDK
2. **Validation**: Webhook validates job specification (replica counts, resource requests, etc.)
3. **Reconciliation**: Controller watches job, creates PodGroup (if gang scheduling enabled)
4. **Pod Creation**: Controller creates pods for each replica type (master/workers/parameter servers)
5. **Service Creation**: Controller creates headless services for pod discovery
6. **Initialization**: Init containers run (PyTorch: coordinate master selection, MPI: deliver kubectl)
7. **Training**: Main containers execute training code with framework-specific coordination
8. **Monitoring**: Controller updates job status based on pod states
9. **Completion**: Job marked as Succeeded when all pods complete successfully
10. **Cleanup**: Failed replicas restarted based on restart policy, job cleaned up after TTL

## Recent Changes

| Date | Commit | Changes |
|------|--------|---------|
| 2026-02-05 | c291ee50 | chore(deps): update registry.access.redhat.com/ubi9/ubi-minimal docker digest to 759f5f4 (#900) |
| 2026-02-04 | 6afa08e6 | chore(deps): update registry.access.redhat.com/ubi9/ubi-minimal docker digest to ecd4751 (#888) |
| 2026-01-26 | dc79794b | chore(deps): update registry.access.redhat.com/ubi9/ubi-minimal docker digest to bb08f23 (#874) |
| 2026-01-19 | de8878b6 | chore(deps): update registry.access.redhat.com/ubi9/ubi-minimal docker digest to 90bd85d (#848) |
| 2026-01-01 | 1e401ccf | chore(deps): update konflux references (#864) |
| 2026-01-01 | 59623634 | chore(deps): update konflux references (#863) |
| 2026-01-01 | 20012f3b | chore(deps): update konflux references (#862) |

## Notable Features

### PyTorch Elastic Training

- Supports elastic training with `elasticPolicy` in PyTorchJob spec
- Horizontal Pod Autoscaler (HPA) integration for dynamic worker scaling
- Automatic restart on worker failures with configurable `maxRestarts`
- Default port: 23456/TCP for worker-to-master communication

### Gang Scheduling Support

- Optional integration with Volcano or scheduler-plugins
- Creates PodGroup resources for all-or-nothing pod scheduling
- Prevents resource fragmentation in multi-tenant clusters
- Ensures all job replicas are scheduled together

### Multi-Framework Support

Each framework has dedicated controller and validation logic:
- **PyTorch**: Master/Worker topology, elastic training, custom init containers
- **TensorFlow**: Parameter Server/Worker/Chief topology
- **MPI**: Launcher/Worker topology for HPC workloads
- **XGBoost**: Master/Worker topology for distributed gradient boosting
- **JAX**: Worker topology for distributed neural network training
- **PaddlePaddle**: Master/Worker topology for PaddlePaddle framework

### Python SDK

- Package: `kubeflow-training` on PyPI
- Programmatic job creation and management
- Simplified API for data scientists
- Trainer classes for fine-tuning large language models

## Troubleshooting

### Common Issues

1. **Webhook certificate errors**: Ensure `training-operator-webhook-cert` secret exists with valid TLS cert/key
2. **Job pods not starting**: Check RBAC permissions, image pull secrets, resource quotas
3. **Pods stuck in Pending**: Enable gang scheduling if using multi-replica jobs in resource-constrained clusters
4. **Worker communication failures**: Verify service DNS resolution, network policies allow inter-pod traffic
5. **Validation failures**: Check job spec against framework-specific defaults and validation rules

### Debugging Commands

```bash
# Check operator logs
kubectl logs -n opendatahub deployment/kubeflow-training-operator

# Check job status
kubectl get pytorchjobs -A
kubectl describe pytorchjob <name> -n <namespace>

# Check created pods and services
kubectl get pods,services -l training.kubeflow.org/job-name=<job-name>

# Check webhook configuration
kubectl get validatingwebhookconfiguration validating-webhook-configuration -o yaml

# Check metrics
kubectl port-forward -n opendatahub svc/kubeflow-training-operator 8080:8080
curl http://localhost:8080/metrics
```
