# Component: RHODS Operator (Red Hat OpenShift AI Operator)

## Metadata
- **Repository**: https://github.com/red-hat-data-services/rhods-operator.git
- **Version**: v1.6.0-556-g9f2b32973
- **Branch**: rhoai-2.9
- **Distribution**: RHOAI
- **Languages**: Go 1.19
- **Deployment Type**: Kubernetes Operator (Cluster-scoped)

## Purpose
**Short**: Primary operator for Red Hat OpenShift AI (RHOAI) that manages the lifecycle of data science components.

**Detailed**: The RHODS Operator is the core orchestration component for Red Hat OpenShift AI platform. It manages the deployment, configuration, and lifecycle of all data science components including workbenches, model serving, pipelines, and distributed computing frameworks. The operator uses two primary CRDs: DSCInitialization for platform-wide configuration (service mesh, monitoring, trusted CA bundles) and DataScienceCluster for enabling and configuring individual components. It integrates with OpenShift's service mesh, monitoring stack, and provides a unified management interface for data scientists and platform administrators. The operator supports both self-service deployment and managed configurations, with extensive RBAC controls and monitoring integration.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| DataScienceCluster Controller | Controller | Reconciles DataScienceCluster CR to deploy and manage component manifests |
| DSCInitialization Controller | Controller | Initializes platform infrastructure (service mesh, monitoring, namespaces) |
| SecretGenerator Controller | Controller | Generates and manages secrets required by components |
| CertConfigmapGenerator Controller | Controller | Generates and manages certificate ConfigMaps for TLS configurations |
| Component Reconcilers | Go Modules | Individual reconciliation logic for each data science component |
| Manifest Loader | Build-time System | Fetches and bundles component manifests from upstream repositories |
| Upgrade Manager | Runtime System | Handles migration from legacy KfDef-based deployments and version upgrades |

## APIs Exposed

### Custom Resource Definitions (CRDs)

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| datasciencecluster.opendatahub.io | v1 | DataScienceCluster | Cluster | Defines which data science components to deploy and their configurations |
| dscinitialization.opendatahub.io | v1 | DSCInitialization | Cluster | Configures platform infrastructure (service mesh, monitoring, namespaces) |
| features.opendatahub.io | v1 | FeatureTracker | Cluster | Tracks resources created via Features API for garbage collection |
| kfdef.apps.kubeflow.org | v1 | KfDef | Cluster | Legacy CRD for backward compatibility with ODH 1.x deployments |

### HTTP Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /metrics | GET | 8080/TCP | HTTP | None | ServiceAccount Token | Prometheus metrics endpoint (internal) |
| /healthz | GET | 8081/TCP | HTTP | None | None | Liveness probe endpoint |
| /readyz | GET | 8081/TCP | HTTP | None | None | Readiness probe endpoint |

### gRPC Services

| Service | Port | Protocol | Encryption | Auth | Purpose |
|---------|------|----------|------------|------|---------|
| N/A | N/A | N/A | N/A | N/A | Operator does not expose gRPC services |

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| Kubernetes | 1.23+ | Yes | Container orchestration platform |
| OpenShift | 4.12+ | Yes | Enterprise Kubernetes distribution with Routes and SCCs |
| Service Mesh Operator (Maistra/Istio) | 2.x | Conditional | Required for KServe, enhances security for all components |
| Serverless Operator (Knative) | 1.x | Conditional | Required for KServe model serving |
| Authorino Operator | 0.x | Conditional | Required for KServe authorization |
| Prometheus Operator | 0.x | No | Monitoring integration (optional but recommended) |
| Cert Manager | 1.x | No | Optional certificate management (can use service-ca) |

### Internal ODH Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| ODH Dashboard | Deploys CRs | Manages OdhApplication, OdhDocument, AcceleratorProfile CRs |
| Data Science Pipelines | Monitors CRs | Watches DataSciencePipelinesApplication CRs |
| KServe | Manages Resources | Deploys ServingRuntimes, InferenceServices, ClusterServingRuntimes |
| ModelMesh Serving | Deploys Manifests | Deploys Seldon-based model serving infrastructure |
| Workbenches | Manages Resources | Deploys Notebook CRs and supporting resources |
| CodeFlare | Monitors Operators | Integrates with CodeFlare operator (MCAD, InstaScale) |
| Ray | Monitors CRs | Watches RayClusters, RayJobs, RayServices |
| Kueue | Monitors Resources | Watches Kueue queue and workload CRs |

