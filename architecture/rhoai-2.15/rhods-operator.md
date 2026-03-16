# Component: RHOAI Operator (rhods-operator)

## Metadata
- **Repository**: https://github.com/red-hat-data-services/rhods-operator.git
- **Version**: v1.6.0-852-g7b9ae0562
- **Branch**: rhoai-2.15
- **Distribution**: RHOAI
- **Languages**: Go 1.21
- **Deployment Type**: Kubernetes Operator

## Purpose
**Short**: Primary operator for RHOAI/ODH that deploys and manages data science platform components.

**Detailed**: The rhods-operator (RHOAI Operator) is the central operator for Red Hat OpenShift AI and Open Data Hub platforms. It orchestrates the deployment and lifecycle management of all data science components including workbenches, model serving (KServe, ModelMesh), pipelines, training operators, and AI/ML tools. The operator uses custom resources (DataScienceCluster and DSCInitialization) to declaratively manage component installations, configure monitoring stack, setup service mesh integration, and handle platform initialization. It acts as an integration point that pulls component-specific manifests from upstream repositories and applies them with platform-specific customizations. The operator also manages cross-cutting concerns like TLS certificates, trusted CA bundles, RBAC policies, and monitoring configuration across all managed components.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| DataScienceCluster Controller | Kubernetes Controller | Reconciles DataScienceCluster CRs to deploy/manage data science components |
| DSCInitialization Controller | Kubernetes Controller | Initializes platform infrastructure (monitoring, service mesh, namespaces, CA bundles) |
| Webhook Server | Admission Controller | Validates and mutates DataScienceCluster and DSCInitialization resources |
| SecretGenerator Controller | Kubernetes Controller | Generates and manages secrets for components |
| CertConfigMapGenerator Controller | Kubernetes Controller | Generates TLS certificate ConfigMaps |
| Component Reconcilers | Component Handlers | Per-component logic for Dashboard, Workbenches, KServe, ModelMesh, Pipelines, etc. |
| Monitoring Stack | Observability | Prometheus, Alertmanager, and federation for platform metrics |

## APIs Exposed

### Custom Resource Definitions (CRDs)

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| datasciencecluster.opendatahub.io | v1 | DataScienceCluster | Cluster | Declares which data science components to enable/disable and their configuration |
| dscinitialization.opendatahub.io | v1 | DSCInitialization | Cluster | Configures platform infrastructure (monitoring, service mesh, namespaces, trusted CAs) |
| features.opendatahub.io | v1 | FeatureTracker | Namespaced | Tracks feature usage and component state across the platform |

### HTTP Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /metrics | GET | 8443/TCP | HTTPS | TLS 1.2+ | Bearer Token | Operator metrics for Prometheus scraping |
| /healthz | GET | 8081/TCP | HTTP | None | None | Liveness probe endpoint |
| /readyz | GET | 8081/TCP | HTTP | None | None | Readiness probe endpoint |
| /mutate-opendatahub-io-v1 | POST | 9443/TCP | HTTPS | TLS 1.2+ | K8s API Server | Mutating webhook for DataScienceCluster |
| /validate-opendatahub-io-v1 | POST | 9443/TCP | HTTPS | TLS 1.2+ | K8s API Server | Validating webhook for DSC/DSCI resources |

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| OpenShift/Kubernetes | 1.28+ | Yes | Target platform for operator deployment |
| Service Mesh (Istio) | varies | Conditional | Required for KServe, ModelMesh, and SSO features |
| Serverless (Knative) | varies | Conditional | Required for KServe component |
| Authorino | varies | Conditional | Required for model serving authentication |
| Prometheus Operator | varies | No | Monitoring stack (operator can deploy its own) |
| Cert Manager | varies | No | Optional for certificate management |
| OpenShift Route API | N/A | Conditional | Required on OpenShift for external access |

### Internal ODH/RHOAI Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| ODH Dashboard | Manifest Deployment | Deploys dashboard UI for data science workflows |
| Workbenches | Manifest Deployment | Deploys Jupyter notebook servers and IDE environments |
| KServe | Manifest Deployment | Deploys serverless model serving platform |
| ModelMesh | Manifest Deployment | Deploys multi-model serving infrastructure |
| Data Science Pipelines | Manifest Deployment | Deploys Kubeflow Pipelines for ML workflows |
| CodeFlare | Manifest Deployment | Deploys distributed workload management |
| Ray | Manifest Deployment | Deploys Ray cluster operator |
| Kueue | Manifest Deployment | Deploys job queueing system |
| Training Operator | Manifest Deployment | Deploys distributed training frameworks |
| TrustyAI | Manifest Deployment | Deploys AI explainability and monitoring |
| Model Registry | Manifest Deployment | Deploys model metadata and versioning service |

