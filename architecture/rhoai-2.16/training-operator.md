# Component: Training Operator

## Metadata
- **Repository**: https://github.com/red-hat-data-services/training-operator.git
- **Version**: v-2160-133-gdf4cc51a
- **Branch**: rhoai-2.16
- **Distribution**: RHOAI
- **Languages**: Go 1.25
- **Deployment Type**: Kubernetes Operator
- **Namespace**: opendatahub

## Purpose
**Short**: Kubernetes-native operator for scalable distributed training of machine learning models across multiple frameworks including PyTorch, TensorFlow, XGBoost, MPI, MXNet, and PaddlePaddle.

**Detailed**: The Kubeflow Training Operator is a unified Kubernetes operator that provides Custom Resource Definitions (CRDs) and controllers for orchestrating distributed machine learning training jobs. It enables data scientists to run scalable training workloads on Kubernetes using industry-standard ML frameworks without needing deep Kubernetes expertise. The operator manages the lifecycle of training jobs including pod creation, service discovery, failure handling, and status reporting. It supports advanced features like elastic training for PyTorch (with HPA integration), gang scheduling for multi-pod coordination (via Volcano or scheduler-plugins), and various restart policies. The operator consolidates what were previously separate operators for each framework into a single, maintainable codebase.

The operator reconciles training job CRDs by creating and managing the necessary Kubernetes resources (pods, services, configmaps, roles) and coordinating distributed training environments with proper networking between master/worker nodes. It integrates with Prometheus for metrics collection and supports both standalone deployments and integration within the broader Open Data Hub/RHOAI platform.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| training-operator | Go Binary (manager) | Main controller process that reconciles training job CRDs and manages lifecycle |
| PyTorchJob Controller | Reconciler | Manages PyTorch distributed training jobs with master/worker topology |
| TFJob Controller | Reconciler | Manages TensorFlow distributed training jobs with PS/worker/chief topology |
| MPIJob Controller | Reconciler | Manages MPI-based training jobs with launcher/worker topology |
| XGBoostJob Controller | Reconciler | Manages XGBoost distributed training jobs |
| MXNetJob Controller | Reconciler | Manages Apache MXNet distributed training jobs |
| PaddleJob Controller | Reconciler | Manages PaddlePaddle distributed training jobs |
| PodControl | Resource Controller | Creates and manages pods for training job replicas |
| ServiceControl | Resource Controller | Creates headless services for training pod discovery |
| Gang Scheduling Integration | Optional Module | Integrates with Volcano or scheduler-plugins for all-or-nothing pod scheduling |
| Metrics Server | HTTP Server | Exposes Prometheus metrics on port 8080 |
| Health Probes | HTTP Server | Exposes healthz/readyz endpoints on port 8081 |
| Webhook Server | HTTPS Server | Optional webhook server on port 9443 (not enabled in RHOAI) |

## APIs Exposed

### Custom Resource Definitions (CRDs)

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| kubeflow.org | v1 | PyTorchJob | Namespaced | Defines PyTorch distributed training job with master/worker replicas (default port 23456) |
| kubeflow.org | v1 | TFJob | Namespaced | Defines TensorFlow distributed training job with PS/worker/chief/evaluator replicas (default port 2222) |
| kubeflow.org | v1 | MPIJob | Namespaced | Defines MPI-based training job with launcher/worker topology |
| kubeflow.org | v1 | XGBoostJob | Namespaced | Defines XGBoost distributed training job with master/worker replicas |
| kubeflow.org | v1 | MXJob | Namespaced | Defines Apache MXNet training job with server/worker/scheduler replicas |
| kubeflow.org | v1 | PaddleJob | Namespaced | Defines PaddlePaddle training job with master/worker replicas |

### HTTP Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /metrics | GET | 8080/TCP | HTTP | None | None | Prometheus metrics endpoint for operator telemetry |
| /healthz | GET | 8081/TCP | HTTP | None | None | Liveness probe endpoint |
| /readyz | GET | 8081/TCP | HTTP | None | None | Readiness probe endpoint |

### gRPC Services

None - operator uses standard Kubernetes API for all communication.

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| Kubernetes | 1.25+ | Yes | Platform for running operator and training workloads |
| controller-runtime | v0.17.2 | Yes | Kubernetes controller framework |
| Prometheus Operator | N/A | No | For PodMonitor-based metrics scraping |
| Volcano | v1.8.0 | No | Optional gang scheduling support for multi-pod coordination |
| scheduler-plugins | v0.26.7 | No | Optional gang scheduling support (alternative to Volcano) |

