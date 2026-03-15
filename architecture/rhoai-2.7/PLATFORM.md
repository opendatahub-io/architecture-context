# Platform: Red Hat OpenShift AI 2.7

## Metadata
- **Distribution**: RHOAI
- **Version**: 2.7
- **Release Date**: 2024 (Q1)
- **Base Platform**: OpenShift Container Platform 4.11+
- **Components Analyzed**: 10
- **Architecture Directory**: architecture/rhoai-2.7

## Platform Overview

Red Hat OpenShift AI (RHOAI) 2.7 is an enterprise AI/ML platform that provides a comprehensive set of tools and services for the entire machine learning lifecycle - from data preparation and model development to training, deployment, and monitoring. The platform integrates cloud-native technologies including Kubernetes operators, service mesh, serverless computing, and distributed processing frameworks to deliver a production-grade AI/ML environment on OpenShift.

The platform architecture follows a microservices pattern with independent operators managing distinct capabilities: interactive development environments (notebooks), ML workflow orchestration (pipelines), model serving (KServe, ModelMesh), distributed computing (Ray, CodeFlare), and AI governance (TrustyAI). All components are orchestrated by the RHOAI Operator which manages platform-wide configuration through declarative DataScienceCluster and DSCInitialization custom resources.

RHOAI 2.7 emphasizes enterprise features including OpenShift OAuth integration, network isolation via NetworkPolicies, service mesh security with mTLS, multi-tenancy through namespace separation, and comprehensive observability through Prometheus metrics and OpenShift monitoring integration.

## Component Inventory

| Component | Type | Version | Purpose |
|-----------|------|---------|---------|
| RHOAI Operator (rhods-operator) | Operator | v1.6.0-441 | Core control plane managing platform lifecycle and component orchestration |
| ODH Dashboard | UI Application | N/A | Web-based user interface for data science project management |
| ODH Notebook Controller | Operator | v1.27.0-rhods-244 | Manages Jupyter notebook instances with OpenShift OAuth and Route integration |
| Notebooks (Workbench Images) | Container Images | v1.1.1-366 | JupyterLab, code-server, and RStudio environments with ML frameworks |
| Data Science Pipelines Operator | Operator | 025e77a | Manages Kubeflow Pipelines (kfp-tekton) for ML workflow orchestration |
| KServe | Operator + Runtime | 80cb15e08 | Serverless single-model serving with autoscaling and multi-framework support |
| ModelMesh Serving | Operator + Runtime | v1.27.0-rhods-168 | High-density multi-model serving with intelligent placement and routing |
| ODH Model Controller | Operator | v1.27.0-rhods-153 | Extends KServe with OpenShift Routes, NetworkPolicies, and service mesh integration |
| CodeFlare Operator | Operator | 9cfde69 | Manages distributed workload scheduling with MCAD and InstaScale |
| KubeRay Operator | Operator | 63106681 | Manages Ray clusters, jobs, and services for distributed computing |
| TrustyAI Service Operator | Operator | eb7d626 | Manages AI explainability and fairness monitoring services |

## Component Relationships

### Dependency Graph

```
RHOAI Operator (rhods-operator)
├── Orchestrates ALL platform components
├── Creates platform namespaces (redhat-ods-applications, redhat-ods-monitoring)
└── Configures service mesh integration (Istio)

ODH Notebook Controller
├── Spawns → Notebook Images (Jupyter, code-server, RStudio)
└── Integrates → OpenShift OAuth + Routes

Data Science Pipelines Operator
├── Depends on → OpenShift Pipelines (Tekton)
├── Integrates → KServe (model deployment from pipelines)
└── Uses → S3/Object Storage (artifact storage)

KServe
├── Depends on → Knative Serving (serverless deployment)
├── Depends on → Istio (service mesh, VirtualServices)
└── Integrates → Model Registry (model metadata)

ODH Model Controller
├── Watches → KServe InferenceServices
├── Creates → OpenShift Routes for external access
├── Manages → Istio PeerAuthentications (mTLS)
└── Configures → NetworkPolicies (namespace isolation)

ModelMesh Serving
├── Depends on → etcd (model placement and routing)
├── Uses → KServe CRDs (InferenceService, ServingRuntime)
└── Integrates → Istio (optional service mesh)

CodeFlare Operator
├── Manages → MCAD (Multi-Cluster App Dispatcher)
├── Manages → InstaScale (cluster autoscaling)
└── Creates → KubeRay RayClusters (for distributed workloads)

KubeRay Operator
└── Independent (no internal dependencies)

TrustyAI Service Operator
├── Integrates → KServe InferenceServices (logging)
├── Patches → ModelMesh Deployments (payload processors)
└── Exposes → Prometheus metrics (fairness/bias)
```

