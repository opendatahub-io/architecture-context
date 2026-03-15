# Platform: Red Hat OpenShift AI 2.6

## Metadata
- **Distribution**: RHOAI
- **Version**: 2.6
- **Base Platform**: OpenShift Container Platform 4.11+
- **Components Analyzed**: 10
- **Analysis Date**: 2026-03-15

## Platform Overview

Red Hat OpenShift AI (RHOAI) 2.6 is an enterprise-grade machine learning platform that provides a complete suite of tools for the entire ML lifecycle—from data preparation and model development through training, serving, and monitoring. The platform extends OpenShift with data science capabilities including interactive Jupyter notebook environments, distributed workload orchestration with Ray and CodeFlare, ML pipeline management via Kubeflow Pipelines with Tekton backend, and production model serving through both KServe (single-model) and ModelMesh (multi-model) frameworks.

RHOAI integrates deeply with OpenShift's security model, leveraging OAuth for authentication, RBAC for authorization, Routes for ingress, and optionally OpenShift Service Mesh for mTLS and advanced traffic management. The platform is orchestrated by the RHODS Operator, which manages component lifecycles through declarative DataScienceCluster custom resources. All components share a common architecture pattern of Kubernetes operators managing custom resources, with centralized monitoring via Prometheus and unified access control through OpenShift OAuth.

The platform supports GPU acceleration (NVIDIA CUDA, Habana AI), distributed computing frameworks (Ray, Spark), multiple ML frameworks (PyTorch, TensorFlow, scikit-learn, XGBoost), and provides observability through TrustyAI for model fairness and explainability monitoring.

## Component Inventory

| Component | Type | Version | Purpose |
|-----------|------|---------|---------|
| RHODS Operator | Platform Orchestrator | v1.6.0-391 | Manages lifecycle of all RHOAI components via DataScienceCluster CRD |
| ODH Dashboard | Web Frontend | v1.27.0-rhods | User interface for managing workbenches, pipelines, models, and data connections |
| Notebook Controller | Kubernetes Controller | v1.27.0-rhods-237 | Extends Kubeflow notebooks with OpenShift Routes and OAuth authentication |
| Notebook Images | Container Images | v1.1.1-312 | Pre-built Jupyter, code-server, and RStudio environments with ML libraries |
| Data Science Pipelines Operator | Kubernetes Operator | rhoai-2.6 (025e77a) | Deploys and manages Kubeflow Pipelines with Tekton backend for ML workflows |
| KServe | Kubernetes Operator | v0.11.1 (7418735ff) | Serverless model serving with Knative and Istio for single-model deployments |
| ModelMesh Serving | Kubernetes Operator | v1.27.0-rhods-169 | High-density multi-model serving with intelligent caching and routing |
| ODH Model Controller | Kubernetes Controller | v1.27.0-rhods-153 | Bridges KServe/ModelMesh with OpenShift networking, monitoring, and security |
| CodeFlare Operator | Kubernetes Operator | cff798d | Manages distributed workloads with MCAD queue scheduling and InstaScale auto-scaling |
| KubeRay | Kubernetes Operator | 43912490 | Deploys and manages Ray clusters for distributed ML workloads |
| TrustyAI Service Operator | Kubernetes Operator | e9bffad | Provides model fairness monitoring and explainability services |

## Component Relationships

### Dependency Graph

```
RHODS Operator (Platform Orchestrator)
├── ODH Dashboard (User Interface)
│   ├── Data Science Pipelines API (pipeline management)
│   ├── Model Registry MLMD (artifact tracking)
│   └── Storage configuration (S3 credentials)
│
├── Notebook Controller (Workbench Management)
│   ├── Notebook Images (container images)
│   ├── OpenShift OAuth (authentication)
│   ├── OpenShift Routes (ingress)
│   └── Data Science Pipelines API (Elyra integration)
│
├── Data Science Pipelines Operator
│   ├── Tekton/OpenShift Pipelines (execution engine)
│   ├── MariaDB or external DB (metadata storage)
│   ├── Minio or S3 (artifact storage)
│   └── ML Metadata gRPC (lineage tracking)
│
├── KServe
│   ├── Knative Serving (serverless autoscaling)
│   ├── Istio Service Mesh (traffic routing, mTLS)
│   ├── ODH Model Controller (OpenShift integration)
│   └── S3 Storage (model artifacts)
│
├── ModelMesh Serving
│   ├── etcd (model registry state)
│   ├── ODH Model Controller (OpenShift integration)
│   └── S3 Storage (model artifacts)
│
├── ODH Model Controller
│   ├── KServe InferenceServices (watched resource)
│   ├── ModelMesh InferenceServices (watched resource)
│   ├── OpenShift Routes (creates ingress)
│   ├── OpenShift Service Mesh (configures mTLS)
│   └── Prometheus (creates ServiceMonitors)
│
├── CodeFlare Operator
│   ├── MCAD (embedded queue controller)
│   ├── InstaScale (optional auto-scaler)
│   ├── KubeRay (creates RayClusters in AppWrappers)
│   └── OpenShift Machine API (optional node scaling)
│
├── KubeRay
│   ├── Ray Framework (distributed compute)
│   └── Volcano Scheduler (optional gang scheduling)
│
└── TrustyAI Service Operator
    ├── KServe InferenceServices (monitors for bias)
    ├── Prometheus (exports fairness metrics)
    └── OpenShift OAuth (secures access)
```

