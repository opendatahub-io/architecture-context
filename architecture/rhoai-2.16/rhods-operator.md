# Component: RHODS Operator

## Metadata
- **Repository**: https://github.com/red-hat-data-services/rhods-operator
- **Version**: v-2160-5996-g221abd71f
- **Branch**: rhoai-2.16
- **Distribution**: RHOAI (Red Hat OpenShift AI)
- **Languages**: Go (Go 1.21+)
- **Deployment Type**: Kubernetes Operator (Kubebuilder-based)
- **Build System**: Konflux (production builds)

## Purpose
**Short**: Primary operator for RHOAI that manages the lifecycle of data science components through DataScienceCluster and DSCInitialization custom resources.

**Detailed**: The RHODS Operator is the central orchestration component for Red Hat OpenShift AI (RHOAI) and Open Data Hub (ODH). It enables data science applications like Jupyter Notebooks, Model Serving (KServe, ModelMesh), Data Science Pipelines, and distributed training frameworks by reconciling DataScienceCluster custom resources. The operator manages component deployment, configuration, monitoring, service mesh integration, and platform initialization. It provides a unified API for enabling/disabling components and handles cross-component dependencies, RBAC configuration, and namespace management. The operator supports both self-managed RHOAI and ODH distributions with platform-specific configurations.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| DataScienceCluster Controller | Kubernetes Controller | Reconciles DataScienceCluster CRs to deploy and manage data science components |
| DSCInitialization Controller | Kubernetes Controller | Initializes platform resources including service mesh, monitoring, and trusted CA bundles |
| CertConfigMapGenerator Controller | Kubernetes Controller | Generates ConfigMaps containing trusted CA certificates for components |
| SecretGenerator Controller | Kubernetes Controller | Generates and manages secrets for components |
| Webhook Server | ValidatingWebhook/MutatingWebhook | Validates and mutates DataScienceCluster and DSCInitialization resources |
| Status Reporter | Status Manager | Aggregates and reports component health status |
| Component Reconcilers | Component Managers | Individual reconcilers for Dashboard, Workbenches, Pipelines, KServe, ModelMesh, CodeFlare, Ray, TrustyAI, ModelRegistry, Kueue, TrainingOperator |
| Feature Tracker | Resource Manager | Tracks features created via internal Features API for garbage collection |

## APIs Exposed

### Custom Resource Definitions (CRDs)

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| datasciencecluster.opendatahub.io | v1 | DataScienceCluster | Cluster | Defines desired state of data science components to be deployed |
| dscinitialization.opendatahub.io | v1 | DSCInitialization | Cluster | Initializes platform infrastructure including monitoring, service mesh, and namespaces |
| features.opendatahub.io | v1 | FeatureTracker | Cluster | Tracks features created via internal API for cross-namespace resource ownership and garbage collection |

### HTTP Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /healthz | GET | 8081/TCP | HTTP | None | None | Operator liveness probe |
| /readyz | GET | 8081/TCP | HTTP | None | None | Operator readiness probe |
| /validate-* | POST | 9443/TCP | HTTPS | TLS 1.2+ | mTLS (service cert) | Webhook validation endpoints for CRD mutations |
| /mutate-* | POST | 9443/TCP | HTTPS | TLS 1.2+ | mTLS (service cert) | Webhook mutation endpoints for CRD defaults |

### gRPC Services

| Service | Port | Protocol | Encryption | Auth | Purpose |
|---------|------|----------|------------|------|---------|
| N/A | N/A | N/A | N/A | N/A | Operator does not expose gRPC services |

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| Kubernetes | 1.25+ | Yes | Container orchestration platform |
| OpenShift | 4.12+ | No | Preferred platform for RHOAI with additional features |
| Service Mesh Operator (Istio) | 2.x | Conditional | Required for KServe and single-sign-on capabilities |
| Serverless Operator (Knative) | Latest | Conditional | Required for KServe component |
| Authorino Operator | Latest | Conditional | Required for model serving authentication |
| Operator Lifecycle Manager (OLM) | Latest | Yes | Operator installation and lifecycle management |
| cert-manager | Latest | No | Optional TLS certificate management |

