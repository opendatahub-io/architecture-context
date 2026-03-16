# Platform: Red Hat OpenShift AI 2.17

## Metadata
- **Distribution**: RHOAI (Red Hat OpenShift AI)
- **Version**: 2.17
- **Release Branch**: rhoai-2.17
- **Base Platform**: Red Hat OpenShift Container Platform 4.11+
- **Components Analyzed**: 14
- **Document Generated**: 2026-03-16

## Platform Overview

Red Hat OpenShift AI (RHOAI) 2.17 is an enterprise platform for developing, training, serving, and monitoring machine learning and artificial intelligence models on Red Hat OpenShift. The platform provides a comprehensive ecosystem of integrated components that span the entire ML lifecycle—from interactive workbench development environments to production-grade model serving with explainability and monitoring.

The platform architecture centers around a unified operator (rhods-operator) that orchestrates 12 specialized component operators and services. These components work together to provide: (1) **Development Environments** through Jupyter notebooks with GPU support and multiple ML frameworks, (2) **Distributed Computing** via Ray, CodeFlare, and Kueue for batch workloads, (3) **Model Training** using Kubeflow Training Operator for distributed training across PyTorch, TensorFlow, and other frameworks, (4) **Model Serving** through KServe and ModelMesh with autoscaling and multi-model support, (5) **ML Pipelines** via Data Science Pipelines with Argo Workflows, (6) **Model Governance** through Model Registry for versioning and lineage, and (7) **AI Trustworthiness** via TrustyAI for explainability and fairness metrics.

RHOAI 2.17 integrates deeply with OpenShift services including Service Mesh (Istio) for mTLS and traffic management, OpenShift OAuth for authentication, Prometheus for monitoring, and OpenShift Routes for ingress. The platform is designed for multi-tenant data science teams with namespace-based isolation, RBAC-based access control, and comprehensive security policies including network policies, pod security standards, and encrypted communication.

## Component Inventory

| Component | Type | Version | Purpose |
|-----------|------|---------|---------|
| rhods-operator | Kubernetes Operator | v1.6.0-4171 | Central orchestration operator managing platform component lifecycle via DataScienceCluster CRD |
| odh-dashboard | Web Application | v1.21.0-18-rhods-2865 | React/Node.js web UI for managing workbenches, pipelines, model serving, and data science projects |
| odh-notebook-controller | Kubernetes Operator | v1.27.0-rhods-873 | Extends Kubeflow notebooks with OpenShift OAuth proxy, Routes, and network policies |
| workbench-images | Container Images | v20xx.1-567 | Jupyter, RStudio, Code Server workbench images with Python 3.9/3.11, PyTorch, TensorFlow, CUDA, ROCm |
| data-science-pipelines-operator | Kubernetes Operator | 15f468f | Deploys Data Science Pipelines (Kubeflow Pipelines v2) with Argo Workflows backend |
| kserve | Kubernetes Operator + Runtimes | 6a07b522b | Model serving framework with serverless autoscaling, multi-framework support, and standardized inference protocols |
| modelmesh-serving | Kubernetes Operator | v1.27.0-rhods-348 | Multi-model serving with intelligent placement, ModelMesh router, and multiple runtime backends |
| odh-model-controller | Kubernetes Operator | v1.27.0-rhods-728 | Extends KServe with OpenShift Routes, Istio integration, Authorino auth, and NVIDIA NIM support |
| model-registry-operator | Kubernetes Operator | a169b40 | Manages Model Registry services with PostgreSQL/MySQL backend, Istio integration, and Authorino auth |
| kueue | Kubernetes Operator | 0f775887e | Job queueing and resource management for Kubernetes workloads with fair sharing and preemption |
| kuberay | Kubernetes Operator | c61e5a05 | Manages Ray cluster lifecycle for distributed computing (RayCluster, RayJob, RayService CRDs) |
| codeflare-operator | Kubernetes Operator | v1.12.0 (6184344) | Manages Ray cluster security (OAuth, mTLS, network policies) and AppWrapper orchestration |
| training-operator | Kubernetes Operator | 1.8.0-rc.0 (36be2dda) | Kubeflow Training Operator for distributed ML training (PyTorch, TensorFlow, MPI, XGBoost, MXNet, PaddlePaddle) |
| trustyai-service-operator | Kubernetes Operator | 286a398 | AI explainability, fairness metrics (SPD, DIR), and LLM evaluation jobs |

## Component Relationships

### Dependency Graph

