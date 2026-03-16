# Component: RHODS Operator (rhods-operator)

## Metadata
- **Repository**: https://github.com/red-hat-data-services/rhods-operator
- **Version**: v1.6.0-2256-g3f6121927
- **Branch**: rhoai-2.13
- **Distribution**: RHOAI
- **Languages**: Go 1.21
- **Deployment Type**: Kubernetes Operator
- **Build System**: Konflux

## Purpose
**Short**: Primary operator for Red Hat OpenShift AI (RHOAI) that deploys and manages data science platform components.

**Detailed**: The RHODS Operator is the central orchestration component for Red Hat OpenShift AI. It manages the lifecycle of multiple data science components including Jupyter notebooks, model serving (KServe/ModelMesh), data science pipelines, workbenches, and distributed computing frameworks. The operator uses a declarative approach through two primary CRDs: DataScienceCluster for enabling/configuring components and DSCInitialization for platform-level initialization including service mesh, monitoring, and trusted CA bundle configuration. It dynamically fetches component manifests from Git repositories and applies them using Kustomize, enabling flexible deployment configurations across different environments. The operator also manages critical platform features such as OAuth client generation, certificate management, and integration with OpenShift's service mesh and serverless infrastructure.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| DataScienceCluster Controller | Reconciler | Manages lifecycle of ODH/RHOAI components based on DataScienceCluster CR |
| DSCInitialization Controller | Reconciler | Initializes platform-level resources (namespaces, service mesh, monitoring) |
| SecretGenerator Controller | Reconciler | Generates OAuth clients and secrets for component authentication |
| CertConfigmapGenerator Controller | Reconciler | Manages trusted CA bundle ConfigMaps across namespaces |
| Component Manifests | Kustomize | Fetched from Git repos, deployed via apply operations |
| Monitoring Stack | Prometheus/Alertmanager | Operator-deployed monitoring infrastructure |

## APIs Exposed

### Custom Resource Definitions (CRDs)

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| datasciencecluster.opendatahub.io | v1 | DataScienceCluster | Cluster | Declares which ODH components to enable and their configuration |
| dscinitialization.opendatahub.io | v1 | DSCInitialization | Cluster | Configures platform initialization (namespaces, service mesh, monitoring, trusted CA) |
| features.opendatahub.io | v1 | FeatureTracker | Cluster | Tracks feature-created resources for garbage collection across namespaces |

### HTTP Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /metrics | GET | 8080/TCP | HTTP | None | ServiceAccount Token | Prometheus metrics endpoint |
| /healthz | GET | 8081/TCP | HTTP | None | None | Liveness probe |
| /readyz | GET | 8081/TCP | HTTP | None | None | Readiness probe |

### gRPC Services

None - operator uses HTTP/REST APIs only.

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| Kubernetes/OpenShift | 1.28+ | Yes | Platform runtime |
| controller-runtime | v0.17.5 | Yes | Operator framework |
| OpenShift Service Mesh Operator | Latest | Conditional | Required for KServe and SSO features |
| OpenShift Serverless Operator | Latest | Conditional | Required for KServe component |
| Authorino Operator | Latest | Conditional | Required for KServe authorization |
| OpenShift Pipelines Operator | Latest | Conditional | Required for DataSciencePipelines component |
| Prometheus Operator | v0.68.0 | No | Monitoring stack management |

### Internal ODH Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| odh-dashboard | Manifest Deployment | Web UI for data science platform |
| odh-notebook-controller | Manifest Deployment | Jupyter notebook lifecycle management |
| kserve | Manifest Deployment | Model serving with Knative and Istio |
| modelmesh-serving | Manifest Deployment | Traditional model serving runtime |
| data-science-pipelines-operator | Manifest Deployment | ML pipeline orchestration |
| codeflare-operator | Manifest Deployment | Distributed computing for AI workloads |
| kuberay-operator | Manifest Deployment | Ray cluster management |
| training-operator | Manifest Deployment | Distributed ML training jobs |
| kueue | Manifest Deployment | Job queueing and resource management |
| trustyai-operator | Manifest Deployment | Model explainability and fairness |

## Network Architecture

### Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| controller-manager-metrics-service | ClusterIP | 8443/TCP | 8080 | HTTP | None | ServiceAccount Token | Internal |
| prometheus | ClusterIP | 9091/TCP | 9091 | HTTPS | TLS (OpenShift service cert) | mTLS | Internal |
| alertmanager | ClusterIP | 9093/TCP | 9093 | HTTP | None | None | Internal |

### Ingress

| Name | Type | Hosts | Port | Protocol | Encryption | TLS Mode | Exposure |
|------|------|-------|------|----------|------------|----------|----------|
| prometheus-route | OpenShift Route | prometheus-{namespace}.apps.{cluster} | 443/TCP | HTTPS | TLS passthrough | SIMPLE | Internal (requires auth) |
| alertmanager-route | OpenShift Route | alertmanager-{namespace}.apps.{cluster} | 443/TCP | HTTPS | TLS edge | SIMPLE | Internal (requires auth) |

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| github.com | 443/TCP | HTTPS | TLS 1.2+ | None | Fetch component manifests from Git repos |
| quay.io | 443/TCP | HTTPS | TLS 1.2+ | None | Pull container images |
| registry.redhat.io | 443/TCP | HTTPS | TLS 1.2+ | Pull secret | Pull Red Hat container images |
| Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token | API operations |

## Security

### RBAC - Cluster Roles

| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|
| controller-manager-role | "" (core) | secrets, configmaps, serviceaccounts, namespaces, services, persistentvolumeclaims, pods, events | create, delete, get, list, patch, update, watch |
| controller-manager-role | apps | deployments, statefulsets, replicasets | create, delete, get, list, patch, update, watch |
| controller-manager-role | rbac.authorization.k8s.io | roles, rolebindings, clusterroles, clusterrolebindings | create, delete, get, list, patch, update, watch |
| controller-manager-role | route.openshift.io | routes | create, delete, get, list, patch, update, watch |
| controller-manager-role | apiextensions.k8s.io | customresourcedefinitions | create, delete, get, list, patch, watch |
| controller-manager-role | networking.k8s.io | networkpolicies, ingresses | create, delete, get, list, patch, update, watch |
| controller-manager-role | monitoring.coreos.com | servicemonitors, prometheusrules, podmonitors | create, delete, get, list, patch, update, watch |
| controller-manager-role | operators.coreos.com | subscriptions, clusterserviceversions | get, list, watch, delete |
| controller-manager-role | serving.kserve.io | inferenceservices, servingruntimes, clusterservingruntimes | create, delete, get, list, patch, update, watch |
| controller-manager-role | serving.knative.dev | services | create, delete, get, list, patch, update, watch |
| controller-manager-role | tekton.dev | * | * |
| controller-manager-role | authorino.kuadrant.io | authconfigs | * |
| controller-manager-role | batch | jobs, cronjobs | create, delete, get, list, patch, update, watch |
| controller-manager-role | autoscaling | horizontalpodautoscalers | create, delete, get, list, patch, update, watch |
| controller-manager-role | oauth.openshift.io | oauthclients | create, delete, get, list, patch, update, watch |
| controller-manager-role | console.openshift.io | consolelinks, odhquickstarts | create, delete, get, list, patch |
| controller-manager-role | config.openshift.io | clusterversions, authentications, ingresses | get, list, watch |
| controller-manager-role | datasciencecluster.opendatahub.io | datascienceclusters | create, delete, get, list, patch, update, watch |
| controller-manager-role | dscinitialization.opendatahub.io | dscinitializations | create, delete, get, list, patch, update, watch |
| controller-manager-role | features.opendatahub.io | featuretrackers | create, delete, get, list, patch, update, watch |

### RBAC - Role Bindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| controller-manager-rolebinding | Cluster-wide | controller-manager-role | controller-manager (in operator namespace) |

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| prometheus-tls | kubernetes.io/tls | TLS certificate for Prometheus service | OpenShift service-ca-operator | Yes |
| webhook-server-cert | kubernetes.io/tls | Webhook server TLS certificate | cert-manager or manual | No |
| {component}-oauth-client-secret | Opaque | OAuth client secrets for component authentication | SecretGenerator controller | No |

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| /metrics | GET | Bearer Token (ServiceAccount) | Kubernetes API proxy | ServiceAccount with read access to metrics |
| /healthz, /readyz | GET | None | Operator process | Public (cluster-internal only) |
| Kubernetes API | ALL | ServiceAccount Token | Kubernetes RBAC | ClusterRole: controller-manager-role |

