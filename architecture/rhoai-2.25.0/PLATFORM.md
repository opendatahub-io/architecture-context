# Platform: Red Hat OpenShift AI 2.25.0

## Metadata
- **Distribution**: RHOAI (Red Hat OpenShift AI)
- **Version**: 2.25.0
- **Base Platform**: OpenShift Container Platform 4.11+
- **Components Analyzed**: 15
- **Analysis Date**: 2026-03-13

## Platform Overview

Red Hat OpenShift AI (RHOAI) 2.25.0 is a comprehensive AI/ML platform built on OpenShift that provides end-to-end capabilities for the complete machine learning lifecycle—from data preparation and model training through deployment and monitoring. The platform integrates 15 core components that work together to deliver notebook-based development environments, distributed training, model serving, pipeline orchestration, model registry, and AI safety/explainability features.

The platform follows a cloud-native, Kubernetes-operator-based architecture where each component is deployed and managed declaratively through Custom Resource Definitions (CRDs). Components communicate via Kubernetes APIs, REST/gRPC protocols, and leverage OpenShift-specific features including Routes for external access, OAuth for authentication, and integration with service mesh (Istio/Maistra) for secure service-to-service communication. The platform supports multiple hardware accelerators (NVIDIA GPUs, AMD ROCm, Intel Gaudi) and provides both serverless (Knative) and traditional Kubernetes deployment modes for model serving.

RHOAI is designed for multi-tenant enterprise environments with namespace-level isolation, RBAC-based access control, and integration with OpenShift's security features including SecurityContextConstraints, pod security standards, and FIPS-compliant cryptography throughout the stack.

## Component Inventory

| Component | Type | Version | Purpose |
|-----------|------|---------|---------|
| ODH Dashboard | Frontend/Backend | v1.21.0-rhods-4281 | Web UI for platform management and user interaction |
| Notebook Controller | Operator | v1.27.0-rhods-1295 | Manages Jupyter notebook instances lifecycle |
| Workbench Images | Container Images | v2.25.2-55 | JupyterLab, VS Code, RStudio environments with ML frameworks |
| Data Science Pipelines Operator | Operator | rhoai-2.25 (763811f) | Kubeflow Pipelines for workflow orchestration |
| KServe | Operator/Runtime | 4211a5da7 | Model serving platform with serverless and raw modes |
| ODH Model Controller | Operator | 1.27.0-rhods-1121 | Extends KServe with OpenShift integration and service mesh |
| ModelMesh Serving | Operator/Runtime | 1.27.0-rhods-480 | Multi-model serving with high-density model placement |
| Model Registry Operator | Operator | 0b48221 | Manages model metadata and versioning services |
| Training Operator | Operator | 1.9.0 (3a1af789) | Distributed ML training (PyTorch, TensorFlow, XGBoost, MPI, JAX, PaddlePaddle) |
| KubeRay Operator | Operator | f10d68b1 | Manages Ray clusters for distributed computing |
| CodeFlare Operator | Operator | 1.15.0 | Ray cluster orchestration with OAuth and mTLS integration |
| Kueue | Operator | 7f2f72e51 | Job queueing and resource quota management |
| Feast Operator | Operator | 0.54.0 (aad1ebcd0) | Feature store for ML feature management |
| TrustyAI Service Operator | Operator | d113dae | AI explainability, bias detection, LM evaluation, guardrails |
| Llama Stack Operator | Operator | 0.3.0 | Manages Llama Stack inference servers (Ollama, vLLM, TGI) |

## Component Relationships

### Dependency Graph

