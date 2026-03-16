# Component: RHODS Operator

## Metadata
- **Repository**: https://github.com/red-hat-data-services/rhods-operator.git
- **Version**: 2.9.0
- **Branch**: rhoai-2.10
- **Distribution**: RHOAI
- **Languages**: Go 1.21
- **Deployment Type**: Kubernetes Operator

## Purpose
**Short**: RHODS Operator is the primary platform operator for Red Hat OpenShift AI that orchestrates deployment and lifecycle management of data science and ML components.

**Detailed**: The RHODS Operator (Red Hat OpenShift AI Operator) serves as the control plane for the OpenShift AI platform. It enables data science teams to deploy and manage a comprehensive suite of ML/AI tools including Jupyter notebooks, model serving frameworks, data science pipelines, distributed training, and workload orchestration. The operator utilizes two primary Custom Resource Definitions (CRDs): `DataScienceCluster` for component selection and configuration, and `DSCInitialization` for platform initialization including service mesh integration, monitoring setup, and namespace management. The operator dynamically fetches component-specific Kustomize manifests from git repositories at build time or runtime (via devFlags), allowing for flexible deployment patterns across ODH and RHOAI distributions. It manages cross-namespace resources, integrates with OpenShift Service Mesh for unified authentication and networking, and provides comprehensive monitoring through Prometheus and Alertmanager integration. The operator implements a declarative reconciliation model where users specify desired component states (Managed/Removed), and the operator continuously ensures actual state matches desired state through component-specific controllers.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| DataScienceCluster Controller | Kubernetes Controller | Reconciles DataScienceCluster CRs to deploy and manage data science components |
| DSCInitialization Controller | Kubernetes Controller | Initializes platform infrastructure including namespaces, service mesh, monitoring, and trusted CA bundles |
| FeatureTracker Controller | Kubernetes Controller | Tracks resources created via internal Features API for cross-namespace garbage collection |
| SecretGenerator Controller | Kubernetes Controller | Generates and manages secrets required by platform components |
| CertConfigMapGenerator Controller | Kubernetes Controller | Generates and manages TLS certificate ConfigMaps for component communication |
| Status Controller | Kubernetes Controller | Updates and maintains status conditions for operator-managed resources |
| Webhook Server | Admission Webhook | Provides CRD conversion webhooks for API version compatibility |
| Metrics Server | HTTP Service | Exposes Prometheus metrics for operator monitoring |

## APIs Exposed

### Custom Resource Definitions (CRDs)

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| datasciencecluster.opendatahub.io | v1 | DataScienceCluster | Cluster | Defines which data science components to deploy and their configuration |
| dscinitialization.opendatahub.io | v1 | DSCInitialization | Cluster | Initializes platform infrastructure including namespaces, service mesh, monitoring |
| features.opendatahub.io | v1 | FeatureTracker | Cluster | Tracks resources for cross-namespace garbage collection via Features API |

### HTTP Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /metrics | GET | 8080/TCP | HTTP | None | None | Prometheus metrics scraping endpoint |
| /healthz | GET | 8081/TCP | HTTP | None | None | Liveness probe for operator health |
| /readyz | GET | 8081/TCP | HTTP | None | None | Readiness probe for operator availability |
| /convert | POST | 9443/TCP | HTTPS | TLS 1.2+ | mTLS | CRD conversion webhook for API version migration |

### gRPC Services

| Service | Port | Protocol | Encryption | Auth | Purpose |
|---------|------|----------|------------|------|---------|
| N/A | N/A | N/A | N/A | N/A | No gRPC services exposed |

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| Kubernetes/OpenShift | 1.25+ | Yes | Container orchestration platform |
| OpenShift Service Mesh | 2.x | Conditional | Required for Kserve and enhanced user experience with SSO |
| Authorino Operator | Latest | Conditional | Required for Kserve authentication and authorization |
| OpenShift Serverless | Latest | Conditional | Required for Kserve serverless deployment mode |
| OpenShift Pipelines | Latest | Conditional | Required for DataSciencePipelines component |
| Prometheus Operator | Latest | No | For monitoring stack when monitoring is enabled |
| cert-manager | Latest | No | For automated TLS certificate management |

