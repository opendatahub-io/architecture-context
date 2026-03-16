# Platform: Red Hat OpenShift AI 3.0

## Metadata
- **Distribution**: RHOAI
- **Version**: 3.0
- **Release Date**: 2025-Q4 (GA), 2026-03-16 (analyzed)
- **Base Platform**: OpenShift Container Platform 4.12+
- **Components Analyzed**: 13
- **Architecture Directory**: architecture/rhoai-3.0

## Platform Overview

Red Hat OpenShift AI (RHOAI) 3.0 is an enterprise AI/ML platform built on OpenShift that provides end-to-end capabilities for data scientists and ML engineers to develop, train, deploy, and monitor machine learning models at scale. The platform integrates multiple open-source projects into a cohesive ecosystem managed by a central operator, providing web-based dashboards, notebook environments, distributed training, model serving, feature stores, model registries, and AI governance tools.

RHOAI 3.0 introduces a fundamental architectural shift from version 2.x, transitioning from OpenShift Routes with oauth-proxy sidecars to a Gateway API-based ingress architecture with kube-auth-proxy authentication and EnvoyFilter-based service mesh integration. This new architecture provides centralized authentication at the gateway layer, per-component RBAC enforcement via kube-rbac-proxy sidecars, native OIDC support for ROSA environments, and improved scalability for multi-tenant deployments. The platform supports multiple deployment modes including serverless (Knative/Istio) and raw Kubernetes deployments, GPU acceleration via NVIDIA CUDA and AMD ROCm, and multi-architecture builds (x86_64, aarch64, ppc64le, s390x).

The RHOAI platform is designed for enterprise AI/ML workflows spanning data preparation, exploratory analysis, distributed model training, hyperparameter tuning, model versioning and registration, real-time and batch inference serving, model monitoring and explainability, feature engineering, and AI safety guardrails. All components are FIPS 140-2 compliant, built via Konflux CI/CD pipelines, and deployed using GitOps-compatible custom resources.

## Component Inventory

| Component | Type | Version | Purpose |
|-----------|------|---------|---------|
| RHODS Operator | Operator | v1.6.0-3582 | Platform orchestrator managing all component lifecycles and Gateway API infrastructure |
| ODH Dashboard | Web UI | v1.21.0-18 | Centralized web console for managing projects, notebooks, pipelines, and model serving |
| Notebook Controller | Operator | v1.27.0-rhods-1345 | Manages Jupyter notebook StatefulSets with culling and Istio VirtualService integration |
| Notebooks (Workbenches) | Container Images | v3.0.0-1 | JupyterLab, RStudio, CodeServer workbench images with CPU/GPU variants |
| Data Science Pipelines Operator | Operator | v0.0.1 | Deploys Kubeflow Pipelines 2.5.0 for ML workflow orchestration via Argo Workflows |
| KServe | Operator | 5e4621c70 | Model serving platform with serverless autoscaling and multi-framework support |
| ODH Model Controller | Operator | v1.27.0-rhods-1087 | Extends KServe with OpenShift Routes, RBAC, monitoring, and NIM integration |
| Model Registry Operator | Operator | eb4d8e5 | Manages ML model metadata storage backed by PostgreSQL/MySQL with gRPC/REST APIs |
| Training Operator | Operator | v1.9.0 | Kubeflow Training Operator for distributed ML training (PyTorch, TensorFlow, MPI, etc.) |
| KubeRay Operator | Operator | dac6aae7 | Manages Ray clusters for distributed computing and reinforcement learning |
| TrustyAI Service Operator | Operator | v1.39.0 | Deploys explainability services, LM evaluation jobs, and AI guardrails orchestration |
| Feast Operator | Operator | e43f213a4 | Manages feature store deployments for online/offline feature serving |
| Llama Stack Operator | Operator | v0.4.0 | Deploys LlamaStack distributions for LLM inference across multiple backends |

## Component Relationships

### Dependency Graph