### Internal ODH Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| ODH Dashboard | CRD-driven deployment | Deploys and manages dashboard manifests from component repository |
| Workbenches (Notebooks) | CRD-driven deployment | Deploys notebook controller and related resources |
| Data Science Pipelines | CRD-driven deployment | Deploys Kubeflow Pipelines components |
| KServe | CRD-driven deployment | Deploys KServe serving runtime with service mesh integration |
| ModelMesh Serving | CRD-driven deployment | Deploys ModelMesh for multi-model serving |
| CodeFlare | CRD-driven deployment | Deploys distributed workload orchestration |
| Ray | CRD-driven deployment | Deploys Ray cluster operator |
| TrustyAI | CRD-driven deployment | Deploys model explainability and bias detection |
| Model Registry | CRD-driven deployment | Deploys model metadata registry |
| Kueue | CRD-driven deployment | Deploys job queueing system |
| Training Operator | CRD-driven deployment | Deploys distributed training frameworks (TFJob, PyTorchJob, etc.) |

## Network Architecture

### Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| webhook-service | ClusterIP | 443/TCP | 9443 | HTTPS | TLS 1.2+ (OpenShift service cert) | mTLS | Internal (cluster) |
| prometheus | ClusterIP | 9091/TCP | 9091 | HTTPS | TLS 1.2+ (OpenShift service cert) | Bearer Token | Internal (monitoring namespace) |
| alertmanager | ClusterIP | 9093/TCP | 9093 | HTTP | None | None | Internal (monitoring namespace) |
| blackbox-exporter | ClusterIP | 9115/TCP | 9115 | HTTP | None | None | Internal (monitoring namespace) |
| rhods-operator-metrics | ClusterIP | 8443/TCP | 8443 | HTTPS | TLS 1.2+ (kube-rbac-proxy) | Bearer Token (SAR) | Internal (operator namespace) |

### Ingress

| Name | Type | Hosts | Port | Protocol | Encryption | TLS Mode | Exposure |
|------|------|-------|------|----------|------------|----------|----------|
| prometheus | OpenShift Route | prometheus-{namespace}.apps.{cluster} | 443/TCP | HTTPS | TLS 1.2+ | Edge (reencrypt) | External (authenticated) |
| alertmanager | OpenShift Route | alertmanager-{namespace}.apps.{cluster} | 443/TCP | HTTPS | TLS 1.2+ | Edge (reencrypt) | External (authenticated) |

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | Bearer Token (SA) | Resource reconciliation and watches |
| Component Git Repositories | 443/TCP | HTTPS | TLS 1.2+ | None | Fetch component manifests (optional via devFlags) |
| Quay.io / registry.redhat.io | 443/TCP | HTTPS | TLS 1.2+ | Pull Secret | Container image pulls |
| OpenShift OAuth Server | 443/TCP | HTTPS | TLS 1.2+ | OAuth | Authentication integration |

## Security

### RBAC - Cluster Roles

| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|
| rhods-operator-role | datasciencecluster.opendatahub.io | datascienceclusters, datascienceclusters/status, datascienceclusters/finalizers | create, delete, get, list, patch, update, watch |
| rhods-operator-role | dscinitialization.opendatahub.io | dscinitializations, dscinitializations/status, dscinitializations/finalizers | create, delete, get, list, patch, update, watch |
| rhods-operator-role | features.opendatahub.io | featuretrackers, featuretrackers/status | create, delete, get, list, patch, update, watch |
| rhods-operator-role | "" (core) | configmaps, secrets, serviceaccounts, services, namespaces, events | create, delete, get, list, patch, update, watch |
| rhods-operator-role | apps | deployments, replicasets, statefulsets, deployments/finalizers | create, delete, get, list, patch, update, watch |
| rhods-operator-role | rbac.authorization.k8s.io | clusterroles, clusterrolebindings, roles, rolebindings | create, delete, get, list, patch, update, watch |
| rhods-operator-role | route.openshift.io | routes | create, delete, get, list, patch, update, watch |
| rhods-operator-role | networking.k8s.io | networkpolicies | create, delete, get, list, patch, update, watch |
| rhods-operator-role | monitoring.coreos.com | servicemonitors, prometheusrules | create, delete, get, list, patch, update, watch |
| rhods-operator-role | authorino.kuadrant.io | authconfigs | create, delete, get, list, patch, update, watch |
| rhods-operator-role | admissionregistration.k8s.io | validatingwebhookconfigurations, mutatingwebhookconfigurations | create, delete, get, list, patch, update, watch |
| rhods-operator-role | apiextensions.k8s.io | customresourcedefinitions | create, delete, get, list, patch, watch |
| rhods-operator-role | serving.knative.dev | services | create, delete, get, list, patch, update, watch |
| rhods-operator-role | serving.kserve.io | inferenceservices, servingruntimes | create, delete, get, list, patch, update, watch |
| rhods-operator-role | maistra.io | servicemeshcontrolplanes, servicemeshmembers | create, delete, get, list, patch, update, watch |
| datasciencecluster-editor | datasciencecluster.opendatahub.io | datascienceclusters | create, delete, get, list, patch, update, watch |
| datasciencecluster-viewer | datasciencecluster.opendatahub.io | datascienceclusters | get, list, watch |
| dscinitialization-editor | dscinitialization.opendatahub.io | dscinitializations | create, delete, get, list, patch, update, watch |
| dscinitialization-viewer | dscinitialization.opendatahub.io | dscinitializations | get, list, watch |

