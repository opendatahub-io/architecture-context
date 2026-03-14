# Component: odh-model-controller

## Metadata
- **Repository**: https://github.com/red-hat-data-services/odh-model-controller.git
- **Version**: v1.27.0-rhods-1157-gfbaeb50
- **Branch**: rhoai-3.3
- **Distribution**: RHOAI
- **Languages**: Go (Golang v1.24+)
- **Deployment Type**: Kubernetes Operator (Kubebuilder-based)

## Purpose
**Short**: Extends KServe controller functionality with OpenShift-specific integrations for model serving workloads.

**Detailed**: The odh-model-controller is a Kubernetes operator that extends the KServe controller to provide seamless integration with OpenShift and Red Hat OpenShift AI. It watches KServe custom resources (InferenceServices, InferenceGraphs, ServingRuntimes) and performs additional reconciliation tasks that are specific to OpenShift environments. Primary responsibilities include creating and managing OpenShift Routes for model endpoints, configuring network policies, setting up RBAC resources for inference workloads, integrating with Prometheus for metrics collection, managing KEDA autoscaling configurations, and handling NVIDIA NIM (NVIDIA Inference Microservices) account integrations. The controller also manages serving runtime templates for various inference frameworks (vLLM, OpenVINO, MLServer, Caikit, TGIS) across multiple hardware architectures including x86, ppc64le, and s390x.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| InferenceService Controller | Reconciler | Reconciles KServe InferenceService resources, creates Routes, NetworkPolicies, RBAC, ServiceMonitors, and KEDA TriggerAuthentications |
| InferenceGraph Controller | Reconciler | Reconciles KServe InferenceGraph resources for multi-model inference pipelines |
| ServingRuntime Controller | Reconciler | Manages KServe ServingRuntime resources and templates |
| LLM InferenceService Controller | Reconciler | Specialized controller for Large Language Model inference services |
| NIM Account Controller | Reconciler | Manages NVIDIA NIM account credentials and configurations, validates NGC API keys |
| ConfigMap Controller | Reconciler | Watches ConfigMaps referenced by managed resources |
| Secret Controller | Reconciler | Watches Secrets referenced by managed resources |
| Pod Controller | Reconciler | Mutates pods for inference workloads via webhooks |
| Webhook Server | Admission Controller | Validates and mutates KServe resources and pods |
| Metrics Server | HTTP Server | Exposes Prometheus metrics for monitoring |
| Health Check Server | HTTP Server | Provides liveness and readiness probes |

## APIs Exposed

### Custom Resource Definitions (CRDs)

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| nim.opendatahub.io | v1 | Account | Namespaced | Manages NVIDIA NGC account credentials and NIM configurations for deploying NVIDIA inference microservices |

### External CRDs Watched

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| serving.kserve.io | v1beta1 | InferenceService | Namespaced | Primary resource for deploying ML models with KServe |
| serving.kserve.io | v1alpha1 | InferenceGraph | Namespaced | Multi-model inference pipeline orchestration |
| serving.kserve.io | v1alpha1 | ServingRuntime | Namespaced | Template for model serving runtime containers |
| serving.kserve.io | v1beta1 | Predictor | Namespaced | Prediction service component of InferenceService |
| serving.kserve.io | v1alpha1 | LLMInferenceService | Namespaced | Specialized resource for Large Language Model inference |
| route.openshift.io | v1 | Route | Namespaced | OpenShift Routes for external access to inference endpoints |
| monitoring.coreos.com | v1 | ServiceMonitor | Namespaced | Prometheus metrics scraping configuration |
| monitoring.coreos.com | v1 | PodMonitor | Namespaced | Prometheus pod-level metrics scraping |
| keda.sh | v1alpha1 | TriggerAuthentication | Namespaced | KEDA autoscaling authentication configuration |
| datasciencecluster.opendatahub.io | v1 | DataScienceCluster | Cluster | ODH cluster-wide configuration |
| dscinitialization.opendatahub.io | v1 | DSCInitialization | Cluster | ODH initialization settings |
| template.openshift.io | v1 | Template | Namespaced | OpenShift templates for NIM serving runtimes |