```
RHODS Operator (Platform Core)
├── Gateway Controller → Gateway API Infrastructure (openshift-ingress)
│   ├── GatewayClass (data-science-gateway-class)
│   ├── Gateway (data-science-gateway)
│   ├── EnvoyFilter (authn-filter) → kube-auth-proxy authentication
│   ├── kube-auth-proxy Deployment (OAuth2/OIDC)
│   └── OAuth Callback HTTPRoute
│
├── Dashboard Component Controller → ODH Dashboard
│   ├── Dashboard Frontend (React SPA)
│   └── Dashboard Backend (Node.js/Fastify) → Kubernetes API
│       ├── Notebook Controller CRDs (Notebook)
│       ├── KServe CRDs (InferenceService, ServingRuntime)
│       ├── Model Registry CRDs (ModelRegistry)
│       ├── DSP CRDs (DataSciencePipelinesApplication)
│       ├── Feast CRDs (FeatureStore)
│       └── Llama Stack CRDs (LlamaStackDistribution)
│
├── Workbenches Component Controller → Notebook Controller
│   ├── NotebookReconciler → StatefulSets + Services + HTTPRoutes
│   ├── CullingReconciler → Idle notebook detection
│   └── Notebook Workbench Images (JupyterLab, RStudio, CodeServer)
│       ├── Minimal CPU/GPU variants
│       ├── DataScience libraries (pandas, numpy, scikit-learn)
│       ├── PyTorch/TensorFlow frameworks
│       └── TrustyAI explainability tools
│
├── DataSciencePipelines Component Controller → DSP Operator
│   ├── DSPO Controller → DSP Instance Deployment
│   │   ├── DSP API Server (KFP v2 REST/gRPC)
│   │   ├── Persistence Agent → MariaDB
│   │   ├── Workflow Controller (Argo Workflows)
│   │   ├── Scheduled Workflow Controller
│   │   └── ML Metadata (MLMD) gRPC Server
│   └── DSP API Server → KServe (model deployment)
│                      → Model Registry (model metadata)
│                      → S3 Storage (artifact storage)
│
├── Kserve Component Controller → KServe Operator
│   ├── KServe Controller Manager
│   │   ├── InferenceService Controller → Knative/Raw Deployments
│   │   ├── ServingRuntime Controller → Runtime templates
│   │   ├── LLMInferenceService Controller → vLLM/TGI runtimes
│   │   └── InferenceGraph Controller → Multi-model pipelines
│   └── ODH Model Controller (OpenShift extension)
│       ├── InferenceService integration → Routes + NetworkPolicies + ServiceMonitors
│       ├── NIM Account Controller → NVIDIA NIM credentials + pull secrets
│       └── Model Registry integration (optional)
│
├── ModelRegistry Component Controller → Model Registry Operator
│   ├── ModelRegistry Controller → REST + gRPC Services
│   │   ├── REST Server (model_registry v1alpha3 API)
│   │   ├── gRPC Server (ML Metadata)
│   │   └── kube-rbac-proxy (authentication)
│   └── PostgreSQL/MySQL Database (metadata persistence)
│
├── TrainingOperator Component Controller → Training Operator
│   ├── PyTorchJob Controller → Distributed PyTorch training
│   ├── TFJob Controller → Distributed TensorFlow training
│   ├── MPIJob Controller → MPI-based HPC workloads
│   ├── XGBoostJob Controller → Distributed XGBoost
│   ├── JAXJob Controller → Distributed JAX training
│   └── Training pods → S3 Storage (datasets/checkpoints)
│                     → Model Registry (trained model registration)
│
├── Ray Component Controller → KubeRay Operator
│   ├── RayCluster Controller → Head + Worker pods
│   ├── RayJob Controller → Batch job execution
│   └── RayService Controller → Ray Serve for ML model serving
│
├── TrustyAI Component Controller → TrustyAI Service Operator
│   ├── TrustyAIService Controller → Explainability service deployment
│   ├── LMEvalJob Controller → Language model evaluation
│   ├── GuardrailsOrchestrator Controller → AI safety guardrails
│   └── KServe Integration → InferenceService guardrails injection
│
├── FeastOperator Component Controller → Feast Operator
│   ├── FeatureStore Controller → Online/Offline/Registry servers
│   └── Storage backends (SQLite, PostgreSQL, Snowflake, S3, GCS)
│
└── LlamaStackOperator Component Controller → Llama Stack Operator
    ├── LlamaStackDistribution Controller → Llama Stack server deployment
    └── Backend distributions (Ollama, vLLM, TGI, Bedrock, Together)
```

### Central Components

The following components serve as core platform services with the most dependencies:

1. **RHODS Operator**: Platform orchestrator deploying all components and Gateway API infrastructure
2. **ODH Dashboard**: Central UI aggregating all component statuses and providing unified management
3. **Kubernetes API Server**: All components depend on K8s API for resource management and reconciliation
4. **Gateway (data-science-gateway)**: Centralized ingress point for all RHOAI workloads with authentication
5. **kube-auth-proxy**: OAuth2/OIDC authentication service for Gateway-based access
6. **KServe**: Model serving platform integrated by DSP, Training Operator, Model Registry, and TrustyAI
7. **Model Registry**: Model metadata service consumed by KServe, DSP, and Training Operator
8. **S3 Storage**: External object storage used by DSP, KServe, Training Operator, Feast, and Notebooks

### Integration Patterns

1. **Gateway API + HTTPRoute Pattern** (RHOAI 3.x):
   - Component controllers create HTTPRoute CRs referencing parent Gateway (`data-science-gateway`)
   - EnvoyFilter ext_authz enforces authentication at gateway layer
   - kube-rbac-proxy sidecars provide per-workload RBAC enforcement
   - Pattern: External request → Gateway → EnvoyFilter authz → HTTPRoute → kube-rbac-proxy → app

2. **CRD Creation and Watching**:
   - Dashboard watches CRDs from all components for status updates
   - DSP creates KServe InferenceServices for model deployment
   - Training Operator creates Model Registry entries for trained models
   - TrustyAI watches and patches KServe InferenceServices for guardrails injection
   - ODH Model Controller watches KServe resources and creates Routes, ServiceMonitors, NetworkPolicies

3. **API Proxy Pattern**:
   - Dashboard backend proxies API requests to Kubernetes API with ServiceAccount token
   - DSP API Server proxies to KServe, Model Registry, and S3 storage
   - Notebook pods access KServe inference endpoints via service mesh

4. **Event-Driven Reconciliation**:
   - All operators use controller-runtime watch patterns for CRD reconciliation
   - Finalizers ensure cleanup of dependent resources (Routes, Services, PVCs)
   - Status conditions propagate from child resources to parent CRs

5. **Metrics Collection**:
   - Operators expose /metrics endpoints (port 8080 or 8443)
   - ServiceMonitors/PodMonitors created by component controllers
   - Prometheus federation to OpenShift cluster monitoring

## Platform Network Architecture

### Namespaces

| Namespace | Purpose | Components |
|-----------|---------|------------|
| redhat-ods-operator | Operator runtime | RHODS Operator controller manager |
| redhat-ods-applications | Platform applications | Dashboard, Notebook Controller, Model Controller, component operators |
| redhat-ods-monitoring | Platform monitoring | Prometheus, Alertmanager, Blackbox Exporter, ServiceMonitors |
| openshift-ingress | Gateway infrastructure | data-science-gateway, kube-auth-proxy, EnvoyFilter, OAuth callback HTTPRoute |
| opendatahub (ODH variant) | ODH applications | Same as redhat-ods-applications for ODH distribution |
| User namespaces (multi-tenant) | User workloads | Notebooks, DSP instances, InferenceServices, Training jobs, Ray clusters, Feature stores |

### External Ingress Points

