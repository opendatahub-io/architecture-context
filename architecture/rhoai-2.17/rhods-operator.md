# Component: RHODS Operator

## Metadata
- **Repository**: https://github.com/red-hat-data-services/rhods-operator.git
- **Version**: v1.6.0-4171-ge2d77a515
- **Branch**: rhoai-2.17
- **Distribution**: RHOAI
- **Languages**: Go
- **Deployment Type**: Kubernetes Operator

## Purpose
**Short**: Primary operator for Red Hat OpenShift AI (RHOAI) that manages data science platform components and infrastructure.

**Detailed**: The RHODS Operator is the central orchestration component for Red Hat OpenShift AI. It manages the lifecycle of data science platform components including Jupyter Notebooks (Workbenches), Model Serving (KServe, ModelMesh), Data Science Pipelines, distributed computing frameworks (Ray, CodeFlare), model training (Training Operator), model explainability (TrustyAI), job queuing (Kueue), and the dashboard. The operator uses the DataScienceCluster CRD to declaratively configure and deploy these components, and DSCInitialization to configure platform-wide infrastructure like service mesh integration, monitoring, and authentication. It also provides webhook-based validation and mutation of cluster configurations to ensure consistency and compliance.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| rhods-operator | Go Operator | Main controller managing DataScienceCluster and DSCInitialization resources |
| DataScienceCluster Controller | Reconciliation Controller | Manages component lifecycle based on DSC CR |
| DSCInitialization Controller | Reconciliation Controller | Initializes platform infrastructure (monitoring, service mesh, auth) |
| Component Controllers (12) | Reconciliation Controllers | Manage individual components: Dashboard, Workbenches, KServe, ModelMesh, DSP, Ray, CodeFlare, TrustyAI, Training Operator, Kueue, ModelRegistry, ModelController |
| Auth Service Controller | Service Controller | Manages authentication and authorization configuration |
| Monitoring Service Controller | Service Controller | Manages monitoring stack (Prometheus, Alertmanager) |
| SecretGenerator Controller | Utility Controller | Generates required secrets for components |
| CertConfigmapGenerator Controller | Utility Controller | Generates certificate configmaps |
| Setup Controller | Initialization Controller | Performs initial cluster setup |
| Webhook Server | Validation/Mutation | Validates and mutates DSC/DSCI resources |

## APIs Exposed

### Custom Resource Definitions (CRDs)

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| datasciencecluster.opendatahub.io | v1 | DataScienceCluster | Cluster | Main configuration for enabling/disabling data science components |
| dscinitialization.opendatahub.io | v1 | DSCInitialization | Cluster | Platform initialization (monitoring, service mesh, trusted CA bundle) |
| components.platform.opendatahub.io | v1alpha1 | Dashboard | Cluster | Dashboard component configuration |
| components.platform.opendatahub.io | v1alpha1 | Workbenches | Cluster | Jupyter notebook workbenches configuration |
| components.platform.opendatahub.io | v1alpha1 | DataSciencePipelines | Cluster | Data science pipelines configuration |
| components.platform.opendatahub.io | v1alpha1 | Kserve | Cluster | KServe model serving configuration |
| components.platform.opendatahub.io | v1alpha1 | ModelMeshServing | Cluster | ModelMesh serving configuration |
| components.platform.opendatahub.io | v1alpha1 | ModelRegistry | Cluster | Model registry configuration |
| components.platform.opendatahub.io | v1alpha1 | ModelController | Cluster | Model controller configuration |
| components.platform.opendatahub.io | v1alpha1 | Ray | Cluster | Ray distributed computing configuration |
| components.platform.opendatahub.io | v1alpha1 | CodeFlare | Cluster | CodeFlare distributed workload configuration |
| components.platform.opendatahub.io | v1alpha1 | TrustyAI | Cluster | TrustyAI model explainability configuration |
| components.platform.opendatahub.io | v1alpha1 | TrainingOperator | Cluster | Training operator configuration |
| components.platform.opendatahub.io | v1alpha1 | Kueue | Cluster | Kueue job queuing configuration |
| services.platform.opendatahub.io | v1alpha1 | Auth | Cluster | Authentication and authorization service |
| services.platform.opendatahub.io | v1alpha1 | Monitoring | Cluster | Monitoring stack configuration |
| features.opendatahub.io | v1 | FeatureTracker | Cluster | Tracks features created via internal Features API for garbage collection |

