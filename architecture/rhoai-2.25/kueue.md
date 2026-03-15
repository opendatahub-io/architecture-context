# Component: Kueue

## Metadata
- **Repository**: https://github.com/red-hat-data-services/kueue
- **Version**: 7f2f72e51 (rhoai-2.25 branch)
- **Distribution**: RHOAI
- **Languages**: Go 1.24
- **Deployment Type**: Kubernetes Operator (Controller)

## Purpose
**Short**: Job queueing controller that manages when Kubernetes jobs should be admitted to start and when they should stop based on resource quotas and priorities.

**Detailed**: Kueue is a Kubernetes-native job management system that provides intelligent queueing and scheduling for batch workloads. It acts as a job-level manager that decides when a job can be admitted (pods can be created) based on available quota in cluster queues and local queues. Kueue supports advanced features like fair sharing, preemption, cohorts for resource sharing across teams, multi-cluster job dispatching (MultiKueue), topology-aware scheduling for optimized pod placement, and integration with cluster autoscaling through provisioning requests. It manages quota for various workload types including Kubernetes Batch Jobs, Kubeflow training jobs (TFJob, PyTorchJob, MPIJob, XGBoostJob, PaddleJob), RayJob, RayCluster, JobSet, AppWrapper, and even serving workloads like Deployments and StatefulSets. The controller watches workload resources, assigns them to queues, evaluates admission based on quota and priority, and manages the lifecycle from queueing through admission to completion.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| kueue-controller-manager | Deployment | Main controller that reconciles workloads, queues, and resource flavors |
| webhook-service | Service | Admission webhook server for mutating and validating workload resources |
| metrics-service | Service | Prometheus metrics endpoint for monitoring queue and workload state |
| kueue-visibility-server | HTTP Server | On-demand visibility API for querying pending workloads |
| workload-reconciler | Controller | Manages workload lifecycle and admission decisions |
| clusterqueue-reconciler | Controller | Manages cluster-level resource quotas and admission |
| localqueue-reconciler | Controller | Manages namespace-scoped queue configurations |
| job-integrations | Controllers | Framework integrating Batch, Kubeflow, Ray, JobSet, AppWrapper jobs |
| scheduler | Core Component | Evaluates workload priorities and quota to make admission decisions |
| cache | Core Component | In-memory cache of cluster queues, workloads, and resource usage |

## APIs Exposed

### Custom Resource Definitions (CRDs)

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| kueue.x-k8s.io | v1beta1 | Workload | Namespaced | Represents a job or group of pods with resource requirements and queue assignment |
| kueue.x-k8s.io | v1beta1 | ClusterQueue | Cluster | Defines cluster-wide resource quotas, flavors, and admission policies |
| kueue.x-k8s.io | v1beta1 | LocalQueue | Namespaced | Namespace-scoped queue that maps to a ClusterQueue |
| kueue.x-k8s.io | v1beta1 | ResourceFlavor | Cluster | Defines a variant of resources (e.g., GPU types, node pools) with labels/taints |
| kueue.x-k8s.io | v1beta1 | WorkloadPriorityClass | Cluster | Defines priority levels for workload scheduling |
| kueue.x-k8s.io | v1beta1 | AdmissionCheck | Cluster | Defines external or internal checks required before workload admission |
| kueue.x-k8s.io | v1beta1 | ProvisioningRequestConfig | Cluster | Configuration for cluster autoscaler provisioning requests |
| kueue.x-k8s.io | v1beta1 | MultiKueueConfig | Cluster | Configuration for multi-cluster job dispatching |
| kueue.x-k8s.io | v1beta1 | MultiKueueCluster | Cluster | Represents a remote cluster for MultiKueue job distribution |
| kueue.x-k8s.io | v1alpha1 | Cohort | Cluster | Groups ClusterQueues for resource sharing and fair sharing policies |
| kueue.x-k8s.io | v1alpha1 | Topology | Cluster | Defines data center topology for topology-aware scheduling |
| visibility.kueue.x-k8s.io | v1beta1 | ClusterQueue (subresource) | Cluster | On-demand API to query pending workloads in a ClusterQueue |
| visibility.kueue.x-k8s.io | v1beta1 | LocalQueue (subresource) | Namespaced | On-demand API to query pending workloads in a LocalQueue |

