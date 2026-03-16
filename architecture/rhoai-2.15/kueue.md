# Component: Kueue

## Metadata
- **Repository**: https://github.com/red-hat-data-services/kueue.git
- **Version**: rhoai-2.15 (commit b8a472288)
- **Distribution**: RHOAI
- **Languages**: Go
- **Deployment Type**: Kubernetes Operator/Controller

## Purpose
**Short**: Kueue is a job queueing system that manages when jobs should be admitted to start and when they should stop based on resource availability and policies.

**Detailed**: Kueue provides a comprehensive job-level management system for Kubernetes that implements intelligent queueing, resource fair sharing, and admission control for workloads. It acts as a gatekeeper that decides when a job can start (create pods) based on available quota, priorities, and admission checks. The system supports multiple queueing strategies (StrictFIFO, BestEffortFIFO), preemption policies, and dynamic resource reclamation. Kueue integrates with various job types including Kubernetes Batch Jobs, Kubeflow training jobs (PyTorchJob, TFJob, MPIJob), Ray workloads, and JobSets, providing a unified queueing layer across different workload types. It enables multi-tenant resource sharing through ClusterQueues and LocalQueues, supports admission checks for additional validation, and integrates with cluster autoscalers for dynamic capacity provisioning.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| Controller Manager | Deployment | Main reconciliation engine managing all Kueue CRDs and workload lifecycle |
| Webhook Server | HTTP Server | Validates and mutates job resources on admission |
| Visibility Server | HTTP/gRPC Server | Provides on-demand API for querying pending workloads status |
| Scheduler | In-Process Service | Decides which workloads to admit based on available quota and policies |
| Cache | In-Memory Store | Maintains snapshot of cluster queue state and resource usage |
| Queue Manager | In-Process Service | Manages workload queues and ordering |
| Admission Check Controllers | Controllers | Execute pre-admission validation (provisioning, multikueue) |

## APIs Exposed

### Custom Resource Definitions (CRDs)

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| kueue.x-k8s.io | v1beta1 | Workload | Namespaced | Represents a unit of work that requires resources to run |
| kueue.x-k8s.io | v1beta1 | ClusterQueue | Cluster | Defines resource quotas and sharing policies at cluster level |
| kueue.x-k8s.io | v1beta1 | LocalQueue | Namespaced | Namespace-scoped queue that references a ClusterQueue |
| kueue.x-k8s.io | v1beta1 | ResourceFlavor | Cluster | Defines resource variants (e.g., different node types, regions) |
| kueue.x-k8s.io | v1beta1 | AdmissionCheck | Cluster | Defines additional validation required before admitting workloads |
| kueue.x-k8s.io | v1beta1 | WorkloadPriorityClass | Cluster | Defines priority levels for workload scheduling |
| kueue.x-k8s.io | v1beta1 | ProvisioningRequestConfig | Cluster | Configuration for cluster autoscaler integration |
| kueue.x-k8s.io | v1alpha1 | MultiKueueCluster | Namespaced | Represents a remote cluster in multi-cluster setup |
| kueue.x-k8s.io | v1alpha1 | MultiKueueConfig | Namespaced | Configuration for multi-cluster workload distribution |

