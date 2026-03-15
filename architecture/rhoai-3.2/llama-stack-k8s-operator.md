# Component: Llama Stack Kubernetes Operator

## Metadata
- **Repository**: https://github.com/red-hat-data-services/llama-stack-k8s-operator
- **Version**: v0.5.0 (commit: 54ab19b)
- **Branch**: rhoai-3.2
- **Distribution**: RHOAI
- **Languages**: Go (1.24)
- **Deployment Type**: Kubernetes Operator
- **Build System**: Konflux

## Purpose
**Short**: Kubernetes operator that automates deployment and lifecycle management of Llama Stack servers.

**Detailed**: The Llama Stack Kubernetes Operator is a cloud-native controller that provides automated deployment, configuration, and management of Llama Stack server instances on Kubernetes platforms. The operator watches custom resources (LlamaStackDistribution) and reconciles the desired state by creating and managing the necessary Kubernetes resources including deployments, services, storage, autoscaling, and network policies. It supports multiple Llama Stack distributions (including Ollama, vLLM, and Meta reference implementations) and provides enterprise features such as horizontal pod autoscaling, pod disruption budgets, topology-aware scheduling, TLS certificate management, and optional network isolation. The operator enables users to declaratively manage Llama Stack servers through Kubernetes-native APIs while handling operational complexity such as version upgrades, configuration management via ConfigMaps, and integration with OpenShift security contexts.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| LlamaStackDistribution Controller | Reconciliation Controller | Watches and reconciles LlamaStackDistribution CRs to manage Llama Stack server lifecycle |
| Cluster Info Manager | Configuration Manager | Loads and manages distribution images, feature flags, and image overrides from ConfigMaps |
| Kustomizer | Deployment Engine | Renders Kubernetes manifests from kustomize templates with instance-specific transformations |
| Resource Helper | Resource Builder | Constructs Kubernetes resources (Deployments, Services, PVCs, HPAs, PDBs, NetworkPolicies) |
| Network Policy Manager | Security Controller | Creates and manages NetworkPolicy resources for network isolation (feature-flagged) |
| CA Bundle Manager | TLS Configuration | Detects and manages CA certificate bundles for secure external connections |
| Metrics Exporter | Observability | Exposes Prometheus metrics via kube-rbac-proxy on port 8443 |
| Health Probe Handler | Health Monitoring | Provides health and readiness endpoints on port 8081 |

## APIs Exposed

### Custom Resource Definitions (CRDs)

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| llamastack.io | v1alpha1 | LlamaStackDistribution | Namespaced | Defines desired state for a Llama Stack server deployment including replicas, distribution type, container spec, storage, autoscaling, and TLS configuration |

**Key CRD Fields:**
- `spec.replicas`: Number of server replicas (default: 1)
- `spec.server.distribution`: Distribution name (starter, remote-vllm, meta-reference-gpu, postgres-demo) or custom image
- `spec.server.containerSpec`: Container configuration (port, resources, env vars, command/args)
- `spec.server.workers`: Uvicorn worker count for multi-process serving
- `spec.server.storage`: Persistent storage configuration (size, mountPath)
- `spec.server.autoscaling`: HPA configuration (minReplicas, maxReplicas, CPU/memory targets)
- `spec.server.podDisruptionBudget`: Voluntary disruption controls
- `spec.server.userConfig`: ConfigMap reference for run.yaml configuration
- `spec.server.tlsConfig`: CA bundle configuration for custom certificates
- `status.phase`: Current phase (Pending, Initializing, Ready, Failed, Terminating)
- `status.serviceURL`: Internal Kubernetes service URL

### HTTP Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /metrics | GET | 8080/TCP | HTTP | None | None | Prometheus metrics (internal, proxied by kube-rbac-proxy) |
| /metrics | GET | 8443/TCP | HTTPS | TLS 1.2+ | Bearer Token (SubjectAccessReview) | Prometheus metrics (external, via kube-rbac-proxy) |
| /healthz | GET | 8081/TCP | HTTP | None | None | Operator liveness probe |
| /readyz | GET | 8081/TCP | HTTP | None | None | Operator readiness probe |

