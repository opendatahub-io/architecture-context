# Component: Kueue

## Metadata
- **Repository**: https://github.com/red-hat-data-services/kueue.git
- **Version**: v0.7.0
- **Branch**: rhoai-2.12
- **Commit**: 175aa61f0
- **Distribution**: RHOAI
- **Languages**: Go
- **Deployment Type**: Kubernetes Operator (Controller)

## Purpose
**Short**: Job queueing and resource management system for Kubernetes batch workloads.

**Detailed**: Kueue is a cloud-native job queueing system that provides fair sharing of cluster resources between different teams and users. It manages when jobs should be admitted to start (pods can be created) and when they should stop (pods should be deleted) based on available quota and priorities. Kueue supports multiple queueing strategies (StrictFIFO, BestEffortFIFO), resource preemption, dynamic resource reclaim, and integrates with popular batch job frameworks including Kubernetes Jobs, Kubeflow training jobs (TFJob, PyTorchJob, MPIJob, XGBoostJob), Ray (RayJob, RayCluster), and JobSets. It provides cluster administrators with fine-grained control over resource allocation through ClusterQueues, LocalQueues, ResourceFlavors, and WorkloadPriorityClasses.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| kueue-controller-manager | Deployment | Main controller managing workload admission, queueing, and resource allocation |
| Webhook Server | Admission Webhook | Mutating and validating webhooks for job resources and Kueue CRDs |
| Visibility Server | API Server | REST API providing visibility into pending workloads and queue status |
| Metrics Exporter | Prometheus Exporter | Exposes queue metrics and resource usage statistics |

## APIs Exposed

### Custom Resource Definitions (CRDs)

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| kueue.x-k8s.io | v1beta1 | ClusterQueue | Cluster | Defines cluster-level resource quotas and policies for workload admission |
| kueue.x-k8s.io | v1beta1 | LocalQueue | Namespaced | Namespace-scoped queue that maps to a ClusterQueue |
| kueue.x-k8s.io | v1beta1 | Workload | Namespaced | Internal representation of a job with resource requirements |
| kueue.x-k8s.io | v1beta1 | ResourceFlavor | Cluster | Defines a resource flavor variant (e.g., GPU type, node pool) |
| kueue.x-k8s.io | v1beta1 | AdmissionCheck | Cluster | Defines admission check requirements for workload admission |
| kueue.x-k8s.io | v1beta1 | WorkloadPriorityClass | Cluster | Defines workload priority for queueing |
| kueue.x-k8s.io | v1beta1 | ProvisioningRequestConfig | Cluster | Configuration for cluster autoscaler provisioning requests |
| kueue.x-k8s.io | v1alpha1 | MultiKueueCluster | Namespaced | Configuration for multi-cluster job distribution |
| kueue.x-k8s.io | v1alpha1 | MultiKueueConfig | Namespaced | Multi-cluster configuration settings |

### HTTP Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /healthz | GET | 8081/TCP | HTTP | None | None | Liveness probe endpoint |
| /readyz | GET | 8081/TCP | HTTP | None | None | Readiness probe endpoint |
| /metrics | GET | 8080/TCP | HTTP | None | None | Prometheus metrics endpoint |
| /metrics (auth proxy) | GET | 8443/TCP | HTTPS | TLS 1.2+ | Bearer Token | Authenticated metrics endpoint |
| /mutate-* | POST | 9443/TCP | HTTPS | TLS | mTLS | Mutating webhook admission endpoints |
| /validate-* | POST | 9443/TCP | HTTPS | TLS | mTLS | Validating webhook admission endpoints |

### Visibility API (v1alpha1)

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /apis/visibility.kueue.x-k8s.io/v1alpha1/clusterqueues/{name}/pendingworkloads | GET | 8082/TCP | HTTPS | TLS | RBAC | Get pending workloads in ClusterQueue |
| /apis/visibility.kueue.x-k8s.io/v1alpha1/namespaces/{ns}/localqueues/{name}/pendingworkloads | GET | 8082/TCP | HTTPS | TLS | RBAC | Get pending workloads in LocalQueue |

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| Kubernetes | 1.22+ | Yes | Container orchestration platform |
| cert-manager or internal-cert | Latest | Yes | TLS certificate provisioning for webhooks |
| Prometheus Operator | Latest | No | Metrics collection and alerting |
| Kubeflow Training Operator | Latest | No | Support for ML training jobs (TFJob, PyTorchJob, etc.) |
| Ray Operator | Latest | No | Support for Ray jobs and clusters |
| JobSet | Latest | No | Support for JobSet resources |

