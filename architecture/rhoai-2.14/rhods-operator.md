# Component: rhods-operator

## Metadata
- **Repository**: https://github.com/red-hat-data-services/rhods-operator.git
- **Version**: v1.6.0-826-gf50f02777
- **Branch**: rhoai-2.14
- **Distribution**: RHOAI (also used as opendatahub-operator in ODH)
- **Languages**: Go 1.21
- **Deployment Type**: Kubernetes Operator (Operator Pattern)

## Purpose
**Short**: Primary operator for deploying and managing Red Hat OpenShift AI (RHOAI) and Open Data Hub (ODH) data science platform components.

**Detailed**: The rhods-operator (also known as opendatahub-operator) is the central orchestration component for the RHOAI/ODH platform. It manages the lifecycle of all data science components including Dashboard, Workbenches, Data Science Pipelines, KServe, ModelMesh Serving, Ray, CodeFlare, Kueue, ModelRegistry, TrustyAI, and Training Operator. The operator uses two primary Custom Resource Definitions (CRDs): DSCInitialization for platform-wide initialization (monitoring, service mesh, trusted CA bundles) and DataScienceCluster for enabling/disabling individual components. It reconciles these CRs to deploy component manifests from remote git repositories, configure RBAC, set up networking, and manage platform upgrades. The operator runs 4 controllers: DataScienceCluster controller for component deployment, DSCInitialization controller for platform setup, SecretGenerator for dynamic secret creation, and CertConfigmapGenerator for certificate management. It also provides admission webhooks for validating and mutating CR instances.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| DataScienceCluster Controller | Reconciliation Controller | Manages deployment and lifecycle of data science components (Dashboard, Pipelines, KServe, etc.) |
| DSCInitialization Controller | Reconciliation Controller | Initializes platform-wide infrastructure (monitoring, service mesh, namespaces, trusted CA) |
| SecretGenerator Controller | Reconciliation Controller | Dynamically generates and manages secrets for components |
| CertConfigmapGenerator Controller | Reconciliation Controller | Generates and manages certificate ConfigMaps |
| Validating Webhook | Admission Webhook | Validates DataScienceCluster and DSCInitialization CR creation/deletion |
| Mutating Webhook | Admission Webhook | Provides default values for DataScienceCluster CRs |
| Operator Manager | Deployment | Main operator process with health/metrics endpoints |
| Auth Proxy | Sidecar (optional) | Provides authenticated access to metrics endpoint |

## APIs Exposed

### Custom Resource Definitions (CRDs)

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| datasciencecluster.opendatahub.io | v1 | DataScienceCluster | Cluster | Defines which data science components to enable and their configuration |
| dscinitialization.opendatahub.io | v1 | DSCInitialization | Cluster | Initializes platform infrastructure (monitoring, service mesh, namespaces) |
| features.opendatahub.io | v1 | FeatureTracker | Cluster | Tracks resources created by internal Features API for garbage collection |

### HTTP Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /healthz | GET | 8081/TCP | HTTP | None | None | Liveness probe endpoint |
| /readyz | GET | 8081/TCP | HTTP | None | None | Readiness probe endpoint |
| /metrics | GET | 8080/TCP | HTTP | None | None | Prometheus metrics (internal only) |
| /metrics | GET | 8443/TCP | HTTPS | TLS 1.2+ | kube-rbac-proxy | Prometheus metrics (authenticated via auth proxy) |
| /mutate-opendatahub-io-v1 | POST | 9443/TCP | HTTPS | TLS 1.2+ | Kubernetes API Server mTLS | Mutating webhook for DataScienceCluster |
| /validate-opendatahub-io-v1 | POST | 9443/TCP | HTTPS | TLS 1.2+ | Kubernetes API Server mTLS | Validating webhook for DataScienceCluster and DSCInitialization |

### gRPC Services

None - this is a pure Kubernetes operator using HTTP/HTTPS only.

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| Kubernetes/OpenShift | 1.25+ / 4.12+ | Yes | Platform runtime |
| Service Mesh Operator | Latest stable | Conditional | Required for KServe and single model serving |
| Serverless Operator | Latest stable | Conditional | Required for KServe serving runtime |
| Authorino Operator | Latest stable | Conditional | Required for model serving authentication |
| Cert-Manager | Latest stable | Optional | Certificate management for components |
| Prometheus Operator | Latest stable | Optional | Monitoring stack management |
| OpenShift Console | 4.12+ | Optional | Console integration (ConsoleLinks, ODHQuickStarts) |

