# Component: Kueue

## Metadata
- **Repository**: https://github.com/red-hat-data-services/kueue.git
- **Version**: v-2160-163-g191c1eac5
- **Branch**: rhoai-2.16
- **Distribution**: RHOAI
- **Languages**: Go
- **Deployment Type**: Kubernetes Controller/Operator
- **Namespace**: opendatahub (in RHOAI)

## Purpose
**Short**: Kubernetes job queueing controller that manages job admission and resource allocation based on priorities and quotas.

**Detailed**: Kueue is a job-level manager for Kubernetes that decides when jobs should be admitted to start (allowing pods to be created) and when they should stop (deleting active pods). It provides job queueing based on priorities with different strategies (StrictFIFO and BestEffortFIFO), resource fair sharing and preemption between different tenants, and dynamic resource reclaim as job pods complete.

Kueue integrates with multiple job frameworks including Kubernetes Batch Jobs, Kubeflow training jobs (MPIJob, PyTorchJob, TFJob, XGBoostJob, MXJob, PaddleJob), Ray (RayJob, RayCluster), JobSet, and plain Pods. It supports admission checks for internal or external components to influence workload admission, advanced autoscaling through cluster-autoscaler's provisioningRequest, and partial admission allowing jobs to run with smaller parallelism based on available quota.

The system provides multi-cluster job distribution through MultiKueue, resource flavor fungibility for quota borrowing and preemption, and comprehensive monitoring through built-in Prometheus metrics and Kubernetes Conditions.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| kueue-controller-manager | Deployment | Main controller managing workload admission and queue reconciliation |
| webhook-service | Service | Admission webhook for mutating and validating job resources |
| visibility-server | APIService | Extended API server providing visibility into pending workloads |
| metrics-service | Service | Prometheus metrics endpoint for monitoring queue and workload state |

## APIs Exposed

### Custom Resource Definitions (CRDs)

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| kueue.x-k8s.io | v1beta1 | ClusterQueue | Cluster | Cluster-wide queue managing resource quotas and admission policies |
| kueue.x-k8s.io | v1beta1 | LocalQueue | Namespaced | Namespace-scoped queue mapping workloads to ClusterQueues |
| kueue.x-k8s.io | v1beta1 | Workload | Namespaced | Abstract representation of job resource requirements |
| kueue.x-k8s.io | v1beta1 | ResourceFlavor | Cluster | Defines resource variants (node types, zones) for quota management |
| kueue.x-k8s.io | v1beta1 | WorkloadPriorityClass | Cluster | Defines priority levels for workload admission ordering |
| kueue.x-k8s.io | v1beta1 | AdmissionCheck | Cluster | Configures pre-admission validation checks for workloads |
| kueue.x-k8s.io | v1beta1 | ProvisioningRequestConfig | Cluster | Configuration for cluster-autoscaler provisioning requests |
| kueue.x-k8s.io | v1alpha1 | MultiKueueCluster | Cluster | Defines remote clusters for multi-cluster job distribution |
| kueue.x-k8s.io | v1alpha1 | MultiKueueConfig | Cluster | Configuration for multi-cluster queue management |

### HTTP Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /healthz | GET | 8081/TCP | HTTP | None | None | Controller liveness probe |
| /readyz | GET | 8081/TCP | HTTP | None | None | Controller readiness probe |
| /metrics | GET | 8443/TCP | HTTPS | TLS 1.2+ | Bearer Token | Prometheus metrics endpoint |
| /mutate-batch-v1-job | POST | 9443/TCP | HTTPS | TLS 1.2+ | K8s API Server | Mutating webhook for Batch Jobs |
| /validate-batch-v1-job | POST | 9443/TCP | HTTPS | TLS 1.2+ | K8s API Server | Validating webhook for Batch Jobs |
| /mutate-kueue-x-k8s-io-v1beta1-workload | POST | 9443/TCP | HTTPS | TLS 1.2+ | K8s API Server | Mutating webhook for Workloads |
| /validate-kueue-x-k8s-io-v1beta1-workload | POST | 9443/TCP | HTTPS | TLS 1.2+ | K8s API Server | Validating webhook for Workloads |
| /mutate-jobset-x-k8s-io-v1alpha2-jobset | POST | 9443/TCP | HTTPS | TLS 1.2+ | K8s API Server | Mutating webhook for JobSets |
| /mutate-kubeflow-org-v1-pytorchjob | POST | 9443/TCP | HTTPS | TLS 1.2+ | K8s API Server | Mutating webhook for PyTorchJobs |
| /mutate-kubeflow-org-v1-tfjob | POST | 9443/TCP | HTTPS | TLS 1.2+ | K8s API Server | Mutating webhook for TFJobs |
| /mutate-ray-io-v1-rayjob | POST | 9443/TCP | HTTPS | TLS 1.2+ | K8s API Server | Mutating webhook for RayJobs |
| /mutate-ray-io-v1-raycluster | POST | 9443/TCP | HTTPS | TLS 1.2+ | K8s API Server | Mutating webhook for RayClusters |
| /mutate--v1-pod | POST | 9443/TCP | HTTPS | TLS 1.2+ | K8s API Server | Mutating webhook for Pods |