```
rhods-operator (Central Orchestration)
├── odh-dashboard
│   ├── kubeflow-notebook-controller (API calls for notebook management)
│   ├── kserve (API calls for InferenceService status)
│   ├── model-registry-operator (API calls for model metadata)
│   ├── data-science-pipelines-operator (API calls for pipeline management)
│   └── Prometheus (metrics queries via Thanos)
│
├── odh-notebook-controller
│   ├── kubeflow-notebook-controller (extends with OpenShift features)
│   └── data-science-pipelines-operator (optional RoleBinding for Elyra pipeline execution)
│
├── kserve
│   ├── knative-serving (serverless autoscaling)
│   ├── istio (traffic management, mTLS)
│   ├── odh-model-controller (OpenShift integrations)
│   └── model-registry-operator (optional model metadata)
│
├── odh-model-controller
│   ├── kserve (extends InferenceServices)
│   ├── istio (Gateway, VirtualService, PeerAuthentication)
│   ├── authorino (AuthConfig for authentication)
│   └── prometheus (ServiceMonitor creation)
│
├── modelmesh-serving
│   ├── kserve (uses KServe CRD schemas)
│   ├── etcd (distributed state coordination)
│   └── istio (optional mTLS)
│
├── data-science-pipelines-operator
│   ├── argo-workflows (pipeline execution backend)
│   ├── kserve (optional model deployment from pipelines)
│   └── model-registry-operator (optional model storage)
│
├── model-registry-operator
│   ├── postgresql OR mysql (metadata storage backend)
│   ├── istio (Gateway, VirtualService, mTLS)
│   └── authorino (authentication/authorization)
│
├── codeflare-operator
│   ├── kuberay (watches and reconciles RayCluster CRs)
│   ├── kueue (optional AppWrapper workload scheduling)
│   └── OpenShift OAuth (Ray dashboard authentication)
│
├── kuberay
│   ├── ray (distributed computing framework)
│   └── prometheus (metrics collection)
│
├── training-operator
│   ├── volcano OR scheduler-plugins (optional gang scheduling)
│   └── kueue (job queue integration)
│
├── kueue
│   ├── training-operator (queues PyTorchJob, TFJob, MPIJob, etc.)
│   ├── kuberay (queues RayJob and RayCluster)
│   ├── codeflare-operator (queues AppWrapper)
│   └── batch/job (queues Kubernetes Batch Jobs)
│
└── trustyai-service-operator
    ├── kserve (InferenceService monitoring and data collection)
    ├── modelmesh-serving (ModelMesh monitoring)
    ├── kueue (LMEvalJob queue management)
    └── prometheus (fairness metrics exposure)
```

### Central Components

The following components have the most dependencies and serve as core platform services:

1. **rhods-operator**: Platform orchestrator managing all component lifecycles
2. **kserve**: Model serving framework integrated by ModelController, Dashboard, Pipelines, TrustyAI
3. **istio (Service Mesh)**: Network layer for KServe, ModelMesh, ModelRegistry (mTLS, routing, auth)
4. **authorino**: Authentication/authorization for KServe, ModelRegistry
5. **prometheus**: Monitoring and metrics for all components
6. **kueue**: Job queue management for Training, Ray, CodeFlare workloads

### Integration Patterns

**Pattern 1: CRD-based Integration**
- Components watch and reconcile each other's CRDs (e.g., odh-model-controller extends kserve InferenceService)
- Example: CodeFlare watches kuberay RayCluster CRDs to inject security configurations

**Pattern 2: API-based Integration**
- Dashboard calls component REST APIs via Kubernetes API server proxy
- Example: Dashboard queries Data Science Pipelines API for pipeline status

**Pattern 3: Sidecar Injection**
- Components inject sidecars into pods for auth, networking, monitoring
- Example: OAuth proxy sidecars for notebooks, Ray dashboards, TrustyAI services

**Pattern 4: Service Discovery**
- Components discover services via Kubernetes Service resources and labels
- Example: TrustyAI discovers InferenceServices via labels to inject payload processors

**Pattern 5: Event-driven Updates**
- Components watch CRD events and update owned resources
- Example: Model Controller watches InferenceService create/update events to manage Routes

## Platform Network Architecture

### Namespaces

| Namespace | Purpose | Components |
|-----------|---------|------------|
| redhat-ods-operator | Operator deployment | rhods-operator controller manager |
| redhat-ods-applications | Application services | odh-dashboard, odh-notebook-controller, odh-model-controller, kserve-controller, modelmesh-controller, model-registry-operator, training-operator, trustyai-operator |
| redhat-ods-monitoring | Monitoring stack | Prometheus, Alertmanager, Blackbox Exporter |
| istio-system | Service mesh control plane | Istio Pilot, Istiod, Ingress Gateway |
| opendatahub | Alternative namespace | KubeRay, CodeFlare, Kueue, Data Science Pipelines Operator |
| User namespaces | Data science projects | Notebooks, InferenceServices, RayClusters, TrustyAI Services, Pipelines |

### External Ingress Points