## Network Architecture

### Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| controller-manager-metrics-service | ClusterIP | 8443/TCP | 8080 | HTTP | None | ServiceAccount Token | Internal |

### Ingress

| Name | Type | Hosts | Port | Protocol | Encryption | TLS Mode | Exposure |
|------|------|-------|------|----------|------------|----------|----------|
| N/A | N/A | N/A | N/A | N/A | N/A | N/A | Operator does not expose external ingress |

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token | CRUD operations on cluster resources |
| Component Git Repositories | 443/TCP | HTTPS | TLS 1.2+ | None | Fetching manifests at build time (if using devFlags) |
| Container Registries | 443/TCP | HTTPS | TLS 1.2+ | Pull Secrets | Pulling component images |

## Security

### RBAC - Cluster Roles

| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|
| controller-manager-role | datasciencecluster.opendatahub.io | datascienceclusters, datascienceclusters/status, datascienceclusters/finalizers | create, delete, get, list, patch, update, watch |
| controller-manager-role | dscinitialization.opendatahub.io | dscinitializations, dscinitializations/status, dscinitializations/finalizers | create, delete, get, list, patch, update, watch |
| controller-manager-role | features.opendatahub.io | featuretrackers, featuretrackers/status | create, delete, get, list, patch, update, watch |
| controller-manager-role | "" | configmaps, secrets, services, serviceaccounts, namespaces, events, pods, persistentvolumeclaims | create, delete, get, list, patch, update, watch |
| controller-manager-role | apps | deployments, replicasets, statefulsets, deployments/finalizers | * |
| controller-manager-role | rbac.authorization.k8s.io | clusterroles, clusterrolebindings, roles, rolebindings | * |
| controller-manager-role | route.openshift.io | routes | create, delete, get, list, patch, update, watch |
| controller-manager-role | networking.k8s.io | networkpolicies, ingresses | create, delete, get, list, patch, update, watch |
| controller-manager-role | networking.istio.io | virtualservices, gateways, envoyfilters | * |
| controller-manager-role | security.istio.io | authorizationpolicies | * |
| controller-manager-role | maistra.io | servicemeshcontrolplanes, servicemeshmemberrolls, servicemeshmembers | create, get, list, patch, update, use, watch |
| controller-manager-role | serving.kserve.io | inferenceservices, servingruntimes, clusterservingruntimes, predictors, trainedmodels, inferencegraphs | create, delete, get, list, patch, update, watch |
| controller-manager-role | serving.knative.dev | services, services/status, services/finalizers | create, delete, list, patch, update, watch |
| controller-manager-role | monitoring.coreos.com | servicemonitors, podmonitors, prometheusrules, prometheuses, alertmanagers | create, delete, deletecollection, get, list, patch, update, watch |
| controller-manager-role | operators.coreos.com | clusterserviceversions, subscriptions, catalogsources | delete, get, list, update, watch |
| controller-manager-role | apiextensions.k8s.io | customresourcedefinitions | create, delete, get, list, patch, watch |
| controller-manager-role | authorization.openshift.io | clusterroles, clusterrolebindings, roles, rolebindings | * |
| controller-manager-role | security.openshift.io | securitycontextconstraints | * |
| controller-manager-role | console.openshift.io | consolelinks, odhquickstarts | create, delete, get, patch, list |
| controller-manager-role | oauth.openshift.io | oauthclients | create, delete, get, list, patch, update, watch |
| controller-manager-role | image.openshift.io | imagestreams, imagestreamtags | create, delete, get, list, patch, update, watch |
| controller-manager-role | build.openshift.io | buildconfigs, builds, buildconfigs/instantiate | create, delete, list, patch, watch |
| controller-manager-role | ray.io | rayclusters, rayjobs, rayservices | create, delete, get, list, patch, update, watch |
| controller-manager-role | workload.codeflare.dev | appwrappers, queuejobs, appwrappers/status, appwrappers/finalizers | create, delete, deletecollection, get, list, patch, update, watch |
| controller-manager-role | datasciencepipelinesapplications.opendatahub.io | datasciencepipelinesapplications, datasciencepipelinesapplications/status, datasciencepipelinesapplications/finalizers | create, delete, get, list, patch, update, watch |
| controller-manager-role | kubeflow.org | * | * |
| controller-manager-role | tekton.dev | * | * |