### Central Components

**RHODS Operator**: Core platform orchestrator with broadest privileges. All other components are deployed and managed through this operator's DataScienceCluster reconciliation.

**ODH Model Controller**: Integration hub for model serving. Bridges KServe and ModelMesh with OpenShift features (Routes, Service Mesh, Prometheus). Critical for external model access.

**Data Science Pipelines API**: Central workflow orchestration. Consumed by ODH Dashboard, Notebook Elyra extension, and external CI/CD systems.

**OpenShift Service Mesh (Istio)**: When enabled, provides service-to-service mTLS, traffic routing for KServe canary deployments, and unified authorization via Authorino.

**Prometheus**: Platform-wide monitoring. All operators expose metrics, and ODH Model Controller configures monitoring for InferenceServices.

### Integration Patterns

1. **CRD Creation**: Operators create and watch custom resources from other components
   - Example: CodeFlare creates RayCluster CRs watched by KubeRay operator
   - Example: Data Science Pipelines creates Tekton PipelineRun CRs

2. **API Calls**: HTTP/gRPC calls to service endpoints
   - Example: ODH Dashboard calls Data Science Pipelines API for pipeline management
   - Example: Notebooks call MLMD gRPC for artifact lineage

3. **Resource Patching**: Controllers modify resources created by other operators
   - Example: Notebook Controller injects OAuth proxy into Notebook pods
   - Example: ODH Model Controller creates Routes for InferenceServices

4. **Secret Sharing**: Aggregation of credentials for cross-component access
   - Example: ODH Model Controller aggregates data connection secrets into storage-config
   - Example: RHODS Operator generates OAuth client secrets for components

5. **Event Watching**: Controllers watch Kubernetes events from other components
   - Example: TrustyAI watches InferenceService create/update events
   - Example: ODH Model Controller watches ServingRuntime to find ports

## Platform Network Architecture

### Namespaces

| Namespace | Purpose | Components |
|-----------|---------|------------|
| redhat-ods-operator | Operator control plane | RHODS Operator controller-manager |
| redhat-ods-applications | Application services | ODH Dashboard, Notebook Controller, Model Controllers, Component operators |
| redhat-ods-monitoring | Platform observability | Prometheus, Alertmanager, Blackbox Exporter, Grafana |
| istio-system | Service mesh control plane | Service Mesh Control Plane (optional) |
| openshift-operators | Global operators | Data Science Pipelines Operator, TrustyAI Operator, CodeFlare Operator, KubeRay |
| {user-namespaces} | User workloads | Notebook pods, InferenceServices, Pipeline runs, Ray clusters |

### External Ingress Points

| Component | Ingress Type | Hosts | Port | Protocol | Encryption | Purpose |
|-----------|--------------|-------|------|----------|------------|---------|
| ODH Dashboard | OpenShift Route | rhods-dashboard-{namespace}.{cluster-domain} | 443/TCP | HTTPS | TLS 1.2+ (edge) | Web UI for platform management |
| Prometheus | OpenShift Route | prometheus-{namespace}.{cluster-domain} | 443/TCP | HTTPS | TLS 1.2+ (edge) | Metrics visualization and alerting UI |
| Alertmanager | OpenShift Route | alertmanager-{namespace}.{cluster-domain} | 443/TCP | HTTPS | TLS 1.2+ (edge) | Alert management UI |
| Notebook | OpenShift Route | {notebook-name}-{namespace}.{cluster-domain} | 443/TCP | HTTPS | TLS 1.2+ (re-encrypt) | Jupyter/code-server/RStudio IDE access |
| Data Science Pipeline API | OpenShift Route | ds-pipeline-{name}-{namespace}.{cluster-domain} | 443/TCP | HTTPS | TLS 1.2+ (re-encrypt) | Pipeline API and UI access |
| KServe InferenceService | OpenShift Route | {isvc-name}-{namespace}.{cluster-domain} | 443/TCP | HTTPS | TLS 1.2+ (edge) | Model inference endpoint |
| ModelMesh InferenceService | OpenShift Route | {isvc-name}-{namespace}.{cluster-domain} | 443/TCP | HTTPS | TLS 1.2+ (edge) | Multi-model inference endpoint |
| TrustyAI Service | OpenShift Route | {trustyai-name}-{namespace}.{cluster-domain} | 443/TCP | HTTPS | TLS 1.2+ (passthrough) | Bias monitoring and explainability API |
| Ray Dashboard | OpenShift Route/Ingress | {raycluster}-{namespace}.{cluster-domain} | 443/TCP | HTTPS | TLS 1.2+ (optional) | Ray cluster monitoring UI |

