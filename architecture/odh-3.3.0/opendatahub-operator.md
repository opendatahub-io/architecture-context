# Component: Open Data Hub Operator

## Metadata
- **Repository**: https://github.com/opendatahub-io/opendatahub-operator
- **Version**: 3.3.0
- **Distribution**: ODH and RHOAI (both)
- **Languages**: Go (1.25.7)
- **Deployment Type**: Kubernetes Operator (Controller-Runtime based)

## Purpose
**Short**: Primary operator for Open Data Hub / Red Hat OpenShift AI that manages deployment and lifecycle of data science platform components.

**Detailed**: The Open Data Hub Operator is the central control plane operator for the Open Data Hub and Red Hat OpenShift AI platforms. It provides declarative management of 20+ integrated data science components including Jupyter workbenches, model serving (KServe/ModelMesh), data science pipelines, model registry, distributed training, and MLOps tooling. The operator implements a two-level CRD hierarchy with DSCInitialization for platform-wide configuration and DataScienceCluster for component management. It uses a component-based architecture where each component has dedicated controllers that deploy and manage component-specific operators and manifests. The operator supports both Open Data Hub (community) and Red Hat OpenShift AI (product) distributions with feature flags and conditional deployment logic.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| Controller Manager | Go Operator (Deployment) | Main reconciliation loop managing DSC and DSCI custom resources |
| Component Controllers | Reconciler Handlers | Individual controllers for 20+ components (Dashboard, KServe, Ray, etc.) |
| Service Controllers | Reconciler Handlers | Platform services (Auth, Gateway, Monitoring, Cert management) |
| Cloud Manager | Separate Binary | Manages cloud-specific infrastructure (Azure, CoreWeave) |
| Webhook Server | Admission Webhooks | Validates and mutates DSC and DSCI resources |
| Manifest Engine | Template Renderer | Kustomize and Helm rendering for component deployments |

## APIs Exposed

### Custom Resource Definitions (CRDs)

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| datasciencecluster.opendatahub.io | v1, v2 | DataScienceCluster | Cluster | Declarative configuration of all data science components |
| dscinitialization.opendatahub.io | v1, v2 | DSCInitialization | Cluster | Platform initialization and global configuration |
| components.platform.opendatahub.io | v1alpha1 | Dashboard | Cluster | ODH Dashboard web UI configuration |
| components.platform.opendatahub.io | v1alpha1 | DataSciencePipelines | Cluster | Kubeflow Pipelines integration |
| components.platform.opendatahub.io | v1alpha1 | Kserve | Cluster | KServe model serving platform |
| components.platform.opendatahub.io | v1alpha1 | Kueue | Cluster | Job queueing and resource management |
| components.platform.opendatahub.io | v1alpha1 | ModelRegistry | Cluster | Model versioning and registry |
| components.platform.opendatahub.io | v1alpha1 | Ray | Cluster | Ray distributed computing framework |
| components.platform.opendatahub.io | v1alpha1 | TrainingOperator | Cluster | Kubeflow Training Operator |
| components.platform.opendatahub.io | v1alpha1 | Trainer | Cluster | Advanced training job management |
| components.platform.opendatahub.io | v1alpha1 | TrustyAI | Cluster | AI explainability and governance |
| components.platform.opendatahub.io | v1alpha1 | Workbenches | Cluster | Jupyter notebook environments |
| components.platform.opendatahub.io | v1alpha1 | FeastOperator | Cluster | Feature store for ML |
| components.platform.opendatahub.io | v1alpha1 | LlamaStackOperator | Cluster | Llama Stack integration |
| components.platform.opendatahub.io | v1alpha1 | MLflowOperator | Cluster | MLflow tracking and registry |
| components.platform.opendatahub.io | v1alpha1 | SparkOperator | Cluster | Apache Spark on Kubernetes |
| components.platform.opendatahub.io | v1alpha1 | ModelsAsService | Cluster | MaaS integration (API key management) |
| services.platform.opendatahub.io | v1alpha1 | Auth | Cluster | Platform authentication configuration |
| services.platform.opendatahub.io | v1alpha1 | GatewayConfig | Cluster | Istio gateway configuration |
| services.platform.opendatahub.io | v1alpha1 | Monitoring | Cluster | Prometheus/Grafana monitoring setup |
| infrastructure.opendatahub.io | v1, v1alpha1 | HardwareProfile | Cluster | Hardware resource profiles |
| cloudmanager.azure.opendatahub.io | v1alpha1 | AzureKubernetesEngine | Cluster | Azure AKS integration |
| cloudmanager.coreweave.opendatahub.io | v1alpha1 | CoreweaveKubernetesEngine | Cluster | CoreWeave cloud integration |

