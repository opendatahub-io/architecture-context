# Component: RHODS Operator (OpenDataHub Operator)

## Metadata
- **Repository**: https://github.com/red-hat-data-services/rhods-operator.git
- **Version**: v1.6.0-5550-g5dbe55bed
- **Branch**: rhoai-3.3
- **Distribution**: RHOAI (also supports ODH)
- **Languages**: Go
- **Deployment Type**: Kubernetes Operator (Kubebuilder v4, multi-group)

## Purpose
**Short**: Primary operator for Red Hat OpenShift AI (RHOAI) that manages and deploys data science platform components and infrastructure.

**Detailed**: The RHODS Operator (also known as OpenDataHub Operator) is the central control plane for RHOAI and Open Data Hub platforms. It orchestrates the lifecycle of data science components including workbenches, model serving (KServe), pipelines, Ray clusters, model registries, and monitoring infrastructure. The operator uses a declarative approach through two main CRDs: `DSCInitialization` (for platform-wide configuration) and `DataScienceCluster` (for component deployment). It manages component-specific operators, configures service mesh integration, sets up monitoring and auth infrastructure, and handles upgrades across the entire platform. The operator runs with 3 replicas for high availability and uses leader election to ensure single active controller.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| Operator Manager | Deployment (3 replicas) | Main controller managing DSC/DSCI reconciliation |
| DSCInitialization Controller | Controller | Manages platform initialization, monitoring, auth, service mesh |
| DataScienceCluster Controller | Controller | Manages component lifecycle (dashboard, kserve, workbenches, etc.) |
| Component Controllers | Controllers | Per-component reconcilers (15+ components) |
| Service Controllers | Controllers | Infrastructure service reconcilers (auth, monitoring, gateway) |
| Webhook Server | Admission Controller | Validates and defaults DSC/DSCI resources |
| Metrics Service | HTTP Service | Prometheus metrics with auth proxy |
| Health Probes | HTTP Endpoints | Liveness and readiness checks |

## APIs Exposed

### Custom Resource Definitions (CRDs)

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| datasciencecluster.opendatahub.io | v1, v2 | DataScienceCluster | Cluster | Declares desired state of data science components |
| dscinitialization.opendatahub.io | v1, v2 | DSCInitialization | Cluster | Initializes platform infrastructure (monitoring, auth, networking) |
| components.platform.opendatahub.io | v1alpha1 | Dashboard | Cluster | ODH/RHOAI dashboard component |
| components.platform.opendatahub.io | v1alpha1 | Workbenches | Cluster | Jupyter notebook server management |
| components.platform.opendatahub.io | v1alpha1 | DataSciencePipelines | Cluster | Kubeflow Pipelines integration |
| components.platform.opendatahub.io | v1alpha1 | Kserve | Cluster | Model serving platform (KServe) |
| components.platform.opendatahub.io | v1alpha1 | Kueue | Cluster | Job queueing system |
| components.platform.opendatahub.io | v1alpha1 | Ray | Cluster | Ray cluster operator |
| components.platform.opendatahub.io | v1alpha1 | TrustyAI | Cluster | AI explainability and fairness |
| components.platform.opendatahub.io | v1alpha1 | ModelRegistry | Cluster | Model metadata registry |
| components.platform.opendatahub.io | v1alpha1 | TrainingOperator | Cluster | Distributed training (Kubeflow Training) |
| components.platform.opendatahub.io | v1alpha1 | FeastOperator | Cluster | Feature store (Feast) |
| components.platform.opendatahub.io | v1alpha1 | LlamaStackOperator | Cluster | LlamaStack deployment |
| components.platform.opendatahub.io | v1alpha1 | MLflowOperator | Cluster | MLflow tracking server |
| components.platform.opendatahub.io | v1alpha1 | Trainer | Cluster | Training runtime management |
| components.platform.opendatahub.io | v1alpha1 | ModelsAsService | Cluster | Managed model serving API |
| services.platform.opendatahub.io | v1alpha1 | Monitoring | Cluster | Platform monitoring configuration |
| services.platform.opendatahub.io | v1alpha1 | Auth | Cluster | Authentication/authorization service |
| services.platform.opendatahub.io | v1alpha1 | GatewayConfig | Cluster | API gateway configuration |
| infrastructure.opendatahub.io | v1, v1alpha1 | HardwareProfile | Namespaced | Hardware acceleration profiles (GPU, etc.) |

