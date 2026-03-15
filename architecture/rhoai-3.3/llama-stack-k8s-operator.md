# Component: Llama Stack Operator

## Metadata
- **Repository**: https://github.com/red-hat-data-services/llama-stack-k8s-operator
- **Version**: v0.6.0 (rhoai-3.3 branch, commit 7167419)
- **Distribution**: RHOAI
- **Languages**: Go 1.24.6
- **Deployment Type**: Kubernetes Operator

## Purpose
**Short**: Kubernetes operator that creates and manages Llama Stack server deployments.

**Detailed**: The Llama Stack Operator is a Kubernetes operator responsible for automating the deployment and lifecycle management of Llama Stack servers on Kubernetes clusters. It provides declarative configuration through Custom Resource Definitions (CRDs), enabling users to deploy Meta's Llama Stack with various distributions including Ollama, vLLM, and other inference providers. The operator handles deployment, scaling, persistence, network policies, and integration with external inference services. It supports multiple deployment configurations (starter, remote-vllm, meta-reference-gpu, postgres-demo) and provides advanced features like autoscaling, pod disruption budgets, topology spread constraints, and optional network isolation through NetworkPolicy resources.

The operator integrates deeply with the RHOAI/ODH ecosystem, deploying into the `redhat-ods-applications` namespace and providing configuration-driven image overrides for independent security patching. It watches ConfigMaps for dynamic configuration updates and automatically restarts pods when configuration changes are detected.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| Controller Manager | Deployment | Main operator process that reconciles LlamaStackDistribution CRs |
| LlamaStackDistribution Controller | Reconciler | Manages lifecycle of Llama Stack server deployments |
| Metrics Service | Service | Exposes Prometheus metrics for monitoring |
| Health Probes | HTTP Endpoints | Provides liveness and readiness checks |
| Kustomize Engine | In-Process Library | Renders Kubernetes manifests from templates |
| ConfigMap Watcher | Controller Watch | Triggers reconciliation on ConfigMap changes |
| NetworkPolicy Manager | Reconciler | Creates/deletes NetworkPolicy resources based on feature flags |

## APIs Exposed

### Custom Resource Definitions (CRDs)

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| llamastack.io | v1alpha1 | LlamaStackDistribution | Namespaced | Declarative configuration for deploying and managing Llama Stack servers with inference providers |

### HTTP Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /metrics | GET | 8443/TCP | HTTPS | TLS | Bearer Token | Prometheus metrics endpoint for operator monitoring |
| /healthz | GET | 8081/TCP | HTTP | None | None | Liveness probe for operator health |
| /readyz | GET | 8081/TCP | HTTP | None | None | Readiness probe for operator availability |

### Managed Services (Created by Operator)

| Service Name | Port | Protocol | Encryption | Purpose |
|--------------|------|----------|------------|---------|
| {instance-name}-service | 8321/TCP | HTTP | Optional TLS | Llama Stack server API endpoint |

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| Kubernetes | 1.20+ | Yes | Runtime platform for operator and managed workloads |
| controller-runtime | v0.22.4 | Yes | Kubernetes operator framework |
| kustomize | v0.21.0 | Yes | Manifest templating and customization |
| Prometheus Operator | N/A | No | Metrics collection via ServiceMonitor |
| Ingress Controller | N/A | No | External access when exposeRoute is enabled |

### Internal ODH/RHOAI Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| Ollama | HTTP API | Inference provider for Llama models (port 11434/TCP) |
| vLLM | HTTP API | GPU-accelerated inference provider |
| odh-trusted-ca-bundle | ConfigMap | Trusted CA certificates for TLS verification |
| ServiceMesh (Optional) | Istio Integration | Service mesh support for advanced networking |

## Network Architecture

### Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| controller-manager-metrics-service | ClusterIP | 8443/TCP | https | HTTPS | TLS | Bearer Token (ServiceAccount) | Internal |
| {instance-name}-service | ClusterIP | 8321/TCP | 8321 | HTTP/HTTPS | Optional TLS 1.3 | None/Custom | Internal |

### Ingress

| Name | Type | Hosts | Port | Protocol | Encryption | TLS Mode | Exposure |
|------|------|-------|------|----------|------------|----------|----------|
| {instance-name}-ingress | Ingress | Dynamic | 80/TCP, 443/TCP | HTTP/HTTPS | Optional TLS 1.2+ | SIMPLE | External (when exposeRoute: true) |

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token | CR reconciliation, resource management |
| Ollama Server | 11434/TCP | HTTP | None | None | Model inference requests |
| vLLM Server | 8000/TCP | HTTP/HTTPS | Optional TLS | Optional Token | Model inference requests |
| HuggingFace Hub | 443/TCP | HTTPS | TLS 1.2+ | Token | Model downloads for vLLM |
| Container Registry | 443/TCP | HTTPS | TLS 1.2+ | Pull Secret | Pull distribution container images |