| Component | Ingress Type | Hosts | Port | Protocol | Encryption | Purpose |
|-----------|--------------|-------|------|----------|------------|---------|
| odh-dashboard | OpenShift Route | Auto-generated | 443/TCP | HTTPS | TLS 1.2+ (Reencrypt) | Web UI for platform management |
| Jupyter Notebooks | OpenShift Route | {notebook}-{ns}.{domain} | 443/TCP | HTTPS | TLS 1.2+ (Edge) | Notebook workbench access |
| RayCluster Dashboard | OpenShift Route | {dashboard}-{ns}.{domain} | 443/TCP | HTTPS | TLS 1.2+ (Re-encrypt) | Ray dashboard UI (with OAuth) |
| InferenceService (KServe) | Istio Gateway + Route | {isvc}.{namespace}.{domain} | 443/TCP | HTTPS | TLS 1.3 | Model inference endpoints |
| InferenceService (ModelMesh) | OpenShift Route | Auto-generated | 443/TCP | HTTPS | TLS 1.2+ | Multi-model inference endpoints |
| Model Registry | Istio Gateway + Route | {registry}-{rest/grpc}.{domain} | 443/TCP | HTTPS | TLS 1.2+ | Model metadata REST/gRPC APIs |
| Data Science Pipelines | OpenShift Route | Auto-generated | 443/TCP | HTTPS | TLS 1.2+ (Reencrypt) | Pipeline API and UI access |
| TrustyAI Service | OpenShift Route | Auto-generated | 443/TCP | HTTPS | TLS 1.2+ (Reencrypt) | Explainability and metrics API |
| Prometheus UI | OpenShift Route | Auto-generated | 443/TCP | HTTPS | TLS 1.2+ (Re-encrypt) | Monitoring dashboard (OAuth) |

### External Egress Dependencies

| Component | Destination | Port | Protocol | Encryption | Purpose |
|-----------|-------------|------|----------|------------|---------|
| Workbench Images | PyPI/Conda Repos | 443/TCP | HTTPS | TLS 1.2+ | Python package installation |
| KServe, ModelMesh | S3-compatible Storage | 443/TCP | HTTPS | TLS 1.2+ | Model artifact download |
| Data Science Pipelines | S3-compatible Storage | 443/TCP | HTTPS | TLS 1.2+ | Pipeline artifact storage |
| Model Registry | PostgreSQL/MySQL | 5432/3306 TCP | PostgreSQL/MySQL | TLS 1.2+ (configurable) | Model metadata persistence |
| Data Science Pipelines | MariaDB/External DB | 3306/TCP | MySQL | TLS 1.2+ (configurable) | Pipeline metadata persistence |
| TrustyAI Service | Database (MySQL/PostgreSQL) | Varies/TCP | JDBC | TLS 1.2+ (optional) | Model monitoring data storage |
| ModeLMesh Serving | etcd | 2379/TCP | HTTP | None | Distributed state coordination |
| odh-model-controller | NVIDIA NGC API | 443/TCP | HTTPS | TLS 1.2+ | NIM account validation |
| All Components | Container Registries | 443/TCP | HTTPS | TLS 1.2+ | Pull container images |

### Internal Service Mesh

| Setting | Value | Components Using |
|---------|-------|------------------|
| mTLS Mode | ISTIO_MUTUAL (default), SIMPLE, MUTUAL | KServe InferenceServices, Model Registry, Data Science Pipelines (optional) |
| Peer Authentication | STRICT mTLS for KServe pods | KServe Serverless deployments in service mesh |
| Gateway Ingress | Istio Gateway for external traffic | KServe InferenceServices, Model Registry REST/gRPC |
| Traffic Policies | DestinationRule for load balancing | KServe, Model Registry |
| Authorization | Authorino external authorization | KServe InferenceServices (when auth enabled), Model Registry |

## Platform Security

### RBAC Summary

**Operator ClusterRoles (Highest Privileges)**

| Component | Key API Groups | Critical Resources | Notable Verbs |
|-----------|----------------|-------------------|---------------|
| rhods-operator | datasciencecluster.opendatahub.io, dscinitialization.opendatahub.io, apiextensions.k8s.io | datascienceclusters, dscinitializations, customresourcedefinitions | Full (*) |
| kserve-manager | serving.kserve.io, networking.istio.io, serving.knative.dev | inferenceservices, virtualservices, services | create, delete, get, list, patch, update, watch |
| odh-model-controller | serving.kserve.io, networking.istio.io, authorino.kuadrant.io, route.openshift.io | inferenceservices, gateways, virtualservices, authconfigs, routes | create, delete, get, list, patch, update, watch |
| training-operator | kubeflow.org, scheduling.volcano.sh | pytorchjobs, tfjobs, mpijobs, xgboostjobs, mxjobs, paddlejobs, podgroups | create, delete, get, list, patch, update, watch |
| kueue-manager | kueue.x-k8s.io, kubeflow.org, ray.io, batch | clusterqueues, localqueues, workloads, pytorchjobs, rayjobs, jobs | get, list, watch, patch, update |

**Dashboard Extensive Permissions**

