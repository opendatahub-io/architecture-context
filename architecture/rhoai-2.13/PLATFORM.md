# Platform: Red Hat OpenShift AI 2.13

## Metadata
- **Distribution**: RHOAI
- **Version**: 2.13
- **Release Date**: 2025-03
- **Base Platform**: OpenShift Container Platform 4.11+
- **Components Analyzed**: 13
- **Source**: architecture/rhoai-2.13

## Platform Overview

Red Hat OpenShift AI (RHOAI) 2.13 is an enterprise-ready AI/ML platform built on OpenShift that provides end-to-end capabilities for data science workflows. The platform enables data scientists and ML engineers to develop, train, and deploy machine learning models at scale with integrated support for popular frameworks including PyTorch, TensorFlow, and distributed computing systems like Ray.

The platform consists of 13 core components orchestrated by the RHODS Operator, providing a unified experience through the ODH Dashboard web interface. RHOAI delivers comprehensive capabilities spanning interactive development environments (Jupyter, VS Code, RStudio), distributed training frameworks (Kubeflow Training Operator, Ray, CodeFlare), ML pipeline orchestration (Data Science Pipelines), model serving (KServe, ModelMesh), job queueing (Kueue), and AI explainability (TrustyAI). All components integrate with OpenShift's security model, service mesh, and monitoring infrastructure.

The architecture follows cloud-native principles with Kubernetes operators managing lifecycle, declarative APIs via Custom Resource Definitions, and built-in support for OpenShift Routes, OAuth authentication, and service mesh integration for production deployments.

## Component Inventory

| Component | Type | Version | Purpose |
|-----------|------|---------|---------|
| RHODS Operator | Platform Orchestrator | v1.6.0-2256 | Primary operator managing all data science components and platform initialization |
| ODH Dashboard | Web UI | v1.21.0-18 | Web-based management console and user interface for platform components |
| Notebook Controller | Kubernetes Operator | v1.27.0-376 | Manages Jupyter notebook server lifecycle with culling and Istio integration |
| Workbench Images | Container Images | v20xx.1-299 | Pre-built Jupyter, VS Code, and RStudio environments with ML frameworks |
| KServe | Model Serving | v0.12.1 (261e500) | Serverless model serving with autoscaling and multi-framework support |
| ModelMesh Serving | Model Serving | v1.27.0-292 | Multi-model serving with optimized resource utilization |
| ODH Model Controller | Kubernetes Operator | v1.27.0-527 | OpenShift-specific KServe extensions for Routes, service mesh, and monitoring |
| Data Science Pipelines | Kubernetes Operator | a30d30f | ML pipeline orchestration based on Kubeflow Pipelines v1/v2 (Tekton/Argo) |
| Training Operator | Kubernetes Operator | f43318d8 | Distributed ML training for PyTorch, TensorFlow, XGBoost, MPI, MXNet, PaddlePaddle |
| CodeFlare Operator | Kubernetes Operator | 8679c4a | Manages Ray clusters and AppWrappers for distributed AI workloads |
| KubeRay Operator | Kubernetes Operator | 06b2ad42 (v1.1.0) | Ray cluster lifecycle management for distributed ML and inference |
| Kueue | Job Queueing | 1f8867691 | Job queueing and resource management with priority scheduling and quotas |
| TrustyAI Service Operator | Kubernetes Operator | 1.17.0 (a9e7fb8) | AI explainability and fairness metrics for model monitoring |

## Component Relationships

### Dependency Graph

```
RHODS Operator (Platform Orchestrator)
├── Deploys → ODH Dashboard
├── Deploys → Notebook Controller
├── Deploys → KServe
├── Deploys → ModelMesh Serving
├── Deploys → Data Science Pipelines Operator
├── Deploys → Training Operator
├── Deploys → CodeFlare Operator
├── Deploys → KubeRay Operator
├── Deploys → Kueue
└── Deploys → TrustyAI Service Operator

ODH Dashboard (User Interface)
├── Creates → Notebook CRs (via Notebook Controller)
├── Creates → InferenceService CRs (via KServe/ModelMesh)
├── Creates → DataSciencePipelinesApplication CRs
├── Creates → Data Connection Secrets
└── Manages → AcceleratorProfiles, ServingRuntimes

Notebook Controller
├── Creates → StatefulSets (notebook pods)
├── Creates → Services (notebook access)
├── Integrates → Istio VirtualServices (when enabled)
└── Uses → Workbench Images

KServe
├── Watched by → ODH Model Controller (augments with Routes/mesh)
├── Integrates → Knative Serving (serverless autoscaling)
├── Integrates → Istio (traffic management)
├── Uses → Model Registry (model metadata)
└── Consumes → ServingRuntime CRs

ODH Model Controller
├── Watches → InferenceService CRs
├── Creates → OpenShift Routes (ingress)
├── Creates → Istio VirtualServices (service mesh)
├── Creates → ServiceMonitors (Prometheus)
└── Aggregates → storage-config secrets

Data Science Pipelines
├── Integrates → KServe (model deployment)
├── Uses → Tekton/Argo (workflow orchestration)
├── Stores → MariaDB (metadata)
└── Stores → S3/Minio (artifacts)

Training Operator
├── Integrates → Kueue (job queueing)
├── Integrates → Volcano (gang scheduling)
└── Creates → PyTorchJob, TFJob, MPIJob, etc.

CodeFlare Operator
├── Watches → RayCluster CRs (managed by KubeRay)
├── Integrates → Kueue (AppWrapper scheduling)
├── Injects → OAuth Proxy (Ray dashboard auth)
└── Configures → mTLS (Ray cluster security)

KubeRay Operator
├── Manages → RayCluster, RayJob, RayService CRs
├── Integrated by → CodeFlare (security/networking augmentation)
└── Creates → Ray head/worker pods

Kueue
├── Queues → Batch Jobs, PyTorchJobs, TFJobs, MPIJobs
├── Queues → RayJobs, RayClusters
├── Queues → AppWrappers (CodeFlare)
└── Integrates → Cluster Autoscaler (ProvisioningRequests)

TrustyAI Service
├── Patches → InferenceService deployments (payload processors)
├── Monitors → KServe/ModelMesh models
└── Exposes → Fairness metrics (Prometheus)
```

### Central Components

