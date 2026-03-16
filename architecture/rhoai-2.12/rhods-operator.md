# Component: RHODS Operator (rhods-operator)

## Metadata
- **Repository**: https://github.com/red-hat-data-services/rhods-operator.git
- **Version**: v1.6.0-718-g719153112
- **Branch**: rhoai-2.12
- **Distribution**: RHOAI (also serves as base for ODH)
- **Languages**: Go 1.21
- **Deployment Type**: Kubernetes Operator (Controller)

## Purpose
**Short**: Primary operator for Red Hat OpenShift AI (RHOAI) that manages the lifecycle of data science platform components via DataScienceCluster and DSCInitialization custom resources.

**Detailed**:
The RHODS Operator is the central orchestration component for the Red Hat OpenShift AI platform. It is responsible for deploying, configuring, and managing the complete lifecycle of data science applications and services including Jupyter Notebooks, Model Serving (KServe, ModelMesh), Data Science Pipelines, Workbenches, CodeFlare, Ray, Kueue, and TrustyAI.

The operator uses a declarative approach where administrators define their desired platform state through DataScienceCluster (DSC) custom resources that specify which components to enable, and DSCInitialization (DSCI) resources that configure platform-wide settings like service mesh integration, monitoring, and trusted CA bundles. The operator continuously reconciles the actual cluster state against the desired state, deploying component manifests from embedded or remote git repositories, managing RBAC permissions, configuring network policies, and integrating with OpenShift's service mesh for authentication and authorization.

It serves as an integration point, fetching and applying kustomize manifests for each managed component, while also providing cross-cutting platform capabilities like certificate management, secret generation, monitoring integration, and feature tracking for garbage collection of cross-namespace resources.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| DataScienceCluster Controller | Kubernetes Controller | Reconciles DataScienceCluster CRs to deploy and manage component lifecycles |
| DSCInitialization Controller | Kubernetes Controller | Reconciles DSCInitialization CRs for platform-wide settings (service mesh, monitoring, trusted CA) |
| SecretGenerator Controller | Kubernetes Controller | Generates and manages secrets required by platform components |
| CertConfigmapGenerator Controller | Kubernetes Controller | Generates and manages certificate ConfigMaps for TLS/mTLS |
| Component Reconcilers | Component Logic | Per-component reconciliation logic for Dashboard, KServe, Workbenches, Pipelines, CodeFlare, Ray, Kueue, ModelMesh, TrainingOperator, TrustyAI |
| Manifest Fetcher | Deployment Manager | Fetches component manifests from git repos and applies them via kustomize |
| Webhook Server | Admission Control | Validates and mutates DataScienceCluster and DSCInitialization resources |

## APIs Exposed

### Custom Resource Definitions (CRDs)

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| datasciencecluster.opendatahub.io | v1 | DataScienceCluster | Cluster | Defines which data science components to deploy and their configurations |
| dscinitialization.opendatahub.io | v1 | DSCInitialization | Cluster | Configures platform-wide settings (service mesh, monitoring, trusted CA bundles, namespaces) |
| features.opendatahub.io | v1 | FeatureTracker | Cluster | Tracks resources created via Features API for cross-namespace garbage collection |

### HTTP Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /metrics | GET | 8080/TCP | HTTP | None | Internal | Prometheus metrics for operator health and performance |
| /healthz | GET | 8081/TCP | HTTP | None | Internal | Liveness probe endpoint |
| /readyz | GET | 8081/TCP | HTTP | None | Internal | Readiness probe endpoint |
| /validate-* | POST | 9443/TCP | HTTPS | TLS 1.2+ | mTLS | Validating webhook for CR admission control |
| /mutate-* | POST | 9443/TCP | HTTPS | TLS 1.2+ | mTLS | Mutating webhook for CR admission control |

### gRPC Services

None - operator uses REST/HTTP APIs only.

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| Kubernetes | 1.26+ | Yes | Core orchestration platform |
| OpenShift | 4.11+ | Yes | Extended Kubernetes platform with Routes, OAuth, SCC |
| controller-runtime | v0.14.6 | Yes | Kubernetes controller framework |
| Service Mesh Operator (Istio) | Latest | Conditional | Required for KServe and enhanced authentication (mTLS, AuthorizationPolicy) |
| Serverless Operator (Knative) | Latest | Conditional | Required for KServe serverless serving |
| Authorino Operator | Latest | Conditional | Required for external authorization with Service Mesh |
| OpenShift Pipelines (Tekton) | Latest | Conditional | Required for Data Science Pipelines component |
| Prometheus Operator | v0.68.0 | No | Used for component monitoring when monitoring is enabled |
| cert-manager | Latest | No | Optional for certificate management in KServe |