### Network Policies (Optional Feature)

| Policy Name | Type | Purpose |
|-------------|------|---------|
| {instance-name}-netpol | NetworkPolicy | Ingress-only policy restricting access to same namespace, operator namespace, and configured allowed namespaces |

## Security

### RBAC - Cluster Roles

| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|
| manager-role | "" | configmaps, persistentvolumeclaims, serviceaccounts, services | create, delete, get, list, patch, update, watch |
| manager-role | apps | deployments | create, delete, get, list, patch, update, watch |
| manager-role | autoscaling | horizontalpodautoscalers | create, delete, get, list, patch, update, watch |
| manager-role | llamastack.io | llamastackdistributions | create, delete, get, list, patch, update, watch |
| manager-role | llamastack.io | llamastackdistributions/finalizers | update |
| manager-role | llamastack.io | llamastackdistributions/status | get, patch, update |
| manager-role | networking.k8s.io | ingresses, networkpolicies | create, delete, get, list, patch, update, watch |
| manager-role | policy | poddisruptionbudgets | create, delete, get, list, patch, update, watch |
| manager-role | rbac.authorization.k8s.io | clusterroles | get, list, watch |
| manager-role | rbac.authorization.k8s.io | clusterrolebindings | delete, get, list |
| manager-role | rbac.authorization.k8s.io | rolebindings | create, delete, get, list, patch, update, watch |
| manager-role | security.openshift.io | securitycontextconstraints | use |
| manager-role | security.openshift.io (anyuid) | securitycontextconstraints | use |
| auth-proxy-role | authentication.k8s.io | tokenreviews | create |
| auth-proxy-role | authorization.k8s.io | subjectaccessreviews | create |
| leader-election-role | "" | configmaps, events | create, get, list, patch, update, watch, delete |
| leader-election-role | coordination.k8s.io | leases | create, get, list, patch, update, watch, delete |

### RBAC - Role Bindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| manager-rolebinding | cluster-wide | manager-role (ClusterRole) | controller-manager |
| auth-proxy-rolebinding | operator namespace | auth-proxy-role (ClusterRole) | controller-manager |
| leader-election-rolebinding | operator namespace | leader-election-role (Role) | controller-manager |

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| hf-token-secret | Opaque | HuggingFace API token for model downloads (vLLM) | User | No |
| {instance-name}-tls | kubernetes.io/tls | Optional TLS certificates for Llama Stack server | User/cert-manager | Depends on provisioner |
| controller-manager-token | kubernetes.io/service-account-token | ServiceAccount token for Kubernetes API access | Kubernetes | Yes |

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| /metrics | GET | Bearer Token (ServiceAccount JWT) | kube-rbac-proxy | Requires auth-proxy-client ClusterRole |
| /healthz, /readyz | GET | None | Operator | Public health checks |
| Llama Stack API (8321/TCP) | GET, POST | None (Default) | Application | User-configurable via NetworkPolicy |

### Container Security

| Feature | Value | Purpose |
|---------|-------|---------|
| Run as Non-Root | true | Security best practice |
| Privilege Escalation | false | Prevent container breakout |
| Drop Capabilities | ALL | Minimal privilege principle |
| Read-Only Root Filesystem | false | Operator needs write access for temp files |
| SELinux | Enforcing | RHEL/OpenShift default security context |
| SecurityContextConstraints | anyuid | Required for certain Llama Stack distributions |

## Data Flows

### Flow 1: LlamaStackDistribution Creation

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User/CI | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | kubeconfig credentials |
| 2 | Kubernetes API | Operator Controller | In-Process | N/A | N/A | Watch notification |
| 3 | Operator Controller | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 4 | Operator Controller | Kustomize Engine | In-Process | N/A | N/A | N/A |
| 5 | Operator Controller | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |

### Flow 2: Metrics Collection

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Prometheus | kube-rbac-proxy | 8443/TCP | HTTPS | TLS | Bearer Token |
| 2 | kube-rbac-proxy | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | Token Review |
| 3 | kube-rbac-proxy | Operator Metrics | 8080/TCP | HTTP | None | Proxied |

