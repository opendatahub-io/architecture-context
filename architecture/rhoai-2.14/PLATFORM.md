# Platform: Red Hat OpenShift AI 2.14

## Metadata
- **Distribution**: RHOAI (Red Hat OpenShift AI)
- **Version**: 2.14
- **Release Date**: 2024 Q4
- **Base Platform**: OpenShift Container Platform 4.12+
- **Components Analyzed**: 14
- **Analysis Date**: 2026-03-15

## Platform Overview

Red Hat OpenShift AI (RHOAI) 2.14 is a comprehensive enterprise platform for developing, training, serving, and monitoring machine learning models on OpenShift. The platform provides a complete end-to-end ML lifecycle management system, from interactive development environments (Jupyter notebooks, code-server, RStudio) through distributed training frameworks (PyTorch, TensorFlow, Ray, MPI) to production model serving (KServe, ModelMesh) with integrated monitoring and governance (TrustyAI, Model Registry).

The platform architecture follows a cloud-native, operator-based pattern where a central rhods-operator orchestrates the deployment and lifecycle of specialized component operators. Each component is designed to run on Kubernetes/OpenShift with OpenShift-specific enhancements including Routes for ingress, OAuth proxy for authentication, and Service Mesh (Istio) integration for secure service-to-service communication. The platform emphasizes security with RBAC-based access control, mTLS encryption, network policies for isolation, and compliance with OpenShift's restricted Security Context Constraints (SCC).

RHOAI 2.14 supports hybrid deployment modes ranging from simple single-model serving to large-scale distributed training workloads with job queuing (Kueue), gang scheduling (Volcano), and resource management. It integrates with external storage (S3, databases), external registries, and enterprise authentication systems while providing comprehensive observability through Prometheus metrics, OpenShift monitoring, and custom dashboards.

## Component Inventory

| Component | Type | Version | Purpose |
|-----------|------|---------|---------|
| rhods-operator | Operator | v1.6.0-826 | Central platform operator managing all component lifecycles |
| odh-dashboard | Web Application | v1.21.0-18 | Unified UI for managing notebooks, pipelines, and model serving |
| notebook-controller (Kubeflow) | Controller | v1.27.0-663 | Base Kubeflow notebook controller for StatefulSet management |
| odh-notebook-controller | Controller | v1.27.0-663 | OpenShift extensions for notebooks (OAuth, Routes, NetworkPolicies) |
| workbench-images (notebooks) | Container Images | 2024b/2024a | Pre-built Jupyter, code-server, RStudio environments with ML frameworks |
| data-science-pipelines-operator | Operator | 6b7b774 | Manages namespace-scoped DSP stacks for ML workflow orchestration |
| kserve | Operator + Runtime | 1fdf877e7 | Serverless and raw deployment model serving platform |
| modelmesh-serving | Operator | v1.27.0-261 | Multi-model serving with intelligent placement and routing |
| odh-model-controller | Controller | v1.27.0-483 | OpenShift/Service Mesh integration for KServe/ModelMesh |
| model-registry-operator | Operator | v-2160 | Deploys and manages Model Registry instances for ML model versioning |
| codeflare-operator | Operator | v1.9.0 | Ray cluster orchestration with OAuth, mTLS, and AppWrapper batch scheduling |
| kuberay | Operator | d490ea60 | Kubernetes operator for Ray distributed computing clusters |
| training-operator | Operator | 4b4e3bb4 | Distributed training for PyTorch, TensorFlow, MPI, XGBoost, MXNet, PaddlePaddle |
| kueue | Operator | v0.8.1 | Job queueing system with quota management and fair sharing |
| trustyai-service-operator | Operator | 1.17.0 | Model explainability, fairness monitoring, and bias detection |

## Component Relationships

### Dependency Graph

```
rhods-operator (Platform Orchestrator)
├─→ odh-dashboard
│   ├─→ notebook-controller (creates Notebook CRs)
│   ├─→ kserve (manages InferenceServices)
│   ├─→ data-science-pipelines-operator (manages DSPAs)
│   └─→ model-registry-operator (manages ModelRegistry CRs)
│
├─→ data-science-pipelines-operator
│   ├─→ Argo Workflows (workflow execution)
│   ├─→ MariaDB/MySQL (metadata storage)
│   ├─→ MinIO/S3 (artifact storage)
│   └─→ kserve (pipeline→model deployment)
│
├─→ kserve
│   ├─→ Knative Serving (serverless autoscaling)
│   ├─→ Istio (traffic management, mTLS)
│   ├─→ odh-model-controller (OpenShift integration)
│   └─→ model-registry (optional model metadata)
│
├─→ modelmesh-serving
│   ├─→ etcd (distributed coordination)
│   ├─→ KServe CRDs (ServingRuntime, InferenceService)
│   └─→ odh-model-controller (Route/mesh integration)
│
├─→ odh-model-controller
│   ├─→ kserve (watches InferenceServices)
│   ├─→ modelmesh-serving (watches Predictors)
│   ├─→ Authorino (creates AuthConfigs)
│   └─→ Istio (creates VirtualServices, Gateways)
│
├─→ notebook-controller + odh-notebook-controller
│   ├─→ workbench-images (container images)
│   ├─→ OpenShift OAuth (authentication)
│   └─→ OpenShift Routes (ingress)
│
├─→ codeflare-operator
│   ├─→ kuberay (Ray cluster management)
│   ├─→ kueue (AppWrapper scheduling)
│   └─→ OpenShift OAuth (Ray dashboard auth)
│
├─→ kuberay
│   └─→ Ray container images (head/worker pods)
│
├─→ training-operator
│   ├─→ kueue (optional job queueing)
│   └─→ Volcano (optional gang scheduling)
│
├─→ kueue
│   ├─→ training-operator jobs (PyTorchJob, TFJob, etc.)
│   ├─→ codeflare AppWrappers
│   └─→ kuberay (RayJob, RayCluster)
│
├─→ model-registry-operator
│   ├─→ PostgreSQL/MySQL (metadata storage)
│   ├─→ Authorino (authentication/authorization)
│   └─→ Istio (optional Gateway/VirtualService)
│
└─→ trustyai-service-operator
    ├─→ kserve (patches InferenceServices for monitoring)
    ├─→ modelmesh-serving (payload processor injection)
    └─→ PVC/Database (metrics storage)
```