### HTTP Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /metrics | GET | 8443/TCP | HTTPS | TLS | Service account | Prometheus metrics endpoint |
| /healthz | GET | 8081/TCP | HTTP | None | None | Liveness probe |
| /readyz | GET | 8081/TCP | HTTP | None | None | Readiness probe |

### Webhook Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /validate | POST | 9443/TCP | HTTPS | TLS (cert-manager) | Kubernetes API | ValidatingWebhook for DSC/DSCI |
| /mutate | POST | 9443/TCP | HTTPS | TLS (cert-manager) | Kubernetes API | MutatingWebhook for DSC/DSCI |

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| OpenShift / Kubernetes | 1.25.0+ | Yes | Container orchestration platform |
| cert-manager Operator | Latest | Optional | TLS certificate management for components |
| Kueue Operator | Latest | Optional | Job queue management for distributed workloads |
| LeaderWorkerSet Operator | Latest | Optional | Distributed training with LWS |
| OpenTelemetry Operator | Latest | Optional | Observability and tracing |
| Tempo Operator | Latest | Optional | Distributed tracing backend |
| Service Mesh (Istio/Sail) | Latest | Optional | Service mesh for KServe and networking |

### Internal ODH Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| ODH Dashboard | Deploys manifests | Web UI for platform management |
| KServe | Deploys operator | Model serving platform |
| Data Science Pipelines Operator | Deploys operator | ML pipeline orchestration |
| Kuberay | Deploys operator | Ray distributed computing |
| Training Operator | Deploys operator | ML training job management |
| Model Registry Operator | Deploys operator | Model versioning |
| TrustyAI Operator | Deploys operator | AI explainability |
| Notebook Controller | Deploys manifests | Jupyter notebook lifecycle |
| Model Controller | Deploys operator | Model deployment orchestration |

## Network Architecture

### Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| controller-manager-metrics-service | ClusterIP | 8443/TCP | 8080 | HTTPS | None | Service account token | Internal |
| webhook-service | ClusterIP | 443/TCP | 9443 | HTTPS | TLS (service-cert) | Kubernetes API | Internal |

### Ingress

No direct ingress - operator is internal only. Component services (Dashboard, KServe, etc.) have their own ingress configurations.

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| Kubernetes API Server | 443/TCP | HTTPS | TLS (mTLS) | Service account token | Cluster resource management |
| Component Git Repositories | 443/TCP | HTTPS | TLS 1.2+ | None | Manifest cloning (build time) |
| Quay.io / Registry | 443/TCP | HTTPS | TLS 1.2+ | Pull secrets | Container image pulls |

## Security

### RBAC - Cluster Roles

| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|
| controller-manager | "" (core) | namespaces, services, serviceaccounts, configmaps, secrets, pods | get, list, watch, create, update, patch, delete |
| controller-manager | apps | deployments, statefulsets, daemonsets | get, list, watch, create, update, patch, delete |
| controller-manager | rbac.authorization.k8s.io | roles, rolebindings, clusterroles, clusterrolebindings | get, list, watch, create, update, patch, delete |
| controller-manager | route.openshift.io | routes | get, list, watch, create, update, patch, delete |
| controller-manager | config.openshift.io | clusterversions | get, list, watch |
| controller-manager | datasciencecluster.opendatahub.io | datascienceclusters | get, list, watch, create, update, patch, delete |
| controller-manager | dscinitialization.opendatahub.io | dscinitializations | get, list, watch, create, update, patch, delete |
| controller-manager | components.platform.opendatahub.io | * (all component CRDs) | get, list, watch, create, update, patch, delete |
| controller-manager | services.platform.opendatahub.io | auths, monitorings, gatewayconfigs | get, list, watch, create, update, patch, delete |
| controller-manager | networking.k8s.io | networkpolicies | get, list, watch, create, update, patch, delete |
| controller-manager | operators.coreos.com | subscriptions, operatorgroups | get, list, watch, create, update, patch, delete |
| controller-manager | monitoring.coreos.com | servicemonitors, prometheusrules | get, list, watch, create, update, patch, delete |
| auth-proxy-client | "" (core) | pods | get, list, watch |

### RBAC - Role Bindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| controller-manager-rolebinding | system | controller-manager (ClusterRole) | controller-manager |

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| opendatahub-operator-controller-webhook-cert | kubernetes.io/tls | Webhook server TLS cert | service.beta.openshift.io/serving-cert-secret-name | Yes (OpenShift) |

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| Kubernetes API | All | Service account token | Kubernetes API Server | RBAC ClusterRole |
| Webhook endpoints | POST | Kubernetes API authentication | Kubernetes API Server | Webhook CA bundle verification |
| Metrics endpoint | GET | Service account token (kube-rbac-proxy) | kube-rbac-proxy sidecar | RBAC ClusterRole |

## Data Flows

### Flow 1: DataScienceCluster Reconciliation

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User/GitOps | Kubernetes API Server | 443/TCP | HTTPS | TLS 1.2+ | User credentials |
| 2 | Kubernetes API Server | Operator Manager | N/A | In-cluster | N/A | Service account |
| 3 | Operator Manager | Kubernetes API Server | 443/TCP | HTTPS | TLS (mTLS) | Service account token |
| 4 | Operator Manager | Manifest Renderer (in-process) | N/A | N/A | N/A | N/A |
| 5 | Manifest Renderer | Kubernetes API Server | 443/TCP | HTTPS | TLS (mTLS) | Service account token |

### Flow 2: Webhook Validation

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User/GitOps | Kubernetes API Server | 443/TCP | HTTPS | TLS 1.2+ | User credentials |
| 2 | Kubernetes API Server | Webhook Service | 443/TCP | HTTPS | TLS (service cert) | Kubernetes API auth |
| 3 | Webhook Service | Kubernetes API Server (response) | N/A | HTTPS | TLS | Service cert |

### Flow 3: Component Deployment

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Operator Manager | Kustomize/Helm Renderer | N/A | In-process | N/A | N/A |
| 2 | Operator Manager | Kubernetes API Server (create Subscription) | 443/TCP | HTTPS | TLS (mTLS) | Service account token |
| 3 | OLM | OperatorHub | 443/TCP | HTTPS | TLS 1.2+ | Pull secrets |
| 4 | Component Operator | Kubernetes API Server | 443/TCP | HTTPS | TLS (mTLS) | Component service account |

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| Kubernetes API Server | REST API | 443/TCP | HTTPS | TLS (mTLS) | Resource CRUD operations |
| OLM (Operator Lifecycle Manager) | CRD (Subscription, OperatorGroup) | N/A | In-cluster | N/A | Component operator installation |
| cert-manager | CRD (Certificate, Issuer) | N/A | In-cluster | N/A | TLS certificate provisioning |
| Prometheus Operator | CRD (ServiceMonitor, PrometheusRule) | N/A | In-cluster | N/A | Monitoring configuration |
| Service Mesh (Istio) | CRD (Gateway, VirtualService) | N/A | In-cluster | N/A | Gateway and routing configuration |

