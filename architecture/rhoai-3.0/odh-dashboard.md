# Component: ODH Dashboard

## Metadata
- **Repository**: https://github.com/red-hat-data-services/odh-dashboard.git
- **Version**: v1.21.0-18-rhods-4527-g8534dfffd
- **Branch**: rhoai-3.0
- **Distribution**: RHOAI
- **Languages**: TypeScript, JavaScript, Node.js 20
- **Deployment Type**: Web Application (Frontend + Backend Service)

## Purpose
**Short**: Web-based management console and user interface for Open Data Hub and Red Hat OpenShift AI platform components.

**Detailed**: The ODH Dashboard is the primary user interface for Open Data Hub and Red Hat OpenShift AI. It provides a centralized web console for data scientists and administrators to manage and interact with the AI/ML platform. The dashboard enables users to launch Jupyter notebooks, manage data science projects, deploy and serve ML models (via KServe and ModelMesh), configure pipelines, manage distributed workloads, and access documentation and quickstarts. It serves as the control plane UI for the entire OpenShift AI ecosystem, integrating with multiple backend components including notebooks, model serving runtimes, model registries, feature stores, and distributed workload management. The dashboard is built as a React-based single-page application (SPA) with a Node.js/Fastify backend that proxies API requests to Kubernetes and provides authentication/authorization enforcement.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| Frontend | React 18 SPA | User interface built with PatternFly components for dashboard interactions |
| Backend | Node.js/Fastify API | API server that proxies K8s requests, enforces auth, serves static files |
| kube-rbac-proxy | Sidecar Proxy | OAuth2 proxy providing authentication and user/group header injection |
| Static File Server | Fastify Static | Serves compiled frontend assets from /frontend/public |
| WebSocket Server | Fastify WebSocket | Real-time communication for log streaming and live updates |

## APIs Exposed

### Custom Resource Definitions (CRDs)

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| dashboard.opendatahub.io | v1 | OdhApplication | Namespaced | Defines applications displayed in dashboard tile catalog |
| opendatahub.io | v1alpha | OdhDashboardConfig | Namespaced | Configuration for dashboard feature flags and settings |
| dashboard.opendatahub.io | v1 | OdhDocument | Namespaced | Documentation resources displayed in dashboard help section |
| console.openshift.io | v1 | OdhQuickStart | Namespaced | Interactive guided tutorials for dashboard features |