The ODH Dashboard requires broad permissions across the platform:
- Storage management: storageclasses (update, patch)
- Component management: datascienceclusters, dscinitializations, all component CRDs
- User resources: notebooks, inferenceservices, modelregistries, servingruntimes
- Namespace management: namespaces (patch), rolebindings (CRUD)
- Monitoring: Access to Prometheus (Thanos) metrics

### Secrets Inventory

| Component | Secret Name Pattern | Type | Purpose |
|-----------|---------------------|------|---------|
| All Operators | {component}-webhook-server-cert | kubernetes.io/tls | Webhook TLS certificates (auto-rotated by OpenShift Service CA) |
| odh-dashboard | dashboard-oauth-config-generated | Opaque | OAuth proxy cookie secret |
| Notebooks | {notebook}-oauth-config | Opaque | Per-notebook OAuth proxy cookie secret |
| Notebooks | {notebook}-tls | kubernetes.io/tls | OAuth proxy TLS certificate (Service CA) |
| RayClusters | {cluster}-oauth-config | Opaque | Ray dashboard OAuth cookie secret |
| RayClusters | ca-secret-{cluster} | Opaque | Ray mTLS CA certificate and key |
| KServe | storage-config | Opaque | S3/GCS/Azure credentials for model storage |
| ModelMesh | storage-config | Opaque | S3 credentials for model artifacts |
| ModelMesh | model-serving-etcd | Opaque | etcd connection configuration |
| Model Registry | {database}-password-secret | Opaque | Database passwords |
| Model Registry | {database}-ssl-cert/key/rootcert | Opaque | Database client TLS certificates |
| Model Registry | {registry-name}-rest/grpc-credential | kubernetes.io/tls | Gateway TLS certificates |
| Data Science Pipelines | ds-pipeline-db-{name} | Opaque | MariaDB credentials |
| Data Science Pipelines | ds-pipeline-s3-{name} | Opaque | S3 storage credentials |
| TrustyAI | {name}-db-credentials | Opaque | Database connection credentials |
| TrustyAI | {name}-tls | kubernetes.io/tls | OAuth proxy TLS certificate |
| Prometheus | prometheus-secret | kubernetes.io/service-account-token | Prometheus service account token |

### Authentication Mechanisms

| Pattern | Components Using | Enforcement Point | Token Type |
|---------|------------------|-------------------|------------|
| OpenShift OAuth (Bearer Token) | Dashboard, Notebooks, Ray Dashboard, Prometheus UI, TrustyAI | OAuth Proxy Sidecar | OpenShift session token (JWT) |
| Kubernetes RBAC (ServiceAccount Tokens) | All Operators | Kubernetes API Server | ServiceAccount JWT tokens |
| Authorino (External Auth) | KServe InferenceServices, Model Registry | Istio AuthorizationPolicy + Authorino | Kubernetes user/SA tokens validated via TokenReview + SubjectAccessReview |
| Istio mTLS (Service-to-Service) | KServe pods, Model Registry, Data Science Pipelines (optional) | Istio Envoy sidecars | X.509 certificates from Istio CA |
| Ray mTLS (Client Certs) | Ray Client connections | Ray head node | Client certificates signed by Ray cluster CA |
| Database Auth (Username/Password) | Model Registry, Data Science Pipelines, TrustyAI | Database server | JDBC/PostgreSQL/MySQL credentials |
| S3 API Keys (AWS Signature v4) | KServe, ModelMesh, Data Science Pipelines, Workbenches | S3-compatible storage | AWS Access/Secret Keys |
| API Keys | odh-model-controller (NVIDIA NGC) | NGC API Gateway | NVIDIA API keys |

### Authorization Policies

**Istio AuthorizationPolicy Examples:**

- **KServe InferenceServices**: CUSTOM action delegates to Authorino, which validates:
  - Kubernetes token via TokenReview API
  - User permission via SubjectAccessReview (GET permission on InferenceService)

- **Model Registry**: Similar pattern with GET permission on Service resource

**OpenShift OAuth Authorization:**

- Notebooks: User must have GET permission on Notebook resource via `--openshift-sar` flag
- Dashboard: User must be able to list projects
- Prometheus: Cluster monitoring view role

**Kubernetes RBAC:**

- Standard Kubernetes RBAC for all operator ServiceAccounts
- User permissions checked via SubjectAccessReview for sensitive operations
- Namespace-based isolation for multi-tenancy

## Platform APIs

### Custom Resource Definitions

