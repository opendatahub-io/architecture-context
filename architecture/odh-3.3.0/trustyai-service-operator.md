# Component: TrustyAI Service Operator

## Metadata
- **Repository**: https://github.com/opendatahub-io/trustyai-service-operator.git
- **Version**: 1.39.0
- **Distribution**: ODH and RHOAI (both)
- **Languages**: Go, YAML
- **Deployment Type**: Kubernetes Operator

## Purpose
**Short**: Kubernetes operator for deploying and managing TrustyAI services providing model explainability, fairness monitoring, LLM evaluation, and guardrails.

**Detailed**: The TrustyAI Service Operator simplifies the deployment and management of AI governance and monitoring components in Kubernetes. It manages several key services: TrustyAI Service for model explainability, fairness monitoring, and data drift detection on KServe models; EvalHub for LLM evaluation and benchmarking using frameworks like EleutherAI's lm-evaluation-harness and integrating with MLFlow for experiment tracking; FMS-Guardrails for implementing modular guardrails on Foundation Model deployments; and NemoGuardrails for additional LLM safety mechanisms. The operator handles deployment lifecycle, RBAC provisioning for multi-tenant environments, database integration for persistence (PostgreSQL), metrics collection, and integration with model serving infrastructure. It provides a unified interface for managing responsible AI tooling across the platform.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| TrustyAI Operator | Go Controller | Reconciles TrustyAI-related CRDs and manages service deployments |
| TrustyAIService Controller | Reconciler | Deploys TrustyAI explainability service alongside KServe models |
| EvalHub Controller | Reconciler | Manages LLM evaluation hub with provider integration and MLFlow tracking |
| LMEvalJob Controller | Reconciler | Creates and manages LLM evaluation jobs as Kubernetes Jobs |
| GuardrailsOrchestrator Controller | Reconciler | Deploys FMS Guardrails orchestrator for LLM safety |
| NemoGuardrails Controller | Reconciler | Manages NVIDIA NeMo Guardrails deployments |

## APIs Exposed

### Custom Resource Definitions (CRDs)

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| trustyai.opendatahub.io | v1 | TrustyAIService | Namespaced | Deploy TrustyAI service for model monitoring and explainability |
| trustyai.opendatahub.io | v1 | EvalHub | Namespaced | Deploy LLM evaluation hub with provider management |
| trustyai.opendatahub.io | v1 | LMEvalJob | Namespaced | Submit LLM evaluation jobs using lm-evaluation-harness |
| trustyai.opendatahub.io | v1 | GuardrailsOrchestrator | Namespaced | Deploy FMS Guardrails framework for LLM safety |
| trustyai.opendatahub.io | v1 | NemoGuardrails | Namespaced | Deploy NVIDIA NeMo Guardrails for LLM safety |

### HTTP Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /metrics | GET | 8080/TCP | HTTP | None | None | Prometheus metrics for TrustyAI service |
| /q/metrics | GET | 8080/TCP | HTTP | None | None | Quarkus application metrics |
| /info/names | GET | 8080/TCP | HTTP | TLS 1.2+ (optional) | Bearer Token | List available models being monitored |
| /info/metrics | GET | 8080/TCP | HTTP | TLS 1.2+ (optional) | Bearer Token | List available fairness and drift metrics |
| /metrics/spd | POST | 8080/TCP | HTTP | TLS 1.2+ (optional) | Bearer Token | Calculate Statistical Parity Difference |
| /metrics/dir | POST | 8080/TCP | HTTP | TLS 1.2+ (optional) | Bearer Token | Calculate Disparate Impact Ratio |
| /explainers/local/shap | POST | 8080/TCP | HTTP | TLS 1.2+ (optional) | Bearer Token | Generate SHAP explanations for predictions |
| /api/v1/evaluations | GET, POST | 8000/TCP | HTTP | TLS 1.2+ (optional) | Bearer Token | EvalHub API for LLM evaluations |
| /api/v1/jobs | GET, POST | 8000/TCP | HTTP | TLS 1.2+ (optional) | Bearer Token | EvalHub job management API |

