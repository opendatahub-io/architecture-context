# Component: Kueue

## Metadata
- **Repository**: https://github.com/red-hat-data-services/kueue.git
- **Version**: f99252525 (rhoai-2.8 branch)
- **Distribution**: RHOAI
- **Languages**: Go
- **Deployment Type**: Kubernetes Controller/Operator

## Purpose
**Short**: Job queueing controller for managing workload admission and resource allocation in Kubernetes clusters.

**Detailed**: Kueue is a Kubernetes-native job-level manager that decides when workloads should be admitted to start (allowing pods to be created) and when they should stop (deleting active pods). It provides sophisticated resource management capabilities including priority-based queueing with StrictFIFO and BestEffortFIFO strategies, resource fair sharing, preemption policies, and quota borrowing between different tenants. Kueue supports dynamic resource reclamation as job pods complete and integrates with popular workload frameworks including Kubernetes Jobs, Kubeflow training jobs (TFJob, PyTorchJob, MPIJob, etc.), Ray (RayJob, RayCluster), and JobSet. The controller manages resource allocation through ClusterQueues and LocalQueues, allowing administrators to define resource quotas with different flavors (e.g., different GPU types, node pools) and enabling workloads to efficiently share cluster resources while respecting organizational policies and priorities.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| kueue-controller-manager | Deployment | Main controller managing workload admission, queueing, and resource allocation |
| webhook-service | Service | Admission webhook server for mutating and validating workload resources |
| visibility-server | APIService | Aggregated API server providing visibility into pending workloads |
| AdmissionCheck Controller | Controller | Validates workloads against admission check requirements |
| ClusterQueue Controller | Controller | Manages cluster-wide resource quotas and workload admission |
| LocalQueue Controller | Controller | Manages namespace-scoped queues linked to ClusterQueues |
| ResourceFlavor Controller | Controller | Manages resource flavor definitions (node types, GPU types, etc.) |
| Workload Controller | Controller | Reconciles workload admission, suspension, and lifecycle |

## APIs Exposed

### Custom Resource Definitions (CRDs)

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| kueue.x-k8s.io | v1beta1 | AdmissionCheck | Cluster | Defines admission checks that workloads must pass before admission |
| kueue.x-k8s.io | v1beta1 | ClusterQueue | Cluster | Defines cluster-wide resource quotas and queueing policies |
| kueue.x-k8s.io | v1beta1 | LocalQueue | Namespaced | Defines namespace-scoped queues linked to ClusterQueues |
| kueue.x-k8s.io | v1beta1 | ProvisioningRequestConfig | Cluster | Configures autoscaling provisioning requests integration |
| kueue.x-k8s.io | v1beta1 | ResourceFlavor | Cluster | Defines resource types/flavors (GPU types, node pools, etc.) |
| kueue.x-k8s.io | v1beta1 | Workload | Namespaced | Represents a unit of work to be queued and admitted |
| kueue.x-k8s.io | v1beta1 | WorkloadPriorityClass | Cluster | Defines priority values for workload scheduling |
| kueue.x-k8s.io | v1alpha1 | MultiKueueCluster | Cluster | Defines remote cluster connections for multi-cluster workload distribution |
| kueue.x-k8s.io | v1alpha1 | MultiKueueConfig | Cluster | Configures multi-cluster workload distribution policies |

