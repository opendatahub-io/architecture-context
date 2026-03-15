# Component: RHOAI Operator (rhods-operator)

## Metadata
- **Repository**: https://github.com/red-hat-data-services/rhods-operator.git
- **Version**: v1.6.0-5936-g181aacbe8
- **Branch**: rhoai-3.2
- **Distribution**: RHOAI (also supports ODH)
- **Languages**: Go 1.25
- **Deployment Type**: Kubernetes Operator

## Purpose
**Short**: Platform operator that manages the lifecycle of Red Hat OpenShift AI (RHOAI) data science components and infrastructure.

**Detailed**: The RHOAI Operator (also known as opendatahub-operator) is the primary control plane operator for Red Hat OpenShift AI. It orchestrates the deployment, configuration, and lifecycle management of data science platform components including dashboards, model serving (KServe), pipelines, workbenches, model registries, and AI/ML operators. The operator uses a declarative approach through two main CRDs: DataScienceCluster (DSC) for component configuration and DSCInitialization (DSCI) for platform initialization including service mesh, monitoring, and trusted CA bundle setup. It reconciles these resources to deploy and manage sub-operators and components, each with dedicated controllers that handle kustomize-based manifest deployment. The operator supports both self-managed (ODH) and managed cloud (RHOAI) deployment models with platform-specific configurations.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| DataScienceCluster Controller | Reconciler | Manages lifecycle of data science components based on DSC CRD |
| DSCInitialization Controller | Reconciler | Initializes platform infrastructure (monitoring, service mesh, trusted CA) |
| Component Controllers | Reconcilers | Individual controllers for each component (dashboard, kserve, workbenches, etc.) |
| Service Controllers | Reconcilers | Manage cross-cutting services (auth, monitoring, gateway, cert-manager) |
| Webhook Server | Admission Controller | Validates and mutates DSC and DSCI resources |
| Manifest Deployer | Deployment Engine | Applies kustomize manifests from /opt/manifests to cluster |
| Monitoring Stack | Observability | Prometheus, Alertmanager, ServiceMonitors, and custom metrics |

## APIs Exposed

### Custom Resource Definitions (CRDs)

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| datasciencecluster.opendatahub.io | v1, v2 | DataScienceCluster | Cluster | Declares desired state of data science platform components |
| dscinitialization.opendatahub.io | v1, v2 | DSCInitialization | Cluster | Initializes platform infrastructure and shared services |
| components.opendatahub.io | v1alpha1 | Dashboard | Namespaced | Configures ODH Dashboard component |
| components.opendatahub.io | v1alpha1 | DataSciencePipelines | Namespaced | Configures Kubeflow/Tekton pipelines component |
| components.opendatahub.io | v1alpha1 | Kserve | Namespaced | Configures KServe model serving component |
| components.opendatahub.io | v1alpha1 | Kueue | Namespaced | Configures Kueue job queuing component |
| components.opendatahub.io | v1alpha1 | Ray | Namespaced | Configures Ray distributed computing component |
| components.opendatahub.io | v1alpha1 | TrustyAI | Namespaced | Configures TrustyAI explainability component |
| components.opendatahub.io | v1alpha1 | ModelRegistry | Namespaced | Configures model registry component |
| components.opendatahub.io | v1alpha1 | TrainingOperator | Namespaced | Configures Kubeflow Training Operator component |
| components.opendatahub.io | v1alpha1 | Workbenches | Namespaced | Configures Jupyter notebook workbenches component |
| components.opendatahub.io | v1alpha1 | FeastOperator | Namespaced | Configures Feast feature store component |
| components.opendatahub.io | v1alpha1 | MLflowOperator | Namespaced | Configures MLflow experiment tracking component |
| components.opendatahub.io | v1alpha1 | LlamaStackOperator | Namespaced | Configures Llama Stack LLM component |
| services.opendatahub.io | v1alpha1 | Auth | Namespaced | Configures authentication service |
| services.opendatahub.io | v1alpha1 | Monitoring | Namespaced | Configures monitoring service |
| services.opendatahub.io | v1alpha1 | Gateway | Namespaced | Configures API gateway service |
| infrastructure.opendatahub.io | v1, v1alpha1 | HardwareProfile | Cluster | Defines hardware profiles for workloads |

### HTTP Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /healthz | GET | 8081/TCP | HTTP | None | None | Liveness probe for operator |
| /readyz | GET | 8081/TCP | HTTP | None | None | Readiness probe for operator |
| /metrics | GET | 8080/TCP | HTTP | None | Bearer Token | Prometheus metrics endpoint |
| /validate-* | POST | 9443/TCP | HTTPS | TLS 1.2+ | mTLS | Webhook validation endpoints |
| /mutate-* | POST | 9443/TCP | HTTPS | TLS 1.2+ | mTLS | Webhook mutation endpoints |