### Internal ODH Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| odh-dashboard | CRD + Deployment | Manages Dashboard CRDs (OdhApplication, OdhDocument, AcceleratorProfile) |
| kserve | CRD + Manifests | Deploys and configures KServe InferenceServices and ServingRuntimes |
| modelmesh-serving | Manifests | Deploys ModelMesh serving infrastructure |
| data-science-pipelines-operator | CRD | Manages DataSciencePipelinesApplication CRDs |
| codeflare-operator | Manifests | Deploys CodeFlare for distributed workloads |
| kuberay-operator | Manifests | Deploys Ray clusters for ML workloads |
| training-operator | Manifests | Deploys Kubeflow Training Operator |
| kueue | Manifests | Deploys job queueing system |
| model-registry | Deployment | Deploys model registry service |
| trustyai-service-operator | Manifests | Deploys TrustyAI for model monitoring |

## Network Architecture

### Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| controller-manager-metrics-service | ClusterIP | 8443/TCP | 8080 | HTTPS | TLS 1.2+ | kube-rbac-proxy | Internal |
| webhook-service | ClusterIP | 443/TCP | 9443 | HTTPS | TLS 1.2+ (service-ca) | Kubernetes API Server | Internal |

### Ingress

| Name | Type | Hosts | Port | Protocol | Encryption | TLS Mode | Exposure |
|------|------|-------|------|----------|------------|----------|----------|
| N/A | N/A | N/A | N/A | N/A | N/A | N/A | Operator has no external ingress - internal only |

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token | CRD reconciliation and resource management |
| github.com | 443/TCP | HTTPS | TLS 1.2+ | None | Download component manifests from git repositories |
| quay.io | 443/TCP | HTTPS | TLS 1.2+ | None | Pull container images |
| OpenShift Image Registry | 5000/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token | Internal image pulls |

## Security

### RBAC - Cluster Roles

| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|
| controller-manager-role | datasciencecluster.opendatahub.io | datascienceclusters, datascienceclusters/finalizers, datascienceclusters/status | create, delete, get, list, patch, update, watch |
| controller-manager-role | dscinitialization.opendatahub.io | dscinitializations, dscinitializations/finalizers, dscinitializations/status | create, delete, get, list, patch, update, watch |
| controller-manager-role | features.opendatahub.io | featuretrackers, featuretrackers/status | create, delete, get, list, patch, update, watch |
| controller-manager-role | "" (core) | namespaces, configmaps, secrets, services, serviceaccounts | create, delete, get, list, patch, update, watch |
| controller-manager-role | apps | deployments, replicasets, statefulsets | create, delete, get, list, patch, update, watch |
| controller-manager-role | rbac.authorization.k8s.io | clusterroles, clusterrolebindings, roles, rolebindings | create, delete, get, list, patch, update, watch |
| controller-manager-role | route.openshift.io | routes | create, delete, get, list, patch, update, watch |
| controller-manager-role | networking.k8s.io | networkpolicies | create, delete, get, list, patch, update, watch |
| controller-manager-role | apiextensions.k8s.io | customresourcedefinitions | create, delete, get, list, patch, watch |
| controller-manager-role | admissionregistration.k8s.io | mutatingwebhookconfigurations, validatingwebhookconfigurations | create, delete, get, list, patch, update, watch |
| controller-manager-role | serving.kserve.io | inferenceservices, servingruntimes, clusterservingruntimes | create, delete, get, list, patch, update, watch |
| controller-manager-role | datasciencepipelinesapplications.opendatahub.io | datasciencepipelinesapplications | create, delete, get, list, patch, update, watch |
| controller-manager-role | authorino.kuadrant.io | authconfigs | create, delete, get, list, patch, update, watch |
| controller-manager-role | console.openshift.io | consolelinks, odhquickstarts | create, delete, get, list, patch |
| controller-manager-role | monitoring.coreos.com | servicemonitors, prometheusrules | create, delete, get, list, patch, update, watch |
| controller-manager-role | batch | jobs, cronjobs | create, delete, get, list, patch, update, watch |

