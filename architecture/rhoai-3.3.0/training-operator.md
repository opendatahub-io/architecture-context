# Component: Kubeflow Training Operator

## Metadata
- **Repository**: https://github.com/red-hat-data-services/training-operator
- **Version**: v1.9.0 (git: 95ec249a)
- **Branch**: rhoai-3.3
- **Distribution**: RHOAI
- **Languages**: Go 1.25
- **Deployment Type**: Kubernetes Operator
- **Build System**: Konflux (Dockerfile.konflux)

## Purpose
**Short**: Kubernetes-native operator for distributed training and fine-tuning of machine learning models across multiple frameworks.

**Detailed**: The Kubeflow Training Operator is a Kubernetes operator that enables scalable distributed training of machine learning models using popular ML frameworks including PyTorch, TensorFlow, XGBoost, JAX, PaddlePaddle, and MPI. It provides Custom Resource Definitions (CRDs) for each framework that abstract the complexity of setting up distributed training jobs, handling worker coordination, and managing job lifecycle. The operator automatically creates and manages the underlying Kubernetes resources (Pods, Services, ConfigMaps) required for distributed training, supports elastic scaling through HorizontalPodAutoscaler integration, and can integrate with gang scheduling systems (Volcano, scheduler-plugins) for improved resource utilization. It serves data scientists by providing a declarative API for launching training jobs without requiring deep Kubernetes expertise, and supports high-performance computing (HPC) workloads through MPI integration.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| training-operator | Go Operator | Main controller that reconciles training job CRDs and manages Pod/Service lifecycle |
| PyTorchJob Controller | Reconciler | Manages PyTorch distributed training jobs (Master/Worker topology) |
| TFJob Controller | Reconciler | Manages TensorFlow distributed training jobs (Chief/Worker/PS topology) |
| XGBoostJob Controller | Reconciler | Manages XGBoost distributed training jobs |
| MPIJob Controller | Reconciler | Manages MPI-based training jobs for HPC workloads |
| JAXJob Controller | Reconciler | Manages JAX distributed training jobs |
| PaddleJob Controller | Reconciler | Manages PaddlePaddle distributed training jobs |
| Validating Webhooks | Admission Controller | Validates job specifications before creation/update for all 6 job types |
| Cert Manager | Certificate Controller | Manages TLS certificates for webhook server using open-policy-agent/cert-controller |
| Metrics Server | Prometheus Exporter | Exposes operator metrics on port 8080 |

## APIs Exposed

### Custom Resource Definitions (CRDs)

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| kubeflow.org | v1 | PyTorchJob | Namespaced | Define PyTorch distributed training jobs with Master/Worker replicas |
| kubeflow.org | v1 | TFJob | Namespaced | Define TensorFlow distributed training jobs with Chief/Worker/PS replicas |
| kubeflow.org | v1 | XGBoostJob | Namespaced | Define XGBoost distributed training jobs with Master/Worker replicas |
| kubeflow.org | v1 | MPIJob | Namespaced | Define MPI-based training jobs (Launcher/Worker topology) |
| kubeflow.org | v1 | JAXJob | Namespaced | Define JAX distributed training jobs |
| kubeflow.org | v1 | PaddleJob | Namespaced | Define PaddlePaddle distributed training jobs with Master/Worker replicas |

