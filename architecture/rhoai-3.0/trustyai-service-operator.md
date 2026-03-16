# Component: TrustyAI Service Operator

## Metadata
- **Repository**: https://github.com/red-hat-data-services/trustyai-service-operator.git
- **Version**: 1.39.0
- **Distribution**: RHOAI
- **Languages**: Go
- **Deployment Type**: Kubernetes Operator

## Purpose
**Short**: Kubernetes operator managing TrustyAI explainability services, LM evaluation jobs, and AI guardrails orchestration.

**Detailed**: The TrustyAI Service Operator is a Kubernetes operator that automates the deployment and lifecycle management of three key AI governance components: TrustyAI explainability services for model transparency, LM Evaluation Jobs (LMES) for language model assessment, and Guardrails Orchestrators (GORCH) for AI safety controls. Built using the Kubebuilder framework, it provides custom resource definitions (CRDs) enabling declarative management of TrustyAI infrastructure.

The operator watches for TrustyAIService, LMEvalJob, and GuardrailsOrchestrator custom resources and automatically provisions corresponding deployments, services, persistent storage, monitoring configurations, and network policies. It integrates with KServe for inference service management, Istio service mesh for traffic control, Prometheus for metrics collection, and optionally Kueue for job scheduling. The operator supports both PVC-based and database-backed storage for TrustyAI services, provides OAuth proxy integration for secured access, and manages TLS certificates for encrypted communications.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| trustyai-service-operator | Operator Controller | Reconciles TrustyAIService, LMEvalJob, and GuardrailsOrchestrator CRs |
| TrustyAI Service | Managed Deployment | Provides explainability and bias detection for ML models |
| LM Evaluation Job | Batch Job | Executes language model evaluation tasks |
| Guardrails Orchestrator | Managed Deployment | Coordinates AI safety guardrails for inference services |
| LMES Driver | Sidecar Container | Manages LM evaluation job execution lifecycle |
| Built-in Detector | Sidecar Container | Provides guardrails detection capabilities |
| Kube-RBAC-Proxy | Sidecar Container | Provides authentication/authorization for service endpoints |

## APIs Exposed

### Custom Resource Definitions (CRDs)

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| trustyai.opendatahub.io | v1 | TrustyAIService | Namespaced | Manages TrustyAI explainability service deployments with storage, metrics, and data configurations |
| trustyai.opendatahub.io | v1alpha1 | TrustyAIService | Namespaced | Legacy version with conversion support to v1 |
| trustyai.opendatahub.io | v1alpha1 | LMEvalJob | Namespaced | Defines language model evaluation jobs with model, tasks, and execution parameters |
| trustyai.opendatahub.io | v1alpha1 | GuardrailsOrchestrator | Namespaced | Configures AI guardrails orchestration with detectors and gateway settings |

