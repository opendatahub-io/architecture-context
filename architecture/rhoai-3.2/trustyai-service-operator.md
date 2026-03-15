# Component: TrustyAI Service Operator

## Metadata
- **Repository**: https://github.com/red-hat-data-services/trustyai-service-operator
- **Version**: a2e891d (rhoai-3.2 branch)
- **Distribution**: RHOAI
- **Languages**: Go 1.23
- **Deployment Type**: Kubernetes Operator

## Purpose
**Short**: Kubernetes operator that manages TrustyAI components for AI model explainability, fairness monitoring, LLM evaluation, and guardrails.

**Detailed**: The TrustyAI Service Operator is a comprehensive Kubernetes operator that deploys and manages multiple AI trustworthiness and safety components. It provides four main capabilities: (1) TrustyAI Service for model explainability, fairness monitoring, and drift detection alongside KServe models, (2) LM-Eval jobs for evaluating Large Language Models using EleutherAI's lm-evaluation-harness, (3) FMS Guardrails Orchestrator for implementing guardrails around LLM applications, and (4) NVIDIA NeMo Guardrails integration. The operator automates deployment, configuration, and lifecycle management of these services, integrating with KServe InferenceServices, Istio service mesh, and OpenShift infrastructure.

The operator is built using the Operator SDK and manages Custom Resource Definitions (CRDs) for each service type. It supports both PVC-based and database-backed storage, implements security through kube-rbac-proxy and TLS certificates, and provides metrics integration with Prometheus. The operator can run in different modes (TAS, LMES, GORCH, NEMO_GUARDRAILS) to enable only required components.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| TrustyAI Operator | Kubernetes Operator | Main controller managing all TrustyAI CRDs and reconciliation logic |
| TrustyAI Service | Deployed Service | Model monitoring service for explainability, fairness, and drift detection |
| LMEval Jobs | Batch Jobs | Kubernetes jobs for evaluating LLM models using lm-evaluation-harness |
| Guardrails Orchestrator | Deployment | Orchestrates guardrail detectors for LLM applications |
| NeMo Guardrails | Deployment | NVIDIA NeMo guardrails integration service |
| LMES Driver | Sidecar Container | Communication driver for LMEval job coordination |
| Kube-RBAC-Proxy | Sidecar Container | Authentication proxy for securing service endpoints |

## APIs Exposed

### Custom Resource Definitions (CRDs)

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| trustyai.opendatahub.io | v1 | TrustyAIService | Namespaced | Defines TrustyAI monitoring service deployment for model explainability and fairness |
| trustyai.opendatahub.io | v1alpha1 | LMEvalJob | Namespaced | Defines LLM evaluation jobs with tasks, models, and output configurations |
| trustyai.opendatahub.io | v1alpha1 | GuardrailsOrchestrator | Namespaced | Defines guardrails orchestrator for LLM safety and policy enforcement |
| trustyai.opendatahub.io | v1alpha1 | NemoGuardrails | Namespaced | Defines NVIDIA NeMo guardrails deployment configuration |

