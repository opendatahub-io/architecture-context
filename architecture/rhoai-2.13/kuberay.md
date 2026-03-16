# Component: KubeRay Operator

## Metadata
- **Repository**: https://github.com/red-hat-data-services/kuberay.git
- **Version**: 06b2ad42 (rhoai-2.13 branch, based on upstream v1.1.0)
- **Distribution**: RHOAI
- **Languages**: Go 1.22.2
- **Deployment Type**: Kubernetes Operator

## Purpose
**Short**: KubeRay is a Kubernetes operator that manages the lifecycle of Ray clusters for distributed machine learning and AI workloads.

**Detailed**: KubeRay Operator provides production-ready deployment and management of Ray clusters on Kubernetes and OpenShift. Ray is an open-source unified compute framework for distributed machine learning, batch inference, and serving AI models. The operator manages three primary custom resources: RayCluster for long-running clusters with autoscaling and fault tolerance, RayJob for batch workloads that create ephemeral clusters, and RayService for serving applications with zero-downtime upgrades and high availability. The operator handles cluster lifecycle management, autoscaling, GCS (Global Control Store) fault tolerance, service mesh integration, and seamless integration with OpenShift Routes and Kubernetes Ingress for external access to Ray dashboards and serving endpoints.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| kuberay-operator | Go Operator | Reconciles RayCluster, RayJob, RayService CRDs and manages Ray cluster lifecycle |
| Ray Head Pod | Managed Pod | Primary Ray cluster node running GCS server, dashboard, and scheduler |
| Ray Worker Pods | Managed Pods | Worker nodes in the Ray cluster that execute distributed tasks |
| Ray Autoscaler | Sidecar Container | Automatically scales worker pods based on Ray workload requirements |
| Validating Webhook | Admission Controller | Validates RayCluster resource specifications before creation/update |

## APIs Exposed

### Custom Resource Definitions (CRDs)

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| ray.io | v1 | RayCluster | Namespaced | Defines a Ray cluster with head and worker groups, autoscaling, and fault tolerance |
| ray.io | v1 | RayJob | Namespaced | Submits batch jobs to Ray cluster, creates ephemeral cluster if needed |
| ray.io | v1 | RayService | Namespaced | Deploys Ray Serve applications with zero-downtime upgrades and high availability |

### HTTP Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /metrics | GET | 8080/TCP | HTTP | None | None | Prometheus metrics for operator monitoring |
| /healthz | GET | 8081/TCP | HTTP | None | None | Operator health check endpoint |
| /readyz | GET | 8081/TCP | HTTP | None | None | Operator readiness probe |
| /validate-ray-io-v1-raycluster | POST | 9443/TCP | HTTPS | TLS 1.2+ | mTLS | ValidatingWebhook for RayCluster validation |

### Ray Cluster Services (Created by Operator)

| Service | Port | Protocol | Encryption | Auth | Purpose |
|---------|------|----------|------------|------|---------|
| Head Service - GCS | 6379/TCP | TCP | None | Optional Redis password | Ray Global Control Store (cluster coordination) |
| Head Service - Dashboard | 8265/TCP | HTTP | Optional TLS | Optional | Ray Dashboard for cluster monitoring and debugging |
| Head Service - Client | 10001/TCP | TCP | Optional TLS | Optional mTLS | Ray client connections for job submission |
| Serve Service | 8000/TCP | HTTP | Optional TLS | Optional | Ray Serve inference endpoints |
| Metrics Service | 8080/TCP | HTTP | None | None | Ray cluster metrics for Prometheus |
| Dashboard Agent | 52365/TCP | HTTP | None | None | Ray dashboard agent on each node |

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| Kubernetes | 1.25+ | Yes | Container orchestration platform |
| cert-manager | v1.0+ | Optional | TLS certificate management for webhooks and Ray clusters |
| Prometheus | 2.x | Optional | Metrics collection from operator and Ray clusters |
| Volcano | 1.6+ | Optional | Gang scheduling for batch workloads |
| Redis | 6.x | Optional | External Redis for GCS fault tolerance |

### Internal ODH/RHOAI Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| ODH Dashboard | UI | Provides UI for creating and managing Ray clusters |
| Prometheus | Metrics Scraping | Monitors operator and Ray cluster health |
| Service Mesh (Istio) | Optional | mTLS and traffic management for Ray services |

## Network Architecture

