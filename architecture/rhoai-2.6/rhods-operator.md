# Component: RHODS Operator

## Metadata
- **Repository**: https://github.com/red-hat-data-services/rhods-operator.git
- **Version**: v1.6.0-391-ge3def7f5d
- **Branch**: rhoai-2.6
- **Distribution**: RHOAI
- **Languages**: Go 1.19
- **Deployment Type**: Kubernetes Operator (Controller-Manager Pattern)

## Purpose
**Short**: Orchestrates and manages the lifecycle of Red Hat OpenShift AI data science platform components.

**Detailed**: The RHODS Operator is the primary control plane for Red Hat OpenShift AI (RHOAI), a downstream productized version of Open Data Hub. It manages the deployment, configuration, and lifecycle of a comprehensive suite of data science and machine learning tools on OpenShift. The operator uses a declarative approach through the DataScienceCluster CRD to enable users to configure which components (Jupyter notebooks, model serving, pipelines, etc.) should be deployed. It handles component orchestration, service mesh integration, monitoring stack deployment, OAuth client generation, and cross-namespace resource management. The operator also manages platform initialization through the DSCInitialization CRD, including namespace creation, network policies, and monitoring configuration.

The operator embeds component manifests at build time (from odh-manifests repositories) and applies them using kustomize, providing a unified interface for managing the entire RHOAI platform. It integrates deeply with OpenShift features including Routes, OAuth, RBAC, and optionally OpenShift Service Mesh for enhanced networking and security.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| DataScienceCluster Controller | Reconciler | Manages lifecycle of data science components (dashboard, workbenches, pipelines, serving, etc.) |
| DSCInitialization Controller | Reconciler | Initializes platform prerequisites: namespaces, service mesh, monitoring, network policies |
| SecretGenerator Controller | Reconciler | Automatically generates OAuth client secrets and credentials for components |
| Feature Framework | Library | Declarative system for deploying cross-component features (auth, certificates, service mesh) |
| Component Managers | Library | Per-component reconciliation logic for 8 managed components |
| Monitoring Stack | Deployment | Prometheus, Alertmanager, and Blackbox Exporter for platform observability |
| Webhook Server | Admission Controller | Validation and defaulting webhooks for DSC and DSCI resources |

## APIs Exposed

### Custom Resource Definitions (CRDs)

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| datasciencecluster.opendatahub.io | v1 | DataScienceCluster | Cluster | Declares which RHOAI components to enable with per-component configuration |
| dscinitialization.opendatahub.io | v1 | DSCInitialization | Cluster | Configures platform-wide settings: namespaces, service mesh, monitoring |
| features.opendatahub.io | v1 | FeatureTracker | Cluster | Tracks cross-namespace resources created by Features API for garbage collection |

### HTTP Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /metrics | GET | 8080/TCP | HTTP | None | None | Prometheus metrics endpoint for operator telemetry |
| /healthz | GET | 8081/TCP | HTTP | None | None | Liveness probe endpoint |
| /readyz | GET | 8081/TCP | HTTP | None | None | Readiness probe endpoint |
| /validate-* | POST | 9443/TCP | HTTPS | TLS 1.2+ | Kubernetes API | Validating webhook for CRD validation |
| /mutate-* | POST | 9443/TCP | HTTPS | TLS 1.2+ | Kubernetes API | Mutating webhook for CRD defaulting |

### Monitoring Services

| Service | Port | Protocol | Encryption | Auth | Purpose |
|---------|------|----------|------------|------|---------|
| Prometheus | 9090/TCP | HTTP | TLS (proxy) | OAuth Proxy | Metrics collection and alerting for RHOAI components |
| Alertmanager | 9093/TCP | HTTP | TLS (proxy) | OAuth Proxy | Alert routing and notification management |
| Blackbox Exporter | 9114/TCP | HTTP | None | Internal | Probe-based monitoring for endpoint availability |
| Blackbox Metrics | 9115/TCP | HTTP | None | Internal | Metrics endpoint for blackbox exporter |

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| Kubernetes | 1.25+ | Yes | Container orchestration platform |
| OpenShift | 4.11+ | Yes | Extended Kubernetes distribution with Routes, OAuth, console |
| controller-runtime | v0.16.3 | Yes | Kubernetes controller framework |
| kustomize | v0.13.4 | Yes | Manifest templating and overlay system |
| OpenShift Service Mesh | 2.x | No | Optional Istio-based networking for KServe and unified auth |
| Prometheus Operator | v0.69.1 | No | CRDs for monitoring stack (if monitoring enabled) |
| cert-manager | Latest | No | Optional certificate provisioning for components |
| Authorino | Latest | No | Optional external authorization for service mesh |

