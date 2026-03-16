# Component: Kueue

## Metadata
- **Repository**: https://github.com/red-hat-data-services/kueue.git
- **Version**: ae90a64c9
- **Branch**: rhoai-2.11
- **Distribution**: RHOAI
- **Languages**: Go 1.22.2
- **Deployment Type**: Kubernetes Operator
- **Namespace**: opendatahub
- **Name Prefix**: kueue-

## Purpose
**Short**: Job queueing system that manages when Kubernetes jobs can be admitted to run based on resource quotas and priorities.

**Detailed**: Kueue is a Kubernetes-native job-level queue manager that provides sophisticated resource management and fair sharing for batch workloads. It implements queueing strategies (StrictFIFO, BestEffortFIFO) to control when jobs are admitted to start (pods can be created) and when they should stop (active pods should be deleted). Kueue supports priority-based scheduling, preemption, resource borrowing between tenants via cohorts, and dynamic resource reclaim as job pods complete. It integrates with various job frameworks including Kubernetes Batch Jobs, Kubeflow training jobs (TFJob, PyTorchJob, MPIJob), Ray (RayJob, RayCluster), and JobSet, making it a comprehensive solution for managing ML/AI training workloads and other batch processing tasks in multi-tenant environments.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| kueue-controller-manager | Deployment | Core controller managing workload admission, queueing, and resource allocation |
| AdmissionCheck Controller | Reconciler | Validates and manages admission checks for workloads |
| ClusterQueue Controller | Reconciler | Manages cluster-wide resource quotas and admission policies |
| LocalQueue Controller | Reconciler | Manages namespace-scoped queues linked to ClusterQueues |
| Workload Controller | Reconciler | Reconciles workload admission state and resource assignments |
| ResourceFlavor Controller | Reconciler | Manages resource flavor definitions (node selectors, tolerations) |
| Webhook Server | Admission Webhook | Validates and mutates workload resources on creation/update |
| Visibility Server | API Extension | Provides additional APIs for pending workloads visibility |
| Metrics Exporter | Prometheus Exporter | Exposes Prometheus metrics for monitoring queue state |

## APIs Exposed

### Custom Resource Definitions (CRDs)

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| kueue.x-k8s.io | v1beta1 | AdmissionCheck | Cluster | Defines conditions that must be met before admitting a workload |
| kueue.x-k8s.io | v1beta1 | ClusterQueue | Cluster | Defines cluster-wide resource quotas and admission policies |
| kueue.x-k8s.io | v1beta1 | LocalQueue | Namespaced | Namespace-scoped queue that references a ClusterQueue |
| kueue.x-k8s.io | v1beta1 | MultiKueueCluster | Cluster | Configuration for multi-cluster job distribution |
| kueue.x-k8s.io | v1beta1 | MultiKueueConfig | Cluster | Global configuration for multi-cluster features |
| kueue.x-k8s.io | v1beta1 | ProvisioningRequestConfig | Cluster | Configuration for cluster autoscaler integration |
| kueue.x-k8s.io | v1beta1 | ResourceFlavor | Cluster | Defines resource variants (node types, labels, taints) |
| kueue.x-k8s.io | v1beta1 | WorkloadPriorityClass | Cluster | Defines priority levels for workload scheduling |
| kueue.x-k8s.io | v1beta1 | Workload | Namespaced | Represents a unit of work (job) in the queue system |