### HTTP Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /metrics | GET | 8080/TCP | HTTP | None | Bearer Token | Prometheus metrics endpoint (TODO: migrate to HTTPS on 8443) |
| /healthz | GET | 8081/TCP | HTTP | None | None | Liveness probe endpoint |
| /readyz | GET | 8081/TCP | HTTP | None | None | Readiness probe endpoint |
| /mutate--v1-pod | POST | 9443/TCP | HTTPS | TLS 1.2+ | K8s Admission | Mutating webhook for Pod resources |
| /mutate-serving-kserve-io-v1alpha1-inferencegraph | POST | 9443/TCP | HTTPS | TLS 1.2+ | K8s Admission | Mutating webhook for InferenceGraph resources |
| /mutate-serving-kserve-io-v1beta1-inferenceservice | POST | 9443/TCP | HTTPS | TLS 1.2+ | K8s Admission | Mutating webhook for InferenceService resources |
| /validate--v1-configmap | POST | 9443/TCP | HTTPS | TLS 1.2+ | K8s Admission | Validating webhook for ConfigMap resources |
| /validate-nim-opendatahub-io-v1-account | POST | 9443/TCP | HTTPS | TLS 1.2+ | K8s Admission | Validating webhook for NIM Account resources |
| /validate-serving-kserve-io-v1alpha1-llminferenceservice | POST | 9443/TCP | HTTPS | TLS 1.2+ | K8s Admission | Validating webhook for LLM InferenceService resources |
| /validate-serving-kserve-io-v1alpha1-inferencegraph | POST | 9443/TCP | HTTPS | TLS 1.2+ | K8s Admission | Validating webhook for InferenceGraph resources |
| /validate-serving-kserve-io-v1beta1-inferenceservice | POST | 9443/TCP | HTTPS | TLS 1.2+ | K8s Admission | Validating webhook for InferenceService resources |

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| KServe | v0.15.1 | Yes | Core model serving platform that this controller extends |
| Kubernetes | v1.11.3+ | Yes | Container orchestration platform |
| OpenShift | v4.11+ | Yes | OpenShift-specific features (Routes, Templates) |
| Prometheus Operator | Latest | No | Metrics collection via ServiceMonitor CRDs |
| KEDA | v2.x | No | Event-driven autoscaling for inference workloads |
| cert-manager | Latest | No | TLS certificate management for webhooks |
| Kuadrant | Latest | No | AuthPolicy for API authentication/authorization |
| Authorino | Latest | No | Authorization service integration |
| Istio | Latest | No | Service mesh integration via EnvoyFilters |

### Internal ODH Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| opendatahub-operator | CRD Watches | Reads DataScienceCluster and DSCInitialization for platform configuration |
| model-registry | HTTP API | Optional integration for model metadata and versioning |
| KServe | CRD Watches/Updates | Core dependency - watches and modifies KServe resources |

### Serving Runtime Dependencies

| Runtime | Version | Purpose |
|---------|---------|---------|
| vLLM | v0.11.2 | LLM inference (CUDA, ROCm, CPU, Gaudi, multinode, Spyre variants) |
| OpenVINO Model Server | v2025.4 | Intel-optimized model serving |
| MLServer | 1.7.1 | Multi-framework model serving (SKLearn, XGBoost, etc.) |
| Caikit | v0.27.7 | IBM AI toolkit for model serving |
| Caikit-nlp | v0.5.8 | NLP-specific Caikit runtime |
| Text Generation Inference | commit 8a8c55d | Hugging Face TGI server |

## Network Architecture

### Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| odh-model-controller-metrics-service | ClusterIP | 8080/TCP | 8080 | HTTP | None | Bearer Token | Internal |
| odh-model-controller-webhook-service | ClusterIP | 443/TCP | 9443 | HTTPS | TLS (cert via service.beta.openshift.io/serving-cert-secret-name) | K8s ServiceAccount Token | Internal |

### Ingress

The controller does not expose ingress for itself. Instead, it creates OpenShift Routes for InferenceService resources that it manages.

| Name | Type | Hosts | Port | Protocol | Encryption | TLS Mode | Exposure |
|------|------|-------|------|----------|------------|----------|----------|
| [per-InferenceService] | OpenShift Route | Dynamic (per InferenceService) | 443/TCP | HTTPS | TLS 1.2+ | Edge/Reencrypt | External |

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| Kubernetes API Server | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token | Watch and reconcile CRDs, create/update resources |
| Prometheus | 9090/TCP | HTTP | None | None | Metrics scraping (via ServiceMonitor) |
| NVIDIA NGC API | 443/TCP | HTTPS | TLS 1.2+ | NGC API Key | Validate NIM accounts and retrieve model configurations |
| Model Registry API | 443/TCP | HTTPS | TLS 1.2+ | Bearer Token | Optional model metadata integration |

## Security

### RBAC - Cluster Roles

| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|
| odh-model-controller-role | "" | configmaps, secrets, serviceaccounts, services | create, delete, get, list, patch, update, watch |
| odh-model-controller-role | "" | endpoints, namespaces, pods | create, get, list, patch, update, watch |
| odh-model-controller-role | "" | events | create, patch |
| odh-model-controller-role | config.openshift.io | authentications | get, list, watch |
| odh-model-controller-role | datasciencecluster.opendatahub.io | datascienceclusters | get, list, watch |
| odh-model-controller-role | dscinitialization.opendatahub.io | dscinitializations | get, list, watch |
| odh-model-controller-role | extensions, networking.k8s.io | ingresses | get, list, watch |
| odh-model-controller-role | gateway.networking.k8s.io | gateways | get, list, patch, update, watch |
| odh-model-controller-role | gateway.networking.k8s.io | gateways/finalizers | patch, update |
| odh-model-controller-role | gateway.networking.k8s.io | httproutes | get, list, watch |
| odh-model-controller-role | keda.sh | triggerauthentications | create, delete, get, list, patch, update, watch |
| odh-model-controller-role | kuadrant.io | authpolicies | create, delete, get, list, patch, update, watch |
| odh-model-controller-role | kuadrant.io | authpolicies/status | get, patch, update |
| odh-model-controller-role | kuadrant.io | kuadrants | get, list, watch |
| odh-model-controller-role | metrics.k8s.io | nodes, pods | get, list, watch |
| odh-model-controller-role | monitoring.coreos.com | podmonitors, servicemonitors | create, delete, get, list, patch, update, watch |
| odh-model-controller-role | networking.istio.io | envoyfilters | create, delete, get, list, patch, update, watch |
| odh-model-controller-role | networking.k8s.io | networkpolicies | create, delete, get, list, patch, update, watch |
| odh-model-controller-role | nim.opendatahub.io | accounts | get, list, patch, update, watch |
| odh-model-controller-role | nim.opendatahub.io | accounts/finalizers | update |
| odh-model-controller-role | nim.opendatahub.io | accounts/status | get, list, update, watch |
| odh-model-controller-role | operator.authorino.kuadrant.io | authorinos | get, list, watch |
| odh-model-controller-role | rbac.authorization.k8s.io | clusterrolebindings, rolebindings, roles | create, delete, get, list, patch, update, watch |
| odh-model-controller-role | route.openshift.io | routes | create, delete, get, list, patch, update, watch |
| odh-model-controller-role | route.openshift.io | routes/custom-host | create |
| odh-model-controller-role | serving.kserve.io | inferencegraphs, llminferenceserviceconfigs | get, list, watch |
| odh-model-controller-role | serving.kserve.io | inferencegraphs/finalizers, servingruntimes/finalizers | update |
| odh-model-controller-role | serving.kserve.io | inferenceservices | get, list, patch, update, watch |
| odh-model-controller-role | serving.kserve.io | inferenceservices/finalizers | create, delete, get, list, patch, update, watch |
| odh-model-controller-role | serving.kserve.io | llminferenceservices | get, list, patch, post, update, watch |
| odh-model-controller-role | serving.kserve.io | llminferenceservices/finalizers | patch, update |
| odh-model-controller-role | serving.kserve.io | llminferenceservices/status | get, patch, update |
| odh-model-controller-role | serving.kserve.io | servingruntimes | create, get, list, update, watch |
| odh-model-controller-role | template.openshift.io | templates | create, delete, get, list, patch, update, watch |
| odh-model-controller-leader-election-role | "" | configmaps | get, list, watch, create, update, patch, delete |
| odh-model-controller-leader-election-role | coordination.k8s.io | leases | get, list, watch, create, update, patch, delete |
| odh-model-controller-leader-election-role | "" | events | create, patch |
| odh-model-controller-metrics-reader | "" | services/proxy | get |
| odh-model-controller-proxy-role | authentication.k8s.io | tokenreviews | create |
| odh-model-controller-proxy-role | authorization.k8s.io | subjectaccessreviews | create |