### HTTP Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /metrics | GET | 8080/TCP | HTTP | None | None | Prometheus metrics endpoint for operator monitoring |
| /healthz | GET | 8081/TCP | HTTP | None | None | Liveness probe endpoint |
| /readyz | GET | 8081/TCP | HTTP | None | None | Readiness probe endpoint |
| /validate-kubeflow-org-v1-pytorchjob | POST | 9443/TCP | HTTPS | TLS 1.2+ | Kubernetes API Server mTLS | Validate PyTorchJob CREATE/UPDATE operations |
| /validate-kubeflow-org-v1-tfjob | POST | 9443/TCP | HTTPS | TLS 1.2+ | Kubernetes API Server mTLS | Validate TFJob CREATE/UPDATE operations |
| /validate-kubeflow-org-v1-xgboostjob | POST | 9443/TCP | HTTPS | TLS 1.2+ | Kubernetes API Server mTLS | Validate XGBoostJob CREATE/UPDATE operations |
| /validate-kubeflow-org-v1-mpijob | POST | 9443/TCP | HTTPS | TLS 1.2+ | Kubernetes API Server mTLS | Validate MPIJob CREATE/UPDATE operations |
| /validate-kubeflow-org-v1-jaxjob | POST | 9443/TCP | HTTPS | TLS 1.2+ | Kubernetes API Server mTLS | Validate JAXJob CREATE/UPDATE operations |
| /validate-kubeflow-org-v1-paddlejob | POST | 9443/TCP | HTTPS | TLS 1.2+ | Kubernetes API Server mTLS | Validate PaddleJob CREATE/UPDATE operations |

### gRPC Services

None - operator uses HTTP/HTTPS only.

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| Kubernetes | 1.27+ | Yes | Platform for running operator and training jobs |
| controller-runtime | v0.19.1 | Yes | Kubernetes operator framework |
| Prometheus Operator | N/A | No | For metrics collection via PodMonitor |
| Volcano | v1.9.0 | No | Optional gang scheduling for improved resource efficiency |
| scheduler-plugins | v0.28.9 | No | Optional alternative gang scheduling implementation |
| cert-manager alternatives | N/A | No | Can use external cert manager instead of built-in cert-controller |

### Internal ODH Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| Prometheus | Metrics scraping | Operator exposes metrics on /metrics endpoint for observability |
| opendatahub-operator | Deployment management | Deploys and manages training-operator as a component |

## Network Architecture

### Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| training-operator | ClusterIP | 443/TCP | 9443 | HTTPS | TLS 1.2+ | Kubernetes API Server mTLS | Internal (webhook) |
| training-operator | ClusterIP | 8080/TCP | 8080 | HTTP | None | None | Internal (metrics) |

**Note**: The RHOAI overlay removes the metrics port from the Service definition via patch. Metrics are collected directly from pods via PodMonitor.

### Ingress

No Ingress resources - operator is internal-only.

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| Kubernetes API Server | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount token | Watch and manage CRDs, Pods, Services, Events, ConfigMaps, NetworkPolicies |
| Training job Pods | Dynamic | TCP/UDP | Framework-dependent | None | Created by operator but communication is framework-specific (e.g., PyTorch uses port 23456) |

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
| training-operator | admissionregistration.k8s.io | validatingwebhookconfigurations | get, list, update, watch |
| training-operator | autoscaling | horizontalpodautoscalers | create, delete, get, list, patch, update, watch |
| training-operator | kubeflow.org | pytorchjobs, tfjobs, xgboostjobs, mpijobs, jaxjobs, paddlejobs | create, delete, get, list, patch, update, watch |
| training-operator | kubeflow.org | pytorchjobs/status, tfjobs/status, xgboostjobs/status, mpijobs/status, jaxjobs/status, paddlejobs/status | get, patch, update |
| training-operator | kubeflow.org | pytorchjobs/finalizers, tfjobs/finalizers, xgboostjobs/finalizers, mpijobs/finalizers, jaxjobs/finalizers, paddlejobs/finalizers | update |
| training-operator | rbac.authorization.k8s.io | roles, rolebindings | create, list, update, watch |
| training-operator | scheduling.volcano.sh | podgroups | create, delete, get, list, patch, update, watch |
| training-operator | scheduling.x-k8s.io | podgroups | create, delete, get, list, patch, update, watch |
| training-operator | networking.k8s.io | networkpolicies | create, delete, get, list, patch, update, watch |

**Note**: Per CVE-2026-2353 fix, secrets access was restricted to namespace-scoped Role (not ClusterRole).