### RBAC - Role Bindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| controller-manager-rolebinding | Cluster-wide | controller-manager-role (ClusterRole) | controller-manager (operator namespace) |

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| redhat-ods-operator-controller-webhook-cert | kubernetes.io/tls | TLS certificate for webhook service | service.beta.openshift.io/serving-cert-secret-name annotation | Yes (OpenShift Service CA) |
| prometheus-secrets | Opaque | Prometheus configuration secrets | Operator | No |
| segment-key-secret | Opaque | Segment analytics key for telemetry | Operator | No |

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| /mutate-opendatahub-io-v1 | POST | Kubernetes API Server mTLS | Admission Controller | Only Kubernetes API Server can call |
| /validate-opendatahub-io-v1 | POST | Kubernetes API Server mTLS | Admission Controller | Only Kubernetes API Server can call |
| /metrics (8443) | GET | kube-rbac-proxy + Bearer Token | kube-rbac-proxy sidecar | Requires get permission on /metrics path |
| /metrics (8080) | GET | None (NetworkPolicy enforced) | NetworkPolicy | Only pods in monitoring namespaces |
| /healthz, /readyz | GET | None (NetworkPolicy enforced) | NetworkPolicy | Kubelet and monitoring namespaces only |

## Data Flows

### Flow 1: Component Deployment

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User/System | Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.3 | kubeconfig credentials |
| 2 | Kubernetes API Server | Operator (Webhook) | 9443/TCP | HTTPS | TLS 1.2+ | API Server mTLS |
| 3 | Operator | Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.3 | ServiceAccount Token |
| 4 | Operator | github.com | 443/TCP | HTTPS | TLS 1.2+ | None |
| 5 | Operator | Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.3 | ServiceAccount Token |

**Description**: User creates/updates DataScienceCluster CR → API Server validates via webhook → Operator reconciles → Downloads manifests from git → Deploys component resources

### Flow 2: Platform Initialization

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Operator (startup) | Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.3 | ServiceAccount Token |
| 2 | Operator | Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.3 | ServiceAccount Token |
| 3 | Operator | Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.3 | ServiceAccount Token |

**Description**: Operator starts → Creates default DSCInitialization CR → Sets up monitoring namespace → Deploys service mesh resources → Configures trusted CA bundles

### Flow 3: Metrics Collection

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Prometheus (monitoring namespace) | Auth Proxy Service | 8443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Bearer Token |
| 2 | Auth Proxy | Operator Manager | 8080/TCP | HTTP | None | Internal pod network |

**Description**: Prometheus scrapes metrics from operator via authenticated auth proxy endpoint

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| Kubernetes API Server | REST API | 6443/TCP | HTTPS | TLS 1.3 | CRD management and resource reconciliation |
| Prometheus | Metrics Scrape | 8443/TCP | HTTPS | TLS 1.2+ | Operator metrics collection |
| OpenShift Service CA | Certificate Injection | N/A | N/A | N/A | Webhook TLS certificate provisioning |
| Service Mesh Control Plane | CRD | 6443/TCP | HTTPS | TLS 1.3 | Configure Istio for model serving |
| Component Operators | CRD | 6443/TCP | HTTPS | TLS 1.3 | Create component-specific CRs (DSP, KServe, etc.) |

## Recent Changes

| Date | Commit | Changes |
|------|--------|---------|
| 2024-10-09 | f50f02777 | - Fix: Add release status to upgrade case |
| 2024-10-04 | b0dcf4e02 | - Fix: Add missing RBAC rule to scrape metrics endpoints protected by RBAC (RHOAIENG-13957) |
| 2024-10-03 | b80854fb6 | - Revert: Keep rhoai-model-registries as default value in DSC CRD |
| 2024-10-01 | b07380e84 | - Update: Set to use odh-model-registries as namespace if not set in DSC CR |
| 2024-09-19 | 53fea2a5e | - Refactor: Change mutating webhook to use Default to set ModelRegistry namespace |
| 2024-09-27 | 2e03e1d80 | - Fix: Keep odh-model-registries as default value in API |
| 2024-10-02 | eaa43c066 | - Fix: Fixed typo for jackdelahunt owner |
| 2024-10-01 | 40e083073 | - Feature: Add support for upgrade to force disableModelRegistry to false |
| 2024-09-30 | 4e6b6214d | - Fix: Add downstream operator namespace into cache for secret |
| 2024-09-26 | Multiple | - Update: Change default model registries namespace to rhoai-model-registries |