### HTTP Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /healthz | GET | 8081/TCP | HTTP | None | None | Operator health check |
| /readyz | GET | 8081/TCP | HTTP | None | None | Operator readiness check |
| /metrics | GET | 8080/TCP | HTTP | None | None | Operator Prometheus metrics |
| /api/v1/* | GET, POST | 8443/TCP | HTTPS | TLS 1.2+ | Bearer Token | TrustyAI Service API via kube-rbac-proxy |
| /q/* | GET, POST | 8032/TCP | HTTP | None | None | Guardrails orchestrator API (internal) |
| /q/* | GET, POST | 8432/TCP | HTTPS | TLS 1.2+ | Bearer Token | Guardrails orchestrator API via kube-rbac-proxy |
| /health | GET | 8034/TCP | HTTP | None | None | Guardrails orchestrator health |
| / | GET, POST | 8000/TCP | HTTP | None | None | NeMo Guardrails API (without auth proxy) |
| / | GET, POST | 8443/TCP | HTTPS | TLS 1.2+ | Bearer Token | NeMo Guardrails API via kube-rbac-proxy |

### gRPC Services

| Service | Port | Protocol | Encryption | Auth | Purpose |
|---------|------|----------|------------|------|---------|
| LMES Driver | 18080/TCP | HTTP | None | None | Job coordination and communication for LMEval tasks |

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| KServe | v0.12.1 | Yes | Inference service integration for model monitoring |
| Kubernetes | v1.19+ | Yes | Operator runtime platform |
| Go | 1.23 | Yes | Build toolchain |
| Kueue | v0.6.2 | No | Job queuing and resource management for LMEval |
| Prometheus Operator | v0.64.1 | No | Metrics collection via ServiceMonitor |

### Internal ODH Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| KServe InferenceServices | CRD Watch/Patch | Monitor and configure inference services for TrustyAI data collection |
| OpenShift Routes | CRD Create | Expose services externally via OpenShift router |
| Istio VirtualService | CRD Create | Configure service mesh routing for TrustyAI services |
| Istio DestinationRule | CRD Create | Configure mTLS and traffic policies in service mesh |
| Service Mesh | Network | Optional integration for secure service-to-service communication |

## Network Architecture

### Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| trustyai-service-\<name\> | ClusterIP | 443/TCP | 8443 | HTTPS | TLS 1.2+ | kube-rbac-proxy | Internal |
| trustyai-service-\<name\>-internal | ClusterIP | 8443/TCP | 8443 | HTTPS | TLS 1.2+ | None | Internal (service mesh) |
| guardrails-orchestrator-\<name\> | ClusterIP | 8032/TCP | 8032 | HTTP | None | None | Internal |
| guardrails-orchestrator-\<name\> | ClusterIP | 8432/TCP | 8432 | HTTPS | TLS 1.2+ | kube-rbac-proxy | Internal |
| guardrails-orchestrator-\<name\> | ClusterIP | 8034/TCP | 8034 | HTTP | None | None | Internal (health) |
| guardrails-orchestrator-\<name\> | ClusterIP | 8080/TCP | 8080 | HTTP | None | None | Internal (built-in detectors) |
| guardrails-orchestrator-\<name\> | ClusterIP | 8090/TCP | 8090 | HTTP | None | None | Internal (gateway) |
| nemo-guardrails-\<name\> | ClusterIP | 443/TCP | 8443 | HTTPS | TLS 1.2+ | kube-rbac-proxy | Internal |
| nemo-guardrails-\<name\> | ClusterIP | 80/TCP | 8000 | HTTP | None | None | Internal (no auth) |
| controller-manager-metrics-service | ClusterIP | 8080/TCP | 8080 | HTTP | None | None | Internal |

### Ingress

| Name | Type | Hosts | Port | Protocol | Encryption | TLS Mode | Exposure |
|------|------|-------|------|----------|------------|----------|----------|
| trustyai-service-\<name\>-route | OpenShift Route | \<generated\>.apps.\<cluster\> | 443/TCP | HTTPS | TLS 1.2+ | Edge Termination | External |
| guardrails-orchestrator-\<name\>-route | OpenShift Route | \<generated\>.apps.\<cluster\> | 443/TCP | HTTPS | TLS 1.2+ | Edge Termination | External |
| nemo-guardrails-\<name\>-route | OpenShift Route | \<generated\>.apps.\<cluster\> | 443/TCP | HTTPS | TLS 1.2+ | Edge Termination | External |

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| PostgreSQL/MySQL Database | 5432/TCP or 3306/TCP | PostgreSQL/MySQL | TLS 1.2+ (optional) | Username/Password | TrustyAI data persistence |
| KServe InferenceService | 443/TCP or 8080/TCP | HTTPS/HTTP | TLS 1.2+ or None | mTLS or None | Inference data collection and payload processing |
| Object Storage (S3-compatible) | 443/TCP | HTTPS | TLS 1.2+ | AWS Signature V4 | LMEval job output storage |
| Model Registry | 443/TCP | HTTPS | TLS 1.2+ | API Key | LLM model download for evaluation |

## Security

### RBAC - Cluster Roles

| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|
| manager-role | "" | configmaps, persistentvolumeclaims, pods, secrets, serviceaccounts, services | create, delete, get, list, patch, update, watch |
| manager-role | "" | events | create, patch, update, watch |
| manager-role | "" | persistentvolumes | get, list, watch |
| manager-role | "" | pods/exec | create, delete, get, list, watch |
| manager-role | apps | deployments | create, delete, get, list, patch, update, watch |
| manager-role | apps | deployments/finalizers | update |
| manager-role | apps | deployments/status | get, patch, update |
| manager-role | serving.kserve.io | inferenceservices | get, list, patch, update, watch |
| manager-role | serving.kserve.io | inferenceservices/finalizers | delete, get, list, patch, update, watch |
| manager-role | serving.kserve.io | servingruntimes | get, list, watch |
| manager-role | networking.istio.io | destinationrules, virtualservices | create, delete, get, list, patch, update, watch |
| manager-role | route.openshift.io | routes | create, delete, get, list, patch, update, watch |
| manager-role | monitoring.coreos.com | servicemonitors | create, list, watch |
| manager-role | kueue.x-k8s.io | workloads | create, delete, get, list, patch, update, watch |
| manager-role | kueue.x-k8s.io | workloads/finalizers | update |
| manager-role | kueue.x-k8s.io | workloads/status | get, patch, update |
| manager-role | kueue.x-k8s.io | resourceflavors, workloadpriorityclasses | get, list, watch |
| manager-role | rbac.authorization.k8s.io | clusterrolebindings | create, delete, get, list, update, watch |
| manager-role | trustyai.opendatahub.io | trustyaiservices, lmevaljobs, guardrailsorchestrators, nemoguardrails | create, delete, get, list, patch, update, watch |
| manager-role | trustyai.opendatahub.io | trustyaiservices/finalizers, lmevaljobs/finalizers, guardrailsorchestrators/finalizers, nemoguardrails/finalizers | update |
| manager-role | trustyai.opendatahub.io | trustyaiservices/status, lmevaljobs/status, guardrailsorchestrators/status, nemoguardrails/status | get, patch, update |
| manager-role | coordination.k8s.io | leases | create, get, update |
| manager-role | apiextensions.k8s.io | customresourcedefinitions | get, list, watch |
| manager-role | scheduling.k8s.io | priorityclasses | get, list, watch |

### RBAC - Role Bindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| manager-rolebinding | \<operator-namespace\> | manager-role (ClusterRole) | controller-manager |
| leader-election-rolebinding | \<operator-namespace\> | leader-election-role (Role) | controller-manager |
| auth-proxy-rolebinding | \<operator-namespace\> | auth-proxy-role (ClusterRole) | controller-manager |

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| \<trustyai-service\>-tls | kubernetes.io/tls | TLS certificate for TrustyAI Service endpoint | OpenShift service-ca | Yes |
| \<trustyai-service\>-db-credentials | Opaque | Database connection credentials (username, password, host, port, name) | User/Admin | No |
| \<trustyai-service\>-db-ca | Opaque | Database CA certificate for TLS connections | User/Admin | No |
| \<guardrails-orchestrator\>-tls | kubernetes.io/tls | TLS certificate for Guardrails Orchestrator endpoint | OpenShift service-ca | Yes |
| \<nemo-guardrails\>-tls | kubernetes.io/tls | TLS certificate for NeMo Guardrails endpoint | OpenShift service-ca | Yes |

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| /api/v1/* (TrustyAI) | GET, POST, DELETE | Bearer Token (SAR) | kube-rbac-proxy | Kubernetes RBAC via SubjectAccessReview |
| /q/* (Guardrails Orchestrator) | GET, POST | Bearer Token (SAR) | kube-rbac-proxy | Kubernetes RBAC via SubjectAccessReview |
| / (NeMo Guardrails) | GET, POST | Bearer Token (SAR) | kube-rbac-proxy | Kubernetes RBAC via SubjectAccessReview |
| Internal Service Mesh | ALL | mTLS | Istio sidecar | Mutual TLS client certificates |

## Data Flows

### Flow 1: TrustyAI Model Monitoring

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | KServe InferenceService | TrustyAI Service | 8443/TCP | HTTPS | TLS 1.2+ | mTLS (Istio) |
| 2 | TrustyAI Service | PostgreSQL/MySQL | 5432/TCP or 3306/TCP | PostgreSQL/MySQL | TLS 1.2+ (optional) | Username/Password |
| 3 | TrustyAI Service | Prometheus | 9443/TCP | HTTPS | TLS 1.2+ | mTLS |
| 4 | User/Dashboard | TrustyAI Service (via Route) | 443/TCP | HTTPS | TLS 1.2+ | Bearer Token |

### Flow 2: LMEval Job Execution

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User | Kubernetes API | 6443/TCP | HTTPS | TLS 1.3 | Bearer Token |
| 2 | Operator | Kueue API | N/A | In-cluster | N/A | ServiceAccount |
| 3 | LMEval Job Pod | Model Endpoint | 443/TCP or 8080/TCP | HTTPS/HTTP | TLS 1.2+ or None | API Key or mTLS |
| 4 | LMEval Job Pod | Object Storage (S3) | 443/TCP | HTTPS | TLS 1.2+ | AWS Signature V4 |
| 5 | LMES Driver | LMES Job Container | 18080/TCP | HTTP | None | None (sidecar) |

### Flow 3: Guardrails Orchestration

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | LLM Application | Guardrails Gateway | 8090/TCP | HTTP | None | None |
| 2 | Guardrails Gateway | Orchestrator | 8032/TCP | HTTP | None | None |
| 3 | Orchestrator | Built-in Detectors | 8080/TCP | HTTP | None | None |
| 4 | Orchestrator | External Detector (InferenceService) | 443/TCP | HTTPS | TLS 1.2+ | mTLS |
| 5 | Orchestrator | LLM InferenceService | 443/TCP | HTTPS | TLS 1.2+ | mTLS |

### Flow 4: Operator Reconciliation

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Operator | Kubernetes API | 6443/TCP | HTTPS | TLS 1.3 | ServiceAccount Token |
| 2 | Operator | Istio API (CRDs) | 6443/TCP | HTTPS | TLS 1.3 | ServiceAccount Token |
| 3 | Operator | OpenShift Routes API | 6443/TCP | HTTPS | TLS 1.3 | ServiceAccount Token |
| 4 | Operator | KServe API | 6443/TCP | HTTPS | TLS 1.3 | ServiceAccount Token |

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| KServe InferenceServices | CRD Patching | N/A | Kubernetes API | TLS 1.3 | Add payload logging configuration for TrustyAI monitoring |
| Istio Service Mesh | CRD Creation | N/A | Kubernetes API | TLS 1.3 | Configure VirtualService and DestinationRule for routing and mTLS |
| OpenShift Service CA | Certificate Injection | N/A | Kubernetes API | TLS 1.3 | Automated TLS certificate provisioning via annotations |
| Prometheus | ServiceMonitor | 9443/TCP | HTTPS | TLS 1.2+ | Metrics scraping from TrustyAI services |
| Kueue | Workload API | N/A | Kubernetes API | TLS 1.3 | Job queuing and resource quotas for LMEval |
| PostgreSQL/MySQL | Database Connection | 5432/TCP or 3306/TCP | PostgreSQL/MySQL | TLS 1.2+ (optional) | Persistent storage for TrustyAI data |
| S3-compatible Storage | S3 API | 443/TCP | HTTPS | TLS 1.2+ | LMEval job output and artifact storage |

## Recent Changes

| Version | Date | Changes |
|---------|------|---------|
| a2e891d | 2026-03 | - Update UBI9 base image digest<br>- Dependency updates for security patches |
| 744a308 | 2026-02 | - Merge upstream main into rhoai-3.2 branch |
| 3656235 | 2026-02 | - NEMO-Guardrails Integration (#528)<br>- Add NemoGuardrails CRD and controller |
| 2512ef3 | 2026-02 | - Add built-in detector standalone mode (#614)<br>- Allow running detectors without orchestrator |
| 58d22c1 | 2026-02 | - OCI output for LMEvalJob (#603)<br>- Support OCI artifact output format |
| 24d9004 | 2026-02 | - Fix serviceaccount name in cluster role (#613)<br>- Correct RBAC configuration |
| 7dc78dc | 2026-02 | - Fix incorrectly named serviceaccount for orchestrators (#612) |
| 52cc305 | 2026-01 | - Add missing Garak image to base and ODH overlays (#615)<br>- Include Garak detector image configuration |
| 467cdfa | 2026-01 | - Allow Tier 1/2 tests to run on all work branches (#616)<br>- Improve CI/CD test coverage |
| 7a2a173 | 2026-01 | - Merge pull request #1612 from trustyai-explainability/main<br>- Sync with upstream changes |

## Deployment Architecture

### Operator Deployment

- **Image**: Built via Dockerfile.konflux (RHOAI Konflux pipeline)
- **Base Image**: registry.access.redhat.com/ubi9/ubi-minimal
- **Resources**:
  - Requests: 10m CPU, 64Mi memory
  - Limits: 900m CPU, 700Mi memory
- **Replicas**: 1 (leader election enabled)
- **Health Checks**:
  - Liveness: /healthz on port 8081 (15s initial, 20s period)
  - Readiness: /readyz on port 8081 (5s initial, 10s period)
- **Security Context**:
  - runAsNonRoot: true
  - allowPrivilegeEscalation: false
  - capabilities: drop ALL
  - seccompProfile: RuntimeDefault

### TrustyAI Service Deployment

- **Image**: quay.io/trustyai/trustyai-service:latest (configurable via ConfigMap)
- **Sidecars**: kube-rbac-proxy for authentication
- **Storage**: PVC (default) or PostgreSQL/MySQL database
- **Scaling**: Configurable replicas (default 1)
- **Metrics**: Batch size configurable (default 5000)

### LMEval Job

- **Architecture**: Kubernetes Job with Kueue integration
- **Driver**: Sidecar container for job coordination (port 18080)
- **Storage**: S3-compatible object storage for outputs
- **Modes**: Online or offline evaluation (configurable)

### Guardrails Orchestrator Deployment

- **Components**:
  - Orchestrator container (port 8032/8432)
  - Gateway sidecar (port 8090/8490, optional)
  - Built-in detectors (port 8080/8480, optional)
- **Auto-configuration**: Discovers detector InferenceServices via labels
- **Custom Detectors**: Supports user-defined Python detectors via ConfigMap

### NeMo Guardrails Deployment

- **Image**: NVIDIA NeMo Guardrails container
- **Ports**: 8000 (internal), 8443 (with auth proxy)
- **CA Bundle**: Supports custom certificate injection
