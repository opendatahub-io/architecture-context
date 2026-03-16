# Component: Kueue

## Metadata
- **Repository**: https://github.com/red-hat-data-services/kueue.git
- **Version**: rhoai-2.17 (commit 0f775887e)
- **Distribution**: RHOAI
- **Languages**: Go
- **Deployment Type**: Kubernetes Operator

## Purpose
**Short**: Job queueing and resource management system for Kubernetes workloads.

**Detailed**: Kueue is a Kubernetes-native job queueing system that manages when jobs should be admitted to run based on available resources. It provides fair resource sharing, preemption policies, and dynamic resource reclaim across multiple tenants. Kueue acts as a job-level manager that decides when pods can be created and when they should be deleted, supporting various job types including Batch jobs, Kubeflow training jobs (TensorFlow, PyTorch, MPI), Ray workloads, and plain pods. It integrates deeply with the Kubernetes scheduler to provide sophisticated queueing strategies (StrictFIFO, BestEffortFIFO), priority-based scheduling, and admission checks for workload validation.

The component consists of a controller manager that reconciles queue and workload resources, a webhook server that validates and mutates job submissions, and a visibility API server that provides insights into pending workloads. It enables multi-cluster job distribution through MultiKueue, integrates with cluster autoscaling via provisioning requests, and provides comprehensive metrics for monitoring queue depth, resource usage, and admission performance.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| Controller Manager | Deployment | Main reconciliation loop for ClusterQueues, LocalQueues, Workloads, ResourceFlavors, and AdmissionChecks |
| Webhook Server | Admission Webhook | Validates and mutates job resources (Batch, Kubeflow, Ray, JobSet, Pods) |
| Visibility Server | API Extension | Provides visibility API for querying pending workloads in queues |
| Core Controllers | Reconcilers | ClusterQueue, LocalQueue, Workload, ResourceFlavor, AdmissionCheck controllers |
| Job Framework Integrations | Adapters | Integrations for Batch, Kubeflow (TF/PyTorch/MPI/XGBoost/MX/Paddle), Ray, JobSet, Pod, AppWrapper |

## APIs Exposed

### Custom Resource Definitions (CRDs)

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| kueue.x-k8s.io | v1beta1 | ClusterQueue | Cluster | Defines cluster-wide resource quotas and queueing policies for workloads |
| kueue.x-k8s.io | v1beta1 | LocalQueue | Namespaced | Namespace-scoped queue that maps to a ClusterQueue for workload submission |
| kueue.x-k8s.io | v1beta1 | Workload | Namespaced | Represents a unit of work (job) with resource requirements and scheduling constraints |
| kueue.x-k8s.io | v1beta1 | ResourceFlavor | Cluster | Defines resource types/flavors (e.g., GPU types, node types) with labels and taints |
| kueue.x-k8s.io | v1beta1 | WorkloadPriorityClass | Cluster | Defines priority levels for workloads in queues |
| kueue.x-k8s.io | v1beta1 | AdmissionCheck | Cluster | Defines checks that must pass before workload admission |
| kueue.x-k8s.io | v1beta1 | MultiKueueCluster | Namespaced | Defines remote cluster configuration for multi-cluster job distribution |
| kueue.x-k8s.io | v1beta1 | MultiKueueConfig | Namespaced | Configures MultiKueue behavior for ClusterQueues |
| kueue.x-k8s.io | v1beta1 | ProvisioningRequestConfig | Cluster | Configures integration with cluster autoscaler provisioning requests |