### RBAC - Role Bindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| training-operator | opendatahub | ClusterRole/training-operator | training-operator |
| training-operator-webhook | opendatahub | Role/training-operator-webhook | training-operator |

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| training-operator-webhook-cert | kubernetes.io/tls | TLS certificate for validating webhook server | cert-controller (built-in) | Yes |

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| /validate-kubeflow-org-v1-* | POST | Kubernetes API Server mTLS | ValidatingWebhookConfiguration | Kubernetes admission control |
| /metrics | GET | None | Service/PodMonitor | Cluster-internal only (ClusterIP) |
| /healthz, /readyz | GET | None | Kubelet | Cluster-internal only |
| Kubernetes API | GET, LIST, WATCH, CREATE, UPDATE, PATCH, DELETE | ServiceAccount token (training-operator) | Kubernetes RBAC | ClusterRole/Role permissions |

## Data Flows

### Flow 1: Training Job Submission

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User/Client | Kubernetes API Server | 443/TCP | HTTPS | TLS 1.3 | User credentials (kubeconfig) |
| 2 | Kubernetes API Server | training-operator webhook | 9443/TCP | HTTPS | TLS 1.2+ | API Server mTLS |
| 3 | training-operator webhook | Kubernetes API Server | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount token |
| 4 | training-operator controller | Kubernetes API Server (watch) | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount token |
| 5 | training-operator controller | Kubernetes API Server (create Pods/Services) | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount token |

### Flow 2: Metrics Collection

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Prometheus | training-operator Pod | 8080/TCP | HTTP | None | None |

### Flow 3: Health Monitoring

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Kubelet | training-operator Pod | 8081/TCP | HTTP | None | None |

### Flow 4: Distributed Training (PyTorch Example)

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Worker Pod | Master Pod | 23456/TCP | TCP | Framework-dependent (typically plaintext) | None |
| 2 | Master Pod | Worker Pod | Dynamic | TCP | Framework-dependent | None |

**Note**: Training pods communicate using framework-specific protocols. The operator creates Services to enable pod discovery but does not enforce encryption on training communication.

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| Kubernetes API Server | REST API | 443/TCP | HTTPS | TLS 1.2+ | Resource management (CRUD operations on Pods, Services, Jobs, etc.) |
| Prometheus | Metrics scraping | 8080/TCP | HTTP | None | Operator health and performance monitoring |
| Volcano Scheduler | API (optional) | 443/TCP | HTTPS | TLS 1.2+ | Gang scheduling integration for PodGroups |
| scheduler-plugins (optional) | API | 443/TCP | HTTPS | TLS 1.2+ | Alternative gang scheduling implementation |
| cert-controller | In-process library | N/A | N/A | N/A | TLS certificate generation and rotation for webhooks |

## Recent Changes

| Version | Date | Changes |
|---------|------|---------|
| 95ec249a | 2026-03 | - Update registry.access.redhat.com/ubi9/go-toolset:1.25 docker digest to 3cdf0d1<br>- Dependency updates for UBI base images |
| b1383aef | 2026-03 | - Update go-toolset digest |
| c2ab68d6 | 2026-02 | - Update ubi-minimal base image digest |
| 28ecb404 | 2026-02 | - Fix: use multi-arch manifest list digest for go-toolset |
| d2991064 | 2026-02 | - Update go-toolset digest |
| b0094a65 | 2026-01 | - **CVE-2026-2353**: Restrict secrets RBAC to namespace-scoped Role |
| 61c7d875 | 2025-12 | - **CVE-2025-61726**: Upgrade Go version to 1.25 |

## Deployment Configuration

### RHOAI-Specific Configuration

The RHOAI deployment uses the `manifests/rhoai` kustomization overlay which:

1. **Namespace**: Deploys to `opendatahub` namespace
2. **Name Prefix**: Adds `kubeflow-` prefix to all resources
3. **Image Override**: Uses ConfigMap `rhoai-config` to inject the RHOAI-built container image
4. **Metrics**: Removes metrics port from Service, relies on PodMonitor for direct pod scraping
5. **Monitoring**: Includes PodMonitor resource for Prometheus Operator integration
6. **Labels**: Adds standard app.kubernetes.io labels (component: controller, name: training-operator)

### Configuration Parameters