### HTTP Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /metrics | GET | 8080/TCP | HTTP | None | None | Prometheus metrics (internal) |
| /healthz | GET | 8081/TCP | HTTP | None | None | Liveness probe |
| /readyz | GET | 8081/TCP | HTTP | None | None | Readiness probe |
| /validate-* | POST | 9443/TCP | HTTPS | TLS 1.2+ | mTLS | Webhook validation endpoints |
| /mutate-* | POST | 9443/TCP | HTTPS | TLS 1.2+ | mTLS | Webhook defaulting endpoints |

### Webhook Services

| Webhook | Type | Port | Protocol | Encryption | Purpose |
|---------|------|------|----------|------------|---------|
| DataScienceCluster Validator | ValidatingWebhook | 9443/TCP | HTTPS | TLS (cert-manager) | Validates DSC spec |
| DataScienceCluster Defaulter | MutatingWebhook | 9443/TCP | HTTPS | TLS (cert-manager) | Sets DSC defaults |
| DSCInitialization Validator | ValidatingWebhook | 9443/TCP | HTTPS | TLS (cert-manager) | Validates DSCI spec |
| Auth Validator | ValidatingWebhook | 9443/TCP | HTTPS | TLS (cert-manager) | Validates Auth service config |
| Monitoring Validator | ValidatingWebhook | 9443/TCP | HTTPS | TLS (cert-manager) | Validates monitoring config |

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| Kubernetes | 1.24+ | Yes | Orchestration platform |
| OpenShift | 4.12+ | Yes (RHOAI) | Enterprise Kubernetes distribution |
| Cert Manager / OpenShift Service CA | Any | Yes | TLS certificate provisioning for webhooks |
| Prometheus Operator | v0.68+ | Optional | Monitoring infrastructure |
| Istio / OpenShift Service Mesh | 2.4+ | Optional | Service mesh for model serving |
| OpenShift Serverless | 1.30+ | Optional | Knative for KServe serverless mode |
| RHOBS Monitoring Stack | Any | Optional (RHOAI) | Observability platform |

### Internal ODH/RHOAI Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| ODH Dashboard | Deploys | Web UI for data science workflows |
| KServe Operator | Deploys/Manages | Model serving infrastructure |
| Kubeflow Pipelines | Deploys | ML pipeline orchestration |
| Model Registry Operator | Deploys | Model versioning and metadata |
| Notebook Controller | Deploys | Jupyter notebook lifecycle |
| Ray Operator | Deploys | Distributed computing |
| Training Operator | Deploys | Distributed training jobs |
| Monitoring Stack | Configures | Prometheus, AlertManager, Grafana |

## Network Architecture

### Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| webhook-service | ClusterIP | 443/TCP | 9443 | HTTPS | TLS 1.2+ (OpenShift Service CA) | mTLS (K8s API server) | Internal |
| controller-manager-metrics-service | ClusterIP | 8443/TCP | 8080 | HTTP | None (behind auth proxy) | Token (kube-rbac-proxy) | Internal |

### Ingress

| Name | Type | Hosts | Port | Protocol | Encryption | TLS Mode | Exposure |
|------|------|-------|------|----------|------------|----------|----------|
| N/A | N/A | N/A | N/A | N/A | N/A | N/A | Operator does not expose external ingress |

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount token | CRD management, resource reconciliation |
| Component Git Repos | 443/TCP | HTTPS | TLS 1.2+ | None | Fetch component manifests (if configured) |
| Container Registries | 443/TCP | HTTPS | TLS 1.2+ | Pull secrets | Pull component images |
| OpenShift OAuth Server | 6443/TCP | HTTPS | TLS 1.2+ | OAuth token | User authentication (RHOAI) |

### Network Policies

| Policy Name | Namespace | Ingress Rules | Egress Rules |
|-------------|-----------|---------------|--------------|
| redhat-ods-applications | redhat-ods-applications | Allow 8443, 8080, 8081, 5432, 8082, 8099, 8181, 9443/TCP from any | Not defined (default allow) |

## Security

### RBAC - Cluster Roles

| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|
| opendatahub-operator-manager | datasciencecluster.opendatahub.io | datascienceclusters, datascienceclusters/status, datascienceclusters/finalizers | get, list, watch, create, update, patch, delete |
| opendatahub-operator-manager | dscinitialization.opendatahub.io | dscinitializations, dscinitializations/status, dscinitializations/finalizers | get, list, watch, create, update, patch, delete |
| opendatahub-operator-manager | components.platform.opendatahub.io | dashboards, workbenches, datasciencepipelines, kserves, kueues, rays, trustyais, modelregistries, trainingoperators, etc. | get, list, watch, create, update, patch, delete |
| opendatahub-operator-manager | services.platform.opendatahub.io | monitorings, auths, gatewayconfigs | get, list, watch, create, update, patch, delete |
| opendatahub-operator-manager | infrastructure.opendatahub.io | hardwareprofiles | get, list, watch, create, update, patch, delete |
| opendatahub-operator-manager | "", apps | deployments, services, configmaps, secrets, serviceaccounts, pods, persistentvolumeclaims | get, list, watch, create, update, patch, delete |
| opendatahub-operator-manager | rbac.authorization.k8s.io | roles, rolebindings, clusterroles, clusterrolebindings | * (all verbs) |
| opendatahub-operator-manager | route.openshift.io | routes | get, list, watch, create, update, patch, delete |
| opendatahub-operator-manager | networking.k8s.io | networkpolicies, ingresses | get, list, watch, create, update, patch, delete |
| opendatahub-operator-manager | monitoring.coreos.com | servicemonitors, prometheusrules, prometheuses, alertmanagers | get, list, watch, create, update, patch, delete |
| opendatahub-operator-manager | operators.coreos.com | subscriptions, clusterserviceversions, catalogsources | get, list, watch, delete, update |
| opendatahub-operator-manager | serving.kserve.io | inferenceservices, servingruntimes, clusterservingruntimes | get, list, watch, create, update, patch, delete |
| opendatahub-operator-manager | ray.io | rayclusters, rayservices, rayjobs | get, list, watch, create, update, patch, delete |
| opendatahub-operator-manager | argoproj.io | workflows | get, list, watch, create, update, patch, delete |
| opendatahub-operator-manager | user.openshift.io | users, groups | get, list, watch, patch, delete, update |
| opendatahub-operator-manager | console.openshift.io | consolelinks | get, list, watch, create, update, patch, delete |
| opendatahub-operator-manager | oauth.openshift.io | oauthclients | get, list, watch, create, update, patch, delete |
| opendatahub-operator-manager | security.openshift.io | securitycontextconstraints | get, list, watch, create, patch, use |
| opendatahub-operator-manager | admissionregistration.k8s.io | validatingwebhookconfigurations, mutatingwebhookconfigurations | get, list, watch, create, update, patch, delete |
| opendatahub-operator-manager | apiextensions.k8s.io | customresourcedefinitions | get, list, watch, create, update, patch, delete |

**Note**: The operator requires extensive cluster-admin level permissions to manage all data science components, operators, networking, and RBAC across the cluster.

### RBAC - Role Bindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| opendatahub-operator-manager | operator namespace | ClusterRole: opendatahub-operator-manager | controller-manager |

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| opendatahub-operator-controller-webhook-cert | kubernetes.io/tls | Webhook server TLS certificate | OpenShift Service CA | Yes (annotation-driven) |

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| /metrics | GET | Token-based (kube-rbac-proxy) | Auth proxy sidecar | Requires valid ServiceAccount token with permissions |
| /healthz, /readyz | GET | None | N/A | Unauthenticated (kubelet probes) |
| Webhook endpoints | POST | mTLS | Kubernetes API server | API server validates webhook server cert |
| CRD Watch/Create/Update | ALL | ServiceAccount token | Kubernetes RBAC | ClusterRole permissions enforced |

### Pod Security

| Setting | Value | Purpose |
|---------|-------|---------|
| runAsNonRoot | true | Prevent root privilege escalation |
| allowPrivilegeEscalation | false | Block privilege escalation |
| seccompProfile | RuntimeDefault | Restrict syscall access |
| capabilities.drop | ALL | Drop all Linux capabilities |
| Service Account | controller-manager | Dedicated identity with ClusterRole |

## Data Flows