## Data Flows

### Flow 1: Component Deployment via DataScienceCluster

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User/GitOps | Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | User credentials |
| 2 | DataScienceCluster Controller | Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 3 | DataScienceCluster Controller | GitHub (manifest repos) | 443/TCP | HTTPS | TLS 1.2+ | None (public repos) |
| 4 | DataScienceCluster Controller | Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |

### Flow 2: Monitoring Metrics Collection

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Prometheus | controller-manager-metrics-service | 8443/TCP | HTTP | None | ServiceAccount Token |
| 2 | Prometheus | Component metrics endpoints | varies | HTTP/HTTPS | varies | ServiceAccount Token |
| 3 | Alertmanager | Prometheus | 9091/TCP | HTTPS | TLS | mTLS |

### Flow 3: Platform Initialization via DSCInitialization

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User/Operator | Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | User/ServiceAccount credentials |
| 2 | DSCInitialization Controller | Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 3 | DSCInitialization Controller | Service Mesh Control Plane | varies | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 4 | DSCInitialization Controller | Monitoring namespace | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |

### Flow 4: OAuth Client Generation

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | SecretGenerator Controller | Route API | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 2 | SecretGenerator Controller | OAuth API | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 3 | SecretGenerator Controller | Secrets API | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| Kubernetes API Server | REST API | 6443/TCP | HTTPS | TLS 1.2+ | Primary control plane interface |
| OpenShift Service Mesh | CRD Management | 6443/TCP | HTTPS | TLS 1.2+ | Configure Istio for model serving and SSO |
| Prometheus Operator | CRD (ServiceMonitor) | 6443/TCP | HTTPS | TLS 1.2+ | Deploy monitoring configuration |
| Component Git Repositories | HTTPS | 443/TCP | HTTPS | TLS 1.2+ | Fetch deployment manifests |
| Component Operators | CRD Management | 6443/TCP | HTTPS | TLS 1.2+ | Deploy and configure component-specific CRs |

## Deployment Configuration

### Operator Pod Specification

| Parameter | Value | Purpose |
|-----------|-------|---------|
| Image | quay.io/opendatahub/opendatahub-operator | Operator container image |
| Replicas | 1 | Single instance (leader election enabled) |
| CPU Request | 100m | Minimum CPU allocation |
| CPU Limit | 500m | Maximum CPU allocation |
| Memory Request | 780Mi | Minimum memory allocation |
| Memory Limit | 4Gi | Maximum memory allocation |
| ServiceAccount | controller-manager | Operator service account |
| Security Context | runAsNonRoot: true, allowPrivilegeEscalation: false, drop ALL capabilities | Restricted pod security |

### Environment Variables

| Variable | Default Value | Purpose |
|----------|---------------|---------|
| OPERATOR_NAMESPACE | (from fieldRef) | Namespace where operator is deployed |
| DEFAULT_MANIFESTS_PATH | /opt/manifests | Path to embedded manifests |
| DISABLE_DSC_CONFIG | unset | Disable automatic DSCI creation if set |

### Command-Line Flags

| Flag | Default | Purpose |
|------|---------|---------|
| --leader-elect | false | Enable leader election (set to true in deployment) |
| --metrics-bind-address | :8080 | Metrics endpoint bind address |
| --health-probe-bind-address | :8081 | Health probe bind address |
| --dsc-applications-namespace | redhat-ods-applications | Default namespace for applications |
| --dsc-monitoring-namespace | redhat-ods-monitoring | Default namespace for monitoring |
| --operator-name | opendatahub | Operator identifier |
| --log-mode | "" | Logging mode (prod/devel) |

## Component Management

### Managed Components

