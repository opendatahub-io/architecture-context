# Component: TrustyAI Service Operator

## Metadata
- **Repository**: https://github.com/red-hat-data-services/trustyai-service-operator
- **Version**: v-2160-525-g148b382 (rhoai-2.16)
- **Distribution**: RHOAI and ODH
- **Languages**: Go
- **Deployment Type**: Kubernetes Operator

## Purpose
**Short**: Manages TrustyAI services for ML model explainability, fairness monitoring, and language model evaluation.

**Detailed**: The TrustyAI Service Operator is a Kubernetes operator that simplifies the deployment and management of TrustyAI services for ML model explainability and monitoring. It manages two main capabilities: (1) TrustyAI Service deployments that provide explainability and fairness metrics for ML models, particularly KServe InferenceServices, and (2) LMEvalJob resources for evaluating large language models using the lm-evaluation-harness framework. The operator automatically configures services, routes, OAuth authentication, Prometheus monitoring, and Istio service mesh integration. It supports both PVC-based and database-backed storage, integrates with ModelMesh and KServe for payload interception, and provides comprehensive metrics for ML model monitoring and governance.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| TrustyAI Service Operator | Go Operator | Reconciles TrustyAIService and LMEvalJob CRs, manages deployments, services, and network resources |
| TrustyAI Service Deployment | Application Container | Quarkus-based service providing explainability and fairness metrics for ML models |
| OAuth Proxy Sidecar | Security Proxy | Provides OAuth-based authentication for TrustyAI service endpoints |
| LMEval Job Pods | Batch Jobs | Executes language model evaluation tasks using lm-evaluation-harness |
| LMEval Driver | Init Container | Manages job execution lifecycle and result collection |
| ServiceMonitor | Prometheus Resource | Configures Prometheus to scrape TrustyAI metrics |
| VirtualService | Istio Resource | HTTP to HTTPS redirection for service mesh integration |
| DestinationRule | Istio Resource | TLS traffic policy configuration |

## APIs Exposed

### Custom Resource Definitions (CRDs)

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| trustyai.opendatahub.io | v1alpha1 | TrustyAIService | Namespaced | Manages TrustyAI service deployment for ML explainability and fairness monitoring |
| trustyai.opendatahub.io | v1alpha1 | LMEvalJob | Namespaced | Manages language model evaluation jobs using lm-evaluation-harness |

### HTTP Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /q/metrics | GET | 80/TCP | HTTP | None | None | Internal Prometheus metrics endpoint |
| /q/metrics | GET | 443/TCP | HTTPS | TLS 1.2+ | None | Internal HTTPS metrics endpoint |
| / | ALL | 443/TCP | HTTPS | TLS 1.2+ | OAuth Bearer Token | External TrustyAI API access via OAuth proxy |
| /healthz | GET | 8081/TCP | HTTP | None | None | Operator liveness probe |
| /readyz | GET | 8081/TCP | HTTP | None | None | Operator readiness probe |

### gRPC Services

No gRPC services exposed.

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| Kubernetes | v1.19+ | Yes | Container orchestration platform |
| OpenShift | v4.6+ | No | Route and OAuth integration (OpenShift-specific features) |
| Prometheus Operator | Latest | Yes | ServiceMonitor CRD for metrics scraping |
| Istio | Latest | No | Service mesh integration for traffic management |
| KServe | v1beta1 | No | InferenceService integration for model monitoring |
| Kueue | Latest | No | Job queue management for LMEvalJobs |
| PostgreSQL/MySQL | Any | No | Database backend for TrustyAI data storage (alternative to PVC) |

### Internal ODH/RHOAI Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| KServe | CRD Watch/Patch | Monitors InferenceServices, patches ModelMesh deployments with TrustyAI payload processors |
| Model Mesh | Deployment Patch | Injects TrustyAI service URL as payload processor for inference monitoring |
| ODH Dashboard | Service Discovery | TrustyAI services are discovered and accessible via ODH/RHOAI dashboards |
| Service Mesh (Istio) | VirtualService/DestinationRule | Traffic routing and TLS configuration |

## Network Architecture

### Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| {instance-name} | ClusterIP | 80/TCP | 8080 | HTTP | None | None | Internal |
| {instance-name} | ClusterIP | 443/TCP | 4443 | HTTPS | TLS 1.2+ | None | Internal |
| {instance-name}-tls | ClusterIP | 443/TCP | 8443 | HTTPS | TLS 1.2+ | OAuth | Internal |
| trustyai-operator-controller-manager | N/A | 8081/TCP | 8081 | HTTP | None | None | Internal (health checks) |

### Ingress

| Name | Type | Hosts | Port | Protocol | Encryption | TLS Mode | Exposure |
|------|------|-------|------|----------|------------|----------|----------|
| {instance-name} | OpenShift Route | Auto-generated | 443/TCP | HTTPS | TLS 1.2+ | edge (re-encrypt) | External (OpenShift only) |

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| Database (PostgreSQL/MySQL) | Variable/TCP | JDBC | TLS 1.2+ (optional) | Username/Password | Data persistence for TrustyAI metrics |
| KServe InferenceService | 80,443/TCP | HTTP/HTTPS | TLS 1.2+ (mesh) | mTLS (service mesh) | Model inference monitoring payload interception |
| Prometheus | 9090/TCP | HTTP | None | None | Metrics push (pull-based via ServiceMonitor) |
| Hugging Face Hub | 443/TCP | HTTPS | TLS 1.2+ | API Token (optional) | LMEvalJob model and dataset downloads (online mode) |

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
| manager-role | trustyai.opendatahub.io | trustyaiservices, lmevaljobs | create, delete, get, list, patch, update, watch |
| manager-role | trustyai.opendatahub.io | trustyaiservices/finalizers, lmevaljobs/finalizers | update |
| manager-role | trustyai.opendatahub.io | trustyaiservices/status, lmevaljobs/status | get, patch, update |
| manager-role | serving.kserve.io | inferenceservices | get, list, patch, update, watch |
| manager-role | serving.kserve.io | inferenceservices/finalizers | delete, get, list, patch, update, watch |
| manager-role | serving.kserve.io | servingruntimes | create, delete, get, list, patch, update, watch |
| manager-role | monitoring.coreos.com | servicemonitors | create, list, watch |
| manager-role | networking.istio.io | destinationrules, virtualservices | create, delete, get, list, patch, update, watch |
| manager-role | route.openshift.io | routes | create, delete, get, list, patch, update, watch |
| manager-role | kueue.x-k8s.io | workloads | create, delete, get, list, patch, update, watch |
| manager-role | kueue.x-k8s.io | workloads/finalizers | update |
| manager-role | kueue.x-k8s.io | workloads/status | get, patch, update |
| manager-role | kueue.x-k8s.io | resourceflavors, workloadpriorityclasses | get, list, watch |
| manager-role | coordination.k8s.io | leases | create, get, update |
| manager-role | rbac.authorization.k8s.io | clusterrolebindings | create, delete, get, list, update, watch |
| manager-role | apiextensions.k8s.io | customresourcedefinitions | get, list, watch |
| leader-election-role | coordination.k8s.io | leases | get, list, watch, create, update, patch, delete |
| leader-election-role | "" | configmaps | get, list, watch, create, update, patch, delete |
| leader-election-role | "" | events | create, patch |

### RBAC - Role Bindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| manager-rolebinding | operator namespace | manager-role (ClusterRole) | controller-manager |
| leader-election-rolebinding | operator namespace | leader-election-role (Role) | controller-manager |
| auth-proxy-rolebinding | operator namespace | auth-proxy-role (ClusterRole) | controller-manager |

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| {instance-name}-internal | kubernetes.io/tls | TLS certificate for internal HTTPS service | service.beta.openshift.io/serving-cert | Yes (OpenShift) |
| {instance-name}-tls | kubernetes.io/tls | TLS certificate for OAuth proxy service | service.beta.openshift.io/serving-cert | Yes (OpenShift) |
| {instance-name}-db-credentials | Opaque | Database connection credentials (kind, username, password, service, port, name) | User/External | No |
| {instance-name}-db-ca | Opaque | Database TLS CA certificate | User/External | No |

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| External Route | ALL | OAuth Bearer Token (OpenShift) | OAuth Proxy (port 8443) | OpenShift OAuth integration |
| Internal Service (HTTP) | ALL | None | N/A | Internal cluster traffic only |
| Internal Service (HTTPS) | ALL | mTLS (service mesh) | Istio sidecar | Service mesh policy |
| Metrics | GET | None | N/A | Internal ServiceMonitor access |
| Database | JDBC | Username/Password + TLS (optional) | JDBC Driver | Connection string authentication |

