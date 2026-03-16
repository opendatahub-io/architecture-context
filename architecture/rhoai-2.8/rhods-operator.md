# Component: RHODS Operator (Red Hat OpenShift AI Operator)

## Metadata
- **Repository**: https://github.com/red-hat-data-services/rhods-operator.git
- **Version**: v1.6.0-1892-gd1214ef4c
- **Branch**: rhoai-2.8
- **Distribution**: RHOAI
- **Languages**: Go
- **Deployment Type**: Kubernetes Operator

## Purpose
**Short**: Primary operator for Red Hat OpenShift AI, responsible for deploying and managing data science platform components.

**Detailed**: The RHODS Operator is the central control plane for Red Hat OpenShift AI (RHOAI), managing the complete lifecycle of data science and machine learning components on OpenShift. It orchestrates the deployment, configuration, and management of integrated components including Jupyter notebooks (workbenches), model serving (KServe and ModelMesh), data science pipelines, distributed compute (CodeFlare, Ray), and job scheduling (Kueue). The operator uses a declarative approach through the DataScienceCluster custom resource, allowing administrators to enable and configure components through a single unified interface.

The operator is built on the Operator SDK framework and implements four primary controllers: DSCInitialization (platform initialization), DataScienceCluster (component lifecycle management), SecretGenerator (credential management), and CertConfigmapGenerator (certificate distribution). It integrates deeply with OpenShift infrastructure including service mesh (Istio), monitoring (Prometheus), certificate management (cert-manager), and authentication/authorization systems. The operator embeds component manifests at build time and applies them using kustomize-based templating, pulling from the odh-manifests repository structure.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| Controller Manager | Operator Deployment | Main operator process managing all controllers and reconciliation loops |
| DSCInitialization Controller | Reconciler | Initializes platform-level resources including namespaces, service mesh, and monitoring |
| DataScienceCluster Controller | Reconciler | Manages component lifecycle (Dashboard, Workbenches, KServe, ModelMesh, Pipelines, etc.) |
| SecretGenerator Controller | Reconciler | Generates and manages secrets for component authentication and configuration |
| CertConfigmapGenerator Controller | Reconciler | Generates and distributes certificate ConfigMaps for TLS configuration |
| Metrics Exporter | Service | Exposes operator metrics for Prometheus scraping |
| Webhook Server | Admission Webhook | Validates and mutates DataScienceCluster and DSCInitialization resources |

## APIs Exposed

### Custom Resource Definitions (CRDs)

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| datasciencecluster.opendatahub.io | v1 | DataScienceCluster | Cluster | Defines which components are enabled and their configuration |
| dscinitialization.opendatahub.io | v1 | DSCInitialization | Cluster | Configures platform-level settings (namespaces, service mesh, monitoring) |
| features.opendatahub.io | v1 | FeatureTracker | Cluster | Tracks resources created by Features API for garbage collection |

### HTTP Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /metrics | GET | 8080/TCP | HTTP | None | None | Prometheus metrics endpoint (internal) |
| /healthz | GET | 8081/TCP | HTTP | None | None | Liveness probe endpoint |
| /readyz | GET | 8081/TCP | HTTP | None | None | Readiness probe endpoint |
| /validate-datasciencecluster | POST | 9443/TCP | HTTPS | TLS 1.2+ | K8s API Server | Validating webhook for DataScienceCluster |
| /mutate-datasciencecluster | POST | 9443/TCP | HTTPS | TLS 1.2+ | K8s API Server | Mutating webhook for DataScienceCluster |
| /validate-dscinitialization | POST | 9443/TCP | HTTPS | TLS 1.2+ | K8s API Server | Validating webhook for DSCInitialization |
| /mutate-dscinitialization | POST | 9443/TCP | HTTPS | TLS 1.2+ | K8s API Server | Mutating webhook for DSCInitialization |

### gRPC Services

No gRPC services exposed directly by this operator.

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| OpenShift Container Platform | 4.12+ | Yes | Kubernetes platform with OpenShift extensions |
| Istio Service Mesh | 2.4+ | Conditional | Required for KServe single model serving, optional for other components |
| Prometheus Operator | N/A | No | Monitoring and alerting (operator deploys its own Prometheus if enabled) |
| cert-manager | N/A | Conditional | Certificate management for service mesh integration |
| OpenShift GitOps (ArgoCD) | N/A | No | Used by Data Science Pipelines for workflow execution |