### gRPC Services
No gRPC services are exposed. TrustyAI components communicate via HTTP/REST APIs.

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| TrustyAI Service | 0.25+ | Yes | Core explainability and fairness monitoring service |
| PostgreSQL | 13+ | No | Persistent storage for TrustyAI data and EvalHub state |
| EleutherAI lm-eval-harness | Latest | No | LLM evaluation framework (EvalHub) |
| MLFlow | 2.x | No | Experiment tracking for LLM evaluations |
| FMS Guardrails | 0.x | No | Foundation Model guardrails framework |
| NVIDIA NeMo Guardrails | Latest | No | LLM safety and guardrails toolkit |
| OpenTelemetry | 1.x | No | Distributed tracing and observability |

### Internal ODH Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| KServe | Inference Data Collection | Monitors model inferences for fairness and drift analysis |
| Model Registry | API | Retrieve model metadata and versioning information |
| ODH Dashboard | UI Integration | Provides UI for managing TrustyAI services and viewing metrics |
| Model Serving | Sidecar Integration | Deploys TrustyAI service alongside model servers |
| Data Science Pipelines | Job Integration | Execute LM evaluation jobs as pipeline steps |

## Network Architecture

### Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| trustyai-service | ClusterIP | 8080/TCP | 8080 | HTTP | TLS 1.2+ (optional) | Bearer Token | Internal |
| evalhub-service | ClusterIP | 8000/TCP | 8000 | HTTP | TLS 1.2+ (optional) | Bearer Token | Internal |
| guardrails-service | ClusterIP | 8080/TCP | 8080 | HTTP | TLS 1.2+ (optional) | Bearer Token | Internal |
| trustyai-operator-metrics | ClusterIP | 8443/TCP | 8443 | HTTPS | TLS 1.2+ | mTLS | Internal |

### Ingress

| Name | Type | Hosts | Port | Protocol | Encryption | TLS Mode | Exposure |
|------|------|-------|------|----------|------------|----------|----------|
| trustyai-route | OpenShift Route | *.apps.cluster | 443/TCP | HTTPS | TLS 1.2+ | Edge Termination | External |
| evalhub-route | OpenShift Route | *.apps.cluster | 443/TCP | HTTPS | TLS 1.2+ | Edge Termination | External |

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| PostgreSQL Database | 5432/TCP | PostgreSQL | TLS 1.2+ (optional) | Password | Persist TrustyAI data and EvalHub state |
| KServe Model Servers | 8080/TCP | HTTP | TLS 1.2+ (optional) | Bearer Token | Collect inference payloads for monitoring |
| MLFlow Server | 5000/TCP | HTTP | None | None | Track LLM evaluation experiments |
| S3 Storage | 443/TCP | HTTPS | TLS 1.2+ | AWS credentials | Store evaluation datasets and results |
| HuggingFace Hub | 443/TCP | HTTPS | TLS 1.2+ | Token | Download LLM models for evaluation |

## Security

### RBAC - Cluster Roles

| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|
| manager-role | "" | pods, services, configmaps, secrets, serviceaccounts, persistentvolumeclaims | create, delete, get, list, patch, update, watch |
| manager-role | apps | deployments | create, delete, get, list, patch, update, watch |
| manager-role | batch | jobs | create, delete, get, list, patch, update, watch |
| manager-role | trustyai.opendatahub.io | trustyaiservices, evalhubs, lmevaljobs, guardrailsorchestrators, nemoguardrails | create, delete, get, list, patch, update, watch |
| manager-role | serving.kserve.io | inferenceservices | get, list, watch |
| manager-role | route.openshift.io | routes | create, delete, get, list, patch, update, watch |
| evalhub-mlflow-role | "" | secrets, serviceaccounts, configmaps | create, delete, get, list, patch, update, watch |
| evalhub-mlflow-role | batch | jobs | create, delete, get, list, patch, update, watch |

### RBAC - Role Bindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| manager-rolebinding | opendatahub | manager-role | trustyai-operator |
| evalhub-mlflow-binding | <tenant-namespaces> | evalhub-mlflow-role | evalhub-mlflow |

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| trustyai-db-credentials | Opaque | PostgreSQL database credentials | User-provided / Operator | No |
| evalhub-database-secret | Opaque | EvalHub PostgreSQL configuration and credentials | User-provided / Operator | No |
| aws-s3-credentials | Opaque | S3 access for evaluation datasets and results | User-provided | No |
| mlflow-secret | Opaque | MLFlow server authentication credentials | User-provided | No |
| huggingface-token | Opaque | HuggingFace API token for model downloads | User-provided | No |
| trustyai-service-oauth-proxy | Opaque | OAuth proxy token for service authentication | cert-manager / OpenShift | Yes |

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| TrustyAI Service APIs | GET, POST | Bearer Token (JWT) | OAuth Proxy | Token validation via OAuth |
| EvalHub APIs | GET, POST | Bearer Token (JWT) | TLS + AuthZ ConfigMap | Token validation and role-based access |
| Operator Metrics | GET | mTLS | kube-rbac-proxy | Mutual TLS client certificates |
| KServe Integration | POST | Bearer Token | KServe Sidecar | Token-based authentication |