### Operator Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| kuberay-operator | ClusterIP | 8080/TCP | 8080 | HTTP | None | None | Internal |
| webhook-service | ClusterIP | 443/TCP | 9443 | HTTPS | TLS 1.2+ | mTLS | Internal |

### Ray Cluster Services (Per RayCluster CR)

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| {cluster}-head-svc | ClusterIP/LoadBalancer | 6379/TCP | 6379 | TCP | None | Optional | Internal/External |
| {cluster}-head-svc | ClusterIP/LoadBalancer | 8265/TCP | 8265 | HTTP | Optional TLS | Optional | Internal/External |
| {cluster}-head-svc | ClusterIP/LoadBalancer | 10001/TCP | 10001 | TCP | Optional TLS | Optional mTLS | Internal/External |
| {cluster}-serve-svc | ClusterIP | 8000/TCP | 8000 | HTTP | Optional TLS | Optional | Internal |
| {cluster}-headless-worker-svc | Headless | N/A | N/A | N/A | N/A | N/A | Internal |

### Ingress

| Name | Type | Hosts | Port | Protocol | Encryption | TLS Mode | Exposure |
|------|------|-------|------|----------|------------|----------|----------|
| Ray Dashboard Ingress | Kubernetes Ingress | User-defined | 8265/TCP | HTTP/HTTPS | Optional TLS 1.2+ | SIMPLE | External |
| Ray Serve Ingress | Kubernetes Ingress | User-defined | 8000/TCP | HTTP/HTTPS | Optional TLS 1.2+ | SIMPLE | External |

### OpenShift Routes

| Name | Type | Hosts | Port | Protocol | Encryption | TLS Mode | Exposure |
|------|------|-------|------|----------|------------|----------|----------|
| Ray Dashboard Route | OpenShift Route | Auto-generated | 8265/TCP | HTTP/HTTPS | Optional TLS | Edge/Passthrough | External |
| Ray Serve Route | OpenShift Route | Auto-generated | 8000/TCP | HTTP/HTTPS | Optional TLS | Edge/Passthrough | External |

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token | Manage Ray cluster resources |
| Container Registry | 443/TCP | HTTPS | TLS 1.2+ | Pull Secrets | Pull Ray container images |
| External Redis | 6379/TCP | TCP | Optional TLS | Password | GCS fault tolerance storage |
| S3-compatible Storage | 443/TCP | HTTPS | TLS 1.2+ | AWS IAM/Keys | Ray object storage and checkpointing |

## Security

### RBAC - Cluster Roles

| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|
| kuberay-operator | "" | pods, pods/status | create, delete, deletecollection, get, list, patch, update, watch |
| kuberay-operator | "" | services, services/status | create, delete, get, list, patch, update, watch |
| kuberay-operator | "" | serviceaccounts | create, delete, get, list, watch |
| kuberay-operator | "" | events | create, delete, get, list, patch, update, watch |
| kuberay-operator | "" | endpoints | get, list |
| kuberay-operator | batch | jobs | create, delete, get, list, patch, update, watch |
| kuberay-operator | ray.io | rayclusters, rayclusters/status, rayclusters/finalizers | create, delete, get, list, patch, update, watch |
| kuberay-operator | ray.io | rayjobs, rayjobs/status, rayjobs/finalizers | create, delete, get, list, patch, update, watch |
| kuberay-operator | ray.io | rayservices, rayservices/status, rayservices/finalizers | create, delete, get, list, patch, update, watch |
| kuberay-operator | networking.k8s.io | ingresses, ingressclasses | create, delete, get, list, patch, update, watch |
| kuberay-operator | extensions | ingresses | create, delete, get, list, patch, update, watch |
| kuberay-operator | route.openshift.io | routes | create, delete, get, list, patch, update, watch |
| kuberay-operator | rbac.authorization.k8s.io | roles, rolebindings | create, delete, get, list, update, watch |
| kuberay-operator | coordination.k8s.io | leases | create, get, list, update |

### RBAC - Role Bindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| kuberay-operator | opendatahub | kuberay-operator | kuberay-operator |
| leader-election-rolebinding | opendatahub | leader-election-role | kuberay-operator |

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| webhook-server-cert | kubernetes.io/tls | TLS certificate for validating webhook | cert-manager | Yes |
| ray-{cluster}-redis-password | Opaque | Redis password for GCS connections | User/Operator | No |

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| /validate-ray-io-v1-raycluster | POST | mTLS client certificates | Kubernetes API Server | ValidatingWebhookConfiguration |
| /metrics | GET | None (cluster-internal) | Network Policy | Allow from Prometheus |
| Ray Dashboard | GET, POST | Optional Bearer Token | Ray Dashboard | Configured via rayStartParams |
| Ray Client | ALL | Optional mTLS | Ray GCS | Configured via TLS settings |

