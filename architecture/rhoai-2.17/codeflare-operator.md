# Component: CodeFlare Operator

## Metadata
- **Repository**: https://github.com/red-hat-data-services/codeflare-operator
- **Version**: v1.12.0 (rhoai-2.17 branch, commit 6184344)
- **Distribution**: RHOAI
- **Languages**: Go
- **Deployment Type**: Kubernetes Operator

## Purpose
**Short**: Manages lifecycle and security configuration for distributed AI/ML workloads using Ray clusters and AppWrapper orchestration.

**Detailed**:

The CodeFlare Operator is a Kubernetes operator that provides installation and lifecycle management for the CodeFlare distributed workload stack. It serves two primary functions: (1) managing RayCluster resources by adding OAuth-based dashboard authentication, mTLS encryption, network policies, and ingress/route configuration for secure external access, and (2) optionally embedding the AppWrapper controller for advanced workload orchestration and job queueing integration with Kueue.

The operator automatically detects whether it's running on OpenShift or vanilla Kubernetes and configures appropriate access patterns (Routes vs Ingresses). For Ray clusters, it creates OAuth proxy sidecars, service accounts, cluster role bindings, CA certificates for mTLS, and network policies to secure communication between Ray head and worker nodes. It integrates with the ODH/RHOAI platform by reading DSCInitialization resources to determine the applications namespace.

The embedded AppWrapper controller manages workload.codeflare.dev AppWrapper custom resources, which wrap multiple Kubernetes resources (Deployments, Jobs, RayClusters, PyTorchJobs) as a single schedulable unit, enabling gang scheduling and resource quota management through Kueue integration.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| codeflare-operator manager | Deployment | Main operator controller managing RayCluster and AppWrapper reconciliation |
| raycluster-controller | Controller | Watches RayCluster CRs and creates OAuth proxies, Routes/Ingresses, network policies, mTLS certificates |
| appwrapper-controller | Embedded Controller | Manages AppWrapper CRs and integrates with Kueue for workload scheduling |
| mutating-webhook | Admission Webhook | Mutates AppWrapper and RayCluster resources on CREATE/UPDATE |
| validating-webhook | Admission Webhook | Validates AppWrapper and RayCluster resources on CREATE/UPDATE |
| metrics-exporter | Prometheus Exporter | Exposes operator metrics on /metrics endpoint |
| cert-controller | Certificate Manager | Rotates webhook server TLS certificates and CA bundles |

## APIs Exposed

### Custom Resource Definitions (CRDs)

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| workload.codeflare.dev | v1beta2 | AppWrapper | Namespaced | Wraps multiple Kubernetes resources as single schedulable unit for gang scheduling with Kueue |

### HTTP Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /metrics | GET | 8080/TCP | HTTP | None | None | Prometheus metrics endpoint for operator health and performance |
| /healthz | GET | 8081/TCP | HTTP | None | None | Liveness probe endpoint |
| /readyz | GET | 8081/TCP | HTTP | None | None | Readiness probe endpoint (checks webhook cert readiness) |
| /mutate-workload-codeflare-dev-v1beta2-appwrapper | POST | 9443/TCP | HTTPS | TLS 1.2+ | K8s API Server | Mutating webhook for AppWrapper CREATE operations |
| /mutate-ray-io-v1-raycluster | POST | 9443/TCP | HTTPS | TLS 1.2+ | K8s API Server | Mutating webhook for RayCluster CREATE/UPDATE operations |
| /validate-workload-codeflare-dev-v1beta2-appwrapper | POST | 9443/TCP | HTTPS | TLS 1.2+ | K8s API Server | Validating webhook for AppWrapper CREATE/UPDATE operations |
| /validate-ray-io-v1-raycluster | POST | 9443/TCP | HTTPS | TLS 1.2+ | K8s API Server | Validating webhook for RayCluster CREATE/UPDATE operations |

### gRPC Services

No gRPC services exposed.

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| KubeRay Operator | v1.1.0 | Yes | Provides RayCluster CRD for distributed Ray workloads |
| Kueue | v0.8.3 | Optional | Job queueing and resource quota management for AppWrappers |
| AppWrapper Library | v0.30.0 | Yes | Embedded controller for AppWrapper orchestration |
| cert-controller | N/A | Yes | Manages webhook certificate rotation |

### Internal ODH Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| opendatahub-operator (DSCInitialization) | CRD Watch | Reads DSCInitialization to determine applications namespace for network policies |
| kuberay | CRD Watch | Watches and reconciles RayCluster resources |

## Network Architecture

### Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| codeflare-operator-webhook-service | ClusterIP | 443/TCP | 9443 | HTTPS | TLS 1.2+ | K8s API Server cert | Internal |
| codeflare-operator-manager-metrics | ClusterIP | 8080/TCP | 8080 | HTTP | None | None | Internal |
| {raycluster}-oauth (per cluster) | ClusterIP | 443/TCP | 443 | HTTPS | TLS (re-encrypt) | OAuth proxy | Internal |

### Ingress

| Name | Type | Hosts | Port | Protocol | Encryption | TLS Mode | Exposure |
|------|------|-------|------|----------|------------|----------|----------|
| ray-dashboard-{cluster} (OpenShift) | Route | {dashboard}-{ns}.{domain} | 443/TCP | HTTPS | TLS 1.2+ | Re-encrypt | External |
| rayclient-{cluster} (OpenShift) | Route | rayclient-{cluster}-{ns}.{domain} | 443/TCP | HTTPS | TLS 1.2+ | Re-encrypt | External |
| ray-dashboard-{cluster} (Kubernetes) | Ingress | {dashboard}-{ns}.{domain} | 443/TCP | HTTPS | TLS 1.2+ | SIMPLE | External |
| rayclient-{cluster} (Kubernetes) | Ingress | rayclient-{cluster}-{ns}.{domain} | 443/TCP | HTTPS | TLS 1.2+ | SIMPLE | External |

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | Service Account Token | Watch CRDs, create/update resources |
| KubeRay Operator | 8265/TCP | HTTP | None | None | Monitor RayCluster status |
| Kueue API (optional) | 6443/TCP | HTTPS | TLS 1.2+ | Service Account Token | Create/update Workload resources |

## Security

### RBAC - Cluster Roles

| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|
| manager-role | workload.codeflare.dev | appwrappers, appwrappers/status, appwrappers/finalizers | get, list, watch, create, update, patch, delete |
| manager-role | ray.io | rayclusters, rayclusters/status, rayclusters/finalizers, rayjobs | get, list, watch, create, update, patch, delete |
| manager-role | "" | pods, services, secrets, serviceaccounts, events | get, list, watch, create, update, patch, delete |
| manager-role | "" | nodes | get, list, watch |
| manager-role | apps | deployments, statefulsets | get, list, watch, create, update, patch, delete |
| manager-role | batch | jobs | get, list, watch, create, update, patch, delete |
| manager-role | networking.k8s.io | ingresses, networkpolicies | get, list, watch, create, update, patch, delete |
| manager-role | rbac.authorization.k8s.io | clusterrolebindings | get, list, watch, create, update, patch, delete |
| manager-role | route.openshift.io | routes, routes/custom-host | get, list, watch, create, update, patch, delete |
| manager-role | kueue.x-k8s.io | workloads, workloads/status, workloads/finalizers | get, list, watch, create, update, patch, delete |
| manager-role | kueue.x-k8s.io | clusterqueues, resourceflavors, workloadpriorityclasses | get, list, watch, update, patch |
| manager-role | scheduling.k8s.io | priorityclasses | get, list, watch |
| manager-role | scheduling.sigs.k8s.io, scheduling.x-k8s.io | podgroups | get, list, watch, create, update, patch, delete |
| manager-role | kubeflow.org | pytorchjobs | get, list, watch, create, update, patch, delete |
| manager-role | admissionregistration.k8s.io | mutatingwebhookconfigurations, validatingwebhookconfigurations | get, list, watch, update |
| manager-role | apiextensions.k8s.io | customresourcedefinitions | get, list, watch |
| manager-role | dscinitialization.opendatahub.io | dscinitializations | get, list, watch |
| manager-role | authentication.k8s.io | tokenreviews | create |
| manager-role | authorization.k8s.io | subjectaccessreviews | create |
| manager-role | config.openshift.io | ingresses | get |
| {cluster}-{ns}-auth (per RayCluster) | rbac.authorization.k8s.io | system:auth-delegator | all verbs |

### RBAC - Role Bindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| manager-role-binding | All namespaces | manager-role (ClusterRole) | controller-manager |
| leader-election-role-binding | Operator namespace | leader-election-role (Role) | controller-manager |
| {cluster}-{ns}-auth (per RayCluster) | N/A (ClusterRoleBinding) | system:auth-delegator | {cluster}-oauth-proxy |

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| codeflare-operator-webhook-server-cert | kubernetes.io/tls | TLS cert for webhook server | cert-controller | Yes |
| {cluster}-oauth-config | Opaque | OAuth proxy cookie secret for Ray dashboard | RayCluster controller | No |
| {cluster}-proxy-tls-secret | kubernetes.io/tls | Service serving cert for OAuth proxy | OpenShift service-ca | Yes |
| ca-secret-{cluster} | Opaque | CA certificate and private key for Ray mTLS | RayCluster controller | No |

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| /metrics | GET | None | N/A | Open to cluster monitoring |
| /healthz, /readyz | GET | None | N/A | Open for kubelet probes |
| /mutate-*, /validate-* | POST | TLS client cert | Kubernetes API Server | Only API server can call webhooks |
| Ray Dashboard (OpenShift) | ALL | OAuth Proxy (OpenShift auth) | OAuth proxy sidecar | Requires valid OpenShift session token |
| Ray Dashboard (Kubernetes) | ALL | None (behind Ingress) | Ingress controller | External ingress authentication required |
| Ray Client API | ALL | mTLS (if enabled) | Ray head node | Client must present valid client cert from CA |

