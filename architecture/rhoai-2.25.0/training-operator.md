# Component: Kubeflow Training Operator

## Metadata
- **Repository**: https://github.com/red-hat-data-services/training-operator
- **Version**: 1.9.0 (git: 3a1af789)
- **Branch**: rhoai-2.25
- **Distribution**: RHOAI
- **Languages**: Go
- **Deployment Type**: Kubernetes Operator

## Purpose
**Short**: Kubernetes-native operator for scalable distributed training of machine learning models across multiple frameworks.

**Detailed**:

The Kubeflow Training Operator is a comprehensive Kubernetes operator that enables data scientists to run distributed training workloads for machine learning models using various frameworks including PyTorch, TensorFlow, XGBoost, MPI, PaddlePaddle, and JAX. It provides Custom Resource Definitions (CRDs) for each framework type, allowing users to declare training jobs as Kubernetes resources that the operator manages throughout their lifecycle.

The operator handles the complexity of distributed training by automatically creating and managing worker pods, establishing communication between training nodes, configuring environment variables for distributed frameworks, and managing job lifecycle including restart policies and cleanup. It supports advanced features like elastic training (dynamic scaling), gang scheduling with Volcano or scheduler-plugins, and HorizontalPodAutoscaler integration for PyTorch jobs. The operator also includes validating webhooks to ensure training job specifications are correct before creation.

For RHOAI deployments, the operator integrates with OpenShift's monitoring stack via PodMonitor resources and is built using Konflux CI/CD with strict FIPS compliance. It provides both Kubernetes Custom Resource APIs and a Python SDK to simplify the creation and management of distributed training jobs.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| training-operator | Go Controller Manager | Main controller process managing all training job types |
| PyTorchJob Controller | Kubernetes Controller | Reconciles PyTorchJob CRs, manages PyTorch distributed training |
| TFJob Controller | Kubernetes Controller | Reconciles TFJob CRs, manages TensorFlow distributed training |
| MPIJob Controller | Kubernetes Controller | Reconciles MPIJob CRs, manages MPI-based HPC workloads |
| XGBoostJob Controller | Kubernetes Controller | Reconciles XGBoostJob CRs, manages XGBoost distributed training |
| PaddleJob Controller | Kubernetes Controller | Reconciles PaddleJob CRs, manages PaddlePaddle training |
| JAXJob Controller | Kubernetes Controller | Reconciles JAXJob CRs, manages JAX distributed training |
| Webhook Server | ValidatingWebhookServer | Validates training job specs on CREATE/UPDATE operations |
| Certificate Manager | Certificate Rotation | Manages TLS certificates for webhook server |
| Metrics Exporter | Prometheus Exporter | Exposes operator and job metrics |

## APIs Exposed

### Custom Resource Definitions (CRDs)

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| kubeflow.org | v1 | PyTorchJob | Namespaced | Defines distributed PyTorch training jobs with master/worker topology |
| kubeflow.org | v1 | TFJob | Namespaced | Defines TensorFlow distributed training with parameter server or collective strategy |
| kubeflow.org | v1 | MPIJob | Namespaced | Defines MPI-based distributed training for HPC workloads |
| kubeflow.org | v1 | XGBoostJob | Namespaced | Defines distributed XGBoost training jobs |
| kubeflow.org | v1 | PaddleJob | Namespaced | Defines PaddlePaddle distributed training jobs |
| kubeflow.org | v1 | JAXJob | Namespaced | Defines JAX distributed training jobs |

### HTTP Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /metrics | GET | 8080/TCP | HTTP | None | None | Prometheus metrics endpoint for operator and job statistics |
| /healthz | GET | 8081/TCP | HTTP | None | None | Liveness probe endpoint |
| /readyz | GET | 8081/TCP | HTTP | None | None | Readiness probe endpoint (waits for webhook cert readiness) |
| /validate-kubeflow-org-v1-pytorchjob | POST | 9443/TCP | HTTPS | TLS 1.2+ | K8s API Server mTLS | ValidatingWebhook for PyTorchJob resources |
| /validate-kubeflow-org-v1-tfjob | POST | 9443/TCP | HTTPS | TLS 1.2+ | K8s API Server mTLS | ValidatingWebhook for TFJob resources |
| /validate-kubeflow-org-v1-mpijob | POST | 9443/TCP | HTTPS | TLS 1.2+ | K8s API Server mTLS | ValidatingWebhook for MPIJob resources |
| /validate-kubeflow-org-v1-xgboostjob | POST | 9443/TCP | HTTPS | TLS 1.2+ | K8s API Server mTLS | ValidatingWebhook for XGBoostJob resources |
| /validate-kubeflow-org-v1-paddlejob | POST | 9443/TCP | HTTPS | TLS 1.2+ | K8s API Server mTLS | ValidatingWebhook for PaddleJob resources |
| /validate-kubeflow-org-v1-jaxjob | POST | 9443/TCP | HTTPS | TLS 1.2+ | K8s API Server mTLS | ValidatingWebhook for JAXJob resources |

