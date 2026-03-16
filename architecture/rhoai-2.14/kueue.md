# Component: Kueue

## Metadata
- **Repository**: https://github.com/red-hat-data-services/kueue
- **Version**: v0.8.1 (commit 630106f49)
- **Distribution**: RHOAI (Red Hat OpenShift AI)
- **Languages**: Go
- **Deployment Type**: Kubernetes Operator

## Purpose
**Short**: Kueue is a Kubernetes-native job queueing system that manages job admission and resource allocation across multiple workload types.

**Detailed**: Kueue provides a set of APIs and controllers for job queueing in Kubernetes clusters. It acts as a job-level manager that decides when jobs should be admitted to start (allowing pods to be created) and when they should stop (deleting active pods). The system supports priority-based queueing with different strategies (StrictFIFO and BestEffortFIFO), resource fair sharing, preemption between tenants, and dynamic resource reclamation. Kueue integrates with various job frameworks including Batch Jobs, Kubeflow training jobs (MPIJob, PyTorchJob, TFJob, etc.), Ray jobs and clusters, JobSets, and in RHOAI, AppWrappers from CodeFlare. It provides cluster administrators with resource quota management capabilities while enabling users to submit jobs to local queues that map to cluster-wide resource pools.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| kueue-controller-manager | Go Operator | Main controller managing job admission, queueing, and resource allocation |
| visibility-server | API Server | REST API for querying pending workloads and queue status |
| webhook-server | Admission Webhook | Mutating and validating webhooks for job resources |
| importer | Utility | Imports and converts existing jobs/pods to Kueue workloads |
| kueuectl | CLI Tool | Command-line interface for managing Kueue resources |

## APIs Exposed

### Custom Resource Definitions (CRDs)

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| kueue.x-k8s.io | v1beta1 | ClusterQueue | Cluster | Defines cluster-level resource pool with quotas and queuing policies |
| kueue.x-k8s.io | v1beta1 | LocalQueue | Namespaced | Namespace-scoped queue that maps to a ClusterQueue |
| kueue.x-k8s.io | v1beta1 | Workload | Namespaced | Internal representation of a job with resource requirements |
| kueue.x-k8s.io | v1beta1 | ResourceFlavor | Cluster | Defines resource variants (e.g., different node types, zones) |
| kueue.x-k8s.io | v1beta1 | WorkloadPriorityClass | Cluster | Defines priority levels for workload scheduling |
| kueue.x-k8s.io | v1beta1 | AdmissionCheck | Cluster | Defines pre-admission checks that workloads must pass |
| kueue.x-k8s.io | v1beta1 | ProvisioningRequestConfig | Cluster | Configuration for cluster autoscaler provisioning requests |
| kueue.x-k8s.io | v1alpha1 | MultiKueueCluster | Cluster | Defines remote cluster for multi-cluster job distribution |
| kueue.x-k8s.io | v1alpha1 | MultiKueueConfig | Cluster | Configuration for multi-cluster job management |