### HTTP Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /healthz | GET | 8081/TCP | HTTP | None | None | Liveness probe endpoint |
| /readyz | GET | 8081/TCP | HTTP | None | None | Readiness probe endpoint |
| /metrics | GET | 8080/TCP | HTTP | None | None | Prometheus metrics (internal service) |
| /metrics | GET | 8443/TCP | HTTPS | TLS 1.2+ | kube-rbac-proxy | Prometheus metrics (auth proxy service) |
| /mutate-batch-v1-job | POST | 9443/TCP | HTTPS | TLS 1.2+ | mTLS | Mutating webhook for Batch Jobs |
| /mutate-jobset-x-k8s-io-v1alpha2-jobset | POST | 9443/TCP | HTTPS | TLS 1.2+ | mTLS | Mutating webhook for JobSets |
| /validate-kueue-x-k8s-io-v1beta1-workload | POST | 9443/TCP | HTTPS | TLS 1.2+ | mTLS | Validating webhook for Workloads |
| /validate-kueue-x-k8s-io-v1beta1-clusterqueue | POST | 9443/TCP | HTTPS | TLS 1.2+ | mTLS | Validating webhook for ClusterQueues |
| /validate-kueue-x-k8s-io-v1beta1-localqueue | POST | 9443/TCP | HTTPS | TLS 1.2+ | mTLS | Validating webhook for LocalQueues |
| /validate-kueue-x-k8s-io-v1beta1-resourceflavor | POST | 9443/TCP | HTTPS | TLS 1.2+ | mTLS | Validating webhook for ResourceFlavors |

### gRPC Services

None - Kueue uses HTTP/HTTPS APIs only.

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| Kubernetes | 1.22+ | Yes | Target platform for operator deployment |
| controller-runtime | v0.17.3 | Yes | Kubernetes controller framework |
| cert-controller | v0.10.1 | Yes | Certificate management for webhooks |
| Prometheus Operator | N/A | No | Optional for PodMonitor-based metrics collection |

### Internal ODH/RHOAI Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| Kubeflow Training Operator | Watches CRDs | Queue management for TFJob, PyTorchJob, MPIJob, MXJob, PaddleJob, XGBoostJob |
| KServe | Watches Pods | Queue management for inference serving workloads (when configured) |
| Ray Operator | Watches CRDs | Queue management for RayJob and RayCluster resources |
| Prometheus | Metrics scraping | Monitoring queue depths, admission rates, resource utilization |

## Network Architecture

### Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| kueue-webhook-service | ClusterIP | 443/TCP | 9443 | HTTPS | TLS 1.2+ | mTLS | Internal (API Server to webhook) |
| kueue-controller-manager-metrics-service | ClusterIP | 8443/TCP | https | HTTPS | TLS 1.2+ | kube-rbac-proxy | Internal (Prometheus) |
| kueue-metrics-service | ClusterIP | 8080/TCP | metrics | HTTP | None | None | Internal (Prometheus) |
| kueue-visibility-server | ClusterIP | 443/TCP | 8082 | HTTPS | TLS 1.2+ | API authentication | Internal (API aggregation) |

### Ingress

None - Kueue services are internal only and accessed via Kubernetes API server aggregation.

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| Kubernetes API Server | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount token | Watch and reconcile CRDs, Jobs, Pods |
| Cluster Autoscaler API | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount token | Create/manage ProvisioningRequests |

## Security

### RBAC - Cluster Roles

| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|
| kueue-manager-role | "" | events, limitranges, namespaces, pods, secrets | create, get, list, watch, update, patch, delete |
| kueue-manager-role | batch | jobs | get, list, watch, update, patch |
| kueue-manager-role | batch | jobs/finalizers, jobs/status | get, update, patch |
| kueue-manager-role | kueue.x-k8s.io | admissionchecks, clusterqueues, localqueues, workloads, resourceflavors | create, delete, get, list, patch, update, watch |
| kueue-manager-role | kueue.x-k8s.io | */finalizers, */status | get, update, patch |
| kueue-manager-role | kubeflow.org | mpijobs, tfjobs, pytorchjobs, mxjobs, paddlejobs, xgboostjobs | get, list, watch, update, patch |
| kueue-manager-role | kubeflow.org | */finalizers, */status | get, update |
| kueue-manager-role | ray.io | rayjobs, rayclusters | get, list, watch, update, patch |
| kueue-manager-role | ray.io | */finalizers, */status | get, update |
| kueue-manager-role | jobset.x-k8s.io | jobsets | get, list, watch, update, patch |
| kueue-manager-role | jobset.x-k8s.io | jobsets/finalizers, jobsets/status | get, update |
| kueue-manager-role | autoscaling.x-k8s.io | provisioningrequests | create, delete, get, list, patch, update, watch |
| kueue-manager-role | admissionregistration.k8s.io | mutatingwebhookconfigurations, validatingwebhookconfigurations | get, list, update, watch |
| kueue-batch-admin-role | "" | events | create, watch, update, patch |
| kueue-batch-admin-role | batch | jobs | get, list, watch, create, update, patch, delete |
| kueue-batch-user-role | "" | events | create, watch, update |
| kueue-batch-user-role | batch | jobs | get, list, watch, create, update, patch |
| kueue-clusterqueue-editor-role | kueue.x-k8s.io | clusterqueues | create, delete, get, list, patch, update, watch |
| kueue-clusterqueue-viewer-role | kueue.x-k8s.io | clusterqueues | get, list, watch |
| kueue-localqueue-editor-role | kueue.x-k8s.io | localqueues | create, delete, get, list, patch, update, watch |
| kueue-localqueue-viewer-role | kueue.x-k8s.io | localqueues | get, list, watch |
| kueue-workload-editor-role | kueue.x-k8s.io | workloads | create, delete, get, list, patch, update, watch |
| kueue-workload-viewer-role | kueue.x-k8s.io | workloads | get, list, watch |