### HTTP Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /healthz | GET | 8081/TCP | HTTP | None | None | Health check probe for liveness |
| /readyz | GET | 8081/TCP | HTTP | None | None | Readiness check probe |
| /metrics | GET | 8443/TCP | HTTPS | TLS 1.2+ | Bearer Token | Prometheus metrics for monitoring workloads and queues |
| /mutate-* | POST | 9443/TCP | HTTPS | TLS 1.2+ | K8s API Server | Mutating admission webhooks for Jobs, JobSets, Kubeflow jobs, etc. |
| /validate-* | POST | 9443/TCP | HTTPS | TLS 1.2+ | K8s API Server | Validating admission webhooks for Kueue CRDs |
| /apis/visibility.kueue.x-k8s.io/v1beta1/clusterqueues/{name}/pendingworkloads | GET | 443/TCP | HTTPS | TLS 1.2+ | K8s RBAC | List pending workloads in ClusterQueue |
| /apis/visibility.kueue.x-k8s.io/v1beta1/namespaces/{ns}/localqueues/{name}/pendingworkloads | GET | 443/TCP | HTTPS | TLS 1.2+ | K8s RBAC | List pending workloads in LocalQueue |

### gRPC Services

No gRPC services exposed.

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| Kubernetes API Server | 1.25+ | Yes | Core platform for CRD management and pod orchestration |
| cert-manager | 1.17+ | Yes | Generates and rotates TLS certificates for webhooks |
| Prometheus | Any | No | Scrapes metrics for monitoring queue state and performance |
| Kubeflow Training Operator | 1.9+ | No | Required only if using TFJob, PyTorchJob, MPIJob, etc. |
| Ray Operator | 1.3+ | No | Required only if using RayJob or RayCluster |
| JobSet | 0.8+ | No | Required only if using JobSet resources |
| AppWrapper | 1.1+ | No | Required only if using CodeFlare AppWrapper |
| Cluster Autoscaler | Any | No | Required for provisioning request integration |

### Internal ODH Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| None | N/A | Kueue is a standalone component with no internal ODH dependencies |

## Network Architecture

### Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| kueue-webhook-service | ClusterIP | 443/TCP | 9443 | HTTPS | TLS 1.2+ | K8s API Server mTLS | Internal |
| kueue-metrics-service | ClusterIP | 8443/TCP | https-metrics | HTTPS | TLS 1.2+ | Bearer Token | Internal |

### Ingress

No direct ingress. Webhook service is accessed by Kubernetes API server via internal service. Visibility API is accessed through Kubernetes API server aggregation layer.

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| Kubernetes API Server | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token | Watch and reconcile CRDs, Jobs, Pods, Deployments, StatefulSets |
| Remote Kubernetes API Servers | 443/TCP | HTTPS | TLS 1.2+ | Kubeconfig | MultiKueue multi-cluster job dispatching |
| Cluster Autoscaler API | 443/TCP | HTTPS | TLS 1.2+ | K8s RBAC | Create and manage ProvisioningRequest resources |

## Security

### RBAC - Cluster Roles

| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|
| kueue-manager-role | kueue.x-k8s.io | workloads, clusterqueues, localqueues, resourceflavors, admissionchecks, workloadpriorityclasses, provisioningrequestconfigs, multikueueconfigs, multikueueclusters, cohorts, topologies | get, list, watch, create, update, patch, delete |
| kueue-manager-role | "" | events, pods, namespaces, nodes, limitranges, secrets, podtemplates | get, list, watch, create, update, patch |
| kueue-manager-role | "" | pods | delete |
| kueue-manager-role | batch | jobs | get, list, watch, patch, update |
| kueue-manager-role | apps | deployments, replicasets, statefulsets | get, list, watch |
| kueue-manager-role | autoscaling.x-k8s.io | provisioningrequests | get, list, watch, create, update, patch, delete |
| kueue-manager-role | jobset.x-k8s.io | jobsets | get, list, watch, patch, update |
| kueue-manager-role | kubeflow.org | tfjobs, pytorchjobs, mpijobs, xgboostjobs, paddlejobs | get, list, watch, patch, update |
| kueue-manager-role | ray.io | rayjobs, rayclusters | get, list, watch, patch, update |
| kueue-manager-role | workload.codeflare.dev | appwrappers | get, list, watch, patch, update |
| kueue-manager-role | admissionregistration.k8s.io | mutatingwebhookconfigurations, validatingwebhookconfigurations | get, list, watch, update |
| kueue-manager-role | flowcontrol.apiserver.k8s.io | flowschemas, prioritylevelconfigurations | list, watch, patch |
| kueue-batch-admin-role | "" | events, pods, services | get, list, watch, create, update, patch, delete |
| kueue-batch-user-role | kueue.x-k8s.io | workloads | get, list, watch, create, update, patch, delete |
| kueue-clusterqueue-editor-role | kueue.x-k8s.io | clusterqueues | get, list, watch, create, update, patch, delete |
| kueue-clusterqueue-viewer-role | kueue.x-k8s.io | clusterqueues | get, list, watch |
| kueue-clusterqueue-viewer-role | visibility.kueue.x-k8s.io | clusterqueues/pendingworkloads | get |
| kueue-localqueue-editor-role | kueue.x-k8s.io | localqueues | get, list, watch, create, update, patch, delete |
| kueue-localqueue-viewer-role | kueue.x-k8s.io | localqueues | get, list, watch |
| kueue-metrics-auth-role | "" | namespaces | get |
| kueue-metrics-reader-role | "" | pods, services, endpoints | get, list, watch |
| kueue-leader-election-role | "" | configmaps | get, list, watch, create, update, patch, delete |
| kueue-leader-election-role | coordination.k8s.io | leases | get, list, watch, create, update, patch, delete |