### Internal ODH/RHOAI Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| Kubeflow Training Operator | Webhook/CRD | Queue management for ML training jobs |
| Ray Operator | Webhook/CRD | Queue management for Ray workloads |
| Prometheus | Metrics Pull | Monitoring queue status and resource usage |

## Network Architecture

### Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| kueue-webhook-service | ClusterIP | 443/TCP | 9443 | HTTPS | TLS | mTLS (API Server) | Internal |
| kueue-controller-manager-metrics-service | ClusterIP | 8443/TCP | https | HTTPS | TLS 1.2+ | Bearer Token | Internal |
| kueue-metrics-service | ClusterIP | 8080/TCP | metrics | HTTP | None | None | Internal |
| kueue-visibility-server | ClusterIP | 443/TCP | 8082 | HTTPS | TLS | RBAC | Internal |

### Ingress

| Name | Type | Hosts | Port | Protocol | Encryption | TLS Mode | Exposure |
|------|------|-------|------|----------|------------|----------|----------|
| N/A | N/A | N/A | N/A | N/A | N/A | N/A | None - All access is cluster-internal |

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token | CRD management, resource watching |
| autoscaling.x-k8s.io API | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token | ProvisioningRequest creation for autoscaling |

## Security

### RBAC - Cluster Roles

| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|
| kueue-manager-role | "" | events, limitranges, namespaces, pods, pods/finalizers, pods/status, podtemplates, secrets | create, delete, get, list, patch, update, watch |
| kueue-manager-role | admissionregistration.k8s.io | mutatingwebhookconfigurations, validatingwebhookconfigurations | get, list, update, watch |
| kueue-manager-role | autoscaling.x-k8s.io | provisioningrequests, provisioningrequests/status | create, delete, get, list, update, watch |
| kueue-manager-role | batch | jobs, jobs/status, jobs/finalizers | get, list, watch, update, patch, delete |
| kueue-manager-role | jobset.x-k8s.io | jobsets, jobsets/status, jobsets/finalizers | get, list, watch, update, patch |
| kueue-manager-role | kubeflow.org | mpijobs, pytorchjobs, tfjobs, xgboostjobs, mxjobs, paddlejobs (all /status, /finalizers) | get, list, watch, update, patch |
| kueue-manager-role | ray.io | rayjobs, rayjobs/status, rayjobs/finalizers, rayclusters, rayclusters/status, rayclusters/finalizers | get, list, watch, update, patch |
| kueue-manager-role | kueue.x-k8s.io | admissionchecks, clusterqueues, localqueues, workloads, resourceflavors, workloadpriorityclasses, provisioningrequestconfigs, multikueueclusters, multikueueconfigs (all /status, /finalizers) | create, delete, get, list, patch, update, watch |
| kueue-batch-admin-role | kueue.x-k8s.io (aggregated) | All Kueue resources | All verbs |
| kueue-batch-user-role | kueue.x-k8s.io | localqueues, workloads | get, list, create (limited) |
| kueue-clusterqueue-viewer-role | kueue.x-k8s.io | clusterqueues | get, list, watch |
| kueue-clusterqueue-editor-role | kueue.x-k8s.io | clusterqueues | create, delete, get, list, patch, update, watch |
| kueue-localqueue-viewer-role | kueue.x-k8s.io | localqueues | get, list, watch |
| kueue-localqueue-editor-role | kueue.x-k8s.io | localqueues | create, delete, get, list, patch, update, watch |
| kueue-workload-viewer-role | kueue.x-k8s.io | workloads | get, list, watch |
| kueue-workload-editor-role | kueue.x-k8s.io | workloads | create, delete, get, list, patch, update, watch |
| kueue-resourceflavor-viewer-role | kueue.x-k8s.io | resourceflavors | get, list, watch |
| kueue-resourceflavor-editor-role | kueue.x-k8s.io | resourceflavors | create, delete, get, list, patch, update, watch |

