# Component: TrustyAI Service Operator

## Metadata
- **Repository**: https://github.com/red-hat-data-services/trustyai-service-operator
- **Version**: 1.39.0
- **Distribution**: RHOAI
- **Languages**: Go 1.23
- **Deployment Type**: Kubernetes Operator (Kubebuilder v4)

## Purpose
**Short**: Kubernetes operator that manages deployment and lifecycle of TrustyAI explainability, monitoring, guardrails, and LLM evaluation services.

**Detailed**: The TrustyAI Service Operator simplifies the deployment and management of various TrustyAI Kubernetes components. It manages the TrustyAI Service for model explainability, fairness monitoring, and drift tracking alongside KServe models; orchestrates FMS-Guardrails for modular LLM guardrailing; deploys NemoGuardrails for additional guardrail capabilities; and provides a job-based architecture for LLM evaluation using the lm-evaluation-harness library. The operator automates service provisioning, storage configuration (PVC or database), TLS certificate management, service mesh integration (Istio), and metrics collection.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| TrustyAI Service Operator | Kubernetes Operator | Manages lifecycle of TrustyAI components via custom resources |
| TrustyAI Service | Deployment | Provides model explainability, fairness monitoring, and drift detection |
| LM Evaluation Driver | Job Controller | Orchestrates language model evaluation jobs |
| Guardrails Orchestrator | Deployment | Coordinates FMS guardrail detectors for LLM safety |
| Nemo Guardrails | Deployment | Provides NVIDIA NeMo guardrails integration |
| Kube-RBAC-Proxy | Sidecar | Provides authentication and authorization for metrics endpoints |

## APIs Exposed

### Custom Resource Definitions (CRDs)

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| trustyai.opendatahub.io | v1 | TrustyAIService | Namespaced | Defines TrustyAI service deployment with storage, metrics, and data configuration |
| trustyai.opendatahub.io | v1alpha1 | TrustyAIService | Namespaced | Legacy version with conversion webhook support |
| trustyai.opendatahub.io | v1alpha1 | LMEvalJob | Namespaced | Defines LLM evaluation jobs with model, tasks, and batch configuration |
| trustyai.opendatahub.io | v1alpha1 | GuardrailsOrchestrator | Namespaced | Configures FMS guardrails orchestrator with detectors and inference service |
| trustyai.opendatahub.io | v1alpha1 | NemoGuardrails | Namespaced | Configures NVIDIA NeMo guardrails deployment |

### HTTP Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /healthz | GET | 8081/TCP | HTTP | None | None | Operator liveness probe |
| /readyz | GET | 8081/TCP | HTTP | None | None | Operator readiness probe |
| /metrics | GET | 8080/TCP | HTTP | None | None | Operator Prometheus metrics (internal) |
| /metrics | GET | 8443/TCP | HTTPS | TLS 1.2+ | kube-rbac-proxy | Operator Prometheus metrics (secured) |
| /q/metrics | GET | 8080/TCP | HTTP | None | None | TrustyAI service Prometheus metrics |
| /q/health/live | GET | 8080/TCP | HTTP | None | None | TrustyAI service liveness probe |
| /q/health/ready | GET | 8080/TCP | HTTP | None | None | TrustyAI service readiness probe |

### gRPC Services

| Service | Port | Protocol | Encryption | Auth | Purpose |
|---------|------|----------|------------|------|---------|
| N/A | N/A | N/A | N/A | N/A | No gRPC services exposed |

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| Kubernetes | 1.19+ | Yes | Container orchestration platform |
| KServe | 0.12.1 | Optional | ML model serving for TrustyAI service integration |
| Istio | Latest | Optional | Service mesh for TLS, routing (VirtualService, DestinationRule) |
| Prometheus Operator | 0.64.1 | Optional | Metrics collection via ServiceMonitor |
| Kueue | 0.6.2 | Optional | Job queueing for LMEvalJob workloads |
| OpenShift | 4.6+ | Optional | Routes for external access, service-serving certificates |

### Internal ODH Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| KServe InferenceService | API (serving.kserve.io) | TrustyAI monitors inference services; GuardrailsOrchestrator patches InferenceServices |
| Model Mesh | Label selector | TrustyAI integrates with ModelMesh serving via label `modelmesh-service: modelmesh-serving` |

## Network Architecture

### Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| controller-manager-metrics-service | ClusterIP | 8443/TCP | https | HTTPS | TLS 1.2+ | kube-rbac-proxy | Internal |
| metrics-service | ClusterIP | 8080/TCP | 8080 | HTTP | None | None | Internal |
| {trustyai-name} | ClusterIP | 80/TCP | 8080 | HTTP | None | None | Internal |
| {trustyai-name} | ClusterIP | 443/TCP | 4443 | HTTPS | TLS (OpenShift service-serving cert) | None | Internal |
| {trustyai-name}-tls | ClusterIP | 443/TCP | 8443 | HTTPS | TLS (OpenShift service-serving cert) | kube-rbac-proxy | Internal |

### Ingress