### gRPC Services

| Service | Port | Protocol | Encryption | Auth | Purpose |
|---------|------|----------|------------|------|---------|
| N/A | N/A | N/A | N/A | N/A | No gRPC services exposed |

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| Kubernetes | 1.27+ | Yes | Container orchestration platform |
| controller-runtime | v0.19+ | Yes | Kubernetes controller framework |
| Prometheus Operator | N/A | No | Metrics collection via PodMonitor |
| Volcano Scheduler | N/A | No | Gang scheduling for training jobs |
| Scheduler Plugins | N/A | No | Alternative gang scheduling implementation |
| Istio Service Mesh | N/A | No | mTLS and traffic management (sidecar injection disabled) |

### Internal ODH Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| ODH Dashboard | UI Integration | Training job creation and monitoring through dashboard |
| Model Registry | Post-training | Storage of trained models after job completion |
| Distributed Workloads | Orchestration | Coordination with other distributed workload components |

## Network Architecture

### Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| kubeflow-training-operator | ClusterIP | 443/TCP | 9443 | HTTPS | TLS 1.2+ | K8s API Server mTLS | Internal (Webhook) |
| kubeflow-training-operator (metrics) | ClusterIP | 8080/TCP | 8080 | HTTP | None | None | Internal (Prometheus) |
| [job-name]-[replica-type]-[idx] | ClusterIP | 23456/TCP (PyTorch) | 23456 | TCP | Application-defined | None | Internal (Worker comm) |

### Ingress

| Name | Type | Hosts | Port | Protocol | Encryption | TLS Mode | Exposure |
|------|------|-------|------|----------|------------|----------|----------|
| N/A | N/A | N/A | N/A | N/A | N/A | N/A | No ingress resources created by operator |

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| Kubernetes API Server | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token | Watch CRDs, manage pods/services/events |
| Container Registry | 443/TCP | HTTPS | TLS 1.2+ | Pull Secrets | Pull training container images |
| Volcano API Server | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token | Gang scheduling (if enabled) |
| Scheduler Plugins API | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token | Gang scheduling (if enabled) |

## Security

### RBAC - Cluster Roles

| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|
| training-operator | "" | pods | create, delete, get, list, patch, update, watch |
| training-operator | "" | pods/exec | create |
| training-operator | "" | services | create, delete, get, list, watch |
| training-operator | "" | serviceaccounts | create, get, list, watch |
| training-operator | "" | configmaps | create, list, update, watch |
| training-operator | "" | events | create, delete, get, list, patch, update, watch |
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
| training-operator | kubeflow.org | paddlejobs | create, delete, get, list, patch, update, watch |
| training-operator | kubeflow.org | paddlejobs/status | get, patch, update |
| training-operator | kubeflow.org | paddlejobs/finalizers | update |
| training-operator | kubeflow.org | jaxjobs | create, delete, get, list, patch, update, watch |
| training-operator | kubeflow.org | jaxjobs/status | get, patch, update |
| training-operator | kubeflow.org | jaxjobs/finalizers | update |
| training-operator | autoscaling | horizontalpodautoscalers | create, delete, get, list, patch, update, watch |
| training-operator | scheduling.volcano.sh | podgroups | create, delete, get, list, patch, update, watch |
| training-operator | scheduling.x-k8s.io | podgroups | create, delete, get, list, patch, update, watch |
| training-operator | networking.k8s.io | networkpolicies | create, delete, get, list, patch, update, watch |
| training-operator | rbac.authorization.k8s.io | roles | create, list, update, watch |
| training-operator | rbac.authorization.k8s.io | rolebindings | create, list, update, watch |
| training-operator | admissionregistration.k8s.io | validatingwebhookconfigurations | get, list, update, watch |

