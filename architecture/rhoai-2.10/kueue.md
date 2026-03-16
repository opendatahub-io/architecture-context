# Component: Kueue

## Metadata
- **Repository**: https://github.com/red-hat-data-services/kueue
- **Version**: 5b3bf2841 (based on upstream Kueue v0.6.2)
- **Branch**: rhoai-2.10
- **Distribution**: RHOAI
- **Languages**: Go
- **Deployment Type**: Kubernetes Operator
- **Namespace**: opendatahub
- **Name Prefix**: kueue-

## Purpose
**Short**: Kueue is a Kubernetes-native job queueing system that manages job admission and resource allocation based on quotas and priorities.

**Detailed**:
Kueue provides a set of APIs and controllers for job queueing in Kubernetes clusters. It acts as a job-level manager that decides when a job should be admitted to start (allowing pods to be created) and when it should stop (requiring active pods to be deleted). Kueue supports multiple job types including Kubernetes batch Jobs, Kubeflow training jobs (TensorFlow, PyTorch, MPI), Ray jobs and clusters, and JobSets.

The system manages resource allocation through ClusterQueues (cluster-scoped resource pools) and LocalQueues (namespace-scoped user-facing queues). It supports advanced features like resource fair sharing, preemption, priority-based queueing with StrictFIFO and BestEffortFIFO strategies, dynamic resource reclaim, quota borrowing between cohorts, and integration with cluster autoscaler for provisioning. Kueue intercepts job creation via admission webhooks, creates Workload objects to represent queued jobs, and manages the admission process based on available quota and admission checks.

In RHOAI, Kueue enables multi-tenant resource management for AI/ML workloads, ensuring fair resource distribution and efficient utilization across different teams and projects.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| kueue-controller-manager | Deployment | Main controller reconciling Workloads, ClusterQueues, LocalQueues, and managing job admission |
| kueue-webhook-server | Webhook Server | Mutating and validating admission webhooks for jobs and Kueue CRDs |
| kueue-visibility-server | APIServer Extension | Optional aggregated API server for visibility API (v1alpha1) |
| Queue Manager | Controller Component | Manages workload queueing with FIFO/priority strategies and fair sharing |
| Scheduler | Controller Component | Assigns workloads to resource flavors and performs admission decisions |
| Job Framework | Integration Layer | Pluggable framework supporting multiple job types (Batch, Kubeflow, Ray, etc.) |

## APIs Exposed

### Custom Resource Definitions (CRDs)

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| kueue.x-k8s.io | v1beta1 | ClusterQueue | Cluster | Manages cluster-wide resource quotas, admission policies, and queueing strategies |
| kueue.x-k8s.io | v1beta1 | LocalQueue | Namespaced | User-facing queue that references a ClusterQueue for workload submission |
| kueue.x-k8s.io | v1beta1 | Workload | Namespaced | Represents a job submission with resource requirements and admission status |
| kueue.x-k8s.io | v1beta1 | ResourceFlavor | Cluster | Defines resource types/flavors with node labels, taints, and tolerations |
| kueue.x-k8s.io | v1beta1 | AdmissionCheck | Cluster | Defines admission checks required before workload admission |
| kueue.x-k8s.io | v1beta1 | WorkloadPriorityClass | Cluster | Defines priority values for workload scheduling |
| kueue.x-k8s.io | v1beta1 | ProvisioningRequestConfig | Cluster | Configures integration with cluster autoscaler provisioning requests |
| kueue.x-k8s.io | v1beta1 | MultiKueueCluster | Cluster | Defines remote clusters for multi-cluster workload distribution |
| kueue.x-k8s.io | v1beta1 | MultiKueueConfig | Cluster | Configures multi-cluster queueing behavior |
| visibility.kueue.x-k8s.io | v1alpha1 | PendingWorkload | Namespaced | API for querying pending workloads (visibility server) |

