# Component: Kueue

## Metadata
- **Repository**: https://github.com/red-hat-data-services/kueue
- **Version**: v0.6.2
- **Distribution**: RHOAI
- **Languages**: Go 1.21
- **Deployment Type**: Kubernetes Operator

## Purpose
**Short**: Job queueing and resource management controller that manages when jobs should be admitted to start and when they should stop based on available cluster resources.

**Detailed**: Kueue is a Kubernetes-native job-level manager that provides fair resource sharing, queueing, and admission control for batch workloads. It acts as a gatekeeper that decides when jobs can be admitted (pods created) based on resource quotas, priorities, and policies. Kueue supports multiple queueing strategies (StrictFIFO, BestEffortFIFO), resource flavor fungibility, preemption, and dynamic resource reclamation. It integrates with popular job frameworks including Kubernetes batch Jobs, JobSet, Kubeflow training operators (TFJob, PyTorchJob, MPIJob, etc.), Ray (RayJob, RayCluster), and plain Pods. The system provides multi-tenancy through ClusterQueues and LocalQueues, enabling organizations to manage resource allocation across teams and projects while supporting advanced features like admission checks for provisioning requests and sequential/partial admission strategies.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| kueue-controller-manager | Deployment | Main controller managing workload admission, queue reconciliation, and resource allocation |
| Webhook Server | Admission Webhook | Mutating and validating webhooks for job resources and Kueue CRDs |
| Visibility Server | HTTP API | Provides visibility into pending workloads and queue status (port 8082) |
| Metrics Server | Prometheus Exporter | Exposes controller metrics for monitoring system health and performance |

## APIs Exposed

### Custom Resource Definitions (CRDs)

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| kueue.x-k8s.io | v1beta1 | AdmissionCheck | Cluster | Defines external/internal admission requirements that workloads must satisfy before admission |
| kueue.x-k8s.io | v1beta1 | ClusterQueue | Cluster | Cluster-scoped resource pool with quotas, defines available resources and admission policies |
| kueue.x-k8s.io | v1beta1 | LocalQueue | Namespaced | Namespace-scoped queue that maps to a ClusterQueue, used by workloads in that namespace |
| kueue.x-k8s.io | v1beta1 | Workload | Namespaced | Represents a unit of work (job) with resource requirements, managed by Kueue |
| kueue.x-k8s.io | v1beta1 | ResourceFlavor | Cluster | Defines resource variants (node labels, taints) that can be allocated to workloads |
| kueue.x-k8s.io | v1beta1 | WorkloadPriorityClass | Cluster | Defines priority levels for workloads to determine admission order |
| kueue.x-k8s.io | v1beta1 | MultiKueueCluster | Cluster | Represents remote clusters in multi-cluster setup |
| kueue.x-k8s.io | v1beta1 | MultiKueueConfig | Cluster | Configuration for multi-cluster workload distribution |
| kueue.x-k8s.io | v1beta1 | ProvisioningRequestConfig | Cluster | Configuration for cluster-autoscaler provisioning requests integration |