### RBAC - Role Bindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| rhods-operator-role-binding | Cluster-wide | rhods-operator-role (ClusterRole) | redhat-ods-operator:redhat-ods-operator-controller-manager |
| prometheus-monitoring | redhat-ods-monitoring | cluster-monitoring-view (ClusterRole) | redhat-ods-monitoring:prometheus |
| rhods-prometheus-rolebinding | redhat-ods-applications | rhods-prometheus-role | redhat-ods-monitoring:prometheus |
| dedicated-admins-mgmt-rolebinding | redhat-ods-operator | dedicated-admins-management | dedicated-admins (Group) |

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| redhat-ods-operator-controller-webhook-cert | kubernetes.io/tls | Webhook server TLS certificate | service.beta.openshift.io/serving-cert-secret-name annotation | Yes (OpenShift) |
| prometheus-tls | kubernetes.io/tls | Prometheus service TLS certificate | service.alpha.openshift.io/serving-cert-secret-name annotation | Yes (OpenShift) |
| prometheus-proxy-tls | Opaque | Prometheus OAuth proxy session secret | Operator | No |

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| /validate-*, /mutate-* | POST | mTLS (Kubernetes API Server client cert) | Kubernetes API Server | Webhook called by API server during resource admission |
| /healthz, /readyz | GET | None | Kubelet | Unrestricted for health checks |
| Prometheus Metrics (8443) | GET | Bearer Token via kube-rbac-proxy | kube-rbac-proxy sidecar | SubjectAccessReview for metrics reader role |
| Prometheus UI (9091) | ALL | OAuth Proxy | OAuth Proxy sidecar | OpenShift OAuth integration |

## Data Flows

### Flow 1: DataScienceCluster Creation

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User/Admin | Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | Bearer Token (User) |
| 2 | Kubernetes API Server | Webhook Service | 9443/TCP | HTTPS | TLS 1.2+ | mTLS (API Server client cert) |
| 3 | Webhook Service | Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | Bearer Token (SA) |
| 4 | Controller (Watch) | Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | Bearer Token (SA) |
| 5 | Controller | Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | Bearer Token (SA) |

### Flow 2: Component Manifest Deployment

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Operator Controller | Kubernetes API Server (read DSC) | 6443/TCP | HTTPS | TLS 1.2+ | Bearer Token (SA) |
| 2 | Operator Controller | Kubernetes API Server (read DSCI) | 6443/TCP | HTTPS | TLS 1.2+ | Bearer Token (SA) |
| 3 | Operator Controller | Local Filesystem (/opt/manifests) | N/A | Local | None | Filesystem |
| 4 | Operator Controller | Kubernetes API Server (apply manifests) | 6443/TCP | HTTPS | TLS 1.2+ | Bearer Token (SA) |
| 5 | Operator Controller | Kubernetes API Server (update status) | 6443/TCP | HTTPS | TLS 1.2+ | Bearer Token (SA) |

