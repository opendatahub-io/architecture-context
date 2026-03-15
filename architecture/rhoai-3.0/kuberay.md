# Component: KubeRay Operator

## Metadata
- **Repository**: https://github.com/red-hat-data-services/kuberay
- **Version**: dac6aae7 (rhoai-3.0 branch)
- **Distribution**: RHOAI
- **Languages**: Go
- **Deployment Type**: Kubernetes Operator

## Purpose
**Short**: KubeRay is a Kubernetes operator that manages the lifecycle of Ray clusters for distributed computing and machine learning workloads.

**Detailed**: KubeRay simplifies the deployment and management of Ray applications on Kubernetes by providing three core custom resource definitions (CRDs): RayCluster, RayJob, and RayService. RayCluster manages the full lifecycle of Ray clusters including creation, deletion, autoscaling, and fault tolerance. RayJob automatically creates a RayCluster and submits jobs when the cluster is ready, with optional automatic cleanup after job completion. RayService combines a RayCluster with a Ray Serve deployment graph to provide zero-downtime upgrades and high availability for ML model serving. The operator includes advanced features such as mTLS certificate management via cert-manager, network policy enforcement, authentication integration with OpenShift, and support for multiple batch schedulers (Volcano, Yunikorn, Kueue).

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| KubeRay Operator | Kubernetes Operator | Manages lifecycle of RayCluster, RayJob, and RayService custom resources |
| RayCluster Controller | Reconciler | Reconciles RayCluster resources, manages head and worker pods |
| RayJob Controller | Reconciler | Reconciles RayJob resources, manages job submission and lifecycle |
| RayService Controller | Reconciler | Reconciles RayService resources, manages Ray Serve deployments |
| NetworkPolicy Controller | Reconciler | Creates and manages NetworkPolicy resources for Ray clusters |
| Authentication Controller | Reconciler | Manages OpenShift OAuth integration and Gateway API configurations |
| mTLS Controller | Reconciler | Manages cert-manager Certificates and Issuers for Ray cluster mTLS |
| Webhook Server | Admission Controller | Validates and mutates RayCluster resources on CREATE/UPDATE |

## APIs Exposed

### Custom Resource Definitions (CRDs)

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| ray.io | v1 | RayCluster | Namespaced | Defines a Ray cluster with head and worker node specifications |
| ray.io | v1 | RayJob | Namespaced | Defines a Ray job that creates a cluster and executes a workload |
| ray.io | v1 | RayService | Namespaced | Defines a Ray Serve deployment with high availability |
| ray.io | v1alpha1 | RayCluster | Namespaced | Legacy API version for RayCluster (deprecated) |
| ray.io | v1alpha1 | RayJob | Namespaced | Legacy API version for RayJob (deprecated) |
| ray.io | v1alpha1 | RayService | Namespaced | Legacy API version for RayService (deprecated) |

### HTTP Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /metrics | GET | 8080/TCP | HTTP | None | None | Prometheus metrics endpoint for operator monitoring |
| /healthz | GET | 8081/TCP | HTTP | None | None | Health check probe endpoint |
| /readyz | GET | 8081/TCP | HTTP | None | None | Readiness probe endpoint |
| /mutate-ray-io-v1-raycluster | POST | 9443/TCP | HTTPS | TLS 1.2+ | Kubernetes API Server | Mutating webhook for RayCluster validation |
| /validate-ray-io-v1-raycluster | POST | 9443/TCP | HTTPS | TLS 1.2+ | Kubernetes API Server | Validating webhook for RayCluster validation |

### gRPC Services

| Service | Port | Protocol | Encryption | Auth | Purpose |
|---------|------|----------|------------|------|---------|
| N/A | N/A | N/A | N/A | N/A | Operator does not expose gRPC services (managed Ray clusters do) |

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| Kubernetes | 1.24+ | Yes | Platform for operator deployment and resource management |
| cert-manager | 1.0+ | Optional | Certificate management for Ray cluster mTLS encryption |
| OpenShift Route API | 4.x | Optional | Route creation for Ray cluster ingress on OpenShift |
| Gateway API | v1/v1beta1 | Optional | HTTPRoute and Gateway integration for ingress |
| Volcano | Any | Optional | Gang scheduling for Ray cluster pods |
| Yunikorn | Any | Optional | Advanced batch scheduling for Ray workloads |
| Kueue | Any | Optional | Job queueing and quota management |