### HTTP Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /healthz | GET | 8081/TCP | HTTP | None | None | Liveness probe for controller health |
| /readyz | GET | 8081/TCP | HTTP | None | None | Readiness probe for controller availability |
| /metrics | GET | 8080/TCP | HTTP | None | None | Prometheus metrics endpoint |
| /mutate-* | POST | 9443/TCP | HTTPS | TLS 1.2+ | mTLS | Mutating webhook endpoints for jobs and CRDs |
| /validate-* | POST | 9443/TCP | HTTPS | TLS 1.2+ | mTLS | Validating webhook endpoints for jobs and CRDs |
| /* | GET | 8082/TCP | HTTP | TLS 1.2+ | HTTPS | Visibility API for pending workloads and queue information |

### Webhook Endpoints

| Webhook Type | Path | Resources | Operations | Purpose |
|--------------|------|-----------|------------|---------|
| Mutating | /mutate-batch-v1-job | batch/v1/jobs | CREATE | Inject Kueue labels and manage job suspension |
| Mutating | /mutate-jobset-x-k8s-io-v1alpha2-jobset | jobset.x-k8s.io/v1alpha2/jobsets | CREATE | Manage JobSet integration with Kueue |
| Mutating | /mutate-kubeflow-org-v1-pytorchjob | kubeflow.org/v1/pytorchjobs | CREATE | Integrate PyTorch training jobs with queueing |
| Mutating | /mutate-kubeflow-org-v1-tfjob | kubeflow.org/v1/tfjobs | CREATE | Integrate TensorFlow training jobs with queueing |
| Mutating | /mutate-kubeflow-org-v2beta1-mpijob | kubeflow.org/v2beta1/mpijobs | CREATE | Integrate MPI training jobs with queueing |
| Mutating | /mutate-ray-io-v1-raycluster | ray.io/v1/rayclusters | CREATE | Integrate Ray clusters with queueing |
| Mutating | /mutate-ray-io-v1alpha1-rayjob | ray.io/v1alpha1/rayjobs | CREATE | Integrate Ray jobs with queueing |
| Mutating | /mutate--v1-pod | core/v1/pods | CREATE | Manage plain pod integration with queueing |
| Mutating | /mutate-kueue-x-k8s-io-v1beta1-workload | kueue.x-k8s.io/v1beta1/workloads | CREATE | Set defaults on Workload creation |
| Validating | /validate-batch-v1-job | batch/v1/jobs | CREATE,UPDATE | Validate job queue references |
| Validating | /validate-kueue-x-k8s-io-v1beta1-clusterqueue | kueue.x-k8s.io/v1beta1/clusterqueues | CREATE,UPDATE | Validate ClusterQueue configuration |
| Validating | /validate-kueue-x-k8s-io-v1beta1-localqueue | kueue.x-k8s.io/v1beta1/localqueues | CREATE,UPDATE | Validate LocalQueue configuration |

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| Kubernetes | 1.22+ | Yes | Platform for running the operator and managing workloads |
| cert-manager or internal-cert | N/A | One Required | TLS certificate management for webhook server |
| Prometheus | N/A | No | Metrics collection and monitoring |
| controller-runtime | v0.17.0 | Yes | Kubernetes controller framework |
| kubeflow/training-operator | v1.7.0 | No | Integration with Kubeflow training jobs (TFJob, PyTorchJob, etc.) |
| kubeflow/mpi-operator | v0.4.0 | No | Integration with MPI jobs |
| ray-project/kuberay | v1.1.0-alpha.0 | No | Integration with Ray clusters and jobs |
| jobset | v0.3.1 | No | Integration with JobSet resources |
| cluster-autoscaler | N/A | No | Integration with provisioning requests for autoscaling |

### Internal ODH Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| Kubeflow Training Operator | CRD Watch/Webhook | Manages queueing for TFJob, PyTorchJob, MXJob, PaddleJob, XGBoostJob workloads |
| Ray Operator | CRD Watch/Webhook | Manages queueing for RayJob and RayCluster workloads |

## Network Architecture

### Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| kueue-webhook-service | ClusterIP | 443/TCP | 9443 | HTTPS | TLS 1.2+ | mTLS | Internal |
| kueue-metrics-service | ClusterIP | 8080/TCP | 8080 | HTTP | None | None | Internal |
| kueue-visibility-server | ClusterIP | 443/TCP | 8082 | HTTPS | TLS 1.2+ | None | Internal |
| kueue-controller-manager-metrics-service | ClusterIP | 8443/TCP | 8443 | HTTPS | TLS 1.2+ | None | Internal |

### Network Policies

| Policy Name | Type | Selectors | Ingress Ports | Purpose |
|-------------|------|-----------|---------------|---------|
| kueue-webhook-server | NetworkPolicy | app.kubernetes.io/name=kueue | 9443/TCP | Allow Kubernetes API server to reach webhook endpoints |

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token | Watch and reconcile CRDs, Jobs, Pods |
| cluster-autoscaler | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token | Create/manage ProvisioningRequests for autoscaling |

## Security

### RBAC - Cluster Roles

| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|
| kueue-manager-role | "" | events, limitranges, namespaces | get, list, watch |
| kueue-manager-role | "" | pods | delete, get, list, patch, update, watch |
| kueue-manager-role | "" | pods/finalizers | get, update |
| kueue-manager-role | "" | pods/status | get, patch |
| kueue-manager-role | "" | secrets | get, list, update, watch |
| kueue-manager-role | batch | jobs | get, list, patch, update, watch |
| kueue-manager-role | batch | jobs/finalizers | get, patch, update |
| kueue-manager-role | batch | jobs/status | get, update |
| kueue-manager-role | kueue.x-k8s.io | admissionchecks, clusterqueues, localqueues, workloads, resourceflavors, workloadpriorityclasses | * |
| kueue-manager-role | kubeflow.org | mpijobs, pytorchjobs, tfjobs, mxjobs, paddlejobs, xgboostjobs | get, list, patch, update, watch |
| kueue-manager-role | kubeflow.org | */finalizers | get, update |
| kueue-manager-role | kubeflow.org | */status | get, update |
| kueue-manager-role | ray.io | rayclusters, rayjobs | get, list, patch, update, watch |
| kueue-manager-role | ray.io | */finalizers | get, update |
| kueue-manager-role | ray.io | */status | get, update |
| kueue-manager-role | jobset.x-k8s.io | jobsets | get, list, patch, update, watch |
| kueue-manager-role | jobset.x-k8s.io | jobsets/finalizers | get, update |
| kueue-manager-role | jobset.x-k8s.io | jobsets/status | get, update |
| kueue-manager-role | autoscaling.x-k8s.io | provisioningrequests | create, delete, get, list, patch, update, watch |
| kueue-manager-role | admissionregistration.k8s.io | mutatingwebhookconfigurations, validatingwebhookconfigurations | get, list, update, watch |
| kueue-manager-role | flowcontrol.apiserver.k8s.io | flowschemas, prioritylevelconfigurations | list, watch |
| kueue-batch-admin-role | kueue.x-k8s.io | clusterqueues, resourceflavors, workloadpriorityclasses | * |
| kueue-batch-user-role | "" | pods | get, list, watch |
| kueue-batch-user-role | batch | jobs | get, list, watch, create, delete, patch, update |

