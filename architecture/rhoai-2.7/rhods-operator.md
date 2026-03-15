# Component: RHOAI Operator (rhods-operator)

## Metadata
- **Repository**: https://github.com/red-hat-data-services/rhods-operator.git
- **Version**: v1.6.0-441-g7d51cea22
- **Branch**: rhoai-2.7
- **Distribution**: RHOAI
- **Languages**: Go 1.19
- **Deployment Type**: Kubernetes Operator

## Purpose
**Short**: Primary operator for Red Hat OpenShift AI (RHOAI) that manages the lifecycle of data science platform components.

**Detailed**: The RHOAI Operator (rhods-operator) is the core control plane for Red Hat OpenShift AI distribution. It orchestrates the deployment, configuration, and lifecycle management of AI/ML platform components including Jupyter notebooks, model serving (KServe, ModelMesh), data science pipelines, distributed computing (CodeFlare, Ray), and TrustyAI. The operator uses a declarative API via the DataScienceCluster CRD to enable platform administrators to configure which components are deployed, while DSCInitialization sets up the foundational infrastructure including namespaces, service mesh integration, and monitoring stack. It extends the upstream Open Data Hub operator with Red Hat specific integrations, enterprise features, and productization changes for OpenShift environments.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| DataScienceCluster Controller | Kubernetes Controller | Reconciles DataScienceCluster CRD to deploy and manage AI/ML components |
| DSCInitialization Controller | Kubernetes Controller | Initializes platform infrastructure (namespaces, service mesh, monitoring) |
| SecretGenerator Controller | Kubernetes Controller | Generates OAuth secrets and other credentials for component authentication |
| Status Controller | Subcontroller | Tracks and reports deployment status of components |
| Component Modules | Go Packages | Individual reconciliation logic for each managed component (Dashboard, KServe, etc.) |
| Metrics Service | HTTP Service | Exposes Prometheus metrics for operator health and component status |
| Health Probes | HTTP Endpoints | Kubernetes liveness and readiness probes |

## APIs Exposed

### Custom Resource Definitions (CRDs)

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| datasciencecluster.opendatahub.io | v1 | DataScienceCluster | Cluster | Declarative API to enable/disable AI/ML platform components with per-component configuration |
| dscinitialization.opendatahub.io | v1 | DSCInitialization | Cluster | Platform initialization configuration including namespaces, service mesh settings, monitoring stack |
| features.opendatahub.io | v1 | FeatureTracker | Cluster | Cluster-scoped owner reference for cross-namespace resource garbage collection |

### HTTP Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /metrics | GET | 8080/TCP | HTTP | None | Bearer Token | Prometheus metrics scraping endpoint for operator telemetry |
| /healthz | GET | 8081/TCP | HTTP | None | None | Kubernetes liveness probe for operator health |
| /readyz | GET | 8081/TCP | HTTP | None | None | Kubernetes readiness probe for operator availability |

### gRPC Services

None - This operator uses Kubernetes API only.

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| Kubernetes | 1.24+ | Yes | Base orchestration platform |
| OpenShift | 4.11+ | Yes | Container platform with Routes, OAuth, ImageStreams |
| Prometheus Operator | 0.69.1 | Yes | ServiceMonitor CRDs for metrics collection |
| cert-manager | Any | No | TLS certificate provisioning (optional, can use OpenShift service-ca) |
| OpenShift Service Mesh | 2.x | No | Service mesh for component networking (required for KServe) |
| Addon Operator | 0.0.0-20230919043633 | No | Managed OpenShift addon integration (for OSD/ROSA deployments) |

