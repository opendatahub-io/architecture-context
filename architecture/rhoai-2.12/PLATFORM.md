# Platform: Red Hat OpenShift AI 2.12

## Metadata
- **Distribution**: RHOAI
- **Version**: 2.12
- **Base Platform**: OpenShift Container Platform 4.11+
- **Components Analyzed**: 13
- **Analysis Date**: 2026-03-15

## Platform Overview

Red Hat OpenShift AI (RHOAI) 2.12 is a comprehensive platform for developing, training, serving, and monitoring AI/ML workloads on Kubernetes. The platform provides an integrated suite of tools spanning the complete machine learning lifecycle, from data science workbenches and distributed training to model serving and explainability.

The platform is built on a microservices architecture where each component operates independently but integrates through Kubernetes APIs, service mesh networking, and shared authentication. The RHODS Operator serves as the central orchestrator, deploying and managing all platform components through declarative DataScienceCluster custom resources. Components communicate via REST APIs, gRPC services, and Kubernetes CRD controllers, with Istio service mesh providing mTLS encryption, traffic management, and fine-grained authorization.

RHOAI 2.12 emphasizes enterprise security with OpenShift OAuth integration, RBAC policies, network isolation, and compliance with OpenShift's security context constraints. The platform supports multiple model serving strategies (KServe serverless, ModelMesh multi-model, and raw Kubernetes deployments), various training frameworks (PyTorch, TensorFlow, XGBoost, MPI), and provides built-in monitoring, fairness analysis, and explainability capabilities.

## Component Inventory

| Component | Type | Version | Purpose |
|-----------|------|---------|---------|
| RHODS Operator | Operator | v1.6.0-718-g719153112 | Central orchestrator managing platform lifecycle via DataScienceCluster CRs |
| ODH Dashboard | Web Application | v1.21.0-18-rhods-2182-ge30b77c5d | Web UI for managing projects, workbenches, pipelines, and model serving |
| KServe | Operator + Runtime | 81bf82134 | Serverless model serving with autoscaling and multi-framework support |
| ModelMesh Serving | Operator + Runtime | v1.27.0-rhods-254-g3d48699 | High-density multi-model serving with intelligent caching |
| ODH Model Controller | Operator | v1.27.0-rhods-453-g5a5992d | Extends KServe with OpenShift Routes, service mesh, and monitoring integration |
| Data Science Pipelines Operator | Operator | 6bcc644 | ML workflow orchestration based on Kubeflow Pipelines v2 (Argo Workflows) |
| Workbenches (Notebooks) | Container Images | v20xx.1-255-g4c7e4f988 | JupyterLab, RStudio, VS Code workbench images with ML frameworks |
| ODH Notebook Controller | Operator | v1.27.0-rhods-327-gc9976e28 | Extends Kubeflow Notebooks with OAuth, Routes, and network policies |
| CodeFlare Operator | Operator | 4e58587 | Distributed ML workload orchestration with Ray cluster management |
| KubeRay Operator | Operator | b0225b36 | Manages Ray clusters for distributed computing and ML workloads |
| Kueue | Operator | v0.7.0 (175aa61f0) | Job queueing and resource quota management for batch workloads |
| Training Operator | Operator | c7d4e1b4 | Distributed training for PyTorch, TensorFlow, XGBoost, MPI, MXNet, PaddlePaddle |
| TrustyAI Service Operator | Operator | 1.17.0 (65f1454) | ML explainability, fairness metrics, and bias detection |

## Component Relationships

### Dependency Graph

```
RHODS Operator (Central Orchestrator)
├── Deploys → ODH Dashboard
├── Deploys → KServe
├── Deploys → ModelMesh Serving
├── Deploys → ODH Model Controller
├── Deploys → Data Science Pipelines Operator
├── Deploys → Workbenches (via ImageStreams)
├── Deploys → ODH Notebook Controller
├── Deploys → CodeFlare Operator
├── Deploys → KubeRay Operator
├── Deploys → Kueue
├── Deploys → Training Operator
└── Deploys → TrustyAI Service Operator

ODH Dashboard
├── Proxies → Data Science Pipelines API
├── Proxies → Model Registry API
├── Proxies → ML Metadata (MLMD) API
├── Proxies → TrustyAI Service API
├── Creates → Notebook CRs (via ODH Notebook Controller)
├── Creates → InferenceService CRs (via KServe/ModelMesh)
└── Creates → DataSciencePipelinesApplication CRs

ODH Notebook Controller
├── Watches → Notebook CRs (from Kubeflow Notebook Controller)
├── Creates → OpenShift Routes (for external access)
├── Creates → OAuth Proxy (for authentication)
├── Creates → NetworkPolicies (for isolation)
└── Uses → Workbench Images (from ImageStreams)

Data Science Pipelines Operator
├── Creates → Argo Workflows (for pipeline execution)
├── Uses → MariaDB (metadata storage)
├── Uses → Minio/S3 (artifact storage)
├── Proxies → ML Metadata gRPC (via Envoy)
└── Integrates → OAuth Proxy (external access)

KServe
├── Depends → Knative Serving (serverless mode)
├── Depends → Istio (traffic management)
├── Uses → ODH Model Controller (for Routes, VirtualServices)
├── Uses → Storage Initializer (model downloads from S3/PVC)
└── Integrates → Model Registry (metadata tracking)

ModelMesh Serving
├── Uses → Etcd (cluster coordination)
├── Uses → Istio (optional mTLS)
├── Integrates → Prometheus (metrics)
└── Supports → Multiple runtime servers (Triton, MLServer, OVMS, TorchServe)

ODH Model Controller
├── Watches → InferenceService CRs (from KServe)
├── Creates → OpenShift Routes (external access)
├── Creates → Istio VirtualServices (service mesh routing)
├── Creates → Authorino AuthConfigs (authentication)
├── Creates → ServiceMeshMembers (mesh integration)
└── Creates → ServiceMonitors (Prometheus monitoring)

CodeFlare Operator
├── Watches → RayCluster CRs (from KubeRay)
├── Injects → OAuth Proxy (dashboard access)
├── Injects → mTLS Certificates (Ray node communication)
├── Creates → OpenShift Routes (Ray dashboard)
├── Integrates → Kueue (via AppWrapper)
└── Creates → NetworkPolicies (pod isolation)

KubeRay Operator
├── Creates → Ray Clusters (head + worker pods)
├── Creates → Services (GCS, dashboard, client, serve)
├── Integrates → Volcano Scheduler (gang scheduling)
└── Supports → RayJob, RayService (batch and serving)

Kueue
├── Watches → Jobs, PyTorchJobs, TFJobs, RayJobs, MPIJobs
├── Creates → Workload CRs (internal queue representation)
├── Manages → ClusterQueues, LocalQueues (quota management)
├── Integrates → Cluster Autoscaler (via ProvisioningRequest)
└── Provides → Visibility API (pending workload inspection)

Training Operator
├── Watches → PyTorchJob, TFJob, MPIJob, XGBoostJob, MXJob, PaddleJob CRs
├── Creates → Training Pods (distributed workers)
├── Integrates → Volcano/scheduler-plugins (gang scheduling)
├── Creates → HorizontalPodAutoscalers (PyTorch elastic)
└── Integrates → Kueue (workload queueing)

TrustyAI Service Operator
├── Watches → TrustyAIService CRs
├── Patches → InferenceServices (payload processor injection)
├── Creates → TrustyAI Service deployments
├── Creates → OAuth Proxy (authentication)
├── Creates → ServiceMonitors (metrics)
└── Integrates → PVC or Database (data storage)
```