## Network Architecture

### Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| webhook-service | ClusterIP | 443/TCP | 9443 | HTTPS | TLS 1.2+ | K8s API Server mTLS | Internal |
| controller-manager-metrics-service | ClusterIP | 8443/TCP | 8080 | HTTP | None | Bearer Token | Internal |
| prometheus | ClusterIP | 9090/TCP | 9090 | HTTP | None | Bearer Token | Internal |
| prometheus-tls | ClusterIP | 10443/TCP | 10443 | HTTPS | TLS 1.2+ | mTLS | Internal |
| alertmanager | ClusterIP | 9093/TCP | 10443 | HTTPS | TLS 1.2+ | mTLS | Internal |
| blackbox-exporter | ClusterIP | 9115/TCP | 9115 | HTTP | None | None | Internal |

### Ingress

| Name | Type | Hosts | Port | Protocol | Encryption | TLS Mode | Exposure |
|------|------|-------|------|----------|------------|----------|----------|
| webhook-service | K8s Service | cluster-internal | 443/TCP | HTTPS | TLS 1.2+ | Service Serving Cert | Internal |

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| Kubernetes API Server | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token | Watch/manage cluster resources |
| Component Git Repositories | 443/TCP | HTTPS | TLS 1.2+ | None | Download component manifests at build time |
| Monitoring Namespaces | Various | HTTP/HTTPS | Varies | Bearer Token | Scrape component metrics |

## Security

### RBAC - Cluster Roles

| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|
| controller-manager-role | datasciencecluster.opendatahub.io | datascienceclusters | create, delete, get, list, patch, update, watch |
| controller-manager-role | dscinitialization.opendatahub.io | dscinitializations | create, delete, get, list, patch, update, watch |
| controller-manager-role | features.opendatahub.io | featuretrackers | create, delete, get, list, patch, update, watch |
| controller-manager-role | "" (core) | configmaps, secrets, serviceaccounts, services, namespaces | create, delete, get, list, patch, update, watch |
| controller-manager-role | apps | deployments, replicasets, statefulsets | create, delete, get, list, patch, update, watch |
| controller-manager-role | rbac.authorization.k8s.io | roles, rolebindings, clusterroles, clusterrolebindings | create, delete, get, list, patch, update, watch |
| controller-manager-role | route.openshift.io | routes | create, delete, get, list, patch, update, watch |
| controller-manager-role | networking.k8s.io | networkpolicies | create, delete, get, list, patch, update, watch |
| controller-manager-role | admissionregistration.k8s.io | validatingwebhookconfigurations, mutatingwebhookconfigurations | create, delete, get, list, patch, update, watch |
| controller-manager-role | apiextensions.k8s.io | customresourcedefinitions | create, delete, get, list, patch, watch |
| controller-manager-role | operators.coreos.com | subscriptions, clusterserviceversions | create, delete, get, list, patch, update, watch |
| controller-manager-role | monitoring.coreos.com | servicemonitors, prometheusrules | create, delete, get, list, patch, update, watch |
| controller-manager-role | authorino.kuadrant.io | authconfigs | create, delete, get, list, patch, update, watch |
| controller-manager-role | maistra.io | servicemeshmembers, servicemeshcontrolplanes | create, delete, get, list, patch, update, watch |
| controller-manager-role | serving.knative.dev | services, routes | create, delete, get, list, patch, update, watch |
| controller-manager-role | serving.kserve.io | inferenceservices, servingruntimes | create, delete, get, list, patch, update, watch |
| controller-manager-role | config.openshift.io | clusterversions, ingresses, authentications | get, list, watch |
| controller-manager-role | user.openshift.io | users, groups, identities | create, delete, get, list, patch, update, watch |

### RBAC - Role Bindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| controller-manager-rolebinding | cluster-wide | controller-manager-role | redhat-ods-operator/rhods-operator-controller-manager |

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| redhat-ods-operator-controller-webhook-cert | kubernetes.io/tls | TLS certificate for webhook server | OpenShift Service CA | Yes |
| prometheus-proxy-tls | kubernetes.io/tls | TLS proxy for Prometheus | OpenShift Service CA | Yes |
| alertmanager-proxy-tls | kubernetes.io/tls | TLS proxy for Alertmanager | OpenShift Service CA | Yes |
| Component-specific secrets | Opaque/TLS | Component authentication, service credentials | SecretGenerator Controller | No |

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| /metrics | GET | Bearer Token (ServiceAccount) | kube-rbac-proxy | Requires monitoring permissions |
| /mutate-opendatahub-io-v1 | POST | K8s API Server mTLS | API Server | Webhook registered with API server |
| /validate-opendatahub-io-v1 | POST | K8s API Server mTLS | API Server | Webhook registered with API server |
| Operator Pod | N/A | ServiceAccount Token | Kubernetes RBAC | ClusterRole grants cluster-wide permissions |