### HTTP Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /healthz | GET | 8081/TCP | HTTP | None | None | Liveness probe for controller manager |
| /readyz | GET | 8081/TCP | HTTP | None | None | Readiness probe for controller manager |
| /metrics | GET | 8443/TCP | HTTPS | TLS 1.2+ | Bearer Token | Prometheus metrics endpoint (authenticated) |
| /mutate-batch-v1-job | POST | 9443/TCP | HTTPS | TLS 1.2+ | K8s API mTLS | Mutating webhook for Batch Jobs |
| /validate-batch-v1-job | POST | 9443/TCP | HTTPS | TLS 1.2+ | K8s API mTLS | Validating webhook for Batch Jobs |
| /mutate-kueue-x-k8s-io-v1beta1-clusterqueue | POST | 9443/TCP | HTTPS | TLS 1.2+ | K8s API mTLS | Mutating webhook for ClusterQueue |
| /validate-kueue-x-k8s-io-v1beta1-clusterqueue | POST | 9443/TCP | HTTPS | TLS 1.2+ | K8s API mTLS | Validating webhook for ClusterQueue |
| /mutate-kueue-x-k8s-io-v1beta1-workload | POST | 9443/TCP | HTTPS | TLS 1.2+ | K8s API mTLS | Mutating webhook for Workload |
| /validate-kueue-x-k8s-io-v1beta1-workload | POST | 9443/TCP | HTTPS | TLS 1.2+ | K8s API mTLS | Validating webhook for Workload |
| /mutate-kubeflow-org-v1-pytorchjob | POST | 9443/TCP | HTTPS | TLS 1.2+ | K8s API mTLS | Mutating webhook for PyTorchJob |
| /validate-kubeflow-org-v1-pytorchjob | POST | 9443/TCP | HTTPS | TLS 1.2+ | K8s API mTLS | Validating webhook for PyTorchJob |
| /mutate-kubeflow-org-v1-tfjob | POST | 9443/TCP | HTTPS | TLS 1.2+ | K8s API mTLS | Mutating webhook for TFJob |
| /validate-kubeflow-org-v1-tfjob | POST | 9443/TCP | HTTPS | TLS 1.2+ | K8s API mTLS | Validating webhook for TFJob |
| /mutate-kubeflow-org-v2beta1-mpijob | POST | 9443/TCP | HTTPS | TLS 1.2+ | K8s API mTLS | Mutating webhook for MPIJob |
| /validate-kubeflow-org-v2beta1-mpijob | POST | 9443/TCP | HTTPS | TLS 1.2+ | K8s API mTLS | Validating webhook for MPIJob |
| /mutate-ray-io-v1-rayjob | POST | 9443/TCP | HTTPS | TLS 1.2+ | K8s API mTLS | Mutating webhook for RayJob |
| /validate-ray-io-v1-rayjob | POST | 9443/TCP | HTTPS | TLS 1.2+ | K8s API mTLS | Validating webhook for RayJob |
| /mutate-ray-io-v1-raycluster | POST | 9443/TCP | HTTPS | TLS 1.2+ | K8s API mTLS | Mutating webhook for RayCluster |
| /validate-ray-io-v1-raycluster | POST | 9443/TCP | HTTPS | TLS 1.2+ | K8s API mTLS | Validating webhook for RayCluster |
| /mutate-jobset-x-k8s-io-v1alpha2-jobset | POST | 9443/TCP | HTTPS | TLS 1.2+ | K8s API mTLS | Mutating webhook for JobSet |
| /validate-jobset-x-k8s-io-v1alpha2-jobset | POST | 9443/TCP | HTTPS | TLS 1.2+ | K8s API mTLS | Validating webhook for JobSet |
| /mutate--v1-pod | POST | 9443/TCP | HTTPS | TLS 1.2+ | K8s API mTLS | Mutating webhook for Pods |
| /validate--v1-pod | POST | 9443/TCP | HTTPS | TLS 1.2+ | K8s API mTLS | Validating webhook for Pods |

### Extension API Services

| Group | Version | Service | Port | Protocol | Encryption | Purpose |
|-------|---------|---------|------|----------|------------|---------|
| visibility.kueue.x-k8s.io | v1alpha1 | visibility-server | 8082/TCP | HTTPS | TLS 1.2+ | Query pending workloads in ClusterQueues and LocalQueues |

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| Kubernetes | 1.25+ | Yes | Core platform for operator and CRDs |
| cert-manager | v1.0+ | No | TLS certificate management for webhooks (optional, internal cert management available) |
| Prometheus Operator | N/A | No | Metrics collection via ServiceMonitor |
| cluster-autoscaler | N/A | No | Auto-scaling integration via ProvisioningRequests |

