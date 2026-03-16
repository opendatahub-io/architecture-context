# Component: RHODS Operator

## Metadata
- **Repository**: https://github.com/red-hat-data-services/rhods-operator.git
- **Version**: v1.6.0-641-gca3c6e249
- **Branch**: rhoai-2.11
- **Distribution**: RHOAI (derived from ODH opendatahub-operator)
- **Languages**: Go 1.21
- **Deployment Type**: Kubernetes Operator

## Purpose
**Short**: Primary operator for Red Hat OpenShift AI that manages the lifecycle of data science platform components through custom resources.

**Detailed**: The RHODS Operator is the core orchestration component for Red Hat OpenShift AI (RHOAI). It manages the deployment, configuration, and lifecycle of all data science platform components including dashboard, workbenches, model serving, data science pipelines, and distributed training frameworks. The operator uses two primary custom resources: DSCInitialization (for platform-wide initialization including service mesh and monitoring) and DataScienceCluster (for component enablement and configuration). It reconciles manifests from component repositories, manages RBAC, configures monitoring, and integrates with OpenShift service mesh for unified authentication and networking. The operator supports both managed (RHOAI) and self-managed (ODH) deployment scenarios with platform-specific logic.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| DataScienceCluster Controller | Kubernetes Controller | Reconciles DataScienceCluster CRs to deploy and manage ODH/RHOAI components |
| DSCInitialization Controller | Kubernetes Controller | Initializes platform infrastructure (service mesh, monitoring, namespaces, RBAC) |
| SecretGenerator Controller | Kubernetes Controller | Generates and manages secrets for component authentication |
| CertConfigmapGenerator Controller | Kubernetes Controller | Generates certificate ConfigMaps for TLS/mTLS configurations |
| Component Reconcilers | Component Modules | Individual reconcile logic for dashboard, kserve, modelmeshserving, datasciencepipelines, codeflare, ray, kueue, trainingoperator, trustyai, workbenches |
| Manifest Manager | Deployment Logic | Fetches and applies kustomize manifests from component repositories |
| Monitoring Stack | Observability | Prometheus, Alertmanager, and ServiceMonitors for platform metrics |

## APIs Exposed

### Custom Resource Definitions (CRDs)

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| datasciencecluster.opendatahub.io | v1 | DataScienceCluster | Cluster | Defines which ODH/RHOAI components are enabled and their configuration |
| dscinitialization.opendatahub.io | v1 | DSCInitialization | Cluster | Configures platform initialization including service mesh, monitoring, and trusted CA bundles |
| features.opendatahub.io | v1 | FeatureTracker | Cluster | Tracks features created via internal Features API for garbage collection |
| kfdef.apps.kubeflow.org | v1 | KfDef | Namespaced | Legacy Kubeflow definition support (external CRD) |

### HTTP Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /metrics | GET | 8080/TCP | HTTP | None | None | Prometheus metrics endpoint for operator |
| /healthz | GET | 8081/TCP | HTTP | None | None | Health probe endpoint |
| /readyz | GET | 8081/TCP | HTTP | None | None | Readiness probe endpoint |

### gRPC Services

No gRPC services exposed by the operator itself.

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| Kubernetes | 1.28+ | Yes | Orchestration platform |
| OpenShift | 4.x | No | Enhanced features (Routes, OAuth, ImageStreams) |
| Service Mesh Operator (Istio) | Latest | No | Service mesh for KServe and unified auth |
| Authorino Operator | Latest | No | API authorization for KServe |
| Serverless Operator (Knative) | Latest | No | Serverless runtime for KServe |
| Prometheus Operator | v0.68.0 | No | Monitoring stack components |
| cert-manager | Latest | No | Certificate management |

### Internal ODH Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| ODH Dashboard | Deploys manifests | Provides web UI for data science platform |
| KServe | Deploys manifests | Single model serving runtime |
| ModelMesh Serving | Deploys manifests | Multi-model serving runtime |
| Data Science Pipelines | Deploys manifests | ML pipeline orchestration |
| Workbenches | Deploys manifests | Jupyter notebook environments |
| CodeFlare | Deploys manifests | Distributed compute orchestration |
| Ray | Deploys manifests | Distributed Python runtime |
| Kueue | Deploys manifests | Job queueing for batch workloads |
| Training Operator | Deploys manifests | Distributed ML training (PyTorch, TensorFlow) |
| TrustyAI | Deploys manifests | Model monitoring and explainability |