### Network Policies

| Policy Name | Namespace | Pod Selector | Ingress Rules |
|-------------|-----------|--------------|---------------|
| redhat-ods-operator | redhat-ods-operator | control-plane=controller-manager | Allow from: redhat-ods-monitoring, openshift-monitoring, openshift-user-workload-monitoring, openshift-console, openshift-operators, generated namespaces, host-network pods |

## Data Flows

### Flow 1: DataScienceCluster Deployment

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User/CI | Kubernetes API | 443/TCP | HTTPS | TLS 1.3 | User credentials |
| 2 | Kubernetes API | Webhook Service | 9443/TCP | HTTPS | TLS 1.2+ | K8s API Server mTLS |
| 3 | DSC Controller | Kubernetes API | 443/TCP | HTTPS | TLS 1.3 | ServiceAccount Token |
| 4 | DSC Controller | Component Namespaces | 443/TCP | HTTPS | TLS 1.3 | ServiceAccount Token |

### Flow 2: Platform Initialization (DSCI)

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User/Operator | Kubernetes API | 443/TCP | HTTPS | TLS 1.3 | User credentials |
| 2 | Kubernetes API | Webhook Service | 9443/TCP | HTTPS | TLS 1.2+ | K8s API Server mTLS |
| 3 | DSCI Controller | Kubernetes API | 443/TCP | HTTPS | TLS 1.3 | ServiceAccount Token |
| 4 | DSCI Controller | Monitoring Namespace | 443/TCP | HTTPS | TLS 1.3 | ServiceAccount Token |
| 5 | DSCI Controller | Service Mesh Namespace | 443/TCP | HTTPS | TLS 1.3 | ServiceAccount Token |

### Flow 3: Metrics Collection

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Prometheus | Operator Metrics Service | 8443/TCP | HTTP | None | Bearer Token |
| 2 | Prometheus | Component Metrics | Various | HTTP/HTTPS | Varies | Bearer Token |
| 3 | User-Workload Prometheus | RHOAI Prometheus (Federation) | 10443/TCP | HTTPS | TLS 1.2+ | Bearer Token |

### Flow 4: Webhook Validation

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User | Kubernetes API | 443/TCP | HTTPS | TLS 1.3 | User credentials |
| 2 | Kubernetes API | Webhook Service | 9443/TCP | HTTPS | TLS 1.2+ | K8s API Server mTLS |
| 3 | Webhook Service | Kubernetes API (lookups) | 443/TCP | HTTPS | TLS 1.3 | ServiceAccount Token |

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| Kubernetes API Server | REST API | 443/TCP | HTTPS | TLS 1.3 | Manage all cluster resources |
| Prometheus Operator | CRD (ServiceMonitor) | N/A | N/A | N/A | Configure metrics scraping |
| Service Mesh (Istio) | CRD (SMCP, SMM) | N/A | N/A | N/A | Configure service mesh for components |
| Authorino | CRD (AuthConfig) | N/A | N/A | N/A | Configure model serving authentication |
| Knative Serving | CRD (KnativeServing) | N/A | N/A | N/A | Configure serverless for KServe |
| Component Operators | Manifest Deployment | 443/TCP | HTTPS | TLS 1.3 | Deploy component-specific operators |
| OpenShift Console | ConsoleLink CRD | N/A | N/A | N/A | Add RHOAI links to OpenShift console |

## Component Manifests Management

### Manifest Sources

The operator downloads component manifests from upstream git repositories during build time (via `get_all_manifests.sh` script). These are embedded in the operator image under `/opt/manifests/`.

**Managed Components:**
- **dashboard**: ODH Dashboard UI
- **workbenches**: Jupyter notebooks and IDEs
- **datasciencepipelines**: Kubeflow Pipelines
- **kserve**: Serverless model serving
- **modelmeshserving**: Multi-model serving
- **codeflare**: Distributed workload management
- **ray**: Ray cluster operator
- **kueue**: Job queueing
- **trainingoperator**: Distributed training (PyTorch, TensorFlow)
- **trustyai**: AI explainability and bias detection
- **modelregistry**: Model versioning and metadata

### Deployment Strategy

Each component can be in one of these states:
- **Managed**: Operator actively deploys and manages the component
- **Removed**: Operator removes the component if present

Components use Kustomize for manifest templating with overlays for platform-specific customizations (ODH vs RHOAI, SelfManaged vs Managed).