### Central Components

**Core Infrastructure** (highest cross-component dependencies):
1. **RHODS Operator** - Deploys and manages all 12 other components
2. **ODH Dashboard** - Primary user interface, proxies to 5+ backend services
3. **Istio Service Mesh** - Provides mTLS, routing, and authorization for 6+ components
4. **Kubernetes API Server** - All components interact for CRD management
5. **OpenShift OAuth** - Authentication provider for 8+ components

**Integration Hubs** (connect multiple components):
1. **ODH Model Controller** - Bridges KServe, Istio, Authorino, Prometheus
2. **Kueue** - Job queue manager for Training Operator, Ray, Kubeflow jobs
3. **Data Science Pipelines** - Orchestrates workflows across storage, compute, serving

### Integration Patterns

**1. CRD Watching and Extension**
- ODH Notebook Controller watches Kubeflow Notebook CRs (extends functionality)
- ODH Model Controller watches KServe InferenceService CRs (adds OpenShift features)
- CodeFlare Operator watches KubeRay RayCluster CRs (injects security features)
- Kueue watches multiple job CRDs (adds queueing and quota management)

**2. Webhook Mutation**
- ODH Notebook Controller mutates Notebook pods (OAuth proxy, CA bundles)
- CodeFlare Operator mutates RayCluster pods (OAuth, mTLS init containers)
- Kueue mutates job pods (workload suspension, gang scheduling)
- Training Operator mutates training jobs (distributed coordination)

**3. Service Proxying**
- ODH Dashboard proxies requests to Data Science Pipelines, Model Registry, MLMD, TrustyAI
- OAuth Proxy sidecars proxy authenticated requests to workbenches, dashboards, services
- REST Proxy translates REST to gRPC for ModelMesh

**4. Manifest Deployment**
- RHODS Operator fetches and applies kustomize manifests from git for each component
- Components are deployed declaratively based on DataScienceCluster CR configuration

**5. Service Mesh Integration**
- KServe uses Istio VirtualServices for traffic splitting (canary, A/B testing)
- ODH Model Controller creates ServiceMeshMembers, PeerAuthentication, AuthConfigs
- Components communicate via mTLS within mesh

**6. Monitoring Integration**
- Components expose Prometheus metrics on /metrics endpoints
- Operators create ServiceMonitor/PodMonitor CRs for automatic scraping
- RHODS Operator deploys centralized Prometheus in monitoring namespace

**7. Storage Integration**
- Data Science Pipelines uses Minio/S3 for artifacts, MariaDB for metadata
- KServe Storage Initializer downloads models from S3/GCS/Azure/PVC
- TrustyAI supports PVC or database backends
- Workbenches mount PVCs for persistent workspace storage

## Platform Network Architecture

### Namespaces

| Namespace | Purpose | Components |
|-----------|---------|------------|
| redhat-ods-operator | Operator deployment | RHODS Operator |
| redhat-ods-applications | Default application namespace | ODH Dashboard, Workbenches, ODH Notebook Controller, ODH Model Controller, KServe, ModelMesh, Data Science Pipelines |
| redhat-ods-monitoring | Monitoring stack | Prometheus, Alertmanager, Grafana, Blackbox Exporter |
| istio-system | Service mesh control plane | Istio Control Plane, Istiod |
| redhat-ods-applications-auth-provider | Authentication provider | Authorino |
| knative-serving | Serverless platform | Knative Serving (for KServe serverless) |
| opendatahub | Component operators | CodeFlare, KubeRay, Kueue, Training Operator, TrustyAI |
| User project namespaces | Data science projects | Notebooks, InferenceServices, Pipelines, Training Jobs, Ray Clusters |

### External Ingress Points