### Internal ODH Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| None | N/A | KubeRay operates independently without direct ODH component dependencies |

## Network Architecture

### Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| kuberay-operator | ClusterIP | 8080/TCP | 8080 | HTTP | None | None | Internal (metrics) |
| kuberay-webhook-service | ClusterIP | 443/TCP | 9443 | HTTPS | TLS 1.2+ | mTLS (Kubernetes API) | Internal (webhooks) |

### Ingress

| Name | Type | Hosts | Port | Protocol | Encryption | TLS Mode | Exposure |
|------|------|-------|------|----------|------------|----------|----------|
| N/A | N/A | N/A | N/A | N/A | N/A | N/A | Operator does not expose external ingress (managed Ray clusters may) |

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | Service Account Token | CRD reconciliation and resource management |
| Ray Cluster Pods | 6379/TCP | TCP | Optional mTLS | Optional mTLS | Ray GCS (Global Control Service) communication |
| Ray Cluster Pods | 8265/TCP | HTTP/HTTPS | Optional TLS | Optional | Ray Dashboard access for status checks |
| Ray Cluster Pods | 10001/TCP | TCP | Optional mTLS | Optional mTLS | Ray Client server communication |

## Security

### RBAC - Cluster Roles

| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|
| kuberay-operator | "" | pods, services, serviceaccounts, configmaps, events, secrets, endpoints | get, list, watch, create, update, patch, delete |
| kuberay-operator | "" | pods/status, pods/proxy, services/status, services/proxy | get, patch, update |
| kuberay-operator | apps | deployments | get, list, watch, patch, update |
| kuberay-operator | batch | jobs | get, list, watch, create, update, patch, delete |
| kuberay-operator | ray.io | rayclusters, rayjobs, rayservices | get, list, watch, create, update, patch, delete |
| kuberay-operator | ray.io | rayclusters/status, rayjobs/status, rayservices/status | get, patch, update |
| kuberay-operator | ray.io | rayclusters/finalizers, rayjobs/finalizers, rayservices/finalizers | update |
| kuberay-operator | networking.k8s.io | ingresses, networkpolicies, ingressclasses | get, list, watch, create, update, patch, delete |
| kuberay-operator | route.openshift.io | routes | get, list, watch, create, update, patch, delete |
| kuberay-operator | cert-manager.io | certificates, issuers | get, list, watch, create, update, patch, delete |
| kuberay-operator | cert-manager.io | certificates/status | get, patch, update |
| kuberay-operator | gateway.networking.k8s.io | gateways | get, list, watch |
| kuberay-operator | gateway.networking.k8s.io | httproutes, referencegrants | get, list, watch, create, update, patch, delete |
| kuberay-operator | rbac.authorization.k8s.io | roles, rolebindings, clusterroles, clusterrolebindings | get, list, watch, create, update, delete |
| kuberay-operator | coordination.k8s.io | leases | get, list, create, update |
| kuberay-operator | authentication.k8s.io | tokenreviews | create |
| kuberay-operator | authorization.k8s.io | subjectaccessreviews | create |
| kuberay-operator | config.openshift.io | authentications, oauths | get, list, watch |
| kuberay-operator | operator.openshift.io | kubeapiservers | get, list, watch |

### RBAC - Role Bindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| kuberay-operator | Cluster-wide | kuberay-operator (ClusterRole) | kuberay-operator |

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| kuberay-webhook-server-cert | kubernetes.io/tls | TLS certificate for webhook server | OpenShift Service CA | Yes |
| Ray cluster mTLS certs | kubernetes.io/tls | mTLS certificates for Ray internal communication | cert-manager | Yes |

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| /metrics | GET | None | N/A | Open to cluster for Prometheus scraping |
| /mutate-ray-io-v1-raycluster | POST | mTLS client certificate | Kubernetes API Server | Only Kubernetes API server can invoke |
| /validate-ray-io-v1-raycluster | POST | mTLS client certificate | Kubernetes API Server | Only Kubernetes API server can invoke |

### Security Context Constraints (OpenShift)

| SCC Name | Run As User | Capabilities | Privilege Escalation | Purpose |
|----------|-------------|--------------|---------------------|---------|
| run-as-ray-user | 1000 (Ray user) | Drop ALL | Denied | Allows Ray pods to run as non-root user 1000 |

## Data Flows