## Monitoring & Observability

### Metrics Endpoints

| Service | Port | Path | Metrics Exported |
|---------|------|------|------------------|
| Operator Metrics | 8443/TCP | /metrics | Controller reconciliation metrics, resource counts |
| Prometheus | 9090/TCP | /metrics | Platform-wide metrics aggregation |
| Blackbox Exporter | 9115/TCP | /metrics | Endpoint availability probes |

### ServiceMonitors

| Name | Namespace | Target | Scrape Interval |
|------|-----------|--------|----------------|
| rhods-monitor-federation | redhat-ods-monitoring | Prometheus Federation | 30s |

### Prometheus Rules

The operator deploys PrometheusRule CRDs for alerting on component health, resource usage, and platform availability.

## Recent Changes

| Commit | Date | Changes |
|--------|------|---------|
| 7b9ae0562 | 2024 | - Made TrustyAI GA (General Availability) |
| bd86bb72e | 2024 | - Added nightly trigger changes |
| 9f5922fd7 | 2024 | - Fixed pull_request_target action integration error |
| 401c0cdcb | 2024 | - Use namespace dynamically from operator env instead of hardcoded value |
| af1c56548 | 2024 | - Added run-nowebhook Makefile target for local development |
| d36c69b78 | 2024 | - Moved webhook initialization inside module |
| 342a444d1 | 2024 | - Removed webhook service from bundle |
| f254c7729 | 2024 | - Fixed unset env variable in CSV to work with fallback |
| e5b990408 | 2024 | - Pass platform type from env variable with fallback to old logic |
| 426389311 | 2024 | - Removed GetPlatform API |
| 114ae8ba0 | 2024 | - Reduced platform detection calls for performance |
| eaedd4fc1 | 2024 | - Refactored platform detection logic |
| bbbd85fd0 | 2024 | - Operator disables usergroup creation if external auth detected |
| 7bea1fdc4 | 2024 | - Added operator processor infrastructure |
| ab08cacb4 | 2024 | - Synced ODH to RHOAI 2.15 with namespace validation |
| 375... | 2024 | - Updated downstream CSV with missing parts |

## Deployment Configuration

### Resource Requirements

| Container | CPU Request | CPU Limit | Memory Request | Memory Limit |
|-----------|-------------|-----------|----------------|--------------|
| manager | 500m | 500m | 256Mi | 4Gi |

### Health Checks

| Type | Path | Port | Initial Delay | Period |
|------|------|------|---------------|--------|
| Liveness | /healthz | 8081 | 15s | 20s |
| Readiness | /readyz | 8081 | 5s | 10s |

### Environment Variables

| Variable | Purpose | Source |
|----------|---------|--------|
| OPERATOR_NAMESPACE | Operator's deployment namespace | Field reference (metadata.namespace) |
| DEFAULT_MANIFESTS_PATH | Path to embedded component manifests | Static (/opt/manifests) |
| ODH_PLATFORM_TYPE | Platform type override (SelfManagedRHOAI, etc.) | ConfigMap/CSV (optional) |

## Container Image

**Build**: Konflux (Red Hat's build system)
- **Dockerfile**: `Dockerfiles/Dockerfile.konflux`
- **Base Image**: UBI8 (Universal Base Image) Go toolset for build, UBI8 minimal for runtime
- **User**: 1001 (non-root)
- **Entrypoint**: `/manager`

**Labels**:
- `com.redhat.component="odh-operator-container"`
- `name="managed-open-data-hub/odh-rhel8-operator"`
- `io.k8s.display-name="odh-operator"`

## Operator Lifecycle

### Installation

1. Operator deployed via OLM (Operator Lifecycle Manager)
2. ClusterServiceVersion (CSV) creates operator deployment
3. Operator watches for DSCInitialization CR
4. DSCI controller initializes platform infrastructure
5. Operator watches for DataScienceCluster CR
6. DSC controller deploys selected components

### Upgrade

- Operator handles upgrade reconciliation logic
- Checks platform versions and applies migrations
- Component manifests updated via operator image updates
- Zero-downtime upgrades for most components

### Uninstallation

1. Delete DataScienceCluster CR (components removed)
2. Delete DSCInitialization CR (infrastructure cleaned up)
3. Operator finalizers ensure clean resource removal
4. Delete operator subscription/CSV

## Known Limitations

1. Only one DataScienceCluster instance supported per cluster
2. Only one DSCInitialization instance supported per cluster
3. Component namespace names are predefined and not fully customizable
4. Some components require specific operators (Service Mesh, Serverless) pre-installed
5. Platform detection relies on OpenShift-specific APIs (limited Kubernetes support)
