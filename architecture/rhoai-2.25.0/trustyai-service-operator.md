# Component: TrustyAI Service Operator

## Metadata
- **Repository**: https://github.com/red-hat-data-services/trustyai-service-operator
- **Version**: d113dae (branch: rhoai-2.25)
- **Distribution**: RHOAI
- **Languages**: Go
- **Deployment Type**: Kubernetes Operator

## Purpose
**Short**: Manages TrustyAI services, LM evaluation jobs, and guardrails orchestrators for AI model explainability, evaluation, and safety.

**Detailed**: The TrustyAI Service Operator is a Kubernetes operator that manages three distinct services within the RHOAI platform: TrustyAI Service for AI explainability and bias detection, LM Eval Jobs for language model evaluation, and Guardrails Orchestrator for AI model safety and content filtering. The operator watches for custom resources in the `trustyai.opendatahub.io` API group and automatically provisions deployments, services, routes, OAuth proxies, and monitoring resources. It integrates with KServe InferenceServices to monitor AI model predictions, supports both PVC and database storage backends, and provides Prometheus metrics scraping through ServiceMonitors. The operator ensures proper RBAC configuration, TLS encryption, and OpenShift Route or Istio VirtualService exposure based on the platform configuration.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| trustyai-service-operator | Kubernetes Operator | Manages TrustyAI service instances, LM evaluation jobs, and guardrails orchestrators |
| TrustyAI Service | AI Explainability Service | Provides model explainability, bias detection, and fairness metrics for ML models |
| LM Eval Job Controller | Job Manager | Orchestrates language model evaluation jobs using lm-evaluation-harness |
| Guardrails Orchestrator | Safety Service | Orchestrates guardrail detectors for AI model input/output filtering |
| OAuth Proxy Sidecars | Authentication Proxy | Provides OpenShift OAuth authentication for service endpoints |
| Prometheus Metrics | Observability | Exposes operator and service metrics for monitoring |

## APIs Exposed

### Custom Resource Definitions (CRDs)

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| trustyai.opendatahub.io | v1 | TrustyAIService | Namespaced | Declarative configuration for TrustyAI explainability service instances |
| trustyai.opendatahub.io | v1alpha1 | TrustyAIService | Namespaced | Legacy version with conversion webhook support |
| trustyai.opendatahub.io | v1alpha1 | LMEvalJob | Namespaced | Language model evaluation job specification using lm-evaluation-harness |
| trustyai.opendatahub.io | v1alpha1 | GuardrailsOrchestrator | Namespaced | Guardrails orchestrator configuration for AI safety detectors |

### HTTP Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /healthz | GET | 8081/TCP | HTTP | None | None | Operator liveness probe |
| /readyz | GET | 8081/TCP | HTTP | None | None | Operator readiness probe |
| /metrics | GET | 8443/TCP | HTTPS | TLS 1.2+ | Bearer Token | Operator Prometheus metrics (via kube-rbac-proxy) |
| /q/metrics | GET | 8080/TCP | HTTP | None | None | TrustyAI Service Prometheus metrics (internal) |
| / | ALL | 80/TCP | HTTP | None | Internal | TrustyAI Service API (internal, redirected to HTTPS) |
| / | ALL | 443/TCP | HTTPS | TLS 1.2+ | Internal | TrustyAI Service API (internal with service-ca cert) |
| / | ALL | 443/TCP | HTTPS | TLS 1.2+ | OAuth Proxy | TrustyAI Service API (OAuth-protected endpoint) |
| /oauth/healthz | GET | 8443/TCP | HTTPS | TLS 1.2+ | None | OAuth Proxy health check |
| /apis/v1beta1/healthz | GET | 8032-8432/TCP | HTTP/HTTPS | TLS 1.2+ | None | Guardrails Orchestrator health (auth bypass) |
| / | ALL | 8090-8490/TCP | HTTP/HTTPS | TLS 1.2+ | OAuth (conditional) | Guardrails gateway endpoint |

### gRPC Services