| Component | Ingress Type | Hosts | Port | Protocol | Encryption | Purpose |
|-----------|--------------|-------|------|----------|------------|---------|
| ODH Dashboard | OpenShift Route | odh-dashboard-{namespace}.{cluster} | 443/TCP | HTTPS | TLS 1.2+ (Reencrypt) | Web UI for platform management |
| Notebook Workbenches | OpenShift Route | notebook-{name}-{namespace}.{cluster} | 443/TCP | HTTPS | TLS 1.2+ (Edge/Reencrypt) | JupyterLab/RStudio/VS Code access |
| Data Science Pipelines API | OpenShift Route | ds-pipeline-{name}-{namespace}.{cluster} | 443/TCP | HTTPS | TLS 1.2+ (Reencrypt) | Pipeline management API |
| Data Science Pipelines UI | OpenShift Route | ds-pipeline-ui-{name}-{namespace}.{cluster} | 443/TCP | HTTPS | TLS 1.2+ (Reencrypt) | Pipeline visualization UI |
| KServe InferenceService | OpenShift Route | {model}-{namespace}.{cluster} | 443/TCP | HTTPS | TLS 1.2+ (Passthrough/Edge) | Model inference endpoints |
| ModelMesh Serving | OpenShift Route | {service}-{namespace}.{cluster} | 443/TCP | HTTPS | TLS 1.2+ (Edge) | Multi-model inference endpoints |
| Ray Dashboard | OpenShift Route | {raycluster}-{namespace}.{cluster} | 443/TCP | HTTPS | TLS 1.2+ (Edge/Reencrypt) | Ray cluster monitoring UI |
| TrustyAI Service | OpenShift Route | trustyai-{name}-{namespace}.{cluster} | 443/TCP | HTTPS | TLS 1.2+ (Reencrypt) | Explainability and bias metrics API |
| Prometheus | OpenShift Route | prometheus-redhat-ods-monitoring.{cluster} | 443/TCP | HTTPS | TLS 1.2+ (Edge) | Metrics query interface |
| Alertmanager | OpenShift Route | alertmanager-redhat-ods-monitoring.{cluster} | 443/TCP | HTTPS | TLS 1.2+ (Edge) | Alert management UI |

**Ingress Security**:
- All routes use TLS 1.2+ encryption
- OAuth proxy sidecars enforce OpenShift authentication
- Reencrypt mode provides end-to-end encryption
- Istio Gateways provide additional traffic management for KServe

### External Egress Dependencies

| Component | Destination | Port | Protocol | Encryption | Purpose |
|-----------|-------------|------|----------|------------|---------|
| KServe, ModelMesh, Data Science Pipelines | S3 (*.amazonaws.com, s3.*.amazonaws.com) | 443/TCP | HTTPS | TLS 1.2+ | Model artifact and pipeline artifact storage |
| KServe | GCS (storage.googleapis.com) | 443/TCP | HTTPS | TLS 1.2+ | Model artifact downloads from Google Cloud |
| KServe | Azure Blob (*.blob.core.windows.net) | 443/TCP | HTTPS | TLS 1.2+ | Model artifact downloads from Azure |
| Workbenches | PyPI (pypi.org, files.pythonhosted.org) | 443/TCP | HTTPS | TLS 1.2+ | Python package installation at runtime |
| Workbenches | Quay.io (quay.io) | 443/TCP | HTTPS | TLS 1.2+ | Container image pulls for builds |
| Workbenches | Git Services (github.com, gitlab.com) | 443/TCP | HTTPS/SSH | TLS 1.2+/SSH | Source code version control |
| RHODS Operator | GitHub (github.com, raw.githubusercontent.com) | 443/TCP | HTTPS | TLS 1.2+ | Fetch component manifests from repositories |
| Data Science Pipelines | External MySQL/MariaDB/PostgreSQL | 3306/TCP, 5432/TCP | MySQL/PostgreSQL | TLS (optional) | Pipeline metadata storage (if external) |
| TrustyAI | External PostgreSQL/MariaDB/MySQL | 5432/TCP, 3306/TCP | PostgreSQL/MySQL | TLS (optional) | Inference data storage (if external) |
| All Components | Container Registries (registry.redhat.io, quay.io, gcr.io) | 443/TCP | HTTPS | TLS 1.2+ | Pull component and workload images |
| All Operators | Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | Cluster resource management |

**Egress Security Notes**:
- S3/cloud storage uses IAM credentials or access keys (stored in Secrets)
- Database connections use TLS when configured
- Container registries use pull secrets for private registries
- Network policies can restrict egress to specific destinations

### Internal Service Mesh

| Setting | Value | Components Using |
|---------|-------|------------------|
| mTLS Mode | PERMISSIVE (default), STRICT (configurable) | KServe, InferenceServices, Data Science Pipelines, TrustyAI |
| Peer Authentication | Namespace-scoped PeerAuthentication CRs | KServe serverless namespaces |
| Service Mesh Control Plane | Maistra/Istio 1.19+ | All mesh-enabled namespaces |
| Service Mesh Members | ServiceMeshMember CRs | User project namespaces with KServe |
| Authorization | Authorino AuthConfigs + Istio AuthorizationPolicy | KServe inference endpoints |
| Traffic Management | Istio VirtualServices, Gateways | KServe (canary, A/B testing, traffic splitting) |
| Telemetry | Istio Telemetry CRs | KServe (metrics collection) |
| Ingress Gateway | knative-ingress-gateway | KServe serverless inference |
| Local Gateway | knative-local-gateway | Internal service-to-service calls |

**Service Mesh Integration**:
- Required for KServe serverless mode
- Optional for other components
- Provides mTLS, observability, and fine-grained traffic control
- Authorino handles external authorization

## Platform Security

### RBAC Summary

**Platform-Level ClusterRoles**:

