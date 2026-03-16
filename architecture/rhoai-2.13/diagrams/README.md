# Architecture Diagrams for RHOAI 2.13 Components

This directory contains architecture diagrams for all RHOAI 2.13 components.

**Note**: Diagram filenames use base component name without version (directory is already versioned).

---

## Table of Contents

- [Platform (Aggregated View)](#platform-aggregated-view)
- [CodeFlare Operator](#codeflare-operator)
- [Data Science Pipelines Operator](#data-science-pipelines-operator)
- [KServe](#kserve)
- [Kubeflow](#kubeflow)
- [KubeRay](#kuberay)
- [ODH Dashboard](#odh-dashboard)
- [RHODS Operator](#rhods-operator)
- [TrustyAI Service Operator](#trustyai-service-operator)
- [How to Use Diagrams](#how-to-use-diagrams)

---

## Platform (Aggregated View)

**Generated from**: `architecture/rhoai-2.13/PLATFORM.md`
**Date**: 2026-03-15

### Overview
Complete platform architecture for Red Hat OpenShift AI 2.13, aggregating all 13 core components into a unified view. This provides the "big picture" of how RHODS Operator, ODH Dashboard, Notebook Controller, KServe, ModelMesh, ODH Model Controller, Data Science Pipelines, Training Operator, CodeFlare, KubeRay, Kueue, and TrustyAI work together.

### Available Diagrams
- [Component Structure](./platform-component.png) ([mmd](./platform-component.mmd)) - All 13 components and their relationships
- [Data Flows](./platform-dataflow.png) ([mmd](./platform-dataflow.mmd)) - Key workflows: notebook launch, model deployment, distributed training
- [Dependencies](./platform-dependencies.png) ([mmd](./platform-dependencies.mmd)) - Complete dependency graph of all platform integrations
- [C4 Context](./platform-c4-context.dsl) - Platform system context with all containers and components
- [Security Network (PNG)](./platform-security-network.png) | [Mermaid](./platform-security-network.mmd) | [ASCII](./platform-security-network.txt) - Complete platform network topology with trust boundaries
- [RBAC Visualization](./platform-rbac.png) ([mmd](./platform-rbac.mmd)) - All operator permissions and API resource access

### Key Components (13 Total)
1. **RHODS Operator** (v1.6.0-2256) - Platform orchestrator
2. **ODH Dashboard** (v1.21.0-18) - Web UI
3. **Notebook Controller** (v1.27.0-376) - Development environments
4. **Workbench Images** - Jupyter/VS Code/RStudio
5. **KServe** (v0.12.1) - Serverless model serving
6. **ModelMesh Serving** (v1.27.0-292) - Multi-model serving
7. **ODH Model Controller** (v1.27.0-527) - OpenShift extensions
8. **Data Science Pipelines** - ML pipeline orchestration
9. **Training Operator** - Distributed ML training
10. **CodeFlare Operator** - AppWrapper and Ray security
11. **KubeRay Operator** (v1.1.0) - Ray cluster management
12. **Kueue** - Job queueing and resource management
13. **TrustyAI Operator** (v1.17.0) - AI explainability

### Key Workflows
1. **Notebook Launch**: User → OAuth → Dashboard → Notebook Controller → Pod → Route
2. **Model Deployment**: User → Dashboard → KServe → ODH Model Controller → Route/Istio → Inference Pod → S3
3. **Distributed Training**: User → PyTorchJob → Kueue → Training Operator → Training Pods → S3
4. **Ray Cluster**: User → AppWrapper → CodeFlare → Kueue → KubeRay → Ray Pods (OAuth/mTLS)
5. **ML Pipeline**: User → DSP → Argo/Tekton → Pipeline Steps → KServe Deployment

### External Dependencies
- **OpenShift Container Platform 4.11+** - Base Kubernetes platform
- **Istio Service Mesh v2.5+** - mTLS, traffic management
- **Knative Serving v1.12+** - Serverless autoscaling
- **Prometheus** - Metrics collection
- **S3-Compatible Storage** - Model/dataset/artifact storage

### Security Highlights
- **Authentication**: OpenShift OAuth (external users), ServiceAccount JWT (operators), AWS IAM/S3 API (storage)
- **Authorization**: RBAC (ClusterRoles/Roles), Istio AuthorizationPolicy
- **Encryption**: TLS 1.2+ (external), mTLS STRICT (service mesh), TLS 1.2+ (S3)
- **Trust Boundaries**: External → Ingress → Platform → Operators → User Workloads → External Services

---

## CodeFlare Operator

**Generated from**: `architecture/rhoai-2.13/codeflare-operator.md`

### Available Diagrams
- [Component Structure](./codeflare-operator-component.png) ([mmd](./codeflare-operator-component.mmd))
- [Data Flows](./codeflare-operator-dataflow.png) ([mmd](./codeflare-operator-dataflow.mmd))
- [Dependencies](./codeflare-operator-dependencies.png) ([mmd](./codeflare-operator-dependencies.mmd))
- [C4 Context](./codeflare-operator-c4-context.dsl)
- [Security Network (PNG)](./codeflare-operator-security-network.png) | [Mermaid](./codeflare-operator-security-network.mmd) | [ASCII](./codeflare-operator-security-network.txt)
- [RBAC Visualization](./codeflare-operator-rbac.png) ([mmd](./codeflare-operator-rbac.mmd))

### Key Features
- **mTLS**: Ray cluster internal communication encrypted
- **OAuth Proxy**: Ray dashboard authentication
- **NetworkPolicies**: Automatic pod-to-pod isolation
- **FIPS Mode**: Built with strictfipsruntime

---

## Data Science Pipelines Operator

**Generated from**: `architecture/rhoai-2.13/data-science-pipelines-operator.md`
**Date**: 2026-03-15

### Available Diagrams
- [Component Structure](./data-science-pipelines-operator-component.png) ([mmd](./data-science-pipelines-operator-component.mmd))
- [Data Flows](./data-science-pipelines-operator-dataflow.png) ([mmd](./data-science-pipelines-operator-dataflow.mmd))
- [Dependencies](./data-science-pipelines-operator-dependencies.png) ([mmd](./data-science-pipelines-operator-dependencies.mmd))
- [C4 Context](./data-science-pipelines-operator-c4-context.dsl)
- [Security Network (PNG)](./data-science-pipelines-operator-security-network.png) | [Mermaid](./data-science-pipelines-operator-security-network.mmd) | [ASCII](./data-science-pipelines-operator-security-network.txt)
- [RBAC Visualization](./data-science-pipelines-operator-rbac.png) ([mmd](./data-science-pipelines-operator-rbac.mmd))

### Component Overview
Shows the DSPO controller, per-instance components (API Server, Persistence Agent, Scheduled Workflow, MariaDB, Minio, ML Metadata), and their relationships with external dependencies (Kubernetes, Argo/Tekton, ODH components).

### Data Flows
Five key flows illustrated:
1. **Pipeline Submission and Execution**: User → Route → OAuth → API Server → Kubernetes → Argo/Tekton → Pipeline Pods
2. **Artifact Storage and Retrieval**: Pipeline components upload to S3/Minio, users download via signed URLs
3. **Metadata Tracking (MLMD)**: Pipeline components record metadata via gRPC to ML Metadata server
4. **Persistence Agent Workflow Sync**: Watches Kubernetes workflows and syncs status to database
5. **Scheduled Workflow Execution**: Scheduled controller creates recurring pipeline runs

### Security Network Architecture
Detailed network architecture showing:
- **External tier**: Users accessing via HTTPS/443 with OAuth tokens
- **Ingress tier**: OpenShift Routes with reencrypt TLS, OAuth proxy sidecar
- **Application tier**: API Server, workflow controllers, pipeline pods with namespace isolation
- **Data tier**: MariaDB (MySQL/3306), Minio (HTTP/9000), ML Metadata (gRPC/8080)
- **External services**: Optional production S3 and database with TLS encryption

### Key Features
- **Namespace-scoped instances**: Multiple independent DSP deployments per cluster
- **Dual workflow engines**: Supports both DSP v1 (Tekton) and v2 (Argo Workflows)
- **OAuth integration**: Routes use OpenShift OAuth proxy for SSO authentication
- **Flexible storage**: Supports embedded MariaDB/Minio (dev) or external database/S3 (production)
- **ML Metadata tracking**: Optional MLMD gRPC server with Envoy proxy for lineage and artifact tracking

### Security Features
- **OAuth Bearer Token authentication**: Via OpenShift OAuth proxy on Routes (TLS 1.2+ reencrypt)
- **Optional TLS**: Database and gRPC connections support TLS encryption
- **NetworkPolicy**: Restricts ML Metadata gRPC access to pipeline components only
- **RBAC**: Separate ServiceAccounts for controller, API server, and pipeline execution
- **Non-root**: Runs as user 65532 with all capabilities dropped

### RBAC Model
Two-tier RBAC:
1. **Cluster-scoped (DSPO Controller)**: Full control over DataSciencePipelinesApplication CRs, Argo workflows, deployments, services, routes
2. **Namespace-scoped (Per DSPA instance)**: Separate ServiceAccounts for API server (`ds-pipeline-{name}`) and pipeline execution (`pipeline-runner-{name}`)

### Dependencies
- **Required external**: Kubernetes 4.11+, Argo Workflows (v2) or Tekton 1.8+ (v1), cert-manager/Service CA, OpenShift OAuth
- **Optional external**: External S3 storage, external database (production)
- **Internal ODH**: opendatahub-operator (deploys DSPO), ODH Dashboard (UI integration), Elyra (pipeline authoring)

---

## KServe

**Generated from**: `architecture/rhoai-2.13/kserve.md`
**Version**: v0.12.1 (RHOAI 2.13)
**Date**: 2026-03-15

### Available Diagrams
- [Component Structure](./kserve-component.png) ([mmd](./kserve-component.mmd))
- [Data Flows](./kserve-dataflow.png) ([mmd](./kserve-dataflow.mmd))
- [Dependencies](./kserve-dependencies.png) ([mmd](./kserve-dependencies.mmd))
- [C4 Context](./kserve-c4-context.dsl)
- [Security Network (PNG)](./kserve-security-network.png) | [Mermaid](./kserve-security-network.mmd) | [ASCII](./kserve-security-network.txt)
- [RBAC Visualization](./kserve-rbac.png) ([mmd](./kserve-rbac.mmd))

### Component Overview
Shows KServe's architecture including:
- **Control Plane**: kserve-controller-manager (operator), webhook server (admission controller)
- **Data Plane**: storage-initializer (model download), kserve-agent (batching/logging), model servers, InferenceGraph router
- **Custom Resources**: InferenceService, InferenceGraph, TrainedModel, ServingRuntime, ClusterServingRuntime, ClusterStorageContainer
- **Created Resources**: Knative Services, Deployments, Services, Istio VirtualServices
- **External Dependencies**: Kubernetes 1.25+, Knative Serving 0.39+ (optional), Istio 1.19+ (optional), cert-manager, S3/GCS storage
- **Internal ODH Dependencies**: odh-model-controller, odh-dashboard, Service Mesh (OSSM), Model Registry

### Data Flows
Four key flows illustrated:
1. **InferenceService Creation**: User creates InferenceService CR → Webhook validation/mutation → Controller reconciliation → Resources created (Knative Service, VirtualService)
2. **Model Initialization**: storage-initializer downloads model from S3/GCS (AWS SigV4/GCP IAM) → Writes to EmptyDir volume → Model server loads from volume
3. **Inference Request**: Client → Istio Gateway (TLS termination) → Knative Activator (autoscaling) → kserve-agent (batching) → Model server → Response + optional CloudEvents logging
4. **InferenceGraph Workflow**: Router orchestrates multi-step inference pipelines with sequence/switch/ensemble routing logic

### Security Network Architecture
Comprehensive network architecture showing:
- **Trust zones**: External (untrusted), Ingress (DMZ), Service Mesh (mTLS STRICT), Control Plane, External Services
- **Network flows**: All ports, protocols, encryption (TLS 1.2+, mTLS via Istio), authentication mechanisms
- **RBAC summary**: ClusterRole kserve-manager-role with full CRUD on KServe CRDs (serving.kserve.io), Knative Services (serving.knative.dev), Istio VirtualServices (networking.istio.io), core resources
- **Service Mesh config**: PeerAuthentication STRICT mode, AuthorizationPolicy for predictor/router access
- **Secrets**: kserve-webhook-server-cert (TLS, cert-manager provisioned, 90d rotation), storage-config (S3/GCS credentials), SA tokens (auto-rotated)

### Key Features
- **Multi-framework support**: TensorFlow, PyTorch, SKLearn, XGBoost, ONNX, HuggingFace, and custom runtimes
- **Autoscaling**: Scale-to-zero with Knative Serving (CPU/GPU workloads)
- **Advanced traffic management**: Canary rollouts, A/B testing via Istio
- **InferenceGraph**: Multi-step pipelines with preprocessing, prediction, postprocessing, and explainability
- **Dual deployment modes**: Serverless (Knative) or RawDeployment (standard Kubernetes)
- **Storage flexibility**: S3, GCS, HTTP(S), PVC model sources
- **Protocol support**: KServe v1 (REST) and v2 (REST/gRPC)

### Security Features
- **Istio mTLS STRICT**: All service mesh traffic encrypted with mutual TLS
- **TLS 1.2+ encryption**: External endpoints and storage access
- **Webhook authentication**: Kubernetes API Server validates webhook via mTLS
- **Storage authentication**: AWS Signature v4 (S3), GCP IAM (GCS) from mounted secrets
- **RBAC**: Fine-grained ClusterRole permissions for controller service account
- **Network isolation**: AuthorizationPolicy for namespace-scoped access control
- **Secret rotation**: Auto-rotation via cert-manager (webhooks) and Kubernetes (SA tokens)

### RBAC Model
Cluster-scoped controller with:
- **ServiceAccount**: kserve-controller-manager (namespace: kserve)
- **ClusterRole**: kserve-manager-role with full control over KServe CRDs, Knative Services, Istio VirtualServices, core K8s resources
- **Leader election**: ConfigMap-based leader election (Role: kserve-leader-election-role)
- **Proxy role**: TokenReviews and SubjectAccessReviews for metrics/auth

### Dependencies
- **Required external**: Kubernetes 1.25+
- **Optional external**: Knative Serving 0.39+ (serverless), Istio 1.19+ (traffic management), cert-manager (webhook certs), Prometheus (metrics)
- **External services**: S3 compatible storage (AWS/Minio), Google Cloud Storage, HTTP(S) endpoints, CloudEvents sinks (logging)
- **Internal ODH**: odh-model-controller (creates InferenceServices), odh-dashboard (UI management), Service Mesh OSSM (mTLS/AuthZ), Model Registry (model metadata)

### Supported Model Runtimes
- **HuggingFace** (Transformers, NLP models)
- **LightGBM** (Gradient boosting)
- **MLServer** (Multi-framework: SKLearn, XGBoost, LightGBM, MLflow)
- **Paddle** (PaddlePaddle)
- **PMML** (Predictive Model Markup Language)
- **SKLearn** (Scikit-learn)
- **TensorFlow** (via TFServing)
- **PyTorch** (via TorchServe)
- **XGBoost**
- **ONNX** (Open Neural Network Exchange)
- **Custom** (user-defined containers implementing KServe protocol)

Each runtime is defined as a ClusterServingRuntime with container specs, supported model formats, and protocol versions (v1/v2).

---

## Kubeflow

**Generated from**: `architecture/rhoai-2.13/kubeflow.md`

### Available Diagrams
- [Component Structure](./kubeflow-component.png) ([mmd](./kubeflow-component.mmd))
- [Data Flows](./kubeflow-dataflow.png) ([mmd](./kubeflow-dataflow.mmd))
- [Dependencies](./kubeflow-dependencies.png) ([mmd](./kubeflow-dependencies.mmd))
- [C4 Context](./kubeflow-c4-context.dsl)
- [Security Network (PNG)](./kubeflow-security-network.png) | [Mermaid](./kubeflow-security-network.mmd) | [ASCII](./kubeflow-security-network.txt)
- [RBAC Visualization](./kubeflow-rbac.png) ([mmd](./kubeflow-rbac.mmd))

---

## KubeRay

**Generated from**: `architecture/rhoai-2.13/kuberay.md`
**Date**: 2026-03-15

### Available Diagrams
- [Component Structure](./kuberay-component.png) ([mmd](./kuberay-component.mmd))
- [Data Flows](./kuberay-dataflow.png) ([mmd](./kuberay-dataflow.mmd))
- [Dependencies](./kuberay-dependencies.png) ([mmd](./kuberay-dependencies.mmd))
- [C4 Context](./kuberay-c4-context.dsl)
- [Security Network (PNG)](./kuberay-security-network.png) | [Mermaid](./kuberay-security-network.mmd) | [ASCII](./kuberay-security-network.txt)
- [RBAC Visualization](./kuberay-rbac.png) ([mmd](./kuberay-rbac.mmd))

### Component Overview
Shows the KubeRay operator architecture including:
- **Operator components**: KubeRay Operator, Validating Webhook
- **Ray cluster components**: Head Pod (GCS, Dashboard, Scheduler), Worker Pods, Autoscaler Sidecar
- **Custom Resources**: RayCluster, RayJob, RayService CRs
- **Services**: Head Service (GCS/Dashboard/Client), Serve Service, Metrics Service
- **External dependencies**: Kubernetes API, cert-manager, Prometheus, Redis, S3

### Key Features
- **Ray Cluster Lifecycle Management**: Automated Head/Worker pod creation and scaling
- **Autoscaling**: Dynamic worker scaling based on workload
- **High Availability**: External Redis for GCS fault tolerance
- **Security**: Non-root execution, capabilities dropped, optional mTLS
- **Integration**: ODH Dashboard, Prometheus metrics, S3 storage

---

## ODH Dashboard

**Generated from**: `architecture/rhoai-2.13/odh-dashboard.md`
**Version**: v1.21.0-18-rhods-2273
**Date**: 2026-03-15

### Available Diagrams
- [Component Structure](./odh-dashboard-component.png) ([mmd](./odh-dashboard-component.mmd))
- [Data Flows](./odh-dashboard-dataflow.png) ([mmd](./odh-dashboard-dataflow.mmd))
- [Dependencies](./odh-dashboard-dependencies.png) ([mmd](./odh-dashboard-dependencies.mmd))
- [C4 Context](./odh-dashboard-c4-context.dsl)
- [Security Network (PNG)](./odh-dashboard-security-network.png) | [Mermaid](./odh-dashboard-security-network.mmd) | [ASCII](./odh-dashboard-security-network.txt)
- [RBAC Visualization](./odh-dashboard-rbac.png) ([mmd](./odh-dashboard-rbac.mmd))

### Component Overview
Shows the ODH Dashboard architecture including:
- **Backend**: Fastify/Node.js REST API server providing Kubernetes API proxy, configuration management, and business logic (port 8080/HTTP)
- **Frontend**: React/PatternFly single-page application for data science workflows
- **OAuth Proxy**: OpenShift OAuth proxy sidecar for authentication and authorization (port 8443/HTTPS)
- **Static File Server**: Fastify Static serving compiled frontend assets
- **Custom Resources**: OdhApplication, OdhDashboardConfig, OdhDocument, OdhQuickStart, AcceleratorProfile
- **External Dependencies**: Kubernetes API (6443), OpenShift OAuth Server (443), Prometheus (9091), Image Registry (5000)
- **Internal ODH Dependencies**: ODH Operator, Kubeflow Notebooks, KServe, Model Registry Operator, OpenShift Build Service

### Data Flows
Four key flows illustrated:
1. **User Authentication and Frontend Access**: User → Route → OAuth Proxy → OpenShift OAuth Server (authentication) → OAuth Proxy → Backend → Frontend (static files)
2. **API Request to Kubernetes**: Frontend → OAuth Proxy → Backend → Kubernetes API (user impersonation with Bearer Token) → Response
3. **Notebook Creation**: User → Backend → K8s API (create Namespace, Notebook CR, RBAC) → Response
4. **Metrics Query**: Frontend → Backend → Prometheus (PromQL with ServiceAccount Token) → Metrics data → Frontend

### Security Network Architecture
Comprehensive network architecture showing:
- **Trust zones**: External (untrusted), Ingress (DMZ), Cluster Internal (trusted)
- **Network flows**: All ports, protocols, encryption (TLS 1.2+ for external, HTTP for localhost)
- **OAuth flow**: OpenShift Route (443/HTTPS TLS1.2+ re-encrypt) → OAuth Proxy (8443/HTTPS) → Backend (8080/HTTP localhost)
- **RBAC summary**: ClusterRole and Role with extensive permissions for dashboard ServiceAccount
- **Service Mesh**: No mTLS integration (uses OAuth proxy instead)
- **Secrets**: dashboard-proxy-tls (TLS cert, auto-rotated by Service CA), dashboard-oauth-config (cookie secret), dashboard-oauth-client (OAuth client secret)

### Key Features
- **Unified UI**: Centralized management console for RHOAI/ODH platform components
- **Multi-component integration**: Manages Jupyter notebooks, data science projects, ML model deployments, accelerator profiles, model serving runtimes
- **OpenShift OAuth integration**: SSO authentication via OpenShift OAuth server
- **User impersonation**: Backend uses user Bearer Tokens to ensure RBAC is respected for all K8s API calls
- **High availability**: 2 replicas with pod anti-affinity across availability zones
- **Stateless backend**: No persistent storage, all state managed via Kubernetes API resources
- **Metrics integration**: Prometheus proxy for model serving and pipeline performance dashboards

### Security Features
- **OAuth Bearer Token authentication**: Via OpenShift OAuth proxy on all routes (TLS 1.2+ re-encrypt mode)
- **User impersonation**: Backend forwards user tokens to K8s API (per-resource RBAC enforcement)
- **TLS 1.2+ encryption**: External endpoints (Route to OAuth Proxy) and backend egress (K8s API, Image Registry)
- **Service Serving Cert**: Auto-rotated TLS certificate for internal service communication
- **RBAC**: Cluster-scoped and namespace-scoped roles with fine-grained permissions
- **Non-root execution**: Containers run as non-root user (UID 65532)
- **Internal HTTP**: Backend uses HTTP only on localhost (8080) since it's accessed via OAuth proxy sidecar in same pod
- **Metrics endpoint**: /metrics bypasses authentication for Prometheus scraping (standard practice)

### RBAC Model
Two-tier RBAC:
1. **Cluster-scoped (ClusterRole: odh-dashboard)**:
   - ServiceAccount: odh-dashboard (namespace: redhat-ods-applications)
   - Permissions: Nodes, ClusterVersions, CSVs, Subscriptions, Routes, ConsoleLinks, Users, Groups, Namespaces (CRUD), RoleBindings, Roles, Events, Notebooks, DataScienceClusters, DSCInitializations, ModelRegistries
2. **Namespace-scoped (Role: odh-dashboard)**:
   - Namespace: redhat-ods-applications
   - Permissions: AcceleratorProfiles, OdhDashboardConfigs, OdhApplications, OdhDocuments, OdhQuickStarts, ImageStreams, Builds, BuildConfigs, Jobs, Deployments, Templates, ServingRuntimes (full CRUD)
3. **Additional ClusterRoleBindings**:
   - system:auth-delegator (authentication delegation to K8s API)
   - cluster-monitoring-view (read-only Prometheus access)
   - system:image-puller (pull images from registry)

### Dependencies
- **Required external**: Node.js 18.0.0+, React 18.2.0, PatternFly 5.3.x, Fastify 4.16.0, Kubernetes Client 0.12.2, OAuth Proxy (openshift4/ose-oauth-proxy), OpenShift OAuth Server
- **Core platform**: Kubernetes API Server (6443/HTTPS TLS1.2+), Prometheus (9091/HTTP), OpenShift Image Registry (5000/HTTPS TLS1.2+)
- **Internal ODH**: ODH Operator (DataScienceCluster/DSCInit monitoring), Kubeflow Notebooks (Notebook CR CRUD), KServe (ServingRuntime templates), Model Registry Operator (ModelRegistry CR CRUD), OpenShift Build Service (BuildConfig creation)
- **Optional**: S3 storage (for user data connections)

### Integration Points
- **Kubernetes API Server**: CRUD operations on all resources via user impersonation
- **OpenShift OAuth Server**: User authentication and authorization (OAuth 2.0, 443/HTTPS)
- **Prometheus**: PromQL metrics queries (9091/HTTP, ServiceAccount Token)
- **Kubeflow Notebook Controller**: Dashboard creates Notebook CRs, controller manages lifecycle
- **KServe Controller**: Dashboard reads ServingRuntime templates from cluster
- **ODH Operator**: Dashboard monitors DataScienceCluster and DSCInitialization CRs
- **Model Registry Operator**: Dashboard creates and manages ModelRegistry CRs
- **OpenShift Console**: Dashboard registers ConsoleLink for navigation integration

---

## RHODS Operator

**Generated from**: `architecture/rhoai-2.13/rhods-operator.md`
**Version**: v1.6.0-2256-g3f6121927 (RHOAI 2.13)
**Date**: 2026-03-15

### Available Diagrams
- [Component Structure](./rhods-operator-component.png) ([mmd](./rhods-operator-component.mmd))
- [Data Flows](./rhods-operator-dataflow.png) ([mmd](./rhods-operator-dataflow.mmd))
- [Dependencies](./rhods-operator-dependencies.png) ([mmd](./rhods-operator-dependencies.mmd))
- [C4 Context](./rhods-operator-c4-context.dsl)
- [Security Network (PNG)](./rhods-operator-security-network.png) | [Mermaid](./rhods-operator-security-network.mmd) | [ASCII](./rhods-operator-security-network.txt)
- [RBAC Visualization](./rhods-operator-rbac.png) ([mmd](./rhods-operator-rbac.mmd))

### Component Overview
Shows the RHODS Operator architecture including:
- **Controllers**: DataScienceCluster Controller (component lifecycle), DSCInitialization Controller (platform initialization), SecretGenerator Controller (OAuth clients), CertConfigmapGenerator Controller (trusted CA bundles)
- **Custom Resources**: DataScienceCluster (component enablement), DSCInitialization (platform config), FeatureTracker (resource tracking)
- **Managed Components**: Dashboard, Notebooks, KServe, ModelMesh, Data Science Pipelines, CodeFlare, KubeRay, Training Operator, Kueue, TrustyAI
- **Manifest Management**: Dynamic fetching from GitHub repos, Kustomize transformations, apply operations
- **External Dependencies**: Kubernetes API, Service Mesh (conditional), Serverless (conditional), Authorino (conditional), Pipelines (conditional), Prometheus Operator
- **External Services**: GitHub (manifest repos), quay.io (images), registry.redhat.io (Red Hat images)

### Data Flows
Four key flows illustrated:
1. **Component Deployment via DataScienceCluster**: User creates DSC CR → Controller fetches manifests from GitHub → Applies Kustomize transformations → Deploys to Kubernetes
2. **Monitoring Metrics Collection**: Prometheus scrapes operator metrics endpoint and component metrics via ServiceAccount tokens
3. **Platform Initialization via DSCInitialization**: Controller creates namespaces (redhat-ods-applications, redhat-ods-monitoring) → Configures Service Mesh → Deploys Prometheus/Alertmanager → Configures trusted CA bundles
4. **OAuth Client Generation**: SecretGenerator gets Route hostname → Creates OAuthClient CR → Provisions secrets for component authentication

### Security Network Architecture
Comprehensive network architecture showing:
- **Trust zones**: External (untrusted), Kubernetes Control Plane, Operator Namespace, Monitoring Namespace, Managed Namespaces, External Services
- **Network flows**: All ports, protocols, encryption (TLS 1.2+ for external, HTTP plaintext for metrics, TLS/mTLS for monitoring)
- **Operator pod security**: runAsNonRoot, no privilege escalation, capabilities dropped, CPU 100m-500m, Memory 780Mi-4Gi
- **Metrics endpoint**: 8443/TCP HTTP (no encryption), ServiceAccount Token required, internal-only via Kubernetes API proxy
- **Monitoring stack**: Prometheus (9091/TCP HTTPS with service-ca TLS, mTLS), Alertmanager (9093/TCP HTTP internal, 443/TCP HTTPS via Route with OAuth)
- **Routes**: TLS passthrough/edge termination with OpenShift OAuth authentication
- **Egress**: GitHub (443/HTTPS public), quay.io (443/HTTPS public), registry.redhat.io (443/HTTPS with pull secret)
- **RBAC summary**: Extensive ClusterRole permissions on core, apps, RBAC, OpenShift, networking, monitoring, OLM, model serving, pipelines, workload resources
- **Secrets**: prometheus-tls (service-ca, auto-rotated), webhook-server-cert (cert-manager/manual), OAuth client secrets (operator-generated), registry pull secret (OpenShift global)

### Key Features
- **Central Orchestration**: Primary operator managing all RHOAI components via DataScienceCluster CR
- **Declarative Deployment**: Kustomize-based manifest deployment from Git repositories
- **Platform Initialization**: Namespace creation, Service Mesh integration, monitoring stack, trusted CA bundles
- **Flexible Component Management**: Enable/disable components individually, supports DevFlags for custom manifests
- **OAuth Integration**: Automatic OAuth client generation for component authentication
- **Single Instance Design**: One DataScienceCluster and one DSCInitialization per cluster
- **Component Conflicts**: Enforces mutual exclusivity (e.g., KServe vs ModelMesh)
- **Version Management**: Upgrade detection, deprecation cleanup, status tracking

### Security Features
- **ServiceAccount Token authentication**: All Kubernetes API calls use ServiceAccount tokens with RBAC enforcement
- **TLS 1.2+ encryption**: All external communication (GitHub, container registries, Routes)
- **Monitoring TLS/mTLS**: Prometheus uses service-ca TLS certificates with mTLS for Alertmanager communication
- **OAuth Routes**: OpenShift Routes with TLS termination and OAuth authentication
- **Pull Secret Auth**: registry.redhat.io access via OpenShift global pull secret
- **Restricted Pod Security**: runAsNonRoot, no privilege escalation, all capabilities dropped
- **Namespace Isolation**: Components deployed in dedicated namespaces with NetworkPolicies
- **RBAC**: Cluster-scoped ClusterRole with fine-grained permissions for all managed resources

### RBAC Model
Cluster-scoped operator with:
- **ServiceAccount**: controller-manager (namespace: redhat-ods-operator)
- **ClusterRole**: controller-manager-role with comprehensive permissions:
  - Core resources (secrets, configmaps, serviceaccounts, namespaces, services, pvcs, pods, events)
  - Apps (deployments, statefulsets, replicasets)
  - RBAC (roles, rolebindings, clusterroles, clusterrolebindings)
  - OpenShift (routes, oauthclients, consolelinks, odhquickstarts, clusterversions, authentications, ingresses)
  - Networking (networkpolicies, ingresses)
  - Monitoring (servicemonitors, prometheusrules, podmonitors)
  - OLM (subscriptions, clusterserviceversions)
  - Model Serving (inferenceservices, servingruntimes, knative services, authconfigs)
  - Pipelines (tekton.dev/* - all resources)
  - Workload (jobs, cronjobs, horizontalpodautoscalers)
  - Custom CRDs (datascienceclusters, dscinitializations, featuretrackers, customresourcedefinitions)
- **ClusterRoleBinding**: controller-manager-rolebinding grants ClusterRole to ServiceAccount cluster-wide

### Dependencies
- **Required external**: Kubernetes/OpenShift 1.28+, controller-runtime v0.17.5
- **Conditional external**: OpenShift Service Mesh (KServe/SSO), OpenShift Serverless (KServe), Authorino Operator (KServe), OpenShift Pipelines (DSP)
- **Optional external**: Prometheus Operator v0.68.0
- **Internal ODH (deployed)**: odh-dashboard, odh-notebook-controller, kserve, modelmesh-serving, data-science-pipelines-operator, codeflare-operator, kuberay-operator, training-operator, kueue, trustyai-operator
- **External Services**: GitHub (manifest repos), quay.io (container images), registry.redhat.io (Red Hat images)

### Managed Components
All components deployed via manifest-based Kustomize approach:
- **Dashboard** (opendatahub-io/odh-dashboard) - Default: Managed
- **Workbenches** (opendatahub-io/notebooks) - Default: Managed
- **DataSciencePipelines** (opendatahub-io/data-science-pipelines-operator) - Default: Removed, Requires: OpenShift Pipelines
- **KServe** (kserve/kserve) - Default: Removed, Requires: Service Mesh, Serverless, Authorino, Incompatible: ModelMesh
- **ModelMeshServing** (opendatahub-io/modelmesh-serving) - Default: Removed, Incompatible: KServe
- **CodeFlare** (project-codeflare/codeflare-operator) - Default: Removed
- **Ray** (ray-project/kuberay) - Default: Removed
- **Kueue** (kubernetes-sigs/kueue) - Default: Removed
- **TrainingOperator** (kubeflow/training-operator) - Default: Removed
- **TrustyAI** (trustyai-explainability/trustyai-service-operator) - Default: Removed

Each component supports DevFlags for custom manifest URIs (uri, contextDir, sourcePath).

### Integration Points
- **Kubernetes API Server**: Primary control plane interface (HTTPS/6443, TLS 1.2+, ServiceAccount Token)
- **OpenShift Service Mesh**: CRD-based configuration for Istio integration (KServe, SSO)
- **Prometheus Operator**: ServiceMonitor CRD deployment for monitoring stack
- **Component Git Repositories**: HTTPS manifest fetching (GitHub, TLS 1.2+)
- **Component Operators**: CRD management for deployed components (KServe, DSP, CodeFlare, etc.)

### Known Limitations
1. **Single Instance**: Only one DataScienceCluster CR supported per cluster
2. **Single DSCI**: Only one DSCInitialization CR supported per cluster
3. **Component Conflicts**: KServe and ModelMeshServing cannot be enabled simultaneously
4. **Namespace Constraints**: Application namespace defaults to redhat-ods-applications (not user-configurable)
5. **Manifest Caching**: Manifests embedded in operator image, updates require operator rebuild

---

## TrustyAI Service Operator

**Generated from**: `architecture/rhoai-2.13/trustyai-service-operator.md`
**Version**: v1.17.0 (commit a9e7fb8, branch rhoai-2.13)
**Date**: 2026-03-15

### Available Diagrams
- [Component Structure](./trustyai-service-operator-component.png) ([mmd](./trustyai-service-operator-component.mmd))
- [Data Flows](./trustyai-service-operator-dataflow.png) ([mmd](./trustyai-service-operator-dataflow.mmd))
- [Dependencies](./trustyai-service-operator-dependencies.png) ([mmd](./trustyai-service-operator-dependencies.mmd))
- [C4 Context](./trustyai-service-operator-c4-context.dsl)
- [Security Network (PNG)](./trustyai-service-operator-security-network.png) | [Mermaid](./trustyai-service-operator-security-network.mmd) | [ASCII](./trustyai-service-operator-security-network.txt)
- [RBAC Visualization](./trustyai-service-operator-rbac.png) ([mmd](./trustyai-service-operator-rbac.mmd))

### Component Overview
Shows the TrustyAI Service Operator architecture including:
- **Operator Controller**: TrustyAI Operator Controller (Go Controller-Runtime based) managing TrustyAIService CRD lifecycle
- **Managed Services**: TrustyAI Service (Quarkus application providing AI explainability and bias detection), OAuth Proxy (sidecar for OpenShift OAuth authentication)
- **Custom Resources**: TrustyAIService (trustyai.opendatahub.io/v1alpha1) defining deployment with storage, metrics schedule, and data format configuration
- **Storage Options**: PersistentVolumeClaim (default, 1Gi, CSV format) or external database (PostgreSQL/MySQL with JDBC)
- **Monitoring**: ServiceMonitor for Prometheus metrics scraping (trustyai_spd, trustyai_dir fairness metrics)
- **KServe Integration**: Automatic payload processor injection into InferenceService deployments for model monitoring
- **External Dependencies**: Kubernetes 1.19+, OpenShift 4.6+ (optional for Routes/OAuth), Prometheus Operator (optional), cert-manager (optional)
- **Internal Dependencies**: KServe (CRD patching), Model Mesh (environment variable injection), ODH Dashboard (route discovery), Prometheus (metrics)

### Data Flows
Five key flows illustrated:
1. **TrustyAI Service Deployment**: User creates TrustyAIService CR → Operator watches CR → Creates Deployment, Services, Route, ServiceMonitor via Kubernetes API
2. **External User Access via Route**: User → OpenShift Router (443/TCP TLS 1.3) → OAuth Proxy (8443/TCP TLS 1.2+, OAuth validation) → TrustyAI Service (8080/TCP HTTP localhost)
3. **Prometheus Metrics Scraping**: Prometheus → TrustyAI Service (80/TCP HTTP, internal ClusterIP) → Metrics response (trustyai_spd, trustyai_dir)
4. **KServe InferenceService Integration**: Operator lists InferenceServices → Patches Deployment env vars (MM_PAYLOAD_PROCESSORS) → Model serving pods send payloads to TrustyAI (443/TCP HTTPS service cert)
5. **Database Storage (Optional)**: TrustyAI Service → Database (3306/5432 JDBC, TLS 1.2+ optional, DB credentials from Secret)

### Security Network Architecture
Comprehensive network architecture showing:
- **Trust zones**: External (untrusted), Ingress/DMZ (OpenShift Router), Application Layer (OAuth + TrustyAI Service), Internal Monitoring (Prometheus), Operator Layer (control plane), Model Serving Integration
- **External access flow**: User → Router (443/TCP TLS 1.3 edge) → {name}-tls Service → OAuth Proxy (8443/TCP TLS 1.2+, OpenShift OAuth validation) → TrustyAI Service (8080/TCP HTTP localhost, trusted)
- **Operator control**: TrustyAI Operator (8080/TCP metrics, 8081/TCP health) ↔ Kubernetes API (6443/TCP HTTPS TLS 1.2+, SA Bearer Token)
- **Metrics scraping**: Prometheus → {name} Service (80/TCP HTTP, internal ClusterIP) → TrustyAI Service (8080/TCP)
- **Model serving integration**: KServe/ModelMesh → TrustyAI Service (443/TCP HTTPS TLS 1.2+, service certificate mTLS)
- **Storage**: PVC (volume mount, CSV) or Database (3306/5432 JDBC, TLS optional, credentials from Secret)
- **Routes**: OpenShift Route (443/TCP HTTPS, TLS re-encrypt, OAuth authentication)
- **Operator endpoints**: /metrics (8080/TCP HTTP, operator metrics for Prometheus), /healthz (8081/TCP HTTP), /readyz (8081/TCP HTTP)
- **Service endpoints**: /q/metrics (8080/TCP HTTP internal, 4443/TCP HTTPS internal TLS), /* (8443/TCP HTTPS OAuth proxy), /* (443/TCP HTTPS via Route)
- **RBAC summary**: Extensive ClusterRole permissions on TrustyAI CRDs, apps (deployments), core (services, configmaps, pods, secrets, serviceaccounts, pvcs, pvs, events), monitoring (servicemonitors), routes, KServe (inferenceservices, servingruntimes), RBAC (clusterrolebindings), coordination (leases)
- **Secrets**: {name}-tls (service cert for OAuth proxy, auto-rotate), {name}-internal (service cert for internal TLS, auto-rotate), {name}-db-credentials (DB auth, manual), {name}-db-tls (DB TLS certs, manual)
- **Service Mesh**: Compatible with Istio via annotations, mTLS configurable for service-to-service communication

### Key Features
- **AI Explainability**: Provides fairness metrics (Statistical Parity Difference, Disparate Impact Ratio) for deployed models
- **OpenShift OAuth Integration**: Automatic OAuth proxy deployment for secure external access
- **Flexible Storage**: Supports PVC (default) or external database (PostgreSQL/MySQL) backends
- **KServe/ModelMesh Integration**: Automatic payload processor injection for model inference monitoring
- **Prometheus Metrics**: Exposes trustyai_spd and trustyai_dir metrics via ServiceMonitor
- **OpenShift Route**: Automatic external access with TLS re-encrypt termination
- **Dual Service Endpoints**: Internal HTTP (monitoring) and HTTPS (service cert), external HTTPS (OAuth)
- **Database TLS**: Optional TLS encryption for JDBC connections
- **Controller-Runtime**: Built on standard Kubernetes controller patterns with leader election

### Security Features
- **Encryption in Transit**: All external access via HTTPS with TLS 1.2+, re-encrypt termination for OpenShift Routes, internal service-to-service TLS optional via service certs
- **Authentication**: OpenShift OAuth for external user access (Bearer Token), ServiceAccount tokens for Kubernetes API access, database credentials stored in Secrets
- **Authorization**: OpenShift SAR (SubjectAccessReview) for OAuth proxy (namespace={ns}, resource=pods, verb=get), RBAC policies for operator permissions, namespace isolation for multi-tenant deployments
- **Secret Management**: TLS certificates auto-provisioned by OpenShift service cert controller (auto-rotate), database credentials managed by users (no hardcoded secrets)
- **Network Policies**: No default NetworkPolicies defined (users should implement namespace-level policies), service mesh integration possible via Istio annotations
- **Pod Security**: Operator runs as non-root, resource limits enforced (CPU 10m-500m, Memory 64Mi-128Mi)

### RBAC Model
Cluster-scoped operator with:
- **ServiceAccount**: controller-manager (operator namespace)
- **ClusterRole**: manager-role with comprehensive permissions:
  - TrustyAI CRDs (trustyaiservices, trustyaiservices/status, trustyaiservices/finalizers) - get, list, watch, create, update, patch, delete
  - Apps (deployments, deployments/status, deployments/finalizers) - get, list, watch, create, update, patch, delete
  - Core (services, configmaps, pods, secrets, serviceaccounts, persistentvolumeclaims) - get, list, watch, create, update, patch, delete
  - Core (persistentvolumes) - get, list, watch
  - Core (events) - create, patch, update
  - Monitoring (servicemonitors) - create, list, watch
  - Routes (routes) - get, list, watch, create, update, patch, delete
  - KServe (inferenceservices, inferenceservices/finalizers, servingruntimes, servingruntimes/status) - get, list, watch, update, patch, delete, create
  - RBAC (clusterrolebindings) - get, list, watch, create, update, delete
  - Coordination (leases) - get, create, update
- **ClusterRole**: auth-proxy-client-clusterrole for ServiceAccount token validation:
  - authentication.k8s.io (tokenreviews) - create
  - authorization.k8s.io (subjectaccessreviews) - create
- **Role**: leader-election-role (operator namespace) for leader election:
  - Core (configmaps) - get, list, watch, create, update, patch, delete
  - Coordination (leases) - get, list, watch, create, update, patch, delete
  - Core (events) - create, patch
- **Per-Service RBAC**: Each TrustyAIService creates ServiceAccount {name}-proxy with OAuth SAR permissions (resource=pods, verb=get, namespace={ns})

### Dependencies
- **Required external**: Kubernetes 1.19+
- **Optional external**: OpenShift 4.6+ (for Routes and OAuth), Prometheus Operator v0.x (for ServiceMonitor), cert-manager (for custom cert management), PostgreSQL/MySQL (for database storage)
- **Internal ODH/RHOAI**: KServe (CRD patching for payload processors), Model Mesh (environment variable injection), ODH Dashboard (route discovery), Prometheus (metrics scraping)
- **External Services**: Kubernetes API Server (6443/TCP HTTPS, TLS 1.2+), OpenShift OAuth Server (443/TCP HTTPS, OAuth 2.0), OpenShift Router (443/TCP HTTPS, re-encrypt), Database Service (3306/5432 JDBC, TLS optional)

### Storage Options
Two storage backends supported:
1. **PVC Storage (default)**: Format: PVC, configurable size (default 1Gi), folder path for data storage, data format: CSV or custom
2. **Database Storage (optional)**: Format: DATABASE, supported: PostgreSQL/MySQL, JDBC connection via secrets, optional TLS certificate support, Hibernate ORM for data persistence

### Monitoring and Observability
- **Metrics**: trustyai_spd (Statistical Parity Difference fairness metric), trustyai_dir (Disparate Impact Ratio fairness metric), controller_runtime_* (standard controller-runtime metrics)
- **Health Checks**: /healthz (8081/TCP HTTP, operator liveness), /readyz (8081/TCP HTTP, operator readiness), /oauth/healthz (8443/TCP HTTPS, OAuth proxy liveness and readiness)
- **ServiceMonitor**: Prometheus CRD for automatic metrics scraping configuration

### Known Limitations
1. **Platform Support**: Route and OAuth features require OpenShift (Kubernetes requires alternative ingress), ServiceMonitor requires Prometheus Operator
2. **Scalability**: Operator runs single replica with leader election support, TrustyAI services default to 1 replica (configurable)
3. **Storage**: PVC storage requires ReadWriteMany for multi-replica deployments, database mode recommended for high-availability scenarios
4. **KServe Integration**: Requires KServe v1alpha1 or v1beta1 APIs, supports ModelMesh and Serverless deployment modes, automatic payload processor injection may require model redeployment

---

## How to Use Diagrams

All Mermaid diagrams are available in both `.mmd` (source) and `.png` (3000px width, high-resolution) formats.

### PNG Files (.png files)
**Automatically generated** at 3000px width for high-resolution presentations and documentation.

- **Ready to use**: High-resolution images suitable for presentations, wikis, and documentation
- **Width**: 3000px (height auto-adjusts to content)
- **Use directly**: Include in PowerPoint, Google Slides, Confluence, etc.

### Mermaid Source Files (.mmd files)
- **In GitHub/GitLab**: Paste into markdown with ` ```mermaid ` code blocks - renders automatically!
- **Live editor**: https://mermaid.live (paste code, edit, export)
- **Editable**: Modify and regenerate if needed

**Manual PNG regeneration** (if you edit .mmd files):

1. **Ensure Mermaid CLI is installed**:
   ```bash
   npm install -g @mermaid-js/mermaid-cli
   ```

2. **Regenerate PNG** (3000px width):
   ```bash
   PUPPETEER_EXECUTABLE_PATH=/usr/bin/google-chrome mmdc -i diagram.mmd -o diagram.png -w 3000
   ```

3. **Alternative formats** (if needed):
   ```bash
   # SVG (vector, scales perfectly)
   PUPPETEER_EXECUTABLE_PATH=/usr/bin/google-chrome mmdc -i diagram.mmd -o diagram.svg

   # PDF
   PUPPETEER_EXECUTABLE_PATH=/usr/bin/google-chrome mmdc -i diagram.mmd -o diagram.pdf
   ```

**Note**: If `google-chrome` is not found, try `chromium` or `which google-chrome` to locate it

### C4 Diagrams (.dsl files)
- **Structurizr Lite**: `docker run -p 8080:8080 -v .:/usr/local/structurizr structurizr/lite`
- **CLI export**: `structurizr-cli export -workspace diagram.dsl -format png`

### ASCII Diagrams (.txt files)
- View in any text editor
- Include in documentation as-is
- Perfect for security reviews (precise technical details)

## Updating Diagrams

To regenerate after architecture changes:
```bash
# Ensure you're in the repository root
cd /path/to/rhoai-architecture-diagrams

# Regenerate diagrams for a specific component
python scripts/generate_architecture_diagrams.py \
  --architecture=architecture/rhoai-2.13/{component-name}.md

# Batch regenerate using the Python script
python scripts/generate_diagram_pngs.py architecture/rhoai-2.13/diagrams --width=3000
```

Or use the generation tool/skill with the appropriate parameters.

---

## Diagram Format Reference

### Component Diagram (.mmd)
Shows internal component structure, CRDs, deployments, and dependencies

### Data Flow Diagram (.mmd)
Sequence diagram showing request/response flows with ports, protocols, and authentication

### Security Network Diagram (.txt + .mmd)
- **ASCII (.txt)**: Precise text format for Security Architecture Reviews
- **Mermaid (.mmd)**: Visual color-coded trust zones for presentations

### C4 Context Diagram (.dsl)
System context in Structurizr DSL showing component in broader ecosystem

### Dependency Graph (.mmd)
Component dependency visualization (required vs optional, internal vs external)

### RBAC Visualization (.mmd)
RBAC hierarchy showing ServiceAccounts, Roles, and API resource permissions
