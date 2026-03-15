# Component: RHOAI Operator (rhods-operator)

## Metadata
- **Repository**: https://github.com/red-hat-data-services/rhods-operator.git
- **Version**: v1.6.0-7305-gd6c55ac5b
- **Branch**: rhoai-2.25
- **Distribution**: RHOAI (Red Hat OpenShift AI)
- **Languages**: Go 1.24.4
- **Deployment Type**: Kubernetes Operator
- **Build System**: Konflux

## Purpose
**Short**: Manages the lifecycle and configuration of Red Hat OpenShift AI data science platform components.

**Detailed**: The RHOAI Operator (rhods-operator) is the primary operator for Red Hat OpenShift AI, responsible for deploying, configuring, and managing the complete data science platform. It orchestrates the installation of multiple AI/ML components including Jupyter Notebooks, KServe model serving, Data Science Pipelines, CodeFlare distributed computing, TrustyAI explainability, Model Registry, and various other components. The operator uses a declarative `DataScienceCluster` Custom Resource to enable and configure components, and a `DSCInitialization` CR to initialize platform-wide services like monitoring, service mesh integration, and authentication. It employs a Kustomize-based manifest rendering system to deploy over 220 component manifests from prefetched component repositories, ensuring consistent deployment across OpenShift clusters.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| rhods-operator | Go Operator | Main controller managing DataScienceCluster and DSCInitialization CRs |
| Component Controllers | Go Controllers | 14 component-specific controllers for dashboard, kserve, pipelines, codeflare, ray, kueue, modelregistry, modelmeshserving, trustyai, trainingoperator, workbenches, feastoperator, llamastackoperator, modelcontroller |
| Service Controllers | Go Controllers | Platform service controllers for auth, monitoring, servicemesh, secret generation, certificate management |
| Webhook Server | Admission Webhooks | Validates and mutates DataScienceCluster and DSCInitialization resources |
| Metrics Server | Prometheus Exporter | Exposes operator and component metrics via kube-rbac-proxy |
| Manifest Renderer | Kustomize Engine | Renders 220+ component manifests using Kustomize with overlay support |
| Feature Tracker | CR Controller | Tracks feature enablement and configuration across components |
| Hardware Profile Manager | CR Controller | Manages hardware profiles for GPU/accelerator configurations |

## APIs Exposed

### Custom Resource Definitions (CRDs)

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| datasciencecluster.opendatahub.io | v1 | DataScienceCluster | Cluster | Main CR for enabling/configuring AI/ML components |
| dscinitialization.opendatahub.io | v1 | DSCInitialization | Cluster | Initializes platform services (monitoring, service mesh, auth) |
| components.platform.opendatahub.io | v1alpha1 | Dashboard | Cluster | ODH Dashboard component configuration |
| components.platform.opendatahub.io | v1alpha1 | KServe | Cluster | KServe model serving component configuration |
| components.platform.opendatahub.io | v1alpha1 | DataSciencePipelines | Cluster | Data Science Pipelines component configuration |
| components.platform.opendatahub.io | v1alpha1 | CodeFlare | Cluster | CodeFlare distributed computing configuration |
| components.platform.opendatahub.io | v1alpha1 | Ray | Cluster | Ray distributed computing configuration |
| components.platform.opendatahub.io | v1alpha1 | Kueue | Cluster | Kueue job queueing configuration |
| components.platform.opendatahub.io | v1alpha1 | ModelRegistry | Cluster | Model Registry component configuration |
| components.platform.opendatahub.io | v1alpha1 | ModelMeshServing | Cluster | ModelMesh multi-model serving configuration |
| components.platform.opendatahub.io | v1alpha1 | TrustyAI | Cluster | TrustyAI explainability service configuration |
| components.platform.opendatahub.io | v1alpha1 | TrainingOperator | Cluster | Training Operator configuration |
| components.platform.opendatahub.io | v1alpha1 | Workbenches | Cluster | Jupyter workbenches configuration |
| components.platform.opendatahub.io | v1alpha1 | FeastOperator | Cluster | Feast feature store operator configuration |
| components.platform.opendatahub.io | v1alpha1 | LlamaStackOperator | Cluster | Llama Stack operator configuration |
| components.platform.opendatahub.io | v1alpha1 | ModelController | Cluster | Model controller configuration |
| services.platform.opendatahub.io | v1alpha1 | Auth | Cluster | Authentication and authorization service configuration |
| services.platform.opendatahub.io | v1alpha1 | Monitoring | Cluster | Prometheus/Alertmanager monitoring stack configuration |
| services.platform.opendatahub.io | v1alpha1 | ServiceMesh | Cluster | Istio service mesh integration configuration |
| features.opendatahub.io | v1 | FeatureTracker | Cluster | Tracks feature enablement across components |
| infrastructure.opendatahub.io | v1alpha1 | HardwareProfile | Cluster | Defines hardware profiles for accelerators/GPUs |