### Internal ODH/RHOAI Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| ODH Dashboard | Manifest Deployment | Deploys dashboard UI for data science workspace management |
| KServe | Manifest Deployment | Deploys single-model serving infrastructure with service mesh integration |
| ModelMesh Serving | Manifest Deployment | Deploys multi-model serving infrastructure |
| Data Science Pipelines | Manifest Deployment | Deploys Kubeflow Pipelines for ML workflow orchestration |
| CodeFlare | Manifest Deployment | Deploys distributed computing stack for Ray workloads |
| Ray | Manifest Deployment | Deploys Ray operator for distributed Python computing |
| Workbenches | Manifest Deployment | Deploys Jupyter notebook controller and related resources |
| TrustyAI | Manifest Deployment | Deploys AI explainability and fairness tools (deprecated in RHOAI 2.7+) |

## Network Architecture

### Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| controller-manager-metrics-service | ClusterIP | 8443/TCP | 8080 | HTTPS | TLS (kube-rbac-proxy) | Bearer Token | Internal |

### Ingress

No direct ingress - operator is internal only. Component ingress is managed by deployed components (e.g., Dashboard route).

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token | CRD reconciliation, resource management |
| Git Repositories (optional) | 443/TCP | HTTPS | TLS 1.2+ | None | Fetch component manifests from custom git repos (devFlags.manifestsUri) |
| Container Registries | 443/TCP | HTTPS | TLS 1.2+ | Pull Secrets | Pull component images during deployment |
| OpenShift Monitoring | 9091/TCP | HTTP | None | ServiceAccount Token | Push metrics to user-workload monitoring |

## Security

### RBAC - Cluster Roles

| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|
| controller-manager-role | datasciencecluster.opendatahub.io | datascienceclusters | get, list, watch, create, update, patch, delete |
| controller-manager-role | dscinitialization.opendatahub.io | dscinitializations | get, list, watch, create, update, patch, delete |
| controller-manager-role | features.opendatahub.io | featuretrackers | get, list, watch, create, update, patch, delete |
| controller-manager-role | "" | deployments, services, configmaps, secrets, serviceaccounts | * (all verbs) |
| controller-manager-role | apps | deployments, statefulsets, replicasets | * (all verbs) |
| controller-manager-role | rbac.authorization.k8s.io | roles, rolebindings, clusterroles, clusterrolebindings | * (all verbs) |
| controller-manager-role | route.openshift.io | routes | create, delete, get, list, patch, update, watch |
| controller-manager-role | networking.k8s.io | networkpolicies | create, delete, get, list, patch, update, watch |
| controller-manager-role | apiextensions.k8s.io | customresourcedefinitions | create, delete, get, list, patch, watch |
| controller-manager-role | admissionregistration.k8s.io | validatingwebhookconfigurations, mutatingwebhookconfigurations | create, delete, get, list, patch, update, watch |
| controller-manager-role | monitoring.coreos.com | servicemonitors, prometheusrules | create, delete, get, list, patch, update, watch |
| controller-manager-role | operators.coreos.com | subscriptions, clusterserviceversions | get, list, watch |
| controller-manager-role | oauth.openshift.io | oauthclients | create, delete, get, list, patch, update, watch |
| controller-manager-role | image.openshift.io | imagestreams | create, delete, get, list, patch, update, watch |
| controller-manager-role | build.openshift.io | buildconfigs | create, delete, get, list, patch, update, watch |
| controller-manager-role | authentication.k8s.io | tokenreviews | create |
| controller-manager-role | authorization.k8s.io | subjectaccessreviews | create |
| auth-proxy-client-clusterrole | authentication.k8s.io | tokenreviews | create |
| auth-proxy-client-clusterrole | authorization.k8s.io | subjectaccessreviews | create |
| leader-election-role | "" | configmaps | get, list, watch, create, update, patch, delete |
| leader-election-role | coordination.k8s.io | leases | get, list, watch, create, update, patch, delete |