### Network Policies

| Policy Name | Target Pods | Ingress Rules |
|-------------|-------------|---------------|
| {cluster}-head | Ray head pods (ray.io/cluster={cluster}, ray.io/node-type=head) | Allow from same cluster pods (all ports); Allow from namespace pods on 10001/TCP, 8265/TCP; Allow from KubeRay operator on 8265/TCP, 10001/TCP; Allow from openshift-monitoring on 8080/TCP; Allow all on 8443/TCP (OAuth), 10001/TCP (Ray client, if mTLS) |
| {cluster}-workers | Ray worker pods (ray.io/cluster={cluster}, ray.io/node-type=worker) | Allow only from same cluster pods (all ports) |

## Data Flows

### Flow 1: User Creates RayCluster (OpenShift)

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User (kubectl/oc) | Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | User credentials |
| 2 | Kubernetes API Server | Operator Webhook | 9443/TCP | HTTPS | TLS 1.2+ | API Server cert |
| 3 | Operator (RayCluster Controller) | Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | Service Account Token |
| 4 | Operator | Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | Service Account Token |
| 5 | Operator | Generates CA cert, creates OAuth Service/Route/Secret/ServiceAccount/ClusterRoleBinding/NetworkPolicy | N/A | N/A | N/A | N/A |

### Flow 2: User Accesses Ray Dashboard (OpenShift)

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User Browser | OpenShift Router | 443/TCP | HTTPS | TLS 1.3 | None |
| 2 | OpenShift Router | OAuth Service (OAuth Proxy sidecar) | 443/TCP | HTTPS | TLS 1.2+ (re-encrypt) | OpenShift session cookie |
| 3 | OAuth Proxy | OpenShift OAuth Server | 443/TCP | HTTPS | TLS 1.2+ | OAuth token |
| 4 | OAuth Proxy | Ray Dashboard (localhost) | 8265/TCP | HTTP | None | Localhost trust |

### Flow 3: User Creates AppWrapper

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User (kubectl) | Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | User credentials |
| 2 | Kubernetes API Server | Operator Webhook | 9443/TCP | HTTPS | TLS 1.2+ | API Server cert |
| 3 | Operator (AppWrapper Controller) | Kueue API (create Workload) | 6443/TCP | HTTPS | TLS 1.2+ | Service Account Token |
| 4 | Kueue | Operator (updates AppWrapper status) | 6443/TCP | HTTPS | TLS 1.2+ | Service Account Token |
| 5 | Operator | Kubernetes API Server (creates wrapped resources) | 6443/TCP | HTTPS | TLS 1.2+ | Service Account Token |

### Flow 4: Prometheus Scrapes Metrics

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Prometheus | Manager Metrics Service | 8080/TCP | HTTP | None | Service Account Token (Bearer) |

### Flow 5: Ray Client Connects to Cluster (mTLS enabled)

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Ray Client Pod | Ray Head Service | 10001/TCP | gRPC/HTTP2 | mTLS | Client cert signed by cluster CA |

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| Kubernetes API Server | REST API (Watch/Create/Update) | 6443/TCP | HTTPS | TLS 1.2+ | Watch CRDs, manage resources |
| KubeRay Operator | CRD Watch | 6443/TCP | HTTPS | TLS 1.2+ | Detect RayCluster API availability |
| Kueue | CRD Create/Update | 6443/TCP | HTTPS | TLS 1.2+ | Submit AppWrapper workloads for scheduling |
| OpenShift OAuth Server | HTTP API | 443/TCP | HTTPS | TLS 1.2+ | Validate user tokens for dashboard access |
| Prometheus | HTTP Scrape | 8080/TCP | HTTP | None | Collect operator metrics |
| OpenShift Service CA | Certificate Injection | N/A | N/A | N/A | Provides TLS certs for OAuth proxy services |
| cert-controller | Certificate Rotation | N/A | N/A | N/A | Manages webhook server certificates |

## Recent Changes