### HTTP Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /healthz | GET | 8081/TCP | HTTP | None | None | Operator liveness probe endpoint |
| /readyz | GET | 8081/TCP | HTTP | None | None | Operator readiness probe endpoint |
| /q/metrics | GET | 80/TCP | HTTP | None | None | TrustyAI service Prometheus metrics (internal) |
| /q/health/ready | GET | 8080/TCP | HTTP | None | None | TrustyAI service readiness probe |
| /q/health/live | GET | 8080/TCP | HTTP | None | None | TrustyAI service liveness probe |
| /* | ALL | 8443/TCP | HTTPS | TLS 1.2+ | Bearer/mTLS | TrustyAI service RBAC-protected endpoint |
| /* | ALL | 443/TCP | HTTPS | TLS 1.2+ | None | TrustyAI service HTTPS endpoint (targets 4443) |
| /* | ALL | 8032/TCP | HTTPS | TLS 1.2+ | None | Guardrails orchestrator HTTPS endpoint (without OAuth) |
| /* | ALL | 8432/TCP | HTTPS | TLS 1.2+ | Bearer | Guardrails orchestrator HTTPS endpoint (with OAuth) |
| /health | GET | 8034/TCP | HTTP | None | None | Guardrails orchestrator health check |
| /gateway | ALL | 8090/TCP | HTTP | None | None | Guardrails gateway endpoint (without OAuth) |
| /gateway | ALL | 8490/TCP | HTTP | TLS 1.2+ | Bearer | Guardrails gateway endpoint (with OAuth) |
| /metrics | GET | 8080/TCP | HTTP | None | None | Built-in detector metrics endpoint |

### gRPC Services

| Service | Port | Protocol | Encryption | Auth | Purpose |
|---------|------|----------|------------|------|---------|
| OTLP Traces | Configurable | gRPC | TLS 1.2+ | None | OpenTelemetry trace export from guardrails orchestrator |
| OTLP Metrics | Configurable | gRPC | TLS 1.2+ | None | OpenTelemetry metrics export from guardrails orchestrator |

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| Kubernetes | 1.19+ | Yes | Container orchestration platform |
| OpenShift | 4.6+ | No | Optional platform providing Routes and OAuth |
| Prometheus Operator | N/A | No | Enables ServiceMonitor creation for metrics scraping |
| Istio | N/A | No | Service mesh for VirtualServices and DestinationRules |
| cert-manager | N/A | No | TLS certificate management |
| Kueue | N/A | No | Job queue management for LMEvalJobs |

### Internal ODH/RHOAI Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| KServe | CRD Watch/Patch | Monitors and modifies InferenceServices for guardrails integration |
| Model Mesh | Label Detection | Identifies ModelMesh deployments for payload processor injection |
| DSC (Data Science Cluster) | ConfigMap | Reads platform configuration for serverless mode detection |

## Network Architecture

### Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| {trustyai-name} | ClusterIP | 80/TCP | 8080 | HTTP | None | None | Internal |
| {trustyai-name} | ClusterIP | 443/TCP | 4443 | HTTPS | TLS 1.2+ | None | Internal |
| {trustyai-name}-tls | ClusterIP | 443/TCP | 8443 | HTTPS | TLS 1.2+ | Bearer/mTLS | Internal |
| {gorch-name}-service | ClusterIP | 8032/TCP | 8032 | HTTPS | TLS 1.2+ | None | Internal |
| {gorch-name}-service | ClusterIP | 8432/TCP | 8432 | HTTPS | TLS 1.2+ | Bearer | Internal |
| {gorch-name}-service | ClusterIP | 8034/TCP | 8034 | HTTP | None | None | Internal |
| {gorch-name}-service | ClusterIP | 8090/TCP | 8090 | HTTP | None | None | Internal |
| {gorch-name}-service | ClusterIP | 8490/TCP | 8490 | HTTP | TLS 1.2+ | Bearer | Internal |
| {gorch-name}-service | ClusterIP | 8080/TCP | 8080 | HTTP | None | None | Internal |
| controller-manager-metrics-service | ClusterIP | 8443/TCP | 8443 | HTTPS | TLS 1.2+ | Bearer | Internal |

### Ingress

| Name | Type | Hosts | Port | Protocol | Encryption | TLS Mode | Exposure |
|------|------|-------|------|----------|------------|----------|----------|
| {trustyai-name} | OpenShift Route | auto-generated | 443/TCP | HTTPS | TLS 1.2+ | edge | External |
| {gorch-name}-https | OpenShift Route | auto-generated | 443/TCP | HTTPS | TLS 1.2+ | reencrypt | External |
| {gorch-name}-gateway | OpenShift Route | auto-generated | 443/TCP | HTTPS | TLS 1.2+ | reencrypt | External |
| {gorch-name}-health | OpenShift Route | auto-generated | 443/TCP | HTTPS | TLS 1.2+ | edge | External |
| {trustyai-name} | Istio VirtualService | {trustyai-name}.{namespace}.svc.cluster.local | N/A | HTTP/HTTPS | mTLS | ISTIO_MUTUAL | Internal |

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| KServe InferenceServices | 443/TCP | HTTPS/gRPC | TLS 1.2+ | mTLS | Forward requests to guarded inference services |
| External Database | Configurable | JDBC | TLS 1.2+ | Username/Password | TrustyAI service database connectivity |
| OTLP Collectors | Configurable | gRPC/HTTP | TLS 1.2+ | None | Export telemetry from guardrails orchestrator |
| Model Registries | 443/TCP | HTTPS | TLS 1.2+ | Token/Credentials | LMEvalJob model download |
| Dataset Repositories | 443/TCP | HTTPS | TLS 1.2+ | Token/API Key | LMEvalJob dataset download (when allowOnline=true) |

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
| manager-role | apps | deployments/finalizers | update |
| manager-role | apps | deployments/status | get, patch, update |
| manager-role | serving.kserve.io | inferenceservices | get, list, patch, update, watch |
| manager-role | serving.kserve.io | inferenceservices/finalizers | delete, get, list, patch, update, watch |
| manager-role | serving.kserve.io | servingruntimes | get, list, watch |
| manager-role | trustyai.opendatahub.io | trustyaiservices, lmevaljobs, guardrailsorchestrators | create, delete, get, list, patch, update, watch |
| manager-role | trustyai.opendatahub.io | trustyaiservices/finalizers, lmevaljobs/finalizers, guardrailsorchestrators/finalizers | update |
| manager-role | trustyai.opendatahub.io | trustyaiservices/status, lmevaljobs/status, guardrailsorchestrators/status | get, patch, update |
| manager-role | monitoring.coreos.com | servicemonitors | create, list, watch |
| manager-role | route.openshift.io | routes | create, delete, get, list, patch, update, watch |
| manager-role | networking.istio.io | destinationrules, virtualservices | create, delete, get, list, patch, update, watch |
| manager-role | kueue.x-k8s.io | workloads | create, delete, get, list, patch, update, watch |
| manager-role | kueue.x-k8s.io | workloads/finalizers | update |
| manager-role | kueue.x-k8s.io | workloads/status | get, patch, update |
| manager-role | kueue.x-k8s.io | resourceflavors, workloadpriorityclasses | get, list, watch |
| manager-role | rbac.authorization.k8s.io | clusterrolebindings | create, delete, get, list, update, watch |
| manager-role | coordination.k8s.io | leases | create, get, update |
| manager-role | apiextensions.k8s.io | customresourcedefinitions | get, list, watch |
| manager-role | scheduling.k8s.io | priorityclasses | get, list, watch |
| leader-election-role | "" | configmaps | get, list, watch, create, update, patch, delete |
| leader-election-role | coordination.k8s.io | leases | get, list, watch, create, update, patch, delete |
| leader-election-role | "" | events | create, patch |
| non-admin-lmeval-role | trustyai.opendatahub.io | lmevaljobs | create, delete, get, list, patch, update, watch |
| non-admin-lmeval-role | trustyai.opendatahub.io | lmevaljobs/status | get |

### RBAC - Role Bindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| manager-rolebinding | All (ClusterRoleBinding) | manager-role | controller-manager |
| leader-election-rolebinding | operator-namespace | leader-election-role | controller-manager |
| auth-proxy-rolebinding | operator-namespace | auth-proxy-role | controller-manager |
| default-lmeval-user-rolebinding | All (ClusterRoleBinding) | non-admin-lmeval-role | default (per namespace) |

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| {trustyai-name}-internal | kubernetes.io/tls | TLS certificate for internal TrustyAI service communication | OpenShift service-ca | Yes |
| {trustyai-name}-tls | kubernetes.io/tls | TLS certificate for RBAC-protected TrustyAI endpoint | OpenShift service-ca | Yes |
| {gorch-name}-tls | kubernetes.io/tls | TLS certificate for guardrails orchestrator service | OpenShift service-ca | Yes |
| {trustyai-name}-db-credentials | Opaque | Database connection credentials (username, password, service, port, name, kind, generation) | User/External System | No |
| {lmevaljob-name}-outputs | Opaque | LMEvalJob execution results and metrics | LMES Driver | No |

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| /q/metrics (TrustyAI) | GET | None | None | Internal metrics endpoint, no auth |
| TrustyAI HTTPS (443) | ALL | None | Service | Internal service communication |
| TrustyAI TLS (8443) | ALL | Bearer Token / mTLS | kube-rbac-proxy | SubjectAccessReview against Kubernetes RBAC |
| Guardrails HTTPS (8032) | ALL | None | Service | Direct access without OAuth |
| Guardrails HTTPS (8432) | ALL | Bearer Token (OAuth) | kube-rbac-proxy | OAuth token validation + SubjectAccessReview |
| Guardrails Gateway (8090) | ALL | None | Service | Direct access without OAuth |
| Guardrails Gateway (8490) | ALL | Bearer Token (OAuth) | kube-rbac-proxy | OAuth token validation + SubjectAccessReview |
| Operator Metrics (8443) | GET | Bearer Token | kube-rbac-proxy | Cluster RBAC for metrics access |
| LMEvalJob Creation | POST | Bearer Token | Kubernetes API | Requires lmevaljobs create permission |

## Data Flows

### Flow 1: TrustyAI Service Data Ingestion

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | External Client | OpenShift Router | 443/TCP | HTTPS | TLS 1.2+ | None |
| 2 | OpenShift Router | TrustyAI Service | 443/TCP | HTTPS | TLS 1.2+ | None |
| 3 | TrustyAI Service | PVC / Database | N/A | Filesystem / JDBC | None / TLS 1.2+ | None / DB Credentials |
| 4 | TrustyAI Service | Prometheus | 80/TCP | HTTP | None | None |

### Flow 2: Guardrails Request Orchestration

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Client | OpenShift Router | 443/TCP | HTTPS | TLS 1.2+ | None |
| 2 | OpenShift Router | Guardrails Service (kube-rbac-proxy) | 8432/TCP | HTTPS | TLS 1.2+ | Bearer Token |
| 3 | kube-rbac-proxy | Guardrails Orchestrator | 8032/TCP | HTTPS | TLS 1.2+ | None |
| 4 | Guardrails Orchestrator | Detector InferenceServices | 443/TCP | HTTPS/gRPC | mTLS | Service Account Token |
| 5 | Guardrails Orchestrator | Generator InferenceService | 443/TCP | HTTPS/gRPC | mTLS | Service Account Token |
| 6 | Guardrails Orchestrator | OTLP Collector | Configurable | gRPC | TLS 1.2+ | None |

### Flow 3: LM Evaluation Job Execution

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | Bearer Token |
| 2 | Operator | Kubernetes API (Job Create) | 6443/TCP | HTTPS | TLS 1.2+ | Service Account Token |
| 3 | LMES Driver | Model Registry | 443/TCP | HTTPS | TLS 1.2+ | Token/Credentials |
| 4 | LMES Job Pod | InferenceService | 443/TCP | HTTPS/gRPC | mTLS | Service Account Token |
| 5 | LMES Driver | Kubernetes API (Secret Create) | 6443/TCP | HTTPS | TLS 1.2+ | Service Account Token |

### Flow 4: InferenceService Guardrails Injection

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Operator Controller | Kubernetes API (InferenceService Watch) | 6443/TCP | HTTPS | TLS 1.2+ | Service Account Token |
| 2 | Operator Controller | Kubernetes API (InferenceService Patch) | 6443/TCP | HTTPS | TLS 1.2+ | Service Account Token |
| 3 | Modified InferenceService | Guardrails Gateway | 8090/TCP | HTTP | None | None |
| 4 | Guardrails Gateway | Guardrails Orchestrator | 8032/TCP | HTTPS | TLS 1.2+ | None |

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| Prometheus | ServiceMonitor Scrape | 80/TCP | HTTP | None | Collect TrustyAI service metrics |
| Prometheus | ServiceMonitor Scrape | 8080/TCP | HTTP | None | Collect guardrails detector metrics |
| Prometheus | ServiceMonitor Scrape | 8443/TCP | HTTPS | TLS 1.2+ | Collect operator metrics via RBAC proxy |
| KServe InferenceService | Watch/Patch CRD | 6443/TCP | HTTPS | TLS 1.2+ | Inject guardrails into inference pipelines |
| Istio Service Mesh | VirtualService CRD | N/A | N/A | N/A | Configure traffic routing for TrustyAI services |
| Istio Service Mesh | DestinationRule CRD | N/A | N/A | N/A | Configure mTLS for TrustyAI services |
| OpenShift Routes | Route CRD | N/A | N/A | N/A | Expose TrustyAI and guardrails services externally |
| Kueue | Workload CRD | N/A | N/A | N/A | Queue and schedule LMEvalJobs with resource quotas |
| Model Mesh | Label Watch/Patch | N/A | N/A | N/A | Inject TrustyAI payload processors into MM pods |
| PostgreSQL/MySQL | JDBC Connection | Configurable | JDBC | TLS 1.2+ (optional) | Persist TrustyAI data in external database |
| OpenTelemetry Collector | OTLP Export | Configurable | gRPC/HTTP | TLS 1.2+ | Export guardrails orchestrator telemetry |

## Recent Changes

| Commit | Date | Changes |
|--------|------|---------|
| b7b8dd9 | 2024+ | - Fix auto config service ports for guardrails orchestrator |
| cc0ee52 | 2024+ | - Fix logging bug in auto config serving runtime logs |
| bb407e8 | 2024+ | - Update autoconfig to use service information instead of hardcoded values |
| 4c1caf3 | 2024+ | - Fix TrustyAI operator tests for config generation |
| 10eee50 | 2024+ | - Mount and reference service CA to kube-rbac-proxy for secure communication |
| 0786da5 | 2024+ | - Make AutoConfig TLS a toggleable option (default: false) |
| 1e7fdb8 | 2024+ | - Add kube-rbac-proxy support for enhanced security (RHOAIENG-32590) |
| 0cd631b | 2024+ | - Fix repeating manual-orchestrator config message |
| 0c0104c | 2024+ | - Add new provider images for RHOAI configuration |

## Container Images

| Image | Purpose | Build Type | Registry |
|-------|---------|------------|----------|
| quay.io/trustyai/trustyai-service-operator:latest | Main operator controller | Konflux (Dockerfile.konflux) | Quay.io |
| quay.io/trustyai/trustyai-service:latest | TrustyAI explainability service | External | Quay.io |
| quay.io/trustyai/ta-lmes-driver:latest | LMEvalJob driver sidecar | Konflux (Dockerfile.konflux.driver) | Quay.io |
| quay.io/trustyai/ta-lmes-job:latest | LMEvalJob execution pod | Dockerfile.lmes-job | Quay.io |
| quay.io/trustyai/ta-guardrails-orchestrator:latest | Guardrails orchestrator | Dockerfile.orchestrator | Quay.io |
| quay.io/trustyai/guardrails-detector-built-in:latest | Built-in detector sidecar | External | Quay.io |
| quay.io/trustyai/guardrails-sidecar-gateway:latest | Guardrails gateway sidecar | External | Quay.io |
| quay.io/openshift/origin-kube-rbac-proxy:4.19 | RBAC authentication proxy | External | Quay.io |

## Deployment Configurations

The operator supports multiple deployment overlays via Kustomize:

- **base**: Core operator deployment with all services enabled (TAS, LMES, GORCH)
- **odh**: OpenDataHub-specific configuration with serverless KServe support
- **rhoai**: Red Hat OpenShift AI configuration
- **odh-kueue**: ODH with Kueue integration for job scheduling
- **lmes**: LMES-only deployment (TAS and GORCH disabled)
- **testing**: Development/testing configuration with AlwaysPull image policy

## Storage Options

### TrustyAIService Storage

1. **PVC Mode**: Data stored in PersistentVolumeClaim
   - Format: CSV or other file formats
   - Size: Configurable (e.g., 1Gi)
   - Folder: Configurable mount path

2. **Database Mode**: Data stored in external database
   - Supported: PostgreSQL, MySQL
   - Credentials: Kubernetes Secret with connection details
   - TLS: Optional with CA certificate mounting
   - Hibernate ORM: Active in database mode
   - Migration: Supports PVC-to-database migration

## Observability

### Metrics

- **TrustyAI Service**: Quarkus metrics at `/q/metrics` (port 80)
- **Guardrails Detector**: Metrics at port 8080
- **Operator**: Metrics at port 8443 (RBAC-protected)
- **ServiceMonitors**: Automatically created for Prometheus scraping

### Health Checks

- **TrustyAI Service**:
  - Readiness: `/q/health/ready` (port 8080)
  - Liveness: `/q/health/live` (port 8080)
- **Guardrails Orchestrator**:
  - Health: `/health` (port 8034)
  - kube-rbac-proxy: `/healthz` (proxy health port)
- **Operator**:
  - Readiness: `/readyz` (port 8081)
  - Liveness: `/healthz` (port 8081)

### Tracing

- **Guardrails Orchestrator**: OpenTelemetry OTLP export
  - Protocol: gRPC or HTTP (configurable)
  - Endpoints: Separate for traces and metrics
  - Toggle: Enable/disable traces and metrics independently

## Notes

- The operator supports leader election for high availability with multiple replicas
- TrustyAI services can scale horizontally (configurable replicas in spec)
- LMEvalJobs are batch workloads with configurable resource requirements
- Guardrails orchestrators support automatic configuration by watching InferenceServices with specific labels
- OAuth proxy integration is optional and enabled via annotations (`security.opendatahub.io/enable-auth`)
- The operator can inject guardrails into existing KServe InferenceServices via finalizers
- Model Mesh integration allows TrustyAI to intercept inference requests via payload processors
- Kueue integration enables enterprise job scheduling with quotas and priorities
- Database migration from PVC to database storage is supported via annotations