### HTTP Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /metrics | GET | 8080/TCP | HTTP | None | kube-rbac-proxy | Prometheus metrics endpoint |
| /healthz | GET | 8081/TCP | HTTP | None | None | Health probe endpoint |
| /readyz | GET | 8081/TCP | HTTP | None | None | Readiness probe endpoint |
| /validate-* | POST | 9443/TCP | HTTPS | TLS 1.2+ | mTLS | Validating webhook for CR mutations |
| /mutate-* | POST | 9443/TCP | HTTPS | TLS 1.2+ | mTLS | Mutating webhook for CR defaults |

### Webhook Endpoints

| Webhook | Type | Port | Protocol | Encryption | Auth | Purpose |
|---------|------|------|----------|------------|------|---------|
| webhook-service | ValidatingWebhookConfiguration | 443/TCP | HTTPS | TLS (OpenShift service-ca) | mTLS | Validates DataScienceCluster CRs |
| webhook-service | MutatingWebhookConfiguration | 443/TCP | HTTPS | TLS (OpenShift service-ca) | mTLS | Sets defaults on DataScienceCluster CRs |

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| Kubernetes | 1.32+ | Yes | Container orchestration platform |
| OpenShift | 4.x | Yes | Enterprise Kubernetes distribution (RHOAI requires OpenShift) |
| Service Mesh Operator (Istio) | 2.x | Conditional | Required for KServe and authentication features |
| Serverless Operator (Knative) | Latest | Conditional | Required for KServe model serving |
| Authorino Operator | Latest | Conditional | Required for auth-based model serving authorization |
| Prometheus Operator | 0.68.0 | Yes | Monitoring stack deployment |
| cert-manager | Latest | Conditional | Certificate management for KServe |
| OpenShift Pipelines | Latest | No | Enhanced pipeline execution (optional) |

### Internal ODH Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| odh-dashboard | Deployed Component | Web UI for platform management deployed via manifests |
| kserve-controller | Deployed Component | Model serving infrastructure deployed via manifests |
| data-science-pipelines-operator | Deployed Component | ML pipeline orchestration deployed via manifests |
| modelmesh-controller | Deployed Component | Multi-model serving infrastructure deployed via manifests |
| codeflare-operator | Deployed Component | Distributed computing workload management deployed via manifests |
| kuberay-operator | Deployed Component | Ray cluster management deployed via manifests |
| training-operator | Deployed Component | ML training job management deployed via manifests |
| model-registry-operator | Deployed Component | Model versioning and metadata deployed via manifests |
| trustyai-service-operator | Deployed Component | Model explainability service deployed via manifests |

## Network Architecture

### Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| redhat-ods-operator-controller-manager-metrics-service | ClusterIP | 8443/TCP | 8080 | HTTP | None (kube-rbac-proxy) | Bearer Token (SAR) | Internal |
| webhook-service | ClusterIP | 443/TCP | 9443 | HTTPS | TLS (service-ca) | mTLS | Internal |

### Network Policies