### Webhook Services

| Service | Port | Protocol | Encryption | Auth | Purpose |
|---------|------|----------|------------|------|---------|
| webhook-service | 443/TCP | HTTPS | TLS (service-ca) | mTLS | Validating/Mutating webhook for CRDs |

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| Kubernetes/OpenShift | 1.28+ / 4.14+ | Yes | Container orchestration platform |
| cert-manager | 1.x | No | Certificate management (optional, uses service-ca by default) |
| OpenShift Service Mesh | 2.x | No | Service mesh for model serving (optional) |
| OpenShift Serverless | 1.x | No | Knative serving for KServe (optional) |
| Prometheus Operator | 0.68.0 | No | Monitoring infrastructure (bundled in config) |

### Internal ODH Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| ODH Dashboard | CRD/Deploy | Deploys dashboard component via manifests |
| KServe | CRD/Deploy | Deploys model serving infrastructure |
| Data Science Pipelines | CRD/Deploy | Deploys pipeline orchestration |
| Model Registry | CRD/API | Manages model registry deployment and access |
| Notebook Controller | Deploy | Deploys workbench/notebook infrastructure |
| ODH Model Controller | Deploy | Manages model deployment automation |

## Network Architecture

### Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| controller-manager-metrics-service | ClusterIP | 8443/TCP | 8443 | HTTPS | TLS (kube-rbac-proxy) | Bearer Token | Internal |
| webhook-service | ClusterIP | 443/TCP | 9443 | HTTPS | TLS 1.2+ (service-ca) | mTLS | Internal |
| prometheus | ClusterIP | 9091/TCP | 9091 | HTTP | None | Internal | Internal |
| alertmanager | ClusterIP | 9093/TCP | 9093 | HTTP | None | Internal | Internal |
| blackbox-exporter | ClusterIP | 9115/TCP | 9115 | HTTP | None | Internal | Internal |

### Ingress

| Name | Type | Hosts | Port | Protocol | Encryption | TLS Mode | Exposure |
|------|------|-------|------|----------|------------|----------|----------|
| prometheus-route | OpenShift Route | prometheus-{namespace}.apps.{cluster} | 9091/TCP | HTTPS | TLS 1.2+ | Edge | External |
| alertmanager-route | OpenShift Route | alertmanager-{namespace}.apps.{cluster} | 9093/TCP | HTTPS | TLS 1.2+ | Edge | External |

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token | Cluster resource management |
| OLM Operators | 443/TCP | HTTPS | TLS 1.2+ | None | Subscription and CSV management |
| Image Registries | 443/TCP | HTTPS | TLS 1.2+ | Pull Secrets | Container image pulls |
| Component Webhooks | 443/TCP | HTTPS | TLS 1.2+ | mTLS | Component webhook validation |

## Security

### RBAC - Cluster Roles

| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|
| opendatahub-operator-manager-role | datasciencecluster.opendatahub.io | datascienceclusters, datascienceclusters/status, datascienceclusters/finalizers | get, list, watch, create, update, patch, delete |
| opendatahub-operator-manager-role | dscinitialization.opendatahub.io | dscinitializations, dscinitializations/status, dscinitializations/finalizers | get, list, watch, create, update, patch, delete |
| opendatahub-operator-manager-role | components.opendatahub.io | dashboards, datasciencepipelines, kserve, kueue, ray, trustyai, modelregistry, etc. | get, list, watch, create, update, patch, delete |
| opendatahub-operator-manager-role | services.opendatahub.io | auths, monitorings, gateways | get, list, watch, create, update, patch, delete |
| opendatahub-operator-manager-role | "" (core) | pods, services, serviceaccounts, secrets, configmaps, persistentvolumeclaims | get, list, watch, create, update, patch, delete |
| opendatahub-operator-manager-role | apps | deployments, replicasets, statefulsets | get, list, watch, create, update, patch, delete |
| opendatahub-operator-manager-role | rbac.authorization.k8s.io | roles, rolebindings, clusterroles, clusterrolebindings | * (all verbs) |
| opendatahub-operator-manager-role | route.openshift.io | routes | get, list, watch, create, update, patch, delete |
| opendatahub-operator-manager-role | networking.k8s.io | networkpolicies, ingresses | get, list, watch, create, update, patch, delete |
| opendatahub-operator-manager-role | monitoring.coreos.com | servicemonitors, podmonitors, prometheusrules, prometheuses, alertmanagers | get, list, watch, create, update, patch, delete |
| opendatahub-operator-manager-role | apiextensions.k8s.io | customresourcedefinitions | get, list, watch, create, update, patch, delete |
| opendatahub-operator-manager-role | operators.coreos.com | subscriptions, clusterserviceversions, catalogsources | get, list, watch, delete, update |
| opendatahub-operator-manager-role | security.openshift.io | securitycontextconstraints | * (all verbs, specific: anyuid, restricted) |
| opendatahub-operator-manager-role | oauth.openshift.io | oauthclients | get, list, watch, create, update, patch, delete |
| opendatahub-operator-manager-role | operator.openshift.io | consoles, ingresscontrollers | get, list, watch, patch, delete |
| opendatahub-operator-manager-role | config.openshift.io | clusterversions, proxies | get, list, watch |
| opendatahub-operator-manager-role | authentication.k8s.io | tokenreviews | create, get |
| opendatahub-operator-manager-role | authorization.k8s.io | subjectaccessreviews | create, get |