### Internal ODH Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| training-operator (Kubeflow) | CRD Watch/Webhook | Queue management for TFJob, PyTorchJob, MPIJob, XGBoostJob, MXJob, PaddleJob |
| kuberay-operator | CRD Watch/Webhook | Queue management for RayJob and RayCluster |
| codeflare-operator | CRD Watch | Queue management for AppWrapper workloads |

## Network Architecture

### Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| webhook-service | ClusterIP | 443/TCP | 9443 | HTTPS | TLS 1.2+ | K8s API mTLS | Internal (K8s API Server) |
| controller-manager-metrics-service | ClusterIP | 8443/TCP | 8443 | HTTPS | TLS 1.2+ | Bearer Token | Internal (Prometheus) |
| visibility-server | ClusterIP | 443/TCP | 8082 | HTTPS | TLS 1.2+ | K8s API Auth | Internal (K8s API Server) |

### Ingress

No external ingress configured. All services are internal cluster services.

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | Service Account Token | Watch/update CRDs, Jobs, Pods |
| Multi-cluster API Servers | 6443/TCP | HTTPS | TLS 1.2+ | Kubeconfig credentials | MultiKueue remote cluster access |

## Security

### RBAC - Cluster Roles

| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|
| manager-role | kueue.x-k8s.io | clusterqueues, localqueues, workloads, admissionchecks, resourceflavors, workloadpriorityclasses, multikueueclusters, multikueueconfigs, provisioningrequestconfigs | get, list, watch, create, update, patch, delete |
| manager-role | kueue.x-k8s.io | clusterqueues/status, localqueues/status, workloads/status, admissionchecks/status | get, patch, update |
| manager-role | kueue.x-k8s.io | clusterqueues/finalizers, localqueues/finalizers, workloads/finalizers, admissionchecks/finalizers, resourceflavors/finalizers | update |
| manager-role | batch | jobs, jobs/status, jobs/finalizers | get, list, watch, patch, update |
| manager-role | kubeflow.org | mpijobs, pytorchjobs, tfjobs, xgboostjobs, mxjobs, paddlejobs | get, list, watch, patch, update |
| manager-role | kubeflow.org | mpijobs/status, pytorchjobs/status, tfjobs/status, xgboostjobs/status, mxjobs/status, paddlejobs/status | get, update |
| manager-role | kubeflow.org | mpijobs/finalizers, pytorchjobs/finalizers, tfjobs/finalizers, xgboostjobs/finalizers, mxjobs/finalizers, paddlejobs/finalizers | get, update |
| manager-role | ray.io | rayjobs, rayclusters | get, list, watch, patch, update |
| manager-role | ray.io | rayjobs/status, rayclusters/status | get, update |
| manager-role | ray.io | rayjobs/finalizers, rayclusters/finalizers | get, update |
| manager-role | jobset.x-k8s.io | jobsets, jobsets/status, jobsets/finalizers | get, list, watch, patch, update |
| manager-role | "" | pods, pods/status, pods/finalizers, podtemplates, secrets, namespaces, limitranges, events | get, list, watch, patch, update, delete, create |
| manager-role | autoscaling.x-k8s.io | provisioningrequests, provisioningrequests/status | get, list, watch, create, update, patch, delete |
| manager-role | admissionregistration.k8s.io | mutatingwebhookconfigurations, validatingwebhookconfigurations | get, list, watch, update |
| manager-role | scheduling.k8s.io | priorityclasses | get, list, watch |
| manager-role | node.k8s.io | runtimeclasses | get, list, watch |
| manager-role | flowcontrol.apiserver.k8s.io | flowschemas, prioritylevelconfigurations | list, watch |
| manager-role | flowcontrol.apiserver.k8s.io | flowschemas/status | patch |
| clusterqueue-viewer-role | kueue.x-k8s.io | clusterqueues | get, list, watch |
| clusterqueue-editor-role | kueue.x-k8s.io | clusterqueues | get, list, watch, create, update, patch, delete |
| localqueue-viewer-role | kueue.x-k8s.io | localqueues | get, list, watch |
| localqueue-editor-role | kueue.x-k8s.io | localqueues | get, list, watch, create, update, patch, delete |
| workload-viewer-role | kueue.x-k8s.io | workloads | get, list, watch |
| workload-editor-role | kueue.x-k8s.io | workloads | get, list, watch, create, update, patch, delete |
| batch-user-role | batch | jobs | get, list, watch, create, update, patch, delete |
| batch-admin-role | batch | jobs | get, list, watch, create, update, patch, delete |
| job-editor-role | batch | jobs | get, list, watch, create, update, patch, delete |
| pytorchjob-editor-role | kubeflow.org | pytorchjobs | get, list, watch, create, update, patch, delete |
| tfjob-editor-role | kubeflow.org | tfjobs | get, list, watch, create, update, patch, delete |
| mpijob-editor-role | kubeflow.org | mpijobs | get, list, watch, create, update, patch, delete |
| rayjob-editor-role | ray.io | rayjobs | get, list, watch, create, update, patch, delete |
| raycluster-editor-role | ray.io | rayclusters | get, list, watch, create, update, patch, delete |
| metrics-reader-role | "" | pods, services | get, list |