### HTTP Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /healthz | GET | 8081/TCP | HTTP | None | None | Liveness probe endpoint |
| /readyz | GET | 8081/TCP | HTTP | None | None | Readiness probe endpoint |
| /metrics | GET | 8080/TCP | HTTP | None | None | Prometheus metrics endpoint (direct) |
| /metrics | GET | 8443/TCP | HTTPS | TLS 1.2+ | kube-rbac-proxy | Prometheus metrics endpoint (authenticated) |
| /mutate-batch-v1-job | POST | 9443/TCP | HTTPS | TLS 1.2+ | Kubernetes API | Mutating webhook for batch Jobs |
| /mutate-kueue-x-k8s-io-v1beta1-workload | POST | 9443/TCP | HTTPS | TLS 1.2+ | Kubernetes API | Mutating webhook for Workloads |
| /validate-kueue-x-k8s-io-v1beta1-clusterqueue | POST | 9443/TCP | HTTPS | TLS 1.2+ | Kubernetes API | Validating webhook for ClusterQueues |
| /validate-kueue-x-k8s-io-v1beta1-localqueue | POST | 9443/TCP | HTTPS | TLS 1.2+ | Kubernetes API | Validating webhook for LocalQueues |
| /validate-kueue-x-k8s-io-v1beta1-resourceflavor | POST | 9443/TCP | HTTPS | TLS 1.2+ | Kubernetes API | Validating webhook for ResourceFlavors |
| /validate-kueue-x-k8s-io-v1beta1-workload | POST | 9443/TCP | HTTPS | TLS 1.2+ | Kubernetes API | Validating webhook for Workloads |

### Webhook Configurations

**Mutating Webhooks** (intercept job creation to inject queue information):
- Kubernetes Jobs (batch/v1)
- JobSets (jobset.x-k8s.io/v1alpha2)
- Kubeflow TFJob, PyTorchJob, MPIJob, MXJob, XGBoostJob, PaddleJob (kubeflow.org/v1, v2beta1)
- Ray RayJob, RayCluster (ray.io/v1)
- Pods (v1)
- Kueue Workloads (kueue.x-k8s.io/v1beta1)

**Validating Webhooks** (validate Kueue CRD specifications):
- ClusterQueue, LocalQueue, ResourceFlavor, Workload, AdmissionCheck, WorkloadPriorityClass

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| Kubernetes | 1.22+ | Yes | Platform for deploying and running Kueue operator |
| cert-manager | Any | No | TLS certificate management for webhooks (alternative: internal cert generation) |
| Prometheus | Any | No | Metrics collection and monitoring |
| Kubeflow Training Operator | v1, v2beta1 | No | Support for ML training jobs (TFJob, PyTorchJob, MPIJob, etc.) |
| JobSet | v1alpha2 | No | Support for JobSet workloads |
| Ray Operator | v1 | No | Support for RayJob and RayCluster workloads |
| Cluster Autoscaler | Latest | No | Integration via ProvisioningRequest for guaranteed resource provisioning |

### Internal ODH/RHOAI Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| Kubeflow Training Operator | CRD Webhooks | Manages queueing for distributed ML training jobs |
| Ray | CRD Webhooks | Manages queueing for Ray jobs and clusters |
| Monitoring Stack | Metrics Scraping | Exposes queue metrics via ServiceMonitor |

## Network Architecture

### Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| kueue-controller-manager-metrics-service | ClusterIP | 8443/TCP | https | HTTPS | TLS 1.2+ | kube-rbac-proxy | Internal |
| kueue-metrics-service | ClusterIP | 8080/TCP | metrics (8080) | HTTP | None | None | Internal |
| kueue-webhook-service | ClusterIP | 443/TCP | 9443 | HTTPS | TLS 1.2+ | Kubernetes API | Internal |
| kueue-visibility-server | ClusterIP | 443/TCP | 8082 | HTTPS | TLS 1.2+ | Kubernetes API | Internal (optional) |

### Ingress

No external ingress configured. All services are internal ClusterIP services accessed within the cluster.

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token | Watch/update Jobs, Pods, Workloads, CRDs |
| autoscaling.x-k8s.io API | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token | Create/manage ProvisioningRequests for autoscaling |

### Network Policies

| Name | Selector | Ingress Rules | Egress Rules | Purpose |
|------|----------|---------------|--------------|---------|
| kueue-webhook-server | app.kubernetes.io/name=kueue | Allow TCP 9443 from any | Not specified | Allow webhook traffic to controller manager |

## Security

### RBAC - Cluster Roles

| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|
| kueue-manager-role | "" | events, limitranges, namespaces | create, patch, update, watch / get, list, watch |
| kueue-manager-role | "" | pods, pods/finalizers, pods/status | delete, get, list, patch, update, watch |
| kueue-manager-role | "" | secrets | get, list, update, watch |
| kueue-manager-role | batch | jobs, jobs/finalizers, jobs/status | get, list, patch, update, watch |
| kueue-manager-role | kueue.x-k8s.io | clusterqueues, localqueues, workloads, resourceflavors, admissionchecks, workloadpriorityclasses, provisioningrequestconfigs | get, list, watch, create, update, patch, delete |
| kueue-manager-role | kueue.x-k8s.io | */status | get, update, patch |
| kueue-manager-role | kueue.x-k8s.io | */finalizers | update |
| kueue-manager-role | kubeflow.org | tfjobs, pytorchjobs, mpijobs, mxjobs, xgboostjobs, paddlejobs | get, list, watch, update, patch |
| kueue-manager-role | jobset.x-k8s.io | jobsets | get, list, watch, update, patch |
| kueue-manager-role | ray.io | rayjobs, rayclusters | get, list, watch, update, patch |
| kueue-manager-role | autoscaling.x-k8s.io | provisioningrequests | create, delete, get, list, patch, update, watch |
| kueue-manager-role | admissionregistration.k8s.io | mutatingwebhookconfigurations, validatingwebhookconfigurations | get, list, update, watch |
| kueue-batch-admin-role | kueue.x-k8s.io | All Kueue resources | All verbs | Aggregate role for batch administrators |
| kueue-batch-user-role | kueue.x-k8s.io | localqueues, workloads | get, list, watch (limited) | Basic user access to queues |
| kueue-clusterqueue-viewer-role | kueue.x-k8s.io | clusterqueues | get, list, watch |
| kueue-*-editor-role | kueue.x-k8s.io | Specific resource types | create, delete, get, list, patch, update, watch |
| kueue-*-viewer-role | kueue.x-k8s.io | Specific resource types | get, list, watch |

### RBAC - Role Bindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| kueue-leader-election-rolebinding | opendatahub | kueue-leader-election-role | kueue-controller-manager |
| kueue-manager-rolebinding | Cluster-wide | kueue-manager-role | opendatahub/kueue-controller-manager |
| kueue-batch-user-rolebinding | opendatahub | kueue-batch-user-role | system:authenticated |
| kueue-auth-proxy-rolebinding | opendatahub | kueue-auth-proxy-role | kueue-controller-manager |

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| kueue-webhook-server-cert | kubernetes.io/tls | TLS certificate for webhook server | cert-manager or internal cert generation | Yes (cert-manager) |
| kueue-visibility-server-cert | kubernetes.io/tls | TLS certificate for visibility API server | cert-manager or internal cert generation | Yes (cert-manager) |

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| /metrics (8443) | GET | Bearer Token (ServiceAccount) | kube-rbac-proxy | Kubernetes RBAC |
| /mutate-* (9443) | POST | Kubernetes API Server Auth | Kubernetes API Server | ValidatingWebhookConfiguration clientConfig |
| /validate-* (9443) | POST | Kubernetes API Server Auth | Kubernetes API Server | MutatingWebhookConfiguration clientConfig |
| Kubernetes API | All | ServiceAccount Token | Kubernetes API Server | RBAC ClusterRole kueue-manager-role |
| Visibility API (8082) | All | Kubernetes API Server Auth | API Aggregation | APIService configuration |

### Pod Security

| Setting | Value | Purpose |
|---------|-------|---------|
| runAsNonRoot | true | Prevent root execution |
| allowPrivilegeEscalation | false | Prevent privilege escalation |
| User/Group | 65532:65532 | Non-root user execution |
| securityContext | Restricted | Drop all capabilities |

## Data Flows

### Flow 1: Job Submission and Admission

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User/Application | Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | User credentials |
| 2 | Kubernetes API Server | kueue-webhook-service | 443/TCP (9443) | HTTPS | TLS 1.2+ | API Server cert |
| 3 | Kueue Webhook | Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 4 | Kueue Controller | Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |

**Description**: User submits a Job → API Server calls mutating webhook → Webhook injects queue name and creates Workload → Controller watches Workload → Scheduler evaluates quota → If quota available, admits Workload → Controller unsuspends Job → Pods are created.

### Flow 2: Metrics Collection

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Prometheus | kueue-metrics-service | 8080/TCP | HTTP | None | None |
| 2 | Prometheus | kueue-controller-manager-metrics-service | 8443/TCP | HTTPS | TLS 1.2+ | Bearer Token (ServiceAccount) |