### RBAC - Role Bindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| opendatahub-operator-manager-rolebinding | redhat-ods-operator | opendatahub-operator-manager-role | controller-manager |
| prometheus-rolebinding-scraper | redhat-ods-monitoring | cluster-monitoring-view | prometheus |
| prometheus-rolebinding-viewer | redhat-ods-monitoring | view | prometheus |

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| opendatahub-operator-controller-webhook-cert | kubernetes.io/tls | Webhook server TLS certificate | service-ca-operator | Yes |
| prometheus-proxy-tls | kubernetes.io/tls | Prometheus metrics proxy TLS | service-ca-operator | Yes |
| alertmanager-proxy-tls | kubernetes.io/tls | Alertmanager proxy TLS | service-ca-operator | Yes |

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| /metrics | GET | Bearer Token (ServiceAccount) | kube-rbac-proxy | cluster-monitoring or namespace admin |
| /validate-* | POST | mTLS (Kubernetes API Server) | Webhook Server | Kubernetes API Server validates caller |
| /mutate-* | POST | mTLS (Kubernetes API Server) | Webhook Server | Kubernetes API Server validates caller |
| Prometheus UI | GET | OpenShift OAuth Proxy | Route | cluster-admin or monitoring-edit |
| Alertmanager UI | GET | OpenShift OAuth Proxy | Route | cluster-admin or monitoring-edit |

### Network Policies

| Policy Name | Namespace | Selectors | Ingress Rules | Purpose |
|-------------|-----------|-----------|---------------|---------|
| redhat-ods-operator | redhat-ods-operator | control-plane=controller-manager | Allow from: redhat-ods-monitoring, openshift-monitoring, openshift-user-workload-monitoring, openshift-console, openshift-operators, ODH namespaces, host-network | Restrict operator pod ingress |
| monitoring-namespace | redhat-ods-monitoring | All pods | Allow from: same namespace, openshift-monitoring, ODH namespaces | Protect monitoring stack |
| applications-namespace | opendatahub/rhods-* | All pods | Allow from: same namespace, monitoring, operator | Protect application workloads |

## Data Flows

### Flow 1: DataScienceCluster Reconciliation

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User/GitOps | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | kubeconfig credentials |
| 2 | Kubernetes API | Operator Webhook | 9443/TCP | HTTPS | TLS 1.2+ (service-ca) | mTLS (API server cert) |
| 3 | Webhook | Kubernetes API (validation response) | N/A | N/A | N/A | N/A |
| 4 | DSC Controller (watch) | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 5 | DSC Controller | Kubernetes API (create resources) | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 6 | Component Controllers | Kubernetes API (deploy manifests) | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |

### Flow 2: Metrics Collection

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Operator Pod | Metrics Endpoint (self) | 8080/TCP | HTTP | None | N/A |
| 2 | Prometheus | Operator Metrics Service | 8443/TCP | HTTPS | TLS 1.2+ (service-ca) | Bearer Token |
| 3 | Prometheus | Component ServiceMonitors | Various/TCP | HTTP/HTTPS | Varies | ServiceAccount Token |
| 4 | Prometheus | Alertmanager | 9093/TCP | HTTP | None | Internal |