**Core Platform Services** (most dependencies):
1. **RHODS Operator** - Deploys and manages all components
2. **ODH Dashboard** - Primary user interface for all workflows
3. **Kubernetes API Server** - All operators reconcile against K8s API
4. **OpenShift OAuth** - Centralized authentication for all web UIs
5. **Prometheus** - Centralized metrics collection from all components

**Model Serving Ecosystem**:
1. **KServe** - Primary model serving with autoscaling
2. **ODH Model Controller** - Extends KServe with OpenShift features
3. **ModelMesh** - Alternative serving for multi-model workloads
4. **Model Registry** - Shared model metadata and versioning

**Distributed Computing**:
1. **Kueue** - Job queue used by Training, Ray, and Batch workloads
2. **KubeRay** - Ray cluster management
3. **CodeFlare** - Ray security and AppWrapper orchestration

### Integration Patterns

**Pattern 1: Operator Watches CRD, Creates Resources**
- All operators watch their respective CRDs and create K8s resources
- Example: Notebook Controller watches Notebook → creates StatefulSet

**Pattern 2: Augmentation/Enhancement**
- One operator enhances resources created by another
- Example: ODH Model Controller watches KServe InferenceServices → creates Routes/VirtualServices
- Example: CodeFlare watches KubeRay RayClusters → injects OAuth/mTLS

**Pattern 3: Storage Aggregation**
- ODH Model Controller aggregates multiple data connection secrets into unified storage-config
- Consumed by KServe and ModelMesh for S3 access

**Pattern 4: API Integration**
- Dashboard calls K8s API to create CRs (Notebook, InferenceService, DSPA)
- Users interact via Dashboard → Dashboard creates CRs → Operators reconcile

**Pattern 5: Event Watching**
- Operators use K8s watch mechanisms for real-time reconciliation
- Example: Training Operator watches PyTorchJob status → updates job phase

## Platform Network Architecture

### Namespaces

| Namespace | Purpose | Components |
|-----------|---------|------------|
| redhat-ods-operator | Operator control plane | RHODS Operator controller-manager |
| redhat-ods-applications | User applications and UI | ODH Dashboard, Notebook Controller, Model Controllers |
| redhat-ods-monitoring | Platform monitoring | Prometheus, Alertmanager, Grafana |
| opendatahub | Component operators | KServe, ModelMesh, DSP, Training, CodeFlare, KubeRay, Kueue, TrustyAI operators |
| istio-system (conditional) | Service mesh control plane | Istio control plane (when ServiceMesh enabled) |
| knative-serving (conditional) | Serverless infrastructure | Knative controllers (when KServe Serverless enabled) |
| {user-namespaces} | User workloads | Notebooks, InferenceServices, Pipelines, Training Jobs, Ray Clusters |

### External Ingress Points

| Component | Ingress Type | Hosts | Port | Protocol | Encryption | Purpose |
|-----------|--------------|-------|------|----------|------------|---------|
| ODH Dashboard | OpenShift Route | odh-dashboard-{ns}.apps.{cluster} | 443/TCP | HTTPS | TLS 1.2+ (re-encrypt) | Web UI access |
| Jupyter Notebook | OpenShift Route | notebook-{name}-{ns}.apps.{cluster} | 443/TCP | HTTPS | TLS 1.2+ (edge) | Workbench access |
| VS Code Workbench | OpenShift Route | notebook-{name}-{ns}.apps.{cluster} | 443/TCP | HTTPS | TLS 1.2+ (edge) | Code Server access |
| RStudio Workbench | OpenShift Route | notebook-{name}-{ns}.apps.{cluster} | 443/TCP | HTTPS | TLS 1.2+ (edge) | RStudio access |
| KServe InferenceService | OpenShift Route + Istio | {isvc}-{ns}.apps.{cluster} | 443/TCP | HTTPS | TLS 1.2+ (edge) | Model inference API |
| ModelMesh Predictor | OpenShift Route | {predictor}-{ns}.apps.{cluster} | 443/TCP | HTTPS | TLS 1.2+ (edge) | Model inference API |
| DSP API Server | OpenShift Route | ds-pipeline-{name}.apps.{cluster} | 443/TCP | HTTPS | TLS 1.2+ (re-encrypt) | Pipeline management API |
| DSP UI | OpenShift Route | ds-pipeline-ui-{name}.apps.{cluster} | 443/TCP | HTTPS | TLS 1.2+ (re-encrypt) | Pipeline visualization |
| Ray Dashboard | OpenShift Route (via CodeFlare) | {raycluster}.apps.{cluster} | 443/TCP | HTTPS | TLS 1.2+ (passthrough) | Ray cluster dashboard |
| TrustyAI Service | OpenShift Route | {trustyai}.apps.{cluster} | 443/TCP | HTTPS | TLS 1.2+ (re-encrypt) | Explainability API |
| Prometheus | OpenShift Route (internal) | prometheus-{ns}.apps.{cluster} | 443/TCP | HTTPS | TLS 1.2+ (passthrough) | Metrics query interface |

### External Egress Dependencies

| Component | Destination | Port | Protocol | Encryption | Purpose |
|-----------|-------------|------|----------|------------|---------|
| All Operators | Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | Resource reconciliation and CRD watches |
| RHODS Operator | github.com | 443/TCP | HTTPS | TLS 1.2+ | Fetch component manifests from Git repos |
| All Components | quay.io, registry.redhat.io | 443/TCP | HTTPS | TLS 1.2+ | Pull container images |
| Workbenches | pypi.org | 443/TCP | HTTPS | TLS 1.2+ | Install Python packages via pip |
| Workbenches (RStudio) | cran.rstudio.com | 443/TCP | HTTPS | TLS 1.2+ | Install R packages |
| KServe/ModelMesh | S3-compatible Storage | 443/TCP | HTTPS | TLS 1.2+ | Download model artifacts |
| Data Science Pipelines | S3/Minio | 443/TCP or 9000/TCP | HTTPS or HTTP | TLS 1.2+ or None | Store pipeline artifacts |
| All Workloads | S3-compatible Storage | 443/TCP | HTTPS | TLS 1.2+ | Access datasets and models |
| Workbenches | Git repositories | 443/TCP or 22/TCP | HTTPS or SSH | TLS 1.2+ or SSH | Clone repos via jupyterlab-git |
| DSP Persistence Agent | External Database (optional) | 3306/5432/TCP | MySQL/PostgreSQL | TLS 1.2+ (optional) | Pipeline metadata storage |
| TrustyAI Service | External Database (optional) | 3306/5432/TCP | MySQL/PostgreSQL | TLS 1.2+ (optional) | Model monitoring data storage |