### Aggregated API Services

| Group | Version | Service | Purpose |
|-------|---------|---------|---------|
| visibility.kueue.x-k8s.io | v1alpha1 | visibility-server:443 | Extended API for querying pending workloads across queues |

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| Kubernetes | 1.25+ | Yes | Core platform for controller runtime and API extensions |
| cert-manager | Any | No | Optional TLS certificate management for webhooks |
| Prometheus Operator | Any | No | Optional metrics collection via ServiceMonitor |

### Internal ODH Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| Kubeflow Training Operator | CRD Watching | Queue management for ML training jobs (PyTorchJob, TFJob, MPIJob, etc.) |
| Ray Operator | CRD Watching | Queue management for Ray distributed workloads |
| JobSet Controller | CRD Watching | Queue management for multi-job workflows |

## Network Architecture

### Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| kueue-webhook-service | ClusterIP | 443/TCP | 9443 | HTTPS | TLS 1.2+ | K8s API Server mTLS | Internal |
| kueue-visibility-server | ClusterIP | 443/TCP | 8082 | HTTPS | TLS 1.2+ | K8s API Server mTLS | Internal |
| kueue-metrics-service | ClusterIP | 8443/TCP | 8443 | HTTPS | TLS 1.2+ | Bearer Token | Internal |

### Ingress

| Name | Type | Hosts | Port | Protocol | Encryption | TLS Mode | Exposure |
|------|------|-------|------|----------|------------|----------|----------|
| N/A | N/A | N/A | N/A | N/A | N/A | N/A | No external ingress configured |

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token | Watch/reconcile jobs and workloads |
| cluster-autoscaler | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token | Create ProvisioningRequests for autoscaling |

### Network Policies

| Policy Name | Namespace | Pod Selector | Ingress Rules |
|-------------|-----------|--------------|---------------|
| kueue-webhook-server | opendatahub | All pods (empty selector) | Allow TCP/9443 from any source |

## Security

### RBAC - Cluster Roles

| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|
| kueue-manager-role | "" | events | create, patch, update, watch |
| kueue-manager-role | "" | pods | delete, get, list, patch, update, watch |
| kueue-manager-role | "" | pods/finalizers | get, update |
| kueue-manager-role | "" | pods/status | get, patch |
| kueue-manager-role | "" | secrets | get, list, update, watch |
| kueue-manager-role | "" | limitranges, namespaces | get, list, watch |
| kueue-manager-role | batch | jobs | get, list, patch, update, watch |
| kueue-manager-role | batch | jobs/finalizers | get, patch, update |
| kueue-manager-role | batch | jobs/status | get, patch, update |
| kueue-manager-role | kueue.x-k8s.io | clusterqueues, localqueues, workloads, admissionchecks | create, delete, get, list, patch, update, watch |
| kueue-manager-role | kueue.x-k8s.io | clusterqueues/status, localqueues/status, workloads/status, admissionchecks/status | get, patch, update |
| kueue-manager-role | kueue.x-k8s.io | resourceflavors | delete, get, list, update, watch |
| kueue-manager-role | kueue.x-k8s.io | workloadpriorityclasses, provisioningrequestconfigs, multikueueclusters, multikueueconfigs | get, list, watch |
| kueue-manager-role | kubeflow.org | mpijobs, pytorchjobs, tfjobs, xgboostjobs, mxjobs, paddlejobs | get, list, patch, update, watch |
| kueue-manager-role | kubeflow.org | mpijobs/finalizers, pytorchjobs/finalizers, tfjobs/finalizers, xgboostjobs/finalizers, mxjobs/finalizers, paddlejobs/finalizers | get, update |
| kueue-manager-role | kubeflow.org | mpijobs/status, pytorchjobs/status, tfjobs/status, xgboostjobs/status, mxjobs/status, paddlejobs/status | get, update |
| kueue-manager-role | ray.io | rayjobs, rayclusters | get, list, patch, update, watch |
| kueue-manager-role | ray.io | rayjobs/finalizers, rayclusters/finalizers | get, update |
| kueue-manager-role | ray.io | rayjobs/status, rayclusters/status | get, update |
| kueue-manager-role | jobset.x-k8s.io | jobsets | get, list, patch, update, watch |
| kueue-manager-role | jobset.x-k8s.io | jobsets/finalizers | get, update |
| kueue-manager-role | jobset.x-k8s.io | jobsets/status | get, patch, update |
| kueue-manager-role | autoscaling.x-k8s.io | provisioningrequests | create, delete, get, list, patch, update, watch |
| kueue-manager-role | autoscaling.x-k8s.io | provisioningrequests/status | get |
| kueue-manager-role | admissionregistration.k8s.io | mutatingwebhookconfigurations, validatingwebhookconfigurations | get, list, update, watch |
| kueue-manager-role | scheduling.k8s.io | priorityclasses | get, list, watch |
| kueue-manager-role | node.k8s.io | runtimeclasses | get, list, watch |
| kueue-manager-role | flowcontrol.apiserver.k8s.io | flowschemas, prioritylevelconfigurations | list, watch |
| kueue-manager-role | flowcontrol.apiserver.k8s.io | flowschemas/status | patch |
| kueue-clusterqueue-editor-role | kueue.x-k8s.io | clusterqueues | create, delete, get, list, patch, update, watch |
| kueue-clusterqueue-viewer-role | kueue.x-k8s.io | clusterqueues | get, list, watch |
| kueue-localqueue-editor-role | kueue.x-k8s.io | localqueues | create, delete, get, list, patch, update, watch |
| kueue-localqueue-viewer-role | kueue.x-k8s.io | localqueues | get, list, watch |
| kueue-workload-editor-role | kueue.x-k8s.io | workloads | create, delete, get, list, patch, update, watch |
| kueue-workload-viewer-role | kueue.x-k8s.io | workloads | get, list, watch |
| kueue-batch-admin-role | "" | events | create, update, watch |
| kueue-batch-admin-role | batch | jobs | create, delete, get, list, update, watch |
| kueue-batch-user-role | batch | jobs | create, delete, get, list, watch |
| kueue-metrics-reader-role | N/A | /metrics endpoint | get |