| Component | Ingress Type | Hosts | Port | Protocol | Encryption | Purpose |
|-----------|--------------|-------|------|----------|------------|---------|
| Gateway (data-science-gateway) | Gateway API v1 | *.apps.<cluster-domain> | 443/TCP | HTTPS | TLS 1.3 | Platform-wide ingress gateway for all RHOAI workloads |
| ODH Dashboard | HTTPRoute → Gateway | dashboard-<namespace>.apps.<domain> | 443/TCP | HTTPS | TLS 1.3 | Web UI access via Gateway + kube-auth-proxy |
| Notebooks | HTTPRoute → Gateway | <notebook>-<namespace>.apps.<domain> | 443/TCP | HTTPS | TLS 1.3 | JupyterLab/RStudio/CodeServer workbenches |
| KServe InferenceService | HTTPRoute → Gateway | <isvc>-<namespace>.apps.<domain> | 443/TCP | HTTPS | TLS 1.3 | Model inference endpoints (serverless/raw modes) |
| DSP API Server | HTTPRoute → Gateway or Route | ds-pipeline-<name>.apps.<domain> | 443/TCP | HTTPS | TLS 1.2+ | Kubeflow Pipelines API for workflow submission |
| Model Registry | HTTPRoute or Route | <registry>-https-<namespace>.apps.<domain> | 443/TCP | HTTPS | TLS 1.2+ | Model metadata REST API |
| TrustyAI Service | HTTPRoute or Route | <trustyai>-<namespace>.apps.<domain> | 443/TCP | HTTPS | TLS 1.2+ | Explainability and bias detection API |
| Guardrails Orchestrator | Route | <gorch>-https-<namespace>.apps.<domain> | 443/TCP | HTTPS | TLS 1.2+ | AI safety guardrails API |

**Authentication Flow (RHOAI 3.x)**:
1. External client → Gateway (443/TCP)
2. EnvoyFilter ext_authz → kube-auth-proxy (8443/TCP HTTPS)
3. kube-auth-proxy validates OAuth/OIDC session cookie
4. If valid: EnvoyFilter allows → HTTPRoute → kube-rbac-proxy sidecar → application
5. If invalid: Redirect to OpenShift OAuth or external OIDC provider
6. Post-login: OAuth callback → kube-auth-proxy sets session cookie

### External Egress Dependencies

| Component | Destination | Port | Protocol | Encryption | Purpose |
|-----------|-------------|------|----------|------------|---------|
| KServe Storage Initializer | S3 (AWS/Minio/Ceph) | 443/TCP | HTTPS | TLS 1.2+ | Download model artifacts for inference |
| KServe Storage Initializer | GCS (Google Cloud Storage) | 443/TCP | HTTPS | TLS 1.2+ | Download model artifacts |
| KServe Storage Initializer | Azure Blob Storage | 443/TCP | HTTPS | TLS 1.2+ | Download model artifacts |
| KServe Storage Initializer | HuggingFace Hub | 443/TCP | HTTPS | TLS 1.2+ | Download HuggingFace models |
| DSP Operator | S3-compatible Storage | 443/TCP | HTTPS | TLS 1.2+ | Pipeline artifact storage (models, datasets, outputs) |
| DSP Operator | External PostgreSQL/MySQL | 3306/5432/TCP | MySQL/PostgreSQL | TLS 1.2+ | Pipeline metadata persistence |
| Training Operator | S3 Storage | 443/TCP | HTTPS | TLS 1.2+ | Training datasets and model checkpoint storage |
| Notebooks | PyPI (files.pythonhosted.org) | 443/TCP | HTTPS | TLS 1.2+ | Python package installation |
| Notebooks | CRAN (cran.rstudio.com) | 443/TCP | HTTPS | TLS 1.2+ | R package installation |
| Notebooks | GitHub | 443/TCP | HTTPS | TLS 1.2+ | Git repository access |
| Notebooks | S3 Storage | 443/TCP | HTTPS | TLS 1.2+ | Access training data and save models |
| All Operators | Container Registries (quay.io, registry.redhat.io) | 443/TCP | HTTPS | TLS 1.2+ | Pull component container images |
| RHODS Operator | OpenShift OAuth Server | 443/TCP | HTTPS | TLS 1.2+ | IntegratedOAuth authentication mode |
| RHODS Operator | External OIDC Provider | 443/TCP | HTTPS | TLS 1.2+ | OIDC authentication (ROSA/external IdP) |
| Model Registry | PostgreSQL/MySQL Database | 5432/3306/TCP | PostgreSQL/MySQL | TLS 1.2+ | Model metadata persistence |
| Feast | Storage Backends (S3/GCS/Snowflake) | 443/TCP | HTTPS/Native | TLS 1.2+ | Feature data persistence |
| Feast | PostgreSQL/Snowflake Database | 5432/443/TCP | PostgreSQL/HTTPS | TLS 1.2+ | Feature registry metadata |
| ODH Model Controller | NVIDIA NGC API | 443/TCP | HTTPS | TLS 1.2+ | NIM account validation and model catalog access |
| TrustyAI LMEvalJob | Model Registries | 443/TCP | HTTPS | TLS 1.2+ | Language model evaluation dataset download |

### Internal Service Mesh

| Setting | Value | Components Using |
|---------|-------|------------------|
| mTLS Mode (optional) | PERMISSIVE/STRICT | KServe (serverless mode), DSP, Model Registry (optional) |
| Peer Authentication | Istio PeerAuthentication | KServe InferenceServices when deployed in serverless mode |
| EnvoyFilter ext_authz | Gateway authentication | Gateway (data-science-gateway) with kube-auth-proxy integration |
| VirtualService | Traffic routing | KServe InferenceServices (serverless), Notebooks (when USE_ISTIO=true) |
| DestinationRule | mTLS config | kube-auth-proxy service (ISTIO_MUTUAL mode) |

**Note**: RHOAI 3.0 supports both service mesh (Istio/OSSM) and raw Kubernetes deployments. Service mesh is optional but recommended for serverless KServe deployments and advanced traffic management.

## Platform Security

### RBAC Summary

Platform operators require extensive cluster-level permissions to manage components across namespaces. Key RBAC patterns:

| Component | ClusterRole Key Permissions | API Groups | Resources |
|-----------|----------------------------|------------|-----------|
| RHODS Operator | Platform orchestration | apps, rbac, gateway.networking.k8s.io, networking.istio.io | deployments, roles, rolebindings, gateways, httproutes, envoyfilters, datascienceclusters, dscinitializations |
| RHODS Operator | OAuth integration | oauth.openshift.io, config.openshift.io | oauthclients, authentications, ingresses |
| Notebook Controller | Notebook lifecycle | kubeflow.org, networking.istio.io, apps | notebooks, statefulsets, virtualservices |
| DSP Operator | Pipeline orchestration | datasciencepipelinesapplications.opendatahub.io, argoproj.io | datasciencepipelinesapplications, workflows, workflowtemplates, cronworkflows |
| KServe Controller | Model serving | serving.kserve.io, serving.knative.dev, networking.istio.io | inferenceservices, servingruntimes, services, virtualservices, destinationrules |
| ODH Model Controller | KServe extension | serving.kserve.io, route.openshift.io, monitoring.coreos.com | inferenceservices, routes, servicemonitors, podmonitors |
| Model Registry Operator | Registry lifecycle | modelregistry.opendatahub.io, route.openshift.io | modelregistries, routes, deployments, services |
| Training Operator | Training jobs | kubeflow.org, scheduling.volcano.sh | pytorchjobs, tfjobs, mpijobs, xgboostjobs, jaxjobs, paddlejobs, podgroups |
| KubeRay Operator | Ray clusters | ray.io, cert-manager.io, gateway.networking.k8s.io | rayclusters, rayjobs, rayservices, certificates, httproutes |
| TrustyAI Operator | Explainability/guardrails | trustyai.opendatahub.io, serving.kserve.io, kueue.x-k8s.io | trustyaiservices, lmevaljobs, guardrailsorchestrators, inferenceservices, workloads |
| Feast Operator | Feature stores | feast.dev, route.openshift.io | featurestores, routes, deployments, cronjobs |
| Llama Stack Operator | LLM inference | llamastack.io, apps, networking.k8s.io | llamastackdistributions, deployments, networkpolicies |

### Secrets Inventory

| Component | Secret Name Pattern | Type | Purpose |
|-----------|---------------------|------|---------|
| RHODS Operator | kube-auth-proxy-creds | Opaque | OAuth2 proxy credentials (clientSecret, cookieSecret) |
| RHODS Operator | kube-auth-proxy-tls | kubernetes.io/tls | TLS certificate for kube-auth-proxy service |
| RHODS Operator | default-gateway-tls | kubernetes.io/tls | Gateway TLS certificate (from OpenShift ingress) |
| Dashboard | dashboard-proxy-tls | kubernetes.io/tls | kube-rbac-proxy TLS cert for Dashboard metrics |
| Notebooks | {notebook}-oauth-config | Opaque | OAuth proxy configuration for notebook access |
| DSP Operator | ds-pipelines-proxy-tls-{name} | kubernetes.io/tls | OAuth proxy TLS certificate (auto-rotated) |
| DSP Operator | {db-credentials-secret} | Opaque | Database username/password for pipeline metadata |
| DSP Operator | {storage-credentials-secret} | Opaque | S3 access key and secret key for artifacts |
| KServe | kserve-webhook-server-cert | kubernetes.io/tls | Webhook server TLS certificate (cert-manager) |
| KServe | storage-config | Opaque | S3/GCS/Azure credentials for model storage |
| Model Registry | {registry}-kube-rbac-proxy | kubernetes.io/tls | kube-rbac-proxy TLS for registry API |
| Model Registry | model-registry-db | Opaque | Database connection password |
| Model Registry | {registry}-postgres-ssl-cert/key | Opaque | PostgreSQL client certificates (optional) |
| Training Operator | training-operator-webhook-cert | kubernetes.io/tls | Validation webhook TLS certificate |
| TrustyAI Operator | {trustyai}-internal | kubernetes.io/tls | TLS for internal service communication |
| TrustyAI Operator | {trustyai}-db-credentials | Opaque | Database credentials for TrustyAI storage |
| Feast Operator | {name}-tls | kubernetes.io/tls | TLS certificates for Feast services |
| Feast Operator | oidc-secret | Opaque | OIDC authentication credentials |
| Feast Operator | {storage}-credentials | Opaque | Storage backend credentials (S3/GCS/DB) |

**Auto-Rotation**: Secrets provisioned by OpenShift service-serving-cert-signer or cert-manager support automatic rotation. User-provisioned secrets require manual rotation.

### Authentication Mechanisms

| Pattern | Components Using | Enforcement Point |
|---------|------------------|-------------------|
| OAuth2 (OpenShift IntegratedOAuth) | Gateway (kube-auth-proxy), Dashboard, Notebooks | OpenShift OAuth server validates credentials → session cookie |
| OIDC (External IdP) | Gateway (kube-auth-proxy) for ROSA | External OIDC provider (Keycloak, etc.) → JWT tokens |
| Bearer Tokens (Kubernetes ServiceAccount) | All operators, inter-component API calls | Kubernetes API Server RBAC authorization |
| kube-rbac-proxy per-workload | Notebooks, KServe, Dashboard, Model Registry, TrustyAI | Kubernetes SubjectAccessReview before proxying to application |
| mTLS (Service Mesh) | KServe (serverless), DSP (optional), Model Registry (optional) | Istio PeerAuthentication + mTLS certificates |
| AWS IAM Credentials | S3 storage access (KServe, DSP, Training, Notebooks) | AWS SigV4 authentication to S3 endpoints |
| Database Passwords | DSP, Model Registry, TrustyAI, Feast | MySQL/PostgreSQL connection authentication |
| API Keys | NVIDIA NIM (NGC API), HuggingFace Hub, OIDC client secrets | API key validation by external services |

**RHOAI 3.x Authentication Architecture**:
- **Gateway-level**: OAuth2/OIDC authentication via kube-auth-proxy + EnvoyFilter ext_authz
- **Component-level**: kube-rbac-proxy sidecars enforce Kubernetes RBAC per workload
- **Service-to-service**: ServiceAccount Bearer tokens with optional mTLS (service mesh)

## Platform APIs

### Custom Resource Definitions