### Flow 3: Component Deployment

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Component Controller | Manifest Loader (/opt/manifests) | N/A | Filesystem | N/A | N/A |
| 2 | Manifest Deployer | Kustomize Engine (in-memory) | N/A | N/A | N/A | N/A |
| 3 | Manifest Deployer | Kubernetes API (apply) | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 4 | Component Sub-Operator | Kubernetes API (reconcile) | 6443/TCP | HTTPS | TLS 1.2+ | Component ServiceAccount Token |

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| OpenShift Console | ConsoleLink CRD | N/A | N/A | N/A | Dashboard integration in UI |
| Prometheus Operator | ServiceMonitor/PrometheusRule CRDs | N/A | N/A | N/A | Monitoring stack integration |
| OLM (Operator Lifecycle Manager) | Subscription/CSV APIs | 6443/TCP | HTTPS | TLS 1.2+ | Operator dependency management |
| Service Mesh (Istio) | ServiceMeshMember CRD | N/A | N/A | N/A | Mesh enrollment for components |
| OpenShift Serverless | KnativeServing CRD | N/A | N/A | N/A | Serverless integration for KServe |
| Image Registries | Container Pull | 443/TCP | HTTPS | TLS 1.2+ | Component image deployment |
| cert-manager | Certificate CRD (optional) | N/A | N/A | N/A | Certificate provisioning (if enabled) |

## Deployment Architecture

### Container Image Build

- **Build System**: Konflux (production), local Make (development)
- **Base Images**:
  - Builder: registry.redhat.io/ubi9/go-toolset:1.25
  - Runtime: registry.access.redhat.com/ubi9/ubi-minimal
- **Build Mode**: Multi-stage with FIPS-compliant Go runtime
- **Manifest Inclusion**: Copies /opt/manifests and prefetched-manifests into image at build time
- **Size Optimization**: Debug symbols stripped, minimal runtime base

### Operator Deployment

- **Replicas**: 3 (with pod anti-affinity for HA)
- **Resource Limits**: CPU 500m, Memory 4Gi
- **Resource Requests**: CPU 100m, Memory 780Mi
- **Security Context**: runAsNonRoot, no privilege escalation, drop all capabilities
- **Probes**: Liveness (/healthz:8081), Readiness (/readyz:8081)
- **Namespace**: redhat-ods-operator (RHOAI) or opendatahub (ODH)

### Configuration

- **Environment Variables**:
  - `OPERATOR_NAMESPACE`: Operator deployment namespace
  - `DEFAULT_MANIFESTS_PATH`: /opt/manifests
  - `ODH_PLATFORM_TYPE`: OpenDataHub or RHOAI (managed/self-managed)
  - `DISABLE_DSC_CONFIG`: Controls auto-creation of DSCI

- **ConfigMaps**:
  - Component-specific configurations in /opt/manifests
  - Monitoring configurations
  - Hardware profiles

## Component Management

### Managed Components

The operator can deploy and manage the following components (configured via DataScienceCluster CR):

| Component | Management State Options | Default State | Purpose |
|-----------|--------------------------|---------------|---------|
| Dashboard | Managed/Removed/Unmanaged | Managed | ODH web console and UI |
| Workbenches | Managed/Removed/Unmanaged | Managed | Jupyter notebook environments |
| Data Science Pipelines | Managed/Removed/Unmanaged | Managed | Kubeflow/Tekton pipelines |
| KServe | Managed/Removed/Unmanaged | Managed | Model serving (RawDeployment/Serverless) |
| Kueue | Managed/Removed/Unmanaged | Removed | Job queuing and resource management |
| Ray | Managed/Removed/Unmanaged | Managed | Distributed computing |
| Training Operator | Managed/Removed/Unmanaged | Managed | Distributed training (TFJob, PyTorchJob, etc.) |
| TrustyAI | Managed/Removed/Unmanaged | Managed | Model explainability and fairness |
| Model Registry | Managed/Removed/Unmanaged | Managed | Model versioning and metadata |
| Feast Operator | Managed/Removed/Unmanaged | Managed | Feature store |
| MLflow Operator | Managed/Removed/Unmanaged | Removed | Experiment tracking |
| Llama Stack Operator | Managed/Removed/Unmanaged | Removed | LLM deployment |

### Platform Services

| Service | Purpose | Management State |
|---------|---------|------------------|
| Monitoring | Prometheus/Alertmanager stack | Managed/Removed |
| Auth | OAuth/RBAC configuration | Managed/Removed |
| Gateway | API gateway (Istio/Gateway API) | Managed/Removed |
| TrustedCABundle | Custom CA injection | Managed/Removed |

## Recent Changes