### Internal Service Mesh

| Setting | Value | Components Using |
|---------|-------|------------------|
| mTLS Mode | STRICT | KServe Serverless InferenceServices |
| mTLS Mode | PERMISSIVE | Ray Clusters (when CodeFlare mTLS enabled) |
| PeerAuthentication | STRICT (predictor pods) | KServe InferenceServices (when service mesh enabled) |
| VirtualService Routing | Istio Gateway | KServe Serverless, Knative Services |
| AuthorizationPolicy | Namespace isolation | KServe InferenceServices |
| Telemetry | Istio metrics | KServe InferenceServices |
| ServiceMesh Control Plane | data-science-smcp | All namespaces joined via ServiceMeshMember |

## Platform Security

### RBAC Summary

**Platform-Level ClusterRoles** (highest privileges):

| Component | ClusterRole | Key API Groups | Notable Resources | Key Verbs |
|-----------|-------------|----------------|-------------------|-----------|
| RHODS Operator | controller-manager-role | All ODH groups, operators.coreos.com, serving.kserve.io | datascienceclusters, dscinitializations, subscriptions, CRDs | create, delete, get, list, patch, update, watch |
| ODH Dashboard | odh-dashboard | kubeflow.org, serving.kserve.io, datasciencecluster, modelregistry | notebooks, inferenceservices, datascienceclusters, modelregistries | create, delete, get, list, patch, update, watch |
| KServe | kserve-manager-role | serving.kserve.io, serving.knative.dev, networking.istio.io | inferenceservices, knative services, virtualservices | create, delete, get, list, patch, update, watch |
| ODH Model Controller | odh-model-controller-role | serving.kserve.io, networking.istio.io, security.istio.io, route.openshift.io | inferenceservices, virtualservices, peerauthentications, routes | create, delete, get, list, patch, update, watch |
| Data Science Pipelines | manager-role | datasciencepipelinesapplications, argoproj.io, tekton.dev | datasciencepipelinesapplications, workflows, pipelines | create, delete, get, list, patch, update, watch |
| Training Operator | training-operator | kubeflow.org (6 job types), scheduling.volcano.sh | pytorchjobs, tfjobs, mpijobs, xgboostjobs, mxjobs, paddlejobs, podgroups | * (all verbs) |
| CodeFlare Operator | manager-role | ray.io, workload.codeflare.dev, kueue.x-k8s.io, dscinitialization | rayclusters, appwrappers, workloads, dscinitializations | get, list, watch, create, update, patch, delete |
| KubeRay Operator | kuberay-operator | ray.io, route.openshift.io, networking.k8s.io | rayclusters, rayjobs, rayservices, routes, ingresses | create, delete, get, list, patch, update, watch |
| Kueue | kueue-manager-role | kueue.x-k8s.io, kubeflow.org, ray.io, batch | clusterqueues, localqueues, workloads, resourceflavors, all training jobs | create, delete, get, list, patch, update, watch |
| ModelMesh Controller | modelmesh-controller-role | serving.kserve.io, monitoring.coreos.com | predictors, servingruntimes, clusterservingruntimes, servicemonitors | create, delete, get, list, patch, update, watch |
| TrustyAI Operator | manager-role | trustyai.opendatahub.io, serving.kserve.io | trustyaiservices, inferenceservices | get, list, watch, create, update, patch, delete |
| Notebook Controller | notebook-controller-role | kubeflow.org, networking.istio.io, apps | notebooks, virtualservices, statefulsets | * (all verbs) |

**User-Facing Roles**:

| Role | API Groups | Resources | Use Case |
|------|-----------|-----------|----------|
| kueue-batch-user-role | kueue.x-k8s.io | localqueues | Users submitting jobs to queues |
| training-edit | kubeflow.org | All 6 training job types | Users creating training jobs |
| training-view | kubeflow.org | All 6 training job types | Read-only access to training jobs |
| prometheus-ns-access | "" (core) | services, endpoints, pods | Prometheus scraping namespaced metrics |

### Secrets Inventory

| Component | Secret Name | Type | Purpose |
|-----------|-------------|------|---------|
| ODH Dashboard | dashboard-proxy-tls | kubernetes.io/tls | OAuth proxy TLS certificate |
| ODH Dashboard | dashboard-oauth-config-generated | Opaque | OAuth proxy cookie secret |
| ODH Dashboard | dashboard-oauth-client-generated | Opaque | OAuth client secret |
| Notebooks | {user-secret} | Opaque | User-provided credentials (API keys, S3, etc.) |
| KServe | kserve-webhook-server-cert | kubernetes.io/tls | Webhook admission TLS certificate |
| KServe | storage-config | Opaque | S3 credentials for storage initializer |
| ODH Model Controller | odh-model-controller-webhook-cert | kubernetes.io/tls | Webhook TLS certificate |
| ODH Model Controller | storage-config | Opaque | Aggregated S3 storage credentials |
| ODH Model Controller | odh-trusted-ca-bundle | Opaque | Custom CA certificates for storage endpoints |
| Data Science Pipelines | ds-pipelines-proxy-tls-{name} | kubernetes.io/tls | OAuth proxy TLS certificate |
| Data Science Pipelines | {name}-mariadb | Opaque | Auto-generated MariaDB credentials |
| Data Science Pipelines | {name}-minio | Opaque | Auto-generated Minio credentials |
| Data Science Pipelines | {db-secret-name} | Opaque | External database credentials |
| Data Science Pipelines | {storage-secret-name} | Opaque | External object storage credentials |
| CodeFlare Operator | codeflare-operator-webhook-server-cert | kubernetes.io/tls | Webhook TLS certificate |
| CodeFlare Operator | {raycluster}-ca-secret | Opaque | CA certificate for Ray mTLS |
| CodeFlare Operator | {raycluster}-tls | kubernetes.io/tls | TLS certificates for Ray nodes |
| CodeFlare Operator | {raycluster}-oauth-config | Opaque | OAuth proxy configuration for Ray dashboard |
| KubeRay Operator | webhook-server-cert | kubernetes.io/tls | Validating webhook TLS certificate |
| Kueue | kueue-webhook-server-cert | kubernetes.io/tls | Webhook TLS certificate |
| Kueue | kueue-visibility-server-cert | kubernetes.io/tls | Visibility API TLS certificate |
| Kueue | multikueue-cluster-credentials | Opaque | KubeConfig for remote clusters |
| ModelMesh | modelmesh-webhook-server-cert | kubernetes.io/tls | Webhook TLS certificate |
| ModelMesh | model-serving-etcd | Opaque | etcd connection configuration |
| ModelMesh | storage-config | Opaque | S3 storage credentials |
| TrustyAI | {name}-tls | kubernetes.io/tls | OAuth proxy TLS certificate |
| TrustyAI | {name}-internal | kubernetes.io/tls | Internal service TLS certificate |
| TrustyAI | {name}-db-credentials | Opaque | Database credentials (optional) |
| RHODS Operator | prometheus-tls | kubernetes.io/tls | Prometheus service TLS certificate |
| RHODS Operator | {component}-oauth-client-secret | Opaque | Generated OAuth client secrets |