### RBAC - Role Bindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| manager-rolebinding | cluster-wide | manager-role | kueue-system/controller-manager |
| leader-election-rolebinding | kueue-system | leader-election-role | kueue-system/controller-manager |
| metrics-auth-rolebinding | cluster-wide | metrics-auth-role | system:authenticated |

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| webhook-server-cert | kubernetes.io/tls | TLS certificate for webhook server | cert-manager or internal cert management | Yes (cert-manager) |

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| /metrics | GET | Bearer Token (ServiceAccount) | Kubernetes RBAC | metrics-auth-role ClusterRole |
| Webhook endpoints | POST | mTLS (K8s API Server client cert) | Kubernetes API Server | Webhook server validates via API server proxy |
| Visibility API | GET | Kubernetes API Authentication | Kubernetes API Server | Standard K8s RBAC on visibility.kueue.x-k8s.io API group |
| CRD API | GET, LIST, WATCH, CREATE, UPDATE, PATCH, DELETE | Kubernetes API Authentication | Kubernetes API Server | RBAC ClusterRoles (viewer/editor roles) |

### Network Policies

| Policy Name | Namespace | Pod Selector | Ingress Rules | Egress Rules |
|-------------|-----------|--------------|---------------|--------------|
| webhook-server | kueue-system | All pods | Allow TCP/9443 from any | N/A |

## Data Flows

### Flow 1: Job Submission and Queueing

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User/System | Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | User credentials |
| 2 | Kubernetes API Server | Kueue Webhook Server | 9443/TCP | HTTPS | TLS 1.2+ | K8s API mTLS |
| 3 | Kueue Webhook | Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | Service Account Token |
| 4 | Kueue Controller | Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | Service Account Token |

### Flow 2: Workload Admission

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Kueue Controller | Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | Service Account Token |
| 2 | Kueue Controller | Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | Service Account Token |
| 3 | Kueue Controller | AdmissionCheck Controllers | Varies | Varies | Varies | Varies |

### Flow 3: Metrics Collection

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Prometheus | Kueue Metrics Service | 8443/TCP | HTTPS | TLS 1.2+ | Bearer Token |

### Flow 4: Visibility API Query

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User/Client | Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | User credentials |
| 2 | Kubernetes API Server | Visibility Server | 8082/TCP | HTTPS | TLS 1.2+ | Service Account Token |