## Data Flows

### Flow 1: Model Inference Monitoring (ModelMesh Integration)

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Client | KServe InferenceService | 443/TCP | HTTPS | TLS 1.2+ | Bearer Token |
| 2 | ModelMesh | TrustyAI Service | 443/TCP | HTTPS | TLS 1.2+ (mTLS) | Service Mesh |
| 3 | TrustyAI Service | Database/PVC | Variable | JDBC/File | TLS 1.2+ (DB) | Credentials (DB) |
| 4 | Prometheus | TrustyAI Service | 80/TCP | HTTP | None | None |

### Flow 2: External TrustyAI API Access (OpenShift)

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | External Client | OpenShift Route | 443/TCP | HTTPS | TLS 1.2+ | None (transport) |
| 2 | Route | OAuth Proxy | 8443/TCP | HTTPS | TLS 1.2+ | OAuth Bearer Token |
| 3 | OAuth Proxy | TrustyAI Service | 8080/TCP | HTTP | None | Validated OAuth |
| 4 | TrustyAI Service | Database/PVC | Variable | JDBC/File | TLS 1.2+ (DB) | Credentials (DB) |

### Flow 3: LMEvalJob Execution

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Operator | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 2 | Operator | LMEvalJob Pod | N/A | N/A | N/A | N/A |
| 3 | Driver (init) | LMEval Container | N/A | Shared Volume | None | None |
| 4 | LMEval Pod | Hugging Face (optional) | 443/TCP | HTTPS | TLS 1.2+ | API Token |
| 5 | LMEval Pod | Model Endpoint (optional) | Variable | HTTP/HTTPS | Variable | Variable |
| 6 | Driver | PVC | N/A | File | None | None |
| 7 | Operator | LMEvalJob Pod (exec) | Variable | Pod Exec | TLS 1.2+ | ServiceAccount Token |

### Flow 4: Metrics Collection

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Prometheus | ServiceMonitor | N/A | N/A | N/A | N/A |
| 2 | Prometheus | TrustyAI Service | 80/TCP | HTTP | None | None |
| 3 | TrustyAI Service | Metrics Endpoint (/q/metrics) | 80/TCP | HTTP | None | None |

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| KServe InferenceService | CRD Watch/Patch | 6443/TCP | HTTPS | TLS 1.2+ | Monitor inference services, inject TrustyAI payload processor |
| ModelMesh Deployment | Deployment Patch | 6443/TCP | HTTPS | TLS 1.2+ | Inject environment variables and volume mounts for TLS certificates |
| Prometheus | ServiceMonitor | 80/TCP | HTTP | None | Expose fairness and explainability metrics for scraping |
| Istio | VirtualService/DestinationRule | 6443/TCP | HTTPS | TLS 1.2+ | Configure traffic routing and TLS policies |
| OpenShift Route | Route CR | 6443/TCP | HTTPS | TLS 1.2+ | External access to TrustyAI service |
| Database | JDBC | Variable/TCP | JDBC | TLS 1.2+ (optional) | Persist inference data and metrics |
| Kueue | Workload CR | 6443/TCP | HTTPS | TLS 1.2+ | Queue management for LMEvalJobs |
| Hugging Face Hub | HTTPS API | 443/TCP | HTTPS | TLS 1.2+ | Download models and datasets for LMEvalJobs |

## Recent Changes