| Service | Port | Protocol | Encryption | Auth | Purpose |
|---------|------|----------|------------|------|---------|
| N/A | N/A | N/A | N/A | N/A | No gRPC services exposed |

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| Kubernetes/OpenShift | 1.19+/4.6+ | Yes | Platform runtime for operator and managed services |
| Prometheus Operator | N/A | No | ServiceMonitor support for metrics scraping |
| OpenShift OAuth | N/A | No | User authentication for service endpoints (OpenShift only) |
| Istio Service Mesh | N/A | No | VirtualService and DestinationRule support for KServe serverless mode |
| Cert Manager | N/A | No | TLS certificate provisioning (alternative to service-ca) |
| Kueue | v0.6+ | No | Workload queue management for LM evaluation jobs |
| PostgreSQL/MySQL | N/A | No | Database backend for TrustyAI Service storage (alternative to PVC) |

### Internal ODH Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| KServe | CRD Watch/Patch | Monitors InferenceService resources for model serving integration |
| Model Mesh | Pod Exec/ConfigMap | Configures payload processors for ModelMesh-served models |
| Data Science Pipelines | PVC | Shares persistent volume claims for data storage |
| ODH Dashboard | CRD Creation | Users create TrustyAI services through dashboard UI |

## Network Architecture

### Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| controller-manager-metrics-service | ClusterIP | 8443/TCP | 8443 | HTTPS | TLS 1.2+ | Bearer Token | Internal |
| {trustyai-service-name} | ClusterIP | 80/TCP | 8080 | HTTP | None | None | Internal |
| {trustyai-service-name} | ClusterIP | 443/TCP | 4443 | HTTPS | TLS (service-ca) | None | Internal |
| {trustyai-service-name}-tls | ClusterIP | 443/TCP | 8443 | HTTPS | TLS (service-ca) | OAuth Proxy | Internal |
| {orchestrator-name}-service | ClusterIP | 8032-8432/TCP | 8032-8432 | HTTPS | TLS (service-ca) | OAuth (conditional) | Internal |
| {orchestrator-name}-service | ClusterIP | 8090-8490/TCP | 8090-8490 | HTTP/HTTPS | TLS (conditional) | OAuth (conditional) | Internal |
| {orchestrator-name}-service | ClusterIP | 8034/TCP | 8034 | HTTP | None | None | Internal |

### Ingress

| Name | Type | Hosts | Port | Protocol | Encryption | TLS Mode | Exposure |
|------|------|-------|------|----------|------------|----------|----------|
| {trustyai-service-name} | OpenShift Route | route-{namespace}.apps.{cluster} | 443/TCP | HTTPS | TLS 1.2+ | Reencrypt | External |
| {trustyai-service-name}-vs | Istio VirtualService | {name}.{namespace}.svc.cluster.local | 443/TCP | HTTPS | TLS 1.2+ | SIMPLE | Internal |
| {orchestrator-name}-https | OpenShift Route | route-{namespace}.apps.{cluster} | 443/TCP | HTTPS | TLS 1.2+ | Reencrypt | External |
| {orchestrator-name}-gateway | OpenShift Route | route-{namespace}.apps.{cluster} | 443/TCP | HTTPS | TLS 1.2+ | Reencrypt | External |
| {orchestrator-name}-health | OpenShift Route | route-{namespace}.apps.{cluster} | 443/TCP | HTTPS | TLS 1.2+ | Reencrypt | External |

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| KServe InferenceService | 80-443/TCP | HTTP/HTTPS | TLS 1.2+ (conditional) | None/Bearer Token | Model prediction monitoring and payload injection |
| PostgreSQL/MySQL Database | 5432/3306/TCP | PostgreSQL/MySQL | TLS 1.2+ (conditional) | Username/Password | TrustyAI Service data persistence |
| S3-compatible Storage | 443/TCP | HTTPS | TLS 1.2+ | AWS IAM/Access Key | LM Eval Job result storage |
| Kueue API Server | 6443/TCP | HTTPS | TLS 1.3 | Service Account Token | Workload admission for LM evaluation jobs |
| Hugging Face Hub | 443/TCP | HTTPS | TLS 1.2+ | API Token (optional) | Download models and datasets for LM evaluation |