### RBAC - Role Bindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| controller-manager-rolebinding | redhat-ods-operator (system) | controller-manager-role (ClusterRole) | controller-manager |
| leader-election-rolebinding | redhat-ods-operator (system) | leader-election-role | controller-manager |
| auth-proxy-rolebinding | redhat-ods-operator (system) | auth-proxy-role | controller-manager |

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| webhook-server-cert | kubernetes.io/tls | Webhook admission controller TLS certificate | cert-manager or service-ca | Yes (cert-manager) |
| oauth-client-secrets | Opaque | OAuth client secrets for component authentication | SecretGenerator controller | No |
| kube-rbac-proxy-tls | kubernetes.io/tls | TLS for metrics service authentication proxy | service-ca operator | Yes |

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| /metrics | GET | Bearer Token (ServiceAccount JWT) | kube-rbac-proxy sidecar | Requires auth-proxy-client-clusterrole (tokenreviews, subjectaccessreviews) |
| /healthz | GET | None | None | Publicly accessible within cluster |
| /readyz | GET | None | None | Publicly accessible within cluster |
| Kubernetes API (client) | All | ServiceAccount Token | Kubernetes RBAC | controller-manager ServiceAccount with controller-manager-role |

### Network Policies

| Policy Name | Namespace | Pod Selector | Ingress Rules |
|-------------|-----------|--------------|---------------|
| redhat-ods-operator | redhat-ods-operator | control-plane: controller-manager | From: redhat-ods-monitoring, openshift-monitoring, openshift-user-workload-monitoring, generated namespaces (opendatahub.io/generated-namespace=true) |
| redhat-ods-applications | redhat-ods-applications | All pods | Ports: 8443/TCP, 8080/TCP, 8081/TCP, 5432/TCP, 8082/TCP, 8099/TCP, 8181/TCP; From: redhat-ods-monitoring, openshift-monitoring |
| redhat-ods-monitoring | redhat-ods-monitoring | All pods | From: redhat-ods-applications, openshift-monitoring |

## Data Flows

### Flow 1: DataScienceCluster Creation

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User/GitOps | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | User credentials |
| 2 | Kubernetes API | Operator (watch) | Internal | In-memory | N/A | ServiceAccount token |
| 3 | Operator | Kubernetes API (read DSCInitialization) | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount token |
| 4 | Operator | Git repo (optional, if devFlags.manifestsUri set) | 443/TCP | HTTPS | TLS 1.2+ | None |
| 5 | Operator | Kubernetes API (create component resources) | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount token |
| 6 | Operator | Kubernetes API (update status) | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount token |

### Flow 2: Metrics Collection

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Prometheus | controller-manager-metrics-service | 8443/TCP | HTTPS | TLS (kube-rbac-proxy) | Bearer Token |
| 2 | kube-rbac-proxy | Kubernetes API (TokenReview) | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount token |
| 3 | kube-rbac-proxy | Operator metrics endpoint | 8080/TCP | HTTP | None (localhost) | None (proxied) |

### Flow 3: Component Health Monitoring

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Kubelet | Operator /healthz | 8081/TCP | HTTP | None | None |
| 2 | Kubelet | Operator /readyz | 8081/TCP | HTTP | None | None |

### Flow 4: Secret Generation

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Component manifest | Kubernetes API (create Secret with annotation) | 6443/TCP | HTTPS | TLS 1.2+ | Operator ServiceAccount |
| 2 | Kubernetes API | SecretGenerator controller (watch) | Internal | In-memory | N/A | ServiceAccount token |
| 3 | SecretGenerator | Kubernetes API (create generated secret) | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount token |
| 4 | SecretGenerator | Kubernetes API (update OAuthClient if needed) | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount token |

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| Kubernetes API Server | REST API | 6443/TCP | HTTPS | TLS 1.2+ | Primary control plane integration for all resource operations |
| Prometheus (User Workload Monitoring) | Metrics Pull | 8443/TCP | HTTPS | TLS (kube-rbac-proxy) | Operator and component health metrics |
| OpenShift Service Mesh Control Plane | API (Kubernetes CRDs) | 6443/TCP | HTTPS | TLS 1.2+ | Configure service mesh for KServe (creates ServiceMeshMember, etc.) |
| OpenShift OAuth Server | OAuth Client API | 6443/TCP | HTTPS | TLS 1.2+ | Register OAuth clients for component authentication |
| OpenShift Image Registry | Image Pull | 5000/TCP | HTTPS | TLS 1.2+ | Pull component container images from internal registry |
| Git Repository (optional) | HTTPS | 443/TCP | HTTPS | TLS 1.2+ | Fetch custom component manifests when devFlags.manifestsUri configured |
| Addon Operator (OSD/ROSA) | API (Kubernetes CRDs) | 6443/TCP | HTTPS | TLS 1.2+ | Integration with managed OpenShift addon framework |

