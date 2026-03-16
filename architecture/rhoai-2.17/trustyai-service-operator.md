# Component: TrustyAI Service Operator

## Metadata
- **Repository**: https://github.com/red-hat-data-services/trustyai-service-operator
- **Version**: rhoai-2.17 (286a398)
- **Distribution**: Both ODH and RHOAI
- **Languages**: Go 1.21
- **Deployment Type**: Kubernetes Operator (Kubebuilder v4)

## Purpose
**Short**: Manages deployment and lifecycle of TrustyAI services for AI model explainability, fairness metrics, and LLM evaluation jobs in Kubernetes/OpenShift.

**Detailed**: The TrustyAI Service Operator is a Kubernetes operator that simplifies deployment and management of TrustyAI services for AI/ML explainability and trustworthiness. It manages two primary custom resources: TrustyAIService for monitoring and explaining model predictions, and LMEvalJob for evaluating Large Language Models. The operator automatically configures monitoring (ServiceMonitors), networking (Routes/Services), authentication (OAuth proxy), and integrates with KServe InferenceServices to provide real-time bias detection, fairness metrics (SPD, DIR), and model explainability. It supports both PVC-based and database storage backends, integrates with service mesh (Istio) for secure communication, and works with Kueue for workload management. The operator is designed for both development (ODH) and production (RHOAI) environments.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| TrustyAI Service Operator | Go Operator | Reconciles TrustyAIService and LMEvalJob CRDs, manages service lifecycle |
| TrustyAI Service | Quarkus Service | Provides explainability, fairness metrics, and bias detection for ML models |
| OAuth Proxy Sidecar | Proxy Container | Provides authentication/authorization for TrustyAI service endpoints |
| LMES Driver | Job Controller | Manages LM Evaluation Job execution and resource allocation |
| LMES Job Pod | Batch Job | Executes LLM evaluation tasks using lm-eval-harness |

## APIs Exposed

### Custom Resource Definitions (CRDs)

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| trustyai.opendatahub.io | v1alpha1 | TrustyAIService | Namespaced | Defines TrustyAI service deployment with storage (PVC/Database), metrics schedule, and data format |
| trustyai.opendatahub.io | v1alpha1 | LMEvalJob | Namespaced | Defines LLM evaluation jobs with model config, tasks, offline mode, and Kueue integration |