| Policy Name | Namespace | Pod Selector | Ingress From | Purpose |
|-------------|-----------|--------------|--------------|---------|
| redhat-ods-operator | redhat-ods-operator | control-plane=controller-manager | redhat-ods-monitoring, openshift-monitoring, openshift-user-workload-monitoring, openshift-console, openshift-operators, opendatahub.io/generated-namespace=true, host-network pods | Restricts operator pod ingress to monitoring and management namespaces |

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token | CR management, resource creation |
| Component Namespaces | Various | Various | Various | ServiceAccount Token | Component deployment and management |
| OpenShift Image Registry | 5000/TCP | HTTPS | TLS 1.2+ | Pull Secrets | Container image pulls |
| External Git Repos | 443/TCP | HTTPS | TLS 1.2+ | None | Manifest downloads (via devFlags.manifests) |

## Security

### RBAC - Cluster Roles

| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|
| rhods-operator-role | datasciencecluster.opendatahub.io | datascienceclusters, datascienceclusters/status, datascienceclusters/finalizers | create, delete, get, list, patch, update, watch |
| rhods-operator-role | dscinitialization.opendatahub.io | dscinitializations, dscinitializations/status, dscinitializations/finalizers | create, delete, get, list, patch, update, watch |
| rhods-operator-role | components.platform.opendatahub.io | codeflares, dashboards, datasciencepipelines, kserves, kueues, modelregistries, modelmeshservings, rays, trainingoperators, trustyais, workbenches, feastoperators, llamastackoperators, modelcontrollers | create, delete, get, list, patch, update, watch |
| rhods-operator-role | services.platform.opendatahub.io | auths, monitorings, servicemeshes | create, delete, get, list, patch, update, watch |
| rhods-operator-role | features.opendatahub.io | featuretrackers, featuretrackers/status, featuretrackers/finalizers | create, delete, get, list, patch, update, watch |
| rhods-operator-role | infrastructure.opendatahub.io | hardwareprofiles, hardwareprofiles/status, hardwareprofiles/finalizers | create, delete, get, list, patch, update, watch |
| rhods-operator-role | "" (core) | configmaps, secrets, serviceaccounts, services, namespaces, pods, persistentvolumeclaims | create, delete, get, list, patch, update, watch |
| rhods-operator-role | apps | deployments, deployments/finalizers, replicasets, statefulsets | * (all) |
| rhods-operator-role | rbac.authorization.k8s.io | clusterroles, clusterrolebindings, roles, rolebindings | * (all) |
| rhods-operator-role | networking.k8s.io | networkpolicies, ingresses | create, delete, get, list, patch, update, watch |
| rhods-operator-role | route.openshift.io | routes | create, delete, get, list, patch, update, watch |
| rhods-operator-role | monitoring.coreos.com | servicemonitors, prometheusrules, podmonitors | create, delete, get, list, patch, update, watch |
| rhods-operator-role | maistra.io | servicemeshcontrolplanes, servicemeshmembers, servicemeshmemberrolls | create, delete, get, list, patch, update, use, watch |
| rhods-operator-role | operator.knative.dev | knativeservings, knativeservings/finalizers | * (all) |
| rhods-operator-role | serving.kserve.io | inferenceservices, servingruntimes, clusterservingruntimes | create, delete, get, list, patch, update, watch |
| rhods-operator-role | apiextensions.k8s.io | customresourcedefinitions | create, delete, get, list, patch, update, watch |
| rhods-operator-role | admissionregistration.k8s.io | validatingwebhookconfigurations, mutatingwebhookconfigurations | create, delete, get, list, patch, update, watch |
| rhods-operator-role | console.openshift.io | consolelinks, odhquickstarts | create, delete, get, list, patch, update, watch |

### RBAC - Role Bindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| rhods-operator-rolebinding | Cluster-wide | rhods-operator-role | redhat-ods-operator/rhods-operator-controller-manager |

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| redhat-ods-operator-controller-webhook-cert | kubernetes.io/tls | Webhook server TLS certificate | service.beta.openshift.io/serving-cert-secret-name annotation | Yes (OpenShift service-ca) |
| redhat-ods-operator-leader-election | Opaque | Leader election lock | controller-runtime | No |
| prometheus-secrets | Opaque | Prometheus configuration secrets | Operator | No |
| segment-key-secret | Opaque | Segment analytics API key (optional telemetry) | Manual/Operator | No |

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| /metrics | GET | Bearer Token + SubjectAccessReview | kube-rbac-proxy | Must have 'get' on rhods-operator service |
| /validate-* | POST | mTLS Client Certificates | Kubernetes API Server | API server validates webhook certificates |
| /mutate-* | POST | mTLS Client Certificates | Kubernetes API Server | API server validates webhook certificates |
| Kubernetes API | ALL | ServiceAccount Token | Kubernetes RBAC | ClusterRole rhods-operator-role |