## Deployment Architecture

### Namespaces

| Namespace | Purpose | Created By |
|-----------|---------|------------|
| redhat-ods-operator | Operator deployment namespace | OLM or manual deployment |
| redhat-ods-applications | Default namespace for data science applications | DSCInitialization controller |
| redhat-ods-monitoring | Monitoring stack namespace (Prometheus, Alertmanager, etc.) | DSCInitialization controller |
| istio-system | Service mesh control plane (if enabled) | DSCInitialization controller or pre-existing |

### Operator Deployment

- **Replicas**: 1 (leader election enabled)
- **Image Pull Policy**: Always
- **Security Context**: runAsNonRoot: true, allowPrivilegeEscalation: false, drop ALL capabilities
- **Resource Requests**: 500m CPU, 256Mi memory
- **Resource Limits**: 500m CPU, 4Gi memory
- **Leader Election**: Enabled (lease name: 07ed84f7.opendatahub.io)
- **Health Probes**: Liveness (15s initial, 20s period), Readiness (5s initial, 10s period)

## Component Lifecycle Management

### Managed Components

The operator supports the following components, each with independent `managementState` control:

1. **Dashboard** - Web UI for data science project management
2. **Workbenches** - Jupyter notebook environments with multiple image options
3. **Data Science Pipelines** - Kubeflow Pipelines for ML workflow orchestration
4. **KServe** - Single-model serving with service mesh integration
5. **ModelMesh Serving** - Multi-model serving for high-scale inference
6. **CodeFlare** - Distributed workload management for Ray
7. **Ray** - Distributed Python computing framework
8. **TrustyAI** - AI explainability and fairness (deprecated in RHOAI 2.7+)

### Management States

- **Managed**: Operator actively deploys and maintains component
- **Removed**: Operator removes component if installed

### Component Deployment Process

1. DSCInitialization creates platform infrastructure (namespaces, service mesh, monitoring)
2. DataScienceCluster reconciler evaluates each component's managementState
3. For Managed components:
   - Fetch manifests from odh-manifests directory or custom git repo
   - Apply Kustomize transformations (namespace, image overrides)
   - Deploy resources to cluster
   - Update component status conditions
4. For Removed components:
   - Clean up component resources
   - Update status to reflect removal

## Recent Changes

| Version | Date | Changes |
|---------|------|---------|
| v1.6.0-441 | 2024-02-20 | - Remove TrustyAI installation in downstream RHOAI<br>- Set TrustyAI status to false in DataScienceCluster |
| v1.6.0-436 | 2024-02-14 | - Revert Kueue dependency checks<br>- Fix KServe manual/unmanaged installation handling |
| v1.6.0-429 | 2024-02-09 | - Cleanup logic for deprecated model monitoring stack deletion<br>- Fix operator uninstallation cleanup process |
| v1.6.0-427 | 2024-02-08 | - Fix rhods-monitor-federation2 creation (do not create)<br>- Add Kueue to initialization resource section |
| v1.6.0-426 | 2024-02-07 | - Fix TrustyAI Prometheus configuration application |
| v1.6.0-425 | 2024-02-06 | - Upstream variable name changes cherry-picked |

## Configuration Options

### DataScienceCluster CRD