### RBAC - Role Bindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| kueue-manager-rolebinding | opendatahub | kueue-manager-role (ClusterRole) | kueue-controller-manager |
| kueue-leader-election-rolebinding | opendatahub | kueue-leader-election-role | kueue-controller-manager |
| kueue-metrics-auth-rolebinding | opendatahub | kueue-metrics-auth-role | kueue-controller-manager |
| kueue-metrics-reader-clusterrolebinding | Cluster | kueue-metrics-reader-role (ClusterRole) | kueue-controller-manager-metrics-reader |

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| kueue-webhook-server-cert | kubernetes.io/tls | TLS certificate for webhook server | cert-manager | Yes |
| kueue-controller-manager-metrics-token | kubernetes.io/service-account-token | Bearer token for Prometheus metrics scraping | Kubernetes | Yes |

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| /metrics | GET | Bearer Token (ServiceAccount) | Controller Runtime | Metrics reader ServiceAccount |
| /mutate-*, /validate-* | POST | mTLS (API Server) | Kubernetes API Server | API server authenticates to webhook via TLS client cert |
| /apis/visibility.kueue.x-k8s.io/* | GET | Bearer Token (User/SA) | Kubernetes API Server | K8s RBAC on visibility API resources |
| /healthz, /readyz | GET | None | None | Public within cluster |

### Network Policies

| Policy Name | Namespace | Pod Selector | Ingress Rules | Egress Rules |
|-------------|-----------|--------------|---------------|--------------|
| kueue-webhook-server | opendatahub | All pods in namespace | Allow TCP 9443 | None (default allow) |

## Data Flows

### Flow 1: Job Submission and Admission

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User kubectl | Kubernetes API Server | 443/TCP | HTTPS | TLS 1.3 | Bearer Token (User) |
| 2 | Kubernetes API Server | kueue-webhook-service | 9443/TCP | HTTPS | TLS 1.2+ | mTLS (API Server client cert) |
| 3 | kueue-webhook (mutate) | Kubernetes API Server (response) | - | HTTPS | TLS 1.2+ | mTLS |
| 4 | kueue-controller-manager (watch) | Kubernetes API Server | 443/TCP | HTTPS | TLS 1.2+ | Bearer Token (ServiceAccount) |
| 5 | kueue-controller-manager (workload reconcile) | Kubernetes API Server | 443/TCP | HTTPS | TLS 1.2+ | Bearer Token (ServiceAccount) |
| 6 | kueue-controller-manager (admit job) | Kubernetes API Server | 443/TCP | HTTPS | TLS 1.2+ | Bearer Token (ServiceAccount) |

### Flow 2: Metrics Collection

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Prometheus | kueue-metrics-service | 8443/TCP | HTTPS | TLS 1.2+ | Bearer Token (ServiceAccount) |
| 2 | kueue-controller-manager | Prometheus (response) | - | HTTPS | TLS 1.2+ | - |

### Flow 3: Visibility API Query

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User kubectl | Kubernetes API Server | 443/TCP | HTTPS | TLS 1.3 | Bearer Token (User) |
| 2 | Kubernetes API Server | kueue-visibility-server (in-process) | - | HTTP | None (in-process) | K8s RBAC |
| 3 | kueue-visibility-server | Cache (in-memory) | - | - | None (in-process) | - |

### Flow 4: Multi-Cluster Job Dispatching (MultiKueue)

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | kueue-controller-manager | Remote K8s API Server | 443/TCP | HTTPS | TLS 1.2+ | Kubeconfig credentials |
| 2 | kueue-controller-manager (watch remote) | Remote K8s API Server | 443/TCP | HTTPS | TLS 1.2+ | Kubeconfig credentials |

### Flow 5: Provisioning Request (Autoscaling)

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | kueue-controller-manager | Kubernetes API Server | 443/TCP | HTTPS | TLS 1.2+ | Bearer Token (ServiceAccount) |
| 2 | Cluster Autoscaler | Kubernetes API Server (watch PR) | 443/TCP | HTTPS | TLS 1.2+ | Bearer Token (ServiceAccount) |
| 3 | Cluster Autoscaler | Cloud Provider API | 443/TCP | HTTPS | TLS 1.2+ | Cloud credentials |

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| Kubernetes API Server | REST API (client) | 443/TCP | HTTPS | TLS 1.2+ | Watch and manage workloads, jobs, pods, CRDs |
| Kubernetes API Server | Webhook (server) | 9443/TCP | HTTPS | TLS 1.2+ | Mutate and validate job resources on admission |
| Kubernetes API Server | Aggregated API (server) | N/A | HTTPS | TLS 1.2+ | Serve visibility API through aggregation layer |
| Prometheus | Metrics (server) | 8443/TCP | HTTPS | TLS 1.2+ | Expose queue and workload metrics |
| cert-manager | Certificate CR | 443/TCP | HTTPS | TLS 1.2+ | Request webhook TLS certificates |
| Batch Jobs | CRD Watch/Patch | 443/TCP | HTTPS | TLS 1.2+ | Suspend jobs until admitted, inject node selectors |
| Kubeflow Operators | CRD Watch/Patch | 443/TCP | HTTPS | TLS 1.2+ | Manage TFJob, PyTorchJob, MPIJob, XGBoostJob, PaddleJob |
| Ray Operator | CRD Watch/Patch | 443/TCP | HTTPS | TLS 1.2+ | Manage RayJob and RayCluster admission |
| JobSet | CRD Watch/Patch | 443/TCP | HTTPS | TLS 1.2+ | Manage JobSet admission and quota |
| AppWrapper | CRD Watch/Patch | 443/TCP | HTTPS | TLS 1.2+ | Manage CodeFlare AppWrapper admission |
| Cluster Autoscaler | ProvisioningRequest CRD | 443/TCP | HTTPS | TLS 1.2+ | Trigger node provisioning for pending workloads |

## Recent Changes

| Date | Commit | Changes |
|------|--------|---------|
| 2025-03 | 7f2f72e51 | - Update UBI9 minimal base image<br>- Sync Konflux pipelines |
| 2025-02 | ce07e72dd | - Update OpenShift Go builder to v1.24 |
| 2025-02 | 666e934da | - Update UBI9 base image security patches |
| 2025-01 | Multiple | - Regular security updates to base images<br>- Konflux pipeline synchronization<br>- Go 1.24 upgrade |

## Deployment Details

### Container Images

- **Built by**: Konflux (RHOAI build system)
- **Builder**: `brew.registry.redhat.io/rh-osbs/openshift-golang-builder:v1.24`
- **Runtime**: `registry.access.redhat.com/ubi9/ubi-minimal` (FIPS-enabled)
- **FIPS**: Enabled with `GOEXPERIMENT=strictfipsruntime` and CGO
- **User**: 65532:65532 (non-root)

### Resource Requirements

| Container | CPU Request | CPU Limit | Memory Request | Memory Limit |
|-----------|-------------|-----------|----------------|--------------|
| manager | 500m | 2000m | 512Mi | 512Mi |

### High Availability

- **Replicas**: 1 (single replica with leader election)
- **Leader Election**: Enabled via ConfigMap/Lease in opendatahub namespace
- **Rolling Updates**: Standard Deployment strategy
- **Pod Disruption Budget**: Not defined (single replica)

### Configuration

- **Namespace**: opendatahub
- **ConfigMap**: kueue-rhoai-config (deployment parameters)
- **Controller Config**: Mounted via ConfigMap with resource quotas, integrations, and feature gates

### Monitoring

- **Metrics Format**: Prometheus
- **Metrics Port**: 8443/TCP (HTTPS)
- **ServiceMonitor**: kueue-controller-manager-metrics-monitor
- **PrometheusRule**: Alerts for pending workloads and admission failures
- **Key Metrics**:
  - `kueue_pending_workloads` - Number of workloads waiting for admission
  - `kueue_admitted_workloads_total` - Total admitted workloads
  - `kueue_admission_attempts_total` - Admission attempt counts and failures
  - `kueue_cluster_queue_resource_usage` - Resource usage by ClusterQueue
  - `kueue_admission_wait_time_seconds` - Time workloads wait before admission

## Notes

- Kueue is a standalone Kubernetes SIG project integrated into RHOAI for job queue management
- Does not directly depend on other ODH components but commonly used with training operators
- Supports multi-tenancy through namespace-scoped LocalQueues and cluster-wide ClusterQueues
- Fair sharing and preemption policies prevent resource starvation across teams
- Topology-aware scheduling optimizes pod placement for GPU/network-intensive workloads
- MultiKueue feature enables bursting to remote clusters when local capacity is exhausted
- Integrates with cluster autoscaler to provision nodes for pending workloads
- Webhook intercepts job creation to inject queue annotations and suspend jobs
- Controller reconciles workloads continuously to make admission decisions based on quota
- Visibility API provides real-time view of queue state without polling CRDs
- Designed for high-scale environments with thousands of workloads and multiple queues