**Authentication**: All external Routes use OpenShift OAuth (Bearer Token) except where noted otherwise.

### External Egress Dependencies

| Component | Destination | Port | Protocol | Encryption | Purpose |
|-----------|-------------|------|----------|------------|---------|
| All operators | Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | Watch resources, reconciliation |
| All components | quay.io, registry.redhat.io | 443/TCP | HTTPS | TLS 1.2+ | Container image pulls |
| Storage Initializers | AWS S3, MinIO, GCS, Azure Blob | 443/TCP | HTTPS | TLS 1.2+ | Model and data artifact storage |
| Data Science Pipelines | External MariaDB/PostgreSQL | 3306/5432 TCP | MySQL/PostgreSQL | TLS 1.2+ (optional) | Pipeline metadata storage |
| Notebooks | PyPI (pypi.org) | 443/TCP | HTTPS | TLS 1.2+ | Python package installation |
| Notebooks | External databases | 3306/5432/1433/27017 TCP | MySQL/PostgreSQL/MSSQL/MongoDB | TLS optional | Data access for ML workflows |
| ModelMesh | etcd cluster | 2379/TCP | HTTPS | TLS 1.2+ | Model registry state |
| InstaScale (optional) | Cloud Provider API | 443/TCP | HTTPS | TLS 1.2+ | Auto-scaling nodes via Machine API |
| Service Mesh | Certificate Authority | 443/TCP | HTTPS | TLS 1.2+ | Certificate issuance for mTLS |

### Internal Service Mesh

| Setting | Value | Components Using | Configuration Point |
|---------|-------|------------------|---------------------|
| mTLS Mode | PERMISSIVE (default) or STRICT | KServe InferenceServices, Data Science Pipelines | PeerAuthentication per namespace |
| Ingress Gateway | istio-ingressgateway | KServe external traffic | VirtualService routing |
| Sidecar Injection | Automatic (label-based) | Namespaces with label `opendatahub.io/generated-namespace: true` | ServiceMeshMemberRoll |
| Traffic Management | VirtualService routing | KServe canary deployments, A/B testing | Created by KServe controller |
| External Authorization | Authorino (optional) | InferenceServices with auth policies | AuthorizationPolicy CRs |

## Platform Security

### RBAC Summary

**Cluster-Level Permissions** (Selected high-privilege roles):