| Component | API Group | Kind | Scope | Purpose |
|-----------|-----------|------|-------|---------|
| RHODS Operator | datasciencecluster.opendatahub.io | DataScienceCluster | Cluster | Defines enabled components and platform configuration |
| RHODS Operator | dscinitialization.opendatahub.io | DSCInitialization | Cluster | Platform initialization, monitoring, CA bundles, namespaces |
| RHODS Operator | services.platform.opendatahub.io | GatewayConfig, Auth, Monitoring | Cluster | Platform ingress gateway, authentication, monitoring configuration |
| RHODS Operator | components.platform.opendatahub.io | Dashboard, Workbenches, Kserve, DataSciencePipelines, etc. | Cluster | Component-specific configuration and status |
| Notebook Controller | kubeflow.org | Notebook | Namespaced | Jupyter notebook instances with PodSpec template |
| DSP Operator | datasciencepipelinesapplications.opendatahub.io | DataSciencePipelinesApplication | Namespaced | Kubeflow Pipelines instance configuration |
| DSP Operator | argoproj.io | Workflow, WorkflowTemplate, CronWorkflow | Namespaced | Argo Workflows for pipeline execution |
| KServe | serving.kserve.io | InferenceService, ServingRuntime, ClusterServingRuntime | Namespaced/Cluster | Model serving workloads and runtime templates |
| KServe | serving.kserve.io | LLMInferenceService, InferenceGraph | Namespaced | LLM serving and multi-model pipelines |
| Model Registry | modelregistry.opendatahub.io | ModelRegistry | Namespaced | Model metadata storage configuration |
| Training Operator | kubeflow.org | PyTorchJob, TFJob, MPIJob, XGBoostJob, JAXJob, PaddleJob | Namespaced | Distributed training job definitions |
| KubeRay | ray.io | RayCluster, RayJob, RayService | Namespaced | Ray cluster and job management |
| TrustyAI | trustyai.opendatahub.io | TrustyAIService, LMEvalJob, GuardrailsOrchestrator | Namespaced | Explainability services, LM evaluation, AI guardrails |
| Feast | feast.dev | FeatureStore | Namespaced | Feature store deployment configuration |
| Llama Stack | llamastack.io | LlamaStackDistribution | Namespaced | Llama Stack server deployment |
| ODH Model Controller | nim.opendatahub.io | Account | Namespaced | NVIDIA NIM account credentials and runtime templates |

**Total CRDs**: 40+ across all components

### Public HTTP Endpoints