## Deployment Architecture

### Container Images

| Image Component | Base Image | Build Method | Purpose |
|----------------|------------|--------------|---------|
| manager | registry.access.redhat.com/ubi8/ubi-minimal:latest | Multi-stage Dockerfile | Operator manager binary with embedded manifests |

### Resource Requirements

| Container | CPU Request | CPU Limit | Memory Request | Memory Limit |
|-----------|-------------|-----------|----------------|--------------|
| manager | 100m | 500m | 780Mi | 4Gi |

### Volumes and Storage

| Volume Name | Type | Purpose | Mount Path |
|-------------|------|---------|------------|
| manifests | Embedded in image | Component manifests from git repositories | /opt/manifests |

### Environment Variables

| Variable | Source | Purpose |
|----------|--------|---------|
| OPERATOR_NAMESPACE | fieldRef: metadata.namespace | Identify operator's deployment namespace |
| DEFAULT_MANIFESTS_PATH | Static | Path to embedded manifests (/opt/manifests) |
| DISABLE_DSC_CONFIG | Optional | Disable automatic DSCInitialization creation |

## Component Lifecycle

### Initialization Sequence

1. Operator pod starts, loads embedded manifests from /opt/manifests
2. Webhook server starts on port 9443 with service-ca provided certificates
3. Health/readiness probes become available on port 8081
4. Metrics endpoint starts on port 8080
5. Controllers register watches for CRDs and related resources
6. If DISABLE_DSC_CONFIG != "false", creates default DSCInitialization CR
7. For managed RHODS, creates default DataScienceCluster CR
8. Runs cleanup of deprecated resources from previous versions
9. Begins reconciliation loops for existing CRs

### Component Management

The operator manages components through a consistent lifecycle:
- **Managed**: Component is deployed and actively reconciled
- **Removed**: Component resources are deleted and cleaned up
- Each component can specify custom manifest sources via devFlags
- Components support platform-specific overlays (ODH vs RHOAI)
- Upgrade logic handles migration between operator versions

## Network Policies

### Operator Namespace (redhat-ods-operator)

**Ingress**:
- Allow from: redhat-ods-monitoring, openshift-monitoring, openshift-user-workload-monitoring, openshift-console, namespaces with opendatahub.io/generated-namespace=true, host-network pods
- Purpose: Allow Prometheus scraping, console access, and component communication

**Egress**: Unrestricted (default)

### Monitoring Namespace (redhat-ods-monitoring)

**Ingress**:
- Allow TCP: 443, 9115, 8443, 9091, 10443, 9114, 8080
- Allow from: openshift-monitoring, openshift-user-workload-monitoring, redhat-ods-operator, namespaces with opendatahub.io/generated-namespace=true
- Purpose: Prometheus, Alertmanager, Blackbox Exporter access

**Egress**: Unrestricted (allow all)

## Troubleshooting

### Common Issues

1. **Webhook certificate not ready**: Wait for service-ca-operator to inject certificate
2. **Component deployment fails**: Check devFlags.manifestsUri for custom manifest source issues
3. **DSCI/DSC creation blocked**: Only one instance of each CR is allowed cluster-wide
4. **Monitoring not working**: Verify redhat-ods-monitoring namespace exists and ServiceMonitor is created
5. **Component stuck in "Not Ready"**: Check component-specific logs and ensure dependent operators are installed

### Debug Endpoints

- Health: `curl http://localhost:8081/healthz`
- Ready: `curl http://localhost:8081/readyz`
- Metrics: `curl -k https://localhost:8443/metrics` (requires auth)

### Log Levels

Controller level: Set via CSV parameter `--log-mode` (devel/prod/production/default)
Component level: Set via DSCI.spec.devFlags.logmode (devel/development/prod/production)