| Component | ClusterRole Highlights | Critical Resources | Justification |
|-----------|------------------------|-------------------|---------------|
| RHODS Operator | Full CRUD on all component CRDs, RBAC resources, CRDs | datascienceclusters, dscinitializations, ClusterRoles, CRDs | Platform orchestrator needs cluster-wide control |
| Data Science Pipelines Operator | Full control of Tekton, Kubeflow, Ray, Seldon, AppWrappers | tekton.dev/*, kubeflow.org/*, ray.io/*, appwrappers | Pipeline workflows can deploy diverse ML workloads |
| ODH Model Controller | InferenceServices, Routes, Service Mesh resources, NetworkPolicies | inferenceservices, virtualservices, networkpolicies | Model serving integration with OpenShift features |
| KServe | InferenceServices, Knative Services, Istio VirtualServices | inferenceservices, knative services, virtualservices | Serverless model serving orchestration |
| CodeFlare Operator | AppWrappers, MachineSets (InstaScale), RayClusters, Routes | appwrappers, machinesets, rayclusters | Distributed workload and cluster auto-scaling |
| KubeRay | RayClusters, RayJobs, RayServices, Routes | rayclusters, rayjobs, rayservices | Ray cluster lifecycle management |
| TrustyAI Operator | InferenceServices (watch and patch), TrustyAIServices | inferenceservices, trustyaiservices | Model monitoring integration |

**Namespace-Level Permissions** (User-facing RBAC):

| Role | API Groups | Resources | User Workflow |
|------|-----------|-----------|---------------|
| ODH Notebook Admin | kubeflow.org | notebooks (all verbs) | Create/delete Jupyter notebooks |
| DSPA Admin | datasciencepipelinesapplications.opendatahub.io | datasciencepipelinesapplications (all verbs) | Deploy pipeline infrastructure |
| Model Admin | serving.kserve.io | inferenceservices, servingruntimes | Deploy and manage models |
| AppWrapper Admin | workload.codeflare.dev | appwrappers | Submit distributed workloads |

### Secrets Inventory

| Component | Secret Name Pattern | Type | Purpose |
|-----------|---------------------|------|---------|
| RHODS Operator | {component}-oauth-client | Opaque | OAuth client credentials for component authentication |
| RHODS Operator | prometheus-proxy-tls, alertmanager-proxy-tls | kubernetes.io/tls | OAuth proxy TLS for monitoring UIs |
| Notebook Controller | {notebook-name}-oauth-config | Opaque | OAuth proxy cookie secret |
| Notebook Controller | {notebook-name}-tls | kubernetes.io/tls | TLS cert for OAuth service (auto-rotated by Service CA) |
| Data Science Pipelines | ds-pipelines-proxy-tls-{name} | kubernetes.io/tls | OAuth proxy TLS for API/UI |
| Data Science Pipelines | mariadb-{name} | Opaque | Database root password |
| Data Science Pipelines | {storage-secret-name} | Opaque | S3/Minio credentials |
| KServe | storage-config | Opaque | S3/GCS/Azure credentials for model downloads |
| ModelMesh | model-serving-etcd | Opaque | etcd connection credentials |
| ModelMesh | modelmesh-webhook-server-cert | kubernetes.io/tls | Webhook TLS certificate |
| ODH Model Controller | storage-config | Opaque | Aggregated S3 credentials from data connections |
| TrustyAI | {instance-name}-tls | kubernetes.io/tls | OAuth proxy TLS (auto-rotated) |

**Auto-Rotation**: Secrets provisioned by OpenShift Service CA (*.io/tls with serving-cert-secret-name annotation) auto-rotate every 90 days.

### Authentication Mechanisms

| Pattern | Components Using | Enforcement Point | Token Type |
|---------|------------------|-------------------|------------|
| Bearer Tokens (JWT) - OpenShift OAuth | Dashboard, Notebooks, Pipelines UI, Prometheus, Alertmanager, TrustyAI | OAuth Proxy sidecar | OpenShift user token |
| Bearer Tokens - Service Accounts | All operators, internal service-to-service | Kubernetes API Server | ServiceAccount JWT |
| mTLS Client Certificates | KServe (optional), ModelMesh (optional) | Istio Envoy sidecar | x.509 client certs issued by service mesh |
| AWS IAM Credentials | Storage initializers (KServe, ModelMesh, Pipelines) | S3-compatible storage | AWS Signature v4 HMAC |
| Database Credentials | Data Science Pipelines, MLMD, ModelMesh | Database server | Username/password from secrets |
| SubjectAccessReview | Notebook OAuth, TrustyAI OAuth | OAuth proxy via Kubernetes API | Kubernetes RBAC check |

### Authorization Policies

| Policy Type | Scope | Enforcement | Example |
|-------------|-------|-------------|---------|
| Kubernetes RBAC | Cluster and Namespace | Kubernetes API Server | ClusterRoles for operators, Roles for user workloads |
| Network Policies | Namespace | CNI (OpenShift SDN/OVN) | Allow ingress from monitoring namespaces, block cross-namespace |
| Istio AuthorizationPolicy | Service Mesh | Istio Envoy sidecar | JWT validation, request header checks for InferenceServices |
| OAuth Proxy SAR | Route endpoints | OpenShift OAuth Proxy | User must have GET permission on notebook/service resource |
| Security Context Constraints | Pod | OpenShift admission | Restricted SCC (non-root, no capabilities) for all workloads |

## Platform APIs

### Custom Resource Definitions

| Component | API Group | Kind | Scope | Purpose |
|-----------|-----------|------|-------|---------|
| RHODS Operator | datasciencecluster.opendatahub.io | DataScienceCluster | Cluster | Platform component configuration |
| RHODS Operator | dscinitialization.opendatahub.io | DSCInitialization | Cluster | Platform initialization settings |
| RHODS Operator | features.opendatahub.io | FeatureTracker | Cluster | Cross-namespace resource tracking |
| ODH Dashboard | dashboard.opendatahub.io | OdhDashboardConfig | Namespaced | Dashboard configuration |
| ODH Dashboard | dashboard.opendatahub.io | OdhApplication | Namespaced | Application tile definitions |
| Kubeflow | kubeflow.org | Notebook | Namespaced | Jupyter notebook instances |
| Data Science Pipelines | datasciencepipelinesapplications.opendatahub.io | DataSciencePipelinesApplication | Namespaced | Complete DSP stack configuration |
| KServe | serving.kserve.io | InferenceService | Namespaced | Model serving deployment |
| KServe | serving.kserve.io | ServingRuntime | Namespaced | Model server runtime configuration |
| KServe | serving.kserve.io | ClusterServingRuntime | Cluster | Cluster-wide runtime templates |
| KServe | serving.kserve.io | InferenceGraph | Namespaced | Multi-model inference pipelines |
| KServe | serving.kserve.io | TrainedModel | Namespaced | Model artifact references |
| ModelMesh | serving.kserve.io | Predictor | Namespaced | ModelMesh model deployment |
| CodeFlare | workload.codeflare.dev | AppWrapper | Namespaced | Distributed workload with scheduling |
| CodeFlare | quota.codeflare.dev | QuotaSubtree | Namespaced | Hierarchical quota management |
| KubeRay | ray.io | RayCluster | Namespaced | Ray cluster infrastructure |
| KubeRay | ray.io | RayJob | Namespaced | Ray job with cluster lifecycle |
| KubeRay | ray.io | RayService | Namespaced | Ray Serve deployment |
| TrustyAI | trustyai.opendatahub.io | TrustyAIService | Namespaced | Bias monitoring service |

### Public HTTP Endpoints (User-Facing)

| Component | Path | Method | Port | Protocol | Auth | Purpose |
|-----------|------|--------|------|----------|------|---------|
| ODH Dashboard | / | GET | 443/TCP (Route) | HTTPS | OAuth | Platform management UI |
| Notebook (Jupyter) | /notebook/{namespace}/{name}/lab | GET | 443/TCP (Route) | HTTPS | OAuth | JupyterLab IDE |
| Notebook (code-server) | / | GET | 443/TCP (Route) | HTTPS | OAuth/Password | VS Code IDE |
| Data Science Pipeline API | /apis/v1beta1/pipelines | GET, POST | 443/TCP (Route) | HTTPS | OAuth | Pipeline management |
| Data Science Pipeline UI | / | GET | 443/TCP (Route) | HTTPS | OAuth | Pipeline visualization |
| MLMD Envoy | / | gRPC | 9090/TCP (internal) | gRPC | NetworkPolicy | Artifact lineage (dashboard access) |
| KServe Predictor | /v1/models/{name}:predict | POST | 443/TCP (Route) | HTTPS | Optional Bearer/mTLS | Model inference (v1 protocol) |
| KServe Predictor | /v2/models/{name}/infer | POST | 443/TCP (Route) | HTTPS | Optional Bearer/mTLS | Model inference (v2 protocol) |
| ModelMesh | /v2/models/{name}/infer | POST | 443/TCP (Route) | HTTPS | None (default) | Multi-model inference |
| TrustyAI | / | ALL | 443/TCP (Route) | HTTPS | OAuth | Explainability API |
| Prometheus | / | GET | 443/TCP (Route) | HTTPS | OAuth | Metrics query UI |
| Ray Dashboard | / | GET | 443/TCP (Route) | HTTPS | Optional | Ray cluster monitoring |

### Internal gRPC Services

| Service | Port | Protocol | Encryption | Purpose |
|---------|------|----------|------------|---------|
| Data Science Pipeline API Server | 8887/TCP | gRPC/HTTP2 | TLS (internal) | Internal pipeline operations |
| MLMD gRPC Server | 8080/TCP | gRPC/HTTP2 | None | ML Metadata artifact tracking |
| MLMD Envoy Proxy | 9090/TCP | gRPC/HTTP2 | None | ODH Dashboard MLMD access |
| KServe Inference | 8081/TCP | gRPC/HTTP2 | None | Model inference (KServe v2 gRPC) |
| ModelMesh | 8085/TCP | gRPC | mTLS (optional) | Model lifecycle and inference |
| ModelMesh Storage Helper | 8086/TCP | gRPC | None | Model artifact pulling |
| KubeRay APIServer (optional) | 8887/TCP | gRPC | None | Programmatic cluster management |

## Data Flows

### Key Platform Workflows

#### Workflow 1: Notebook to Model Deployment

| Step | Component | Action | Next Component | Protocol |
|------|-----------|--------|----------------|----------|
| 1 | User | Creates Notebook CR via Dashboard | ODH Dashboard → K8s API | HTTPS |
| 2 | Notebook Controller | Watches Notebook CR, creates StatefulSet + Route | Notebook Pod | Internal |
| 3 | User | Trains model in Jupyter, saves to S3 | S3 Storage | HTTPS |
| 4 | User | Creates InferenceService CR via Dashboard | KServe Controller | HTTPS |
| 5 | KServe Controller | Creates Knative Service, storage-initializer downloads model | Model Server Pod | HTTPS (S3) |
| 6 | ODH Model Controller | Creates Route for InferenceService | OpenShift Router | Internal |
| 7 | Client | Sends inference request | Model Server | HTTPS (Route) |

#### Workflow 2: Pipeline Execution with Elyra

| Step | Component | Action | Next Component | Protocol |
|------|-----------|--------|----------------|----------|
| 1 | User | Authors pipeline in Jupyter notebook using Elyra | Notebook Pod | N/A |
| 2 | Elyra Extension | Submits pipeline to DSP API Server | Data Science Pipeline API | HTTP |
| 3 | DSP API Server | Creates Tekton PipelineRun CR | Tekton Controller | HTTP |
| 4 | Tekton Controller | Spawns pods for pipeline steps (uses runtime images) | Pipeline Step Pods | Internal |
| 5 | Pipeline Step Pods | Pull data from S3, execute code, write outputs to S3 | S3 Storage | HTTPS |
| 6 | Persistence Agent | Syncs PipelineRun status to DSP database | MariaDB | MySQL |
| 7 | MLMD Writer | Records artifact lineage in MLMD | MLMD gRPC Server | gRPC |
| 8 | User | Views pipeline results in Dashboard | ODH Dashboard → MLMD Envoy | gRPC |

#### Workflow 3: Distributed Ray Job with CodeFlare

| Step | Component | Action | Next Component | Protocol |
|------|-----------|--------|----------------|----------|
| 1 | User | Submits AppWrapper CR (wraps RayCluster + Job) via SDK | CodeFlare Operator (MCAD) | HTTPS |
| 2 | MCAD Controller | Queues AppWrapper, checks resource availability | Kubernetes API | HTTPS |
| 3 | MCAD Controller | Dispatches AppWrapper, creates RayCluster CR | KubeRay Operator | Internal |
| 4 | KubeRay Operator | Creates Ray head + worker pods | Ray Cluster Pods | Internal |
| 5 | User Job Code | Connects to Ray head, submits distributed tasks | Ray Head (port 10001) | TCP |
| 6 | Ray Head | Distributes tasks to workers, aggregates results | Ray Workers (GCS port 6379) | TCP |
| 7 | Ray Dashboard | Provides cluster monitoring UI | User Browser (via Route) | HTTPS |
| 8 | InstaScale (optional) | Scales OpenShift MachineSets if resources needed | Cloud Provider API | HTTPS |

#### Workflow 4: Model Fairness Monitoring

| Step | Component | Action | Next Component | Protocol |
|------|-----------|--------|----------------|----------|
| 1 | User | Creates TrustyAIService CR | TrustyAI Operator | HTTPS |
| 2 | TrustyAI Operator | Deploys TrustyAI service pod with OAuth proxy + PVC | TrustyAI Service | Internal |
| 3 | TrustyAI Operator | Watches InferenceServices, patches deployments with payload processor config | InferenceService Pods | HTTPS |
| 4 | InferenceService | Sends inference requests/responses to TrustyAI | TrustyAI Service (port 8080) | HTTP |
| 5 | TrustyAI Service | Calculates fairness metrics (SPD, DIR), stores to PVC | PersistentVolume | Filesystem |
| 6 | TrustyAI Service | Exposes metrics on /q/metrics endpoint | Prometheus | HTTP |
| 7 | Prometheus | Scrapes fairness metrics via ServiceMonitor | TrustyAI Metrics | HTTP |
| 8 | User | Views fairness metrics in Prometheus or Grafana | Monitoring UI | HTTPS |

#### Workflow 5: Multi-Model Serving with ModelMesh

| Step | Component | Action | Next Component | Protocol |
|------|-----------|--------|----------------|----------|
| 1 | User | Creates Predictor CR (ModelMesh mode) | ModelMesh Controller | HTTPS |
| 2 | ModelMesh Controller | Registers model in etcd, provisions serving pods if needed | etcd + ModelMesh Pods | HTTPS |
| 3 | ModelMesh Pod (Storage Helper) | Downloads model from S3 to shared pod volume | S3 Storage | HTTPS |
| 4 | ModelMesh Container | Loads model into runtime (Triton/MLServer/OpenVINO) | Runtime Adapter | gRPC |
| 5 | ODH Model Controller | Creates OpenShift Route for Predictor | OpenShift Router | Internal |
| 6 | Client | Sends inference request to Route | REST Proxy (ModelMesh pod) | HTTPS |
| 7 | REST Proxy | Translates HTTP to gRPC, forwards to ModelMesh | ModelMesh Container | gRPC |
| 8 | ModelMesh | Routes request to appropriate runtime pod | Model Runtime | gRPC |
| 9 | Runtime | Executes inference, returns prediction | Client (via reverse path) | HTTPS |

## Deployment Architecture

### Deployment Topology

**Control Plane (redhat-ods-operator namespace)**:
- RHODS Operator (1 replica, leader election)
  - CPU: 500m / Memory: 256Mi-4Gi
  - Deploys and manages all platform components

**Application Services (redhat-ods-applications namespace)**:
- ODH Dashboard (2 replicas, load balanced)
- Notebook Controller (1 replica)
- ODH Model Controller (3 replicas, leader election)
- Component operators deployed by RHODS Operator

**Monitoring (redhat-ods-monitoring namespace)**:
- Prometheus (1 replica, StatefulSet, 40Gi PVC)
- Alertmanager (1 replica, StatefulSet, 1Gi PVC)
- Blackbox Exporter (1 replica)
- Grafana (optional, 1 replica)

**User Namespaces ({project}-{user})**:
- Notebook StatefulSets (1 replica each, with OAuth proxy sidecar)
- Data Science Pipeline Application stacks (per DSPA instance)
  - API Server (1 replica)
  - Persistence Agent (1 replica)
  - Scheduled Workflow (1 replica)
  - MariaDB (1 replica, StatefulSet with PVC) or external DB
  - Minio (1 replica, StatefulSet with PVC) or external S3
  - MLMD stack (3 deployments: gRPC, Envoy, Writer)
- InferenceService Pods (KServe: managed by Knative; ModelMesh: 2+ pods per runtime)
- Ray Clusters (1 head + N workers)
- TrustyAI Services (1 replica with OAuth proxy)

### Resource Requirements

**Platform Operators** (Aggregate):
- CPU: ~2-3 cores total requests
- Memory: ~2-4 GiB total requests

**Per-User Workbench**:
- CPU: 500m default (configurable)
- Memory: 2Gi default (configurable)
- GPU: 0-8 NVIDIA GPUs (optional, Habana support)

**Per Data Science Pipeline Application**:
- CPU: ~1.5-2 cores (API + agents + workflows)
- Memory: ~2-3 GiB
- Storage: 1-10 Gi PVC (MariaDB), 5-100 Gi PVC (Minio)

**Per InferenceService**:
- KServe: 500m-4 CPU, 1-8 GiB memory (scales to zero)
- ModelMesh: 300m-1 CPU per ModelMesh pod, 500m-4 CPU per runtime

**Per Ray Cluster**:
- Head: 1 CPU, 2 GiB memory
- Workers: 1-16 CPU, 4-64 GiB memory (configurable per worker group)

**Monitoring Stack**:
- Prometheus: 1 CPU, 4 GiB memory, 40 Gi storage
- Alertmanager: 100m CPU, 256 Mi memory, 1 Gi storage

## Version-Specific Changes (2.6)

| Component | Changes |
|-----------|---------|
| RHODS Operator | - Based on upstream ODH v2.x with RHOAI downstream patches<br>- Feature framework for cross-component capabilities<br>- Enhanced DSCInitialization with service mesh integration |
| Data Science Pipelines | - Go 1.19 upgrade<br>- CA bundle injection for external DB/storage with custom TLS<br>- Security updates: gRPC/HTTP2 CVE fixes<br>- Upstream KFP 1.5 with kfp-tekton backend |
| KServe | - Based on upstream v0.11.1<br>- Authentication bypass fix (RHOAIENG-1995)<br>- DoS vulnerability fix (RHOAIENG-1943)<br>- Knative-serving dependency update<br>- SSH vulnerability fix (CVE-2023-48795) |
| Notebook Images | - Release 2023b image updates (N, N-1, N-2 versions)<br>- Code-server naming fixes<br>- Weekly Pipfile.lock security updates<br>- TrustyAI notebook UBI9 migration<br>- Habana AI support (1.9.0, 1.10.0, 1.11.0) |
| ODH Model Controller | - Network policy refinements for component traffic<br>- CVE fixes: protobuf, otelhttp, golang.org/x/crypto<br>- Monitoring stack migration job |
| CodeFlare Operator | - MCAD v1.38.1, InstaScale v0.3.1 embedded<br>- RHODS admin/editor roles merged<br>- ClusterRoles for AppWrapper management |
| KubeRay | - Kubernetes dependencies upgraded to v0.28.3<br>- Golang 1.20 upgrade<br>- High CVE fixes (grpc CVE-2023-44487)<br>- Data Science Pipelines support (RHOAIENG-2184) |
| TrustyAI | - API group renamed to trustyai.opendatahub.io<br>- OAuth for external endpoints<br>- CVE fixes: otelhttp, goproxy<br>- Unique ClusterRoleBinding names |
| ModelMesh | - Based on upstream KServe v0.11.1<br>- RHOAI 2.6 downstream patches (stable branch) |
| Notebook Controller | - RHOAI 2.6 release (v1.27.0-rhods-237)<br>- OpenShift integration enhancements |

**Security Focus**: Version 2.6 includes significant security hardening with CVE remediations across multiple components (protobuf, gRPC, otelhttp, SSH, authentication bypass).

## Platform Maturity

- **Total Components**: 10 operators/controllers + 1 platform orchestrator
- **Operator-Based Architecture**: 100% (all components use Kubernetes operator pattern)
- **Service Mesh Coverage**: Optional (KServe requires, Dashboard/Pipelines/ModelMesh can use)
- **mTLS Enforcement**: PERMISSIVE by default (can be set to STRICT for KServe namespaces)
- **CRD API Versions**:
  - v1beta1: InferenceService (KServe)
  - v1alpha1: Predictor, ServingRuntime, InferenceGraph, TrustyAIService, DSPA, OdhDashboardConfig
  - v1: DataScienceCluster, DSCInitialization, Notebook, RayCluster, RayJob, RayService
- **OpenShift Integration**: Deep (Routes, OAuth, Service CA, Security Context Constraints, Console links)
- **Monitoring Maturity**: Comprehensive (all components expose Prometheus metrics, ServiceMonitors auto-created)
- **Authentication Maturity**: Mature (OAuth for all user-facing endpoints, SubjectAccessReview for authorization)
- **Storage Abstraction**: S3-compatible (AWS S3, MinIO, GCS, Azure Blob, Ceph RGW supported)
- **GPU Support**: NVIDIA CUDA (11.8), Habana AI (1.9.0-1.11.0), planned AMD ROCm
- **Multi-Tenancy**: Namespace-scoped isolation with RBAC, NetworkPolicies, optional Service Mesh policies

**Maturity Assessment**: Enterprise-ready platform with strong security, observability, and operational capabilities. Based on mature upstream projects (Kubeflow, KServe, Ray, Tekton) with Red Hat downstream hardening.

## Platform Dependencies Summary

**External Platform Requirements**:
- OpenShift Container Platform 4.11+ (Kubernetes 1.24+)
- OpenShift Pipelines (Tekton 1.8+) - required for Data Science Pipelines
- OpenShift Service Mesh 2.x (Istio 1.15+) - optional but recommended for KServe
- Persistent storage provider (block storage for StatefulSets, file storage for ReadWriteMany)
- Container registry access (quay.io, registry.redhat.io)
- S3-compatible object storage (AWS S3, MinIO, Ceph RGW, etc.)

**Optional External Services**:
- External PostgreSQL/MySQL/MariaDB (for Data Science Pipelines)
- External etcd cluster (for ModelMesh)
- Prometheus Operator (for monitoring stack)
- cert-manager (for TLS certificate automation)
- Authorino (for advanced service mesh authorization)
- Volcano Scheduler (for gang scheduling of Ray workloads)

**Internal Component Dependencies**:
- Critical path: RHODS Operator → Component Operators → User Workloads
- Service mesh enables: KServe serverless, unified mTLS, external authorization
- Monitoring stack: All components → Prometheus → Alertmanager
- Network dependencies: All external access via OpenShift Routes → OAuth Proxy → Services

## Upgrade and Migration Notes

**Operator Lifecycle Manager (OLM) Integration**:
- All operators installed via OLM subscriptions (OperatorHub catalog)
- Automatic upgrades managed by OLM (manual approval optional)
- CRD versioning strategy: API versions frozen at v1beta1/v1alpha1 with conversion webhooks
- Backward compatibility maintained for user-created CRs

**Data Persistence During Upgrades**:
- Notebook PVCs preserved (data persists across pod restarts)
- Pipeline metadata in external DB or MariaDB PVC (persistent)
- Model artifacts in S3 (external to cluster)
- Prometheus metrics in PVC (40Gi retention)

**Breaking Changes**:
- TrustyAI API group changed (requires CR recreation)
- Service mesh integration refactored (auto-migrated by operator)

**Migration Path from ODH**:
- KfDef (legacy) → DataScienceCluster (current) via operator upgrade package
- Component-level compatibility maintained

## Next Steps for Documentation

1. **Generate Architecture Diagrams**:
   - Platform-level component relationship diagram
   - Network flow diagrams for each key workflow
   - Security boundary diagram showing authentication/authorization layers
   - Namespace topology diagram

2. **Security Architecture Review (SAR) Documentation**:
   - Network security diagram with ingress/egress paths
   - Authentication flow diagrams for each access pattern
   - RBAC matrix showing roles and permissions
   - Secret management and rotation policies
   - Compliance mapping (NIST, FedRAMP, SOC2)

3. **Operational Runbooks**:
   - Component health check procedures
   - Disaster recovery and backup strategies
   - Capacity planning guidelines
   - Troubleshooting decision trees
   - Upgrade procedures and rollback plans

4. **Developer Guides**:
   - Custom notebook image creation
   - Custom serving runtime development
   - Pipeline authoring best practices
   - Ray application development on RHOAI

5. **Architecture Decision Records (ADRs)**:
   - Why KServe and ModelMesh (dual model serving)
   - Service mesh optional vs. required trade-offs
   - Namespace isolation strategy
   - OAuth vs. alternative auth mechanisms
   - Prometheus stack vs. user-workload monitoring

6. **Performance and Scalability Documentation**:
   - Load testing results for inference endpoints
   - Pipeline concurrency limits
   - Recommended cluster sizing by workload type
   - GPU scheduling and utilization patterns
   - etcd and database sizing for ModelMesh

7. **User-Facing Architecture Documentation**:
   - Simplified architecture overview for data scientists
   - Component selection guide (when to use KServe vs ModelMesh, Ray vs standard Jobs)
   - Security best practices for users
   - Cost optimization strategies

8. **Integration Guides**:
   - CI/CD integration patterns (Jenkins, Tekton, GitHub Actions)
   - MLOps workflow examples
   - Data lake integration (Trino, Presto, Spark)
   - External model registry integration (MLflow, etc.)