### RBAC - Role Bindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| kueue-manager-rolebinding | opendatahub | kueue-manager-role | opendatahub/kueue-controller-manager |
| kueue-leader-election-rolebinding | opendatahub | kueue-leader-election-role | opendatahub/kueue-controller-manager |
| kueue-batch-user-rolebinding | opendatahub | kueue-batch-user-role | opendatahub/default |

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| kueue-webhook-server-cert | kubernetes.io/tls | TLS certificates for webhook server authentication | cert-manager or internal-cert | Yes |

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| /mutate-*, /validate-* | POST | mTLS (Kubernetes API Server) | Kubernetes Admission Controller | Webhook TLS cert validation |
| /metrics | GET | None | Network Policy | Internal cluster access only |
| /healthz, /readyz | GET | None | Container | Kubelet health checks |
| Kubernetes API | GET, LIST, WATCH, PATCH, UPDATE | Bearer Token (ServiceAccount) | Kubernetes RBAC | ClusterRole permissions |

## Data Flows

### Flow 1: Job Submission and Queueing

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User/CI | Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | User credentials |
| 2 | Kubernetes API Server | kueue-webhook-service | 9443/TCP | HTTPS | TLS 1.2+ | mTLS |
| 3 | kueue-webhook-service | Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 4 | kueue-controller-manager | Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |

### Flow 2: Workload Admission

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | kueue-controller-manager | Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 2 | kueue-controller-manager | Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 3 | Kubernetes API Server | kueue-webhook-service | 9443/TCP | HTTPS | TLS 1.2+ | mTLS |

### Flow 3: Metrics Collection

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Prometheus | kueue-metrics-service | 8080/TCP | HTTP | None | None |