### Flow 1: User Creates DataScienceCluster

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User (kubectl/oc) | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | User credentials |
| 2 | Kubernetes API | Webhook Service | 443/TCP -> 9443/TCP | HTTPS | TLS 1.2+ | mTLS (API server cert) |
| 3 | Webhook Service | Return validation/mutation | N/A | N/A | N/A | N/A |
| 4 | Kubernetes API | Operator watch cache | N/A | N/A | N/A | N/A |
| 5 | Operator controller | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount token |
| 6 | Operator controller | Component deployments | N/A | N/A | N/A | Creates resources |

### Flow 2: Operator Reconciles Components

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Operator controller | Kubernetes API (read DSC) | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount token |
| 2 | Operator controller | Kubernetes API (create/update resources) | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount token |
| 3 | Operator controller | Kubernetes API (deploy component operators) | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount token |
| 4 | Operator controller | Kubernetes API (update DSC status) | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount token |

### Flow 3: Monitoring Scrapes Metrics

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Prometheus | Metrics Service | 8443/TCP | HTTP | None | Bearer token (ServiceAccount) |
| 2 | Auth Proxy | Validate token | 6443/TCP | HTTPS | TLS 1.2+ | TokenReview API |
| 3 | Auth Proxy | Operator metrics endpoint | 8080/TCP | HTTP | None | Internal |
| 4 | Operator | Return metrics | N/A | N/A | N/A | N/A |

### Flow 4: Component Manifest Fetching

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Operator init | Git repository | 443/TCP | HTTPS | TLS 1.2+ | None (public repos) |
| 2 | Operator | Load manifests to /opt/manifests | N/A | N/A | N/A | N/A |
| 3 | Component reconciler | Read manifest from disk | N/A | N/A | N/A | N/A |
| 4 | Component reconciler | Kubernetes API (apply manifests) | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount token |

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| Kubernetes API Server | REST API | 6443/TCP | HTTPS | TLS 1.2+ | Resource management, CRD operations |
| Component Operators (KServe, ModelRegistry, etc.) | CRD Creation | 6443/TCP | HTTPS | TLS 1.2+ | Deploy and manage sub-operators |
| OpenShift OAuth | OAuth API | 6443/TCP | HTTPS | TLS 1.2+ | User authentication in RHOAI |
| Prometheus Operator | CRD (ServiceMonitor, PrometheusRule) | 6443/TCP | HTTPS | TLS 1.2+ | Configure monitoring |
| OLM (Operator Lifecycle Manager) | CRD (Subscription, CSV) | 6443/TCP | HTTPS | TLS 1.2+ | Manage component operator subscriptions |
| Istio / Service Mesh | CRD Creation | 6443/TCP | HTTPS | TLS 1.2+ | Configure service mesh for model serving |
| OpenShift Router | Route API | 6443/TCP | HTTPS | TLS 1.2+ | Expose component services externally |
| Knative Serving | CRD Creation | 6443/TCP | HTTPS | TLS 1.2+ | Serverless model serving (KServe) |

## Component Deployment Details

### Operator Deployment Configuration

| Setting | Value | Purpose |
|---------|-------|---------|
| Replicas | 3 | High availability |
| Leader Election | Enabled | Single active controller |
| Leader Election ID | 07ed84f7.opendatahub.io | Lease identifier |
| Pod Anti-Affinity | Preferred | Spread across nodes |
| Node Selector | linux | Linux nodes only |
| Resource Requests | CPU: 100m, Memory: 780Mi | Minimum resources |
| Resource Limits | CPU: 1000m, Memory: 4Gi | Maximum resources |
| Image Pull Policy | Always | Always pull latest image |
| Termination Grace Period | 10s | Graceful shutdown time |

### Environment Variables

| Variable | Default | Purpose |
|----------|---------|---------|
| OPERATOR_NAMESPACE | (from fieldRef) | Namespace where operator is deployed |
| DEFAULT_MANIFESTS_PATH | /opt/manifests | Path to component manifests |
| ODH_PLATFORM_TYPE | OpenDataHub | Platform type (OpenDataHub or ManagedRhoai) |
| DISABLE_DSC_CONFIG | true | Disable auto-creation of DSCI in some configs |

### Managed Namespaces

| Namespace | Purpose |
|-----------|---------|
| redhat-ods-operator | Operator deployment namespace |
| redhat-ods-applications | Application components (dashboard, notebooks, etc.) |
| redhat-ods-monitoring | Monitoring stack (Prometheus, AlertManager, Grafana) |
| istio-system | Service mesh control plane (if enabled) |
| knative-serving | Serverless infrastructure (if enabled) |