**Description**: Prometheus scrapes metrics from Kueue controller via ServiceMonitor, collecting queue depths, admission rates, and workload statistics.

### Flow 3: Workload Queueing and Preemption

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Kueue Controller | Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 2 | Kueue Controller | Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |

**Description**: Controller watches ClusterQueue quota usage → If quota exceeded and higher priority workload arrives → Controller evicts lower priority workload → Sets admitted=false on Workload → Job controller suspends Job and deletes Pods.

### Flow 4: Autoscaler Integration

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Kueue Controller | Kubernetes API Server (autoscaling.x-k8s.io) | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 2 | Cluster Autoscaler | Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 3 | Kueue Controller | Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |

**Description**: When AdmissionCheck references ProvisioningRequestConfig → Kueue creates ProvisioningRequest → Cluster Autoscaler provisions nodes → Once ready, Kueue admits workload.

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| Kubernetes API Server | REST API | 6443/TCP | HTTPS | TLS 1.2+ | Watch/update all managed resources |
| Kubeflow Training Operator | Mutating Webhook | 9443/TCP | HTTPS | TLS 1.2+ | Intercept training job creation for queueing |
| JobSet Controller | Mutating Webhook | 9443/TCP | HTTPS | TLS 1.2+ | Intercept JobSet creation for queueing |
| Ray Operator | Mutating Webhook | 9443/TCP | HTTPS | TLS 1.2+ | Intercept Ray job/cluster creation for queueing |
| Cluster Autoscaler | CRD API (ProvisioningRequest) | 6443/TCP | HTTPS | TLS 1.2+ | Request guaranteed node provisioning |
| Prometheus | Metrics Scraping | 8080/TCP, 8443/TCP | HTTP, HTTPS | TLS 1.2+ (8443) | Collect queue and workload metrics |

## Deployment Configuration

### Container Images

| Container | Image | Purpose |
|-----------|-------|---------|
| manager | UBI9-based Go binary | Main Kueue controller manager |
| kube-rbac-proxy | gcr.io/kubebuilder/kube-rbac-proxy | RBAC authentication for metrics endpoint |

### Resource Limits

| Container | CPU Request | CPU Limit | Memory Request | Memory Limit |
|-----------|-------------|-----------|----------------|--------------|
| manager | 500m | 500m | 512Mi | 512Mi |
| kube-rbac-proxy | Not specified | Not specified | Not specified | Not specified |

### Replicas

| Deployment | Replicas | Strategy |
|------------|----------|----------|
| kueue-controller-manager | 1 | Rolling Update |

**Note**: Single replica with leader election for high availability support. Only one instance is active at a time.

## Observability

### Prometheus Metrics

Kueue exposes comprehensive metrics including:
- **Queue Metrics**: pending workloads, admitted workloads per ClusterQueue/LocalQueue
- **Admission Metrics**: admission attempts, admission latency, admission cycle duration
- **Quota Metrics**: quota usage, reserved quota, borrowed quota per ClusterQueue
- **Preemption Metrics**: preemption counts, reasons
- **Controller Metrics**: reconciliation duration, workqueue depth, API call latency

Metrics endpoint: `http://kueue-metrics-service:8080/metrics` (internal) or `https://kueue-controller-manager-metrics-service:8443/metrics` (authenticated)

### Health Checks

- **Liveness**: `http://:8081/healthz`
- **Readiness**: `http://:8081/readyz`

### Logging

Structured logging via klog with configurable log level (default: 2). Logs include:
- Workload admission/preemption events
- Queue state changes
- Webhook validation/mutation results
- Controller reconciliation errors

## Configuration

### Controller Configuration

Managed via ConfigMap with controller-runtime configuration including:
- Webhook server port: 9443
- Metrics bind address: :8080
- Health probe bind address: :8081
- Leader election: enabled
- Sync period, timeout settings

### Feature Gates

Kueue supports feature gates for alpha/beta features:
- **PartialAdmission**: Allow jobs to run with reduced parallelism
- **ProvisioningRequestConfig**: Autoscaler integration
- **MultiKueue**: Multi-cluster workload distribution
- **VisibilityAPI**: Aggregated API for visibility

Configured via command-line flags or controller configuration.

## Recent Changes