### RBAC - Role Bindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| odh-model-controller-role-binding | Cluster-wide (ClusterRoleBinding) | odh-model-controller-role | odh-model-controller (in deployment namespace) |
| odh-model-controller-leader-election-role-binding | Cluster-wide (ClusterRoleBinding) | odh-model-controller-leader-election-role | odh-model-controller (in deployment namespace) |
| odh-model-controller-proxy-rolebinding | Cluster-wide (ClusterRoleBinding) | odh-model-controller-proxy-role | odh-model-controller (in deployment namespace) |

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| odh-model-controller-webhook-cert | kubernetes.io/tls | TLS certificate for webhook server | OpenShift service-ca-operator (via service.beta.openshift.io/serving-cert-secret-name annotation) | Yes |
| [NGC API Key Secrets] | Opaque | NVIDIA NGC API keys for NIM account validation (referenced by Account CRs) | User-provisioned | No |
| [Model Pull Secrets] | kubernetes.io/dockerconfigjson | Container image pull secrets for NIM models | NIM Account Controller (generated from NGC API keys) | No |

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| /metrics | GET | Bearer Token (ServiceAccount) | kube-rbac-proxy sidecar | Requires odh-model-controller-metrics-reader ClusterRole |
| /healthz, /readyz | GET | None | Controller | Public health endpoints |
| Webhook endpoints | POST | mTLS (Kubernetes API server client cert) | Kubernetes API server | API server validates webhook server TLS cert |
| Kubernetes API (egress) | ALL | ServiceAccount Token | Kubernetes API server | RBAC based on odh-model-controller ServiceAccount |

### Network Policies

The controller creates NetworkPolicy resources for InferenceService workloads to control ingress/egress traffic based on security requirements.

| Policy Pattern | Selector | Ingress Rules | Egress Rules |
|----------------|----------|---------------|--------------|
| InferenceService Network Isolation | serving.kserve.io/inferenceservice label | Allow from Istio ingress gateway, Allow from same namespace | Allow to Kubernetes API, Allow to model storage (S3/PVC) |

## Data Flows

### Flow 1: InferenceService Reconciliation

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User | Kubernetes API Server | 443/TCP | HTTPS | TLS 1.2+ | User credentials |
| 2 | Kubernetes API Server | odh-model-controller | N/A | Watch (HTTPS) | TLS 1.2+ | ServiceAccount Token |
| 3 | odh-model-controller | Kubernetes API Server | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 4 | odh-model-controller | Kubernetes API Server (create Route) | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 5 | odh-model-controller | Kubernetes API Server (create ServiceMonitor) | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 6 | odh-model-controller | Kubernetes API Server (create NetworkPolicy) | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 7 | odh-model-controller | Kubernetes API Server (create RBAC) | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |

### Flow 2: NIM Account Validation

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User | Kubernetes API Server (create Account CR) | 443/TCP | HTTPS | TLS 1.2+ | User credentials |
| 2 | Kubernetes API Server | odh-model-controller (webhook) | 9443/TCP | HTTPS | TLS 1.2+ | K8s API client cert |
| 3 | odh-model-controller | Kubernetes API Server (read NGC API key Secret) | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 4 | odh-model-controller | NVIDIA NGC API | 443/TCP | HTTPS | TLS 1.2+ | NGC API Key |
| 5 | NVIDIA NGC API | odh-model-controller | 443/TCP | HTTPS | TLS 1.2+ | Response |
| 6 | odh-model-controller | Kubernetes API Server (update Account status) | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 7 | odh-model-controller | Kubernetes API Server (create NIM Template) | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |

### Flow 3: Webhook Admission Control

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User | Kubernetes API Server (create/update resource) | 443/TCP | HTTPS | TLS 1.2+ | User credentials |
| 2 | Kubernetes API Server | odh-model-controller-webhook-service | 443/TCP (external), 9443/TCP (internal) | HTTPS | TLS 1.2+ | K8s API client cert (mTLS) |
| 3 | odh-model-controller | Kubernetes API Server (validation/mutation response) | N/A | HTTPS Response | TLS 1.2+ | Response to API server |