### Flow 3: Llama Stack Inference Request

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Client Application | Llama Stack Service | 8321/TCP | HTTP/HTTPS | Optional TLS 1.3 | None/Custom |
| 2 | Llama Stack Pod | Ollama/vLLM Service | 11434/TCP or 8000/TCP | HTTP/HTTPS | Optional TLS | Optional Token |
| 3 | Ollama/vLLM | GPU/CPU | N/A | In-Process | N/A | N/A |
| 4 | Ollama/vLLM | Llama Stack Pod | 11434/TCP or 8000/TCP | HTTP/HTTPS | Optional TLS | Response |
| 5 | Llama Stack Service | Client Application | 8321/TCP | HTTP/HTTPS | Optional TLS 1.3 | Response |

### Flow 4: ConfigMap Update and Pod Restart

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User/CI | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | kubeconfig credentials |
| 2 | Kubernetes API | Operator Controller | In-Process | N/A | N/A | Watch notification |
| 3 | Operator Controller | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 4 | Operator Controller | Deployment | In-Process | N/A | N/A | Update pod template annotations |
| 5 | Kubernetes | Llama Stack Pods | N/A | N/A | N/A | Rolling restart |

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| Kubernetes API | REST API | 6443/TCP | HTTPS | TLS 1.2+ | Resource CRUD operations, watching |
| Prometheus | ServiceMonitor | 8443/TCP | HTTPS | TLS | Metrics scraping for operator health |
| Ollama Server | HTTP API | 11434/TCP | HTTP | None | Inference provider for starter distribution |
| vLLM Server | HTTP API | 8000/TCP | HTTP/HTTPS | Optional TLS | GPU-accelerated inference provider |
| HuggingFace Hub | HTTPS API | 443/TCP | HTTPS | TLS 1.2+ | Model downloads (vLLM with hf-token-secret) |
| Container Registry | HTTPS API | 443/TCP | HTTPS | TLS 1.2+ | Pull Llama Stack distribution images |
| odh-trusted-ca-bundle | ConfigMap | N/A | N/A | N/A | Trusted CA certificates for TLS verification |
| Ingress Controller | Ingress Resource | 80/TCP, 443/TCP | HTTP/HTTPS | Optional TLS | External exposure when exposeRoute: true |

## Deployment Architecture

### Operator Deployment

| Property | Value |
|----------|-------|
| Namespace | redhat-ods-applications (RHOAI) |
| Replicas | 1 |
| Leader Election | Enabled (lease-based) |
| Resource Requests | CPU: 10m, Memory: 256Mi |
| Resource Limits | CPU: 500m, Memory: 1Gi |
| Security Context | runAsNonRoot: true, allowPrivilegeEscalation: false |
| Topology Spread | zone and hostname spreading with ScheduleAnyway |

### Managed Llama Stack Deployment

| Property | Default Value | Configurable |
|----------|---------------|--------------|
| Replicas | 1 | Yes (spec.replicas) |
| Container Port | 8321/TCP | Yes (spec.server.containerSpec.port) |
| CPU Request | 500m (or workers count) | Yes (spec.server.containerSpec.resources) |
| Memory Request | 1Gi | Yes (spec.server.containerSpec.resources) |
| Storage Size | 10Gi | Yes (spec.server.storage.size) |
| Storage Mount Path | /opt/app-root/src/.llama/distributions/rh/ | Yes (spec.server.storage.mountPath) |
| Autoscaling | Disabled | Yes (spec.server.autoscaling) |
| Workers (uvicorn) | Not set | Yes (spec.server.workers) |

## Feature Flags

The operator supports dynamic configuration via ConfigMap (`llama-stack-operator-config` in operator namespace):

| Feature Flag | Default | Purpose |
|--------------|---------|---------|
| enableNetworkPolicy.enabled | false | Enable/disable NetworkPolicy creation for LlamaStackDistribution instances |
| image-overrides.{distribution} | N/A | Override default distribution images for independent patching |

## Recent Changes

| Version | Date | Changes |
|---------|------|---------|
| 7167419 | 2026-03-11 | - Update UBI9 minimal base image to digest 69f5c98<br>- Dependency security updates |
| 184c487 | 2026-03-04 | - Sync Konflux CI/CD pipeline configurations |
| f897b43 | 2026-02-06 | - Merge RHDS 3.3 branch updates<br>- Fix CA bundle volume conflict during operator upgrade |
| 7126cab | 2026-01-22 | - Fix NetworkPolicy to remove pod selectors<br>- Improve namespace-based access control |
| 5eeae04 | 2026-01-16 | - Update default feature flags for RHOAI 3.3<br>- NetworkPolicy enabled by default in 3.3 |
| a746efe | 2026-01-15 | - Update versions for RHOAI 3.3 release<br>- Llama Stack v0.4.2, Operator v0.6.0 |