### HTTP Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /metrics | GET | 8080/TCP | HTTP | None | None | Prometheus metrics endpoint |
| /healthz | GET | 8081/TCP | HTTP | None | None | Liveness probe endpoint |
| /readyz | GET | 8081/TCP | HTTP | None | None | Readiness probe endpoint |
| /mutate-opendatahub-io-v1 | POST | 9443/TCP | HTTPS | TLS 1.2+ | K8s API Server | Mutating webhook for DataScienceCluster |
| /validate-opendatahub-io-v1 | POST | 9443/TCP | HTTPS | TLS 1.2+ | K8s API Server | Validating webhook for DSC/DSCI |

### Webhook Configurations

| Type | Name | Resources | Operations | Purpose |
|------|------|-----------|------------|---------|
| MutatingWebhookConfiguration | mutating-webhook-configuration | datascienceclusters | CREATE, UPDATE | Applies defaults and transformations to DSC |
| ValidatingWebhookConfiguration | validating-webhook-configuration | datascienceclusters, dscinitializations | CREATE, DELETE | Validates DSC/DSCI configurations |

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| Kubernetes | 1.25+ | Yes | Container orchestration platform |
| OpenShift | 4.11+ | Yes | Enterprise Kubernetes distribution |
| Service Mesh Operator (Istio) | Latest | Conditional | Required for KServe and authentication |
| Serverless Operator (Knative) | Latest | Conditional | Required for KServe model serving |
| Authorino Operator | Latest | Conditional | Required for KServe authentication |
| cert-manager | Latest | No | Certificate management (optional) |

### Internal ODH/RHOAI Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| ODH Dashboard | CRD Management | Deploys and configures dashboard component manifests |
| KServe | CRD Management | Deploys KServe operator and dependencies |
| ModelMesh | CRD Management | Deploys ModelMesh serving infrastructure |
| Data Science Pipelines | CRD Management | Deploys DSP operator and Argo/Tekton backends |
| Ray | CRD Management | Deploys Ray operator for distributed computing |
| CodeFlare | CRD Management | Deploys CodeFlare operator for batch workloads |
| TrustyAI | CRD Management | Deploys TrustyAI service operator |
| Training Operator | CRD Management | Deploys Kubeflow Training Operator |
| Kueue | CRD Management | Deploys Kueue for job queueing |
| Model Registry | CRD Management | Deploys model registry service |

## Network Architecture

### Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| webhook-service | ClusterIP | 443/TCP | 9443 | HTTPS | TLS (OpenShift service CA) | K8s API Server mTLS | Internal |
| prometheus | ClusterIP | 9091/TCP | 9091 | HTTPS | TLS (OpenShift service CA) | OAuth Proxy | Internal |
| alertmanager | ClusterIP | 9093/TCP | 9093 | HTTPS | TLS (OpenShift service CA) | OAuth Proxy | Internal |
| blackbox-exporter | ClusterIP | 9115/TCP | 9115 | HTTP | None | None | Internal |

### Ingress

| Name | Type | Hosts | Port | Protocol | Encryption | TLS Mode | Exposure |
|------|------|-------|------|----------|------------|----------|----------|
| prometheus | OpenShift Route | Auto-generated | 443/TCP | HTTPS | TLS 1.2+ | Re-encrypt | Internal (OAuth) |
| alertmanager | OpenShift Route | Auto-generated | 443/TCP | HTTPS | TLS 1.2+ | Re-encrypt | Internal (OAuth) |

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| GitHub API | 443/TCP | HTTPS | TLS 1.2+ | None | Fetch component manifests (devFlags) |
| Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | Service Account Token | Cluster resource management |
| Component Git Repos | 443/TCP | HTTPS | TLS 1.2+ | None | Download manifests via get_all_manifests.sh |

## Security

### RBAC - Cluster Roles

| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|
| rhods-operator-role | apps | deployments, replicasets, statefulsets | * |
| rhods-operator-role | "" | services, configmaps, secrets, serviceaccounts, namespaces | * |
| rhods-operator-role | rbac.authorization.k8s.io | clusterroles, clusterrolebindings, roles, rolebindings | * |
| rhods-operator-role | datasciencecluster.opendatahub.io | datascienceclusters, datascienceclusters/status, datascienceclusters/finalizers | * |
| rhods-operator-role | dscinitialization.opendatahub.io | dscinitializations, dscinitializations/status, dscinitializations/finalizers | * |
| rhods-operator-role | components.platform.opendatahub.io | codeflares, dashboards, datasciencepipelines, kserves, kueues, modelcontrollers, modelmeshservings, modelregistries, rays, trainingoperators, trustyais, workbenches | create, delete, get, list, patch, update, watch |
| rhods-operator-role | services.platform.opendatahub.io | auths, monitorings | * |
| rhods-operator-role | features.opendatahub.io | featuretrackers | * |
| rhods-operator-role | route.openshift.io | routes | * |
| rhods-operator-role | monitoring.coreos.com | servicemonitors, prometheusrules | * |
| rhods-operator-role | apiextensions.k8s.io | customresourcedefinitions | create, delete, get, list, patch, update, watch |
| rhods-operator-role | admissionregistration.k8s.io | mutatingwebhookconfigurations, validatingwebhookconfigurations | create, delete, get, list, patch, update, watch |
| rhods-operator-role | authorino.kuadrant.io | authconfigs | * |
| rhods-operator-role | networking.k8s.io | networkpolicies | * |
| rhods-operator-role | batch | jobs, cronjobs | * |

### RBAC - Role Bindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| rhods-operator-rolebinding | - | rhods-operator-role (ClusterRole) | redhat-ods-operator:redhat-ods-operator-controller-manager |
| prometheus-rolebinding | redhat-ods-monitoring | prometheus-role (Role) | redhat-ods-monitoring:prometheus |

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| redhat-ods-operator-controller-webhook-cert | kubernetes.io/tls | Webhook server TLS certificate | OpenShift service CA | Yes |
| prometheus-tls | kubernetes.io/tls | Prometheus HTTPS endpoint certificate | OpenShift service CA | Yes |
| prometheus-proxy | Opaque | OAuth proxy cookie secret | Operator | No |
| prometheus-secret | kubernetes.io/service-account-token | Service account token for Prometheus | Kubernetes | Yes |
| alertmanager-proxy | Opaque | OAuth proxy cookie secret for Alertmanager | Operator | No |
| segment-key-secret | Opaque | Segment analytics key (managed RHOAI only) | External | No |

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| /metrics | GET | None (Internal only) | NetworkPolicy | Allow from monitoring namespaces |
| /healthz, /readyz | GET | None | None | Open to kubelet |
| Webhook endpoints | POST | mTLS | K8s API Server | API server client cert validation |
| Prometheus UI | GET, POST | OAuth Proxy | OAuth Proxy | OpenShift RBAC |
| Alertmanager UI | GET, POST | OAuth Proxy | OAuth Proxy | OpenShift RBAC |

### Network Policies

| Policy Name | Namespace | Pod Selector | Ingress Rules | Purpose |
|-------------|-----------|--------------|---------------|---------|
| redhat-ods-operator | redhat-ods-operator | control-plane: controller-manager | Allow from: redhat-ods-monitoring, openshift-monitoring, openshift-user-workload-monitoring, openshift-console, openshift-operators, opendatahub.io/generated-namespace=true, host-network pods | Restrict operator access |
| monitoring | redhat-ods-monitoring | (all pods) | Allow from: same namespace, openshift-monitoring, openshift-user-workload-monitoring, applications namespace | Restrict monitoring stack access |
| applications | redhat-ods-applications | (all pods) | Allow from: same namespace, openshift-monitoring, openshift-ingress | Restrict application namespace access |

## Data Flows

### Flow 1: Component Deployment via DataScienceCluster

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User/Admin | K8s API Server | 6443/TCP | HTTPS | TLS 1.2+ | User credentials |
| 2 | K8s API Server | rhods-operator webhook | 9443/TCP | HTTPS | TLS (service CA) | mTLS |
| 3 | K8s API Server | rhods-operator controller | N/A | Internal | N/A | Watch API |
| 4 | rhods-operator controller | K8s API Server | 6443/TCP | HTTPS | TLS 1.2+ | Service Account Token |
| 5 | rhods-operator controller | Component Namespaces | N/A | Internal | N/A | Apply manifests |