## Data Flows

### Flow 1: DataScienceCluster Creation and Component Deployment

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User/GitOps | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | kubectl/oc credentials |
| 2 | Kubernetes API | rhods-operator webhook | 9443/TCP | HTTPS | TLS (service-ca) | mTLS |
| 3 | rhods-operator webhook | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 4 | rhods-operator controller | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 5 | rhods-operator controller | Component Namespaces | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |

### Flow 2: Monitoring and Metrics Collection

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Prometheus | kube-rbac-proxy | 8443/TCP | HTTPS | TLS 1.2+ | Bearer Token (ServiceAccount) |
| 2 | kube-rbac-proxy | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | SubjectAccessReview |
| 3 | kube-rbac-proxy | rhods-operator /metrics | 8080/TCP | HTTP | None (localhost) | None (proxied) |

### Flow 3: Component Manifest Rendering and Deployment

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | rhods-operator controller | Local /opt/manifests | N/A | Filesystem | None | Container FS permissions |
| 2 | Kustomize renderer | Component manifests | N/A | Filesystem | None | Container FS permissions |
| 3 | rhods-operator controller | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 4 | rhods-operator controller | Component Namespaces | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |

### Flow 4: Webhook Validation and Mutation

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User CR Update | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | kubectl/oc credentials |
| 2 | Kubernetes API | webhook-service | 443/TCP | HTTPS | TLS (service-ca) | mTLS |
| 3 | webhook-service | rhods-operator webhook handler | 9443/TCP | HTTPS | TLS (service-ca) | mTLS (internal) |
| 4 | webhook handler | Validation logic | N/A | In-process | N/A | N/A |

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| Kubernetes API Server | REST API | 6443/TCP | HTTPS | TLS 1.2+ | CR lifecycle, resource management |
| Prometheus Operator | CRD Creation | 6443/TCP | HTTPS | TLS 1.2+ | Deploy ServiceMonitors, PrometheusRules |
| Service Mesh Operator | CRD Management | 6443/TCP | HTTPS | TLS 1.2+ | Create ServiceMeshMembers, ServiceMeshControlPlanes |
| Serverless Operator | CRD Management | 6443/TCP | HTTPS | TLS 1.2+ | Manage KnativeServing for KServe |
| Authorino Operator | CRD Management | 6443/TCP | HTTPS | TLS 1.2+ | Configure AuthConfigs for model serving |
| OpenShift OAuth | OAuth Client Creation | 6443/TCP | HTTPS | TLS 1.2+ | Create OAuthClients for component authentication |
| OpenShift Console | ConsoleLink Creation | 6443/TCP | HTTPS | TLS 1.2+ | Add dashboard links to OpenShift console |
| OpenShift Service CA | Certificate Injection | N/A | ConfigMap Watch | N/A | Auto-inject trusted CA bundles |
| Component Operators | Manifest Deployment | 6443/TCP | HTTPS | TLS 1.2+ | Deploy operator manifests for each component |
| OpenTelemetry Collector | Instrumentation CRs | 6443/TCP | HTTPS | TLS 1.2+ | Create OpenTelemetryCollector instances |
| Tempo Operator | TempoStack CRs | 6443/TCP | HTTPS | TLS 1.2+ | Deploy distributed tracing backend |

## Recent Changes