## Network Architecture

### Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| controller-manager-metrics-service | ClusterIP | 8443/TCP | 8080 | HTTP | None | None | Internal |
| prometheus | ClusterIP | 9091/TCP | https | HTTPS | TLS (service cert) | OAuth Proxy | Internal |
| alertmanager | ClusterIP | 9093/TCP | https | HTTPS | TLS (service cert) | OAuth Proxy | Internal |
| blackbox-exporter | ClusterIP | 9115/TCP | 9115 | HTTP | None | None | Internal |

### Ingress

| Name | Type | Hosts | Port | Protocol | Encryption | TLS Mode | Exposure |
|------|------|-------|------|----------|------------|----------|----------|
| prometheus | OpenShift Route | cluster-specific | 443/TCP | HTTPS | TLS 1.2+ | Reencrypt | External |
| alertmanager | OpenShift Route | cluster-specific | 443/TCP | HTTPS | TLS 1.2+ | Reencrypt | External |

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| GitHub component repos | 443/TCP | HTTPS | TLS 1.2+ | None | Fetch component manifests at build time |
| Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token | Reconcile cluster resources |
| Prometheus | 9091/TCP | HTTPS | TLS 1.2+ | OAuth | Scrape component metrics |

## Security

### RBAC - Cluster Roles

| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|
| controller-manager-role | "" | namespaces, configmaps, secrets, services, serviceaccounts, pods, persistentvolumeclaims | create, delete, get, list, patch, update, watch |
| controller-manager-role | apps | deployments, statefulsets, replicasets | * |
| controller-manager-role | datasciencecluster.opendatahub.io | datascienceclusters, datascienceclusters/status, datascienceclusters/finalizers | create, delete, get, list, patch, update, watch |
| controller-manager-role | dscinitialization.opendatahub.io | dscinitializations, dscinitializations/status, dscinitializations/finalizers | create, delete, get, list, patch, update, watch |
| controller-manager-role | features.opendatahub.io | featuretrackers, featuretrackers/status | create, delete, get, list, patch, update, watch |
| controller-manager-role | rbac.authorization.k8s.io | clusterroles, clusterrolebindings, roles, rolebindings | * |
| controller-manager-role | route.openshift.io | routes | create, delete, get, list, patch, update, watch |
| controller-manager-role | networking.istio.io | gateways, virtualservices, envoyfilters | * |
| controller-manager-role | maistra.io | servicemeshcontrolplanes, servicemeshmemberrolls, servicemeshmembers | create, get, list, patch, update, use, watch |
| controller-manager-role | monitoring.coreos.com | servicemonitors, podmonitors, prometheusrules, prometheuses, alertmanagers | create, delete, get, list, patch, update, watch |
| controller-manager-role | authorino.kuadrant.io | authconfigs | * |
| controller-manager-role | serving.kserve.io | * | * |
| controller-manager-role | kubeflow.org | * | * |
| controller-manager-role | apiextensions.k8s.io | customresourcedefinitions | create, delete, get, list, patch, watch |
| controller-manager-role | admissionregistration.k8s.io | mutatingwebhookconfigurations, validatingwebhookconfigurations | create, delete, get, list, patch, update, watch |
| auth-proxy-client | "" (core) | pods, services, endpoints | get, list, watch |
| auth-proxy-client | authentication.k8s.io | tokenreviews | create |
| auth-proxy-client | authorization.k8s.io | subjectaccessreviews | create |

**Note**: The operator has extensive RBAC permissions (159 distinct apiGroups) to manage all ODH/RHOAI components and their dependencies.