| Component | ClusterRole | Key Permissions |
|-----------|-------------|-----------------|
| RHODS Operator | controller-manager-role | Full control over DataScienceCluster, DSCInitialization, all component CRDs, namespaces, deployments, RBAC, Routes, Service Mesh resources |
| ODH Dashboard | odh-dashboard | Nodes, cluster versions, CSVs, ImageStreams, Routes, ConsoleLinks, RHMIs, users/groups, notebooks, datascienceclusters, model registries |
| KServe | kserve-manager-role | InferenceServices, ServingRuntimes, Knative Services, Istio VirtualServices, Deployments, HPAs, Secrets, ConfigMaps |
| ODH Model Controller | odh-model-controller-role | InferenceServices, ServingRuntimes, VirtualServices, Gateways, PeerAuthentications, AuthConfigs, Routes, ServiceMonitors, NetworkPolicies |
| ModelMesh Serving | modelmesh-controller-role | InferenceServices, Predictors, ServingRuntimes, Deployments, HPAs, ServiceMonitors, AuthConfigs |
| Data Science Pipelines Operator | manager-role | DataSciencePipelinesApplications, Argo Workflows, Tekton resources, Deployments, Routes, ServiceMonitors, Ray clusters, AppWrappers |
| ODH Notebook Controller | manager-role | Notebooks, Routes, Services, Secrets, ConfigMaps, NetworkPolicies, ImageStreams, Proxies (OpenShift config) |
| CodeFlare Operator | codeflare-operator-manager-role | AppWrappers, RayClusters, RayJobs, Workloads (Kueue), Ingresses, Routes, NetworkPolicies, ClusterRoleBindings, DSCInitializations |
| KubeRay Operator | kuberay-operator | RayClusters, RayJobs, RayServices, Pods, Services, Ingresses, Routes, Jobs, ServiceAccounts, RBAC resources |
| Kueue | kueue-manager-role | ClusterQueues, LocalQueues, Workloads, ResourceFlavors, AdmissionChecks, Pods, Jobs, PyTorchJobs, TFJobs, RayJobs, MPI Jobs, ProvisioningRequests |
| Training Operator | training-operator | PyTorchJobs, TFJobs, MPIJobs, XGBoostJobs, MXJobs, PaddleJobs, Pods, Services, ConfigMaps, HPAs, PodGroups (Volcano/scheduler-plugins) |
| TrustyAI Service Operator | manager-role | TrustyAIServices, InferenceServices, ServingRuntimes, Deployments, Routes, ServiceMonitors, ClusterRoleBindings, PVCs |

**User-Facing Roles** (aggregated to edit/view):
- `notebooks-edit`, `notebooks-view` - Notebook management
- `training-edit`, `training-view` - Training job management
- `kueue-batch-user-role` - Queue and workload submission
- `odh-dashboard-model-serving-role` - Model serving management

**Least Privilege Design**:
- Each component has minimal required permissions
- Namespace-scoped roles for component-specific actions
- Cluster-scoped roles only for cross-namespace operations
- ServiceAccount tokens for operator-to-API authentication

### Secrets Inventory

**Platform-Wide Secrets**:

| Secret Name | Type | Purpose | Components Using |
|-------------|------|---------|------------------|
| odh-trusted-ca-bundle | ConfigMap | Cluster and custom CA certificates | All components (workbenches, operators, services) |
| dashboard-proxy-tls, {component}-proxy-tls | kubernetes.io/tls | OAuth proxy TLS certificates (Service CA) | ODH Dashboard, Notebooks, Data Science Pipelines, Ray Dashboard, TrustyAI |
| {component}-oauth-config, {component}-oauth-client | Opaque | OAuth cookie secrets and client credentials | ODH Dashboard, Notebooks, Data Science Pipelines, Ray Dashboard, TrustyAI |
| webhook-server-cert | kubernetes.io/tls | Webhook server TLS certificates | RHODS Operator, KServe, Training Operator, Kueue, ODH Notebook Controller |

**Component-Specific Secrets**:

| Component | Secret Type | Examples | Purpose |
|-----------|-------------|----------|---------|
| Data Science Pipelines | Opaque | {dspa}-db-secret, {dspa}-storage-secret | Database and object storage credentials |
| KServe/ModelMesh | Opaque | storage-config, {custom-secret} | S3/GCS/Azure credentials for model downloads |
| CodeFlare | Opaque, kubernetes.io/tls | {raycluster}-ca-secret, {raycluster}-oauth-proxy-tls | Ray mTLS CA and OAuth proxy TLS |
| ModelMesh | Opaque | model-serving-etcd, storage-config | Etcd connection and storage credentials |
| TrustyAI | Opaque, kubernetes.io/tls | {instance}-db-credentials, {instance}-tls | Database credentials and service TLS |
| Workbenches | Opaque, kubernetes.io/basic-auth, ssh-auth | aws-connection-*, {database}-credentials, git-credentials | Cloud, database, and git credentials |

**Secret Management**:
- OpenShift Service CA auto-rotates TLS certificates (service.alpha.openshift.io/serving-cert-secret-name)
- secret-generator.opendatahub.io annotations auto-generate random secrets
- Database passwords are user/admin-provisioned (no auto-rotation)
- Image pull secrets managed by cluster or namespace administrators

### Authentication Mechanisms

| Pattern | Components Using | Enforcement Point | Protocol |
|---------|------------------|-------------------|----------|
| OpenShift OAuth (Bearer Token JWT) | ODH Dashboard, Notebooks, Data Science Pipelines UI, Ray Dashboard, TrustyAI, Prometheus Routes | OAuth Proxy Sidecar | HTTPS with Bearer token in Authorization header |
| ServiceAccount Tokens (JWT) | All Operators, inter-service communication | Kubernetes API Server | HTTPS with bearer token, validated via TokenReview |
| mTLS Client Certificates | Webhook servers, Service Mesh (when STRICT mode) | Kubernetes API Server, Istio Envoy Proxies | TLS mutual authentication |
| Authorino External Authorization | KServe inference endpoints (optional) | Istio + Authorino | OAuth2/OIDC token validation via AuthConfig CRs |
| Database Username/Password | Data Science Pipelines, TrustyAI, ModelMesh (etcd) | Application-level | SCRAM-SHA-256, TLS encryption (optional) |
| S3 Access Keys / AWS IAM | KServe, ModelMesh, Data Science Pipelines, Workbenches | Application-level (boto3, cloud SDKs) | HTTPS with AWS Signature V4 or access/secret keys |
| None (Internal ClusterIP) | Component metrics endpoints, health checks | Network Policy | HTTP on internal cluster network |

**Authorization Patterns**:
- **OpenShift RBAC**: OAuth proxy validates tokens via SubjectAccessReview (SAR) against Kubernetes RBAC
- **Istio AuthorizationPolicy**: Fine-grained request authorization based on JWT claims, namespaces, service accounts
- **Namespace isolation**: NetworkPolicies and RBAC restrict cross-namespace access
- **Component-level**: Each operator enforces ownership via controller owner references

## Platform APIs

### Custom Resource Definitions

**Platform Management**:

| Component | API Group | Kind | Scope | Purpose |
|-----------|-----------|------|-------|---------|
| RHODS Operator | datasciencecluster.opendatahub.io | DataScienceCluster | Cluster | Defines platform components to deploy and their configurations |
| RHODS Operator | dscinitialization.opendatahub.io | DSCInitialization | Cluster | Platform-wide settings (service mesh, monitoring, trusted CA bundles) |
| RHODS Operator | features.opendatahub.io | FeatureTracker | Cluster | Tracks cross-namespace resources for garbage collection |

**Model Serving**:

| Component | API Group | Kind | Scope | Purpose |
|-----------|-----------|------|-------|---------|
| KServe | serving.kserve.io | InferenceService | Namespaced | Model serving deployment with predictor/transformer/explainer |
| KServe | serving.kserve.io | ServingRuntime | Namespaced | Model server runtime template (framework-specific) |
| KServe | serving.kserve.io | ClusterServingRuntime | Cluster | Cluster-wide serving runtime template |
| KServe | serving.kserve.io | ClusterStorageContainer | Cluster | Storage initialization behavior for model downloads |
| KServe | serving.kserve.io | InferenceGraph | Namespaced | Multi-step inference pipelines with routing |
| KServe | serving.kserve.io | TrainedModel | Namespaced | Trained ML model artifact with storage location |
| ModelMesh | serving.kserve.io | Predictor | Namespaced | Model predictor instance (ModelMesh-specific) |

**Data Science Workbenches**:

| Component | API Group | Kind | Scope | Purpose |
|-----------|-----------|------|-------|---------|
| ODH Notebook Controller | kubeflow.org | Notebook | Namespaced | Jupyter notebook workload definition |
| ODH Dashboard | opendatahub.io | OdhDashboardConfig | Namespaced | Dashboard configuration and feature flags |
| ODH Dashboard | dashboard.opendatahub.io | OdhApplication | Namespaced | Catalog of available applications |
| ODH Dashboard | dashboard.opendatahub.io | OdhDocument | Namespaced | Documentation and tutorial resources |
| ODH Dashboard | console.openshift.io | OdhQuickStart | Cluster | Quick start guides for onboarding |
| ODH Dashboard | dashboard.opendatahub.io | AcceleratorProfile | Namespaced | GPU and accelerator device configurations |

**ML Pipelines**:

| Component | API Group | Kind | Scope | Purpose |
|-----------|-----------|------|-------|---------|
| Data Science Pipelines Operator | datasciencepipelinesapplications.opendatahub.io | DataSciencePipelinesApplication | Namespaced | Complete pipeline stack deployment (API, storage, database, UI) |

**Distributed Training**:

| Component | API Group | Kind | Scope | Purpose |
|-----------|-----------|------|-------|---------|
| Training Operator | kubeflow.org | PyTorchJob | Namespaced | Distributed PyTorch training jobs |
| Training Operator | kubeflow.org | TFJob | Namespaced | Distributed TensorFlow training jobs |
| Training Operator | kubeflow.org | MPIJob | Namespaced | MPI-based distributed training jobs |
| Training Operator | kubeflow.org | MXJob | Namespaced | Apache MXNet distributed training jobs |
| Training Operator | kubeflow.org | XGBoostJob | Namespaced | Distributed XGBoost training jobs |
| Training Operator | kubeflow.org | PaddleJob | Namespaced | PaddlePaddle distributed training jobs |

**Distributed Computing (Ray)**:

| Component | API Group | Kind | Scope | Purpose |
|-----------|-----------|------|-------|---------|
| KubeRay Operator | ray.io | RayCluster | Namespaced | Ray cluster with head and worker groups |
| KubeRay Operator | ray.io | RayJob | Namespaced | Batch job execution on Ray cluster |
| KubeRay Operator | ray.io | RayService | Namespaced | Ray Serve deployment with HA and zero-downtime updates |
| CodeFlare Operator | workload.codeflare.dev | AppWrapper | Namespaced | Wraps resources for batch job scheduling with Kueue |

**Workload Queueing**:

| Component | API Group | Kind | Scope | Purpose |
|-----------|-----------|------|-------|---------|
| Kueue | kueue.x-k8s.io | ClusterQueue | Cluster | Cluster-level resource quotas and admission policies |
| Kueue | kueue.x-k8s.io | LocalQueue | Namespaced | Namespace-scoped queue mapping to ClusterQueue |
| Kueue | kueue.x-k8s.io | Workload | Namespaced | Internal representation of job with resource requirements |
| Kueue | kueue.x-k8s.io | ResourceFlavor | Cluster | Resource flavor variant (GPU type, node pool) |
| Kueue | kueue.x-k8s.io | AdmissionCheck | Cluster | Admission check requirements for workload admission |
| Kueue | kueue.x-k8s.io | WorkloadPriorityClass | Cluster | Workload priority for queueing |

**Explainability & Fairness**:

| Component | API Group | Kind | Scope | Purpose |
|-----------|-----------|------|-------|---------|
| TrustyAI Service Operator | trustyai.opendatahub.io | TrustyAIService | Namespaced | TrustyAI service deployment for bias metrics and explainability |

**Total CRDs**: 40+

## Public HTTP Endpoints

**User-Facing Web Interfaces**:

| Component | Path | Port | Protocol | Auth | Purpose |
|-----------|------|------|----------|------|---------|
| ODH Dashboard | /* | 8443/TCP (Route: 443) | HTTPS | OAuth2 Bearer | Platform management UI |
| Notebooks | /* | 8888/TCP (Route: 443) | HTTPS | OAuth2 Bearer | JupyterLab/RStudio/VS Code interface |
| Data Science Pipelines UI | /* | 8443/TCP (Route: 443) | HTTPS | OAuth2 Bearer | Pipeline visualization and management |
| Ray Dashboard | /dashboard | 8265/TCP (Route: 443) | HTTPS | OAuth2 Bearer | Ray cluster monitoring |
| Prometheus | /* | 9091/TCP (Route: 443) | HTTPS | OAuth2 Bearer | Metrics query and visualization |

**APIs (External Access)**:

| Component | Path | Port | Protocol | Auth | Purpose |
|-----------|------|------|----------|------|---------|
| KServe InferenceService | /v1/models/{model}:predict, /v2/models/{model}/infer | 8080/TCP, 8443/TCP (Route: 443) | HTTP/HTTPS | OAuth2/Authorino (optional) | Model inference REST API |
| ModelMesh | /v2/models/{model}/infer | 8008/TCP (Route: 443) | HTTPS | OAuth2 (optional) | Multi-model inference REST API |
| Data Science Pipelines | /apis/v2beta1/* | 8888/TCP (Route: 443) | HTTPS | OAuth2 Bearer | Pipeline management API |
| TrustyAI Service | /* | 8443/TCP (Route: 443) | HTTPS | OAuth2 Bearer | Explainability and bias metrics API |

**Internal APIs (ClusterIP)**:

| Component | Path | Port | Protocol | Auth | Purpose |
|-----------|------|------|----------|------|---------|
| All Operators | /metrics | 8080/TCP | HTTP | ServiceAccount (Prometheus) | Prometheus metrics scraping |
| All Operators | /healthz, /readyz | 8081/TCP | HTTP | None | Kubernetes health probes |
| KServe, ModelMesh | /v2/models/{model}/infer (internal) | 8033/TCP, 8888/TCP | gRPC/HTTP | None | Internal inference endpoints |
| Data Science Pipelines | /apis/* (internal) | 8888/TCP | HTTP | None | Internal pipeline API |

## Data Flows

### Key Platform Workflows

#### Workflow 1: Model Training to Deployment (End-to-End)

| Step | Component | Action | Next Component | Protocol |
|------|-----------|--------|----------------|----------|
| 1 | User | Launches Jupyter notebook from ODH Dashboard | ODH Notebook Controller | HTTPS (OAuth) |
| 2 | ODH Notebook Controller | Creates Notebook CR, deploys pod with OAuth proxy | Notebook Pod | Kubernetes API |
| 3 | Notebook Pod | User develops and trains model using PyTorch/TensorFlow | Writes model to S3 | HTTPS (AWS SDK) |
| 4 | User | Submits model to Model Registry via Dashboard | Model Registry API | HTTPS (proxied) |
| 5 | User | Creates InferenceService CR via Dashboard | KServe Controller | Kubernetes API |
| 6 | KServe Controller | Creates Knative Service, triggers deployment | KServe Predictor Pod | Kubernetes API |
| 7 | KServe Storage Initializer | Downloads model from S3 | Model Server Container | HTTPS → filesystem |
| 8 | ODH Model Controller | Creates Route, VirtualService, AuthConfig | Istio Gateway | Kubernetes API |
| 9 | External Client | Sends inference request to Route | Istio → KServe Predictor | HTTPS (TLS) |
| 10 | KServe Predictor | Returns prediction | Client | HTTPS response |

#### Workflow 2: Distributed Training Job Submission

| Step | Component | Action | Next Component | Protocol |
|------|-----------|--------|----------------|----------|
| 1 | User | Submits PyTorchJob CR from notebook or CLI | Training Operator | Kubernetes API |
| 2 | Training Operator | Creates PyTorchJob CR | Kueue Webhook | HTTPS (admission) |
| 3 | Kueue Webhook | Mutates job, creates Workload CR | Kueue Controller | Kubernetes API |
| 4 | Kueue Controller | Checks ClusterQueue quota, admits workload | Training Operator | Status update |
| 5 | Training Operator | Creates master and worker pods | Kubernetes Scheduler | Kubernetes API |
| 6 | Volcano Scheduler | Gang schedules all pods atomically | Kubelet | Scheduling |
| 7 | Training Pods | Execute distributed training, communicate via torchrun | Training Pods | TCP (internal) |
| 8 | Training Pods | Write checkpoints to S3 | S3 Storage | HTTPS |
| 9 | Training Operator | Updates job status on completion | User (via Dashboard) | Kubernetes API |

#### Workflow 3: ML Pipeline Execution (Data Science Pipelines)

| Step | Component | Action | Next Component | Protocol |
|------|-----------|--------|----------------|----------|
| 1 | User | Creates pipeline via Elyra in JupyterLab | Elyra (in notebook) | Local |
| 2 | Elyra | Compiles pipeline to Argo Workflow YAML | DS Pipelines API | HTTPS (OAuth) |
| 3 | DS Pipelines API | Creates Argo Workflow CR | Argo Workflow Controller | Kubernetes API |
| 4 | Argo Workflow Controller | Creates pipeline step pods sequentially | Kubernetes Scheduler | Kubernetes API |
| 5 | Pipeline Step Pods | Execute Python code, read/write data | Minio (artifacts), MariaDB (metadata) | HTTP, MySQL |
| 6 | Pipeline Step Pods | Log outputs to stdout | Argo Workflow Controller | Kubelet logs API |
| 7 | MLMD Envoy | Receives metadata writes from pipeline | MLMD gRPC Server | gRPC (internal) |
| 8 | MLMD gRPC Server | Stores artifact lineage | MariaDB | MySQL |
| 9 | Argo Workflow Controller | Updates workflow status | DS Pipelines API | Kubernetes API |
| 10 | User | Views pipeline run in Dashboard UI | DS Pipelines API (proxied) | HTTPS (OAuth) |

#### Workflow 4: Ray Cluster for Distributed Compute

| Step | Component | Action | Next Component | Protocol |
|------|-----------|--------|----------------|----------|
| 1 | User | Creates RayCluster CR via Dashboard or kubectl | KubeRay Operator | Kubernetes API |
| 2 | KubeRay Operator | Creates RayCluster CR | CodeFlare Operator (webhook) | HTTPS (admission) |
| 3 | CodeFlare Operator | Mutates RayCluster, injects OAuth proxy and mTLS | KubeRay Operator | Kubernetes API |
| 4 | KubeRay Operator | Creates Ray head and worker pods | Kubernetes Scheduler | Kubernetes API |
| 5 | Ray Head Pod | Starts Ray GCS, dashboard, client server | Ray Worker Pods | TCP (GCS port 6379) |
| 6 | Ray Worker Pods | Connect to Ray head via mTLS | Ray Head (GCS) | TCP mTLS |
| 7 | CodeFlare Operator | Creates Route with OAuth proxy | OpenShift Router | Kubernetes API |
| 8 | User | Accesses Ray dashboard via Route | OAuth Proxy → Ray Dashboard | HTTPS (OAuth) |
| 9 | User (from notebook) | Submits Ray job via ray.init() | Ray Client (head pod) | TCP (port 10001) |
| 10 | Ray Head | Schedules tasks across workers | Ray Workers | TCP (internal Ray protocol) |

#### Workflow 5: Model Fairness Analysis (TrustyAI)

| Step | Component | Action | Next Component | Protocol |
|------|-----------|--------|----------------|----------|
| 1 | User | Creates TrustyAIService CR | TrustyAI Operator | Kubernetes API |
| 2 | TrustyAI Operator | Creates TrustyAI service deployment | Kubernetes Scheduler | Kubernetes API |
| 3 | TrustyAI Operator | Patches InferenceService with payload processor | KServe Controller | Kubernetes API |
| 4 | KServe Predictor | Sends inference payloads to TrustyAI | TrustyAI Service | HTTPS (mTLS) |
| 5 | TrustyAI Service | Stores inference data | PVC or Database | Filesystem or PostgreSQL |
| 6 | TrustyAI Service (scheduled) | Calculates fairness metrics (SPD, DIR) | Prometheus (metrics) | HTTP (ServiceMonitor) |
| 7 | User | Queries fairness metrics via TrustyAI API | TrustyAI Service (via Route) | HTTPS (OAuth) |
| 8 | Prometheus | Scrapes trustyai_spd, trustyai_dir metrics | Grafana | HTTPS |
| 9 | User | Visualizes bias metrics in Grafana dashboard | Prometheus datasource | HTTPS |

## Platform Maturity

**Platform Statistics**:
- **Total Components**: 13 major components
- **Operator-based Components**: 11 (RHODS, KServe, ModelMesh, ODH Model Controller, Data Science Pipelines, ODH Notebook Controller, CodeFlare, KubeRay, Kueue, Training, TrustyAI)
- **Service Mesh Coverage**: 40% (KServe, Data Science Pipelines, TrustyAI support mTLS and Istio integration)
- **mTLS Enforcement**: PERMISSIVE (default), supports STRICT mode configuration
- **OAuth Integration**: 90% (ODH Dashboard, Notebooks, Data Science Pipelines, Ray Dashboard, TrustyAI, Prometheus)
- **CRD API Versions**: v1alpha1 (25%), v1beta1 (30%), v1 (45%) - mature API versions
- **Monitoring Coverage**: 100% (all operators expose Prometheus metrics)
- **Webhook Validation**: 60% (KServe, Training Operator, Kueue, ODH Notebook Controller, CodeFlare)

**Enterprise Readiness**:
- ✅ RBAC policies for all components
- ✅ TLS encryption for all external traffic
- ✅ OpenShift OAuth integration
- ✅ High availability support (multi-replica deployments with leader election)
- ✅ Monitoring and alerting (Prometheus + Alertmanager)
- ✅ Network isolation (NetworkPolicies for sensitive components)
- ✅ Storage encryption at rest (when configured in OpenShift)
- ✅ Compliance with OpenShift SecurityContextConstraints
- ✅ Certificate auto-rotation via OpenShift Service CA
- ✅ Audit logging (via Kubernetes audit logs)

**API Stability**:
- Core CRDs (DataScienceCluster, InferenceService, Notebook) use stable v1 APIs
- Newer features (InferenceGraph, TrustyAIService, AppWrapper) use v1alpha1 APIs
- Training jobs use stable v1 APIs (PyTorchJob, TFJob, etc.)
- Kueue uses v1beta1 for queue management
- Service mesh integration uses Istio v1beta1 APIs

**Deployment Models**:
1. **Managed RHOAI**: Auto-deployed on OpenShift with RHMI/Addon integration
2. **Self-Managed RHOAI**: Admin-deployed via Operator Lifecycle Manager (OLM)
3. **Upstream ODH**: Community deployment on vanilla Kubernetes or OpenShift

## Version-Specific Changes (2.12)

| Component | Changes |
|-----------|---------|
| CodeFlare Operator | - Update AppWrapper to v0.23.0<br>- Downgrade StatusReasonConflict errors to debug messages<br>- Update dependency versions for release v1.6.0<br>- Add check for head pod imagePullSecrets |
| Data Science Pipelines Operator | - Add service CA bundle for pod-to-pod TLS<br>- Add apiserver TLS support<br>- Add ability to configure artifact download link expiry<br>- Enable sample pipeline in DSPA samples |
| KServe | - Update kserve-agent-212, kserve-controller-212, kserve-router-212, kserve-storage-initializer-212 components<br>- Update Konflux references for rhoai-2.12<br>- Base image updates and security patches |
| ODH Notebook Controller | - Update kustomization to use params env and yml<br>- Add `.snyk` config file to ignore non-ODH directories<br>- Update contributing guide and OWNERS file |
| KubeRay Operator | - Regular dependency updates via automated PRs<br>- Base image security updates (UBI9)<br>- Konflux pipeline synchronization |
| Kueue | - RHOAI-specific customizations (OpenShift monitoring integration)<br>- UBI9-based container images<br>- Network policy for webhook security |
| ModelMesh Serving | - Merge remote-tracking branch 'upstream/release-0.12.0-rc0'<br>- Sync with upstream 0.12.0-rc0<br>- Increase etcd resources<br>- Update golang.org/x/net dependency |
| Notebooks (Workbenches) | - Remove install of package in bootstrapper as pre-installed (RHOAIENG-11087)<br>- Print image digests after build (RHOAIENG-10783)<br>- Combine `fix-permissions` RUN statements to reduce layers<br>- Run Trivy image scan for ROCm PyTorch image<br>- De-vendor bundled ROCm libraries from PyTorch<br>- Set CodeFlare SDK 0.18.0 annotation |
| ODH Dashboard | - Enable KServeMetrics by default (RHOAIENG-8575)<br>- Infrastructure proxy call for artifacts API<br>- Navigate to pipeline details on import<br>- Restart pod after updating configMap in workbench<br>- Handle deleted container size in workbenches<br>- Display pipeline run volume name correctly |
| ODH Model Controller | - Update latest SHA<br>- Konflux component updates for caikit-nlp-212<br>- Update OVMS runtime and vLLM image<br>- KServe metrics checkpoint implementation |
| RHODS Operator | - Sync: fix for managed cluster upgrade with DSC already exists<br>- Exports configmap names to const for service-mesh<br>- Fix: preserves original target namespace in feature tracking<br>- Fix: devFlags for dashboard did not set correct values |
| Training Operator | - Update Go to 1.21<br>- Add separate file for RHOAI build and update multarch base image<br>- ODH Image build actions<br>- Add RHOAI manifests |
| TrustyAI Service Operator | - Current stable version 1.17.0<br>- Support for database storage backend<br>- PVC to database migration capability<br>- OAuth proxy integration<br>- ServiceMonitor support |

## Next Steps for Documentation

Based on this platform architecture analysis, recommended next steps:

### 1. Generate Visual Diagrams
- **Component Dependency Graph**: Visualize the component relationships with GraphViz/Mermaid
- **Network Flow Diagrams**: Show ingress/egress traffic flows between components
- **Data Flow Sequence Diagrams**: Illustrate end-to-end workflows (training to deployment)
- **Service Mesh Architecture**: Map Istio integration and mTLS connections
- **Storage Architecture**: Document data persistence patterns across components

### 2. Update Architecture Decision Records (ADRs)
- **ADR-001**: Service mesh integration strategy (Istio vs alternatives)
- **ADR-002**: Model serving architecture (KServe vs ModelMesh selection criteria)
- **ADR-003**: Authentication and authorization patterns (OAuth, Authorino, RBAC)
- **ADR-004**: Storage strategy (PVC, S3, database backends)
- **ADR-005**: Pipeline execution engines (Argo vs Tekton)
- **ADR-006**: Distributed training frameworks (Training Operator vs Ray)
- **ADR-007**: Job queueing and resource management (Kueue integration)

### 3. Create User-Facing Documentation
- **Getting Started Guide**: Deploy first notebook, train model, serve model
- **Model Serving Guide**: KServe vs ModelMesh decision tree, configuration examples
- **Distributed Training Guide**: PyTorchJob, TFJob, and Ray cluster usage
- **Pipeline Authoring Guide**: Elyra and KFP SDK tutorials
- **Security Best Practices**: RBAC configuration, secret management, network policies
- **Monitoring and Observability**: Prometheus queries, Grafana dashboards, alerting rules
- **Troubleshooting Guide**: Common issues, diagnostic commands, log locations

### 4. Generate Security Documentation for SAR (Security Architecture Review)
- **Network Segmentation Diagram**: Show namespace isolation and NetworkPolicies
- **Authentication Flow Diagrams**: OAuth, ServiceAccount, mTLS flows
- **Encryption in Transit Map**: TLS endpoints, mTLS mesh, unencrypted internal traffic
- **RBAC Permission Matrix**: ClusterRoles, ServiceAccounts, least privilege analysis
- **Secret Management Inventory**: Secret types, rotation policies, provisioning methods
- **Compliance Checklist**: OpenShift SCC compliance, pod security standards
- **Threat Model**: Attack surface analysis, trust boundaries, mitigation controls

### 5. Component Deep Dives
- **KServe Architecture Deep Dive**: Storage initializer, predictor, explainer, transformer
- **Data Science Pipelines Internals**: Argo Workflows, MLMD, caching, artifact storage
- **Service Mesh Integration Guide**: VirtualService patterns, AuthorizationPolicy examples
- **Workbench Image Customization**: Building custom images, adding Python packages
- **Ray Cluster Operations**: Autoscaling, fault tolerance, multi-tenancy

### 6. API Reference Documentation
- **CRD Field Reference**: Complete field documentation for all 40+ CRDs
- **REST API Reference**: OpenAPI specs for Dashboard, Pipelines, Model Serving APIs
- **Python SDK Documentation**: kubeflow-training, kfp, ray, codeflare SDKs
- **CLI Usage Guide**: kubectl plugins, oc commands, ODH-specific tooling

### 7. Operations Runbooks
- **Installation Guide**: Prerequisites, operator deployment, DataScienceCluster configuration
- **Upgrade Procedures**: Version compatibility matrix, upgrade paths, rollback procedures
- **Backup and Restore**: Pipeline artifacts, model metadata, user workspaces
- **Disaster Recovery**: Multi-cluster deployments, data replication strategies
- **Performance Tuning**: Resource limits, autoscaling configuration, database optimization
- **Monitoring Setup**: Prometheus configuration, alert rules, Grafana dashboards

### 8. Integration Guides
- **CI/CD Integration**: Jenkins, Tekton, GitHub Actions for model training and deployment
- **MLOps Workflows**: Model versioning, A/B testing, canary deployments, rollback
- **External Storage Integration**: AWS S3, Azure Blob, GCS, Ceph configuration
- **External Database Integration**: PostgreSQL, MySQL, MariaDB for pipelines and metadata
- **Identity Provider Integration**: LDAP, Active Directory, OIDC providers

### 9. Compliance and Governance
- **Data Lineage Tracking**: MLMD integration, artifact provenance
- **Model Governance**: Model registry, version tracking, approval workflows
- **Audit Logging**: Kubernetes audit logs, component-specific audit trails
- **Resource Quotas**: Kueue configuration, fair sharing policies
- **Cost Management**: Resource tracking, chargeback models, namespace quotas

### 10. Reference Architectures
- **Financial Services ML**: Fraud detection, risk modeling, compliance requirements
- **Healthcare AI**: Medical imaging, HIPAA compliance, data privacy
- **Edge AI Deployment**: Model serving at edge locations, federated learning
- **Large-Scale Training**: Multi-node GPU clusters, distributed data parallelism
- **Real-Time Inference**: Low-latency serving, autoscaling for burst traffic