| Commit | Date | Changes |
|--------|------|---------|
| d6c55ac5b | 2025-03-13 | - Updated operator repo with latest images and manifests |
| 1d74fc204 | 2025-03-13 | - Updated odh-dashboard-v2-25 to b94336b |
| 505613340 | 2025-03-13 | - chore(deps): update odh-dashboard-v2-25 to b94336b |
| 386fd0625 | 2025-03-13 | - Updated operator repo with latest images and manifests |
| f86858fae | 2025-03-13 | - Updated odh-ml-pipelines-runtime-generic-v2-25 to 18ef0ff |
| 580f8edca | 2025-03-13 | - chore(deps): update odh-ml-pipelines-runtime-generic-v2-25 to 18ef0ff |
| 9c051032c | 2025-03-13 | - Updated operator repo with latest images and manifests |
| e25074076 | 2025-03-13 | - Updated odh-training-operator-v2-25 to c41a4d3 |
| 8fca82fc7 | 2025-03-13 | - chore(deps): update odh-training-operator-v2-25 to c41a4d3 |
| 516155a35 | 2025-03-13 | - Updated odh-ml-pipelines-api-server-v2-v2-25 to 9498fb2 |
| f5c619c1e | 2025-03-13 | - chore(deps): update odh-ml-pipelines-api-server-v2-v2-25 to 9498fb2 |
| 69e2c65d8 | 2025-03-13 | - Updated operator repo with latest images and manifests |
| 44388f292 | 2025-03-13 | - Updated odh-dashboard-v2-25 to 0432ddf |
| ce23cb33f | 2025-03-13 | - chore(deps): update odh-dashboard-v2-25 to 0432ddf |
| 413f952c3 | 2025-03-13 | - Updated odh-modelmesh-runtime-adapter-v2-25 to fe0c68b |
| cb989d05e | 2025-03-13 | - chore(deps): update odh-modelmesh-runtime-adapter-v2-25 to fe0c68b |
| f6993571d | 2025-03-13 | - Updated odh-model-registry-v2-25 to 599f50f |
| 9e3543495 | 2025-03-13 | - chore(deps): update odh-model-registry-v2-25 to 599f50f |
| 32ff0800a | 2025-03-13 | - chore(deps): update registry.redhat.io/ubi9/go-toolset:1.25 docker digest to 3cdf0d1 |
| ae8cd261c | 2025-03-13 | - Updated odh-data-science-pipelines-argo-argoexec-v2-25 component |

## Deployment Architecture

### Container Images

| Image | Base | Purpose | Build System |
|-------|------|---------|--------------|
| odh-rhel8-operator | registry.access.redhat.com/ubi9/ubi-minimal | Main operator controller | Konflux |

### Container Ports

| Container | Port | Protocol | Purpose |
|-----------|------|----------|---------|
| rhods-operator | 8080/TCP | HTTP | Metrics endpoint (proxied by kube-rbac-proxy) |
| rhods-operator | 8081/TCP | HTTP | Health and readiness probes |
| rhods-operator | 9443/TCP | HTTPS | Webhook server |

### Resource Requirements

| Component | CPU Request | CPU Limit | Memory Request | Memory Limit |
|-----------|-------------|-----------|----------------|--------------|
| rhods-operator | Not specified | Not specified | Not specified | Not specified |
| kube-rbac-proxy | Not specified | Not specified | Not specified | Not specified |

### Environment Variables

| Variable | Default | Purpose |
|----------|---------|---------|
| ODH_MANAGER_METRICS_BIND_ADDRESS | :8080 | Metrics endpoint address |
| ODH_MANAGER_HEALTH_PROBE_BIND_ADDRESS | :8081 | Health probe endpoint address |
| ODH_MANAGER_LEADER_ELECT | false | Enable leader election |
| ZAP_LOG_LEVEL | info | Log verbosity level |
| OPERATOR_NAMESPACE | redhat-ods-operator | Operator installation namespace |

### Volumes and Mounts

| Volume | Type | Mount Path | Purpose |
|--------|------|------------|---------|
| webhook-cert | Secret | /tmp/k8s-webhook-server/serving-certs | Webhook TLS certificates |
| manifests | EmptyDir/Image | /opt/manifests | Component Kustomize manifests (223 manifest sets) |

## Platform Services

### Monitoring Service

The operator deploys a complete monitoring stack when `DSCInitialization.spec.monitoring.managementState: Managed`:

| Component | Type | Purpose |
|-----------|------|---------|
| Prometheus | StatefulSet | Metrics collection and storage (90d retention default) |
| Alertmanager | StatefulSet | Alert routing and notification |
| Blackbox Exporter | Deployment | Endpoint availability monitoring |
| OpenTelemetry Collector | Deployment | Traces and metrics collection |
| Tempo | StatefulSet | Distributed tracing backend |
| ServiceMonitors | CRD | Auto-discovery of metrics endpoints |
| PrometheusRules | CRD | Alert rule definitions |

### Auth Service

When `Auth` CR is created, the operator configures:

| Component | Purpose |
|-----------|---------|
| OAuthClient | OpenShift OAuth integration |
| ServiceMeshMember | Istio integration for dashboard |
| AuthorizationPolicies | Istio-based access control |
| Admin Groups Configuration | RBAC for admin access |
| Allowed Groups Configuration | RBAC for general user access |

### Service Mesh Integration

When `ServiceMesh` CR is created, the operator:

| Action | Purpose |
|--------|---------|
| Creates ServiceMeshMember | Adds application namespace to mesh |
| Configures SMCP Integration | Links to existing ServiceMeshControlPlane |
| Deploys Authorino | Configures auth for model serving |
| Creates VirtualServices | Routes for component services |
| Creates Gateways | External access points |

## Component Manifest Management

The operator manages 223 Kustomize manifest sets for deployed components:

| Component | Manifest Count | Purpose |
|-----------|----------------|---------|
| Dashboard | 40+ | ODH Dashboard UI and APIs |
| KServe | 30+ | Model serving infrastructure |
| Data Science Pipelines | 35+ | ML pipeline orchestration |
| CodeFlare | 20+ | Distributed computing |
| Ray | 15+ | Ray cluster operator |
| ModelMesh Serving | 25+ | Multi-model serving |
| Model Registry | 15+ | Model versioning |
| TrustyAI | 10+ | Model explainability |
| Training Operator | 15+ | ML training jobs |
| Workbenches | 10+ | Jupyter notebook servers |
| Kueue | 10+ | Job queueing |
| Feast Operator | 8+ | Feature store |

Manifests are:
- Pre-fetched from component repositories into `/opt/manifests` during image build
- Rendered using Kustomize with overlay support (odh/rhoai variants)
- Can be overridden at runtime via `devFlags.manifests` in component specs
- Deployed to application namespace (default: `redhat-ods-applications`)

## Observability

### Metrics Exposed

| Metric Prefix | Purpose |
|---------------|---------|
| controller_runtime_* | Controller-runtime framework metrics |
| workqueue_* | Work queue performance metrics |
| datasciencecluster_* | DataScienceCluster reconciliation metrics |
| dscinitialization_* | DSCInitialization reconciliation metrics |
| component_* | Individual component status metrics |

### Logging

| Logger | Level | Purpose |
|--------|-------|---------|
| controller-runtime | Info | Framework operations |
| datasciencecluster-controller | Info | DSC reconciliation |
| dscinitialization-controller | Info | DSCI reconciliation |
| webhook | Info | Webhook validations |

### Health Checks

| Endpoint | Type | Success Criteria |
|----------|------|------------------|
| /healthz | Liveness | Controller manager running |
| /readyz | Readiness | Leader elected, webhooks registered |

## Operational Notes

### Leader Election
- Uses Lease-based leader election in `redhat-ods-operator` namespace
- Lease name: `rhods-operator-leader-election`
- Enables high availability deployments

### Finalizers
- `datasciencecluster.opendatahub.io/finalizer`: Ensures component cleanup
- `dscinitialization.opendatahub.io/finalizer`: Ensures service cleanup
- Component-specific finalizers for each enabled component

### Upgrade Strategy
- Operator upgrades managed via OLM (Operator Lifecycle Manager)
- Component manifests updated automatically on operator upgrade
- Supports in-place upgrades without service disruption
- Version compatibility tracked via `DataScienceCluster.status.release`

### Troubleshooting
- Check operator logs: `oc logs -n redhat-ods-operator deployment/rhods-operator`
- Verify CR status: `oc get datasciencecluster -o yaml`
- Check component status: `oc get <component-cr> -o yaml`
- Review events: `oc get events -n redhat-ods-operator`
- Validate webhooks: `oc get validatingwebhookconfiguration,mutatingwebhookconfiguration`