### Central Components

**Core Platform Services** (highest dependency count):
1. **RHOAI Operator** - Orchestrates all platform components
2. **Istio Service Mesh** - Provides mTLS, routing, and observability for model serving
3. **OpenShift OAuth** - Centralized authentication for all user-facing services
4. **Prometheus/OpenShift Monitoring** - Metrics collection from all operators and services

**Model Serving Hub**:
- **KServe + ODH Model Controller** - Primary model serving infrastructure with 5+ integrations

### Integration Patterns

| Pattern | Components Using | Purpose |
|---------|------------------|---------|
| **CRD Watching** | All operators | React to custom resource changes via Kubernetes API |
| **ServiceMonitor Creation** | All operators | Enable Prometheus metrics scraping |
| **Route Generation** | ODH Notebook Controller, ODH Model Controller, Data Science Pipelines, TrustyAI | External HTTPS access via OpenShift Router |
| **OAuth Proxy Injection** | ODH Notebook Controller, Data Science Pipelines, TrustyAI | OpenShift OAuth authentication for web UIs |
| **NetworkPolicy Creation** | ODH Model Controller, Data Science Pipelines | Namespace network isolation |
| **Istio Integration** | KServe, ModelMesh, ODH Model Controller | Service mesh mTLS and VirtualService routing |
| **Storage Initialization** | KServe, ModelMesh | Download models from S3/GCS/Azure before serving |

## Platform Network Architecture

### Namespaces

| Namespace | Purpose | Components |
|-----------|---------|------------|
| redhat-ods-operator | Operator deployment | RHOAI Operator controller-manager |
| redhat-ods-applications | Data science applications | ODH Dashboard, Notebook Controller, Data Science Pipelines Operator, Model Controllers |
| redhat-ods-monitoring | Platform monitoring | Prometheus, Alertmanager, Grafana (user-workload monitoring) |
| istio-system | Service mesh control plane | Istio Pilot, istio-ingressgateway, istiod |
| openshift-operators | Cluster operators | CodeFlare Operator, KubeRay Operator, TrustyAI Operator, ModelMesh Controller, KServe Controller |
| {user-namespaces} | User workloads | Notebook pods, InferenceServices, TrustyAI services, Data Science Pipeline instances |

### External Ingress Points

| Component | Ingress Type | Hosts | Port | Protocol | Encryption | Purpose |
|-----------|--------------|-------|------|----------|------------|---------|
| ODH Dashboard | OpenShift Route | rhods-dashboard-{ns}.{domain} | 443/TCP | HTTPS | TLS 1.2+ (Edge) | Web UI for platform management |
| Notebook Instances | OpenShift Route | {notebook}-{user}-{ns}.{domain} | 443/TCP | HTTPS | TLS 1.2+ (Edge) | JupyterLab/code-server/RStudio access |
| Data Science Pipelines API | OpenShift Route | ds-pipeline-{name}-{ns}.{domain} | 443/TCP | HTTPS | TLS 1.2+ (Reencrypt) | Pipeline API and UI access |
| KServe InferenceServices | OpenShift Route + Istio VirtualService | {isvc}-{ns}.{domain} | 443/TCP | HTTPS | TLS 1.2+ (Passthrough) | Model inference endpoints |
| ModelMesh Services | OpenShift Route (optional) | {isvc}.{ns}.svc | 8008/TCP, 8443/TCP | HTTP/HTTPS | TLS 1.2+ (Reencrypt) | Internal/external model inference |
| TrustyAI Services | OpenShift Route | {trustyai}-{ns}.{domain} | 443/TCP | HTTPS | TLS 1.2+ (Passthrough) | Explainability service access |
| Ray Dashboard | OpenShift Route (optional) | {raycluster}-dashboard-{ns}.{domain} | 443/TCP | HTTPS | TLS 1.2+ (Edge) | Ray cluster monitoring UI |

### External Egress Dependencies