### Central Components

Components with the most dependencies (core platform services):
1. **rhods-operator** - Orchestrates all component deployments
2. **odh-dashboard** - Primary user interface for all platform capabilities
3. **kserve** - Central model serving platform used by pipelines and manual deployments
4. **Istio Service Mesh** - Provides mTLS, routing, and security for serving workloads
5. **Kubernetes API Server** - All components interact with K8s API for resource management
6. **OpenShift OAuth** - Authentication for dashboard, notebooks, Ray dashboards
7. **Prometheus** - Metrics collection from all platform components

### Integration Patterns

**Common Patterns Across Components**:
- **CRD-based Configuration**: All operators use Custom Resources for declarative management
- **ServiceAccount RBAC**: All components authenticate to K8s API via ServiceAccount tokens
- **Prometheus Metrics**: Nearly all components expose `/metrics` endpoints (port 8080 or 8443)
- **Health Probes**: Standard `/healthz` (liveness) and `/readyz` (readiness) on port 8081
- **OpenShift Routes**: External ingress via Routes with TLS edge or re-encrypt termination
- **OAuth Proxy Sidecar**: Authentication pattern for external access (notebooks, Ray, dashboards)
- **NetworkPolicies**: Components create NetworkPolicies for traffic isolation
- **Service CA Certificates**: Automatic TLS certificate provisioning via `service.beta.openshift.io/serving-cert-secret-name`

**Integration Workflows**:
- **Notebook → Pipeline**: Users develop in notebooks, submit pipelines via kfp SDK
- **Pipeline → Model Deployment**: DSP creates InferenceService CRs for trained models
- **Model Serving → Monitoring**: TrustyAI patches inference services for bias detection
- **Training → Scheduling**: Training jobs queue in Kueue, scheduled with gang scheduling
- **Ray → Job Queuing**: AppWrappers wrap RayClusters for Kueue integration

## Platform Network Architecture

### Namespaces

| Namespace | Purpose | Components |
|-----------|---------|------------|
| redhat-ods-operator | Platform operator | rhods-operator controller |
| redhat-ods-applications | Core services | odh-dashboard, notebook-controller, odh-model-controller, data-science-pipelines-operator, kserve-controller, modelmesh-controller, training-operator, trustyai-service-operator |
| redhat-ods-monitoring | Observability | Prometheus, Alertmanager, Grafana, ServiceMonitors |
| opendatahub | Legacy/alternate | KubeRay, CodeFlare, Kueue operators |
| istio-system | Service Mesh | Istio control plane (managed by Service Mesh Operator) |
| {user-namespace} | User workloads | Notebooks, InferenceServices, DSPAs, Training Jobs, Ray Clusters |
| rhoai-model-registries / odh-model-registries | Model Registry | ModelRegistry service instances |

### External Ingress Points

| Component | Ingress Type | Hosts | Port | Protocol | Encryption | Purpose |
|-----------|--------------|-------|------|----------|------------|---------|
| odh-dashboard | OpenShift Route | {cluster-domain} | 443/TCP | HTTPS | TLS 1.2+ (reencrypt) | Platform UI access |
| Notebooks | OpenShift Route | {notebook}-{namespace}.{cluster-domain} | 443/TCP | HTTPS | TLS 1.2+ (edge or reencrypt) | Jupyter/code-server access |
| Ray Dashboard | OpenShift Route | {raycluster}.{cluster-domain} | 443/TCP | HTTPS | TLS 1.2+ (edge) | Ray cluster dashboard |
| InferenceService (KServe) | OpenShift Route + Istio Gateway | {isvc}-{namespace}.{domain} | 443/TCP | HTTPS | TLS 1.2+ | Model inference endpoints |
| InferenceService (ModelMesh) | OpenShift Route | {predictor}.{cluster-domain} | 443/TCP | HTTPS | TLS 1.2+ | Multi-model inference |
| Model Registry | Istio Gateway + OpenShift Route | {registry}-{namespace}.{domain} | 443/TCP | HTTPS | TLS 1.2+ (passthrough/edge) | Model metadata API |
| TrustyAI Service | OpenShift Route | {service}.{cluster-domain} | 443/TCP | HTTPS | TLS 1.2+ (reencrypt) | Explainability API |
| DSP UI (optional) | OpenShift Route | ds-pipeline-ui-{name}.{cluster-domain} | 443/TCP | HTTPS | TLS 1.2+ (reencrypt) | Pipeline UI |