Key flags available in the operator (from main.go):

| Flag | Default | Purpose |
|------|---------|---------|
| --metrics-bind-address | :8080 | Metrics endpoint address |
| --health-probe-bind-address | :8081 | Health probe address |
| --enable-scheme | all | Enable specific job types (tfjob, pytorchjob, etc.) |
| --gang-scheduler-name | "" | Gang scheduler to use (volcano, scheduler-plugins, or custom) |
| --namespace | "" | Namespace to watch (empty = cluster-wide) |
| --controller-threads | 1 | Number of worker threads per controller |
| --kube-api-qps | 20 | QPS limit for Kubernetes API client |
| --kube-api-burst | 30 | Burst limit for Kubernetes API client |
| --webhook-server-port | 9443 | Webhook server listening port |

### Resource Defaults

Default ports and values used by training jobs (from API types):

| Framework | Default Port | Container Name | Restart Policy |
|-----------|--------------|----------------|----------------|
| PyTorch | 23456/TCP | pytorch | OnFailure |
| TensorFlow | N/A | tensorflow | Never |
| XGBoost | 9999/TCP | xgboost | Never |
| MPI | N/A | mpi | Never |

## Security Posture

### Threat Model

1. **Webhook Security**: Webhook server uses TLS certificates to prevent MITM attacks during admission control. Certificates are auto-rotated by cert-controller.
2. **RBAC Least Privilege**: Secrets access restricted to namespace scope (not cluster-wide) per CVE-2026-2353.
3. **No Network Policies**: Operator does not enforce NetworkPolicies on training pods by default, but has RBAC to create them if configured.
4. **Training Pod Security**: Training pods run with user-specified security context. Operator deployment runs as non-root (UID 65532).
5. **No Service Mesh**: Operator explicitly disables Istio sidecar injection (`sidecar.istio.io/inject: "false"`) to avoid interference with webhook server.

### Known Security Considerations

1. **Plaintext Training Communication**: Framework-to-framework communication (e.g., PyTorch workers) typically uses plaintext protocols. Users should configure network isolation at the cluster level if required.
2. **No Built-in Encryption**: Operator does not enforce encryption on training data or model parameters. Users must implement this at the application layer.
3. **Secrets in Job Specs**: Users may include secrets in job specifications (e.g., for S3 access). These should use Kubernetes Secrets, not plaintext.

## Operational Notes

### High Availability

- Operator supports leader election (disabled by default, enable with `--leader-elect=true`)
- Single replica deployment in base configuration
- Stateless operation - operator can be restarted without affecting running training jobs

### Monitoring

Key metrics exposed (partial list):
- Controller queue depth and processing latency
- Reconciliation errors and retries
- Webhook latency and errors
- Active jobs by type and status

### Logging

- Uses structured logging (zap) with configurable log levels
- Logs include correlation IDs for tracking job lifecycle
- Development mode enabled by default

### Scaling Considerations

1. **Controller Threads**: Default 1 thread per controller. Increase `--controller-threads` for high job volume.
2. **API QPS**: Default 20 QPS to Kubernetes API. Increase for large clusters with many concurrent jobs.
3. **Namespace Scoping**: Use `--namespace` flag to limit operator scope and reduce API server load.

### Known Limitations

1. **Single Namespace Jobs**: Each training job and its pods must be in the same namespace
2. **Framework Version Lock-in**: Job specifications are tightly coupled to ML framework versions
3. **No Multi-Cluster**: Operator manages jobs in a single Kubernetes cluster only
4. **Gang Scheduling Optional**: Requires separate installation of Volcano or scheduler-plugins

## References

- **Upstream Documentation**: https://www.kubeflow.org/docs/components/training/
- **API Documentation**: `docs/api/kubeflow.org_v1_generated.asciidoc` in repository
- **Python SDK**: https://pypi.org/project/kubeflow-training/
- **Examples**: `examples/` directory contains sample jobs for all frameworks
- **Contributing Guide**: `CONTRIBUTING.md` in repository
- **Changelog**: `CHANGELOG.md` in repository