| Component | Destination | Port | Protocol | Encryption | Purpose |
|-----------|-------------|------|----------|------------|---------|
| KServe, ModelMesh | s3.amazonaws.com | 443/TCP | HTTPS | TLS 1.2+ | Download model artifacts from S3 |
| KServe, ModelMesh | storage.googleapis.com | 443/TCP | HTTPS | TLS 1.2+ | Download model artifacts from GCS |
| KServe, ModelMesh | blob.core.windows.net | 443/TCP | HTTPS | TLS 1.2+ | Download model artifacts from Azure Blob |
| Notebooks | pypi.org | 443/TCP | HTTPS | TLS 1.2+ | Install Python packages at runtime |
| Notebooks | cran.rstudio.com | 443/TCP | HTTPS | TLS 1.2+ | Install R packages (RStudio) |
| Notebooks | github.com | 443/TCP | HTTPS/SSH | TLS 1.2+ | Git operations from notebooks |
| Data Science Pipelines | External S3/Database | 443/TCP, 3306/TCP, 5432/TCP | HTTPS/SQL | TLS 1.2+ | Artifact storage and metadata persistence |
| CodeFlare (InstaScale) | Cloud Provider APIs | 443/TCP | HTTPS | TLS 1.2+ | Cluster node provisioning (AWS/GCP/Azure) |
| All Operators | quay.io, registry.redhat.io | 443/TCP | HTTPS | TLS 1.2+ | Container image pulls |

### Internal Service Mesh

| Setting | Value | Components Using |
|---------|-------|------------------|
| **Mesh Provider** | OpenShift Service Mesh (Maistra) 2.x | KServe, ModelMesh, ODH Model Controller |
| **Control Plane Namespace** | istio-system | All mesh-enabled namespaces |
| **mTLS Mode** | STRICT (predictor pods), PERMISSIVE (metrics ports 8086, 3000) | KServe InferenceServices via ODH Model Controller |
| **Peer Authentication** | Namespace-scoped PeerAuthentication resources | Created by ODH Model Controller per InferenceService namespace |
| **VirtualServices** | Created per InferenceService | KServe, ModelMesh (for traffic routing and canary deployments) |
| **Telemetry** | Istio Telemetry resources | ODH Model Controller creates per namespace |
| **Membership** | ServiceMeshMember/ServiceMeshMemberRoll | ODH Model Controller adds InferenceService namespaces to mesh |

## Platform Security

### RBAC Summary

**Operator Permissions** (ClusterRole scope):

| Component | Key API Groups | Critical Resources | Broad Permissions |
|-----------|----------------|-------------------|-------------------|
| RHOAI Operator | *, datasciencecluster, dscinitialization | All resources | Yes (manages all components) |
| ODH Model Controller | serving.kserve.io, security.istio.io, route.openshift.io | InferenceServices, Routes, PeerAuthentications | Yes (integrates KServe with OpenShift) |
| KServe | serving.kserve.io, serving.knative.dev, networking.istio.io | InferenceServices, Knative Services, VirtualServices | Yes (model serving orchestration) |
| ModelMesh | serving.kserve.io, monitoring.coreos.com | InferenceServices, Predictors, ServiceMonitors | Moderate |
| Data Science Pipelines | tekton.dev, serving.kserve.io, ray.io | PipelineRuns, InferenceServices, RayClusters | Yes (multi-framework orchestration) |
| CodeFlare | workload.codeflare.dev, machine.openshift.io, ray.io | AppWrappers, MachineSets, RayClusters | Yes (cluster scaling) |
| KubeRay | ray.io, route.openshift.io | RayClusters, RayJobs, RayServices, Routes | Moderate |
| ODH Notebook Controller | kubeflow.org, route.openshift.io, networking.k8s.io | Notebooks, Routes, NetworkPolicies | Moderate |
| TrustyAI Operator | trustyai.opendatahub.io, serving.kserve.io | TrustyAIServices, InferenceServices | Moderate |

**Common Permissions** (all operators):
- `coordination.k8s.io/leases` - Leader election
- `""/configmaps` - Configuration and leader election
- `monitoring.coreos.com/servicemonitors` - Metrics collection

### Secrets Inventory