| Component | Path Pattern | Method | Port | Protocol | Auth | Purpose |
|-----------|--------------|--------|------|----------|------|---------|
| ODH Dashboard | /api/* | GET/POST/PUT/DELETE | 8443/TCP | HTTPS | OAuth2 Bearer | Dashboard backend API (config, notebooks, components, status) |
| Notebooks | /lab | GET/POST/WS | 8888/TCP | HTTP | OAuth Proxy | JupyterLab interface (via Gateway) |
| Notebooks (RStudio) | / | GET/POST | 8888/TCP | HTTP | OAuth Proxy | RStudio Server interface (via Gateway) |
| Notebooks (CodeServer) | / | GET | 8888/TCP | HTTP | OAuth Proxy | VS Code interface (via Gateway) |
| DSP API Server | /apis/v2beta1/* | GET/POST/DELETE | 8888/TCP | HTTP | Bearer Token | KFP v2 API for pipelines, runs, experiments (via Gateway/Route) |
| KServe InferenceService | /v1/models/:name:infer | POST | 8080/TCP | HTTP | Configurable | KServe V1 inference protocol (via Gateway/Route) |
| KServe InferenceService | /v2/models/:name/infer | POST | 8080/TCP | HTTP | Configurable | KServe V2 inference protocol (via Gateway/Route) |
| Model Registry | /api/model_registry/v1alpha3/* | GET/POST/PUT/DELETE | 8443/TCP | HTTPS | Bearer Token | Model registry REST API (via kube-rbac-proxy) |
| TrustyAI Service | /q/metrics | GET | 80/TCP | HTTP | None | TrustyAI metrics endpoint (via Route) |
| Guardrails Orchestrator | /gateway | ALL | 8090/TCP | HTTP | None/Bearer | AI guardrails gateway (via Route) |
| Feast Online Store | /get-online-features | POST | 6566/TCP | HTTP | OIDC/K8s/None | Real-time feature retrieval |
| Feast Offline Store | /get-historical-features | POST | 8815/TCP | HTTP | OIDC/K8s/None | Historical feature retrieval for training |
| Llama Stack | /v1/* | POST/GET | 8321/TCP | HTTP | None | Llama Stack API for LLM inference |

All external endpoints are accessed via Gateway (RHOAI 3.x) or OpenShift Routes (legacy components), with authentication enforced by kube-auth-proxy or oauth-proxy.

## Data Flows

### Key Platform Workflows

#### Workflow 1: End-to-End Model Development and Deployment

| Step | Component | Action | API/Protocol | Next Component |
|------|-----------|--------|--------------|----------------|
| 1 | User Browser → Dashboard | Access platform via Gateway | HTTPS (Gateway → kube-auth-proxy → Dashboard) | Dashboard displays available resources |
| 2 | User → Dashboard | Create data science project (namespace) | Dashboard API → Kubernetes API | Namespace created with RBAC |
| 3 | User → Dashboard | Launch Jupyter workbench | Dashboard API → Notebook Controller | Notebook CR created |
| 4 | Notebook Controller | Create StatefulSet + Service + HTTPRoute | Kubernetes API | JupyterLab pod running |
| 5 | Data Scientist → Notebook | Develop and train model code | Jupyter kernels (Python/R) | Model trained locally or via Training Operator |
| 6 | Notebook → Training Operator | Submit distributed training job (PyTorchJob) | Kubernetes API | PyTorchJob CR created |
| 7 | Training Operator | Create training pods (master + workers) | Kubernetes API | Distributed training execution |
| 8 | Training Pods → S3 Storage | Download datasets, save checkpoints | HTTPS (AWS SigV4) | Model artifacts in S3 |
| 9 | Notebook/Training → Model Registry | Register trained model metadata | Model Registry REST API | Model versioned and cataloged |
| 10 | User → Dashboard | Deploy model for serving | Dashboard API → KServe | InferenceService CR created |
| 11 | KServe Controller | Deploy model server, pull artifacts from S3 | Storage Initializer → S3, Predictor deployment | Model serving endpoint live |
| 12 | ODH Model Controller | Create Route + ServiceMonitor + NetworkPolicy | Kubernetes API | External access enabled, metrics collected |
| 13 | Client Application → InferenceService | Send inference requests | HTTPS via Gateway/Route | Predictions returned |
| 14 | TrustyAI → InferenceService | Monitor predictions for bias/drift | HTTP/gRPC | Explainability metrics collected |

#### Workflow 2: ML Pipeline Orchestration (MLOps)

| Step | Component | Action | API/Protocol | Next Component |
|------|-----------|--------|--------------|----------------|
| 1 | Data Scientist → Notebook | Author pipeline using KFP SDK | Python SDK (kfp v2) | Pipeline YAML generated |
| 2 | Notebook → DSP API Server | Upload pipeline definition | HTTPS (KFP v2 API) | Pipeline stored in DSP database |
| 3 | User → Dashboard | Trigger pipeline run | Dashboard API → DSP API | Pipeline run created |
| 4 | DSP API Server → Workflow Controller | Create Argo Workflow | Kubernetes API | Workflow CR created |
| 5 | Workflow Controller → Kubernetes API | Schedule pipeline pods | Kubernetes API | Pipeline step pods executing |
| 6 | Pipeline Pod (step 1) → S3 | Load training data | HTTPS | Dataset downloaded |
| 7 | Pipeline Pod (step 2) → Training Operator | Launch distributed training | Kubernetes API | PyTorchJob created |
| 8 | Pipeline Pod (step 3) → Model Registry | Register model | REST API | Model metadata stored |
| 9 | Pipeline Pod (step 4) → KServe | Deploy model | Kubernetes API (InferenceService CR) | Model deployed |
| 10 | Persistence Agent → DSP Database | Update pipeline run status | MariaDB/PostgreSQL | Run status persisted |
| 11 | MLMD gRPC → DSP Database | Store artifact lineage | gRPC | Artifact graph updated |
| 12 | User → Dashboard | View pipeline execution graph | Dashboard API → DSP API | Pipeline visualization displayed |

#### Workflow 3: Feature Engineering for Online Inference

| Step | Component | Action | API/Protocol | Next Component |
|------|-----------|--------|--------------|----------------|
| 1 | Data Engineer → Notebook | Define features using Feast SDK | Python (feast SDK) | Feature definitions created |
| 2 | Notebook → Feast Registry | Register feature definitions | gRPC/HTTP (Feast registry) | Features cataloged |
| 3 | Notebook/Pipeline → Feast Offline Store | Materialize features (batch processing) | HTTP (get-historical-features) | Features computed from data warehouse |
| 4 | Feast CronJob | Schedule feature materialization | Kubernetes CronJob | Periodic offline→online sync |
| 5 | Offline Store → Online Store | Push features to online store | Feast internal API | Real-time features available |
| 6 | ML Model (InferenceService) → Feast Online Store | Retrieve features for inference | HTTP (get-online-features) | Features returned |
| 7 | InferenceService | Combine features + input → prediction | Model inference | Prediction generated |
| 8 | InferenceService → Client | Return prediction | HTTPS via Gateway | Client receives result |

#### Workflow 4: AI Guardrails and Model Monitoring

| Step | Component | Action | API/Protocol | Next Component |
|------|-----------|--------|--------------|----------------|
| 1 | Admin → TrustyAI Operator | Deploy GuardrailsOrchestrator | Kubernetes API | Guardrails service created |
| 2 | TrustyAI Operator → KServe | Inject guardrails into InferenceService | Patch InferenceService CR | Inference traffic routed through guardrails |
| 3 | Client → Gateway | Send inference request | HTTPS | Request routed to InferenceService |
| 4 | InferenceService (modified) → Guardrails Gateway | Forward request to guardrails | HTTP | Guardrails intercepts request |
| 5 | Guardrails Gateway → Detector InferenceServices | Check for toxic content, PII, etc. | HTTPS/gRPC | Safety checks executed |
| 6 | Guardrails Orchestrator | Approve/deny/modify request | Internal routing | Decision made |
| 7 | Guardrails → Generator InferenceService | Forward approved request to model | HTTPS/gRPC | Model generates prediction |
| 8 | Guardrails → Detector InferenceServices | Check response for safety violations | HTTPS/gRPC | Response safety validated |
| 9 | Guardrails → Client | Return filtered/approved response | HTTPS | Safe response delivered |
| 10 | TrustyAI Service → InferenceService | Collect predictions for monitoring | HTTP payload logging | Predictions logged |
| 11 | Data Scientist → TrustyAI Service | Query bias metrics | TrustyAI REST API | Bias reports generated |
| 12 | TrustyAI → Prometheus | Export fairness/drift metrics | Prometheus scrape | Metrics visualized in dashboards |

#### Workflow 5: Distributed Ray Workload for Reinforcement Learning

| Step | Component | Action | API/Protocol | Next Component |
|------|-----------|--------|--------------|----------------|
| 1 | User → Dashboard | Create Ray cluster | Dashboard API → KubeRay Operator | RayCluster CR created |
| 2 | KubeRay Operator | Deploy Ray head + worker pods | Kubernetes API | Ray cluster running |
| 3 | Data Scientist → Notebook | Connect to Ray cluster | Ray client API (port 10001) | Notebook connected to Ray |
| 4 | Notebook → Ray Head | Submit reinforcement learning job | Ray submit API | Job queued |
| 5 | Ray Head → Ray Workers | Distribute training across workers | Ray internal protocol (6379 GCS) | Parallel training execution |
| 6 | Ray Workers → S3 | Load environment data | HTTPS | Training data accessed |
| 7 | Ray Workers → Ray Head | Report training progress | Ray internal protocol | Metrics aggregated |
| 8 | Notebook → Ray Dashboard | Monitor training progress | HTTP (port 8265) | Training visualization |
| 9 | Ray Job → Model Registry | Save trained RL model | Model Registry API | Model versioned |

## Deployment Architecture

### Deployment Topology

**Platform Operator Layer** (redhat-ods-operator namespace):
- RHODS Operator (1 deployment, 3 replicas for HA)
- Manages all component lifecycles via DataScienceCluster and DSCInitialization CRs

**Gateway Infrastructure Layer** (openshift-ingress namespace):
- data-science-gateway (Gateway API v1)
- GatewayClass (data-science-gateway-class)
- kube-auth-proxy (deployment, 2 replicas for HA)
- EnvoyFilter (authn-filter) for ext_authz integration
- OAuth callback HTTPRoute

**Application Layer** (redhat-ods-applications namespace):
- ODH Dashboard (2 replicas for HA)
- Notebook Controller (1 replica)
- DSP Operator (1 replica)
- KServe Controller (1 replica)
- ODH Model Controller (1 replica)
- Model Registry Operator (1 replica)
- Training Operator (1 replica)
- KubeRay Operator (1 replica)
- TrustyAI Service Operator (1 replica)
- Feast Operator (1 replica)
- Llama Stack Operator (1 replica)

**Monitoring Layer** (redhat-ods-monitoring namespace):
- Prometheus (1 StatefulSet, 2 replicas, federated to cluster monitoring)
- Alertmanager (1 StatefulSet, 3 replicas)
- Blackbox Exporter (1 deployment)
- ServiceMonitors for all components

**User Workload Layer** (user namespaces, multi-tenant):
- Notebooks (StatefulSets, 1 pod per user workbench)
- DSP Instances (per-namespace deployments of DSP API + persistence + workflow controllers)
- InferenceServices (KServe model serving deployments)
- Training Jobs (batch pods for PyTorchJob, TFJob, etc.)
- Ray Clusters (head + worker pods)
- TrustyAI Services (per-namespace explainability deployments)
- Model Registries (per-registry REST + gRPC services)
- Feature Stores (Feast online/offline/registry servers)
- Llama Stack Servers (LLM inference deployments)

### Resource Requirements

Minimum platform footprint (operators only):
- **CPU**: ~5 cores (requests), ~15 cores (limits)
- **Memory**: ~10 GiB (requests), ~30 GiB (limits)
- **Storage**: ~50 GiB for operator images and monitoring data

Typical production deployment with active workloads:
- **CPU**: 50-200+ cores depending on concurrent notebooks, training jobs, inference services
- **Memory**: 100-500+ GiB depending on model sizes and batch sizes
- **Storage**: 1-10+ TiB for persistent data (PVCs for notebooks, DSP artifacts, model registries)
- **GPUs**: 0-100+ NVIDIA/AMD GPUs for GPU-accelerated training and inference

## Version-Specific Changes (RHOAI 3.0)

| Component | Major Changes from 2.x |
|-----------|------------------------|
| RHODS Operator | - **Gateway API ingress architecture** (replaces Routes for new workloads)<br>- **kube-auth-proxy authentication** (replaces oauth-proxy)<br>- HTTPRoute + kube-rbac-proxy sidecar pattern for component ingress<br>- EnvoyFilter ext_authz integration for Service Mesh<br>- OIDC authentication support (ROSA compatibility)<br>- GatewayConfig, Auth, Monitoring service CRDs introduced<br>- Component CRDs migrated to components.platform.opendatahub.io/v1alpha1<br>- DSCInitialization v2 API with immutable applicationsNamespace |
| KServe | - **Raw deployment mode as default** (Knative optional)<br>- LLMInferenceService CRD for vLLM/TGI runtimes<br>- Multi-node LLM serving support<br>- Precise prefix routing for InferenceGraphs<br>- Gateway API integration for LLM services |
| DSP Operator | - **Kubeflow Pipelines 2.5.0** (KFP v2 API)<br>- Argo Workflows v3.4+ (replaces Tekton)<br>- MLMD gRPC integration for artifact lineage<br>- Pod-to-pod TLS enabled by default<br>- Pipeline CRD storage option (in addition to database) |
| Notebooks | - **Python 3.12** as default runtime (from 3.11)<br>- R 4.5.1 support<br>- PyTorch/TensorFlow with CUDA 12.8 and ROCm 6.3/6.4<br>- Multi-architecture builds (x86_64, aarch64, ppc64le, s390x)<br>- LLMCompressor workbench for model optimization<br>- IPv6 support for CodeServer and RStudio |
| Model Registry | - **kube-rbac-proxy authentication** (replaces oauth-proxy)<br>- v1beta1 API (v1alpha1 deprecated)<br>- PostgreSQL 16 support<br>- Database schema migration capabilities |
| Training Operator | - Kubeflow Training Operator v1.9.0<br>- JAXJob support for JAX distributed training<br>- Enhanced PyTorch elastic training with HPA integration<br>- Gang scheduling with Volcano/scheduler-plugins<br>- Improved multi-framework validation webhooks |
| TrustyAI Operator | - GuardrailsOrchestrator CRD for AI safety<br>- LMEvalJob for language model evaluation<br>- kube-rbac-proxy integration<br>- KServe InferenceService guardrails injection<br>- OpenTelemetry OTLP export support |
| ODH Dashboard | - Gateway API HTTPRoute integration<br>- Model-as-a-Service features (beta)<br>- GenAI Studio features (beta)<br>- NVIDIA NIM integration<br>- Llama Stack integration<br>- Enhanced distributed workloads UI |
| ODH Model Controller | - NVIDIA NIM Account CRD for NIM credentials<br>- Gateway API HTTPRoute creation for LLM services<br>- Kuadrant AuthPolicy integration<br>- KEDA TriggerAuthentication for autoscaling<br>- vLLM runtime templates (CUDA, ROCm, Gaudi, multi-node, Spyre) |

**Architecture Evolution Summary**:
- **Ingress**: Gateway API (HTTPRoute) > OpenShift Routes (legacy still supported)
- **Authentication**: kube-auth-proxy + EnvoyFilter ext_authz > oauth-proxy sidecars
- **Authorization**: kube-rbac-proxy per-workload > component-level oauth-proxy
- **Service Mesh**: Optional Istio for advanced use cases > Required for serverless KServe
- **OIDC**: Native OIDC provider support > OpenShift OAuth only
- **Scalability**: Centralized Gateway authentication > Per-component Routes

## Platform Maturity

- **Total Components**: 13 operators/services
- **Operator-based Components**: 12 (92%)
- **Service Mesh Coverage**: ~30% (optional, KServe serverless mode, optional for others)
- **mTLS Enforcement**: PERMISSIVE (service mesh optional, pod-to-pod TLS for DSP/Model Registry)
- **CRD API Versions**: v1 (majority), v1alpha1 (newer features), v1beta1 (transitional)
- **Multi-Architecture Support**: 100% (x86_64, aarch64, ppc64le, s390x for CPU workloads)
- **GPU Support**: NVIDIA CUDA 12.8, AMD ROCm 6.3/6.4, Intel Gaudi
- **FIPS Compliance**: 100% (all operators built with strictfipsruntime)
- **Container Base**: UBI9 Minimal (Red Hat Universal Base Image)
- **Build System**: Konflux CI/CD (100% of RHOAI components)
- **Authentication Methods**: 3 (OpenShift OAuth, OIDC, Kubernetes RBAC)
- **Deployment Modes**: 2 (Serverless with Knative/Istio, Raw Kubernetes)
- **Storage Backends**: 5+ (S3, GCS, Azure Blob, PostgreSQL, MySQL, MariaDB, PVC)
- **Monitoring Integration**: Prometheus federation to OpenShift cluster monitoring
- **Observability**: ServiceMonitors/PodMonitors for all components, OpenTelemetry OTLP support

**Production Readiness Indicators**:
- ✅ High Availability: Dashboard (2 replicas), kube-auth-proxy (2 replicas), Prometheus (2 replicas), Alertmanager (3 replicas)
- ✅ Leader Election: All operators support leader election for active-standby HA
- ✅ Auto-scaling: HPA support for notebooks, KServe inference services, Ray workers
- ✅ Health Probes: All components expose /healthz and /readyz endpoints
- ✅ Metrics: All operators expose Prometheus /metrics endpoints
- ✅ TLS Encryption: TLS 1.2+ for all external communications, optional mTLS for service mesh
- ✅ RBAC: Fine-grained Kubernetes RBAC for all components
- ✅ Audit Logging: Kubernetes audit logs capture all API operations
- ✅ Backup/Restore: Velero-compatible PVC snapshots, database backups, GitOps-friendly CRs
- ✅ Disaster Recovery: Stateless operators (state in CRs + databases), namespace-scoped workloads

## Next Steps for Documentation

1. **Generate Architecture Diagrams**:
   - Platform-level component dependency graph
   - Gateway API ingress flow diagram (RHOAI 3.x)
   - Authentication/authorization flow diagrams
   - Network topology diagram showing namespaces and traffic flows
   - Data flow diagrams for key workflows (model development, pipeline orchestration, feature engineering)

2. **Update ADRs (Architecture Decision Records)**:
   - ADR: Migration from Routes to Gateway API in RHOAI 3.0
   - ADR: kube-auth-proxy vs oauth-proxy authentication pattern
   - ADR: EnvoyFilter ext_authz for centralized authentication
   - ADR: Multi-architecture support strategy (x86_64, aarch64, ppc64le, s390x)
   - ADR: FIPS compliance implementation across all components
   - ADR: Konflux CI/CD build system adoption
   - ADR: Service mesh optional vs required decision

3. **Create User-Facing Architecture Documentation**:
   - RHOAI 3.0 Architecture Overview (high-level for customers)
   - Component Integration Guide (how components interact)
   - Deployment Patterns and Best Practices
   - Security Architecture and Compliance Guide
   - Multi-tenancy and Namespace Isolation Guide
   - GPU Acceleration Configuration Guide (NVIDIA CUDA, AMD ROCm)
   - Monitoring and Observability Guide
   - Disaster Recovery and Backup Strategy Guide

4. **Generate Security Architecture Review (SAR) Documentation**:
   - Network segmentation diagram (namespaces, ingress/egress)
   - Authentication and authorization flows
   - TLS/mTLS encryption matrix (component-to-component)
   - RBAC permission matrix (operators and workloads)
   - Secrets management and rotation strategy
   - Egress firewall rules and external dependencies
   - Compliance artifacts (FIPS, PCI-DSS, HIPAA considerations)

5. **Create Operational Runbooks**:
   - RHOAI 3.0 Installation and Upgrade Guide
   - Gateway API troubleshooting guide
   - Authentication troubleshooting (kube-auth-proxy, OIDC, OAuth)
   - Component-specific troubleshooting guides
   - Performance tuning recommendations
   - Capacity planning guide (CPU, memory, GPU, storage)
   - Backup and restore procedures

6. **Performance and Scalability Analysis**:
   - Component resource consumption benchmarks
   - Gateway API scalability testing results
   - Multi-tenant workload isolation validation
   - GPU utilization and sharing strategies
   - Prometheus federation performance impact

7. **Migration Guides**:
   - RHOAI 2.x to 3.0 migration guide (Routes → Gateway API)
   - oauth-proxy to kube-rbac-proxy migration steps
   - Legacy workload compatibility matrix
   - Rollback procedures

8. **API Documentation**:
   - OpenAPI/Swagger specs for all REST APIs (Dashboard, DSP, Model Registry, KServe)
   - CRD reference documentation with examples
   - Python SDK documentation (kubeflow-training, kfp, feast)
   - API versioning and deprecation policy

---

**Document Version**: 1.0
**Generated**: 2026-03-16
**Components Analyzed**: 13
**Source**: architecture/rhoai-3.0/ (13 component architecture files)
**Next Review**: 2026-06 (quarterly update recommended)