### RBAC - Role Bindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| kueue-leader-election-role-binding | opendatahub | kueue-leader-election-role | kueue-controller-manager |
| kueue-role-binding | opendatahub | kueue-manager-role | kueue-controller-manager |
| kueue-auth-proxy-role-binding | opendatahub | kueue-auth-proxy-role | kueue-controller-manager |
| kueue-batch-user-rolebinding | opendatahub | kueue-batch-user-role | default |

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| kueue-webhook-server-cert | kubernetes.io/tls | TLS certificate for webhook server | cert-controller | Yes |

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| Webhook endpoints (/mutate-*, /validate-*) | POST | mTLS client certs | Kubernetes API Server | API Server validates client certificates |
| /metrics (8443) | GET | Bearer Token (ServiceAccount) | kube-rbac-proxy | Enforces Kubernetes RBAC |
| Kubernetes API | GET, LIST, WATCH, CREATE, UPDATE, PATCH, DELETE | ServiceAccount token | Kubernetes API Server | RBAC ClusterRole permissions |

### Network Policies

| Name | Selector | Ingress Rules | Egress Rules |
|------|----------|---------------|--------------|
| kueue-webhook-server | app.kubernetes.io/name=kueue, app.kubernetes.io/component=controller | Allow TCP/9443 from any | None (default allow) |

## Data Flows

### Flow 1: Job Submission and Admission

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User/Pipeline | Kubernetes API Server | 443/TCP | HTTPS | TLS 1.2+ | Bearer Token (user credentials) |
| 2 | Kubernetes API Server | kueue-webhook-service | 443/TCP (to 9443) | HTTPS | TLS 1.2+ | mTLS |
| 3 | kueue-webhook-service | Kubernetes API Server (response) | ephemeral | HTTPS | TLS 1.2+ | mTLS |
| 4 | kueue-controller-manager | Kubernetes API Server (watch) | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount token |
| 5 | kueue-controller-manager | Kubernetes API Server (update workload status) | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount token |

### Flow 2: Metrics Collection

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Prometheus | kueue-metrics-service | 8080/TCP | HTTP | None | None |
| 2 | Prometheus (alternative) | kueue-controller-manager-metrics-service | 8443/TCP | HTTPS | TLS 1.2+ | Bearer Token (ServiceAccount) |

### Flow 3: Workload Reconciliation

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | kueue-controller-manager (watch) | Kubernetes API Server | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount token |
| 2 | kueue-controller-manager (evaluate admission) | Internal logic | N/A | N/A | N/A | N/A |
| 3 | kueue-controller-manager (admit workload) | Kubernetes API Server | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount token |
| 4 | kueue-controller-manager (unsuspend job) | Kubernetes API Server | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount token |