| Component | Secret Name | Type | Purpose |
|-----------|-------------|------|---------|
| RHOAI Operator | oauth-client-secrets | Opaque | OAuth client secrets for component authentication |
| RHOAI Operator | webhook-server-cert | kubernetes.io/tls | Webhook admission controller TLS |
| ODH Notebook Controller | {notebook}-oauth-config | Opaque | OAuth proxy cookie secret |
| ODH Notebook Controller | odh-notebook-controller-webhook-cert | kubernetes.io/tls | Webhook server TLS |
| Data Science Pipelines | ds-pipeline-db-{name} | Opaque | MariaDB password |
| Data Science Pipelines | mlpipeline-minio-artifact | Opaque | S3 access/secret keys |
| Data Science Pipelines | ds-pipelines-proxy-tls-{name} | kubernetes.io/tls | OAuth proxy TLS |
| KServe, ModelMesh | storage-config | Opaque | S3/GCS/Azure credentials for model downloads |
| KServe | kserve-webhook-server-cert | kubernetes.io/tls | Webhook server TLS |
| ModelMesh | model-serving-etcd | Opaque | etcd connection configuration |
| ModelMesh | webhook-server-cert | kubernetes.io/tls | Webhook server TLS |
| TrustyAI | {instance}-tls | kubernetes.io/tls | OAuth proxy TLS |
| All Components | ServiceAccount tokens | kubernetes.io/service-account-token | Kubernetes API authentication |

### Authentication Mechanisms

| Pattern | Components Using | Enforcement Point |
|---------|------------------|-------------------|
| **Bearer Tokens (JWT) from OpenShift OAuth** | ODH Dashboard, Notebooks, Data Science Pipelines UI, TrustyAI | OAuth Proxy sidecar |
| **mTLS Client Certificates (Istio)** | KServe InferenceServices, ModelMesh (optional) | Istio service mesh (Envoy sidecar) |
| **ServiceAccount Tokens** | All operators | Kubernetes RBAC via API server |
| **Kubernetes Webhook mTLS** | All webhooks (KServe, ODH Notebook, ModelMesh, TrustyAI) | Kubernetes API server validates client cert |
| **AWS IAM / S3 Signature V4** | KServe, ModelMesh, Data Science Pipelines | Storage-initializer, runtime adapter |
| **Subject Access Review (SAR)** | OAuth proxies | Kubernetes authorization API |
| **Optional Token Auth** | KServe/ModelMesh inference endpoints | Application-level (optional) |

### Authorization Policies

| Policy Type | Enforced By | Scope | Example |
|-------------|-------------|-------|---------|
| **Kubernetes RBAC** | Kubernetes API Server | Cluster-wide and namespace-scoped | Users need `get notebooks` permission to access notebook via OAuth |
| **NetworkPolicy** | OpenShift SDN/OVN | Namespace ingress/egress | ODH Model Controller creates 3 NetworkPolicies per InferenceService namespace |
| **Istio AuthorizationPolicy** | Istio Envoy sidecar | Service-to-service | (Optional) Can be configured for fine-grained access to InferenceServices |
| **OAuth Proxy SAR** | OAuth Proxy | HTTP endpoints | Delegates authorization to K8s RBAC via SubjectAccessReview |

## Platform APIs

### Custom Resource Definitions

| Component | API Group | Kind | Scope | Purpose |
|-----------|-----------|------|-------|---------|
| RHOAI Operator | datasciencecluster.opendatahub.io | DataScienceCluster | Cluster | Enable/disable AI/ML platform components |
| RHOAI Operator | dscinitialization.opendatahub.io | DSCInitialization | Cluster | Platform initialization (namespaces, service mesh, monitoring) |
| RHOAI Operator | features.opendatahub.io | FeatureTracker | Cluster | Cross-namespace resource garbage collection |
| ODH Notebook Controller | kubeflow.org | Notebook | Namespaced | Jupyter notebook deployments (external CRD) |
| Data Science Pipelines | datasciencepipelinesapplications.opendatahub.io | DataSciencePipelinesApplication | Namespaced | DSP stack deployment configuration |
| KServe | serving.kserve.io | InferenceService | Namespaced | ML model deployment with predictor/transformer/explainer |
| KServe | serving.kserve.io | ServingRuntime | Namespaced | Model serving runtime definition |
| KServe | serving.kserve.io | ClusterServingRuntime | Cluster | Cluster-wide serving runtime template |
| KServe | serving.kserve.io | InferenceGraph | Namespaced | Multi-step inference pipeline |
| KServe | serving.kserve.io | TrainedModel | Namespaced | Trained model artifact metadata |
| ModelMesh | serving.kserve.io | Predictor | Namespaced | ModelMesh-specific predictor resource |
| CodeFlare | workload.codeflare.dev | AppWrapper | Namespaced | Batch workload scheduling with MCAD |
| CodeFlare | workload.codeflare.dev | SchedulingSpec | Namespaced | Workload requeuing and dispatch parameters |
| CodeFlare | quota.codeflare.dev | QuotaSubtree | Namespaced | Hierarchical quota management |
| KubeRay | ray.io | RayCluster | Namespaced | Ray cluster with head/worker configuration |
| KubeRay | ray.io | RayJob | Namespaced | Batch job with RayCluster lifecycle |
| KubeRay | ray.io | RayService | Namespaced | Ray Serve deployment with zero-downtime upgrades |
| TrustyAI | trustyai.opendatahub.io | TrustyAIService | Namespaced | AI explainability service deployment |