### Internal ODH/RHOAI Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| Dashboard | CRD Management | Operator deploys and manages ODH Dashboard manifests |
| Workbenches | CRD Management | Operator deploys notebook controller and spawner components |
| KServe | CRD Management | Operator deploys KServe controller and serving runtime |
| ModelMesh Serving | CRD Management | Operator deploys ModelMesh controller and runtime adapters |
| Data Science Pipelines | CRD Management | Operator deploys Kubeflow Pipelines v2 components |
| CodeFlare | CRD Management | Operator deploys CodeFlare operator for distributed compute |
| Ray | CRD Management | Operator deploys KubeRay operator for Ray clusters |
| Kueue | CRD Management | Operator deploys Kueue for job scheduling |
| TrustyAI | CRD Management | Operator deploys TrustyAI service for model explainability |

## Network Architecture

### Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| controller-manager-metrics-service | ClusterIP | 8443/TCP | 8080 | HTTP | TLS 1.2+ (proxy) | K8s RBAC | Internal |
| prometheus | ClusterIP | 9091/TCP | 9091 | HTTPS | TLS 1.2+ | Bearer Token | Internal |
| alertmanager | ClusterIP | 9093/TCP | 9093 | HTTP | None | None | Internal |
| blackbox-exporter | ClusterIP | 9115/TCP | 9115 | HTTP | None | None | Internal |

### Ingress

| Name | Type | Hosts | Port | Protocol | Encryption | TLS Mode | Exposure |
|------|------|-------|------|----------|------------|----------|----------|
| prometheus-route | OpenShift Route | prometheus-{namespace}.{cluster-domain} | 9091/TCP | HTTPS | TLS 1.2+ | Edge | Internal (requires auth) |
| alertmanager-route | OpenShift Route | alertmanager-{namespace}.{cluster-domain} | 9093/TCP | HTTP | None | N/A | Internal |

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token | Resource reconciliation and status updates |
| Component Git Repositories | 443/TCP | HTTPS | TLS 1.2+ | None | Fetch manifests when devFlags.manifestsUri is set |
| Image Registries | 443/TCP | HTTPS | TLS 1.2+ | Pull Secrets | Pull component container images |
| OpenShift OAuth Server | 6443/TCP | HTTPS | TLS 1.2+ | OAuth Token | User authentication for dashboard components |

### Network Policies

| Policy Name | Namespace | Selector | Ingress Rules | Egress Rules |
|-------------|-----------|----------|---------------|--------------|
| redhat-ods-operator | redhat-ods-operator | control-plane=controller-manager | From: redhat-ods-monitoring, openshift-monitoring, openshift-user-workload-monitoring, ODH namespaces | None (default allow) |
| redhat-ods-monitoring | redhat-ods-monitoring | All pods | Ports: 443, 8080, 8443, 9091, 9114, 9115, 10443/TCP; From: openshift-monitoring, openshift-user-workload-monitoring, redhat-ods-operator, ODH namespaces | Allow all |
| redhat-ods-applications | redhat-ods-applications | All pods | Ports: 5432, 8080, 8081, 8082, 8099, 8181, 8443/TCP; From: redhat-ods-monitoring, openshift-monitoring | None (default allow) |

## Security

### RBAC - Cluster Roles

| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|
| controller-manager-role | datasciencecluster.opendatahub.io | datascienceclusters, datascienceclusters/status, datascienceclusters/finalizers | create, delete, get, list, patch, update, watch |
| controller-manager-role | dscinitialization.opendatahub.io | dscinitializations, dscinitializations/status, dscinitializations/finalizers | create, delete, get, list, patch, update, watch |
| controller-manager-role | features.opendatahub.io | featuretrackers, featuretrackers/status | create, delete, get, list, patch, update, watch |
| controller-manager-role | "" (core) | configmaps, secrets, services, serviceaccounts, persistentvolumeclaims, namespaces, events | create, delete, get, list, patch, update, watch |
| controller-manager-role | apps | deployments, replicasets, statefulsets | create, delete, get, list, patch, update, watch |
| controller-manager-role | rbac.authorization.k8s.io | roles, rolebindings, clusterroles, clusterrolebindings | create, delete, get, list, patch, update, watch |
| controller-manager-role | route.openshift.io | routes | create, delete, get, list, patch, update, watch |
| controller-manager-role | networking.istio.io | virtualservices, gateways, destinationrules, authorizationpolicies | create, delete, get, list, patch, update, watch |
| controller-manager-role | serving.kserve.io | inferenceservices, servingruntimes, clusterservingruntimes, inferencegraphs | create, delete, get, list, patch, update, watch |
| controller-manager-role | serving.knative.dev | services, revisions, configurations, routes | create, delete, get, list, patch, update, watch |
| controller-manager-role | datasciencepipelinesapplications.opendatahub.io | datasciencepipelinesapplications | create, delete, get, list, patch, update, watch |
| controller-manager-role | kfdef.apps.kubeflow.org | kfdefs | create, delete, get, list, patch, update, watch |
| controller-manager-role | monitoring.coreos.com | servicemonitors, prometheusrules, podmonitors | create, delete, get, list, patch, update, watch |
| controller-manager-role | admissionregistration.k8s.io | mutatingwebhookconfigurations, validatingwebhookconfigurations | create, delete, get, list, patch, update, watch |
| controller-manager-role | console.openshift.io | consolelinks, odhquickstarts | create, delete, get, patch |
| controller-manager-role | apiextensions.k8s.io | customresourcedefinitions | create, delete, get, list, patch, watch |
| controller-manager-role | config.openshift.io | clusterversions, ingresses | get, list, watch |
| controller-manager-role | authorization.k8s.io | subjectaccessreviews, tokenreviews | create, get |
| controller-manager-role | batch | jobs, cronjobs | create, delete, get, list, patch, update, watch |
| controller-manager-role | networking.k8s.io | networkpolicies | create, delete, get, list, patch, update, watch |
| controller-manager-role | cert-manager.io | certificates, issuers | create, patch |
| prometheus-scraper | "" (core) | endpoints, services, pods | get, list, watch |
| prometheus-scraper | monitoring.coreos.com | servicemonitors | get, list |

### RBAC - Role Bindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| controller-manager-rolebinding | Cluster-wide | controller-manager-role | redhat-ods-operator/controller-manager |
| prometheus-scraper | Cluster-wide | prometheus-scraper | redhat-ods-monitoring/prometheus |

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| prometheus-tls | kubernetes.io/tls | TLS certificate for Prometheus service | OpenShift service-ca | Yes (OpenShift) |
| webhook-server-cert | kubernetes.io/tls | TLS certificate for admission webhooks | cert-manager or operator | No |
| controller-manager-sa-token | kubernetes.io/service-account-token | Service account token for operator | Kubernetes | Yes (automatic) |
| segment-key | Opaque | Analytics key for telemetry (optional) | Administrator | No |

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| /metrics | GET | None (NetworkPolicy restricted) | NetworkPolicy | Only accessible from monitoring namespaces |
| /healthz, /readyz | GET | None | None | Publicly accessible within cluster |
| Webhook endpoints | POST | TLS client certificate | Kubernetes API Server | API Server validates webhook server certificate |
| Kubernetes API (operator calls) | ALL | ServiceAccount Bearer Token | Kubernetes API Server | RBAC policies enforce permissions |
| Component resources | ALL | Delegated via operator | Operator RBAC | Operator acts on behalf of users/controllers |

## Data Flows

### Flow 1: DataScienceCluster Creation and Component Deployment

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User/Admin | Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | User credentials (OAuth/cert) |
| 2 | Kubernetes API Server | Operator Webhook | 9443/TCP | HTTPS | TLS 1.2+ | TLS client cert |
| 3 | Kubernetes API Server | Operator Controller | N/A | Watch API | TLS 1.2+ | ServiceAccount token |
| 4 | Operator Controller | Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount token |
| 5 | Operator Controller | Component Namespaces | N/A | API calls | TLS 1.2+ | ServiceAccount token |

### Flow 2: Monitoring and Metrics Collection

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Prometheus (ODH) | Operator Metrics Service | 8080/TCP | HTTP | None | None (internal) |
| 2 | Prometheus (ODH) | Component Services | Various | HTTP/HTTPS | TLS 1.2+ (varies) | Bearer token |
| 3 | OpenShift Monitoring | Prometheus (ODH) | 9091/TCP | HTTPS | TLS 1.2+ | Bearer token |
| 4 | Alertmanager | Notification Channels | 443/TCP | HTTPS | TLS 1.2+ | Webhook/SMTP auth |