### Flow 2: Monitoring Metrics Collection

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Prometheus | rhods-operator | 8080/TCP | HTTP | None | Service Account Token |
| 2 | Prometheus | Component Services | Various | HTTP/HTTPS | Varies | Service Account Token |
| 3 | User | Prometheus Route | 443/TCP | HTTPS | TLS 1.2+ | OAuth (OpenShift) |
| 4 | Prometheus Route | OAuth Proxy | 9091/TCP | HTTPS | TLS (service CA) | OAuth Token |
| 5 | OAuth Proxy | Prometheus | 9090/TCP | HTTP | None | Internal |

### Flow 3: Platform Initialization

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | rhods-operator | K8s API Server | 6443/TCP | HTTPS | TLS 1.2+ | Service Account Token |
| 2 | rhods-operator | Service Mesh Namespace | N/A | Internal | N/A | Create ServiceMeshControlPlane |
| 3 | rhods-operator | Monitoring Namespace | N/A | Internal | N/A | Deploy Prometheus, Alertmanager |
| 4 | rhods-operator | Applications Namespace | N/A | Internal | N/A | Create namespace, labels, RBAC |

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| Kubernetes API Server | REST API Client | 6443/TCP | HTTPS | TLS 1.2+ | CRUD operations on cluster resources |
| OpenShift Service CA | Certificate Consumer | N/A | N/A | N/A | Obtain TLS certificates for services |
| Prometheus | ServiceMonitor CRD | 8080/TCP | HTTP | None | Expose operator metrics |
| OpenShift Console | ConsoleCRD | N/A | N/A | N/A | Register ODH console links |
| Service Mesh (Istio) | ServiceMeshMember CRD | N/A | N/A | N/A | Add namespaces to service mesh |
| OLM (Operator Lifecycle Manager) | CSV/Subscription | N/A | N/A | N/A | Operator installation and updates |

## Recent Changes

| Commit | Date | Changes |
|--------|------|---------|
| e2d77a515 | Recent | - Updating the operator repo with latest images and manifests |
| 39baf2823 | Recent | - chore(deps): update odh-dashboard-v2-17 to b3fe7fb |
| b57a933d4 | Recent | - chore(deps): update odh-trustyai-service-operator-v2-17 to 1e41ae5 |
| 41635230b | Recent | - Updating the operator repo with latest images and manifests |
| fe3d2c42f | Recent | - chore(deps): update odh-trustyai-service-operator-v2-17 to 7b28743 |
| 8aa04c5b9 | Recent | - chore(deps): update odh-trustyai-service-operator-v2-17 to 98abc77 |
| 4b4bf9edc | Recent | - Updating the operator repo with latest images and manifests |
| eb8693f14 | Recent | - chore(deps): update odh-trustyai-service-operator-v2-17 to 7d7d2dd |
| 9326235ae | Recent | - Updating the operator repo with latest images and manifests |
| faf43caeb | Recent | - chore(deps): update odh-trustyai-service-operator-v2-17 to 759cfc6 |

**Note**: Recent changes are primarily focused on updating component manifests and images, particularly for dashboard and TrustyAI components in the v2.17 release branch.

## Component Manifest Management

The operator uses a manifest-based approach to deploy components:

- **Embedded Manifests**: Component manifests are embedded in the operator image at `/opt/manifests/`
- **Runtime Manifests**: Components can override manifests at runtime via `devFlags.manifests` in CRs
- **Manifest Sources**: Manifests are sourced from component repositories using `get_all_manifests.sh`
- **Kustomize**: Operator applies manifests using Kustomize transformations

## Special Considerations

### Multi-Tenancy
- Supports single DSCInitialization and single DataScienceCluster per cluster
- Components are deployed into shared application namespace (default: redhat-ods-applications)
- User workloads isolated via namespace-based tenancy

### High Availability
- Operator runs with single replica (no leader election enabled by default)
- Components may have their own HA configurations

### Upgrade Handling
- CleanupExistingResource function handles cleanup from previous versions
- Version-specific upgrade logic in `pkg/upgrade` package
- Release version tracked and compared during operator startup

### Platform Detection
- Detects platform type: ManagedRhoai, SelfManagedRhoai, or OpenDataHub
- Adjusts behavior based on platform (e.g., monitoring only on ManagedRhoai)
- Uses cluster configuration and catalog sources for detection

### Resource Management
- Garbage Collection service tracks and cleans up operator-created resources
- FeatureTracker CRD provides cluster-scoped ownership for cross-namespace resources
- Labels and annotations track resource ownership and management state