### Authentication Mechanisms

| Pattern | Components Using | Enforcement Point | Details |
|---------|------------------|-------------------|---------|
| OpenShift OAuth (Bearer Token JWT) | ODH Dashboard, Notebooks, Ray Dashboard, DSP UI, TrustyAI | OAuth Proxy Sidecar | Users authenticate via OpenShift OAuth, proxy validates session |
| Kubernetes ServiceAccount Tokens | All Operators | Kubernetes API Server | Operators use SA tokens for K8s API access with RBAC |
| Istio mTLS (Client Certificates) | KServe InferenceServices | Envoy Sidecar Proxy | Service-to-service mTLS within service mesh |
| Ray mTLS (Cluster CA) | Ray Clusters (when enabled) | Ray GCS Server | Ray nodes authenticate using cluster CA certificates |
| AWS Signature v4 / IAM | KServe, ModelMesh, DSP, Workbenches | S3 Storage Provider | S3 access using AWS access keys or IAM roles |
| Database Username/Password | DSP, TrustyAI | Application | JDBC connections to MariaDB/PostgreSQL |
| Authorino (External Auth) | KServe InferenceServices (optional) | Authorino Service | API-level authentication/authorization for model endpoints |
| Bearer Tokens (Prometheus) | Metrics Endpoints | kube-rbac-proxy | Prometheus uses SA tokens for scraping |

## Platform APIs

### Custom Resource Definitions

**Platform Management**:

| Component | API Group | Kind | Scope | Purpose |
|-----------|-----------|------|-------|---------|
| RHODS Operator | datasciencecluster.opendatahub.io/v1 | DataScienceCluster | Cluster | Enable/configure platform components |
| RHODS Operator | dscinitialization.opendatahub.io/v1 | DSCInitialization | Cluster | Initialize service mesh, monitoring, trusted CA |
| RHODS Operator | features.opendatahub.io/v1 | FeatureTracker | Cluster | Track feature-created resources for cleanup |

**User Interface & Configuration**:

| Component | API Group | Kind | Scope | Purpose |
|-----------|-----------|------|-------|---------|
| ODH Dashboard | dashboard.opendatahub.io/v1 | OdhApplication | Namespaced | Applications in dashboard catalog |
| ODH Dashboard | opendatahub.io/v1alpha | OdhDashboardConfig | Namespaced | Dashboard feature flags and configuration |
| ODH Dashboard | dashboard.opendatahub.io/v1 | OdhDocument | Namespaced | Documentation resources |
| ODH Dashboard | console.openshift.io/v1 | OdhQuickStart | Namespaced | Interactive tutorials |
| ODH Dashboard | dashboard.opendatahub.io/v1 | AcceleratorProfile | Namespaced | GPU/accelerator profiles |

**Workbenches**:

| Component | API Group | Kind | Scope | Purpose |
|-----------|-----------|------|-------|---------|
| Notebook Controller | kubeflow.org/v1 | Notebook | Namespaced | Jupyter notebook server instances |
| Notebook Controller | kubeflow.org/v1beta1 | Notebook | Namespaced | Beta version with webhook support |
| Notebook Controller | kubeflow.org/v1alpha1 | Notebook | Namespaced | Legacy version (conversion supported) |

**Model Serving**:

| Component | API Group | Kind | Scope | Purpose |
|-----------|-----------|------|-------|---------|
| KServe | serving.kserve.io/v1beta1 | InferenceService | Namespaced | Model serving workload with predictor/transformer/explainer |
| KServe | serving.kserve.io/v1alpha1 | InferenceGraph | Namespaced | Multi-step inference pipelines |
| KServe | serving.kserve.io/v1alpha1 | TrainedModel | Namespaced | Trained model artifacts and associations |
| KServe | serving.kserve.io/v1alpha1 | ClusterServingRuntime | Cluster | Cluster-scoped serving runtime template |
| KServe | serving.kserve.io/v1alpha1 | ServingRuntime | Namespaced | Namespace-scoped serving runtime template |
| KServe | serving.kserve.io/v1alpha1 | ClusterStorageContainer | Cluster | Storage backend initialization config |
| ModelMesh | serving.kserve.io/v1alpha1 | Predictor | Namespaced | Single model to be served |
| ModelMesh | serving.kserve.io/v1alpha1 | ServingRuntime | Namespaced | Serving runtime template for ModelMesh |
| ModelMesh | serving.kserve.io/v1alpha1 | ClusterServingRuntime | Cluster | Cluster-wide serving runtime template |

**ML Pipelines**:

| Component | API Group | Kind | Scope | Purpose |
|-----------|-----------|------|-------|---------|
| DSP Operator | datasciencepipelinesapplications.opendatahub.io/v1alpha1 | DataSciencePipelinesApplication | Namespaced | DSP stack deployment configuration |

**Distributed Training**:

| Component | API Group | Kind | Scope | Purpose |
|-----------|-----------|------|-------|---------|
| Training Operator | kubeflow.org/v1 | PyTorchJob | Namespaced | Distributed PyTorch training jobs |
| Training Operator | kubeflow.org/v1 | TFJob | Namespaced | Distributed TensorFlow training jobs |
| Training Operator | kubeflow.org/v1 | MPIJob | Namespaced | MPI-based distributed training |
| Training Operator | kubeflow.org/v1 | XGBoostJob | Namespaced | Distributed XGBoost training |
| Training Operator | kubeflow.org/v1 | MXJob | Namespaced | Distributed MXNet training |
| Training Operator | kubeflow.org/v1 | PaddleJob | Namespaced | Distributed PaddlePaddle training |