### Internal ODH Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| odh-dashboard | Kustomize Manifests | Web UI for platform management and resource creation |
| notebook-controller | Kustomize Manifests | Manages Jupyter notebook lifecycle and workspace resources |
| odh-notebook-controller | Kustomize Manifests | Enhanced notebook controller with ODH-specific features |
| data-science-pipelines-operator | Kustomize Manifests | Deploys and manages Kubeflow Pipelines for ML workflows |
| kserve | Kustomize Manifests | Model serving infrastructure for serverless inference |
| model-mesh-serving | Kustomize Manifests | Multi-model serving infrastructure with mesh architecture |
| codeflare-operator | Kustomize Manifests | Distributed workload orchestration and scaling |
| kuberay-operator | Kustomize Manifests | Ray cluster management for distributed Python workloads |
| training-operator | Kustomize Manifests | Distributed training job orchestration (TFJob, PyTorchJob, etc.) |
| trustyai-service-operator | Kustomize Manifests | AI fairness, bias detection, and explainability services |
| kueue | Kustomize Manifests | Multi-tenant job queueing and resource quota management |

## Network Architecture

### Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| controller-manager-metrics-service | ClusterIP | 8443/TCP | 8080 | HTTP | None | kube-rbac-proxy | Internal |
| webhook-service | ClusterIP | 9443/TCP | 9443 | HTTPS | TLS 1.2+ | mTLS | Internal |

### Ingress

| Name | Type | Hosts | Port | Protocol | Encryption | TLS Mode | Exposure |
|------|------|-------|------|----------|------------|----------|----------|
| N/A | N/A | N/A | N/A | N/A | N/A | N/A | No external ingress configured |

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| github.com | 443/TCP | HTTPS | TLS 1.2+ | None | Fetch component manifests at build/runtime |
| quay.io | 443/TCP | HTTPS | TLS 1.2+ | None | Pull container images for managed components |
| registry.access.redhat.com | 443/TCP | HTTPS | TLS 1.2+ | None | Pull base container images |
| Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token | Manage cluster resources across namespaces |

## Security

### RBAC - Cluster Roles

| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|
| controller-manager-role | datasciencecluster.opendatahub.io | datascienceclusters, datascienceclusters/finalizers, datascienceclusters/status | create, delete, get, list, patch, update, watch |
| controller-manager-role | dscinitialization.opendatahub.io | dscinitializations, dscinitializations/finalizers, dscinitializations/status | create, delete, get, list, patch, update, watch |
| controller-manager-role | features.opendatahub.io | featuretrackers, featuretrackers/status | create, delete, get, list, patch, update, watch |
| controller-manager-role | "" | namespaces, namespaces/finalizers | create, delete, get, list, patch, update, watch |
| controller-manager-role | "" | configmaps, configmaps/status | create, delete, get, list, patch, update, watch |
| controller-manager-role | "" | secrets, secrets/finalizers | create, delete, get, list, patch, update, watch |
| controller-manager-role | "" | services, services/finalizers | create, delete, get, list, patch, update, watch |
| controller-manager-role | "" | serviceaccounts | create, delete, get, list, patch, update, watch |
| controller-manager-role | apps | deployments, deployments/finalizers | create, delete, get, list, patch, update, watch |
| controller-manager-role | apps | statefulsets | create, delete, get, list, patch, update, watch |
| controller-manager-role | batch | jobs, jobs/status | create, delete, get, list, patch, update, watch |
| controller-manager-role | rbac.authorization.k8s.io | roles, rolebindings, clusterroles, clusterrolebindings | create, delete, get, list, patch, update, watch |
| controller-manager-role | route.openshift.io | routes | create, delete, get, list, patch, update, watch |
| controller-manager-role | networking.k8s.io | networkpolicies | create, delete, get, list, patch, update, watch |
| controller-manager-role | admissionregistration.k8s.io | mutatingwebhookconfigurations, validatingwebhookconfigurations | create, delete, get, list, patch, update, watch |
| controller-manager-role | apiextensions.k8s.io | customresourcedefinitions | create, delete, get, list, patch, watch |
| controller-manager-role | operators.coreos.com | subscriptions, clusterserviceversions | create, delete, get, list, patch, update, watch |
| controller-manager-role | maistra.io | servicemeshcontrolplanes, servicemeshmemberrolls, servicemeshmembers | create, delete, get, list, patch, update, watch |
| controller-manager-role | serving.kserve.io | inferenceservices, servingruntimes | create, delete, get, list, patch, update, watch |
| controller-manager-role | serving.knative.dev | services, knativeservings | create, delete, get, list, patch, update, watch |
| controller-manager-role | authorino.kuadrant.io | authconfigs | create, delete, get, list, patch, update, watch |
| controller-manager-role | monitoring.coreos.com | servicemonitors, prometheuses, alertmanagers | create, delete, get, list, patch, update, watch |
| controller-manager-role | cert-manager.io | certificates, issuers | create, patch |
| datasciencecluster-editor-role | datasciencecluster.opendatahub.io | datascienceclusters | create, delete, get, list, patch, update, watch |
| datasciencecluster-viewer-role | datasciencecluster.opendatahub.io | datascienceclusters | get, list, watch |
| dscinitialization-editor-role | dscinitialization.opendatahub.io | dscinitializations | create, delete, get, list, patch, update, watch |
| dscinitialization-viewer-role | dscinitialization.opendatahub.io | dscinitializations | get, list, watch |