### Flow 3: Monitoring and Metrics Collection

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Prometheus | Operator Metrics Endpoint | 8443/TCP | HTTPS | TLS 1.2+ | Bearer Token (Prometheus SA) |
| 2 | Prometheus | Component Metrics Endpoints | varies/TCP | HTTPS | TLS 1.2+ | Bearer Token (Prometheus SA) |
| 3 | OpenShift Monitoring | Prometheus (federation) | 9091/TCP | HTTPS | TLS 1.2+ | Bearer Token |
| 4 | Blackbox Exporter | Component HTTP Endpoints | 443/TCP | HTTPS | TLS 1.2+ | None |

### Flow 4: Service Mesh Integration (KServe)

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | DSCInitialization Controller | Kubernetes API Server (create SMCP) | 6443/TCP | HTTPS | TLS 1.2+ | Bearer Token (SA) |
| 2 | DSCInitialization Controller | Kubernetes API Server (create SMM) | 6443/TCP | HTTPS | TLS 1.2+ | Bearer Token (SA) |
| 3 | KServe Component Controller | Kubernetes API Server (configure networking) | 6443/TCP | HTTPS | TLS 1.2+ | Bearer Token (SA) |
| 4 | KServe Component Controller | Kubernetes API Server (create AuthorizationPolicy) | 6443/TCP | HTTPS | TLS 1.2+ | Bearer Token (SA) |

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| Kubernetes API Server | REST API (controller-runtime client) | 6443/TCP | HTTPS | TLS 1.2+ | Primary interaction for all CRUD operations on cluster resources |
| Service Mesh Control Plane | CRD API (ServiceMeshControlPlane, ServiceMeshMember) | 6443/TCP | HTTPS | TLS 1.2+ | Configure service mesh for KServe and component networking |
| Knative Serving | CRD API (KnativeServing) | 6443/TCP | HTTPS | TLS 1.2+ | Configure serverless infrastructure for KServe |
| Authorino | CRD API (AuthConfig) | 6443/TCP | HTTPS | TLS 1.2+ | Configure authentication for model serving endpoints |
| Prometheus Operator | CRD API (ServiceMonitor, PrometheusRule) | 6443/TCP | HTTPS | TLS 1.2+ | Configure monitoring for components |
| OpenShift OAuth | OAuth2 (openshift-oauth-apiserver) | 6443/TCP | HTTPS | TLS 1.2+ | Integrate with OpenShift authentication for monitoring UIs |
| OLM (Operator Lifecycle Manager) | CRD API (CSV, Subscription, OperatorCondition) | 6443/TCP | HTTPS | TLS 1.2+ | Manage operator upgrades and dependencies |

## Recent Changes

Based on git log from the last 3 months (recent 20 commits on rhoai-2.16 branch):

| Commit | Date | Changes |
|--------|------|---------|
| 221abd71f | Recent | - Updating the operator repo with latest images and manifests |
| ea2306163 | Recent | - Merge PR #20283: Component update for odh-model-controller-v2-16 |
| 87cc46276 | Recent | - chore(deps): update odh-model-controller-v2-16 to 0500da8 |
| 8e5cb61a0 | Recent | - Updating the operator repo with latest images and manifests |
| 77635cb76 | Recent | - Merge PR #20229: Component update for odh-training-operator-v2-16 |
| 85812d11c | Recent | - chore(deps): update odh-training-operator-v2-16 to fd3ab61 |
| 8a2f2aabf | Recent | - Updating the operator repo with latest images and manifests |
| 5133143ab | Recent | - Merge PR #20175: Component update for odh-modelmesh-v2-16 |
| 2e8bceb61 | Recent | - chore(deps): update odh-modelmesh-v2-16 to 270c372 |
| ccb14d904 | Recent | - Updating the operator repo with latest images and manifests |
| 0ea0b7ad0 | Recent | - Updating the operator repo with latest images and manifests |
| 84f9ee438 | Recent | - Merge PR #19843: Component update for odh-training-operator-v2-16 |
| bc59d1965 | Recent | - chore(deps): update odh-training-operator-v2-16 to e281efa |
| c70d500b7 | Recent | - Updating the operator repo with latest images and manifests |
| 0ff1cd744 | Recent | - Merge PR #19781: Component update for odh-notebook-controller-v2-16 |
| 88c164d0d | Recent | - Merge PR #19782: Component update for odh-kf-notebook-controller-v2-16 |
| 35b58168b | Recent | - chore(deps): update odh-kf-notebook-controller-v2-16 to 571410c |
| 2e5e21c0a | Recent | - chore(deps): update odh-notebook-controller-v2-16 to 2fb145b |
| 7945cddb1 | Recent | - Updating the operator repo with latest images and manifests |
| 96cc3d430 | Recent | - Merge PR #19696: Component update for odh-model-registry-operator-v2-16 |