### OpenShift Security

| Resource | Type | Purpose |
|----------|------|---------|
| run-as-ray-user | SecurityContextConstraints | Allows Ray pods to run as UID 1000 with dropped capabilities |

### Pod Security

| Setting | Value | Applied To |
|---------|-------|------------|
| runAsNonRoot | true | Operator and Ray pods |
| allowPrivilegeEscalation | false | All containers |
| capabilities.drop | ALL | All containers |
| seccompProfile | RuntimeDefault | All containers |

## Data Flows

### Flow 1: RayCluster Creation and Management

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User/Dashboard | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | Bearer Token |
| 2 | Kubernetes API | Validating Webhook | 9443/TCP | HTTPS | TLS 1.2+ | mTLS |
| 3 | Operator | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 4 | Operator | Creates Head Pod | N/A | N/A | N/A | N/A |
| 5 | Operator | Creates Head Services | N/A | N/A | N/A | N/A |
| 6 | Operator | Creates Worker Pods | N/A | N/A | N/A | N/A |
| 7 | Worker Pods | Ray Head GCS | 6379/TCP | TCP | Optional TLS | Optional Password |

### Flow 2: Ray Job Submission

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | Bearer Token |
| 2 | Operator | Creates Job Submitter Pod | N/A | N/A | N/A | N/A |
| 3 | Job Submitter | Ray Head Client | 10001/TCP | TCP | Optional TLS | Optional mTLS |
| 4 | Ray Head | Distributes to Workers | 6379/TCP | TCP | Optional TLS | Optional |
| 5 | Job Submitter | Ray Dashboard (status) | 8265/TCP | HTTP | Optional TLS | Optional |

### Flow 3: Ray Serve Inference

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | External Client | Ingress/Route | 443/TCP | HTTPS | TLS 1.2+ | Optional Bearer |
| 2 | Ingress/Route | Ray Serve Service | 8000/TCP | HTTP | Optional TLS | Optional |
| 3 | Ray Serve | Ray Head (coordination) | 6379/TCP | TCP | Optional TLS | Optional |
| 4 | Ray Serve | Returns Response | 8000/TCP | HTTP | Optional TLS | Optional |

### Flow 4: Autoscaling

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Autoscaler Sidecar | Ray Head Dashboard | 8265/TCP | HTTP | None | None |
| 2 | Autoscaler Sidecar | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 3 | Kubernetes API | Operator | Watch | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 4 | Operator | Creates/Deletes Worker Pods | N/A | N/A | N/A | N/A |

### Flow 5: Metrics Collection

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Prometheus | Operator Metrics | 8080/TCP | HTTP | None | None |
| 2 | Prometheus | Ray Head Metrics | 8080/TCP | HTTP | None | None |
| 3 | Prometheus | Ray Worker Metrics | 8080/TCP | HTTP | None | None |

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| Kubernetes API | REST API | 6443/TCP | HTTPS | TLS 1.2+ | CRD reconciliation and resource management |
| Prometheus | Metrics Scraping | 8080/TCP | HTTP | None | Operator and Ray cluster monitoring |
| cert-manager | Certificate API | N/A | N/A | N/A | TLS certificate provisioning for webhooks |
| Service Mesh (Istio) | mTLS Proxy | Various | HTTPS/gRPC | mTLS | Secure service-to-service communication |
| Volcano Scheduler | Batch Scheduling | N/A | N/A | N/A | Gang scheduling for Ray workloads |
| External Redis | TCP | 6379/TCP | TCP | Optional TLS | GCS fault tolerance and state persistence |
| S3/Object Storage | HTTP API | 443/TCP | HTTPS | TLS 1.2+ | Ray object spilling and checkpointing |

## Recent Changes