| Version | Date | Changes |
|---------|------|---------|
| 6184344 | 2026-03 | - Update Konflux references (#319) |
| 4a4d8b0 | 2026-03 | - Update Konflux references (#318) |
| c88764b | 2026-03 | - Update registry.access.redhat.com/ubi8/go-toolset:1.22 Docker digest to c7ebff7 (#315) |
| 7435e3d | 2026-03 | - Update Konflux references (#308) |
| 3971051 | 2026-03 | - Update Konflux references to b9cb1e1 (#302) |
| 90d016e | 2026-03 | - Update Konflux references to b9cb1e1 (#301) |
| 18b281b | 2026-03 | - Update Konflux references to 944e769 (#295) |
| a02b07f | 2026-03 | - Update Konflux references to 944e769 (#294) |
| 4244b0e | 2026-02 | - Update Konflux references to 6673cbd (#284) |
| 87d66c5 | 2026-02 | - Update Konflux references (#282) |
| 938f3f6 | 2026-02 | - Update Konflux references to 8b6f22f (#276) |
| e0c689f | 2026-02 | - Update Konflux references to 8b6f22f (#274) |
| 1f41252 | 2026-02 | - Update Konflux references (#268) |
| 5088cf4 | 2026-02 | - Update registry.access.redhat.com/ubi8/go-toolset:1.22 Docker digest to 2a324cf (#265) |
| d343374 | 2026-02 | - Update registry.access.redhat.com/ubi8/ubi-minimal Docker digest to c38cc77 (#255) |
| f6ce806 | 2026-02 | - Update Konflux references to 5bc6129 (#249) |
| af64b83 | 2026-01 | - Update registry.access.redhat.com/ubi8/go-toolset:1.22 Docker digest to 1f949a7 (#241) |
| 51445ad | 2026-01 | - chore(deps): update konflux references to b78123a (#229) |
| 9c16faf | 2026-01 | - chore(deps): update konflux references |
| a570eca | 2026-01 | - Merge pull request #216 from red-hat-data-services/MohammadiIram-patch-4 |

## Configuration

### Operator Configuration (ConfigMap: codeflare-operator-config)

| Parameter | Default | Purpose |
|-----------|---------|---------|
| KubeRay.RayDashboardOAuthEnabled | true | Enable OAuth proxy for Ray dashboard (OpenShift only) |
| KubeRay.MTLSEnabled | true | Enable mTLS encryption for Ray client connections |
| KubeRay.IngressDomain | Auto-detected | Domain for generating Ingress/Route hostnames |
| AppWrapper.Enabled | false | Enable embedded AppWrapper controller |
| ClientConnection.QPS | 50 | Kubernetes API client queries per second |
| ClientConnection.Burst | 100 | Kubernetes API client burst allowance |
| Metrics.BindAddress | :8080 | Metrics HTTP server bind address |
| Health.BindAddress | :8081 | Health probe HTTP server bind address |
| LeaderElection.LeaderElect | false | Enable leader election for HA deployments |

## Deployment Architecture

### Container Images

| Image | Registry | Purpose |
|-------|----------|---------|
| odh-codeflare-operator-container | registry.access.redhat.com/managed-open-data-hub/odh-codeflare-operator-container-rhel8 | Main operator container (FIPS-compliant build) |

### Resource Requirements

| Resource | Request | Limit |
|----------|---------|-------|
| CPU | 1 core | 1 core |
| Memory | 1Gi | 1Gi |

### Deployment Topology

- **Replicas**: 1 (active-passive leader election optional)
- **Namespace**: Determined by ODH/RHOAI platform (typically redhat-ods-applications)
- **ServiceAccount**: controller-manager
- **Security Context**: runAsNonRoot=true, allowPrivilegeEscalation=false, capabilities dropped=ALL

## Observability

### Metrics

Prometheus metrics exposed on :8080/metrics include:
- Standard controller-runtime metrics (workqueue, reconciliation latency)
- Custom metrics for AppWrapper and RayCluster reconciliation
- Webhook admission latency metrics

### Logs

Structured JSON logging with configurable log levels (--zap-log-level flag). Filters sensitive information from logs.

### Health Checks

- **Liveness**: HTTP GET :8081/healthz (simple ping)
- **Readiness**: HTTP GET :8081/readyz (checks webhook cert readiness)

## Known Limitations

1. **OpenShift-specific features**: OAuth proxy and Routes only work on OpenShift; vanilla Kubernetes deployments require external authentication for dashboard access
2. **Single replica**: No built-in HA support (leader election configurable but not enabled by default)
3. **AppWrapper controller conditional loading**: If Kueue Workload API becomes available after operator start, requires operator restart to enable AppWrapper indexers
4. **Network policy assumptions**: Assumes KubeRay operator is in opendatahub or redhat-ods-applications namespace
5. **Certificate rotation**: CA certificates for Ray mTLS are not auto-rotated (1-year validity)