```
User/Data Scientist
  └─> ODH Dashboard (Web UI)
       ├─> Notebook Controller ─> Workbench Images (Jupyter/VS Code/RStudio)
       ├─> Data Science Pipelines Operator
       │    ├─> Argo Workflows (pipeline execution)
       │    ├─> Model Registry Operator (model tracking)
       │    └─> KServe (model deployment from pipelines)
       ├─> Model Registry Operator
       │    ├─> PostgreSQL/MySQL (metadata storage)
       │    └─> OpenShift OAuth (authentication)
       ├─> KServe
       │    ├─> Knative Serving (serverless mode)
       │    ├─> Istio (service mesh, traffic management)
       │    ├─> ODH Model Controller (OpenShift integration)
       │    └─> Model Registry (model references)
       ├─> ModelMesh Serving
       │    ├─> ETCD (distributed state)
       │    ├─> ODH Model Controller (OpenShift integration)
       │    └─> S3 Storage (model artifacts)
       ├─> Training Operator
       │    ├─> Kueue (job queueing)
       │    ├─> Volcano/Scheduler Plugins (gang scheduling)
       │    └─> Model Registry (post-training model registration)
       ├─> CodeFlare Operator
       │    ├─> KubeRay Operator (Ray cluster management)
       │    ├─> Kueue (AppWrapper scheduling)
       │    └─> OpenShift OAuth (Ray dashboard auth)
       ├─> Feast Operator
       │    ├─> PostgreSQL/Redis (feature storage)
       │    └─> S3/GCS (offline data)
       ├─> TrustyAI Service Operator
       │    ├─> KServe (model monitoring)
       │    ├─> ModelMesh (payload processing)
       │    └─> Kueue (LM evaluation jobs)
       └─> Llama Stack Operator
            └─> Ollama/vLLM/TGI (inference backends)

ODH Model Controller (extends)
  └─> KServe + ModelMesh
       ├─> Creates OpenShift Routes
       ├─> Creates Istio VirtualServices
       ├─> Creates AuthConfigs (Authorino)
       ├─> Creates ServiceMonitors (Prometheus)
       └─> Creates NetworkPolicies

KubeRay Operator (provides base Ray clusters)
  └─> CodeFlare Operator (adds OAuth, mTLS, networking)

Kueue (manages admission for)
  ├─> Training Operator jobs
  ├─> CodeFlare AppWrappers
  └─> TrustyAI LM Eval jobs
```

### Central Components

**Core Infrastructure (highest dependencies):**
1. **Kubernetes API Server** - All components interact with K8s API for resource management
2. **ODH Dashboard** - Primary user interface for all platform features
3. **OpenShift OAuth** - Authentication for external access across components
4. **Istio/Service Mesh** - Service-to-service communication for KServe, ModelMesh
5. **Prometheus** - Metrics collection from all components

**Model Serving Hub:**
1. **KServe** - Primary model serving platform
2. **ODH Model Controller** - Extends KServe with OpenShift/mesh integration
3. **ModelMesh Serving** - Alternative high-density serving
4. **Model Registry** - Centralized model metadata and versioning

**Distributed Computing Hub:**
1. **Training Operator** - Framework-specific training jobs
2. **KubeRay/CodeFlare** - Ray-based distributed workloads
3. **Kueue** - Resource quota and queue management across workloads

### Integration Patterns

**Pattern 1: CRD-Based Resource Management**
- Components create/watch Kubernetes Custom Resources
- Controllers reconcile desired state from CRs
- Example: ODH Dashboard → creates Notebook CR → Notebook Controller reconciles → StatefulSet created

**Pattern 2: Webhook-Based Admission Control**
- Validating webhooks ensure resource correctness
- Mutating webhooks inject defaults and sidecars
- Example: Training Operator validates PyTorchJob specs before admission

**Pattern 3: Operator Extension Pattern**
- Base operator provides core functionality
- Extension operator adds platform-specific features
- Example: KServe (base) + ODH Model Controller (OpenShift integration)

**Pattern 4: OAuth Proxy Sidecar Pattern**
- OpenShift OAuth proxy container provides authentication
- Backend service handles business logic without auth concerns
- Example: Model Registry, TrustyAI Service, ODH Dashboard

**Pattern 5: Service Mesh Integration**
- Istio VirtualServices for traffic routing
- PeerAuthentication for mTLS enforcement
- AuthorizationPolicies for access control
- Example: KServe InferenceServices exposed via Istio Gateway

**Pattern 6: Event-Based Communication**
- Kubernetes Watch API for resource change notifications
- WebSocket streams for real-time updates
- Example: ODH Dashboard watches CRD status changes

## Platform Network Architecture

### Namespaces

| Namespace | Purpose | Components |
|-----------|---------|------------|
| redhat-ods-applications | RHOAI platform services | ODH Dashboard, Notebook Controller, operators |
| opendatahub | Alternative ODH platform namespace | Same components (ODH distribution) |
| istio-system or openshift-servicemesh | Service mesh control plane | Istio Pilot, Ingress Gateway |
| User namespaces (data science projects) | Tenant workloads | Notebooks, InferenceServices, training jobs, pipelines |
| openshift-monitoring | Platform monitoring | Prometheus, Thanos, AlertManager |

### External Ingress Points