**Llama Stack Server Endpoints (created by operator):**

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /v1/health | GET | 8321/TCP | HTTP | None | None | Llama Stack server health check |
| /v1/* | POST/GET | 8321/TCP | HTTP | None | None | Llama Stack API endpoints (inference, agents, safety, etc.) |

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| Kubernetes | 1.20+ | Yes | Orchestration platform for operator and workloads |
| controller-runtime | v0.17+ | Yes | Kubernetes controller framework and reconciliation engine |
| kube-rbac-proxy | v0.15.0 | Yes | RBAC authorization proxy for metrics endpoint |
| Llama Stack Distribution | v0.3.5 | Yes | Llama Stack server images (managed by operator) |
| Kustomize | v4+ | Yes | Manifest rendering and transformation |
| OpenShift SCC | anyuid | Optional | Required on OpenShift for container permissions |
| Prometheus ServiceMonitor | - | Optional | Metrics scraping via Prometheus Operator |
| cert-manager | - | Optional | TLS certificate provisioning for user workloads |

### Internal ODH/RHOAI Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| ODH Dashboard | CRD Management | Users create LlamaStackDistribution CRs via ODH UI |
| ODH Trusted CA Bundle | ConfigMap Detection | Auto-detects odh-trusted-ca-bundle ConfigMap for TLS certificate injection |
| Model Registry | External Service | Llama Stack servers may query model registry for model metadata |
| Inference Services (vLLM, Ollama) | HTTP/gRPC | Llama Stack distributions integrate with inference providers |

## Network Architecture

### Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| controller-manager-metrics-service | ClusterIP | 8443/TCP | https | HTTPS | TLS 1.2+ | Bearer Token | Internal (operator namespace) |
| {instance-name}-service | ClusterIP | 8321/TCP | 8321 | HTTP | None | None | Internal (user namespace) |

**Service Labels:**
- Operator: `control-plane: controller-manager`
- Llama Stack: `app: llama-stack`, `app.kubernetes.io/instance: {instance-name}`

### Ingress

The operator does not create Ingress resources by default. Users must manually configure Ingress/Route to expose Llama Stack servers externally.

**Recommended External Exposure:**
```yaml
apiVersion: route.openshift.io/v1
kind: Route
metadata:
  name: {instance-name}
spec:
  to:
    kind: Service
    name: {instance-name}-service
  port:
    targetPort: 8321
  tls:
    termination: edge
```

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| Kubernetes API Server | 443/TCP | HTTPS | TLS 1.2+ | Bearer Token (ServiceAccount) | CRD watch, resource CRUD operations |
| Container Registry (quay.io, docker.io) | 443/TCP | HTTPS | TLS 1.2+ | Registry Credentials | Pull Llama Stack distribution images |
| Inference Providers (vLLM, Ollama) | 11434/TCP, 8000/TCP | HTTP/gRPC | Varies | API Keys | Llama Stack calls to inference backends |
| HuggingFace Hub | 443/TCP | HTTPS | TLS 1.2+ | HF Tokens | Model and dataset downloads |
| External APIs | 443/TCP | HTTPS | TLS 1.2+ | API Keys | Custom integrations defined in run.yaml |

### Network Policies (Optional, Feature-Flagged)

**Policy Name:** `{instance-name}-network-policy`

**Enabled By:** ConfigMap `llama-stack-operator-config` in operator namespace with `featureFlags.enableNetworkPolicy.enabled: true`

**Ingress Rules:**
1. Allow from pods with label `app.kubernetes.io/part-of: llama-stack` in same namespace on port 8321/TCP
2. Allow from all pods in operator namespace on port 8321/TCP

**Egress Rules:** Not restricted (default allow)

## Security

### RBAC - Cluster Roles

| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|
| manager-role | llamastack.io | llamastackdistributions | get, list, watch, create, update, patch, delete |
| manager-role | llamastack.io | llamastackdistributions/status | get, update, patch |
| manager-role | llamastack.io | llamastackdistributions/finalizers | update |
| manager-role | apps | deployments | get, list, watch, create, update, patch, delete |
| manager-role | "" (core) | services, serviceaccounts | get, list, watch, create, update, patch, delete |
| manager-role | "" (core) | persistentvolumeclaims | get, list, watch, create |
| manager-role | "" (core) | configmaps | get, list, watch, create, update, patch |
| manager-role | networking.k8s.io | networkpolicies | get, list, watch, create, update, patch, delete |
| manager-role | policy | poddisruptionbudgets | get, list, watch, create, update, patch, delete |
| manager-role | autoscaling | horizontalpodautoscalers | get, list, watch, create, update, patch, delete |
| manager-role | rbac.authorization.k8s.io | rolebindings | get, list, watch, create, update, patch, delete |
| manager-role | rbac.authorization.k8s.io | clusterroles | get, list, watch |
| manager-role | rbac.authorization.k8s.io | clusterrolebindings | get, list, delete |
| manager-role | security.openshift.io | securitycontextconstraints | use |
| manager-role | security.openshift.io | securitycontextconstraints (anyuid) | use |
| auth-proxy-role | "" (core) | configmaps | get, list, watch |
| leader-election-role | coordination.k8s.io | leases | get, list, watch, create, update, patch |

### RBAC - Role Bindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| manager-rolebinding | Cluster-wide | manager-role (ClusterRole) | controller-manager (operator namespace) |
| auth-proxy-rolebinding | operator namespace | auth-proxy-role (Role) | controller-manager (operator namespace) |
| leader-election-rolebinding | operator namespace | leader-election-role (Role) | controller-manager (operator namespace) |
| {instance-name}-rolebinding | user namespace | view (ClusterRole) | {instance-name}-sa (user namespace) |

**Llama Stack Server Service Accounts:**
- Each LlamaStackDistribution creates a ServiceAccount: `{instance-name}-sa`
- Bound to ClusterRole `view` for read-only Kubernetes API access
- Users can override via `spec.server.podOverrides.serviceAccountName`

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| controller-manager-token | kubernetes.io/service-account-token | Operator ServiceAccount credentials | Kubernetes | No |
| {instance-name}-sa-token | kubernetes.io/service-account-token | Llama Stack server ServiceAccount credentials | Kubernetes | No |
| hf-token-secret | Opaque | HuggingFace API token for model downloads (user-provided) | User | No |

**Note:** The operator does not manage TLS secrets. Users must provision secrets manually if using HTTPS/TLS.

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| /metrics (8443) | GET | Bearer Token (JWT) | kube-rbac-proxy | SubjectAccessReview against auth-proxy-role |
| /healthz, /readyz (8081) | GET | None | Operator | None (health probes) |
| Kubernetes API (operator) | ALL | Bearer Token (ServiceAccount) | Kubernetes API Server | ClusterRole: manager-role |
| Llama Stack API (8321) | POST/GET | None (default) | None | User must implement auth in run.yaml or external proxy |

**OpenShift Security Context Constraints:**
- Operator pod runs as non-root (UID 1001)
- Llama Stack server pods run with `fsGroup: 1001` for volume permissions
- Requires `anyuid` SCC on OpenShift for operator functionality

## Data Flows

### Flow 1: LlamaStackDistribution Creation

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User/ODH Dashboard | Kubernetes API Server | 443/TCP | HTTPS | TLS 1.3 | Bearer Token (User) |
| 2 | Kubernetes API Server | Operator Controller | Watch Stream | HTTPS | TLS 1.3 | Bearer Token (SA) |
| 3 | Operator Controller | Kubernetes API Server | 443/TCP | HTTPS | TLS 1.3 | Bearer Token (SA) |
| 4 | Kubelet | Container Registry | 443/TCP | HTTPS | TLS 1.2+ | Registry Credentials |
| 5 | Llama Stack Pod | HuggingFace Hub | 443/TCP | HTTPS | TLS 1.2+ | HF Token (optional) |

**Flow Description:**
1. User creates LlamaStackDistribution CR via kubectl or ODH Dashboard
2. Operator reconciles CR and creates Deployment, Service, PVC, ServiceAccount, RoleBinding
3. Kubernetes scheduler assigns pod to node
4. Kubelet pulls Llama Stack distribution image from registry
5. Llama Stack container starts, downloads models/datasets from HuggingFace if configured

### Flow 2: Inference Request to Llama Stack Server

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Client Application | {instance-name}-service | 8321/TCP | HTTP | None | None (default) |
| 2 | Service | Llama Stack Pod | 8321/TCP | HTTP | None | None |
| 3 | Llama Stack Pod | Inference Provider (vLLM/Ollama) | 8000/TCP or 11434/TCP | HTTP/gRPC | None | API Key (optional) |
| 4 | Llama Stack Pod | Client Application | 8321/TCP | HTTP | None | None |

**Flow Description:**
1. Client sends inference request to ClusterIP service
2. Service load-balances to healthy Llama Stack pod
3. Llama Stack calls configured inference provider (Ollama/vLLM)
4. Response returns to client via service

### Flow 3: Operator Metrics Collection

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Prometheus | kube-rbac-proxy | 8443/TCP | HTTPS | TLS 1.2+ | Bearer Token |
| 2 | kube-rbac-proxy | Kubernetes API Server | 443/TCP | HTTPS | TLS 1.3 | SubjectAccessReview |
| 3 | kube-rbac-proxy | Operator Manager | 8080/TCP | HTTP | None | None (localhost) |
| 4 | kube-rbac-proxy | Prometheus | 8443/TCP | HTTPS | TLS 1.2+ | None |

**Flow Description:**
1. Prometheus scrapes /metrics endpoint on kube-rbac-proxy (8443)
2. Proxy validates bearer token via SubjectAccessReview
3. Proxy forwards authorized request to operator metrics port (8080 localhost)
4. Metrics data returned to Prometheus

### Flow 4: ConfigMap-Based Configuration Update

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User | Kubernetes API Server | 443/TCP | HTTPS | TLS 1.3 | Bearer Token (User) |
| 2 | Operator Controller | Kubernetes API Server | 443/TCP | HTTPS | TLS 1.3 | Bearer Token (SA) |
| 3 | Operator Controller | Kubernetes API Server | 443/TCP | HTTPS | TLS 1.3 | Bearer Token (SA) |
| 4 | Kubelet | Llama Stack Pod | - | - | - | - |

**Flow Description:**
1. User updates ConfigMap referenced in `spec.server.userConfig.configMapName`
2. Operator detects ConfigMap change via watch
3. Operator updates Deployment to trigger pod restart with new ConfigMap data
4. New pod starts with updated run.yaml configuration

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| Kubernetes API Server | REST API | 443/TCP | HTTPS | TLS 1.3 | Resource CRUD, watches, leader election |
| Prometheus Operator | ServiceMonitor | 8443/TCP | HTTPS | TLS 1.2+ | Metrics scraping via ServiceMonitor CRD |
| ODH Dashboard | CRD Management | 443/TCP (k8s API) | HTTPS | TLS 1.3 | UI for creating/managing LlamaStackDistribution CRs |
| vLLM Inference Server | HTTP/gRPC | 8000/TCP | HTTP/gRPC | None | Remote inference backend for Llama Stack |
| Ollama Inference Server | HTTP | 11434/TCP | HTTP | None | Local inference backend for Llama Stack |
| HuggingFace Hub | REST API | 443/TCP | HTTPS | TLS 1.2+ | Model and dataset downloads |
| Container Registry (Quay.io) | Docker Registry API | 443/TCP | HTTPS | TLS 1.2+ | Llama Stack distribution image pulls |
| cert-manager | Certificate CRD | N/A | N/A | N/A | Optional TLS certificate provisioning for user workloads |

## Deployment Configuration

### Kustomize Structure

**Base:** `config/default/kustomization.yaml`
- Namespace: `llama-stack-k8s-operator-system`
- Resources: CRD, RBAC, Deployment, Service, ServiceMonitor

**Overlays:**
- `config/overlays/odh`: ODH-specific configuration (removes namespace creation)
- `config/overlays/rhoai`: RHOAI-specific configuration (removes namespace creation, adds FIPS annotations)

**Manifests Folder:** `config/` (as specified in requirements)
- CRDs: `config/crd/bases/`
- RBAC: `config/rbac/`
- Manager: `config/manager/`
- Prometheus: `config/prometheus/`
- Samples: `config/samples/`

**Controller Manifests:** `controllers/manifests/base/`
- Used at runtime by operator to create Llama Stack resources
- Includes: Deployment, Service, PVC, ServiceAccount, RoleBinding, NetworkPolicy, HPA, PDB

### Environment Variables

**Operator Manager Container:**
- `OPERATOR_VERSION`: Operator version (default: "latest")
- `RELATED_IMAGE_RH_DISTRIBUTION`: Override for Red Hat distribution images

**Llama Stack Container (created by operator):**
- `HF_HOME`: HuggingFace cache directory (set to storage mount path)
- `SSL_CERT_FILE`: Path to CA bundle file (if TLS configured)
- `LLS_WORKERS`: Number of uvicorn workers
- `LLS_PORT`: Server port (default: 8321)
- `LLAMA_STACK_CONFIG`: Path to run.yaml configuration file
- User-provided environment variables from `spec.server.containerSpec.env`

### Resource Defaults

**Operator Pod:**
- CPU Requests: 10m
- Memory Requests: 256Mi
- CPU Limits: 500m
- Memory Limits: 1Gi

**Llama Stack Server Pod (defaults):**
- CPU Requests: 500m (or 1 core per worker if workers configured)
- Memory Requests: 1Gi
- Storage: 10Gi (if persistent storage enabled)

**kube-rbac-proxy Sidecar:**
- CPU Requests: 5m
- Memory Requests: 64Mi
- CPU Limits: 500m
- Memory Limits: 128Mi

## Feature Flags

**Configured via ConfigMap:** `llama-stack-operator-config` in operator namespace

**Available Flags:**
- `enableNetworkPolicy.enabled` (boolean): Enable NetworkPolicy creation for Llama Stack servers (default: false)

**Image Overrides:**
- `image-overrides` (map): Override distribution images by name (e.g., `starter: quay.io/custom/llama-stack:latest`)

## Recent Changes

| Version | Date | Changes |
|---------|------|---------|
| 54ab19b | 2026-03 | - Dependency update: ubi9/ubi-minimal digest to 759f5f4 |
| da65f85 | 2026-03 | - Merge upstream changes for rhoai-3.2 branch<br>- Update versions for 3.2 release |
| c588264 | 2026-02 | - **Feature:** Add support for uvicorn workers for multi-process serving<br>- Improves throughput and concurrency handling |
| b1a7c0d | 2026-02 | - **Feature:** ConfigMap image mapping overrides for Llama Stack distributions<br>- Enables independent security/bug fix patching without operator upgrade |
| 2aa8a32 | 2026-02 | - **Fix:** Operator config ConfigMap watching<br>- Ensures feature flag and image override changes trigger reconciliation |
| 9734b04 | 2026-02 | - **Feature:** Enable multi-arch builds with ARM64 compatibility<br>- Supports ARM-based Kubernetes clusters (e.g., AWS Graviton) |
| 9041847 | 2026-02 | - **Fix:** Set correct operator version on upgrade<br>- Prevents version drift in status.version.operatorVersion |
| a28954e | 2026-02 | - **CI:** Add e2e test validation to release workflow<br>- Ensures release quality with automated end-to-end testing |

**Key Capabilities Added Recently:**
- Uvicorn multi-worker support for production workloads
- ConfigMap-driven image overrides for security patching
- ARM64/multi-architecture support
- Enhanced TLS CA bundle management with auto-detection
- Improved upgrade handling and version tracking

## Operational Considerations

### High Availability
- Operator runs single replica with leader election (ID: `54e06e98.llamastack.io`)
- Llama Stack servers support multiple replicas via `spec.replicas`
- HPA enables automatic scaling based on CPU/memory utilization
- PodDisruptionBudget ensures minimum availability during voluntary disruptions
- Topology spread constraints distribute pods across zones/regions

### Monitoring
- Prometheus metrics exposed via ServiceMonitor
- Llama Stack health probe: `/v1/health` on port 8321
- Operator health probes: `/healthz` (liveness), `/readyz` (readiness) on port 8081
- Status conditions tracked in CRD status field

### Troubleshooting
- Check operator logs: `kubectl logs -n llama-stack-k8s-operator-system deployment/llama-stack-k8s-operator-controller-manager`
- Check Llama Stack pod logs: `kubectl logs -n {namespace} {instance-name}-{pod-id}`
- Verify CRD status: `kubectl get llsd {instance-name} -o yaml`
- Common issues:
  - Image pull failures: Check registry credentials and network connectivity
  - PVC pending: Ensure storage class is available and configured
  - Pod CrashLoopBackOff: Check logs for config errors, missing dependencies, or resource constraints

### Upgrade Path
- Operator upgrades via new Deployment image
- Performs one-time cleanup operations on startup (legacy resource migration)
- Version tracking in `status.version.operatorVersion` and `status.version.llamaStackServerVersion`
- ConfigMap-based image overrides enable Llama Stack updates without operator upgrade

### Backup and Disaster Recovery
- Backup LlamaStackDistribution CRs: `kubectl get llsd -A -o yaml > backup.yaml`
- PersistentVolumeClaims contain downloaded models and datasets
- Use Velero or similar tools for PVC backup
- ConfigMaps for run.yaml should be version-controlled

### Security Best Practices
- Enable NetworkPolicies to restrict ingress traffic
- Use custom CA bundles for mTLS to inference providers
- Store sensitive credentials (HF tokens, API keys) in Secrets, not ConfigMaps
- Implement external authentication/authorization proxy for production Llama Stack APIs
- Regularly update operator and distribution images for security patches
- Audit RBAC permissions and follow principle of least privilege

## Known Limitations
- Llama Stack API does not include built-in authentication (user must implement external auth)
- NetworkPolicy feature is opt-in and disabled by default
- No built-in Ingress/Route creation (manual configuration required for external access)
- PVC resizing requires manual intervention (StatefulSet not used)
- Leader election uses leases in operator namespace (requires coordination.k8s.io API)
- OpenShift requires `anyuid` SCC for proper operation