### External Egress Dependencies

| Component | Destination | Port | Protocol | Encryption | Purpose |
|-----------|-------------|------|----------|------------|---------|
| KServe storage-initializer | S3 (AWS/MinIO/etc.) | 443/TCP | HTTPS | TLS 1.2+ | Model artifact downloads |
| KServe storage-initializer | GCS | 443/TCP | HTTPS | TLS 1.2+ | Model artifact downloads |
| KServe storage-initializer | Azure Blob | 443/TCP | HTTPS | TLS 1.2+ | Model artifact downloads |
| DSP API Server | S3/MinIO | 443/TCP or 9000/TCP | HTTPS/HTTP | TLS 1.2+ or None | Pipeline artifact storage |
| DSP API Server | External MySQL/PostgreSQL | 3306/TCP or 5432/TCP | MySQL/PostgreSQL | TLS (configurable) | Pipeline metadata |
| Model Registry | External PostgreSQL/MySQL | 5432/TCP or 3306/TCP | PostgreSQL/MySQL | TLS (configurable) | Model metadata storage |
| TrustyAI Service | External Database | Varies | JDBC | TLS (configurable) | Fairness metrics storage |
| ModelMesh | S3/MinIO | 443/TCP or 9000/TCP | HTTPS/HTTP | TLS 1.2+ or None | Model storage |
| ModelMesh | etcd | 2379/TCP | HTTP | None | Model registry coordination |
| rhods-operator | github.com | 443/TCP | HTTPS | TLS 1.2+ | Component manifest downloads |
| All operators | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | Resource management |
| All operators | Container Registry | 443/TCP | HTTPS | TLS 1.2+ | Container image pulls |
| Notebooks | PyPI/Conda | 443/TCP | HTTPS | TLS 1.2+ | Python package installation |
| Notebooks | Git repositories | 443/TCP | HTTPS | TLS 1.2+ | Code repositories |
| Ray Clusters | Git repositories | 443/TCP | HTTPS | TLS 1.2+ | Runtime environments |

### Internal Service Mesh

| Setting | Value | Components Using |
|---------|-------|------------------|
| mTLS Mode | ISTIO_MUTUAL (default) | KServe InferenceServices, Model Registry, odh-model-controller |
| Peer Authentication | PERMISSIVE (namespace-level) | Inference service namespaces |
| Traffic Management | VirtualService + Gateway | KServe, ModelMesh, Model Registry |
| Authorization | Authorino external provider | KServe inference endpoints, Model Registry API |
| Telemetry | Enabled | InferenceService metrics collection |
| Sidecar Injection | Selective (annotation-based) | InferenceService pods, Model Registry pods |

## Platform Security

### RBAC Summary

**Cluster-Level Permissions (Selected High-Privilege Roles)**:

| Component | ClusterRole | Key API Groups | Key Resources | Notable Verbs |
|-----------|-------------|----------------|---------------|---------------|
| rhods-operator | controller-manager-role | *, apps, rbac.authorization.k8s.io | namespaces, configmaps, secrets, deployments, clusterroles, clusterrolebindings, CRDs | create, delete, get, list, patch, update, watch |
| kserve | kserve-manager-role | serving.kserve.io, serving.knative.dev, networking.istio.io | inferenceservices, servingruntimes, knative services, virtualservices | create, delete, get, list, patch, update, watch |
| odh-model-controller | odh-model-controller-role | serving.kserve.io, networking.istio.io, security.istio.io, authorino.kuadrant.io | inferenceservices, gateways, virtualservices, authorizationpolicies, authconfigs | create, delete, get, list, patch, update, watch |
| codeflare-operator | codeflare-operator-manager-role | ray.io, workload.codeflare.dev, kueue.x-k8s.io | rayclusters, appwrappers, workloads | create, delete, get, list, patch, update, watch |
| kueue | manager-role | kueue.x-k8s.io, kubeflow.org, ray.io, batch | clusterqueues, localqueues, workloads, pytorchjobs, rayjobs, jobs | create, delete, get, list, patch, update, watch |
| training-operator | kubeflow-training-operator | kubeflow.org, scheduling.volcano.sh | pytorchjobs, tfjobs, mpijobs, podgroups | create, delete, get, list, patch, update, watch |
| odh-dashboard | odh-dashboard | kubeflow.org, serving.kserve.io, datasciencecluster.opendatahub.io | notebooks, inferenceservices, datascienceclusters | create, delete, get, list, patch, update, watch |