### Flow 1: RayCluster Creation

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User/CLI | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | Bearer Token (user credentials) |
| 2 | Kubernetes API | kuberay-webhook-service | 9443/TCP | HTTPS | TLS 1.2+ | mTLS (API server cert) |
| 3 | RayCluster Controller | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | Bearer Token (SA) |
| 4 | RayCluster Controller | Ray Head Pod | 8265/TCP | HTTP | None | None |
| 5 | Ray Worker Pods | Ray Head Pod (GCS) | 6379/TCP | TCP | Optional mTLS | Optional mTLS |

### Flow 2: RayJob Execution

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User/CLI | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | Bearer Token (user credentials) |
| 2 | RayJob Controller | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | Bearer Token (SA) |
| 3 | RayJob Controller | Ray Head Pod | 10001/TCP | TCP | Optional mTLS | Optional mTLS |
| 4 | Ray Head Pod | Ray Worker Pods | Dynamic | TCP | Optional mTLS | Optional mTLS |

### Flow 3: Metrics Collection

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Prometheus | kuberay-operator service | 8080/TCP | HTTP | None | None |

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| Kubernetes API Server | REST API | 6443/TCP | HTTPS | TLS 1.2+ | Watch and manage Ray CRDs and Kubernetes resources |
| cert-manager | CRD API | 6443/TCP | HTTPS | TLS 1.2+ | Request and manage TLS certificates for Ray clusters |
| Prometheus | HTTP Pull | 8080/TCP | HTTP | None | Scrape operator metrics for monitoring |
| OpenShift Service CA | Certificate Injection | N/A | N/A | N/A | Automatic webhook certificate provisioning |
| Gateway API | CRD API | 6443/TCP | HTTPS | TLS 1.2+ | Create HTTPRoutes for Ray cluster ingress |
| Volcano Scheduler | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | Gang scheduling annotations for Ray pods |
| Kueue | CRD API | 6443/TCP | HTTPS | TLS 1.2+ | Job queue management for RayJobs |

## Recent Changes

| Commit | Date | Changes |
|--------|------|---------|
| dac6aae7 | 2025-01-13 | - Update UBI9 go-toolset base image digest<br>- Dependency updates for security patches |
| ed6ec6b6 | 2024-12-16 | - Update UBI9 go-toolset base image digest |
| 0189b21b | 2024-12-30 | - Update UBI9 ubi-minimal base image digest |
| c8381bbb | 2024-12-28 | - Update UBI9 ubi-minimal base image digest |
| c30f345d | 2024-12-03 | - Update Konflux pipeline references |
| 4ffc5c82 | 2024-12-03 | - Update Konflux pipeline references |
| b06c936d | 2024-12-02 | - Update Konflux pipeline references |

## Deployment Configuration

### Kustomize Structure

The operator is deployed using Kustomize with the following structure:

**Base Configuration**: `ray-operator/config/default`
- Manager deployment
- RBAC resources
- CRD definitions

**OpenShift Overlay**: `ray-operator/config/openshift`
- Namespace: `opendatahub`
- Custom SecurityContextConstraints for Ray pods
- Webhook configuration with OpenShift Service CA integration
- Gateway API environment variable configuration
- Image override: `quay.io/opendatahub/kuberay-operator:v1.4.2`

### Container Build

**Build File**: `ray-operator/Dockerfile.konflux`
- Base Image: `registry.access.redhat.com/ubi9/go-toolset` (build stage)
- Runtime Image: `registry.access.redhat.com/ubi9/ubi-minimal`
- Build: CGO enabled with FIPS mode (`GOEXPERIMENT=strictfipsruntime`)
- Run As: Non-root user 65532

## Operational Characteristics

### Resource Requirements

**Operator Pod**:
- CPU: 100m (request and limit)
- Memory: 512Mi (request and limit)

### Scaling

- **Operator**: Single replica (Recreate strategy)
- **Leader Election**: Optional (disabled by default, can be enabled for HA)
- **Reconciliation Concurrency**: Configurable (default varies by configuration)

### Feature Gates

Configurable features include:
- `RayClusterStatusConditions`: Enhanced status conditions (enabled by default in v1.3+)
- Batch scheduler integration (Volcano, Yunikorn)
- Metrics emission
- Init container injection for Ray GCS readiness

### Logging

- **Format**: JSON or console (configurable)
- **Output**: stdout and optional file rotation
- **File Rotation**: 500MB max size, 10 file backups
- **Log Encoder**: Configurable for stdout and file separately