### Internal ODH/RHOAI Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| odh-operator / rhoai-operator | CRD Management | Deploys and configures training-operator via DSC/DSCI |
| User Workload Monitoring | PodMonitor | Scrapes metrics from training-operator |
| OpenShift Monitoring | ServiceAccount/RBAC | Aggregates training job RBAC to edit/view cluster roles |

## Network Architecture

### Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| kubeflow-training-operator | ClusterIP | 8080/TCP | 8080 | HTTP | None | None | Internal |

### Training Job Services (Created Dynamically)

| Service Pattern | Type | Port | Protocol | Encryption | Auth | Exposure |
|----------------|------|------|----------|------------|------|----------|
| {jobname}-{replicatype}-{index} | Headless ClusterIP | Framework-specific | TCP | None | None | Internal (namespace-scoped) |

**Service Creation Notes**:
- PyTorchJob: Creates headless services on port 23456 for master/worker communication
- TFJob: Creates headless services on port 2222 for PS/worker/chief communication
- Services enable DNS-based discovery for distributed training coordination
- Service names follow pattern: `{job-name}-{replica-type}-{replica-index}`

### Ingress

None - operator does not expose external ingress. Training jobs may create their own ingress if needed.

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token | Watch/reconcile training job CRDs, manage pods/services |
| Container Registry | 443/TCP | HTTPS | TLS 1.2+ | Pull Secrets | Pull training container images |
| Volcano API | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token | Manage PodGroup resources (if gang scheduling enabled) |

## Security

### RBAC - Cluster Roles

| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|
| kubeflow-training-operator | "" | configmaps | create, list, update, watch |
| kubeflow-training-operator | "" | events | create, delete, get, list, patch, update, watch |
| kubeflow-training-operator | "" | pods | create, delete, get, list, patch, update, watch |
| kubeflow-training-operator | "" | pods/exec | create |
| kubeflow-training-operator | "" | serviceaccounts | create, get, list, watch |
| kubeflow-training-operator | "" | services | create, delete, get, list, watch |
| kubeflow-training-operator | autoscaling | horizontalpodautoscalers | create, delete, get, list, patch, update, watch |
| kubeflow-training-operator | kubeflow.org | pytorchjobs, pytorchjobs/status, pytorchjobs/finalizers | create, delete, get, list, patch, update, watch |
| kubeflow-training-operator | kubeflow.org | tfjobs, tfjobs/status, tfjobs/finalizers | create, delete, get, list, patch, update, watch |
| kubeflow-training-operator | kubeflow.org | mpijobs, mpijobs/status, mpijobs/finalizers | create, delete, get, list, patch, update, watch |
| kubeflow-training-operator | kubeflow.org | xgboostjobs, xgboostjobs/status, xgboostjobs/finalizers | create, delete, get, list, patch, update, watch |
| kubeflow-training-operator | kubeflow.org | mxjobs, mxjobs/status, mxjobs/finalizers | create, delete, get, list, patch, update, watch |
| kubeflow-training-operator | kubeflow.org | paddlejobs, paddlejobs/status, paddlejobs/finalizers | create, delete, get, list, patch, update, watch |
| kubeflow-training-operator | rbac.authorization.k8s.io | roles, rolebindings | create, list, update, watch |
| kubeflow-training-operator | scheduling.volcano.sh | podgroups | create, delete, get, list, patch, update, watch |
| kubeflow-training-operator | scheduling.x-k8s.io | podgroups | create, delete, get, list, patch, update, watch |
| kubeflow-training-edit | kubeflow.org | all training jobs and status | create, delete, get, list, patch, update, watch |
| kubeflow-training-view | kubeflow.org | all training jobs and status | get, list, watch |

### RBAC - Role Bindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| kubeflow-training-operator | N/A (ClusterRoleBinding) | kubeflow-training-operator | opendatahub/kubeflow-training-operator |

### RBAC - Aggregation

| Role | Aggregates To | Purpose |
|------|---------------|---------|
| kubeflow-training-edit | admin, edit | Allows namespace admins/editors to manage training jobs |
| kubeflow-training-view | view | Allows namespace viewers to read training jobs |

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| N/A | N/A | Operator does not manage secrets directly | N/A | N/A |