| Component | Ingress Type | Hosts | Port | Protocol | Encryption | Purpose |
|-----------|--------------|-------|------|----------|------------|---------|
| ODH Dashboard | OpenShift Route | cluster-specific | 443/TCP | HTTPS | TLS 1.2+ (edge) | Web UI access |
| Jupyter Notebooks | OpenShift Route | notebook-{user}-{namespace}.apps.{cluster} | 443/TCP | HTTPS | TLS 1.2+ (edge) | Notebook access via OAuth proxy |
| KServe InferenceService | OpenShift Route or Istio VirtualService | {isvc}-{namespace}.apps.{cluster} | 443/TCP | HTTPS | TLS 1.2+ | Model inference endpoints |
| ModelMesh Serving | OpenShift Route | modelmesh-{name}.apps.{cluster} | 443/TCP | HTTPS | TLS 1.2+ | Model inference endpoints |
| Model Registry | OpenShift Route | {name}-{namespace}.apps.{cluster} | 443/TCP | HTTPS | TLS 1.2+ (reencrypt) | Model metadata API |
| Data Science Pipelines | OpenShift Route | ds-pipeline-{name}.apps.{cluster} | 443/TCP | HTTPS | TLS 1.2+ (reencrypt) | Pipeline API and UI |
| Ray Dashboard | OpenShift Route | ray-dashboard-{cluster}.{domain} | 443/TCP | HTTPS | TLS 1.2+ (edge) | Ray cluster dashboard (OAuth) |
| TrustyAI Service | OpenShift Route | trustyai-{namespace}.apps.{cluster} | 443/TCP | HTTPS | TLS 1.2+ (reencrypt) | Explainability API |
| Feast Feature Store | OpenShift Route | feast-{name}-{namespace}.apps.{cluster} | 443/TCP | HTTPS | TLS 1.2+ (edge/reencrypt) | Feature serving API |

### External Egress Dependencies

| Component | Destination | Port | Protocol | Encryption | Purpose |
|-----------|-------------|------|----------|------------|---------|
| Multiple | S3-compatible Storage (AWS S3, MinIO, etc.) | 443/TCP | HTTPS | TLS 1.2+ | Model artifacts, pipeline artifacts, data storage |
| Data Science Pipelines | External databases (MySQL, PostgreSQL) | 3306/5432/TCP | MySQL/PostgreSQL | TLS 1.2+ (optional) | Pipeline metadata persistence |
| Model Registry | PostgreSQL/MySQL | 5432/3306/TCP | PostgreSQL/MySQL | TLS 1.2+ (optional) | Model metadata storage |
| ModelMesh | ETCD | 2379/TCP | HTTP/gRPC | TLS 1.2+ (optional) | Distributed model metadata |
| Workbench Images | PyPI, Conda, npm registries | 443/TCP | HTTPS | TLS 1.2+ | Package installation during runtime |
| Workbench Images | quay.io, registry.redhat.io | 443/TCP | HTTPS | TLS 1.2+ | Container image pulls |
| KServe | Storage (S3, GCS, Azure Blob, PVC) | 443/TCP or N/A | HTTPS or Filesystem | TLS 1.2+ | Model loading during initialization |
| Feast | PostgreSQL, Redis, S3, GCS, Snowflake | varies | varies | TLS 1.2+ (optional) | Feature storage backends |
| TrustyAI | PostgreSQL/MySQL | 5432/3306/TCP | PostgreSQL/MySQL | TLS 1.2+ (optional) | Explainability data persistence |
| Llama Stack | NVIDIA NGC, HuggingFace Hub | 443/TCP | HTTPS | TLS 1.2+ | Model downloads |
| Training Operator | Container Registries | 443/TCP | HTTPS | TLS 1.2+ | Training job image pulls |
| All Operators | Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | Resource management |
| All Operators | OpenShift OAuth Server | 6443/TCP | HTTPS | TLS 1.2+ | Authentication validation |

### Internal Service Mesh

| Setting | Value | Components Using |
|---------|-------|------------------|
| mTLS Mode | STRICT (configurable) | KServe InferenceServices, ModelMesh |
| Peer Authentication | Per-namespace PeerAuthentication resources | KServe predictor pods |
| Service-to-Service Encryption | mTLS via Istio | KServe → transformers, KServe → predictors |
| Traffic Management | Istio VirtualServices, DestinationRules | KServe serverless mode, InferenceGraph routing |
| Ingress Gateway | istio-ingressgateway or knative-local-gateway | KServe external traffic |
| Authorization | Istio AuthorizationPolicies + Authorino AuthConfigs | KServe endpoints (optional) |

## Platform Security