### Public HTTP Endpoints

**Model Serving Inference APIs**:

| Component | Path | Method | Port | Protocol | Auth | Purpose |
|-----------|------|--------|------|----------|------|---------|
| KServe | /v1/models/:name:predict | POST | 8080/TCP | HTTP | Optional Token | KServe v1 inference protocol |
| KServe | /v2/models/:name/infer | POST | 8080/TCP | HTTP | Optional Token | KServe v2 inference protocol |
| ModelMesh | /v2/models/{model}/infer | POST | 8008/TCP | HTTP | None | KServe V2 REST via proxy |
| ModelMesh (gRPC) | inference.GRPCInferenceService | - | 8033/TCP | gRPC | None | KServe V2 gRPC inference |
| Ray Serve | /predict, /infer | POST | 8000/TCP | HTTP | Optional Bearer | Ray Serve inference endpoint |

**Platform Management APIs**:

| Component | Path | Method | Port | Protocol | Auth | Purpose |
|-----------|------|--------|------|----------|------|---------|
| Data Science Pipelines | /apis/v1beta1/* | GET/POST/PUT/DELETE | 8888/TCP | HTTP | Service token (internal) | KFP API for pipeline management |
| Data Science Pipelines (external) | /* | GET/POST/PUT/DELETE | 8443/TCP | HTTPS | OAuth Bearer | External API via OAuth proxy |
| ODH Dashboard | /* | GET/POST | 443/TCP | HTTPS | OAuth Bearer | Dashboard web UI |
| Notebooks | /notebook/{namespace}/{username}/* | GET/POST | 8888/TCP | HTTP | Token (disabled in managed) | Jupyter API (proxied) |
| TrustyAI | / | ALL | 8443/TCP | HTTPS | OAuth | Explainability service API |
| Ray Dashboard | / | GET | 8265/TCP | HTTP | Optional Token | Ray cluster dashboard |

**Operator Metrics Endpoints** (all operators):

| Path | Port | Protocol | Auth | Purpose |
|------|------|----------|------|---------|
| /metrics | 8080/TCP or 8443/TCP | HTTP or HTTPS | Bearer Token (if 8443) | Prometheus metrics |
| /healthz | 8081/TCP | HTTP | None | Liveness probe |
| /readyz | 8081/TCP | HTTP | None | Readiness probe |

## Data Flows

### Key Platform Workflows

#### Workflow 1: Model Training to Deployment

| Step | Component | Action | Next Component |
|------|-----------|--------|----------------|
| 1 | **User** | Authenticates via OpenShift OAuth | ODH Dashboard |
| 2 | **ODH Dashboard** | User creates data science project (namespace) | RHOAI Operator |
| 3 | **User** | Launches Jupyter notebook | ODH Notebook Controller |
| 4 | **ODH Notebook Controller** | Spawns StatefulSet with notebook image | Notebook Pod |
| 5 | **Notebook Pod** | User trains model, uploads to S3 | S3 Storage |
| 6 | **User** | Submits InferenceService CR via Dashboard or kubectl | KServe Controller |
| 7 | **KServe Controller** | Creates Knative Service or Deployment | Predictor Pod |
| 8 | **ODH Model Controller** | Creates Route, NetworkPolicies, PeerAuthentication | OpenShift Router, Istio |
| 9 | **Predictor Pod (storage-initializer)** | Downloads model from S3 | S3 Storage |
| 10 | **Model Server** | Loads model, ready for inference | - |
| 11 | **External Client** | Sends inference request to Route | OpenShift Router → Istio Ingress → Predictor |

#### Workflow 2: Pipeline Execution

| Step | Component | Action | Next Component |
|------|-----------|--------|----------------|
| 1 | **User** | Creates DataSciencePipelinesApplication CR | Data Science Pipelines Operator |
| 2 | **DSPO** | Deploys API server, persistence agent, MariaDB, Minio | DSPA Namespace |
| 3 | **User** | Uploads pipeline definition via UI or SDK | DSP API Server |
| 4 | **DSP API Server** | Stores pipeline in MariaDB, creates Tekton PipelineRun | Tekton |
| 5 | **Tekton** | Creates pipeline task pods | Pipeline Task Pods |
| 6 | **Pipeline Tasks** | Execute data prep, training, evaluation steps | Minio/S3 (artifacts) |
| 7 | **Pipeline Task (Deploy)** | Creates InferenceService CR for model | KServe Controller |
| 8 | **Persistence Agent** | Syncs Tekton metadata to database | MariaDB |
| 9 | **User** | Views pipeline run status in UI | DSP UI |

#### Workflow 3: Distributed Training with Ray

| Step | Component | Action | Next Component |
|------|-----------|--------|----------------|
| 1 | **User** | Creates RayCluster CR | KubeRay Operator |
| 2 | **KubeRay Operator** | Creates Ray head and worker pods, services | Ray Cluster Pods |
| 3 | **User (from notebook)** | Connects to Ray cluster via Ray client | Ray Head Pod |
| 4 | **User** | Submits distributed training job | Ray Cluster |
| 5 | **Ray Autoscaler** | Scales worker pods based on resource demand | KubeRay Operator |
| 6 | **Ray Workers** | Execute distributed training tasks | Training Data (S3/PVC) |
| 7 | **Training Job** | Saves checkpoints and final model | S3/Object Storage |
| 8 | **User** | Creates InferenceService with trained model | KServe Controller |

#### Workflow 4: Batch Workload Scheduling

| Step | Component | Action | Next Component |
|------|-----------|--------|----------------|
| 1 | **User** | Creates AppWrapper CR | CodeFlare Operator (MCAD) |
| 2 | **MCAD Controller** | Queues workload, checks quota and priority | AppWrapper Queue |
| 3 | **MCAD Controller** | When resources available, creates RayCluster CR | KubeRay Operator |
| 4 | **InstaScale (if enabled)** | Detects resource shortage, creates MachineSets | OpenShift Machine API |
| 5 | **Machine API** | Provisions new nodes from cloud provider | Cloud Provider API |
| 6 | **KubeRay Operator** | Schedules Ray pods on new nodes | Ray Cluster Pods |
| 7 | **MCAD Controller** | Monitors RayCluster status, updates AppWrapper | AppWrapper Status |
| 8 | **InstaScale** | Scales down MachineSets when workload completes | OpenShift Machine API |

#### Workflow 5: Model Monitoring and Explainability

| Step | Component | Action | Next Component |
|------|-----------|--------|----------------|
| 1 | **User** | Creates TrustyAIService CR in namespace with InferenceServices | TrustyAI Operator |
| 2 | **TrustyAI Operator** | Deploys TrustyAI service with OAuth proxy, creates Route | TrustyAI Service Pod |
| 3 | **TrustyAI Operator** | Patches InferenceServices to enable logging | KServe/ModelMesh |
| 4 | **InferenceService** | Sends inference requests/responses to TrustyAI | TrustyAI Service |
| 5 | **TrustyAI Service** | Stores payloads, calculates fairness metrics | PVC + /q/metrics endpoint |
| 6 | **Prometheus** | Scrapes TrustyAI metrics (SPD, DIR, etc.) | TrustyAI ServiceMonitor |
| 7 | **User** | Views fairness metrics in dashboard via Route | TrustyAI Service (OAuth protected) |

## Deployment Architecture

### Deployment Topology

**Operator Deployments** (redhat-ods-operator, openshift-operators):
- RHOAI Operator: 1 replica, leader election
- ODH Notebook Controller: 1 replica
- Data Science Pipelines Operator: 1 replica, leader election
- KServe Controller: 1 replica (in kserve namespace)
- ModelMesh Controller: 1 replica, leader election
- ODH Model Controller: 3 replicas, leader election (HA)
- CodeFlare Operator: 1 replica, leader election
- KubeRay Operator: 1 replica, leader election
- TrustyAI Operator: 1 replica, leader election

**Application Deployments** (redhat-ods-applications):
- ODH Dashboard: Multi-replica frontend
- Various operator controllers

**User Workloads** (user namespaces):
- Notebook Pods: StatefulSets (1 replica per user)
- InferenceService Predictors: Knative Services or Deployments (autoscaled)
- ModelMesh Runtime Pods: Deployments (2+ replicas per ServingRuntime)
- Ray Clusters: Head (1 replica) + Workers (autoscaled)
- Data Science Pipeline Instances: Per-namespace deployments

**Monitoring Stack** (redhat-ods-monitoring):
- Prometheus: User-workload monitoring
- Alertmanager: Alert routing
- Grafana: Metrics visualization

### Resource Requirements

**Operator Pods**:

| Component | CPU Request | CPU Limit | Memory Request | Memory Limit |
|-----------|-------------|-----------|----------------|--------------|
| RHOAI Operator | 500m | 500m | 256Mi | 4Gi |
| ODH Notebook Controller | 500m | 500m | 256Mi | 4Gi |
| ODH Model Controller | 10m | 500m | 64Mi | 2Gi |
| Data Science Pipelines Operator | - | - | - | - |
| KServe Manager | 100m | 100m | 200Mi | 300Mi |
| ModelMesh Controller | - | - | - | - |
| CodeFlare Operator | 1 | 1 | 1Gi | 1Gi |
| KubeRay Operator | 100m | 100m | 512Mi | 512Mi |
| TrustyAI Operator | 10m | 500m | 64Mi | 128Mi |

**User Workloads** (configurable by admin/user):
- Notebook Pods: Default 500m CPU, 2Gi memory
- InferenceService Predictors: Varies by model server
- Ray Clusters: User-defined per RayCluster spec
- Data Science Pipeline components: Varies per component

## Version-Specific Changes (2.7)

| Component | Changes |
|-----------|---------|
| RHOAI Operator | - **REMOVED**: TrustyAI installation in downstream RHOAI<br>- Set TrustyAI status to false in DataScienceCluster<br>- Cleanup deprecated model monitoring stack<br>- Fix KServe manual/unmanaged installation handling |
| Data Science Pipelines | - Latest 1.5 DSP images<br>- Add support for CA bundle injection for TLS<br>- Update to Go 1.19<br>- Security: Update golang grpc, x/net packages |
| KServe | - Security patches: CVE-2023-48795, CVE-2022-21698, CVE-2023-45142<br>- Pin Kubernetes dependencies to v0.26.4/v0.27.x<br>- Update controller-runtime v0.14.6, Knative v0.39.3 |
| ModelMesh | - Merge upstream release-0.11.1<br>- Fix CVE-2023-37788, CVE-2023-48795 (protobuf), CVE-2023-44487 (HTTP/2)<br>- Update Knative serving dependencies |
| ODH Model Controller | - Network policy updates (RHOAIENG-1003)<br>- Monitoring stack cleanup and RBAC fixes<br>- Security: Fix protobuf CVE, otelhttp CVE<br>- Sync with upstream KServe release-0.11.1 |
| ODH Notebook Controller | - Bump controller-runtime version<br>- Set SSL_CERT_FILE env var for proxy CA trust<br>- Upgrade Go 1.19, fix CVEs in net/grpc |
| KubeRay | - Fix CVE: Replace go-sqlite3 upgraded version<br>- Upgrade Kubernetes to v0.28.3, Go 1.20<br>- Fix CVE-2023-44487 (grpc) |
| TrustyAI | - Remove /metrics from skip-auth regex (require auth)<br>- Update ose-auth-proxy image<br>- Rename apiGroup to trustyai.opendatahub.io<br>- Fix CVE-2022-21698 (opentelemetry), CVE-2023-37788 (goproxy) |
| CodeFlare | - Add roles for admin/editor to operator<br>- Adjust DSC source path<br>- Upgrade KubeRay to v1.0.0<br>- Update MCAD version |

**Overall Platform Trends**:
- **Security Hardening**: Multiple CVE fixes across all components (gRPC, protobuf, HTTP/2, SSL)
- **Golang Updates**: Platform-wide upgrade to Go 1.19/1.20
- **Dependency Updates**: Kubernetes client libraries updated to v0.26-0.28
- **Network Isolation**: Enhanced NetworkPolicy configurations
- **Component Deprecation**: TrustyAI removed from default RHOAI installation (optional addon)

## Platform Maturity

### Platform Statistics

- **Total Components**: 10 operators + 1 workbench image set
- **Operator-based Components**: 9 operators + 1 image controller
- **Service Mesh Coverage**: ~40% (KServe, ModelMesh, ODH Model Controller required; others optional)
- **mTLS Enforcement**: MIXED (STRICT for KServe predictors, PERMISSIVE for metrics ports, DISABLED for non-mesh components)
- **CRD API Versions**: Mix of v1alpha1 (newer components), v1beta1 (KServe), v1 (platform CRDs)
- **OpenShift Integration**: 100% (all components use OpenShift Routes, OAuth, ImageStreams)
- **Observability**: 100% (all operators expose Prometheus metrics via ServiceMonitor)

### Maturity Assessment

**Strengths**:
- **Comprehensive RBAC**: All components follow least-privilege patterns with detailed ClusterRoles
- **High Availability**: ODH Model Controller (3 replicas), others use leader election
- **Enterprise Auth**: Full OpenShift OAuth integration for all user-facing components
- **Network Security**: NetworkPolicies for namespace isolation, Istio mTLS for model serving
- **Monitoring**: Complete observability stack with Prometheus metrics and ServiceMonitors
- **Modular Architecture**: Components independently managed via DataScienceCluster managementState

**Areas for Improvement**:
- **Mixed API Versions**: Some CRDs still in v1alpha1 (not GA)
- **Service Mesh Coverage**: Optional for some components, required for others (inconsistent)
- **Storage Dependency**: Heavy reliance on external S3-compatible storage (not abstracted)
- **Custom Webhooks**: Multiple webhook servers increase operational complexity
- **Scaling Limits**: Some components (notebooks) are single-user only

### Production Readiness

| Capability | Status | Notes |
|------------|--------|-------|
| **High Availability** | ✅ Partial | Operators use leader election; ODH Model Controller has 3 replicas; user workloads configurable |
| **Disaster Recovery** | ⚠️ External | Relies on backup of PVCs, S3 buckets, and etcd for stateful components |
| **Multi-tenancy** | ✅ Yes | Namespace isolation with NetworkPolicies, RBAC, and optional service mesh |
| **Autoscaling** | ✅ Yes | KServe (Knative HPA), Ray (autoscaler), CodeFlare (cluster scaling) |
| **Monitoring** | ✅ Complete | All components expose metrics; integrated with OpenShift monitoring |
| **Alerting** | ⚠️ Partial | Component-level alerts available; platform-level alert rules may need customization |
| **TLS Everywhere** | ✅ Yes | All external endpoints use TLS; internal traffic can use mTLS (Istio) |
| **FIPS Compliance** | ✅ Supported | Operators built with FIPS mode enabled |
| **Upgrade Strategy** | ✅ OLM | Operator Lifecycle Manager handles upgrades with CSV dependencies |
| **GitOps Support** | ✅ Yes | All CRDs can be managed via GitOps (DataScienceCluster, DSCInitialization) |

## Next Steps for Documentation

### Immediate Actions

1. **Generate Architecture Diagrams**
   - Component dependency graph (Graphviz/Mermaid)
   - Network flow diagrams for each workflow
   - Service mesh topology diagram
   - Namespace and RBAC relationships

2. **Create Security Architecture Review (SAR) Documentation**
   - Network segmentation diagrams with NetworkPolicy visualization
   - mTLS certificate chain diagrams
   - Authentication/authorization flow diagrams
   - Threat model for model serving endpoints

3. **Update User-Facing Documentation**
   - Component selection guide (when to use KServe vs ModelMesh)
   - Best practices for notebook resource allocation
   - Pipeline authoring guide with Tekton examples
   - Distributed training guide with Ray and CodeFlare

### Strategic Enhancements

4. **Develop ADRs (Architecture Decision Records)**
   - ADR-001: Why Tekton instead of Argo for pipelines
   - ADR-002: KServe + ModelMesh dual-mode serving strategy
   - ADR-003: OpenShift Routes vs Kubernetes Ingress
   - ADR-004: Service mesh integration patterns
   - ADR-005: Namespace design and multi-tenancy model

5. **Create Runbooks**
   - InferenceService troubleshooting guide
   - Pipeline execution failure recovery
   - Service mesh debugging procedures
   - Operator upgrade procedures
   - Disaster recovery procedures

6. **Performance Benchmarking**
   - Model serving latency benchmarks (KServe vs ModelMesh)
   - Notebook spawn time optimization guide
   - Pipeline execution performance tuning
   - Ray cluster scaling performance

7. **Compliance Documentation**
   - FIPS 140-2 compliance guide
   - Network security diagrams for FedRAMP
   - Audit logging configuration
   - Data residency and encryption-at-rest guide

### Documentation Repositories

- **Architecture Council Repository**: Share this PLATFORM.md for review
- **OpenShift AI Documentation**: Create user-facing architecture guide
- **Red Hat KCS**: Document common troubleshooting scenarios
- **Developer Portal**: Publish API reference and integration guides