| Commit | Date | Changes |
|--------|------|---------|
| 5b3bf2841 | 2024 | Merge pull request #11: RHTAP purge for kueue-210 |
| 7f84b0414 | 2024 | Red Hat Konflux purge kueue-210 |
| 519fdc19c | 2024 | Merge pull request #8: Update Konflux references for rhoai-2.10 |
| a19d1d840 | 2024 | Update RHTAP references |
| a504c5283 | 2024 | Merge pull request #9: Update kueue Tekton pipeline |
| 317cb17c3 | 2024 | Updating Tekton file for kueue |
| 210676f1a | 2024 | Merge pull request #7: Konflux update kueue-210 |
| 51cd91e10 | 2024 | Red Hat Konflux update kueue-210 |
| fdafd7a7b | 2024 | **CARRY**: Add dedicated Dockerfile for Konflux |
| 00db55463 | 2024 | **PATCH**: Move service to resources from patch |
| c312b2d13 | 2024 | **PATCH**: Add service for kueue metrics |
| d3d458de8 | 2024 | **CARRY**: Add delete patch to remove default namespace |
| 4cf5cceab | 2024 | **PATCH**: Rebase on Kueue v0.6.2 |
| d7083e9cb | 2024 | **CARRY**: Set waitForPodsReady to true by default (#23) |
| d6d413a8f | 2024 | **CARRY**: Add workflow to release ODH/Kueue with compiled test binaries |
| 5bf273006 | 2024 | **CARRY**: Allow non-admin user access to view clusterqueue (metrics) |
| 91eed92a0 | 2024 | **CARRY**: Use env variable 'NAMESPACE' for e2e tests |
| b13c3d516 | 2024 | **CARRY**: Add Kueue webhook NetworkPolicy |
| 323ee05bb | 2024 | **DROP**: Use uniquely identifying labels |
| 20727dca9 | 2024 | **PATCH**: Change func to wait until admission check is properly removed |

### RHOAI-Specific Changes

The RHOAI distribution includes several patches and customizations:
- **Konflux Build**: Dedicated Dockerfile.rhoai for Red Hat Konflux CI/CD pipeline
- **Namespace Configuration**: Deploys to `opendatahub` namespace instead of `kueue-system`
- **Network Policy**: Added NetworkPolicy for webhook server
- **Metrics Service**: Dedicated service for metrics exposure
- **RBAC Enhancements**: Allow non-admin users to view ClusterQueue metrics
- **Default Settings**: waitForPodsReady set to true by default
- **Based on v0.6.2**: Rebased on upstream Kueue v0.6.2 with RHOAI patches

## Upstream Information

- **Upstream Project**: https://github.com/kubernetes-sigs/kueue
- **Documentation**: https://kueue.sigs.k8s.io/
- **API Version**: v1beta1 (respects Kubernetes Deprecation Policy)
- **Upstream Version**: v0.6.2
- **License**: Apache 2.0
- **Community**: SIG Scheduling, WG Batch

## Known Limitations

1. **Single Controller Instance**: Only one active controller manager instance (leader election ensures HA readiness but not active-active)
2. **Webhook Availability**: Webhook failures block job submission (failurePolicy: Fail)
3. **API Version**: v1beta1 means API may still evolve before v1
4. **Visibility API**: v1alpha1 status, may change
5. **Multi-cluster**: MultiKueue feature is in development
6. **Resource Types**: Limited to CPU, memory, GPU - custom resources require ResourceFlavor configuration

## Troubleshooting

### Common Issues

1. **Jobs not starting**: Check LocalQueue references valid ClusterQueue, verify quota availability
2. **Webhook errors**: Check webhook service connectivity, certificate validity
3. **Admission failures**: Review AdmissionCheck status, ProvisioningRequest state
4. **Preemption loops**: Review priority classes, cohort borrowing policies
5. **Metrics not available**: Verify ServiceMonitor configuration, network access to metrics service

### Debug Commands

```bash
# Check ClusterQueue status
kubectl get clusterqueue -o wide

# Check LocalQueue status
kubectl get localqueue -n <namespace> -o wide

# Check Workload admission status
kubectl get workloads -n <namespace> -o yaml

# View controller logs
kubectl logs -n opendatahub deployment/kueue-controller-manager -c manager

# Check webhook configuration
kubectl get mutatingwebhookconfigurations
kubectl get validatingwebhookconfigurations

# Test metrics endpoint
kubectl port-forward -n opendatahub svc/kueue-metrics-service 8080:8080
curl http://localhost:8080/metrics
```