### HTTP Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /healthz | GET | 8081/TCP | HTTP | None | None | Liveness probe endpoint |
| /readyz | GET | 8081/TCP | HTTP | None | None | Readiness probe endpoint |
| /metrics | GET | 8080/TCP | HTTP | None | None | Prometheus metrics endpoint (internal) |
| /metrics | GET | 8443/TCP | HTTPS | TLS 1.2+ | Bearer Token | Prometheus metrics endpoint (kube-rbac-proxy protected) |
| /apis/visibility.kueue.x-k8s.io/v1alpha1/* | GET | 8082/TCP | HTTPS | TLS 1.2+ | Bearer Token | Visibility API for pending workloads queries |
| /mutate-* | POST | 9443/TCP | HTTPS | TLS 1.2+ | mTLS | Mutating webhook endpoints for job frameworks |
| /validate-* | POST | 9443/TCP | HTTPS | TLS 1.2+ | mTLS | Validating webhook endpoints for Kueue CRDs |

### Mutating Webhooks

| Resource | API Group | Operations | Purpose |
|----------|-----------|------------|---------|
| jobs | batch/v1 | CREATE | Inject queue name and suspend jobs for Kueue management |
| jobsets | jobset.x-k8s.io/v1alpha2 | CREATE | Inject queue name and suspend jobsets for Kueue management |
| mpijobs | kubeflow.org/v1, v2beta1 | CREATE | Inject queue name and suspend MPIJobs for Kueue management |
| mxjobs | kubeflow.org/v1 | CREATE | Inject queue name and suspend MXJobs for Kueue management |
| paddlejobs | kubeflow.org/v1 | CREATE | Inject queue name and suspend PaddleJobs for Kueue management |
| pytorchjobs | kubeflow.org/v1 | CREATE | Inject queue name and suspend PyTorchJobs for Kueue management |
| tfjobs | kubeflow.org/v1 | CREATE | Inject queue name and suspend TFJobs for Kueue management |
| xgboostjobs | kubeflow.org/v1 | CREATE | Inject queue name and suspend XGBoostJobs for Kueue management |
| rayjobs | ray.io/v1 | CREATE | Inject queue name and suspend RayJobs for Kueue management |
| rayclusters | ray.io/v1 | CREATE | Inject queue name and suspend RayClusters for Kueue management |

### Validating Webhooks

| Resource | API Group | Operations | Purpose |
|----------|-----------|------------|---------|
| admissionchecks | kueue.x-k8s.io/v1beta1 | CREATE, UPDATE | Validate AdmissionCheck configuration |
| clusterqueues | kueue.x-k8s.io/v1beta1 | CREATE, UPDATE | Validate ClusterQueue resource quotas and policies |
| localqueues | kueue.x-k8s.io/v1beta1 | CREATE, UPDATE | Validate LocalQueue configuration and ClusterQueue references |
| resourceflavors | kueue.x-k8s.io/v1beta1 | CREATE, UPDATE | Validate ResourceFlavor node labels and taints |
| workloads | kueue.x-k8s.io/v1beta1 | CREATE, UPDATE | Validate Workload resource requests and queue references |
| workloadpriorityclasses | kueue.x-k8s.io/v1beta1 | CREATE, UPDATE | Validate WorkloadPriorityClass priority values |

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| Kubernetes | 1.22+ | Yes | Core platform for controller runtime and API server |
| cert-manager | Any | No | Optional certificate management for webhooks (can use internal cert management) |
| Prometheus Operator | Any | No | Optional metrics collection via PodMonitor |
| kube-rbac-proxy | Latest | Yes | Protects metrics endpoint with RBAC authentication |

### Internal ODH Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| Training Operator (Kubeflow) | CRD Watch/Webhook | Manages queueing for PyTorchJob, TFJob, MPIJob, MXJob, XGBoostJob, PaddleJob training workloads |
| Ray Operator | CRD Watch/Webhook | Manages queueing for RayJob and RayCluster workloads |
| Batch Jobs | CRD Watch/Webhook | Manages queueing for standard Kubernetes batch/v1 Jobs |
| JobSet | CRD Watch/Webhook | Manages queueing for JobSet workloads |

## Network Architecture

### Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| webhook-service | ClusterIP | 443/TCP | 9443 | HTTPS | TLS 1.2+ | mTLS | Internal (API server to webhook) |
| visibility-server | ClusterIP | 443/TCP | 8082 | HTTPS | TLS 1.2+ | Bearer Token | Internal (kubectl/API clients) |
| controller-manager-metrics-service | ClusterIP | 8443/TCP | https | HTTPS | TLS 1.2+ | Bearer Token | Internal (Prometheus) |

### Ingress

No external ingress configured. All services are internal ClusterIP services accessible only within the cluster.

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | Service Account Token | Watch and reconcile Kueue CRDs and workload resources |
| Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | Service Account Token | Register admission webhooks and aggregated APIs |
| Remote Kubernetes Clusters | 6443/TCP | HTTPS | TLS 1.2+ | Kubeconfig Credentials | Multi-cluster workload distribution (MultiKueue) |
| Cluster Autoscaler API | Varies | HTTPS | TLS 1.2+ | Service Account Token | Create ProvisioningRequests for autoscaling integration |

## Security

### RBAC - Cluster Roles

| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|
| manager-role | "" | events | create, patch, update, watch |
| manager-role | "" | limitranges, namespaces | get, list, watch |
| manager-role | "" | pods | delete, get, list, patch, update, watch |
| manager-role | "" | pods/finalizers | get, update |
| manager-role | "" | pods/status | get, patch |
| manager-role | "" | podtemplates | create, delete, get, list, update, watch |
| manager-role | "" | secrets | get, list, update, watch |
| manager-role | admissionregistration.k8s.io | mutatingwebhookconfigurations, validatingwebhookconfigurations | get, list, update, watch |
| manager-role | autoscaling.x-k8s.io | provisioningrequests | create, delete, get, list, patch, update, watch |
| manager-role | batch | jobs | get, list, patch, update, watch |
| manager-role | batch | jobs/finalizers | get, patch, update |
| manager-role | batch | jobs/status | get, update |
| manager-role | flowcontrol.apiserver.k8s.io | flowschemas, prioritylevelconfigurations | list, watch |
| manager-role | jobset.x-k8s.io | jobsets | get, list, patch, update, watch |
| manager-role | jobset.x-k8s.io | jobsets/finalizers | get, patch, update |
| manager-role | jobset.x-k8s.io | jobsets/status | get |
| manager-role | kueue.x-k8s.io | admissionchecks, clusterqueues, localqueues, provisioningrequestconfigs, resourceflavors, workloads, workloadpriorityclasses | create, delete, get, list, patch, update, watch |
| manager-role | kueue.x-k8s.io | admissionchecks/finalizers, clusterqueues/finalizers, localqueues/finalizers, resourceflavors/finalizers, workloads/finalizers | update |
| manager-role | kueue.x-k8s.io | admissionchecks/status, clusterqueues/status, localqueues/status, workloads/status | get, patch, update |
| manager-role | kubeflow.org | mpijobs, mxjobs, paddlejobs, pytorchjobs, tfjobs, xgboostjobs | get, list, patch, update, watch |
| manager-role | kubeflow.org | mpijobs/finalizers, mxjobs/finalizers, paddlejobs/finalizers, pytorchjobs/finalizers, tfjobs/finalizers, xgboostjobs/finalizers | get, patch, update |
| manager-role | kubeflow.org | mpijobs/status, mxjobs/status, paddlejobs/status, pytorchjobs/status, tfjobs/status, xgboostjobs/status | get, update |
| manager-role | ray.io | rayclusters, rayjobs | get, list, patch, update, watch |
| manager-role | ray.io | rayclusters/finalizers, rayjobs/finalizers | get, patch, update |
| manager-role | ray.io | rayclusters/status, rayjobs/status | get, update |
| leader-election-role | "" | configmaps | get, list, watch, create, update, patch, delete |
| leader-election-role | coordination.k8s.io | leases | get, list, watch, create, update, patch, delete |
| leader-election-role | "" | events | create, patch |
| auth-proxy-client-clusterrole | authentication.k8s.io | tokenreviews | create |
| auth-proxy-client-clusterrole | authorization.k8s.io | subjectaccessreviews | create |
| batch-admin-role | "" | events | create, watch, update |
| batch-admin-role | batch | jobs | create, delete, get, list, patch, update, watch |
| batch-admin-role | kueue.x-k8s.io | localqueues | get, list, watch |
| batch-user-role | "" | events | get, watch |
| batch-user-role | batch | jobs | get, list, watch |
| batch-user-role | kueue.x-k8s.io | localqueues | get, list, watch |
| clusterqueue-editor-role | kueue.x-k8s.io | clusterqueues | create, delete, get, list, patch, update, watch |
| clusterqueue-viewer-role | kueue.x-k8s.io | clusterqueues | get, list, watch |
| localqueue-editor-role | kueue.x-k8s.io | localqueues | create, delete, get, list, patch, update, watch |
| localqueue-viewer-role | kueue.x-k8s.io | localqueues | get, list, watch |
| resourceflavor-editor-role | kueue.x-k8s.io | resourceflavors | create, delete, get, list, patch, update, watch |
| resourceflavor-viewer-role | kueue.x-k8s.io | resourceflavors | get, list, watch |
| workload-editor-role | kueue.x-k8s.io | workloads | create, delete, get, list, patch, update, watch |
| workload-viewer-role | kueue.x-k8s.io | workloads | get, list, watch |

### RBAC - Role Bindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| manager-rolebinding | N/A (Cluster) | manager-role (ClusterRole) | controller-manager (kueue-system) |
| leader-election-rolebinding | kueue-system | leader-election-role (Role) | controller-manager (kueue-system) |
| auth-proxy-rolebinding | kueue-system | auth-proxy-role (Role) | controller-manager (kueue-system) |

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| webhook-server-cert | kubernetes.io/tls | TLS certificate for webhook server | cert-manager or internal cert management | Yes (cert-manager) or No (internal) |
| visibility-server-cert | kubernetes.io/tls | TLS certificate for visibility API server | cert-manager or internal cert management | Yes (cert-manager) or No (internal) |

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| /healthz | GET | None | None | Public within pod network |
| /readyz | GET | None | None | Public within pod network |
| /metrics (8080) | GET | None | Controller manager | Internal-only metrics port |
| /metrics (8443) | GET | Bearer Token (RBAC) | kube-rbac-proxy | Requires auth-proxy-client-clusterrole permissions |
| /apis/visibility.kueue.x-k8s.io/* | GET | Bearer Token (RBAC) | Kubernetes API Server | Standard Kubernetes API authorization |
| /mutate-*, /validate-* | POST | mTLS (API Server Client Cert) | Kubernetes API Server | Webhook called by API server with client cert |

### Network Policies

| Policy Name | Namespace | Pod Selector | Ingress Rules | Egress Rules |
|-------------|-----------|--------------|---------------|--------------|
| webhook-server | kueue-system | matchLabels: {} (all pods) | Allow TCP/9443 from any | Not specified (allow all) |

## Data Flows

### Flow 1: Job Submission and Queueing

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User kubectl/API client | Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | Bearer Token |
| 2 | Kubernetes API Server | webhook-service | 443/TCP | HTTPS | TLS 1.2+ | mTLS |
| 3 | webhook-service | Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | Service Account Token |
| 4 | Job Controller | Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | Service Account Token |
| 5 | Workload Controller | Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | Service Account Token |

**Description**: User creates a Job → API server calls mutating webhook to inject queue name and suspend flag → Job is created in suspended state → Kueue creates corresponding Workload → ClusterQueue controller evaluates admission based on quota → Workload is admitted → Job controller unsuspends Job → Pods start running.

### Flow 2: Workload Admission

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | ClusterQueue Controller | Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | Service Account Token |
| 2 | AdmissionCheck Controller | Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | Service Account Token |
| 3 | Workload Controller | Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | Service Account Token |
| 4 | Workload Controller | Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | Service Account Token |

**Description**: ClusterQueue controller watches pending workloads → Evaluates workload against quota and admission checks → Admission check controllers validate requirements → Workload status updated to admitted with resource assignment → Job framework controller watches workload admission → Job unsuspended and pods created.

### Flow 3: Visibility API Query

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | kubectl/API client | Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | Bearer Token |
| 2 | Kubernetes API Server | visibility-server | 443/TCP | HTTPS | TLS 1.2+ | Bearer Token (proxied) |
| 3 | visibility-server | Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | Service Account Token |

**Description**: User queries pending workloads via visibility API → API server proxies to visibility-server via aggregation → visibility-server queries Workload CRDs → Returns formatted pending workloads summary.

### Flow 4: Metrics Collection

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Prometheus | kube-rbac-proxy | 8443/TCP | HTTPS | TLS 1.2+ | Bearer Token |
| 2 | kube-rbac-proxy | Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | Token Review (proxied) |
| 3 | kube-rbac-proxy | controller-manager | 8080/TCP | HTTP | None | Local sidecar |

**Description**: Prometheus scrapes metrics endpoint via PodMonitor → Connects to kube-rbac-proxy with service account token → kube-rbac-proxy validates token via TokenReview → Proxies request to controller-manager metrics endpoint.

### Flow 5: Multi-Cluster Workload Distribution (MultiKueue)

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | MultiKueue Controller | Kubernetes API Server (local) | 6443/TCP | HTTPS | TLS 1.2+ | Service Account Token |
| 2 | MultiKueue Controller | Remote Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | Kubeconfig Credentials (from Secret) |
| 3 | MultiKueue Controller | Remote Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | Kubeconfig Credentials |
| 4 | Remote Cluster | Local Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | Kubeconfig Credentials |

**Description**: MultiKueue controller watches admitted workloads → Reads remote cluster kubeconfig from Secret → Creates workload in remote cluster → Monitors remote workload status → Syncs status back to local workload.

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| Kubernetes API Server | REST API | 6443/TCP | HTTPS | TLS 1.2+ | Watch and manage all Kueue CRDs and integrated workloads |
| Kubernetes Admission Controller | Webhook | 9443/TCP | HTTPS | TLS 1.2+ | Mutate and validate workload resources on creation |
| Training Operator (PyTorchJob, TFJob, etc.) | CRD Watch + Webhook | 6443/TCP, 9443/TCP | HTTPS | TLS 1.2+ | Queue and manage ML training jobs |
| Ray Operator | CRD Watch + Webhook | 6443/TCP, 9443/TCP | HTTPS | TLS 1.2+ | Queue and manage Ray workloads |
| JobSet Operator | CRD Watch + Webhook | 6443/TCP, 9443/TCP | HTTPS | TLS 1.2+ | Queue and manage JobSet workloads |
| Cluster Autoscaler | ProvisioningRequest API | 6443/TCP | HTTPS | TLS 1.2+ | Request node provisioning for admitted workloads |
| Prometheus | Metrics Scrape | 8443/TCP | HTTPS | TLS 1.2+ | Collect controller performance and queue metrics |
| kubectl/API Clients | Visibility API | 6443/TCP (proxied to 8082) | HTTPS | TLS 1.2+ | Query pending workload status and queue positions |

## Recent Changes

| Commit | Date | Changes |
|--------|------|---------|
| f99252525 | 2024 | - Update registry.redhat.io/ubi8/ubi-minimal Docker digest to 43dde01 |
| cce626c01 | 2024 | - Update registry.redhat.io/ubi8/ubi Docker digest to 534c2c0 |
| 08a95b1a7 | 2024 | - Update Konflux references |
| 0ea775d03 | 2024 | - Update Konflux references |
| dfaad1f1d | 2024 | - Update Konflux references |
| 804d53bad | 2024 | - Update Konflux references |
| d25fc7c7b | 2024 | - Update registry.redhat.io/ubi8/ubi Docker digest to 4f0a4e4 |
| 78a183ed1 | 2024 | - Update registry.redhat.io/ubi8/ubi Docker digest to dd9e25c |
| 7030e11d3 | 2024 | - Update registry.redhat.io/ubi8/ubi Docker digest to a463a8e |
| 9f7129fc7 | 2024 | - Update Konflux references |

**Note**: The rhoai-2.8 branch primarily contains container image updates and Konflux build configuration updates. Core Kueue functionality is inherited from upstream kubernetes-sigs/kueue project.

## Deployment Configuration

### Container Image
- **Built with**: Dockerfile.konflux
- **Base Image**: registry.redhat.io/ubi8/ubi-minimal
- **Build System**: Konflux CI/CD
- **Registry**: Red Hat Container Registry
- **Component Name**: odh-kueue-controller-container
- **Image Name**: managed-open-data-hub/odh-kueue-controller-rhel8

### Deployment Specifications
- **Replicas**: 1 (single controller with leader election)
- **Resource Limits**: CPU: 500m, Memory: 512Mi
- **Resource Requests**: CPU: 500m, Memory: 512Mi
- **Security Context**: runAsNonRoot: true, allowPrivilegeEscalation: false
- **User**: 65532:65532 (non-root)
- **Service Account**: controller-manager
- **Leader Election**: Enabled (resourceName: c1f6bfd2.kueue.x-k8s.io)

### Controller Configuration
- **Webhook Port**: 9443
- **Metrics Port**: 8080
- **Health Probe Port**: 8081
- **Visibility API Port**: 8082
- **QPS**: 50 (API server queries per second)
- **Burst**: 100 (API server burst limit)
- **Concurrency**:
  - Job.batch: 5
  - Pod: 5
  - Workload.kueue.x-k8s.io: 5
  - LocalQueue.kueue.x-k8s.io: 1
  - ClusterQueue.kueue.x-k8s.io: 1
  - ResourceFlavor.kueue.x-k8s.io: 1

### Supported Job Frameworks
- batch/job (Kubernetes Jobs)
- kubeflow.org/mpijob (MPI Jobs)
- kubeflow.org/mxjob (MXNet Jobs)
- kubeflow.org/paddlejob (PaddlePaddle Jobs)
- kubeflow.org/pytorchjob (PyTorch Jobs)
- kubeflow.org/tfjob (TensorFlow Jobs)
- kubeflow.org/xgboostjob (XGBoost Jobs)
- ray.io/rayjob (Ray Jobs)
- ray.io/raycluster (Ray Clusters)
- jobset.x-k8s.io/jobset (JobSets)

## Operational Notes

### High Availability
- Single replica deployment with Kubernetes leader election
- Leader election uses ConfigMaps and Leases for coordination
- Controller automatically recovers from failures via Kubernetes deployment
- Workload state persisted in CRDs ensures no data loss during restarts

### Monitoring and Observability
- Prometheus metrics exposed via kube-rbac-proxy on port 8443
- PodMonitor CRD for automatic Prometheus service discovery
- Health endpoints (/healthz, /readyz) for Kubernetes liveness/readiness probes
- Controller events emitted for workload admission, suspension, and errors
- Visibility API provides real-time pending workload information

### Certificate Management
- Supports cert-manager for automatic certificate rotation
- Alternative internal certificate management available
- Webhook certificates required for API server communication
- Visibility API server requires TLS certificate for aggregation

### Network Security
- NetworkPolicy enforces ingress on webhook port (9443)
- All external communication uses TLS 1.2+
- Metrics endpoint protected by kube-rbac-proxy with RBAC
- Webhook communication secured via mTLS with API server
- Service account tokens for Kubernetes API authentication

### Multi-Cluster Support
- MultiKueue enables workload distribution across clusters
- Remote cluster credentials stored in Secrets (kubeconfig)
- Supports up to 10 remote clusters per MultiKueueConfig
- Workload status synchronized between local and remote clusters