**Distributed Computing (Ray)**:

| Component | API Group | Kind | Scope | Purpose |
|-----------|-----------|------|-------|---------|
| KubeRay | ray.io/v1 | RayCluster | Namespaced | Ray cluster with autoscaling and fault tolerance |
| KubeRay | ray.io/v1 | RayJob | Namespaced | Batch jobs on Ray cluster |
| KubeRay | ray.io/v1 | RayService | Namespaced | Ray Serve applications with HA |
| CodeFlare | workload.codeflare.dev/v1beta2 | AppWrapper | Namespaced | Wraps resources for gang scheduling |

**Job Queueing**:

| Component | API Group | Kind | Scope | Purpose |
|-----------|-----------|------|-------|---------|
| Kueue | kueue.x-k8s.io/v1beta1 | ClusterQueue | Cluster | Cluster-wide resource quotas and queueing |
| Kueue | kueue.x-k8s.io/v1beta1 | LocalQueue | Namespaced | Namespace-scoped queue |
| Kueue | kueue.x-k8s.io/v1beta1 | Workload | Namespaced | Abstract job resource requirements |
| Kueue | kueue.x-k8s.io/v1beta1 | ResourceFlavor | Cluster | Resource characteristics for quotas |
| Kueue | kueue.x-k8s.io/v1beta1 | AdmissionCheck | Cluster | External admission requirements |
| Kueue | kueue.x-k8s.io/v1beta1 | WorkloadPriorityClass | Cluster | Priority values for scheduling |
| Kueue | kueue.x-k8s.io/v1beta1 | ProvisioningRequestConfig | Cluster | Cluster autoscaler integration |

**AI Explainability**:

| Component | API Group | Kind | Scope | Purpose |
|-----------|-----------|------|-------|---------|
| TrustyAI | trustyai.opendatahub.io/v1alpha1 | TrustyAIService | Namespaced | TrustyAI explainability service deployment |

**Total CRDs**: 44 (across 13 components)

### Public HTTP Endpoints

**User-Facing Services**:

| Component | Path Pattern | Port | Protocol | Auth | Purpose |
|-----------|-------------|------|----------|------|---------|
| ODH Dashboard | /* | 8443/TCP | HTTPS | OAuth | Web UI for platform management |
| Jupyter Notebook | /notebook/{ns}/{name}/* | 8888/TCP | HTTP (via OAuth proxy) | OAuth | Interactive notebook environment |
| VS Code | /codeserver/* | 8888/TCP | HTTP (via OAuth proxy) | OAuth | Code Server web interface |
| RStudio | /rstudio/* | 8888/TCP | HTTP (via OAuth proxy) | OAuth | RStudio web interface |
| KServe InferenceService | /v1/models/{model}:predict | 8080/TCP | HTTP (via Istio) | Bearer/mTLS | KServe v1 prediction API |
| KServe InferenceService | /v2/models/{model}/infer | 8080/TCP | HTTP (via Istio) | Bearer/mTLS | KServe v2 prediction API |
| ModelMesh Predictor | /v2/models/{model}/infer | 8008/TCP | HTTP | None (internal) | ModelMesh REST inference |
| DSP API Server | /apis/v2beta1/* | 8888/TCP | HTTP (via OAuth proxy) | OAuth | Pipeline management API |
| Ray Dashboard | /* | 8265/TCP | HTTP (via OAuth proxy) | OAuth | Ray cluster monitoring |
| TrustyAI Service | /* | 8080/TCP | HTTP (via OAuth proxy) | OAuth | Explainability API |

**Operator Health & Metrics**:

| Component | Path | Port | Protocol | Auth | Purpose |
|-----------|------|------|----------|------|---------|
| All Operators | /healthz | 8081/TCP | HTTP | None | Liveness probe |
| All Operators | /readyz | 8081/TCP | HTTP | None | Readiness probe |
| All Operators | /metrics | 8080/TCP | HTTP | Bearer Token | Prometheus metrics |

### gRPC Services

| Component | Service | Port | Protocol | Encryption | Purpose |
|-----------|---------|------|----------|------------|---------|
| KServe | inference.GRPCInferenceService | 8081/TCP | gRPC/HTTP2 | None/TLS | KServe v2 gRPC inference |
| ModelMesh | ModelMesh Management | 8033/TCP | gRPC | None | Model load/unload/status |
| ModelMesh | ModelMesh Inference | 8033/TCP | gRPC | None | Model inference via gRPC |
| DSP | DSP API Server | 8887/TCP | gRPC | TLS (optional) | gRPC pipeline operations |
| DSP | ML Metadata gRPC | 8080/TCP | gRPC | TLS (optional) | Metadata lineage tracking |
| DSP | ML Metadata Envoy | 9090/TCP | gRPC | TLS 1.2+ | Authenticated MLMD access |

## Data Flows

### Key Platform Workflows

#### Workflow 1: User Launches Jupyter Notebook

| Step | Component | Action | Next Component |
|------|-----------|--------|----------------|
| 1 | User (Browser) | Logs into OpenShift, accesses ODH Dashboard | ODH Dashboard |
| 2 | ODH Dashboard | Displays available notebook images and configurations | User |
| 3 | User | Selects image, configures resources, clicks "Start" | ODH Dashboard Backend |
| 4 | ODH Dashboard Backend | Creates Namespace (if needed), creates Notebook CR | Kubernetes API |
| 5 | Notebook Controller | Watches Notebook CR, creates StatefulSet | Kubernetes |
| 6 | Kubernetes | Schedules notebook pod with PVC, injects OAuth proxy | Node |
| 7 | Notebook Pod | Pulls workbench image, starts Jupyter server | - |
| 8 | Notebook Controller | Creates Service, creates Route, creates VirtualService (if Istio) | OpenShift Router |
| 9 | User (Browser) | Accesses Route URL, OAuth proxy authenticates | Notebook Pod |
| 10 | User | Works in Jupyter, installs packages via pip | PyPI, S3, etc. |

#### Workflow 2: Model Training to Deployment

| Step | Component | Action | Next Component |
|------|-----------|--------|----------------|
| 1 | User (Notebook) | Trains model locally or submits PyTorchJob | Training Operator |
| 2 | Training Operator | Creates master/worker pods for distributed training | Kubernetes |
| 3 | Training Pods | Execute training, communicate via framework protocol | Each other |
| 4 | Training Pods | Save model artifacts to S3 bucket | S3 Storage |
| 5 | User (Dashboard) | Creates InferenceService CR pointing to S3 model | KServe Controller |
| 6 | KServe Controller | Creates Knative Service or Deployment for serving | Knative/K8s |
| 7 | ODH Model Controller | Watches InferenceService, creates Route, VirtualService, ServiceMonitor | OpenShift/Istio |
| 8 | Storage Initializer | Downloads model from S3 to shared volume | Model Server Pod |
| 9 | Model Server | Loads model, exposes inference endpoint | - |
| 10 | External Client | Sends prediction requests to Route → Istio → Pod | InferenceService |

#### Workflow 3: ML Pipeline Execution

| Step | Component | Action | Next Component |
|------|-----------|--------|----------------|
| 1 | User (Notebook with Elyra) | Designs pipeline visually, defines steps | Elyra Extension |
| 2 | Elyra | Converts visual pipeline to KFP YAML, submits | DSP API Server |
| 3 | DSP API Server | Creates workflow CR (Argo or Tekton) | Workflow Engine |
| 4 | Argo/Tekton Controller | Creates pipeline pods for each step | Kubernetes |
| 5 | Pipeline Step 1 | Executes data preprocessing, uploads to S3 | S3 Storage |
| 6 | Pipeline Step 2 | Trains model using processed data, saves to S3 | S3 Storage |
| 7 | Pipeline Step 3 | Creates InferenceService CR to deploy model | KServe |
| 8 | Persistence Agent | Watches workflow pods, persists status/logs to MariaDB | MariaDB |
| 9 | User (DSP UI) | Views pipeline run status, metrics, artifacts | DSP API Server |

#### Workflow 4: Distributed Ray Job with Queueing

| Step | Component | Action | Next Component |
|------|-----------|--------|----------------|
| 1 | User | Submits AppWrapper CR wrapping RayCluster | CodeFlare Operator |
| 2 | CodeFlare Operator | Creates Workload CR for Kueue | Kueue |
| 3 | Kueue | Evaluates queue, checks quota, admits workload when resources available | CodeFlare Operator |
| 4 | CodeFlare Operator | Unsuspends AppWrapper, creates RayCluster CR | KubeRay Operator |
| 5 | KubeRay Operator | Creates Ray head pod, worker pods | Kubernetes |
| 6 | CodeFlare Operator | Injects OAuth proxy into head pod, configures mTLS | Ray Pods |
| 7 | Ray Workers | Connect to head via GCS (port 6379), form cluster | Ray Head |
| 8 | User (Ray Client) | Submits Ray job to head node | Ray Head |
| 9 | Ray Head | Distributes tasks to workers, collects results | Ray Workers |
| 10 | User | Accesses Ray dashboard via OAuth-protected Route | Ray Head |

#### Workflow 5: Model Monitoring and Explainability

| Step | Component | Action | Next Component |
|------|-----------|--------|----------------|
| 1 | Admin | Creates TrustyAIService CR in namespace with InferenceServices | TrustyAI Operator |
| 2 | TrustyAI Operator | Deploys TrustyAI service, creates ServiceMonitor | Kubernetes/Prometheus |
| 3 | TrustyAI Operator | Patches InferenceService deployments with payload processor env vars | KServe/ModelMesh |
| 4 | Model Serving Pods | Send inference payloads to TrustyAI service | TrustyAI Service |
| 5 | TrustyAI Service | Analyzes payloads, calculates fairness metrics (SPD, DIR) | - |
| 6 | TrustyAI Service | Exposes metrics on /q/metrics endpoint | Prometheus |
| 7 | Prometheus | Scrapes fairness metrics every 30s | TrustyAI Service |
| 8 | User (Grafana) | Views fairness dashboards, sets up alerts | Prometheus |
| 9 | User (TrustyAI API) | Requests explainability for specific predictions | TrustyAI Service |

## Deployment Architecture

### Deployment Topology

**Control Plane (redhat-ods-operator namespace)**:
- RHODS Operator: 1 replica (leader election enabled)
- Manages entire platform lifecycle

**Applications Plane (redhat-ods-applications namespace)**:
- ODH Dashboard: 2 replicas (HA with anti-affinity)
- Notebook Controller: 1 replica
- ODH Model Controller: 3 replicas (HA with leader election)

**Component Operators (opendatahub namespace)**:
- KServe Controller: 1 replica (leader election)
- ModelMesh Controller: 1 replica (leader election)
- DSP Operator: 1 replica
- Training Operator: 1 replica
- CodeFlare Operator: 1 replica
- KubeRay Operator: 1 replica (leader election)
- Kueue: 1 replica (leader election)
- TrustyAI Operator: 1 replica (leader election)

**Monitoring (redhat-ods-monitoring namespace)**:
- Prometheus: 1 replica (StatefulSet)
- Alertmanager: 1 replica
- Grafana: Deployed by Prometheus Operator

**User Workloads (user namespaces)**:
- Notebooks: 1 pod per notebook (StatefulSet)
- InferenceServices: Variable (autoscaling 0-N based on traffic)
- Pipeline Runs: Ephemeral pods per step
- Training Jobs: Variable workers per job
- Ray Clusters: 1 head + N workers

### Resource Requirements

**Minimum Cluster Requirements for RHOAI 2.13**:
- **Nodes**: 3 worker nodes (for HA)
- **CPU**: 16 cores total (operators + minimal workloads)
- **Memory**: 64 GB total
- **Storage**: 100 GB for PVCs (workbenches, pipeline artifacts)
- **OpenShift**: 4.11+ (4.14+ recommended)

**Operator Resource Allocations**:

| Operator | CPU Request | CPU Limit | Memory Request | Memory Limit |
|----------|-------------|-----------|----------------|--------------|
| RHODS Operator | 100m | 500m | 780Mi | 4Gi |
| ODH Dashboard (per pod) | 500m | 1000m | 1Gi | 2Gi |
| Notebook Controller | 100m | 500m | 512Mi | 1Gi |
| KServe Controller | 100m | 500m | 512Mi | 2Gi |
| ODH Model Controller | 10m | 500m | 64Mi | 2Gi |
| DSP Operator | 500m | 500m | 512Mi | 512Mi |
| Training Operator | 100m | 200m | 64Mi | 128Mi |
| CodeFlare Operator | 200m | 500m | 256Mi | 512Mi |
| KubeRay Operator | 100m | 500m | 512Mi | 1Gi |
| Kueue | 500m | 500m | 512Mi | 512Mi |
| ModelMesh Controller | 50m | 1000m | 96Mi | 512Mi |
| TrustyAI Operator | 10m | 500m | 64Mi | 128Mi |

**Total Operator Overhead**: ~2.5 CPU cores, ~6 GB memory (excluding user workloads)

## Version-Specific Changes (2.13)

| Component | Notable Changes |
|-----------|-----------------|
| RHODS Operator | - Stable 2.13 release branch<br>- Component manifest fetching from Git repos<br>- Feature tracker for resource cleanup<br>- Enhanced DSCInitialization for service mesh config |
| ODH Dashboard | - Konflux service account migration<br>- Model registry integration<br>- Connection type management<br>- Enhanced accelerator profile support<br>- Node.js 18 base image |
| Notebook Controller | - Konflux build pipeline updates<br>- OpenShift compatibility improvements (fsGroup handling)<br>- Regular dependency updates<br>- BDD test enhancements |
| Workbench Images | - Habana notebook deactivated from manifests<br>- ROCm image support for AMD GPUs<br>- Weekly security patches and digest updates<br>- KFP package version alignment<br>- Automated library upgrade tooling |
| KServe | - Type Confusion security fix (RHOAIENG-14313)<br>- Image digest updates for all components<br>- Aggregate roles fix in manifests<br>- Upstream merge from v0.12.1 |
| ModelMesh Serving | - Konflux reference updates<br>- Based on upstream v0.11.0<br>- Stable maintenance mode |
| ODH Model Controller | - Stable release snapshot v1.27.0-rhods-527<br>- OpenShift Route and service mesh integration<br>- Model registry reconciler enhancements |
| DSP Operator | - Konflux reference updates<br>- DSP v2 (Argo) and v1 (Tekton) support<br>- Improved health check handling<br>- Custom CA bundle support |
| Training Operator | - Stable 2.13 snapshot<br>- Python SDK v1.7.0<br>- Kubernetes 1.25+ support<br>- FIPS compliance (strictfipsruntime) |
| CodeFlare Operator | - Konflux reference updates<br>- KubeRay v1.1.1 integration<br>- Enhanced OAuth and mTLS for Ray clusters<br>- AppWrapper v0.23.0 support |
| KubeRay Operator | - Konflux reference updates<br>- Based on upstream v1.0.0 (v1 CRDs GA)<br>- OpenShift Route support<br>- Enhanced GCS fault tolerance |
| Kueue | - Konflux reference updates<br>- Multi-cluster workload distribution (MultiKueue)<br>- Visibility API for queue monitoring<br>- Support for 6+ job frameworks |
| TrustyAI Operator | - Konflux reference updates to 998b546<br>- Version 1.17.0 stable<br>- KServe/ModelMesh payload processor integration<br>- Database storage mode support |

**Platform-Wide Updates**:
- All components migrated to Konflux build system
- Consistent UBI8 base images across operators
- FIPS 140-2 compliance (strictfipsruntime build tags)
- Weekly dependency and security updates
- Image digest-based references for reproducibility

## Platform Maturity

### Component Statistics

- **Total Components**: 13
- **Operator-based Components**: 12 (92%)
- **Web UI Components**: 1 (ODH Dashboard)
- **Container Image Collections**: 1 (Workbench Images)
- **Custom Resource Definitions**: 44 total
  - v1 (GA): 18 CRDs
  - v1beta1/v1beta2: 9 CRDs
  - v1alpha1: 17 CRDs
- **API Versions in Use**: v1 (primary), v1beta1, v1beta2, v1alpha1

### Service Mesh Coverage

- **Components with Service Mesh Integration**: 3
  - KServe Serverless: STRICT mTLS for predictor pods
  - ODH Model Controller: Creates VirtualServices, PeerAuthentications, Telemetry
  - Notebook Controller: Optional VirtualService creation (USE_ISTIO flag)
  - CodeFlare: Optional mTLS for Ray clusters
- **Service Mesh Coverage**: ~25% (optional, enabled for production KServe deployments)
- **Service Mesh Control Plane**: data-science-smcp (Maistra/OpenShift Service Mesh)

### mTLS Enforcement

- **STRICT mTLS**: KServe Serverless InferenceServices (when service mesh enabled)
- **PERMISSIVE mTLS**: Ray Clusters (when CodeFlare mTLS enabled)
- **No mTLS**: Notebooks, Training Jobs, ModelMesh, Pipelines, Operators
- **Overall Status**: MIXED (optional, production workloads can enable)

### Authentication Coverage

- **OAuth-Protected External Access**: 100%
  - All user-facing web UIs use OpenShift OAuth proxy
  - All Routes use edge/re-encrypt TLS termination
- **ServiceAccount Tokens for APIs**: 100%
  - All operators use SA tokens with RBAC
- **Optional External Auth**: Available
  - Authorino for InferenceService API authentication
  - Can be enabled per-InferenceService with labels

### CRD Maturity

- **GA (v1)**: 41% - Production-ready, stable APIs
- **Beta (v1beta1/v1beta2)**: 20% - Near-stable, minor changes possible
- **Alpha (v1alpha1)**: 39% - Experimental, subject to change

**Most Mature Components (v1 APIs)**:
- RHODS Operator: DataScienceCluster, DSCInitialization
- ODH Dashboard: OdhApplication, OdhDocument, AcceleratorProfile
- Notebook Controller: Notebook (v1 with v1beta1/v1alpha1 conversion)
- Training Operator: All 6 job types (PyTorchJob, TFJob, etc.)
- KubeRay: RayCluster, RayJob, RayService

**Evolving Components (alpha APIs)**:
- KServe: InferenceGraph, TrainedModel, ServingRuntime
- ModelMesh: Predictor, ServingRuntime
- Kueue: Most CRDs (v1beta1, moving toward v1)
- TrustyAI: TrustyAIService (v1alpha1)

### Build & Release Maturity

- **Build System**: Konflux (100% adoption)
- **Base Images**: UBI8 (100% - Red Hat Universal Base Image)
- **Security Scanning**: All images scanned in Konflux pipeline
- **FIPS Compliance**: Enabled for all Go-based operators
- **Image Signing**: All images signed by Red Hat
- **Release Cadence**: Quarterly major releases + weekly patches
- **Support Lifecycle**: 1 year minimum per major version

### Monitoring & Observability

- **Prometheus Metrics**: 100% of operators expose /metrics
- **ServiceMonitors**: Available for all operators
- **Health Probes**: 100% of operators have /healthz and /readyz
- **Grafana Dashboards**: Auto-created for InferenceServices
- **Alerting**: Configured via Prometheus Operator
- **Logging**: Structured logging (JSON) in all operators

### High Availability

- **Operators with Leader Election**: 9 (KServe, ODH Model Controller, KubeRay, Kueue, ModelMesh, TrustyAI, RHODS, DSP, CodeFlare)
- **Multi-Replica Deployments**:
  - ODH Dashboard: 2 replicas (default)
  - ODH Model Controller: 3 replicas
  - Most operators: 1 replica (leader election handles HA)
- **StatefulSet Workloads**: Notebooks, Prometheus, MariaDB (DSP)
- **Autoscaling**: KServe InferenceServices (0-N based on traffic via Knative)

### Platform Integration Score

| Integration | Coverage | Status |
|-------------|----------|--------|
| OpenShift Routes | 100% | All external services exposed via Routes |
| OpenShift OAuth | 100% | All user-facing UIs use OAuth proxy |
| OpenShift Service CA | 100% | TLS certificates auto-provisioned |
| Service Mesh (Istio) | Optional | KServe production deployments |
| Serverless (Knative) | Optional | KServe Serverless mode |
| Prometheus Operator | 100% | All metrics via ServiceMonitors |
| OpenShift Pipelines | Optional | DSP v1 uses Tekton |
| Cluster Autoscaler | Optional | Kueue ProvisioningRequests |

### Security Posture

- **Non-root Containers**: 100%
- **RBAC Enforcement**: 100%
- **NetworkPolicies**: Partial (KServe, ModelMesh, operators)
- **Secret Encryption at Rest**: K8s default
- **TLS in Transit (External)**: 100%
- **TLS in Transit (Internal)**: Optional (service mesh)
- **Image Vulnerability Scanning**: 100%
- **FIPS 140-2 Compliance**: Available (all operators)

## Next Steps for Documentation

### Immediate Actions

1. **Generate Architecture Diagrams**:
   - Platform component relationship diagram
   - Network flow diagrams for each workflow
   - Service mesh topology when enabled
   - Namespace and deployment topology

2. **Create User-Facing Documentation**:
   - Getting Started Guide (end-to-end workflow)
   - Component Selection Guide (when to use KServe vs ModelMesh, etc.)
   - Production Deployment Checklist (service mesh, HA, monitoring)
   - Troubleshooting Guide (common issues from each component)

3. **Security Architecture Review (SAR)**:
   - Network security zones diagram
   - Authentication flow diagrams
   - RBAC policy documentation
   - Threat model and mitigations
   - Compliance documentation (FIPS, STIGs)

### Enhanced Documentation

4. **Update Architecture Decision Records (ADRs)**:
   - ADR: KServe Serverless vs Raw deployment modes
   - ADR: ModelMesh vs KServe selection criteria
   - ADR: Service mesh integration approach
   - ADR: Multi-tenancy isolation strategy
   - ADR: Monitoring and observability architecture

5. **Create Operational Runbooks**:
   - Operator upgrade procedures
   - Component scaling guidelines
   - Backup and disaster recovery
   - Performance tuning guide
   - Cost optimization strategies

6. **Developer Documentation**:
   - Component integration guide
   - Custom ServingRuntime creation
   - Webhook development guidelines
   - Testing and validation procedures
   - Contributing to platform components

### Platform Evolution

7. **Maturity Improvements**:
   - Graduate alpha APIs to beta/GA
   - Expand service mesh coverage to all components
   - Implement comprehensive NetworkPolicies
   - Add webhook validations where missing
   - Enhance multi-tenancy isolation

8. **Observability Enhancements**:
   - Distributed tracing (Jaeger integration)
   - Centralized logging (OpenShift Logging)
   - Cost attribution metrics
   - User activity analytics
   - Predictive scaling metrics

9. **Reference Architectures**:
   - Small/Dev deployment (minimal resources)
   - Medium/Test deployment (HA operators)
   - Large/Production deployment (full HA + service mesh)
   - GPU-focused deployment (ML training emphasis)
   - Inference-focused deployment (serving emphasis)
   - Multi-cluster deployment (MultiKueue)

## Summary

Red Hat OpenShift AI 2.13 provides a comprehensive, production-ready platform for AI/ML workloads with:

- **13 integrated components** working together seamlessly
- **44 Custom Resource Definitions** providing declarative APIs
- **100% OpenShift integration** (Routes, OAuth, Service CA)
- **Multiple deployment modes** (serverless, traditional, multi-model)
- **Comprehensive security** (RBAC, mTLS, OAuth, secrets management)
- **Enterprise monitoring** (Prometheus, Grafana, ServiceMonitors)
- **Flexible workflows** (notebooks → training → pipelines → serving → monitoring)

The platform architecture prioritizes:
- **Operator-based lifecycle management** for automation
- **Cloud-native design** with Kubernetes primitives
- **Security by default** with OAuth and TLS everywhere
- **Extensibility** via CRDs and ServingRuntimes
- **Production readiness** with HA, monitoring, and service mesh support

Key differentiators:
- Deep OpenShift integration (Routes, OAuth, SCC)
- Comprehensive ML lifecycle coverage (develop → train → deploy → monitor)
- Multiple serving options (KServe, ModelMesh) for different use cases
- Advanced queueing (Kueue) for multi-tenant resource management
- AI explainability (TrustyAI) for responsible AI

The platform is mature and ready for production use, with ongoing evolution toward v1 APIs, expanded service mesh coverage, and enhanced observability.