### RBAC Summary

**Operator Cluster Roles (aggregated permissions):**

| Component | Key API Groups | Critical Resources | Notable Verbs |
|-----------|----------------|-------------------|---------------|
| ODH Dashboard | kubeflow.org, serving.kserve.io, datasciencecluster.opendatahub.io | notebooks, inferenceservices, datascienceclusters | create, get, list, watch, patch, delete |
| Notebook Controller | kubeflow.org | notebooks | full CRUD + status updates |
| Data Science Pipelines Operator | datasciencepipelinesapplications.opendatahub.io, argoproj.io | datasciencepipelinesapplications, workflows | create, delete, get, list, patch, update, watch |
| KServe | serving.kserve.io, networking.istio.io, serving.knative.dev | inferenceservices, servingruntimes, virtualservices, services | full CRUD + finalizers |
| ODH Model Controller | serving.kserve.io, networking.istio.io, route.openshift.io | inferenceservices, virtualservices, routes, authconfigs | get, list, patch, update, watch, create |
| ModelMesh Serving | serving.kserve.io | inferenceservices, servingruntimes, predictors | create, delete, get, list, patch, update, watch |
| Model Registry Operator | modelregistry.opendatahub.io, route.openshift.io | modelregistries, routes | full CRUD + status updates |
| Training Operator | kubeflow.org (6 training CRDs), scheduling.volcano.sh | pytorchjobs, tfjobs, mpijobs, xgboostjobs, paddlejobs, jaxjobs, podgroups | full CRUD + status + finalizers |
| KubeRay Operator | ray.io, route.openshift.io | rayclusters, rayjobs, rayservices, routes, ingresses | create, delete, get, list, patch, update, watch |
| CodeFlare Operator | ray.io, workload.codeflare.dev, dscinitialization.opendatahub.io | rayclusters, appwrappers, dscinitializations | get, list, watch, create, patch, update |
| Kueue | kueue.x-k8s.io, batch, kubeflow.org, ray.io | workloads, clusterqueues, localqueues, jobs, pytorchjobs, rayjobs | full CRUD + patch for suspension |
| Feast Operator | feast.dev, route.openshift.io | featurestores, routes | create, delete, get, list, update, watch |
| TrustyAI Operator | trustyai.opendatahub.io, serving.kserve.io, kueue.x-k8s.io | trustyaiservices, lmevaljobs, guardrailsorchestrators, inferenceservices | full CRUD + status |
| Llama Stack Operator | llamastack.io, template.openshift.io | llamastackdistributions, templates | get, list, watch, create, update, patch, delete |

**Cross-Cutting Permissions:**
- All operators: `pods`, `services`, `configmaps`, `secrets`, `events` (create, get, list, watch, patch)
- All operators: `deployments`, `statefulsets` (create, delete, get, list, patch, update, watch)
- Most operators: `routes` (OpenShift-specific for external access)
- Serving operators: `virtualservices`, `gateways` (Istio integration)
- Multiple operators: `servicemonitors`, `podmonitors` (Prometheus integration)

### Secrets Inventory

| Component | Secret Name Pattern | Type | Purpose |
|-----------|---------------------|------|---------|
| ODH Dashboard | dashboard-proxy-tls | kubernetes.io/tls | OAuth proxy TLS certificate |
| ODH Dashboard | dashboard-oauth-config-generated | Opaque | OAuth cookie secret |
| Notebook Controller | notebook-controller-webhook-cert | kubernetes.io/tls | Webhook TLS certificate |
| Data Science Pipelines | ds-pipelines-proxy-tls-{name} | kubernetes.io/tls | OAuth proxy TLS |
| Data Science Pipelines | mariadb-{name} | Opaque | Database password |
| Data Science Pipelines | mlpipeline-minio-artifact | Opaque | Minio/S3 credentials |
| KServe | kserve-webhook-server-cert | kubernetes.io/tls | Webhook TLS certificate |
| KServe | storage-config | Opaque | Default S3/GCS/Azure credentials |
| ODH Model Controller | webhook-server-cert | kubernetes.io/tls | Webhook TLS |
| ModelMesh | storage-config | Opaque | S3/storage credentials |
| ModelMesh | model-serving-etcd | Opaque | ETCD connection config |
| Model Registry | {name}-oauth-proxy | kubernetes.io/tls | OAuth proxy TLS |
| Model Registry | {name}-oauth-cookie-secret | Opaque | OAuth session cookie encryption |
| Training Operator | training-operator-webhook-cert | kubernetes.io/tls | Webhook TLS |
| KubeRay | webhook-server-cert | kubernetes.io/tls | Webhook TLS |
| CodeFlare | codeflare-operator-webhook-server-cert | kubernetes.io/tls | Webhook TLS |
| CodeFlare | {cluster}-ca | Opaque | mTLS CA certificates for Ray |
| Kueue | kueue-webhook-server-cert | kubernetes.io/tls | Webhook TLS |
| Feast | {featurestore-name}-tls | kubernetes.io/tls | Feature server TLS |
| Feast | {featurestore-name}-db-secret | Opaque | Database credentials |
| TrustyAI | {service-name}-tls | kubernetes.io/tls | Service TLS |
| TrustyAI | {service-name}-db-credentials | Opaque | Database credentials |
| Llama Stack | hf-token-secret | Opaque | HuggingFace API token |