### HTTP Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /q/metrics | GET | 8080/TCP | HTTP | None (internal) | None | Prometheus metrics (trustyai_spd, trustyai_dir) |
| /q/health/ready | GET | 8080/TCP | HTTP | None (internal) | None | Readiness probe for TrustyAI service |
| /q/health/live | GET | 8080/TCP | HTTP | None (internal) | None | Liveness probe for TrustyAI service |
| /oauth/healthz | GET | 8443/TCP | HTTPS | TLS 1.2+ | None | OAuth proxy health check |
| /* | ALL | 8443/TCP | HTTPS | TLS 1.2+ | OAuth Bearer Token | Authenticated access to TrustyAI service via OAuth proxy |
| /healthz | GET | 8081/TCP | HTTP | None (internal) | None | Operator manager liveness probe |
| /readyz | GET | 8081/TCP | HTTP | None (internal) | None | Operator manager readiness probe |

### gRPC Services

No gRPC services exposed directly by this component.

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| Kubernetes | v1.19+ | Yes | Container orchestration platform |
| OpenShift | v4.6+ | No | Optional for Route and OAuth integration |
| KServe | v0.12.1 | No | InferenceService integration for model monitoring |
| Prometheus Operator | v0.64.1 | Yes | ServiceMonitor creation for metrics scraping |
| Istio | Latest | No | Service mesh for mTLS and traffic policies |
| Kueue | v0.6.2 | No | Workload queue management for LMEvalJobs |
| Database (MySQL/PostgreSQL) | Any | No | Optional storage backend (alternative to PVC) |

### Internal ODH Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| KServe InferenceServices | CRD Watch/Patch | Monitor model deployments and inject payload processors for data collection |
| ModelMesh Serving | Label Selector | Discover ModelMesh deployments to configure monitoring |
| ODH Dashboard | Service Discovery | TrustyAI service endpoints discoverable via labels |
| Prometheus (UWM) | ServiceMonitor | Expose trustyai_* metrics to user workload monitoring |

## Network Architecture

### Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| {name} | ClusterIP | 80/TCP | 8080 | HTTP | None | None | Internal |
| {name} | ClusterIP | 443/TCP | 4443 | HTTPS | TLS (service-ca) | OAuth Bearer Token | Internal |
| {name}-tls | ClusterIP | 443/TCP | 8443 | HTTPS | TLS (service-ca) | OAuth Bearer Token | Internal |
| controller-manager-metrics | ClusterIP | 8443/TCP | 8443 | HTTPS | TLS (kube-rbac-proxy) | K8s TokenReview | Internal |

### Ingress

| Name | Type | Hosts | Port | Protocol | Encryption | TLS Mode | Exposure |
|------|------|-------|------|----------|------------|----------|----------|
| {name} | OpenShift Route | Auto-generated | 443/TCP | HTTPS | TLS 1.2+ | Reencrypt | External (OpenShift only) |
| {name}-tls | Istio VirtualService | {name}.{namespace}.svc.cluster.local | 443/TCP | HTTPS | TLS 1.2+ | SIMPLE | Internal (Service Mesh) |

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| Database Service | Varies/TCP | JDBC | TLS 1.2+ (optional) | Username/Password | Store model data and metrics (DATABASE mode) |
| KServe InferenceService | 8080/TCP | HTTP | None (cluster-local) | None | Monitor model predictions and collect data |
| Prometheus | Scrape | HTTP | None (cluster-local) | ServiceAccount Token | Expose metrics for collection |

## Security

### RBAC - Cluster Roles

| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|
| manager-role | "" | configmaps, persistentvolumeclaims, pods, secrets, services, serviceaccounts | create, delete, get, list, patch, update, watch |
| manager-role | "" | events | create, patch, update, watch |
| manager-role | "" | persistentvolumes | get, list, watch |
| manager-role | "" | pods/exec | create, delete, get, list, watch |
| manager-role | apps | deployments | create, delete, get, list, patch, update, watch |
| manager-role | apps | deployments/finalizers, deployments/status | get, patch, update |
| manager-role | serving.kserve.io | inferenceservices, servingruntimes | create, delete, get, list, patch, update, watch |
| manager-role | serving.kserve.io | inferenceservices/finalizers | delete, get, list, patch, update, watch |
| manager-role | monitoring.coreos.com | servicemonitors | create, list, watch |
| manager-role | networking.istio.io | destinationrules, virtualservices | create, delete, get, list, patch, update, watch |
| manager-role | route.openshift.io | routes | create, delete, get, list, patch, update, watch |
| manager-role | kueue.x-k8s.io | workloads, resourceflavors, workloadpriorityclasses | create, delete, get, list, patch, update, watch |
| manager-role | trustyai.opendatahub.io | trustyaiservices, lmevaljobs | create, delete, get, list, patch, update, watch |
| manager-role | trustyai.opendatahub.io | trustyaiservices/status, lmevaljobs/status, trustyaiservices/finalizers, lmevaljobs/finalizers | get, patch, update |
| manager-role | rbac.authorization.k8s.io | clusterrolebindings | create, delete, get, list, update, watch |
| manager-role | coordination.k8s.io | leases | create, get, update |
| leader-election-role | "" | configmaps | get, list, watch, create, update, patch, delete |
| leader-election-role | coordination.k8s.io | leases | get, list, watch, create, update, patch, delete |
| leader-election-role | "" | events | create, patch |
| metrics-reader | "" | pods, services, endpoints | get, list, watch |
| auth-proxy-role | authentication.k8s.io | tokenreviews | create |
| auth-proxy-role | authorization.k8s.io | subjectaccessreviews | create |

### RBAC - Role Bindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| manager-rolebinding | system | manager-role (ClusterRole) | controller-manager |
| leader-election-rolebinding | system | leader-election-role | controller-manager |
| auth-proxy-rolebinding | system | auth-proxy-role | controller-manager |
| {name}-proxy | {namespace} | view (ClusterRole) | {name}-proxy (per TrustyAIService) |

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| {name}-internal | kubernetes.io/tls | Service-to-service TLS certificate for internal communication | OpenShift service-ca | Yes (OpenShift) |
| {name}-tls | kubernetes.io/tls | OAuth proxy TLS certificate for external/Route access | OpenShift service-ca | Yes (OpenShift) |
| {name}-db-credentials | Opaque | Database connection credentials (username, password, host, port, name, kind) | User/External | No |
| {name}-db-ca | Opaque | Database TLS CA certificate for secure JDBC connections | User/External | No |

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| /oauth/* | ALL | OAuth Bearer Token (OpenShift) | OAuth Proxy Sidecar | OpenShift RBAC via ServiceAccount token review |
| /* (via Route) | ALL | OAuth Bearer Token (OpenShift) | OpenShift Route + OAuth Proxy | Reencrypt TLS with OAuth authentication |
| /q/metrics | GET | None (internal only) | Network isolation | ClusterIP service, not exposed externally |
| /q/health/* | GET | None (internal only) | Network isolation | ClusterIP service, Kubernetes probes only |
| Istio mesh traffic | ALL | mTLS (optional) | Istio DestinationRule | SIMPLE TLS mode on port 443 |

## Data Flows

### Flow 1: Model Monitoring and Metrics Collection

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | TrustyAI Operator | KServe InferenceService | 443/TCP | HTTPS | None (cluster-local) | ServiceAccount Token |
| 2 | TrustyAI Operator | InferenceService Deployment | N/A | K8s Patch | None | ServiceAccount RBAC |
| 3 | InferenceService | TrustyAI Service | 8080/TCP | HTTP | TLS (Istio mTLS optional) | None |
| 4 | TrustyAI Service | PVC Storage | N/A | Filesystem | None | PodSecurityContext |
| 5 | TrustyAI Service | Database (optional) | Varies/TCP | JDBC | TLS (optional) | Username/Password |
| 6 | Prometheus | TrustyAI Service | 8080/TCP | HTTP | None | ServiceMonitor token |
| 7 | User/Dashboard | OAuth Proxy | 443/TCP | HTTPS | TLS 1.2+ (Reencrypt) | OAuth Bearer Token |
| 8 | OAuth Proxy | TrustyAI Service | 8080/TCP | HTTP | TLS (internal) | None |

### Flow 2: LMEvalJob Execution

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User | Kubernetes API | 6443/TCP | HTTPS | TLS 1.3 | Kubeconfig/Token |
| 2 | TrustyAI Operator | Kueue Workload | N/A | K8s CRD | None | ServiceAccount RBAC |
| 3 | Kueue | LMES Driver Pod | N/A | K8s Job | None | Kueue Admission |
| 4 | LMES Driver | Model Endpoint | Varies/TCP | HTTP/HTTPS | TLS (if external) | API Key/Token |
| 5 | LMES Job Pod | Output PVC | N/A | Filesystem | None | PodSecurityContext |
| 6 | TrustyAI Operator | LMEvalJob Status | N/A | K8s CRD Status | None | ServiceAccount RBAC |

### Flow 3: Database Migration (PVC to Database)

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | TrustyAI Service | PVC (source) | N/A | Filesystem | None | VolumeMount |
| 2 | TrustyAI Service | Database | Varies/TCP | JDBC | TLS (optional) | Username/Password from Secret |
| 3 | TrustyAI Service | TrustyAIService Status | N/A | K8s CRD Status | None | Controller Update |

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| KServe InferenceService | CRD Watch + Patch | N/A | K8s API | TLS 1.3 | Monitor model deployments, inject payload processors for data collection |
| ModelMesh Deployment | Label Discovery + Patch | N/A | K8s API | TLS 1.3 | Configure model mesh containers with TrustyAI endpoints |
| Prometheus (UWM) | ServiceMonitor | 8080/TCP | HTTP | None | Scrape fairness metrics (trustyai_spd, trustyai_dir) |
| Istio Service Mesh | DestinationRule | 443/TCP | HTTPS | TLS SIMPLE | Configure traffic policies for secure communication |
| OpenShift OAuth | OAuth Proxy Sidecar | 8443/TCP | HTTPS | TLS 1.2+ | Authenticate users via OpenShift tokens |
| OpenShift Routes | Route CR | 443/TCP | HTTPS | TLS Reencrypt | Expose TrustyAI service externally on OpenShift |
| Kueue | Workload CRD | N/A | K8s API | TLS 1.3 | Queue and schedule LMEvalJobs with resource management |
| Database (MySQL/PostgreSQL) | JDBC | Varies/TCP | JDBC/TCP | TLS (optional) | Persist model data and metrics in DATABASE mode |

## Recent Changes

| Commit | Date | Changes |
|--------|------|---------|
| 286a398 | 2025-04-10 | - Update Konflux references to 998b546 (#1180) |
| 428d86a | 2025-04-10 | - Update Konflux references to 998b546 (#1179) |
| 94ab2c1 | 2025-04-10 | - Update Konflux references to 998b546 (#1178) |
| 65cc4cf | 2025-04-10 | - Update Konflux references to 998b546 (#1176) |
| 0fe62a1 | 2025-04-10 | - Update Konflux references to 1abf949 (#1169) |

**Note**: Recent commits primarily focus on updating Konflux (RHOAI build system) references, indicating active maintenance for production builds. The component is under active development with a focus on Konflux CI/CD integration for RHOAI 2.17 release.

## Container Images

| Image | Purpose | Base | Build System |
|-------|---------|------|--------------|
| odh-trustyai-service-operator-rhel8 | Operator Manager | registry.redhat.io/ubi8/ubi-minimal | Konflux (Dockerfile.konflux) |
| trustyai-service | TrustyAI Service (Quarkus) | User configurable (default: quay.io/trustyai/trustyai-service:latest) | External |
| ose-oauth-proxy | OAuth Proxy Sidecar | registry.redhat.io/openshift4/ose-oauth-proxy:latest | External |
| ta-lmes-driver | LMES Driver | User configurable (default: quay.io/trustyai/ta-lmes-driver:latest) | External |
| ta-lmes-job | LMES Job Pod | User configurable (default: quay.io/trustyai/ta-lmes-job:latest) | External |

## Deployment Configuration

| Parameter | Default | ConfigMap Override | Purpose |
|-----------|---------|-------------------|---------|
| trustyaiServiceImage | quay.io/trustyai/trustyai-service:latest | trustyai-service-operator-config | TrustyAI service container image |
| oauthProxyImage | quay.io/openshift/origin-oauth-proxy:4.14.0 | trustyai-service-operator-config | OAuth proxy sidecar image |
| kServeServerless | enabled | trustyai-service-operator-config | Enable KServe serverless integration |
| lmes-driver-image | quay.io/trustyai/ta-lmes-driver:latest | N/A | LMES driver container image |
| lmes-pod-image | quay.io/trustyai/ta-lmes-job:latest | N/A | LMES job pod container image |

## Observability

| Type | Endpoint/Resource | Purpose |
|------|------------------|---------|
| Metrics | /q/metrics | Prometheus metrics: trustyai_spd (Statistical Parity Difference), trustyai_dir (Disparate Impact Ratio) |
| ServiceMonitor | trustyai-metrics | Auto-created for Prometheus scraping in user namespaces |
| Health Checks | /q/health/ready, /q/health/live | Kubernetes readiness and liveness probes |
| Logs | Container stdout/stderr | Operator and TrustyAI service logs via Kubernetes logging |
| Events | Kubernetes Events | PVCCreated, InferenceServiceConfigured, ServiceMonitorCreated |

## Storage Modes

| Mode | Configuration | Persistence | Use Case |
|------|--------------|-------------|----------|
| PVC | storage.format: PVC | PersistentVolumeClaim | Development, small datasets, namespace-scoped storage |
| DATABASE | storage.format: DATABASE | External Database (MySQL/PostgreSQL) | Production, large datasets, shared storage across namespaces |
| Migration | Annotation: trustyai.opendatahub.io/db-migration | Both PVC and Database | Migrate data from PVC to Database mode |