| Component | Manifest Source | Default State | Prerequisites |
|-----------|----------------|---------------|---------------|
| Dashboard | opendatahub-io/odh-dashboard | Managed | None |
| Workbenches | opendatahub-io/notebooks | Managed | None |
| DataSciencePipelines | opendatahub-io/data-science-pipelines-operator | Removed | OpenShift Pipelines Operator |
| KServe | kserve/kserve | Removed | Service Mesh, Serverless, Authorino |
| ModelMeshServing | opendatahub-io/modelmesh-serving | Removed | Incompatible with KServe |
| CodeFlare | project-codeflare/codeflare-operator | Removed | None |
| Ray | ray-project/kuberay | Removed | None |
| Kueue | kubernetes-sigs/kueue | Removed | None |
| TrainingOperator | kubeflow/training-operator | Removed | None |
| TrustyAI | trustyai-explainability/trustyai-service-operator | Removed | None |

### Component DevFlags

Each component supports:
- **manifests**: Custom manifest URIs for testing/development
  - `uri`: Git repository tarball URL
  - `contextDir`: Relative path to manifests (default: "manifests")
  - `sourcePath`: Kustomize build path within contextDir

## Monitoring & Observability

### Metrics Exposed

| Metric Prefix | Type | Purpose |
|---------------|------|---------|
| controller_runtime_* | Various | Controller-runtime framework metrics |
| workqueue_* | Gauge/Counter | Reconciliation queue metrics |
| rest_client_* | Counter/Histogram | Kubernetes API client metrics |

### Logging

| Level | Flag Value | Output Format | Use Case |
|-------|------------|---------------|----------|
| Production | "" or "prod" | JSON, ERROR stacktrace, INFO verbosity | Default production logging |
| Development | "devel" or "development" | Console, WARN stacktrace, INFO verbosity | Development/debugging |

### Health Checks

| Endpoint | Type | Port | Success Criteria |
|----------|------|------|------------------|
| /healthz | Liveness | 8081/TCP | Returns 200 OK |
| /readyz | Readiness | 8081/TCP | Returns 200 OK, leader elected |

## Upgrade & Lifecycle Management

### Upgrade Process

1. Operator detects version change via `GetRelease()` function
2. Runs `CleanupExistingResource()` to remove deprecated resources
3. Updates DSCI status with new operator version
4. Reconciles all components with new manifests
5. Updates DSC status with component versions

### Finalizers

| Finalizer | Resource | Purpose |
|-----------|----------|---------|
| datasciencecluster.opendatahub.io/finalizer | DataScienceCluster | Clean up component resources on deletion |
| dscinitialization.opendatahub.io/finalizer | DSCInitialization | Clean up platform resources on deletion |

## Known Limitations

1. **Single Instance**: Only one DataScienceCluster CR supported per cluster
2. **Single DSCI**: Only one DSCInitialization CR supported per cluster
3. **Component Conflicts**: KServe and ModelMeshServing cannot be enabled simultaneously
4. **Namespace Constraints**: Application namespace defaults to `redhat-ods-applications`, not user-configurable
5. **Manifest Caching**: Manifests embedded in operator image, updates require operator rebuild

## Recent Changes

No recent commits available in the specified 3-month window (since 2025-12-15). Repository is on stable branch rhoai-2.13.

## Troubleshooting

### Common Issues

| Issue | Symptom | Resolution |
|-------|---------|------------|
| Component stuck in "Installing" | Component status shows Installing phase | Check component pod logs, verify prerequisites installed |
| DSCI not created | No DSCI instance exists | Check DISABLE_DSC_CONFIG env var, manually create DSCI |
| Manifest fetch failure | Component deployment fails | Check network policies, verify Git repository accessibility |
| OAuth client creation fails | Dashboard/component auth broken | Check Route exists, verify OAuth API access permissions |
| Service Mesh integration fails | KServe deployment fails | Verify Service Mesh Operator installed, check SMCP status |

### Debug Commands

```bash
# Check operator logs
oc logs -n redhat-ods-operator deployment/rhods-operator

# Check DSCI status
oc get dsci -o yaml

# Check DSC status
oc get dsc -o yaml

# List all managed components
oc get deployments -n redhat-ods-applications

# Check operator RBAC
oc describe clusterrole controller-manager-role

# View operator metrics
oc port-forward -n redhat-ods-operator svc/controller-manager-metrics-service 8443:8443
curl -k https://localhost:8443/metrics
```

## References

- [Component Integration Guide](components/README.md)
- [API Documentation](docs/api-overview.md)
- [Troubleshooting Guide](docs/troubleshooting.md)
- [Upgrade Testing](docs/upgrade-testing.md)