### RBAC - Role Bindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| kueue-manager-rolebinding | opendatahub | kueue-manager-role (ClusterRole) | opendatahub/kueue-controller-manager |
| kueue-leader-election-rolebinding | opendatahub | kueue-leader-election-role | opendatahub/kueue-controller-manager |
| kueue-batch-user-rolebinding | opendatahub | kueue-batch-user-role | opendatahub/default |

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| kueue-webhook-server-cert | kubernetes.io/tls | TLS certificate for webhook server | cert-manager or internal-cert | Yes |
| kueue-visibility-server-cert | kubernetes.io/tls | TLS certificate for visibility API server | cert-manager or internal-cert | Yes |

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| /mutate-*, /validate-* | POST | mTLS (client cert) | Kubernetes API Server | Webhook CA bundle verification |
| /metrics (8443) | GET | Bearer Token (OAuth) | kube-rbac-proxy | RBAC: kueue-metrics-reader |
| /metrics (8080) | GET | None | None | Cluster-internal only |
| Visibility API | GET | Bearer Token (ServiceAccount) | Kubernetes API Server | RBAC on visibility.kueue.x-k8s.io resources |
| /healthz, /readyz | GET | None | None | Cluster-internal health checks |

### Network Policies

| Policy Name | Pod Selector | Ingress Rules | Egress Rules |
|-------------|-------------|---------------|--------------|
| kueue-webhook-server | app.kubernetes.io/name: kueue | Allow TCP/9443 from all | Not restricted |

## Data Flows

### Flow 1: Job Submission and Admission

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User/App | Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | Bearer Token/Client Cert |
| 2 | Kubernetes API Server | kueue-webhook-service | 9443/TCP | HTTPS | TLS | mTLS |
| 3 | kueue-controller-manager | Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 4 | kueue-controller-manager | Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |

**Description**: User submits a Job/TFJob/PyTorchJob. Kueue's mutating webhook intercepts creation, creates a Workload CRD. Controller watches Workload, evaluates against ClusterQueue quotas, and admits workload if resources are available. Admitted workload allows job pods to be created.

### Flow 2: Metrics Collection

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Prometheus | kueue-metrics-service | 8080/TCP | HTTP | None | None |
| 2 | Prometheus (authenticated) | kueue-controller-manager-metrics-service | 8443/TCP | HTTPS | TLS 1.2+ | Bearer Token |

**Description**: Prometheus scrapes metrics from Kueue controller exposing queue depths, admitted workloads, resource usage, and quota information.

### Flow 3: Visibility API Query

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User/CLI | Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | Bearer Token |
| 2 | Kubernetes API Server | kueue-visibility-server | 8082/TCP | HTTPS | TLS | ServiceAccount delegation |

**Description**: User queries pending workloads via visibility API to inspect queue positions and priorities.

### Flow 4: Cluster Autoscaler Integration

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | kueue-controller-manager | Kubernetes API Server (autoscaling.x-k8s.io) | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |

**Description**: When admission check requires provisioning, Kueue creates ProvisioningRequest to trigger cluster-autoscaler to provision new nodes.

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| Kubernetes API Server | REST API (Watch/List) | 6443/TCP | HTTPS | TLS 1.2+ | Watch jobs, pods, CRDs; reconcile workloads |
| Kubeflow Training Operator | Mutating Webhook | 9443/TCP | HTTPS | TLS | Intercept TFJob, PyTorchJob, MPIJob, XGBoostJob creation |
| Ray Operator | Mutating Webhook | 9443/TCP | HTTPS | TLS | Intercept RayJob and RayCluster creation |
| JobSet | Mutating Webhook | 9443/TCP | HTTPS | TLS | Intercept JobSet creation |
| Batch Jobs | Mutating Webhook | 9443/TCP | HTTPS | TLS | Intercept Kubernetes Job creation |
| Prometheus | Metrics Pull | 8080/TCP or 8443/TCP | HTTP/HTTPS | None/TLS 1.2+ | Collect queue and resource metrics |
| Cluster Autoscaler | ProvisioningRequest API | 6443/TCP | HTTPS | TLS 1.2+ | Trigger node provisioning for pending workloads |

