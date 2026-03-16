# Component: Kueue

## Metadata
- **Repository**: https://github.com/red-hat-data-services/kueue.git
- **Version**: 1f8867691 (rhoai-2.13)
- **Distribution**: RHOAI
- **Languages**: Go
- **Deployment Type**: Kubernetes Operator (Job Queueing Controller)

## Purpose
**Short**: Kubernetes job queueing controller that manages when jobs should be admitted to start based on resource availability and priorities.

**Detailed**: Kueue is a Kubernetes-native job queueing system that provides sophisticated resource management and workload scheduling capabilities. It acts as a job-level manager that decides when a job should be admitted to start (allowing pods to be created) and when it should stop (requiring active pods to be deleted). The system supports multiple queueing strategies (StrictFIFO, BestEffortFIFO), priority-based scheduling, resource fair sharing, preemption, and dynamic resource reclaim. Kueue integrates with various job frameworks including Kubernetes Batch Jobs, Kubeflow training jobs (TensorFlow, PyTorch, MPI, etc.), Ray jobs and clusters, JobSets, and standalone pods. It provides admission checks for advanced features like cluster autoscaling integration and multi-cluster workload distribution. The component exposes a visibility API for monitoring pending workloads and queue status, along with comprehensive Prometheus metrics for observability.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| Manager | Controller Deployment | Main reconciliation loop managing ClusterQueues, LocalQueues, Workloads, ResourceFlavors, and AdmissionChecks |
| Webhook Server | Admission Webhook | Mutating and validating webhooks for job frameworks and Kueue CRDs |
| Visibility Server | API Extension Server | REST API for querying pending workload summaries and queue status |
| Queue Manager | In-Memory Cache | Manages workload queues and scheduling decisions |
| Scheduler | Scheduling Engine | Determines workload admission based on resource availability and priorities |
| Job Framework Integrations | Plugin System | Integrates with Batch, Kubeflow, Ray, JobSet, and Pod workloads |
| Admission Check Controllers | Extension Points | Handles provisioning requests and multi-cluster coordination |

## APIs Exposed

### Custom Resource Definitions (CRDs)

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| kueue.x-k8s.io | v1beta1 | ClusterQueue | Cluster | Defines cluster-wide resource quotas and queueing policies |
| kueue.x-k8s.io | v1beta1 | LocalQueue | Namespaced | Namespace-scoped queue that references a ClusterQueue |
| kueue.x-k8s.io | v1beta1 | Workload | Namespaced | Abstract representation of a job's resource requirements and status |
| kueue.x-k8s.io | v1beta1 | ResourceFlavor | Cluster | Defines resource characteristics (node labels, taints) for quota management |
| kueue.x-k8s.io | v1beta1 | AdmissionCheck | Cluster | Defines external admission requirements before workload admission |
| kueue.x-k8s.io | v1beta1 | WorkloadPriorityClass | Cluster | Defines priority values for workload scheduling |
| kueue.x-k8s.io | v1beta1 | ProvisioningRequestConfig | Cluster | Configuration for cluster autoscaler integration |
| kueue.x-k8s.io | v1alpha1 | MultiKueueCluster | Cluster | Defines remote cluster connection for multi-cluster scheduling |
| kueue.x-k8s.io | v1alpha1 | MultiKueueConfig | Cluster | Configuration for multi-cluster workload distribution |

### HTTP Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /healthz | GET | 8081/TCP | HTTP | None | None | Liveness probe endpoint |
| /readyz | GET | 8081/TCP | HTTP | None | None | Readiness probe endpoint |
| /metrics | GET | 8080/TCP | HTTP | None | None | Prometheus metrics endpoint |
| /mutate-* | POST | 9443/TCP | HTTPS | TLS 1.2+ | K8s API Server mTLS | Mutating webhooks for job resources and Kueue CRDs |
| /validate-* | POST | 9443/TCP | HTTPS | TLS 1.2+ | K8s API Server mTLS | Validating webhooks for job resources and Kueue CRDs |

### Visibility API (Aggregated API)

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /apis/visibility.kueue.x-k8s.io/v1alpha1/clusterqueues/{name}/pendingworkloads | GET | 8082/TCP | HTTPS | TLS (internal cert) | K8s RBAC | Query pending workloads in a ClusterQueue |
| /apis/visibility.kueue.x-k8s.io/v1alpha1/namespaces/{ns}/localqueues/{name}/pendingworkloads | GET | 8082/TCP | HTTPS | TLS (internal cert) | K8s RBAC | Query pending workloads in a LocalQueue |

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| Kubernetes | 1.22+ | Yes | Platform for operator and workload execution |
| cert-manager | Any | No | TLS certificate provisioning for webhooks (alternative to internal cert management) |
| Prometheus Operator | Any | No | Metrics collection via PodMonitor |
| Cluster Autoscaler | Any | No | Dynamic cluster scaling via ProvisioningRequests |