**User-Facing Roles (Aggregated to admin/edit/view)**:
- `notebooks-admin`, `notebooks-edit`, `notebooks-view` - Notebook management
- `kubeflow-training-edit`, `kubeflow-training-view` - Training job management
- `kserve-editor`, `kserve-viewer` - Model serving management
- `modelregistry-editor`, `modelregistry-viewer` - Model registry access

### Secrets Inventory

| Component | Secret Name Pattern | Type | Purpose |
|-----------|---------------------|------|---------|
| rhods-operator | redhat-ods-operator-controller-webhook-cert | kubernetes.io/tls | Webhook TLS certificate |
| odh-dashboard | dashboard-proxy-tls, dashboard-oauth-config-generated | kubernetes.io/tls, Opaque | OAuth proxy TLS and config |
| Notebooks | {notebook}-oauth-config, {notebook}-tls | Opaque, kubernetes.io/tls | OAuth proxy cookie secret and TLS cert |
| Ray Clusters | {raycluster}-ca-secret, {raycluster}-oauth-config | Opaque | Ray mTLS CA and OAuth config |
| KServe | storage-config, kserve-webhook-server-cert | Opaque, kubernetes.io/tls | S3 credentials and webhook cert |
| ModelMesh | model-serving-etcd, storage-config | Opaque | etcd credentials and S3 config |
| DSP | ds-pipeline-db-{name}, ds-pipeline-s3-{name} | Opaque | Database and S3 credentials |
| Model Registry | {registry}-db, modelregistry-sample-rest-credential | Opaque, kubernetes.io/tls | Database password and Gateway TLS |
| TrustyAI | {instance}-db-credentials, {instance}-tls | Opaque, kubernetes.io/tls | Database credentials and service TLS |

### Authentication Mechanisms

| Pattern | Components Using | Enforcement Point | Token/Credential Type |
|---------|------------------|-------------------|----------------------|
| OpenShift OAuth (Browser) | odh-dashboard, notebooks, Ray dashboards | OAuth Proxy Sidecar | Session cookies, OAuth tokens |
| Bearer Tokens (API) | KServe inference, Model Registry API, DSP API | Authorino, OAuth Proxy | Kubernetes ServiceAccount tokens (JWT) |
| mTLS Client Certificates | Ray client connections, Istio service-to-service | Ray head pod, Istio sidecars | X.509 client certificates |
| AWS IAM (IRSA) | KServe storage-initializer, DSP, notebooks | S3 API | AWS STS temporary credentials |
| Basic Auth | etcd (ModelMesh) | etcd server | Username/password |
| Database Auth | DSP MariaDB, Model Registry DB, TrustyAI DB | Database server | Username/password over TLS |
| Kubernetes API | All operators and controllers | Kubernetes API Server | ServiceAccount tokens (JWT) |

### Network Policy Summary

**Common Patterns**:
- Allow ingress from `openshift-monitoring`, `openshift-user-workload-monitoring` for Prometheus scraping
- Allow ingress from `openshift-ingress` for OpenShift Router traffic
- Allow ingress from namespaces with label `opendatahub.io/generated-namespace=true` for inter-component communication
- Deny all other ingress by default (namespace-level policies)

**Per-Component Examples**:
- **Notebooks**: Allow ingress on 8888/TCP from controller namespace, allow 8443/TCP for OAuth proxy
- **Ray Clusters**: Allow ingress on 8265/TCP (dashboard), 10001/TCP (client) from same namespace
- **ModelMesh**: Allow ingress on 8033/TCP (gRPC), 8008/TCP (REST) from all, 2112/TCP (metrics) from monitoring
- **KServe**: Policies managed by odh-model-controller based on deployment mode

## Platform APIs

### Custom Resource Definitions

| Component | API Group | Kind | Scope | Purpose |
|-----------|-----------|------|-------|---------|
| rhods-operator | datasciencecluster.opendatahub.io | DataScienceCluster | Cluster | Platform component enablement |
| rhods-operator | dscinitialization.opendatahub.io | DSCInitialization | Cluster | Platform initialization (monitoring, mesh) |
| odh-dashboard | dashboard.opendatahub.io | OdhApplication, OdhDocument, AcceleratorProfile | Namespaced | Dashboard catalog and configuration |
| odh-dashboard | opendatahub.io | OdhDashboardConfig | Namespaced | Dashboard feature flags and settings |
| odh-dashboard | console.openshift.io | OdhQuickStart | Cluster | Guided tutorials |
| notebook-controller | kubeflow.org | Notebook | Namespaced | Jupyter notebook instances |
| data-science-pipelines | datasciencepipelinesapplications.opendatahub.io | DataSciencePipelinesApplication | Namespaced | Pipeline stack instances |
| kserve | serving.kserve.io | InferenceService, ServingRuntime, ClusterServingRuntime, InferenceGraph, TrainedModel | Namespaced/Cluster | Model serving configurations |
| modelmesh-serving | serving.kserve.io | Predictor, ServingRuntime, ClusterServingRuntime | Namespaced/Cluster | Multi-model serving (legacy) |
| model-registry | modelregistry.opendatahub.io | ModelRegistry | Namespaced | Model registry instances |
| codeflare | workload.codeflare.dev | AppWrapper | Namespaced | Batch workload scheduling wrapper |
| kuberay | ray.io | RayCluster, RayJob, RayService | Namespaced | Ray distributed computing |
| training-operator | kubeflow.org | PyTorchJob, TFJob, MPIJob, MXJob, XGBoostJob, PaddleJob | Namespaced | Distributed training jobs |
| kueue | kueue.x-k8s.io | ClusterQueue, LocalQueue, Workload, ResourceFlavor, WorkloadPriorityClass | Cluster/Namespaced | Job queueing and quota |
| trustyai | trustyai.opendatahub.io | TrustyAIService | Namespaced | AI fairness service instances |