### Authentication Mechanisms

| Pattern | Components Using | Enforcement Point | User Experience |
|---------|------------------|-------------------|-----------------|
| OpenShift OAuth (Bearer Token) | ODH Dashboard, Notebooks, Model Registry, Data Science Pipelines UI, Ray Dashboard, TrustyAI | OAuth Proxy Sidecar | Browser redirect to OpenShift login |
| Kubernetes ServiceAccount Token | All operators, internal service-to-service | Kubernetes API Server | Automatic pod-mounted tokens |
| mTLS Client Certificates (Istio) | KServe (in-mesh), ModelMesh (optional) | Envoy sidecar proxies | Transparent to applications |
| Authorino JWT Validation | KServe InferenceServices (optional) | Authorino + Istio | Bearer token in Authorization header |
| S3 Signature v4 / AWS IAM | KServe, Data Science Pipelines, Workbenches | S3-compatible storage | Credentials from secrets or IRSA |
| Database Authentication | Model Registry, Data Science Pipelines, TrustyAI, Feast | Database server | Username/password from secrets |
| Webhook mTLS | All operators with webhooks | Kubernetes API Server | API server client certificate |

## Platform APIs

### Custom Resource Definitions

| Component | API Group | Kind | Scope | Primary Use Case |
|-----------|-----------|------|-------|------------------|
| ODH Dashboard | dashboard.opendatahub.io | OdhApplication | Namespaced | Define dashboard tiles and applications |
| ODH Dashboard | opendatahub.io | OdhDashboardConfig | Namespaced | Dashboard feature flags and configuration |
| ODH Dashboard | dashboard.opendatahub.io | OdhDocument | Namespaced | Documentation links |
| ODH Dashboard | console.openshift.io | OdhQuickStart | Namespaced | Interactive tutorials |
| ODH Dashboard | infrastructure.opendatahub.io | HardwareProfile | Namespaced | GPU/accelerator profiles |
| Notebook Controller | kubeflow.org | Notebook | Namespaced | Jupyter notebook instances |
| Data Science Pipelines | datasciencepipelinesapplications.opendatahub.io | DataSciencePipelinesApplication | Namespaced | Pipeline stack deployment |
| Data Science Pipelines | pipelines.kubeflow.org | Pipeline, PipelineVersion | Namespaced | Pipeline definitions |
| Data Science Pipelines | argoproj.io | Workflow, WorkflowTemplate | Namespaced | Argo workflow execution |
| KServe | serving.kserve.io | InferenceService | Namespaced | Model serving instances |
| KServe | serving.kserve.io | ServingRuntime, ClusterServingRuntime | Namespaced/Cluster | Runtime templates |
| KServe | serving.kserve.io | TrainedModel | Namespaced | Multi-model serving |
| KServe | serving.kserve.io | InferenceGraph | Namespaced | Multi-model pipelines |
| KServe | serving.kserve.io | LLMInferenceService | Namespaced | LLM-specific serving |
| ODH Model Controller | nim.opendatahub.io | Account | Namespaced | NVIDIA NIM account management |
| ModelMesh | serving.kserve.io | Predictor | Namespaced | ModelMesh model deployment (legacy) |
| Model Registry | modelregistry.opendatahub.io | ModelRegistry | Namespaced | Model metadata service |
| Training Operator | kubeflow.org | PyTorchJob, TFJob, MPIJob, XGBoostJob, PaddleJob, JAXJob | Namespaced | Distributed training jobs |
| KubeRay | ray.io | RayCluster, RayJob, RayService | Namespaced | Ray distributed computing |
| CodeFlare | workload.codeflare.dev | AppWrapper | Namespaced | Grouped resource scheduling |
| Kueue | kueue.x-k8s.io | Workload, ClusterQueue, LocalQueue | Cluster/Namespaced | Job queueing and quotas |
| Kueue | kueue.x-k8s.io | ResourceFlavor, WorkloadPriorityClass | Cluster | Resource variants and priorities |
| Feast | feast.dev | FeatureStore | Namespaced | Feature store instances |
| TrustyAI | trustyai.opendatahub.io | TrustyAIService, LMEvalJob, GuardrailsOrchestrator | Namespaced | Explainability, evaluation, safety |
| Llama Stack | llamastack.io | LlamaStackDistribution | Namespaced | Llama Stack server deployment |