### Flow 5: Multi-Cluster Job Distribution

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Kueue Controller | Remote K8s API Server | 6443/TCP | HTTPS | TLS 1.2+ | Kubeconfig credentials |
| 2 | Kueue Controller | Remote K8s API Server | 6443/TCP | HTTPS | TLS 1.2+ | Kubeconfig credentials |

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| Kubernetes API Server | REST API | 6443/TCP | HTTPS | TLS 1.2+ | Watch/reconcile CRDs, Jobs, Pods |
| Batch Jobs | CRD Watch/Webhook | 9443/TCP | HTTPS | TLS 1.2+ | Queue batch/v1 Jobs |
| Training Operator (Kubeflow) | CRD Watch/Webhook | 9443/TCP | HTTPS | TLS 1.2+ | Queue TFJob, PyTorchJob, MPIJob, etc. |
| KubeRay Operator | CRD Watch/Webhook | 9443/TCP | HTTPS | TLS 1.2+ | Queue RayJob and RayCluster |
| CodeFlare Operator | CRD Watch | 6443/TCP | HTTPS | TLS 1.2+ | Queue AppWrapper workloads |
| Cluster Autoscaler | ProvisioningRequest API | 6443/TCP | HTTPS | TLS 1.2+ | Auto-provision nodes for queued workloads |
| Prometheus | Metrics Scrape | 8443/TCP | HTTPS | TLS 1.2+ | Collect queue metrics, resource usage, admission performance |

## Prometheus Metrics

### Key Metrics Exposed

| Metric | Type | Labels | Purpose |
|--------|------|--------|---------|
| kueue_cluster_queue_resource_usage | Gauge | cluster_queue, resource | Current resource usage in ClusterQueue |
| kueue_cluster_queue_nominal_quota | Gauge | cluster_queue, resource | Nominal quota configured for ClusterQueue |
| kueue_cluster_queue_resource_reservation | Gauge | cluster_queue, resource | Reserved resources for pending workloads |
| kueue_pending_workloads | Gauge | cluster_queue, status | Number of pending workloads in ClusterQueue |
| kueue_admitted_workloads_total | Counter | cluster_queue | Total workloads admitted |
| kueue_admission_wait_time_seconds | Histogram | cluster_queue | Time workloads wait before admission |

### Prometheus Alerts

| Alert | Severity | Condition | Purpose |
|-------|----------|-----------|---------|
| KueuePodDown | critical | kueue pod not ready for 5m | Detect Kueue controller unavailability |
| LowClusterQueueResourceUsage | info | Resource usage < 20% for 1 day | Identify underutilized queues |
| ResourceReservationExceedsQuota | info | Reservation > 10x quota for 10m | Detect queue oversubscription |
| PendingWorkloadPods | info | Pods pending > 3 days | Identify stuck workloads |

## Configuration

### Controller Configuration

| Parameter | Default | Purpose |
|-----------|---------|---------|
| health.healthProbeBindAddress | :8081 | Health check endpoint binding |
| metrics.bindAddress | :8443 | Metrics endpoint binding |
| webhook.port | 9443 | Webhook server port |
| leaderElection.leaderElect | true | Enable leader election for HA |
| controller.groupKindConcurrency.Job.batch | 5 | Concurrent reconciliations for Jobs |
| controller.groupKindConcurrency.Workload | 5 | Concurrent reconciliations for Workloads |
| clientConnection.qps | 50 | K8s API client QPS limit |
| clientConnection.burst | 100 | K8s API client burst limit |
| waitForPodsReady.enable | true | Wait for pod readiness before considering workload running |

### Integrated Frameworks

- batch/job (Kubernetes Batch Jobs)
- kubeflow.org/mpijob (MPI Training Jobs)
- kubeflow.org/pytorchjob (PyTorch Training Jobs)
- kubeflow.org/tfjob (TensorFlow Training Jobs)
- kubeflow.org/xgboostjob (XGBoost Training Jobs)
- kubeflow.org/mxjob (MXNet Training Jobs)
- kubeflow.org/paddlejob (PaddlePaddle Training Jobs)
- ray.io/rayjob (Ray Jobs)
- ray.io/raycluster (Ray Clusters)
- jobset.x-k8s.io/jobset (JobSets)
- workload.codeflare.dev/AppWrapper (AppWrapper)
- pod (Plain Pods - optional)