### Public HTTP Endpoints

**User-Facing APIs** (External Access via Routes/Gateways):

| Path Pattern | Component | Method | Port | Protocol | Auth | Purpose |
|--------------|-----------|--------|------|----------|------|---------|
| /api/* | odh-dashboard | GET, POST, PATCH, DELETE | 8443/TCP | HTTPS | OAuth | Dashboard API (notebooks, pipelines, models) |
| /notebook/{namespace}/{user}/* | Notebooks | GET, POST, WebSocket | 8443/TCP | HTTPS | OAuth | Jupyter/code-server interface |
| /apis/v2beta1/* | DSP API Server | REST | 8443/TCP | HTTPS | OAuth | Pipeline management API |
| /v1/models/{model}:predict | KServe | POST | 443/TCP | HTTPS | Bearer Token | V1 inference endpoint |
| /v2/models/{model}/infer | KServe/ModelMesh | POST | 443/TCP | HTTPS | Bearer Token | V2 inference endpoint (gRPC-Web or REST) |
| /api/model_registry/v1alpha3/* | Model Registry | GET, POST, PUT, DELETE | 443/TCP | HTTPS | Bearer Token | Model metadata CRUD |
| /* | TrustyAI Service | ALL | 8443/TCP | HTTPS | OAuth | Explainability API |
| / | Ray Dashboard | GET, POST | 443/TCP | HTTPS | OAuth | Ray cluster monitoring |

**Internal-Only APIs** (ClusterIP Services):

| Path | Component | Port | Purpose |
|------|-----------|------|---------|
| /metrics | All operators | 8080/TCP or 8443/TCP | Prometheus metrics |
| /healthz | All operators | 8081/TCP | Liveness probes |
| /readyz | All operators | 8081/TCP | Readiness probes |

### gRPC Services

| Service | Component | Port | Protocol | Encryption | Purpose |
|---------|-----------|------|----------|------------|---------|
| inference.GRPCInferenceService | KServe | 8081/TCP | gRPC/HTTP2 | None (internal) | V2 gRPC inference |
| ModelMesh Inference | ModelMesh | 8033/TCP | gRPC | None (internal) | KServe V2 gRPC protocol |
| ML Metadata Store | DSP, Model Registry | 9090/TCP or 8080/TCP | gRPC | TLS (configurable) | Metadata lineage |
| Ray GCS | Ray Clusters | 6379/TCP | Ray Protocol | None | Ray cluster coordination |
| Ray Client Server | Ray Clusters | 10001/TCP | Ray Protocol | mTLS (optional) | Job submission |

## Data Flows

### Key Platform Workflows

#### Workflow 1: Notebook Development to Model Deployment

| Step | Component | Action | Protocol | Next Component |
|------|-----------|--------|----------|----------------|
| 1 | User | Access Dashboard → Create Notebook | HTTPS (OAuth) | odh-dashboard |
| 2 | odh-dashboard | Create Notebook CR via K8s API | HTTPS | notebook-controller |
| 3 | notebook-controller | Create StatefulSet, Service, Route | K8s API | Notebook pod starts |
| 4 | User | Develop model in Jupyter | HTTPS (OAuth via Route) | Notebook pod |
| 5 | Notebook | Train model, save to S3 | HTTPS | S3 storage |
| 6 | User | Create InferenceService via Dashboard or kubectl | HTTPS | kserve-controller |
| 7 | kserve-controller | Create Knative Service or Deployment | K8s API | InferenceService pod starts |
| 8 | odh-model-controller | Create Route, Gateway, AuthConfig | K8s API | Inference endpoint available |
| 9 | storage-initializer | Download model from S3 | HTTPS | InferenceService pod |
| 10 | User/App | Send inference request | HTTPS (Bearer Token) | InferenceService |

#### Workflow 2: Pipeline Execution to Model Serving

| Step | Component | Action | Protocol | Next Component |
|------|-----------|--------|----------|----------------|
| 1 | User | Create DSPA via Dashboard | HTTPS (OAuth) | odh-dashboard |
| 2 | DSPO | Deploy API Server, Argo Workflow Controller, MariaDB | K8s API | Pipeline infrastructure ready |
| 3 | User | Submit pipeline via kfp SDK from Notebook | HTTPS (Bearer Token) | DSP API Server |
| 4 | DSP API Server | Create Argo Workflow CR | K8s API | Argo Workflow Controller |
| 5 | Argo Workflow Controller | Create pipeline step pods | K8s API | Workflow pods execute |
| 6 | Pipeline Step Pods | Execute training, download/upload artifacts to S3 | HTTPS | S3 storage |
| 7 | Pipeline Step | Create InferenceService CR | K8s API | kserve-controller |
| 8 | Persistence Agent | Watch workflow status, update DB | MySQL | DSP API Server, MariaDB |
| 9 | kserve-controller | Deploy model | K8s API | Model serving pod |

#### Workflow 3: Distributed Training with Job Queueing

| Step | Component | Action | Protocol | Next Component |
|------|-----------|--------|----------|----------------|
| 1 | User | Create PyTorchJob CR | HTTPS | Kubernetes API |
| 2 | Kubernetes API | Webhook to training-operator | HTTPS | training-operator |
| 3 | training-operator | Create Kueue Workload CR | K8s API | kueue |
| 4 | kueue | Evaluate ClusterQueue quotas | In-process | Admission decision |
| 5 | kueue | Admit workload if quota available | K8s API | training-operator |
| 6 | training-operator | Create PyTorch worker pods | K8s API | PyTorch pods start |
| 7 | PyTorch workers | Distributed training communication | TCP (torchrun) | Training completes |
| 8 | training-operator | Update PyTorchJob status | K8s API | Job completed |
| 9 | kueue | Release quota | In-process | Next job can be admitted |

#### Workflow 4: Ray Cluster Creation and Job Execution

| Step | Component | Action | Protocol | Next Component |
|------|-----------|--------|----------|----------------|
| 1 | User | Create RayCluster CR (optionally via AppWrapper) | HTTPS | kuberay-operator |
| 2 | kuberay-operator | Create head pod, worker pods, services | K8s API | Ray cluster starts |
| 3 | codeflare-operator | Inject OAuth proxy, create Route, NetworkPolicy | K8s API | Ray dashboard accessible |
| 4 | codeflare-operator | Create AppWrapper Workload (if AppWrapper used) | K8s API | kueue |
| 5 | kueue | Admit AppWrapper based on quotas | K8s API | Resources provisioned |
| 6 | User | Submit Ray job via dashboard or client | HTTPS (OAuth) | Ray head pod |
| 7 | Ray head | Distribute work to workers | Ray Protocol (6379, 10001) | Distributed execution |
| 8 | Ray workers | Execute tasks, return results | Ray Protocol | Job completes |

#### Workflow 5: Model Monitoring and Bias Detection

| Step | Component | Action | Protocol | Next Component |
|------|-----------|--------|----------|----------------|
| 1 | User | Create TrustyAIService CR | HTTPS | trustyai-service-operator |
| 2 | trustyai-operator | Deploy TrustyAI service, Route, PVC | K8s API | TrustyAI service starts |
| 3 | trustyai-operator | Watch for InferenceServices in namespace | K8s API | Monitoring loop |
| 4 | trustyai-operator | Patch ModelMesh deployment with MM_PAYLOAD_PROCESSORS | K8s API | ModelMesh |
| 5 | ModelMesh | Send inference payloads to TrustyAI | HTTP | TrustyAI service |
| 6 | TrustyAI service | Calculate fairness metrics (SPD, DIR) | In-process | Metrics storage |
| 7 | TrustyAI service | Expose metrics on /q/metrics | HTTP | Prometheus scrapes |
| 8 | User | View bias metrics via Prometheus/Grafana | HTTPS | Monitoring dashboards |

## Deployment Architecture

### Deployment Topology

**Multi-Namespace Architecture**:
- **Platform Operators**: Deployed in `redhat-ods-operator` and `redhat-ods-applications` namespaces
- **Monitoring**: Centralized in `redhat-ods-monitoring` namespace with Prometheus, Alertmanager
- **Service Mesh**: Control plane in `istio-system`, data plane sidecars in user namespaces
- **User Workloads**: Isolated per-namespace deployment for notebooks, pipelines, models
- **Shared Services**: Model Registry instances in dedicated namespace(s)

**Component Distribution**:
```
redhat-ods-operator/
├── rhods-operator (1 replica, leader election)

redhat-ods-applications/
├── odh-dashboard (2 replicas, HA)
├── notebook-controller (1 replica)
├── odh-notebook-controller (1 replica)
├── data-science-pipelines-operator (1 replica, leader election)
├── kserve-controller-manager (1 replica, leader election)
├── modelmesh-controller (1 replica, leader election)
├── odh-model-controller (1 replica, leader election)
├── kuberay-operator (1 replica)
├── codeflare-operator (1 replica)
├── training-operator (1 replica)
├── kueue-controller-manager (1 replica, leader election)
├── model-registry-operator (1 replica, leader election)
└── trustyai-service-operator (1 replica, leader election)

{user-namespace}/
├── Notebook StatefulSets (per user/workbench)
├── DSPA instances (API Server, Persistence Agent, Workflow Controller, MariaDB, MinIO)
├── InferenceService Deployments/KnativeServices (per model)
├── Training Job Pods (PyTorchJob, TFJob, etc.)
├── RayCluster Pods (head + workers)
└── TrustyAI Service Deployments

rhoai-model-registries/
└── ModelRegistry Deployments (REST + gRPC containers)
```

### Resource Requirements

**Operator Resource Profiles** (Aggregate):
- **Minimal Setup**: ~2 vCPU, ~4 GiB memory for all operators
- **Recommended**: ~5 vCPU, ~10 GiB memory for all operators with headroom
- **Per-Component Breakdown** (Requests/Limits):
  - rhods-operator: 100m CPU / 780Mi memory
  - odh-dashboard: 1000m CPU / 2Gi memory (per replica, 2 replicas)
  - notebook-controller: 500m CPU / 256Mi memory
  - DSPO: 200m CPU / 400Mi memory
  - kserve-controller: CPU/memory not specified (uses defaults)
  - odh-model-controller: 10m CPU / 64Mi memory
  - Other operators: 10-500m CPU, 64Mi-2Gi memory

**User Workload Resource Profiles** (Typical):
- **Notebook**: 1-2 CPU, 2-8 GiB memory (user-configurable)
- **DSPA Instance**: ~2 CPU, ~4 GiB memory (API Server + agents + database)
- **InferenceService**: 1-4 CPU, 2-16 GiB memory (model-dependent, GPU optional)
- **Training Job**: 4-128 CPU, 16-512 GiB memory (distributed training, GPU-accelerated)
- **RayCluster**: 2-64+ CPU, 8-256+ GiB memory (per cluster, scales with workers)

### High Availability Considerations

**Operator HA**:
- Most operators: Single replica with leader election (automatic failover)
- odh-dashboard: 2 replicas with anti-affinity for active-active HA
- Webhook servers: Maintained by all replicas (no leader election needed)

**User Workload HA**:
- Notebooks: Single-replica StatefulSets (not HA, tied to user session)
- InferenceServices (Serverless): Auto-scaling with Knative (min 0, max configurable)
- InferenceServices (Raw): Multiple replicas with HPA (configurable)
- ModelMesh: Multiple runtime pods with intelligent model placement
- DSPA: Single replica components (no HA for API Server, agents)
- Training Jobs: Job-level fault tolerance (restart policies, checkpointing)

## Version-Specific Changes (2.14)

| Component | Notable Changes |
|-----------|-----------------|
| kserve | - Security fix for CVE-2024-6119 Type Confusion vulnerability<br>- Updated to commit 1fdf877e7 with kserve-agent-214, storage-initializer-214, router-214, controller-214 updates<br>- Merged upstream release-v0.12.1 |
| odh-model-controller | - Updated vLLM CUDA to versions 9b5ce1d, 97b91f9, 018c2a6<br>- Added 2.14 (2024.3) stable images of OVMS, caikit-tgis, TGIS<br>- Merged upstream main and release-0.12.0 branches |
| codeflare-operator | - Update dependency versions for release v1.9.0<br>- Update appwrappers to v0.25.0<br>- Update codeflare-common version |
| kueue | - Upgrade Kueue image to v0.8.1<br>- Add AppWrappers as external framework for RHOAI<br>- Set waitForPodsReady to true by default<br>- Add dedicated service for kueue metrics |
| data-science-pipelines | - Added support for TLS to MLMD GRPC Server<br>- Updated MariaDB to serve over TLS<br>- Support environment variables as pipeline parameters<br>- Added secrets::list permissions to pipeline runner |
| kuberay | - Raise head pod memory limit to avoid test instability<br>- Add SecurityContext to ray pods for restricted pod-security<br>- Updated KubeRay image to v1.1.0 |
| training-operator | - Training-operator manifests kustomize v5 upgrade<br>- Update go to 1.21<br>- Update manifests to use ODH KFTO image |
| workbench-images | - Include 2024.1 images with codeflare-sdk commit 636b66d<br>- Update odh-elyra from 4.0.2 to 4.0.3<br>- Update imagestream SHAs for 2024b and 2024a releases |
| odh-dashboard | - Fix NIM model name fetch from ConfigMap<br>- Version bump for Dashboard v2.27.0<br>- Enable model registry feature by default<br>- Add storage class support for notebook PVCs<br>- Optimize project list notebook fetch (lazy load) |
| model-registry-operator | - Remove static AUTH_PROVIDER to allow operator runtime configuration<br>- Replace rbac proxy container with controller metrics server authentication<br>- Add govulncheck and fix protobuf dependency |
| trustyai-service-operator | - Add support for custom DB names<br>- Add TLS endpoint for ModelMesh payload processors<br>- Add support for custom certificates in database connection<br>- Skip InferenceService patching for KServe RawDeployment |
| rhods-operator | - Fix: Add release status to upgrade case<br>- Add missing RBAC rule to scrape metrics endpoints protected by RBAC<br>- Add support for upgrade to force disableModelRegistry to false<br>- Change default model registries namespace to rhoai-model-registries |

## Platform Maturity

**Total Components**: 14 core components + 1 base platform (Kubeflow Notebook Controller)

**Operator-based Components**: 100% (all components use operator pattern)

**Service Mesh Coverage**:
- **Full Integration**: KServe InferenceServices, ModelMesh Serving, Model Registry (70% of serving workloads)
- **Optional/Partial**: Notebooks, DSP (can use mesh but not required)
- **No Integration**: Training jobs, Ray clusters (stateful compute workloads)
- **Overall Coverage**: ~60% of platform traffic flows through service mesh

**mTLS Enforcement**:
- **STRICT**: Not enforced by default (PERMISSIVE mode for backwards compatibility)
- **ISTIO_MUTUAL**: Default for service-to-service in mesh (KServe, Model Registry)
- **Custom mTLS**: Ray clusters (self-signed CA per cluster)
- **Overall**: MIXED (mesh-enabled components use mTLS, others rely on TLS at ingress)

**CRD API Versions**:
- **v1 (Stable)**: DataScienceCluster, DSCInitialization, Notebook, PyTorchJob, TFJob, MPIJob, RayCluster, RayJob, TrustyAIService, ClusterQueue, LocalQueue
- **v1beta1**: InferenceService, ServingRuntime, Workload (Kueue)
- **v1beta2**: AppWrapper, AuthConfig (Authorino)
- **v1alpha1**: DataSciencePipelinesApplication, OdhDashboardConfig, ModelRegistry, InferenceGraph, TrainedModel, Predictor
- **Assessment**: Core platform APIs are stable (v1), newer features still in alpha/beta

**Platform Maturity Indicators**:
- ✅ **Production Ready**: Notebook management, basic model serving (KServe), pipeline execution (DSP)
- ✅ **Stable**: Distributed training (Training Operator), job queueing (Kueue), Ray clusters
- ⚠️ **Maturing**: Model Registry (v1alpha1), ModelMesh serving (legacy), InferenceGraph (v1alpha1)
- ⚠️ **Emerging**: TrustyAI monitoring, multi-model serving with TrainedModel API
- ⚠️ **Limited HA**: Most DSPA components, Model Registry (single replica)

**Security Posture**:
- ✅ Non-root containers across all components
- ✅ RBAC enforced for all API operations
- ✅ TLS for external ingress (Routes)
- ✅ Optional mTLS for service-to-service (Istio)
- ✅ OpenShift SCC compliance (restricted)
- ⚠️ NetworkPolicies created but may require tuning
- ⚠️ Secrets rotation varies (auto-rotate for service-ca, manual for user secrets)

## Next Steps for Documentation

### Recommended Actions

1. **Generate Architecture Diagrams**
   - Component dependency graph
   - Network flow diagrams per workflow
   - Namespace topology visualization
   - Service mesh traffic flows

2. **Update Architecture Decision Records (ADRs)**
   - Document decision to use Istio for service mesh
   - Document Kueue as standard job queue vs. Volcano
   - Document model registry namespace strategy
   - Document decision to enable waitForPodsReady in Kueue by default

3. **Create User-Facing Documentation**
   - Simplified architecture overview for data scientists
   - Component selection guide (when to use KServe vs. ModelMesh, etc.)
   - Resource planning guide (sizing recommendations per workload type)
   - Security best practices (secrets management, RBAC, network policies)

4. **Generate Security Architecture Review (SAR) Documentation**
   - Network diagram showing all external egress points
   - Authentication flow diagrams (OAuth, bearer tokens, mTLS)
   - Secrets inventory and rotation policy
   - Compliance mapping (RBAC, encryption, audit logging)

5. **Develop Operational Runbooks**
   - Component upgrade procedures
   - Disaster recovery procedures
   - Troubleshooting guides per component
   - Monitoring and alerting setup

6. **Create Integration Guides**
   - Integrating external S3/blob storage
   - Connecting to external databases
   - Setting up custom CA certificates
   - Configuring custom authentication providers

### Immediate Priorities

**High Priority**:
- Document model registry namespace configuration (breaking change in 2.14)
- Create security network diagrams for SAR
- Document TLS configuration for external databases (DSP, Model Registry, TrustyAI)

**Medium Priority**:
- Create workflow diagrams for the 5 key workflows documented above
- Document service mesh opt-in vs. opt-out strategy
- Update capacity planning guides with RHOAI 2.14 resource requirements

**Low Priority**:
- Document advanced Kueue configuration (ClusterQueues, ResourceFlavors)
- Create example manifests for common deployment patterns
- Document multi-cluster deployment considerations

### Documentation Gaps Identified

1. **Missing**: End-to-end GPU/accelerator configuration documentation
2. **Missing**: Multi-tenancy and quota management best practices
3. **Missing**: Pipeline-to-model-serving automation patterns
4. **Missing**: Cost attribution and chargeback strategies
5. **Incomplete**: Service mesh configuration examples (AuthorizationPolicy, PeerAuthentication)
6. **Incomplete**: Disaster recovery procedures for stateful components (DSPA, Model Registry)
