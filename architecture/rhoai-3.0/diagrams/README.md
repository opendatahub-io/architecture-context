# Architecture Diagrams for RHOAI 3.0 Components

This directory contains auto-generated architecture diagrams for all RHOAI 3.0 components.

Generated from: `architecture/rhoai-3.0/*.md`
Date: 2026-03-15

**Note**: Diagram filenames use base component name without version (directory is already versioned).

## Available Components

- [Data Science Pipelines Operator](#data-science-pipelines-operator)
- [Feast](#feast)
- [KServe](#kserve)
- [Kubeflow (Notebook Controller)](#kubeflow-notebook-controller)
- [KubeRay](#kuberay)
- [Llama Stack Kubernetes Operator](#llama-stack-kubernetes-operator)
- [Model Registry Operator](#model-registry-operator)
- [Notebooks](#notebooks)
- [ODH Dashboard](#odh-dashboard)
- [ODH Model Controller](#odh-model-controller)
- [Platform (Aggregated)](#platform-aggregated)

---

## Data Science Pipelines Operator

### For Developers
- [Component Structure](./data-science-pipelines-operator-component.png) ([mmd](./data-science-pipelines-operator-component.mmd)) - Mermaid diagram showing internal components
- [Data Flows](./data-science-pipelines-operator-dataflow.png) ([mmd](./data-science-pipelines-operator-dataflow.mmd)) - Sequence diagram of request/response flows

### For Security Teams
- [Security Network Diagram (PNG)](./data-science-pipelines-operator-security-network.png) - High-resolution network topology
- [Security Network Diagram (Mermaid)](./data-science-pipelines-operator-security-network.mmd) - Visual network topology (editable)

---

## Feast

All Mermaid diagrams are available in both `.mmd` (source) and `.png` (3000px width, high-resolution) formats.

### For Developers
- [Component Structure](./feast-component.png) ([mmd](./feast-component.mmd)) - Mermaid diagram showing operator, feature servers (online/offline/registry/UI), and storage backends
- [Data Flows](./feast-dataflow.png) ([mmd](./feast-dataflow.mmd)) - Sequence diagrams for online/offline feature retrieval, materialization, and registry management
- [Dependencies](./feast-dependencies.png) ([mmd](./feast-dependencies.mmd)) - Component dependency graph showing external and internal ODH dependencies

### For Architects
- [C4 Context](./feast-c4-context.dsl) - System context in C4 format (Structurizr) showing Feast operator in broader ecosystem
- [Component Overview](./feast-component.png) ([mmd](./feast-component.mmd)) - High-level component view with operator and feature servers

### For Security Teams
- [Security Network Diagram (PNG)](./feast-security-network.png) - High-resolution network topology with trust zones
- [Security Network Diagram (Mermaid)](./feast-security-network.mmd) - Visual network topology (editable)
- [Security Network Diagram (ASCII)](./feast-security-network.txt) - Precise text format for SAR submissions with RBAC, Service Mesh config, and secrets
- [RBAC Visualization](./feast-rbac.png) ([mmd](./feast-rbac.mmd)) - RBAC permissions and bindings for operator and feature servers

---

## KServe

### For Developers
- [Component Structure](./kserve-component.png) ([mmd](./kserve-component.mmd)) - Mermaid diagram showing internal components
- [Data Flows](./kserve-dataflow.png) ([mmd](./kserve-dataflow.mmd)) - Sequence diagram of standard inference flows
- [Data Flows (InferenceGraph)](./kserve-dataflow-inferencegraph.png) ([mmd](./kserve-dataflow-inferencegraph.mmd)) - InferenceGraph workflow
- [Data Flows (LLM)](./kserve-dataflow-llm.png) ([mmd](./kserve-dataflow-llm.mmd)) - LLM inference workflow

### For Security Teams
- [Security Network Diagram (PNG)](./kserve-security-network.png) - High-resolution network topology
- [Security Network Diagram (Mermaid)](./kserve-security-network.mmd) - Visual network topology (editable)

---

## Kubeflow (Notebook Controller)

All Mermaid diagrams are available in both `.mmd` (source) and `.png` (3000px width, high-resolution) formats.

### For Developers
- [Component Structure](./kubeflow-component.png) ([mmd](./kubeflow-component.mmd)) - Mermaid diagram showing internal components, controllers, and managed resources
- [Data Flows](./kubeflow-dataflow.png) ([mmd](./kubeflow-dataflow.mmd)) - Sequence diagram of notebook creation, culling, metrics collection, and restart flows
- [Dependencies](./kubeflow-dependencies.png) ([mmd](./kubeflow-dependencies.mmd)) - Component dependency graph showing external and internal ODH dependencies

### For Architects
- [C4 Context](./kubeflow-c4-context.dsl) - System context in C4 format (Structurizr) showing Notebook Controller in broader ecosystem
- [Component Overview](./kubeflow-component.png) ([mmd](./kubeflow-component.mmd)) - High-level component view with controllers and integrations

### For Security Teams
- [Security Network Diagram (PNG)](./kubeflow-security-network.png) - High-resolution network topology with trust boundaries
- [Security Network Diagram (Mermaid)](./kubeflow-security-network.mmd) - Visual network topology (editable)
- [Security Network Diagram (ASCII)](./kubeflow-security-network.txt) - Precise text format for SAR submissions with RBAC, Service Mesh config, and secrets
- [RBAC Visualization](./kubeflow-rbac.png) ([mmd](./kubeflow-rbac.mmd)) - RBAC permissions and bindings for notebook-controller-service-account

---

## KubeRay

### For Developers
- [Component Structure](./kuberay-component.png) ([mmd](./kuberay-component.mmd)) - Mermaid diagram showing KubeRay operator, controllers, and managed resources
- [Data Flows](./kuberay-dataflow.png) ([mmd](./kuberay-dataflow.mmd)) - Sequence diagram of RayCluster creation, RayJob execution, and metrics collection flows
- [Dependencies](./kuberay-dependencies.png) ([mmd](./kuberay-dependencies.mmd)) - Component dependency graph showing optional integrations (cert-manager, Gateway API, Volcano, Kueue)

### For Architects
- [C4 Context](./kuberay-c4-context.dsl) - System context in C4 format (Structurizr) showing KubeRay operator in broader ecosystem
- [Component Overview](./kuberay-component.png) ([mmd](./kuberay-component.mmd)) - High-level component view with controllers and Ray cluster management

### For Security Teams
- [Security Network Diagram (PNG)](./kuberay-security-network.png) - High-resolution network topology with trust boundaries
- [Security Network Diagram (Mermaid)](./kuberay-security-network.mmd) - Visual network topology (editable)
- [Security Network Diagram (ASCII)](./kuberay-security-network.txt) - Precise text format for SAR submissions with RBAC, Network Policies, and SCC config
- [RBAC Visualization](./kuberay-rbac.png) ([mmd](./kuberay-rbac.mmd)) - RBAC permissions and bindings for kuberay-operator service account

---

## Llama Stack Kubernetes Operator

All Mermaid diagrams are available in both `.mmd` (source) and `.png` (3000px width, high-resolution) formats.

### For Developers
- [Component Structure](./llama-stack-k8s-operator-component.png) ([mmd](./llama-stack-k8s-operator-component.mmd)) - Mermaid diagram showing operator controller, internal components, managed resources per CR, and inference providers
- [Data Flows](./llama-stack-k8s-operator-dataflow.png) ([mmd](./llama-stack-k8s-operator-dataflow.mmd)) - Sequence diagrams for LlamaStackDistribution creation, health checks, inference requests, and metrics collection
- [Dependencies](./llama-stack-k8s-operator-dependencies.png) ([mmd](./llama-stack-k8s-operator-dependencies.mmd)) - Component dependency graph showing Kubernetes dependencies, inference backends (Ollama, vLLM, TGI, Bedrock, Together), and managed resources

### For Architects
- [C4 Context](./llama-stack-k8s-operator-c4-context.dsl) - System context in C4 format (Structurizr) showing operator in AI inference ecosystem
- [Component Overview](./llama-stack-k8s-operator-component.png) ([mmd](./llama-stack-k8s-operator-component.mmd)) - High-level component view with operator internals and multi-backend support

### For Security Teams
- [Security Network Diagram (PNG)](./llama-stack-k8s-operator-security-network.png) - High-resolution network topology with operator and user namespaces
- [Security Network Diagram (Mermaid)](./llama-stack-k8s-operator-security-network.mmd) - Visual network topology (editable)
- [Security Network Diagram (ASCII)](./llama-stack-k8s-operator-security-network.txt) - Precise text format for SAR submissions with RBAC, NetworkPolicy, and security configuration
- [RBAC Visualization](./llama-stack-k8s-operator-rbac.png) ([mmd](./llama-stack-k8s-operator-rbac.mmd)) - RBAC permissions and bindings for operator and managed resources

---

## Model Registry Operator

All Mermaid diagrams are available in both `.mmd` (source) and `.png` (3000px width, high-resolution) formats.

### For Developers
- [Component Structure](./model-registry-operator-component.png) ([mmd](./model-registry-operator-component.mmd)) - Mermaid diagram showing operator controller, webhook server, model registry instances (REST/gRPC/kube-rbac-proxy), and database backends
- [Data Flows](./model-registry-operator-dataflow.png) ([mmd](./model-registry-operator-dataflow.mmd)) - Sequence diagrams for authenticated model registry queries, internal gRPC calls, operator reconciliation, and webhook validation
- [Dependencies](./model-registry-operator-dependencies.png) ([mmd](./model-registry-operator-dependencies.mmd)) - Component dependency graph showing external dependencies (PostgreSQL/MySQL, OpenShift Service CA, Istio) and internal ODH/RHOAI integrations

### For Architects
- [C4 Context](./model-registry-operator-c4-context.dsl) - System context in C4 format (Structurizr) showing operator and model registry instances in the ODH/RHOAI ecosystem
- [Component Overview](./model-registry-operator-component.png) ([mmd](./model-registry-operator-component.mmd)) - High-level component view with operator and per-instance deployments

### For Security Teams
- [Security Network Diagram (PNG)](./model-registry-operator-security-network.png) - High-resolution network topology with trust boundaries
- [Security Network Diagram (Mermaid)](./model-registry-operator-security-network.mmd) - Visual network topology (editable) with color-coded zones
- [Security Network Diagram (ASCII)](./model-registry-operator-security-network.txt) - Precise text format for SAR submissions with complete RBAC, secrets, and authentication details
- [RBAC Visualization](./model-registry-operator-rbac.png) ([mmd](./model-registry-operator-rbac.mmd)) - RBAC permissions and bindings for operator controller-manager and per-registry service accounts

---

## ODH Dashboard

All Mermaid diagrams are available in both `.mmd` (source) and `.png` (3000px width, high-resolution) formats.

### For Developers
- [Component Structure](./odh-dashboard-component.png) ([mmd](./odh-dashboard-component.mmd)) - Mermaid diagram showing React SPA frontend, Node.js/Fastify backend, kube-rbac-proxy sidecar, custom resources watched, and ODH component integrations
- [Data Flows](./odh-dashboard-dataflow.png) ([mmd](./odh-dashboard-dataflow.mmd)) - Sequence diagrams for user authentication (OAuth2), API requests to Kubernetes, Prometheus metrics queries, and notebook creation flows
- [Dependencies](./odh-dashboard-dependencies.png) ([mmd](./odh-dashboard-dependencies.mmd)) - Component dependency graph showing external dependencies (Node.js, React, PatternFly, OpenShift OAuth) and internal ODH integrations

### For Architects
- [C4 Context](./odh-dashboard-c4-context.dsl) - System context in C4 format (Structurizr) showing dashboard as the primary UI for ODH/RHOAI platform management
- [Component Overview](./odh-dashboard-component.png) ([mmd](./odh-dashboard-component.mmd)) - High-level component view with frontend, backend, and OAuth proxy containers

### For Security Teams
- [Security Network Diagram (PNG)](./odh-dashboard-security-network.png) - High-resolution network topology with trust boundaries and authentication flows
- [Security Network Diagram (Mermaid)](./odh-dashboard-security-network.mmd) - Visual network topology (editable) with color-coded zones (External, Ingress, Cluster Network, Auth Services)
- [Security Network Diagram (ASCII)](./odh-dashboard-security-network.txt) - Precise text format for SAR submissions with complete RBAC (ClusterRole + namespace Role), secrets, OAuth2 flow, and ServiceAccount token authentication
- [RBAC Visualization](./odh-dashboard-rbac.png) ([mmd](./odh-dashboard-rbac.mmd)) - RBAC permissions and bindings for odh-dashboard service account with cluster-wide and namespace-scoped roles

---

## Diagram Details

### Component Structure (`kubeflow-component.mmd/png`)
Shows the internal architecture of the Notebook Controller including:
- **NotebookReconciler**: Main controller watching Notebook CRs and managing StatefulSet/Service lifecycle
- **CullingReconciler**: Optional controller for idle notebook detection and culling
- **Metrics Collector**: Prometheus metrics exporter
- **Health/Readiness Probes**: Kubernetes liveness/readiness endpoints
- **VirtualService Generator**: Istio integration (when USE_ISTIO=true)
- **Event Recorder**: Event propagation to parent Notebook CR
- Custom Resource Definitions (v1, v1beta1, v1alpha1)
- Managed resources (StatefulSets, Services, VirtualServices)
- External dependencies (Kubernetes API, Istio, Prometheus)
- Internal ODH dependencies (jupyter-web-app, odh-dashboard, notebook-images)

### Data Flow Diagrams (`kubeflow-dataflow.mmd/png`)
Sequence diagrams showing:
1. **Notebook Creation**: User/jupyter-web-app → Kubernetes API → NotebookReconciler → StatefulSet/Service/VirtualService creation
2. **Idle Notebook Culling**: CullingReconciler polls /api/kernels → checks idle time → adds STOP_ANNOTATION → NotebookReconciler scales to 0
3. **Metrics Collection**: Prometheus scrapes /metrics → Controller lists StatefulSets → returns metrics
4. **Notebook Restart on ConfigMap Update**: User annotates Notebook → NotebookReconciler deletes Pod → StatefulSet recreates Pod

Technical details included:
- Port numbers (6443/TCP, 8888/TCP, 8080/TCP, 8081/TCP)
- Protocols (HTTPS, HTTP)
- Encryption (TLS 1.2+, plaintext)
- Authentication (ServiceAccount Token, Bearer Token, AuthorizationPolicy)

### Security Network Diagram (`kubeflow-security-network.txt/mmd/png`)
**ASCII version** (`.txt`) - For SAR documentation:
- Precise network topology with all ports, protocols, encryption, authentication
- Trust boundaries (External, Ingress, Service Mesh, External Services)
- RBAC summary (ClusterRoles, RoleBindings, permissions)
- Service Mesh configuration (Istio VirtualService, AuthorizationPolicy)
- Secrets and credentials (ServiceAccount tokens, optional TLS certs)
- Network policies (recommended ingress/egress rules)

**Mermaid version** (`.mmd` + `.png`) - For presentations:
- Visual network flow with color-coded trust zones
- Same technical details as ASCII version
- Editable and high-resolution PNG

### C4 Context Diagram (`kubeflow-c4-context.dsl`)
Structurizr DSL showing:
- **Person**: Data Scientist
- **Software System**: Notebook Controller (with containers: NotebookReconciler, CullingReconciler, Metrics Exporter, Health Probes)
- **External Dependencies**: Kubernetes, Istio, Prometheus, controller-runtime
- **Internal ODH Dependencies**: jupyter-web-app, odh-dashboard, notebook-images, odh-notebook-controller
- **Integration points**: How components interact (HTTPS/6443, HTTP/8080, HTTP/8888)

### Dependency Graph (`kubeflow-dependencies.mmd/png`)
Shows:
- **External Dependencies**: Kubernetes v1.22.0+, controller-runtime v0.21.0, Istio (optional), Prometheus (optional), kube-rbac-proxy (optional)
- **Internal ODH Dependencies**: odh-notebook-controller (CRD extension), jupyter-web-app (creates CRs), odh-dashboard (status monitoring), notebook-images (container images)
- **Managed Resources**: StatefulSets, Services, VirtualServices (when USE_ISTIO=true)
- **API Server**: Central hub for all Kubernetes interactions
- **Integration Points**: Culling (polls /api/kernels on notebook pods)

### RBAC Visualization (`kubeflow-rbac.mmd/png`)
Shows:
- **ServiceAccount**: notebook-controller-service-account (namespace: opendatahub)
- **ClusterRoles**:
  - `notebook-controller-role`: Full permissions on notebooks, statefulsets, services, virtualservices; read/delete on pods; create/patch on events
  - `notebook-controller-proxy-role`: Create tokenreviews/subjectaccessreviews for kube-rbac-proxy
- **Role**: `notebook-controller-leader-election-role`: Leader election (configmaps, leases)
- **Bindings**: ClusterRoleBindings and RoleBinding connecting ServiceAccount to roles
- **API Resources**: Visual representation of which resources each role can access and with which verbs

### KubeRay Operator (`kuberay-*` diagrams)

**Component Purpose**: KubeRay is a Kubernetes operator that manages the lifecycle of Ray clusters for distributed computing and machine learning workloads.

#### Component Structure (`kuberay-component.mmd/png`)
Shows the internal architecture of the KubeRay operator including:
- **KubeRay Operator**: Main operator pod with multiple specialized controllers
- **Controllers**:
  - RayClusterController: Manages RayCluster resources, creates head and worker pods
  - RayJobController: Manages RayJob resources, submits jobs to Ray clusters
  - RayServiceController: Manages RayService resources for Ray Serve deployments
  - NetworkPolicyController: Creates network policies for Ray clusters
  - AuthenticationController: Manages OpenShift OAuth integration
  - mTLSController: Manages cert-manager certificates for Ray cluster mTLS
- **Webhook Server**: Validates and mutates RayCluster resources on CREATE/UPDATE
- **Custom Resources**: RayCluster, RayJob, RayService (ray.io/v1)
- **Managed Resources**: Ray head pods, worker pods, services, network policies, certificates
- **External Dependencies**: Kubernetes API, cert-manager (optional), Gateway API (optional), Volcano/Kueue schedulers (optional)

#### Data Flow Diagrams (`kuberay-dataflow.mmd/png`)
Sequence diagrams showing:
1. **RayCluster Creation**: User/CLI → Kubernetes API → Webhook validation/mutation → RayCluster Controller → Ray head/worker pod creation
2. **RayJob Execution**: User creates RayJob → RayJob Controller creates RayCluster → Job submission to Ray head pod → Task distribution to workers
3. **Metrics Collection**: Prometheus scrapes operator metrics endpoint

Technical details included:
- Port numbers (6443/TCP, 9443/TCP, 8080/TCP, 8265/TCP, 6379/TCP, 10001/TCP)
- Protocols (HTTPS, HTTP, TCP)
- Encryption (TLS 1.2+, optional mTLS)
- Authentication (Bearer Token, mTLS client certificates)

#### Security Network Diagram (`kuberay-security-network.txt/mmd/png`)
**ASCII version** (`.txt`) - For SAR documentation:
- Precise network topology with all ports, protocols, encryption, authentication
- Trust boundaries (External, Kubernetes API, Operator Namespace, User Namespaces, Optional Integrations)
- RBAC summary (ClusterRole kuberay-operator with extensive permissions across multiple API groups)
- Network Policies (created by NetworkPolicy Controller for each RayCluster)
- Security Context Constraints (run-as-ray-user SCC for Ray pods running as user 1000)
- Secrets (kuberay-webhook-server-cert, Ray cluster mTLS certs)

**Mermaid version** (`.mmd` + `.png`) - For presentations:
- Visual network flow with color-coded zones (External, K8s API, Operator NS, User NS, Optional Integrations)
- Same technical details as ASCII version
- Editable and high-resolution PNG

#### C4 Context Diagram (`kuberay-c4-context.dsl`)
Structurizr DSL showing:
- **Person**: Data Scientist / ML Engineer
- **Software System**: KubeRay Operator (with containers: Operator, Webhook Server, and components for each controller)
- **Software System**: Ray Cluster (with containers: Ray Head Pod, Ray Worker Pods)
- **External Dependencies**: Kubernetes API, cert-manager, Gateway API, Volcano, Kueue, Prometheus, OpenShift Service CA
- **Integration points**: How components interact (HTTPS/6443, HTTP/8080, TCP/6379, TCP/10001)

#### Dependency Graph (`kuberay-dependencies.mmd/png`)
Shows:
- **External Dependencies - Required**: Kubernetes 1.24+
- **External Dependencies - Optional**: cert-manager 1.0+, OpenShift Route API 4.x, Gateway API v1/v1beta1, Volcano Scheduler, Yunikorn Scheduler, Kueue, OpenShift Service CA
- **No Internal ODH/RHOAI Dependencies**: KubeRay operates independently
- **Managed Resources**: Ray Clusters (head + worker pods), Network Policies, Kubernetes Resources (services, deployments, jobs)
- **Custom Resources Watched**: RayCluster CR, RayJob CR, RayService CR
- **Monitoring Integration**: Prometheus scrapes metrics from operator

#### RBAC Visualization (`kuberay-rbac.mmd/png`)
Shows:
- **ServiceAccount**: kuberay-operator (namespace: opendatahub)
- **ClusterRole**: kuberay-operator with permissions across multiple API groups:
  - Core API: pods, services, serviceaccounts, configmaps, events, secrets, endpoints
  - apps: deployments
  - batch: jobs
  - ray.io: rayclusters, rayjobs, rayservices (including status and finalizers)
  - networking.k8s.io: ingresses, networkpolicies, ingressclasses
  - route.openshift.io: routes
  - cert-manager.io: certificates, issuers
  - gateway.networking.k8s.io: gateways, httproutes, referencegrants
  - rbac.authorization.k8s.io: roles, rolebindings, clusterroles, clusterrolebindings
  - coordination.k8s.io: leases
  - authentication.k8s.io: tokenreviews
  - authorization.k8s.io: subjectaccessreviews
  - config.openshift.io: authentications, oauths
  - operator.openshift.io: kubeapiservers
- **ClusterRoleBinding**: kuberay-operator (binds ServiceAccount to ClusterRole)
- **API Resources**: Visual representation of permissions with verbs (get, list, watch, create, update, patch, delete)

**Repository**: https://github.com/red-hat-data-services/kuberay
**Version**: dac6aae7
**Branch**: rhoai-3.0
**Distribution**: RHOAI

### Llama Stack Kubernetes Operator (`llama-stack-k8s-operator-*` diagrams)

**Component Purpose**: Llama Stack Kubernetes Operator automates the deployment and lifecycle management of Llama Stack AI inference servers, supporting multiple backend distributions (Ollama, vLLM, TGI, Bedrock, Together) through a single Custom Resource Definition.

#### Component Structure (`llama-stack-k8s-operator-component.mmd/png`)
Shows the internal architecture of the Llama Stack K8s Operator including:
- **Operator Controller Manager**: Main reconciliation process for LlamaStackDistribution CRDs
- **Internal Components**:
  - LlamaStackDistribution Controller: Watches and reconciles custom resources
  - Kustomize Transformer: Dynamically generates Kubernetes manifests from templates
  - Distribution Resolver: Maps distribution names to container images
  - Network Policy Manager: Creates and manages network isolation policies
  - Storage Provisioner: Creates and manages PersistentVolumeClaims for model storage
- **Managed Resources per CR**: ServiceAccount, RoleBinding, PVC (10Gi default), Deployment, Service (8321/TCP), NetworkPolicy
- **Inference Providers**: Ollama (11434/TCP), vLLM (8000/TCP), TGI (8080/TCP), Bedrock, Together
- **External Dependencies**: Kubernetes API, Container Registry (quay.io), HuggingFace Hub (optional)
- **Observability**: kube-rbac-proxy for secured Prometheus metrics (8443/TCP HTTPS)

#### Data Flow Diagrams (`llama-stack-k8s-operator-dataflow.mmd/png`)
Sequence diagrams showing:
1. **LlamaStackDistribution Creation**: User/CI → Kubernetes API → Operator Controller → Creates all managed resources (ServiceAccount, RoleBinding, PVC, Deployment, Service, NetworkPolicy)
2. **Health Check**: Operator Controller → Llama Stack Service (8321/TCP HTTP /providers endpoint) → Status update
3. **Inference Request**: Client → Llama Stack Service → Llama Stack Pod → Inference Provider (Ollama/vLLM/TGI) → Response
4. **Metrics Collection**: Prometheus → kube-rbac-proxy (8443/TCP HTTPS Bearer Token) → Operator Manager (8080/TCP HTTP localhost)

Technical details included:
- Port numbers (6443/TCP, 8080/TCP, 8081/TCP, 8321/TCP, 8443/TCP, 11434/TCP, 8000/TCP)
- Protocols (HTTPS, HTTP)
- Encryption (TLS 1.2+, plaintext HTTP within cluster)
- Authentication (ServiceAccount Token, Bearer Token, none for internal services)

#### Security Network Diagram (`llama-stack-k8s-operator-security-network.txt/mmd/png`)
**ASCII version** (`.txt`) - For SAR documentation:
- Precise network topology with all ports, protocols, encryption, authentication
- Trust boundaries (External, Kubernetes API Server, Operator Namespace, User Namespace, External Services)
- RBAC summary (manager-role, leader-election-role, metrics-reader with detailed permissions)
- NetworkPolicy configuration (restricts ingress to llama-stack components and operator namespace)
- Security Context (non-root UID 1001, no capabilities, no privilege escalation)
- Secrets (user-provided hf-token-secret for HuggingFace model downloads)
- Health probes (/healthz, /readyz on 8081/TCP)

**Mermaid version** (`.mmd` + `.png`) - For presentations:
- Visual network flow with color-coded zones (External, K8s API, Operator NS, User NS, External Services)
- Same technical details as ASCII version
- Editable and high-resolution PNG

#### C4 Context Diagram (`llama-stack-k8s-operator-c4-context.dsl`)
Structurizr DSL showing:
- **Person**: Data Scientist / ML Engineer
- **Software System**: Llama Stack Kubernetes Operator (with containers: Operator Controller Manager, kube-rbac-proxy, Llama Stack Server, and components for each internal module)
- **External Dependencies**: Kubernetes, Ollama Server, vLLM Server, TGI Server, Container Registry (quay.io), HuggingFace Hub, Prometheus
- **Integration points**: How components interact (HTTPS/6443, HTTP/8321, HTTP/11434, HTTP/8000, HTTP/8080)

#### Dependency Graph (`llama-stack-k8s-operator-dependencies.mmd/png`)
Shows:
- **External Dependencies - Required**: Kubernetes 1.20+, controller-runtime v0.20+, Kustomize (embedded), Inference Provider (Ollama/vLLM/TGI/etc)
- **External Dependencies - Optional**: Prometheus Operator, OpenShift SCC
- **External Services**: Container Registry (quay.io), HuggingFace Hub (model downloads)
- **Inference Backends**: Ollama, vLLM, TGI, Bedrock, Together (multiple distribution support)
- **No Internal ODH/RHOAI Dependencies**: Standalone operator with no direct ODH component dependencies
- **Managed Resources**: ServiceAccount, RoleBinding, PVC, Deployment, Service, NetworkPolicy (created per LlamaStackDistribution CR)
- **Internal Components**: Distribution Controller, Kustomize Transformer, Distribution Resolver, Network Policy Manager, Storage Provisioner

#### RBAC Visualization (`llama-stack-k8s-operator-rbac.mmd/png`)
Shows:
- **ServiceAccount**: controller-manager (namespace: redhat-ods-applications)
- **ClusterRole**: manager-role with permissions:
  - llamastack.io: llamastackdistributions (full CRUD + status + finalizers)
  - apps: deployments (full CRUD)
  - core: services, serviceaccounts, configmaps (full CRUD), persistentvolumeclaims (get, list, watch, create)
  - networking.k8s.io: networkpolicies (full CRUD)
  - rbac.authorization.k8s.io: rolebindings (full CRUD), clusterroles (get, list, watch), clusterrolebindings (get, list, delete)
  - security.openshift.io: securitycontextconstraints (use, including anyuid)
- **ClusterRole**: leader-election-role (configmaps, leases, events for leader election)
- **ClusterRole**: metrics-reader (pods, services for Prometheus)
- **User Roles**: llsd-editor-role (full CRUD), llsd-viewer-role (read-only)
- **Bindings**: ClusterRoleBindings and RoleBinding connecting ServiceAccount to roles

**Repository**: https://github.com/red-hat-data-services/llama-stack-k8s-operator
**Version**: v0.4.0
**Distribution**: RHOAI

**Key Features**:
- **Standalone operator**: No direct ODH/RHOAI component dependencies
- **Multi-backend support**: Ollama, vLLM, TGI, Bedrock, Together, custom distributions
- **Kubernetes-native**: Uses standard primitives (CRDs, Deployments, Services, NetworkPolicies)
- **Storage management**: Automatic PVC provisioning for model storage (default 10Gi, configurable)
- **Network isolation**: NetworkPolicy restricts ingress to llama-stack components and operator namespace
- **Security hardened**: Non-root execution (UID 1001), no capabilities, no privilege escalation
- **Configurable**: Custom CA certificates, ConfigMap-based run.yaml, resource limits, volumes, environment variables

### Model Registry Operator (`model-registry-operator-*` diagrams)

**Component Purpose**: Model Registry Operator is a Kubernetes operator that automates the deployment and lifecycle management of Model Registry instances for tracking ML model metadata and artifacts in OpenShift AI and Open Data Hub.

#### Component Structure (`model-registry-operator-component.mmd/png`)
Shows the internal architecture of the Model Registry Operator including:
- **Controller Manager**: Main operator controller that reconciles ModelRegistry CRs and manages lifecycle
- **Webhook Server**: Validates and mutates ModelRegistry CR changes on CREATE/UPDATE (port 9443/TCP)
- **Model Registry Instance Components** (deployed per ModelRegistry CR):
  - **REST Server**: REST API server for model registry operations (port 8080/TCP HTTP)
  - **gRPC Server**: ML Metadata gRPC API sidecar container (port 9090/TCP gRPC)
  - **kube-rbac-proxy**: Authentication proxy with bearer token validation (port 8443/TCP HTTPS)
- **Custom Resources**: ModelRegistry v1alpha1 (deprecated), ModelRegistry v1beta1 (current)
- **External Dependencies**: PostgreSQL 16 or MySQL 8.x (required), OpenShift Service CA (optional), Istio Service Mesh 1.20+ (optional)
- **Internal ODH Dependencies**: opendatahub-operator (platform integration, service-mesh-refs ConfigMap)
- **Managed Resources**: Deployments, Services, OpenShift Routes, NetworkPolicies, Roles/RoleBindings

#### Data Flow Diagrams (`model-registry-operator-dataflow.mmd/png`)
Sequence diagrams showing:
1. **Authenticated Model Registry Query**: External Client → OpenShift Router (443/TCP) → OpenShift Route → kube-rbac-proxy (8443/TCP HTTPS) validates bearer token → REST Server (8080/TCP HTTP) → PostgreSQL/MySQL database
2. **Internal gRPC Call**: Internal Client Pod → gRPC Server (9090/TCP gRPC) → PostgreSQL/MySQL database (ML Metadata operations)
3. **Operator Reconciliation**: Controller Manager ↔ Kubernetes API Server (6443/TCP HTTPS) - watches ModelRegistry CRs, creates/updates resources (Deployments, Services, Routes)
4. **Webhook Validation**: User creates/updates ModelRegistry CR → Kubernetes API Server → Webhook Server (9443/TCP HTTPS, TLS client cert auth) → validation response

Technical details included:
- Port numbers (443/TCP, 6443/TCP, 8080/TCP, 8443/TCP, 9090/TCP, 9443/TCP, 5432/TCP PostgreSQL, 3306/TCP MySQL)
- Protocols (HTTPS, HTTP, gRPC, PostgreSQL, MySQL)
- Encryption (TLS 1.2+, optional database TLS, plaintext HTTP for localhost proxy)
- Authentication (Bearer Token with SubjectAccessReview, ServiceAccount Token, TLS Client Cert, Database Password/Client Cert)

#### Security Network Diagram (`model-registry-operator-security-network.txt/mmd/png`)
**ASCII version** (`.txt`) - For SAR documentation:
- Precise network topology with all ports, protocols, encryption, authentication
- Trust boundaries (External, Ingress/DMZ with OpenShift Router, Application Layer, Operator Namespace, Kubernetes Control Plane, External Database Services)
- RBAC summary:
  - **manager-role** (ClusterRole): Full permissions on modelregistries, deployments, services, routes, networkpolicies, roles, rolebindings, clusterrolebindings, configmaps, secrets, serviceaccounts, groups, storageversionmigrations
  - **modelregistry-editor-role** (ClusterRole): Create/update/delete ModelRegistry CRs
  - **modelregistry-viewer-role** (ClusterRole): Read-only access to ModelRegistry CRs
  - **leader-election-role** (Role): Configmaps and leases for leader election
  - **registry-user-{registry-name}** (Role): Per-registry access control
- NetworkPolicy configuration: {registry-name}-https-route allows ingress from OpenShift Router (namespace selector: network.openshift.io/policy-group=ingress) to port 8443/TCP
- Secrets:
  - **{registry-name}-kube-rbac-proxy** (kubernetes.io/tls): Auto-provisioned by OpenShift Service CA, auto-rotates
  - **model-registry-db** (Opaque): Database password and connection info (username, database, host, port)
  - **model-registry-db-credential** (Opaque): Optional database TLS CA certificates
  - **{registry-name}-postgres-ssl-cert/key** (Opaque): Optional PostgreSQL client certificates
  - **{registry-name}-mysql-ssl-cert/key** (Opaque): Optional MySQL client certificates
  - **webhook-server-cert** (kubernetes.io/tls): Webhook TLS cert, auto-provisioned by cert-manager/OpenShift
- Deployment security:
  - **Operator**: runAsNonRoot (65532:65532), drop all capabilities, FIPS strict mode, UBI9 minimal base
  - **Registry Instances**: runAsNonRoot, drop all capabilities, restricted-v2 SCC (OpenShift)

**Mermaid version** (`.mmd` + `.png`) - For presentations:
- Visual network flow with color-coded zones (External, Ingress/DMZ, Registry Instance Namespace, Operator Namespace, Control Plane, External Services, Optional Integrations)
- Same technical details as ASCII version
- Editable and high-resolution PNG

#### C4 Context Diagram (`model-registry-operator-c4-context.dsl`)
Structurizr DSL showing:
- **Persons**: Data Scientist/ML Engineer (queries model metadata), Platform Administrator (deploys operator)
- **Software System**: Model Registry Operator (with containers: Controller Manager, Webhook Server)
- **Software System**: Model Registry Instance (with containers: REST Server, gRPC Server, kube-rbac-proxy)
- **External Dependencies**: Kubernetes API Server, PostgreSQL, MySQL, OpenShift Router, Istio Service Mesh (optional), OpenShift Service CA (optional), Prometheus
- **Internal ODH Dependencies**: opendatahub-operator (platform integration), KServe (fetches model metadata), ODH/RHOAI Dashboard (UI management), Data Science Pipelines (model tracking)
- **Integration points**: How components interact (HTTPS/443, HTTPS/6443, HTTP/8080, HTTPS/8443, gRPC/9090, HTTPS/9443, PostgreSQL/5432, MySQL/3306)

#### Dependency Graph (`model-registry-operator-dependencies.mmd/png`)
Shows:
- **External Dependencies - Required**: PostgreSQL 16 (RHEL9) OR MySQL 8.x (database backend - one required)
- **External Dependencies - Optional**: OpenShift Service CA (auto TLS certs), cert-manager (alternative cert management), Istio Service Mesh 1.20+ (service mesh integration)
- **Internal ODH/RHOAI Dependencies**:
  - **opendatahub-operator**: Platform integration, provides service-mesh-refs ConfigMap
  - **Istio Ingress Gateway**: External ingress when Istio integration enabled
- **Integration Points** (optional):
  - **ODH/RHOAI Dashboard**: UI-based management of registry instances
  - **KServe**: Model metadata integration for inference serving
  - **Data Science Pipelines**: Model tracking in ML pipelines
- **Core Infrastructure**: Kubernetes API Server, Prometheus (metrics), OpenShift Router (external routing)
- **ConfigMaps**: service-mesh-refs (provided by opendatahub-operator) for Istio configuration

#### RBAC Visualization (`model-registry-operator-rbac.mmd/png`)
Shows:
- **ServiceAccounts**:
  - **controller-manager** (namespace: opendatahub / redhat-ods-applications)
  - **Per-registry SA** (namespace: {registry-namespace})
- **ClusterRoles**:
  - **manager-role**: Full CRUD on modelregistries, deployments, services, routes, networkpolicies, roles, rolebindings; create tokenreviews/subjectaccessreviews; get/list/watch on ingresses, pods, endpoints
  - **modelregistry-editor-role**: Full CRUD on ModelRegistry CRs, read status
  - **modelregistry-viewer-role**: Read-only access to ModelRegistry CRs and status
  - **metrics-reader**: GET /metrics (non-resource URL)
  - **proxy-role**: Token/subject access review for kube-rbac-proxy
- **Roles**:
  - **leader-election-role**: Get/create/update/patch/delete configmaps and leases, create/patch events
  - **registry-user-{registry-name}**: Per-registry service access control
- **Bindings**:
  - **manager-rolebinding** (ClusterRoleBinding): controller-manager → manager-role
  - **proxy-rolebinding** (RoleBinding): controller-manager → proxy-role
  - **leader-election-rolebinding** (RoleBinding): controller-manager → leader-election-role
  - **registry-user-{registry-name}** (RoleBinding): per-registry SA → registry-user-{registry-name}
- **API Resources**: Visual representation with verbs:
  - Core: configmaps, secrets, services, serviceaccounts, persistentvolumeclaims, endpoints, pods, events
  - apps: deployments
  - modelregistry.opendatahub.io: modelregistries (+ /finalizers, /status)
  - route.openshift.io: routes, routes/custom-host
  - user.openshift.io: groups
  - networking.k8s.io: networkpolicies
  - rbac.authorization.k8s.io: clusterrolebindings, rolebindings, roles
  - authentication.k8s.io: tokenreviews
  - authorization.k8s.io: subjectaccessreviews
  - config.openshift.io: ingresses
  - migration.k8s.io: storageversionmigrations

**Repository**: https://github.com/red-hat-data-services/model-registry-operator
**Version**: eb4d8e5
**Branch**: rhoai-3.0
**Distribution**: RHOAI

**Key Features**:
- **Operator pattern**: Declarative API via ModelRegistry CRD (v1beta1 current, v1alpha1 deprecated)
- **Database backends**: PostgreSQL 16 (recommended) or MySQL 8.x with optional TLS/client cert auth
- **Auto-provisioning**: Can auto-deploy PostgreSQL with PVC for development
- **Authentication**: kube-rbac-proxy with bearer token validation via SubjectAccessReview
- **External access**: OpenShift Routes (edge TLS with re-encryption) or Istio Gateway (optional)
- **Network isolation**: NetworkPolicies restricting ingress to OpenShift Router
- **Multi-tenancy**: Per-registry RBAC with editor/viewer roles
- **Security hardened**: Non-root execution (operator: 65532:65532), dropped capabilities, FIPS strict mode
- **OpenShift integration**: Service CA auto-provisions TLS certificates, Routes for external access
- **API versions**: REST API v1alpha3, gRPC ML Metadata Service
- **Monitoring**: Prometheus metrics on /metrics endpoint (8443/TCP HTTPS with bearer token auth)
- **Health checks**: /healthz and /readyz endpoints for operator and registry pods
- **Migration support**: Database schema upgrades/downgrades, OAuth proxy → kube-rbac-proxy migration

## How to Use

### PNG Files (.png files)
**Automatically generated** at 3000px width for high-resolution presentations and documentation.

- **Ready to use**: High-resolution images suitable for presentations, wikis, and documentation
- **Width**: 3000px (height auto-adjusts to content)
- **Use directly**: Include in PowerPoint, Google Slides, Confluence, etc.

### Mermaid Source Files (.mmd files)
- **In GitHub/GitLab**: Paste into markdown with ````mermaid` code blocks - renders automatically!
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
# For a specific component
/generate-architecture-diagrams --architecture=architecture/rhoai-3.0/kuberay.md
/generate-architecture-diagrams --architecture=architecture/rhoai-3.0/kubeflow.md

# Regenerate all PNGs
python scripts/generate_diagram_pngs.py architecture/rhoai-3.0/diagrams --width=3000
```

## Notes

- All diagrams are auto-generated from structured markdown architecture files
- PNG files are generated at 3000px width for high-resolution use
- Component-specific technical details are included in each diagram
- Refer to individual component architecture markdown files (`architecture/rhoai-3.0/*.md`) for complete technical specifications