### Internal ODH/RHOAI Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| Kubeflow Training Operator | Webhooks, CRD Watch | Queue management for ML training jobs (TFJob, PyTorchJob, MPIJob, etc.) |
| Ray Operator | Webhooks, CRD Watch | Queue management for Ray jobs and clusters |
| CodeFlare Operator | CRD Watch | Queue management for AppWrapper workloads |

## Network Architecture

### Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| kueue-webhook-service | ClusterIP | 443/TCP | 9443 | HTTPS | TLS 1.2+ | K8s API Server mTLS | Internal (K8s API Server) |
| kueue-metrics-service | ClusterIP | 8080/TCP | 8080 | HTTP | None | None | Internal (Prometheus) |
| kueue-visibility-server | ClusterIP | 443/TCP | 8082 | HTTPS | TLS (internal cert) | K8s RBAC | Internal (API Aggregation) |

### Ingress

| Name | Type | Hosts | Port | Protocol | Encryption | TLS Mode | Exposure |
|------|------|-------|------|----------|------------|----------|----------|
| N/A | N/A | N/A | N/A | N/A | N/A | N/A | No external ingress (internal-only component) |

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token | Watch and manage workloads, jobs, pods |
| Remote Clusters (MultiKueue) | 6443/TCP | HTTPS | TLS 1.2+ | KubeConfig Credentials | Multi-cluster workload distribution |
| Cluster Autoscaler API | 443/TCP | HTTPS | TLS 1.2+ | K8s RBAC | Create/manage ProvisioningRequests |

## Security

### RBAC - Cluster Roles

| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|
| kueue-manager-role | kueue.x-k8s.io | admissionchecks, clusterqueues, localqueues, workloads, resourceflavors, workloadpriorityclasses, provisioningrequestconfigs | create, delete, get, list, patch, update, watch |
| kueue-manager-role | "" | events, pods, namespaces, limitranges, secrets | get, list, watch, create, patch, update |
| kueue-manager-role | "" | pods/finalizers, pods/status | get, patch, update |
| kueue-manager-role | batch | jobs, jobs/status, jobs/finalizers | get, list, patch, update, watch |
| kueue-manager-role | kubeflow.org | mpijobs, pytorchjobs, tfjobs, mxjobs, paddlejobs, xgboostjobs | get, list, patch, update, watch |
| kueue-manager-role | kubeflow.org | mpijobs/status, pytorchjobs/status, tfjobs/status, etc. | get, update |
| kueue-manager-role | ray.io | rayjobs, rayclusters | get, list, patch, update, watch |
| kueue-manager-role | jobset.x-k8s.io | jobsets, jobsets/status | get, list, patch, update, watch |
| kueue-manager-role | autoscaling.x-k8s.io | provisioningrequests, provisioningrequests/status | create, delete, get, list, patch, update, watch |
| kueue-manager-role | admissionregistration.k8s.io | mutatingwebhookconfigurations, validatingwebhookconfigurations | get, list, update, watch |
| kueue-manager-role | flowcontrol.apiserver.k8s.io | flowschemas, prioritylevelconfigurations | list, watch, patch (status) |
| kueue-batch-admin-role | kueue.x-k8s.io | clusterqueues, localqueues, workloads, resourceflavors | get, list, watch, create, update, patch, delete |
| kueue-batch-user-role | kueue.x-k8s.io | localqueues | get, list, watch, create, update |
| kueue-clusterqueue-editor-role | kueue.x-k8s.io | clusterqueues | get, list, watch, create, update, patch, delete |
| kueue-clusterqueue-viewer-role | kueue.x-k8s.io | clusterqueues | get, list, watch |
| kueue-localqueue-editor-role | kueue.x-k8s.io | localqueues | get, list, watch, create, update, patch, delete |
| kueue-localqueue-viewer-role | kueue.x-k8s.io | localqueues | get, list, watch |
| kueue-proxy-role | authentication.k8s.io | tokenreviews | create |
| kueue-proxy-role | authorization.k8s.io | subjectaccessreviews | create |