### RBAC - Role Bindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| controller-manager-rolebinding | All Namespaces | controller-manager-role (ClusterRole) | controller-manager |

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| webhook-server-cert | kubernetes.io/tls | TLS certificate for webhook server | cert-manager or operator | Yes |
| controller-manager-token | kubernetes.io/service-account-token | ServiceAccount authentication token | Kubernetes | Yes |

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| /convert | POST | mTLS client certificates | Kubernetes API Server | Only API server can call webhook endpoints |
| /metrics | GET | kube-rbac-proxy | kube-rbac-proxy sidecar | Requires valid ServiceAccount token with metrics read permission |
| Kubernetes API | ALL | ServiceAccount Token (JWT) | Kubernetes API Server | RBAC policies enforced by cluster |

## Data Flows

### Flow 1: DataScienceCluster Component Deployment

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User/GitOps | Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | User credentials or ServiceAccount Token |
| 2 | Kubernetes API Server | RHODS Operator | N/A | In-Memory | N/A | N/A |
| 3 | RHODS Operator | GitHub (manifests) | 443/TCP | HTTPS | TLS 1.2+ | None |
| 4 | RHODS Operator | Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 5 | Kubernetes API Server | Component Controllers | N/A | In-Memory | N/A | N/A |

### Flow 2: CRD Conversion Webhook

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User/Client | Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | User credentials |
| 2 | Kubernetes API Server | webhook-service | 9443/TCP | HTTPS | TLS 1.2+ | mTLS |
| 3 | webhook-service | Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | Response over existing connection |

### Flow 3: Metrics Collection

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Prometheus | kube-rbac-proxy | 8443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 2 | kube-rbac-proxy | Manager (metrics endpoint) | 8080/TCP | HTTP | None | Proxy validated token |

### Flow 4: Platform Initialization (DSCInitialization)

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Administrator | Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | Admin credentials |
| 2 | Kubernetes API Server | RHODS Operator | N/A | In-Memory | N/A | N/A |
| 3 | RHODS Operator | Kubernetes API Server (create namespaces) | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 4 | RHODS Operator | Service Mesh Operator (create SMCP) | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 5 | RHODS Operator | Prometheus Operator (create monitoring) | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| Kubernetes API Server | REST API | 6443/TCP | HTTPS | TLS 1.2+ | Primary control plane interface for resource management |
| Service Mesh Operator | Custom Resources | 6443/TCP | HTTPS | TLS 1.2+ | Deploy ServiceMeshControlPlane and ServiceMeshMemberRoll |
| Prometheus Operator | Custom Resources | 6443/TCP | HTTPS | TLS 1.2+ | Deploy ServiceMonitor, Prometheus, Alertmanager instances |
| Authorino Operator | Custom Resources | 6443/TCP | HTTPS | TLS 1.2+ | Deploy AuthConfig resources for authentication policies |
| KNative Serving Operator | Custom Resources | 6443/TCP | HTTPS | TLS 1.2+ | Deploy KnativeServing for Kserve serverless mode |
| OLM (Operator Lifecycle Manager) | Custom Resources | 6443/TCP | HTTPS | TLS 1.2+ | Manage operator subscriptions and CSVs |
| GitHub | Git/HTTPS | 443/TCP | HTTPS | TLS 1.2+ | Fetch component manifests during build or via devFlags |

## Recent Changes

| Version | Date | Changes |
|---------|------|---------|
| 2.9.0 | 2024 | - RHOAI 2.10 release branch<br>- Component lifecycle management improvements<br>- Service mesh integration enhancements<br>- Monitoring stack updates |

## Component Manifest Architecture

### Manifest Sources

The operator follows a unique architecture where component deployment manifests are not embedded in the operator code, but are dynamically sourced:

**Build-time Manifest Fetching:**
- Script: `get_all_manifests.sh` fetches Kustomize manifests from component git repositories
- Stored in: `/opt/manifests` inside operator container
- Components: dashboard, workbenches, datasciencepipelines, kserve, modelmeshserving, codeflare, ray, trustyai, trainingoperator, kueue

**Runtime Manifest Overrides:**
- Field: `spec.components.<component>.devFlags.manifests` in DataScienceCluster CR
- Allows: Specifying custom git repository URI, contextDir, and sourcePath
- Use case: Testing component changes without rebuilding operator

### Managed Components Configuration

| Component | Default Manifest Source | ServiceMesh Required | Dependencies |
|-----------|------------------------|----------------------|--------------|
| dashboard | opendatahub-io/odh-dashboard | No | None |
| workbenches | opendatahub-io/notebooks | No | None |
| datasciencepipelines | opendatahub-io/data-science-pipelines-operator | No | OpenShift Pipelines |
| kserve | kserve/kserve | Yes | Service Mesh, Authorino, Serverless |
| modelmeshserving | opendatahub-io/modelmesh-serving | No | None |
| codeflare | project-codeflare/codeflare-operator | No | None |
| ray | ray-project/kuberay | No | None |
| trustyai | trustyai-explainability/trustyai-service-operator | No | None |
| trainingoperator | kubeflow/training-operator | No | None |
| kueue | kubernetes-sigs/kueue | No | None |

## Deployment Architecture

### Operator Deployment

| Property | Value |
|----------|-------|
| Replicas | 1 (single instance, leader election enabled) |
| Namespace | openshift-operators (RHOAI) or opendatahub (ODH) |
| Service Account | controller-manager |
| Security Context | runAsNonRoot: true, allowPrivilegeEscalation: false |
| Resource Requests | CPU: 500m, Memory: 256Mi |
| Resource Limits | CPU: 500m, Memory: 4Gi |
| Health Checks | Liveness: /healthz:8081, Readiness: /readyz:8081 |

### Namespace Management

| Namespace | Purpose | Created By |
|-----------|---------|------------|
| redhat-ods-applications (RHOAI) or opendatahub (ODH) | Default namespace for data science applications and user workloads | DSCInitialization |
| redhat-ods-monitoring (RHOAI) or opendatahub-monitoring (ODH) | Monitoring stack (Prometheus, Alertmanager, Grafana) | DSCInitialization (if monitoring enabled) |
| istio-system | Service Mesh control plane | DSCInitialization (if serviceMesh enabled) |
| redhat-ods-applications-auth-provider | OAuth/OIDC authentication provider | DSCInitialization (if serviceMesh enabled) |

## Observability

### Metrics

| Metric Type | Exported | Port | Format |
|-------------|----------|------|--------|
| Controller Metrics | Yes | 8080/TCP | Prometheus |
| Reconciliation Duration | Yes | 8080/TCP | Prometheus Histogram |
| Reconciliation Errors | Yes | 8080/TCP | Prometheus Counter |
| API Server Requests | Yes | 8080/TCP | Prometheus Counter |

### Logging

| Level | Configuration | Location |
|-------|--------------|----------|
| INFO (default) | DSCI spec.devFlags.logmode: "production" | stdout/stderr |
| DEBUG | DSCI spec.devFlags.logmode: "development" | stdout/stderr |
| ERROR | DSCI spec.devFlags.logmode: "production" | stdout/stderr |

### Health Checks

| Endpoint | Port | Purpose | Check Type |
|----------|------|---------|------------|
| /healthz | 8081/TCP | Liveness probe - operator process health | HTTP GET |
| /readyz | 8081/TCP | Readiness probe - operator ready to reconcile | HTTP GET |

## Build and Deployment

### Container Build

| Stage | Base Image | Purpose |
|-------|------------|---------|
| builder | registry.access.redhat.com/ubi8/go-toolset:1.21 | Compile Go binary and fetch manifests |
| runtime | registry.access.redhat.com/ubi8/ubi-minimal:latest | Minimal runtime container |

### Build Arguments

| Argument | Default | Purpose |
|----------|---------|---------|
| GOLANG_VERSION | 1.21 | Go compiler version |
| USE_LOCAL | false | Use local manifests instead of fetching from git |
| OVERWRITE_MANIFESTS | "" | Override specific component manifest sources |

### Deployment Methods

1. **OLM (Production)**: Installed via OperatorHub subscription
2. **Direct (Development)**: `make deploy` with custom operator image
3. **OLM Bundle (Testing)**: `operator-sdk run bundle` with custom bundle image