### Internal ODH/RHOAI Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| ODH Dashboard | Deploys/Manages | Provides web UI for data science platform |
| KServe | Deploys/Manages | Model serving with serverless inference |
| ModelMesh Serving | Deploys/Manages | Multi-model serving for high-density deployments |
| Data Science Pipelines | Deploys/Manages | ML workflow orchestration (Kubeflow Pipelines/Tekton) |
| Workbenches | Deploys/Manages | Jupyter notebook environments and VS Code servers |
| CodeFlare | Deploys/Manages | Distributed ML training orchestration |
| Ray | Deploys/Manages | Distributed computing framework for ML |
| Kueue | Deploys/Manages | Job queueing and resource quota management |
| Training Operator | Deploys/Manages | Distributed training for PyTorch, TensorFlow, XGBoost |
| TrustyAI | Deploys/Manages | ML explainability and bias detection |

## Network Architecture

### Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| controller-manager-metrics-service | ClusterIP | 8443/TCP | 8080 | HTTP | TLS (via proxy) | kube-rbac-proxy | Internal |
| prometheus | ClusterIP | 9091/TCP | 9091 | HTTPS | TLS 1.2+ | prometheus-tls secret | Internal (monitoring namespace) |
| alertmanager | ClusterIP | 9093/TCP | 9093 | HTTP | TLS (serving-cert) | Internal | Internal (monitoring namespace) |
| blackbox-exporter | ClusterIP | 9115/TCP | 9115 | HTTP | None | None | Internal (monitoring namespace) |

### Ingress

| Name | Type | Hosts | Port | Protocol | Encryption | TLS Mode | Exposure |
|------|------|-------|------|----------|------------|----------|----------|
| prometheus | OpenShift Route | prometheus-redhat-ods-monitoring | 443/TCP | HTTPS | TLS 1.2+ | edge | Internal (requires auth) |
| alertmanager | OpenShift Route | alertmanager-redhat-ods-monitoring | 443/TCP | HTTPS | TLS 1.2+ | edge | Internal (requires auth) |

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| GitHub | 443/TCP | HTTPS | TLS 1.2+ | None | Fetch component manifests from git repositories |
| Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token | Manage cluster resources |
| Component Namespaces | Various | Various | Various | RBAC | Deploy and monitor managed components |

### Network Policies

| Policy Name | Namespace | Selector | Ingress From | Egress To | Purpose |
|-------------|-----------|----------|--------------|-----------|---------|
| redhat-ods-operator | redhat-ods-operator | control-plane: controller-manager | redhat-ods-monitoring, openshift-monitoring, openshift-user-workload-monitoring, opendatahub.io/generated-namespace=true | N/A | Restrict ingress to operator from monitoring and managed namespaces only |

## Security

### RBAC - Cluster Roles

| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|
| controller-manager-role | datasciencecluster.opendatahub.io | datascienceclusters, datascienceclusters/status, datascienceclusters/finalizers | create, delete, get, list, patch, update, watch |
| controller-manager-role | dscinitialization.opendatahub.io | dscinitializations, dscinitializations/status, dscinitializations/finalizers | create, delete, get, list, patch, update, watch |
| controller-manager-role | features.opendatahub.io | featuretrackers, featuretrackers/status | create, delete, get, list, patch, update, watch |
| controller-manager-role | "" (core) | namespaces, namespaces/finalizers | create, delete, get, list, patch, update, watch |
| controller-manager-role | "" (core) | configmaps, secrets, serviceaccounts, services, pods, events | create, delete, get, list, patch, update, watch |
| controller-manager-role | apps | deployments, deployments/finalizers, replicasets, statefulsets | create, delete, get, list, patch, update, watch |
| controller-manager-role | rbac.authorization.k8s.io | clusterroles, clusterrolebindings, roles, rolebindings | create, delete, get, list, patch, update, watch |
| controller-manager-role | route.openshift.io | routes | create, delete, get, list, patch, update, watch |
| controller-manager-role | networking.k8s.io | networkpolicies, ingresses | create, delete, get, list, patch, update, watch |
| controller-manager-role | serving.kserve.io | inferenceservices, servingruntimes, clusterservingruntimes | create, delete, get, list, patch, update, watch |
| controller-manager-role | operator.knative.dev | knativeservings | create, delete, get, list, patch, update, watch |
| controller-manager-role | maistra.io | servicemeshcontrolplanes, servicemeshmemberrolls, servicemeshmembers | create, get, list, patch, update, use, watch |
| controller-manager-role | networking.istio.io | gateways, virtualservices, envoyfilters | create, delete, get, list, patch, update, watch |
| controller-manager-role | security.istio.io | authorizationpolicies | create, delete, get, list, patch, update, watch |
| controller-manager-role | authorino.kuadrant.io | authconfigs | create, delete, get, list, patch, update, watch |
| controller-manager-role | monitoring.coreos.com | servicemonitors, podmonitors, prometheusrules, prometheuses, alertmanagers | create, delete, get, list, patch, update, watch |
| controller-manager-role | tekton.dev | * | create, delete, get, list, patch, update, watch |
| controller-manager-role | ray.io | rayclusters, rayjobs, rayservices | create, delete, get, list, patch, update, watch |
| controller-manager-role | batch | jobs, cronjobs | create, delete, get, list, patch, update, watch |
| controller-manager-role | apiextensions.k8s.io | customresourcedefinitions | create, delete, get, list, patch, watch |
| controller-manager-role | admissionregistration.k8s.io | validatingwebhookconfigurations, mutatingwebhookconfigurations | create, delete, get, list, patch, update, watch |
| controller-manager-role | console.openshift.io | consolelinks, odhquickstarts | create, delete, get, patch |
| controller-manager-role | oauth.openshift.io | oauthclients | create, delete, get, list, patch, update, watch |
| controller-manager-role | operators.coreos.com | clusterserviceversions, subscriptions | delete, get, list, update, watch |
| controller-manager-role | security.openshift.io | securitycontextconstraints | create, delete, get, list, patch, update, watch |

### RBAC - Role Bindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| controller-manager-rolebinding | cluster-wide | controller-manager-role | controller-manager (operator namespace) |
| leader-election-rolebinding | operator namespace | leader-election-role | controller-manager (operator namespace) |
| prometheus-scraper | component namespaces | prometheus-scraper | prometheus (monitoring namespace) |

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| prometheus-tls | kubernetes.io/tls | TLS certificate for Prometheus service | service.alpha.openshift.io/serving-cert-secret-name annotation | Yes (OpenShift) |
| webhook-server-cert | kubernetes.io/tls | TLS certificate for admission webhooks | cert-manager or OLM | No |
| Generated component secrets | Opaque | Component-specific credentials (DB passwords, API tokens, etc.) | SecretGenerator controller | No |
| odh-trusted-ca-bundle | ConfigMap | Cluster-wide and custom CA certificates | CertConfigmapGenerator controller | Yes (when cluster CA changes) |

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| /metrics (8080) | GET | kube-rbac-proxy | kube-rbac-proxy sidecar | ClusterRole: system:auth-delegator |
| /healthz, /readyz (8081) | GET | None | None | Unauthenticated (internal) |
| Webhooks (9443) | POST | mTLS | Kubernetes API Server | API server validates webhook server certificate |
| Managed Components | Various | OAuth/OIDC via Service Mesh | Istio + Authorino | AuthorizationPolicy + AuthConfig CRs |

## Data Flows

### Flow 1: DataScienceCluster Creation and Component Deployment

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User/Admin | Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | OpenShift OAuth |
| 2 | API Server | Webhook Server (operator) | 9443/TCP | HTTPS | mTLS | API Server client cert |
| 3 | DSC Controller (operator) | Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 4 | Manifest Fetcher (operator) | GitHub | 443/TCP | HTTPS | TLS 1.2+ | None |
| 5 | Component Reconciler (operator) | Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |

### Flow 2: Component Monitoring

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Prometheus | Operator metrics endpoint | 8443/TCP | HTTPS | TLS 1.2+ | Bearer Token (ServiceAccount) |
| 2 | Prometheus | Component metrics endpoints | Various | HTTPS | TLS 1.2+ | Bearer Token (ServiceAccount) |
| 3 | Alertmanager | Prometheus | 9091/TCP | HTTPS | TLS 1.2+ | Internal |
| 4 | OpenShift Monitoring | Prometheus | 9091/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |

### Flow 3: Secret and Certificate Generation

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | SecretGenerator Controller | Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 2 | CertConfigmapGenerator | Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 3 | CertConfigmapGenerator | OpenShift Proxy Config | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 4 | Controller | Component Namespaces | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| Kubernetes API Server | REST API Client | 6443/TCP | HTTPS | TLS 1.2+ | Create, update, delete all cluster resources |
| Service Mesh Control Plane | CR Management | 6443/TCP | HTTPS | TLS 1.2+ | Create ServiceMeshMember, configure mTLS and AuthZ |
| Knative Serving | CR Management | 6443/TCP | HTTPS | TLS 1.2+ | Create KnativeServing instances for KServe |
| Authorino | CR Management | 6443/TCP | HTTPS | TLS 1.2+ | Create AuthConfig for external authorization |
| Prometheus Operator | CR Management | 6443/TCP | HTTPS | TLS 1.2+ | Create ServiceMonitor, PodMonitor, PrometheusRule resources |
| OLM (Operator Lifecycle Manager) | CR Observation | 6443/TCP | HTTPS | TLS 1.2+ | Watch ClusterServiceVersions, Subscriptions for operator dependencies |
| OpenShift Console | CR Management | 6443/TCP | HTTPS | TLS 1.2+ | Create ConsoleLinks, ODHQuickStarts for UI integration |
| Component Operators | Manifest Deployment | 6443/TCP | HTTPS | TLS 1.2+ | Deploy component-specific CRs (InferenceService, DataSciencePipelinesApplication, etc.) |

## Deployment Architecture

### Operator Pod Specification

| Attribute | Value | Notes |
|-----------|-------|-------|
| Image | rhods-operator:latest | Built from UBI8 minimal base |
| Replicas | 1 | Leader election enabled for HA in future |
| Resource Requests | CPU: 500m, Memory: 256Mi | Minimum guaranteed resources |
| Resource Limits | CPU: 500m, Memory: 4Gi | Maximum allowed resources |
| Security Context | runAsNonRoot: true, allowPrivilegeEscalation: false, capabilities: drop ALL | Least privilege |
| Manifest Path | /opt/manifests | Embedded component manifests |
| Health Probes | Liveness: /healthz (8081), Readiness: /readyz (8081) | Initial delay: 15s / 5s |

### Namespaces

| Namespace | Purpose | Created By |
|-----------|---------|------------|
| redhat-ods-operator | Operator deployment | OLM or manual install |
| redhat-ods-applications | Default application namespace for components (Dashboard, Workbenches, etc.) | DSCI controller |
| redhat-ods-monitoring | Monitoring stack (Prometheus, Alertmanager) | DSCI controller |
| istio-system | Service Mesh control plane | DSCI controller (if managed) |
| redhat-ods-applications-auth-provider | Authorino instance for authentication | DSCI controller (if service mesh enabled) |
| knative-serving | KNative Serving for KServe | KServe component reconciler |
| opendatahub.io/generated-namespace=true | User-created data science project namespaces | Dashboard or user action |

## Component Manifest Sources

The operator embeds or fetches manifests from the following repositories (configured in `get_all_manifests.sh`):

| Component | Manifest Source | Format |
|-----------|-----------------|--------|
| Dashboard | opendatahub-io/odh-dashboard | Kustomize |
| KServe | opendatahub-io/kserve | Kustomize |
| ModelMesh Serving | opendatahub-io/modelmesh-serving | Kustomize |
| Data Science Pipelines | opendatahub-io/data-science-pipelines-operator | Kustomize |
| Workbenches | opendatahub-io/notebooks | Kustomize |
| CodeFlare | project-codeflare/codeflare-operator | Kustomize |
| Ray | ray-project/kuberay | Kustomize |
| Kueue | kubernetes-sigs/kueue | Kustomize |
| Training Operator | kubeflow/training-operator | Kustomize |
| TrustyAI | trustyai-explainability/trustyai-service-operator | Kustomize |

Manifests are fetched at build time by default, or can be overridden via DSC CR `.spec.components.<component>.devFlags.manifests` for development/testing.

## Reconciliation Logic

### DataScienceCluster Reconciliation

1. **Validation**: Webhook validates DSC CR (mutual exclusivity of KServe/ModelMesh, prerequisite operators)
2. **Component Iteration**: For each component in `.spec.components`:
   - Check `managementState` (Managed/Removed)
   - If Managed: Deploy manifests via kustomize, create RBAC, configure monitoring
   - If Removed: Remove component resources, cleanup RBAC