### RBAC - Role Bindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| controller-manager-rolebinding | Cluster-wide | controller-manager-role | controller-manager (redhat-ods-operator ns) |

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| controller-manager-sa-token | kubernetes.io/service-account-token | ServiceAccount authentication token | Kubernetes | Yes |
| Various component secrets | Opaque | Component-specific credentials (generated by SecretGenerator) | SecretGenerator controller | No |
| TLS certificates | kubernetes.io/tls | Component TLS certificates | service-ca or cert-manager | Yes (service-ca) |

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| /metrics | GET | ServiceAccount Token (Bearer) | Kubernetes RBAC | Requires prometheus ServiceAccount or cluster-monitoring-view role |
| /healthz | GET | None | None | Publicly accessible within cluster |
| /readyz | GET | None | None | Publicly accessible within cluster |
| Kubernetes API operations | ALL | ServiceAccount Token (Bearer) | Kubernetes API Server | Enforced via ClusterRole/ClusterRoleBinding |

## Data Flows

### Flow 1: Component Deployment

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User/Admin | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | User credentials (Bearer Token/X.509) |
| 2 | Kubernetes API | RHODS Operator | N/A | In-process | N/A | Watch notification |
| 3 | RHODS Operator | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 4 | RHODS Operator | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |

**Description**: User creates/updates DataScienceCluster CR → Operator watches CR → Operator applies component manifests → Component resources deployed

### Flow 2: Platform Initialization

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | RHODS Operator (startup) | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 2 | RHODS Operator | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 3 | RHODS Operator | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 4 | RHODS Operator | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |

**Description**: Operator startup → Check for existing DSCI → Create default DSCI if missing → Apply infrastructure resources (namespaces, service mesh members, network policies, monitoring)

### Flow 3: Monitoring Metrics Collection

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Prometheus | controller-manager-metrics-service | 8443/TCP | HTTP | None | ServiceAccount Token |
| 2 | controller-manager-metrics-service | Operator Pod | 8080/TCP | HTTP | None | Internal |

**Description**: Prometheus scrapes metrics from operator service → Service forwards to operator pod metrics endpoint

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| Kubernetes API Server | REST API | 6443/TCP | HTTPS | TLS 1.2+ | All CRUD operations on cluster resources |
| Service Mesh Control Plane | CRD Management | 6443/TCP | HTTPS | TLS 1.2+ | Create/manage ServiceMeshMember, ServiceMeshControlPlane |
| Prometheus (OCP Monitoring) | Metrics Scraping | 8080/TCP | HTTP | None | Operator health and performance metrics |
| Component Operators (KServe, CodeFlare, etc.) | CRD Management | 6443/TCP | HTTPS | TLS 1.2+ | Deploy and watch component-specific CRs |
| ODH Dashboard | ConfigMap/CR Management | 6443/TCP | HTTPS | TLS 1.2+ | Deploy dashboard configuration and custom resources |

## Component Manifest Management

### Manifest Sources

The operator manages manifests for the following components:

| Component | Source | Management |
|-----------|--------|------------|
| Dashboard | odh-manifests/dashboard | Kustomize-based deployment |
| Workbenches | odh-manifests/workbenches | Includes notebook controllers, OAuth proxy |
| Data Science Pipelines | odh-manifests/data-science-pipelines | Tekton and Argo-based pipelines |
| KServe | odh-manifests/kserve | Model serving with Knative |
| ModelMesh Serving | odh-manifests/modelmesh | Alternative model serving (Seldon-based) |
| CodeFlare | odh-manifests/codeflare | Distributed workload management (MCAD, InstaScale) |
| Ray | odh-manifests/ray | Ray operator for distributed computing |
| Kueue | odh-manifests/kueue | Job queueing system |
| Monitoring | config/monitoring | Prometheus, Grafana, Alertmanager configs |

### Manifest Loading Strategy