### RBAC - Role Bindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| kubeflow-training-operator | opendatahub | training-operator (ClusterRole) | training-operator |
| kubeflow-training-operator-webhook-secret | opendatahub | training-operator-webhook-secret (Role) | training-operator |

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| training-operator-webhook-cert | kubernetes.io/tls | TLS certificate for webhook server | cert-manager (operator) | Yes |

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| /validate-* | POST | mTLS (K8s API Server) | Webhook Server | K8s RBAC for admission controller |
| /metrics | GET | None | Prometheus Scraper | Network policy + service account |
| Kubernetes API | ALL | ServiceAccount Token (JWT) | K8s API Server | RBAC ClusterRole bindings |
| Training Worker Pods | TCP | Application-defined | Application Layer | Training framework auth (if any) |

## Data Flows

### Flow 1: Training Job Creation

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User/Dashboard | Kubernetes API Server | 443/TCP | HTTPS | TLS 1.2+ | User credentials |
| 2 | Kubernetes API Server | training-operator webhook | 9443/TCP | HTTPS | TLS 1.2+ | K8s API Server mTLS |
| 3 | training-operator webhook | Kubernetes API Server | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 4 | training-operator controller | Kubernetes API Server | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 5 | training-operator controller | Kubernetes API Server (create pods) | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 6 | training-operator controller | Kubernetes API Server (create services) | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |

### Flow 2: Training Job Execution (PyTorch Example)

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Kubelet | Container Registry | 443/TCP | HTTPS | TLS 1.2+ | Pull Secret |
| 2 | Training Master Pod | Training Worker Pods | 23456/TCP | TCP | Application-defined | Framework-specific |
| 3 | Training Worker Pods | Training Master Pod | 23456/TCP | TCP | Application-defined | Framework-specific |
| 4 | Training Worker Pods | Object Storage (S3/etc) | 443/TCP | HTTPS | TLS 1.2+ | AWS IAM / Cloud credentials |

### Flow 3: Metrics Collection

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Prometheus | training-operator service | 8080/TCP | HTTP | None | ServiceAccount (bearer token) |
| 2 | training-operator | Prometheus | N/A | N/A | N/A | Metrics push not used |

### Flow 4: Webhook Certificate Management

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | cert-manager (in operator) | Kubernetes API Server (create secret) | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 2 | cert-manager (in operator) | Kubernetes API Server (update webhook config) | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| Kubernetes API Server | REST API (client) | 443/TCP | HTTPS | TLS 1.2+ | Watch CRDs, manage resources, update status |
| Kubernetes API Server | Webhook (server) | 9443/TCP | HTTPS | TLS 1.2+ | Validate training job specifications |
| Prometheus | HTTP Metrics (server) | 8080/TCP | HTTP | None | Expose operator metrics for monitoring |
| Volcano Scheduler | CRD (PodGroup) | 443/TCP | HTTPS | TLS 1.2+ | Gang scheduling coordination |
| Scheduler Plugins | CRD (PodGroup) | 443/TCP | HTTPS | TLS 1.2+ | Alternative gang scheduling |
| ODH Dashboard | REST API (via K8s API) | 443/TCP | HTTPS | TLS 1.2+ | UI-based job creation and monitoring |

## Recent Changes