**Summary**: Recent activity focuses on automated dependency updates via Konflux, updating component images and manifests for Model Controller, Training Operator, ModelMesh, Notebook Controllers, and Model Registry Operator. This indicates active maintenance and regular component version synchronization in the RHOAI 2.16 release branch.

## Deployment Architecture

### Operator Deployment

- **Namespace**: `redhat-ods-operator` (RHOAI) or `openshift-operators` (ODH community)
- **Replicas**: 1 (singleton operator)
- **Pod Security**:
  - `runAsNonRoot: true`
  - `allowPrivilegeEscalation: false`
  - Capabilities dropped: ALL
- **Resource Limits**:
  - CPU: 500m (request and limit)
  - Memory: 256Mi (request), 4Gi (limit)
- **Health Checks**:
  - Liveness: HTTP GET /healthz on port 8081 (15s initial delay, 20s period)
  - Readiness: HTTP GET /readyz on port 8081 (5s initial delay, 10s period)

### Managed Namespaces

| Namespace | Purpose | Created By |
|-----------|---------|------------|
| redhat-ods-operator | Operator deployment | OLM/Administrator |
| redhat-ods-applications | Component deployments (Dashboard, Workbenches, etc.) | DSCInitialization |
| redhat-ods-monitoring | Prometheus, Alertmanager, monitoring stack | DSCInitialization (if monitoring enabled) |
| istio-system | Service Mesh Control Plane | DSCInitialization (if service mesh enabled) |
| {custom}-model-registries | Model Registry instances | ModelRegistry component (configurable) |

### Configuration Management

- **Manifests Location**: `/opt/manifests` in operator container
- **Manifest Sources**:
  - Embedded manifests (built into container via Konflux)
  - Prefetched manifests (cloned from component repos during build)
  - Runtime manifests (monitoring, partners, OSD configs)
- **Override Mechanism**: `devFlags.manifests` in DataScienceCluster CR allows runtime manifest override from Git repos
- **Platform Detection**: Operator detects RHOAI vs ODH via operator release metadata

## Notable Design Patterns

### Component Integration Pattern
- Common `ComponentInterface` for all managed components
- Manifest-based deployment using embedded Kustomize overlays
- Component-specific reconciliation logic in dedicated packages
- Shared status reporting and lifecycle management

### Feature Framework
- Internal Features API for cross-namespace resource management
- FeatureTracker CRs for garbage collection ownership
- Template-based manifest generation with data providers

### Monitoring Integration
- Self-monitoring via Prometheus ServiceMonitor
- Component monitoring configuration via UpdatePrometheusConfig interface
- Blackbox exporter for endpoint health checks
- Integration with OpenShift monitoring via prometheus-k8s federation

### Service Mesh Integration
- Automatic ServiceMeshControlPlane and ServiceMeshMember creation
- Component-specific networking configuration (KServe, ModelMesh)
- Authorization policy generation for secure model serving
- mTLS enforcement for inter-component communication

### Platform Abstraction
- Platform-aware manifest selection (ODH vs RHOAI)
- OpenShift-specific features (Routes, OAuth, service-ca)
- Kubernetes compatibility for core functionality
- Addon integration for managed service deployments

## Troubleshooting Endpoints

| Endpoint | Access Method | Purpose |
|----------|---------------|---------|
| Operator Logs | `oc logs -n redhat-ods-operator deployment/rhods-operator` | Operator reconciliation logs and errors |
| DSC Status | `oc get datasciencecluster -o yaml` | View component deployment status |
| DSCI Status | `oc get dscinitialization -o yaml` | View platform initialization status |
| Component Events | `oc get events -n redhat-ods-applications` | Kubernetes events for component resources |
| Prometheus Metrics | `oc port-forward -n redhat-ods-operator svc/rhods-operator-metrics 8443:8443` | Operator metrics for debugging |
| Webhook Logs | Search operator logs for "webhook" | Validation and mutation webhook activity |