## Configuration Options

### Distribution Types

| Distribution | Image | Purpose |
|--------------|-------|---------|
| starter | docker.io/llamastack/distribution-starter:latest | Basic Llama Stack with Ollama integration |
| remote-vllm | docker.io/llamastack/distribution-remote-vllm:latest | vLLM-based GPU inference |
| meta-reference-gpu | docker.io/llamastack/distribution-meta-reference-gpu:latest | Meta's reference GPU implementation |
| postgres-demo | docker.io/llamastack/distribution-postgres-demo:latest | Demo with PostgreSQL backend |

### Network Access Control

| Option | Default | Purpose |
|--------|---------|---------|
| spec.network.exposeRoute | false | Create Ingress for external access |
| spec.network.allowedFrom.namespaces | [] | Explicit namespace names for NetworkPolicy |
| spec.network.allowedFrom.labels | [] | Namespace label keys for NetworkPolicy |

### Advanced Features

| Feature | Configuration Path | Purpose |
|---------|-------------------|---------|
| Autoscaling | spec.server.autoscaling | HorizontalPodAutoscaler with CPU/memory targets |
| Pod Disruption Budget | spec.server.podDisruptionBudget | Voluntary disruption protection |
| Topology Spread | spec.server.topologySpreadConstraints | Fine-grained pod distribution |
| Workers | spec.server.workers | Uvicorn worker processes for parallelism |
| User Config | spec.server.userConfig.configMapName | Custom Llama Stack configuration |
| CA Bundle | spec.server.tlsConfig.caBundle.configMapName | Custom CA certificates for TLS |

## Monitoring and Observability

### Metrics Exposed

| Metric Type | Example | Purpose |
|-------------|---------|---------|
| controller_runtime_reconcile_total | Counter | Total reconciliation attempts |
| controller_runtime_reconcile_errors_total | Counter | Failed reconciliations |
| controller_runtime_reconcile_time_seconds | Histogram | Reconciliation duration |
| workqueue_depth | Gauge | Work queue depth |
| workqueue_adds_total | Counter | Total items added to queue |

### Health Checks

| Endpoint | Port | Type | Purpose |
|----------|------|------|---------|
| /healthz | 8081/TCP | Liveness | Operator process health |
| /readyz | 8081/TCP | Readiness | Operator ready to reconcile |

### Logging

| Component | Level | Format |
|-----------|-------|--------|
| Controller | Info | JSON (zap logger) |
| Reconciler | Info/Debug | JSON with context |

## Upgrade Considerations

### Operator Upgrades

- Operator uses leader election for zero-downtime upgrades
- ConfigMap changes trigger automatic reconciliation
- Image overrides allow independent distribution patching
- Upgrade cleanup handles legacy resources (CA bundle volume conflicts fixed in 7167419)

### Breaking Changes

- NetworkPolicy feature flag defaults changed in RHOAI 3.3 (now enabled by default)
- CA bundle configuration structure may require migration for pre-3.3 installations

## Troubleshooting

### Common Issues

| Issue | Symptoms | Resolution |
|-------|----------|------------|
| Pod not starting | Pending phase | Check PVC provisioning, node resources |
| Inference failure | 500/503 errors | Verify Ollama/vLLM service connectivity |
| NetworkPolicy blocking | Connection refused | Review allowedFrom configuration |
| ConfigMap not updating | Stale configuration | Verify ConfigMap watch and pod annotations |
| Image pull failure | ImagePullBackOff | Check image-overrides and registry access |

### Debug Commands

```bash
# Check operator logs
kubectl logs -n redhat-ods-applications deployment/controller-manager

# Check LlamaStackDistribution status
kubectl get llsd -A -o yaml

# Check managed resources
kubectl get deployment,service,networkpolicy,ingress -l app.kubernetes.io/managed-by=llama-stack-operator

# Check feature flags
kubectl get configmap llama-stack-operator-config -n redhat-ods-applications -o yaml

# Check metrics
kubectl port-forward -n redhat-ods-applications svc/controller-manager-metrics-service 8443:8443
curl -k https://localhost:8443/metrics
```

## References

- **Llama Stack Project**: https://github.com/meta-llama/llama-stack
- **Llama Stack Distribution (ODH)**: https://github.com/opendatahub-io/llama-stack-distribution
- **Operator Source**: https://github.com/opendatahub-io/llama-stack-k8s-operator
- **RHOAI Source**: https://github.com/red-hat-data-services/llama-stack-k8s-operator
- **Kubebuilder**: https://book.kubebuilder.io/
- **Controller Runtime**: https://github.com/kubernetes-sigs/controller-runtime