**Total CRD Count:** 40+ Custom Resource Definitions across the platform

### Public HTTP Endpoints (User-Facing)

| Endpoint Pattern | Component | Authentication | Purpose |
|------------------|-----------|----------------|---------|
| /notebook/{namespace}/{user}/* | Workbenches | OAuth | Jupyter/VS Code/RStudio access |
| /apis/v2beta1/pipelines/* | Data Science Pipelines | OAuth | Pipeline management API |
| /v1/models/{model}:predict | KServe | Bearer/mTLS (optional) | Model inference (V1 protocol) |
| /v2/models/{model}/infer | KServe/ModelMesh | Bearer/mTLS (optional) | Model inference (V2 protocol) |
| /api/model_registry/v1alpha3/* | Model Registry | OAuth | Model metadata CRUD |
| /get-online-features | Feast | OIDC/RBAC (optional) | Real-time feature retrieval |
| /apis/v1beta1/* | TrustyAI | OAuth | Explainability metrics |
| / (dashboard) | ODH Dashboard | OAuth | Platform web UI |
| :8265 | Ray Dashboard | OAuth (CodeFlare) | Ray cluster monitoring |

## Data Flows

### Key Platform Workflows

#### Workflow 1: Model Development to Deployment

| Step | Component | Action | Next Component |
|------|-----------|--------|----------------|
| 1 | User | Logs into ODH Dashboard | ODH Dashboard |
| 2 | ODH Dashboard | Creates Notebook CR | Notebook Controller |
| 3 | Notebook Controller | Deploys Jupyter Pod with OAuth proxy | Workbench Image |
| 4 | User in Notebook | Trains model, saves to S3 | S3 Storage |
| 5 | User via Dashboard | Creates InferenceService CR | KServe |
| 6 | KServe | Creates Knative Service or Deployment | Kubernetes |
| 7 | ODH Model Controller | Creates Route, VirtualService, AuthConfig | OpenShift/Istio |
| 8 | KServe Pod | Downloads model from S3 during init | S3 Storage |
| 9 | User/Application | Sends inference request via Route | KServe Pod |
| 10 | Optional: User | Registers model metadata | Model Registry |

#### Workflow 2: Pipeline-Based Training and Deployment

| Step | Component | Action | Next Component |
|------|-----------|--------|----------------|
| 1 | User | Creates DataSciencePipelinesApplication CR | Data Science Pipelines Operator |
| 2 | DSP Operator | Deploys API Server, Argo Workflows, MariaDB, Minio | Kubernetes |
| 3 | User via UI | Submits pipeline with training steps | DSP API Server |
| 4 | DSP API Server | Creates Argo Workflow CR | Argo Workflows |
| 5 | Argo Workflows | Schedules training pods (runtime images) | Kubernetes Scheduler |
| 6 | Training Pod | Fetches data from S3, trains model | S3 Storage |
| 7 | Training Pod | Uploads trained model to S3 | S3 Storage |
| 8 | Pipeline Step | Creates InferenceService CR | KServe |
| 9 | KServe | Deploys model server | Previous Workflow |
| 10 | Pipeline Step | Registers model in Model Registry | Model Registry |

#### Workflow 3: Distributed Training Job

| Step | Component | Action | Next Component |
|------|-----------|--------|----------------|
| 1 | User | Creates PyTorchJob CR | Training Operator |
| 2 | Training Operator Webhook | Validates job specification | Training Operator |
| 3 | Training Operator | Creates PodGroup for gang scheduling | Kueue/Volcano |
| 4 | Kueue | Evaluates quota and admits workload | Training Operator |
| 5 | Training Operator | Creates master and worker pods | Kubernetes |
| 6 | Training Pods | Download training data from S3 | S3 Storage |
| 7 | Training Pods | Execute distributed training (inter-pod communication) | Training Pods |
| 8 | Training Pods | Save model checkpoints to S3 | S3 Storage |
| 9 | Training Operator | Updates PyTorchJob status to Succeeded | User/Dashboard |
| 10 | User | Registers trained model | Model Registry |

#### Workflow 4: Ray Cluster for Distributed Workload

| Step | Component | Action | Next Component |
|------|-----------|--------|----------------|
| 1 | User | Creates RayCluster CR | KubeRay Operator |
| 2 | KubeRay | Creates head and worker pods | Kubernetes |
| 3 | CodeFlare Operator (watches RayCluster) | Adds OAuth proxy, mTLS, NetworkPolicies | OpenShift/Istio |
| 4 | CodeFlare Operator | Creates Route for Ray Dashboard | OpenShift Router |
| 5 | User | Accesses Ray Dashboard via OAuth | Ray Head Pod |
| 6 | User/Script | Submits Ray job via client | Ray Head Pod |
| 7 | Ray Autoscaler | Scales workers based on workload | KubeRay |
| 8 | Ray Workers | Execute distributed tasks | Ray Cluster |
| 9 | Ray Job | Completes and stores results | S3 Storage |

#### Workflow 5: Model Monitoring with TrustyAI

| Step | Component | Action | Next Component |
|------|-----------|--------|----------------|
| 1 | User | Creates TrustyAIService CR | TrustyAI Operator |
| 2 | TrustyAI Operator | Deploys TrustyAI service with OAuth proxy | Kubernetes |
| 3 | TrustyAI Operator | Patches InferenceService to route predictions | KServe |
| 4 | User Request | Sends inference request | KServe InferenceService |
| 5 | KServe | Forwards request payload to TrustyAI | TrustyAI Service |
| 6 | TrustyAI Service | Logs prediction data, computes metrics | PostgreSQL/PVC |
| 7 | User | Queries bias/fairness metrics via API | TrustyAI Service |
| 8 | Prometheus | Scrapes TrustyAI metrics | TrustyAI Service |
| 9 | User/Dashboard | Views explainability dashboard | Grafana/ODH Dashboard |

## Deployment Architecture

### Deployment Topology

**Operator Deployments:**
- Operators deployed in `redhat-ods-applications` namespace (single namespace for all operators)
- Each operator runs as a Deployment with 1 replica (leader election enabled)
- Operators watch all namespaces for their respective CRDs

**User Workloads:**
- Notebooks, InferenceServices, training jobs deployed in user-created namespaces (data science projects)
- Namespace-level isolation with RBAC and resource quotas
- Service mesh membership per namespace (optional)

**Shared Services:**
- Service mesh control plane in `istio-system` or `openshift-servicemesh`
- Monitoring stack in `openshift-monitoring`
- Image registry in `openshift-image-registry`

### Resource Requirements (Operator Pods)

| Operator | CPU Request | CPU Limit | Memory Request | Memory Limit |
|----------|-------------|-----------|----------------|--------------|
| ODH Dashboard (backend) | 500m | 1000m | 1Gi | 2Gi |
| ODH Dashboard (oauth-proxy) | 500m | 1000m | 1Gi | 2Gi |
| Notebook Controller | Not specified | Not specified | Not specified | Not specified |
| Data Science Pipelines Operator | Not specified | Not specified | Not specified | Not specified |
| KServe Controller | Not specified | Not specified | Not specified | Not specified |
| ODH Model Controller | 10m | 500m | 64Mi | 2Gi |
| ModelMesh Controller | Not specified | Not specified | Not specified | Not specified |
| Model Registry Operator | 100m | Not specified | 256Mi | 512Mi |
| Training Operator | Not specified | Not specified | Not specified | Not specified |
| KubeRay Operator | 100m | 100m | 512Mi | 512Mi |
| CodeFlare Operator | 1 core | 1 core | 1Gi | 1Gi |
| Kueue | 500m | 2000m | 512Mi | 512Mi |
| Feast Operator | Not specified | Not specified | Not specified | Not specified |
| TrustyAI Operator | 10m | 900m | 64Mi | 700Mi |
| Llama Stack Operator | 10m | 500m | 256Mi | 1Gi |

**Note:** Many operators do not specify default resource limits, allowing cluster administrators to set them via resource quotas or LimitRanges.

## Version-Specific Changes (2.25.0)

| Component | Key Changes in 2.25.0 |
|-----------|----------------------|
| All Go Components | - Upgraded to Go 1.25+ for CVE fixes (CVE-2025-61729, CVE-2025-61726)<br>- FIPS compliance with strictfipsruntime |
| All Components | - Base images updated to UBI9 latest (security patches)<br>- Konflux CI/CD pipeline synchronization |
| ODH Model Controller | - FIPS compliance: replaced math/rand with crypto/rand<br>- vLLM version updates across templates |
| KServe | - Security: Path traversal vulnerability fixes in storage-initializer<br>- Multi-architecture support (ppc64le, s390x) |
| Data Science Pipelines | - Go 1.25.5 update for CVE-2025-61729<br>- Dependency updates |
| Training Operator | - Secrets RBAC restricted to namespace-scoped roles (security improvement)<br>- Go 1.25 upgrade |
| Workbench Images | - Python 3.12 as primary version<br>- JupyterLab 4.4<br>- CUDA 12.6/12.8, ROCm 6.2/6.4 support |
| Llama Stack | - NetworkPolicy improvements<br>- Llama Stack Server v0.2.22 |

## Platform Maturity

- **Total Components**: 15 core components
- **Operator-based Components**: 13 operators managing platform lifecycle
- **Container Images**: 50+ workbench and runtime images (multi-arch support)
- **Service Mesh Coverage**: Optional but supported for KServe, ModelMesh, TrustyAI
- **mTLS Enforcement**: Configurable (STRICT/PERMISSIVE) for Istio-enabled services
- **CRD API Versions**: Primarily v1 (stable), some v1alpha1/v1beta1 (evolving APIs)
- **Authentication**: Unified OpenShift OAuth for external access
- **Build System**: Konflux CI/CD with FIPS-compliant builds
- **Base OS**: Red Hat UBI9 (Universal Base Image 9)
- **Multi-Tenancy**: Namespace-level isolation with RBAC
- **Hardware Acceleration**: NVIDIA CUDA, AMD ROCm, Intel Gaudi support

## Security Posture

**Strengths:**
- FIPS-compliant cryptography across all Go components
- Non-root container execution (UID 65532 or specific UIDs)
- Minimal attack surface (UBI minimal base images)
- No privileged escalation allowed
- Network policies for pod isolation (optional, per component)
- mTLS for service-to-service communication (Istio/service mesh)
- OAuth integration for user authentication (OpenShift)
- Webhook admission control for resource validation
- ServiceAccount-based RBAC throughout
- TLS 1.2+ for all external communication
- Auto-rotating TLS certificates (cert-manager or service-ca)

**Areas for Consideration:**
- Some operators expose metrics on HTTP (port 8080) instead of HTTPS
- Mixed use of OAuth and mTLS authentication patterns
- Storage credentials managed via Secrets (rotation is manual)
- Database connections may not enforce TLS (optional per component)
- Some components allow disabling authentication for development

## Next Steps for Documentation

1. **Generate Architecture Diagrams**: Use this platform architecture to create visual diagrams showing:
   - Component dependency graph
   - Network flows for key workflows
   - Multi-tenancy isolation boundaries
   - Service mesh traffic patterns

2. **Update ADRs (Architecture Decision Records)**: Document key decisions:
   - Why both KServe and ModelMesh for model serving
   - OAuth vs. mTLS authentication strategy
   - Namespace-level vs. cluster-level isolation model
   - Choice of Argo Workflows vs. Tekton for pipelines

3. **Create User-Facing Architecture Documentation**: Translate technical details into user guides:
   - "Getting Started with Model Serving"
   - "Distributed Training Guide"
   - "Pipeline Development Best Practices"
   - "Multi-Tenancy Setup for Administrators"

4. **Generate Security Architecture Review (SAR) Documentation**: For compliance and security teams:
   - Network security diagrams (ingress/egress flows)
   - RBAC permission matrix
   - Secret management and rotation policies
   - Compliance mapping (FIPS, SOC2, etc.)

5. **Performance and Scaling Guides**: Based on component resource patterns:
   - Cluster sizing recommendations
   - Resource quota templates for namespaces
   - Autoscaling configurations
   - High availability setup for production

6. **Integration Guides**: For platform extensions:
   - Custom serving runtime development
   - Pipeline step development
   - Dashboard plugin creation
   - Custom workbench image building

---

**Document Generated**: 2026-03-13
**Source Components**: 15 component architecture files in architecture/rhoai-2.25.0/
**Distribution**: RHOAI 2.25.0
**Aggregation Tool**: /aggregate-platform-architecture skill