## Recent Changes

| Commit | Date | Changes |
|---------|------|---------|
| 0f775887e | 2026 | - Update Konflux references (#270) |
| d29226007 | 2026 | - Update registry.access.redhat.com/ubi8/go-toolset:1.22 Docker digest to c7ebff7 (#267) |
| 2e8ae1d85 | 2026 | - Update Konflux references (#262) |
| b29a4e596 | 2026 | - Update Konflux references to b9cb1e1 (#257) |
| fdf309d52 | 2026 | - Update Konflux references to 944e769 (#251) |
| e177e1e3c | 2026 | - Update Konflux references (#240) |
| 61c7be7da | 2026 | - Update Konflux references to 8b6f22f (#233) |
| 43f646713 | 2026 | - Update registry.access.redhat.com/ubi8/go-toolset:1.22 Docker digest to 2a324cf (#223) |
| 8119cb698 | 2026 | - Update registry.redhat.io/ubi8/ubi-minimal Docker digest to c38cc77 (#213) |
| 51d217d86 | 2026 | - Update registry.access.redhat.com/ubi8/go-toolset:1.22 Docker digest to 1f949a7 (#212) |

## Deployment Architecture

### Container Images

| Container | Base Image | Build Method | Purpose |
|-----------|------------|--------------|---------|
| odh-kueue-controller | registry.redhat.io/ubi8/ubi-minimal | Konflux (Dockerfile.konflux) | Main controller manager |

### Deployment Configuration

| Parameter | Value | Purpose |
|-----------|-------|---------|
| Replicas | 1 | Single replica with leader election |
| Resource Limits | CPU: 2, Memory: 512Mi | Controller manager resource limits |
| Resource Requests | CPU: 500m, Memory: 512Mi | Controller manager resource requests |
| Service Account | controller-manager | Identity for K8s API access |
| Security Context | runAsNonRoot: true, allowPrivilegeEscalation: false | Pod security hardening |

### Kustomize Overlays

| Overlay | Purpose |
|---------|---------|
| config/default | Standard deployment with all components |
| config/rhoai | RHOAI-specific customizations (NetworkPolicy, Prometheus rules, metrics service) |
| config/dev | Development environment configuration |
| config/alpha-enabled | Enable alpha features |

## Design Patterns

### Queueing Strategies

- **StrictFIFO**: Workloads admitted strictly in submission order
- **BestEffortFIFO**: FIFO with opportunistic resource borrowing

### Resource Management

- **Resource Flavors**: Define heterogeneous resource types (e.g., different GPU models)
- **Cohorts**: Group ClusterQueues for resource sharing across tenants
- **Preemption**: Reclaim resources from lower-priority workloads
- **Dynamic Reclaim**: Release quota as job pods complete

### Admission Checks

- External validation before workload admission
- Integration with provisioning requests for auto-scaling
- Custom admission check controllers can be developed

## Operational Considerations

### High Availability

- Leader election enabled for controller manager
- Multiple replicas can be deployed (only leader reconciles)
- Webhook server runs in all pods for load distribution

### Scalability

- Configurable concurrency per resource type
- Efficient queue indexing for fast workload lookup
- Supports thousands of workloads across hundreds of queues

### Monitoring

- Comprehensive Prometheus metrics for queue depth, resource usage, admission latency
- Prometheus alerts for pod health, resource utilization, stuck workloads
- Visibility API for real-time queue inspection

### Troubleshooting

- Health and readiness probes for pod lifecycle management
- Structured logging with configurable log levels
- Status conditions on CRDs for reconciliation state
- Events generated for significant workload state changes