## Security

### RBAC - Cluster Roles

| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|
| manager-role | "" | configmaps, persistentvolumeclaims, pods, secrets, services | create, delete, get, list, patch, update, watch |
| manager-role | "" | events | create, patch, update, watch |
| manager-role | "" | persistentvolumes | get, list, watch |
| manager-role | "" | pods/exec | create, delete, get, list, watch |
| manager-role | "" | serviceaccounts | create, delete, get, list, update, watch |
| manager-role | apps | deployments | create, delete, get, list, patch, update, watch |
| manager-role | apps | deployments/finalizers, deployments/status | get, patch, update |
| manager-role | coordination.k8s.io | leases | create, get, update |
| manager-role | monitoring.coreos.com | servicemonitors | create, list, watch |
| manager-role | networking.istio.io | destinationrules, virtualservices | create, delete, get, list, patch, update, watch |
| manager-role | route.openshift.io | routes | create, delete, get, list, patch, update, watch |
| manager-role | serving.kserve.io | inferenceservices | get, list, patch, update, watch |
| manager-role | serving.kserve.io | inferenceservices/finalizers | delete, get, list, patch, update, watch |
| manager-role | serving.kserve.io | servingruntimes | get, list, watch |
| manager-role | trustyai.opendatahub.io | guardrailsorchestrators, lmevaljobs, trustyaiservices | create, delete, get, list, patch, update, watch |
| manager-role | trustyai.opendatahub.io | guardrailsorchestrators/finalizers, lmevaljobs/finalizers, trustyaiservices/finalizers | update |
| manager-role | trustyai.opendatahub.io | guardrailsorchestrators/status, lmevaljobs/status, trustyaiservices/status | get, patch, update |
| manager-role | kueue.x-k8s.io | workloads | create, delete, get, list, patch, update, watch |
| manager-role | kueue.x-k8s.io | workloads/finalizers, workloads/status | get, patch, update |
| manager-role | kueue.x-k8s.io | resourceflavors, workloadpriorityclasses | get, list, watch |
| manager-role | rbac.authorization.k8s.io | clusterrolebindings | create, delete, get, list, update, watch |
| manager-role | apiextensions.k8s.io | customresourcedefinitions | get, list, watch |
| manager-role | scheduling.k8s.io | priorityclasses | get, list, watch |
| leader-election-role | "" | configmaps | get, list, watch, create, update, patch, delete |
| leader-election-role | coordination.k8s.io | leases | get, list, watch, create, update, patch, delete |
| leader-election-role | "" | events | create, patch |
| non-admin-lmeval-role | trustyai.opendatahub.io | lmevaljobs | create, delete, get, list, patch, update, watch |

### RBAC - Role Bindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| leader-election-rolebinding | system | leader-election-role | controller-manager |
| manager-rolebinding | system | manager-role | controller-manager |
| auth-proxy-rolebinding | system | auth-proxy-role | controller-manager |
| default-lmeval-user-rolebinding | system | non-admin-lmeval-role | default (all users) |

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| {trustyai-service-name}-internal | kubernetes.io/tls | TLS certificate for internal HTTPS service | OpenShift service-ca | Yes |
| {trustyai-service-name}-tls | kubernetes.io/tls | TLS certificate for OAuth proxy service | OpenShift service-ca | Yes |
| {trustyai-service-name}-db-credentials | Opaque | Database connection credentials (username, password, host, port, name) | User-provided | No |
| {orchestrator-name}-tls | kubernetes.io/tls | TLS certificate for guardrails orchestrator service | OpenShift service-ca | Yes |
| webhook-server-cert | kubernetes.io/tls | TLS certificate for conversion webhook server | cert-manager | Yes |

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| TrustyAI Service (Route) | ALL | OpenShift OAuth (Bearer Token) | OAuth Proxy Sidecar | OpenShift SAR: namespace pods get |
| TrustyAI Service (Internal) | ALL | None (internal only) | Service Network | ClusterIP internal traffic |
| Guardrails Orchestrator (Route) | ALL | OpenShift OAuth (Bearer Token) | OAuth Proxy Sidecar | OpenShift SAR: namespace pods get |
| Guardrails Health Endpoint | GET | None (bypass via skip-auth-regex) | OAuth Proxy Sidecar | Public health check |
| Operator Metrics | GET | Kubernetes Service Account Token | kube-rbac-proxy | RBAC: read metrics endpoint |
| LMEvalJob Creation | CREATE | Kubernetes RBAC | API Server | ClusterRole: non-admin-lmeval-role |