**Secret Notes**:
- Operator runs with ServiceAccount token for Kubernetes API authentication
- Training jobs may reference user-provided secrets for image pull credentials or application secrets
- No TLS certificates managed by operator (webhook disabled in RHOAI deployment)

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| /metrics | GET | None | Application | Prometheus scraping (internal only via ServiceMonitor) |
| /healthz, /readyz | GET | None | Application | Kubernetes liveness/readiness probes |
| Kubernetes API | ALL | ServiceAccount Token | Kubernetes API Server | ClusterRole kubeflow-training-operator |

### Network Policies

No NetworkPolicy resources defined in manifests. Network isolation relies on:
- Namespace-scoped service discovery for training jobs
- Istio sidecar injection explicitly disabled (`sidecar.istio.io/inject: "false"`)
- ClusterIP services (not exposed externally)

### Security Context

| Container | allowPrivilegeEscalation | runAsUser | runAsNonRoot | Capabilities |
|-----------|-------------------------|-----------|--------------|--------------|
| training-operator | false | 65532 | Yes (implied) | Not specified |

## Data Flows

### Flow 1: Training Job Creation

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User/ODH Dashboard | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | User credentials |
| 2 | Kubernetes API | training-operator | N/A | Watch API | TLS 1.2+ | ServiceAccount token |
| 3 | training-operator | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount token |

**Description**: User creates PyTorchJob/TFJob CRD → Kubernetes notifies operator via watch → Operator reconciles by creating pods and services.

### Flow 2: Distributed Training Communication

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Training Worker Pod | DNS (ClusterDNS) | 53/UDP | DNS | None | None |
| 2 | Training Worker Pod | Master/Worker Service | 23456/TCP (PyTorch) or 2222/TCP (TF) | TCP | Application-defined | Application-defined |

**Description**: Training pods use headless services for peer discovery → Direct pod-to-pod communication for distributed training coordination.

### Flow 3: Metrics Collection

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Prometheus (UWM) | kubeflow-training-operator Service | 8080/TCP | HTTP | None | None |

**Description**: PodMonitor configures Prometheus to scrape /metrics endpoint from operator pods.

### Flow 4: Gang Scheduling (Optional)

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | training-operator | Kubernetes API (PodGroup CRD) | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount token |
| 2 | Volcano/scheduler-plugins | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount token |

**Description**: When gang scheduling enabled, operator creates PodGroup for training job → Scheduler ensures all pods scheduled atomically.

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| Kubernetes API Server | REST API (Watch/CRUD) | 6443/TCP | HTTPS | TLS 1.2+ | CRD reconciliation, resource management |
| Prometheus | Metrics Pull | 8080/TCP | HTTP | None | Operator health and performance monitoring |
| Volcano API | CRD (PodGroup) | 6443/TCP | HTTPS | TLS 1.2+ | Gang scheduling coordination |
| scheduler-plugins | CRD (PodGroup) | 6443/TCP | HTTPS | TLS 1.2+ | Gang scheduling coordination (alternative) |
| Container Registry | Image Pull | 443/TCP | HTTPS | TLS 1.2+ | Pull operator and training container images |

## Configuration

### ConfigMap

| Name | Purpose | Key Configuration |
|------|---------|-------------------|
| rhoai-config (generated) | Container image configuration | `odh-training-operator-controller-image` - specifies operator container image |

### Environment Variables

| Variable | Source | Purpose |
|----------|--------|---------|
| MY_POD_NAMESPACE | fieldRef: metadata.namespace | Namespace awareness for operator |
| MY_POD_NAME | fieldRef: metadata.name | Pod identity for leader election |

### Command-Line Flags (Default Configuration)

| Flag | Default Value | Purpose |
|------|---------------|---------|
| --metrics-bind-address | :8080 | Metrics endpoint port |
| --health-probe-bind-address | :8081 | Health probe port |
| --enable-scheme | all | Enabled training frameworks (TFJob, PyTorchJob, etc.) |
| --controller-threads | 1 | Number of reconciliation worker threads |
| --webhook-server-port | 9443 | Webhook port (not used in RHOAI) |

## Deployment Configuration

### Kustomize Structure