### Flow 4: Provisioning Request (Autoscaling)

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | kueue-controller-manager | Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 2 | cluster-autoscaler | Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| Kubernetes API Server | REST API Client | 6443/TCP | HTTPS | TLS 1.2+ | Watch and reconcile CRDs, Jobs, Pods, manage workload lifecycle |
| Kubernetes API Server (Admission) | Webhook Server | 9443/TCP | HTTPS | TLS 1.2+ | Validate and mutate job resources on creation |
| Prometheus | Metrics Scraping | 8080/TCP | HTTP | None | Expose controller and queue metrics |
| Kubeflow Training Operator | CRD Reconciliation | 6443/TCP | HTTPS | TLS 1.2+ | Queue and admit Kubeflow training jobs (TFJob, PyTorchJob, etc.) |
| Ray Operator | CRD Reconciliation | 6443/TCP | HTTPS | TLS 1.2+ | Queue and admit Ray workloads (RayJob, RayCluster) |
| JobSet Controller | CRD Reconciliation | 6443/TCP | HTTPS | TLS 1.2+ | Queue and admit JobSet resources |
| cluster-autoscaler | ProvisioningRequest API | 6443/TCP | HTTPS | TLS 1.2+ | Request node provisioning based on pending workloads |

## Monitoring & Observability

### Prometheus Metrics

| Metric Type | Purpose | Scrape Configuration |
|-------------|---------|---------------------|
| PodMonitor | Scrapes metrics from controller-manager pods | Matches labels: app.kubernetes.io/name=kueue, app.kubernetes.io/component=controller |

### Key Metrics Exposed

- `kueue_pending_workloads` - Number of workloads waiting in queues
- `kueue_admitted_workloads_total` - Total admitted workloads by queue
- `kueue_admission_cycle_duration_seconds` - Time taken for admission cycles
- `kueue_cluster_queue_resource_usage` - Resource usage per ClusterQueue
- `kueue_cluster_queue_nominal_quota` - Configured quota per ClusterQueue
- Controller runtime metrics (reconciliation duration, errors, etc.)

## Deployment Configuration

### Namespace

- **RHOAI**: `opendatahub`

### Resource Limits

| Container | CPU Request | CPU Limit | Memory Request | Memory Limit |
|-----------|-------------|-----------|----------------|--------------|
| manager | 500m | 500m | 512Mi | 512Mi |

### Security Context

- **runAsNonRoot**: true
- **allowPrivilegeEscalation**: false
- **User**: 65532:65532

### Configuration

| Config Type | Name | Purpose |
|-------------|------|---------|
| ConfigMap | manager-config | Controller configuration (mounted at /controller_manager_config.yaml) |
| ConfigMap | rhoai-config | RHOAI-specific configuration including container image reference |

## Controllers

| Controller Name | Watches | Reconciles | Purpose |
|----------------|---------|------------|---------|
| AdmissionCheck | AdmissionCheck CRD | AdmissionCheck status | Manage admission check lifecycle and status |
| ClusterQueue | ClusterQueue CRD, ResourceFlavor CRD | ClusterQueue status, Workload admission | Manage resource quotas and admit workloads |
| LocalQueue | LocalQueue CRD, ClusterQueue CRD | LocalQueue status | Connect namespace queues to cluster queues |
| ResourceFlavor | ResourceFlavor CRD, Nodes | ResourceFlavor status | Track available resource flavors in cluster |
| Workload | Workload CRD, ClusterQueue CRD | Workload admission | Manage workload lifecycle and admission |
| Job | batch/v1 Job, Workload CRD | Job suspension, Workload | Integrate Kubernetes Jobs with Kueue |
| JobSet | JobSet CRD, Workload CRD | JobSet suspension, Workload | Integrate JobSets with Kueue |
| PyTorchJob | PyTorchJob CRD, Workload CRD | PyTorchJob suspension, Workload | Integrate PyTorch training with Kueue |
| TFJob | TFJob CRD, Workload CRD | TFJob suspension, Workload | Integrate TensorFlow training with Kueue |
| MPIJob | MPIJob CRD, Workload CRD | MPIJob suspension, Workload | Integrate MPI training with Kueue |
| RayJob | RayJob CRD, Workload CRD | RayJob suspension, Workload | Integrate Ray jobs with Kueue |
| RayCluster | RayCluster CRD, Workload CRD | RayCluster suspension, Workload | Integrate Ray clusters with Kueue |
| Pod | Pod, Workload CRD | Pod gating, Workload | Integrate plain Pods with Kueue |
| ProvisioningRequest | ProvisioningRequestConfig, Workload | ProvisioningRequest | Integrate with cluster-autoscaler for autoscaling |

