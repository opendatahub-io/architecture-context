# Component: RHODS Operator

## Metadata
- **Repository**: https://github.com/red-hat-data-services/rhods-operator.git
- **Version**: v1.6.0-3582-g331819fa5
- **Branch**: rhoai-3.0
- **Distribution**: RHOAI (also serves as base for ODH)
- **Languages**: Go 1.24
- **Deployment Type**: Kubernetes Operator

## Purpose
**Short**: Platform operator that manages the lifecycle of data science and AI/ML components in Red Hat OpenShift AI (RHOAI) and Open Data Hub (ODH).

**Detailed**: The RHODS operator (also known as opendatahub-operator) is the primary control plane operator for Red Hat OpenShift AI (RHOAI) and Open Data Hub (ODH). It orchestrates the deployment, configuration, and lifecycle management of data science and machine learning platform components including Jupyter notebooks, data science pipelines, model serving (KServe, ModelMesh), distributed training (Kubeflow Training Operator), distributed compute (Ray, CodeFlare), model registry, and the ODH/RHOAI dashboard. The operator uses a declarative API through Custom Resource Definitions (CRDs) to enable platform administrators to configure which components are enabled and how they are deployed. It manages platform-level services including authentication, authorization, monitoring, service mesh integration, and gateway configuration. The operator supports both self-managed and managed (ROSA, OSD) deployment models and provides upgrade capabilities between versions.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| Operator Manager | Go Binary | Main controller runtime managing reconciliation loops for all CRDs |
| Component Controllers | Reconcilers | Individual controllers for data science components (dashboard, pipelines, kserve, ray, workbenches, etc.) |
| Service Controllers | Reconcilers | Platform service controllers (auth, monitoring, gateway, cert management) |
| DSCInitialization Controller | Reconciler | Initializes platform-level configuration and shared services |
| DataScienceCluster Controller | Reconciler | Manages component lifecycle based on DSC configuration |
| Webhook Server | Validation/Mutation | Validates and mutates CRs for DSC, DSCI, Auth, and Monitoring |
| Metrics Server | HTTP Service | Exposes Prometheus metrics on operator health and operations |

## APIs Exposed

### Custom Resource Definitions (CRDs)

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| datasciencecluster.opendatahub.io | v1, v2 | DataScienceCluster | Cluster | Defines which data science components are enabled and their configuration |
| dscinitialization.opendatahub.io | v1, v2 | DSCInitialization | Cluster | Initializes platform-wide settings (monitoring, service mesh, trust CA bundles) |
| components.platform.opendatahub.io | v1alpha1 | Dashboard | Cluster | Manages ODH/RHOAI dashboard deployment |
| components.platform.opendatahub.io | v1alpha1 | DataSciencePipelines | Cluster | Manages Kubeflow Pipelines deployment |
| components.platform.opendatahub.io | v1alpha1 | Kserve | Cluster | Manages KServe model serving deployment |
| components.platform.opendatahub.io | v1alpha1 | Kueue | Cluster | Manages Kueue job queueing system |
| components.platform.opendatahub.io | v1alpha1 | Ray | Cluster | Manages Ray distributed compute framework |
| components.platform.opendatahub.io | v1alpha1 | TrainingOperator | Cluster | Manages Kubeflow Training Operator |
| components.platform.opendatahub.io | v1alpha1 | TrustyAI | Cluster | Manages TrustyAI model explainability service |
| components.platform.opendatahub.io | v1alpha1 | Workbenches | Cluster | Manages Jupyter notebook environments |
| components.platform.opendatahub.io | v1alpha1 | ModelRegistry | Cluster | Manages model registry service |
| components.platform.opendatahub.io | v1alpha1 | ModelController | Cluster | Manages model controller for inference |
| components.platform.opendatahub.io | v1alpha1 | FeastOperator | Cluster | Manages Feast feature store operator |
| components.platform.opendatahub.io | v1alpha1 | LlamaStackOperator | Cluster | Manages Llama Stack operator for LLM deployments |
| services.platform.opendatahub.io | v1alpha1 | Auth | Cluster | Configures platform authentication and authorization |
| services.platform.opendatahub.io | v1alpha1 | Monitoring | Cluster | Configures platform monitoring (Prometheus, AlertManager) |
| services.platform.opendatahub.io | v1alpha1 | GatewayConfig | Cluster | Configures service mesh gateway and TLS certificates |
| infrastructure.opendatahub.io | v1, v1alpha1 | HardwareProfile | Cluster | Defines hardware resource profiles for workloads |
| features.opendatahub.io | v1 | FeatureTracker | Cluster | Internal CR to track feature deployments and status |