## Deployment Configuration

### RHOAI-Specific Settings
- **Namespace**: `opendatahub`
- **Name Prefix**: `kueue-`
- **Image**: Configured via ConfigMap `kueue-rhoai-config` (default: registry.k8s.io/kueue/kueue:v0.7.0)
- **Components Deployed**:
  - CRDs
  - RBAC (manager role, viewer/editor roles)
  - Controller manager deployment
  - Internal cert manager
  - Webhook server
  - Visibility server
  - Prometheus monitoring (PodMonitor, PrometheusRule)
  - Network policy for webhook

### Resource Requirements
- **CPU**: 500m (requests and limits)
- **Memory**: 512Mi (requests and limits)
- **Replicas**: 1

### Container Security
- **Run as non-root**: Yes
- **User ID**: 65532:65532
- **Allow privilege escalation**: No
- **Image**: UBI9-based (Red Hat Universal Base Image)

## Monitoring and Observability

### Prometheus Metrics

| Metric Name | Type | Purpose |
|-------------|------|---------|
| kueue_cluster_queue_resource_usage | Gauge | Resource usage per ClusterQueue |
| kueue_cluster_queue_nominal_quota | Gauge | Nominal quota per ClusterQueue |
| kueue_cluster_queue_resource_reservation | Gauge | Reserved resources per ClusterQueue |
| kueue_pending_workloads | Gauge | Number of pending workloads |
| kueue_admitted_workloads_total | Counter | Total admitted workloads |
| kueue_evicted_workloads_total | Counter | Total evicted workloads |
| kube_pod_status_ready | Gauge | Kueue pod readiness status |
| kube_pod_status_phase | Gauge | Kueue pod phase |

### Prometheus Alerts

| Alert Name | Severity | Condition | Description |
|------------|----------|-----------|-------------|
| KueuePodDown | Critical | kueue pod not ready for 5m | Kueue controller is unavailable |
| LowClusterQueueResourceUsage | Info | Resource usage < 20% for 1 day | Underutilized quota |
| ResourceReservationExceedsQuota | Info | Reservation > 10x quota for 10m | Over-subscription detected |
| PendingWorkloadPods | Info | Pods pending > 3 days | Long-pending workloads |

## Recent Changes

**Note**: No recent commits found in the last 3 months. This appears to be a stable RHOAI-specific branch (rhoai-2.12) forked from upstream Kueue v0.7.0.

| Version | Date | Changes |
|---------|------|---------|
| v0.7.0 (rhoai-2.12) | 2024+ | - RHOAI-specific customizations<br>- OpenShift monitoring integration (PrometheusRule in openshift-monitoring namespace)<br>- UBI9-based container images<br>- RHOAI namespace configuration (opendatahub)<br>- Network policy for webhook security |

## Operational Notes

### High Availability
- Currently deployed with 1 replica (single controller)
- Leader election enabled for future multi-replica support
- Controller failure stops new workload admissions but running jobs continue

### Scaling Considerations
- Controller memory usage scales with number of ClusterQueues, LocalQueues, and Workloads
- Default 512Mi memory suitable for ~1000 workloads
- Metrics scraping interval affects memory for time-series data

### Troubleshooting
1. **Workloads not admitted**: Check ClusterQueue quotas, ResourceFlavors, and AdmissionChecks
2. **Webhook failures**: Verify webhook certificates are valid and not expired
3. **Pod pending**: Check `kubectl get workloads -A` for admission status and conditions
4. **Metrics missing**: Verify PodMonitor selector matches controller pod labels

### Configuration Files
- **Main config**: `config/rhoai/kustomization.yaml` (RHOAI deployment)
- **Manager config**: `config/components/manager/controller_manager_config.yaml`
- **CRD location**: `config/components/crd/bases/`
- **RBAC location**: `config/components/rbac/`