| Component | API Group | Kind | Scope | Purpose |
|-----------|-----------|------|-------|---------|
| rhods-operator | datasciencecluster.opendatahub.io | DataScienceCluster | Cluster | Main platform configuration |
| rhods-operator | dscinitialization.opendatahub.io | DSCInitialization | Cluster | Platform initialization |
| rhods-operator | components.platform.opendatahub.io | Dashboard, Workbenches, Kserve, ModelMeshServing, DataSciencePipelines, Ray, CodeFlare, TrustyAI, TrainingOperator, Kueue, ModelRegistry, ModelController | Cluster | Component configurations |
| odh-dashboard | dashboard.opendatahub.io | OdhApplication, OdhDocument, AcceleratorProfile, HardwareProfile | Namespaced | Dashboard resources |
| odh-dashboard | console.openshift.io | OdhQuickStart | Namespaced | Interactive tutorials |
| kubeflow-notebook-controller | kubeflow.org | Notebook | Namespaced | Jupyter notebook instances |
| kserve | serving.kserve.io | InferenceService, ServingRuntime, ClusterServingRuntime, InferenceGraph, TrainedModel | Namespaced/Cluster | Model serving |
| modelmesh-serving | serving.kserve.io | Predictor | Namespaced | ModelMesh predictors |
| model-registry-operator | modelregistry.opendatahub.io | ModelRegistry | Namespaced | Model registry instances |
| data-science-pipelines | datasciencepipelinesapplications.opendatahub.io | DataSciencePipelinesApplication | Namespaced | Pipeline deployments |
| data-science-pipelines | argoproj.io | Workflow, WorkflowTemplate, CronWorkflow | Namespaced | Argo workflow resources |
| kuberay | ray.io | RayCluster, RayJob, RayService | Namespaced | Ray distributed computing |
| codeflare-operator | workload.codeflare.dev | AppWrapper | Namespaced | Gang scheduling wrapper |
| kueue | kueue.x-k8s.io | ClusterQueue, LocalQueue, Workload, ResourceFlavor, WorkloadPriorityClass, AdmissionCheck | Cluster/Namespaced | Job queueing |
| training-operator | kubeflow.org | PyTorchJob, TFJob, MPIJob, XGBoostJob, MXJob, PaddleJob | Namespaced | Distributed training |
| trustyai-service-operator | trustyai.opendatahub.io | TrustyAIService, LMEvalJob | Namespaced | AI explainability and LLM eval |
| odh-model-controller | nim.opendatahub.io | Account | Namespaced | NVIDIA NIM accounts |

**Total CRDs**: 40+ custom resource definitions across the platform

### Public HTTP Endpoints (External Access)