## Recent Changes

_Note: No git commits found in the last 3 months. This is a stable RHOAI 2.9 release branch based on upstream Kueue v0.6.2._

| Version | Date | Changes |
|---------|------|---------|
| v0.6.2 | 2024 | - Stable release for RHOAI 2.9<br>- Support for v1beta1 API<br>- Integration with Kubeflow, Ray, JobSet workloads<br>- Admission checks and provisioning request support<br>- Multi-cluster capabilities (alpha)<br>- Partial admission support |

## Key Features

1. **Fair Resource Sharing**: Multi-tenancy with ClusterQueues and LocalQueues, cohort-based borrowing
2. **Flexible Queueing**: StrictFIFO and BestEffortFIFO strategies with priority support
3. **Preemption**: Policy-based workload preemption to reclaim resources
4. **Dynamic Resource Reclaim**: Release quota as pods complete
5. **Flavor Fungibility**: Try different resource flavors before borrowing/preempting
6. **Admission Checks**: External validation before admitting workloads
7. **Autoscaling Integration**: ProvisioningRequest support for cluster-autoscaler
8. **Sequential Admission**: All-or-nothing scheduling for gang workloads
9. **Partial Admission**: Run jobs with reduced parallelism based on available quota
10. **Multi-Cluster**: Distribute workloads across multiple Kubernetes clusters (alpha)

## Architecture Diagrams

```
┌─────────────────────────────────────────────────────────────────────┐
│                          User / CI System                            │
└────────────────────────────┬────────────────────────────────────────┘
                             │ Submit Job
                             ▼
┌─────────────────────────────────────────────────────────────────────┐
│                    Kubernetes API Server                             │
│  ┌────────────────────────────────────────────────────────────────┐ │
│  │              Admission Webhooks                                 │ │
│  │  ┌──────────────────────────────────────────────────────────┐  │ │
│  │  │   Kueue Webhook Server (port 9443)                        │  │ │
│  │  │   - Mutate/Validate Jobs, Pods, Kubeflow, Ray            │  │ │
│  │  │   - Inject labels, manage suspension                      │  │ │
│  │  └──────────────────────────────────────────────────────────┘  │ │
│  └────────────────────────────────────────────────────────────────┘ │
└─────────────────────────────┬───────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────────┐
│              Kueue Controller Manager                                │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │  Core Controllers:                                           │   │
│  │  • ClusterQueue Controller - Resource quota & admission     │   │
│  │  • LocalQueue Controller - Namespace queue management       │   │
│  │  • Workload Controller - Workload lifecycle                 │   │
│  │  • AdmissionCheck Controller - Validation logic             │   │
│  │  • ResourceFlavor Controller - Resource variant tracking    │   │
│  └─────────────────────────────────────────────────────────────┘   │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │  Job Integration Controllers:                                │   │
│  │  • Job, JobSet, Pod Controllers                             │   │
│  │  • Kubeflow (TF, PyTorch, MPI, MX, Paddle, XGBoost)        │   │
│  │  • Ray (RayJob, RayCluster)                                 │   │
│  └─────────────────────────────────────────────────────────────┘   │
│                                                                     │
│  Metrics (8080) | Health (8081) | Visibility (8082)                │
└─────────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────────┐
│                   Workload Execution                                 │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐              │
│  │  Batch Jobs  │  │ Training Jobs│  │  Ray Clusters│              │
│  │  (Pods)      │  │ (Kubeflow)   │  │  (Pods)      │              │
│  └──────────────┘  └──────────────┘  └──────────────┘              │
└─────────────────────────────────────────────────────────────────────┘
```

## Notes

- Kueue operates as a non-intrusive overlay on existing job frameworks, using suspension and label injection
- Workloads are kept suspended until Kueue admits them based on available quota
- The system supports hierarchical resource sharing through cohorts
- Integration with cluster-autoscaler enables automatic node provisioning for pending workloads
- All job integrations follow a common framework pattern for consistency
- Webhook certificates must be properly configured using cert-manager or internal certificate controller
- The visibility API provides read-only access to queue status for debugging and monitoring