| Commit | Date | Changes |
|--------|------|---------|
| 181aacbe8 | 2025-03 | Updating the operator repo with latest images and manifests |
| 7c6c598aa | 2025-03 | Update odh-must-gather-v3-2 to e587946 |
| 402cc0a36 | 2025-03 | Update odh-maas-api-v3-2 to c67e14e |
| ed3623342 | 2025-03 | Update odh-model-registry-v3-2 to 6908d2b |
| b20045a18 | 2025-03 | Component dependency updates |
| 8dea3dc85 | 2025-03 | Update odh-kuberay-operator-controller-v3-2 to 5249b6d |
| c522f0db1 | 2025-03 | Update odh-kf-notebook-controller-v3-2 to 18fb24e |
| de26b9b65 | 2025-03 | Update odh-notebook-controller-v3-2 to be3773b |
| 630813435 | 2025-03 | Update odh-mlflow-operator-v3-2 to 88a232e |
| b303680a5 | 2025-03 | Update odh-mlflow-v3-2 to 3c11a49 |

**Recent Activity**: The operator is actively maintained with frequent component image updates, dependency version bumps, and manifest synchronization. The rhoai-3.2 branch shows continuous integration with Konflux-based automated builds and component updates.

## Operational Characteristics

### High Availability

- **Deployment**: 3 replicas with pod anti-affinity
- **Leader Election**: Enabled (lease-based, ID: 07ed84f7.opendatahub.io)
- **Fault Tolerance**: Automatic failover via leader election

### Observability

- **Metrics**: Prometheus metrics on :8080/metrics (proxied via :8443 with auth)
- **Logging**: Configurable via log-mode (development/production), zap logger
- **Health Checks**: /healthz and /readyz endpoints
- **Events**: Kubernetes events for reconciliation status

### Performance

- **Caching**: Intelligent cache filtering for Secrets, ConfigMaps, specific resource types
- **Concurrency**: Controller-runtime with parallel reconciliation
- **Resource Watching**: Selective watches with field/label selectors to reduce API load

### Upgrade Strategy

- **CRD Versioning**: v1 and v2 API versions with conversion webhooks
- **Cleanup**: Automated cleanup of deprecated resources from previous versions
- **Compatibility**: Backward compatible API changes, stored version migration

## Development & Testing

### Local Development

```bash
# Download component manifests
make get-manifests  # Not applicable - uses prefetched-manifests

# Build operator
make build

# Run locally
make run

# Build image
make docker-build IMG=<registry>/rhods-operator:tag

# Deploy to cluster
make deploy IMG=<registry>/rhods-operator:tag
```

### Testing

- **Unit Tests**: Go test framework with Gomega matchers
- **E2E Tests**: Ginkgo-based functional tests
- **Webhook Tests**: Validation/mutation logic testing

### CI/CD

- **Build Platform**: Konflux (production), GitHub Actions (CI)
- **Image Signing**: FIPS-compliant builds
- **Dependency Management**: Dependabot/Renovate for Go modules and component images

## Known Limitations

1. **Platform Lock-in**: Primarily designed for OpenShift; some features require OpenShift-specific APIs
2. **Component Dependencies**: Some components require external operators (Service Mesh, Serverless)
3. **Namespace Constraints**: Operator must run in specific namespace (redhat-ods-operator or opendatahub)
4. **Single Instance**: Only one DataScienceCluster CR supported per cluster
5. **Manifest Immutability**: Component manifests baked into operator image at build time

## Troubleshooting

### Common Issues

**Operator not starting:**
- Check ServiceAccount permissions
- Verify CRD installation
- Check webhook certificate provisioning

**Component deployment failing:**
- Review DataScienceCluster status conditions
- Check operator logs for reconciliation errors
- Verify manifest path (/opt/manifests) exists in container

**Webhook failures:**
- Ensure service-ca-operator is running
- Check webhook service and certificate secret
- Verify API server can reach webhook service

### Debug Commands

```bash
# Check operator logs
oc logs -n redhat-ods-operator deployment/rhods-operator

# View DSC status
oc get datasciencecluster -o yaml

# View DSCI status
oc get dscinitialization -o yaml

# Check component status
oc get components.opendatahub.io -A

# View webhook configuration
oc get validatingwebhookconfigurations | grep opendatahub
oc get mutatingwebhookconfigurations | grep opendatahub
```

## References

- **Source Code**: https://github.com/red-hat-data-services/rhods-operator
- **Documentation**: See README.md and docs/ directory in repository
- **CRD API Docs**: Generated from api/ directory with crd-ref-docs
- **Component Manifests**: prefetched-manifests/ directory
- **Monitoring Config**: config/monitoring/ directory