| Name | Type | Hosts | Port | Protocol | Encryption | TLS Mode | Exposure |
|------|------|-------|------|----------|------------|----------|----------|
| {trustyai-name} | OpenShift Route | Auto-generated | 443/TCP | HTTPS | TLS 1.2+ | Reencrypt | External |

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| Database (PostgreSQL/MySQL) | Varies | JDBC | TLS (optional with verify-ca) | Username/Password | TrustyAI service storage backend |
| KServe InferenceService | 80/TCP, 443/TCP | HTTP/HTTPS | TLS (Istio mTLS) | Service mesh | Monitor model inference data |
| HuggingFace Hub | 443/TCP | HTTPS | TLS 1.2+ | API Token (optional) | Download models/datasets for LMEvalJob |

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
| manager-role | trustyai.opendatahub.io | guardrailsorchestrators, lmevaljobs, nemoguardrails, trustyaiservices | create, delete, get, list, patch, update, watch |
| manager-role | trustyai.opendatahub.io | guardrailsorchestrators/finalizers, lmevaljobs/finalizers, nemoguardrails/finalizers, trustyaiservices/finalizers | update |
| manager-role | trustyai.opendatahub.io | guardrailsorchestrators/status, lmevaljobs/status, nemoguardrails/status, trustyaiservices/status | get, patch, update |
| manager-role | rbac.authorization.k8s.io | clusterrolebindings | create, delete, get, list, update, watch |
| manager-role | coordination.k8s.io | leases | create, get, update |
| proxy-role | authentication.k8s.io | tokenreviews | create |
| proxy-role | authorization.k8s.io | subjectaccessreviews | create |
| leader-election-role | "" | configmaps | get, list, watch, create, update, patch, delete |
| leader-election-role | coordination.k8s.io | leases | get, list, watch, create, update, patch, delete |
| leader-election-role | "" | events | create, patch |

### RBAC - Role Bindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| leader-election-rolebinding | system | leader-election-role | controller-manager |
| manager-rolebinding | cluster-wide | manager-role | controller-manager |
| proxy-rolebinding | cluster-wide | proxy-role | controller-manager |

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| {trustyai-name}-internal | kubernetes.io/tls | TLS certificate for internal service communication | OpenShift service-serving cert | Yes |
| {trustyai-name}-tls | kubernetes.io/tls | TLS certificate for kube-rbac-proxy metrics endpoint | OpenShift service-serving cert | Yes |
| {trustyai-name}-db-credentials | Opaque | Database connection credentials (username, password, host, port, dbname) | User | No |
| {trustyai-name}-db-ca | Opaque | Database CA certificate for TLS connection verification | User | No |

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| /metrics (8443) | GET | Bearer Token (K8s ServiceAccount) | kube-rbac-proxy | TokenReview + SubjectAccessReview |
| TrustyAI Service (443) | All | OpenShift service-serving TLS | Service | mTLS within cluster |
| TrustyAI Route | All | TLS reencrypt | OpenShift Route | External TLS termination, reencrypt to backend |
| Database | All | Username/Password + TLS (optional) | TrustyAI deployment | JDBC with SSL verify-ca mode |

## Data Flows

### Flow 1: TrustyAI Service Deployment

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | Bearer Token |
| 2 | Operator | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 3 | Operator | TrustyAI Service | N/A | N/A | N/A | N/A (creates deployment) |
| 4 | TrustyAI Service | Database | Varies | JDBC | TLS (optional) | Username/Password |
| 5 | TrustyAI Service | PVC | N/A | N/A | N/A | N/A (filesystem) |

### Flow 2: Inference Monitoring

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | KServe InferenceService | TrustyAI Service | 80/TCP or 443/TCP | HTTP/HTTPS | mTLS (Istio) | Service mesh |
| 2 | TrustyAI Service | Database/PVC | Varies | JDBC/Filesystem | TLS (optional) | Username/Password |
| 3 | Prometheus | TrustyAI Service | 8080/TCP | HTTP | None | None |

### Flow 3: LM Evaluation Job

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | Bearer Token |
| 2 | Operator | Kueue API | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 3 | LMEvalJob Pod | HuggingFace Hub | 443/TCP | HTTPS | TLS 1.2+ | API Token (optional) |
| 4 | LMEvalJob Pod | Model Inference Service | Varies | gRPC/HTTP | TLS | API Token/mTLS |
| 5 | LMEvalJob Driver | LMEvalJob Pod | Varies | gRPC | None | None |

### Flow 4: Guardrails Orchestration

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Client | Guardrails Orchestrator | 443/TCP | HTTPS | TLS | Service mesh |
| 2 | Guardrails Orchestrator | Detector InferenceServices | 80/TCP or 443/TCP | HTTP/HTTPS | mTLS (Istio) | Service mesh |
| 3 | Guardrails Orchestrator | LLM InferenceService | 80/TCP or 443/TCP | HTTP/HTTPS | mTLS (Istio) | Service mesh |

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| KServe InferenceService | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | Patch InferenceServices to inject TrustyAI payload processors |
| Istio | Kubernetes API (CRDs) | 6443/TCP | HTTPS | TLS 1.2+ | Create VirtualService and DestinationRule for traffic routing |
| Prometheus | ServiceMonitor | 8080/TCP | HTTP | None | Scrape metrics from TrustyAI service |
| Kueue | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | Submit and manage LMEvalJob workloads in queue |
| OpenShift Routes | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | Create external access routes for TrustyAI service |
| Database (PostgreSQL/MySQL) | JDBC | Varies | JDBC | TLS (optional) | Persist inference data and metrics |

## Recent Changes

| Version | Date | Changes |
|---------|------|---------|
| dea3aba | 2025-01 | - Update UBI9 minimal base image<br>- Sync Konflux pipelineruns<br>- Merge upstream changes |
| 048bef7 | 2025-01 | - Fix urllib3 security vulnerability (upgrade to 2.6.3)<br>- Fix e2e CI test timeout |
| 0ee0629 | 2025-01 | - Update GuardrailsOrchestrator status logic<br>- Upgrade urllib3 to 2.6.0 in tests |