### HTTP Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /healthz | GET | 8081/TCP | HTTP | None | None | Operator liveness probe |
| /readyz | GET | 8081/TCP | HTTP | None | None | Operator readiness probe |
| /metrics | GET | 8443/TCP | HTTPS | TLS 1.2+ | mTLS | Prometheus metrics endpoint (via kube-rbac-proxy) |
| /validate/* | POST | 9443/TCP | HTTPS | TLS 1.2+ | K8s API Server mTLS | Validating webhook for CRD admission |
| /mutate/* | POST | 9443/TCP | HTTPS | TLS 1.2+ | K8s API Server mTLS | Mutating webhook for CRD admission |

### gRPC Services

None - This operator does not expose gRPC services.

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| OpenShift/Kubernetes | 4.12+ | Yes | Container orchestration platform |
| OpenShift Service Mesh | 2.4+ | Conditional | Service mesh for KServe and gateway (if service mesh enabled) |
| OpenShift Serverless | 1.28+ | Conditional | Serverless runtime for KServe (if KServe enabled) |
| cert-manager | 1.11+ | No | Certificate management (alternative to OpenShift cert injection) |
| Prometheus Operator | 0.56+ | Conditional | Monitoring infrastructure (if monitoring enabled) |
| Gateway API | v1 | Conditional | Gateway resources for Istio/Envoy (if gateway enabled) |

### Internal ODH Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| ODH Dashboard | Deploys/Manages | User interface for platform management |
| KServe Operator | Deploys/Manages | Model serving infrastructure |
| Kubeflow Pipelines | Deploys/Manages | ML pipeline orchestration |
| Ray Operator | Deploys/Manages | Distributed compute framework |
| Kubeflow Training Operator | Deploys/Manages | Distributed training jobs |
| Model Registry | Deploys/Manages | ML model versioning and registry |
| TrustyAI Service | Deploys/Manages | Model explainability and bias detection |
| Workbench Images | References | Jupyter notebook container images |

## Network Architecture

### Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| redhat-ods-operator-controller-manager-metrics-service | ClusterIP | 8443/TCP | http | HTTPS | TLS 1.2+ | mTLS (kube-rbac-proxy) | Internal |
| webhook-service | ClusterIP | 443/TCP | 9443 | HTTPS | TLS 1.2+ | K8s API Server mTLS | Internal |
| prometheus | ClusterIP | 9091/TCP | https | HTTPS | TLS 1.2+ (OpenShift cert) | Bearer Token | Internal |
| alertmanager | ClusterIP | 9093/TCP | web | HTTPS | TLS 1.2+ (OpenShift cert) | Bearer Token | Internal |
| blackbox-exporter | ClusterIP | 9115/TCP | http | HTTP | None | None | Internal |

### Ingress

| Name | Type | Hosts | Port | Protocol | Encryption | TLS Mode | Exposure |
|------|------|-------|------|----------|------------|----------|----------|
| prometheus-route | OpenShift Route | prometheus-{namespace}.apps.{cluster-domain} | 9091/TCP | HTTPS | TLS 1.2+ | edge (reencrypt) | External (with auth) |
| alertmanager-route | OpenShift Route | alertmanager-{namespace}.apps.{cluster-domain} | 9093/TCP | HTTPS | TLS 1.2+ | edge (reencrypt) | External (with auth) |

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token | CRD management, resource reconciliation |
| Component Git Repositories | 443/TCP | HTTPS | TLS 1.2+ | None | Fetching component manifests during build |
| Image Registries (quay.io, registry.redhat.io) | 443/TCP | HTTPS | TLS 1.2+ | Pull Secrets | Container image pulls |
| OpenShift Monitoring | 9091/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token | Federation to cluster Prometheus |

## Security

### RBAC - Cluster Roles

| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|
| rhods-operator-role | "" (core) | configmaps, events, namespaces, secrets, serviceaccounts | create, delete, get, list, patch, update, watch |
| rhods-operator-role | "" (core) | pods, pods/exec, pods/log | * (all) |
| rhods-operator-role | apps | deployments, replicasets, statefulsets | * (all) |
| rhods-operator-role | rbac.authorization.k8s.io | clusterroles, clusterrolebindings, roles, rolebindings | create, delete, get, list, patch, update, watch |
| rhods-operator-role | route.openshift.io | routes | * (all) |
| rhods-operator-role | datasciencecluster.opendatahub.io | datascienceclusters | create, delete, get, list, patch, update, watch |
| rhods-operator-role | dscinitialization.opendatahub.io | dscinitializations | create, delete, get, list, patch, update, watch |
| rhods-operator-role | components.platform.opendatahub.io | * (all component CRDs) | create, delete, get, list, patch, update, watch |
| rhods-operator-role | services.platform.opendatahub.io | * (all service CRDs) | create, delete, get, list, patch, update, watch |
| rhods-operator-role | networking.k8s.io | networkpolicies | create, delete, get, list, patch, update, watch |
| rhods-operator-role | monitoring.coreos.com | servicemonitors, prometheusrules | create, delete, get, list, patch, update, watch |
| rhods-operator-role | operators.coreos.com | subscriptions, clusterserviceversions, operatorconditions | create, delete, get, list, patch, update, watch |
| rhods-operator-role | admissionregistration.k8s.io | validatingwebhookconfigurations, mutatingwebhookconfigurations | create, delete, get, list, patch, update, watch |
| rhods-operator-role | apiextensions.k8s.io | customresourcedefinitions | create, delete, get, list, patch, update, watch |
| auth-proxy-client | authentication.k8s.io | tokenreviews | create |
| auth-proxy-client | authorization.k8s.io | subjectaccessreviews | create |
| component-editor-roles | components.platform.opendatahub.io | {component-name} | create, delete, get, list, patch, update, watch |
| component-viewer-roles | components.platform.opendatahub.io | {component-name} | get, list, watch |

### RBAC - Role Bindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| rhods-operator-rolebinding | N/A (ClusterRoleBinding) | rhods-operator-role | redhat-ods-operator-system/redhat-ods-operator-controller-manager |
| rhods-operator-metrics-reader | redhat-ods-operator-system | metrics-reader | Various (for Prometheus scraping) |
| rhods-prometheus-rolebinding | redhat-ods-monitoring | rhods-prometheus-role | redhat-ods-monitoring/prometheus |

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| redhat-ods-operator-controller-webhook-cert | kubernetes.io/tls | Webhook server TLS certificate | OpenShift service-ca | Yes |
| prometheus-tls | kubernetes.io/tls | Prometheus service TLS certificate | OpenShift service-ca | Yes |
| alertmanager-tls | kubernetes.io/tls | AlertManager service TLS certificate | OpenShift service-ca | Yes |
| odh-trusted-ca-bundle | Opaque | Custom CA bundle for trusted certificates | User/Admin | No |

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| /metrics | GET | Bearer Token (ServiceAccount) + RBAC | kube-rbac-proxy | Requires cluster-monitoring view permissions |
| /validate/*, /mutate/* | POST | mTLS (K8s API Server) | Kubernetes API Server | Only API server can call webhooks |
| Prometheus Route | GET | OAuth Proxy (OpenShift) | OpenShift Router | Requires cluster-monitoring view permissions |
| AlertManager Route | GET | OAuth Proxy (OpenShift) | OpenShift Router | Requires cluster-monitoring view permissions |

### Network Policies

| Policy Name | Namespace | Pod Selector | Ingress From | Egress To |
|-------------|-----------|--------------|--------------|-----------|
| redhat-ods-operator | redhat-ods-operator | control-plane: controller-manager | redhat-ods-monitoring, openshift-monitoring, openshift-user-workload-monitoring, openshift-console, openshift-operators, generated-namespaces, host-network pods | Not restricted |
| monitoring | redhat-ods-monitoring | deployment: prometheus, deployment: alertmanager | openshift-monitoring, openshift-user-workload-monitoring, same namespace | Not restricted |

## Data Flows

### Flow 1: DataScienceCluster Creation

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User/GitOps | Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | User credentials/ServiceAccount |
| 2 | Kubernetes API Server | Webhook Service | 9443/TCP | HTTPS | TLS 1.2+ (mTLS) | K8s API Server cert |
| 3 | Webhook Service | Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 4 | Kubernetes API Server | Operator Manager | Watch/List | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 5 | Operator Manager | Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |

### Flow 2: Component Deployment

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | DSC Controller | Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 2 | Component Controller | Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 3 | Kubernetes Scheduler | Kubelet | 10250/TCP | HTTPS | TLS 1.2+ | Node cert |
| 4 | Kubelet | Image Registry | 443/TCP | HTTPS | TLS 1.2+ | Pull Secret |

### Flow 3: Metrics Collection

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Prometheus | ServiceMonitor Discovery | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 2 | Prometheus | kube-rbac-proxy (operator) | 8443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 3 | Prometheus | Blackbox Exporter | 9115/TCP | HTTP | None | None |
| 4 | OpenShift Monitoring Prometheus | RHODS Prometheus | 9091/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| Kubernetes API Server | REST API | 6443/TCP | HTTPS | TLS 1.2+ | Resource management and reconciliation |
| OpenShift Service Mesh Control Plane | CRD API | 6443/TCP | HTTPS | TLS 1.2+ | Service mesh configuration for KServe |
| OpenShift Serverless | CRD API | 6443/TCP | HTTPS | TLS 1.2+ | Knative serving for KServe |
| Prometheus Operator | CRD API | 6443/TCP | HTTPS | TLS 1.2+ | ServiceMonitor and PrometheusRule deployment |
| OLM (Operator Lifecycle Manager) | CRD API | 6443/TCP | HTTPS | TLS 1.2+ | Installing dependent operators (KServe, Ray, etc.) |
| Component Operators | CRD API | 6443/TCP | HTTPS | TLS 1.2+ | Delegating component-specific resources to specialized operators |

## Recent Changes

| Commit | Date | Changes |
|--------|------|---------|
| 331819fa5 | 2026-03 | - Updating operator with latest images and manifests |
| 9241b8a24 | 2026-03 | - Update odh-must-gather-v3-0 to a7820c1 |
| 722771c8e | 2026-03 | - Update odh-kuberay-operator-controller-v3-0 to 35bd47d |
| 01bf6a1cf | 2026-03 | - Update odh-dashboard-v3-0 to ae158eb |
| 3e354d2f1 | 2026-03 | - Update odh-kuberay-operator-controller-v3-0 to 3de22b9 |
| e213ab318 | 2026-03 | - Update odh-dashboard-v3-0 to ced0bc6 |
| a6e0b1419 | 2026-03 | - Update odh-dashboard-v3-0 to 8c190ca |
| 4051dc41d | 2026-03 | - Update odh-dashboard-v3-0 to 19f6955 |
| 2ff32630d | 2026-03 | - Update odh-dashboard-v3-0 (multiple dashboard updates) |

**Note**: Recent commits show active development with frequent updates to component versions (dashboard, kuberay, must-gather) as part of the RHOAI 3.0 development cycle.

## Deployment Architecture

### Operator Deployment

- **Replicas**: 3 (high availability)
- **Anti-Affinity**: Pods spread across nodes using preferred pod anti-affinity
- **Resource Requests**: 500m CPU, 256Mi memory
- **Resource Limits**: 500m CPU, 4Gi memory
- **Security Context**: runAsNonRoot, no privilege escalation, all capabilities dropped
- **Probes**:
  - Liveness: /healthz on port 8081 (15s initial delay, 20s period)
  - Readiness: /readyz on port 8081 (5s initial delay, 10s period)

### Namespaces

| Namespace | Purpose |
|-----------|---------|
| redhat-ods-operator-system | Operator deployment and management |
| redhat-ods-applications | Default namespace for ODH/RHOAI components |
| redhat-ods-monitoring | Monitoring stack (Prometheus, AlertManager, Blackbox Exporter) |
| openshift-operators | Dependent operator installations (when using OLM) |

### Configuration

The operator supports extensive configuration through environment variables and command-line flags:

| Configuration | Default | Purpose |
|---------------|---------|---------|
| DISABLE_DSC_CONFIG | false | Controls automatic DSCI creation |
| DEFAULT_MANIFESTS_PATH | /opt/manifests | Location of embedded component manifests |
| ODH_MANAGER_METRICS_BIND_ADDRESS | :8080 | Metrics endpoint address |
| ODH_MANAGER_HEALTH_PROBE_BIND_ADDRESS | :8081 | Health probe endpoint address |
| ODH_MANAGER_LEADER_ELECT | false | Enable leader election |
| ZAP_LOG_LEVEL | info | Logging verbosity (debug, info, error) |

### Build and Deployment

- **Build Method**: Konflux (RHOAI production builds)
- **Container Base**: UBI9 minimal
- **Go Compilation**: CGO_ENABLED=1 with FIPS strict mode support
- **Manifest Embedding**: Component manifests copied into /opt/manifests during build
- **Security**: Runs as UID 1001, all manifests have group=user permissions

## Component Architecture Pattern

The operator follows a modular architecture where each component (Dashboard, KServe, Ray, etc.) has:

1. **Component CRD**: API definition (e.g., `Dashboard`, `Kserve`)
2. **Component Handler**: Initialization and registration logic
3. **Component Reconciler**: Controller managing component lifecycle
4. **Component Manifests**: Kustomize overlays for deployment resources

Similarly, platform services (Auth, Monitoring, Gateway) follow the same pattern with Service CRDs.

The `DataScienceCluster` CR acts as a unified configuration interface, where users specify which components should be "Managed" or "Removed". The DSC controller creates/deletes the individual component CRs, which are then reconciled by their respective controllers.

## Observability

### Metrics

- **ServiceMonitor**: Operator exposes metrics scraped by Prometheus
- **PrometheusRules**: Alert rules for operator and component health
- **Custom Metrics**: Component deployment status, reconciliation duration, API call rates

### Logging

- **Structured Logging**: JSON format (production) or console (development)
- **Runtime Log Level**: Configurable via DSCI devFlags.logLevel
- **Log Aggregation**: Compatible with OpenShift cluster logging

### Tracing

- **OpenTelemetry**: Optional trace collection (configured via DSCI)
- **Storage**: PV-backed trace storage with configurable retention

## Upgrade Strategy

The operator supports version upgrades through:

1. **OLM-managed upgrades**: For OperatorHub installations
2. **Manual upgrades**: Via updated Deployment manifest
3. **Upgrade hooks**: `CleanupExistingResource` function removes deprecated resources
4. **Version tracking**: Stores deployed version in cluster for upgrade detection
5. **Component versioning**: Each component tracks its own version independently