| Commit | Date | Changes |
|---------|------|---------|
| 06b2ad42 | 2025-03-12 | - Update Konflux references |
| 6f9d044c | 2025-03-12 | - Update Konflux references |
| 0e25dd19 | 2025-03-12 | - Update Konflux references |
| 95bf3d1c | 2025-03-11 | - Update Konflux references to d00d159 |
| 00e330b4 | 2025-03-11 | - Update Konflux references |
| d1709b6e | 2025-03-04 | - Update registry.access.redhat.com/ubi8/go-toolset:1.22 Docker digest |
| 5c981e77 | 2025-03-03 | - Update Konflux references |
| 92ca9646 | 2025-03-02 | - Update Konflux references to b9cb1e1 |

## Deployment Architecture

### Operator Deployment

- **Namespace**: `opendatahub` (RHOAI default)
- **Replicas**: 1 (with leader election for HA)
- **Strategy**: Recreate
- **Resources**: 100m CPU / 512Mi memory (limits and requests)
- **Image**: Built via Konflux using `Dockerfile.konflux` with strict FIPS mode (`-tags strictfipsruntime`)
- **Base Images**:
  - Builder: `registry.access.redhat.com/ubi8/go-toolset:1.22`
  - Runtime: `registry.access.redhat.com/ubi8/ubi-minimal`

### Configuration Options

| Flag | Default | Purpose |
|------|---------|---------|
| --metrics-addr | :8080 | Prometheus metrics endpoint binding address |
| --health-probe-bind-address | :8081 | Health and readiness probe endpoint |
| --enable-leader-election | false | Enable leader election for HA deployments |
| --reconcile-concurrency | 1 | Maximum concurrent reconcile operations |
| --watch-namespace | "" | Namespaces to watch (empty = all namespaces) |
| --forced-cluster-upgrade | false | Force cluster upgrades without checks |
| --enable-batch-scheduler | false | Enable Volcano gang scheduling support |

### Webhook Configuration

| Setting | Value |
|---------|-------|
| Webhook Type | ValidatingWebhookConfiguration |
| Service Port | 443/TCP -> 9443/TCP |
| Failure Policy | Fail |
| Operations | CREATE, UPDATE |
| Resources | rayclusters.ray.io/v1 |

## Version Information

**Based on**: KubeRay v1.0.0 (upstream) with RHOAI-specific patches
- Upstream moved from v1alpha1 to v1 CRDs (GA release)
- Added OpenShift Route support
- Added SecurityContextConstraints for OpenShift
- Integrated with Konflux build system
- Enhanced GCS fault tolerance
- Improved RayJob and RayService UX
- Support for Ray 2.x versions

## Known Limitations

1. **Single Operator**: Only one active operator instance per namespace (leader election required for HA)
2. **GCS FT Requirements**: External Redis required for GCS fault tolerance
3. **Autoscaler Dependency**: Autoscaler runs as sidecar, requires Ray cluster head to be ready
4. **Port Conflicts**: Default ports (6379, 8265, 10001, 8000) must be available in cluster
5. **OpenShift Routes**: Only supported on OpenShift, use Ingress for vanilla Kubernetes
6. **Batch Scheduler**: Volcano integration is optional and experimental

## Troubleshooting

### Common Issues

| Issue | Symptom | Resolution |
|-------|---------|------------|
| Worker pods not connecting | Workers in CrashLoopBackOff | Check GCS port (6379) accessibility, verify network policies |
| Autoscaler not scaling | Workers not added/removed | Check autoscaler sidecar logs, verify RBAC permissions |
| Webhook failures | RayCluster creation rejected | Check webhook service is running, verify cert-manager certificates |
| Dashboard not accessible | 8265 port unreachable | Check Ingress/Route configuration, verify service endpoints |
| Job submission fails | Job stuck in Pending | Verify Ray client port (10001), check head pod readiness |

### Debug Commands

```bash
# Check operator logs
kubectl logs -n opendatahub deployment/kuberay-operator

# Check RayCluster status
kubectl get raycluster -A
kubectl describe raycluster <name> -n <namespace>

# Check services created
kubectl get svc -l ray.io/cluster=<cluster-name>

# Check webhook configuration
kubectl get validatingwebhookconfiguration -l app.kubernetes.io/name=kuberay

# Test Ray cluster connectivity
kubectl exec -it <ray-head-pod> -- python -c "import ray; ray.init()"
```

## References

- **Upstream Documentation**: https://docs.ray.io/en/latest/cluster/kubernetes/index.html
- **KubeRay GitHub**: https://github.com/ray-project/kuberay
- **RHOAI KubeRay Fork**: https://github.com/red-hat-data-services/kuberay
- **Ray Project**: https://github.com/ray-project/ray