### RBAC - Role Bindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| controller-manager-rolebinding | cluster-wide | controller-manager-role | system:controller-manager |
| prometheus-rolebinding-scraper | redhat-ods-monitoring | prometheus-role | prometheus |
| rhods-prometheus-rolebinding | redhat-ods-monitoring | rhods-prometheus-role | prometheus |

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| prometheus-tls | kubernetes.io/tls | TLS cert for Prometheus service | OpenShift Service CA | Yes |
| prometheus-secret | kubernetes.io/service-account-token | OAuth proxy service account token | Kubernetes | No |
| alertmanager-tls | kubernetes.io/tls | TLS cert for Alertmanager service | OpenShift Service CA | Yes |
| segment-key-secret | Opaque | Analytics key for telemetry | Manual/GitOps | No |

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| /metrics | GET | None | None | Accessible within cluster network policy |
| Prometheus Route | GET, POST | OAuth Proxy (OpenShift) | OpenShift OAuth | cluster-admin or prometheus viewer |
| Alertmanager Route | GET, POST | OAuth Proxy (OpenShift) | OpenShift OAuth | cluster-admin or alertmanager viewer |

### Network Policies

| Policy Name | Namespace | Pod Selector | Ingress Rules |
|-------------|-----------|--------------|---------------|
| redhat-ods-operator | redhat-ods-operator | control-plane: controller-manager | Allow from: redhat-ods-monitoring, openshift-monitoring, openshift-user-workload-monitoring, opendatahub.io/generated-namespace=true |
| redhat-ods-applications | redhat-ods-applications | all | Component-specific rules |
| redhat-ods-monitoring | redhat-ods-monitoring | all | Allow Prometheus scraping and monitoring access |

## Data Flows

### Flow 1: Component Deployment

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User/Admin | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | kubeconfig auth |
| 2 | User creates DSCInitialization CR | Operator watches CR | - | - | - | - |
| 3 | DSCInitialization Controller | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 4 | DSCI Controller creates namespaces, RBAC, service mesh config | Cluster Resources | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 5 | User creates DataScienceCluster CR | Operator watches CR | - | - | - | - |
| 6 | DSC Controller | GitHub (build time) | 443/TCP | HTTPS | TLS 1.2+ | None |
| 7 | DSC Controller applies component manifests | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 8 | Component pods start | Component Services | varies | varies | varies | varies |

### Flow 2: Monitoring and Metrics

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Prometheus | Operator metrics endpoint | 8080/TCP | HTTP | None | None |
| 2 | Prometheus | Component ServiceMonitors | varies | HTTP/HTTPS | varies | ServiceAccount |
| 3 | User | Prometheus Route | 443/TCP | HTTPS | TLS 1.2+ | OAuth Proxy |
| 4 | OAuth Proxy | Prometheus Service | 9091/TCP | HTTPS | TLS (internal) | Service cert |
| 5 | Prometheus | Alertmanager | 9093/TCP | HTTPS | TLS (internal) | Service cert |

### Flow 3: Secret and Certificate Generation

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | SecretGenerator Controller watches Secret annotations | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 2 | Controller generates random secret values | Kubernetes API (Secret creation) | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 3 | CertConfigmapGenerator watches cert-manager Certificates | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 4 | Controller creates ConfigMaps from cert data | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| Kubernetes API Server | REST API | 6443/TCP | HTTPS | TLS 1.2+ | Reconcile all cluster resources |
| Service Mesh Control Plane | Custom Resources | 6443/TCP | HTTPS | TLS 1.2+ | Configure Istio for KServe and auth |
| Prometheus | ServiceMonitor CRs | 6443/TCP | HTTPS | TLS 1.2+ | Configure platform monitoring |
| Component Manifests (GitHub) | Git clone (build time) | 443/TCP | HTTPS | TLS 1.2+ | Fetch deployment manifests |
| OpenShift OAuth | OAuth annotations | varies | HTTPS | TLS 1.2+ | Secure route access |
| cert-manager | Certificate CRs | 6443/TCP | HTTPS | TLS 1.2+ | Request TLS certificates |

## Recent Changes