## Recent Changes

| Version | Date | Changes |
|---------|------|---------|
| 3.3.0 | 2025-01 | - Added workbenches manifest separation (ODH/RHOAI)<br>- Added cert-manager PKI bootstrap for cloud controllers<br>- Added AutoRAG UI and AutoML UI to image map<br>- Added MLflow UI support<br>- Added cloud manager infrastructure (Azure, CoreWeave)<br>- Added MaaS API key max expiration configuration<br>- Added dynamic resource ownership action<br>- Implemented configuration to suppress management of platform components<br>- Added E2E testing documentation<br>- Security config sync improvements |
| 3.2.x | 2024-12 | - Trainer component integration<br>- MLflow operator support<br>- Enhanced monitoring and alerting<br>- Improved component dev workflows<br>- Manifest SHA update automation |

## Build and Deployment

### Container Build

- **Base Image**: registry.access.redhat.com/ubi9/ubi-minimal:latest (runtime)
- **Builder Image**: registry.access.redhat.com/ubi9/go-toolset:1.25
- **Build Tags**: `strictfipsruntime` (FIPS 140-2 compliance)
- **Binaries**: `manager` (main operator), `cloudmanager` (cloud integration)
- **Manifests**: Embedded in `/opt/manifests` and `/opt/charts` (cloned at build time via `get_all_manifests.sh`)

### Deployment Configuration

- **Replicas**: 3 (high availability)
- **Resource Limits**: CPU 1000m, Memory 4Gi
- **Resource Requests**: CPU 100m, Memory 780Mi
- **Pod Anti-Affinity**: Preferred scheduling on different nodes
- **Security Context**: Non-root user (UID 1001), seccomp RuntimeDefault, drop all capabilities

### Leader Election

- Enabled via `--leader-elect` flag
- Ensures only one active reconciliation manager in HA setup

## Component Management

The operator manages 20+ data science components with three management states:

1. **Managed**: Operator actively manages component lifecycle and upgrades
2. **Unmanaged**: Operator creates supporting resources but does not manage lifecycle
3. **Removed**: Operator actively removes component if installed

### Managed Components

- Dashboard, Workbenches, Data Science Pipelines
- KServe, Model Registry, Model Controller
- Ray, Training Operator, Trainer
- Kueue, TrustyAI, Feast Operator
- MLflow Operator, LlamaStack Operator, Spark Operator
- Models as Service (MaaS)

## Monitoring and Observability

### Metrics

- **Endpoint**: Port 8080 (exposed via 8443 with kube-rbac-proxy)
- **Format**: Prometheus format
- **ServiceMonitor**: Configured for Prometheus Operator integration

### Logging

- **Framework**: Zap (structured logging)
- **Level**: Configurable via `DevFlags.LogLevel` (debug, info, error)
- **Runtime Control**: Log level adjustable without restart

### Health Checks

- **Liveness**: `/healthz` on port 8081
- **Readiness**: `/readyz` on port 8081
- **Initial Delay**: Liveness 15s, Readiness 5s

## Notes

- Operator requires OpenShift 4.19+ or Kubernetes 1.25+
- Supports both Open Data Hub (community) and Red Hat OpenShift AI (product) via `ODH_PLATFORM_TYPE` environment variable
- Component manifests are cloned from upstream repositories at build time and embedded in the container image
- Helm charts and Kustomize overlays are supported for component customization
- The operator uses a two-stage rendering pipeline: Helm chart rendering followed by Kustomize transformations
- Cloud manager provides integration with Azure AKS and CoreWeave Kubernetes
- Webhook validations enforce security policies (e.g., AdminGroups cannot contain 'system:authenticated')
- High availability is achieved through 3 replicas with leader election