## Recent Changes

| Commit | Date | Changes |
|--------|------|---------|
| 5dbe55bed | 2026-03 | Updating operator repo with latest images and manifests |
| cefa2cef6 | 2026-03 | Merge PR #20293: update odh-cli-v3-3 component |
| 210caecd7 | 2026-03 | chore(deps): update odh-cli-v3-3 to 1ff8f93 |
| 7f6d07146 | 2026-03 | Updating operator repo with latest images and manifests |
| eab4c88ec | 2026-03 | Merge PR #20232: update odh-training-operator-v3-3 |
| 9df70c604 | 2026-03 | chore(deps): update odh-training-operator-v3-3 to 56307fc |
| 7f373f3b6 | 2026-03 | Merge PR #20225: update odh-model-registry-v3-3 |
| a95654638 | 2026-03 | chore(deps): update odh-model-registry-v3-3 to 2eda6a2 |
| 779d8d771 | 2026-03 | Merge PR #20223: update odh-model-registry-operator-v3-3 |
| 28a3c1a46 | 2026-03 | chore(deps): update odh-model-registry-operator-v3-3 to 8beaddb |
| 04d3694ca | 2026-03 | Merge PR #20218: update odh-maas-api-v3-3 |
| 8928b7abf | 2026-03 | chore(deps): update odh-maas-api-v3-3 to 38cd39a |
| fa76743fb | 2026-03 | chore(deps): update UBI9 go-toolset to 1.25 |
| eb68ed815 | 2026-03 | Updating operator repo with latest images and manifests |
| 87d4982b1 | 2026-03 | Merge PR #20200: update odh-notebook-controller-v3-3 |
| 675cdf742 | 2026-03 | chore(deps): update odh-notebook-controller-v3-3 to 32604a1 |
| 2e319f260 | 2026-03 | chore(deps): update odh-kf-notebook-controller-v3-3 to aa7a73b |
| 9e450961f | 2026-03 | Merge PR #20196: update odh-kf-notebook-controller-v3-3 |
| 540f7de35 | 2026-03 | Merge PR #20194: update odh-kuberay-operator-controller-v3-3 |
| 71787ce88 | 2026-03 | chore(deps): update odh-kuberay-operator-controller-v3-3 to 37b8a54 |

**Pattern**: Recent commits show active development focused on keeping component images and manifests up-to-date. The operator uses Konflux for automated dependency updates and component version bumping. Most changes are automated version updates for sub-components (model registry, training operator, notebook controllers, Ray, etc.).

## Build and Deployment

### Container Build

| Setting | Value |
|---------|-------|
| Primary Dockerfile | Dockerfiles/Dockerfile.konflux |
| Build System | Konflux (RHOAI CI/CD) |
| Base Image | UBI9 go-toolset:1.25 |
| Multi-stage Build | Yes |

### Deployment Method

| Method | Description |
|--------|-------------|
| Kustomize | Primary deployment via config/ directory |
| OLM Bundle | Operator Lifecycle Manager bundle for OpenShift |
| Manifest Location | config/ directory (manager, rbac, webhook, crd, monitoring) |
| Prefetched Manifests | Component manifests stored in prefetched-manifests/ for offline deployment |

### Component Manifest Sources

The operator manages component manifests in two ways:

1. **Prefetched Manifests**: Stored in `prefetched-manifests/` directory, versioned with the operator
2. **Dynamic Fetching**: Can fetch manifests from Git repositories at runtime (controlled by env vars)
3. **Default Path**: `/opt/manifests` inside container

Components managed include: Dashboard, Workbenches, DataSciencePipelines, KServe, Kueue, ModelRegistry, Ray, TrustyAI, TrainingOperator, and more.

## Observability

### Metrics Exposed

| Metric Type | Description |
|-------------|-------------|
| controller_runtime_* | Controller reconciliation metrics (rate, errors, duration) |
| workqueue_* | Work queue depth and processing metrics |
| process_* | Process CPU, memory, file descriptor usage |
| go_* | Go runtime metrics (goroutines, memory, GC) |

### Health Checks