### HTTP Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /mutate-batch-v1-job | POST | 9443/TCP | HTTPS | TLS | Kubernetes API Server mTLS | Mutating webhook for Batch Jobs |
| /mutate-kubeflow-org-v1-pytorchjob | POST | 9443/TCP | HTTPS | TLS | Kubernetes API Server mTLS | Mutating webhook for PyTorchJobs |
| /mutate-kubeflow-org-v1-tfjob | POST | 9443/TCP | HTTPS | TLS | Kubernetes API Server mTLS | Mutating webhook for TFJobs |
| /mutate-kubeflow-org-v1-mpijob | POST | 9443/TCP | HTTPS | TLS | Kubernetes API Server mTLS | Mutating webhook for MPIJobs |
| /mutate-ray-io-v1-rayjob | POST | 9443/TCP | HTTPS | TLS | Kubernetes API Server mTLS | Mutating webhook for RayJobs |
| /mutate-ray-io-v1-raycluster | POST | 9443/TCP | HTTPS | TLS | Kubernetes API Server mTLS | Mutating webhook for RayClusters |
| /mutate-jobset-x-k8s-io-v1alpha2-jobset | POST | 9443/TCP | HTTPS | TLS | Kubernetes API Server mTLS | Mutating webhook for JobSets |
| /validate-kueue-x-k8s-io-v1beta1-clusterqueue | POST | 9443/TCP | HTTPS | TLS | Kubernetes API Server mTLS | Validating webhook for ClusterQueues |
| /validate-kueue-x-k8s-io-v1beta1-localqueue | POST | 9443/TCP | HTTPS | TLS | Kubernetes API Server mTLS | Validating webhook for LocalQueues |
| /validate-kueue-x-k8s-io-v1beta1-workload | POST | 9443/TCP | HTTPS | TLS | Kubernetes API Server mTLS | Validating webhook for Workloads |
| /validate-kueue-x-k8s-io-v1beta1-resourceflavor | POST | 9443/TCP | HTTPS | TLS | Kubernetes API Server mTLS | Validating webhook for ResourceFlavors |
| /healthz | GET | 8081/TCP | HTTP | None | None | Health check endpoint |
| /readyz | GET | 8081/TCP | HTTP | None | None | Readiness check endpoint |
| /metrics | GET | 8080/TCP | HTTP | None | None | Prometheus metrics endpoint |
| /apis/visibility.kueue.x-k8s.io/v1alpha1/* | GET | 8082/TCP | HTTPS | TLS | Kubernetes RBAC | Visibility API for pending workloads |

### gRPC Services

| Service | Port | Protocol | Encryption | Auth | Purpose |
|---------|------|----------|------------|------|---------|
| N/A | N/A | N/A | N/A | N/A | No gRPC services exposed |

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| Kubernetes | 1.25+ | Yes | Core platform for running operator and workloads |
| cert-manager | Any | No | TLS certificate management (alternative: internal cert management) |
| Prometheus | Any | No | Metrics collection and monitoring |
| Cluster Autoscaler | With ProvisioningRequest API | No | Dynamic node provisioning integration |

### Internal ODH Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| KubeFlow Training Operator | CRD Watching | Queue management for ML training jobs (PyTorchJob, TFJob, MPIJob, etc.) |
| Ray Operator | CRD Watching | Queue management for Ray workloads (RayJob, RayCluster) |
| JobSet Operator | CRD Watching | Queue management for JobSet workloads |

## Network Architecture

### Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| kueue-webhook-service | ClusterIP | 443/TCP | 9443 | HTTPS | TLS | Kubernetes API Server mTLS | Internal (API Server) |
| kueue-visibility-server | ClusterIP | 443/TCP | 8082 | HTTPS | TLS | Kubernetes RBAC | Internal (Cluster) |
| kueue-metrics-service | ClusterIP | 8080/TCP | 8080 | HTTP | None | None | Internal (Prometheus) |
| kueue-controller-manager-metrics-service | ClusterIP | 8443/TCP | 8443 | HTTPS | TLS | Kubernetes RBAC | Internal (Prometheus) |

### Ingress

| Name | Type | Hosts | Port | Protocol | Encryption | TLS Mode | Exposure |
|------|------|-------|------|----------|------------|----------|----------|
| N/A | N/A | N/A | N/A | N/A | N/A | N/A | No external ingress configured |

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| Kubernetes API Server | 6443/TCP | HTTPS | TLS | ServiceAccount Token | Watch and manage CRDs, Jobs, and Pods |
| Remote Kubernetes Clusters (MultiKueue) | 6443/TCP | HTTPS | TLS | Kubeconfig credentials | Distribute workloads across clusters |
| Cluster Autoscaler API | Varies | HTTPS | TLS | ServiceAccount Token | Create ProvisioningRequests for capacity |

## Security

### RBAC - Cluster Roles

| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|
| kueue-manager-role | "" | events, limitranges, namespaces | get, list, watch, create, patch, update |
| kueue-manager-role | "" | pods | delete, get, list, patch, update, watch |
| kueue-manager-role | "" | pods/finalizers | get, update |
| kueue-manager-role | "" | pods/status | get, patch |
| kueue-manager-role | "" | secrets | get, list, update, watch |
| kueue-manager-role | batch | jobs | get, list, patch, update, watch |
| kueue-manager-role | batch | jobs/finalizers, jobs/status | get, patch, update |
| kueue-manager-role | kueue.x-k8s.io | workloads, clusterqueues, localqueues, admissionchecks, resourceflavors | create, delete, get, list, patch, update, watch |
| kueue-manager-role | kueue.x-k8s.io | workloads/status, clusterqueues/status, localqueues/status | get, patch, update |
| kueue-manager-role | kueue.x-k8s.io | workloadpriorityclasses, multikueueclusters, multikueueconfigs, provisioningrequestconfigs | get, list, watch |
| kueue-manager-role | kubeflow.org | pytorchjobs, tfjobs, mpijobs, mxjobs, xgboostjobs, paddlejobs | get, list, patch, update, watch |
| kueue-manager-role | kubeflow.org | pytorchjobs/finalizers, tfjobs/finalizers, mpijobs/finalizers | get, update |
| kueue-manager-role | kubeflow.org | pytorchjobs/status, tfjobs/status, mpijobs/status | get, update |
| kueue-manager-role | ray.io | rayjobs, rayclusters | get, list, patch, update, watch |
| kueue-manager-role | ray.io | rayjobs/finalizers, rayclusters/finalizers | get, update |
| kueue-manager-role | ray.io | rayjobs/status, rayclusters/status | get, update |
| kueue-manager-role | jobset.x-k8s.io | jobsets | get, list, patch, update, watch |
| kueue-manager-role | jobset.x-k8s.io | jobsets/finalizers, jobsets/status | get, patch, update |
| kueue-manager-role | autoscaling.x-k8s.io | provisioningrequests | create, delete, get, list, patch, update, watch |
| kueue-manager-role | admissionregistration.k8s.io | mutatingwebhookconfigurations, validatingwebhookconfigurations | get, list, update, watch |
| kueue-batch-admin-role | kueue.x-k8s.io | clusterqueues, localqueues, workloadpriorityclasses, resourceflavors | get, list, watch, create, update, patch, delete |
| kueue-batch-user-role | kueue.x-k8s.io | localqueues, workloads | get, list, watch, create, update, patch, delete |

### RBAC - Role Bindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| kueue-manager-rolebinding | kueue-system | kueue-manager-role | kueue-controller-manager |
| kueue-leader-election-rolebinding | kueue-system | kueue-leader-election-role | kueue-controller-manager |

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| kueue-webhook-server-cert | kubernetes.io/tls | Webhook server TLS certificate | cert-manager or internal cert manager | Yes |
| kueue-client-cert | kubernetes.io/tls | Client certificates for mTLS | cert-manager or internal cert manager | Yes |

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| /mutate-* | POST | Kubernetes API Server mTLS | Admission Webhook | API Server validates webhook call |
| /validate-* | POST | Kubernetes API Server mTLS | Admission Webhook | API Server validates webhook call |
| /apis/visibility.kueue.x-k8s.io/v1alpha1/* | GET | Bearer Token (ServiceAccount) | API Server RBAC | Kubernetes RBAC on visibility API |
| /metrics | GET | None | None | Exposed only to internal cluster (Prometheus) |
| /healthz, /readyz | GET | None | None | Public within cluster for liveness/readiness |

### Network Policies

| Policy Name | Namespace | Selectors | Ingress Rules | Egress Rules |
|-------------|-----------|-----------|---------------|--------------|
| kueue-webhook-server | opendatahub | app.kubernetes.io/name=kueue | Allow TCP/9443 from any | Not specified |

## Data Flows

### Flow 1: Job Submission and Admission

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User/Controller | Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token or Kubeconfig |
| 2 | Kubernetes API Server | Kueue Webhook Service | 9443/TCP | HTTPS | TLS | Kubernetes API Server mTLS |
| 3 | Kueue Controller | Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 4 | Kueue Controller | Kueue Cache (in-process) | N/A | In-Process | None | N/A |
| 5 | Kueue Scheduler | Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |

### Flow 2: Workload Status Query (Visibility API)

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User/CLI | Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | Bearer Token |
| 2 | Kubernetes API Server | Kueue Visibility Server | 8082/TCP | HTTPS | TLS | Kubernetes RBAC delegation |
| 3 | Kueue Visibility Server | Kueue Queue Manager (in-process) | N/A | In-Process | None | N/A |

### Flow 3: Metrics Collection

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Prometheus | Kueue Metrics Service | 8080/TCP | HTTP | None | None |
| 2 | Kueue Controller | Metrics Registry (in-process) | N/A | In-Process | None | N/A |

### Flow 4: Provisioning Request (Autoscaling)

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Kueue Admission Check Controller | Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 2 | Kubernetes API Server | Cluster Autoscaler | Varies | Varies | TLS 1.2+ | ServiceAccount Token |
| 3 | Cluster Autoscaler | Cloud Provider API | 443/TCP | HTTPS | TLS 1.2+ | Cloud Credentials |

### Flow 5: Multi-Cluster Workload Distribution (MultiKueue)

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Kueue MultiKueue Controller | Remote Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | Kubeconfig credentials |
| 2 | Remote Cluster | Kueue MultiKueue Controller | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| Kubernetes Batch Jobs | CRD Watch/Webhook | 6443/TCP | HTTPS | TLS | Queue and manage batch job lifecycle |
| KubeFlow PyTorchJob | CRD Watch/Webhook | 6443/TCP | HTTPS | TLS | Queue and manage PyTorch training jobs |
| KubeFlow TFJob | CRD Watch/Webhook | 6443/TCP | HTTPS | TLS | Queue and manage TensorFlow training jobs |
| KubeFlow MPIJob | CRD Watch/Webhook | 6443/TCP | HTTPS | TLS | Queue and manage MPI training jobs |
| Ray RayJob | CRD Watch/Webhook | 6443/TCP | HTTPS | TLS | Queue and manage Ray jobs |
| Ray RayCluster | CRD Watch/Webhook | 6443/TCP | HTTPS | TLS | Queue and manage Ray clusters |
| JobSet | CRD Watch/Webhook | 6443/TCP | HTTPS | TLS | Queue and manage JobSet workloads |
| Cluster Autoscaler | ProvisioningRequest API | 6443/TCP | HTTPS | TLS | Request node provisioning for queued workloads |
| Prometheus | Metrics Scraping | 8080/TCP | HTTP | None | Monitor queue depth, admission rates, resource usage |
| cert-manager | Certificate API | 6443/TCP | HTTPS | TLS | Obtain and rotate TLS certificates for webhooks |

## Recent Changes

| Commit | Date | Changes |
|--------|------|---------|
| b8a472288 | 2026-03 | - Add renovate.json config |
| 0d7a9cd1f | 2026-03 | - Review Dockerfile and RPM files for building odh-kuberay-operator-controller in konflux |
| e5d643376 | 2026-03 | - Review Dockerfile and RPM files for building odh-kueue-controller in konflux |
| 3a722af87 | 2026-03 | - Review Dockerfile and RPM files for building odh-kueue-controller in konflux |
| d1f4cfc16 | 2026-03 | - DROP: Expose available ResourceFlavors from the ClusterQueue in the LocalQueue status |
| ae5f7b2b4 | 2026-03 | - CARRY: Use environment variable to skip jobset availability check |
| a4061939d | 2026-03 | - Updating prompt for release tag |
| 630106f49 | 2026-03 | - CARRY: Removing kueue runbooks |
| edaa8c714 | 2026-03 | - CARRY: Upgrade Kueue image to v0.8.1 |
| 2582cae19 | 2026-03 | - CARRY: Remove check for restarted pod from test suite |
| 25c614948 | 2026-03 | - CARRY: Use env variable 'NAMESPACE' for e2e tests |
| 5c577bac5 | 2026-03 | - CARRY: Add .snyk file to ignore cmd/kueuectl and test directories from snyk scans |
| d9267f21f | 2026-03 | - CARRY: Update workflow to trigger manually only |
| 1e7963b65 | 2026-03 | - CARRY: Updating runbook urls for use on OpenShift alerting UI |
| a704f065a | 2026-03 | - CARRY: Adding runbooks for alerts |
| dbfd80ab6 | 2026-03 | - CARRY: use golang version workaround for ubi9 image |
| 5ae8695ce | 2026-03 | - CARRY: Adding info level alerts |
| 14b0e143e | 2026-03 | - CARRY: kueue manager needs RBACs to get,list,watch AppWrappers |
| b77b99fb0 | 2026-03 | - CARRY: ODH build and publish image |

## Deployment Configuration

### RHOAI-Specific Settings

- **Namespace**: opendatahub (configured in config/rhoai/kustomization.yaml)
- **Name Prefix**: kueue-
- **Image**: Specified via ConfigMap (odh-kueue-controller-image)
- **Build**: Konflux-based build using Dockerfile.konflux
- **Runtime**: UBI8 minimal base image, runs as non-root user (UID 65532)

### Resource Requirements

| Component | CPU Request | CPU Limit | Memory Request | Memory Limit |
|-----------|-------------|-----------|----------------|--------------|
| Manager | 500m | 500m | 512Mi | 512Mi |

### High Availability

- **Replicas**: 1 (default, can be scaled)
- **Leader Election**: Enabled (using Kubernetes lease-based leader election)
- **Health Checks**: Liveness probe on /healthz:8081, Readiness probe on /readyz:8081

### Feature Gates

Kueue supports feature gates for alpha/experimental features:
- **VisibilityOnDemand**: Enable on-demand visibility API server
- **ProvisioningACC**: Enable provisioning admission check controller
- **MultiKueue**: Enable multi-cluster workload distribution
- **WaitForPodsReady**: Enable waiting for pods to be ready before admission
- **PartialAdmission**: Allow jobs to run with fewer resources if available

### Configuration Options

- **QueueingStrategy**: StrictFIFO or BestEffortFIFO
- **FairSharing**: Enable fair sharing of resources across tenants
- **Preemption**: Configure preemption policies
- **WaitForPodsReady**: Timeout-based all-or-nothing scheduling
- **ClientConnection.QPS**: Rate limiting for Kubernetes API calls
- **ClientConnection.Burst**: Burst allowance for Kubernetes API calls
- **Resources.ExcludeResourcePrefixes**: Exclude certain resource types from management

## Monitoring and Observability

### Prometheus Metrics

Kueue exposes comprehensive Prometheus metrics on port 8080:
- Queue depth and pending workload counts
- Admission rates and latencies
- Preemption events
- Resource usage by ClusterQueue
- Webhook latencies
- Controller reconciliation metrics

### Alerting

RHOAI configuration includes:
- PodMonitor for Prometheus scraping
- PrometheusRule with custom alerts (configured in config/rhoai/prometheus_rule.yaml)
- Alert runbooks for operational guidance

### Logging

- Structured logging using zap logger
- Configurable log levels via --zap-log-level flag
- Default log level: 2 (info)
- Logs include reconciliation events, admission decisions, and error conditions