### Flow 4: Cluster Autoscaler Integration

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | kueue-controller-manager | Kubernetes API Server (create ProvisioningRequest) | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount token |
| 2 | Cluster Autoscaler | Kubernetes API Server (watch ProvisioningRequests) | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount token |
| 3 | Cluster Autoscaler | Cloud Provider API | 443/TCP | HTTPS | TLS 1.2+ | Cloud credentials |

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| Kubernetes API Server | REST API (client) | 443/TCP | HTTPS | TLS 1.2+ | Watch/reconcile all managed resources |
| Batch Jobs | CRD watch + webhook | 9443/TCP (webhook) | HTTPS | TLS 1.2+ | Queue and admission management |
| JobSet | CRD watch + webhook | 9443/TCP (webhook) | HTTPS | TLS 1.2+ | Queue management for JobSets |
| Kubeflow Training Operator | CRD watch | N/A (API Server) | HTTPS | TLS 1.2+ | Queue TFJob, PyTorchJob, MPIJob, etc. |
| Ray Operator | CRD watch | N/A (API Server) | HTTPS | TLS 1.2+ | Queue RayJob and RayCluster |
| Cluster Autoscaler | ProvisioningRequest API | N/A (API Server) | HTTPS | TLS 1.2+ | Trigger node provisioning for queued workloads |
| Prometheus | Metrics scrape | 8080/TCP or 8443/TCP | HTTP/HTTPS | None/TLS 1.2+ | Monitor queue metrics and workload states |

## Recent Changes

Note: Full commit history not available in this checkout. Version ae90a64c9 on branch rhoai-2.11.

Recent development focus (based on upstream Kueue project):
- Enhanced multi-cluster job distribution (MultiKueue features)
- Cluster autoscaler integration via ProvisioningRequest API
- Partial admission support for flexible job sizing
- Sequential admission for all-or-nothing scheduling
- Improved preemption and borrowing policies
- Expanded job framework integrations (Ray, JobSet)

## Deployment Configuration

### Container Images

- **Base Image**: registry.access.redhat.com/ubi9/ubi:latest
- **Build Image**: registry.access.redhat.com/ubi9/go-toolset:1.21
- **Container Name**: manager
- **Entrypoint**: /manager
- **User**: 65532:65532 (non-root)

### Resource Requirements

| Component | CPU Request | CPU Limit | Memory Request | Memory Limit |
|-----------|-------------|-----------|----------------|--------------|
| kueue-controller-manager | 500m | 500m | 512Mi | 512Mi |

### Health Checks

| Type | Path | Port | Initial Delay | Period |
|------|------|------|---------------|--------|
| Liveness | /healthz | 8081/TCP | 15s | 20s |
| Readiness | /readyz | 8081/TCP | 5s | 10s |

### Monitoring

- **PodMonitor**: kueue-controller-manager-metrics-monitor
- **Metrics Port**: metrics (8080)
- **Metrics Endpoint**: /metrics
- **Labels**: app.kubernetes.io/name=kueue, app.kubernetes.io/component=controller

## Operational Notes

### High Availability

- **Replica Count**: 1 (single controller with leader election)
- **Leader Election**: Enabled via lease-based mechanism
- **Leader Election Role**: kueue-leader-election-role

### Security Posture

- **Non-root Execution**: Runs as UID/GID 65532
- **Privilege Escalation**: Disabled (allowPrivilegeEscalation: false)
- **Security Context**: runAsNonRoot: true
- **Webhook TLS**: Certificate rotation handled by cert-controller
- **Network Isolation**: NetworkPolicy restricts webhook ingress to port 9443

### Scalability Considerations

- Supports up to 8 PodSets per Workload
- Queue depth monitored via Prometheus metrics
- Performance tested for scalability (see upstream performance tests)
- Single controller design with efficient informer caching

### Key Configuration Options

Configuration managed via ComponentConfig type (manager_config_patch.yaml):
- Webhook certificates mounted at /tmp/k8s-webhook-server/serving-certs
- Log level: --zap-log-level=2
- Metrics binding: 0.0.0.0:8080
- Webhook binding: 0.0.0.0:9443
- Health probe binding: 0.0.0.0:8081