### Internal ODH/RHOAI Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| ODH Dashboard | Deploy/Manage CRDs | Web UI for RHOAI platform - creates OdhDashboardConfig, OdhApplication CRs |
| Workbenches | Deploy manifests | Jupyter notebook environments - manages Notebook CRDs |
| Data Science Pipelines | Deploy/Manage CRDs | Kubeflow Pipelines - creates DataSciencePipelinesApplication CRs |
| KServe | Deploy/Manage CRDs | Single-model serving - manages InferenceService, ServingRuntime CRs |
| ModelMesh Serving | Deploy/Manage CRDs | Multi-model serving - manages ServingRuntime, InferenceService CRs |
| CodeFlare | Deploy/Manage CRDs | Distributed workload orchestration - manages MCAD, InstaScale CRs |
| Ray | Deploy/Manage CRDs | Distributed compute framework - manages RayCluster, RayJob CRs |
| TrustyAI | Deploy/Manage CRDs | Model monitoring and explainability - manages TrustyAIService CRs |

## Network Architecture

### Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| controller-manager-metrics-service | ClusterIP | 8443/TCP | 8443 | HTTPS | TLS 1.2+ | OAuth Proxy | Internal |
| prometheus | ClusterIP | 9090/TCP | 9090 | HTTP | TLS (via proxy) | OAuth Proxy | Internal |
| alertmanager | ClusterIP | 9093/TCP | 9093 | HTTP | TLS (via proxy) | OAuth Proxy | Internal |
| blackbox-exporter | ClusterIP | 9115/TCP | 9115 | HTTP | None | None | Internal |

### Ingress

| Name | Type | Hosts | Port | Protocol | Encryption | TLS Mode | Exposure |
|------|------|-------|------|----------|------------|----------|----------|
| prometheus | OpenShift Route | prometheus-{namespace}.{cluster-domain} | 443/TCP | HTTPS | TLS 1.2+ | edge | External (OAuth) |
| alertmanager | OpenShift Route | alertmanager-{namespace}.{cluster-domain} | 443/TCP | HTTPS | TLS 1.2+ | edge | External (OAuth) |

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | Service Account Token | Reconcile cluster resources |
| quay.io | 443/TCP | HTTPS | TLS 1.2+ | None | Pull component container images |
| registry.redhat.io | 443/TCP | HTTPS | TLS 1.2+ | Pull Secret | Pull Red Hat certified images |
| github.com | 443/TCP | HTTPS | TLS 1.2+ | None | Download manifests (dev mode with devFlags.manifestsUri) |

### Network Policies

| Policy Name | Namespace | Selector | Ingress Rules |
|-------------|-----------|----------|---------------|
| redhat-ods-operator | redhat-ods-operator | control-plane: controller-manager | Allow from: redhat-ods-monitoring, openshift-monitoring, openshift-user-workload-monitoring, namespaces with label opendatahub.io/generated-namespace=true |
| redhat-ods-monitoring | redhat-ods-monitoring | All pods | Allow from: redhat-ods-operator, openshift-monitoring, openshift-user-workload-monitoring |
| redhat-ods-applications | redhat-ods-applications | All pods | Allow from: redhat-ods-monitoring, same namespace, service mesh |

## Security

### RBAC - Cluster Roles

| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|
| controller-manager-role | datasciencecluster.opendatahub.io | datascienceclusters | create, delete, get, list, patch, update, watch |
| controller-manager-role | dscinitialization.opendatahub.io | dscinitializations | create, delete, get, list, patch, update, watch |
| controller-manager-role | features.opendatahub.io | featuretrackers | create, delete, get, list, patch, update, watch |
| controller-manager-role | "" (core) | secrets, configmaps, serviceaccounts, namespaces | create, delete, get, list, patch, update, watch |
| controller-manager-role | apps | deployments, statefulsets, replicasets | create, delete, get, list, patch, update, watch |
| controller-manager-role | rbac.authorization.k8s.io | roles, rolebindings, clusterroles, clusterrolebindings | * (all) |
| controller-manager-role | route.openshift.io | routes | create, delete, get, list, patch, update, watch |
| controller-manager-role | oauth.openshift.io | oauthclients | create, delete, get, list, patch, update, watch |
| controller-manager-role | networking.k8s.io | networkpolicies | create, delete, get, list, patch, update, watch |
| controller-manager-role | monitoring.coreos.com | servicemonitors, podmonitors, prometheusrules | create, delete, get, list, patch, update, watch |
| controller-manager-role | serving.kserve.io | inferenceservices, servingruntimes, clusterservingruntimes | create, delete, list, patch, update, watch |
| controller-manager-role | serving.knative.dev | services | create, delete, list, patch, update, watch |
| controller-manager-role | maistra.io | servicemeshcontrolplanes, servicemeshmemberrolls, servicemeshmembers | create, get, list, patch, update, use, watch |
| controller-manager-role | networking.istio.io | gateways, virtualservices | * (all) |
| controller-manager-role | operator.knative.dev | knativeservings | * (all) |
| controller-manager-role | ray.io | rayclusters, rayjobs, rayservices | create, delete, get, list, patch, update, watch |
| controller-manager-role | kubeflow.org | * | * (all) |
| controller-manager-role | tekton.dev | * | * (all) |
| controller-manager-role | trustyai.opendatahub.io | trustyaiservices | create, delete, get, list, patch, update, watch |
| controller-manager-role | datasciencepipelinesapplications.opendatahub.io | datasciencepipelinesapplications | create, delete, get, list, patch, update, watch |
| controller-manager-role | apiextensions.k8s.io | customresourcedefinitions | create, delete, get, list, patch, watch |
| controller-manager-role | security.openshift.io | securitycontextconstraints (anyuid, restricted) | * (all) |

### RBAC - Role Bindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| controller-manager-role-binding | Cluster | controller-manager-role | controller-manager (redhat-ods-operator ns) |
| leader-election-role-binding | redhat-ods-operator | leader-election-role | controller-manager |
| prometheus-scraper | redhat-ods-monitoring | rhods-prometheus-role | prometheus |
| prometheus-cluster-monitor | Cluster | cluster-monitoring-view | prometheus (redhat-ods-monitoring ns) |

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| webhook-server-cert | kubernetes.io/tls | Webhook admission controller TLS | cert-manager or OLM | No |
| {component}-oauth-client | Opaque | OAuth client ID/secret for component auth | SecretGenerator controller | No |
| prometheus-proxy-tls | kubernetes.io/tls | OAuth proxy TLS for Prometheus | Service CA | Yes (auto) |
| alertmanager-proxy-tls | kubernetes.io/tls | OAuth proxy TLS for Alertmanager | Service CA | Yes (auto) |

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| /metrics | GET | None | Network Policy | Internal cluster access only |
| /healthz, /readyz | GET | None | Network Policy | Internal cluster access only |
| Webhook endpoints | POST | mTLS client cert | Kubernetes API Server | API server validates cert against CA bundle |
| Prometheus UI (Route) | GET, POST | OAuth Proxy (OpenShift OAuth) | oauth-proxy sidecar | Authenticated OpenShift users with view permissions |
| Alertmanager UI (Route) | GET, POST | OAuth Proxy (OpenShift OAuth) | oauth-proxy sidecar | Authenticated OpenShift users with edit permissions |
| Component APIs | Various | Component-specific or Service Mesh | Istio AuthorizationPolicy | Per-component policies when service mesh enabled |

## Data Flows

### Flow 1: DataScienceCluster Creation - Component Deployment

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User/CI | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | kubeconfig credentials |
| 2 | Kubernetes API | Operator (Webhook) | 9443/TCP | HTTPS | TLS 1.2+ | mTLS (K8s API client cert) |
| 3 | Operator | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | Service Account Token |
| 4 | Operator | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | Service Account Token |
| 5 | Operator | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | Service Account Token |

**Flow Description**:
1. User creates DataScienceCluster CR declaring enabled components (e.g., dashboard, workbenches, kserve)
2. API server calls operator webhook to validate CR (ensures single DSC instance, valid component configs)
3. DataScienceCluster controller watches CR and begins reconciliation loop
4. Operator applies kustomize manifests from /opt/manifests/{component}/ for each enabled component
5. Operator creates component-specific resources: Deployments, Services, Routes, ConfigMaps, RBAC, CRDs

### Flow 2: DSCInitialization - Platform Bootstrap

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Operator (startup) | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | Service Account Token |
| 2 | Operator | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | Service Account Token |
| 3 | Operator | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | Service Account Token |
| 4 | Operator | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | Service Account Token |
| 5 | Operator | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | Service Account Token |