| Endpoint | Type | Port | Interval |
|----------|------|------|----------|
| /healthz | Liveness | 8081/TCP | Every 20s (initial delay 15s) |
| /readyz | Readiness | 8081/TCP | Every 10s (initial delay 5s) |

### Logging

| Setting | Default | Purpose |
|---------|---------|---------|
| Log Format | JSON or console | Configurable via --zap-encoder |
| Log Level | info | Configurable via --zap-log-level or runtime update |
| Development Mode | false | Configurable via --zap-devel |
| Stacktrace Level | error | Configurable via --zap-stacktrace-level |

## Upgrade and Migration

### Version Support

| Feature | Description |
|---------|-------------|
| API Versions | Supports v1 and v2 for DSC/DSCI (storage version: v2) |
| Conversion Webhooks | Yes (v1 ↔ v2 conversion) |
| Upgrade Path | Automated via operator upgrade |
| Cleanup Tasks | Runs cleanup runnable on operator start |

### Upgrade Process

1. Operator detects version change
2. Runs cleanup for deprecated resources from previous versions
3. Migrates CRD versions via conversion webhooks
4. Updates component manifests to new versions
5. Reconciles all components to desired state

## Troubleshooting

### Common Issues

| Issue | Symptom | Resolution |
|-------|---------|------------|
| Webhook unavailable | DSC/DSCI creation fails with timeout | Check webhook service and certificate |
| Component not deploying | Phase stuck in "Pending" | Check operator logs, RBAC permissions |
| Resource conflicts | "AlreadyExists" errors | Check for manual resources with same names |
| OOM crashes | Operator pod restarting | Increase memory limits (default 4Gi) |

### Debug Commands

```bash
# Check operator logs
oc logs -n redhat-ods-operator deployment/rhods-operator-controller-manager

# Check DSC status
oc get datasciencecluster -o yaml

# Check DSCI status
oc get dscinitialization -o yaml

# Check webhook configuration
oc get validatingwebhookconfigurations | grep opendatahub
oc get mutatingwebhookconfigurations | grep opendatahub

# Check operator metrics
oc port-forward -n redhat-ods-operator svc/controller-manager-metrics-service 8443:8443
curl -k https://localhost:8443/metrics
```

### Log Levels

Operator supports dynamic log level changes via patch:

```bash
# Set debug level at runtime
oc patch configmap/odh-operator-config -n redhat-ods-operator \
  --type=merge -p '{"data":{"LOG_LEVEL":"debug"}}'
```

## Security Considerations

### Cluster Admin Privileges

⚠️ **Critical**: This operator requires extensive cluster-admin level permissions including:
- Full RBAC management (ClusterRole, ClusterRoleBinding)
- CRD lifecycle management
- Security Context Constraints (SCC) modification
- Cross-namespace resource management
- Operator installation/updates via OLM

**Justification**: The operator manages platform-wide data science infrastructure requiring privileged operations across multiple namespaces and resource types.

### Sensitive Data Handling

| Data Type | Storage | Protection |
|-----------|---------|------------|
| Webhook TLS certs | Secret (opendatahub-operator-controller-webhook-cert) | Auto-rotated by Service CA |
| Component credentials | Secrets in application namespaces | Managed by component operators |
| User auth tokens | Not stored | Validated via TokenReview API |

### Network Security

- **Default Deny**: Network policies enforce ingress restrictions
- **TLS Everywhere**: All webhook traffic uses TLS
- **Service Mesh Ready**: Supports Istio integration for mTLS between components
- **Internal Only**: Operator itself has no external exposure

## Operational Notes

### Leader Election

The operator uses Kubernetes leader election with:
- Lease-based election
- Lease duration: default (15s)
- Renew deadline: default (10s)
- Retry period: default (2s)

Only the leader performs reconciliation; followers remain ready as standby.

### Resource Caching

The operator caches specific resources to reduce API server load:
- Secrets: operator, monitoring, application namespaces
- ConfigMaps: component configurations
- Deployments: monitoring and owned deployments
- Limited cache for large resources (Pods not cached)

### Finalizers

The operator adds finalizers to:
- DataScienceCluster: Ensures component cleanup before deletion
- DSCInitialization: Ensures monitoring/auth cleanup
- Component CRs: Ensures sub-resources are cleaned up

### Rate Limiting

Default controller-runtime rate limits apply:
- QPS: 50
- Burst: 100

Can be tuned via controller-runtime flags if needed.