### Flow 4: Metrics Collection

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Prometheus | odh-model-controller-metrics-service | 8080/TCP | HTTP | None (TODO: TLS) | Bearer Token (ServiceAccount) |
| 2 | odh-model-controller | Prometheus | N/A | HTTP Response | None | Metrics response |

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| KServe | CRD Watch/Update | 443/TCP (K8s API) | HTTPS | TLS 1.2+ | Core integration - watches KServe CRDs and extends functionality |
| OpenShift Routes | CRD Create/Update | 443/TCP (K8s API) | HTTPS | TLS 1.2+ | Creates Routes for InferenceService external access |
| Prometheus Operator | CRD Create (ServiceMonitor) | 443/TCP (K8s API) | HTTPS | TLS 1.2+ | Configures metrics scraping for inference pods |
| KEDA | CRD Create (TriggerAuthentication) | 443/TCP (K8s API) | HTTPS | TLS 1.2+ | Configures autoscaling authentication for inference workloads |
| Istio Service Mesh | CRD Create (EnvoyFilter) | 443/TCP (K8s API) | HTTPS | TLS 1.2+ | Configures service mesh policies for inference traffic |
| Kuadrant | CRD Create (AuthPolicy) | 443/TCP (K8s API) | HTTPS | TLS 1.2+ | Configures API authentication/authorization policies |
| Model Registry | HTTP API | 443/TCP | HTTPS | TLS 1.2+ | Optional integration for model metadata and lineage |
| NVIDIA NGC API | HTTP API | 443/TCP | HTTPS | TLS 1.2+ | Validates NIM accounts and retrieves model configurations |
| Kubernetes Gateway API | CRD Watch/Update | 443/TCP (K8s API) | HTTPS | TLS 1.2+ | Watches Gateway/HTTPRoute resources for ingress configuration |

## Recent Changes

| Version | Date | Changes |
|---------|------|---------|
| v1.27.0-rhods-1157-gfbaeb50 | 2026-03 | - Updated UBI minimal base image to sha256:69f5c98<br>- Synced Konflux pipelineruns<br>- Added single manifest entry for Spyre images<br>- Fixed RAG ppc64le spyre template (RHOAIENG-48076)<br>- Used downward API for MAAS_NAMESPACE for dynamic namespace configuration<br>- Added Template for Spyre ppc64le (RHOAIENG-45239)<br>- Multiple dependency updates for security patches |
| v1.27.0 (base) | 2025-01 | - Merged changes from upstream ODH incubating branch<br>- Synced with OpenDataHub main branch<br>- CI integration improvements |

## Deployment Configuration

The controller is deployed via Kustomize manifests located in the `config/` directory:

- **Base manifests**: `config/base/` - Core deployment configuration
- **Manager**: `config/manager/manager.yaml` - Deployment resource with 1 replica
- **RBAC**: `config/rbac/` - ClusterRole, RoleBindings, ServiceAccount
- **CRDs**: `config/crd/bases/` - Account CRD, `config/crd/external/` - External CRDs
- **Webhooks**: `config/webhook/` - MutatingWebhookConfiguration, ValidatingWebhookConfiguration
- **Metrics**: `config/prometheus/` - ServiceMonitor for Prometheus
- **Serving Runtimes**: `config/runtimes/` - ServingRuntime templates (vLLM, OVMS, MLServer, etc.)
- **Cert Manager**: `config/certmanager/` - Certificate resources (optional, OpenShift uses service-ca)

### Container Image

Built using Konflux with **Dockerfile.konflux**:
- Base build image: `registry.access.redhat.com/ubi9/go-toolset:1.24`
- Runtime image: `registry.access.redhat.com/ubi9/ubi-minimal`
- FIPS compliance: Built with `strictfipsruntime` tags
- User: Non-root (UID 2000)
- Entrypoint: `/manager`

### Resource Requirements

| Resource | Request | Limit |
|----------|---------|-------|
| CPU | 10m | 500m |
| Memory | 64Mi | 2Gi |

### Environment Variables

| Variable | Default | Purpose |
|----------|---------|---------|
| POD_NAMESPACE | (from fieldRef) | Current namespace for operator |
| NIM_STATE | replace | NIM feature state (managed/replace) |
| KSERVE_STATE | replace | KServe integration state |
| MODELREGISTRY_STATE | replace | Model Registry integration state |
| MAAS_NAMESPACE | (from fieldRef) | Model-as-a-Service namespace |
| ENABLE_WEBHOOKS | true | Enable/disable webhook server |

## Notes

- The metrics endpoint currently uses HTTP on port 8080. There are TODO comments indicating plans to migrate to HTTPS on port 8443 with proper TLS encryption.
- The controller requires OpenShift-specific features (Routes, Templates, service-ca for certificate provisioning) and may not function fully on vanilla Kubernetes.
- Webhook TLS certificates are automatically provisioned by OpenShift's service-ca-operator via the `service.beta.openshift.io/serving-cert-secret-name` annotation.
- The controller supports multiple hardware architectures through Spyre-based serving runtime templates for ppc64le and s390x platforms.
- Leader election is enabled to support high availability with multiple replicas (though default deployment is 1 replica).
- HTTP/2 is disabled by default for the metrics and webhook servers to mitigate HTTP/2 Stream Cancellation and Rapid Reset vulnerabilities (CVE-2023-44487).