| Version | Date | Changes |
|---------|------|---------|
| 3a1af789 | 2026-03-13 | - Update go-toolset base image to 1.25 (CVE fixes)<br>- Restrict secrets RBAC to namespace-scoped Role<br>- Add RHOAI 2.25.0 version parameter to Tekton pipeline |
| e7f24921 | 2026-02-28 | - Update ubi9/ubi-minimal base image digest<br>- Sync pipelineruns with konflux-central |
| 3cc019b9 | 2026-02-25 | - Restrict secrets RBAC permissions from ClusterRole to namespace-scoped Role for improved security |
| 1abc9fed | 2026-02-24 | - Refresh RPM lockfiles for dependency updates |
| 9618a811 | 2026-02-18 | - Fix CVE-2025-61726 by upgrading Go version to 1.25<br>- Update go-toolset base image |
| e95b8bb7 | 2026-02-15 | - Update go-toolset:1.25 base image digest (security patches) |
| d763379c | 2026-02-10 | - Update go-toolset:1.25 base image digest |
| 83f6ab5d | 2026-02-08 | - Update go-toolset:1.25 base image digest |
| 28e23d29 | 2026-02-05 | - Update go-toolset:1.25 base image digest |
| df5c3e9e | 2026-02-03 | - Update go-toolset:1.25 base image digest |
| 8f2c8247 | 2026-01-30 | - Sync pipelineruns with konflux-central pipeline updates |
| 5f3c7837 | 2026-01-28 | - Update ubi9/ubi-minimal runtime image digest |
| 91387195 | 2026-01-25 | - Sync pipelineruns with konflux-central |
| 22adc76c | 2026-01-22 | - Update ubi9/ubi-minimal runtime image digest |
| 6af73adf | 2026-01-18 | - Update ubi9/ubi-minimal runtime image digest |
| d13ad47c | 2026-01-15 | - Sync pipelineruns with konflux-central |

## Component-Specific Details

### Training Job Lifecycle

The operator follows a standard Kubernetes controller pattern with specific lifecycle management for training jobs:

1. **Job Creation**: User creates a training job CR (e.g., PyTorchJob). The validating webhook checks the specification.
2. **Reconciliation**: The appropriate controller watches for the new CR and begins reconciliation.
3. **Resource Creation**: Controller creates pods (master/workers), services (for inter-pod communication), and optionally NetworkPolicies, PodGroups (for gang scheduling), and HorizontalPodAutoscalers.
4. **Status Updates**: Controller continuously monitors pod states and updates the job CR status with conditions (Created, Running, Succeeded, Failed).
5. **Job Completion**: When all replicas complete successfully, the controller marks the job as Succeeded and optionally cleans up resources based on the cleanup policy.
6. **Job Failure**: If pods fail beyond the restart policy limit, the controller marks the job as Failed.

### Framework-Specific Features

**PyTorchJob**:
- Supports elastic training with dynamic worker scaling (ElasticPolicy with HPA)
- Configurable `nprocPerNode` for GPU/CPU allocation
- Master-Worker topology with configurable communication port (default: 23456)
- Init containers for distributed setup

**TFJob**:
- Supports Parameter Server and Ring AllReduce (Horovod) strategies
- Chief, Worker, ParameterServer, and Evaluator replica types
- Port configuration per replica type

**MPIJob**:
- Launcher-Worker architecture for MPI-based workloads
- kubectl delivery init container for MPI launcher
- Supports SSH-based and kubectl-exec based communication

**XGBoostJob, PaddleJob, JAXJob**:
- Master-Worker architecture
- Framework-specific environment variable injection
- Service-based worker discovery

### Gang Scheduling

The operator supports gang scheduling to ensure all pods of a training job are scheduled together:

- **Volcano**: Creates PodGroup resources with `scheduling.volcano.sh` API
- **Scheduler Plugins**: Creates PodGroup resources with `scheduling.x-k8s.io` API
- Prevents resource deadlocks in multi-tenant clusters
- Configurable via `--gang-scheduler-name` flag

### Monitoring and Observability

- **Metrics**: Prometheus metrics exposed on port 8080, scraped via PodMonitor
- **Events**: Kubernetes events created for job lifecycle transitions
- **Logs**: Structured logging with configurable verbosity
- **Probes**: Liveness (/healthz) and readiness (/readyz) endpoints for operator health

### Security Considerations

1. **Network Isolation**: Training pods can optionally have NetworkPolicies created to restrict traffic
2. **RBAC**: Minimal permissions model with separate roles for webhook secret management
3. **Secrets**: RBAC restricted to namespace-scoped roles (recent security improvement)
4. **FIPS Compliance**: Built with `GOEXPERIMENT=strictfipsruntime` for FIPS 140-2 compliance
5. **Webhook TLS**: Self-managed certificate rotation for webhook server
6. **Sidecar Injection**: Istio sidecar injection explicitly disabled (`sidecar.istio.io/inject: "false"`)

### Python SDK

The operator provides a Python SDK (`kubeflow-training`) that simplifies job creation:
- High-level APIs for creating training jobs
- Integration with Hugging Face Trainer
- Support for fine-tuning workflows
- Job monitoring and log retrieval