| Version | Date | Changes |
|---------|------|---------|
| v1.6.0-641 | 2024-07-12 | - Fix for managed cluster upgrade with DSC already exists<br>- Add odh-model-controller NetworkPolicy to whitelist<br>- Platform name cleanup |
| v1.6.0-638 | 2024-06-26 | - Add kserve-local-gateway Gateway and Service<br>- Remove duplicated logic by function call<br>- Fix ingress cert secret type to kubernetes.io/tls |
| v1.6.0-635 | 2024-06-25 | - Configure importas for consistent import aliases<br>- Update to latest linter version<br>- Remove unused client parameters |
| v1.6.0-632 | 2024-06-24 | - Move ArgoCD conditions to pipelines component<br>- Disable deprecated linters<br>- Make default knative secret local for serverless |
| v1.6.0-629 | 2024-06-20 | - Change serviceMesh and trustCABundle to pointer types in DSCI<br>- Add support for default Ingress Cert<br>- Upgrade Go from 1.20 to 1.21 |
| v1.6.0-626 | 2024-06-19 | - Fix release version<br>- Sync from ODH to RHOAI 2.11<br>- Revert TrustyAI re-enablement |

## Deployment Configuration

### Operator Deployment

- **Namespace**: redhat-ods-operator (RHOAI) or opendatahub (ODH)
- **Replicas**: 1 (leader election enabled)
- **Security Context**: runAsNonRoot: true, allowPrivilegeEscalation: false, drop ALL capabilities
- **Resource Limits**:
  - CPU: 500m request, 500m limit
  - Memory: 256Mi request, 4Gi limit
- **Health Checks**:
  - Liveness: /healthz on 8081, initialDelay 15s, period 20s
  - Readiness: /readyz on 8081, initialDelay 5s, period 10s

### Component Namespaces

- **Applications**: redhat-ods-applications (RHOAI) or opendatahub (ODH) - component workloads
- **Monitoring**: redhat-ods-monitoring (RHOAI) or opendatahub (ODH) - Prometheus, Alertmanager
- **Operator**: redhat-ods-operator (RHOAI) or openshift-operators (ODH) - operator pod

### Manifest Management

The operator fetches component manifests at build time via `get_all_manifests.sh` script:
- Component sources defined in COMPONENT_MANIFESTS map
- Supports custom manifest URIs via DSC/DSCI devFlags
- Manifests embedded in operator image at `/opt/manifests`
- Applied via kustomize at runtime during component reconciliation

### Feature Flags

- **DISABLE_DSC_CONFIG**: Disable automatic DSCI creation (default: false)
- **devFlags.logmode**: Component logging level (production, development)
- **devFlags.manifestsUri**: Override manifest sources for testing
- **component.devFlags.manifests**: Per-component manifest overrides

## Operational Notes

### Controller Reconciliation

- **Rate Limiting**: QPS: 20 (5 * 4 controllers), Burst: 40 (10 * 4 controllers)
- **Leader Election**: Enabled with lease ID `07ed84f7.opendatahub.io`
- **Requeue Behavior**: Requeues on transient errors, finalizers prevent premature deletion
- **Singleton Enforcement**: Only one DataScienceCluster CR allowed per cluster

### Upgrade Strategy

- Operator detects platform (Self-Managed, Managed RHODS, ODH)
- Runs upgrade functions on startup:
  - `CreateDefaultDSCI`: Ensures DSCI exists
  - `CreateDefaultDSC`: Creates default DSC for managed RHODS
  - `CleanupExistingResource`: Removes deprecated resources from v1
  - `RemoveDeprecatedTrustyAI`: Removes TrustyAI from RHOAI DSC
- Deletion ConfigMap triggers uninstall sequence

### Monitoring

- **ServiceMonitors**: rhods-servicemonitor for operator metrics
- **PrometheusRules**: Component-specific alerting rules
- **Dashboards**: Grafana dashboards for component health (external)
- **Metrics Endpoint**: :8080/metrics (Prometheus format)

### Troubleshooting

- Check operator logs: `oc logs -n redhat-ods-operator deployment/rhods-operator`
- Verify DSCI status: `oc get dsci -o yaml`
- Verify DSC status: `oc get dsc -o yaml`
- Check component deployments: `oc get pods -n redhat-ods-applications`
- Review events: `oc get events -n redhat-ods-operator --sort-by='.lastTimestamp'`
- Network policies: Ensure monitoring namespaces can scrape metrics