## Data Flows

### Flow 1: Model Inference Monitoring

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Client | KServe Model Server | 8080/TCP | HTTP | TLS 1.2+ (optional) | Bearer Token |
| 2 | KServe Sidecar | TrustyAI Service | 8080/TCP | HTTP | TLS 1.2+ (optional) | Bearer Token |
| 3 | TrustyAI Service | PostgreSQL DB | 5432/TCP | PostgreSQL | TLS 1.2+ (optional) | Password |
| 4 | TrustyAI Service | Client (metrics response) | 8080/TCP | HTTP | TLS 1.2+ (optional) | Bearer Token |

### Flow 2: LLM Evaluation Job

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User/Dashboard | Kubernetes API (create LMEvalJob) | 6443/TCP | HTTPS | TLS 1.2+ | Bearer Token |
| 2 | TrustyAI Operator | Kubernetes API (create Job) | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 3 | Evaluation Job Pod | HuggingFace Hub | 443/TCP | HTTPS | TLS 1.2+ | Token |
| 4 | Evaluation Job Pod | S3 Storage | 443/TCP | HTTPS | TLS 1.2+ | AWS credentials |
| 5 | Evaluation Job Pod | MLFlow Server | 5000/TCP | HTTP | None | None |
| 6 | Evaluation Job Pod | EvalHub API | 8000/TCP | HTTP | TLS 1.2+ (optional) | Bearer Token |

### Flow 3: Fairness Metric Calculation

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User/Dashboard | TrustyAI Service API | 8080/TCP | HTTP | TLS 1.2+ (optional) | Bearer Token |
| 2 | TrustyAI Service | PostgreSQL DB | 5432/TCP | PostgreSQL | TLS 1.2+ (optional) | Password |
| 3 | TrustyAI Service | User/Dashboard (metric result) | 8080/TCP | HTTP | TLS 1.2+ (optional) | Bearer Token |

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| KServe InferenceServices | HTTP Sidecar | 8080/TCP | HTTP | TLS 1.2+ (optional) | Collect inference payloads for monitoring |
| PostgreSQL Database | PostgreSQL Protocol | 5432/TCP | PostgreSQL | TLS 1.2+ (optional) | Persist monitoring data and evaluation results |
| MLFlow Server | HTTP API | 5000/TCP | HTTP | None | Track experiment metrics for LLM evaluations |
| Kubernetes API | REST API | 6443/TCP | HTTPS | TLS 1.2+ | Manage resources (Jobs, Deployments, ConfigMaps) |
| Prometheus | Metrics Scraping | 8080/TCP, 8443/TCP | HTTP/HTTPS | TLS 1.2+ (optional) | Collect service and operator metrics |
| ODH Dashboard | REST API | 8080/TCP | HTTP | TLS 1.2+ (optional) | UI for service management and metric visualization |

## Recent Changes

| Version | Date | Changes |
|---------|------|---------|
| 1.39.0 | 2025-01 | - Remove init container default tag<br>- Create missing MLFlow service SA RoleBinding in tenant namespaces<br>- Provision tenant namespace RBAC for multi-tenant job creation<br>- Add Garak-KFP provider to kustomization<br>- Fix Multi-tenancy RBAC gaps<br>- Add EvalHub image to config |
| 1.38.0 | 2024-12 | - Remove kube-rbac-proxy integration, serve TLS directly in EvalHub<br>- Add authorization configuration to EvalHub ConfigMap<br>- Update Garak provider ConfigMap with supported benchmarks<br>- Expose OTEL configuration in CR spec (RHOAIENG-51312)<br>- Providers as ConfigMaps<br>- Add update verb to MLFlow jobs ClusterRole for run creation |
| 1.37.0 | 2024-12 | - Add MLFlow integration for experiment tracking<br>- Inject PostgreSQL config via database secret<br>- Add RBAC, ServiceAccounts, and Roles for EvalHub<br>- Avoid double-prefix in resource names |