### RBAC - Role Bindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| kueue-leader-election-rolebinding | opendatahub | kueue-leader-election-role | kueue-controller-manager |
| kueue-manager-rolebinding | Cluster | kueue-manager-role | opendatahub/kueue-controller-manager |
| kueue-proxy-rolebinding | Cluster | kueue-proxy-role | opendatahub/kueue-controller-manager |
| kueue-batch-user-rolebinding | kube-system | kueue-batch-user-role | kueue-controller-manager |

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| kueue-webhook-server-cert | kubernetes.io/tls | Webhook TLS certificate | cert-manager or Internal Cert Manager | Yes |
| kueue-visibility-server-cert | kubernetes.io/tls | Visibility API TLS certificate | Internal Cert Manager | Yes |
| multikueue-cluster-credentials | Opaque | KubeConfig for remote clusters | User/Admin | No |

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| /mutate-*, /validate-* | POST | mTLS Client Cert | K8s API Server | API Server validates webhook caller identity |
| /metrics | GET | None | Application | Open to internal network (scraped by Prometheus) |
| /healthz, /readyz | GET | None | Application | Open to kubelet health checks |
| /apis/visibility.kueue.x-k8s.io/* | GET | Bearer Token (ServiceAccount) | K8s API Server | K8s RBAC via API aggregation |

### Network Policies

| Policy Name | Namespace | Selectors | Ingress Rules | Egress Rules |
|-------------|-----------|-----------|---------------|--------------|
| kueue-webhook-server | opendatahub | app.kubernetes.io/name=kueue | Allow TCP/9443 from any | N/A |

## Data Flows

### Flow 1: Job Submission and Admission

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User/Controller | K8s API Server | 6443/TCP | HTTPS | TLS 1.2+ | Bearer Token |
| 2 | K8s API Server | Kueue Webhook | 9443/TCP | HTTPS | TLS 1.2+ | mTLS |
| 3 | Kueue Manager | K8s API Server | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 4 | Kueue Manager | Kueue Manager (internal queue) | In-Process | N/A | N/A | N/A |
| 5 | Kueue Manager | K8s API Server | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |

**Description**: User submits a Job → API Server calls Kueue mutating webhook to inject queue name → Kueue controller creates Workload CR → Scheduler evaluates admission → Updates Workload status and Job suspend field.

### Flow 2: Visibility API Query

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User/CLI | K8s API Server | 6443/TCP | HTTPS | TLS 1.2+ | Bearer Token |
| 2 | K8s API Server | Kueue Visibility Server | 8082/TCP | HTTPS | TLS (internal) | API Aggregation |
| 3 | Kueue Visibility Server | Kueue Manager (cache query) | In-Process | N/A | N/A | N/A |

**Description**: User queries pending workloads via kubectl → API Server proxies to Visibility API extension → Returns pending workload summaries from in-memory cache.

### Flow 3: Metrics Collection

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Prometheus | Kueue Metrics Service | 8080/TCP | HTTP | None | None |

**Description**: Prometheus scrapes /metrics endpoint for workload queue metrics, admission statistics, and resource utilization.

### Flow 4: Multi-Cluster Workload Distribution (MultiKueue)

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Kueue Manager | Remote Cluster API | 6443/TCP | HTTPS | TLS 1.2+ | KubeConfig Credentials |
| 2 | Kueue Manager | Remote Cluster API | 6443/TCP | HTTPS | TLS 1.2+ | KubeConfig Credentials |

**Description**: Manager cluster distributes workload to remote clusters → Creates workload on remote cluster → Monitors remote workload status → Syncs results back to manager cluster.

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| Kubernetes Batch Jobs | Webhooks + CRD Watch | 9443/TCP | HTTPS | TLS 1.2+ | Queue management for batch/v1 Jobs |
| Kubeflow Training Operator | Webhooks + CRD Watch | 9443/TCP | HTTPS | TLS 1.2+ | Queue TFJobs, PyTorchJobs, MPIJobs, etc. |
| Ray Operator | Webhooks + CRD Watch | 9443/TCP | HTTPS | TLS 1.2+ | Queue RayJobs and RayClusters |
| JobSet Controller | Webhooks + CRD Watch | 9443/TCP | HTTPS | TLS 1.2+ | Queue JobSets |
| CodeFlare AppWrapper | CRD Watch | N/A | N/A | N/A | External framework integration for AppWrappers |
| Cluster Autoscaler | API Calls | 443/TCP | HTTPS | TLS 1.2+ | Create ProvisioningRequests for guaranteed node provisioning |
| Prometheus | Metrics Scrape | 8080/TCP | HTTP | None | Workload queue and resource metrics collection |

## Deployment Configuration

### Container Images

| Image | Build File | Purpose |
|-------|------------|---------|
| odh-kueue-controller | Dockerfile.konflux | Main controller manager binary |

### Environment Variables

| Variable | Source | Purpose |
|----------|--------|---------|
| N/A | N/A | Configuration via ConfigMap and controller flags |

### ConfigMaps

| Name | Namespace | Purpose |
|------|-----------|---------|
| kueue-rhoai-config | opendatahub | Image reference for kustomize substitution |
| kueue-manager-config | opendatahub | Controller manager configuration (ports, integrations, features) |

### Resource Limits

| Container | CPU Request | CPU Limit | Memory Request | Memory Limit |
|-----------|-------------|-----------|----------------|--------------|
| manager | 500m | 500m | 512Mi | 512Mi |

## Monitoring and Observability

### Prometheus Metrics

| Metric Prefix | Purpose |
|---------------|---------|
| kueue_admitted_workloads_total | Total number of admitted workloads |
| kueue_pending_workloads | Current number of pending workloads per queue |
| kueue_cluster_queue_* | ClusterQueue resource usage and quota metrics |
| kueue_admission_attempt_duration_seconds | Histogram of admission check durations |
| kueue_admission_checks_* | Admission check execution metrics |

### Health Probes

| Probe Type | Path | Port | Initial Delay | Period |
|------------|------|------|---------------|--------|
| Liveness | /healthz | 8081 | 15s | 20s |
| Readiness | /readyz | 8081 | 5s | 10s |

## Feature Flags and Configuration

### Enabled Integrations (RHOAI)

- batch/job (Kubernetes Batch Jobs)
- kubeflow.org/mpijob (MPI Operator)
- ray.io/rayjob (Ray Jobs)
- ray.io/raycluster (Ray Clusters)
- jobset.x-k8s.io/jobset (JobSet)
- kubeflow.org/mxjob, pytorchjob, tfjob, paddlejob, xgboostjob (Kubeflow Training)
- workload.codeflare.dev/AppWrapper (CodeFlare external framework)

### Controller Settings

| Setting | Value | Purpose |
|---------|-------|---------|
| healthProbeBindAddress | :8081 | Health check endpoint port |
| metricsBindAddress | :8080 | Prometheus metrics port |
| webhookPort | 9443 | Admission webhook listener port |
| leaderElection | true | Enable leader election for HA |
| waitForPodsReady.enable | true | Wait for pod readiness before considering workload active |
| waitForPodsReady.blockAdmission | false | Don't block new admissions while waiting for pods |
| enableClusterQueueResources | true | Export ClusterQueue metrics |

## Recent Changes

| Commit | Date | Changes |
|--------|------|---------|
| 1f8867691 | Recent | Update Konflux references (#319) |
| 0363bdf4b | Recent | Update Konflux references (#318) |
| f86768c25 | Recent | Update Konflux references to d00d159 (#311) |
| c86d7bf53 | Recent | Update Konflux references to d00d159 (#310) |
| 87663fa78 | Recent | Update Konflux references (#303) |
| c984d8f3e | Recent | Update Konflux references (#302) |
| 9b647eb99 | Recent | Update Konflux references (#301) |
| 6d4e4665b | Recent | Update Konflux references to 66401e3 (#297) |
| b167a7b1e | Recent | Update Konflux references to 66401e3 (#296) |
| ddd6697c1 | Recent | Update Konflux references (#294) |

**Summary**: Recent commits focus on updating Konflux build references, indicating active CI/CD pipeline maintenance for RHOAI distribution.

## Additional Notes

### Queueing Strategies

Kueue supports two queueing strategies configured per ClusterQueue:

1. **StrictFIFO**: Workloads are admitted in strict FIFO order within their priority class
2. **BestEffortFIFO**: Attempts FIFO but may admit smaller workloads out of order if they fit available quota

### Preemption

ClusterQueues can be configured with preemption policies:
- **LowerPriority**: Evict lower-priority workloads to admit higher-priority ones
- **LowerOrNewerEqualPriority**: Evict lower priority or newer equal-priority workloads
- **Any**: Preempt any workload to reclaim resources

### Cohorts

Multiple ClusterQueues can form a cohort to share quota and borrow/lend resources between teams while maintaining fair sharing policies.

### Admission Checks

Admission checks provide extension points for:
- **Provisioning**: Integration with cluster autoscaler for guaranteed node provisioning
- **MultiKueue**: Multi-cluster workload distribution and coordination
- **Custom**: External systems can implement custom admission requirements

### Visibility Features

The visibility API provides:
- Query pending workloads in ClusterQueue or LocalQueue
- Pagination support (offset/limit parameters)
- Position tracking (workload's position in queue)
- Priority information for scheduling decisions