| Component | Path Pattern | Method | Port | Protocol | Auth | Purpose |
|-----------|-------------|--------|------|----------|------|---------|
| odh-dashboard | /* | GET, POST, PUT, DELETE | 8443/TCP | HTTPS | OpenShift OAuth | Web UI and API |
| Notebooks | /lab/*, /api/* | GET, POST | 8888/TCP | HTTP (via Route HTTPS) | OAuth or Token | JupyterLab interface |
| RayCluster | / (dashboard) | GET | 8265/TCP | HTTP (via Route HTTPS) | OAuth | Ray dashboard UI |
| KServe InferenceService | /v1/models/:model/infer, /v2/models/:model/infer | POST | 443/TCP (Gateway) | HTTPS | Bearer Token (Authorino) | Model inference |
| ModelMesh | /v2/models/:model/infer | POST | 8008/TCP (via Route) | HTTP (via Route HTTPS) | Optional | Multi-model inference |
| Model Registry | /api/model_registry/v1alpha3/* | GET, POST, PUT, DELETE | 443/TCP (Gateway) | HTTPS | Bearer Token (Authorino) | Model metadata API |
| Data Science Pipelines | /apis/v2beta1/*, /apis/v1beta1/* | GET, POST, DELETE | 8443/TCP (via Route) | HTTPS | OAuth | Pipeline API |
| TrustyAI | /q/metrics | GET | 8080/TCP (via Route) | HTTP (via Route HTTPS) | OAuth | Fairness metrics |

### Internal gRPC Services

| Component | Service | Port | Protocol | Encryption | Purpose |
|-----------|---------|------|----------|------------|---------|
| KServe | inference.GRPCInferenceService | 9000/TCP | gRPC | Optional mTLS | V2 inference protocol |
| ModelMesh | inference.GRPCInferenceService | 8033/TCP | gRPC | None (cluster-local) | ModelMesh inference |
| Model Registry | ML Metadata gRPC API | 9090/TCP | gRPC | mTLS (Istio) or None | Model metadata operations |
| Data Science Pipelines | ml-pipeline | 8887/TCP | gRPC | mTLS (optional) | Pipeline execution API |

## Data Flows

### Key Platform Workflows

#### Workflow 1: Interactive Model Development to Deployment

| Step | Component | Action | Next Component |
|------|-----------|--------|----------------|
| 1 | Dashboard | User creates Data Science Project (namespace) | Kubernetes API |
| 2 | Dashboard | User launches Jupyter Workbench | odh-notebook-controller |
| 3 | odh-notebook-controller | Creates Notebook CR with OAuth proxy | kubeflow-notebook-controller |
| 4 | kubeflow-notebook-controller | Deploys notebook pod with PVC | Workbench Images |
| 5 | User | Develops and trains model in Jupyter | S3 Storage (saves model) |
| 6 | Dashboard | User creates InferenceService | kserve |
| 7 | kserve | Downloads model, creates deployment | odh-model-controller |
| 8 | odh-model-controller | Creates Route, Istio Gateway, AuthConfig | Istio, Authorino |
| 9 | Client | Sends inference request | InferenceService Pod |
| 10 | TrustyAI (optional) | Monitors predictions for bias | Prometheus (metrics) |

#### Workflow 2: Distributed Training Job

| Step | Component | Action | Next Component |
|------|-----------|--------|----------------|
| 1 | User | Submits PyTorchJob manifest | training-operator |
| 2 | training-operator | Validates via webhook | Kubernetes API |
| 3 | kueue | Queues PyTorchJob | - |
| 4 | kueue | Admits PyTorchJob when resources available | training-operator |
| 5 | training-operator | Creates PodGroup for gang scheduling | Volcano/Scheduler-Plugins |
| 6 | Gang Scheduler | Schedules all pods atomically | Kubernetes Scheduler |
| 7 | PyTorchJob Pods | Execute distributed training | S3 Storage (checkpoint) |
| 8 | PyTorchJob Pods | Save final model | S3 Storage |
| 9 | model-registry-operator | Register trained model (optional) | PostgreSQL/MySQL |

#### Workflow 3: Data Science Pipeline Execution

| Step | Component | Action | Next Component |
|------|-----------|--------|----------------|
| 1 | Dashboard | User uploads pipeline YAML | data-science-pipelines |
| 2 | Data Science Pipelines | Creates Argo Workflow | Argo Workflows |
| 3 | Argo Workflow Controller | Schedules pipeline steps as pods | Kubernetes API |
| 4 | Pipeline Step Pod | Preprocesses data | S3 Storage |
| 5 | Pipeline Step Pod | Trains model | S3 Storage |
| 6 | Pipeline Step Pod | Validates model | - |
| 7 | Pipeline Step Pod | Creates InferenceService CR | kserve |
| 8 | kserve | Deploys model | InferenceService deployment |
| 9 | Data Science Pipelines | Records execution metadata | MariaDB |
| 10 | Pipeline Step Pod (optional) | Registers model | model-registry |

#### Workflow 4: Ray Distributed Computing

| Step | Component | Action | Next Component |
|------|-----------|--------|----------------|
| 1 | User | Creates RayCluster CR | kuberay |
| 2 | codeflare-operator | Injects security (OAuth, mTLS, NetworkPolicy) | kuberay |
| 3 | kuberay | Creates Ray head and worker pods | Kubernetes API |
| 4 | codeflare-operator | Creates Route for Ray dashboard | OpenShift Router |
| 5 | User | Submits Ray job via client | Ray Head Service |
| 6 | Ray Head | Distributes tasks | Ray Workers |
| 7 | Ray Workers | Execute distributed computation | S3 Storage (results) |
| 8 | Ray Autoscaler | Scales workers based on load | kuberay |
| 9 | Prometheus | Scrapes Ray metrics | Ray Head Pod |

#### Workflow 5: Multi-Model Serving with ModelMesh

| Step | Component | Action | Next Component |
|------|-----------|--------|----------------|
| 1 | User | Creates Predictor CRs (multiple models) | modelmesh-serving |
| 2 | modelmesh-serving | Deploys ModelMesh runtime pods | ModelMesh Router |
| 3 | modelmesh-serving | Creates Route for inference endpoint | OpenShift Router |
| 4 | ModelMesh Runtime Pods | Download models from S3 | S3 Storage |
| 5 | ModelMesh Router | Loads models into runtime servers | Runtime Adapter |
| 6 | Client | Sends inference request | ModelMesh Service |
| 7 | ModelMesh Router | Routes to appropriate loaded model | Runtime Server (Triton/MLServer) |
| 8 | Runtime Server | Returns prediction | Client |
| 9 | ModelMesh Router | Manages model placement | etcd (state) |

## Deployment Architecture

### Deployment Topology

```
Red Hat OpenShift Cluster
│
├── redhat-ods-operator (Namespace)
│   └── rhods-operator (Deployment, 1 replica)
│       └── Manages all platform components via DataScienceCluster CR
│
├── redhat-ods-applications (Namespace)
│   ├── odh-dashboard (Deployment, 2 replicas with anti-affinity)
│   ├── odh-notebook-controller (Deployment, 1 replica)
│   ├── kserve-controller-manager (Deployment, 1 replica)
│   ├── modelmesh-controller (Deployment, 1 replica)
│   ├── odh-model-controller (Deployment, 1 replica)
│   ├── model-registry-operator (Deployment, 1 replica)
│   ├── training-operator (Deployment, 1 replica)
│   └── trustyai-service-operator (Deployment, 1 replica)
│
├── opendatahub (Namespace)
│   ├── data-science-pipelines-operator (Deployment, 1 replica)
│   ├── kuberay-operator (Deployment, 1 replica)
│   ├── codeflare-operator-manager (Deployment, 1 replica)
│   └── kueue-controller-manager (Deployment, 1 replica)
│
├── redhat-ods-monitoring (Namespace)
│   ├── prometheus (StatefulSet, 2 replicas)
│   ├── alertmanager (StatefulSet, 3 replicas)
│   └── blackbox-exporter (Deployment, 1 replica)
│
├── istio-system (Namespace)
│   ├── istiod (Deployment, 2 replicas)
│   ├── istio-ingressgateway (Deployment, 2+ replicas)
│   └── istio-egressgateway (Deployment, optional)
│
└── User Data Science Projects (Namespaces: {user-project-name})
    ├── Notebook Pods (StatefulSets, per user)
    ├── InferenceService Pods (Knative Services or Deployments)
    ├── ModelMesh Runtime Pods (Deployments)
    ├── RayCluster Pods (Ray Head + Workers)
    ├── Training Job Pods (PyTorchJob, TFJob, etc.)
    ├── Data Science Pipelines (per-namespace DSPA stack)
    ├── TrustyAI Service (Deployment with OAuth proxy)
    └── Model Registry (optional per-namespace instance)
```

### Resource Requirements (Operators)

| Component | CPU Request | CPU Limit | Memory Request | Memory Limit | Replicas |
|-----------|-------------|-----------|----------------|--------------|----------|
| rhods-operator | - | - | - | - | 1 |
| odh-dashboard | 500m | 1000m | 1Gi | 2Gi | 2 |
| odh-notebook-controller | 500m | 500m | 256Mi | 4Gi | 1 |
| kserve-controller | - | - | - | - | 1 |
| modelmesh-controller | 50m | 1 | 96Mi | 512Mi | 1 |
| odh-model-controller | 10m | 500m | 64Mi | 2Gi | 1 |
| model-registry-operator | - | - | - | - | 1 |
| data-science-pipelines-operator | 200m | 1 | 400Mi | 4Gi | 1 |
| kuberay-operator | - | - | - | - | 1 |
| codeflare-operator | 1 | 1 | 1Gi | 1Gi | 1 |
| kueue-controller | 500m | 2 | 512Mi | 512Mi | 1 |
| training-operator | - | - | - | - | 1 |
| trustyai-service-operator | - | - | - | - | 1 |

**Note**: Some operators do not specify resource requests/limits in their base manifests.

### Resource Requirements (Runtime Components)

**Per-User Workbench**: 2Gi memory minimum, GPU variants require GPU node selectors

**InferenceService (KServe)**: Varies by model size, typically 1-4 CPU, 2-8Gi memory

**ModelMesh Runtime Pod**:
- modelmesh container: 300m CPU, 448Mi memory
- rest-proxy: 50m CPU, 96Mi memory
- Model server (Triton/MLServer): 500m-5 CPU, 1-8Gi memory

**RayCluster**:
- Ray Head: Configurable, typically 1-2 CPU, 2-4Gi memory
- Ray Worker: Configurable, scales with workload

**Training Job**: Highly variable, distributed jobs can span multiple nodes with GPUs

**Data Science Pipelines (per namespace)**:
- API Server: Configurable
- MariaDB: 10Gi PVC (default)
- Minio: 10Gi PVC (default)

## Version-Specific Changes (RHOAI 2.17)

| Component | Notable Changes |
|-----------|-----------------|
| codeflare-operator | - Update Konflux references<br>- Update UBI8 base images<br>- Registry and build configuration updates |
| data-science-pipelines-operator | - Konflux references updates<br>- CVE resolution: glog to 1.2.4 (CVE-2024-45339)<br>- RHOAI 2.17 release preparation |
| kserve | - Konflux component updates for kserve-controller-217, kserve-router-217<br>- Security fix: path traversal vulnerability in createNewFile<br>- OAuth proxy integration for RHOAI 2.17 |
| kubeflow (ODH Notebook Controller) | - Update UBI8 minimal base image digest<br>- Add repo IDs to CPE mapping<br>- Bump golang.org/x/net dependency (security)<br>- Integration of Codecov coverage reporting |
| kuberay | - Konflux references updates<br>- UBI8 base image security updates<br>- RHOAI 2.17 release preparation |
| kueue | - Konflux references updates<br>- Update UBI8 Go toolset base image<br>- Update UBI8 minimal runtime image |
| modelmesh-serving | - Stable release branch (rhoai-2.17)<br>- No commits in last 3 months (frozen for release)<br>- Based on upstream kserve/modelmesh-serving v0.11.0 |
| model-registry-operator | - Extensive Konflux references updates<br>- Update UBI8 minimal base image digest |
| notebooks (workbench images) | - RHOAIENG-17368: Update package versions for 2.16.1 support<br>- Update poetry.lock, Pipfile.lock files<br>- RStudio source build branch updates<br>- Kubeflow Pipelines SDK added to dependencies |
| odh-dashboard | - Konflux SA migration<br>- Update Konflux references<br>- Update UBI8 nodejs-18 docker digest |
| odh-model-controller | - Konflux references updates<br>- Update UBI9 Go toolset base image<br>- RHOAI 2.17 release preparation |
| rhods-operator | - Updating operator repo with latest images and manifests<br>- odh-dashboard-v2-17 updates<br>- odh-trustyai-service-operator-v2-17 updates |
| training-operator | - Component metadata for RHOAI 2.17<br>- Konflux build pipeline integration<br>- UBI9 base image updates<br>- Multi-arch manifest support |
| trustyai-service-operator | - Update Konflux references (multiple commits)<br>- RHOAI 2.17 release preparation |

**Common Theme**: Most components received Konflux CI/CD pipeline updates, UBI8/UBI9 base image security updates, and release branch stabilization for RHOAI 2.17.

## Platform Maturity

### Component Statistics

- **Total Components**: 14 (1 platform operator + 13 specialized operators/services)
- **Operator-based Components**: 13 (93% operator-managed)
- **Container Images**: 50+ (including operators, runtimes, workbench variants)
- **CRDs**: 40+ custom resource definitions
- **Namespaces**: 4 platform namespaces + user project namespaces

### Service Mesh Coverage

- **Enabled Components**: KServe (serverless mode), Model Registry, Data Science Pipelines (optional)
- **mTLS Enforcement**: STRICT for KServe pods in mesh, ISTIO_MUTUAL for Model Registry
- **Coverage**: ~35-40% of components (model serving and registry services)
- **Gateway Integration**: Istio Gateway for InferenceServices and Model Registry

### CRD API Versions

- **v1**: InferenceService, Notebook, PyTorchJob, TFJob, RayCluster, DataScienceCluster, DSCInitialization
- **v1beta1**: Many KServe and Kueue resources
- **v1beta2**: AppWrapper (CodeFlare)
- **v1alpha1**: Many component resources (Dashboard, Model Registry, TrustyAI, etc.)
- **v1alpha**: Serving runtimes, InferenceGraph

### Security Posture

- **TLS Encryption**: HTTPS for all external endpoints, optional mTLS for internal service-to-service
- **Authentication**: OpenShift OAuth for user access, ServiceAccount tokens for operators, optional Authorino for inference endpoints
- **Authorization**: Kubernetes RBAC enforced, SubjectAccessReview checks for sensitive operations
- **Network Policies**: Deployed for operators, notebooks, and model serving components
- **Pod Security**: Non-root users, no privilege escalation, capabilities dropped
- **Secret Management**: Kubernetes Secrets with OpenShift Service CA for auto-rotation

### Build and Release

- **Build System**: Konflux CI/CD for all RHOAI components
- **Base Images**: UBI8 (most components) and UBI9 (newer components) for FIPS compliance
- **FIPS Compliance**: CGO-enabled builds with strictfipsruntime tags
- **Image Registries**: registry.redhat.io (production), quay.io (development/ODH)
- **Versioning**: Git commit-based tags for traceability

## Next Steps for Documentation

1. **Generate Architecture Diagrams**
   - Platform-level component diagram showing all 14 components and dependencies
   - Network flow diagrams for key workflows (5 workflows documented above)
   - Security architecture diagram showing authentication/authorization flows
   - Deployment topology diagram for multi-namespace architecture

2. **Update Architecture Decision Records (ADRs)**
   - Document decision to use Konflux for all RHOAI builds
   - Document service mesh integration strategy (Istio for model serving only)
   - Document authentication approach (OpenShift OAuth + Authorino for external access)
   - Document namespace topology (applications, monitoring, operator separation)

3. **Create User-Facing Documentation**
   - Getting Started guides for each workflow (development, training, serving)
   - Component integration guides (e.g., how KServe + Model Registry + TrustyAI work together)
   - Security best practices for multi-tenant deployments
   - Troubleshooting guides for common issues

4. **Generate Security Architecture Review (SAR) Materials**
   - Network security diagrams showing ingress/egress paths
   - Authentication/authorization matrix for all endpoints
   - Secrets and certificate management documentation
   - Threat model for multi-tenant ML platform
   - Compliance documentation (FIPS, pod security standards)

5. **Performance and Scalability Documentation**
   - Benchmark results for model serving (KServe vs ModelMesh)
   - Distributed training performance characteristics
   - Resource consumption profiles for different workload types
   - Horizontal scaling capabilities and limits

6. **Upgrade and Migration Guides**
   - Upgrade paths from RHOAI 2.16 to 2.17
   - Breaking changes and migration procedures
   - Backup and restore procedures for platform components
   - Component compatibility matrix