### HTTP Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| / | GET | 8443/TCP | HTTPS | TLS 1.2+ | OAuth2 Bearer | Serve frontend SPA |
| /api/config | GET, PATCH | 8443/TCP | HTTPS | TLS 1.2+ | OAuth2 Bearer | Dashboard configuration |
| /api/dashboardConfig | GET, PATCH | 8443/TCP | HTTPS | TLS 1.2+ | OAuth2 Bearer | OdhDashboardConfig management |
| /api/namespaces/* | GET | 8443/TCP | HTTPS | TLS 1.2+ | OAuth2 Bearer | Namespace/project operations |
| /api/notebooks/* | GET, POST, PUT, DELETE | 8443/TCP | HTTPS | TLS 1.2+ | OAuth2 Bearer | Jupyter notebook management |
| /api/components | GET | 8443/TCP | HTTPS | TLS 1.2+ | OAuth2 Bearer | List installed ODH components |
| /api/docs | GET | 8443/TCP | HTTPS | TLS 1.2+ | OAuth2 Bearer | Documentation resources |
| /api/quickstarts | GET | 8443/TCP | HTTPS | TLS 1.2+ | OAuth2 Bearer | QuickStart tutorials |
| /api/health | GET | 8080/TCP | HTTP | None | None | Health check endpoint (internal) |
| /api/accelerators/* | GET | 8443/TCP | HTTPS | TLS 1.2+ | OAuth2 Bearer | Hardware profile management |
| /api/cluster-settings/* | GET, PUT | 8443/TCP | HTTPS | TLS 1.2+ | OAuth2 Bearer | Cluster configuration |
| /api/connection-types/* | GET, POST, PUT, PATCH, DELETE | 8443/TCP | HTTPS | TLS 1.2+ | OAuth2 Bearer | Connection type management |
| /api/builds/* | GET | 8443/TCP | HTTPS | TLS 1.2+ | OAuth2 Bearer | Build status and logs |
| /api/console-links | GET | 8443/TCP | HTTPS | TLS 1.2+ | OAuth2 Bearer | Console navigation links |
| /api/dsc/status | GET | 8443/TCP | HTTPS | TLS 1.2+ | OAuth2 Bearer | DataScienceCluster status |
| /api/dsci/status | GET | 8443/TCP | HTTPS | TLS 1.2+ | OAuth2 Bearer | DSCInitialization status |
| /api/envs/* | GET | 8443/TCP | HTTPS | TLS 1.2+ | OAuth2 Bearer | Environment variables |
| /api/featurestores/* | GET | 8443/TCP | HTTPS | TLS 1.2+ | OAuth2 Bearer | Feature store integration |
| /api/modelRegistries/* | GET, POST, PUT, PATCH, DELETE | 8443/TCP | HTTPS | TLS 1.2+ | OAuth2 Bearer | Model registry management |
| /api/service/* | GET | 8443/TCP | HTTPS | TLS 1.2+ | OAuth2 Bearer | Service mesh integration |
| /api/servingRuntimes/* | GET, POST, PUT, DELETE | 8443/TCP | HTTPS | TLS 1.2+ | OAuth2 Bearer | Serving runtime management |
| /api/templates/* | GET | 8443/TCP | HTTPS | TLS 1.2+ | OAuth2 Bearer | Workbench templates |
| /api/prometheus/* | GET | 8443/TCP | HTTPS | TLS 1.2+ | OAuth2 Bearer | Metrics queries |
| /api/status | GET | 8443/TCP | HTTPS | TLS 1.2+ | OAuth2 Bearer | Overall status |
| /api/rolebindings | GET | 8443/TCP | HTTPS | TLS 1.2+ | OAuth2 Bearer | RBAC role bindings |
| /api/segment-key | GET | 8443/TCP | HTTPS | TLS 1.2+ | OAuth2 Bearer | Analytics configuration |
| /api/validate-isv | GET | 8443/TCP | HTTPS | TLS 1.2+ | OAuth2 Bearer | ISV validation |
| /api/nim-serving/* | GET, POST, DELETE | 8443/TCP | HTTPS | TLS 1.2+ | OAuth2 Bearer | NVIDIA NIM integration |
| /api/llama-stack/* | GET | 8443/TCP | HTTPS | TLS 1.2+ | OAuth2 Bearer | Llama Stack integration |
| /healthz | GET | 8444/TCP | HTTPS | TLS 1.2+ | None | kube-rbac-proxy health (internal) |

### gRPC Services

| Service | Port | Protocol | Encryption | Auth | Purpose |
|---------|------|----------|------------|------|---------|
| N/A | N/A | N/A | N/A | N/A | No gRPC services exposed |

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| Node.js | 20.x | Yes | Runtime for backend server |
| Kubernetes | 1.27+ | Yes | Container orchestration platform |
| OpenShift | 4.14+ | No | Preferred platform for Routes and OAuth |
| kube-rbac-proxy | Latest | Yes | Authentication proxy sidecar |
| PatternFly | 6.3.1 | Yes | UI component library |
| React | 18.2.0 | Yes | Frontend framework |
| Fastify | 4.28.1 | Yes | Backend web framework |
| @kubernetes/client-node | 0.12.2 | Yes | Kubernetes API client |
| Monaco Editor | 0.50.0 | Yes | Code editor for YAML/JSON editing |

### Internal ODH Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| odh-operator | CRD Watch | Monitors DataScienceCluster and DSCInitialization resources |
| notebook-controller | CRD/API | Creates and manages Jupyter notebook pods |
| model-registry-operator | CRD/API | Manages ModelRegistry instances |
| kserve-controller | CRD Watch | Monitors InferenceService resources for model serving |
| kubeflow-pipelines | API Proxy | Accesses pipeline definitions and executions |
| distributed-workloads | CRD Watch | Monitors distributed training jobs |
| feast-operator | CRD Watch | Monitors FeatureStore resources |
| llama-stack-operator | CRD Watch | Monitors LlamaStackDistribution resources |
| thanos-querier | HTTP API | Queries Prometheus metrics for monitoring dashboards |
| openshift-oauth | OAuth2 Flow | User authentication via kube-rbac-proxy |

## Network Architecture

### Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| odh-dashboard | ClusterIP | 8443/TCP | 8443 | HTTPS | TLS 1.2+ | OAuth2 | Internal |
| odh-dashboard (backend) | Container Port | 8080/TCP | 8080 | HTTP | None | None | Pod-local only |
| kube-rbac-proxy | Container Port | 8443/TCP | 8443 | HTTPS | TLS 1.2+ | OAuth2 | Internal |
| kube-rbac-proxy-health | Container Port | 8444/TCP | 8444 | HTTPS | TLS 1.2+ | None | Pod-local only |

### Ingress

| Name | Type | Hosts | Port | Protocol | Encryption | TLS Mode | Exposure |
|------|------|-------|------|----------|------------|----------|----------|
| odh-dashboard | OpenShift Route | Auto-generated | 8443/TCP | HTTPS | TLS 1.2+ | Reencrypt | External |
| odh-dashboard | Gateway HTTPRoute | Via Gateway | 8443/TCP | HTTPS | TLS 1.2+ | Passthrough | External |

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| kubernetes.default.svc | 443/TCP | HTTPS | TLS 1.2+ | Service Account Token | Kubernetes API queries |
| thanos-querier.openshift-monitoring.svc | 9092/TCP | HTTPS | TLS 1.2+ | Service Account Token | Prometheus metrics queries |
| model-registry-*.svc | 8080/TCP, 9090/TCP | HTTP/gRPC | Varies | Bearer Token | Model registry access |
| kserve predictor services | 8080/TCP, 8443/TCP | HTTP/HTTPS | Varies | None/Bearer | Inference service proxying |

## Security

### RBAC - Cluster Roles

| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|
| odh-dashboard | storage.k8s.io | storageclasses | update, patch |
| odh-dashboard | "" (core) | nodes | get, list |
| odh-dashboard | machine.openshift.io | machineautoscalers, machinesets | get, list |
| odh-dashboard | autoscaling.openshift.io | machineautoscalers, machinesets | get, list |
| odh-dashboard | "" (core), config.openshift.io | clusterversions, ingresses | get, watch, list |
| odh-dashboard | operators.coreos.com | clusterserviceversions, subscriptions | get, list, watch |
| odh-dashboard | "" (core), image.openshift.io | imagestreams/layers | get |
| odh-dashboard | "" (core) | configmaps, persistentvolumeclaims, secrets | create, delete, get, list, patch, update, watch |
| odh-dashboard | route.openshift.io | routes | get, list, watch |
| odh-dashboard | console.openshift.io | consolelinks | get, list, watch |
| odh-dashboard | operator.openshift.io | consoles | get, list, watch |
| odh-dashboard | "" (core), integreatly.org | rhmis | get, watch, list |
| odh-dashboard | user.openshift.io | groups, users | get, list, watch |
| odh-dashboard | "" (core) | pods, serviceaccounts, services | get, list, watch |
| odh-dashboard | "" (core) | namespaces | patch |
| odh-dashboard | rbac.authorization.k8s.io | rolebindings, clusterrolebindings, roles | list, get, create, patch, delete |
| odh-dashboard | "" (core), events.k8s.io | events | get, list, watch |
| odh-dashboard | kubeflow.org | notebooks | get, list, watch, create, update, patch, delete |
| odh-dashboard | datasciencecluster.opendatahub.io | datascienceclusters | list, watch, get |
| odh-dashboard | dscinitialization.opendatahub.io | dscinitializations | list, watch, get |
| odh-dashboard | serving.kserve.io | inferenceservices | get, list, watch |
| odh-dashboard | modelregistry.opendatahub.io | modelregistries | get, list, watch, create, update, patch, delete |
| odh-dashboard | "" (core) | endpoints | get |
| odh-dashboard | services.platform.opendatahub.io | auths | get |
| odh-dashboard | llamastack.io | llamastackdistributions | get, list, watch |
| odh-dashboard | feast.dev | featurestores | get, list, watch |
| odh-dashboard | authentication.k8s.io | tokenreviews | create |
| odh-dashboard | authorization.k8s.io | subjectaccessreviews | create |

### RBAC - Namespace Roles

| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|
| odh-dashboard | dashboard.opendatahub.io | acceleratorprofiles | create, get, list, update, patch, delete |
| odh-dashboard | route.openshift.io | routes | get, list, watch |
| odh-dashboard | batch | cronjobs | get, update, delete |
| odh-dashboard | image.openshift.io | imagestreams | create, get, list, update, patch, delete |
| odh-dashboard | build.openshift.io | builds, buildconfigs | list |
| odh-dashboard | apps | deployments | patch, update |
| odh-dashboard | apps.openshift.io | deploymentconfigs, deploymentconfigs/instantiate | get, list, watch, create, update, patch, delete |
| odh-dashboard | opendatahub.io | odhdashboardconfigs | get, list, watch, create, update, patch, delete |
| odh-dashboard | kubeflow.org | notebooks | get, list, watch, create, update, patch, delete |
| odh-dashboard | dashboard.opendatahub.io | odhapplications | get, list |
| odh-dashboard | dashboard.opendatahub.io | odhdocuments | get, list |
| odh-dashboard | console.openshift.io | odhquickstarts | get, list |
| odh-dashboard | template.openshift.io | templates | * (all) |
| odh-dashboard | serving.kserve.io | servingruntimes | * (all) |
| odh-dashboard | nim.opendatahub.io | accounts | get, list, watch, create, update, patch, delete |

### RBAC - Role Bindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| odh-dashboard | opendatahub or redhat-ods-applications | odh-dashboard (Role) | odh-dashboard |
| odh-dashboard | Cluster-wide | odh-dashboard (ClusterRole) | odh-dashboard |
| odh-dashboard-auth-delegator | kube-system | system:auth-delegator | odh-dashboard |
| odh-dashboard-cluster-monitoring-view | openshift-monitoring | cluster-monitoring-view | odh-dashboard |
| odh-dashboard-image-puller | All user namespaces | system:image-puller | odh-dashboard |
| odh-dashboard-model-serving-view | All user namespaces | model-serving-view | odh-dashboard |

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| dashboard-proxy-tls | kubernetes.io/tls | TLS cert for kube-rbac-proxy HTTPS | service-serving-cert-signer | Yes |
| odh-trusted-ca-bundle | Opaque (ConfigMap) | Trusted CA certificates for API calls | cluster-ca-operator | Yes |

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| /api/* | All | OAuth2 Bearer Token (JWT) | kube-rbac-proxy | Token forwarded in X-Forwarded-Access-Token header |
| /api/* | All | User/Group Headers | kube-rbac-proxy | X-Auth-Request-User, X-Auth-Request-Groups injected |
| / (frontend) | GET | OAuth2 Bearer Token (JWT) | kube-rbac-proxy | Authenticated users only |
| /api/health | GET | None | Backend direct | Unauthenticated health check |
| /healthz | GET | None | kube-rbac-proxy | Unauthenticated health check |

## Data Flows

### Flow 1: User Authentication and Dashboard Access

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User Browser | OpenShift Route/Gateway | 443/TCP | HTTPS | TLS 1.2+ | None |
| 2 | OpenShift Router | odh-dashboard Service | 8443/TCP | HTTPS | TLS 1.2+ (reencrypt) | None |
| 3 | odh-dashboard Service | kube-rbac-proxy Container | 8443/TCP | HTTPS | TLS 1.2+ | None |
| 4 | kube-rbac-proxy | OpenShift OAuth | 443/TCP | HTTPS | TLS 1.2+ | OAuth2 |
| 5 | kube-rbac-proxy | odh-dashboard Backend | 8080/TCP | HTTP | None | User/Group Headers |
| 6 | odh-dashboard Backend | Static Files | File I/O | N/A | None | None |

### Flow 2: API Request to Kubernetes

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User Browser | odh-dashboard Route | 443/TCP | HTTPS | TLS 1.2+ | Bearer Token |
| 2 | kube-rbac-proxy | odh-dashboard Backend | 8080/TCP | HTTP | None | User/Group Headers |
| 3 | odh-dashboard Backend | kubernetes.default.svc | 443/TCP | HTTPS | TLS 1.2+ | Service Account Token |
| 4 | Kubernetes API | Response | N/A | N/A | N/A | N/A |
| 5 | odh-dashboard Backend | User Browser | 443/TCP | HTTPS | TLS 1.2+ | Bearer Token |

### Flow 3: Prometheus Metrics Query

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User Browser | odh-dashboard API | 443/TCP | HTTPS | TLS 1.2+ | Bearer Token |
| 2 | odh-dashboard Backend | thanos-querier.openshift-monitoring.svc | 9092/TCP | HTTPS | TLS 1.2+ | Service Account Token |
| 3 | Thanos Querier | Prometheus | 9091/TCP | HTTP | mTLS | Service Mesh |
| 4 | odh-dashboard Backend | User Browser | 443/TCP | HTTPS | TLS 1.2+ | Bearer Token |

### Flow 4: Notebook Creation

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User Browser | odh-dashboard API | 443/TCP | HTTPS | TLS 1.2+ | Bearer Token |
| 2 | odh-dashboard Backend | kubernetes.default.svc | 443/TCP | HTTPS | TLS 1.2+ | Service Account Token |
| 3 | Kubernetes API | notebook-controller | N/A | Internal | N/A | N/A |
| 4 | notebook-controller | Notebook Pod | N/A | Internal | N/A | N/A |

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| Kubernetes API | REST API | 443/TCP | HTTPS | TLS 1.2+ | All resource CRUD operations |
| notebook-controller | Kubernetes CRD | 443/TCP | HTTPS | TLS 1.2+ | Notebook lifecycle management |
| kserve-controller | Kubernetes CRD Watch | 443/TCP | HTTPS | TLS 1.2+ | InferenceService status monitoring |
| model-registry-operator | Kubernetes CRD | 443/TCP | HTTPS | TLS 1.2+ | ModelRegistry management |
| odh-operator | Kubernetes CRD Watch | 443/TCP | HTTPS | TLS 1.2+ | DSC/DSCI status monitoring |
| thanos-querier | HTTP API | 9092/TCP | HTTPS | TLS 1.2+ | Prometheus metrics queries |
| OpenShift OAuth | OAuth2 Protocol | 443/TCP | HTTPS | TLS 1.2+ | User authentication |
| feast-operator | Kubernetes CRD Watch | 443/TCP | HTTPS | TLS 1.2+ | FeatureStore status monitoring |
| llama-stack-operator | Kubernetes CRD Watch | 443/TCP | HTTPS | TLS 1.2+ | LlamaStack distribution monitoring |
| OpenShift Image Registry | HTTP API | 443/TCP | HTTPS | TLS 1.2+ | ImageStream and image layer access |
| OpenShift Routes | Kubernetes API | 443/TCP | HTTPS | TLS 1.2+ | Route discovery for applications |

## Recent Changes

| Date | Commit | Changes |
|------|--------|---------|
| 2026-03 | 8534dfffd | chore(deps): update registry.access.redhat.com/ubi9/nodejs-20 docker digest to b45e1ba |
| 2026-03 | b4a7c512d | chore(deps): update registry.access.redhat.com/ubi9/nodejs-20 docker digest to b45e1ba |
| 2026-03 | a29b6c931 | chore(deps): update dockerfile digest updates |
| 2026-03 | 7eb0fcd5f | chore(deps): update dockerfile digest updates |
| 2026-03 | eec66a01c | chore(deps): update dockerfile digest updates |
| 2026-03 | 3496d67b4 | chore(deps): update dockerfile digest updates |
| 2026-03 | 8dfcb8c18 | chore(deps): update dockerfile digest updates |
| 2026-03 | 3494d3c83 | chore(deps): update dockerfile digest updates |
| 2026-03 | 0e24af77c | chore(deps): update dockerfile digest updates |
| 2026-03 | f76c2b691 | chore(deps): update dockerfile digest updates |
| 2026-03 | 15d70d3ad | chore(deps): update dockerfile digest updates |
| 2026-02 | 99661fa18 | chore(deps): update registry.access.redhat.com/ubi9-minimal docker digest to ecd4751 |
| 2026-02 | b6bc53927 | chore(deps): update registry.access.redhat.com/ubi9-minimal docker digest to ecd4751 |
| 2026-02 | 68b6e86b7 | chore(deps): update registry.access.redhat.com/ubi9/nodejs-20 docker digest to ad30ca7 |
| 2026-02 | 5d2935c80 | chore(deps): update registry.access.redhat.com/ubi9/nodejs-20 docker digest to f65d181 |
| 2026-02 | 3d954d808 | chore(deps): update registry.access.redhat.com/ubi9/nodejs-20 docker digest to 5a87f3b |
| 2026-01 | 47998a38f | chore(deps): update registry.access.redhat.com/ubi9/nodejs-20 docker digest to ef1fa40 |
| 2026-01 | 2d5b02e7b | chore(deps): update registry.access.redhat.com/ubi9-minimal docker digest to bb08f23 |
| 2026-01 | 9dd5c2cb2 | chore(deps): update registry.access.redhat.com/ubi9/nodejs-20 docker digest to 0ac1c5a |
| 2026-01 | 694a0c06c | chore(deps): update registry.access.redhat.com/ubi9-minimal docker digest to 90bd85d |

## Deployment Architecture

### Container Images

| Image | Base | Purpose | Build System |
|-------|------|---------|--------------|
| odh-dashboard | registry.access.redhat.com/ubi9/nodejs-20 | Main application container | Konflux |
| kube-rbac-proxy | quay.io/brancz/kube-rbac-proxy | OAuth2 authentication proxy | Upstream |

### Resource Requirements

| Container | CPU Request | CPU Limit | Memory Request | Memory Limit |
|-----------|-------------|-----------|----------------|--------------|
| odh-dashboard | 500m | 1000m | 1Gi | 2Gi |
| kube-rbac-proxy | 500m | 1000m | 1Gi | 2Gi |

### High Availability

| Feature | Configuration | Purpose |
|---------|---------------|---------|
| Replicas | 2 | Ensure availability during rolling updates |
| Pod Anti-Affinity | Preferred (topology.kubernetes.io/zone) | Distribute pods across availability zones |
| Liveness Probe | TCP 8080 (30s interval) | Restart unhealthy containers |
| Readiness Probe | HTTP /api/health (30s interval) | Remove unhealthy pods from service |

### Network Policies

| Policy Name | Pod Selector | Policy Type | Rules |
|-------------|--------------|-------------|-------|
| odh-dashboard-allow-ports | deployment: odh-dashboard | Ingress | Allow TCP 8443, 8043, 8143 from all sources |

### Storage

| Volume | Type | Mount Path | Purpose |
|--------|------|------------|---------|
| proxy-tls | Secret | /etc/tls/private | TLS certificates for kube-rbac-proxy |
| kube-rbac-proxy-config | ConfigMap | /etc/kube-rbac-proxy | Proxy configuration |
| odh-trusted-ca-cert | ConfigMap | /etc/pki/tls/certs, /etc/ssl/certs | Trusted CA bundle for outbound HTTPS |
| odh-ca-cert | ConfigMap | /etc/pki/tls/certs, /etc/ssl/certs | ODH platform CA bundle |

## Feature Flags

The dashboard supports extensive feature flag configuration via OdhDashboardConfig:

| Feature | Default | Purpose |
|---------|---------|---------|
| enablement | true | Enable/disable entire dashboard |
| disableProjects | false | Hide data science projects feature |
| disableModelServing | false | Hide model serving features |
| disablePipelines | false | Hide pipeline features |
| disableKServe | false | Hide KServe model serving |
| disableModelMesh | false | Hide ModelMesh serving |
| disableDistributedWorkloads | false | Hide distributed workload features |
| disableModelRegistry | false | Hide model registry features |
| disableModelCatalog | false | Hide model catalog |
| disableNIMModelServing | false | Hide NVIDIA NIM integration |
| disableFeatureStore | false | Hide feature store integration |
| genAiStudio | false | Enable GenAI Studio features (beta) |
| modelAsService | false | Enable Model-as-a-Service features (beta) |

## Monitoring and Observability

| Metric Type | Endpoint | Format | Purpose |
|-------------|----------|--------|---------|
| Application Logs | stdout/stderr | JSON (pino) | Request logs, errors, debug info |
| Kubernetes Events | Kubernetes API | Events | Deployment status, pod lifecycle |
| Access Logs | kube-rbac-proxy logs | Text | Authentication, authorization events |
| Health Checks | /api/health, /healthz | HTTP 200/503 | Liveness and readiness status |

## Known Limitations

- Dashboard relies on OpenShift OAuth for authentication; alternative auth requires kube-rbac-proxy configuration
- WebSocket connections for log streaming require stable network connectivity
- Large clusters (>1000 projects) may experience slower namespace list performance
- Model registry integration requires model-registry-operator to be installed
- Feature store integration requires feast-operator to be installed
- Some features (distributed workloads, NIM) are behind feature flags and require additional operators