| Version | Date | Changes |
|---------|------|---------|
| 148b382 | 2026-03 | - Updated Go toolset to 1.25<br>- Updated UBI8 base images<br>- Dependency updates for security patches |
| f1c2af3 | 2026-03 | - Updated Go toolset Docker digest |
| ac883ec | 2026-03 | - Updated UBI-minimal base image |
| 7f4a7b6 | 2026-03 | - Updated Tekton PipelineRun configurations<br>- Added LMES Driver configuration |
| 438c284 | 2026-03 | - Updated ta-lmes-job image version |

## Deployment Configurations

### Kustomize Overlays

The operator supports multiple deployment overlays:

- **base**: Common base configuration
- **odh**: Open Data Hub specific configuration
- **rhoai**: Red Hat OpenShift AI specific configuration
- **lmes**: LMES (Language Model Evaluation Service) only mode
- **odh-kueue**: ODH with Kueue integration enabled
- **testing**: Testing configuration with custom image pull policies

### Container Images

| Image | Purpose | Registry | Build |
|-------|---------|----------|-------|
| odh-trustyai-service-operator | Operator manager | quay.io | Konflux |
| trustyai-service | TrustyAI explainability service | quay.io/trustyai | External |
| ta-lmes-job | Language model evaluation harness | quay.io/trustyai | Konflux |
| ta-lmes-driver | LMEval job driver | quay.io/trustyai | Konflux |
| ose-oauth-proxy | OAuth proxy sidecar | registry.redhat.io/openshift4 | Red Hat |

### Configuration Parameters

| Parameter | Default | Purpose |
|-----------|---------|---------|
| trustyaiServiceImage | quay.io/trustyai/trustyai-service:latest | TrustyAI service container image |
| oauthProxyImage | registry.redhat.io/openshift4/ose-oauth-proxy:latest | OAuth proxy sidecar image |
| lmes-pod-image | quay.io/trustyai/ta-lmes-job:latest | LMEval job container image |
| lmes-driver-image | quay.io/trustyai/ta-lmes-driver:latest | LMEval driver container image |
| kServeServerless | false | Enable KServe serverless mode detection |

## Storage Options

### PVC-based Storage

- Storage format: `PVC`
- Configurable size (e.g., 1Gi)
- Data stored in CSV or other formats
- Suitable for smaller deployments

### Database Storage

- Storage format: `DATABASE`
- Supported databases: PostgreSQL, MySQL
- TLS encryption support via CA certificates
- Credentials stored in Kubernetes secrets
- Suitable for production deployments with high data volume

## Observability

### Metrics

TrustyAI exposes Prometheus metrics including:
- `trustyai_spd`: Statistical Parity Difference (fairness metric)
- `trustyai_dir`: Disparate Impact Ratio (fairness metric)
- Custom explainability and model monitoring metrics

### Health Checks

- Liveness probe: `GET /healthz` on port 8081
- Readiness probe: `GET /readyz` on port 8081

### Status Conditions

TrustyAIService tracks the following conditions:
- `InferenceServicesPresent`: Availability of KServe InferenceServices
- `PVCAvailable`: Availability of PersistentVolumeClaims (PVC mode)
- `DBAvailable`: Database connection status (DATABASE mode)
- `RouteAvailable`: OpenShift Route availability
- `Available`: Overall service readiness

## Known Limitations

1. **OpenShift Routes**: External access via Routes is only available on OpenShift (not upstream Kubernetes)
2. **OAuth Integration**: OAuth proxy integration is OpenShift-specific
3. **Database Migration**: Migration from PVC to DATABASE storage requires manual intervention
4. **Kueue Dependency**: LMEvalJobs with job manager enabled require Kueue queue labels
5. **Service Mesh**: Full TLS and traffic management features require Istio service mesh installation

## Security Considerations

1. **Non-Root Containers**: All containers run as non-root users (UID 65532 for operator, configurable for services)
2. **Seccomp Profile**: RuntimeDefault seccomp profile enforced
3. **Capabilities**: All Linux capabilities dropped
4. **Privilege Escalation**: Prevented via securityContext
5. **TLS Certificates**: Auto-provisioned by OpenShift service-serving-cert controller
6. **Database TLS**: Optional but recommended for production database connections
7. **OAuth Authentication**: External API access protected by OpenShift OAuth
8. **Service Mesh mTLS**: Internal service-to-service communication can be secured via Istio mTLS