```
manifests/
├── base/
│   ├── crds/                    # All 6 training job CRDs
│   ├── rbac/                    # ClusterRole, ClusterRoleBinding, ServiceAccount
│   ├── deployment.yaml          # Operator deployment
│   └── service.yaml             # Metrics service
└── rhoai/
    ├── kustomization.yaml       # RHOAI overlay
    ├── monitor.yaml             # PodMonitor for Prometheus
    ├── kubeflow-training-roles.yaml  # Aggregated RBAC roles
    └── manager_*.yaml           # Deployment patches
```

### Container Build

- **Konflux Build**: `Dockerfile.konflux` (RHOAI production builds)
- **Base Image**: `registry.access.redhat.com/ubi9/go-toolset:1.25`
- **Runtime Image**: `registry.redhat.io/ubi8/ubi-minimal`
- **Binary**: `/manager` (compiled with `CGO_ENABLED=1` and `strictfipsruntime` tags)
- **User**: Non-root UID 65532

## Observability

### Metrics

Operator exposes Prometheus metrics on `:8080/metrics` including:
- Controller reconciliation latency
- Training job status counts
- Pod creation/deletion rates
- Reconciliation errors

PodMonitor configuration:
```yaml
selector:
  matchLabels:
    app.kubernetes.io/name: training-operator
    app.kubernetes.io/component: controller
podMetricsEndpoints:
  - port: metrics
```

### Health Checks

- **Liveness**: `GET :8081/healthz` (15s initial delay, 20s period)
- **Readiness**: `GET :8081/readyz` (10s initial delay, 15s period)

### Logging

- **Framework**: Zap logger (structured JSON logging)
- **Log Level**: Development mode with DPanic stacktrace level
- **Output**: stdout

## Recent Changes

| Version | Date | Changes |
|---------|------|---------|
| v-2160-133 | 2025-03 | - Update go-toolset to 1.25 (CVE-2025-61726 fix)<br>- Use multi-arch manifest list digest for base images<br>- Update UBI minimal base image<br>- Configure PipelineRun for RHOAI 2.16 |
| v1.7.0 | 2023-07 | - Merge kubeflow/common library into training-operator<br>- Implement suspend semantics for jobs<br>- Support torchrun ENV for PyTorchJob<br>- Make scheduler-plugins default gang scheduler<br>- Auto-generate RBAC manifests<br>- Upgrade Kubernetes dependencies to v1.27 |
| v1.6.0 | 2023-03 | - Add PaddlePaddle support<br>- HPA support for PyTorch Elastic training<br>- Unified Training SDK client<br>- Create jobs from Python function APIs<br>- Support Kubernetes v1.25<br>- Coscheduling plugin adoption |

## Known Limitations

1. **Webhook Support**: Admission webhooks are defined in CRDs but webhook server is not enabled in RHOAI deployment
2. **Gang Scheduling**: Requires additional installation of Volcano or scheduler-plugins
3. **Namespace Scope**: Operator can be configured for cluster-wide or single-namespace operation (RHOAI uses cluster-wide in `opendatahub` namespace)
4. **Sidecar Injection**: Istio sidecar injection explicitly disabled due to potential conflicts with training job networking
5. **Leader Election**: Single replica deployment (no HA configuration in RHOAI)

## References

- **Upstream**: https://github.com/kubeflow/training-operator
- **Documentation**: https://www.kubeflow.org/docs/components/training/
- **API Docs**: [docs/api/kubeflow.org_v1_generated.asciidoc](docs/api/kubeflow.org_v1_generated.asciidoc)
- **Python SDK**: https://pypi.org/project/kubeflow-training/
- **Examples**: [examples/](examples/) directory for each framework

## Architecture Diagram Notes

For visual architecture diagrams, the following should be highlighted:

1. **Controller Pattern**: Operator watches 6 CRD types, reconciles into pods/services
2. **Service Mesh**: Headless services enable DNS-based peer discovery for distributed training
3. **RBAC Aggregation**: Edit/view roles automatically grant training job permissions to namespace users
4. **Gang Scheduling**: Optional PodGroup integration ensures atomicity for multi-pod jobs
5. **Metrics Pipeline**: PodMonitor → Prometheus → User Workload Monitoring
6. **No External Exposure**: All operator endpoints are internal (ClusterIP), training jobs may create routes/ingress separately