At **build time**, the operator fetches component manifests using `get_all_manifests.sh` script, which clones upstream repositories and bundles manifests into `/opt/manifests` in the container image. At **runtime**, the operator applies these manifests using kustomize with component-specific overlays and parameter substitution.

## Recent Changes

| Commit | Date | Changes |
|--------|------|---------|
| 9f2b329 | 2026-03 | - Merge pull request for JIRA/6989 fix |
| 2a43cfa | 2026-03 | - Add basic alerting for Kueue (#258) |
| bfd7be5 | 2026-03 | - Skip reconcile on deployment resources for model serving |
| 896cd5e | 2026-03 | - Revert revert: Prepare CodeFlare, Ray, Kueue for GA |
| 17c131a | 2026-03 | - Add watch to deleted namespaces |
| 919d746 | 2026-03 | - Merge pull request for 2.9 fix |
| 4a10605 | 2026-03 | - Remove duplicated call to UpdateFromLegacyVersion |
| 5820621 | 2026-03 | - Remove deprecated namespace handling |
| 0d58961 | 2026-03 | - Fix linter issues |
| c2daf91 | 2026-03 | - Sync upstream changes for 2.9.0 |
| b982013 | 2026-03 | - Update condition to avoid upgrade on reconcile |
| 5760b2a | 2026-03 | - Fix DSC error when DSCI CR missing (#971) |
| cc3e2fb | 2026-03 | - Update CSV annotation for features |
| 9ed9a0b | 2026-03 | - Add fixes for namespace watch |
| 386b2f1 | 2026-03 | - Update upgrade.go |
| 03a1b01 | 2026-03 | - Ray: Cleanup opendatahub namespace |
| 56b1946 | 2026-03 | - Sync upstream changes for 2.9.0 |
| aaae271 | 2026-03 | - Add watch fixes |
| 283fa8e | 2026-03 | - Fix linter issues |

## Deployment Architecture

### Namespaces

| Namespace | Purpose | Created By |
|-----------|---------|------------|
| redhat-ods-operator | Operator deployment | OLM/Manual installation |
| redhat-ods-applications | Component applications | DSCInitialization controller |
| redhat-ods-monitoring | Monitoring stack | DSCInitialization controller |
| istio-system | Service mesh control plane | Service Mesh Operator (if enabled) |

### Security Context

The operator runs with the following security constraints:
- **Run as non-root**: Yes (UID 1001)
- **Privilege escalation**: Disabled
- **Capabilities**: All dropped
- **SELinux**: Enforced (OpenShift default)
- **Seccomp**: RuntimeDefault (Kubernetes 1.19+)

### Resource Limits

| Resource | Limit | Request |
|----------|-------|---------|
| CPU | 500m | 500m |
| Memory | 4Gi | 256Mi |

## Operational Considerations

### High Availability

- **Leader Election**: Enabled (lease-based)
- **Replicas**: 1 (only one active, leader election prevents split-brain)
- **Recovery**: Automatic pod restart on failure

### Upgrade Strategy

- **Zero-downtime**: Operator supports rolling upgrades
- **Legacy migration**: Automatic migration from KfDef v1 to DSC v1
- **Version compatibility**: Maintains backward compatibility with DSCI/DSC CRs

### Monitoring & Alerting

- **Metrics**: Exposed on /metrics endpoint (port 8080)
- **Health checks**: Liveness (/healthz) and Readiness (/readyz) probes
- **Service monitors**: Configured for component federation to cluster monitoring
- **Alerting**: Integrates with OpenShift cluster monitoring and RHODS-specific Prometheus

### Troubleshooting

Common issues and resolutions:
1. **Multiple DSC instances**: Only one DataScienceCluster CR allowed per cluster
2. **DSCI missing**: Operator auto-creates default DSCI on startup
3. **Component conflicts**: Check component ManagementState (Managed/Removed)
4. **Service Mesh issues**: Verify ServiceMeshMember created in component namespaces
5. **Permission errors**: Verify ClusterRoleBinding for controller-manager ServiceAccount

## Future Enhancements

Based on code comments and TODO markers:
- Enhanced metrics collection for operator performance
- Improved seccomp profile support for Kubernetes 1.19+
- Enhanced resource configuration customization
- Extended monitoring and alerting capabilities