### Flow 3: Component Manifest Application

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Operator Controller | Local Filesystem | N/A | File I/O | None | N/A (in-container) |
| 2 | Operator Controller | Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount token |
| 3 | Kubernetes API Server | Component Controllers | N/A | Watch API | TLS 1.2+ | ServiceAccount tokens |

### Flow 4: Service Mesh Integration (KServe)

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Operator Controller | Service Mesh Control Plane | 6443/TCP | HTTPS (K8s API) | TLS 1.2+ | ServiceAccount token |
| 2 | Operator Controller | Istio Resources (Gateway, VS) | N/A | K8s API | TLS 1.2+ | ServiceAccount token |
| 3 | KServe Controller | Knative Serving | N/A | K8s API | TLS 1.2+ | ServiceAccount token |

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| Kubernetes API Server | REST API Client | 6443/TCP | HTTPS | TLS 1.2+ | Resource CRUD operations and watch events |
| OpenShift OAuth | OAuth Client | 6443/TCP | HTTPS | TLS 1.2+ | User authentication delegation |
| Service Mesh (Istio) | CRD Management | 6443/TCP | HTTPS (via K8s API) | TLS 1.2+ | Deploy Gateway, VirtualService, AuthorizationPolicy |
| Prometheus Operator | CRD Management | 6443/TCP | HTTPS (via K8s API) | TLS 1.2+ | Deploy ServiceMonitors and PrometheusRules |
| Cert-Manager | CRD Management | 6443/TCP | HTTPS (via K8s API) | TLS 1.2+ | Request certificates for components |
| Component Operators | CRD Management | 6443/TCP | HTTPS (via K8s API) | TLS 1.2+ | Deploy component-specific CRDs (KServe, Kubeflow, etc.) |
| OpenShift Console | CRD Modification | 6443/TCP | HTTPS (via K8s API) | TLS 1.2+ | Create ConsoleLinks and ODHQuickStarts |
| Image Registries | Container Image Pull | 443/TCP | HTTPS | TLS 1.2+ | Pull component images during deployment |

## Component Manifests Structure

The operator embeds component manifests at build time from two sources:

1. **Prefetched Manifests** (`/opt/manifests/` in container):
   - Cloned from component repositories during build via `get_all_manifests.sh`
   - Each component has structure: `{component-name}/{base,overlays}/*.yaml`
   - Applied using kustomize build + kubectl apply pattern

2. **Config Manifests** (embedded from `config/` directory):
   - `config/monitoring/`: Prometheus, Alertmanager, Blackbox exporter, ServiceMonitors
   - `config/osd-configs/`: OpenShift Dedicated specific configurations
   - `config/partners/`: Partner integration configurations

Components managed:
- **Dashboard**: ODH/RHOAI web console and API server
- **Workbenches**: Notebook controller, spawner, OAuth proxy
- **KServe**: Serving controller, runtimes (OVMS, TGIS, vLLM, Caikit)
- **ModelMesh**: ModelMesh controller, runtime adapters, REST proxy
- **Data Science Pipelines**: Kubeflow Pipelines v2, API server, persistence agent, workflow controller
- **CodeFlare**: MCAD, InstaScale for distributed training
- **Ray**: KubeRay operator for Ray cluster management
- **Kueue**: Job queue controller for resource management
- **TrustyAI**: Explainability service

## Recent Changes