```yaml
apiVersion: datasciencecluster.opendatahub.io/v1
kind: DataScienceCluster
metadata:
  name: default-dsc
spec:
  components:
    dashboard:
      managementState: Managed  # or Removed
      devFlags:  # Optional
        manifests:
          - uri: https://github.com/org/repo/tarball/branch
            contextDir: manifests
            sourcePath: base
    # ... similar structure for other components
```

### DSCInitialization CRD

```yaml
apiVersion: dscinitialization.opendatahub.io/v1
kind: DSCInitialization
metadata:
  name: default-dsci
spec:
  applicationsNamespace: redhat-ods-applications  # Non-configurable
  monitoring:
    managementState: Managed  # or Removed
    namespace: redhat-ods-monitoring
  serviceMesh:
    controlPlane:
      name: data-science-smcp
      namespace: istio-system
      metricsCollection: Istio  # or None
    managementState: Managed  # or Removed
  devFlags:  # Development/testing only
    manifestsUri: https://github.com/org/odh-manifests/tarball/branch
```

## Troubleshooting

### Common Issues

1. **Component deployment stuck in Progressing**
   - Check operator logs: `oc logs -n redhat-ods-operator deployment/rhods-operator`
   - Verify network policies allow required traffic
   - Check for resource quota limits in target namespace

2. **Multiple DSC/DSCI instances**
   - Only one instance of each is allowed cluster-wide
   - Operator will set error condition on duplicate instances
   - Delete duplicate instances to resolve

3. **Service mesh integration failures**
   - Verify OpenShift Service Mesh operator is installed
   - Check ServiceMeshControlPlane exists in configured namespace
   - Ensure operator has RBAC to create ServiceMeshMember resources

4. **Custom manifests not applied**
   - Verify `devFlags.manifestsUri` is accessible from operator pod
   - Check git repository is public or credentials are configured
   - Review operator logs for manifest fetch errors

### Diagnostic Commands

```bash
# Check operator status
oc get deployment -n redhat-ods-operator rhods-operator
oc logs -n redhat-ods-operator deployment/rhods-operator

# Check CRD instances
oc get datasciencecluster -A
oc get dscinitialization -A
oc describe datasciencecluster default-dsc

# Check component deployments
oc get deployments -n redhat-ods-applications
oc get pods -n redhat-ods-applications

# Check monitoring stack
oc get prometheus -n redhat-ods-monitoring
oc get servicemonitor -n redhat-ods-operator

# Check network policies
oc get networkpolicies -n redhat-ods-operator
oc get networkpolicies -n redhat-ods-applications
```

## Performance Considerations

- **Reconciliation**: Operator uses controller-runtime with exponential backoff for retries
- **Leader Election**: Single active replica ensures no duplicate reconciliations
- **Resource Limits**: 4Gi memory limit accommodates large manifest sets during deployment
- **Namespace Watch**: Operator watches multiple namespaces for component resources
- **Status Updates**: Retries with conflict handling to avoid status update failures

## Security Considerations

- **Least Privilege**: Operator requires broad RBAC due to multi-component management (deployments, services, routes, CRDs, webhooks)
- **Network Isolation**: Network policies restrict ingress to operator pod (monitoring scraping only)
- **Secret Management**: Generated secrets use random data, no secrets stored in CRD specs
- **TLS**: Metrics endpoint uses kube-rbac-proxy with TLS for authenticated access
- **Webhook Security**: Admission webhooks use TLS certificates from cert-manager or service-ca
- **Container Security**: Non-root user, no privilege escalation, all capabilities dropped

## Upgrade Considerations

The operator includes upgrade logic in `pkg/upgrade/` to handle:

1. **Legacy operator migration**: Detects and migrates from v1 operator (kfdef-based)
2. **Component cleanup**: Removes deprecated resources (e.g., TrustyAI in RHOAI 2.7+)
3. **Operator uninstall**: Cleanup when deletion ConfigMap is present
4. **Resource version updates**: Updates existing resources to match new API versions

Upgrades are performed automatically when operator image is updated via OLM subscription.