3. **Status Update**: Update `.status.installedComponents`, `.status.conditions`, `.status.phase`
4. **Feature Tracking**: Create/update FeatureTracker CRs for cross-namespace resource ownership
5. **Monitoring Integration**: Create/update ServiceMonitor, PodMonitor resources if monitoring enabled

### DSCInitialization Reconciliation

1. **Namespace Creation**: Create applications and monitoring namespaces if they don't exist
2. **Service Mesh Setup**: If managed, create ServiceMeshControlPlane, ServiceMeshMemberRoll, configure Authorino
3. **Trusted CA Bundle**: If managed, create/update odh-trusted-ca-bundle ConfigMap with cluster and custom CAs
4. **Monitoring Setup**: If managed, deploy Prometheus, Alertmanager, Grafana to monitoring namespace
5. **Network Policies**: Apply network policies for operator, monitoring, and application namespaces
6. **Status Update**: Update `.status.conditions`, `.status.phase`

## Recent Changes

| Commit | Date | Changes |
|--------|------|---------|
| 7191531 | Recent | Sync: fix for managed cluster upgrade with DSC already exists |
| 98f5e32 | Recent | Chore(service-mesh): exports configmap names to const |
| 493fa5b | Recent | Fix(feature): preserves original target namespace |
| 29231bd | Recent | Chore: renames IngressGatewaySpec type to GatewaySpec |
| 242da53 | Recent | Fix: devFlags for dashboard did not set correct values |
| 67056c3 | Recent | Chore: rename variable/function name |
| 3a58718 | Recent | Tests: dscinitialization_test: use monitoringNamespace in its test |
| 2dc404b | Recent | Tests: dscinitialization_test: add missing Context |
| 6fb6d4d | Recent | Tests: remove webhook_suite_test.go |
| a6ba0a7 | Recent | Fix: difference in rhoai not covered by odh change |

Note: This repository is on the rhoai-2.12 branch tracking the RHOAI 2.12 release. The component is actively maintained with regular fixes for service mesh integration, feature preservation, and upgrade scenarios.

## Platform Detection

The operator detects and adapts to different deployment platforms:

| Platform | Detection Method | Behavior |
|----------|------------------|----------|
| Managed RHOAI | Checks for RHMI/Addon CRs | Auto-creates default DSC CR, uses managed monitoring |
| Self-Managed OpenShift | Cluster platform detection | Uses OpenShift-specific resources (Routes, OAuth, SCC) |
| Upstream ODH | Config or namespace naming | May use different defaults, community manifests |

## Observability

### Metrics Exported

- Controller reconciliation duration and errors
- Component deployment status
- Resource creation/update/delete counts
- Webhook admission latency
- Leader election status
- Work queue depth and latency

### Logging

- Structured logging via zap logger
- Log levels configurable via `--log-mode` flag (prod/devel)
- Component-level log mode via DSCI `.spec.devFlags.logmode`
- Events generated for major reconciliation steps

### Health Checks

- **Liveness Probe**: /healthz ensures process is running
- **Readiness Probe**: /readyz ensures operator can accept work
- **Webhook Health**: Webhook server must be serving for cluster admission control

## Upgrade Strategy

- **In-Place Upgrades**: Operator upgrades are handled by OLM subscription updates
- **Resource Migration**: `upgrade.CleanupExistingResource` removes deprecated resources from v1 releases
- **Default CR Creation**: Auto-creates DSCI if `DISABLE_DSC_CONFIG != "true"`
- **Backward Compatibility**: Maintains compatibility with existing DSC/DSCI CRs during upgrades
- **Component Manifest Updates**: New operator versions may include updated component manifests

## Known Limitations

- Only one DataScienceCluster instance supported per cluster
- KServe and ModelMesh Serving cannot be enabled simultaneously
- Service Mesh is required for KServe single-model serving
- Component manifest customization requires component-specific knowledge
- Leader election not currently enabled (single replica)

## Future Roadmap

Based on codebase and community direction:
- Enhanced multi-tenancy and quota management
- Improved upgrade testing and automation
- Extended component customization APIs
- Advanced networking and service mesh configurations
- Integration with GitOps workflows (ArgoCD)
- Enhanced observability and telemetry