### RBAC - Role Bindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| kueue-leader-election-rolebinding | opendatahub | kueue-leader-election-role | kueue-controller-manager |
| kueue-manager-rolebinding | Cluster | kueue-manager-role (ClusterRole) | opendatahub:kueue-controller-manager |
| kueue-metrics-auth-rolebinding | opendatahub | kueue-metrics-auth-role | kueue-controller-manager |

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| kueue-webhook-server-cert | kubernetes.io/tls | TLS certificate for webhook server | cert-manager or internal cert generator | Yes (cert-manager) or No (internal) |
| kueue-visibility-server-cert | kubernetes.io/tls | TLS certificate for visibility API server | cert-manager or internal cert generator | Yes (cert-manager) or No (internal) |

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| /metrics (8443) | GET | Bearer Token (ServiceAccount JWT) | kube-rbac-proxy | Requires authentication via tokenreviews.authentication.k8s.io |
| Webhook endpoints (9443) | POST | mTLS (Kubernetes API Server client cert) | Kubernetes API Server | API server validates webhook TLS and calls webhook |
| Visibility API (8082) | GET, LIST, WATCH | mTLS (Kubernetes API Server client cert) | APIService aggregation layer | Kubernetes RBAC enforced by aggregation layer |
| Health endpoints (8081) | GET | None | Controller application | Unauthenticated for kubelet probes |

## Data Flows

### Flow 1: Job Submission and Admission

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User/CI | Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | User credentials |
| 2 | Kubernetes API Server | kueue-webhook-service | 9443/TCP | HTTPS | TLS 1.2+ | K8s API Server mTLS |
| 3 | kueue-webhook-service | Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 4 | kueue-controller-manager | Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |

### Flow 2: Workload Reconciliation

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | kueue-controller-manager | Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 2 | kueue-controller-manager | cluster-autoscaler (optional) | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |

### Flow 3: Metrics Collection

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Prometheus | kueue-metrics-service | 8443/TCP | HTTPS | TLS 1.2+ | Bearer Token (ServiceAccount) |

### Flow 4: Visibility API Queries

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | kubectl/User | Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | User credentials |
| 2 | Kubernetes API Server | kueue-visibility-server | 8082/TCP | HTTPS | TLS 1.2+ | K8s API Server mTLS |

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| Kubernetes API Server | REST API | 6443/TCP | HTTPS | TLS 1.2+ | Watch and reconcile jobs, workloads, and queue resources |
| Kubeflow Training Operator | CRD Watch | 6443/TCP | HTTPS | TLS 1.2+ | Manage admission for ML training jobs |
| Ray Operator | CRD Watch | 6443/TCP | HTTPS | TLS 1.2+ | Manage admission for Ray distributed workloads |
| JobSet Controller | CRD Watch | 6443/TCP | HTTPS | TLS 1.2+ | Manage admission for multi-job workflows |
| cluster-autoscaler | REST API | 443/TCP | HTTPS | TLS 1.2+ | Create ProvisioningRequests for node autoscaling |
| Prometheus | Metrics Scrape | 8443/TCP | HTTPS | TLS 1.2+ | Collect queue and workload metrics |