## Data Flows

### Flow 1: TrustyAI Service Model Prediction Monitoring

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User/Application | KServe InferenceService | 443/TCP | HTTPS | TLS 1.2+ | Bearer Token |
| 2 | KServe InferenceService | TrustyAI Service (ModelMesh Payload Processor) | 80-443/TCP | HTTP/HTTPS | TLS (conditional) | None |
| 3 | TrustyAI Service | PVC Storage or Database | N/A or 5432/3306/TCP | Filesystem or PostgreSQL/MySQL | None or TLS 1.2+ | Filesystem or DB Credentials |
| 4 | Prometheus | TrustyAI Service | 80/TCP | HTTP | None | None |
| 5 | Prometheus | TrustyAI Service Metrics | 8080/TCP | HTTP | None | None |

### Flow 2: LM Evaluation Job Execution

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User | Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.3 | Bearer Token |
| 2 | LMEvalJob Controller | Kueue API Server | 6443/TCP | HTTPS | TLS 1.3 | Service Account Token |
| 3 | Kueue | Kubernetes Scheduler | 6443/TCP | HTTPS | TLS 1.3 | Service Account Token |
| 4 | LMES Pod | Hugging Face Hub | 443/TCP | HTTPS | TLS 1.2+ | API Token (optional) |
| 5 | LMES Pod | KServe InferenceService | 443/TCP | HTTPS | TLS 1.2+ | Bearer Token |
| 6 | LMES Pod | S3-compatible Storage | 443/TCP | HTTPS | TLS 1.2+ | AWS IAM/Access Key |

### Flow 3: Guardrails Orchestrator Request Processing

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | External Client | OpenShift Route | 443/TCP | HTTPS | TLS 1.2+ | OAuth Redirect |
| 2 | OpenShift Route | OAuth Proxy Sidecar | 8443/TCP | HTTPS | TLS 1.2+ | Bearer Token |
| 3 | OAuth Proxy | Guardrails Orchestrator | 8032/TCP | HTTPS | TLS (service-ca) | Forwarded Bearer |
| 4 | Guardrails Orchestrator | Detector InferenceService | 443/TCP | HTTPS | TLS 1.2+ | Bearer Token |
| 5 | Guardrails Orchestrator | Generator InferenceService | 443/TCP | HTTPS | TLS 1.2+ | Bearer Token |

### Flow 4: Operator Reconciliation

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Kubernetes API Server | Operator Manager | N/A | Watch Stream | TLS 1.3 | Service Account Token |
| 2 | Operator Manager | Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.3 | Service Account Token |
| 3 | Operator Manager | Kubernetes API Server (Create/Update Resources) | 6443/TCP | HTTPS | TLS 1.3 | Service Account Token |

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| KServe InferenceService | CRD Watch/Patch | 6443/TCP | HTTPS | TLS 1.3 | Monitor and configure inference services for explainability |
| ModelMesh Serving | Pod Exec | 8033/TCP | gRPC | mTLS | Inject payload processors for model monitoring |
| Prometheus | ServiceMonitor | 8080/TCP | HTTP | None | Scrape TrustyAI and operator metrics |
| OpenShift Router | Route | 443/TCP | HTTPS | TLS 1.2+ | External access to TrustyAI services |
| Istio Service Mesh | VirtualService/DestinationRule | 443/TCP | HTTPS | TLS 1.2+ | Traffic routing for KServe serverless mode |
| Kueue | Workload CRD | 6443/TCP | HTTPS | TLS 1.3 | Queue management for LM evaluation jobs |
| S3-compatible Storage | S3 API | 443/TCP | HTTPS | TLS 1.2+ | Store LM evaluation results |
| PostgreSQL/MySQL | Database Connection | 5432/3306/TCP | PostgreSQL/MySQL | TLS 1.2+ (conditional) | TrustyAI Service persistent storage |