**Flow Description**:
1. On first installation, operator checks for existing DSCInitialization CR or creates default instance
2. DSCInitialization controller creates platform namespaces (redhat-ods-applications, redhat-ods-monitoring)
3. If serviceMesh.managementState=Managed: creates ServiceMeshControlPlane, ServiceMeshMember resources
4. If monitoring.managementState=Managed: deploys Prometheus, Alertmanager, Blackbox Exporter to monitoring namespace
5. Applies NetworkPolicies to operator, monitoring, and applications namespaces for network isolation

### Flow 3: Secret Generation - OAuth Client Provisioning

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Component Manifest | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | Service Account Token |
| 2 | SecretGenerator Controller | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | Service Account Token |
| 3 | SecretGenerator Controller | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | Service Account Token |

**Flow Description**:
1. Component manifest creates Secret with annotation `secret-generator.opendatahub.io/secret-name`
2. SecretGenerator controller watches Secret create events with this annotation
3. Controller generates random credentials, creates OAuth client, and creates target secret with generated values

### Flow 4: Monitoring - Metrics Collection

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Prometheus | Operator | 8080/TCP | HTTP | None | None |
| 2 | Prometheus | Component Pods | varies/TCP | HTTP | varies | Service Account Token |
| 3 | User Browser | OpenShift OAuth | 443/TCP | HTTPS | TLS 1.2+ | User credentials |
| 4 | OAuth Proxy | Prometheus | 9090/TCP | HTTP | None | Session cookie |

**Flow Description**:
1. Prometheus scrapes operator /metrics endpoint based on ServiceMonitor CRD
2. Prometheus scrapes component metrics endpoints via ServiceMonitor/PodMonitor CRDs created per component
3. User accesses Prometheus Route, redirected to OpenShift OAuth for authentication
4. OAuth proxy validates session and proxies authenticated requests to Prometheus UI

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| Kubernetes API Server | REST API Client | 6443/TCP | HTTPS | TLS 1.2+ | Create/update/delete cluster resources |
| OpenShift OAuth Server | OAuth Client Registration | 443/TCP | HTTPS | TLS 1.2+ | Register OAuth clients for component authentication |
| Service Mesh Control Plane | CR Management | 6443/TCP | HTTPS | TLS 1.2+ | Configure service mesh membership and policies |
| Prometheus Operator | CR Creation | 6443/TCP | HTTPS | TLS 1.2+ | Deploy ServiceMonitor, PodMonitor, PrometheusRule CRs |
| Component Operators | Manifest Deployment | 6443/TCP | HTTPS | TLS 1.2+ | Deploy component CRDs and watch component status |
| OpenShift Console | ConsoleLink CR | 6443/TCP | HTTPS | TLS 1.2+ | Add RHOAI dashboard link to OpenShift console |
| Image Registry (Quay, RHCR) | Image Pull | 443/TCP | HTTPS | TLS 1.2+ | Pull container images for deployments |

## Component Manifest Management

The operator embeds component manifests at build time from source repositories. The manifest structure follows:

| Component | Manifest Source | Kustomize Base Path | Runtime Path |
|-----------|----------------|---------------------|--------------|
| Dashboard | odh-dashboard repo | manifests/base | /opt/manifests/odh-dashboard |
| Workbenches | kubeflow/notebooks repo | manifests | /opt/manifests/workbenches |
| Data Science Pipelines | data-science-pipelines-operator repo | config | /opt/manifests/data-science-pipelines-operator |
| KServe | kserve repo | manifests/kserve | /opt/manifests/kserve |
| ModelMesh Serving | modelmesh-serving repo | config | /opt/manifests/modelmesh-serving |
| CodeFlare | codeflare-operator repo | config | /opt/manifests/codeflare |
| Ray | kuberay repo | ray-operator/config | /opt/manifests/ray |
| TrustyAI | trustyai-service-operator repo | config | /opt/manifests/trustyai-service-operator |

**Manifest Customization**: In development, users can override manifest sources using `DSCInitialization.spec.devFlags.manifestsUri` to point to custom Git repositories.

## Monitoring & Observability

### Metrics Exposed

| Metric Source | Metrics Endpoint | Metrics Exposed |
|---------------|------------------|-----------------|
| Operator | :8080/metrics | controller_runtime_* (reconciliation metrics), workqueue_*, go_* (runtime stats) |
| Prometheus | :9090 | Component-specific metrics aggregated from ServiceMonitors |
| Blackbox Exporter | :9115/metrics | probe_success, probe_duration_seconds (endpoint health checks) |

### Alerts Configured