### HTTP Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /metrics | GET | 8080/TCP | HTTP | None | None | Prometheus metrics endpoint |
| /healthz | GET | 8081/TCP | HTTP | None | None | Health check endpoint |
| /readyz | GET | 8081/TCP | HTTP | None | None | Readiness probe endpoint |
| /apis/visibility.kueue.x-k8s.io/v1alpha1/* | GET | 8082/TCP | HTTPS | TLS 1.2+ | K8s Auth | Visibility API for pending workloads |
| /mutate-* | POST | 9443/TCP | HTTPS | TLS 1.2+ | K8s Auth | Mutating webhook endpoints for job resources |
| /validate-* | POST | 9443/TCP | HTTPS | TLS 1.2+ | K8s Auth | Validating webhook endpoints for Kueue CRDs |

### Visibility API (Aggregated API)

| Group | Version | Resources | Purpose |
|-------|---------|-----------|---------|
| visibility.kueue.x-k8s.io | v1alpha1 | clusterqueues, localqueues | Read-only API to query pending workloads per queue |

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| Kubernetes | 1.25+ | Yes | Platform for running the operator |
| cert-manager | 1.x | Optional | TLS certificate management for webhooks |
| Prometheus Operator | 0.50+ | Optional | Metrics collection via ServiceMonitor/PodMonitor |

### Internal RHOAI Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| CodeFlare AppWrapper | CRD Watch | Integration with AppWrapper workloads for distributed training |
| Kubeflow Training Operator | CRD Watch | Integration with MPIJob, PyTorchJob, TFJob, XGBoostJob, PaddleJob, MXJob |
| KServe (via Ray) | CRD Watch | Integration with Ray jobs and clusters for inference workloads |
| JobSet | CRD Watch | Integration with JobSet for multi-job workflows |

## Network Architecture

### Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| controller-manager-metrics-service | ClusterIP | 8443/TCP | https | HTTPS | TLS 1.2+ | Bearer Token | Internal |
| metrics-service | ClusterIP | 8080/TCP | metrics | HTTP | None | None | Internal |
| webhook-service | ClusterIP | 443/TCP | 9443 | HTTPS | TLS 1.2+ | K8s Auth | Internal |
| visibility-server | ClusterIP | 443/TCP | 8082 | HTTPS | TLS 1.2+ | K8s Auth | Internal |

### Ingress

| Name | Type | Hosts | Port | Protocol | Encryption | TLS Mode | Exposure |
|------|------|-------|------|----------|------------|----------|----------|
| N/A | N/A | N/A | N/A | N/A | N/A | N/A | Kueue services are internal only |

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token | Watch and manage Kubernetes resources |
| autoscaling.x-k8s.io API | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token | Create/manage ProvisioningRequests for cluster autoscaling |

### Network Policies

| Name | Namespace | Pod Selector | Ingress Rules | Egress Rules |
|------|-----------|--------------|---------------|--------------|
| webhook-server | kueue-system | All pods | Allow TCP/9443 from any | N/A |

## Security

### RBAC - Cluster Roles

| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|
| manager-role | "" | events, limitranges, namespaces, pods, secrets | create, delete, get, list, patch, update, watch |
| manager-role | batch | jobs | get, list, patch, update, watch |
| manager-role | kueue.x-k8s.io | clusterqueues, localqueues, workloads, admissionchecks, resourceflavors, workloadpriorityclasses, multikueueclusters, multikueueconfigs, provisioningrequestconfigs | create, delete, get, list, patch, update, watch |
| manager-role | kubeflow.org | mpijobs, pytorchjobs, tfjobs, xgboostjobs, mxjobs, paddlejobs | get, list, patch, update, watch |
| manager-role | ray.io | rayjobs, rayclusters | get, list, patch, update, watch |
| manager-role | jobset.x-k8s.io | jobsets | get, list, patch, update, watch |
| manager-role | workload.codeflare.dev | appwrappers | get, list, watch |
| manager-role | autoscaling.x-k8s.io | provisioningrequests | create, delete, get, list, patch, update, watch |
| manager-role | admissionregistration.k8s.io | mutatingwebhookconfigurations, validatingwebhookconfigurations | get, list, update, watch |
| batch-admin-role | "" | events, limitranges, pods, resourcequotas | get, list, watch |
| batch-admin-role | kueue.x-k8s.io | localqueues | create, delete, get, list, patch, update, watch |
| batch-user-role | "" | events, limitranges, pods, resourcequotas | get, list, watch |
| batch-user-role | kueue.x-k8s.io | localqueues | get, list, watch |
| clusterqueue-editor-role | kueue.x-k8s.io | clusterqueues | create, delete, get, list, patch, update, watch |
| clusterqueue-viewer-role | kueue.x-k8s.io | clusterqueues | get, list, watch |
| localqueue-editor-role | kueue.x-k8s.io | localqueues | create, delete, get, list, patch, update, watch |
| localqueue-viewer-role | kueue.x-k8s.io | localqueues | get, list, watch |
| workload-editor-role | kueue.x-k8s.io | workloads | create, delete, get, list, patch, update, watch |
| workload-viewer-role | kueue.x-k8s.io | workloads | get, list, watch |
| resourceflavor-editor-role | kueue.x-k8s.io | resourceflavors | create, delete, get, list, patch, update, watch |
| resourceflavor-viewer-role | kueue.x-k8s.io | resourceflavors | get, list, watch |

### RBAC - Role Bindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| leader-election-role-binding | kueue-system | leader-election-role | controller-manager |
| auth-proxy-role-binding | kueue-system | auth-proxy-role | controller-manager |
| visibility-server-auth-reader | kueue-system | extension-apiserver-authentication-reader | visibility-server |

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| webhook-server-cert | kubernetes.io/tls | TLS certificate for webhook server | cert-manager or internal cert manager | Yes |
| visibility-server-cert | kubernetes.io/tls | TLS certificate for visibility API server | cert-manager or internal cert manager | Yes |

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| /metrics | GET | None | Application | Public within cluster |
| /healthz, /readyz | GET | None | Application | Public within cluster |
| /apis/visibility.kueue.x-k8s.io/* | GET | Bearer Token (ServiceAccount) | Kubernetes API Server | RBAC enforced by K8s |
| Webhook endpoints | POST | Kubernetes API Server mTLS | Webhook Server | K8s API Server authenticates calls |

## Data Flows

### Flow 1: Job Submission and Admission

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User/Controller | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | Bearer Token |
| 2 | Kubernetes API | Webhook Service | 9443/TCP | HTTPS | TLS 1.2+ | K8s mTLS |
| 3 | Webhook Service | Job Framework API | In-process | N/A | N/A | N/A |
| 4 | Kueue Controller | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 5 | Kueue Controller | Workload Creation | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 6 | Kueue Scheduler | ClusterQueue Evaluation | In-process | N/A | N/A | N/A |
| 7 | Kueue Controller | Job/Pod Update | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |

### Flow 2: Metrics Collection

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Prometheus | metrics-service | 8080/TCP | HTTP | None | None |
| 2 | Application | Metrics Endpoint | In-process | N/A | N/A | N/A |

### Flow 3: Visibility API Query

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User/Client | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | Bearer Token |
| 2 | Kubernetes API | visibility-server | 8082/TCP | HTTPS | TLS 1.2+ | K8s mTLS |
| 3 | visibility-server | Queue Cache | In-process | N/A | N/A | N/A |

### Flow 4: Cluster Autoscaling Integration

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Kueue Controller | ProvisioningRequest Creation | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 2 | Cluster Autoscaler | ProvisioningRequest Watch | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 3 | Cluster Autoscaler | Cloud Provider API | 443/TCP | HTTPS | TLS 1.2+ | Cloud IAM |
| 4 | Cluster Autoscaler | ProvisioningRequest Status Update | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| Kubernetes API Server | REST API | 6443/TCP | HTTPS | TLS 1.2+ | Core resource management and watches |
| Batch Jobs (batch/v1) | CRD Watch | 6443/TCP | HTTPS | TLS 1.2+ | Job queueing and admission control |
| Kubeflow MPIJob | CRD Watch | 6443/TCP | HTTPS | TLS 1.2+ | Distributed training job management |
| Kubeflow PyTorchJob | CRD Watch | 6443/TCP | HTTPS | TLS 1.2+ | PyTorch distributed training management |
| Kubeflow TFJob | CRD Watch | 6443/TCP | HTTPS | TLS 1.2+ | TensorFlow distributed training management |
| Ray RayJob | CRD Watch | 6443/TCP | HTTPS | TLS 1.2+ | Ray job queueing and resource management |
| Ray RayCluster | CRD Watch | 6443/TCP | HTTPS | TLS 1.2+ | Ray cluster resource allocation |
| JobSet | CRD Watch | 6443/TCP | HTTPS | TLS 1.2+ | Multi-job workflow coordination |
| AppWrapper (CodeFlare) | CRD Watch | 6443/TCP | HTTPS | TLS 1.2+ | RHOAI-specific workload wrapper for distributed training |
| Cluster Autoscaler | ProvisioningRequest API | 6443/TCP | HTTPS | TLS 1.2+ | Dynamic node provisioning based on pending workloads |
| Prometheus | Metrics Scrape | 8080/TCP | HTTP | None | Monitoring queue depths, admission rates, resource usage |

## Recent Changes

| Version | Date | Changes |
|---------|------|---------|
| v0.8.1-rhoai | 2026-03 | - CARRY: Removing kueue runbooks<br>- CARRY: Upgrade Kueue image to v0.8.1<br>- CARRY: Remove check for restarted pod from test suite<br>- CARRY: Use env variable 'NAMESPACE' for e2e tests |
| v0.8.1-rhoai | 2026-02 | - CARRY: Add .snyk file to ignore cmd/kueuectl and test directories from snyk scans<br>- CARRY: Update workflow to trigger manually only<br>- CARRY: Updating runbook urls for use on OpenShift alerting UI<br>- CARRY: Adding runbooks for alerts |
| v0.8.1-rhoai | 2026-01 | - CARRY: use golang version workaround for ubi9 image<br>- CARRY: Adding info level alerts<br>- CARRY: kueue manager needs RBACs to get,list,watch AppWrappers<br>- CARRY: ODH build and publish image<br>- CARRY: Register AppWrappers as an externalFramework for Kueue |
| v0.8.1-rhoai | 2025-12 | - PATCH: Use previous Go 1.22.2 version for compatibility purposes<br>- CARRY: Add dedicated Dockerfile for Konflux<br>- PATCH: move service to resources from patch<br>- PATCH: add service for kueue metrics<br>- CARRY: Add delete patch to remove default namespace |
| v0.8.1-rhoai | 2025-11 | - CARRY: Set waitForPodsReady to true by default<br>- CARRY: Add workflow to release ODH/Kueue with compiled test binaries |

## Controllers and Reconciliation Logic

### Core Controllers

| Controller | Watches | Reconciles | Purpose |
|------------|---------|------------|---------|
| ClusterQueueController | ClusterQueue | ClusterQueue status | Manages cluster-level resource quotas and admission policies |
| LocalQueueController | LocalQueue | LocalQueue status | Maps namespace queues to cluster queues |
| WorkloadController | Workload, Jobs, Pods | Workload admission/status | Coordinates job admission and pod lifecycle |
| ResourceFlavorController | ResourceFlavor | ResourceFlavor validation | Manages resource variant definitions |
| AdmissionCheckController | AdmissionCheck | AdmissionCheck status | Executes pre-admission checks for workloads |

### Job Framework Integrations

| Framework | Group/Version | Controller | Webhook Support |
|-----------|---------------|------------|-----------------|
| Batch Job | batch/v1 | JobReconciler | Mutating |
| MPIJob | kubeflow.org/v1, v2beta1 | MPIJobReconciler | Mutating |
| PyTorchJob | kubeflow.org/v1 | PyTorchJobReconciler | Mutating |
| TFJob | kubeflow.org/v1 | TFJobReconciler | Mutating |
| XGBoostJob | kubeflow.org/v1 | XGBoostJobReconciler | Mutating |
| MXJob | kubeflow.org/v1 | MXJobReconciler | Mutating |
| PaddleJob | kubeflow.org/v1 | PaddleJobReconciler | Mutating |
| RayJob | ray.io/v1 | RayJobReconciler | Mutating |
| RayCluster | ray.io/v1 | RayClusterReconciler | Mutating |
| JobSet | jobset.x-k8s.io/v1alpha2 | JobSetReconciler | Mutating |
| AppWrapper | workload.codeflare.dev/v1beta2 | AppWrapperReconciler | Mutating |

## Configuration

### Manager Configuration (config.kueue.x-k8s.io/v1beta1)

| Setting | Default | Purpose |
|---------|---------|---------|
| health.healthProbeBindAddress | :8081 | Health and readiness probe port |
| metrics.bindAddress | :8080 | Prometheus metrics port |
| metrics.enableClusterQueueResources | true | Export ClusterQueue resource metrics |
| webhook.port | 9443 | Webhook server port |
| leaderElection.leaderElect | true | Enable leader election for HA |
| waitForPodsReady.enable | true | Wait for all pods to be ready before admission |
| waitForPodsReady.blockAdmission | false | Block admission if pods not ready (RHOAI: false) |
| controller.groupKindConcurrency.Job.batch | 5 | Concurrent Job reconciliations |
| controller.groupKindConcurrency.Workload | 5 | Concurrent Workload reconciliations |
| controller.groupKindConcurrency.ClusterQueue | 1 | Concurrent ClusterQueue reconciliations |
| clientConnection.qps | 50 | Kubernetes API QPS limit |
| clientConnection.burst | 100 | Kubernetes API burst limit |

## Deployment Manifests

### Kustomize Structure

| Path | Purpose |
|------|---------|
| config/default | Default deployment with webhooks and cert-manager |
| config/rhoai | RHOAI-specific patches (metrics, monitoring, RBAC, network policies) |
| config/components/crd | CRD definitions |
| config/components/rbac | RBAC roles and bindings |
| config/components/manager | Controller manager deployment |
| config/components/webhook | Webhook server configuration |
| config/components/visibility | Visibility API server deployment |
| config/components/prometheus | Prometheus monitoring resources |

### Container Images

| Image | Build Path | Purpose |
|-------|-----------|---------|
| kueue-controller-manager | Dockerfile.rhoai | Main operator with all controllers and webhooks |
| kueue-visibility | cmd/experimental/kjobctl | Visibility API server (experimental) |
| kueue-importer | cmd/importer | Job import utility |

## Observability

### Prometheus Metrics

| Metric Type | Examples | Purpose |
|-------------|----------|---------|
| Queue Metrics | kueue_pending_workloads, kueue_admitted_workloads | Track workload states per queue |
| Cluster Queue Metrics | kueue_cluster_queue_status, kueue_cluster_queue_nominal_quota | Monitor cluster-level resource allocation |
| Admission Metrics | kueue_admission_attempts_total, kueue_admission_wait_time | Track admission performance |
| Controller Metrics | workqueue_depth, reconcile_duration_seconds | Monitor controller performance |

### Monitoring Resources

| Resource | Type | Purpose |
|----------|------|---------|
| controller-manager-metrics-monitor | ServiceMonitor | Scrape metrics from controller via service |
| controller-manager-metrics-monitor | PodMonitor | Scrape metrics directly from controller pods |
| kueue-alerts | PrometheusRule | Alert rules for queue depths, admission failures |

## Known Limitations and Considerations

1. **Namespace Scope**: LocalQueues are namespaced; users cannot see or interact with queues in other namespaces
2. **Resource Preemption**: Preemption may disrupt running workloads; configure WorkloadPriorityClass carefully
3. **Webhook Dependencies**: Admission control requires webhook service availability; use cert-manager for production
4. **Multi-cluster**: MultiKueue features are in alpha (v1alpha1) and may have stability limitations
5. **AppWrapper Integration**: RHOAI-specific feature; not available in upstream Kueue
6. **Wait for Pods Ready**: Enabled by default in RHOAI to ensure all pods start before admission confirmation

## RHOAI-Specific Features

| Feature | Description |
|---------|-------------|
| AppWrapper Integration | Native support for CodeFlare AppWrappers as external framework |
| Metrics Service | Dedicated ClusterIP service for Prometheus metrics scraping |
| PodMonitor | Direct pod metrics collection for better observability |
| NetworkPolicy | Webhook server ingress network policy for enhanced security |
| RBAC Patches | Additional RBAC for AppWrapper resources |
| Runbooks | Alert runbooks for OpenShift monitoring integration |
| UBI9 Base Image | Red Hat Universal Base Image for enterprise support |