## Recent Changes

| Version | Date | Changes |
|---------|------|---------|
| d113dae | 2026-03 | - Sync pipelineruns with konflux-central - 19bdad4 |
| 86c4e9b | 2026-03 | - Sync pipelineruns with konflux-central - e68c3cf |
| 1570f80 | 2026-03 | - Sync pipelineruns with konflux-central - 07ea5e7 |
| afff627 | 2026-03 | - Sync pipelineruns with konflux-central - 2ebf2ad |
| ab250a3 | 2026-03 | - Sync pipelineruns with konflux-central - 64394fa |
| b765f0c | 2026-03 | - Sync pipelineruns with konflux-central - 8ea3217 |
| 8638be3 | 2026-03 | - Sync pipelineruns with konflux-central - bdabac2 |

## Deployment Configuration

### Container Images

| Image Name | Registry | Build Method | Purpose |
|------------|----------|--------------|---------|
| odh-trustyai-service-operator | quay.io/trustyai | Konflux (Dockerfile.konflux) | Operator controller manager |
| trustyai-service | quay.io/trustyai | External | TrustyAI explainability service runtime |
| ta-lmes-job | quay.io/trustyai | External | LM evaluation job execution pod |
| ta-lmes-driver | quay.io/trustyai | Konflux (Dockerfile.konflux.driver) | LM evaluation job driver |
| guardrails-orchestrator | quay.io/trustyai | Konflux (Dockerfile.orchestrator) | Guardrails orchestration service |
| ose-oauth-proxy | registry.redhat.io/openshift4 | External | OpenShift OAuth authentication proxy |

### Kustomize Overlays

| Overlay | Purpose |
|---------|---------|
| config/overlays/odh | OpenDataHub distribution configuration |
| config/overlays/rhoai | RHOAI distribution configuration |
| config/overlays/lmes | LMES-only deployment configuration |
| config/overlays/odh-kueue | ODH with Kueue integration |
| config/overlays/testing | Testing environment with custom image pull policy |

### Resource Requirements

| Component | CPU Request | CPU Limit | Memory Request | Memory Limit |
|-----------|-------------|-----------|----------------|--------------|
| Operator Manager | 10m | 900m | 64Mi | 700Mi |
| TrustyAI Service | configurable | configurable | configurable | configurable |
| OAuth Proxy | 100m | 100m | 64Mi | 64Mi |
| Guardrails Orchestrator | configurable | configurable | configurable | configurable |

## Observability

### Metrics Endpoints

| Endpoint | Port | Path | Scheme | Purpose |
|----------|------|------|--------|---------|
| Operator Metrics | 8443/TCP | /metrics | HTTPS | Operator controller metrics (controller-runtime) |
| TrustyAI Service Metrics | 8080/TCP | /q/metrics | HTTP | Service business metrics (Quarkus/Prometheus) |

### Health Checks

| Component | Endpoint | Port | Type | Purpose |
|-----------|----------|------|------|---------|
| Operator | /healthz | 8081/TCP | Liveness | Operator health status |
| Operator | /readyz | 8081/TCP | Readiness | Operator ready to reconcile |
| OAuth Proxy | /oauth/healthz | 8443/TCP | Liveness/Readiness | OAuth proxy health |
| Guardrails Orchestrator | /apis/v1beta1/healthz | 8034/TCP | Liveness/Readiness | Orchestrator health |

### ServiceMonitors

| Name | Namespace | Port | Path | Purpose |
|------|-----------|------|------|---------|
| controller-manager-metrics-monitor | system | https | /metrics | Operator metrics collection |
| trustyai-metrics | {instance-namespace} | http | /q/metrics | TrustyAI service metrics collection |