| Alert Group | File | Critical Alerts |
|-------------|------|-----------------|
| Operator | operator-recording.rules | RHODS operator pod down, reconciliation failures |
| Dashboard | rhods-dashboard-alerting.rules | Dashboard unavailable, high error rate |
| Data Science Pipelines | data-science-pipelines-operator-alerting.rules | Pipeline API down, workflow failures |
| Model Mesh | model-mesh-alerting.rules | Serving runtime failures, high latency |
| KServe | kserve-alerting.rules | InferenceService failures, model load errors |
| Workbenches | workbenches-alerting.rules | Notebook spawn failures, image pull errors |

### Logging

- **Log Level**: Configurable via `--zap-log-level` flag (default: info)
- **Format**: JSON structured logs
- **Destinations**: stdout (captured by OpenShift logging stack)
- **Key Log Sources**:
  - Controller reconciliation loops
  - Component deployment status
  - Feature application results
  - Secret generation events
  - Webhook validation decisions

## Deployment Model

### Installation Methods

1. **OperatorHub (Production)**: Install from Red Hat Catalog via OLM
   - Operator deployed to `redhat-ods-operator` namespace
   - OLM manages upgrades, RBAC, CRD installation

2. **Manual Deploy (Development)**: `make deploy IMG=<image>`
   - Direct kustomize application to cluster
   - Manual CRD and RBAC setup

### Upgrade Strategy

- **OLM-Managed**: Operator subscription handles automatic upgrades
- **Component Upgrades**: Operator compares deployed vs embedded manifest versions
- **Rollback**: Not automated - requires manual DSC CR modification or operator downgrade
- **Migration Handling**: `pkg/upgrade` package handles legacy KfDef to DSC migration

### Resource Requirements

| Resource | Requests | Limits |
|----------|----------|--------|
| CPU | 500m | 500m |
| Memory | 256Mi | 4Gi |

### High Availability

- **Replicas**: 1 (single instance, leader election enabled)
- **Leader Election**: Enabled via `--leader-elect` flag
- **Lease**: Uses coordination.k8s.io/v1 Lease in operator namespace
- **Failover**: Automatic re-election on pod failure

## Recent Changes

Recent development activity is not captured in recent commits (3 months window shows no results), indicating stable release branch (rhoai-2.6) with limited churn.

**Version Notes**:
- Current version: v1.6.0-391-ge3def7f5d (391 commits ahead of v1.6.0 tag)
- This is a RHOAI 2.6 downstream build based on upstream OpenDataHub operator v2.x

## Known Limitations & Constraints

1. **Single Instance**: Only one DataScienceCluster CR supported per cluster
2. **Namespace Restrictions**: Applications namespace defaults to `redhat-ods-applications` (configurable at operator startup only)
3. **Component Dependencies**: Some components have prerequisites (e.g., KServe requires Service Mesh)
4. **Offline Support**: Requires external registry mirrors for disconnected clusters
5. **GPU Support**: GPU scheduling requires NFD and GPU operators pre-installed
6. **Platform**: OpenShift-specific features (Routes, OAuth, SCCs) - not portable to upstream Kubernetes

## Testing & Validation

### Test Suites

- **Unit Tests**: `make unit-test` - envtest-based controller tests
- **Functional Tests**: Component-specific ginkgo/gomega tests
- **E2E Tests**: `make e2e-test` - full DSC lifecycle tests on live cluster
- **Integration Tests**: Feature framework integration tests

### Quality Gates

- **Linting**: golangci-lint (config: .golangci.yml)
- **CRD Validation**: kubebuilder validation markers
- **Webhook Tests**: Admission webhook validation tests

## Security Considerations

### Pod Security

- **runAsNonRoot**: true
- **allowPrivilegeEscalation**: false
- **capabilities**: DROP ALL
- **SecurityContextConstraints**: Uses `restricted` SCC by default

### Secret Management

- **OAuth Secrets**: Auto-generated with cryptographically random values
- **TLS Certificates**: Managed by cert-manager or OLM webhook certificate injection
- **Service Account Tokens**: Mounted for Kubernetes API access, rotated automatically

### Network Security

- **Network Policies**: Enforced ingress rules limiting cross-namespace traffic
- **Service Mesh**: Optional mTLS for component-to-component communication
- **TLS Termination**: Routes use edge termination, oauth-proxy provides authentication layer

### Supply Chain

- **Image Sources**: Red Hat certified images from registry.redhat.io
- **SBOM**: Available for RHOAI product images
- **Vulnerability Scanning**: Images scanned in CI/CD pipeline
- **Signature Verification**: Red Hat GPG signatures on RPMs/images