| Commit | Date | Changes |
|--------|------|---------|
| d1214ef4c | 2025-09-25 | Updating the operator repo with latest images and manifests |
| 8ff991249 | 2025-09-25 | Merge pull request #12575: Component update for odh-mm-rest-proxy-v2-8 |
| 8e0896ab8 | 2025-09-25 | chore(deps): update odh-mm-rest-proxy-v2-8 to b622288 |
| 92a784e3f | 2025-09-22 | chore(deps): update registry.access.redhat.com/ubi8/ubi-minimal docker digest to 43dde01 |
| 917e8a885 | 2025-09-02 | Updating the operator repo with latest images and manifests |
| 4f10e0fe7 | 2025-09-02 | Merge pull request #11792: Component update for odh-modelmesh-serving-controller-v2-8 |
| d42a06b45 | 2025-09-02 | chore(deps): update odh-modelmesh-serving-controller-v2-8 to 4da8258 |
| 255b4769c | 2025-09-02 | Merge pull request #11749: Component update for odh-ml-pipelines-persistenceagent-v2-8 |
| 3d20205de | 2025-09-02 | chore(deps): update odh-ml-pipelines-persistenceagent-v2-8 to 8045b45 |
| f05e9bcf8 | 2025-09-02 | Updating the operator repo with latest images and manifests |
| 2fd46e703 | 2025-09-02 | Merge pull request #11747: Component update for odh-ml-pipelines-scheduledworkflow-v2-8 |
| 6d23190d9 | 2025-09-02 | chore(deps): update odh-ml-pipelines-scheduledworkflow-v2-8 to 2591abb |
| df315280a | 2025-09-02 | Updating the operator repo with latest images and manifests |
| d8a7fd585 | 2025-09-02 | Merge pull request #11746: Component update for odh-modelmesh-runtime-adapter-v2-8 |
| b545bd173 | 2025-09-02 | chore(deps): update odh-modelmesh-runtime-adapter-v2-8 to 0c62f29 |
| e15934a33 | 2025-09-01 | Updating the operator repo with latest images and manifests |
| 2e551380f | 2025-09-01 | Merge pull request #11701: Component update for odh-modelmesh-runtime-adapter-v2-8 |
| 1e3b9d3d3 | 2025-09-01 | chore(deps): update odh-modelmesh-runtime-adapter-v2-8 to e2d7bfb |
| 6178da0e4 | 2025-09-01 | Merge pull request #11695: Component update for odh-mm-rest-proxy-v2-8 |
| 06b6d875e | 2025-09-01 | chore(deps): update odh-mm-rest-proxy-v2-8 to c57a209 |

## Build and Deployment

### Container Build

**Primary Dockerfile**: `Dockerfiles/Dockerfile.konflux` (used by RHOAI Konflux builds)

**Build Process**:
1. Base image: `registry.access.redhat.com/ubi8/go-toolset:1.21`
2. Copies prefetched-manifests into `/opt/odh-manifests/`
3. Copies monitoring, partners, osd-configs from `config/` into `/opt/odh-manifests/`
4. Builds Go binary with CGO_ENABLED=0 for static linking
5. Runtime image: `registry.access.redhat.com/ubi8/ubi-minimal`
6. Final image runs as non-root user (UID 1001)

**Image Labels**:
- Component: `odh-operator-container`
- Name: `managed-open-data-hub/odh-rhel8-operator`
- Description: `rhoai-operator`

### Deployment Model

**Namespace**: `redhat-ods-operator`

**Deployment Specs**:
- Replicas: 1 (leader election enabled)
- Resource requests: 500m CPU, 256Mi memory
- Resource limits: 500m CPU, 4Gi memory
- Security: runAsNonRoot, drop all capabilities, no privilege escalation
- Health checks: liveness on `/healthz`, readiness on `/readyz`

**Service Account**: `controller-manager`

**Leader Election**: Enabled (LeaderElectionID: `07ed84f7.opendatahub.io`)

### Configuration

**Environment Variables**:
- `DISABLE_DSC_CONFIG`: Skip automatic DSCInitialization creation
- Default namespace flags:
  - `--dsc-applications-namespace=redhat-ods-applications`
  - `--dsc-monitoring-namespace=redhat-ods-monitoring`

**ConfigMaps**:
- Controller manager config for tuning reconciliation behavior

## Operational Characteristics

### Reconciliation

The operator uses controller-runtime's reconciliation pattern with:
- QPS: 20 (5 per controller × 4 controllers)
- Burst: 40 (10 per controller × 4 controllers)
- Watch-based triggering for CRD changes
- Periodic requeue for status synchronization

### Upgrade Handling

The operator includes upgrade logic in `pkg/upgrade/`:
- `CreateDefaultDSCI()`: Creates default DSCInitialization on first install
- `UpdateFromLegacyVersion()`: Migrates from ODH v1 to v2
- `RemoveDeprecatedTrustyAI()`: Removes TrustyAI in RHOAI 2.9+
- `CleanupExistingResource()`: Removes obsolete resources

### Platform Detection

Automatically detects platform type:
- Managed OpenShift (OSD/ROSA): via `addons.managed.openshift.io/addons`
- Self-managed OpenShift: via `config.openshift.io/clusterversions`
- Kubernetes: fallback detection

Platform detection influences:
- Monitoring configuration (managed vs. self-managed)
- Namespace naming conventions
- Component defaults