## Recent Changes

| Version/Commit | Date | Changes |
|----------------|------|---------|
| 191c1eac5 | 2026-03 | - Update UBI8 go-toolset base image digest<br>- Security updates for base images |
| dde1749cd | 2026-03 | - Update UBI8 go-toolset base image digest |
| ef37f95ef | 2026-03 | - Update UBI8 minimal base image digest |
| 6519be3fa | 2026-03 | - Sync PipelineRuns with konflux-central |
| 71385fa62 | 2026-02 | - Add Tekton PipelineRun configuration for Kueue Controller pull requests |
| 4a4a8aa29 | 2026-02 | - Fix Dockerfile syntax: correct stage name from 'builder' to 'BUILDER' in Dockerfile.konflux<br>- Update Dockerfile.rhoai to remove redundant 'FROM' keyword |
| 7d6db37da | 2026-02 | - Fix CVE-2025-61729<br>- Bump Go version for security |
| v-2160-163 | 2026-02 | - RHOAI 2.16 release branch<br>- Container image updates<br>- Konflux build pipeline integration |

## Deployment Configuration

### RHOAI-Specific Configuration

**Namespace**: opendatahub
**Name Prefix**: kueue-

**Included Components**:
- CRDs for all 9 Kueue resource types
- RBAC roles and bindings
- Controller manager deployment
- Internal certificate generation
- Webhook configurations (mutating and validating)
- Prometheus ServiceMonitor
- Network policy for webhook ingress

**Configuration Patches**:
- Manager configuration for RHOAI-specific settings
- Webhook configuration with proper namespace injection
- RBAC role extensions for additional permissions
- Metrics service configuration
- ClusterQueue viewer role customizations
- Default namespace removal for cluster-scoped operation

**Resource Limits**:
- CPU: 500m request, 2 CPU limit
- Memory: 512Mi request, 512Mi limit

## Monitoring and Observability

### Prometheus Metrics

**Endpoint**: https://kueue-metrics-service.opendatahub.svc:8443/metrics

**Key Metrics Categories**:
- Queue depth and pending workload counts
- Admission latency and throughput
- Resource quota utilization per ClusterQueue
- Workload state transitions
- Preemption events
- Admission check execution time

**ServiceMonitor Configuration**:
- Namespace: opendatahub
- Path: /metrics
- Port: https (8443)
- Scheme: HTTPS with insecure TLS skip (internal cert)
- Authentication: Bearer token from ServiceAccount

### Health Checks

| Endpoint | Port | Purpose | Probe Type |
|----------|------|---------|------------|
| /healthz | 8081 | Controller manager liveness | Liveness Probe |
| /readyz | 8081 | Controller manager readiness | Readiness Probe |

**Probe Configuration**:
- Liveness: initialDelaySeconds=15, periodSeconds=20
- Readiness: initialDelaySeconds=5, periodSeconds=10

## Operational Notes

### Queue Management Strategy

Kueue supports two queueing strategies configurable per ClusterQueue:
- **StrictFIFO**: Workloads admitted in strict order of creation time
- **BestEffortFIFO**: Attempts FIFO but may skip workloads that don't fit to prevent head-of-line blocking

### Resource Flavors

ResourceFlavors represent variations of resources (e.g., different node types, GPU models, availability zones). ClusterQueues can define quotas per ResourceFlavor, and Kueue will attempt flavor assignment based on:
- Workload requirements
- Quota availability
- Flavor assignment strategies (minimizing cost vs. minimizing borrowing)

### Multi-Cluster Support

MultiKueue (alpha) enables distributing workloads across multiple Kubernetes clusters:
- MultiKueueCluster defines remote cluster connection details
- MultiKueueConfig associates ClusterQueues with target clusters
- Workloads can be automatically dispatched to clusters with available quota

### Admission Checks

AdmissionChecks provide extensibility for pre-admission validation:
- Internal checks (e.g., ProvisioningRequest for autoscaling)
- External checks via custom controllers
- Workloads block admission until all configured checks pass

### Preemption

ClusterQueues support preemption policies to reclaim quota:
- **LowerPriority**: Preempt lower-priority workloads within same ClusterQueue
- **LowerOrNewerEqualPriority**: Extend preemption to newer equal-priority workloads
- Cohort-level preemption for resource sharing across ClusterQueues
